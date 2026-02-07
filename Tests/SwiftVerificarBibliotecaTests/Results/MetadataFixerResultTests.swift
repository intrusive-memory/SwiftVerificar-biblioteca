import Testing
import Foundation
@testable import SwiftVerificarBiblioteca

// MARK: - MetadataFixerResult Tests

@Suite("MetadataFixerResult Tests")
struct MetadataFixerResultTests {

    // MARK: - Helpers

    private static let testOutputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

    private static func makeFix(
        field: String = "dc:title",
        originalValue: String? = nil,
        newValue: String? = "New Value",
        fixDescription: String = "Fixed field"
    ) -> MetadataFix {
        MetadataFix(
            field: field,
            originalValue: originalValue,
            newValue: newValue,
            fixDescription: fixDescription
        )
    }

    // MARK: - Initialization

    @Test("Full initializer sets all fields")
    func fullInit() {
        let fix = Self.makeFix()
        let result = MetadataFixerResult(
            status: .success,
            fixes: [fix],
            outputURL: Self.testOutputURL
        )
        #expect(result.status == .success)
        #expect(result.fixes.count == 1)
        #expect(result.outputURL == Self.testOutputURL)
    }

    @Test("Default initializer has empty fixes and nil outputURL")
    func defaultInit() {
        let result = MetadataFixerResult(status: .failed)
        #expect(result.status == .failed)
        #expect(result.fixes.isEmpty)
        #expect(result.outputURL == nil)
    }

    @Test("Initializer with multiple fixes")
    func initWithMultipleFixes() {
        let fixes = [
            Self.makeFix(field: "dc:title", newValue: "Title"),
            Self.makeFix(field: "dc:creator", newValue: "Author"),
            Self.makeFix(field: "pdfaid:part", originalValue: "2", newValue: nil),
        ]
        let result = MetadataFixerResult(
            status: .partialSuccess,
            fixes: fixes,
            outputURL: Self.testOutputURL
        )
        #expect(result.fixes.count == 3)
        #expect(result.status == .partialSuccess)
    }

    // MARK: - Computed Properties: fixCount

    @Test("fixCount returns correct count")
    func fixCountProperty() {
        let fixes = [
            Self.makeFix(field: "a"),
            Self.makeFix(field: "b"),
            Self.makeFix(field: "c"),
        ]
        let result = MetadataFixerResult(status: .success, fixes: fixes)
        #expect(result.fixCount == 3)
    }

    @Test("fixCount is zero when no fixes")
    func fixCountZero() {
        let result = MetadataFixerResult(status: .noFixesNeeded)
        #expect(result.fixCount == 0)
    }

    // MARK: - Computed Properties: hasFixes

    @Test("hasFixes is true when fixes are present")
    func hasFixesTrue() {
        let result = MetadataFixerResult(
            status: .success,
            fixes: [Self.makeFix()]
        )
        #expect(result.hasFixes == true)
    }

    @Test("hasFixes is false when no fixes")
    func hasFixesFalse() {
        let result = MetadataFixerResult(status: .failed)
        #expect(result.hasFixes == false)
    }

    // MARK: - Computed Properties: hasOutput

    @Test("hasOutput is true when outputURL is non-nil")
    func hasOutputTrue() {
        let result = MetadataFixerResult(
            status: .success,
            outputURL: Self.testOutputURL
        )
        #expect(result.hasOutput == true)
    }

    @Test("hasOutput is false when outputURL is nil")
    func hasOutputFalse() {
        let result = MetadataFixerResult(status: .failed)
        #expect(result.hasOutput == false)
    }

    // MARK: - Computed Properties: modifiedFields

    @Test("modifiedFields returns unique field names")
    func modifiedFieldsUnique() {
        let fixes = [
            Self.makeFix(field: "dc:title"),
            Self.makeFix(field: "dc:title"),
            Self.makeFix(field: "dc:creator"),
        ]
        let result = MetadataFixerResult(status: .success, fixes: fixes)
        #expect(result.modifiedFields.count == 2)
        #expect(result.modifiedFields.contains("dc:title"))
        #expect(result.modifiedFields.contains("dc:creator"))
    }

    @Test("modifiedFields is empty when no fixes")
    func modifiedFieldsEmpty() {
        let result = MetadataFixerResult(status: .noFixesNeeded)
        #expect(result.modifiedFields.isEmpty)
    }

    // MARK: - Computed Properties: additions, removals, modifications

    @Test("additions filters only addition fixes")
    func additionsFilter() {
        let fixes = [
            MetadataFix(field: "dc:title", newValue: "Title", fixDescription: "Added"),
            MetadataFix(field: "dc:creator", originalValue: "Old", fixDescription: "Removed"),
            MetadataFix(field: "dc:date", originalValue: "Old", newValue: "New", fixDescription: "Modified"),
        ]
        let result = MetadataFixerResult(status: .success, fixes: fixes)
        #expect(result.additions.count == 1)
        #expect(result.additions.first?.field == "dc:title")
    }

