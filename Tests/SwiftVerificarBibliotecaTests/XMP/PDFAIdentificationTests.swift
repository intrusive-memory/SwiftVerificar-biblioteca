import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("PDFAIdentification Tests")
struct PDFAIdentificationTests {

    // MARK: - Initialization

    @Test("Default init with part and conformance")
    func defaultInit() {
        let id = PDFAIdentification(part: 2, conformance: "u")
        #expect(id.part == 2)
        #expect(id.conformance == "u")
        #expect(id.amendment == nil)
        #expect(id.revision == nil)
    }

    @Test("Full init with all fields")
    func fullInit() {
        let id = PDFAIdentification(part: 1, conformance: "b", amendment: "1", revision: "2009")
        #expect(id.part == 1)
        #expect(id.conformance == "b")
        #expect(id.amendment == "1")
        #expect(id.revision == "2009")
    }

    @Test("Init with only amendment")
    func amendmentOnly() {
        let id = PDFAIdentification(part: 3, conformance: "a", amendment: "1")
        #expect(id.amendment == "1")
        #expect(id.revision == nil)
    }

    @Test("Init with only revision")
    func revisionOnly() {
        let id = PDFAIdentification(part: 4, conformance: "e", revision: "2020")
        #expect(id.amendment == nil)
        #expect(id.revision == "2020")
    }

    // MARK: - Display Name

    @Test("Display name for PDF/A-1b")
    func displayNamePDFA1b() {
        let id = PDFAIdentification(part: 1, conformance: "b")
        #expect(id.displayName == "PDF/A-1b")
    }

    @Test("Display name for PDF/A-2u")
    func displayNamePDFA2u() {
        let id = PDFAIdentification(part: 2, conformance: "u")
        #expect(id.displayName == "PDF/A-2u")
    }

    @Test("Display name for PDF/A-3a")
    func displayNamePDFA3a() {
        let id = PDFAIdentification(part: 3, conformance: "a")
        #expect(id.displayName == "PDF/A-3a")
    }

    @Test("Display name for PDF/A-4f")
    func displayNamePDFA4f() {
        let id = PDFAIdentification(part: 4, conformance: "f")
        #expect(id.displayName == "PDF/A-4f")
    }

    @Test("Display name with amendment")
    func displayNameWithAmendment() {
        let id = PDFAIdentification(part: 1, conformance: "b", amendment: "1")
        #expect(id.displayName == "PDF/A-1b (Amendment 1)")
    }

    @Test("Display name without amendment does not show parenthetical")
    func displayNameWithoutAmendment() {
        let id = PDFAIdentification(part: 2, conformance: "u")
        #expect(!id.displayName.contains("Amendment"))
    }

    // MARK: - Validity

    @Test("Part 1 is valid")
    func part1Valid() {
        let id = PDFAIdentification(part: 1, conformance: "a")
        #expect(id.isValidPart)
    }

    @Test("Part 2 is valid")
    func part2Valid() {
        let id = PDFAIdentification(part: 2, conformance: "b")
        #expect(id.isValidPart)
    }

    @Test("Part 3 is valid")
    func part3Valid() {
        let id = PDFAIdentification(part: 3, conformance: "u")
        #expect(id.isValidPart)
    }

    @Test("Part 4 is valid")
    func part4Valid() {
        let id = PDFAIdentification(part: 4, conformance: "e")
        #expect(id.isValidPart)
    }

    @Test("Part 0 is invalid")
    func part0Invalid() {
        let id = PDFAIdentification(part: 0, conformance: "a")
        #expect(!id.isValidPart)
    }

    @Test("Part 5 is invalid")
    func part5Invalid() {
        let id = PDFAIdentification(part: 5, conformance: "a")
        #expect(!id.isValidPart)
    }

    @Test("Negative part is invalid")
    func negativePartInvalid() {
        let id = PDFAIdentification(part: -1, conformance: "a")
        #expect(!id.isValidPart)
    }

    @Test("Conformance 'a' is valid")
    func conformanceAValid() {
        let id = PDFAIdentification(part: 1, conformance: "a")
        #expect(id.isValidConformance)
    }

    @Test("Conformance 'b' is valid")
    func conformanceBValid() {
        let id = PDFAIdentification(part: 1, conformance: "b")
        #expect(id.isValidConformance)
    }

    @Test("Conformance 'u' is valid")
    func conformanceUValid() {
        let id = PDFAIdentification(part: 2, conformance: "u")
        #expect(id.isValidConformance)
    }

    @Test("Conformance 'e' is valid")
    func conformanceEValid() {
        let id = PDFAIdentification(part: 4, conformance: "e")
        #expect(id.isValidConformance)
    }

