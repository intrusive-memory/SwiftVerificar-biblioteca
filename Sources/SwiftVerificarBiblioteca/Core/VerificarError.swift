import Foundation

/// Consolidated error type for the SwiftVerificar ecosystem.
///
/// This enum consolidates six Java exception classes from veraPDF-library
/// into a single, expressive Swift error type:
///
/// | Java Exception             | Swift Case             |
/// |---------------------------|------------------------|
/// | `VeraPDFException`         | `.configurationError`  |
/// | `ValidationException`      | `.validationFailed`    |
/// | `ModelParsingException`    | `.parsingFailed`       |
/// | `ProfileException`         | `.profileNotFound`     |
/// | `EncryptedPdfException`    | `.encryptedPDF`        |
/// | `FeatureParsingException`  | `.ioError`             |
///
/// Each case carries associated values providing context about the failure.
public enum VerificarError: Error, Sendable, Equatable {

    /// PDF parsing failed.
    ///
    /// Thrown when the parser cannot read or interpret a PDF document.
    /// Consolidates Java `ModelParsingException`.
    ///
    /// - Parameters:
    ///   - url: The URL of the document that could not be parsed.
    ///   - reason: A human-readable description of why parsing failed.
    case parsingFailed(url: URL, reason: String)

    /// Validation of a document failed due to an internal error.
    ///
    /// This is distinct from a document *not being compliant*. This error
    /// indicates the validation engine itself encountered a problem.
    /// Consolidates Java `ValidationException`.
    ///
    /// - Parameter reason: A human-readable description of the failure.
    case validationFailed(reason: String)

    /// The requested validation profile could not be found or loaded.
    ///
    /// Consolidates Java `ProfileException`.
    ///
    /// - Parameter name: The profile identifier that was not found
    ///   (e.g., a flavour name like "pdfua2").
    case profileNotFound(name: String)

    /// The PDF document is encrypted and cannot be validated.
    ///
    /// Consolidates Java `EncryptedPdfException`.
    ///
    /// - Parameter url: The URL of the encrypted document.
    case encryptedPDF(url: URL)

    /// A configuration or setup error occurred.
    ///
    /// Thrown when the system is misconfigured (e.g., no foundry registered,
    /// invalid parameters). Consolidates Java `VeraPDFException`.
    ///
    /// - Parameter reason: A human-readable description of the configuration issue.
    case configurationError(reason: String)

    /// An I/O or feature extraction error occurred.
    ///
    /// Thrown when file reading, writing, or feature extraction fails.
    /// Consolidates Java `FeatureParsingException` and general I/O errors.
    ///
    /// - Parameters:
    ///   - path: An optional file path associated with the failure.
    ///   - reason: A human-readable description of the I/O failure.
    case ioError(path: String?, reason: String)
}

// MARK: - LocalizedError

extension VerificarError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .parsingFailed(let url, let reason):
            return "Failed to parse PDF at '\(url.path)' (\(url.lastPathComponent)): \(reason)"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .profileNotFound(let name):
            if name.isEmpty {
                return "Validation profile not found: profile name must not be empty"
            }
            return "Validation profile not found: '\(name)'"
        case .encryptedPDF(let url):
            return "PDF is encrypted and cannot be validated: '\(url.path)' (\(url.lastPathComponent))"
        case .configurationError(let reason):
            return "Configuration error: \(reason)"
        case .ioError(let path, let reason):
            if let path {
                return "I/O error at '\(path)': \(reason)"
            }
            return "I/O error: \(reason)"
        }
    }
}

// MARK: - CustomStringConvertible

extension VerificarError: CustomStringConvertible {
    public var description: String {
        errorDescription ?? "Unknown VerificarError"
    }
}
