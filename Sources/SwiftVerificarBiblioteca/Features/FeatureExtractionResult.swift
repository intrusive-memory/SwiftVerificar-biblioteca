import Foundation

/// The result of a feature extraction operation on a PDF document.
///
/// `FeatureExtractionResult` contains the extracted feature tree,
/// any errors encountered during extraction, and metadata about the
/// source document. It consolidates the Java `FeatureExtractionResult`
/// from veraPDF-library.
///
/// Feature extraction is designed to be *partial-success*: even if some
/// features cannot be extracted (e.g., a corrupt font or invalid ICC
/// profile), the remaining features are still returned. Errors for
/// individual features are collected in the `errors` array.
///
/// ## Example
/// ```swift
/// let result = FeatureExtractionResult(
///     documentURL: pdfURL,
///     features: .branch(name: "Document", children: [...], attributes: [:]),
///     errors: []
/// )
/// print("Extracted \(result.features.nodeCount) feature nodes")
/// ```
public struct FeatureExtractionResult: Sendable, Codable, Equatable {

    /// The URL of the document from which features were extracted.
    public let documentURL: URL

    /// The root of the extracted feature tree.
    ///
    /// This is typically a `.branch` node named "Document" containing
    /// child nodes for each extracted feature category.
    public let features: FeatureNode

    /// Errors encountered during extraction.
    ///
    /// Each error corresponds to a feature type or specific object that
    /// could not be extracted. An empty array means extraction completed
    /// without errors.
    public let errors: [FeatureError]

    /// Creates a feature extraction result.
    ///
    /// - Parameters:
    ///   - documentURL: The URL of the source document.
    ///   - features: The root of the extracted feature tree.
    ///   - errors: Any errors encountered during extraction.
    public init(
        documentURL: URL,
        features: FeatureNode,
        errors: [FeatureError] = []
    ) {
        self.documentURL = documentURL
        self.features = features
        self.errors = errors
    }

    /// Whether the extraction completed without any errors.
    public var isComplete: Bool {
        errors.isEmpty
    }

    /// The total number of feature nodes in the result tree.
    public var featureCount: Int {
        features.nodeCount
    }

    /// The number of errors encountered during extraction.
    public var errorCount: Int {
        errors.count
    }

    /// The set of feature types that produced errors.
    public var failedFeatureTypes: Set<FeatureType> {
        Set(errors.map(\.featureType))
    }

    /// Returns errors filtered to a specific feature type.
    ///
    /// - Parameter type: The feature type to filter by.
    /// - Returns: An array of errors for the specified type.
    public func errors(for type: FeatureType) -> [FeatureError] {
        errors.filter { $0.featureType == type }
    }
}

// MARK: - CustomStringConvertible

extension FeatureExtractionResult: CustomStringConvertible {
    public var description: String {
        let status = isComplete ? "complete" : "\(errorCount) errors"
        return "FeatureExtractionResult(\(documentURL.lastPathComponent), " +
               "\(featureCount) nodes, \(status))"
    }
}
