import Foundation

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
/// ## Current Status
///
/// This is a stub orchestrator. The actual integration with
/// `SwiftVerificar-parser`, `SwiftVerificar-validation`, and other
/// packages will be wired up during reconciliation. Currently, calling
/// ``process(url:config:)`` returns a result populated with errors
/// indicating that the real implementation is not yet connected.
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
    /// 1. **Validate**: Validates the document against its declared profile.
    /// 2. **Extract Features**: Extracts PDF features according to the feature config.
    /// 3. **Fix Metadata**: Repairs metadata if the document is non-compliant.
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

        // Phase 1: Validation
        if config.shouldValidate {
            // Stub: real implementation will use Foundry to create a validator
            collectedErrors.append(
                .configurationError(reason: "Validation not yet connected — awaiting reconciliation")
            )
        }

        // Phase 2: Feature extraction
        if config.shouldExtractFeatures {
            // Stub: real implementation will use Foundry to create a feature extractor
            collectedErrors.append(
                .configurationError(reason: "Feature extraction not yet connected — awaiting reconciliation")
            )
        }

        // Phase 3: Metadata fixing
        if config.shouldFixMetadata {
            // Stub: real implementation will use Foundry to create a fixer
            // and only run if validation produced a non-compliant result
            collectedErrors.append(
                .configurationError(reason: "Metadata fixing not yet connected — awaiting reconciliation")
            )
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
