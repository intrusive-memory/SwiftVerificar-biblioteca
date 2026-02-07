import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("PDFUAIdentification Tests")
struct PDFUAIdentificationTests {

    // MARK: - Initialization

    @Test("Default init with part only")
    func defaultInit() {
        let id = PDFUAIdentification(part: 1)
        #expect(id.part == 1)
        #expect(id.revision == nil)
    }

    @Test("Init with part and revision")
    func initWithRevision() {
        let id = PDFUAIdentification(part: 2, revision: "2023")
        #expect(id.part == 2)
        #expect(id.revision == "2023")
    }

    @Test("Part 1 initialization")
    func part1Init() {
        let id = PDFUAIdentification(part: 1)
        #expect(id.part == 1)
    }

    @Test("Part 2 initialization")
    func part2Init() {
        let id = PDFUAIdentification(part: 2)
        #expect(id.part == 2)
    }

    // MARK: - Display Name

    @Test("Display name for PDF/UA-1")
    func displayNamePart1() {
        let id = PDFUAIdentification(part: 1)
        #expect(id.displayName == "PDF/UA-1")
    }

    @Test("Display name for PDF/UA-2")
    func displayNamePart2() {
        let id = PDFUAIdentification(part: 2)
        #expect(id.displayName == "PDF/UA-2")
    }

    @Test("Display name with revision")
    func displayNameWithRevision() {
        let id = PDFUAIdentification(part: 1, revision: "2014")
        #expect(id.displayName == "PDF/UA-1 (Revision 2014)")
    }

    @Test("Display name without revision has no parenthetical")
    func displayNameWithoutRevision() {
        let id = PDFUAIdentification(part: 2)
        #expect(!id.displayName.contains("Revision"))
    }

    // MARK: - Validity

    @Test("Part 1 is valid")
    func part1Valid() {
        let id = PDFUAIdentification(part: 1)
        #expect(id.isValidPart)
    }

    @Test("Part 2 is valid")
    func part2Valid() {
        let id = PDFUAIdentification(part: 2)
        #expect(id.isValidPart)
    }

    @Test("Part 0 is invalid")
    func part0Invalid() {
        let id = PDFUAIdentification(part: 0)
        #expect(!id.isValidPart)
    }

    @Test("Part 3 is invalid")
    func part3Invalid() {
        let id = PDFUAIdentification(part: 3)
        #expect(!id.isValidPart)
    }

    @Test("Negative part is invalid")
    func negativePartInvalid() {
        let id = PDFUAIdentification(part: -1)
        #expect(!id.isValidPart)
    }

    @Test("Large part number is invalid")
    func largePartInvalid() {
        let id = PDFUAIdentification(part: 100)
        #expect(!id.isValidPart)
    }

    // MARK: - Equatable

    @Test("Equal instances are equal")
    func equatable() {
        let a = PDFUAIdentification(part: 1)
        let b = PDFUAIdentification(part: 1)
        #expect(a == b)
    }

    @Test("Different parts are not equal")
    func differentParts() {
        let a = PDFUAIdentification(part: 1)
        let b = PDFUAIdentification(part: 2)
        #expect(a != b)
    }

    @Test("Different revisions are not equal")
    func differentRevisions() {
        let a = PDFUAIdentification(part: 1, revision: "2014")
        let b = PDFUAIdentification(part: 1, revision: "2023")
        #expect(a != b)
    }

    @Test("Nil vs non-nil revision are not equal")
    func nilVsNonNilRevision() {
        let a = PDFUAIdentification(part: 1)
        let b = PDFUAIdentification(part: 1, revision: "2014")
        #expect(a != b)
    }

    @Test("Same part and revision are equal")
    func samePartAndRevision() {
        let a = PDFUAIdentification(part: 2, revision: "2023")
        let b = PDFUAIdentification(part: 2, revision: "2023")
        #expect(a == b)
    }

    // MARK: - Hashable

    @Test("Can be used in a Set")
    func hashable() {
        let a = PDFUAIdentification(part: 1)
        let b = PDFUAIdentification(part: 2)
        let c = PDFUAIdentification(part: 1)

        let set: Set<PDFUAIdentification> = [a, b, c]
        #expect(set.count == 2)
    }

    @Test("Can be used as Dictionary key")
    func dictionaryKey() {
        let key = PDFUAIdentification(part: 2)
        var dict: [PDFUAIdentification: String] = [:]
        dict[key] = "test"
        #expect(dict[key] == "test")
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = PDFUAIdentification(part: 2, revision: "2023")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFUAIdentification.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip with nil revision")
    func codableRoundTripNilRevision() throws {
        let original = PDFUAIdentification(part: 1)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFUAIdentification.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes part")
    func descriptionIncludesPart() {
        let id = PDFUAIdentification(part: 2)
        #expect(id.description.contains("2"))
    }

    @Test("Description includes revision when present")
    func descriptionIncludesRevision() {
        let id = PDFUAIdentification(part: 1, revision: "2014")
        #expect(id.description.contains("revision"))
    }

    @Test("Description does not include revision when nil")
    func descriptionExcludesNilRevision() {
        let id = PDFUAIdentification(part: 1)
        #expect(!id.description.contains("revision"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let id = PDFUAIdentification(part: 2)
        let result = await Task { id }.value
        #expect(result == id)
    }
}
