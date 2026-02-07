import Testing
import Foundation
@testable import SwiftVerificarBiblioteca
import SwiftVerificarValidationProfiles

// MARK: - ValidationResult Tests

@Suite("ValidationResult Tests")
struct ValidationResultTests {

    // MARK: - Helpers

    private static let testURL = URL(fileURLWithPath: "/tmp/test.pdf")
    private static let profileName = "PDF/UA-2 validation profile"

    private static func sampleRuleID(clause: String = "8.2.5.26", testNumber: Int = 1) -> RuleID {
        RuleID(specification: .iso142892, clause: clause, testNumber: testNumber)
    }

    private static func sampleDuration() -> ValidationDuration {
        let start = Date(timeIntervalSince1970: 1000)
        let end = Date(timeIntervalSince1970: 1002.5)
        return ValidationDuration(start: start, end: end)
    }

    private static func makeAssertion(
        ruleID: RuleID = sampleRuleID(),
        status: AssertionStatus = .passed,
        message: String = "Test message"
    ) -> TestAssertion {
        TestAssertion(
            ruleID: ruleID,
            status: status,
            message: message
        )
    }

    // MARK: - Initialization

    @Test("Full initializer sets all fields")
    func fullInit() {
        let duration = Self.sampleDuration()
        let assertions = [
            Self.makeAssertion(status: .passed),
            Self.makeAssertion(status: .failed),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: duration
        )
        #expect(result.profileName == Self.profileName)
        #expect(result.documentURL == Self.testURL)
        #expect(result.isCompliant == false)
        #expect(result.assertions.count == 2)
        #expect(result.duration == duration)
    }

