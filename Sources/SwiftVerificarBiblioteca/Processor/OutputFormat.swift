import Foundation

/// Output format for validation reports and processing results.
///
/// `OutputFormat` specifies how results should be serialized for
/// consumption by external tools or user-facing displays.
///
/// ## Java-to-Swift Mapping
///
/// | Java Class        | Swift Equivalent        |
/// |------------------|-------------------------|
/// | `FormatOption` enum | ``OutputFormat`` enum  |
///
/// ## Example
///
/// ```swift
/// let format = OutputFormat.json
/// print(format.rawValue)            // "json"
/// print(format.fileExtension)       // "json"
/// print(format.mimeType)            // "application/json"
/// ```
public enum OutputFormat: String, Sendable, CaseIterable, Codable {

    /// JSON output format.
    case json

    /// XML output format.
    case xml

    /// Plain text output format.
    case text

    /// HTML output format.
    case html
}

// MARK: - Derived Properties

extension OutputFormat {

    /// The file extension typically used for this format.
    public var fileExtension: String {
        switch self {
        case .json: return "json"
        case .xml: return "xml"
        case .text: return "txt"
        case .html: return "html"
        }
    }

    /// The MIME type for this format.
    public var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .xml: return "application/xml"
        case .text: return "text/plain"
        case .html: return "text/html"
        }
    }

    /// A human-readable display name for the format.
    public var displayName: String {
        switch self {
        case .json: return "JSON"
        case .xml: return "XML"
        case .text: return "Plain Text"
        case .html: return "HTML"
        }
    }
}

// MARK: - CustomStringConvertible

extension OutputFormat: CustomStringConvertible {
    public var description: String {
        displayName
    }
}

// MARK: - Hashable

extension OutputFormat: Hashable {}
