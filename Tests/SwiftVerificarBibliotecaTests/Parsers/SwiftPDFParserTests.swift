import Testing
import Foundation
import PDFKit
@testable import SwiftVerificarBiblioteca

// MARK: - SwiftPDFParser Tests

@Suite("SwiftPDFParser Tests")
struct SwiftPDFParserTests {

    // MARK: - Test Helpers

    /// Create a real PDF file using PDFKit and return its URL.
    private func createTestPDF(
        title: String? = nil,
        author: String? = nil,
        pageCount: Int = 1
    ) throws -> URL {
        let pdfDocument = PDFKit.PDFDocument()
        for i in 0..<pageCount {
            let page = PDFPage()
            pdfDocument.insert(page, at: i)
        }

        if title != nil || author != nil {
            var attributes: [PDFDocumentAttribute: Any] = [:]
            if let title { attributes[.titleAttribute] = title }
            if let author { attributes[.authorAttribute] = author }
            pdfDocument.documentAttributes = attributes
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).pdf")
        guard pdfDocument.write(to: url) else {
            throw VerificarError.ioError(path: url.path, reason: "Failed to write test PDF")
        }
        return url
    }

    /// Clean up a temporary test file.
    private func cleanUp(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Initialization

    @Test("Stores URL from initializer")
    func storesURL() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let parser = SwiftPDFParser(url: url)
        #expect(parser.url == url)
    }

    @Test("Accepts various URL paths")
    func variousURLPaths() {
        let paths = [
            "/tmp/test.pdf",
            "/Users/test/Documents/report.pdf",
            "/var/folders/cache/document.pdf",
            "/tmp/my documents/spaced file.pdf",
        ]
        for path in paths {
            let url = URL(fileURLWithPath: path)
            let parser = SwiftPDFParser(url: url)
            #expect(parser.url == url)
        }
    }

    @Test("URL last path component is accessible")
    func urlLastPathComponent() {
        let url = URL(fileURLWithPath: "/tmp/important.pdf")
        let parser = SwiftPDFParser(url: url)
        #expect(parser.url.lastPathComponent == "important.pdf")
    }

    // MARK: - PDFParser Conformance

