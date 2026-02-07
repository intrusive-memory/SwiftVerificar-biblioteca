import Foundation

/// Static utility for generating reports in different output formats.
///
/// `ReportGenerator` is a caseless enum providing static methods to
/// serialize a ``ValidationReport`` into JSON, XML, HTML, or plain text.
/// It consolidates the Java `HTMLReport`, `XsltTransformer`, and
/// `JsonHandler` classes from veraPDF-library.
///
/// ## Example
/// ```swift
/// let report = ValidationReport.generate(from: result)
/// let jsonData = try ReportGenerator.json(from: report)
/// let htmlString = ReportGenerator.html(from: report)
/// ```
public enum ReportGenerator: Sendable {

    // MARK: - JSON

    /// Serializes a ``ValidationReport`` to JSON data.
    ///
    /// Uses `JSONEncoder` with pretty-printed, sorted-keys formatting.
    ///
    /// - Parameter report: The validation report to serialize.
    /// - Returns: UTF-8 encoded JSON data.
    /// - Throws: `EncodingError` if the report cannot be encoded.
    public static func json(from report: ValidationReport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(report)
    }

    // MARK: - XML

    /// Serializes a ``ValidationReport`` to XML data.
    ///
    /// Generates a simple XML document representing the report structure.
    /// The XML is encoded as UTF-8 data.
    ///
    /// - Parameter report: The validation report to serialize.
    /// - Returns: UTF-8 encoded XML data.
    /// - Throws: An error if the XML string cannot be encoded to data.
    public static func xml(from report: ValidationReport) throws -> Data {
        let xmlString = buildXML(from: report)
        guard let data = xmlString.data(using: .utf8) else {
            throw ReportGeneratorError.encodingFailed(format: "xml")
        }
        return data
    }

    // MARK: - HTML

    /// Generates an HTML string from a ``ValidationReport``.
    ///
    /// Produces a self-contained HTML document with an inline CSS
    /// stylesheet and a table of rule summaries.
    ///
    /// - Parameter report: The validation report to render.
    /// - Returns: A complete HTML document as a string.
    public static func html(from report: ValidationReport) -> String {
        buildHTML(from: report)
    }

    // MARK: - Plain Text

    /// Generates a plain text string from a ``ValidationReport``.
    ///
    /// Produces a human-readable text report with overall statistics
    /// and per-rule summary lines.
    ///
    /// - Parameter report: The validation report to render.
    /// - Returns: A multi-line plain text string.
    public static func text(from report: ValidationReport) -> String {
        buildText(from: report)
    }

    // MARK: - Private XML Builder

    private static func buildXML(from report: ValidationReport) -> String {
        var lines: [String] = []
        lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        lines.append("<validationReport>")
        lines.append("  <result>")
        lines.append("    <profileName>\(escapeXML(report.result.profileName))</profileName>")
        lines.append("    <documentURL>\(escapeXML(report.result.documentURL.absoluteString))</documentURL>")
        lines.append("    <isCompliant>\(report.result.isCompliant)</isCompliant>")
        lines.append("    <passedCount>\(report.result.passedCount)</passedCount>")
        lines.append("    <failedCount>\(report.result.failedCount)</failedCount>")
        lines.append("    <totalCount>\(report.result.totalCount)</totalCount>")
        lines.append("    <duration>\(String(format: "%.3f", report.result.duration.duration))</duration>")
        lines.append("  </result>")
        lines.append("  <summaries>")

        for summary in report.summaries {
            lines.append("    <ruleSummary>")
            lines.append("      <ruleID>\(escapeXML(summary.ruleID.uniqueID))</ruleID>")
            lines.append("      <specification>\(escapeXML(summary.ruleID.specification.rawValue))</specification>")
            lines.append("      <clause>\(escapeXML(summary.ruleID.clause))</clause>")
            lines.append("      <testNumber>\(summary.ruleID.testNumber)</testNumber>")
            lines.append("      <passedCount>\(summary.passedCount)</passedCount>")
            lines.append("      <failedCount>\(summary.failedCount)</failedCount>")
            lines.append("      <totalChecks>\(summary.totalChecks)</totalChecks>")
            lines.append("      <failureRate>\(String(format: "%.4f", summary.failureRate))</failureRate>")
            lines.append("      <description>\(escapeXML(summary.ruleDescription))</description>")
            lines.append("    </ruleSummary>")
        }

        lines.append("  </summaries>")
        lines.append("</validationReport>")

        return lines.joined(separator: "\n")
    }

    // MARK: - Private HTML Builder

