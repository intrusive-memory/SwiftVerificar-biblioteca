import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("FeatureReport Tests")
struct FeatureReportTests {

    // MARK: - Test Helpers

    private func makeExtractionResult(
        documentPath: String = "/test/document.pdf",
        features: FeatureNode = .branch(name: "Document", children: [], attributes: [:]),
        errors: [FeatureError] = []
    ) -> FeatureExtractionResult {
        FeatureExtractionResult(
            documentURL: URL(fileURLWithPath: documentPath),
            features: features,
            errors: errors
        )
    }

    private func makeFeatureTree(leafCount: Int) -> FeatureNode {
        let leaves = (0..<leafCount).map { i in
            FeatureNode.leaf(name: "Feature\(i)", value: "value\(i)")
        }
        return .branch(name: "Document", children: leaves, attributes: [:])
    }

    // MARK: - Initialization

    @Test("Init stores extraction result and summary")
    func initStoresProperties() {
        let extraction = makeExtractionResult()
        let report = FeatureReport(extractionResult: extraction, summary: "Test summary")

        #expect(report.extractionResult == extraction)
        #expect(report.summary == "Test summary")
    }

    @Test("Init with empty summary")
    func initEmptySummary() {
        let extraction = makeExtractionResult()
        let report = FeatureReport(extractionResult: extraction, summary: "")
        #expect(report.summary == "")
    }

    // MARK: - generate(from:)

    @Test("Generate produces summary with document name")
    func generateContainsDocumentName() {
        let extraction = makeExtractionResult(documentPath: "/path/to/myfile.pdf")
        let report = FeatureReport.generate(from: extraction)
        #expect(report.summary.contains("myfile.pdf"))
    }

    @Test("Generate produces summary with feature count")
    func generateContainsFeatureCount() {
        let tree = makeFeatureTree(leafCount: 5)
        let extraction = makeExtractionResult(features: tree)
        let report = FeatureReport.generate(from: extraction)
        // 5 leaves + 1 branch = 6 nodes
        #expect(report.summary.contains("6 feature nodes"))
    }

    @Test("Generate singular node text for 1 node")
    func generateSingularNode() {
        let tree = FeatureNode.leaf(name: "Single", value: "x")
        let extraction = makeExtractionResult(features: tree)
        let report = FeatureReport.generate(from: extraction)
        #expect(report.summary.contains("1 feature node "))
    }

    @Test("Generate indicates no errors when clean")
    func generateNoErrors() {
        let extraction = makeExtractionResult()
        let report = FeatureReport.generate(from: extraction)
        #expect(report.summary.contains("without errors"))
    }

    @Test("Generate includes error count when errors exist")
    func generateWithErrors() {
        let errors = [
            FeatureError(featureType: .fonts, message: "corrupt font"),
            FeatureError(featureType: .iccProfiles, message: "bad profile"),
        ]
        let extraction = makeExtractionResult(errors: errors)
        let report = FeatureReport.generate(from: extraction)
        #expect(report.summary.contains("2 errors"))
    }

    @Test("Generate singular error text for 1 error")
    func generateSingularError() {
        let errors = [FeatureError(featureType: .fonts, message: "corrupt")]
        let extraction = makeExtractionResult(errors: errors)
        let report = FeatureReport.generate(from: extraction)
        #expect(report.summary.contains("1 error "))
    }

    @Test("Generate includes failed feature types")
    func generateIncludesFailedTypes() {
        let errors = [FeatureError(featureType: .fonts, message: "fail")]
        let extraction = makeExtractionResult(errors: errors)
        let report = FeatureReport.generate(from: extraction)
        #expect(report.summary.contains("fonts"))
    }

    @Test("Generate stores the extraction result")
    func generateStoresResult() {
        let extraction = makeExtractionResult()
        let report = FeatureReport.generate(from: extraction)
        #expect(report.extractionResult == extraction)
    }

    // MARK: - Computed Properties

    @Test("isComplete when no errors")
    func isCompleteNoErrors() {
        let extraction = makeExtractionResult()
        let report = FeatureReport.generate(from: extraction)
        #expect(report.isComplete)
    }

    @Test("isComplete is false when errors exist")
    func isCompleteWithErrors() {
        let errors = [FeatureError(featureType: .fonts, message: "fail")]
        let extraction = makeExtractionResult(errors: errors)
        let report = FeatureReport.generate(from: extraction)
        #expect(!report.isComplete)
    }

    @Test("featureCount returns node count")
    func featureCount() {
        let tree = makeFeatureTree(leafCount: 3)
        let extraction = makeExtractionResult(features: tree)
        let report = FeatureReport.generate(from: extraction)
        #expect(report.featureCount == 4) // 3 leaves + 1 branch
    }

    @Test("errorCount returns error count")
    func errorCount() {
        let errors = [
            FeatureError(featureType: .fonts, message: "a"),
            FeatureError(featureType: .pages, message: "b"),
        ]
        let extraction = makeExtractionResult(errors: errors)
        let report = FeatureReport.generate(from: extraction)
        #expect(report.errorCount == 2)
    }

    @Test("documentURL returns the extraction URL")
    func documentURL() {
        let extraction = makeExtractionResult(documentPath: "/test/abc.pdf")
        let report = FeatureReport.generate(from: extraction)
        #expect(report.documentURL.lastPathComponent == "abc.pdf")
    }

    // MARK: - Equatable

    @Test("Equatable — same reports are equal")
    func equatable() {
        let extraction = makeExtractionResult()
        let a = FeatureReport(extractionResult: extraction, summary: "same")
        let b = FeatureReport(extractionResult: extraction, summary: "same")
        #expect(a == b)
    }

    @Test("Equatable — different summaries are not equal")
    func equatableDifferent() {
        let extraction = makeExtractionResult()
        let a = FeatureReport(extractionResult: extraction, summary: "a")
        let b = FeatureReport(extractionResult: extraction, summary: "b")
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let extraction = makeExtractionResult()
        let report = FeatureReport.generate(from: extraction)
        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(FeatureReport.self, from: data)
        #expect(decoded == report)
    }

    @Test("Codable preserves summary string")
    func codablePreservesSummary() throws {
        let extraction = makeExtractionResult()
        let report = FeatureReport(extractionResult: extraction, summary: "Custom summary text")
        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(FeatureReport.self, from: data)
        #expect(decoded.summary == "Custom summary text")
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let extraction = makeExtractionResult()
        let report = FeatureReport.generate(from: extraction)
        let transferred = await Task { report }.value
        #expect(transferred == report)
    }

    // MARK: - CustomStringConvertible

    @Test("Description contains document name")
    func descriptionContainsDocName() {
        let extraction = makeExtractionResult(documentPath: "/path/report.pdf")
        let report = FeatureReport.generate(from: extraction)
        #expect(report.description.contains("report.pdf"))
    }

    @Test("Description indicates complete status")
    func descriptionComplete() {
        let extraction = makeExtractionResult()
        let report = FeatureReport.generate(from: extraction)
        #expect(report.description.contains("complete"))
    }

    @Test("Description indicates error count")
    func descriptionErrors() {
        let errors = [FeatureError(featureType: .fonts, message: "x")]
        let extraction = makeExtractionResult(errors: errors)
        let report = FeatureReport.generate(from: extraction)
        #expect(report.description.contains("1 errors"))
    }
}