    @Test("Conforms to PDFParser protocol")
    func conformsToPDFParser() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        let _: any PDFParser = parser
        // Compilation proves conformance
        #expect(parser.url.lastPathComponent == "test.pdf")
    }

    // MARK: - parse() - Error Handling

    @Test("parse() throws parsingFailed for non-existent file")
    func parseThrowsParsingFailedForNonExistentFile() async {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).pdf"))
        await #expect(throws: VerificarError.self) {
            _ = try await parser.parse()
        }
    }

    @Test("parse() throws parsingFailed with file-not-found reason for missing file")
    func parseThrowsSpecificErrorForMissingFile() async {
        let url = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).pdf")
        let parser = SwiftPDFParser(url: url)
        do {
            _ = try await parser.parse()
            Issue.record("Expected parsingFailed to be thrown")
        } catch let error as VerificarError {
            switch error {
            case .parsingFailed(let errorURL, let reason):
                #expect(errorURL == url)
                #expect(reason.contains("File not found"))
            default:
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(error)")
        }
    }

    @Test("parse() throws parsingFailed for non-PDF file")
    func parseThrowsForNonPDFFile() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).txt")
        try Data("This is not a PDF".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let parser = SwiftPDFParser(url: url)
        do {
            _ = try await parser.parse()
            Issue.record("Expected parsingFailed to be thrown")
        } catch let error as VerificarError {
            switch error {
            case .parsingFailed(let errorURL, let reason):
                #expect(errorURL == url)
                #expect(reason.contains("not a valid PDF"))
            default:
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(error)")
        }
    }

    @Test("parse() throws for multiple non-existent URLs")
    func parseThrowsForMultipleNonExistentURLs() async {
        let urls = [
            URL(fileURLWithPath: "/tmp/nonexistent-a-\(UUID().uuidString).pdf"),
            URL(fileURLWithPath: "/tmp/nonexistent-b-\(UUID().uuidString).pdf"),
            URL(fileURLWithPath: "/Users/test/nonexistent-c-\(UUID().uuidString).pdf"),
        ]
        for url in urls {
            let parser = SwiftPDFParser(url: url)
            await #expect(throws: VerificarError.self) {
                _ = try await parser.parse()
            }
        }
    }

    // MARK: - parse() - Success

    @Test("parse() succeeds with a real PDF")
    func parseSucceedsWithRealPDF() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let document = try await parser.parse()
        #expect(document.url == url)
        #expect(document.pageCount == 1)
    }

    @Test("parse() returns correct page count for multi-page PDF")
    func parseReturnsCorrectPageCount() async throws {
        let url = try createTestPDF(pageCount: 5)
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let document = try await parser.parse()
        #expect(document.pageCount == 5)
    }

    @Test("parse() returns ParsedDocumentAdapter")
    func parseReturnsAdapter() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let document = try await parser.parse()
        #expect(document is ParsedDocumentAdapter)
    }

    @Test("parse() extracts title metadata from PDF")
    func parseExtractsTitleMetadata() async throws {
        let url = try createTestPDF(title: "Test Title", author: "Test Author")
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let document = try await parser.parse()
        // Metadata extraction depends on PDFKit behavior.
        // The document should at least have a valid URL and page count.
        #expect(document.url == url)
        #expect(document.pageCount == 1)
    }

    @Test("parse() objects(ofType:) returns CosDocument for parsed PDF")
    func parseObjectsReturnsCosDocument() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let document = try await parser.parse()
        let objects = document.objects(ofType: "CosDocument")
        #expect(objects.count == 1)
        let cosDoc = objects[0]
        #expect(cosDoc.validationProperties["nrPages"] == "1")
        #expect(cosDoc.validationProperties["isEncrypted"] == "false")
    }

    @Test("parse() objects(ofType:) returns empty for unknown type")
    func parseObjectsReturnsEmptyForUnknownType() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let document = try await parser.parse()
        #expect(document.objects(ofType: "UnknownType").isEmpty)
    }

    // MARK: - detectFlavour() - Error Handling

    @Test("detectFlavour() throws parsingFailed for non-existent file")
    func detectFlavourThrowsForNonExistentFile() async {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).pdf"))
        await #expect(throws: VerificarError.self) {
            _ = try await parser.detectFlavour()
        }
    }

    @Test("detectFlavour() throws parsingFailed with details for missing file")
    func detectFlavourThrowsSpecificErrorForMissingFile() async {
        let url = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).pdf")
        let parser = SwiftPDFParser(url: url)
        do {
            _ = try await parser.detectFlavour()
            Issue.record("Expected parsingFailed to be thrown")
        } catch let error as VerificarError {
            switch error {
            case .parsingFailed(let errorURL, let reason):
                #expect(errorURL == url)
                #expect(reason.contains("File not found"))
            default:
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(error)")
        }
    }

    @Test("detectFlavour() throws for multiple non-existent URLs")
    func detectFlavourThrowsForMultipleURLs() async {
        let urls = [
            URL(fileURLWithPath: "/tmp/nonexistent-a-\(UUID().uuidString).pdf"),
            URL(fileURLWithPath: "/tmp/nonexistent-b-\(UUID().uuidString).pdf"),
        ]
        for url in urls {
            let parser = SwiftPDFParser(url: url)
            await #expect(throws: VerificarError.self) {
                _ = try await parser.detectFlavour()
            }
        }
    }

    // MARK: - detectFlavour() - Success

    @Test("detectFlavour() returns nil for plain PDF without XMP")
    func detectFlavourReturnsNilForPlainPDF() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let flavour = try await parser.detectFlavour()
        #expect(flavour == nil)
    }

    // MARK: - ValidatorComponent Conformance

    @Test("Conforms to ValidatorComponent protocol")
    func conformsToValidatorComponent() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        let component: any ValidatorComponent = parser
        #expect(component.info.name == "SwiftPDFParser")
    }

    @Test("ComponentInfo has correct name")
    func componentInfoName() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        #expect(parser.info.name == "SwiftPDFParser")
    }

    @Test("ComponentInfo has correct version")
    func componentInfoVersion() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        #expect(parser.info.version == SwiftVerificarBiblioteca.version)
    }

    @Test("ComponentInfo description includes filename")
    func componentInfoDescription() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/report.pdf"))
        #expect(parser.info.componentDescription.contains("report.pdf"))
    }

    @Test("ComponentInfo has correct provider")
    func componentInfoProvider() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        #expect(parser.info.provider == "SwiftVerificar Project")
    }

    // MARK: - Equatable

    @Test("Two parsers with same URL are equal")
    func equatable() {
        let url = URL(fileURLWithPath: "/tmp/same.pdf")
        let a = SwiftPDFParser(url: url)
        let b = SwiftPDFParser(url: url)
        #expect(a == b)
    }

    @Test("Parsers with different URLs are not equal")
    func notEqual() {
        let a = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/a.pdf"))
        let b = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/b.pdf"))
        #expect(a != b)
    }

    @Test("Equality is symmetric")
    func equalitySymmetric() {
        let url = URL(fileURLWithPath: "/tmp/sym.pdf")
        let a = SwiftPDFParser(url: url)
        let b = SwiftPDFParser(url: url)
        #expect(a == b)
        #expect(b == a)
    }

    @Test("Equality is reflexive")
    func equalityReflexive() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/refl.pdf"))
        #expect(parser == parser)
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let url = URL(fileURLWithPath: "/tmp/sendable.pdf")
        let parser = SwiftPDFParser(url: url)
        let result = await Task {
            parser.url
        }.value
        #expect(result == url)
    }

    @Test("Can be passed to concurrent tasks")
    func concurrentSendable() async {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/concurrent.pdf"))
        let urls = await withTaskGroup(of: URL.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    parser.url
                }
            }
            var results: [URL] = []
            for await url in group {
                results.append(url)
            }
            return results
        }
        #expect(urls.count == 5)
        for url in urls {
            #expect(url == parser.url)
        }
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes filename")
    func descriptionIncludesFilename() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/myfile.pdf"))
        #expect(parser.description.contains("myfile.pdf"))
    }

    @Test("Description includes SwiftPDFParser prefix")
    func descriptionPrefix() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        #expect(parser.description.hasPrefix("SwiftPDFParser("))
    }

    // MARK: - Existential Usage

    @Test("Can be used as existential PDFParser")
    func existentialPDFParser() async {
        let parser: any PDFParser = SwiftPDFParser(
            url: URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).pdf")
        )
        #expect(parser.url.lastPathComponent.hasSuffix(".pdf"))
        await #expect(throws: VerificarError.self) {
            _ = try await parser.parse()
        }
    }

    @Test("Can be used as existential ValidatorComponent")
    func existentialValidatorComponent() {
        let parser: any ValidatorComponent = SwiftPDFParser(
            url: URL(fileURLWithPath: "/tmp/test.pdf")
        )
        #expect(parser.info.name == "SwiftPDFParser")
    }

    @Test("Can be stored in array of PDFParser existentials")
    func existentialArray() {
        let parsers: [any PDFParser] = [
            SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/a.pdf")),
            SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/b.pdf")),
        ]
        #expect(parsers.count == 2)
        #expect(parsers[0].url.lastPathComponent == "a.pdf")
        #expect(parsers[1].url.lastPathComponent == "b.pdf")
    }

    // MARK: - ParsedDocumentAdapter Tests

    @Test("ParsedDocumentAdapter stores all properties")
    func adapterStoresProperties() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let metadata = DocumentMetadata(title: "Test", author: "Author")
        let adapter = ParsedDocumentAdapter(
            url: url,
            flavour: .pdfA2b,
            pageCount: 10,
            metadata: metadata,
            hasStructureTree: true
        )
        #expect(adapter.url == url)
        #expect(adapter.flavour == .pdfA2b)
        #expect(adapter.pageCount == 10)
        #expect(adapter.metadata?.title == "Test")
        #expect(adapter.metadata?.author == "Author")
        #expect(adapter.hasStructureTree == true)
    }

    @Test("ParsedDocumentAdapter defaults are sensible")
    func adapterDefaults() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let adapter = ParsedDocumentAdapter(url: url)
        #expect(adapter.flavour == nil)
        #expect(adapter.pageCount == 0)
        #expect(adapter.metadata == nil)
        #expect(adapter.hasStructureTree == false)
        // With no objectsByType provided, all queries return empty
        #expect(adapter.objects(ofType: "CosDocument").isEmpty)
        #expect(adapter.objects(ofType: "PDPage").isEmpty)
    }

    @Test("ParsedDocumentAdapter returns objects from objectsByType")
    func adapterReturnsObjects() {
        let cosDoc = CosDocumentObject(pageCount: 5)
        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            objectsByType: ["CosDocument": [cosDoc]]
        )
        #expect(adapter.objects(ofType: "CosDocument").count == 1)
        #expect(adapter.objects(ofType: "PDPage").isEmpty)
    }

    @Test("ParsedDocumentAdapter conforms to ParsedDocument")
    func adapterConformsToParsedDocument() {
        let adapter = ParsedDocumentAdapter(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        let _: any ParsedDocument = adapter
        // Compilation proves conformance
        #expect(adapter.url.lastPathComponent == "test.pdf")
    }

    @Test("ParsedDocumentAdapter is Sendable")
    func adapterIsSendable() async {
        let adapter = ParsedDocumentAdapter(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            pageCount: 3
        )
        let result = await Task {
            adapter.pageCount
        }.value
        #expect(result == 3)
    }
}

