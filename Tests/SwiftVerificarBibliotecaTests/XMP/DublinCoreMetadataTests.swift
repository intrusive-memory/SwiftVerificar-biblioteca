import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("DublinCoreMetadata Tests")
struct DublinCoreMetadataTests {

    // MARK: - Default Initialization

    @Test("Default init creates empty metadata")
    func defaultInit() {
        let dc = DublinCoreMetadata()
        #expect(dc.title == nil)
        #expect(dc.creator == nil)
        #expect(dc.dcDescription == nil)
        #expect(dc.subject.isEmpty)
        #expect(dc.publisher == nil)
        #expect(dc.contributor == nil)
        #expect(dc.date == nil)
        #expect(dc.type == nil)
        #expect(dc.format == nil)
        #expect(dc.identifier == nil)
        #expect(dc.source == nil)
        #expect(dc.language == nil)
        #expect(dc.relation == nil)
        #expect(dc.coverage == nil)
        #expect(dc.rights == nil)
    }

    @Test("Init with all fields populated")
    func fullInit() {
        let dc = DublinCoreMetadata(
            title: "Test Title",
            creator: "Test Author",
            dcDescription: "Test Description",
            subject: ["keyword1", "keyword2"],
            publisher: "Test Publisher",
            contributor: "Test Contributor",
            date: "2024-01-15",
            type: "report",
            format: "application/pdf",
            identifier: "isbn:1234567890",
            source: "original.pdf",
            language: "en-US",
            relation: "related-doc",
            coverage: "worldwide",
            rights: "CC BY 4.0"
        )
        #expect(dc.title == "Test Title")
        #expect(dc.creator == "Test Author")
        #expect(dc.dcDescription == "Test Description")
        #expect(dc.subject == ["keyword1", "keyword2"])
        #expect(dc.publisher == "Test Publisher")
        #expect(dc.contributor == "Test Contributor")
        #expect(dc.date == "2024-01-15")
        #expect(dc.type == "report")
        #expect(dc.format == "application/pdf")
        #expect(dc.identifier == "isbn:1234567890")
        #expect(dc.source == "original.pdf")
        #expect(dc.language == "en-US")
        #expect(dc.relation == "related-doc")
        #expect(dc.coverage == "worldwide")
        #expect(dc.rights == "CC BY 4.0")
    }

    @Test("Init with partial fields")
    func partialInit() {
        let dc = DublinCoreMetadata(title: "Title Only")
        #expect(dc.title == "Title Only")
        #expect(dc.creator == nil)
    }

    // MARK: - isEmpty

    @Test("isEmpty returns true for default init")
    func isEmptyDefault() {
        let dc = DublinCoreMetadata()
        #expect(dc.isEmpty)
    }

    @Test("isEmpty returns false when title is set")
    func isEmptyWithTitle() {
        let dc = DublinCoreMetadata(title: "T")
        #expect(!dc.isEmpty)
    }

    @Test("isEmpty returns false when subject is non-empty")
    func isEmptyWithSubject() {
        let dc = DublinCoreMetadata(subject: ["keyword"])
        #expect(!dc.isEmpty)
    }

    @Test("isEmpty returns true with empty subject array")
    func isEmptyWithEmptySubject() {
        let dc = DublinCoreMetadata(subject: [])
        #expect(dc.isEmpty)
    }

    @Test("isEmpty returns false when only rights is set")
    func isEmptyWithRightsOnly() {
        let dc = DublinCoreMetadata(rights: "CC BY")
        #expect(!dc.isEmpty)
    }

    // MARK: - populatedFieldCount

    @Test("populatedFieldCount is 0 for empty metadata")
    func populatedFieldCountZero() {
        let dc = DublinCoreMetadata()
        #expect(dc.populatedFieldCount == 0)
    }

    @Test("populatedFieldCount counts title")
    func populatedFieldCountTitle() {
        let dc = DublinCoreMetadata(title: "T")
        #expect(dc.populatedFieldCount == 1)
    }

    @Test("populatedFieldCount counts multiple fields")
    func populatedFieldCountMultiple() {
        let dc = DublinCoreMetadata(
            title: "T",
            creator: "C",
            dcDescription: "D",
            subject: ["S"]
        )
        #expect(dc.populatedFieldCount == 4)
    }

    @Test("populatedFieldCount counts all 15 fields when all populated")
    func populatedFieldCountAll() {
        let dc = DublinCoreMetadata(
            title: "T",
            creator: "C",
            dcDescription: "D",
            subject: ["S"],
            publisher: "P",
            contributor: "Con",
            date: "2024",
            type: "T",
            format: "F",
            identifier: "I",
            source: "S",
            language: "L",
            relation: "R",
            coverage: "Cov",
            rights: "Ri"
        )
        #expect(dc.populatedFieldCount == 15)
    }

    @Test("populatedFieldCount does not count empty subject")
    func populatedFieldCountEmptySubject() {
        let dc = DublinCoreMetadata(title: "T", subject: [])
        #expect(dc.populatedFieldCount == 1)
    }

    // MARK: - from(package:)

