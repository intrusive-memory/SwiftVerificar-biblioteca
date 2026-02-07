import Foundation
import SwiftVerificarValidationProfiles

/// Orchestrates validation, feature extraction, and metadata fixing for a PDF.
///
/// `PDFProcessor` is a lightweight coordinator that delegates to the
/// appropriate components (validator, feature extractor, metadata fixer)
/// based on the ``ProcessorConfig``. It parses the document once and then
/// runs each requested phase in sequence, collecting results and errors
/// into a single ``ProcessorResult``.
///
/// ## Java-to-Swift Mapping
///
/// | Java Class          | Swift Equivalent         |
/// |--------------------|--------------------------|
/// | `ProcessorImpl`     | ``PDFProcessor`` struct  |
/// | `ProcessorFactory`  | Consolidated into struct |
/// | `Processor` interface | Consolidated            |
///
/// ## Pipeline
///
/// The processor uses:
/// - ``SwiftPDFParser`` to parse the PDF document into a ``ParsedDocument``
/// - ``SwiftPDFValidator`` for rule-based document validation against a profile
/// - ``SwiftFeatureExtractor`` for extracting PDF features (fonts, pages, etc.)
/// - ``SwiftMetadataFixer`` for repairing and synchronizing PDF metadata
///
/// ## Example
///
/// ```swift
/// let processor = PDFProcessor()
/// let config = ProcessorConfig(tasks: [.validate, .extractFeatures])
/// let result = try await processor.process(url: pdfURL, config: config)
/// if result.isSuccessful {
///     print("Processing complete")
/// }
/// ```
public struct PDFProcessor: Sendable {

    /// Creates a new PDF processor.
    public init() {}

    /// Processes a PDF document according to the given configuration.
    ///
    /// The processor performs each task listed in `config.tasks` in order:
    /// 1. **Parse**: Parses the document using ``SwiftPDFParser`` (required by all phases).
    /// 2. **Validate**: Validates the document against its declared or default profile.
    /// 3. **Extract Features**: Extracts PDF features according to the feature config.
    /// 4. **Fix Metadata**: Repairs metadata if the document is non-compliant.
    ///
    /// Each phase's result is collected into the returned ``ProcessorResult``.
    /// If a phase fails, its error is appended to the result's errors array
    /// and subsequent phases may still execute.
    ///
    /// - Parameters:
    ///   - url: The URL of the PDF document to process.
    ///   - config: The processing configuration specifying what to do.
    /// - Returns: A ``ProcessorResult`` containing results from all phases.
    /// - Throws: ``VerificarError`` if a fatal error prevents any processing.
    public func process(url: URL, config: ProcessorConfig) async throws -> ProcessorResult {
        var collectedErrors: [VerificarError] = []
        var validationResult: ValidationResult?
        var featureResult: FeatureExtractionResult?
        var fixerResult: MetadataFixerResult?

        // Guard against empty task set
        guard config.hasTasks else {
            return ProcessorResult(
                documentURL: url,
                errors: [.configurationError(reason: "No processing tasks specified")]
            )
        }

        // Step 0: Parse the document once (needed by all phases)
        let parser = SwiftPDFParser(url: url)
        let document: any ParsedDocument
        do {
            document = try await parser.parse()
        } catch {
            // If parsing fails, no phases can run
            if let verificarError = error as? VerificarError {
                return ProcessorResult(documentURL: url, errors: [verificarError])
            }
            return ProcessorResult(documentURL: url, errors: [
                .parsingFailed(url: url, reason: error.localizedDescription)
            ])
        }

        // Phase 1: Validation
        if config.shouldValidate {
            do {
                // Auto-detect profile from document flavour, or use "PDF/UA-2" as default
                let profileName: String
                if let flavour = document.flavour {
                    profileName = flavour.displayName
                } else {
                    // Try to detect flavour from the parser
                    let detected = try? await parser.detectFlavour()
                    profileName = detected?.displayName ?? "PDF/UA-2"
                }

                let validator = SwiftPDFValidator(
                    profileName: profileName,
                    config: config.validatorConfig
                )
                validationResult = try await validator.validate(document)
            } catch {
                if let verificarError = error as? VerificarError {
                    collectedErrors.append(verificarError)
                } else {
                    collectedErrors.append(.configurationError(
                        reason: "Validation failed: \(error.localizedDescription)"
                    ))
                }
            }
        }

        // Phase 2: Feature extraction
        if config.shouldExtractFeatures {
            let featureConfig = config.featureConfig ?? FeatureConfig()
            // Convert FeatureConfig to FeatureExtractorConfiguration for SwiftFeatureExtractor
            let extractorConfig = FeatureExtractorConfiguration(
                enabledFeatures: Set(featureConfig.enabledFeatures.map(\.rawValue)),
                includeSubFeatures: featureConfig.includeSubFeatures
            )
            let extractor = SwiftFeatureExtractor(config: extractorConfig)
            featureResult = extractor.extract(from: document)
        }

        // Phase 3: Metadata fixing
        if config.shouldFixMetadata {
            do {
                let fixConfig = config.fixerConfig ?? FixerConfig()
                let fixer = SwiftMetadataFixer(config: fixConfig)

                // Need a validation result to determine what to fix
                let valResult = validationResult ?? ValidationResult(
                    profileName: "unknown",
                    documentURL: url,
                    isCompliant: false,
                    assertions: [],
                    duration: .zero()
                )

                // Create output URL in temp directory
                let outputURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("fixed_\(url.lastPathComponent)")

                fixerResult = try await fixer.fix(
                    document: document,
                    validationResult: valResult,
                    outputURL: outputURL
                )
            } catch {
                if let verificarError = error as? VerificarError {
                    collectedErrors.append(verificarError)
                } else {
                    collectedErrors.append(.configurationError(
                        reason: "Metadata fixing failed: \(error.localizedDescription)"
                    ))
                }
            }
        }

        return ProcessorResult(
            documentURL: url,
            validationResult: validationResult,
            featureResult: featureResult,
            fixerResult: fixerResult,
            errors: collectedErrors
        )
    }
}

// MARK: - CustomStringConvertible

extension PDFProcessor: CustomStringConvertible {
    public var description: String {
        "PDFProcessor()"
    }
}
