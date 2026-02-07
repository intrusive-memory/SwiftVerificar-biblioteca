import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("MainXMPPackage Tests")
struct MainXMPPackageTests {

    // MARK: - Initialization

    @Test("Default init creates empty package")
    func defaultInit() {
        let pkg = MainXMPPackage()
        #expect(pkg.properties.isEmpty)
        #expect(pkg.pdfaIdentification == nil)
        #expect(pkg.pdfuaIdentification == nil)
    }

    @Test("Init with properties")
    func initWithProperties() {
        let prop = XMPProperty(namespace: "ns", name: "title", value: "Test")
        let pkg = MainXMPPackage(properties: [prop])
        #expect(pkg.properties.count == 1)
    }

    @Test("Init with explicit PDF/A identification")
    func initWithPDFAIdentification() {
        let pdfa = PDFAIdentification(part: 2, conformance: "u")
        let pkg = MainXMPPackage(pdfaIdentification: pdfa)
        #expect(pkg.pdfaIdentification?.part == 2)
        #expect(pkg.pdfaIdentification?.conformance == "u")
    }

    @Test("Init with explicit PDF/UA identification")
    func initWithPDFUAIdentification() {
        let pdfua = PDFUAIdentification(part: 2)
        let pkg = MainXMPPackage(pdfuaIdentification: pdfua)
        #expect(pkg.pdfuaIdentification?.part == 2)
    }

    @Test("Init with all fields")
    func fullInit() {
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v")
        let pdfa = PDFAIdentification(part: 1, conformance: "b")
        let pdfua = PDFUAIdentification(part: 1)
        let pkg = MainXMPPackage(
            properties: [prop],
            pdfaIdentification: pdfa,
            pdfuaIdentification: pdfua
        )
        #expect(pkg.properties.count == 1)
        #expect(pkg.pdfaIdentification != nil)
        #expect(pkg.pdfuaIdentification != nil)
    }

    // MARK: - Resolved Identification

    @Test("resolvedPDFAIdentification returns explicit value when set")
    func resolvedPDFAExplicit() {
        let pdfa = PDFAIdentification(part: 3, conformance: "a")
        let pkg = MainXMPPackage(pdfaIdentification: pdfa)
        #expect(pkg.resolvedPDFAIdentification?.part == 3)
        #expect(pkg.resolvedPDFAIdentification?.conformance == "a")
    }

    @Test("resolvedPDFAIdentification extracts from properties when not set")
    func resolvedPDFAFromProperties() {
        let partProp = XMPProperty(
            namespace: XMPProperty.Namespace.pdfaID,
            name: "part",
            value: "2"
        )
        let confProp = XMPProperty(
            namespace: XMPProperty.Namespace.pdfaID,
            name: "conformance",
            value: "u"
        )
        let pkg = MainXMPPackage(properties: [partProp, confProp])
        #expect(pkg.resolvedPDFAIdentification?.part == 2)
        #expect(pkg.resolvedPDFAIdentification?.conformance == "u")
    }

    @Test("resolvedPDFAIdentification returns nil when no properties match")
    func resolvedPDFANil() {
        let pkg = MainXMPPackage()
        #expect(pkg.resolvedPDFAIdentification == nil)
    }

    @Test("resolvedPDFAIdentification extracts amendment and revision")
    func resolvedPDFAAmendmentRevision() {
        let props: [XMPProperty] = [
            .init(namespace: XMPProperty.Namespace.pdfaID, name: "part", value: "1"),
            .init(namespace: XMPProperty.Namespace.pdfaID, name: "conformance", value: "b"),
            .init(namespace: XMPProperty.Namespace.pdfaID, name: "amd", value: "1"),
            .init(namespace: XMPProperty.Namespace.pdfaID, name: "rev", value: "2009"),
        ]
        let pkg = MainXMPPackage(properties: props)
        let resolved = pkg.resolvedPDFAIdentification
        #expect(resolved?.amendment == "1")
        #expect(resolved?.revision == "2009")
    }

    @Test("resolvedPDFUAIdentification returns explicit value when set")
    func resolvedPDFUAExplicit() {
        let pdfua = PDFUAIdentification(part: 2, revision: "2023")
        let pkg = MainXMPPackage(pdfuaIdentification: pdfua)
        #expect(pkg.resolvedPDFUAIdentification?.part == 2)
        #expect(pkg.resolvedPDFUAIdentification?.revision == "2023")
    }

    @Test("resolvedPDFUAIdentification extracts from properties when not set")
    func resolvedPDFUAFromProperties() {
        let partProp = XMPProperty(
            namespace: XMPProperty.Namespace.pdfuaID,
            name: "part",
            value: "1"
        )
        let pkg = MainXMPPackage(properties: [partProp])
        #expect(pkg.resolvedPDFUAIdentification?.part == 1)
    }

    @Test("resolvedPDFUAIdentification returns nil when no properties match")
    func resolvedPDFUANil() {
        let pkg = MainXMPPackage()
        #expect(pkg.resolvedPDFUAIdentification == nil)
    }

    @Test("resolvedPDFUAIdentification extracts revision")
    func resolvedPDFUARevision() {
        let props: [XMPProperty] = [
            .init(namespace: XMPProperty.Namespace.pdfuaID, name: "part", value: "2"),
            .init(namespace: XMPProperty.Namespace.pdfuaID, name: "rev", value: "2023"),
        ]
        let pkg = MainXMPPackage(properties: props)
        #expect(pkg.resolvedPDFUAIdentification?.revision == "2023")
    }

