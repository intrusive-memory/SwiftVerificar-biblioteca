import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("XMPProperty Tests")
struct XMPPropertyTests {

    // MARK: - Initialization

    @Test("Default init with namespace, name, value")
    func defaultInit() {
        let prop = XMPProperty(
            namespace: "http://purl.org/dc/elements/1.1/",
            name: "title",
            value: "My Document"
        )
        #expect(prop.namespace == "http://purl.org/dc/elements/1.1/")
        #expect(prop.name == "title")
        #expect(prop.value == "My Document")
        #expect(prop.qualifiers.isEmpty)
    }

    @Test("Init with qualifiers")
    func initWithQualifiers() {
        let qualifier = XMPProperty(
            namespace: XMPProperty.Namespace.xml,
            name: "lang",
            value: "en-US"
        )
        let prop = XMPProperty(
            namespace: XMPProperty.Namespace.dublinCore,
            name: "title",
            value: "My Document",
            qualifiers: [qualifier]
        )
        #expect(prop.qualifiers.count == 1)
        #expect(prop.qualifiers[0].name == "lang")
    }

    @Test("Init with empty value")
    func emptyValue() {
        let prop = XMPProperty(namespace: "ns", name: "field", value: "")
        #expect(prop.value.isEmpty)
    }

    @Test("Init with empty namespace")
    func emptyNamespace() {
        let prop = XMPProperty(namespace: "", name: "field", value: "val")
        #expect(prop.namespace.isEmpty)
    }

    // MARK: - Qualified Name

    @Test("qualifiedName combines namespace and name")
    func qualifiedName() {
        let prop = XMPProperty(
            namespace: "http://purl.org/dc/elements/1.1/",
            name: "title",
            value: "Test"
        )
        #expect(prop.qualifiedName == "{http://purl.org/dc/elements/1.1/}title")
    }

    @Test("qualifiedName with empty namespace")
    func qualifiedNameEmptyNamespace() {
        let prop = XMPProperty(namespace: "", name: "field", value: "v")
        #expect(prop.qualifiedName == "{}field")
    }

    // MARK: - Qualifier Access

    @Test("hasQualifiers returns false when empty")
    func hasQualifiersFalse() {
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v")
        #expect(!prop.hasQualifiers)
    }

    @Test("hasQualifiers returns true when qualifiers present")
    func hasQualifiersTrue() {
        let q = XMPProperty(namespace: "ns", name: "lang", value: "en")
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v", qualifiers: [q])
        #expect(prop.hasQualifiers)
    }

    @Test("qualifier(named:) finds matching qualifier")
    func qualifierNamed() {
        let q1 = XMPProperty(namespace: "ns", name: "lang", value: "en")
        let q2 = XMPProperty(namespace: "ns", name: "type", value: "Alt")
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v", qualifiers: [q1, q2])

        let found = prop.qualifier(named: "lang")
        #expect(found?.value == "en")
    }

    @Test("qualifier(named:) returns nil when not found")
    func qualifierNamedNotFound() {
        let q = XMPProperty(namespace: "ns", name: "lang", value: "en")
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v", qualifiers: [q])

        #expect(prop.qualifier(named: "missing") == nil)
    }

    @Test("qualifier(named:) returns first match when multiple exist")
    func qualifierNamedFirstMatch() {
        let q1 = XMPProperty(namespace: "ns", name: "lang", value: "en")
        let q2 = XMPProperty(namespace: "ns", name: "lang", value: "fr")
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v", qualifiers: [q1, q2])

        let found = prop.qualifier(named: "lang")
        #expect(found?.value == "en")
    }

    @Test("qualifiers(inNamespace:) filters by namespace")
    func qualifiersInNamespace() {
        let q1 = XMPProperty(namespace: "ns1", name: "a", value: "1")
        let q2 = XMPProperty(namespace: "ns2", name: "b", value: "2")
        let q3 = XMPProperty(namespace: "ns1", name: "c", value: "3")
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v", qualifiers: [q1, q2, q3])

        let ns1Qualifiers = prop.qualifiers(inNamespace: "ns1")
        #expect(ns1Qualifiers.count == 2)
        #expect(ns1Qualifiers[0].name == "a")
        #expect(ns1Qualifiers[1].name == "c")
    }

    @Test("qualifiers(inNamespace:) returns empty for unknown namespace")
    func qualifiersInUnknownNamespace() {
        let q = XMPProperty(namespace: "ns1", name: "a", value: "1")
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v", qualifiers: [q])

        #expect(prop.qualifiers(inNamespace: "unknown").isEmpty)
    }

