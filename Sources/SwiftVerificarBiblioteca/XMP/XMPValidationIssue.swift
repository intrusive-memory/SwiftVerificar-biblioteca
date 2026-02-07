import Foundation

/// A validation issue found during XMP metadata validation.
///
/// `XMPValidationIssue` represents a single problem detected when validating
/// XMP metadata for PDF/A or PDF/UA compliance. Each issue includes a human-readable
/// message, an optional property path identifying the problematic field, and a
/// severity level.
///
/// ## Example
/// ```swift
/// let issue = XMPValidationIssue(
///     message: "Missing required pdfaid:part property",
///     property: "pdfaid:part",
///     severity: .error
/// )
/// ```
public struct XMPValidationIssue: Sendable, Codable, Equatable {

    /// A human-readable message describing the validation issue.
    public let message: String

    /// The XMP property path related to this issue, if applicable.
    ///
    /// For example, `"pdfaid:part"`, `"dc:title"`, or `nil` if
    /// the issue is not specific to a single property.
    public let property: String?

    /// The severity of the validation issue.
    public let severity: Severity

    /// Creates an XMP validation issue.
    ///
    /// - Parameters:
    ///   - message: A description of the issue.
    ///   - property: The related XMP property path, or `nil`.
    ///   - severity: The severity level.
    public init(
        message: String,
        property: String? = nil,
        severity: Severity
    ) {
        self.message = message
        self.property = property
        self.severity = severity
    }

    /// The severity level of an XMP validation issue.
    public enum Severity: String, Sendable, Codable, Equatable, CaseIterable {
        /// An error that prevents compliance.
        case error

        /// A warning about a potential issue.
        case warning

        /// An informational note.
        case info
    }

    /// Whether this issue is an error.
    public var isError: Bool {
        severity == .error
    }

    /// Whether this issue is a warning.
    public var isWarning: Bool {
        severity == .warning
    }

    /// Whether this issue is informational.
    public var isInfo: Bool {
        severity == .info
    }
}

// MARK: - CustomStringConvertible

extension XMPValidationIssue: CustomStringConvertible {
    public var description: String {
        if let property {
            return "[\(severity.rawValue.uppercased())] \(property): \(message)"
        }
        return "[\(severity.rawValue.uppercased())] \(message)"
    }
}

// MARK: - Severity CustomStringConvertible

extension XMPValidationIssue.Severity: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
