import Foundation
import SwiftVerificarValidationProfiles

/// The main entry point for SwiftVerificar -- designed for Lazarillo integration.
///
/// `SwiftVerificar` is a lean orchestration struct that provides a simple,
/// async API for PDF accessibility and compliance validation. It delegates
/// to the foundry system and component subsystems built in earlier sprints.
///
/// ## Java-to-Swift Mapping
///
/// This struct consolidates the top-level facade patterns from veraPDF-library
/// (`Processor`, `ProcessorFactory`, `VeraPDFFoundry`) into a single, clean
/// Swift entry point with async/await support.
///
/// ## Usage
///
/// ```swift
/// // Simple accessibility check (PDF/UA-2 default)
/// let result = try await SwiftVerificar.shared.validateAccessibility(pdfURL)
///
/// // Validate against a specific profile
/// let result = try await SwiftVerificar.shared.validate(
///     pdfURL,
///     profile: "PDF/UA-2",
///     config: ValidatorConfig(maxFailures: 10)
/// )
///
/// // Full processing pipeline
/// let processorResult = try await SwiftVerificar.shared.process(
///     pdfURL,
///     config: ProcessorConfig.all
/// )
///
/// // Batch validation
/// let batchResults = try await SwiftVerificar.shared.validateBatch(
///     [url1, url2, url3],
///     profile: "PDF/UA-2"
/// )
/// ```
///
public struct SwiftVerificar: Sendable {

    /// The shared singleton instance.
    ///
    /// Use this for all standard validation operations:
    /// ```swift
    /// let result = try await SwiftVerificar.shared.validateAccessibility(pdfURL)
    /// ```
    public static let shared = SwiftVerificar()

    /// The foundry used to create subsystem components.
    private let foundry: SwiftFoundry

    /// The processor used for full pipeline operations.
    private let processor: PDFProcessor

    /// Creates a new `SwiftVerificar` instance.
    ///
    /// Most callers should use ``shared`` instead. This initializer is
    /// public to support testing and custom configurations.
    ///
    /// - Parameter foundry: The foundry to use. Defaults to a new ``SwiftFoundry``.
    public init(foundry: SwiftFoundry = SwiftFoundry()) {
        self.foundry = foundry
        self.processor = PDFProcessor()
    }

    // MARK: - Simple API

    /// Validates a PDF document for accessibility against the PDF/UA-2 profile.
    ///
    /// This is the most common entry point for Lazarillo. It validates
    /// the document at the given URL against the PDF/UA-2 standard,
    /// which is the current best practice for accessible PDFs.
    ///
    /// - Parameters:
    ///   - url: The file URL of the PDF document to validate.
    ///   - progress: An optional closure called with progress updates.
    ///     The first parameter is a fraction (0.0 to 1.0) and the second
    ///     is a human-readable status message.
    /// - Returns: A ``ValidationResult`` describing the document's compliance.
    /// - Throws: ``VerificarError`` if validation cannot be performed.
    @Sendable
    public func validateAccessibility(
        _ url: URL,
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) async throws -> ValidationResult {
        try await validate(url, profile: "PDF/UA-2", progress: progress)
    }

    /// Validates a PDF document against a specific validation profile.
    ///
    /// Use this method when you need to validate against a profile other
    /// than PDF/UA-2 (e.g., "PDF/A-1b", "PDF/A-2u", "PDF/UA-1").
    ///
    /// - Parameters:
    ///   - url: The file URL of the PDF document to validate.
    ///   - profile: The name of the validation profile (e.g., "PDF/UA-2").
    ///   - config: Configuration controlling validator behavior.
    ///     Defaults to a default ``ValidatorConfig``.
    ///   - progress: An optional closure called with progress updates.
    ///     The first parameter is a fraction (0.0 to 1.0) and the second
    ///     is a human-readable status message.
    /// - Returns: A ``ValidationResult`` describing the document's compliance.
    /// - Throws: ``VerificarError`` if validation cannot be performed.
    @Sendable
    public func validate(
        _ url: URL,
        profile: String,
        config: ValidatorConfig = ValidatorConfig(),
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) async throws -> ValidationResult {
        progress?(0.05, "Initializing validation...")

        // Guard: profile name must not be empty
        guard !profile.isEmpty else {
            throw VerificarError.profileNotFound(name: "")
        }

        progress?(0.1, "Loading profile '\(profile)'...")

        // Step 1: Map the profile name string to a PDFFlavour
        let flavour = try resolveFlavour(from: profile)

        // Step 2: Load the validation profile from bundled XML resources (pre-check)
        do {
            let _ = try await ProfileLoader.shared.loadProfile(for: flavour)
        } catch {
            throw VerificarError.configurationError(
                reason: "Failed to load profile '\(profile)' (\(flavour.displayName)): \(error.localizedDescription)"
            )
        }

        progress?(0.2, "Profile '\(profile)' loaded. Preparing validation engine...")

        // Check for cancellation before starting expensive work
        try Task.checkCancellation()

        // Step 3: Parse and validate via SwiftPDFValidator
        progress?(0.3, "Parsing document...")

        let validator = SwiftPDFValidator(profileName: profile, config: config)
        progress?(0.5, "Validating against '\(profile)'...")

        let result = try await validator.validate(contentsOf: url)

        progress?(0.9, "Validation complete")
        progress?(1.0, "Done")
        return result
    }

    // MARK: - Advanced API

