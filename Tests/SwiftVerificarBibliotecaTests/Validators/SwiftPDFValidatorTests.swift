import Testing
import Foundation
import SwiftVerificarValidationProfiles
@testable import SwiftVerificarBiblioteca

// MARK: - SwiftPDFValidator Tests

@Suite("SwiftPDFValidator Tests")
struct SwiftPDFValidatorTests {

    // MARK: - Initialization

    @Test("Default initializer stores profile name and default config")
    func defaultInitializer() {
        let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
        #expect(validator.profileName == "PDF/UA-2")
        #expect(validator.config == ValidatorConfig())
    }

    @Test("Custom config initializer stores all values")
    func customConfigInitializer() {
        let config = ValidatorConfig(
            maxFailures: 10,
            recordPassedAssertions: true,
            logProgress: true,
            timeout: 60.0,
            parallelValidation: false
        )
        let validator = SwiftPDFValidator(profileName: "PDF/A-2b", config: config)
        #expect(validator.profileName == "PDF/A-2b")
        #expect(validator.config == config)
        #expect(validator.config.maxFailures == 10)
        #expect(validator.config.recordPassedAssertions == true)
        #expect(validator.config.logProgress == true)
        #expect(validator.config.timeout == 60.0)
        #expect(validator.config.parallelValidation == false)
    }

    @Test("Profile name can be any string")
    func profileNameVariants() {
        let names = ["PDF/UA-1", "PDF/UA-2", "PDF/A-1a", "PDF/A-2b", "PDF/A-3u", "WCAG-2.2", "Custom"]
        for name in names {
            let validator = SwiftPDFValidator(profileName: name)
            #expect(validator.profileName == name)
        }
    }

    @Test("Empty profile name is allowed")
    func emptyProfileName() {
        let validator = SwiftPDFValidator(profileName: "")
        #expect(validator.profileName == "")
    }

    // MARK: - PDFValidator Conformance

    @Test("Conforms to PDFValidator protocol")
    func conformsToPDFValidator() {
        let validator = SwiftPDFValidator(profileName: "Test")
        let _: any PDFValidator = validator
        // Compilation proves conformance
        #expect(validator.profileName == "Test")
    }

