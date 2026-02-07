import Foundation
import Testing
@testable import SwiftVerificarBiblioteca
import SwiftVerificarValidationProfiles

@Suite("ReportGenerator Tests")
struct ReportGeneratorTests {

    // MARK: - Test Helpers

    private func makeRuleID(
        clause: String = "8.2.5.26",
        testNumber: Int = 1
    ) -> RuleID {
        RuleID(specification: .iso142892, clause: clause, testNumber: testNumber)
    }

    private func makeAssertion(
        ruleID: RuleID? = nil,
        status: AssertionStatus = .failed,
        message: String = "test message"
    ) -> TestAssertion {
        TestAssertion(
            id: UUID(),
            ruleID: ruleID ?? makeRuleID(),
            status: status,
            message: message
        )
    }

    private func makeDuration() -> ValidationDuration {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let end = Date(timeIntervalSinceReferenceDate: 1.234)
        return ValidationDuration(start: start, end: end)
    }

    private func makeReport(
        profileName: String = "PDF/UA-2",
        isCompliant: Bool = false,
        assertions: [TestAssertion]? = nil
    ) -> ValidationReport {
        let defaultAssertions = assertions ?? [
            makeAssertion(ruleID: makeRuleID(clause: "1.0"), status: .passed, message: "Rule 1 ok"),
            makeAssertion(ruleID: makeRuleID(clause: "1.0"), status: .failed, message: "Rule 1 fail"),
            makeAssertion(ruleID: makeRuleID(clause: "2.0"), status: .failed, message: "Rule 2 fail"),
            makeAssertion(ruleID: makeRuleID(clause: "2.0"), status: .failed, message: "Rule 2 fail again"),
        ]
        let result = ValidationResult(
            profileName: profileName,
            documentURL: URL(fileURLWithPath: "/test/doc.pdf"),
            isCompliant: isCompliant,
            assertions: defaultAssertions,
            duration: makeDuration()
        )
        return ValidationReport.generate(from: result)
    }

    private func makeEmptyReport() -> ValidationReport {
        let result = ValidationResult(
            profileName: "Empty",
            documentURL: URL(fileURLWithPath: "/test/empty.pdf"),
            isCompliant: true,
            assertions: [],
            duration: makeDuration()
        )
        return ValidationReport.generate(from: result)
    }

    // MARK: - JSON

    @Test("JSON produces valid JSON data")
    func jsonProducesValidData() throws {
        let report = makeReport()
        let data = try ReportGenerator.json(from: report)
        #expect(!data.isEmpty)

        // Verify it's valid JSON
        let json = try JSONSerialization.jsonObject(with: data)
        #expect(json is [String: Any])
    }

    @Test("JSON contains profile name")
    func jsonContainsProfileName() throws {
        let report = makeReport(profileName: "TestProfile")
        let data = try ReportGenerator.json(from: report)
        let str = String(data: data, encoding: .utf8)
        #expect(str?.contains("TestProfile") == true)
    }

    @Test("JSON contains summaries")
    func jsonContainsSummaries() throws {
        let report = makeReport()
        let data = try ReportGenerator.json(from: report)
        let str = String(data: data, encoding: .utf8)
        #expect(str?.contains("summaries") == true)
    }

