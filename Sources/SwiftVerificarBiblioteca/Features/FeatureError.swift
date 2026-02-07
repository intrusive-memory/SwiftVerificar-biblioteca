import Foundation

/// An error encountered during feature extraction.
///
/// `FeatureError` captures failures that occur while extracting individual
/// PDF features. Unlike `VerificarError`, which represents top-level
/// operation failures, `FeatureError` is designed to be collected into
/// `FeatureExtractionResult.errors` so that partial results can still
/// be returned even when some features cannot be extracted.
///
/// Each error records the feature type that failed, a human-readable
/// message, and an optional underlying cause.
public struct FeatureError: Error, Sendable, Equatable, Hashable {

    /// The type of feature that could not be extracted.
    public let featureType: FeatureType

    /// A human-readable description of the extraction failure.
    public let message: String

    /// An optional identifier for the specific object that caused the failure.
    ///
    /// For example, a font name, an annotation index, or a page number.
    public let objectIdentifier: String?

    /// Creates a new feature extraction error.
    ///
    /// - Parameters:
    ///   - featureType: The feature type that failed.
    ///   - message: A description of the failure.
    ///   - objectIdentifier: An optional identifier for the failing object.
    public init(
        featureType: FeatureType,
        message: String,
        objectIdentifier: String? = nil
    ) {
        self.featureType = featureType
        self.message = message
        self.objectIdentifier = objectIdentifier
    }
}

// MARK: - Codable

extension FeatureError: Codable {}

// MARK: - LocalizedError

extension FeatureError: LocalizedError {
    public var errorDescription: String? {
        if let objectIdentifier {
            return "Feature extraction failed for \(featureType.displayName) " +
                   "[\(objectIdentifier)]: \(message)"
        }
        return "Feature extraction failed for \(featureType.displayName): \(message)"
    }
}

// MARK: - CustomStringConvertible

extension FeatureError: CustomStringConvertible {
    public var description: String {
        errorDescription ?? "Unknown FeatureError"
    }
}
