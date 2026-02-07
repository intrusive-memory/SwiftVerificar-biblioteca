import Foundation

/// Enumeration of extractable PDF feature types.
///
/// Each case represents a category of features that can be extracted
/// from a PDF document during feature extraction. This enum consolidates
/// the Java `FeatureObjectType` enum from veraPDF-library.
///
/// The 19 cases cover all major structural and content aspects of a PDF:
/// document-level metadata, security, embedded resources, visual content,
/// and interactive elements.
public enum FeatureType: String, CaseIterable, Sendable, Codable, Equatable, Hashable {

    /// PDF Information Dictionary entries (Title, Author, Subject, etc.).
    case informationDictionary

    /// XMP metadata streams.
    case metadata

    /// Document security settings (encryption, permissions).
    case documentSecurity

    /// Digital signatures.
    case signatures

    /// Low-level PDF info (version, page count, incremental updates).
    case lowLevelInfo

    /// Embedded file streams.
    case embeddedFiles

    /// ICC color profiles.
    case iccProfiles

    /// Output intent dictionaries.
    case outputIntents

    /// Document outline (bookmarks) hierarchy.
    case outlines

    /// Annotation dictionaries.
    case annotations

    /// Page dictionaries and their properties.
    case pages

    /// Extended graphics state dictionaries.
    case graphicsStates

    /// Color space definitions.
    case colorSpaces

    /// Pattern definitions (tiling and shading patterns).
    case patterns

    /// Shading dictionaries.
    case shadings

    /// XObject resources (images, forms).
    case xObjects

    /// Font resources and their programs.
    case fonts

    /// Marked-content properties.
    case properties

    /// Interactive form field (AcroForm) dictionaries.
    case interactiveFormFields
}

// MARK: - CustomStringConvertible

extension FeatureType: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Display Name

extension FeatureType {
    /// A human-readable display name for this feature type.
    ///
    /// Returns a formatted string suitable for UI display or reports.
    public var displayName: String {
        switch self {
        case .informationDictionary: return "Information Dictionary"
        case .metadata: return "Metadata"
        case .documentSecurity: return "Document Security"
        case .signatures: return "Signatures"
        case .lowLevelInfo: return "Low-Level Info"
        case .embeddedFiles: return "Embedded Files"
        case .iccProfiles: return "ICC Profiles"
        case .outputIntents: return "Output Intents"
        case .outlines: return "Outlines"
        case .annotations: return "Annotations"
        case .pages: return "Pages"
        case .graphicsStates: return "Graphics States"
        case .colorSpaces: return "Color Spaces"
        case .patterns: return "Patterns"
        case .shadings: return "Shadings"
        case .xObjects: return "XObjects"
        case .fonts: return "Fonts"
        case .properties: return "Properties"
        case .interactiveFormFields: return "Interactive Form Fields"
        }
    }
}
