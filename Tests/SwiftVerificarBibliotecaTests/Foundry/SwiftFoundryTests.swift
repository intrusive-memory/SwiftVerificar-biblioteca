import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("SwiftFoundry Tests")
struct SwiftFoundryTests {

    // MARK: - Initialization

    @Test("Default init creates foundry with default info")
    func defaultInit() {
        let foundry = SwiftFoundry()

        #expect(foundry.info.name == "SwiftFoundry")
        #expect(foundry.info.version == SwiftVerificarBiblioteca.version)
        #expect(foundry.info.componentDescription == "Default SwiftVerificar component factory")
        #expect(foundry.info.provider == "SwiftVerificar Project")
    }

    @Test("Custom init stores custom info")
    func customInit() {
        let customInfo = ComponentInfo(
            name: "CustomFoundry",
            version: "99.0.0",
            componentDescription: "Custom factory",
            provider: "Test Corp"
        )
        let foundry = SwiftFoundry(info: customInfo)

        #expect(foundry.info == customInfo)
    }

    // MARK: - ValidatorComponent Conformance

    @Test("Conforms to ValidatorComponent")
    func validatorComponentConformance() {
        let foundry = SwiftFoundry()
        let component: any ValidatorComponent = foundry

        #expect(component.info.name == "SwiftFoundry")
    }

    // MARK: - createParser