    // MARK: - Property Access

    @Test("propertyCount returns correct count")
    func propertyCount() {
        let p1 = XMPProperty(namespace: "ns", name: "a", value: "1")
        let p2 = XMPProperty(namespace: "ns", name: "b", value: "2")
        let pkg = MainXMPPackage(properties: [p1, p2])
        #expect(pkg.propertyCount == 2)
    }

    @Test("isEmpty returns true for empty package")
    func isEmptyTrue() {
        let pkg = MainXMPPackage()
        #expect(pkg.isEmpty)
    }

    @Test("isEmpty returns false for non-empty package")
    func isEmptyFalse() {
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v")
        let pkg = MainXMPPackage(properties: [prop])
        #expect(!pkg.isEmpty)
    }

    @Test("property(named:) finds matching property")
    func propertyNamed() {
        let p1 = XMPProperty(namespace: "ns", name: "title", value: "Test")
        let p2 = XMPProperty(namespace: "ns", name: "creator", value: "Author")
        let pkg = MainXMPPackage(properties: [p1, p2])
        #expect(pkg.property(named: "title")?.value == "Test")
    }

    @Test("property(named:) returns nil when not found")
    func propertyNamedNotFound() {
        let pkg = MainXMPPackage()
        #expect(pkg.property(named: "missing") == nil)
    }

    @Test("properties(inNamespace:) filters by namespace")
    func propertiesInNamespace() {
        let p1 = XMPProperty(namespace: "ns1", name: "a", value: "1")
        let p2 = XMPProperty(namespace: "ns2", name: "b", value: "2")
        let p3 = XMPProperty(namespace: "ns1", name: "c", value: "3")
        let pkg = MainXMPPackage(properties: [p1, p2, p3])

        let result = pkg.properties(inNamespace: "ns1")
        #expect(result.count == 2)
    }

    @Test("properties(inNamespace:) returns empty for unknown namespace")
    func propertiesInUnknownNamespace() {
        let pkg = MainXMPPackage()
        #expect(pkg.properties(inNamespace: "unknown").isEmpty)
    }

    // MARK: - Invalid Part Extraction

    @Test("resolvedPDFAIdentification returns nil for non-numeric part")
    func resolvedPDFANonNumericPart() {
        let prop = XMPProperty(
            namespace: XMPProperty.Namespace.pdfaID,
            name: "part",
            value: "abc"
        )
        let pkg = MainXMPPackage(properties: [prop])
        #expect(pkg.resolvedPDFAIdentification == nil)
    }

    @Test("resolvedPDFUAIdentification returns nil for non-numeric part")
    func resolvedPDFUANonNumericPart() {
        let prop = XMPProperty(
            namespace: XMPProperty.Namespace.pdfuaID,
            name: "part",
            value: "abc"
        )
        let pkg = MainXMPPackage(properties: [prop])
        #expect(pkg.resolvedPDFUAIdentification == nil)
    }

    // MARK: - Equatable

    @Test("Equal packages are equal")
    func equatable() {
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v")
        let a = MainXMPPackage(properties: [prop])
        let b = MainXMPPackage(properties: [prop])
        #expect(a == b)
    }

    @Test("Different properties are not equal")
    func differentProperties() {
        let p1 = XMPProperty(namespace: "ns", name: "a", value: "1")
        let p2 = XMPProperty(namespace: "ns", name: "b", value: "2")
        let a = MainXMPPackage(properties: [p1])
        let b = MainXMPPackage(properties: [p2])
        #expect(a != b)
    }

    @Test("Different PDF/A identifications are not equal")
    func differentPDFAIdentifications() {
        let a = MainXMPPackage(pdfaIdentification: PDFAIdentification(part: 1, conformance: "b"))
        let b = MainXMPPackage(pdfaIdentification: PDFAIdentification(part: 2, conformance: "u"))
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let prop = XMPProperty(namespace: "ns", name: "title", value: "Test")
        let pdfa = PDFAIdentification(part: 2, conformance: "u")
        let original = MainXMPPackage(properties: [prop], pdfaIdentification: pdfa)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MainXMPPackage.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip empty package")
    func codableRoundTripEmpty() throws {
        let original = MainXMPPackage()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MainXMPPackage.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes property count")
    func descriptionPropertyCount() {
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v")
        let pkg = MainXMPPackage(properties: [prop])
        #expect(pkg.description.contains("properties: 1"))
    }

    @Test("Description includes PDF/A when present via properties")
    func descriptionIncludesPDFA() {
        let props: [XMPProperty] = [
            .init(namespace: XMPProperty.Namespace.pdfaID, name: "part", value: "2"),
            .init(namespace: XMPProperty.Namespace.pdfaID, name: "conformance", value: "u"),
        ]
        let pkg = MainXMPPackage(properties: props)
        #expect(pkg.description.contains("pdfa"))
    }

    @Test("Description includes PDF/UA when present via explicit")
    func descriptionIncludesPDFUA() {
        let pdfua = PDFUAIdentification(part: 2)
        let pkg = MainXMPPackage(pdfuaIdentification: pdfua)
        #expect(pkg.description.contains("pdfua"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let pkg = MainXMPPackage()
        let result = await Task { pkg }.value
        #expect(result == pkg)
    }
}