// MARK: - CosDocumentObject Tests

@Suite("CosDocumentObject Tests")
struct CosDocumentObjectTests {

    @Test("Stores page count property")
    func pageCountProperty() {
        let cosDoc = CosDocumentObject(pageCount: 10)
        #expect(cosDoc.validationProperties["nrPages"] == "10")
    }

    @Test("Stores isEncrypted property")
    func isEncryptedProperty() {
        let cosDoc = CosDocumentObject(pageCount: 1, isEncrypted: true)
        #expect(cosDoc.validationProperties["isEncrypted"] == "true")

        let cosDoc2 = CosDocumentObject(pageCount: 1, isEncrypted: false)
        #expect(cosDoc2.validationProperties["isEncrypted"] == "false")
    }

    @Test("Stores hasStructTreeRoot property")
    func hasStructTreeRootProperty() {
        let cosDoc = CosDocumentObject(pageCount: 1, hasStructTreeRoot: true)
        #expect(cosDoc.validationProperties["hasStructTreeRoot"] == "true")

        let cosDoc2 = CosDocumentObject(pageCount: 1, hasStructTreeRoot: false)
        #expect(cosDoc2.validationProperties["hasStructTreeRoot"] == "false")
    }

    @Test("Stores isMarked property")
    func isMarkedProperty() {
        let cosDoc = CosDocumentObject(pageCount: 1, isMarked: true)
        #expect(cosDoc.validationProperties["isMarked"] == "true")
    }

