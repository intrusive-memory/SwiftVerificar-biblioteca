import Foundation

/// Configuration for feature extraction.
///
/// `FeatureConfig` specifies which PDF features to extract and whether
/// to include sub-features. It consolidates the Java
/// `FeatureExtractorConfig` interface and `FeatureExtractorConfigImpl`
/// class from veraPDF-library.
///
/// By default, all feature types are enabled and sub-features are included.
///
/// ## Example
/// ```swift
/// // Extract only font and color space features
/// let config = FeatureConfig(
///     enabledFeatures: [.fonts, .colorSpaces],
///     includeSubFeatures: true
/// )
///
/// // Extract all features (default)
/// let fullConfig = FeatureConfig()
/// ```
public struct FeatureConfig: Sendable, Equatable, Hashable {

    /// The set of feature types to extract.
    ///
    /// Only features whose type is in this set will be extracted.
    /// Defaults to all feature types.
    public var enabledFeatures: Set<FeatureType>

    /// Whether to include sub-features within each extracted feature type.
    ///
    /// When `true`, the extractor descends into nested structures
    /// (e.g., extracting individual glyphs within a font, or individual
    /// annotations within a page). When `false`, only top-level feature
    /// information is included.
    ///
    /// Defaults to `true`.
    public var includeSubFeatures: Bool

    /// Creates a feature extraction configuration.
    ///
    /// - Parameters:
    ///   - enabledFeatures: The feature types to extract. Defaults to all types.
    ///   - includeSubFeatures: Whether to include sub-features. Defaults to `true`.
    public init(
        enabledFeatures: Set<FeatureType> = Set(FeatureType.allCases),
        includeSubFeatures: Bool = true
    ) {
        self.enabledFeatures = enabledFeatures
        self.includeSubFeatures = includeSubFeatures
    }

    /// Whether a given feature type is enabled in this configuration.
    ///
    /// - Parameter type: The feature type to check.
    /// - Returns: `true` if the feature type is in the enabled set.
    public func isEnabled(_ type: FeatureType) -> Bool {
        enabledFeatures.contains(type)
    }

    /// Returns a new configuration with the specified feature type added.
    ///
    /// - Parameter type: The feature type to enable.
    /// - Returns: A new `FeatureConfig` with the type added.
    public func enabling(_ type: FeatureType) -> FeatureConfig {
        var copy = self
        copy.enabledFeatures.insert(type)
        return copy
    }

    /// Returns a new configuration with the specified feature type removed.
    ///
    /// - Parameter type: The feature type to disable.
    /// - Returns: A new `FeatureConfig` with the type removed.
    public func disabling(_ type: FeatureType) -> FeatureConfig {
        var copy = self
        copy.enabledFeatures.remove(type)
        return copy
    }

    /// A configuration with no features enabled.
    ///
    /// Useful as a starting point to selectively enable specific features.
    public static let none = FeatureConfig(enabledFeatures: [], includeSubFeatures: false)

    /// A configuration with all features enabled and sub-features included.
    public static let all = FeatureConfig()
}

// MARK: - Codable

extension FeatureConfig: Codable {}

// MARK: - CustomStringConvertible

extension FeatureConfig: CustomStringConvertible {
    public var description: String {
        let featureNames = enabledFeatures
            .sorted { $0.rawValue < $1.rawValue }
            .map(\.displayName)
            .joined(separator: ", ")
        return "FeatureConfig(features: [\(featureNames)], includeSubFeatures: \(includeSubFeatures))"
    }
}
