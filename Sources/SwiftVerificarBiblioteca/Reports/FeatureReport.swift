import Foundation

/// A report of extracted PDF features with a textual summary.
///
/// `FeatureReport` wraps a ``FeatureExtractionResult`` and provides
/// a human-readable summary string describing the extraction outcome.
/// Use ``generate(from:)`` to create a report from an extraction result.
///
/// This is the Swift equivalent of Java's `FeaturesReport` in
/// veraPDF-library, consolidated into a single value type.
///
/// ## Example
/// ```swift
/// let extractionResult = try await extractor.extract(from: document)
/// let report = FeatureReport.generate(from: extractionResult)
/// print(report.summary)
/// ```
public struct FeatureReport: Sendable, Codable, Equatable {

    /// The underlying feature extraction result.
    public let extractionResult: FeatureExtractionResult

    /// A human-readable summary of the extraction outcome.
    ///
    /// Includes the document name, feature node count, and error count.
    public let summary: String

    /// Creates a new `FeatureReport`.
    ///
    /// - Parameters:
    ///   - extractionResult: The underlying extraction result.
    ///   - summary: A human-readable summary string.
    public init(extractionResult: FeatureExtractionResult, summary: String) {
        self.extractionResult = extractionResult
        self.summary = summary
    }

    /// Generates a `FeatureReport` from a ``FeatureExtractionResult``.
    ///
    /// Builds a summary string containing the document file name,
    /// total feature node count, and error count (if any).
    ///
    /// - Parameter result: The feature extraction result to summarize.
    /// - Returns: A new ``FeatureReport`` with a generated summary.
    public static func generate(from result: FeatureExtractionResult) -> FeatureReport {
        let documentName = result.documentURL.lastPathComponent
        let nodeCount = result.featureCount
        let errorCount = result.errorCount

        var parts: [String] = []
        parts.append("Feature extraction for \"\(documentName)\"")
        parts.append("\(nodeCount) feature node\(nodeCount == 1 ? "" : "s") extracted")

        if errorCount > 0 {
            parts.append("\(errorCount) error\(errorCount == 1 ? "" : "s") encountered")
            let failedTypes = result.failedFeatureTypes
                .map(\.rawValue)
                .sorted()
                .joined(separator: ", ")
            if !failedTypes.isEmpty {
                parts.append("Failed feature types: \(failedTypes)")
            }
        } else {
            parts.append("Extraction completed without errors")
        }

        let summary = parts.joined(separator: ". ") + "."

        return FeatureReport(extractionResult: result, summary: summary)
    }

    // MARK: - Computed Properties

    /// Whether the extraction completed without any errors.
    public var isComplete: Bool {
        extractionResult.isComplete
    }

    /// The total number of feature nodes in the extraction result.
    public var featureCount: Int {
        extractionResult.featureCount
    }

    /// The number of errors encountered during extraction.
    public var errorCount: Int {
        extractionResult.errorCount
    }

    /// The URL of the document from which features were extracted.
    public var documentURL: URL {
        extractionResult.documentURL
    }
}

// MARK: - CustomStringConvertible

extension FeatureReport: CustomStringConvertible {
    public var description: String {
        let status = isComplete ? "complete" : "\(errorCount) errors"
        return "FeatureReport(\(documentURL.lastPathComponent), " +
               "\(featureCount) nodes, \(status))"
    }
}