    @Test("Conformance 'f' is valid")
    func conformanceFValid() {
        let id = PDFAIdentification(part: 4, conformance: "f")
        #expect(id.isValidConformance)
    }

    @Test("Uppercase conformance 'A' is valid (case insensitive)")
    func uppercaseConformanceValid() {
        let id = PDFAIdentification(part: 1, conformance: "A")
        #expect(id.isValidConformance)
    }

    @Test("Invalid conformance 'x' is not valid")
    func invalidConformance() {
        let id = PDFAIdentification(part: 1, conformance: "x")
        #expect(!id.isValidConformance)
    }

    @Test("Empty conformance is not valid")
    func emptyConformance() {
        let id = PDFAIdentification(part: 1, conformance: "")
        #expect(!id.isValidConformance)
    }

    @Test("isValid combines part and conformance checks")
    func isValidCombined() {
        let valid = PDFAIdentification(part: 2, conformance: "u")
        #expect(valid.isValid)

        let invalidPart = PDFAIdentification(part: 5, conformance: "a")
        #expect(!invalidPart.isValid)

        let invalidConf = PDFAIdentification(part: 2, conformance: "x")
        #expect(!invalidConf.isValid)

        let bothInvalid = PDFAIdentification(part: 0, conformance: "z")
        #expect(!bothInvalid.isValid)
    }

    // MARK: - Valid Conformance Levels

    @Test("validConformanceLevels contains all expected levels")
    func validConformanceLevelsSet() {
        let expected: Set<String> = ["a", "b", "u", "e", "f"]
        #expect(PDFAIdentification.validConformanceLevels == expected)
    }

    // MARK: - Equatable

    @Test("Equal instances are equal")
    func equatable() {
        let a = PDFAIdentification(part: 2, conformance: "u")
        let b = PDFAIdentification(part: 2, conformance: "u")
        #expect(a == b)
    }

    @Test("Different parts are not equal")
    func differentParts() {
        let a = PDFAIdentification(part: 1, conformance: "a")
        let b = PDFAIdentification(part: 2, conformance: "a")
        #expect(a != b)
    }

    @Test("Different conformance are not equal")
    func differentConformance() {
        let a = PDFAIdentification(part: 2, conformance: "a")
        let b = PDFAIdentification(part: 2, conformance: "u")
        #expect(a != b)
    }

    @Test("Different amendments are not equal")
    func differentAmendments() {
        let a = PDFAIdentification(part: 1, conformance: "b", amendment: "1")
        let b = PDFAIdentification(part: 1, conformance: "b", amendment: "2")
        #expect(a != b)
    }

    @Test("Nil vs non-nil amendment are not equal")
    func nilVsNonNilAmendment() {
        let a = PDFAIdentification(part: 1, conformance: "b")
        let b = PDFAIdentification(part: 1, conformance: "b", amendment: "1")
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Can be used in a Set")
    func hashable() {
        let a = PDFAIdentification(part: 2, conformance: "u")
        let b = PDFAIdentification(part: 1, conformance: "b")
        let c = PDFAIdentification(part: 2, conformance: "u")

        let set: Set<PDFAIdentification> = [a, b, c]
        #expect(set.count == 2)
    }

    @Test("Can be used as Dictionary key")
    func dictionaryKey() {
        let key = PDFAIdentification(part: 2, conformance: "u")
        var dict: [PDFAIdentification: String] = [:]
        dict[key] = "test"
        #expect(dict[key] == "test")
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = PDFAIdentification(part: 2, conformance: "u", amendment: "1", revision: "2011")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFAIdentification.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip with nil optionals")
    func codableRoundTripNilOptionals() throws {
        let original = PDFAIdentification(part: 1, conformance: "b")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFAIdentification.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes part and conformance")
    func descriptionIncludesFields() {
        let id = PDFAIdentification(part: 2, conformance: "u")
        #expect(id.description.contains("2"))
        #expect(id.description.contains("u"))
    }

    @Test("Description includes amendment when present")
    func descriptionIncludesAmendment() {
        let id = PDFAIdentification(part: 1, conformance: "b", amendment: "1")
        #expect(id.description.contains("amendment"))
    }

    @Test("Description includes revision when present")
    func descriptionIncludesRevision() {
        let id = PDFAIdentification(part: 1, conformance: "b", revision: "2009")
        #expect(id.description.contains("revision"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let id = PDFAIdentification(part: 2, conformance: "u")
        let result = await Task { id }.value
        #expect(result == id)
    }
}
