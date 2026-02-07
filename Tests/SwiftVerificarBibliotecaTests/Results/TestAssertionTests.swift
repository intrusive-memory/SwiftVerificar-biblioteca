import Testing
import Foundation
@testable import SwiftVerificarBiblioteca
import SwiftVerificarValidationProfiles

// MARK: - TestAssertion Tests

@Suite("TestAssertion Tests")
struct TestAssertionTests {

    // MARK: - Helpers

    private static func sampleRuleID() -> RuleID {
        RuleID(specification: .iso142892, clause: "8.2.5.26", testNumber: 1)
    }

    private static func sampleLocation() -> PDFLocation {
        PDFLocation(objectKey: "42 0 obj", pageNumber: 3, structureID: "SE-17")
    }

    private static func sampleAssertion(
        id: UUID = UUID(),
        status: AssertionStatus = .failed,
        message: String = "Alt text missing",
        location: PDFLocation? = sampleLocation(),
        context: String? = "Figure",
        arguments: [String] = ["Alt", "Figure"]
    ) -> TestAssertion {
        TestAssertion(
            id: id,
            ruleID: sampleRuleID(),
            status: status,
            message: message,
            location: location,
            context: context,
            arguments: arguments
        )
    }

    // MARK: - Initialization

    @Test("Full initializer sets all fields")
    func fullInit() {
        let id = UUID()
        let ruleID = Self.sampleRuleID()
        let location = Self.sampleLocation()

        let assertion = TestAssertion(
            id: id,
            ruleID: ruleID,
            status: .failed,
            message: "Alt text missing",
            location: location,
            context: "Figure",
            arguments: ["Alt", "Figure"]
        )

        #expect(assertion.id == id)
        #expect(assertion.ruleID == ruleID)
        #expect(assertion.status == .failed)
        #expect(assertion.message == "Alt text missing")
        #expect(assertion.location == location)
        #expect(assertion.context == "Figure")
        #expect(assertion.arguments == ["Alt", "Figure"])
    }

    @Test("Default initializer generates a UUID and uses defaults for optional fields")
    func defaultInit() {
        let ruleID = Self.sampleRuleID()

        let assertion = TestAssertion(
            ruleID: ruleID,
            status: .passed,
            message: "Check passed"
        )

        #expect(assertion.ruleID == ruleID)
        #expect(assertion.status == .passed)
        #expect(assertion.message == "Check passed")
        #expect(assertion.location == nil)
        #expect(assertion.context == nil)
        #expect(assertion.arguments.isEmpty)
        // Verify a UUID was generated
        #expect(assertion.id.uuidString.isEmpty == false)
    }

    @Test("Unknown status can be created")
    func unknownStatusInit() {
        let assertion = TestAssertion(
            ruleID: Self.sampleRuleID(),
            status: .unknown,
            message: "Could not evaluate expression"
        )
        #expect(assertion.status == .unknown)
        #expect(assertion.status.isUnknown)
    }

    // MARK: - Identifiable

    @Test("Identifiable id matches the stored id")
    func identifiableConformance() {
        let id = UUID()
        let assertion = Self.sampleAssertion(id: id)
        #expect(assertion.id == id)
    }

    @Test("Two assertions with different ids are distinct")
    func differentIds() {
        let a = Self.sampleAssertion(id: UUID())
        let b = Self.sampleAssertion(id: UUID())
        #expect(a.id != b.id)
    }

    // MARK: - Equatable

    @Test("Equal assertions with same id and fields are equal")
    func equalAssertions() {
        let id = UUID()
        let a = Self.sampleAssertion(id: id)
        let b = Self.sampleAssertion(id: id)
        #expect(a == b)
    }

    @Test("Assertions with different statuses are not equal")
    func differentStatuses() {
        let id = UUID()
        let a = Self.sampleAssertion(id: id, status: .passed)
        let b = Self.sampleAssertion(id: id, status: .failed)
        #expect(a != b)
    }

    @Test("Assertions with different messages are not equal")
    func differentMessages() {
        let id = UUID()
        let a = Self.sampleAssertion(id: id, message: "msg1")
        let b = Self.sampleAssertion(id: id, message: "msg2")
        #expect(a != b)
    }

    @Test("Assertions with nil vs non-nil location are not equal")
    func nilVsNonNilLocation() {
        let id = UUID()
        let a = Self.sampleAssertion(id: id, location: nil)
        let b = Self.sampleAssertion(id: id, location: Self.sampleLocation())
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Hashable allows use in Set")
    func hashableConformance() {
        let id1 = UUID()
        let id2 = UUID()
        let a = Self.sampleAssertion(id: id1)
        let b = Self.sampleAssertion(id: id1)
        let c = Self.sampleAssertion(id: id2)
        let set: Set<TestAssertion> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("Codable round-trips for assertion with all fields")
    func codableRoundTripFull() throws {
        let original = Self.sampleAssertion()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(TestAssertion.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for assertion with nil optional fields")
    func codableRoundTripMinimal() throws {
        let original = TestAssertion(
            ruleID: Self.sampleRuleID(),
            status: .passed,
            message: "OK"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TestAssertion.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for assertion with empty arguments")
    func codableRoundTripEmptyArguments() throws {
        let original = TestAssertion(
            ruleID: Self.sampleRuleID(),
            status: .unknown,
            message: "Expression error",
            arguments: []
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TestAssertion.self, from: data)
        #expect(decoded.arguments.isEmpty)
        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes rule uniqueID and status")
    func descriptionContent() {
        let assertion = Self.sampleAssertion(status: .failed)
        let desc = assertion.description
        #expect(desc.contains(Self.sampleRuleID().uniqueID))
        #expect(desc.contains("failed"))
    }

    @Test("Description includes location when present")
    func descriptionWithLocation() {
        let assertion = Self.sampleAssertion(location: PDFLocation(pageNumber: 5))
        let desc = assertion.description
        #expect(desc.contains("page=5"))
    }

    @Test("Description without location does not contain 'at'")
    func descriptionWithoutLocation() {
        let assertion = Self.sampleAssertion(location: nil)
        let desc = assertion.description
        #expect(!desc.contains(" at "))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendableConformance() async {
        let assertion = Self.sampleAssertion()
        let result = await Task { assertion }.value
        #expect(result == assertion)
    }

    // MARK: - Edge Cases

    @Test("Empty message is valid")
    func emptyMessage() {
        let assertion = TestAssertion(
            ruleID: Self.sampleRuleID(),
            status: .passed,
            message: ""
        )
        #expect(assertion.message.isEmpty)
    }

    @Test("Multiple arguments preserved in order")
    func multipleArguments() {
        let args = ["arg1", "arg2", "arg3", "arg4"]
        let assertion = TestAssertion(
            ruleID: Self.sampleRuleID(),
            status: .failed,
            message: "Error with %1 and %2",
            arguments: args
        )
        #expect(assertion.arguments == args)
        #expect(assertion.arguments.count == 4)
    }
}
