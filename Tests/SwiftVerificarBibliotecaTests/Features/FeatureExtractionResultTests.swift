import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("FeatureExtractionResult Tests")
struct FeatureExtractionResultTests {

    // MARK: - Helpers

    private static let testURL = URL(fileURLWithPath: "/tmp/test.pdf")

    private static let sampleTree = FeatureNode.branch(
        name: "Document",
        children: [
            .branch(name: "Fonts", children: [
                .leaf(name: "Font", value: "Helvetica"),
                .leaf(name: "Font", value: "Times-Roman"),
            ], attributes: ["count": "2"]),
            .leaf(name: "PageCount", value: "5"),
        ],
        attributes: [:]
    )

    // MARK: - Construction

    @Test("Stores documentURL, features, and errors")
    func fullConstruction() {
        let error = FeatureError(featureType: .fonts, message: "corrupt")
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: [error]
        )

        #expect(result.documentURL == Self.testURL)
        #expect(result.features == Self.sampleTree)
        #expect(result.errors.count == 1)
        #expect(result.errors[0] == error)
    }

    @Test("Default errors is empty array")
    func defaultErrors() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: .leaf(name: "Root", value: nil)
        )

        #expect(result.errors.isEmpty)
    }

    // MARK: - isComplete

    @Test("isComplete is true when no errors")
    func isCompleteNoErrors() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree
        )
        #expect(result.isComplete)
    }

    @Test("isComplete is false when errors exist")
    func isCompleteWithErrors() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: [FeatureError(featureType: .fonts, message: "bad")]
        )
        #expect(!result.isComplete)
    }

    // MARK: - featureCount

    @Test("featureCount returns total node count")
    func featureCount() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree
        )
        // Document(1) + Fonts(1) + Helvetica(1) + Times(1) + PageCount(1) = 5
        #expect(result.featureCount == 5)
    }

    @Test("featureCount for leaf-only result")
    func featureCountLeaf() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: .leaf(name: "Root", value: "val")
        )
        #expect(result.featureCount == 1)
    }

    // MARK: - errorCount

    @Test("errorCount returns number of errors")
    func errorCount() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: [
                FeatureError(featureType: .fonts, message: "A"),
                FeatureError(featureType: .pages, message: "B"),
            ]
        )
        #expect(result.errorCount == 2)
    }

    @Test("errorCount is zero when no errors")
    func errorCountZero() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree
        )
        #expect(result.errorCount == 0)
    }

    // MARK: - failedFeatureTypes

    @Test("failedFeatureTypes returns unique types")
    func failedFeatureTypes() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: [
                FeatureError(featureType: .fonts, message: "A"),
                FeatureError(featureType: .fonts, message: "B"),
                FeatureError(featureType: .pages, message: "C"),
            ]
        )
        #expect(result.failedFeatureTypes == [.fonts, .pages])
    }

    @Test("failedFeatureTypes is empty when no errors")
    func failedFeatureTypesEmpty() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree
        )
        #expect(result.failedFeatureTypes.isEmpty)
    }

    // MARK: - errors(for:)

    @Test("errors(for:) filters by feature type")
    func errorsForType() {
        let fontError1 = FeatureError(featureType: .fonts, message: "A")
        let fontError2 = FeatureError(featureType: .fonts, message: "B")
        let pageError = FeatureError(featureType: .pages, message: "C")

        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: [fontError1, fontError2, pageError]
        )

        let fontErrors = result.errors(for: .fonts)
        #expect(fontErrors.count == 2)
        #expect(fontErrors.contains(fontError1))
        #expect(fontErrors.contains(fontError2))
    }

    @Test("errors(for:) returns empty for type with no errors")
    func errorsForTypeEmpty() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: [FeatureError(featureType: .fonts, message: "A")]
        )

        #expect(result.errors(for: .pages).isEmpty)
    }

    // MARK: - Equatable

    @Test("Same results are equal")
    func equality() {
        let a = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: []
        )
        let b = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: []
        )
        #expect(a == b)
    }

    @Test("Different URLs are not equal")
    func urlInequality() {
        let a = FeatureExtractionResult(
            documentURL: URL(fileURLWithPath: "/a.pdf"),
            features: Self.sampleTree
        )
        let b = FeatureExtractionResult(
            documentURL: URL(fileURLWithPath: "/b.pdf"),
            features: Self.sampleTree
        )
        #expect(a != b)
    }

    @Test("Different features are not equal")
    func featureInequality() {
        let a = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: .leaf(name: "A", value: "1")
        )
        let b = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: .leaf(name: "B", value: "2")
        )
        #expect(a != b)
    }

    @Test("Different errors make results not equal")
    func errorInequality() {
        let a = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: [FeatureError(featureType: .fonts, message: "A")]
        )
        let b = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: []
        )
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("Codable round-trip without errors")
    func codableRoundTripNoErrors() throws {
        let original = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FeatureExtractionResult.self, from: data)

        #expect(decoded == original)
    }

    @Test("Codable round-trip with errors")
    func codableRoundTripWithErrors() throws {
        let original = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: [
                FeatureError(featureType: .fonts, message: "bad", objectIdentifier: "F1"),
                FeatureError(featureType: .pages, message: "missing"),
            ]
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FeatureExtractionResult.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes filename")
    func descriptionIncludesFilename() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree
        )
        #expect(result.description.contains("test.pdf"))
    }

    @Test("Description includes node count")
    func descriptionIncludesNodeCount() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree
        )
        #expect(result.description.contains("5 nodes"))
    }

    @Test("Description shows complete when no errors")
    func descriptionComplete() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree
        )
        #expect(result.description.contains("complete"))
    }

    @Test("Description shows error count when errors exist")
    func descriptionWithErrors() {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree,
            errors: [
                FeatureError(featureType: .fonts, message: "A"),
                FeatureError(featureType: .pages, message: "B"),
            ]
        )
        #expect(result.description.contains("2 errors"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let result = FeatureExtractionResult(
            documentURL: Self.testURL,
            features: Self.sampleTree
        )

        let transferred = await Task {
            result
        }.value

        #expect(transferred == result)
    }
}