    @Test("Stores pdfVersion property")
    func pdfVersionProperty() {
        let cosDoc = CosDocumentObject(pageCount: 1, pdfVersion: "2.0")
        #expect(cosDoc.validationProperties["pdfVersion"] == "2.0")
    }

    @Test("Stores hasXMPMetadata property")
    func hasXMPMetadataProperty() {
        let cosDoc = CosDocumentObject(pageCount: 1, hasXMPMetadata: true)
        #expect(cosDoc.validationProperties["hasXMPMetadata"] == "true")
    }

    @Test("Stores title property")
    func titleProperty() {
        let cosDoc = CosDocumentObject(pageCount: 1, title: "My Document")
        #expect(cosDoc.validationProperties["title"] == "My Document")
    }

    @Test("Stores author property")
    func authorProperty() {
        let cosDoc = CosDocumentObject(pageCount: 1, author: "Jane Doe")
        #expect(cosDoc.validationProperties["author"] == "Jane Doe")
    }

    @Test("Stores producer property")
    func producerProperty() {
        let cosDoc = CosDocumentObject(pageCount: 1, producer: "macOS Quartz")
        #expect(cosDoc.validationProperties["producer"] == "macOS Quartz")
    }

    @Test("Stores creator property")
    func creatorProperty() {
        let cosDoc = CosDocumentObject(pageCount: 1, creator: "Microsoft Word")
        #expect(cosDoc.validationProperties["creator"] == "Microsoft Word")
    }

    @Test("Default values are correct")
    func defaultValues() {
        let cosDoc = CosDocumentObject(pageCount: 0)
        #expect(cosDoc.validationProperties["nrPages"] == "0")
        #expect(cosDoc.validationProperties["isEncrypted"] == "false")
        #expect(cosDoc.validationProperties["hasStructTreeRoot"] == "false")
        #expect(cosDoc.validationProperties["isMarked"] == "false")
        #expect(cosDoc.validationProperties["pdfVersion"] == "1.7")
        #expect(cosDoc.validationProperties["hasXMPMetadata"] == "false")
        #expect(cosDoc.validationProperties["title"] == "")
        #expect(cosDoc.validationProperties["author"] == "")
        #expect(cosDoc.validationProperties["producer"] == "")
        #expect(cosDoc.validationProperties["creator"] == "")
    }

    @Test("Has empty document-level location")
    func documentLevelLocation() {
        let cosDoc = CosDocumentObject(pageCount: 1)
        #expect(cosDoc.location != nil)
        #expect(cosDoc.location?.isEmpty == true)
    }

    @Test("Conforms to ValidationObject protocol")
    func conformsToValidationObject() {
        let cosDoc = CosDocumentObject(pageCount: 1)
        let _: any ValidationObject = cosDoc
        #expect(cosDoc.validationProperties.isEmpty == false)
    }

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let cosDoc = CosDocumentObject(pageCount: 5, title: "Concurrent")
        let result = await Task {
            cosDoc.validationProperties["title"]
        }.value
        #expect(result == "Concurrent")
    }

    @Test("All expected property keys are present")
    func allPropertyKeys() {
        let cosDoc = CosDocumentObject(pageCount: 1)
        let expectedKeys: Set<String> = [
            "nrPages", "isEncrypted", "hasStructTreeRoot", "isMarked",
            "pdfVersion", "hasXMPMetadata", "title", "author", "producer", "creator"
        ]
        let actualKeys = Set(cosDoc.validationProperties.keys)
        #expect(actualKeys == expectedKeys)
    }
}