    @Test("Compliant result with no assertions")
    func compliantNoAssertions() {
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: true,
            assertions: [],
            duration: Self.sampleDuration()
        )
        #expect(result.isCompliant == true)
        #expect(result.assertions.isEmpty)
    }

    // MARK: - Computed Properties: Counts

    @Test("passedCount returns correct count")
    func passedCount() {
        let assertions = [
            Self.makeAssertion(status: .passed),
            Self.makeAssertion(status: .passed),
            Self.makeAssertion(status: .failed),
            Self.makeAssertion(status: .unknown),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        #expect(result.passedCount == 2)
    }

    @Test("failedCount returns correct count")
    func failedCount() {
        let assertions = [
            Self.makeAssertion(status: .passed),
            Self.makeAssertion(status: .failed),
            Self.makeAssertion(status: .failed),
            Self.makeAssertion(status: .failed),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        #expect(result.failedCount == 3)
    }

    @Test("unknownCount returns correct count")
    func unknownCount() {
        let assertions = [
            Self.makeAssertion(status: .unknown),
            Self.makeAssertion(status: .unknown),
            Self.makeAssertion(status: .passed),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        #expect(result.unknownCount == 2)
    }

    @Test("totalCount matches assertions.count")
    func totalCount() {
        let assertions = [
            Self.makeAssertion(status: .passed),
            Self.makeAssertion(status: .failed),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        #expect(result.totalCount == 2)
    }

    @Test("Counts are zero for empty assertions")
    func countsForEmptyAssertions() {
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: true,
            assertions: [],
            duration: Self.sampleDuration()
        )
        #expect(result.passedCount == 0)
        #expect(result.failedCount == 0)
        #expect(result.unknownCount == 0)
        #expect(result.totalCount == 0)
    }

    // MARK: - Computed Properties: Grouping

    @Test("failedByRule groups failures correctly")
    func failedByRule() {
        let ruleA = Self.sampleRuleID(clause: "8.2.5.26", testNumber: 1)
        let ruleB = Self.sampleRuleID(clause: "8.4.3", testNumber: 2)
        let assertions = [
            Self.makeAssertion(ruleID: ruleA, status: .failed),
            Self.makeAssertion(ruleID: ruleA, status: .failed),
            Self.makeAssertion(ruleID: ruleB, status: .failed),
            Self.makeAssertion(ruleID: ruleA, status: .passed), // not included
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        let grouped = result.failedByRule
        #expect(grouped.count == 2)
        #expect(grouped[ruleA]?.count == 2)
        #expect(grouped[ruleB]?.count == 1)
    }

    @Test("failedByRule is empty when no failures")
    func failedByRuleEmpty() {
        let assertions = [
            Self.makeAssertion(status: .passed),
            Self.makeAssertion(status: .unknown),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: true,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        #expect(result.failedByRule.isEmpty)
    }

    @Test("failedRuleIDs returns unique set of failing rule IDs")
    func failedRuleIDs() {
        let ruleA = Self.sampleRuleID(clause: "8.2.5.26", testNumber: 1)
        let ruleB = Self.sampleRuleID(clause: "8.4.3", testNumber: 2)
        let assertions = [
            Self.makeAssertion(ruleID: ruleA, status: .failed),
            Self.makeAssertion(ruleID: ruleA, status: .failed),
            Self.makeAssertion(ruleID: ruleB, status: .failed),
            Self.makeAssertion(ruleID: ruleB, status: .passed),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        #expect(result.failedRuleIDs.count == 2)
        #expect(result.failedRuleIDs.contains(ruleA))
        #expect(result.failedRuleIDs.contains(ruleB))
    }

    @Test("errorCodes returns unique error code strings")
    func errorCodes() {
        let ruleA = Self.sampleRuleID(clause: "8.2.5.26", testNumber: 1)
        let ruleB = Self.sampleRuleID(clause: "8.4.3", testNumber: 2)
        let assertions = [
            Self.makeAssertion(ruleID: ruleA, status: .failed),
            Self.makeAssertion(ruleID: ruleA, status: .failed),
            Self.makeAssertion(ruleID: ruleB, status: .failed),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        #expect(result.errorCodes.count == 2)
        #expect(result.errorCodes.contains(ruleA.uniqueID))
        #expect(result.errorCodes.contains(ruleB.uniqueID))
    }

    // MARK: - assertions(withStatus:)

    @Test("assertions(withStatus:) filters correctly")
    func assertionsWithStatus() {
        let assertions = [
            Self.makeAssertion(status: .passed, message: "p1"),
            Self.makeAssertion(status: .failed, message: "f1"),
            Self.makeAssertion(status: .passed, message: "p2"),
            Self.makeAssertion(status: .unknown, message: "u1"),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        #expect(result.assertions(withStatus: .passed).count == 2)
        #expect(result.assertions(withStatus: .failed).count == 1)
        #expect(result.assertions(withStatus: .unknown).count == 1)
    }

    @Test("assertions(withStatus:) returns empty array for unmatched status")
    func assertionsWithStatusUnmatched() {
        let assertions = [
            Self.makeAssertion(status: .passed),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: true,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        #expect(result.assertions(withStatus: .failed).isEmpty)
        #expect(result.assertions(withStatus: .unknown).isEmpty)
    }

    // MARK: - Factory Methods

    @Test("compliant() factory creates correct result")
    func compliantFactory() {
        let duration = Self.sampleDuration()
        let result = ValidationResult.compliant(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            duration: duration
        )
        #expect(result.isCompliant == true)
        #expect(result.assertions.isEmpty)
        #expect(result.profileName == Self.profileName)
        #expect(result.documentURL == Self.testURL)
        #expect(result.duration == duration)
        #expect(result.passedCount == 0)
        #expect(result.failedCount == 0)
    }

    // MARK: - Equatable

    @Test("Equal results are equal")
    func equalResults() {
        let duration = Self.sampleDuration()
        let id = UUID()
        let assertion = TestAssertion(
            id: id,
            ruleID: Self.sampleRuleID(),
            status: .passed,
            message: "OK"
        )
        let a = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: true,
            assertions: [assertion],
            duration: duration
        )
        let b = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: true,
            assertions: [assertion],
            duration: duration
        )
        #expect(a == b)
    }

    @Test("Results with different compliance status are not equal")
    func differentCompliance() {
        let duration = Self.sampleDuration()
        let a = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: true,
            assertions: [],
            duration: duration
        )
        let b = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: [],
            duration: duration
        )
        #expect(a != b)
    }

    @Test("Results with different profile names are not equal")
    func differentProfileNames() {
        let duration = Self.sampleDuration()
        let a = ValidationResult(
            profileName: "Profile A",
            documentURL: Self.testURL,
            isCompliant: true,
            assertions: [],
            duration: duration
        )
        let b = ValidationResult(
            profileName: "Profile B",
            documentURL: Self.testURL,
            isCompliant: true,
            assertions: [],
            duration: duration
        )
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Hashable allows use in Set")
    func hashableConformance() {
        let duration = Self.sampleDuration()
        let a = ValidationResult(
            profileName: "A",
            documentURL: Self.testURL,
            isCompliant: true,
            assertions: [],
            duration: duration
        )
        let b = ValidationResult(
            profileName: "B",
            documentURL: Self.testURL,
            isCompliant: true,
            assertions: [],
            duration: duration
        )
        let set: Set<ValidationResult> = [a, a, b]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("Codable round-trips for full result")
    func codableRoundTripFull() throws {
        let id = UUID()
        let assertion = TestAssertion(
            id: id,
            ruleID: Self.sampleRuleID(),
            status: .failed,
            message: "Issue found",
            location: PDFLocation(pageNumber: 3),
            context: "Figure",
            arguments: ["Alt"]
        )
        let original = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: [assertion],
            duration: Self.sampleDuration()
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(ValidationResult.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for empty result")
    func codableRoundTripEmpty() throws {
        let original = ValidationResult.compliant(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            duration: Self.sampleDuration()
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ValidationResult.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for result with multiple assertions")
    func codableRoundTripMultiple() throws {
        let ruleA = Self.sampleRuleID(clause: "1.1", testNumber: 1)
        let ruleB = Self.sampleRuleID(clause: "2.2", testNumber: 3)
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let assertions = [
            TestAssertion(id: id1, ruleID: ruleA, status: .passed, message: "OK"),
            TestAssertion(id: id2, ruleID: ruleB, status: .failed, message: "Error"),
            TestAssertion(id: id3, ruleID: ruleA, status: .unknown, message: "N/A"),
        ]
        let original = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ValidationResult.self, from: data)
        #expect(decoded == original)
        #expect(decoded.passedCount == 1)
        #expect(decoded.failedCount == 1)
        #expect(decoded.unknownCount == 1)
    }

    // MARK: - CustomStringConvertible

    @Test("Description for compliant result contains COMPLIANT")
    func descriptionCompliant() {
        let result = ValidationResult.compliant(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            duration: Self.sampleDuration()
        )
        #expect(result.description.contains("COMPLIANT"))
        #expect(!result.description.contains("NON-COMPLIANT"))
    }

    @Test("Description for non-compliant result contains NON-COMPLIANT")
    func descriptionNonCompliant() {
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: [Self.makeAssertion(status: .failed)],
            duration: Self.sampleDuration()
        )
        #expect(result.description.contains("NON-COMPLIANT"))
    }

    @Test("Description includes pass and fail counts")
    func descriptionCounts() {
        let assertions = [
            Self.makeAssertion(status: .passed),
            Self.makeAssertion(status: .passed),
            Self.makeAssertion(status: .failed),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        let desc = result.description
        #expect(desc.contains("2 passed"))
        #expect(desc.contains("1 failed"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendableConformance() async {
        let result = ValidationResult.compliant(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            duration: Self.sampleDuration()
        )
        let returned = await Task { result }.value
        #expect(returned == result)
    }

    // MARK: - Edge Cases

    @Test("Result with all three status types")
    func allThreeStatuses() {
        let assertions = [
            Self.makeAssertion(status: .passed),
            Self.makeAssertion(status: .failed),
            Self.makeAssertion(status: .unknown),
        ]
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        #expect(result.passedCount == 1)
        #expect(result.failedCount == 1)
        #expect(result.unknownCount == 1)
        #expect(result.totalCount == 3)
    }

    @Test("Result with many assertions of same rule")
    func manyAssertionsSameRule() {
        let ruleID = Self.sampleRuleID()
        let assertions = (0..<100).map { i in
            Self.makeAssertion(ruleID: ruleID, status: i < 50 ? .passed : .failed)
        }
        let result = ValidationResult(
            profileName: Self.profileName,
            documentURL: Self.testURL,
            isCompliant: false,
            assertions: assertions,
            duration: Self.sampleDuration()
        )
        #expect(result.passedCount == 50)
        #expect(result.failedCount == 50)
        #expect(result.failedByRule.count == 1)
        #expect(result.failedByRule[ruleID]?.count == 50)
        #expect(result.failedRuleIDs.count == 1)
        #expect(result.errorCodes.count == 1)
    }
}
