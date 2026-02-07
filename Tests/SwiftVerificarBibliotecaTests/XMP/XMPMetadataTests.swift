import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("XMPMetadata Tests")
struct XMPMetadataTests {

    // MARK: - Test Helpers

    private func makePDFAPackage(part: String, conformance: String) -> XMPPackage {
        XMPPackage(
            namespace: XMPProperty.Namespace.pdfaID,
            prefix: "pdfaid",
            properties: [
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "part", value: part),
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "conformance", value: conformance),
            ]
        )
    }

    private func makePDFUAPackage(part: String) -> XMPPackage {
        XMPPackage(
            namespace: XMPProperty.Namespace.pdfuaID,
            prefix: "pdfuaid",
            properties: [
                XMPProperty(namespace: XMPProperty.Namespace.pdfuaID, name: "part", value: part),
            ]
        )
    }

    private func makeDCPackage(title: String? = nil, creator: String? = nil) -> XMPPackage {
        var props: [XMPProperty] = []
        if let title {
            props.append(XMPProperty(namespace: XMPProperty.Namespace.dublinCore, name: "title", value: title))
        }
        if let creator {
            props.append(XMPProperty(namespace: XMPProperty.Namespace.dublinCore, name: "creator", value: creator))
        }
        return XMPPackage(
            namespace: XMPProperty.Namespace.dublinCore,
            prefix: "dc",
            properties: props
        )
    }

    // MARK: - Initialization

    @Test("Default init creates empty metadata")
    func defaultInit() {
        let md = XMPMetadata()
        #expect(md.packages.isEmpty)
    }

    @Test("Init with packages")
    func initWithPackages() {
        let pkg = XMPPackage(namespace: "ns", prefix: "p")
        let md = XMPMetadata(packages: [pkg])
        #expect(md.packages.count == 1)
    }

    @Test("Init with multiple packages")
    func initWithMultiplePackages() {
        let p1 = XMPPackage(namespace: "ns1", prefix: "p1")
        let p2 = XMPPackage(namespace: "ns2", prefix: "p2")
        let md = XMPMetadata(packages: [p1, p2])
        #expect(md.packages.count == 2)
    }

    // MARK: - PDF/A Identification

    @Test("pdfaIdentification extracts from pdfaid package")
    func pdfaIdentification() {
        let pkg = makePDFAPackage(part: "2", conformance: "u")
        let md = XMPMetadata(packages: [pkg])
        #expect(md.pdfaIdentification?.part == 2)
        #expect(md.pdfaIdentification?.conformance == "u")
    }

    @Test("pdfaIdentification returns nil when no pdfaid package")
    func pdfaIdentificationNil() {
        let md = XMPMetadata()
        #expect(md.pdfaIdentification == nil)
    }

    @Test("pdfaIdentification returns nil for non-numeric part")
    func pdfaIdentificationNonNumeric() {
        let pkg = XMPPackage(
            namespace: XMPProperty.Namespace.pdfaID,
            prefix: "pdfaid",
            properties: [
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "part", value: "abc"),
            ]
        )
        let md = XMPMetadata(packages: [pkg])
        #expect(md.pdfaIdentification == nil)
    }

    @Test("pdfaIdentification extracts amendment and revision")
    func pdfaIdentificationFull() {
        let pkg = XMPPackage(
            namespace: XMPProperty.Namespace.pdfaID,
            prefix: "pdfaid",
            properties: [
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "part", value: "1"),
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "conformance", value: "b"),
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "amd", value: "1"),
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "rev", value: "2009"),
            ]
        )
        let md = XMPMetadata(packages: [pkg])
        let pdfa = md.pdfaIdentification
        #expect(pdfa?.part == 1)
        #expect(pdfa?.conformance == "b")
        #expect(pdfa?.amendment == "1")
        #expect(pdfa?.revision == "2009")
    }

    @Test("pdfaIdentification defaults conformance to empty when missing")
    func pdfaIdentificationDefaultConformance() {
        let pkg = XMPPackage(
            namespace: XMPProperty.Namespace.pdfaID,
            prefix: "pdfaid",
            properties: [
                XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "part", value: "4"),
            ]
        )
        let md = XMPMetadata(packages: [pkg])
        #expect(md.pdfaIdentification?.conformance == "")
    }

    // MARK: - PDF/UA Identification

    @Test("pdfuaIdentification extracts from pdfuaid package")
    func pdfuaIdentification() {
        let pkg = makePDFUAPackage(part: "2")
        let md = XMPMetadata(packages: [pkg])
        #expect(md.pdfuaIdentification?.part == 2)
    }

    @Test("pdfuaIdentification returns nil when no pdfuaid package")
    func pdfuaIdentificationNil() {
        let md = XMPMetadata()
        #expect(md.pdfuaIdentification == nil)
    }

    @Test("pdfuaIdentification returns nil for non-numeric part")
    func pdfuaIdentificationNonNumeric() {
        let pkg = XMPPackage(
            namespace: XMPProperty.Namespace.pdfuaID,
            prefix: "pdfuaid",
            properties: [
                XMPProperty(namespace: XMPProperty.Namespace.pdfuaID, name: "part", value: "xyz"),
            ]
        )
        let md = XMPMetadata(packages: [pkg])
        #expect(md.pdfuaIdentification == nil)
    }

    @Test("pdfuaIdentification extracts revision")
    func pdfuaIdentificationRevision() {
        let pkg = XMPPackage(
            namespace: XMPProperty.Namespace.pdfuaID,
            prefix: "pdfuaid",
            properties: [
                XMPProperty(namespace: XMPProperty.Namespace.pdfuaID, name: "part", value: "1"),
                XMPProperty(namespace: XMPProperty.Namespace.pdfuaID, name: "rev", value: "2014"),
            ]
        )
        let md = XMPMetadata(packages: [pkg])
        #expect(md.pdfuaIdentification?.revision == "2014")
    }

    // MARK: - Dublin Core

    @Test("dublinCore extracts from DC package")
    func dublinCore() {
        let pkg = makeDCPackage(title: "Test Doc", creator: "Author")
        let md = XMPMetadata(packages: [pkg])
        #expect(md.dublinCore?.title == "Test Doc")
        #expect(md.dublinCore?.creator == "Author")
    }

    @Test("dublinCore returns nil when no DC package")
    func dublinCoreNil() {
        let md = XMPMetadata()
        #expect(md.dublinCore == nil)
    }

    @Test("dublinCore returns nil for empty DC package")
    func dublinCoreEmpty() {
        let pkg = XMPPackage(
            namespace: XMPProperty.Namespace.dublinCore,
            prefix: "dc",
            properties: []
        )
        let md = XMPMetadata(packages: [pkg])
        #expect(md.dublinCore == nil)
    }

    // MARK: - Package Lookup

    @Test("package(forNamespace:) finds matching package")
    func packageForNamespace() {
        let pkg = XMPPackage(namespace: "http://example.com/", prefix: "ex")
        let md = XMPMetadata(packages: [pkg])
        #expect(md.package(forNamespace: "http://example.com/") != nil)
    }

    @Test("package(forNamespace:) returns nil when not found")
    func packageForNamespaceNotFound() {
        let md = XMPMetadata()
        #expect(md.package(forNamespace: "missing") == nil)
    }

    @Test("package(forPrefix:) finds matching package")
    func packageForPrefix() {
        let pkg = XMPPackage(namespace: "ns", prefix: "dc")
        let md = XMPMetadata(packages: [pkg])
        #expect(md.package(forPrefix: "dc") != nil)
    }

    @Test("package(forPrefix:) returns nil when not found")
    func packageForPrefixNotFound() {
        let md = XMPMetadata()
        #expect(md.package(forPrefix: "missing") == nil)
    }

    @Test("packages(forNamespace:) returns all matching packages")
    func packagesForNamespace() {
        let p1 = XMPPackage(namespace: "ns", prefix: "a")
        let p2 = XMPPackage(namespace: "ns", prefix: "b")
        let p3 = XMPPackage(namespace: "other", prefix: "c")
        let md = XMPMetadata(packages: [p1, p2, p3])
        #expect(md.packages(forNamespace: "ns").count == 2)
    }

    @Test("packages(forNamespace:) returns empty for no matches")
    func packagesForNamespaceEmpty() {
        let md = XMPMetadata()
        #expect(md.packages(forNamespace: "ns").isEmpty)
    }

    // MARK: - Computed Properties

    @Test("isEmpty returns true for empty metadata")
    func isEmptyTrue() {
        let md = XMPMetadata()
        #expect(md.isEmpty)
    }

    @Test("isEmpty returns false for non-empty metadata")
    func isEmptyFalse() {
        let pkg = XMPPackage(namespace: "ns", prefix: "p")
        let md = XMPMetadata(packages: [pkg])
        #expect(!md.isEmpty)
    }

    @Test("packageCount returns correct count")
    func packageCount() {
        let p1 = XMPPackage(namespace: "ns1", prefix: "p1")
        let p2 = XMPPackage(namespace: "ns2", prefix: "p2")
        let md = XMPMetadata(packages: [p1, p2])
        #expect(md.packageCount == 2)
    }

    @Test("totalPropertyCount sums across packages")
    func totalPropertyCount() {
        let prop1 = XMPProperty(namespace: "ns1", name: "a", value: "1")
        let prop2 = XMPProperty(namespace: "ns1", name: "b", value: "2")
        let prop3 = XMPProperty(namespace: "ns2", name: "c", value: "3")
        let p1 = XMPPackage(namespace: "ns1", prefix: "p1", properties: [prop1, prop2])
        let p2 = XMPPackage(namespace: "ns2", prefix: "p2", properties: [prop3])
        let md = XMPMetadata(packages: [p1, p2])
        #expect(md.totalPropertyCount == 3)
    }

    @Test("totalPropertyCount is 0 for empty metadata")
    func totalPropertyCountZero() {
        let md = XMPMetadata()
        #expect(md.totalPropertyCount == 0)
    }

    @Test("namespaces returns unique namespace URIs")
    func namespaces() {
        let p1 = XMPPackage(namespace: "ns1", prefix: "p1")
        let p2 = XMPPackage(namespace: "ns2", prefix: "p2")
        let p3 = XMPPackage(namespace: "ns1", prefix: "p3")
        let md = XMPMetadata(packages: [p1, p2, p3])
        #expect(md.namespaces == ["ns1", "ns2"])
    }

    @Test("namespaces is empty for empty metadata")
    func namespacesEmpty() {
        let md = XMPMetadata()
        #expect(md.namespaces.isEmpty)
    }

    // MARK: - Property Search

    @Test("property(namespace:name:) finds matching property")
    func propertySearch() {
        let prop = XMPProperty(namespace: "ns1", name: "title", value: "Test")
        let pkg = XMPPackage(namespace: "ns1", prefix: "p", properties: [prop])
        let md = XMPMetadata(packages: [pkg])
        #expect(md.property(namespace: "ns1", name: "title")?.value == "Test")
    }

    @Test("property(namespace:name:) returns nil when not found")
    func propertySearchNotFound() {
        let md = XMPMetadata()
        #expect(md.property(namespace: "ns", name: "missing") == nil)
    }

    @Test("property(namespace:name:) only searches matching namespace packages")
    func propertySearchNamespaceScoped() {
        let prop1 = XMPProperty(namespace: "ns1", name: "title", value: "V1")
        let prop2 = XMPProperty(namespace: "ns2", name: "title", value: "V2")
        let p1 = XMPPackage(namespace: "ns1", prefix: "p1", properties: [prop1])
        let p2 = XMPPackage(namespace: "ns2", prefix: "p2", properties: [prop2])
        let md = XMPMetadata(packages: [p1, p2])
        #expect(md.property(namespace: "ns2", name: "title")?.value == "V2")
    }

    // MARK: - Combined Schema Metadata

    @Test("Metadata with both PDF/A and PDF/UA packages")
    func combinedSchemas() {
        let pdfaPkg = makePDFAPackage(part: "2", conformance: "u")
        let pdfuaPkg = makePDFUAPackage(part: "2")
        let dcPkg = makeDCPackage(title: "Accessible Doc")
        let md = XMPMetadata(packages: [pdfaPkg, pdfuaPkg, dcPkg])

        #expect(md.pdfaIdentification?.part == 2)
        #expect(md.pdfuaIdentification?.part == 2)
        #expect(md.dublinCore?.title == "Accessible Doc")
    }

    // MARK: - Equatable

    @Test("Equal metadata are equal")
    func equatable() {
        let pkg = XMPPackage(namespace: "ns", prefix: "p")
        let a = XMPMetadata(packages: [pkg])
        let b = XMPMetadata(packages: [pkg])
        #expect(a == b)
    }

    @Test("Different packages are not equal")
    func differentPackages() {
        let p1 = XMPPackage(namespace: "ns1", prefix: "p1")
        let p2 = XMPPackage(namespace: "ns2", prefix: "p2")
        let a = XMPMetadata(packages: [p1])
        let b = XMPMetadata(packages: [p2])
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let pdfaPkg = makePDFAPackage(part: "2", conformance: "u")
        let original = XMPMetadata(packages: [pdfaPkg])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(XMPMetadata.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip empty metadata")
    func codableRoundTripEmpty() throws {
        let original = XMPMetadata()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(XMPMetadata.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes package count")
    func descriptionPackageCount() {
        let md = XMPMetadata()
        #expect(md.description.contains("packages: 0"))
    }

    @Test("Description includes pdfa when present")
    func descriptionIncludesPDFA() {
        let pkg = makePDFAPackage(part: "2", conformance: "u")
        let md = XMPMetadata(packages: [pkg])
        #expect(md.description.contains("pdfa"))
    }

    @Test("Description includes pdfua when present")
    func descriptionIncludesPDFUA() {
        let pkg = makePDFUAPackage(part: "2")
        let md = XMPMetadata(packages: [pkg])
        #expect(md.description.contains("pdfua"))
    }

    @Test("Description includes dublinCore when present")
    func descriptionIncludesDC() {
        let pkg = makeDCPackage(title: "Doc")
        let md = XMPMetadata(packages: [pkg])
        #expect(md.description.contains("dublinCore"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let md = XMPMetadata()
        let result = await Task { md }.value
        #expect(result == md)
    }
}