    @Test("removals filters only removal fixes")
    func removalsFilter() {
        let fixes = [
            MetadataFix(field: "dc:title", newValue: "Title", fixDescription: "Added"),
            MetadataFix(field: "dc:creator", originalValue: "Old", fixDescription: "Removed"),
            MetadataFix(field: "dc:date", originalValue: "Old", newValue: "New", fixDescription: "Modified"),
        ]
        let result = MetadataFixerResult(status: .success, fixes: fixes)
        #expect(result.removals.count == 1)
        #expect(result.removals.first?.field == "dc:creator")
    }

    @Test("modifications filters only modification fixes")
    func modificationsFilter() {
        let fixes = [
            MetadataFix(field: "dc:title", newValue: "Title", fixDescription: "Added"),
            MetadataFix(field: "dc:creator", originalValue: "Old", fixDescription: "Removed"),
            MetadataFix(field: "dc:date", originalValue: "Old", newValue: "New", fixDescription: "Modified"),
        ]
        let result = MetadataFixerResult(status: .success, fixes: fixes)
        #expect(result.modifications.count == 1)
        #expect(result.modifications.first?.field == "dc:date")
    }

    @Test("All filter categories are correct for mixed fixes")
    func allFilterCategories() {
        let fixes = [
            MetadataFix(field: "a", newValue: "v", fixDescription: "add1"),
            MetadataFix(field: "b", newValue: "v", fixDescription: "add2"),
            MetadataFix(field: "c", originalValue: "v", fixDescription: "rem1"),
            MetadataFix(field: "d", originalValue: "o", newValue: "n", fixDescription: "mod1"),
            MetadataFix(field: "e", originalValue: "o", newValue: "n", fixDescription: "mod2"),
            MetadataFix(field: "f", originalValue: "o", newValue: "n", fixDescription: "mod3"),
        ]
        let result = MetadataFixerResult(status: .success, fixes: fixes)
        #expect(result.additions.count == 2)
        #expect(result.removals.count == 1)
        #expect(result.modifications.count == 3)
    }

    @Test("Filters return empty arrays when no fixes match")
    func filtersReturnEmpty() {
        let result = MetadataFixerResult(status: .noFixesNeeded)
        #expect(result.additions.isEmpty)
        #expect(result.removals.isEmpty)
        #expect(result.modifications.isEmpty)
    }

    // MARK: - Factory Methods

    @Test("noFixesNeeded() factory creates correct result")
    func noFixesNeededFactory() {
        let result = MetadataFixerResult.noFixesNeeded()
        #expect(result.status == .noFixesNeeded)
        #expect(result.fixes.isEmpty)
        #expect(result.outputURL == nil)
        #expect(result.fixCount == 0)
        #expect(result.hasFixes == false)
        #expect(result.hasOutput == false)
    }

    @Test("failed() factory creates correct result")
    func failedFactory() {
        let result = MetadataFixerResult.failed()
        #expect(result.status == .failed)
        #expect(result.fixes.isEmpty)
        #expect(result.outputURL == nil)
        #expect(result.fixCount == 0)
        #expect(result.hasFixes == false)
        #expect(result.hasOutput == false)
    }

    // MARK: - Equatable

    @Test("Equal results are equal")
    func equalResults() {
        let fix = Self.makeFix()
        let a = MetadataFixerResult(
            status: .success,
            fixes: [fix],
            outputURL: Self.testOutputURL
        )
        let b = MetadataFixerResult(
            status: .success,
            fixes: [fix],
            outputURL: Self.testOutputURL
        )
        #expect(a == b)
    }

    @Test("Results with different status are not equal")
    func differentStatus() {
        let a = MetadataFixerResult(status: .success)
        let b = MetadataFixerResult(status: .failed)
        #expect(a != b)
    }

    @Test("Results with different fixes are not equal")
    func differentFixes() {
        let fixA = Self.makeFix(field: "a")
        let fixB = Self.makeFix(field: "b")
        let a = MetadataFixerResult(status: .success, fixes: [fixA])
        let b = MetadataFixerResult(status: .success, fixes: [fixB])
        #expect(a != b)
    }

    @Test("Results with different outputURLs are not equal")
    func differentOutputURLs() {
        let a = MetadataFixerResult(
            status: .success,
            outputURL: URL(fileURLWithPath: "/tmp/a.pdf")
        )
        let b = MetadataFixerResult(
            status: .success,
            outputURL: URL(fileURLWithPath: "/tmp/b.pdf")
        )
        #expect(a != b)
    }

