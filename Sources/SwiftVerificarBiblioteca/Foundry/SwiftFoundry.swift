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
/// ## Implementation
///
/// The foundry returns real implementations for all four component types:
/// `SwiftPDFParser`, `SwiftPDFValidator`, `SwiftMetadataFixer`, and
/// `SwiftFeatureExtractor`. These are fully wired to the SwiftVerificar
/// dependency packages.
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
        let fixerConfig = FixerConfig(
            fixInfoDictionary: config.fixInfoDictionary,
            fixXMPMetadata: config.fixXMPMetadata,
            syncInfoAndXMP: config.syncInfoAndXMP
        )
        return SwiftMetadataFixer(config: fixerConfig)
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

