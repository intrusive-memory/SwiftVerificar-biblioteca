import Testing
import Foundation
@testable import SwiftVerificarBiblioteca

// MARK: - Test Doubles

/// A mock PDFParser for testing the protocol contract.
struct MockPDFParser: PDFParser {
    let url: URL
    var shouldThrow: Bool = false
    var mockDocument: (any ParsedDocument)?
    var mockFlavour: String?

    init(
        url: URL = URL(fileURLWithPath: "/tmp/test.pdf"),
        shouldThrow: Bool = false,
        mockDocument: (any ParsedDocument)? = nil,
        mockFlavour: String? = nil
    ) {
        self.url = url
        self.shouldThrow = shouldThrow
        self.mockDocument = mockDocument
        self.mockFlavour = mockFlavour
    }

    func parse() async throws -> any ParsedDocument {
        if shouldThrow {
            throw VerificarError.parsingFailed(
                url: url,
                reason: "Mock parsing error"
            )
        }
        if let doc = mockDocument {
            return doc
        }
        return StubParsedDocument(url: url)
    }

    func detectFlavour() async throws -> String? {
        if shouldThrow {
            throw VerificarError.parsingFailed(
                url: url,
                reason: "Mock flavour detection error"
            )
        }
        return mockFlavour
    }
}

/// A stub ParsedDocument for testing parsers.
struct StubParsedDocument: ParsedDocument {
    let url: URL
    let flavour: String?
    let pageCount: Int
    let metadata: DocumentMetadata?
    let hasStructureTree: Bool
    let objectsByType: [String: [any ValidationObject]]

    init(
        url: URL = URL(fileURLWithPath: "/tmp/test.pdf"),
        flavour: String? = nil,
        pageCount: Int = 1,
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

// MARK: - PDFParser Protocol Tests

@Suite("PDFParser Protocol Tests")
struct PDFParserProtocolTests {

    // MARK: - URL Property

    @Test("Parser exposes url property")
    func urlProperty() {
        let url = URL(fileURLWithPath: "/tmp/document.pdf")
        let parser: any PDFParser = MockPDFParser(url: url)
        #expect(parser.url == url)
    }

    @Test("Parser url matches construction url")
    func urlMatchesConstruction() {
        let url = URL(fileURLWithPath: "/Users/test/Desktop/report.pdf")
        let parser = MockPDFParser(url: url)
        #expect(parser.url == url)
    }

    @Test("Parser url with spaces in path")
    func urlWithSpaces() {
        let url = URL(fileURLWithPath: "/tmp/my documents/test file.pdf")
        let parser = MockPDFParser(url: url)
        #expect(parser.url == url)
    }

    // MARK: - parse()

    @Test("Mock parser returns document on parse")
    func parseReturnsDocument() async throws {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let parser = MockPDFParser(url: url)
        let document = try await parser.parse()
        #expect(document.url == url)
    }

    @Test("Mock parser returns custom document")
    func parseReturnsCustomDocument() async throws {
        let docURL = URL(fileURLWithPath: "/tmp/custom.pdf")
        let customDoc = StubParsedDocument(
            url: docURL,
            flavour: "pdfua2",
            pageCount: 10
        )
        let parser = MockPDFParser(
            url: docURL,
            mockDocument: customDoc
        )
        let document = try await parser.parse()
        #expect(document.url == docURL)
        #expect(document.flavour == "pdfua2")
        #expect(document.pageCount == 10)
    }

    @Test("Mock parser throws on parse when configured")
    func parseThrows() async {
        let parser = MockPDFParser(shouldThrow: true)
        await #expect(throws: VerificarError.self) {
            _ = try await parser.parse()
        }
    }

    @Test("Mock parser throws specific parsingFailed error")
    func parseThrowsSpecificError() async {
        let url = URL(fileURLWithPath: "/tmp/broken.pdf")
        let parser = MockPDFParser(url: url, shouldThrow: true)
        do {
            _ = try await parser.parse()
            Issue.record("Expected parsingFailed error to be thrown")
        } catch let error as VerificarError {
            switch error {
            case .parsingFailed(let errorURL, let reason):
                #expect(errorURL == url)
                #expect(reason.contains("Mock"))
            default:
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(error)")
        }
    }

    // MARK: - detectFlavour()

    @Test("Mock parser detects flavour")
    func detectFlavourReturns() async throws {
        let parser = MockPDFParser(mockFlavour: "pdfua2")
        let flavour = try await parser.detectFlavour()
        #expect(flavour == "pdfua2")
    }

    @Test("Mock parser returns nil for unknown flavour")
    func detectFlavourReturnsNil() async throws {
        let parser = MockPDFParser(mockFlavour: nil)
        let flavour = try await parser.detectFlavour()
        #expect(flavour == nil)
    }

    @Test("Mock parser throws on detectFlavour when configured")
    func detectFlavourThrows() async {
        let parser = MockPDFParser(shouldThrow: true)
        await #expect(throws: VerificarError.self) {
            _ = try await parser.detectFlavour()
        }
    }

    @Test("Various flavour strings are returned correctly")
    func variousFlavourStrings() async throws {
        let flavours = ["pdfua1", "pdfua2", "pdfa1a", "pdfa2b", "pdfa3u", "wcag22"]
        for flavour in flavours {
            let parser = MockPDFParser(mockFlavour: flavour)
            let detected = try await parser.detectFlavour()
            #expect(detected == flavour)
        }
    }

    // MARK: - Sendable

    @Test("Parser is Sendable across task boundaries")
    func sendable() async {
        let url = URL(fileURLWithPath: "/tmp/sendable.pdf")
        let parser = MockPDFParser(url: url)
        let result = await Task {
            parser.url
        }.value
        #expect(result == url)
    }

    @Test("Parser can be used in concurrent tasks")
    func concurrentTasks() async throws {
        let parser = MockPDFParser(
            url: URL(fileURLWithPath: "/tmp/concurrent.pdf"),
            mockFlavour: "pdfua2"
        )
        async let doc = parser.parse()
        async let flavour = parser.detectFlavour()
        let document = try await doc
        let detectedFlavour = try await flavour
        #expect(document.url == parser.url)
        #expect(detectedFlavour == "pdfua2")
    }

    // MARK: - Existential Usage

    @Test("Can be used as existential PDFParser type")
    func existentialUsage() async throws {
        let parser: any PDFParser = MockPDFParser(
            url: URL(fileURLWithPath: "/tmp/existential.pdf")
        )
        let document = try await parser.parse()
        #expect(document.url == parser.url)
    }

    @Test("Multiple parsers can be stored in an array")
    func arrayOfParsers() {
        let parsers: [any PDFParser] = [
            MockPDFParser(url: URL(fileURLWithPath: "/tmp/a.pdf")),
            MockPDFParser(url: URL(fileURLWithPath: "/tmp/b.pdf")),
            MockPDFParser(url: URL(fileURLWithPath: "/tmp/c.pdf")),
        ]
        #expect(parsers.count == 3)
        #expect(parsers[0].url.lastPathComponent == "a.pdf")
        #expect(parsers[1].url.lastPathComponent == "b.pdf")
        #expect(parsers[2].url.lastPathComponent == "c.pdf")
    }

    // MARK: - Protocol Composition

    @Test("Parser result conforms to ParsedDocument")
    func parserResultConformsToParsedDocument() async throws {
        let parser = MockPDFParser()
        let document = try await parser.parse()
        // Compilation succeeds — document is `any ParsedDocument`
        #expect(document.url.lastPathComponent == "test.pdf")
    }
}
