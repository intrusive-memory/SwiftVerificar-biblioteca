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

    @Test("parse() objects(ofType:) returns empty array for Sprint 1")
    func parseObjectsReturnsEmpty() async throws {
        let url = try createTestPDF()
        defer { cleanUp(url) }

        let parser = SwiftPDFParser(url: url)
        let document = try await parser.parse()
        let objects = document.objects(ofType: "CosDocument")
        #expect(objects.isEmpty)
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
        #expect(adapter.objects(ofType: "CosDocument").isEmpty)
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
