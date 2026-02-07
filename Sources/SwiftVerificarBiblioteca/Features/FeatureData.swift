import Foundation

/// A protocol for types that provide extractable feature data.
///
/// `FeatureData` consolidates the Java `FeaturesData` interface from
/// veraPDF-library. Types conforming to this protocol can convert
/// their data into a `FeatureNode` tree for inclusion in a
/// `FeatureExtractionResult`.
///
/// Implementors represent specific categories of PDF features
/// (fonts, color spaces, annotations, etc.) and know how to
/// serialize their data into the feature tree format.
///
/// ## Conformance
/// ```swift
/// struct FontFeatureData: FeatureData {
///     let fontName: String
///     let fontType: String
///     let encoding: String?
///
///     var featureType: FeatureType { .fonts }
///
///     func toFeatureNode() -> FeatureNode {
///         .branch(name: "Font", children: [
///             .leaf(name: "Name", value: fontName),
///             .leaf(name: "Type", value: fontType),
///             .leaf(name: "Encoding", value: encoding),
///         ], attributes: [:])
///     }
/// }
/// ```
public protocol FeatureData: Sendable {

    /// The feature type category this data belongs to.
    var featureType: FeatureType { get }

    /// Converts this feature data into a `FeatureNode` tree.
    ///
    /// The returned node typically represents a single instance of
    /// a feature (e.g., one font, one annotation, one ICC profile).
    ///
    /// - Returns: A `FeatureNode` representing this data.
    func toFeatureNode() -> FeatureNode
}
