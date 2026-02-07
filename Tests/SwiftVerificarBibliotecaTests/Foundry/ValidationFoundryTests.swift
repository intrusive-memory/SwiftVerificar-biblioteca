import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

// MARK: - Test Double

/// A mock foundry for testing the `ValidationFoundry` protocol conformance.
private struct MockFoundry: ValidationFoundry {
    let shouldThrowOnParser: Bool
    let shouldThrowOnValidator: Bool

    init(shouldThrowOnParser: Bool = false, shouldThrowOnValidator: Bool = false) {
        self.shouldThrowOnParser = shouldThrowOnParser
        self.shouldThrowOnValidator = shouldThrowOnValidator
    }

    func createParser(for url: URL) async throws -> any PDFParserProvider {
        if shouldThrowOnParser {
            throw VerificarError.parsingFailed(url: url, reason: "Mock failure")
        }
        return MockParser(url: url)
    }

    func createValidator(
        profileName: String,
        config: ValidatorConfiguration
    ) throws -> any PDFValidatorProvider {
        if shouldThrowOnValidator {
            throw VerificarError.profileNotFound(name: profileName)
        }
        return MockValidator(profileName: profileName)
    }

    func createMetadataFixer(
        config: MetadataFixerConfiguration
    ) -> any MetadataFixerProvider {
        MockFixer()
    }

    func createFeatureExtractor(
        config: FeatureExtractorConfiguration
    ) -> any FeatureExtractorProvider {
        MockExtractor()
    }
}

private struct MockParser: PDFParserProvider {
    let url: URL
    let info = ComponentInfo(
        name: "MockParser", version: "1.0", componentDescription: "Mock", provider: "Test"
    )
}

private struct MockValidator: PDFValidatorProvider {
    let profileName: String
    let info = ComponentInfo(
        name: "MockValidator", version: "1.0", componentDescription: "Mock", provider: "Test"
    )
}

private struct MockFixer: MetadataFixerProvider {
    let info = ComponentInfo(
        name: "MockFixer", version: "1.0", componentDescription: "Mock", provider: "Test"
    )
}

private struct MockExtractor: FeatureExtractorProvider {
    let info = ComponentInfo(
        name: "MockExtractor", version: "1.0", componentDescription: "Mock", provider: "Test"
    )
}

// MARK: - ValidationFoundry Protocol Tests

@Suite("ValidationFoundry Protocol Tests")
struct ValidationFoundryTests {

    @Test("Custom type can conform to ValidationFoundry")
    func customConformance() {
        let foundry = MockFoundry()
        // Just verifying the type checks compile
        let _: any ValidationFoundry = foundry
    }

    @Test("createParser returns a PDFParserProvider")
    func createParser() async throws {
        let foundry = MockFoundry()
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test.pdf")
        let parser = try await foundry.createParser(for: tempURL)

        #expect(parser.url == tempURL)
        #expect(parser.info.name == "MockParser")
    }

    @Test("createParser can throw errors")
    func createParserThrows() async {
        let foundry = MockFoundry(shouldThrowOnParser: true)
        let url = URL(fileURLWithPath: "/nonexistent.pdf")

        await #expect(throws: VerificarError.self) {
            _ = try await foundry.createParser(for: url)
        }
    }

    @Test("createValidator returns a PDFValidatorProvider")
    func createValidator() throws {
        let foundry = MockFoundry()
        let config = ValidatorConfiguration()
        let validator = try foundry.createValidator(profileName: "pdfua2", config: config)

        #expect(validator.profileName == "pdfua2")
        #expect(validator.info.name == "MockValidator")
    }

    @Test("createValidator can throw errors")
    func createValidatorThrows() {
        let foundry = MockFoundry(shouldThrowOnValidator: true)
        let config = ValidatorConfiguration()

        #expect(throws: VerificarError.self) {
            _ = try foundry.createValidator(profileName: "bad", config: config)
        }
    }

    @Test("createMetadataFixer returns a MetadataFixerProvider")
    func createMetadataFixer() {
        let foundry = MockFoundry()
        let config = MetadataFixerConfiguration()
        let fixer = foundry.createMetadataFixer(config: config)

        #expect(fixer.info.name == "MockFixer")
    }

    @Test("createFeatureExtractor returns a FeatureExtractorProvider")
    func createFeatureExtractor() {
        let foundry = MockFoundry()
        let config = FeatureExtractorConfiguration()
        let extractor = foundry.createFeatureExtractor(config: config)

        #expect(extractor.info.name == "MockExtractor")
    }

    @Test("ValidationFoundry is Sendable")
    func sendable() async {
        let foundry: any ValidationFoundry = MockFoundry()

        let name = await Task {
            foundry.self
        }.value

        // If this compiles, Sendable conformance is verified
        #expect(name is MockFoundry)
    }
}

