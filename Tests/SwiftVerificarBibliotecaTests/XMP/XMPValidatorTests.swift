import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("XMPValidator Tests")
struct XMPValidatorTests {

    // MARK: - Test Helpers

    private func makePDFAMetadata(part: String, conformance: String) -> XMPMetadata {
        let pkg = XMPPackage(
            namespace: XMPProperty.Namespace.pdfaID,
            prefix: "pdfaid",
            properties: [
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "part", value: part),
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "conformance", value: conformance),
            ]
        )
        return XMPMetadata(packages: [pkg])
    }

    private func makePDFUAMetadata(part: String) -> XMPMetadata {
        let pkg = XMPPackage(
            namespace: XMPProperty.Namespace.pdfuaID,
            prefix: "pdfuaid",
            properties: [
                XMPProperty(namespace: XMPProperty.Namespace.pdfuaID, name: "part", value: part),
            ]
        )
        return XMPMetadata(packages: [pkg])
    }

    // MARK: - Initialization

    @Test("Default init creates validator")
    func defaultInit() {
        let validator = XMPValidator()
        #expect(validator.description == "XMPValidator()")
    }

    // MARK: - General Validation (no profile)

    @Test("Empty metadata produces warning")
    func emptyMetadataWarning() {
        let validator = XMPValidator()
        let issues = validator.validate(metadata: XMPMetadata())
        #expect(issues.contains { $0.isWarning && $0.message.contains("no packages") })
    }

    @Test("Non-empty metadata produces no structural warnings")
    func nonEmptyMetadata() {
        let pkg = XMPPackage(
            namespace: "ns",
            prefix: "p",
            properties: [XMPProperty(namespace: "ns", name: "n", value: "v")]
        )
        let md = XMPMetadata(packages: [pkg])
        let validator = XMPValidator()
        let issues = validator.validate(metadata: md)
        #expect(issues.isEmpty)
    }

    @Test("Duplicate namespaces produce warning")
    func duplicateNamespaces() {
        let p1 = XMPPackage(namespace: "ns", prefix: "p1")
        let p2 = XMPPackage(namespace: "ns", prefix: "p2")
        let md = XMPMetadata(packages: [p1, p2])
        let validator = XMPValidator()
        let issues = validator.validate(metadata: md)
        #expect(issues.contains { $0.isWarning && $0.message.contains("Duplicate") })
    }

    @Test("No duplicate namespace warning for unique namespaces")
    func uniqueNamespaces() {
        let p1 = XMPPackage(namespace: "ns1", prefix: "p1")
        let p2 = XMPPackage(namespace: "ns2", prefix: "p2")
        let md = XMPMetadata(packages: [p1, p2])
        let validator = XMPValidator()
        let issues = validator.validate(metadata: md)
        let dupeWarnings = issues.filter { $0.message.contains("Duplicate") }
        #expect(dupeWarnings.isEmpty)
    }

    // MARK: - Structural Validation

    @Test("validateStructure on empty metadata returns warning")
    func validateStructureEmpty() {
        let validator = XMPValidator()
        let issues = validator.validateStructure(XMPMetadata())
        #expect(!issues.isEmpty)
        #expect(issues[0].isWarning)
    }

    @Test("validateStructure on non-empty metadata returns empty")
    func validateStructureNonEmpty() {
        let pkg = XMPPackage(namespace: "ns", prefix: "p")
        let md = XMPMetadata(packages: [pkg])
        let validator = XMPValidator()
        let issues = validator.validateStructure(md)
        #expect(issues.isEmpty)
    }

    // MARK: - PDF/A Compliance

    @Test("Valid PDF/A-2u passes compliance check")
    func validPDFA() {
        let md = makePDFAMetadata(part: "2", conformance: "u")
        let validator = XMPValidator()
        let issues = validator.validatePDFACompliance(md)
        #expect(issues.isEmpty)
    }

    @Test("Missing PDF/A identification fails compliance check")
    func missingPDFA() {
        let md = XMPMetadata()
        let validator = XMPValidator()
        let issues = validator.validatePDFACompliance(md)
        #expect(issues.contains { $0.isError && $0.message.contains("Missing PDF/A") })
    }

    @Test("Invalid PDF/A part fails compliance check")
    func invalidPDFAPart() {
        let md = makePDFAMetadata(part: "5", conformance: "a")
        let validator = XMPValidator()
        let issues = validator.validatePDFACompliance(md)
        #expect(issues.contains { $0.isError && $0.message.contains("Invalid PDF/A part") })
    }

    @Test("Invalid PDF/A conformance fails compliance check")
    func invalidPDFAConformance() {
        let md = makePDFAMetadata(part: "2", conformance: "x")
        let validator = XMPValidator()
        let issues = validator.validatePDFACompliance(md)
        #expect(issues.contains { $0.isError && $0.message.contains("Invalid PDF/A conformance") })
    }

    @Test("PDF/A-1b passes compliance check")
    func pdfa1b() {
        let md = makePDFAMetadata(part: "1", conformance: "b")
        let validator = XMPValidator()
        let issues = validator.validatePDFACompliance(md)
        #expect(issues.isEmpty)
    }

    @Test("PDF/A-3a passes compliance check")
    func pdfa3a() {
        let md = makePDFAMetadata(part: "3", conformance: "a")
        let validator = XMPValidator()
        let issues = validator.validatePDFACompliance(md)
        #expect(issues.isEmpty)
    }

    @Test("PDF/A-4e passes compliance check")
    func pdfa4e() {
        let md = makePDFAMetadata(part: "4", conformance: "e")
        let validator = XMPValidator()
        let issues = validator.validatePDFACompliance(md)
        #expect(issues.isEmpty)
    }

    @Test("PDF/A-4f passes compliance check")
    func pdfa4f() {
        let md = makePDFAMetadata(part: "4", conformance: "f")
        let validator = XMPValidator()
        let issues = validator.validatePDFACompliance(md)
        #expect(issues.isEmpty)
    }

    // MARK: - PDF/UA Compliance

    @Test("Valid PDF/UA-1 passes compliance check")
    func validPDFUA1() {
        let md = makePDFUAMetadata(part: "1")
        let validator = XMPValidator()
        let issues = validator.validatePDFUACompliance(md)
        #expect(issues.isEmpty)
    }

    @Test("Valid PDF/UA-2 passes compliance check")
    func validPDFUA2() {
        let md = makePDFUAMetadata(part: "2")
        let validator = XMPValidator()
        let issues = validator.validatePDFUACompliance(md)
        #expect(issues.isEmpty)
    }

    @Test("Missing PDF/UA identification fails compliance check")
    func missingPDFUA() {
        let md = XMPMetadata()
        let validator = XMPValidator()
        let issues = validator.validatePDFUACompliance(md)
        #expect(issues.contains { $0.isError && $0.message.contains("Missing PDF/UA") })
    }

    @Test("Invalid PDF/UA part fails compliance check")
    func invalidPDFUAPart() {
        let md = makePDFUAMetadata(part: "3")
        let validator = XMPValidator()
        let issues = validator.validatePDFUACompliance(md)
        #expect(issues.contains { $0.isError && $0.message.contains("Invalid PDF/UA part") })
    }

    // MARK: - Profile-Based Validation

    @Test("PDF/A profile triggers PDF/A compliance checks")
    func pdfaProfileValidation() {
        let md = XMPMetadata()
        let validator = XMPValidator()
        let issues = validator.validate(metadata: md, profile: "PDF/A-2u")
        let pdfaErrors = issues.filter { $0.message.contains("PDF/A") }
        #expect(!pdfaErrors.isEmpty)
    }

    @Test("PDF/UA profile triggers PDF/UA compliance checks")
    func pdfuaProfileValidation() {
        let md = XMPMetadata()
        let validator = XMPValidator()
        let issues = validator.validate(metadata: md, profile: "PDF/UA-2")
        let pdfuaErrors = issues.filter { $0.message.contains("PDF/UA") }
        #expect(!pdfuaErrors.isEmpty)
    }

    @Test("pdfa lowercase profile triggers PDF/A checks")
    func pdfaLowercaseProfile() {
        let md = XMPMetadata()
        let validator = XMPValidator()
        let issues = validator.validate(metadata: md, profile: "pdfa-2u")
        let pdfaErrors = issues.filter { $0.message.contains("PDF/A") }
        #expect(!pdfaErrors.isEmpty)
    }

    @Test("pdfua lowercase profile triggers PDF/UA checks")
    func pdfuaLowercaseProfile() {
        let md = XMPMetadata()
        let validator = XMPValidator()
        let issues = validator.validate(metadata: md, profile: "pdfua-2")
        let pdfuaErrors = issues.filter { $0.message.contains("PDF/UA") }
        #expect(!pdfuaErrors.isEmpty)
    }

    @Test("Nil profile only runs structural validation")
    func nilProfile() {
        let md = makePDFAMetadata(part: "2", conformance: "u")
        let validator = XMPValidator()
        let issues = validator.validate(metadata: md, profile: nil)
        // Should only have structural checks, which pass for non-empty metadata
        #expect(issues.isEmpty)
    }

    @Test("Unrecognized profile only runs structural validation")
    func unrecognizedProfile() {
        let pkg = XMPPackage(namespace: "ns", prefix: "p")
        let md = XMPMetadata(packages: [pkg])
        let validator = XMPValidator()
        let issues = validator.validate(metadata: md, profile: "something-else")
        #expect(issues.isEmpty)
    }

    // MARK: - Combined Profile Validation

    @Test("Valid metadata passes both PDF/A and PDF/UA profile")
    func validCombinedProfile() {
        let pdfaPkg = XMPPackage(
            namespace: XMPProperty.Namespace.pdfaID,
            prefix: "pdfaid",
            properties: [
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "part", value: "2"),
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "conformance", value: "u"),
            ]
        )
        let pdfuaPkg = XMPPackage(
            namespace: XMPProperty.Namespace.pdfuaID,
            prefix: "pdfuaid",
            properties: [
                XMPProperty(namespace: XMPProperty.Namespace.pdfuaID, name: "part", value: "2"),
            ]
        )
        let md = XMPMetadata(packages: [pdfaPkg, pdfuaPkg])
        let validator = XMPValidator()

        let pdfaIssues = validator.validate(metadata: md, profile: "PDF/A-2u")
        #expect(pdfaIssues.isEmpty)

        let pdfuaIssues = validator.validate(metadata: md, profile: "PDF/UA-2")
        #expect(pdfuaIssues.isEmpty)
    }

    // MARK: - Sendable

    @Test("XMPValidator is Sendable across task boundaries")
    func sendable() async {
        let validator = XMPValidator()
        let result = await Task { validator.description }.value
        #expect(result == "XMPValidator()")
    }
}
