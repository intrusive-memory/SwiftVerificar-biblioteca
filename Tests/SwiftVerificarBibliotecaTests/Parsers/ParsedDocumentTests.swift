import Testing
import Foundation
import SwiftVerificarValidationProfiles
@testable import SwiftVerificarBiblioteca

// MARK: - Test Doubles (local to this file)

/// A full-featured mock ParsedDocument for testing the expanded protocol.
private struct FullMockParsedDocument: ParsedDocument {
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
private struct StubValidationObject: ValidationObject {
    let validationProperties: [String: String]
    let location: PDFLocation?

    init(properties: [String: String] = [:], location: PDFLocation? = nil) {
        self.validationProperties = properties
        self.location = location
    }
}

// MARK: - Expanded ParsedDocument Protocol Tests

@Suite("Expanded ParsedDocument Protocol Tests")
struct ExpandedParsedDocumentTests {

    // MARK: - URL

    @Test("Document stores URL")
    func urlStored() {
        let url = URL(fileURLWithPath: "/tmp/myfile.pdf")
        let doc = FullMockParsedDocument(url: url)
        #expect(doc.url == url)
    }

    // MARK: - Flavour

    @Test("Document stores flavour")
    func flavourStored() {
        let doc = FullMockParsedDocument(flavour: .pdfUA2)
        #expect(doc.flavour == .pdfUA2)
    }

    @Test("Document flavour can be nil")
    func flavourNil() {
        let doc = FullMockParsedDocument(flavour: nil)
        #expect(doc.flavour == nil)
    }

    @Test("Various flavour identifiers")
    func variousFlavours() {
        let flavours: [PDFFlavour] = [.pdfUA1, .pdfUA2, .pdfA1a, .pdfA2b, .pdfA3u, .wcag22]
        for f in flavours {
            let doc = FullMockParsedDocument(flavour: f)
            #expect(doc.flavour == f)
        }
    }

    // MARK: - Page Count

    @Test("Document stores page count")
    func pageCountStored() {
        let doc = FullMockParsedDocument(pageCount: 42)
        #expect(doc.pageCount == 42)
    }

    @Test("Document page count defaults to zero")
    func pageCountDefaultZero() {
        let doc = FullMockParsedDocument()
        #expect(doc.pageCount == 0)
    }

    @Test("Document page count can be one")
    func pageCountOne() {
        let doc = FullMockParsedDocument(pageCount: 1)
        #expect(doc.pageCount == 1)
    }

    @Test("Document page count large value")
    func pageCountLarge() {
        let doc = FullMockParsedDocument(pageCount: 10000)
        #expect(doc.pageCount == 10000)
    }

    // MARK: - Metadata

    @Test("Document stores metadata")
    func metadataStored() {
        let meta = DocumentMetadata(title: "Test Document")
        let doc = FullMockParsedDocument(metadata: meta)
        #expect(doc.metadata?.title == "Test Document")
    }

    @Test("Document metadata can be nil")
    func metadataNil() {
        let doc = FullMockParsedDocument(metadata: nil)
        #expect(doc.metadata == nil)
    }

    @Test("Document metadata with all fields")
    func metadataAllFields() {
        let now = Date()
        let meta = DocumentMetadata(
            title: "Title",
            author: "Author",
            subject: "Subject",
            keywords: "key1, key2",
            creator: "Creator App",
            producer: "Producer App",
            creationDate: now,
            modificationDate: now,
            hasXMPMetadata: true
        )
        let doc = FullMockParsedDocument(metadata: meta)
        #expect(doc.metadata == meta)
    }

    // MARK: - Structure Tree

    @Test("Document stores hasStructureTree true")
    func hasStructureTreeTrue() {
        let doc = FullMockParsedDocument(hasStructureTree: true)
        #expect(doc.hasStructureTree == true)
    }

    @Test("Document stores hasStructureTree false")
    func hasStructureTreeFalse() {
        let doc = FullMockParsedDocument(hasStructureTree: false)
        #expect(doc.hasStructureTree == false)
    }

    @Test("Document hasStructureTree defaults to false")
    func hasStructureTreeDefault() {
        let doc = FullMockParsedDocument()
        #expect(doc.hasStructureTree == false)
    }

    // MARK: - Objects

    @Test("Document returns objects by type")
    func objectsByType() {
        let obj = StubValidationObject(properties: ["key": "value"])
        let doc = FullMockParsedDocument(objectsByType: ["CosDocument": [obj]])
        let objects = doc.objects(ofType: "CosDocument")
        #expect(objects.count == 1)
    }

    @Test("Document returns empty array for unknown type")
    func objectsUnknownType() {
        let doc = FullMockParsedDocument()
        #expect(doc.objects(ofType: "Unknown").isEmpty)
    }