    @Test("createParser succeeds for readable file")
    func createParserReadableFile() async throws {
        let foundry = SwiftFoundry()

        // Create a temporary file so it exists
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).pdf")
        FileManager.default.createFile(atPath: tempFile.path, contents: Data())

        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }

        let parser = try await foundry.createParser(for: tempFile)

        #expect(parser.url == tempFile)
        #expect(parser.info.name == "SwiftPDFParser")
    }

    @Test("createParser throws for non-existent file")
    func createParserNonExistent() async {
        let foundry = SwiftFoundry()
        let url = URL(fileURLWithPath: "/nonexistent/path/to/file.pdf")

        await #expect(throws: VerificarError.self) {
            _ = try await foundry.createParser(for: url)
        }
    }

    @Test("createParser throws parsingFailed with descriptive reason")
    func createParserErrorMessage() async {
        let foundry = SwiftFoundry()
        let url = URL(fileURLWithPath: "/definitely/not/a/real/file.pdf")

        do {
            _ = try await foundry.createParser(for: url)
            Issue.record("Expected error was not thrown")
        } catch let error as VerificarError {
            switch error {
            case .parsingFailed(let errorURL, let reason):
                #expect(errorURL == url)
                #expect(reason.contains("not readable"))
            default:
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("createParser returns a Sendable PDFParserProvider")
    func createParserSendable() async throws {
        let foundry = SwiftFoundry()
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("sendable_\(UUID().uuidString).pdf")
        FileManager.default.createFile(atPath: tempFile.path, contents: Data())

        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }

        let parser = try await foundry.createParser(for: tempFile)

        let url = await Task {
            parser.url
        }.value

        #expect(url == tempFile)
    }

    // MARK: - createValidator

    @Test("createValidator succeeds with valid profile name")
    func createValidatorValid() throws {
        let foundry = SwiftFoundry()
        let config = ValidatorConfiguration()
        let validator = try foundry.createValidator(profileName: "pdfua2", config: config)

        #expect(validator.profileName == "pdfua2")
        #expect(validator.info.name == "SwiftPDFValidator")
    }

    @Test("createValidator throws for empty profile name")
    func createValidatorEmptyProfile() {
        let foundry = SwiftFoundry()
        let config = ValidatorConfiguration()

        #expect(throws: VerificarError.self) {
            _ = try foundry.createValidator(profileName: "", config: config)
        }
    }

    @Test("createValidator throws profileNotFound for empty name")
    func createValidatorErrorType() {
        let foundry = SwiftFoundry()
        let config = ValidatorConfiguration()

        do {
            _ = try foundry.createValidator(profileName: "", config: config)
            Issue.record("Expected error was not thrown")
        } catch let error as VerificarError {
            switch error {
            case .profileNotFound(let name):
                #expect(name == "")
            default:
                Issue.record("Expected profileNotFound, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("createValidator passes config to real validator")
    func createValidatorPassesConfig() throws {
        let foundry = SwiftFoundry()
        let config = ValidatorConfiguration(maxFailures: 42, recordPassedAssertions: true)
        let validator = try foundry.createValidator(profileName: "pdfa1b", config: config)

        // SwiftFoundry now returns a real SwiftPDFValidator.
        // ValidatorConfiguration is converted to ValidatorConfig.
        let real = validator as? SwiftPDFValidator
        #expect(real != nil)
        #expect(real?.config.maxFailures == 42)
        #expect(real?.config.recordPassedAssertions == true)
    }

    @Test("createValidator with various profile names")
    func createValidatorProfileNames() throws {
        let foundry = SwiftFoundry()
        let config = ValidatorConfiguration()

        let profiles = ["pdfua1", "pdfua2", "pdfa1a", "pdfa1b", "pdfa2a", "pdfa3b", "wcag22"]
        for name in profiles {
            let validator = try foundry.createValidator(profileName: name, config: config)
            #expect(validator.profileName == name)
        }
    }

    // MARK: - createMetadataFixer

    @Test("createMetadataFixer returns a fixer")
    func createMetadataFixer() {
        let foundry = SwiftFoundry()
        let config = MetadataFixerConfiguration()
        let fixer = foundry.createMetadataFixer(config: config)

        #expect(fixer.info.name == "StubMetadataFixer")
    }

    @Test("createMetadataFixer passes config to stub")
    func createMetadataFixerPassesConfig() {
        let foundry = SwiftFoundry()
        let config = MetadataFixerConfiguration(fixInfoDictionary: false, fixXMPMetadata: true, syncInfoAndXMP: false)
        let fixer = foundry.createMetadataFixer(config: config)

        let stub = fixer as? StubMetadataFixer
        #expect(stub?.config.fixInfoDictionary == false)
        #expect(stub?.config.fixXMPMetadata == true)
        #expect(stub?.config.syncInfoAndXMP == false)
    }

    @Test("createMetadataFixer with all-disabled config")
    func createMetadataFixerAllDisabled() {
        let foundry = SwiftFoundry()
        let config = MetadataFixerConfiguration(
            fixInfoDictionary: false,
            fixXMPMetadata: false,
            syncInfoAndXMP: false
        )
        let fixer = foundry.createMetadataFixer(config: config)

        #expect(fixer is StubMetadataFixer)
    }

    // MARK: - createFeatureExtractor

    @Test("createFeatureExtractor returns an extractor")
    func createFeatureExtractor() {
        let foundry = SwiftFoundry()
        let config = FeatureExtractorConfiguration()
        let extractor = foundry.createFeatureExtractor(config: config)

        #expect(extractor.info.name == "StubFeatureExtractor")
    }

    @Test("createFeatureExtractor passes config to stub")
    func createFeatureExtractorPassesConfig() {
        let foundry = SwiftFoundry()
        let config = FeatureExtractorConfiguration(enabledFeatures: ["fonts", "pages"], includeSubFeatures: false)
        let extractor = foundry.createFeatureExtractor(config: config)

        let stub = extractor as? StubFeatureExtractor
        #expect(stub?.config.enabledFeatures.count == 2)
        #expect(stub?.config.includeSubFeatures == false)
    }

    @Test("createFeatureExtractor with empty features")
    func createFeatureExtractorEmptyFeatures() {
        let foundry = SwiftFoundry()
        let config = FeatureExtractorConfiguration(enabledFeatures: [])
        let extractor = foundry.createFeatureExtractor(config: config)

        #expect(extractor is StubFeatureExtractor)
    }

    // MARK: - Equatable

    @Test("Default foundries are equal")
    func defaultEquality() {
        let foundry1 = SwiftFoundry()
        let foundry2 = SwiftFoundry()

        #expect(foundry1 == foundry2)
    }

    @Test("Foundries with different info are not equal")
    func differentInfoNotEqual() {
        let foundry1 = SwiftFoundry()
        let foundry2 = SwiftFoundry(
            info: ComponentInfo(
                name: "Other",
                version: "2.0",
                componentDescription: "Other factory",
                provider: "Other"
            )
        )

        #expect(foundry1 != foundry2)
    }

    // MARK: - Sendable

    @Test("SwiftFoundry is Sendable across task boundaries")
    func sendable() async {
        let foundry = SwiftFoundry()

        let name = await Task {
            foundry.info.name
        }.value

        #expect(name == "SwiftFoundry")
    }

    // MARK: - Integration: SwiftFoundry with Foundry actor

    @Test("SwiftFoundry can be registered with Foundry actor")
    func registeredWithFoundryActor() async throws {
        let registry = Foundry()
        let swiftFoundry = SwiftFoundry()

        await registry.register(swiftFoundry)
        let current = try await registry.current()

        #expect(current is SwiftFoundry)
    }

    @Test("Foundry actor delegates to SwiftFoundry correctly")
    func foundryActorDelegates() async throws {
        let registry = Foundry()
        await registry.register(SwiftFoundry())

        let current = try await registry.current()
        let config = ValidatorConfiguration(maxFailures: 5)
        let validator = try current.createValidator(profileName: "pdfua2", config: config)

        #expect(validator.profileName == "pdfua2")
    }

    @Test("Full round-trip: register, retrieve, create all components")
    func fullRoundTrip() async throws {
        let registry = Foundry()
        await registry.register(SwiftFoundry())

        let current = try await registry.current()

        // Create a temp file for parser
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("roundtrip_\(UUID().uuidString).pdf")
        FileManager.default.createFile(atPath: tempFile.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: tempFile) }

        // Parser
        let parser = try await current.createParser(for: tempFile)
        #expect(parser.url == tempFile)

        // Validator
        let validator = try current.createValidator(
            profileName: "pdfua2",
            config: ValidatorConfiguration()
        )
        #expect(validator.profileName == "pdfua2")

        // Fixer
        let fixer = current.createMetadataFixer(config: MetadataFixerConfiguration())
        #expect(fixer.info.name == "StubMetadataFixer")

        // Extractor
        let extractor = current.createFeatureExtractor(config: FeatureExtractorConfiguration())
        #expect(extractor.info.name == "StubFeatureExtractor")
    }
}