    private static func buildHTML(from report: ValidationReport) -> String {
        let status = report.result.isCompliant ? "COMPLIANT" : "NON-COMPLIANT"
        let statusColor = report.result.isCompliant ? "#4caf50" : "#f44336"
        let failureRatePercent = String(format: "%.1f", report.overallFailureRate * 100)

        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Validation Report</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 20px; color: #333; }
            h1 { color: #1a1a1a; }
            .status { display: inline-block; padding: 4px 12px; border-radius: 4px; color: white; font-weight: bold; }
            .summary-table { width: 100%; border-collapse: collapse; margin-top: 16px; }
            .summary-table th, .summary-table td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            .summary-table th { background-color: #f5f5f5; }
            .summary-table tr:nth-child(even) { background-color: #fafafa; }
            .pass { color: #4caf50; }
            .fail { color: #f44336; }
            .meta { color: #666; font-size: 0.9em; margin-bottom: 16px; }
          </style>
        </head>
        <body>
          <h1>Validation Report</h1>
          <p class="meta">
            Document: \(escapeHTML(report.result.documentURL.lastPathComponent))<br>
            Profile: \(escapeHTML(report.result.profileName))<br>
            Duration: \(String(format: "%.3f", report.result.duration.duration))s
          </p>
          <p>
            Status: <span class="status" style="background-color: \(statusColor)">\(status)</span>
          </p>
          <p>
            Total assertions: \(report.result.totalCount) |
            <span class="pass">Passed: \(report.result.passedCount)</span> |
            <span class="fail">Failed: \(report.result.failedCount)</span> |
            Overall failure rate: \(failureRatePercent)%
          </p>
        """

        if !report.summaries.isEmpty {
            html += """

              <h2>Rule Summaries (\(report.ruleCount) rules)</h2>
              <table class="summary-table">
                <thead>
                  <tr>
                    <th>Rule ID</th>
                    <th>Clause</th>
                    <th>Passed</th>
                    <th>Failed</th>
                    <th>Total</th>
                    <th>Failure Rate</th>
                    <th>Description</th>
                  </tr>
                </thead>
                <tbody>
            """

            for summary in report.summaries {
                let rateStr = String(format: "%.1f%%", summary.failureRate * 100)
                let rowClass = summary.failedCount > 0 ? "fail" : "pass"
                html += """

                    <tr>
                      <td>\(escapeHTML(summary.ruleID.uniqueID))</td>
                      <td>\(escapeHTML(summary.ruleID.clause))</td>
                      <td class="pass">\(summary.passedCount)</td>
                      <td class="\(rowClass)">\(summary.failedCount)</td>
                      <td>\(summary.totalChecks)</td>
                      <td>\(rateStr)</td>
                      <td>\(escapeHTML(summary.ruleDescription))</td>
                    </tr>
                """
            }

            html += """

                </tbody>
              </table>
            """
        }

        html += """

        </body>
        </html>
        """

        return html
    }

    // MARK: - Private Text Builder

    private static func buildText(from report: ValidationReport) -> String {
        let status = report.result.isCompliant ? "COMPLIANT" : "NON-COMPLIANT"
        let failureRatePercent = String(format: "%.1f", report.overallFailureRate * 100)
        let separator = String(repeating: "=", count: 60)
        let thinSeparator = String(repeating: "-", count: 60)

        var lines: [String] = []
        lines.append(separator)
        lines.append("VALIDATION REPORT")
        lines.append(separator)
        lines.append("")
        lines.append("Document: \(report.result.documentURL.lastPathComponent)")
        lines.append("Profile:  \(report.result.profileName)")
        lines.append("Status:   \(status)")
        lines.append("Duration: \(String(format: "%.3f", report.result.duration.duration))s")
        lines.append("")
        lines.append("Assertions: \(report.result.totalCount) total, " +
                     "\(report.result.passedCount) passed, " +
                     "\(report.result.failedCount) failed")
        lines.append("Rules:      \(report.ruleCount) evaluated, " +
                     "\(report.failedRuleCount) with failures")
        lines.append("Failure rate: \(failureRatePercent)%")

        if !report.summaries.isEmpty {
            lines.append("")
            lines.append(thinSeparator)
            lines.append("RULE SUMMARIES")
            lines.append(thinSeparator)

            for summary in report.summaries {
                let rateStr = String(format: "%.1f%%", summary.failureRate * 100)
                let statusMark = summary.failedCount > 0 ? "FAIL" : "PASS"
                lines.append("")
                lines.append("[\(statusMark)] \(summary.ruleID.uniqueID)")
                lines.append("  Clause: \(summary.ruleID.clause)")
                lines.append("  Passed: \(summary.passedCount), Failed: \(summary.failedCount), " +
                            "Total: \(summary.totalChecks) (\(rateStr) failure)")
                lines.append("  \(summary.ruleDescription)")
            }
        }

        lines.append("")
        lines.append(separator)

        return lines.joined(separator: "\n")
    }

    // MARK: - Escaping Utilities

    /// Escapes special XML characters.
    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    /// Escapes special HTML characters.
    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

// MARK: - ReportGeneratorError

/// Errors that can occur during report generation.
public enum ReportGeneratorError: Error, Sendable, Equatable {

    /// The report could not be encoded in the specified format.
    case encodingFailed(format: String)
}

// MARK: - LocalizedError

extension ReportGeneratorError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let format):
            return "Failed to encode report as \(format)"
        }
    }
}
