import Foundation
import Testing
@testable import SwiftVerificarBiblioteca
import SwiftVerificarValidationProfiles

@Suite("RuleSummary Tests")
struct RuleSummaryTests {

    // MARK: - Test Helpers

    private func makeRuleID(
        specification: Specification = .iso142892,
        clause: String = "8.2.5.26",
        testNumber: Int = 1
    ) -> RuleID {
        RuleID(specification: specification, clause: clause, testNumber: testNumber)
    }

    private func makeSummary(
        ruleID: RuleID? = nil,
        passedCount: Int = 5,
        failedCount: Int = 3,
        ruleDescription: String = "Test rule description"
    ) -> RuleSummary {
        RuleSummary(
            ruleID: ruleID ?? makeRuleID(),
            passedCount: passedCount,
            failedCount: failedCount,
            ruleDescription: ruleDescription
        )
    }

    // MARK: - Initialization

    @Test("Init stores all properties correctly")
    func initStoresProperties() {
        let ruleID = makeRuleID()
        let summary = RuleSummary(
            ruleID: ruleID,
            passedCount: 10,
            failedCount: 2,
            ruleDescription: "Alt text missing"
        )

        #expect(summary.ruleID == ruleID)
        #expect(summary.passedCount == 10)
        #expect(summary.failedCount == 2)
        #expect(summary.ruleDescription == "Alt text missing")
    }

    @Test("Init with zero counts")
    func initWithZeroCounts() {
        let summary = makeSummary(passedCount: 0, failedCount: 0)
        #expect(summary.passedCount == 0)
        #expect(summary.failedCount == 0)
    }

    @Test("Init with empty description")
    func initWithEmptyDescription() {
        let summary = makeSummary(ruleDescription: "")
        #expect(summary.ruleDescription == "")
    }

    @Test("Init with large counts")
    func initWithLargeCounts() {
        let summary = makeSummary(passedCount: 100_000, failedCount: 50_000)
        #expect(summary.passedCount == 100_000)
        #expect(summary.failedCount == 50_000)
    }

    // MARK: - totalChecks

    @Test("totalChecks returns sum of passed and failed")
    func totalChecks() {
        let summary = makeSummary(passedCount: 7, failedCount: 3)
        #expect(summary.totalChecks == 10)
    }

    @Test("totalChecks when all passed")
    func totalChecksAllPassed() {
        let summary = makeSummary(passedCount: 5, failedCount: 0)
        #expect(summary.totalChecks == 5)
    }

    @Test("totalChecks when all failed")
    func totalChecksAllFailed() {
        let summary = makeSummary(passedCount: 0, failedCount: 8)
        #expect(summary.totalChecks == 8)
    }

    @Test("totalChecks when both zero")
    func totalChecksBothZero() {
        let summary = makeSummary(passedCount: 0, failedCount: 0)
        #expect(summary.totalChecks == 0)
    }

    // MARK: - failureRate

    @Test("failureRate calculates correctly")
    func failureRate() {
        let summary = makeSummary(passedCount: 7, failedCount: 3)
        #expect(summary.failureRate == 0.3)
    }

    @Test("failureRate is zero when no failures")
    func failureRateNoFailures() {
        let summary = makeSummary(passedCount: 10, failedCount: 0)
        #expect(summary.failureRate == 0.0)
    }

    @Test("failureRate is 1.0 when all failed")
    func failureRateAllFailed() {
        let summary = makeSummary(passedCount: 0, failedCount: 5)
        #expect(summary.failureRate == 1.0)
    }

    @Test("failureRate is zero when both counts are zero")
    func failureRateBothZero() {
        let summary = makeSummary(passedCount: 0, failedCount: 0)
        #expect(summary.failureRate == 0.0)
    }

    @Test("failureRate at 50%")
    func failureRateHalf() {
        let summary = makeSummary(passedCount: 5, failedCount: 5)
        #expect(summary.failureRate == 0.5)
    }

    // MARK: - passRate

    @Test("passRate calculates correctly")
    func passRate() {
        let summary = makeSummary(passedCount: 7, failedCount: 3)
        #expect(summary.passRate == 0.7)
    }

    @Test("passRate is zero when no passes")
    func passRateNoPasses() {
        let summary = makeSummary(passedCount: 0, failedCount: 5)
        #expect(summary.passRate == 0.0)
    }

    @Test("passRate is 1.0 when all passed")
    func passRateAllPassed() {
        let summary = makeSummary(passedCount: 10, failedCount: 0)
        #expect(summary.passRate == 1.0)
    }

