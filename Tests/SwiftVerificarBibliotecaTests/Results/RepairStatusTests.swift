import Testing
import Foundation
@testable import SwiftVerificarBiblioteca

// MARK: - RepairStatus Tests

@Suite("RepairStatus Tests")
struct RepairStatusTests {

    // MARK: - Raw Values

    @Test("Raw value for success is 'success'")
    func successRawValue() {
        #expect(RepairStatus.success.rawValue == "success")
    }

    @Test("Raw value for partialSuccess is 'partialSuccess'")
    func partialSuccessRawValue() {
        #expect(RepairStatus.partialSuccess.rawValue == "partialSuccess")
    }

    @Test("Raw value for noFixesNeeded is 'noFixesNeeded'")
    func noFixesNeededRawValue() {
        #expect(RepairStatus.noFixesNeeded.rawValue == "noFixesNeeded")
    }

    @Test("Raw value for failed is 'failed'")
    func failedRawValue() {
        #expect(RepairStatus.failed.rawValue == "failed")
    }

    @Test("Raw value for idRemoved is 'idRemoved'")
    func idRemovedRawValue() {
        #expect(RepairStatus.idRemoved.rawValue == "idRemoved")
    }

    // MARK: - Convenience: isSuccess

    @Test("isSuccess returns true only for success")
    func isSuccessProperty() {
        #expect(RepairStatus.success.isSuccess == true)
        #expect(RepairStatus.partialSuccess.isSuccess == false)
        #expect(RepairStatus.noFixesNeeded.isSuccess == false)
        #expect(RepairStatus.failed.isSuccess == false)
        #expect(RepairStatus.idRemoved.isSuccess == false)
    }

    // MARK: - Convenience: hasAppliedFixes

    @Test("hasAppliedFixes returns true for success and partialSuccess")
    func hasAppliedFixesProperty() {
        #expect(RepairStatus.success.hasAppliedFixes == true)
        #expect(RepairStatus.partialSuccess.hasAppliedFixes == true)
        #expect(RepairStatus.noFixesNeeded.hasAppliedFixes == false)
        #expect(RepairStatus.failed.hasAppliedFixes == false)
        #expect(RepairStatus.idRemoved.hasAppliedFixes == false)
    }

    // MARK: - Convenience: isTerminal

    @Test("isTerminal returns true for all except partialSuccess")
    func isTerminalProperty() {
        #expect(RepairStatus.success.isTerminal == true)
        #expect(RepairStatus.partialSuccess.isTerminal == false)
        #expect(RepairStatus.noFixesNeeded.isTerminal == true)
        #expect(RepairStatus.failed.isTerminal == true)
        #expect(RepairStatus.idRemoved.isTerminal == true)
    }

    // MARK: - CaseIterable

    @Test("CaseIterable produces exactly five cases")
    func caseIterableCount() {
        #expect(RepairStatus.allCases.count == 5)
        #expect(RepairStatus.allCases.contains(.success))
        #expect(RepairStatus.allCases.contains(.partialSuccess))
        #expect(RepairStatus.allCases.contains(.noFixesNeeded))
        #expect(RepairStatus.allCases.contains(.failed))
        #expect(RepairStatus.allCases.contains(.idRemoved))
    }

    // MARK: - Equatable

    @Test("Equatable conformance works correctly")
    func equatableConformance() {
        #expect(RepairStatus.success == RepairStatus.success)
        #expect(RepairStatus.failed == RepairStatus.failed)
        #expect(RepairStatus.success != RepairStatus.failed)
        #expect(RepairStatus.partialSuccess != RepairStatus.success)
        #expect(RepairStatus.noFixesNeeded != RepairStatus.idRemoved)
    }

    // MARK: - Hashable

    @Test("Hashable conformance allows use in Set")
    func hashableConformance() {
        let set: Set<RepairStatus> = [.success, .failed, .noFixesNeeded, .success]
        #expect(set.count == 3)
    }

    @Test("All cases produce distinct hash values when in a Set")
    func allCasesDistinctInSet() {
        let set = Set(RepairStatus.allCases)
        #expect(set.count == 5)
    }

    // MARK: - Codable

    @Test("Codable round-trips for success")
    func codableRoundTripSuccess() throws {
        let original = RepairStatus.success
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RepairStatus.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for partialSuccess")
    func codableRoundTripPartialSuccess() throws {
        let original = RepairStatus.partialSuccess
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RepairStatus.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for noFixesNeeded")
    func codableRoundTripNoFixesNeeded() throws {
        let original = RepairStatus.noFixesNeeded
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RepairStatus.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for failed")
    func codableRoundTripFailed() throws {
        let original = RepairStatus.failed
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RepairStatus.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for idRemoved")
    func codableRoundTripIdRemoved() throws {
        let original = RepairStatus.idRemoved
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RepairStatus.self, from: data)
        #expect(decoded == original)
    }

    @Test("Decoding invalid raw value fails")
    func codableInvalidValue() {
        let json = "\"invalid\"".data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RepairStatus.self, from: json)
        }
    }

    @Test("Codable round-trips for all cases")
    func codableRoundTripAllCases() throws {
        for status in RepairStatus.allCases {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(RepairStatus.self, from: data)
            #expect(decoded == status)
        }
    }

    // MARK: - CustomStringConvertible

    @Test("Description matches raw value for each case")
    func descriptionMatchesRawValue() {
        for status in RepairStatus.allCases {
            #expect(status.description == status.rawValue)
        }
    }

    @Test("Description for success is 'success'")
    func descriptionSuccess() {
        #expect(RepairStatus.success.description == "success")
    }

    @Test("Description for partialSuccess is 'partialSuccess'")
    func descriptionPartialSuccess() {
        #expect(RepairStatus.partialSuccess.description == "partialSuccess")
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendableConformance() async {
        let status = RepairStatus.success
        let result = await Task { status }.value
        #expect(result == .success)
    }

    @Test("All cases are Sendable across task boundaries")
    func allCasesSendable() async {
        for status in RepairStatus.allCases {
            let result = await Task { status }.value
            #expect(result == status)
        }
    }
}