    @Test("validate(document:) throws configurationError (placeholder)")
    func validateDocumentThrowsPlaceholder() async {
        let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
        let document = MockParsedDocument()
        await #expect(throws: VerificarError.self) {
            _ = try await validator.validate(document)
        }
    }

    @Test("validate(document:) throws specific configurationError")
    func validateDocumentThrowsSpecificError() async {
        let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
        let document = MockParsedDocument()
        do {
            _ = try await validator.validate(document)
            Issue.record("Expected configurationError to be thrown")
        } catch let error as VerificarError {
            switch error {
            case .configurationError(let reason):
                #expect(reason.contains("not yet available"))
            default:
                Issue.record("Expected configurationError, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(error)")
        }
    }

    @Test("validate(contentsOf:) throws configurationError (placeholder)")
    func validateURLThrowsPlaceholder() async {
        let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
        let url = URL(fileURLWithPath: "/tmp/nonexistent.pdf")
        await #expect(throws: VerificarError.self) {
            _ = try await validator.validate(contentsOf: url)
        }
    }

    @Test("validate(contentsOf:) throws specific configurationError about parser")
    func validateURLThrowsParserError() async {
        let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
        let url = URL(fileURLWithPath: "/tmp/nonexistent.pdf")
        do {
            _ = try await validator.validate(contentsOf: url)
            Issue.record("Expected configurationError to be thrown")
        } catch let error as VerificarError {
            switch error {
            case .configurationError(let reason):
                #expect(reason.contains("parser"))
            default:
                Issue.record("Expected configurationError, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(error)")
        }
    }

    // MARK: - ValidatorComponent Conformance

    @Test("Conforms to ValidatorComponent protocol")
    func conformsToValidatorComponent() {
        let validator = SwiftPDFValidator(profileName: "Test")
        let component: any ValidatorComponent = validator
        #expect(component.info.name == "SwiftPDFValidator")
    }

    @Test("ComponentInfo has correct name")
    func componentInfoName() {
        let validator = SwiftPDFValidator(profileName: "Test")
        #expect(validator.info.name == "SwiftPDFValidator")
    }

    @Test("ComponentInfo has correct version")
    func componentInfoVersion() {
        let validator = SwiftPDFValidator(profileName: "Test")
        #expect(validator.info.version == SwiftVerificarBiblioteca.version)
    }

    @Test("ComponentInfo description includes profile name")
    func componentInfoDescription() {
        let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
        #expect(validator.info.componentDescription.contains("PDF/UA-2"))
    }

    @Test("ComponentInfo has correct provider")
    func componentInfoProvider() {
        let validator = SwiftPDFValidator(profileName: "Test")
        #expect(validator.info.provider == "SwiftVerificar Project")
    }

    // MARK: - Equatable

    @Test("Two validators with same profile and config are equal")
    func equatable() {
        let a = SwiftPDFValidator(profileName: "PDF/UA-2")
        let b = SwiftPDFValidator(profileName: "PDF/UA-2")
        #expect(a == b)
    }

    @Test("Validators with different profile names are not equal")
    func notEqualProfileName() {
        let a = SwiftPDFValidator(profileName: "PDF/UA-1")
        let b = SwiftPDFValidator(profileName: "PDF/UA-2")
        #expect(a != b)
    }

    @Test("Validators with different configs are not equal")
    func notEqualConfig() {
        let a = SwiftPDFValidator(profileName: "Test", config: ValidatorConfig(maxFailures: 5))
        let b = SwiftPDFValidator(profileName: "Test", config: ValidatorConfig(maxFailures: 10))
        #expect(a != b)
    }

    @Test("Validators with same profile but different timeout are not equal")
    func notEqualTimeout() {
        let a = SwiftPDFValidator(profileName: "Test", config: ValidatorConfig(timeout: 30.0))
        let b = SwiftPDFValidator(profileName: "Test", config: ValidatorConfig(timeout: 60.0))
        #expect(a != b)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes profile name")
    func descriptionIncludesProfile() {
        let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
        #expect(validator.description.contains("PDF/UA-2"))
    }

    @Test("Description includes SwiftPDFValidator prefix")
    func descriptionPrefix() {
        let validator = SwiftPDFValidator(profileName: "Test")
        #expect(validator.description.hasPrefix("SwiftPDFValidator("))
    }

    @Test("Description includes config info")
    func descriptionIncludesConfig() {
        let validator = SwiftPDFValidator(
            profileName: "Test",
            config: ValidatorConfig(maxFailures: 5)
        )
        #expect(validator.description.contains("maxFailures=5"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let validator = SwiftPDFValidator(profileName: "SendableTest")
        let name = await Task {
            validator.profileName
        }.value
        #expect(name == "SendableTest")
    }

    @Test("Config is preserved across task boundaries")
    func configSendable() async {
        let config = ValidatorConfig(maxFailures: 42, timeout: 99.0)
        let validator = SwiftPDFValidator(profileName: "Test", config: config)
        let result = await Task {
            validator.config
        }.value
        #expect(result == config)
    }

    // MARK: - Used as existential

    @Test("Can be used as existential PDFValidator")
    func existentialUsage() async {
        let validator: any PDFValidator = SwiftPDFValidator(profileName: "Test")
        #expect(validator.profileName == "Test")
        #expect(validator.config == ValidatorConfig())
    }

    @Test("Can be used as existential ValidatorComponent")
    func existentialComponentUsage() {
        let validator: any ValidatorComponent = SwiftPDFValidator(profileName: "Test")
        #expect(validator.info.name == "SwiftPDFValidator")
    }

    @Test("Can be stored in array of PDFValidator existentials")
    func existentialArray() {
        let validators: [any PDFValidator] = [
            SwiftPDFValidator(profileName: "PDF/UA-1"),
            SwiftPDFValidator(profileName: "PDF/UA-2"),
        ]
        #expect(validators.count == 2)
        #expect(validators[0].profileName == "PDF/UA-1")
        #expect(validators[1].profileName == "PDF/UA-2")
    }

    // MARK: - Integration with existing types

    @Test("Config isFastFail works through validator")
    func configFastFailThroughValidator() {
        let validator = SwiftPDFValidator(
            profileName: "Test",
            config: ValidatorConfig(maxFailures: 5)
        )
        #expect(validator.config.isFastFail == true)
    }

    @Test("Config hasTimeout works through validator")
    func configTimeoutThroughValidator() {
        let validator = SwiftPDFValidator(
            profileName: "Test",
            config: ValidatorConfig(timeout: 30.0)
        )
        #expect(validator.config.hasTimeout == true)
    }

    @Test("Default config through validator has expected defaults")
    func defaultConfigThroughValidator() {
        let validator = SwiftPDFValidator(profileName: "Test")
        #expect(validator.config.maxFailures == 0)
        #expect(validator.config.recordPassedAssertions == false)
        #expect(validator.config.logProgress == false)
        #expect(validator.config.timeout == nil)
        #expect(validator.config.parallelValidation == true)
    }
}