    @Test("Results with nil vs non-nil outputURL are not equal")
    func nilVsNonNilOutput() {
        let a = MetadataFixerResult(status: .success)
        let b = MetadataFixerResult(
            status: .success,
            outputURL: Self.testOutputURL
        )
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Hashable conformance allows use in Set")
    func hashableConformance() {
        let a = MetadataFixerResult(status: .success)
        let b = MetadataFixerResult(status: .failed)
        let set: Set<MetadataFixerResult> = [a, b, a]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("Codable round-trips for result with fixes and outputURL")
    func codableRoundTripFull() throws {
        let fixes = [
            MetadataFix(field: "dc:title", newValue: "Title", fixDescription: "Added title"),
            MetadataFix(field: "dc:creator", originalValue: "Old", newValue: "New", fixDescription: "Changed creator"),
        ]
        let original = MetadataFixerResult(
            status: .success,
            fixes: fixes,
            outputURL: Self.testOutputURL
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(MetadataFixerResult.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for empty result")
    func codableRoundTripEmpty() throws {
        let original = MetadataFixerResult.noFixesNeeded()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MetadataFixerResult.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for failed result")
    func codableRoundTripFailed() throws {
        let original = MetadataFixerResult.failed()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MetadataFixerResult.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for result with all RepairStatus values")
    func codableRoundTripAllStatuses() throws {
        for status in RepairStatus.allCases {
            let original = MetadataFixerResult(status: status)
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(MetadataFixerResult.self, from: data)
            #expect(decoded == original)
        }
    }

    @Test("Codable preserves fix ordering")
    func codablePreservesOrdering() throws {
        let fixes = (0..<5).map { i in
            MetadataFix(
                field: "field_\(i)",
                newValue: "value_\(i)",
                fixDescription: "Fix \(i)"
            )
        }
        let original = MetadataFixerResult(status: .success, fixes: fixes)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MetadataFixerResult.self, from: data)
        for (i, fix) in decoded.fixes.enumerated() {
            #expect(fix.field == "field_\(i)")
        }
    }

    // MARK: - CustomStringConvertible

    @Test("Description for result with fixes includes fix count")
    func descriptionWithFixes() {
        let result = MetadataFixerResult(
            status: .success,
            fixes: [Self.makeFix(), Self.makeFix()],
            outputURL: Self.testOutputURL
        )
        #expect(result.description.contains("2 fixes"))
        #expect(result.description.contains("success"))
    }

    @Test("Description for result with no fixes includes 0 fixes")
    func descriptionWithoutFixes() {
        let result = MetadataFixerResult.noFixesNeeded()
        #expect(result.description.contains("0 fixes"))
        #expect(result.description.contains("noFixesNeeded"))
    }

    @Test("Description for result with outputURL includes filename")
    func descriptionWithOutput() {
        let result = MetadataFixerResult(
            status: .success,
            outputURL: URL(fileURLWithPath: "/tmp/my_fixed.pdf")
        )
        #expect(result.description.contains("my_fixed.pdf"))
    }

    @Test("Description for result without outputURL has no arrow")
    func descriptionWithoutOutput() {
        let result = MetadataFixerResult(status: .failed)
        #expect(!result.description.contains("->"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendableConformance() async {
        let result = MetadataFixerResult(
            status: .success,
            fixes: [Self.makeFix()],
            outputURL: Self.testOutputURL
        )
        let returned = await Task { result }.value
        #expect(returned == result)
    }

    // MARK: - Edge Cases

    @Test("Result with empty fixes array and outputURL")
    func emptyFixesWithOutput() {
        let result = MetadataFixerResult(
            status: .success,
            fixes: [],
            outputURL: Self.testOutputURL
        )
        #expect(result.hasFixes == false)
        #expect(result.hasOutput == true)
        #expect(result.fixCount == 0)
    }

    @Test("Result with many fixes")
    func manyFixes() {
        let fixes = (0..<100).map { i in
            MetadataFix(
                field: "field_\(i)",
                newValue: "value_\(i)",
                fixDescription: "Fix \(i)"
            )
        }
        let result = MetadataFixerResult(status: .success, fixes: fixes)
        #expect(result.fixCount == 100)
        #expect(result.modifiedFields.count == 100)
        #expect(result.additions.count == 100)
        #expect(result.removals.isEmpty)
        #expect(result.modifications.isEmpty)
    }

    @Test("Result with duplicate field fixes")
    func duplicateFieldFixes() {
        let fixes = [
            MetadataFix(field: "dc:title", newValue: "First", fixDescription: "First pass"),
            MetadataFix(field: "dc:title", originalValue: "First", newValue: "Second", fixDescription: "Second pass"),
        ]
        let result = MetadataFixerResult(status: .success, fixes: fixes)
        #expect(result.fixCount == 2)
        #expect(result.modifiedFields.count == 1)
        #expect(result.additions.count == 1)
        #expect(result.modifications.count == 1)
    }
}