    // MARK: - Namespace Constants

    @Test("Namespace.dublinCore is correct")
    func namespaceDublinCore() {
        #expect(XMPProperty.Namespace.dublinCore == "http://purl.org/dc/elements/1.1/")
    }

    @Test("Namespace.xmpBasic is correct")
    func namespaceXmpBasic() {
        #expect(XMPProperty.Namespace.xmpBasic == "http://ns.adobe.com/xap/1.0/")
    }

    @Test("Namespace.adobePDF is correct")
    func namespaceAdobePDF() {
        #expect(XMPProperty.Namespace.adobePDF == "http://ns.adobe.com/pdf/1.3/")
    }

    @Test("Namespace.pdfaID is correct")
    func namespacePdfaID() {
        #expect(XMPProperty.Namespace.pdfaID == "http://www.aiim.org/pdfa/ns/id/")
    }

    @Test("Namespace.pdfuaID is correct")
    func namespacePdfuaID() {
        #expect(XMPProperty.Namespace.pdfuaID == "http://www.aiim.org/pdfua/ns/id/")
    }

    @Test("Namespace.xmpRights is correct")
    func namespaceXmpRights() {
        #expect(XMPProperty.Namespace.xmpRights == "http://ns.adobe.com/xap/1.0/rights/")
    }

    @Test("Namespace.xml is correct")
    func namespaceXml() {
        #expect(XMPProperty.Namespace.xml == "http://www.w3.org/XML/1998/namespace")
    }

    @Test("Namespace.rdf is correct")
    func namespaceRdf() {
        #expect(XMPProperty.Namespace.rdf == "http://www.w3.org/1999/02/22-rdf-syntax-ns#")
    }

    // MARK: - Equatable

    @Test("Equal properties are equal")
    func equatable() {
        let a = XMPProperty(namespace: "ns", name: "n", value: "v")
        let b = XMPProperty(namespace: "ns", name: "n", value: "v")
        #expect(a == b)
    }

    @Test("Different values are not equal")
    func differentValues() {
        let a = XMPProperty(namespace: "ns", name: "n", value: "v1")
        let b = XMPProperty(namespace: "ns", name: "n", value: "v2")
        #expect(a != b)
    }

    @Test("Different names are not equal")
    func differentNames() {
        let a = XMPProperty(namespace: "ns", name: "a", value: "v")
        let b = XMPProperty(namespace: "ns", name: "b", value: "v")
        #expect(a != b)
    }

    @Test("Different namespaces are not equal")
    func differentNamespaces() {
        let a = XMPProperty(namespace: "ns1", name: "n", value: "v")
        let b = XMPProperty(namespace: "ns2", name: "n", value: "v")
        #expect(a != b)
    }

    @Test("Different qualifiers are not equal")
    func differentQualifiers() {
        let q = XMPProperty(namespace: "ns", name: "q", value: "qv")
        let a = XMPProperty(namespace: "ns", name: "n", value: "v", qualifiers: [q])
        let b = XMPProperty(namespace: "ns", name: "n", value: "v")
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("Codable round-trip without qualifiers")
    func codableRoundTrip() throws {
        let original = XMPProperty(namespace: "ns", name: "title", value: "Test")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(XMPProperty.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip with qualifiers")
    func codableRoundTripWithQualifiers() throws {
        let q = XMPProperty(namespace: "xml-ns", name: "lang", value: "en")
        let original = XMPProperty(namespace: "dc", name: "title", value: "Doc", qualifiers: [q])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(XMPProperty.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description without qualifiers")
    func descriptionNoQualifiers() {
        let prop = XMPProperty(namespace: "ns", name: "title", value: "Test")
        #expect(prop.description.contains("title"))
        #expect(prop.description.contains("Test"))
        #expect(!prop.description.contains("qualifiers"))
    }

    @Test("Description with qualifiers")
    func descriptionWithQualifiers() {
        let q = XMPProperty(namespace: "ns", name: "lang", value: "en")
        let prop = XMPProperty(namespace: "ns", name: "title", value: "Test", qualifiers: [q])
        #expect(prop.description.contains("qualifiers: 1"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let prop = XMPProperty(namespace: "ns", name: "title", value: "Test")
        let result = await Task { prop }.value
        #expect(result == prop)
    }
}
