import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("OutputFormat Tests")
struct OutputFormatTests {

    // MARK: - Case Values

    @Test("json case exists")
    func jsonCase() {
        let format = OutputFormat.json
        #expect(format == .json)
    }

    @Test("xml case exists")
    func xmlCase() {
        let format = OutputFormat.xml
        #expect(format == .xml)
    }

    @Test("text case exists")
    func textCase() {
        let format = OutputFormat.text
        #expect(format == .text)
    }

    @Test("html case exists")
    func htmlCase() {
        let format = OutputFormat.html
        #expect(format == .html)
    }

    // MARK: - CaseIterable

    @Test("CaseIterable has exactly 4 cases")
    func caseIterableCount() {
        #expect(OutputFormat.allCases.count == 4)
    }

    @Test("CaseIterable contains all cases")
    func caseIterableContainsAll() {
        let allCases = OutputFormat.allCases
        #expect(allCases.contains(.json))
        #expect(allCases.contains(.xml))
        #expect(allCases.contains(.text))
        #expect(allCases.contains(.html))
    }

    // MARK: - RawValue

    @Test("json raw value")
    func jsonRawValue() {
        #expect(OutputFormat.json.rawValue == "json")
    }

    @Test("xml raw value")
    func xmlRawValue() {
        #expect(OutputFormat.xml.rawValue == "xml")
    }

    @Test("text raw value")
    func textRawValue() {
        #expect(OutputFormat.text.rawValue == "text")
    }

    @Test("html raw value")
    func htmlRawValue() {
        #expect(OutputFormat.html.rawValue == "html")
    }

    @Test("Init from valid raw value succeeds")
    func initFromValidRawValue() {
        #expect(OutputFormat(rawValue: "json") == .json)
        #expect(OutputFormat(rawValue: "xml") == .xml)
        #expect(OutputFormat(rawValue: "text") == .text)
        #expect(OutputFormat(rawValue: "html") == .html)
    }

    @Test("Init from invalid raw value returns nil")
    func initFromInvalidRawValue() {
        #expect(OutputFormat(rawValue: "invalid") == nil)
        #expect(OutputFormat(rawValue: "") == nil)
        #expect(OutputFormat(rawValue: "JSON") == nil)
        #expect(OutputFormat(rawValue: "pdf") == nil)
    }

    // MARK: - fileExtension

    @Test("json file extension")
    func jsonFileExtension() {
        #expect(OutputFormat.json.fileExtension == "json")
    }

    @Test("xml file extension")
    func xmlFileExtension() {
        #expect(OutputFormat.xml.fileExtension == "xml")
    }

    @Test("text file extension is txt")
    func textFileExtension() {
        #expect(OutputFormat.text.fileExtension == "txt")
    }

    @Test("html file extension")
    func htmlFileExtension() {
        #expect(OutputFormat.html.fileExtension == "html")
    }

    @Test("All cases have non-empty file extension")
    func allCasesHaveFileExtension() {
        for format in OutputFormat.allCases {
            #expect(!format.fileExtension.isEmpty)
        }
    }

    // MARK: - mimeType

    @Test("json MIME type")
    func jsonMimeType() {
        #expect(OutputFormat.json.mimeType == "application/json")
    }

    @Test("xml MIME type")
    func xmlMimeType() {
        #expect(OutputFormat.xml.mimeType == "application/xml")
    }

    @Test("text MIME type")
    func textMimeType() {
        #expect(OutputFormat.text.mimeType == "text/plain")
    }

    @Test("html MIME type")
    func htmlMimeType() {
        #expect(OutputFormat.html.mimeType == "text/html")
    }

    @Test("All cases have non-empty MIME type")
    func allCasesHaveMimeType() {
        for format in OutputFormat.allCases {
            #expect(!format.mimeType.isEmpty)
        }
    }

    // MARK: - displayName

    @Test("json display name")
    func jsonDisplayName() {
        #expect(OutputFormat.json.displayName == "JSON")
    }

    @Test("xml display name")
    func xmlDisplayName() {
        #expect(OutputFormat.xml.displayName == "XML")
    }

    @Test("text display name")
    func textDisplayName() {
        #expect(OutputFormat.text.displayName == "Plain Text")
    }

    @Test("html display name")
    func htmlDisplayName() {
        #expect(OutputFormat.html.displayName == "HTML")
    }

    @Test("All cases have non-empty display name")
    func allCasesHaveDisplayName() {
        for format in OutputFormat.allCases {
            #expect(!format.displayName.isEmpty)
        }
    }

    // MARK: - CustomStringConvertible

    @Test("description matches displayName for all cases")
    func descriptionMatchesDisplayName() {
        for format in OutputFormat.allCases {
            #expect(format.description == format.displayName)
        }
    }

    // MARK: - Hashable

    @Test("Can be used in a Set")
    func hashable() {
        let set: Set<OutputFormat> = [.json, .xml, .text, .html]
        #expect(set.count == 4)
    }

    @Test("Duplicate elements in Set are deduplicated")
    func hashableDeduplicate() {
        let set: Set<OutputFormat> = [.json, .json, .xml]
        #expect(set.count == 2)
    }

    @Test("Equal formats have same hash value")
    func equalHashValues() {
        let a = OutputFormat.html
        let b = OutputFormat.html
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Can be used as Dictionary key")
    func dictionaryKey() {
        let dict: [OutputFormat: String] = [
            .json: "json-template",
            .xml: "xml-template",
            .text: "text-template",
            .html: "html-template"
        ]
        #expect(dict.count == 4)
        #expect(dict[.json] == "json-template")
    }

    // MARK: - Codable

    @Test("Codable round-trip for all cases")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for format in OutputFormat.allCases {
            let data = try encoder.encode(format)
            let decoded = try decoder.decode(OutputFormat.self, from: data)
            #expect(decoded == format)
        }
    }

    @Test("JSON encoding produces raw value string")
    func jsonEncodesRawValue() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(OutputFormat.json)
        let string = String(data: data, encoding: .utf8)
        #expect(string == "\"json\"")
    }

    @Test("JSON decoding from raw value string")
    func jsonDecodesRawValue() throws {
        let decoder = JSONDecoder()
        let data = "\"html\"".data(using: .utf8)!
        let format = try decoder.decode(OutputFormat.self, from: data)
        #expect(format == .html)
    }

    @Test("Codable array round-trip")
    func codableArrayRoundTrip() throws {
        let original: [OutputFormat] = [.json, .xml, .text, .html]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode([OutputFormat].self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let format = OutputFormat.xml

        let result = await Task {
            format
        }.value

        #expect(result == .xml)
    }

    @Test("All cases are Sendable across task boundaries")
    func allCasesSendable() async {
        for format in OutputFormat.allCases {
            let result = await Task {
                format
            }.value
            #expect(result == format)
        }
    }
}