    @Test("passRate is zero when both zero")
    func passRateBothZero() {
        let summary = makeSummary(passedCount: 0, failedCount: 0)
        #expect(summary.passRate == 0.0)
    }

    // MARK: - isFullyPassing

    @Test("isFullyPassing when no failures")
    func isFullyPassingTrue() {
        let summary = makeSummary(passedCount: 10, failedCount: 0)
        #expect(summary.isFullyPassing)
    }

    @Test("isFullyPassing is false when failures exist")
    func isFullyPassingFalse() {
        let summary = makeSummary(passedCount: 10, failedCount: 1)
        #expect(!summary.isFullyPassing)
    }

    @Test("isFullyPassing with zero checks")
    func isFullyPassingZeroChecks() {
        let summary = makeSummary(passedCount: 0, failedCount: 0)
        #expect(summary.isFullyPassing)
    }

    // MARK: - isFullyFailing

    @Test("isFullyFailing when all failed")
    func isFullyFailingTrue() {
        let summary = makeSummary(passedCount: 0, failedCount: 5)
        #expect(summary.isFullyFailing)
    }

    @Test("isFullyFailing is false when some passed")
    func isFullyFailingFalse() {
        let summary = makeSummary(passedCount: 1, failedCount: 5)
        #expect(!summary.isFullyFailing)
    }

    @Test("isFullyFailing is false when both zero")
    func isFullyFailingBothZero() {
        let summary = makeSummary(passedCount: 0, failedCount: 0)
        #expect(!summary.isFullyFailing)
    }

    // MARK: - Equatable

    @Test("Equatable — equal summaries")
    func equatable() {
        let ruleID = makeRuleID()
        let a = RuleSummary(ruleID: ruleID, passedCount: 5, failedCount: 3, ruleDescription: "desc")
        let b = RuleSummary(ruleID: ruleID, passedCount: 5, failedCount: 3, ruleDescription: "desc")
        #expect(a == b)
    }

    @Test("Equatable — different failedCount")
    func equatableDifferentFailedCount() {
        let ruleID = makeRuleID()
        let a = RuleSummary(ruleID: ruleID, passedCount: 5, failedCount: 3, ruleDescription: "desc")
        let b = RuleSummary(ruleID: ruleID, passedCount: 5, failedCount: 4, ruleDescription: "desc")
        #expect(a != b)
    }

    @Test("Equatable — different ruleID")
    func equatableDifferentRuleID() {
        let a = makeSummary(ruleID: makeRuleID(clause: "8.2.5.26"))
        let b = makeSummary(ruleID: makeRuleID(clause: "8.2.5.27"))
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Hashable — equal summaries produce same hash")
    func hashable() {
        let ruleID = makeRuleID()
        let a = RuleSummary(ruleID: ruleID, passedCount: 5, failedCount: 3, ruleDescription: "desc")
        let b = RuleSummary(ruleID: ruleID, passedCount: 5, failedCount: 3, ruleDescription: "desc")
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Hashable — can be used in a Set")
    func hashableSet() {
        let a = makeSummary(ruleID: makeRuleID(clause: "1.0"))
        let b = makeSummary(ruleID: makeRuleID(clause: "2.0"))
        let set: Set<RuleSummary> = [a, b]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let summary = makeSummary()
        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(RuleSummary.self, from: data)
        #expect(summary == decoded)
    }

    @Test("Codable encodes ruleDescription field")
    func codableFieldName() throws {
        let summary = makeSummary(ruleDescription: "My rule")
        let data = try JSONEncoder().encode(summary)
        let json = String(data: data, encoding: .utf8)
        #expect(json?.contains("ruleDescription") == true)
        #expect(json?.contains("My rule") == true)
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let summary = makeSummary()
        let result = await Task { summary }.value
        #expect(result == summary)
    }

    // MARK: - CustomStringConvertible

    @Test("Description contains rule ID")
    func descriptionContainsRuleID() {
        let summary = makeSummary()
        let desc = summary.description
        #expect(desc.contains(summary.ruleID.uniqueID))
    }

    @Test("Description contains passed count")
    func descriptionContainsPassedCount() {
        let summary = makeSummary(passedCount: 12, failedCount: 3)
        let desc = summary.description
        #expect(desc.contains("12 passed"))
    }

    @Test("Description contains failed count")
    func descriptionContainsFailedCount() {
        let summary = makeSummary(passedCount: 12, failedCount: 3)
        let desc = summary.description
        #expect(desc.contains("3 failed"))
    }

    @Test("Description contains failure rate")
    func descriptionContainsFailureRate() {
        let summary = makeSummary(passedCount: 8, failedCount: 2)
        let desc = summary.description
        #expect(desc.contains("20.0%"))
    }
}