    @Test("Document returns multiple objects for same type")
    func multipleObjectsSameType() {
        let obj1 = StubValidationObject(properties: ["a": "1"])
        let obj2 = StubValidationObject(properties: ["b": "2"])
        let obj3 = StubValidationObject(properties: ["c": "3"])
        let doc = FullMockParsedDocument(objectsByType: ["PDPage": [obj1, obj2, obj3]])
        #expect(doc.objects(ofType: "PDPage").count == 3)
    }

    @Test("Document supports multiple object types")
    func multipleObjectTypes() {
        let cosObj = StubValidationObject(properties: ["version": "1.7"])
        let pageObj = StubValidationObject(properties: ["mediaBox": "0 0 612 792"])
        let doc = FullMockParsedDocument(objectsByType: [
            "CosDocument": [cosObj],
            "PDPage": [pageObj],
        ])
        #expect(doc.objects(ofType: "CosDocument").count == 1)
        #expect(doc.objects(ofType: "PDPage").count == 1)
        #expect(doc.objects(ofType: "SEFigure").isEmpty)
    }

    // MARK: - Sendable

    @Test("Document is Sendable across task boundaries")
    func sendable() async {
        let doc = FullMockParsedDocument(
            url: URL(fileURLWithPath: "/tmp/sendable.pdf"),
            pageCount: 5
        )
        let result = await Task {
            (doc.url, doc.pageCount)
        }.value
        #expect(result.0 == doc.url)
        #expect(result.1 == 5)
    }

    // MARK: - Realistic Scenario

    @Test("Realistic tagged PDF document representation")
    func realisticTaggedPDF() {
        let meta = DocumentMetadata(
            title: "Annual Report 2025",
            author: "Acme Corp",
            creator: "Microsoft Word",
            producer: "macOS Quartz PDFContext",
            hasXMPMetadata: true
        )
        let cosObj = StubValidationObject(
            properties: ["headerVersion": "1.7", "containsStructTreeRoot": "true"]
        )
        let pageObj = StubValidationObject(
            properties: ["mediaBox": "0 0 612 792"],
            location: PDFLocation(pageNumber: 1)
        )
        let seObj = StubValidationObject(
            properties: ["Alt": "Company logo", "ActualText": ""],
            location: PDFLocation(pageNumber: 1, structureID: "SE-3")
        )

        let doc = FullMockParsedDocument(
            url: URL(fileURLWithPath: "/tmp/annual-report.pdf"),
            flavour: .pdfUA2,
            pageCount: 42,
            metadata: meta,
            hasStructureTree: true,
            objectsByType: [
                "CosDocument": [cosObj],
                "PDPage": [pageObj],
                "SEFigure": [seObj],
            ]
        )

        #expect(doc.flavour == .pdfUA2)
        #expect(doc.pageCount == 42)
        #expect(doc.hasStructureTree == true)
        #expect(doc.metadata?.title == "Annual Report 2025")
        #expect(doc.metadata?.hasXMPMetadata == true)
        #expect(doc.objects(ofType: "CosDocument").count == 1)
        #expect(doc.objects(ofType: "PDPage").count == 1)
        #expect(doc.objects(ofType: "SEFigure").count == 1)
    }
}

// MARK: - DocumentMetadata Tests

@Suite("DocumentMetadata Tests")
struct DocumentMetadataTests {

    // MARK: - Initialization

    @Test("Default initializer creates empty metadata")
    func defaultInitializer() {
        let meta = DocumentMetadata()
        #expect(meta.title == nil)
        #expect(meta.author == nil)
        #expect(meta.subject == nil)
        #expect(meta.keywords == nil)
        #expect(meta.creator == nil)
        #expect(meta.producer == nil)
        #expect(meta.creationDate == nil)
        #expect(meta.modificationDate == nil)
        #expect(meta.hasXMPMetadata == false)
    }

    @Test("Full initializer stores all fields")
    func fullInitializer() {
        let now = Date()
        let meta = DocumentMetadata(
            title: "My Title",
            author: "Author Name",
            subject: "Subject Line",
            keywords: "pdf, accessibility",
            creator: "Word",
            producer: "macOS",
            creationDate: now,
            modificationDate: now,
            hasXMPMetadata: true
        )
        #expect(meta.title == "My Title")
        #expect(meta.author == "Author Name")
        #expect(meta.subject == "Subject Line")
        #expect(meta.keywords == "pdf, accessibility")
        #expect(meta.creator == "Word")
        #expect(meta.producer == "macOS")
        #expect(meta.creationDate == now)
        #expect(meta.modificationDate == now)
        #expect(meta.hasXMPMetadata == true)
    }

    @Test("Partial initializer with only title")
    func partialTitle() {
        let meta = DocumentMetadata(title: "Only Title")
        #expect(meta.title == "Only Title")
        #expect(meta.author == nil)
        #expect(meta.hasXMPMetadata == false)
    }

    @Test("Partial initializer with only author")
    func partialAuthor() {
        let meta = DocumentMetadata(author: "Only Author")
        #expect(meta.title == nil)
        #expect(meta.author == "Only Author")
    }

