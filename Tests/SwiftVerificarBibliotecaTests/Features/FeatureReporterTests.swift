import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("FeatureReporter Tests")
struct FeatureReporterTests {

    // MARK: - Helpers

    private static let testURL = URL(fileURLWithPath: "/tmp/report.pdf")

    private static let sampleResult = FeatureExtractionResult(
        documentURL: testURL,
        features: .branch(name: "Document", children: [
            .branch(name: "Fonts", children: [
                .leaf(name: "Font", value: "Helvetica"),
                .leaf(name: "Font", value: "Times-Roman"),
            ], attributes: ["count": "2"]),
            .leaf(name: "PageCount", value: "5"),
        ], attributes: [:]),
        errors: []
    )

    private static let resultWithErrors = FeatureExtractionResult(
        documentURL: testURL,
        features: .branch(name: "Document", children: [
            .leaf(name: "PageCount", value: "3"),
        ], attributes: [:]),
        errors: [
            FeatureError(featureType: .fonts, message: "corrupt font program"),
            FeatureError(featureType: .iccProfiles, message: "invalid ICC header"),
        ]
    )

    // MARK: - Construction

    @Test("Default init sets includeErrors true and includeEmptyBranches false")
    func defaultInit() {
        let reporter = FeatureReporter()
        #expect(reporter.includeErrors == true)
        #expect(reporter.includeEmptyBranches == false)
    }

    @Test("Custom init sets properties")
    func customInit() {
        let reporter = FeatureReporter(includeErrors: false, includeEmptyBranches: true)
        #expect(reporter.includeErrors == false)
        #expect(reporter.includeEmptyBranches == true)
    }

    // MARK: - JSON Generation

    @Test("generateJSON produces valid JSON data")
    func generateJSONProducesData() throws {
        let reporter = FeatureReporter()
        let data = try reporter.generateJSON(from: Self.sampleResult)

        #expect(!data.isEmpty)

        // Verify it's valid JSON
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        #expect(jsonObject is [String: Any])
    }

    @Test("generateJSON is decodable back to FeatureExtractionResult")
    func generateJSONDecodable() throws {
        let reporter = FeatureReporter()
        let data = try reporter.generateJSON(from: Self.sampleResult)

        let decoded = try JSONDecoder().decode(FeatureExtractionResult.self, from: data)
        #expect(decoded == Self.sampleResult)
    }

    @Test("generateJSON includes errors when present")
    func generateJSONWithErrors() throws {
        let reporter = FeatureReporter()
        let data = try reporter.generateJSON(from: Self.resultWithErrors)
        let jsonString = String(data: data, encoding: .utf8) ?? ""

        #expect(jsonString.contains("corrupt font program"))
        #expect(jsonString.contains("invalid ICC header"))
    }

    // MARK: - Text Generation

    @Test("generateText includes document filename")
    func textIncludesFilename() {
        let reporter = FeatureReporter()
        let text = reporter.generateText(from: Self.sampleResult)

        #expect(text.contains("report.pdf"))
    }

    @Test("generateText includes feature names and values")
    func textIncludesFeatures() {
        let reporter = FeatureReporter()
        let text = reporter.generateText(from: Self.sampleResult)

        #expect(text.contains("Helvetica"))
        #expect(text.contains("Times-Roman"))
        #expect(text.contains("PageCount"))
    }

    @Test("generateText includes error section when errors present")
    func textIncludesErrors() {
        let reporter = FeatureReporter()
        let text = reporter.generateText(from: Self.resultWithErrors)

        #expect(text.contains("Errors (2)"))
        #expect(text.contains("corrupt font program"))
        #expect(text.contains("Fonts"))
    }

    @Test("generateText omits error section when no errors")
    func textOmitsErrorsWhenNone() {
        let reporter = FeatureReporter()
        let text = reporter.generateText(from: Self.sampleResult)

        #expect(!text.contains("Errors"))
    }

    @Test("generateText omits error section when includeErrors is false")
    func textOmitsErrorsWhenDisabled() {
        let reporter = FeatureReporter(includeErrors: false)
        let text = reporter.generateText(from: Self.resultWithErrors)

        #expect(!text.contains("Errors"))
    }

    @Test("generateText uses indentation for nesting")
    func textIndentation() {
        let reporter = FeatureReporter()
        let text = reporter.generateText(from: Self.sampleResult)

        // "Fonts" is at indent level 1, "Font: Helvetica" at level 2
        #expect(text.contains("  Fonts"))
        #expect(text.contains("    Font: Helvetica"))
    }

    @Test("generateText includes branch attributes")
    func textBranchAttributes() {
        let reporter = FeatureReporter()
        let text = reporter.generateText(from: Self.sampleResult)

        #expect(text.contains("count=2"))
    }

