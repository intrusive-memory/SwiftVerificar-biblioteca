import Foundation

/// Default Swift implementation of `ValidationFoundry`.
///
/// `SwiftFoundry` creates component instances backed by the
/// SwiftVerificar dependency packages. It is the standard foundry
/// that applications should register at startup.
///
/// This is the Swift equivalent of Java's default `VeraPDFFoundry`
/// implementation in veraPDF-library.
///
/// ## Usage
///
/// ```swift
/// await Foundry.shared.register(SwiftFoundry())
/// ```
///
/// ## Current Limitations
///
/// In this sprint the foundry returns stub implementations because the
/// full `PDFParser`, `PDFValidator`, `MetadataFixer`, and
/// `FeatureExtractor` types have not yet been built. Once those types
/// are defined (Sprints 5-8), `SwiftFoundry` will be updated to return
/// real implementations.
public struct SwiftFoundry: ValidationFoundry, Equatable {

    /// Component metadata for this foundry.
    public let info: ComponentInfo

    /// Creates a new `SwiftFoundry`.
    ///
    /// - Parameter info: Optional custom component info. If `nil`, the
    ///   default metadata is used.
    public init(
        info: ComponentInfo = ComponentInfo(
            name: "SwiftFoundry",
            version: SwiftVerificarBiblioteca.version,
            componentDescription: "Default SwiftVerificar component factory",
            provider: "SwiftVerificar Project"
        )
    ) {
        self.info = info
    }

    // MARK: - ValidationFoundry

    public func createParser(for url: URL) async throws -> any PDFParserProvider {
        // Guard: the file must be reachable
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw VerificarError.parsingFailed(
                url: url,
                reason: "File not readable at path: \(url.path)"
            )
        }
        return SwiftPDFParser(url: url)
    }

    public func createValidator(
        profileName: String,
        config: ValidatorConfiguration
    ) throws -> any PDFValidatorProvider {
        guard !profileName.isEmpty else {
            throw VerificarError.profileNotFound(name: profileName)
        }
        // Convert ValidatorConfiguration to ValidatorConfig
        let validatorConfig = ValidatorConfig(
            maxFailures: config.maxFailures,
            recordPassedAssertions: config.recordPassedAssertions,
            logProgress: config.logProgress
        )
        return SwiftPDFValidator(profileName: profileName, config: validatorConfig)
    }

    public func createMetadataFixer(
        config: MetadataFixerConfiguration
    ) -> any MetadataFixerProvider {
        StubMetadataFixer(config: config)
    }

    public func createFeatureExtractor(
        config: FeatureExtractorConfiguration
    ) -> any FeatureExtractorProvider {
        SwiftFeatureExtractor(config: config)
    }

    // MARK: - Equatable

    public static func == (lhs: SwiftFoundry, rhs: SwiftFoundry) -> Bool {
        lhs.info == rhs.info
    }
}

// MARK: - ValidatorComponent

extension SwiftFoundry: ValidatorComponent {}

// MARK: - Provider Protocol Conformances

/// `SwiftPDFParser` already has `url: URL` and conforms to `ValidatorComponent`
/// (which provides `info: ComponentInfo`), satisfying `PDFParserProvider`.
extension SwiftPDFParser: PDFParserProvider {}

/// `SwiftPDFValidator` already has `profileName: String` and conforms to
/// `ValidatorComponent` (which provides `info: ComponentInfo`), satisfying
/// `PDFValidatorProvider`.
extension SwiftPDFValidator: PDFValidatorProvider {}

// MARK: - Stub Implementations (internal, to be replaced in later sprints)

/// Stub parser returned by `SwiftFoundry` until Sprint 6 provides the real type.
struct StubPDFParser: PDFParserProvider {
    let url: URL
    let info: ComponentInfo

    init(url: URL) {
        self.url = url
        self.info = ComponentInfo(
            name: "StubPDFParser",
            version: SwiftVerificarBiblioteca.version,
            componentDescription: "Placeholder PDF parser",
            provider: "SwiftVerificar Project"
        )
    }
}

/// Stub validator returned by `SwiftFoundry` until Sprint 5 provides the real type.
struct StubPDFValidator: PDFValidatorProvider {
    let profileName: String
    let config: ValidatorConfiguration
    let info: ComponentInfo

    init(profileName: String, config: ValidatorConfiguration) {
        self.profileName = profileName
        self.config = config
        self.info = ComponentInfo(
            name: "StubPDFValidator",
            version: SwiftVerificarBiblioteca.version,
            componentDescription: "Placeholder PDF validator",
            provider: "SwiftVerificar Project"
        )
    }
}

/// Stub metadata fixer returned by `SwiftFoundry` until Sprint 8 provides the real type.
struct StubMetadataFixer: MetadataFixerProvider {
    let config: MetadataFixerConfiguration
    let info: ComponentInfo

    init(config: MetadataFixerConfiguration) {
        self.config = config
        self.info = ComponentInfo(
            name: "StubMetadataFixer",
            version: SwiftVerificarBiblioteca.version,
            componentDescription: "Placeholder metadata fixer",
            provider: "SwiftVerificar Project"
        )
    }
}

/// Stub feature extractor returned by `SwiftFoundry` until Sprint 7 provides the real type.
struct StubFeatureExtractor: FeatureExtractorProvider {
    let config: FeatureExtractorConfiguration
    let info: ComponentInfo

    init(config: FeatureExtractorConfiguration) {
        self.config = config
        self.info = ComponentInfo(
            name: "StubFeatureExtractor",
            version: SwiftVerificarBiblioteca.version,
            componentDescription: "Placeholder feature extractor",
            provider: "SwiftVerificar Project"
        )
    }
}
