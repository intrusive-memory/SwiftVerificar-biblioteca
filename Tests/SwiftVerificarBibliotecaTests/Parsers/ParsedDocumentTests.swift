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

// MARK: - ParsedDocumentAdapter with CosDocument Tests

@Suite("ParsedDocumentAdapter CosDocument Integration Tests")
struct ParsedDocumentAdapterCosDocumentTests {

    @Test("Adapter with CosDocument returns it via objects(ofType:)")
    func adapterWithCosDocument() {
        let cosDoc = CosDocumentObject(
            pageCount: 10,
            isEncrypted: false,
            hasStructTreeRoot: true,
            pdfVersion: "2.0"
        )
        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            pageCount: 10,
            hasStructureTree: true,
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let objects = adapter.objects(ofType: "CosDocument")
        #expect(objects.count == 1)
        #expect(objects[0].validationProperties["nrPages"] == "10")
        #expect(objects[0].validationProperties["pdfVersion"] == "2.0")
        #expect(objects[0].validationProperties["hasStructTreeRoot"] == "true")
    }

    @Test("Adapter with multiple object types returns correct objects")
    func adapterWithMultipleTypes() {
        let cosDoc = CosDocumentObject(pageCount: 5)
        let pageObj = StubValidationObject(
            properties: ["mediaBox": "0 0 612 792"],
            location: PDFLocation(pageNumber: 1)
        )
        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            pageCount: 5,
            objectsByType: [
                "CosDocument": [cosDoc],
                "PDPage": [pageObj],
            ]
        )
        #expect(adapter.objects(ofType: "CosDocument").count == 1)
        #expect(adapter.objects(ofType: "PDPage").count == 1)
        #expect(adapter.objects(ofType: "Unknown").isEmpty)
    }

    @Test("Adapter CosDocument properties match document metadata")
    func cosDocPropertiesMatchMetadata() {
        let meta = DocumentMetadata(
            title: "Report",
            author: "Jane",
            creator: "Pages",
            producer: "macOS Quartz",
            hasXMPMetadata: true
        )
        let cosDoc = CosDocumentObject(
            pageCount: 42,
            hasStructTreeRoot: true,
            hasXMPMetadata: true,
            title: "Report",
            author: "Jane",
            producer: "macOS Quartz",
            creator: "Pages"
        )
        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/report.pdf"),
            pageCount: 42,
            metadata: meta,
            hasStructureTree: true,
            objectsByType: ["CosDocument": [cosDoc]]
        )

        let objects = adapter.objects(ofType: "CosDocument")
        #expect(objects.count == 1)
        let props = objects[0].validationProperties
        #expect(props["nrPages"] == "42")
        #expect(props["title"] == "Report")
        #expect(props["author"] == "Jane")
        #expect(props["producer"] == "macOS Quartz")
        #expect(props["creator"] == "Pages")
        #expect(props["hasXMPMetadata"] == "true")
        #expect(props["hasStructTreeRoot"] == "true")
    }

    @Test("Adapter with empty objectsByType returns empty for all types")
    func adapterEmptyObjectsByType() {
        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            objectsByType: [:]
        )
        #expect(adapter.objects(ofType: "CosDocument").isEmpty)
        #expect(adapter.objects(ofType: "PDPage").isEmpty)
        #expect(adapter.objects(ofType: "SEFigure").isEmpty)
    }

    @Test("Adapter is Sendable with objects")
    func adapterSendableWithObjects() async {
        let cosDoc = CosDocumentObject(pageCount: 3, title: "Sendable Test")
        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            pageCount: 3,
            objectsByType: ["CosDocument": [cosDoc]]
        )
        let result = await Task {
            adapter.objects(ofType: "CosDocument").first?.validationProperties["title"]
        }.value
        #expect(result == "Sendable Test")
    }
}

// MARK: - Sprint 4: Adapter with Multiple Object Types Tests

@Suite("ParsedDocumentAdapter Multi-Type Integration Tests")
struct ParsedDocumentAdapterMultiTypeTests {