    @Test("from(package:) extracts title")
    func fromPackageTitle() {
        let prop = XMPProperty(
            namespace: XMPProperty.Namespace.dublinCore,
            name: "title",
            value: "My Document"
        )
        let pkg = XMPPackage(
            namespace: XMPProperty.Namespace.dublinCore,
            prefix: "dc",
            properties: [prop]
        )
        let dc = DublinCoreMetadata.from(package: pkg)
        #expect(dc.title == "My Document")
    }

    @Test("from(package:) extracts creator")
    func fromPackageCreator() {
        let prop = XMPProperty(
            namespace: XMPProperty.Namespace.dublinCore,
            name: "creator",
            value: "Author Name"
        )
        let pkg = XMPPackage(
            namespace: XMPProperty.Namespace.dublinCore,
            prefix: "dc",
            properties: [prop]
        )
        let dc = DublinCoreMetadata.from(package: pkg)
        #expect(dc.creator == "Author Name")
    }

    @Test("from(package:) extracts description")
    func fromPackageDescription() {
        let prop = XMPProperty(
            namespace: XMPProperty.Namespace.dublinCore,
            name: "description",
            value: "A test document"
        )
        let pkg = XMPPackage(
            namespace: XMPProperty.Namespace.dublinCore,
            prefix: "dc",
            properties: [prop]
        )
        let dc = DublinCoreMetadata.from(package: pkg)
        #expect(dc.dcDescription == "A test document")
    }

    @Test("from(package:) extracts multiple subjects")
    func fromPackageSubjects() {
        let s1 = XMPProperty(namespace: "dc", name: "subject", value: "math")
        let s2 = XMPProperty(namespace: "dc", name: "subject", value: "science")
        let pkg = XMPPackage(namespace: "dc", prefix: "dc", properties: [s1, s2])
        let dc = DublinCoreMetadata.from(package: pkg)
        #expect(dc.subject == ["math", "science"])
    }

    @Test("from(package:) returns nil fields for missing properties")
    func fromPackageMissing() {
        let pkg = XMPPackage(namespace: "dc", prefix: "dc", properties: [])
        let dc = DublinCoreMetadata.from(package: pkg)
        #expect(dc.title == nil)
        #expect(dc.creator == nil)
        #expect(dc.subject.isEmpty)
    }

    @Test("from(package:) extracts all Dublin Core elements")
    func fromPackageAll() {
        let props: [XMPProperty] = [
            .init(namespace: "dc", name: "title", value: "T"),
            .init(namespace: "dc", name: "creator", value: "C"),
            .init(namespace: "dc", name: "description", value: "D"),
            .init(namespace: "dc", name: "subject", value: "S"),
            .init(namespace: "dc", name: "publisher", value: "P"),
            .init(namespace: "dc", name: "contributor", value: "Con"),
            .init(namespace: "dc", name: "date", value: "2024"),
            .init(namespace: "dc", name: "type", value: "Ty"),
            .init(namespace: "dc", name: "format", value: "F"),
            .init(namespace: "dc", name: "identifier", value: "I"),
            .init(namespace: "dc", name: "source", value: "So"),
            .init(namespace: "dc", name: "language", value: "L"),
            .init(namespace: "dc", name: "relation", value: "R"),
            .init(namespace: "dc", name: "coverage", value: "Cov"),
            .init(namespace: "dc", name: "rights", value: "Ri"),
        ]
        let pkg = XMPPackage(namespace: "dc", prefix: "dc", properties: props)
        let dc = DublinCoreMetadata.from(package: pkg)
        #expect(dc.populatedFieldCount == 15)
    }

    // MARK: - Equatable

    @Test("Equal instances are equal")
    func equatable() {
        let a = DublinCoreMetadata(title: "T", subject: ["S"])
        let b = DublinCoreMetadata(title: "T", subject: ["S"])
        #expect(a == b)
    }

    @Test("Different titles are not equal")
    func differentTitles() {
        let a = DublinCoreMetadata(title: "A")
        let b = DublinCoreMetadata(title: "B")
        #expect(a != b)
    }

    @Test("Different subjects are not equal")
    func differentSubjects() {
        let a = DublinCoreMetadata(subject: ["x"])
        let b = DublinCoreMetadata(subject: ["y"])
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = DublinCoreMetadata(
            title: "Test",
            creator: "Author",
            dcDescription: "A doc",
            subject: ["s1", "s2"],
            language: "en"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DublinCoreMetadata.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip with empty metadata")
    func codableRoundTripEmpty() throws {
        let original = DublinCoreMetadata()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DublinCoreMetadata.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description shows title when present")
    func descriptionWithTitle() {
        let dc = DublinCoreMetadata(title: "My Title")
        #expect(dc.description.contains("My Title"))
    }

    @Test("Description shows empty for empty metadata")
    func descriptionEmpty() {
        let dc = DublinCoreMetadata()
        #expect(dc.description.contains("empty"))
    }

    @Test("Description shows creator when present")
    func descriptionWithCreator() {
        let dc = DublinCoreMetadata(creator: "Author")
        #expect(dc.description.contains("Author"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let dc = DublinCoreMetadata(title: "T")
        let result = await Task { dc }.value
        #expect(result == dc)
    }
}