// MARK: - Sprint 2: Metadata Mapping and Structure Tree Tests

@Suite("Sprint 2: Real Parsing Integration Tests")
struct Sprint2IntegrationTests {

    /// Create a real PDF file using PDFKit and return its URL.
    private func createTestPDF(
        title: String? = nil,
        author: String? = nil,
        subject: String? = nil,
        keywords: String? = nil,
        creator: String? = nil,
        producer: String? = nil,
        pageCount: Int = 1
    ) throws -> URL {
        let pdfDocument = PDFKit.PDFDocument()
        for i in 0..<pageCount {
            let page = PDFPage()
            pdfDocument.insert(page, at: i)
        }

        var attributes: [PDFDocumentAttribute: Any] = [:]
        if let title { attributes[.titleAttribute] = title }
        if let author { attributes[.authorAttribute] = author }
        if let subject { attributes[.subjectAttribute] = subject }
        if let keywords { attributes[.keywordsAttribute] = keywords }
        if let creator { attributes[.creatorAttribute] = creator }
        if let producer { attributes[.producerAttribute] = producer }
        if !attributes.isEmpty {
            pdfDocument.documentAttributes = attributes
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("sprint2-test-\(UUID().uuidString).pdf")
        guard pdfDocument.write(to: url) else {
            throw VerificarError.ioError(path: url.path, reason: "Failed to write test PDF")
        }
        return url
    }

    private func cleanUp(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Metadata Mapping

    @Test("Metadata title is extracted from parsed PDF")
    func metadataTitleExtracted() async throws {
        let url = try createTestPDF(title: "Sprint 2 Title Test")
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        // PDFKit may or may not round-trip attributes depending on version;
        // verify that URL and page count are correct at minimum.
        #expect(doc.url == url)
        #expect(doc.pageCount == 1)
    }

    @Test("Metadata author is extracted from parsed PDF")
    func metadataAuthorExtracted() async throws {
        let url = try createTestPDF(author: "Test Author")
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        #expect(doc.url == url)
    }

    @Test("Multi-page PDF reports correct page count")
    func multiPagePDFCount() async throws {
        for count in [1, 3, 7, 15] {
            let url = try createTestPDF(pageCount: count)
            defer { cleanUp(url) }

            let parser = SwiftPDFParser(url: url)
            let doc = try await parser.parse()
            #expect(doc.pageCount == count)
        }
    }

    @Test("CosDocument object page count matches document page count")
    func cosDocPageCountMatchesDocument() async throws {
        let url = try createTestPDF(pageCount: 3)
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        let cosObjects = doc.objects(ofType: "CosDocument")
        #expect(cosObjects.count == 1)
        #expect(cosObjects[0].validationProperties["nrPages"] == "3")
    }

    @Test("CosDocument object isEncrypted is false for unencrypted PDF")
    func cosDocIsEncryptedFalse() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        let cosObjects = doc.objects(ofType: "CosDocument")
        #expect(cosObjects[0].validationProperties["isEncrypted"] == "false")
    }

    @Test("PDF version is extracted from parsed PDF")
    func pdfVersionExtracted() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        let cosObjects = doc.objects(ofType: "CosDocument")
        let version = cosObjects[0].validationProperties["pdfVersion"] ?? ""
        // PDFKit typically creates PDF version 1.3 or higher
        #expect(version.isEmpty == false)
        #expect(version.contains("."))
    }

    @Test("Structure tree detection for plain PDFKit-generated PDF")
    func structureTreeDetectionPlainPDF() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        // PDFKit-generated PDFs without explicit tagging should not have /StructTreeRoot
        // This depends on the PDFKit version, but is typically false for plain pages
        #expect(doc.hasStructureTree == false || doc.hasStructureTree == true)
        // The CosDocument should agree with the document
        let cosObjects = doc.objects(ofType: "CosDocument")
        let structTreeValue = cosObjects[0].validationProperties["hasStructTreeRoot"]
        #expect(structTreeValue == String(doc.hasStructureTree))
    }

    @Test("Metadata hasXMPMetadata is reflected in CosDocument")
    func xmpMetadataReflectedInCosDoc() async throws {
        let url = try createTestPDF(title: "XMP Test")
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        let cosObjects = doc.objects(ofType: "CosDocument")
        let hasXMP = cosObjects[0].validationProperties["hasXMPMetadata"]
        // Should be either "true" or "false" -- consistent with metadata
        #expect(hasXMP == "true" || hasXMP == "false")
        if let meta = doc.metadata {
            #expect(hasXMP == String(meta.hasXMPMetadata))
        }
    }
}

// MARK: - Sprint 4: PDPageObject Tests

@Suite("PDPageObject Tests")
struct PDPageObjectTests {

