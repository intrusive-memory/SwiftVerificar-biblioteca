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
        // No rdf:Description with namespace properties, so empty
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

    @Test("parse(from: Data) parses real XMP data with PDF/A identification")
    func parseFromDataRealXMP() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/"
              pdfaid:part="2"
              pdfaid:conformance="u"/>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let data = Data(xmp.utf8)
        let parser = XMPParser()
        let metadata = try parser.parse(from: data)
        #expect(metadata.pdfaIdentification?.part == 2)
        #expect(metadata.pdfaIdentification?.conformance == "u")
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

    @Test("parse(from: String) succeeds with empty rdf:Description")
    func parseFromStringEmptyDescription() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""/>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)
        // Description has no namespace-prefixed properties, so still empty
        #expect(metadata.packages.isEmpty)
    }

    // MARK: - Real Parsing: PDF/A Identification

    @Test("Parses PDF/A-2u identification from attributes")
    func parsePDFA2uFromAttributes() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/"
              pdfaid:part="2"
              pdfaid:conformance="u"/>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)

        #expect(!metadata.isEmpty)
        #expect(metadata.pdfaIdentification != nil)
        #expect(metadata.pdfaIdentification?.part == 2)
        #expect(metadata.pdfaIdentification?.conformance == "u")
        #expect(metadata.pdfaIdentification?.displayName == "PDF/A-2u")
    }

    @Test("Parses PDF/A-1b identification")
    func parsePDFA1b() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/"
              pdfaid:part="1"
              pdfaid:conformance="b"/>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)

        #expect(metadata.pdfaIdentification?.part == 1)
        #expect(metadata.pdfaIdentification?.conformance == "b")
    }

    @Test("Parses PDF/A identification with amendment and revision")
    func parsePDFAWithAmendment() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/"
              pdfaid:part="1"
              pdfaid:conformance="b"
              pdfaid:amd="1"
              pdfaid:rev="2009"/>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)

        let pdfa = metadata.pdfaIdentification
        #expect(pdfa?.part == 1)
        #expect(pdfa?.conformance == "b")
        #expect(pdfa?.amendment == "1")
        #expect(pdfa?.revision == "2009")
    }

    // MARK: - Real Parsing: PDF/UA Identification

    @Test("Parses PDF/UA-2 identification from attributes")
    func parsePDFUA2() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:pdfuaid="http://www.aiim.org/pdfua/ns/id/"
              pdfuaid:part="2"/>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)

        #expect(!metadata.isEmpty)
        #expect(metadata.pdfuaIdentification != nil)
        #expect(metadata.pdfuaIdentification?.part == 2)
        #expect(metadata.pdfuaIdentification?.displayName == "PDF/UA-2")
    }

    @Test("Parses PDF/UA-1 identification")
    func parsePDFUA1() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:pdfuaid="http://www.aiim.org/pdfua/ns/id/"
              pdfuaid:part="1"/>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)

        #expect(metadata.pdfuaIdentification?.part == 1)
    }

    // MARK: - Real Parsing: Dublin Core

    @Test("Parses Dublin Core title from child element")
    func parseDublinCoreTitle() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:dc="http://purl.org/dc/elements/1.1/">
              <dc:title>My Document Title</dc:title>
              <dc:creator>John Author</dc:creator>
            </rdf:Description>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)

        #expect(metadata.dublinCore != nil)
        #expect(metadata.dublinCore?.title == "My Document Title")
        #expect(metadata.dublinCore?.creator == "John Author")
    }

    @Test("Parses Dublin Core from attributes")
    func parseDublinCoreFromAttributes() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:dc="http://purl.org/dc/elements/1.1/"
              dc:title="Attribute Title"
              dc:creator="Attribute Author"/>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)

        #expect(metadata.dublinCore?.title == "Attribute Title")
        #expect(metadata.dublinCore?.creator == "Attribute Author")
    }

    // MARK: - Real Parsing: Combined Schemas

    @Test("Parses combined PDF/A and PDF/UA metadata")
    func parseCombinedSchemas() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/"
              pdfaid:part="2"
              pdfaid:conformance="u"/>
            <rdf:Description rdf:about=""
              xmlns:pdfuaid="http://www.aiim.org/pdfua/ns/id/"
              pdfuaid:part="2"/>
            <rdf:Description rdf:about=""
              xmlns:dc="http://purl.org/dc/elements/1.1/">
              <dc:title>Accessible Document</dc:title>
            </rdf:Description>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)

        #expect(metadata.pdfaIdentification?.part == 2)
        #expect(metadata.pdfaIdentification?.conformance == "u")
        #expect(metadata.pdfuaIdentification?.part == 2)
        #expect(metadata.dublinCore?.title == "Accessible Document")
        #expect(metadata.packageCount >= 3)
    }

    @Test("Parses XMP Basic namespace properties")
    func parseXMPBasic() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:xmp="http://ns.adobe.com/xap/1.0/"
              xmp:CreatorTool="SwiftVerificar"
              xmp:CreateDate="2024-01-15"/>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)

        let xmpPkg = metadata.package(forNamespace: XMPProperty.Namespace.xmpBasic)
        #expect(xmpPkg != nil)
        #expect(xmpPkg?.property(named: "CreatorTool")?.value == "SwiftVerificar")
        #expect(xmpPkg?.property(named: "CreateDate")?.value == "2024-01-15")
    }

    // MARK: - Real Parsing: Child Elements

    @Test("Parses properties from child elements with text content")
    func parseChildElements() throws {
        let xmp = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/">
              <pdfaid:part>3</pdfaid:part>
              <pdfaid:conformance>a</pdfaid:conformance>
            </rdf:Description>
          </rdf:RDF>
        </x:xmpmeta>
        """
        let parser = XMPParser()
        let metadata = try parser.parse(from: xmp)

        #expect(metadata.pdfaIdentification?.part == 3)
        #expect(metadata.pdfaIdentification?.conformance == "a")
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
