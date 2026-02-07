import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("XMPParser Tests")
struct XMPParserTests {

    // MARK: - Initialization

    @Test("Default init creates parser")
    func defaultInit() {
        let parser = XMPParser()
        #expect(parser.description == "XMPParser()")
    }

    // MARK: - parse(from: Data)

    @Test("parse(from: Data) succeeds with valid UTF-8 data")
    func parseFromDataValid() throws {
        let xml = "<x:xmpmeta><rdf:RDF/></x:xmpmeta>"
        let data = Data(xml.utf8)
        let parser = XMPParser()
        let metadata = try parser.parse(from: data)
        // Stub returns empty metadata
        #expect(metadata.packages.isEmpty)
    }

    @Test("parse(from: Data) throws for invalid UTF-8 data")
    func parseFromDataInvalidUTF8() {
        // Invalid UTF-8 byte sequence
        let data = Data([0xFF, 0xFE, 0x80, 0x81])
        let parser = XMPParser()

        #expect(throws: XMPParser.XMPParserError.self) {
            try parser.parse(from: data)
        }
    }

    @Test("parse(from: Data) with empty data throws")
    func parseFromDataEmpty() {
        let data = Data()
        let parser = XMPParser()

        #expect(throws: XMPParser.XMPParserError.self) {
            try parser.parse(from: data)
        }
    }

    @Test("parse(from: Data) throws invalidData for non-UTF8")
    func parseFromDataInvalidDataError() {
        let data = Data([0xFF, 0xFE, 0x80, 0x81])
        let parser = XMPParser()

        do {
            _ = try parser.parse(from: data)
            #expect(Bool(false), "Should have thrown")
        } catch let error as XMPParser.XMPParserError {
            if case .invalidData = error {
                // Expected
            } else {
                #expect(Bool(false), "Expected invalidData, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    // MARK: - parse(from: String)

    @Test("parse(from: String) succeeds with non-empty XML")
    func parseFromStringValid() throws {
        let parser = XMPParser()
        let metadata = try parser.parse(from: "<x:xmpmeta/>")
        #expect(metadata.packages.isEmpty)
    }

    @Test("parse(from: String) throws for empty string")
    func parseFromStringEmpty() {
        let parser = XMPParser()
        #expect(throws: XMPParser.XMPParserError.self) {
            try parser.parse(from: "")
        }
    }

    @Test("parse(from: String) throws for whitespace-only string")
    func parseFromStringWhitespace() {
        let parser = XMPParser()
        #expect(throws: XMPParser.XMPParserError.self) {
            try parser.parse(from: "   \n\t  ")
        }
    }

    @Test("parse(from: String) throws parsingFailed for empty input")
    func parseFromStringParsingFailedError() {
        let parser = XMPParser()

        do {
            _ = try parser.parse(from: "")
            #expect(Bool(false), "Should have thrown")
        } catch let error as XMPParser.XMPParserError {
            if case .parsingFailed = error {
                // Expected
            } else {
                #expect(Bool(false), "Expected parsingFailed, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("parse(from: String) succeeds with minimal XMP content")
    func parseFromStringMinimal() throws {
        let parser = XMPParser()
        let metadata = try parser.parse(from: "<?xpacket?>")
        #expect(metadata.isEmpty)
    }

    @Test("parse(from: String) succeeds with multiline XMP")
    func parseFromStringMultiline() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""/>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)
        #expect(metadata.packages.isEmpty) // Stub behavior
    }

    // MARK: - XMPParserError

    @Test("XMPParserError.invalidData is equatable")
    func invalidDataEquatable() {
        let a = XMPParser.XMPParserError.invalidData("reason")
        let b = XMPParser.XMPParserError.invalidData("reason")
        #expect(a == b)
    }

    @Test("XMPParserError.parsingFailed is equatable")
    func parsingFailedEquatable() {
        let a = XMPParser.XMPParserError.parsingFailed("reason")
        let b = XMPParser.XMPParserError.parsingFailed("reason")
        #expect(a == b)
    }

    @Test("Different XMPParserError cases are not equal")
    func differentErrorCases() {
        let a = XMPParser.XMPParserError.invalidData("reason")
        let b = XMPParser.XMPParserError.parsingFailed("reason")
        #expect(a != b)
    }

    @Test("Different error messages are not equal")
    func differentErrorMessages() {
        let a = XMPParser.XMPParserError.invalidData("reason1")
        let b = XMPParser.XMPParserError.invalidData("reason2")
        #expect(a != b)
    }

    @Test("XMPParserError.invalidData description includes reason")
    func invalidDataDescription() {
        let error = XMPParser.XMPParserError.invalidData("bad bytes")
        #expect(error.description.contains("bad bytes"))
        #expect(error.description.contains("invalidData"))
    }

    @Test("XMPParserError.parsingFailed description includes reason")
    func parsingFailedDescription() {
        let error = XMPParser.XMPParserError.parsingFailed("malformed XML")
        #expect(error.description.contains("malformed XML"))
        #expect(error.description.contains("parsingFailed"))
    }

    // MARK: - Sendable

    @Test("XMPParser is Sendable across task boundaries")
    func sendable() async {
        let parser = XMPParser()
        let result = await Task { parser.description }.value
        #expect(result == "XMPParser()")
    }

    @Test("XMPParserError is Sendable across task boundaries")
    func errorSendable() async {
        let error = XMPParser.XMPParserError.invalidData("test")
        let result = await Task { error }.value
        #expect(result == XMPParser.XMPParserError.invalidData("test"))
    }
}