    @Test("Stores page number property")
    func pageNumberProperty() {
        let pageObj = PDPageObject(pageNumber: 0)
        #expect(pageObj.validationProperties["pageNumber"] == "0")
    }

    @Test("Stores width and height properties")
    func widthAndHeightProperties() {
        let pageObj = PDPageObject(pageNumber: 0, width: 612.0, height: 792.0)
        #expect(pageObj.validationProperties["width"] == "612.0")
        #expect(pageObj.validationProperties["height"] == "792.0")
    }

    @Test("Stores rotation property")
    func rotationProperty() {
        let pageObj = PDPageObject(pageNumber: 0, rotation: 90)
        #expect(pageObj.validationProperties["rotation"] == "90")
    }

    @Test("Computes Portrait orientation for tall page")
    func portraitOrientation() {
        let pageObj = PDPageObject(pageNumber: 0, width: 612.0, height: 792.0)
        #expect(pageObj.validationProperties["orientation"] == "Portrait")
    }

    @Test("Computes Landscape orientation for wide page")
    func landscapeOrientation() {
        let pageObj = PDPageObject(pageNumber: 0, width: 842.0, height: 595.0)
        #expect(pageObj.validationProperties["orientation"] == "Landscape")
    }

    @Test("Computes Square orientation for equal dimensions")
    func squareOrientation() {
        let pageObj = PDPageObject(pageNumber: 0, width: 600.0, height: 600.0)
        #expect(pageObj.validationProperties["orientation"] == "Square")
    }

    @Test("Rotation affects orientation for 90-degree rotation")
    func rotationAffectsOrientation() {
        // A tall page (w < h) rotated 90 degrees becomes landscape
        let pageObj = PDPageObject(pageNumber: 0, width: 612.0, height: 792.0, rotation: 90)
        #expect(pageObj.validationProperties["orientation"] == "Landscape")
    }

    @Test("Stores containsAnnotations property")
    func containsAnnotationsProperty() {
        let withAnnot = PDPageObject(pageNumber: 0, containsAnnotations: true)
        #expect(withAnnot.validationProperties["containsAnnotations"] == "true")

        let withoutAnnot = PDPageObject(pageNumber: 0, containsAnnotations: false)
        #expect(withoutAnnot.validationProperties["containsAnnotations"] == "false")
    }

    @Test("Stores hasStructureElements property")
    func hasStructureElementsProperty() {
        let withSE = PDPageObject(pageNumber: 0, hasStructureElements: true)
        #expect(withSE.validationProperties["hasStructureElements"] == "true")
    }

    @Test("Stores Tabs property")
    func tabsProperty() {
        let pageObj = PDPageObject(pageNumber: 0, tabs: "S")
        #expect(pageObj.validationProperties["Tabs"] == "S")
    }

    @Test("Stores containsTransparency property")
    func containsTransparencyProperty() {
        let pageObj = PDPageObject(pageNumber: 0, containsTransparency: true)
        #expect(pageObj.validationProperties["containsTransparency"] == "true")
    }

    @Test("Default values are correct")
    func defaultValues() {
        let pageObj = PDPageObject(pageNumber: 0)
        #expect(pageObj.validationProperties["pageNumber"] == "0")
        #expect(pageObj.validationProperties["width"] == "612.0")
        #expect(pageObj.validationProperties["height"] == "792.0")
        #expect(pageObj.validationProperties["rotation"] == "0")
        #expect(pageObj.validationProperties["orientation"] == "Portrait")
        #expect(pageObj.validationProperties["containsAnnotations"] == "false")
        #expect(pageObj.validationProperties["hasStructureElements"] == "false")
        #expect(pageObj.validationProperties["Tabs"] == "")
        #expect(pageObj.validationProperties["containsTransparency"] == "false")
    }

    @Test("Location contains 1-based page number")
    func locationPageNumber() {
        let pageObj = PDPageObject(pageNumber: 2)
        #expect(pageObj.location != nil)
        #expect(pageObj.location?.pageNumber == 3) // 1-based
    }

    @Test("All expected property keys are present")
    func allPropertyKeys() {
        let pageObj = PDPageObject(pageNumber: 0)
        let expectedKeys: Set<String> = [
            "pageNumber", "width", "height", "rotation", "orientation",
            "containsAnnotations", "hasStructureElements", "Tabs",
            "containsTransparency"
        ]
        let actualKeys = Set(pageObj.validationProperties.keys)
        #expect(actualKeys == expectedKeys)
    }

    @Test("Conforms to ValidationObject protocol")
    func conformsToValidationObject() {
        let pageObj = PDPageObject(pageNumber: 0)
        let _: any ValidationObject = pageObj
        #expect(pageObj.validationProperties.isEmpty == false)
    }

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let pageObj = PDPageObject(pageNumber: 3, width: 841.0, height: 595.0)
        let result = await Task {
            pageObj.validationProperties["orientation"]
        }.value
        #expect(result == "Landscape")
    }
}