// MARK: - ValidatorConfiguration Tests

@Suite("ValidatorConfiguration Tests")
struct ValidatorConfigurationTests {

    @Test("Default init has expected defaults")
    func defaultInit() {
        let config = ValidatorConfiguration()

        #expect(config.maxFailures == 0)
        #expect(config.recordPassedAssertions == false)
        #expect(config.logProgress == false)
    }

    @Test("Custom init stores all fields")
    func customInit() {
        let config = ValidatorConfiguration(
            maxFailures: 10,
            recordPassedAssertions: true,
            logProgress: true
        )

        #expect(config.maxFailures == 10)
        #expect(config.recordPassedAssertions == true)
        #expect(config.logProgress == true)
    }

    @Test("Equal instances are equal")
    func equality() {
        let config1 = ValidatorConfiguration(maxFailures: 5, recordPassedAssertions: true)
        let config2 = ValidatorConfiguration(maxFailures: 5, recordPassedAssertions: true)

        #expect(config1 == config2)
    }

    @Test("Different maxFailures makes unequal")
    func differentMaxFailures() {
        let config1 = ValidatorConfiguration(maxFailures: 5)
        let config2 = ValidatorConfiguration(maxFailures: 10)

        #expect(config1 != config2)
    }

    @Test("Different recordPassedAssertions makes unequal")
    func differentRecordPassed() {
        let config1 = ValidatorConfiguration(recordPassedAssertions: true)
        let config2 = ValidatorConfiguration(recordPassedAssertions: false)

        #expect(config1 != config2)
    }

    @Test("Different logProgress makes unequal")
    func differentLogProgress() {
        let config1 = ValidatorConfiguration(logProgress: true)
        let config2 = ValidatorConfiguration(logProgress: false)

        #expect(config1 != config2)
    }

    @Test("Is Hashable")
    func hashable() {
        let config1 = ValidatorConfiguration(maxFailures: 5)
        let config2 = ValidatorConfiguration(maxFailures: 5)

        #expect(config1.hashValue == config2.hashValue)

        var set: Set<ValidatorConfiguration> = [config1, config2]
        #expect(set.count == 1)
    }

    @Test("Encodes and decodes to JSON")
    func codable() throws {
        let original = ValidatorConfiguration(
            maxFailures: 42,
            recordPassedAssertions: true,
            logProgress: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ValidatorConfiguration.self, from: data)

        #expect(original == decoded)
    }

    @Test("Description with defaults")
    func descriptionDefaults() {
        let config = ValidatorConfiguration()

        #expect(config.description == "ValidatorConfiguration(maxFailures=0)")
    }

    @Test("Description with all options")
    func descriptionAllOptions() {
        let config = ValidatorConfiguration(
            maxFailures: 10,
            recordPassedAssertions: true,
            logProgress: true
        )

        #expect(config.description.contains("maxFailures=10"))
        #expect(config.description.contains("recordPassed"))
        #expect(config.description.contains("logProgress"))
    }

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let config = ValidatorConfiguration(maxFailures: 7)

        let value = await Task {
            config.maxFailures
        }.value

        #expect(value == 7)
    }
}

