import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("XMPPackage Tests")
struct XMPPackageTests {

    // MARK: - Initialization

    @Test("Default init with namespace and prefix")
    func defaultInit() {
        let pkg = XMPPackage(
            namespace: "http://purl.org/dc/elements/1.1/",
            prefix: "dc"
        )
        #expect(pkg.namespace == "http://purl.org/dc/elements/1.1/")
        #expect(pkg.prefix == "dc")
        #expect(pkg.properties.isEmpty)
    }

    @Test("Init with properties")
    func initWithProperties() {
        let prop = XMPProperty(namespace: "ns", name: "title", value: "Test")
        let pkg = XMPPackage(namespace: "ns", prefix: "p", properties: [prop])
        #expect(pkg.properties.count == 1)
        #expect(pkg.properties[0].name == "title")
    }

    @Test("Init with multiple properties")
    func initWithMultipleProperties() {
        let p1 = XMPProperty(namespace: "ns", name: "title", value: "T")
        let p2 = XMPProperty(namespace: "ns", name: "creator", value: "C")
        let p3 = XMPProperty(namespace: "ns", name: "date", value: "D")
        let pkg = XMPPackage(namespace: "ns", prefix: "p", properties: [p1, p2, p3])
        #expect(pkg.properties.count == 3)
    }

    // MARK: - isEmpty / propertyCount

    @Test("isEmpty returns true for empty package")
    func isEmptyTrue() {
        let pkg = XMPPackage(namespace: "ns", prefix: "p")
        #expect(pkg.isEmpty)
    }

    @Test("isEmpty returns false for non-empty package")
    func isEmptyFalse() {
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v")
        let pkg = XMPPackage(namespace: "ns", prefix: "p", properties: [prop])
        #expect(!pkg.isEmpty)
    }

    @Test("propertyCount returns correct count")
    func propertyCount() {
        let p1 = XMPProperty(namespace: "ns", name: "a", value: "1")
        let p2 = XMPProperty(namespace: "ns", name: "b", value: "2")
        let pkg = XMPPackage(namespace: "ns", prefix: "p", properties: [p1, p2])
        #expect(pkg.propertyCount == 2)
    }

    @Test("propertyCount is zero for empty package")
    func propertyCountZero() {
        let pkg = XMPPackage(namespace: "ns", prefix: "p")
        #expect(pkg.propertyCount == 0)
    }

    // MARK: - Property Lookup

    @Test("property(named:) finds matching property")
    func propertyNamed() {
        let p1 = XMPProperty(namespace: "ns", name: "title", value: "Test")
        let p2 = XMPProperty(namespace: "ns", name: "creator", value: "Author")
        let pkg = XMPPackage(namespace: "ns", prefix: "p", properties: [p1, p2])

        let found = pkg.property(named: "title")
        #expect(found?.value == "Test")
    }

    @Test("property(named:) returns nil when not found")
    func propertyNamedNotFound() {
        let pkg = XMPPackage(namespace: "ns", prefix: "p")
        #expect(pkg.property(named: "missing") == nil)
    }

    @Test("property(named:) returns first match")
    func propertyNamedFirstMatch() {
        let p1 = XMPProperty(namespace: "ns", name: "subject", value: "first")
        let p2 = XMPProperty(namespace: "ns", name: "subject", value: "second")
        let pkg = XMPPackage(namespace: "ns", prefix: "p", properties: [p1, p2])

        let found = pkg.property(named: "subject")
        #expect(found?.value == "first")
    }

    @Test("properties(named:) returns all matches")
    func propertiesNamed() {
        let p1 = XMPProperty(namespace: "ns", name: "subject", value: "math")
        let p2 = XMPProperty(namespace: "ns", name: "title", value: "Doc")
        let p3 = XMPProperty(namespace: "ns", name: "subject", value: "science")
        let pkg = XMPPackage(namespace: "ns", prefix: "p", properties: [p1, p2, p3])

        let found = pkg.properties(named: "subject")
        #expect(found.count == 2)
        #expect(found[0].value == "math")
        #expect(found[1].value == "science")
    }

    @Test("properties(named:) returns empty for no matches")
    func propertiesNamedEmpty() {
        let pkg = XMPPackage(namespace: "ns", prefix: "p")
        #expect(pkg.properties(named: "missing").isEmpty)
    }

    @Test("containsProperty(named:) returns true when present")
    func containsPropertyTrue() {
        let prop = XMPProperty(namespace: "ns", name: "title", value: "T")
        let pkg = XMPPackage(namespace: "ns", prefix: "p", properties: [prop])
        #expect(pkg.containsProperty(named: "title"))
    }

    @Test("containsProperty(named:) returns false when absent")
    func containsPropertyFalse() {
        let pkg = XMPPackage(namespace: "ns", prefix: "p")
        #expect(!pkg.containsProperty(named: "missing"))
    }

    // MARK: - Equatable

    @Test("Equal packages are equal")
    func equatable() {
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v")
        let a = XMPPackage(namespace: "ns", prefix: "p", properties: [prop])
        let b = XMPPackage(namespace: "ns", prefix: "p", properties: [prop])
        #expect(a == b)
    }

    @Test("Different namespaces are not equal")
    func differentNamespaces() {
        let a = XMPPackage(namespace: "ns1", prefix: "p")
        let b = XMPPackage(namespace: "ns2", prefix: "p")
        #expect(a != b)
    }

    @Test("Different prefixes are not equal")
    func differentPrefixes() {
        let a = XMPPackage(namespace: "ns", prefix: "p1")
        let b = XMPPackage(namespace: "ns", prefix: "p2")
        #expect(a != b)
    }

    @Test("Different properties are not equal")
    func differentProperties() {
        let p1 = XMPProperty(namespace: "ns", name: "a", value: "1")
        let p2 = XMPProperty(namespace: "ns", name: "b", value: "2")
        let a = XMPPackage(namespace: "ns", prefix: "p", properties: [p1])
        let b = XMPPackage(namespace: "ns", prefix: "p", properties: [p2])
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let prop = XMPProperty(namespace: "ns", name: "title", value: "Test")
        let original = XMPPackage(namespace: "ns", prefix: "dc", properties: [prop])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(XMPPackage.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip empty package")
    func codableRoundTripEmpty() throws {
        let original = XMPPackage(namespace: "ns", prefix: "p")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(XMPPackage.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes prefix and namespace")
    func descriptionIncludesFields() {
        let pkg = XMPPackage(namespace: "http://example.com/", prefix: "ex")
        #expect(pkg.description.contains("ex"))
        #expect(pkg.description.contains("http://example.com/"))
    }

    @Test("Description includes property count")
    func descriptionIncludesPropertyCount() {
        let prop = XMPProperty(namespace: "ns", name: "n", value: "v")
        let pkg = XMPPackage(namespace: "ns", prefix: "p", properties: [prop])
        #expect(pkg.description.contains("properties: 1"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let pkg = XMPPackage(namespace: "ns", prefix: "p")
        let result = await Task { pkg }.value
        #expect(result == pkg)
    }
}