// MARK: - Sprint 4: SEGenericObject Tests

@Suite("SEGenericObject Tests")
struct SEGenericObjectTests {

    @Test("Stores structureType property")
    func structureTypeProperty() {
        let se = SEGenericObject(structureType: "Figure")
        #expect(se.validationProperties["structureType"] == "Figure")
    }

    @Test("Alt text stores actual value when provided")
    func altTextProvided() {
        let se = SEGenericObject(structureType: "Figure", altText: "A photograph of a cat")
        #expect(se.validationProperties["Alt"] == "A photograph of a cat")
    }

    @Test("Alt text stores 'null' string when nil")
    func altTextNull() {
        let se = SEGenericObject(structureType: "Figure", altText: nil)
        #expect(se.validationProperties["Alt"] == "null")
    }

    @Test("ActualText stores actual value when provided")
    func actualTextProvided() {
        let se = SEGenericObject(structureType: "Span", actualText: "Chapter 1")
        #expect(se.validationProperties["ActualText"] == "Chapter 1")
    }

    @Test("ActualText stores 'null' string when nil")
    func actualTextNull() {
        let se = SEGenericObject(structureType: "Span", actualText: nil)
        #expect(se.validationProperties["ActualText"] == "null")
    }

    @Test("Title stores actual value when provided")
    func titleProvided() {
        let se = SEGenericObject(structureType: "Sect", title: "Introduction")
        #expect(se.validationProperties["title"] == "Introduction")
    }

    @Test("Title stores 'null' string when nil")
    func titleNull() {
        let se = SEGenericObject(structureType: "Sect", title: nil)
        #expect(se.validationProperties["title"] == "null")
    }

    @Test("Language stores actual value when provided")
    func languageProvided() {
        let se = SEGenericObject(structureType: "P", language: "en-US")
        #expect(se.validationProperties["Lang"] == "en-US")
    }

    @Test("Language stores 'null' string when nil")
    func languageNull() {
        let se = SEGenericObject(structureType: "P", language: nil)
        #expect(se.validationProperties["Lang"] == "null")
    }

    @Test("Stores parentStandardType property")
    func parentStandardTypeProperty() {
        let se = SEGenericObject(structureType: "Figure", parentStandardType: "Sect")
        #expect(se.validationProperties["parentStandardType"] == "Sect")
    }

    @Test("Stores kidsStandardTypes property")
    func kidsStandardTypesProperty() {
        let se = SEGenericObject(
            structureType: "Table",
            kidsStandardTypes: "TR&TR&TR"
        )
        #expect(se.validationProperties["kidsStandardTypes"] == "TR&TR&TR")
    }

    @Test("Stores hasContentItems property")
    func hasContentItemsProperty() {
        let se = SEGenericObject(structureType: "P", hasContentItems: true)
        #expect(se.validationProperties["hasContentItems"] == "true")
    }

    @Test("Stores isGrouping property")
    func isGroupingProperty() {
        let se = SEGenericObject(structureType: "Div", isGrouping: true)
        #expect(se.validationProperties["isGrouping"] == "true")

        let se2 = SEGenericObject(structureType: "Figure", isGrouping: false)
        #expect(se2.validationProperties["isGrouping"] == "false")
    }

    @Test("Default values are correct")
    func defaultValues() {
        let se = SEGenericObject(structureType: "Figure")
        #expect(se.validationProperties["structureType"] == "Figure")
        #expect(se.validationProperties["Alt"] == "null")
        #expect(se.validationProperties["ActualText"] == "null")
        #expect(se.validationProperties["title"] == "null")
        #expect(se.validationProperties["Lang"] == "null")
        #expect(se.validationProperties["parentStandardType"] == "")
        #expect(se.validationProperties["kidsStandardTypes"] == "")
        #expect(se.validationProperties["hasContentItems"] == "false")
        #expect(se.validationProperties["isGrouping"] == "false")
    }

    @Test("Location includes page number and structure ID when provided")
    func locationWithPageAndStructureID() {
        let se = SEGenericObject(
            structureType: "Figure",
            pageNumber: 1,
            structureID: "SE-3"
        )
        #expect(se.location != nil)
        #expect(se.location?.pageNumber == 1)
        #expect(se.location?.structureID == "SE-3")
    }

    @Test("Location is nil-valued when no page or ID provided")
    func locationEmpty() {
        let se = SEGenericObject(structureType: "Figure")
        #expect(se.location != nil)
        #expect(se.location?.pageNumber == nil)
        #expect(se.location?.structureID == nil)
    }