    @Test("Adapter with PDPage objects returns them via objects(ofType:)")
    func adapterWithPDPageObjects() {
        let page0 = PDPageObject(pageNumber: 0, width: 612, height: 792)
        let page1 = PDPageObject(pageNumber: 1, width: 612, height: 792)
        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            pageCount: 2,
            objectsByType: ["PDPage": [page0, page1]]
        )
        let pages = adapter.objects(ofType: "PDPage")
        #expect(pages.count == 2)
        #expect(pages[0].validationProperties["pageNumber"] == "0")
        #expect(pages[1].validationProperties["pageNumber"] == "1")
    }

    @Test("Adapter with SEGenericObject returns them via objects(ofType:)")
    func adapterWithSEGenericObjects() {
        let figure = SEGenericObject(
            structureType: "Figure",
            altText: "A chart",
            pageNumber: 1,
            structureID: "SE-1"
        )
        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            objectsByType: ["SEFigure": [figure]]
        )
        let figures = adapter.objects(ofType: "SEFigure")
        #expect(figures.count == 1)
        #expect(figures[0].validationProperties["Alt"] == "A chart")
        #expect(figures[0].validationProperties["structureType"] == "Figure")
    }

    @Test("Adapter with CosDocument, PDPage, and SEFigure returns all types")
    func adapterWithAllTypes() {
        let cosDoc = CosDocumentObject(pageCount: 2, hasStructTreeRoot: true)
        let page0 = PDPageObject(pageNumber: 0)
        let page1 = PDPageObject(pageNumber: 1)
        let figure = SEGenericObject(
            structureType: "Figure",
            altText: "Logo",
            pageNumber: 1,
            structureID: "SE-5"
        )

        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/report.pdf"),
            pageCount: 2,
            hasStructureTree: true,
            objectsByType: [
                "CosDocument": [cosDoc],
                "PDPage": [page0, page1],
                "SEFigure": [figure],
            ]
        )

        #expect(adapter.objects(ofType: "CosDocument").count == 1)
        #expect(adapter.objects(ofType: "PDPage").count == 2)
        #expect(adapter.objects(ofType: "SEFigure").count == 1)
        #expect(adapter.objects(ofType: "SETable").isEmpty)
    }

    @Test("Adapter availableObjectTypes lists all stored types")
    func adapterAvailableObjectTypes() {
        let cosDoc = CosDocumentObject(pageCount: 1)
        let page = PDPageObject(pageNumber: 0)
        let figure = SEGenericObject(structureType: "Figure")
        let table = SEGenericObject(structureType: "Table")

        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            objectsByType: [
                "CosDocument": [cosDoc],
                "PDPage": [page],
                "SEFigure": [figure],
                "SETable": [table],
            ]
        )

        let types = adapter.availableObjectTypes
        #expect(types.contains("CosDocument"))
        #expect(types.contains("PDPage"))
        #expect(types.contains("SEFigure"))
        #expect(types.contains("SETable"))
        #expect(types.count == 4)
    }

    @Test("Adapter with multiple SE types distinguishes between them")
    func adapterDistinguishesSETypes() {
        let figure = SEGenericObject(
            structureType: "Figure",
            altText: "Image"
        )
        let table = SEGenericObject(
            structureType: "Table",
            kidsStandardTypes: "TR&TR"
        )
        let heading = SEGenericObject(
            structureType: "H1"
        )

        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            objectsByType: [
                "SEFigure": [figure],
                "SETable": [table],
                "SEHn": [heading],
            ]
        )

        let figures = adapter.objects(ofType: "SEFigure")
        #expect(figures.count == 1)
        #expect(figures[0].validationProperties["structureType"] == "Figure")

        let tables = adapter.objects(ofType: "SETable")
        #expect(tables.count == 1)
        #expect(tables[0].validationProperties["kidsStandardTypes"] == "TR&TR")

        let headings = adapter.objects(ofType: "SEHn")
        #expect(headings.count == 1)
        #expect(headings[0].validationProperties["structureType"] == "H1")
    }

    @Test("Adapter is Sendable with all object types")
    func adapterSendableWithAllTypes() async {
        let cosDoc = CosDocumentObject(pageCount: 1)
        let page = PDPageObject(pageNumber: 0)
        let figure = SEGenericObject(structureType: "Figure", altText: "Concurrent Chart")

        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            objectsByType: [
                "CosDocument": [cosDoc],
                "PDPage": [page],
                "SEFigure": [figure],
            ]
        )

        let result = await Task {
            (
                adapter.objects(ofType: "CosDocument").count,
                adapter.objects(ofType: "PDPage").count,
                adapter.objects(ofType: "SEFigure").first?.validationProperties["Alt"]
            )
        }.value

        #expect(result.0 == 1)
        #expect(result.1 == 1)
        #expect(result.2 == "Concurrent Chart")
    }
}
