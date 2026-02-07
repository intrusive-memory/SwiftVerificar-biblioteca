import Foundation

/// Protocol for validation component factories.
///
/// A `ValidationFoundry` knows how to create the four major subsystem
/// components: parser, validator, metadata fixer, and feature extractor.
/// Implementations provide concrete instances backed by the SwiftVerificar
/// dependency packages.
///
/// This is the Swift equivalent of Java's `VeraPDFFoundry` interface in
/// veraPDF-library, consolidated with `AbstractFoundry` (default implementation)
/// and `VeraFoundryProvider` (provider interface).
///
/// ## Thread Safety
///
/// All conforming types must be `Sendable`. Factory methods are synchronous
/// where possible; asynchronous when the created component requires I/O
/// during initialization.
public protocol ValidationFoundry: Sendable {

    /// Create a parser for a PDF document at the given URL.
    ///
    /// - Parameter url: The file URL of the PDF document to parse.
    /// - Returns: A parser ready to parse the document.
    /// - Throws: `VerificarError.parsingFailed` if the parser cannot be
    ///   initialized (e.g., file not found).
    func createParser(for url: URL) async throws -> any PDFParserProvider

    /// Create a validator for the given profile and configuration.
    ///
    /// - Parameters:
    ///   - profileName: The name of the validation profile to use.
    ///   - config: Configuration controlling validator behavior.
    /// - Returns: A validator ready to validate documents.
    /// - Throws: `VerificarError.profileNotFound` if the profile cannot be loaded.
    func createValidator(
        profileName: String,
        config: ValidatorConfiguration
    ) throws -> any PDFValidatorProvider

    /// Create a metadata fixer with the given configuration.
    ///
    /// - Parameter config: Configuration controlling fixer behavior.
    /// - Returns: A metadata fixer ready to repair documents.
    func createMetadataFixer(
        config: MetadataFixerConfiguration
    ) -> any MetadataFixerProvider

    /// Create a feature extractor with the given configuration.
    ///
    /// - Parameter config: Configuration controlling which features to extract.
    /// - Returns: A feature extractor ready to analyze documents.
    func createFeatureExtractor(
        config: FeatureExtractorConfiguration
    ) -> any FeatureExtractorProvider
}

// MARK: - Provider Protocols

/// Protocol for PDF parser providers.
///
/// Captures the minimal contract needed by the foundry system.
public protocol PDFParserProvider: Sendable, ValidatorComponent {

    /// The URL of the document being parsed.
    var url: URL { get }
}

/// Protocol for PDF validator providers.
///
/// Captures the minimal contract needed by the foundry system.
public protocol PDFValidatorProvider: Sendable, ValidatorComponent {

    /// The name of the validation profile in use.
    var profileName: String { get }
}

/// Protocol for metadata fixer providers.
///
/// Captures the minimal contract needed by the foundry system.
public protocol MetadataFixerProvider: Sendable, ValidatorComponent {}

/// Protocol for feature extractor providers.
///
/// Captures the minimal contract needed by the foundry system.
public protocol FeatureExtractorProvider: Sendable, ValidatorComponent {}

// MARK: - Configuration Types

/// Configuration for the PDF validator.
///
/// Controls how the validator behaves during a validation run.
/// This is the Swift equivalent of Java's `ValidatorConfig` interface.
///
/// In later sprints this may be replaced or extended by `ValidatorConfig`.
public struct ValidatorConfiguration: Sendable, Equatable, Hashable, Codable {

    /// Maximum number of failures before the validator stops.
    ///
    /// A value of `0` means the validator runs to completion regardless
    /// of how many failures are encountered.
    public var maxFailures: Int

    /// Whether to record passed assertions in the result.
    ///
    /// Set to `true` if you need a complete log of all checked rules,
    /// not just the failures.
    public var recordPassedAssertions: Bool

    /// Whether to log progress during validation.
    public var logProgress: Bool

    /// Creates a new `ValidatorConfiguration` with the given settings.
    ///
    /// - Parameters:
    ///   - maxFailures: Maximum failures before stopping. Defaults to `0` (unlimited).
    ///   - recordPassedAssertions: Whether to record passed assertions. Defaults to `false`.
    ///   - logProgress: Whether to log progress. Defaults to `false`.
    public init(
        maxFailures: Int = 0,
        recordPassedAssertions: Bool = false,
        logProgress: Bool = false
    ) {
        self.maxFailures = maxFailures
        self.recordPassedAssertions = recordPassedAssertions
        self.logProgress = logProgress
    }
}