    @Test("generateText omits empty branches when includeEmptyBranches is false")
    func textOmitsEmptyBranches() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: .branch(name: "Root", children: [
                .branch(name: "EmptyGroup", children: [], attributes: [:]),
                .leaf(name: "Data", value: "value"),
            ], attributes: [:])
        )
        let reporter = FeatureReporter(includeEmptyBranches: false)
        let text = reporter.generateText(from: result)

        #expect(!text.contains("EmptyGroup"))
        #expect(text.contains("Data"))
    }

    @Test("generateText includes empty branches when includeEmptyBranches is true")
    func textIncludesEmptyBranches() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: .branch(name: "Root", children: [
                .branch(name: "EmptyGroup", children: [], attributes: [:]),
            ], attributes: [:])
        )
        let reporter = FeatureReporter(includeEmptyBranches: true)
        let text = reporter.generateText(from: result)

        #expect(text.contains("EmptyGroup"))
    }

    // MARK: - XML Generation

    @Test("generateXML starts with XML declaration")
    func xmlDeclaration() {
        let reporter = FeatureReporter()
        let xml = reporter.generateXML(from: Self.sampleResult)

        #expect(xml.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
    }

    @Test("generateXML contains feature data as elements")
    func xmlContainsElements() {
        let reporter = FeatureReporter()
        let xml = reporter.generateXML(from: Self.sampleResult)

        #expect(xml.contains("<Document>"))
        #expect(xml.contains("</Document>"))
        #expect(xml.contains("<Font>Helvetica</Font>"))
        #expect(xml.contains("<PageCount>5</PageCount>"))
    }

    @Test("generateXML includes attributes on branches")
    func xmlBranchAttributes() {
        let reporter = FeatureReporter()
        let xml = reporter.generateXML(from: Self.sampleResult)

        #expect(xml.contains("count=\"2\""))
    }

    @Test("generateXML includes error elements when present")
    func xmlIncludesErrors() {
        let reporter = FeatureReporter()
        let xml = reporter.generateXML(from: Self.resultWithErrors)

        #expect(xml.contains("<errors>"))
        #expect(xml.contains("</errors>"))
        #expect(xml.contains("featureType=\"fonts\""))
    }

    @Test("generateXML omits errors when includeErrors is false")
    func xmlOmitsErrorsWhenDisabled() {
        let reporter = FeatureReporter(includeErrors: false)
        let xml = reporter.generateXML(from: Self.resultWithErrors)

        #expect(!xml.contains("<errors>"))
    }

    @Test("generateXML escapes special characters in values")
    func xmlEscapesSpecialChars() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: .leaf(name: "Note", value: "A <b>bold</b> & \"special\" 'value'")
        )
        let reporter = FeatureReporter()
        let xml = reporter.generateXML(from: result)

        #expect(xml.contains("&lt;b&gt;bold&lt;/b&gt;"))
        #expect(xml.contains("&amp;"))
        #expect(xml.contains("&quot;special&quot;"))
        #expect(xml.contains("&apos;value&apos;"))
    }

    @Test("generateXML uses self-closing tags for leaves with nil value")
    func xmlSelfClosingTag() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: .leaf(name: "Empty", value: nil)
        )
        let reporter = FeatureReporter()
        let xml = reporter.generateXML(from: result)

        #expect(xml.contains("<Empty/>"))
    }

    // MARK: - generate(format:) Dispatch

    @Test("generate with json format produces decodable data")
    func generateJSON() throws {
        let reporter = FeatureReporter()
        let data = try reporter.generate(from: Self.sampleResult, format: .json)

        let decoded = try JSONDecoder().decode(FeatureExtractionResult.self, from: data)
        #expect(decoded == Self.sampleResult)
    }

    @Test("generate with text format produces UTF-8 text")
    func generateText() throws {
        let reporter = FeatureReporter()
        let data = try reporter.generate(from: Self.sampleResult, format: .text)
        let text = String(data: data, encoding: .utf8)

        #expect(text?.contains("report.pdf") == true)
    }

    @Test("generate with xml format produces UTF-8 XML")
    func generateXML() throws {
        let reporter = FeatureReporter()
        let data = try reporter.generate(from: Self.sampleResult, format: .xml)
        let xml = String(data: data, encoding: .utf8)

        #expect(xml?.contains("<?xml") == true)
    }

    // MARK: - Summarize

    @Test("summarize returns category-to-count mapping")
    func summarize() {
        let reporter = FeatureReporter()
        let summary = reporter.summarize(Self.sampleResult)

        // "Fonts" has 2 leaf values ("Helvetica", "Times-Roman")
        // "PageCount" is a leaf with value "5" -> 1 leaf value
        #expect(summary["Fonts"] == 2)
        #expect(summary["PageCount"] == 1)
    }

    @Test("summarize returns empty for leaf-only root")
    func summarizeLeafRoot() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: .leaf(name: "Root", value: "val")
        )
        let reporter = FeatureReporter()
        let summary = reporter.summarize(result)

        #expect(summary.isEmpty)
    }

    // MARK: - Equatable

    @Test("Same reporters are equal")
    func equality() {
        let a = FeatureReporter(includeErrors: true, includeEmptyBranches: false)
        let b = FeatureReporter(includeErrors: true, includeEmptyBranches: false)
        #expect(a == b)
    }

    @Test("Different reporters are not equal")
    func inequality() {
        let a = FeatureReporter(includeErrors: true)
        let b = FeatureReporter(includeErrors: false)
        #expect(a != b)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes property values")
    func descriptionContent() {
        let reporter = FeatureReporter(includeErrors: false, includeEmptyBranches: true)
        #expect(reporter.description.contains("false"))
        #expect(reporter.description.contains("true"))
    }

    // MARK: - OutputFormat

    @Test("OutputFormat has 3 cases")
    func outputFormatCaseCount() {
        #expect(FeatureReporter.OutputFormat.allCases.count == 3)
    }

    @Test("OutputFormat raw values")
    func outputFormatRawValues() {
        #expect(FeatureReporter.OutputFormat.json.rawValue == "json")
        #expect(FeatureReporter.OutputFormat.text.rawValue == "text")
        #expect(FeatureReporter.OutputFormat.xml.rawValue == "xml")
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let reporter = FeatureReporter()

        let result = await Task {
            reporter
        }.value

        #expect(result == reporter)
    }
}
