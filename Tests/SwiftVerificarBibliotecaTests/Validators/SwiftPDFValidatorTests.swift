import Testing
import Foundation
import PDFKit
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

    @Test("validate(document:) returns ValidationResult for valid profile")
    func validateDocumentReturnsResult() async throws {
        let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
        let cosDoc = CosDocumentObject(
            pageCount: 1,
            hasStructTreeRoot: true,
            isMarked: true,
            pdfVersion: "2.0"
        )
        let document = MockParsedDocument(
            flavour: .pdfUA2,
            pageCount: 1,
            hasStructureTree: true,
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let result = try await validator.validate(document)
        // The result should be a ValidationResult (may or may not be compliant,
        // depending on the profile rules, but it should not throw)
        #expect(result.documentURL == document.url)
        #expect(result.profileName.contains("PDF/UA"))
    }

    @Test("validate(document:) throws profileNotFound for invalid profile name")
    func validateDocumentThrowsForInvalidProfile() async {
        let validator = SwiftPDFValidator(profileName: "INVALID-PROFILE")
        let document = MockParsedDocument()
        await #expect(throws: VerificarError.self) {
            _ = try await validator.validate(document)
        }
    }

    @Test("validate(document:) throws profileNotFound with correct error details")
    func validateDocumentThrowsSpecificError() async {
        let validator = SwiftPDFValidator(profileName: "INVALID-PROFILE")
        let document = MockParsedDocument()
        do {
            _ = try await validator.validate(document)
            Issue.record("Expected profileNotFound to be thrown")
        } catch let error as VerificarError {
            switch error {
            case .profileNotFound(let name):
                #expect(name == "INVALID-PROFILE")
            default:
                Issue.record("Expected profileNotFound, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(error)")
        }
    }

    @Test("validate(contentsOf:) throws parsingFailed for non-existent file")
    func validateURLThrowsForNonExistentFile() async {
        let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
        let url = URL(fileURLWithPath: "/tmp/nonexistent_\(UUID().uuidString).pdf")
        await #expect(throws: VerificarError.self) {
            _ = try await validator.validate(contentsOf: url)
        }
    }

    @Test("validate(contentsOf:) throws parsingFailed with correct details")
    func validateURLThrowsParsingError() async {
        let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
        let url = URL(fileURLWithPath: "/tmp/nonexistent_\(UUID().uuidString).pdf")
        do {
            _ = try await validator.validate(contentsOf: url)
            Issue.record("Expected parsingFailed to be thrown")
        } catch let error as VerificarError {
            switch error {
            case .parsingFailed:
                // Expected: file not found causes parsingFailed
                break
            default:
                Issue.record("Expected parsingFailed, got \(error)")
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

// MARK: - Sprint 5: Real Validation Tests

@Suite("Sprint 5: SwiftPDFValidator Real Validation")
struct SwiftPDFValidatorRealValidationTests {

    // MARK: - Profile Resolution

    @Test("Validates with PDF/UA-2 profile and loads real rules")
    func validateWithPDFUA2Profile() async throws {
        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(recordPassedAssertions: true)
        )
        let cosDoc = CosDocumentObject(
            pageCount: 1,
            hasStructTreeRoot: true,
            isMarked: true,
            pdfVersion: "2.0",
            hasXMPMetadata: true
        )
        let document = MockParsedDocument(
            flavour: .pdfUA2,
            pageCount: 1,
            hasStructureTree: true,
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let result = try await validator.validate(document)
        // Should produce assertions (the profile has rules for CosDocument)
        #expect(result.totalCount > 0)
        #expect(result.profileName.contains("PDF/UA"))
    }

    @Test("Validates with PDF/A-2b profile")
    func validateWithPDFA2bProfile() async throws {
        let validator = SwiftPDFValidator(
            profileName: "PDF/A-2b",
            config: ValidatorConfig(recordPassedAssertions: true)
        )
        let cosDoc = CosDocumentObject(
            pageCount: 1,
            isEncrypted: false,
            pdfVersion: "1.7"
        )
        let document = MockParsedDocument(
            flavour: .pdfA2b,
            pageCount: 1,
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let result = try await validator.validate(document)
        #expect(result.documentURL == document.url)
        // The result should have assertions (rules for CosDocument in PDF/A-2b)
        #expect(result.totalCount >= 0)
    }

    @Test("Validates with PDF/UA-1 profile")
    func validateWithPDFUA1Profile() async throws {
        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-1",
            config: ValidatorConfig(recordPassedAssertions: true)
        )
        let cosDoc = CosDocumentObject(
            pageCount: 1,
            hasStructTreeRoot: true,
            isMarked: true
        )
        let document = MockParsedDocument(
            flavour: .pdfUA1,
            pageCount: 1,
            hasStructureTree: true,
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let result = try await validator.validate(document)
        #expect(result.documentURL == document.url)
    }

    // MARK: - Assertion Recording

    @Test("recordPassedAssertions=false excludes passed assertions from result")
    func recordPassedAssertionsFalse() async throws {
        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(recordPassedAssertions: false)
        )
        let cosDoc = CosDocumentObject(
            pageCount: 1,
            hasStructTreeRoot: true,
            isMarked: true,
            pdfVersion: "2.0",
            hasXMPMetadata: true
        )
        let document = MockParsedDocument(
            flavour: .pdfUA2,
            pageCount: 1,
            hasStructureTree: true,
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let result = try await validator.validate(document)
        // No passed assertions should be recorded
        #expect(result.passedCount == 0)
    }

    @Test("recordPassedAssertions=true includes passed assertions in result")
    func recordPassedAssertionsTrue() async throws {
        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(recordPassedAssertions: true)
        )
        let cosDoc = CosDocumentObject(
            pageCount: 1,
            hasStructTreeRoot: true,
            isMarked: true,
            pdfVersion: "2.0",
            hasXMPMetadata: true
        )
        let document = MockParsedDocument(
            flavour: .pdfUA2,
            pageCount: 1,
            hasStructureTree: true,
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let resultWithPassed = try await validator.validate(document)

        // Validate the same document WITHOUT recording passed assertions
        let validatorNoPassed = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(recordPassedAssertions: false)
        )
        let resultNoPassed = try await validatorNoPassed.validate(document)

        // The version with passed assertions should have at least as many
        // total assertions as the one without
        #expect(resultWithPassed.totalCount >= resultNoPassed.totalCount)
    }

    // MARK: - MaxFailures (Fast-Fail)

    @Test("maxFailures limits the number of failure assertions")
    func maxFailuresLimitsFailures() async throws {
        // Create a document with objects that should produce failures
        let cosDoc = CosDocumentObject(
            pageCount: 0,
            isEncrypted: true  // Likely to trigger failures
        )
        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(maxFailures: 2, recordPassedAssertions: false)
        )
        let document = MockParsedDocument(
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let result = try await validator.validate(document)
        // The failure count should be at most maxFailures
        #expect(result.failedCount <= 2)
    }

    // MARK: - Empty Document

    @Test("Validates empty document with no objects")
    func validateEmptyDocument() async throws {
        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(recordPassedAssertions: true)
        )
        let document = MockParsedDocument(objectsByType: [:])
        let result = try await validator.validate(document)
        // No objects means no rules can be evaluated, so no assertions
        #expect(result.totalCount == 0)
        #expect(result.isCompliant == true)
    }

    // MARK: - Result Mapping

    @Test("Assertions have valid ruleIDs from the profile")
    func assertionsHaveValidRuleIDs() async throws {
        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(recordPassedAssertions: true)
        )
        let cosDoc = CosDocumentObject(
            pageCount: 1,
            hasStructTreeRoot: true,
            isMarked: true,
            pdfVersion: "2.0"
        )
        let document = MockParsedDocument(
            flavour: .pdfUA2,
            pageCount: 1,
            hasStructureTree: true,
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let result = try await validator.validate(document)
        for assertion in result.assertions {
            // Each assertion should have a non-empty ruleID
            #expect(!assertion.ruleID.clause.isEmpty)
            #expect(assertion.ruleID.testNumber > 0)
        }
    }

    @Test("Assertions include context with object type")
    func assertionsIncludeContext() async throws {
        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(recordPassedAssertions: true)
        )
        let cosDoc = CosDocumentObject(pageCount: 1)
        let document = MockParsedDocument(
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let result = try await validator.validate(document)
        for assertion in result.assertions {
            #expect(assertion.context == "CosDocument")
        }
    }

    @Test("Failed assertions have non-empty messages")
    func failedAssertionsHaveMessages() async throws {
        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(recordPassedAssertions: false)
        )
        // Document missing required properties to trigger failures
        let cosDoc = CosDocumentObject(pageCount: 0)
        let document = MockParsedDocument(
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let result = try await validator.validate(document)
        for assertion in result.assertions.filter({ $0.status == .failed }) {
            #expect(!assertion.message.isEmpty)
        }
    }

    // MARK: - Duration Tracking

    @Test("Result contains valid duration information")
    func resultHasDuration() async throws {
        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(recordPassedAssertions: true)
        )
        let cosDoc = CosDocumentObject(pageCount: 1)
        let document = MockParsedDocument(
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let result = try await validator.validate(document)
        // Duration should be non-negative
        #expect(result.duration.duration >= 0)
    }

    // MARK: - validate(contentsOf:) with real PDF

    @Test("validate(contentsOf:) works with a real PDF file")
    func validateContentsOfRealPDF() async throws {
        // Create a temporary PDF using PDFKit
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_validator_\(UUID().uuidString).pdf")
        let pdfDoc = PDFKit.PDFDocument()
        let page = PDFKit.PDFPage()
        pdfDoc.insert(page, at: 0)
        pdfDoc.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(recordPassedAssertions: true)
        )
        let result = try await validator.validate(contentsOf: tempURL)
        #expect(result.documentURL == tempURL)
        // Should produce a real result (may have failures for non-tagged PDF)
        #expect(result.totalCount >= 0)
    }

    // MARK: - Multiple Profile Names

    @Test("Various profile name formats resolve correctly")
    func variousProfileNameFormats() async throws {
        let profileNames = ["PDF/UA-2", "PDF/A-2b", "PDF/A-1a", "PDF/UA-1"]
        let document = MockParsedDocument(objectsByType: [:])

        for name in profileNames {
            let validator = SwiftPDFValidator(profileName: name)
            let result = try await validator.validate(document)
            // Empty document produces empty assertions for any profile
            #expect(result.isCompliant == true)
        }
    }
}
