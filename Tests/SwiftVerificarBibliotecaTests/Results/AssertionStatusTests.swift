import Testing
import Foundation
@testable import SwiftVerificarBiblioteca

// MARK: - AssertionStatus Tests

@Suite("AssertionStatus Tests")
struct AssertionStatusTests {

    // MARK: - Raw Values

    @Test("Raw value for passed is 'passed'")
    func passedRawValue() {
        #expect(AssertionStatus.passed.rawValue == "passed")
    }

    @Test("Raw value for failed is 'failed'")
    func failedRawValue() {
        #expect(AssertionStatus.failed.rawValue == "failed")
    }

    @Test("Raw value for unknown is 'unknown'")
    func unknownRawValue() {
        #expect(AssertionStatus.unknown.rawValue == "unknown")
    }

    // MARK: - Convenience Properties

    @Test("isPassed returns true only for passed")
    func isPassedProperty() {
        #expect(AssertionStatus.passed.isPassed == true)
        #expect(AssertionStatus.failed.isPassed == false)
        #expect(AssertionStatus.unknown.isPassed == false)
    }

    @Test("isFailed returns true only for failed")
    func isFailedProperty() {
        #expect(AssertionStatus.passed.isFailed == false)
        #expect(AssertionStatus.failed.isFailed == true)
        #expect(AssertionStatus.unknown.isFailed == false)
    }

    @Test("isUnknown returns true only for unknown")
    func isUnknownProperty() {
        #expect(AssertionStatus.passed.isUnknown == false)
        #expect(AssertionStatus.failed.isUnknown == false)
        #expect(AssertionStatus.unknown.isUnknown == true)
    }

    // MARK: - CaseIterable

    @Test("CaseIterable produces exactly three cases")
    func caseIterableCount() {
        #expect(AssertionStatus.allCases.count == 3)
        #expect(AssertionStatus.allCases.contains(.passed))
        #expect(AssertionStatus.allCases.contains(.failed))
        #expect(AssertionStatus.allCases.contains(.unknown))
    }

    // MARK: - Equatable

    @Test("Equatable conformance works correctly")
    func equatableConformance() {
        #expect(AssertionStatus.passed == AssertionStatus.passed)
        #expect(AssertionStatus.failed == AssertionStatus.failed)
        #expect(AssertionStatus.unknown == AssertionStatus.unknown)
        #expect(AssertionStatus.passed != AssertionStatus.failed)
        #expect(AssertionStatus.passed != AssertionStatus.unknown)
        #expect(AssertionStatus.failed != AssertionStatus.unknown)
    }

    // MARK: - Hashable

    @Test("Hashable conformance allows use in Set")
    func hashableConformance() {
        let set: Set<AssertionStatus> = [.passed, .failed, .unknown, .passed]
        #expect(set.count == 3)
    }

    // MARK: - Codable

    @Test("Codable round-trips for passed")
    func codableRoundTripPassed() throws {
        let original = AssertionStatus.passed
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssertionStatus.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for failed")
    func codableRoundTripFailed() throws {
        let original = AssertionStatus.failed
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssertionStatus.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for unknown")
    func codableRoundTripUnknown() throws {
        let original = AssertionStatus.unknown
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AssertionStatus.self, from: data)
        #expect(decoded == original)
    }

    @Test("Decoding invalid raw value fails")
    func codableInvalidValue() {
        let json = "\"invalid\"".data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(AssertionStatus.self, from: json)
        }
    }

    // MARK: - CustomStringConvertible

    @Test("Description matches raw value")
    func descriptionMatchesRawValue() {
        #expect(AssertionStatus.passed.description == "passed")
        #expect(AssertionStatus.failed.description == "failed")
        #expect(AssertionStatus.unknown.description == "unknown")
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendableConformance() async {
        let status = AssertionStatus.passed
        let result = await Task { status }.value
        #expect(result == .passed)
    }
}