    @Test("JSON round-trips via Codable")
    func jsonRoundTrip() throws {
        let report = makeReport()
        let data = try ReportGenerator.json(from: report)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ValidationReport.self, from: data)
        #expect(decoded.result.profileName == report.result.profileName)
        #expect(decoded.summaries.count == report.summaries.count)
    }

    @Test("JSON for empty report")
    func jsonEmptyReport() throws {
        let report = makeEmptyReport()
        let data = try ReportGenerator.json(from: report)
        let str = String(data: data, encoding: .utf8)
        #expect(str?.contains("\"summaries\" : [") == true)
    }

    @Test("JSON uses pretty printing")
    func jsonPrettyPrinted() throws {
        let report = makeReport()
        let data = try ReportGenerator.json(from: report)
        let str = String(data: data, encoding: .utf8)
        // Pretty-printed JSON has newlines
        #expect(str?.contains("\n") == true)
    }

    @Test("JSON uses sorted keys")
    func jsonSortedKeys() throws {
        let report = makeReport()
        let data = try ReportGenerator.json(from: report)
        let str = String(data: data, encoding: .utf8) ?? ""
        // "result" should appear before "summaries" (alphabetical)
        if let resultRange = str.range(of: "\"result\""),
           let summariesRange = str.range(of: "\"summaries\"") {
            #expect(resultRange.lowerBound < summariesRange.lowerBound)
        }
    }

    // MARK: - XML

    @Test("XML produces valid UTF-8 data")
    func xmlProducesData() throws {
        let report = makeReport()
        let data = try ReportGenerator.xml(from: report)
        #expect(!data.isEmpty)
        let str = String(data: data, encoding: .utf8)
        #expect(str != nil)
    }

    @Test("XML has proper declaration")
    func xmlHasDeclaration() throws {
        let report = makeReport()
        let data = try ReportGenerator.xml(from: report)
        let str = String(data: data, encoding: .utf8) ?? ""
        #expect(str.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
    }

    @Test("XML contains validationReport root element")
    func xmlRootElement() throws {
        let report = makeReport()
        let data = try ReportGenerator.xml(from: report)
        let str = String(data: data, encoding: .utf8) ?? ""
        #expect(str.contains("<validationReport>"))
        #expect(str.contains("</validationReport>"))
    }

    @Test("XML contains profile name")
    func xmlContainsProfileName() throws {
        let report = makeReport(profileName: "MyProfile")
        let data = try ReportGenerator.xml(from: report)
        let str = String(data: data, encoding: .utf8) ?? ""
        #expect(str.contains("<profileName>MyProfile</profileName>"))
    }

    @Test("XML contains compliance status")
    func xmlContainsCompliance() throws {
        let report = makeReport(isCompliant: false)
        let data = try ReportGenerator.xml(from: report)
        let str = String(data: data, encoding: .utf8) ?? ""
        #expect(str.contains("<isCompliant>false</isCompliant>"))
    }

    @Test("XML contains rule summaries")
    func xmlContainsRuleSummaries() throws {
        let report = makeReport()
        let data = try ReportGenerator.xml(from: report)
        let str = String(data: data, encoding: .utf8) ?? ""
        #expect(str.contains("<ruleSummary>"))
        #expect(str.contains("<ruleID>"))
        #expect(str.contains("<passedCount>"))
        #expect(str.contains("<failedCount>"))
    }

    @Test("XML escapes special characters")
    func xmlEscapesSpecialChars() throws {
        let assertions = [
            makeAssertion(
                ruleID: makeRuleID(),
                status: .failed,
                message: "Value <test> & \"quoted\" 'apos'"
            ),
        ]
        let report = makeReport(assertions: assertions)
        let data = try ReportGenerator.xml(from: report)
        let str = String(data: data, encoding: .utf8) ?? ""
        #expect(str.contains("&lt;test&gt;"))
        #expect(str.contains("&amp;"))
        #expect(str.contains("&quot;quoted&quot;"))
        #expect(str.contains("&apos;apos&apos;"))
    }

    @Test("XML empty report has empty summaries element")
    func xmlEmptyReport() throws {
        let report = makeEmptyReport()
        let data = try ReportGenerator.xml(from: report)
        let str = String(data: data, encoding: .utf8) ?? ""
        #expect(str.contains("<summaries>"))
        #expect(str.contains("</summaries>"))
        #expect(!str.contains("<ruleSummary>"))
    }

    @Test("XML contains duration")
    func xmlContainsDuration() throws {
        let report = makeReport()
        let data = try ReportGenerator.xml(from: report)
        let str = String(data: data, encoding: .utf8) ?? ""
        #expect(str.contains("<duration>"))
    }

    // MARK: - HTML

    @Test("HTML produces a complete document")
    func htmlProducesDocument() {
        let report = makeReport()
        let html = ReportGenerator.html(from: report)
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("<html"))
        #expect(html.contains("</html>"))
    }

    @Test("HTML contains title")
    func htmlContainsTitle() {
        let report = makeReport()
        let html = ReportGenerator.html(from: report)
        #expect(html.contains("<title>Validation Report</title>"))
    }

    @Test("HTML contains document name")
    func htmlContainsDocumentName() {
        let report = makeReport()
        let html = ReportGenerator.html(from: report)
        #expect(html.contains("doc.pdf"))
    }

    @Test("HTML contains profile name")
    func htmlContainsProfileName() {
        let report = makeReport(profileName: "PDF/UA-2")
        let html = ReportGenerator.html(from: report)
        #expect(html.contains("PDF/UA-2"))
    }

    @Test("HTML shows compliance status")
    func htmlShowsCompliance() {
        let report = makeReport(isCompliant: false)
        let html = ReportGenerator.html(from: report)
        #expect(html.contains("NON-COMPLIANT"))
    }

    @Test("HTML shows COMPLIANT for compliant docs")
    func htmlShowsCompliant() {
        let report = makeReport(isCompliant: true, assertions: [])
        let html = ReportGenerator.html(from: report)
        #expect(html.contains("COMPLIANT"))
    }

    @Test("HTML contains summary table")
    func htmlContainsSummaryTable() {
        let report = makeReport()
        let html = ReportGenerator.html(from: report)
        #expect(html.contains("<table"))
        #expect(html.contains("Rule ID"))
        #expect(html.contains("Clause"))
        #expect(html.contains("Passed"))
        #expect(html.contains("Failed"))
    }

    @Test("HTML contains assertion counts")
    func htmlContainsAssertionCounts() {
        let report = makeReport()
        let html = ReportGenerator.html(from: report)
        #expect(html.contains("Passed:"))
        #expect(html.contains("Failed:"))
    }

    @Test("HTML escapes special characters")
    func htmlEscapesSpecialChars() {
        let result = ValidationResult(
            profileName: "Test <profile> & \"stuff\"",
            documentURL: URL(fileURLWithPath: "/test/doc.pdf"),
            isCompliant: true,
            assertions: [],
            duration: makeDuration()
        )
        let report = ValidationReport.generate(from: result)
        let html = ReportGenerator.html(from: report)
        #expect(html.contains("&lt;profile&gt;"))
        #expect(html.contains("&amp;"))
    }

    @Test("HTML empty report has no table body rows")
    func htmlEmptyReport() {
        let report = makeEmptyReport()
        let html = ReportGenerator.html(from: report)
        // Should not contain a summary table since there are no summaries
        #expect(!html.contains("<tbody>"))
    }

    @Test("HTML includes inline CSS")
    func htmlIncludesCSS() {
        let report = makeReport()
        let html = ReportGenerator.html(from: report)
        #expect(html.contains("<style>"))
    }

    // MARK: - Text

    @Test("Text produces multi-line output")
    func textProducesOutput() {
        let report = makeReport()
        let text = ReportGenerator.text(from: report)
        #expect(!text.isEmpty)
        #expect(text.contains("\n"))
    }

    @Test("Text contains VALIDATION REPORT header")
    func textContainsHeader() {
        let report = makeReport()
        let text = ReportGenerator.text(from: report)
        #expect(text.contains("VALIDATION REPORT"))
    }

    @Test("Text contains document name")
    func textContainsDocumentName() {
        let report = makeReport()
        let text = ReportGenerator.text(from: report)
        #expect(text.contains("doc.pdf"))
    }

    @Test("Text contains profile name")
    func textContainsProfileName() {
        let report = makeReport(profileName: "PDF/UA-2")
        let text = ReportGenerator.text(from: report)
        #expect(text.contains("PDF/UA-2"))
    }

    @Test("Text shows compliance status")
    func textShowsCompliance() {
        let report = makeReport(isCompliant: false)
        let text = ReportGenerator.text(from: report)
        #expect(text.contains("NON-COMPLIANT"))
    }

    @Test("Text shows COMPLIANT for compliant docs")
    func textShowsCompliant() {
        let report = makeReport(isCompliant: true, assertions: [])
        let text = ReportGenerator.text(from: report)
        #expect(text.contains("COMPLIANT"))
    }

    @Test("Text contains assertion counts")
    func textContainsAssertionCounts() {
        let report = makeReport()
        let text = ReportGenerator.text(from: report)
        #expect(text.contains("passed"))
        #expect(text.contains("failed"))
    }

    @Test("Text contains RULE SUMMARIES section")
    func textContainsRuleSummaries() {
        let report = makeReport()
        let text = ReportGenerator.text(from: report)
        #expect(text.contains("RULE SUMMARIES"))
    }

    @Test("Text contains FAIL/PASS markers")
    func textContainsStatusMarkers() {
        let report = makeReport()
        let text = ReportGenerator.text(from: report)
        #expect(text.contains("[FAIL]"))
    }

    @Test("Text empty report has no rule summaries section")
    func textEmptyReport() {
        let report = makeEmptyReport()
        let text = ReportGenerator.text(from: report)
        #expect(!text.contains("RULE SUMMARIES"))
    }

    @Test("Text contains duration")
    func textContainsDuration() {
        let report = makeReport()
        let text = ReportGenerator.text(from: report)
        #expect(text.contains("Duration:"))
    }

    @Test("Text contains separator lines")
    func textContainsSeparators() {
        let report = makeReport()
        let text = ReportGenerator.text(from: report)
        #expect(text.contains("===="))
    }

    @Test("Text shows rule clause")
    func textShowsRuleClause() {
        let report = makeReport()
        let text = ReportGenerator.text(from: report)
        #expect(text.contains("Clause:"))
    }

    // MARK: - ReportGeneratorError

    @Test("ReportGeneratorError encodingFailed has description")
    func errorDescription() {
        let error = ReportGeneratorError.encodingFailed(format: "xml")
        #expect(error.localizedDescription.contains("xml"))
    }

    @Test("ReportGeneratorError is Equatable")
    func errorEquatable() {
        let a = ReportGeneratorError.encodingFailed(format: "xml")
        let b = ReportGeneratorError.encodingFailed(format: "xml")
        #expect(a == b)
    }

    @Test("ReportGeneratorError different formats not equal")
    func errorNotEqual() {
        let a = ReportGeneratorError.encodingFailed(format: "xml")
        let b = ReportGeneratorError.encodingFailed(format: "json")
        #expect(a != b)
    }
}