    /// Performs full processing on a PDF document.
    ///
    /// This method delegates to ``PDFProcessor`` and supports validation,
    /// feature extraction, and metadata fixing in a single pass. The
    /// processing phases executed depend on the ``ProcessorConfig/tasks``
    /// specified in the configuration.
    ///
    /// - Parameters:
    ///   - url: The file URL of the PDF document to process.
    ///   - config: Configuration specifying which tasks to perform
    ///     and how to configure each phase.
    ///   - progress: An optional closure called with progress updates.
    ///     The first parameter is a fraction (0.0 to 1.0) and the second
    ///     is a human-readable status message.
    /// - Returns: A ``ProcessorResult`` containing results from all phases.
    /// - Throws: ``VerificarError`` if a fatal error prevents any processing.
    @Sendable
    public func process(
        _ url: URL,
        config: ProcessorConfig = ProcessorConfig(),
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) async throws -> ProcessorResult {
        progress?(0.05, "Starting processing...")

        let result = try await processor.process(url: url, config: config)

        progress?(1.0, "Processing complete")
        return result
    }

    // MARK: - Batch API

    /// Validates multiple PDF documents concurrently.
    ///
    /// Each URL is validated independently against the specified profile.
    /// Failures for individual documents are captured as `.failure` results
    /// in the returned dictionary, not thrown as errors. Only a global
    /// configuration error (e.g., empty profile name) is thrown.
    ///
    /// - Parameters:
    ///   - urls: An array of file URLs to validate.
    ///   - profile: The name of the validation profile to use.
    ///   - maxConcurrency: The maximum number of concurrent validations.
    ///     Defaults to `4`.
    ///   - progress: An optional closure called after each document completes.
    ///     The parameters are: completed count, total count, and the URL
    ///     that just completed (or `nil`).
    /// - Returns: A dictionary mapping each URL to its validation result
    ///   or error.
    /// - Throws: ``VerificarError`` if the batch cannot start at all
    ///   (e.g., empty profile name).
    @Sendable
    public func validateBatch(
        _ urls: [URL],
        profile: String,
        maxConcurrency: Int = 4,
        progress: (@Sendable (Int, Int, URL?) -> Void)? = nil
    ) async throws -> [URL: Result<ValidationResult, Error>] {
        // Guard: profile name must not be empty
        guard !profile.isEmpty else {
            throw VerificarError.profileNotFound(name: "")
        }

        // Edge case: empty array returns immediately
        guard !urls.isEmpty else {
            return [:]
        }

        // Validate each URL concurrently with bounded parallelism
        let effectiveConcurrency = max(1, min(maxConcurrency, urls.count))

        return await withTaskGroup(
            of: (URL, Result<ValidationResult, Error>).self
        ) { group in
            var results: [URL: Result<ValidationResult, Error>] = [:]
            results.reserveCapacity(urls.count)
            var completed = 0
            var urlIterator = urls.makeIterator()

            // Seed the group with up to effectiveConcurrency tasks
            for _ in 0..<effectiveConcurrency {
                guard let url = urlIterator.next() else { break }
                group.addTask { [self] in
                    do {
                        let result = try await self.validate(url, profile: profile)
                        return (url, .success(result))
                    } catch {
                        return (url, .failure(error))
                    }
                }
            }

            // As each task completes, start the next one
            for await (url, result) in group {
                results[url] = result
                completed += 1
                progress?(completed, urls.count, url)

                // Launch next task if there are more URLs
                if let nextURL = urlIterator.next() {
                    group.addTask { [self] in
                        do {
                            let result = try await self.validate(nextURL, profile: profile)
                            return (nextURL, .success(result))
                        } catch {
                            return (nextURL, .failure(error))
                        }
                    }
                }
            }

            return results
        }
    }

    // MARK: - Introspection

    /// The version of the SwiftVerificar library.
    public var version: String {
        SwiftVerificarBiblioteca.version
    }

    /// The component info of the underlying foundry.
    public var foundryInfo: ComponentInfo {
        foundry.info
    }

    // MARK: - Private Helpers

    /// Maps a human-readable profile name to a ``PDFFlavour``.
    ///
    /// Accepts common profile names such as "PDF/UA-2", "PDF/A-1b",
    /// "WCAG 2.2", etc. and normalizes them by stripping spaces,
    /// slashes, and hyphens before matching.
    ///
    /// - Parameter profileName: The profile name string to resolve.
    /// - Returns: The corresponding ``PDFFlavour``.
    /// - Throws: ``VerificarError/profileNotFound(name:)`` if the
    ///   name does not match any known flavour.
    private func resolveFlavour(from profileName: String) throws -> PDFFlavour {
        let normalized = profileName
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "-", with: "")

        switch normalized {
        case "pdfua2":
            return .pdfUA2
        case "pdfua1":
            return .pdfUA1
        case "pdfa1a":
            return .pdfA1a
        case "pdfa1b":
            return .pdfA1b
        case "pdfa2a":
            return .pdfA2a
        case "pdfa2b":
            return .pdfA2b
        case "pdfa2u":
            return .pdfA2u
        case "pdfa3a":
            return .pdfA3a
        case "pdfa3b":
            return .pdfA3b
        case "pdfa3u":
            return .pdfA3u
        case "pdfa4":
            return .pdfA4
        case "wcag22", "wcag2.2":
            return .wcag22
        default:
            throw VerificarError.profileNotFound(name: profileName)
        }
    }
}

// MARK: - CustomStringConvertible

extension SwiftVerificar: CustomStringConvertible {
    public var description: String {
        "SwiftVerificar(version: \(version), foundry: \(foundry.info.name))"
    }
}