// MARK: - MetadataFixerConfiguration Tests

@Suite("MetadataFixerConfiguration Tests")
struct MetadataFixerConfigurationTests {

    @Test("Default init has expected defaults")
    func defaultInit() {
        let config = MetadataFixerConfiguration()

        #expect(config.fixInfoDictionary == true)
        #expect(config.fixXMPMetadata == true)
        #expect(config.syncInfoAndXMP == true)
    }

    @Test("Custom init stores all fields")
    func customInit() {
        let config = MetadataFixerConfiguration(
            fixInfoDictionary: false,
            fixXMPMetadata: true,
            syncInfoAndXMP: false
        )

        #expect(config.fixInfoDictionary == false)
        #expect(config.fixXMPMetadata == true)
        #expect(config.syncInfoAndXMP == false)
    }

    @Test("Equal instances are equal")
    func equality() {
        let config1 = MetadataFixerConfiguration(fixInfoDictionary: false, fixXMPMetadata: true)
        let config2 = MetadataFixerConfiguration(fixInfoDictionary: false, fixXMPMetadata: true)

        #expect(config1 == config2)
    }

    @Test("Different fixInfoDictionary makes unequal")
    func differentFixInfo() {
        let config1 = MetadataFixerConfiguration(fixInfoDictionary: true)
        let config2 = MetadataFixerConfiguration(fixInfoDictionary: false)

        #expect(config1 != config2)
    }

    @Test("Different fixXMPMetadata makes unequal")
    func differentFixXMP() {
        let config1 = MetadataFixerConfiguration(fixXMPMetadata: true)
        let config2 = MetadataFixerConfiguration(fixXMPMetadata: false)

        #expect(config1 != config2)
    }

    @Test("Different syncInfoAndXMP makes unequal")
    func differentSync() {
        let config1 = MetadataFixerConfiguration(syncInfoAndXMP: true)
        let config2 = MetadataFixerConfiguration(syncInfoAndXMP: false)

        #expect(config1 != config2)
    }

    @Test("Is Hashable")
    func hashable() {
        let config1 = MetadataFixerConfiguration()
        let config2 = MetadataFixerConfiguration()

        #expect(config1.hashValue == config2.hashValue)

        var set: Set<MetadataFixerConfiguration> = [config1, config2]
        #expect(set.count == 1)
    }

    @Test("Encodes and decodes to JSON")
    func codable() throws {
        let original = MetadataFixerConfiguration(
            fixInfoDictionary: false,
            fixXMPMetadata: true,
            syncInfoAndXMP: false
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MetadataFixerConfiguration.self, from: data)

        #expect(original == decoded)
    }

    @Test("Description with all enabled")
    func descriptionAllEnabled() {
        let config = MetadataFixerConfiguration()

        #expect(config.description.contains("fixInfo"))
        #expect(config.description.contains("fixXMP"))
        #expect(config.description.contains("syncInfoXMP"))
    }

    @Test("Description with none enabled")
    func descriptionNoneEnabled() {
        let config = MetadataFixerConfiguration(
            fixInfoDictionary: false,
            fixXMPMetadata: false,
            syncInfoAndXMP: false
        )

        #expect(config.description == "MetadataFixerConfiguration()")
    }

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let config = MetadataFixerConfiguration()

        let result = await Task {
            config.fixInfoDictionary
        }.value

        #expect(result == true)
    }
}

// MARK: - FeatureExtractorConfiguration Tests

@Suite("FeatureExtractorConfiguration Tests")
struct FeatureExtractorConfigurationTests {

    @Test("Default init includes all standard features")
    func defaultInit() {
        let config = FeatureExtractorConfiguration()

        #expect(config.enabledFeatures == FeatureExtractorConfiguration.allStandardFeatures)
        #expect(config.includeSubFeatures == true)
    }

    @Test("allStandardFeatures has expected count")
    func standardFeatureCount() {
        // Per TODO.md Phase 7, there are 19 feature types
        #expect(FeatureExtractorConfiguration.allStandardFeatures.count == 19)
    }

