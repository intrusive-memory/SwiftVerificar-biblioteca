import Foundation

/// The combined result of a ``PDFProcessor`` run.
///
/// `ProcessorResult` aggregates the outcomes of each processing phase
/// (validation, feature extraction, metadata fixing) into a single
/// value. Each result is optional because the corresponding task may
/// not have been requested in the ``ProcessorConfig``.
///
/// Errors that occur during processing are collected in the ``errors``
/// array. A processing run may produce partial results (e.g., validation
/// succeeds but metadata fixing fails).
///
/// ## Java-to-Swift Mapping
///
/// | Java Class            | Swift Equivalent              |
/// |----------------------|-------------------------------|
/// | `ProcessorResult`     | ``ProcessorResult`` struct    |
/// | `ProcessorResultImpl` | Consolidated into struct      |
///
/// ## Example
///
/// ```swift
/// let result = ProcessorResult(
///     documentURL: pdfURL,
///     validationResult: validationResult,
///     featureResult: nil,
///     fixerResult: nil,
///     errors: []
/// )
/// print(result.isSuccessful)   // true if no errors
/// print(result.hasValidation)  // true
/// ```
public struct ProcessorResult: Sendable, Equatable {

    /// The URL of the document that was processed.
    public let documentURL: URL

    /// The result of the validation phase, if validation was performed.
    ///
    /// `nil` when the ``ProcessorConfig`` did not include `.validate`
    /// in its tasks, or when validation failed with an error (which
    /// would appear in ``errors``).
    public let validationResult: ValidationResult?

    /// The result of the feature extraction phase, if extraction was performed.
    ///
    /// `nil` when the ``ProcessorConfig`` did not include `.extractFeatures`
    /// in its tasks, or when extraction failed with an error.
    public let featureResult: FeatureExtractionResult?

    /// The result of the metadata fixing phase, if fixing was performed.
    ///
    /// `nil` when the ``ProcessorConfig`` did not include `.fixMetadata`
    /// in its tasks, or when fixing failed with an error.
    public let fixerResult: MetadataFixerResult?

    /// Errors that occurred during processing.
    ///
    /// An empty array indicates all requested tasks completed without
    /// errors. Errors may be present alongside partial results (e.g.,
    /// validation succeeded but feature extraction failed).
    public let errors: [VerificarError]

    /// Creates a processor result.
    ///
    /// - Parameters:
    ///   - documentURL: The URL of the processed document.
    ///   - validationResult: The validation result, if any.
    ///   - featureResult: The feature extraction result, if any.
    ///   - fixerResult: The metadata fixer result, if any.
    ///   - errors: Errors that occurred during processing.
    public init(
        documentURL: URL,
        validationResult: ValidationResult? = nil,
        featureResult: FeatureExtractionResult? = nil,
        fixerResult: MetadataFixerResult? = nil,
        errors: [VerificarError] = []
    ) {
        self.documentURL = documentURL
        self.validationResult = validationResult
        self.featureResult = featureResult
        self.fixerResult = fixerResult
        self.errors = errors
    }

    // MARK: - Computed Properties

    /// Whether the processing completed without errors.
    public var isSuccessful: Bool {
        errors.isEmpty
    }

    /// Whether the processing produced any errors.
    public var hasErrors: Bool {
        !errors.isEmpty
    }

    /// The number of errors that occurred during processing.
    public var errorCount: Int {
        errors.count
    }

    /// Whether a validation result is present.
    public var hasValidation: Bool {
        validationResult != nil
    }

    /// Whether a feature extraction result is present.
    public var hasFeatures: Bool {
        featureResult != nil
    }

    /// Whether a metadata fixer result is present.
    public var hasFixer: Bool {
        fixerResult != nil
    }

    /// Whether the validated document is compliant, if validation was performed.
    ///
    /// Returns `nil` if no validation was performed.
    public var isCompliant: Bool? {
        validationResult?.isCompliant
    }

    /// The total number of phases that produced results.
    public var completedPhaseCount: Int {
        var count = 0
        if hasValidation { count += 1 }
        if hasFeatures { count += 1 }
        if hasFixer { count += 1 }
        return count
    }
}

// MARK: - CustomStringConvertible

extension ProcessorResult: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        parts.append(documentURL.lastPathComponent)
        if let validationResult {
            parts.append(validationResult.isCompliant ? "compliant" : "non-compliant")
        }
        if hasFeatures {
            parts.append("features")
        }
        if hasFixer {
            parts.append("fixed")
        }
        if hasErrors {
            parts.append("\(errorCount) errors")
        }
        return "ProcessorResult(\(parts.joined(separator: ", ")))"
    }
}