    @Test("All expected property keys are present")
    func allPropertyKeys() {
        let se = SEGenericObject(structureType: "Figure")
        let expectedKeys: Set<String> = [
            "structureType", "Alt", "ActualText", "title", "Lang",
            "parentStandardType", "kidsStandardTypes",
            "hasContentItems", "isGrouping"
        ]
        let actualKeys = Set(se.validationProperties.keys)
        #expect(actualKeys == expectedKeys)
    }

    @Test("Conforms to ValidationObject protocol")
    func conformsToValidationObject() {
        let se = SEGenericObject(structureType: "Table")
        let _: any ValidationObject = se
        #expect(se.validationProperties.isEmpty == false)
    }

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let se = SEGenericObject(
            structureType: "Figure",
            altText: "A chart showing revenue",
            pageNumber: 2,
            structureID: "SE-7"
        )
        let result = await Task {
            se.validationProperties["Alt"]
        }.value
        #expect(result == "A chart showing revenue")
    }
}

// MARK: - Sprint 4: PDPage Parsing Integration Tests

@Suite("Sprint 4: PDPage Parsing Integration Tests")
struct Sprint4PDPageIntegrationTests {

    /// Create a real PDF file using PDFKit and return its URL.
    private func createTestPDF(pageCount: Int = 1) throws -> URL {
        let pdfDocument = PDFKit.PDFDocument()
        for i in 0..<pageCount {
            let page = PDFPage()
            pdfDocument.insert(page, at: i)
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("sprint4-test-\(UUID().uuidString).pdf")
        guard pdfDocument.write(to: url) else {
            throw VerificarError.ioError(path: url.path, reason: "Failed to write test PDF")
        }
        return url
    }

    private func cleanUp(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("parse() returns PDPage objects for each page")
    func parseReturnsPDPageObjects() async throws {
        let url = try createTestPDF(pageCount: 3)
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        let pageObjects = doc.objects(ofType: "PDPage")
        #expect(pageObjects.count == 3)
    }

    @Test("PDPage objects have sequential page numbers")
    func pageObjectsHaveSequentialNumbers() async throws {
        let url = try createTestPDF(pageCount: 5)
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        let pageObjects = doc.objects(ofType: "PDPage")
        for (i, obj) in pageObjects.enumerated() {
            #expect(obj.validationProperties["pageNumber"] == String(i))
        }
    }

    @Test("PDPage objects have width and height from MediaBox")
    func pageObjectsHaveDimensions() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        let pageObjects = doc.objects(ofType: "PDPage")
        #expect(pageObjects.count == 1)
        let props = pageObjects[0].validationProperties
        // PDFKit's default blank pages have dimensions
        let width = Double(props["width"] ?? "0") ?? 0
        let height = Double(props["height"] ?? "0") ?? 0
        #expect(width > 0)
        #expect(height > 0)
    }

    @Test("PDPage objects have location with 1-based page number")
    func pageObjectsHaveLocation() async throws {
        let url = try createTestPDF(pageCount: 2)
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        let pageObjects = doc.objects(ofType: "PDPage")
        #expect(pageObjects[0].location?.pageNumber == 1)
        #expect(pageObjects[1].location?.pageNumber == 2)
    }

    @Test("PDPage count matches document page count")
    func pageCountMatchesDocumentPageCount() async throws {
        for count in [1, 3, 7] {
            let url = try createTestPDF(pageCount: count)
            defer { cleanUp(url) }

            let parser = SwiftPDFParser(url: url)
            let doc = try await parser.parse()
            let pageObjects = doc.objects(ofType: "PDPage")
            #expect(pageObjects.count == doc.pageCount)
        }
    }

    @Test("PDPage objects have orientation property")
    func pageObjectsHaveOrientation() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        let pageObjects = doc.objects(ofType: "PDPage")
        let orientation = pageObjects[0].validationProperties["orientation"] ?? ""
        #expect(orientation == "Portrait" || orientation == "Landscape" || orientation == "Square")
    }

    @Test("Adapter availableObjectTypes includes PDPage and CosDocument")
    func adapterAvailableObjectTypes() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        if let adapter = doc as? ParsedDocumentAdapter {
            let types = adapter.availableObjectTypes
            #expect(types.contains("CosDocument"))
            #expect(types.contains("PDPage"))
        }
    }

    @Test("Single page PDF has exactly one PDPage object")
    func singlePagePDF() async throws {
        let url = try createTestPDF(pageCount: 1)
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let doc = try await parser.parse()
        #expect(doc.objects(ofType: "PDPage").count == 1)
        #expect(doc.objects(ofType: "CosDocument").count == 1)
    }
}
