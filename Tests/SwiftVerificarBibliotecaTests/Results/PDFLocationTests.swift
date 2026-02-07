import Testing
import Foundation
@testable import SwiftVerificarBiblioteca

// MARK: - PDFLocation Tests

@Suite("PDFLocation Tests")
struct PDFLocationTests {

    // MARK: - Initialization

    @Test("Default initializer creates empty location")
    func defaultInit() {
        let location = PDFLocation()
        #expect(location.objectKey == nil)
        #expect(location.pageNumber == nil)
        #expect(location.structureID == nil)
        #expect(location.contentPath == nil)
    }

    @Test("Full initializer sets all fields")
    func fullInit() {
        let location = PDFLocation(
            objectKey: "42 0 obj",
            pageNumber: 3,
            structureID: "SE-17",
            contentPath: "/Document/Part/P[3]"
        )
        #expect(location.objectKey == "42 0 obj")
        #expect(location.pageNumber == 3)
        #expect(location.structureID == "SE-17")
        #expect(location.contentPath == "/Document/Part/P[3]")
    }

    @Test("Partial initializer with only objectKey")
    func partialInitObjectKey() {
        let location = PDFLocation(objectKey: "7 0 obj")
        #expect(location.objectKey == "7 0 obj")
        #expect(location.pageNumber == nil)
        #expect(location.structureID == nil)
        #expect(location.contentPath == nil)
    }

    @Test("Partial initializer with only pageNumber")
    func partialInitPageNumber() {
        let location = PDFLocation(pageNumber: 5)
        #expect(location.objectKey == nil)
        #expect(location.pageNumber == 5)
        #expect(location.structureID == nil)
        #expect(location.contentPath == nil)
    }

    @Test("Partial initializer with only structureID")
    func partialInitStructureID() {
        let location = PDFLocation(structureID: "SE-42")
        #expect(location.objectKey == nil)
        #expect(location.pageNumber == nil)
        #expect(location.structureID == "SE-42")
        #expect(location.contentPath == nil)
    }

    @Test("Partial initializer with only contentPath")
    func partialInitContentPath() {
        let location = PDFLocation(contentPath: "/Document/Section/Figure")
        #expect(location.objectKey == nil)
        #expect(location.pageNumber == nil)
        #expect(location.structureID == nil)
        #expect(location.contentPath == "/Document/Section/Figure")
    }

    // MARK: - isEmpty

    @Test("isEmpty returns true for default location")
    func isEmptyDefault() {
        let location = PDFLocation()
        #expect(location.isEmpty == true)
    }

    @Test("isEmpty returns false when any field is set")
    func isEmptyWithObjectKey() {
        #expect(PDFLocation(objectKey: "1 0 obj").isEmpty == false)
        #expect(PDFLocation(pageNumber: 1).isEmpty == false)
        #expect(PDFLocation(structureID: "SE-1").isEmpty == false)
        #expect(PDFLocation(contentPath: "/Doc").isEmpty == false)
    }

    @Test("isEmpty returns false when all fields are set")
    func isEmptyAllSet() {
        let location = PDFLocation(
            objectKey: "1 0 obj",
            pageNumber: 1,
            structureID: "SE-1",
            contentPath: "/Doc"
        )
        #expect(location.isEmpty == false)
    }

    // MARK: - Equatable

    @Test("Equal locations are equal")
    func equalLocations() {
        let a = PDFLocation(objectKey: "1 0 obj", pageNumber: 2)
        let b = PDFLocation(objectKey: "1 0 obj", pageNumber: 2)
        #expect(a == b)
    }

    @Test("Different locations are not equal")
    func differentLocations() {
        let a = PDFLocation(objectKey: "1 0 obj", pageNumber: 2)
        let b = PDFLocation(objectKey: "1 0 obj", pageNumber: 3)
        #expect(a != b)
    }

    @Test("Empty locations are equal")
    func emptyLocationsEqual() {
        let a = PDFLocation()
        let b = PDFLocation()
        #expect(a == b)
    }

    // MARK: - Hashable

    @Test("Hashable conformance allows use in Set")
    func hashableConformance() {
        let a = PDFLocation(objectKey: "1 0 obj", pageNumber: 2)
        let b = PDFLocation(objectKey: "1 0 obj", pageNumber: 2)
        let c = PDFLocation(objectKey: "2 0 obj", pageNumber: 3)
        let set: Set<PDFLocation> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("Codable round-trips for full location")
    func codableRoundTripFull() throws {
        let original = PDFLocation(
            objectKey: "42 0 obj",
            pageNumber: 7,
            structureID: "SE-99",
            contentPath: "/Document/H1[2]"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFLocation.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for empty location")
    func codableRoundTripEmpty() throws {
        let original = PDFLocation()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFLocation.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips for partial location")
    func codableRoundTripPartial() throws {
        let original = PDFLocation(pageNumber: 5, structureID: "SE-10")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFLocation.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description for empty location")
    func descriptionEmpty() {
        let location = PDFLocation()
        #expect(location.description == "PDFLocation(empty)")
    }

    @Test("Description for full location includes all parts")
    func descriptionFull() {
        let location = PDFLocation(
            objectKey: "42 0 obj",
            pageNumber: 3,
            structureID: "SE-17",
            contentPath: "/Document/Part"
        )
        let desc = location.description
        #expect(desc.contains("obj=42 0 obj"))
        #expect(desc.contains("page=3"))
        #expect(desc.contains("se=SE-17"))
        #expect(desc.contains("path=/Document/Part"))
    }

    @Test("Description for partial location includes only set parts")
    func descriptionPartial() {
        let location = PDFLocation(pageNumber: 5)
        let desc = location.description
        #expect(desc.contains("page=5"))
        #expect(!desc.contains("obj="))
        #expect(!desc.contains("se="))
        #expect(!desc.contains("path="))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendableConformance() async {
        let location = PDFLocation(objectKey: "1 0 obj", pageNumber: 1)
        let result = await Task { location }.value
        #expect(result == location)
    }
}
