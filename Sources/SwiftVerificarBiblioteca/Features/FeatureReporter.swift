import Foundation

/// A reporter that formats and serializes extracted feature data.
///
/// `FeatureReporter` consolidates the Java `FeaturesReporter` class
/// from veraPDF-library. It provides methods to convert a
/// `FeatureExtractionResult` into various output formats (JSON, XML,
/// plain text) and to filter or summarize feature data.
///
/// ## Example
/// ```swift
/// let reporter = FeatureReporter()
/// let jsonData = try reporter.generateJSON(from: result)
/// let summary = reporter.summarize(result)
/// ```
public struct FeatureReporter: Sendable, Equatable {

    /// The output format for report generation.
    public enum OutputFormat: String, CaseIterable, Sendable, Codable {
        /// JSON format.
        case json

        /// Plain text format.
        case text

        /// XML format.
        case xml
    }

    /// Whether to include error details in the generated report.
    public var includeErrors: Bool

    /// Whether to include empty branches (branches with no leaf values).
    public var includeEmptyBranches: Bool

    /// Creates a new feature reporter.
    ///
    /// - Parameters:
    ///   - includeErrors: Whether to include error details. Defaults to `true`.
    ///   - includeEmptyBranches: Whether to include empty branches. Defaults to `false`.
    public init(includeErrors: Bool = true, includeEmptyBranches: Bool = false) {
        self.includeErrors = includeErrors
        self.includeEmptyBranches = includeEmptyBranches
    }

    /// Generates a JSON representation of the extraction result.
    ///
    /// - Parameter result: The feature extraction result to encode.
    /// - Returns: JSON-encoded data.
    /// - Throws: An error if encoding fails.
    public func generateJSON(from result: FeatureExtractionResult) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(result)
    }

    /// Generates a plain-text summary of the extraction result.
    ///
    /// The output is a human-readable, indented tree representation
    /// of the feature data.
    ///
    /// - Parameter result: The feature extraction result to format.
    /// - Returns: A plain-text string representation.
    public func generateText(from result: FeatureExtractionResult) -> String {
        var lines: [String] = []
        lines.append("Feature Report: \(result.documentURL.lastPathComponent)")
        lines.append(String(repeating: "=", count: 60))
        lines.append("")
        renderNode(result.features, indent: 0, into: &lines)

        if includeErrors && !result.errors.isEmpty {
            lines.append("")
            lines.append("Errors (\(result.errors.count)):")
            lines.append(String(repeating: "-", count: 40))
            for error in result.errors {
                lines.append("  [\(error.featureType.displayName)] \(error.message)")
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Generates an XML representation of the extraction result.
    ///
    /// - Parameter result: The feature extraction result to format.
    /// - Returns: An XML string representation.
    public func generateXML(from result: FeatureExtractionResult) -> String {
        var lines: [String] = []
        lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        renderNodeAsXML(result.features, indent: 0, into: &lines)

        if includeErrors && !result.errors.isEmpty {
            lines.append("<errors>")
            for error in result.errors {
                let escapedMessage = escapeXML(error.message)
                lines.append("  <error featureType=\"\(error.featureType.rawValue)\">" +
                             "\(escapedMessage)</error>")
            }
            lines.append("</errors>")
        }

        return lines.joined(separator: "\n")
    }

    /// Produces a data representation in the given output format.
    ///
    /// - Parameters:
    ///   - result: The feature extraction result to format.
    ///   - format: The desired output format.
    /// - Returns: The formatted data.
    /// - Throws: An error if JSON encoding fails.
    public func generate(from result: FeatureExtractionResult, format: OutputFormat) throws -> Data {
        switch format {
        case .json:
            return try generateJSON(from: result)
        case .text:
            guard let data = generateText(from: result).data(using: .utf8) else {
                throw VerificarError.ioError(path: nil, reason: "Failed to encode text as UTF-8")
            }
            return data
        case .xml:
            guard let data = generateXML(from: result).data(using: .utf8) else {
                throw VerificarError.ioError(path: nil, reason: "Failed to encode XML as UTF-8")
            }
            return data
        }
    }

    /// Creates a summary of the extraction result.
    ///
    /// Returns a dictionary mapping each top-level feature category name
    /// to the number of leaf nodes it contains.
    ///
    /// - Parameter result: The feature extraction result.
    /// - Returns: A summary dictionary keyed by category name.
    public func summarize(_ result: FeatureExtractionResult) -> [String: Int] {
        var summary: [String: Int] = [:]
        for child in result.features.children {
            summary[child.name] = child.allLeafValues.count
        }
        return summary
    }

    // MARK: - Private Helpers

    private func renderNode(_ node: FeatureNode, indent: Int, into lines: inout [String]) {
        let prefix = String(repeating: "  ", count: indent)

        switch node {
        case .leaf(let name, let value):
            if let value {
                lines.append("\(prefix)\(name): \(value)")
            } else {
                lines.append("\(prefix)\(name)")
            }
        case .branch(let name, let children, let attributes):
            if !includeEmptyBranches && children.isEmpty && attributes.isEmpty {
                return
            }
            var header = "\(prefix)\(name)"
            if !attributes.isEmpty {
                let attrString = attributes
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key)=\($0.value)" }
                    .joined(separator: ", ")
                header += " (\(attrString))"
            }
            lines.append(header)
            for child in children {
                renderNode(child, indent: indent + 1, into: &lines)
            }
        }
    }

    private func renderNodeAsXML(_ node: FeatureNode, indent: Int, into lines: inout [String]) {
        let prefix = String(repeating: "  ", count: indent)
        let escapedName = escapeXMLTag(node.name)

        switch node {
        case .leaf(let name, let value):
            let tag = escapeXMLTag(name)
            if let value {
                lines.append("\(prefix)<\(tag)>\(escapeXML(value))</\(tag)>")
            } else {
                lines.append("\(prefix)<\(tag)/>")
            }
        case .branch(let name, let children, let attributes):
            if !includeEmptyBranches && children.isEmpty && attributes.isEmpty {
                return
            }
            var openTag = "\(prefix)<\(escapedName)"
            for (key, val) in attributes.sorted(by: { $0.key < $1.key }) {
                openTag += " \(escapeXMLTag(key))=\"\(escapeXML(val))\""
            }

            if children.isEmpty {
                lines.append("\(openTag)/>")
            } else {
                lines.append("\(openTag)>")
                for child in children {
                    renderNodeAsXML(child, indent: indent + 1, into: &lines)
                }
                lines.append("\(prefix)</\(escapedName)>")
            }
        }
    }

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func escapeXMLTag(_ string: String) -> String {
        // XML tags cannot contain spaces or special characters.
        // Replace spaces with underscores and remove other invalid characters.
        string
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" || $0 == "." }
    }
}

// MARK: - CustomStringConvertible

extension FeatureReporter: CustomStringConvertible {
    public var description: String {
        "FeatureReporter(includeErrors: \(includeErrors), includeEmptyBranches: \(includeEmptyBranches))"
    }
}