    @Test("Empty string values are valid")
    func emptyStringValues() {
        let meta = DocumentMetadata(
            title: "",
            author: "",
            subject: ""
        )
        #expect(meta.title == "")
        #expect(meta.author == "")
        #expect(meta.subject == "")
    }

    // MARK: - Equatable

    @Test("Two identical metadata are equal")
    func equatable() {
        let now = Date()
        let a = DocumentMetadata(title: "T", author: "A", creationDate: now)
        let b = DocumentMetadata(title: "T", author: "A", creationDate: now)
        #expect(a == b)
    }

    @Test("Metadata with different titles are not equal")
    func notEqualTitle() {
        let a = DocumentMetadata(title: "A")
        let b = DocumentMetadata(title: "B")
        #expect(a != b)
    }

    @Test("Metadata with different authors are not equal")
    func notEqualAuthor() {
        let a = DocumentMetadata(author: "Alice")
        let b = DocumentMetadata(author: "Bob")
        #expect(a != b)
    }

    @Test("Metadata with different XMP flags are not equal")
    func notEqualXMP() {
        let a = DocumentMetadata(hasXMPMetadata: true)
        let b = DocumentMetadata(hasXMPMetadata: false)
        #expect(a != b)
    }

    @Test("Default metadata instances are equal")
    func defaultEqual() {
        let a = DocumentMetadata()
        let b = DocumentMetadata()
        #expect(a == b)
    }

    // MARK: - Hashable

    @Test("Equal metadata produce same hash")
    func hashableEqual() {
        let a = DocumentMetadata(title: "Same", author: "Same")
        let b = DocumentMetadata(title: "Same", author: "Same")
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Can be used as dictionary key")
    func dictionaryKey() {
        let meta = DocumentMetadata(title: "Key")
        var dict: [DocumentMetadata: Int] = [:]
        dict[meta] = 42
        #expect(dict[meta] == 42)
    }

    @Test("Can be stored in a Set")
    func setStorage() {
        let a = DocumentMetadata(title: "A")
        let b = DocumentMetadata(title: "B")
        let c = DocumentMetadata(title: "A") // same as a
        let set: Set<DocumentMetadata> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("Encodes and decodes to JSON")
    func codable() throws {
        let original = DocumentMetadata(
            title: "Test",
            author: "Author",
            hasXMPMetadata: true
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DocumentMetadata.self, from: data)
        #expect(decoded == original)
    }

    @Test("Encodes and decodes empty metadata")
    func codableEmpty() throws {
        let original = DocumentMetadata()
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DocumentMetadata.self, from: data)
        #expect(decoded == original)
    }

    @Test("Encodes and decodes with dates")
    func codableWithDates() throws {
        let now = Date()
        let original = DocumentMetadata(
            creationDate: now,
            modificationDate: now
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DocumentMetadata.self, from: data)
        // Date precision may differ slightly but should round-trip
        #expect(decoded.creationDate != nil)
        #expect(decoded.modificationDate != nil)
    }

    @Test("Full metadata round-trips through JSON")
    func fullCodableRoundTrip() throws {
        let original = DocumentMetadata(
            title: "Report",
            author: "Jane",
            subject: "Annual",
            keywords: "finance, 2025",
            creator: "Pages",
            producer: "macOS",
            hasXMPMetadata: true
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DocumentMetadata.self, from: data)
        #expect(decoded.title == original.title)
        #expect(decoded.author == original.author)
        #expect(decoded.subject == original.subject)
        #expect(decoded.keywords == original.keywords)
        #expect(decoded.creator == original.creator)
        #expect(decoded.producer == original.producer)
        #expect(decoded.hasXMPMetadata == original.hasXMPMetadata)
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let meta = DocumentMetadata(title: "Sendable")
        let result = await Task {
            meta.title
        }.value
        #expect(result == "Sendable")
    }

    // MARK: - CustomStringConvertible

    @Test("Description of metadata with title")
    func descriptionWithTitle() {
        let meta = DocumentMetadata(title: "My Title")
        #expect(meta.description.contains("My Title"))
    }

    @Test("Description of metadata with author")
    func descriptionWithAuthor() {
        let meta = DocumentMetadata(author: "My Author")
        #expect(meta.description.contains("My Author"))
    }

    @Test("Description of metadata with XMP")
    func descriptionWithXMP() {
        let meta = DocumentMetadata(hasXMPMetadata: true)
        #expect(meta.description.contains("xmp=true"))
    }

    @Test("Description of empty metadata")
    func descriptionEmpty() {
        let meta = DocumentMetadata()
        #expect(meta.description == "DocumentMetadata(empty)")
    }

    @Test("Description includes DocumentMetadata prefix")
    func descriptionPrefix() {
        let meta = DocumentMetadata(title: "Test")
        #expect(meta.description.hasPrefix("DocumentMetadata("))
    }
}