    @Test("allStandardFeatures contains expected values")
    func standardFeatureValues() {
        let features = FeatureExtractorConfiguration.allStandardFeatures

        #expect(features.contains("informationDictionary"))
        #expect(features.contains("metadata"))
        #expect(features.contains("documentSecurity"))
        #expect(features.contains("signatures"))
        #expect(features.contains("lowLevelInfo"))
        #expect(features.contains("embeddedFiles"))
        #expect(features.contains("iccProfiles"))
        #expect(features.contains("outputIntents"))
        #expect(features.contains("outlines"))
        #expect(features.contains("annotations"))
        #expect(features.contains("pages"))
        #expect(features.contains("graphicsStates"))
        #expect(features.contains("colorSpaces"))
        #expect(features.contains("patterns"))
        #expect(features.contains("shadings"))
        #expect(features.contains("xObjects"))
        #expect(features.contains("fonts"))
        #expect(features.contains("properties"))
        #expect(features.contains("interactiveFormFields"))
    }

    @Test("Custom init with subset of features")
    func customInit() {
        let config = FeatureExtractorConfiguration(
            enabledFeatures: ["fonts", "metadata"],
            includeSubFeatures: false
        )

        #expect(config.enabledFeatures.count == 2)
        #expect(config.enabledFeatures.contains("fonts"))
        #expect(config.enabledFeatures.contains("metadata"))
        #expect(config.includeSubFeatures == false)
    }

    @Test("Custom init with empty features")
    func emptyFeatures() {
        let config = FeatureExtractorConfiguration(enabledFeatures: [])

        #expect(config.enabledFeatures.isEmpty)
    }

    @Test("Equal instances are equal")
    func equality() {
        let config1 = FeatureExtractorConfiguration(enabledFeatures: ["fonts"])
        let config2 = FeatureExtractorConfiguration(enabledFeatures: ["fonts"])

        #expect(config1 == config2)
    }

    @Test("Different features make unequal")
    func differentFeatures() {
        let config1 = FeatureExtractorConfiguration(enabledFeatures: ["fonts"])
        let config2 = FeatureExtractorConfiguration(enabledFeatures: ["metadata"])

        #expect(config1 != config2)
    }

    @Test("Different includeSubFeatures makes unequal")
    func differentIncludeSub() {
        let config1 = FeatureExtractorConfiguration(includeSubFeatures: true)
        let config2 = FeatureExtractorConfiguration(includeSubFeatures: false)

        #expect(config1 != config2)
    }

    @Test("Is Hashable")
    func hashable() {
        let config1 = FeatureExtractorConfiguration(enabledFeatures: ["fonts"])
        let config2 = FeatureExtractorConfiguration(enabledFeatures: ["fonts"])

        #expect(config1.hashValue == config2.hashValue)
    }

    @Test("Encodes and decodes to JSON")
    func codable() throws {
        let original = FeatureExtractorConfiguration(
            enabledFeatures: ["fonts", "metadata", "pages"],
            includeSubFeatures: false
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FeatureExtractorConfiguration.self, from: data)

        #expect(original == decoded)
    }

    @Test("Description with features")
    func descriptionWithFeatures() {
        let config = FeatureExtractorConfiguration(
            enabledFeatures: ["fonts", "metadata"],
            includeSubFeatures: true
        )

        #expect(config.description.contains("2 features"))
        #expect(config.description.contains("includeSubFeatures"))
    }

    @Test("Description without sub-features")
    func descriptionWithoutSub() {
        let config = FeatureExtractorConfiguration(
            enabledFeatures: ["fonts"],
            includeSubFeatures: false
        )

        #expect(config.description.contains("1 features"))
        #expect(!config.description.contains("includeSubFeatures"))
    }

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let config = FeatureExtractorConfiguration(enabledFeatures: ["fonts"])

        let result = await Task {
            config.enabledFeatures
        }.value

        #expect(result.contains("fonts"))
    }
}
