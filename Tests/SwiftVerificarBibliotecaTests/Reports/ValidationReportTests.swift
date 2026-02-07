import Foundation
import Testing
@testable import SwiftVerificarBiblioteca
import SwiftVerificarValidationProfiles

@Suite("ValidationReport Tests")
struct ValidationReportTests {

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
        let end = Date(timeIntervalSinceReferenceDate: 2)
        return ValidationDuration(start: start, end: end)
    }

    private func makeResult(
        profileName: String = "PDF/UA-2",
        isCompliant: Bool = false,
        assertions: [TestAssertion] = []
    ) -> ValidationResult {
        ValidationResult(
            profileName: profileName,
            documentURL: URL(fileURLWithPath: "/test/doc.pdf"),
            isCompliant: isCompliant,
            assertions: assertions,
            duration: makeDuration()
        )
    }

    // MARK: - Initialization

    @Test("Init stores result and summaries")
    func initStoresProperties() {
        let result = makeResult()
        let summary = RuleSummary(
            ruleID: makeRuleID(),
            passedCount: 5,
            failedCount: 2,
            ruleDescription: "desc"
        )
        let report = ValidationReport(result: result, summaries: [summary])

        #expect(report.result == result)
        #expect(report.summaries.count == 1)
        #expect(report.summaries[0] == summary)
    }

    @Test("Init with empty summaries")
    func initEmptySummaries() {
        let result = makeResult()
        let report = ValidationReport(result: result, summaries: [])
        #expect(report.summaries.isEmpty)
    }

    // MARK: - generate(from:)

    @Test("Generate from empty assertions produces empty summaries")
    func generateEmpty() {
        let result = makeResult(isCompliant: true, assertions: [])
        let report = ValidationReport.generate(from: result)
        #expect(report.summaries.isEmpty)
        #expect(report.result == result)
    }

    @Test("Generate groups assertions by ruleID")
    func generateGroupsByRuleID() {
        let ruleA = makeRuleID(clause: "1.0")
        let ruleB = makeRuleID(clause: "2.0")
        let assertions = [
            makeAssertion(ruleID: ruleA, status: .passed),
            makeAssertion(ruleID: ruleA, status: .failed),
            makeAssertion(ruleID: ruleB, status: .passed),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)

        #expect(report.summaries.count == 2)
    }

    @Test("Generate sorts summaries by failedCount descending")
    func generateSortsByFailedCount() {
        let ruleA = makeRuleID(clause: "1.0")
        let ruleB = makeRuleID(clause: "2.0")
        let assertions = [
            makeAssertion(ruleID: ruleA, status: .failed),
            makeAssertion(ruleID: ruleB, status: .failed),
            makeAssertion(ruleID: ruleB, status: .failed),
            makeAssertion(ruleID: ruleB, status: .failed),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)

        #expect(report.summaries[0].ruleID == ruleB)
        #expect(report.summaries[0].failedCount == 3)
        #expect(report.summaries[1].ruleID == ruleA)
        #expect(report.summaries[1].failedCount == 1)
    }

    @Test("Generate correctly counts passed and failed")
    func generateCountsCorrectly() {
        let ruleID = makeRuleID()
        let assertions = [
            makeAssertion(ruleID: ruleID, status: .passed),
            makeAssertion(ruleID: ruleID, status: .passed),
            makeAssertion(ruleID: ruleID, status: .failed),
            makeAssertion(ruleID: ruleID, status: .unknown),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)

        #expect(report.summaries.count == 1)
        #expect(report.summaries[0].passedCount == 2)
        #expect(report.summaries[0].failedCount == 1)
    }

    @Test("Generate uses first assertion message as description")
    func generateUsesFirstMessage() {
        let ruleID = makeRuleID()
        let assertions = [
            makeAssertion(ruleID: ruleID, status: .failed, message: "first message"),
            makeAssertion(ruleID: ruleID, status: .failed, message: "second message"),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)

        #expect(report.summaries[0].ruleDescription == "first message")
    }

    @Test("Generate with all passing assertions")
    func generateAllPassing() {
        let ruleID = makeRuleID()
        let assertions = [
            makeAssertion(ruleID: ruleID, status: .passed, message: "all good"),
        ]
        let result = makeResult(isCompliant: true, assertions: assertions)
        let report = ValidationReport.generate(from: result)

        #expect(report.summaries.count == 1)
        #expect(report.summaries[0].failedCount == 0)
        #expect(report.summaries[0].passedCount == 1)
    }

    @Test("Generate with multiple rules mixed")
    func generateMultipleRulesMixed() {
        let rule1 = makeRuleID(clause: "1.0")
        let rule2 = makeRuleID(clause: "2.0")
        let rule3 = makeRuleID(clause: "3.0")
        let assertions = [
            makeAssertion(ruleID: rule1, status: .passed),
            makeAssertion(ruleID: rule2, status: .failed),
            makeAssertion(ruleID: rule2, status: .failed),
            makeAssertion(ruleID: rule3, status: .passed),
            makeAssertion(ruleID: rule3, status: .failed),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)

        #expect(report.summaries.count == 3)
        // rule2 has 2 failures, should be first
        #expect(report.summaries[0].failedCount == 2)
    }

    // MARK: - Computed Properties

    @Test("ruleCount returns number of summaries")
    func ruleCount() {
        let assertions = [
            makeAssertion(ruleID: makeRuleID(clause: "1.0")),
            makeAssertion(ruleID: makeRuleID(clause: "2.0")),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)
        #expect(report.ruleCount == 2)
    }

    @Test("failedRuleCount counts rules with failures")
    func failedRuleCount() {
        let assertions = [
            makeAssertion(ruleID: makeRuleID(clause: "1.0"), status: .passed),
            makeAssertion(ruleID: makeRuleID(clause: "2.0"), status: .failed),
            makeAssertion(ruleID: makeRuleID(clause: "3.0"), status: .failed),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)
        #expect(report.failedRuleCount == 2)
    }

    @Test("passedRuleCount counts rules without failures")
    func passedRuleCount() {
        let assertions = [
            makeAssertion(ruleID: makeRuleID(clause: "1.0"), status: .passed),
            makeAssertion(ruleID: makeRuleID(clause: "2.0"), status: .failed),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)
        #expect(report.passedRuleCount == 1)
    }

    @Test("overallFailureRate calculates correctly")
    func overallFailureRate() {
        let ruleID = makeRuleID()
        let assertions = [
            makeAssertion(ruleID: ruleID, status: .passed),
            makeAssertion(ruleID: ruleID, status: .passed),
            makeAssertion(ruleID: ruleID, status: .failed),
            makeAssertion(ruleID: ruleID, status: .failed),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)
        #expect(report.overallFailureRate == 0.5)
    }

    @Test("overallFailureRate is zero when no assertions")
    func overallFailureRateEmpty() {
        let result = makeResult(assertions: [])
        let report = ValidationReport.generate(from: result)
        #expect(report.overallFailureRate == 0.0)
    }

    @Test("failedSummaries filters correctly")
    func failedSummaries() {
        let assertions = [
            makeAssertion(ruleID: makeRuleID(clause: "1.0"), status: .passed),
            makeAssertion(ruleID: makeRuleID(clause: "2.0"), status: .failed),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)
        #expect(report.failedSummaries.count == 1)
        #expect(report.failedSummaries[0].failedCount > 0)
    }

    @Test("passedSummaries filters correctly")
    func passedSummaries() {
        let assertions = [
            makeAssertion(ruleID: makeRuleID(clause: "1.0"), status: .passed),
            makeAssertion(ruleID: makeRuleID(clause: "2.0"), status: .failed),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)
        #expect(report.passedSummaries.count == 1)
        #expect(report.passedSummaries[0].failedCount == 0)
    }

    // MARK: - Equatable

    @Test("Equatable — same reports are equal")
    func equatable() {
        let result = makeResult(isCompliant: true, assertions: [])
        let a = ValidationReport(result: result, summaries: [])
        let b = ValidationReport(result: result, summaries: [])
        #expect(a == b)
    }

    @Test("Equatable — different results are not equal")
    func equatableDifferent() {
        let resultA = makeResult(profileName: "Profile A", assertions: [])
        let resultB = makeResult(profileName: "Profile B", assertions: [])
        let a = ValidationReport(result: resultA, summaries: [])
        let b = ValidationReport(result: resultB, summaries: [])
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let assertions = [
            makeAssertion(ruleID: makeRuleID(), status: .passed, message: "ok"),
        ]
        let result = makeResult(isCompliant: true, assertions: assertions)
        let report = ValidationReport.generate(from: result)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(report)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ValidationReport.self, from: data)

        #expect(decoded.result == report.result)
        #expect(decoded.summaries == report.summaries)
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let result = makeResult(assertions: [])
        let report = ValidationReport.generate(from: result)
        let transferred = await Task { report }.value
        #expect(transferred == report)
    }

    // MARK: - CustomStringConvertible

    @Test("Description for compliant report")
    func descriptionCompliant() {
        let result = makeResult(isCompliant: true, assertions: [])
        let report = ValidationReport.generate(from: result)
        #expect(report.description.contains("COMPLIANT"))
    }

    @Test("Description for non-compliant report")
    func descriptionNonCompliant() {
        let result = makeResult(isCompliant: false, assertions: [])
        let report = ValidationReport.generate(from: result)
        #expect(report.description.contains("NON-COMPLIANT"))
    }

    @Test("Description contains rule count")
    func descriptionContainsRuleCount() {
        let assertions = [
            makeAssertion(ruleID: makeRuleID(clause: "1.0")),
            makeAssertion(ruleID: makeRuleID(clause: "2.0")),
        ]
        let result = makeResult(assertions: assertions)
        let report = ValidationReport.generate(from: result)
        #expect(report.description.contains("2 rules"))
    }
}
