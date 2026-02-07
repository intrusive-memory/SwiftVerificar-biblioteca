import Testing
import Foundation
import SwiftVerificarValidationProfiles
@testable import SwiftVerificarBiblioteca

// MARK: - Test Doubles

/// A mock ParsedDocument for testing validators.
struct MockParsedDocument: ParsedDocument {
    let url: URL
    let flavour: PDFFlavour?
    let pageCount: Int
    let metadata: DocumentMetadata?
    let hasStructureTree: Bool
    let objectsByType: [String: [any ValidationObject]]

    init(
        url: URL = URL(fileURLWithPath: "/tmp/test.pdf"),
        flavour: PDFFlavour? = nil,
        pageCount: Int = 0,
        metadata: DocumentMetadata? = nil,
        hasStructureTree: Bool = false,
        objectsByType: [String: [any ValidationObject]] = [:]
    ) {
        self.url = url
        self.flavour = flavour
        self.pageCount = pageCount
        self.metadata = metadata
        self.hasStructureTree = hasStructureTree
        self.objectsByType = objectsByType
    }

    func objects(ofType objectType: String) -> [any ValidationObject] {
        objectsByType[objectType] ?? []
    }
}

/// A mock ValidationObject for testing.
struct MockValidationObject: ValidationObject {
    let validationProperties: [String: String]
    let location: PDFLocation?

    init(
        properties: [String: String] = [:],
        location: PDFLocation? = nil
    ) {
        self.validationProperties = properties
        self.location = location
    }
}

/// A mock PDFValidator for testing the protocol contract.
struct MockPDFValidator: PDFValidator {
    let profileName: String
    let config: ValidatorConfig
    var shouldThrow: Bool = false
    var mockResult: ValidationResult?

    init(
        profileName: String = "TestProfile",
        config: ValidatorConfig = ValidatorConfig(),
        shouldThrow: Bool = false,
        mockResult: ValidationResult? = nil
    ) {
        self.profileName = profileName
        self.config = config
        self.shouldThrow = shouldThrow
        self.mockResult = mockResult
    }

    func validate(_ document: any ParsedDocument) async throws -> ValidationResult {
        if shouldThrow {
            throw VerificarError.validationFailed(reason: "Mock validation error")
        }
        if let result = mockResult {
            return result
        }
        return ValidationResult.compliant(
            profileName: profileName,
            documentURL: document.url,
            duration: ValidationDuration.zero()
        )
    }

    func validate(contentsOf url: URL) async throws -> ValidationResult {
        if shouldThrow {
            throw VerificarError.validationFailed(reason: "Mock validation error")
        }
        if let result = mockResult {
            return result
        }
        return ValidationResult.compliant(
            profileName: profileName,
            documentURL: url,
            duration: ValidationDuration.zero()
        )
    }
}

// MARK: - PDFValidator Protocol Tests

@Suite("PDFValidator Protocol Tests")
struct PDFValidatorProtocolTests {

    @Test("Mock validator returns compliant result for document")
    func mockValidatorCompliantDocument() async throws {
        let validator = MockPDFValidator(profileName: "PDF/UA-2")
        let document = MockParsedDocument()
        let result = try await validator.validate(document)
        #expect(result.isCompliant == true)
        #expect(result.profileName == "PDF/UA-2")
    }

    @Test("Mock validator returns compliant result for URL")
    func mockValidatorCompliantURL() async throws {
        let validator = MockPDFValidator(profileName: "PDF/A-2b")
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let result = try await validator.validate(contentsOf: url)
        #expect(result.isCompliant == true)
        #expect(result.profileName == "PDF/A-2b")
    }