// MARK: - ValidatorConfiguration CustomStringConvertible

extension ValidatorConfiguration: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        parts.append("maxFailures=\(maxFailures)")
        if recordPassedAssertions { parts.append("recordPassed") }
        if logProgress { parts.append("logProgress") }
        return "ValidatorConfiguration(\(parts.joined(separator: ", ")))"
    }
}

/// Configuration for the metadata fixer.
///
/// Controls which kinds of metadata the fixer will attempt to repair.
/// This is the Swift equivalent of Java's `MetadataFixerConfig` interface.
///
/// In later sprints this may be replaced or extended by `FixerConfig`.
public struct MetadataFixerConfiguration: Sendable, Equatable, Hashable, Codable {

    /// Whether to fix the document's Info dictionary.
    public var fixInfoDictionary: Bool

    /// Whether to fix the document's XMP metadata.
    public var fixXMPMetadata: Bool

    /// Whether to synchronize the Info dictionary and XMP metadata.
    public var syncInfoAndXMP: Bool

    /// Creates a new `MetadataFixerConfiguration`.
    ///
    /// - Parameters:
    ///   - fixInfoDictionary: Whether to fix the Info dictionary. Defaults to `true`.
    ///   - fixXMPMetadata: Whether to fix XMP metadata. Defaults to `true`.
    ///   - syncInfoAndXMP: Whether to synchronize Info and XMP. Defaults to `true`.
    public init(
        fixInfoDictionary: Bool = true,
        fixXMPMetadata: Bool = true,
        syncInfoAndXMP: Bool = true
    ) {
        self.fixInfoDictionary = fixInfoDictionary
        self.fixXMPMetadata = fixXMPMetadata
        self.syncInfoAndXMP = syncInfoAndXMP
    }
}

// MARK: - MetadataFixerConfiguration CustomStringConvertible

extension MetadataFixerConfiguration: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        if fixInfoDictionary { parts.append("fixInfo") }
        if fixXMPMetadata { parts.append("fixXMP") }
        if syncInfoAndXMP { parts.append("syncInfoXMP") }
        return "MetadataFixerConfiguration(\(parts.joined(separator: ", ")))"
    }
}

/// Configuration for the feature extractor.
///
/// Controls which PDF features the extractor will report on.
/// This is the Swift equivalent of Java's `FeatureExtractorConfig` interface.
///
/// In later sprints this may be replaced or extended by `FeatureConfig`.
public struct FeatureExtractorConfiguration: Sendable, Equatable, Hashable, Codable {

    /// The set of feature types to extract.
    public var enabledFeatures: Set<String>

    /// Whether to include sub-features for each enabled feature.
    public var includeSubFeatures: Bool

    /// Creates a new `FeatureExtractorConfiguration`.
    ///
    /// - Parameters:
    ///   - enabledFeatures: Feature type identifiers to extract. Defaults to all standard features.
    ///   - includeSubFeatures: Whether to include sub-features. Defaults to `true`.
    public init(
        enabledFeatures: Set<String> = FeatureExtractorConfiguration.allStandardFeatures,
        includeSubFeatures: Bool = true
    ) {
        self.enabledFeatures = enabledFeatures
        self.includeSubFeatures = includeSubFeatures
    }

    /// The full set of standard feature type identifiers.
    ///
    /// These correspond to the `FeatureType` enum cases that will
    /// be defined in Sprint 7.
    public static let allStandardFeatures: Set<String> = [
        "informationDictionary",
        "metadata",
        "documentSecurity",
        "signatures",
        "lowLevelInfo",
        "embeddedFiles",
        "iccProfiles",
        "outputIntents",
        "outlines",
        "annotations",
        "pages",
        "graphicsStates",
        "colorSpaces",
        "patterns",
        "shadings",
        "xObjects",
        "fonts",
        "properties",
        "interactiveFormFields",
    ]
}

// MARK: - FeatureExtractorConfiguration CustomStringConvertible

extension FeatureExtractorConfiguration: CustomStringConvertible {
    public var description: String {
        let featureCount = enabledFeatures.count
        let sub = includeSubFeatures ? ", includeSubFeatures" : ""
        return "FeatureExtractorConfiguration(\(featureCount) features\(sub))"
    }
}
