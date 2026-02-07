import Testing
import Foundation
@testable import SwiftVerificarBiblioteca

// MARK: - MetadataFix Tests

@Suite("MetadataFix Tests")
struct MetadataFixTests {

    // MARK: - Initialization

    @Test("Full initializer sets all fields")
    func fullInit() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "Old Title",
            newValue: "New Title",
            fixDescription: "Updated title"
        )
        #expect(fix.field == "dc:title")
        #expect(fix.originalValue == "Old Title")
        #expect(fix.newValue == "New Title")
        #expect(fix.fixDescription == "Updated title")
    }

    @Test("Minimal initializer uses defaults for optional parameters")
    func minimalInit() {
        let fix = MetadataFix(
            field: "pdfaid:part",
            fixDescription: "Cleared field"
        )
        #expect(fix.field == "pdfaid:part")
        #expect(fix.originalValue == nil)
        #expect(fix.newValue == nil)
        #expect(fix.fixDescription == "Cleared field")
    }

    @Test("Initializer with only originalValue")
    func initWithOriginalOnly() {
        let fix = MetadataFix(
            field: "dc:creator",
            originalValue: "OldAuthor",
            fixDescription: "Removed creator"
        )
        #expect(fix.originalValue == "OldAuthor")
        #expect(fix.newValue == nil)
    }

    @Test("Initializer with only newValue")
    func initWithNewOnly() {
        let fix = MetadataFix(
            field: "dc:creator",
            newValue: "NewAuthor",
            fixDescription: "Added creator"
        )
        #expect(fix.originalValue == nil)
        #expect(fix.newValue == "NewAuthor")
    }

    // MARK: - Convenience: isAddition

    @Test("isAddition is true when originalValue is nil and newValue is non-nil")
    func isAdditionTrue() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: nil,
            newValue: "New Title",
            fixDescription: "Added title"
        )
        #expect(fix.isAddition == true)
    }

    @Test("isAddition is false when both values are present")
    func isAdditionFalseWhenModification() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "Old",
            newValue: "New",
            fixDescription: "Modified title"
        )
        #expect(fix.isAddition == false)
    }

    @Test("isAddition is false when both values are nil")
    func isAdditionFalseWhenBothNil() {
        let fix = MetadataFix(
            field: "dc:title",
            fixDescription: "No change"
        )
        #expect(fix.isAddition == false)
    }

    @Test("isAddition is false when only originalValue is present")
    func isAdditionFalseWhenRemoval() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "Old",
            fixDescription: "Removed title"
        )
        #expect(fix.isAddition == false)
    }

    // MARK: - Convenience: isRemoval

    @Test("isRemoval is true when originalValue is non-nil and newValue is nil")
    func isRemovalTrue() {
        let fix = MetadataFix(
            field: "pdfaid:part",
            originalValue: "2",
            fixDescription: "Removed PDF/A ID"
        )
        #expect(fix.isRemoval == true)
    }

    @Test("isRemoval is false when both values are present")
    func isRemovalFalseWhenModification() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "Old",
            newValue: "New",
            fixDescription: "Modified"
        )
        #expect(fix.isRemoval == false)
    }

    @Test("isRemoval is false when both values are nil")
    func isRemovalFalseWhenBothNil() {
        let fix = MetadataFix(
            field: "dc:title",
            fixDescription: "No change"
        )
        #expect(fix.isRemoval == false)
    }

    @Test("isRemoval is false when only newValue is present")
    func isRemovalFalseWhenAddition() {
        let fix = MetadataFix(
            field: "dc:title",
            newValue: "New",
            fixDescription: "Added"
        )
        #expect(fix.isRemoval == false)
    }

    // MARK: - Convenience: isModification

    @Test("isModification is true when both values are non-nil")
    func isModificationTrue() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "Old Title",
            newValue: "New Title",
            fixDescription: "Updated title"
        )
        #expect(fix.isModification == true)
    }

    @Test("isModification is false when originalValue is nil")
    func isModificationFalseWhenAddition() {
        let fix = MetadataFix(
            field: "dc:title",
            newValue: "New",
            fixDescription: "Added"
        )
        #expect(fix.isModification == false)
    }

    @Test("isModification is false when newValue is nil")
    func isModificationFalseWhenRemoval() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "Old",
            fixDescription: "Removed"
        )
        #expect(fix.isModification == false)
    }

    @Test("isModification is false when both values are nil")
    func isModificationFalseWhenBothNil() {
        let fix = MetadataFix(
            field: "dc:title",
            fixDescription: "No change"
        )
        #expect(fix.isModification == false)
    }

    // MARK: - Mutual Exclusivity

    @Test("Exactly one of isAddition, isRemoval, isModification is true for addition")
    func mutualExclusivityAddition() {
        let fix = MetadataFix(
            field: "dc:title",
            newValue: "New",
            fixDescription: "Added"
        )
        let flags = [fix.isAddition, fix.isRemoval, fix.isModification]
        #expect(flags.filter { $0 }.count == 1)
        #expect(fix.isAddition == true)
    }

    @Test("Exactly one of isAddition, isRemoval, isModification is true for removal")
    func mutualExclusivityRemoval() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "Old",
            fixDescription: "Removed"
        )
        let flags = [fix.isAddition, fix.isRemoval, fix.isModification]
        #expect(flags.filter { $0 }.count == 1)
        #expect(fix.isRemoval == true)
    }

    @Test("Exactly one of isAddition, isRemoval, isModification is true for modification")
    func mutualExclusivityModification() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "Old",
            newValue: "New",
            fixDescription: "Updated"
        )
        let flags = [fix.isAddition, fix.isRemoval, fix.isModification]
        #expect(flags.filter { $0 }.count == 1)
        #expect(fix.isModification == true)
    }

    @Test("None of isAddition, isRemoval, isModification is true when both nil")
    func mutualExclusivityNone() {
        let fix = MetadataFix(
            field: "dc:title",
            fixDescription: "No-op"
        )
        #expect(fix.isAddition == false)
        #expect(fix.isRemoval == false)
        #expect(fix.isModification == false)
    }

    // MARK: - Equatable

    @Test("Equal fixes are equal")
    func equalFixes() {
        let a = MetadataFix(
            field: "dc:title",
            originalValue: "Old",
            newValue: "New",
            fixDescription: "Updated"
        )
        let b = MetadataFix(
            field: "dc:title",
            originalValue: "Old",
            newValue: "New",
            fixDescription: "Updated"
        )
        #expect(a == b)
    }

    @Test("Fixes with different fields are not equal")
    func differentFields() {
        let a = MetadataFix(field: "dc:title", fixDescription: "A")
        let b = MetadataFix(field: "dc:creator", fixDescription: "A")
        #expect(a != b)
    }

    @Test("Fixes with different originalValues are not equal")
    func differentOriginalValues() {
        let a = MetadataFix(field: "dc:title", originalValue: "X", fixDescription: "A")
        let b = MetadataFix(field: "dc:title", originalValue: "Y", fixDescription: "A")
        #expect(a != b)
    }

    @Test("Fixes with different newValues are not equal")
    func differentNewValues() {
        let a = MetadataFix(field: "dc:title", newValue: "X", fixDescription: "A")
        let b = MetadataFix(field: "dc:title", newValue: "Y", fixDescription: "A")
        #expect(a != b)
    }

    @Test("Fixes with different fixDescriptions are not equal")
    func differentDescriptions() {
        let a = MetadataFix(field: "dc:title", fixDescription: "A")
        let b = MetadataFix(field: "dc:title", fixDescription: "B")
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Hashable conformance allows use in Set")
    func hashableConformance() {
        let a = MetadataFix(field: "dc:title", newValue: "T", fixDescription: "Add title")
        let b = MetadataFix(field: "dc:creator", newValue: "C", fixDescription: "Add creator")
        let set: Set<MetadataFix> = [a, b, a]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("Codable round-trips for addition fix")
    func codableRoundTripAddition() throws {
        let original = MetadataFix(
            field: "dc:title",
            newValue: "New Title",
            fixDescription: "Added title"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MetadataFix.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for removal fix")
    func codableRoundTripRemoval() throws {
        let original = MetadataFix(
            field: "pdfaid:part",
            originalValue: "2",
            fixDescription: "Removed PDF/A ID"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MetadataFix.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for modification fix")
    func codableRoundTripModification() throws {
        let original = MetadataFix(
            field: "dc:title",
            originalValue: "Old",
            newValue: "New",
            fixDescription: "Updated title"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MetadataFix.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for fix with both values nil")
    func codableRoundTripBothNil() throws {
        let original = MetadataFix(
            field: "dc:title",
            fixDescription: "No-op"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MetadataFix.self, from: data)
        #expect(decoded == original)
    }

    @Test("JSON contains expected keys")
    func jsonContainsExpectedKeys() throws {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "Old",
            newValue: "New",
            fixDescription: "Changed"
        )
        let data = try JSONEncoder().encode(fix)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["field"] as? String == "dc:title")
        #expect(json?["originalValue"] as? String == "Old")
        #expect(json?["newValue"] as? String == "New")
        #expect(json?["fixDescription"] as? String == "Changed")
    }

    // MARK: - CustomStringConvertible

    @Test("Description for addition fix contains 'add'")
    func descriptionForAddition() {
        let fix = MetadataFix(
            field: "dc:title",
            newValue: "Title",
            fixDescription: "Added"
        )
        #expect(fix.description.contains("add"))
        #expect(fix.description.contains("dc:title"))
    }

    @Test("Description for removal fix contains 'remove'")
    func descriptionForRemoval() {
        let fix = MetadataFix(
            field: "pdfaid:part",
            originalValue: "2",
            fixDescription: "Removed"
        )
        #expect(fix.description.contains("remove"))
        #expect(fix.description.contains("pdfaid:part"))
    }

    @Test("Description for modification fix contains '->'")
    func descriptionForModification() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "Old",
            newValue: "New",
            fixDescription: "Modified"
        )
        #expect(fix.description.contains("modify"))
        #expect(fix.description.contains("->"))
    }

    @Test("Description for no-change fix contains 'no value change'")
    func descriptionForNoChange() {
        let fix = MetadataFix(
            field: "dc:title",
            fixDescription: "Nothing"
        )
        #expect(fix.description.contains("no value change"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendableConformance() async {
        let fix = MetadataFix(
            field: "dc:title",
            newValue: "Title",
            fixDescription: "Added"
        )
        let result = await Task { fix }.value
        #expect(result == fix)
    }

    // MARK: - Edge Cases

    @Test("Empty field name is allowed")
    func emptyFieldName() {
        let fix = MetadataFix(field: "", fixDescription: "Empty field")
        #expect(fix.field == "")
    }

    @Test("Empty string values are treated as non-nil")
    func emptyStringValues() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "",
            newValue: "",
            fixDescription: "Both empty strings"
        )
        #expect(fix.isModification == true)
        #expect(fix.isAddition == false)
        #expect(fix.isRemoval == false)
    }

    @Test("Same original and new value is treated as modification")
    func sameOriginalAndNewValue() {
        let fix = MetadataFix(
            field: "dc:title",
            originalValue: "Same",
            newValue: "Same",
            fixDescription: "No actual change"
        )
        #expect(fix.isModification == true)
    }
}