    @Test("Mock validator throws when configured to throw")
    func mockValidatorThrows() async {
        let validator = MockPDFValidator(shouldThrow: true)
        let document = MockParsedDocument()
        await #expect(throws: VerificarError.self) {
            _ = try await validator.validate(document)
        }
    }

    @Test("Mock validator throws on URL validate when configured")
    func mockValidatorThrowsURL() async {
        let validator = MockPDFValidator(shouldThrow: true)
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        await #expect(throws: VerificarError.self) {
            _ = try await validator.validate(contentsOf: url)
        }
    }

    @Test("Mock validator returns custom result")
    func mockValidatorCustomResult() async throws {
        let customResult = ValidationResult(
            profileName: "Custom",
            documentURL: URL(fileURLWithPath: "/tmp/custom.pdf"),
            isCompliant: false,
            assertions: [],
            duration: ValidationDuration.zero()
        )
        let validator = MockPDFValidator(mockResult: customResult)
        let document = MockParsedDocument()
        let result = try await validator.validate(document)
        #expect(result.isCompliant == false)
        #expect(result.profileName == "Custom")
    }

    @Test("PDFValidator exposes profileName property")
    func profileNameProperty() {
        let validator: any PDFValidator = MockPDFValidator(profileName: "PDF/UA-1")
        #expect(validator.profileName == "PDF/UA-1")
    }

    @Test("PDFValidator exposes config property")
    func configProperty() {
        let config = ValidatorConfig(maxFailures: 5)
        let validator: any PDFValidator = MockPDFValidator(config: config)
        #expect(validator.config == config)
    }

    @Test("Validator can be stored as existential type")
    func existentialType() async throws {
        let validator: any PDFValidator = MockPDFValidator(profileName: "Test")
        let document = MockParsedDocument()
        let result = try await validator.validate(document)
        #expect(result.isCompliant == true)
    }

    @Test("Multiple validators can be stored in an array")
    func arrayOfValidators() {
        let validators: [any PDFValidator] = [
            MockPDFValidator(profileName: "PDF/UA-1"),
            MockPDFValidator(profileName: "PDF/UA-2"),
            MockPDFValidator(profileName: "PDF/A-2b"),
        ]
        #expect(validators.count == 3)
        #expect(validators[0].profileName == "PDF/UA-1")
        #expect(validators[1].profileName == "PDF/UA-2")
        #expect(validators[2].profileName == "PDF/A-2b")
    }

    @Test("Mock validator is Sendable")
    func sendable() async {
        let validator = MockPDFValidator(profileName: "SendableTest")
        let name = await Task {
            validator.profileName
        }.value
        #expect(name == "SendableTest")
    }
}

// MARK: - ParsedDocument Protocol Tests

@Suite("ParsedDocument Protocol Tests")
struct ParsedDocumentProtocolTests {

    @Test("MockParsedDocument stores url")
    func url() {
        let url = URL(fileURLWithPath: "/tmp/myfile.pdf")
        let doc = MockParsedDocument(url: url)
        #expect(doc.url == url)
    }

    @Test("MockParsedDocument stores flavour")
    func flavour() {
        let doc = MockParsedDocument(flavour: .pdfUA2)
        #expect(doc.flavour == .pdfUA2)
    }

    @Test("MockParsedDocument flavour can be nil")
    func flavourNil() {
        let doc = MockParsedDocument(flavour: nil)
        #expect(doc.flavour == nil)
    }

    @Test("MockParsedDocument returns objects by type")
    func objectsByType() {
        let obj = MockValidationObject(properties: ["key": "value"])
        let doc = MockParsedDocument(objectsByType: ["CosDocument": [obj]])
        let objects = doc.objects(ofType: "CosDocument")
        #expect(objects.count == 1)
    }

    @Test("MockParsedDocument returns empty array for unknown type")
    func objectsUnknownType() {
        let doc = MockParsedDocument()
        let objects = doc.objects(ofType: "Unknown")
        #expect(objects.isEmpty)
    }

    @Test("MockParsedDocument returns multiple objects")
    func multipleObjects() {
        let obj1 = MockValidationObject(properties: ["a": "1"])
        let obj2 = MockValidationObject(properties: ["b": "2"])
        let doc = MockParsedDocument(objectsByType: ["PDPage": [obj1, obj2]])
        let objects = doc.objects(ofType: "PDPage")
        #expect(objects.count == 2)
    }

    @Test("MockParsedDocument is Sendable")
    func sendable() async {
        let doc = MockParsedDocument()
        let url = await Task {
            doc.url
        }.value
        #expect(url == doc.url)
    }
}

// MARK: - ValidationObject Protocol Tests

@Suite("ValidationObject Protocol Tests")
struct ValidationObjectProtocolTests {

    @Test("MockValidationObject stores properties")
    func properties() {
        let obj = MockValidationObject(properties: ["Alt": "Figure description"])
        #expect(obj.validationProperties["Alt"] == "Figure description")
    }

    @Test("MockValidationObject empty properties")
    func emptyProperties() {
        let obj = MockValidationObject()
        #expect(obj.validationProperties.isEmpty)
    }

    @Test("MockValidationObject stores location")
    func location() {
        let loc = PDFLocation(pageNumber: 3, structureID: "SE-5")
        let obj = MockValidationObject(location: loc)
        #expect(obj.location == loc)
    }

    @Test("MockValidationObject location can be nil")
    func locationNil() {
        let obj = MockValidationObject()
        #expect(obj.location == nil)
    }

    @Test("MockValidationObject is Sendable")
    func sendable() async {
        let obj = MockValidationObject(properties: ["key": "val"])
        let result = await Task {
            obj.validationProperties
        }.value
        #expect(result["key"] == "val")
    }

    @Test("Multiple properties are stored correctly")
    func multipleProperties() {
        let obj = MockValidationObject(properties: [
            "Alt": "text",
            "ActualText": "more text",
            "Lang": "en-US",
        ])
        #expect(obj.validationProperties.count == 3)
        #expect(obj.validationProperties["Alt"] == "text")
        #expect(obj.validationProperties["ActualText"] == "more text")
        #expect(obj.validationProperties["Lang"] == "en-US")
    }
}
