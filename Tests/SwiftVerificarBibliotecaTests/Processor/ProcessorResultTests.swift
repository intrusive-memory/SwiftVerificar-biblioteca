import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

/// Helpers for building test data.
private extension ProcessorResultTests {

    static let testURL = URL(fileURLWithPath: "/tmp/test.pdf")

    static func makeValidationResult(
        isCompliant: Bool = true
    ) -> ValidationResult {
        ValidationResult(
            profileName: "Test Profile",
            documentURL: testURL,
            isCompliant: isCompliant,
            assertions: [],
            duration: ValidationDuration(start: Date(), end: Date())
        )
    }

    static func makeFeatureResult() -> FeatureExtractionResult {
        FeatureExtractionResult(
            documentURL: testURL,
            features: .leaf(name: "root", value: nil),
            errors: []
        )
    }

    static func makeFixerResult() -> MetadataFixerResult {
        MetadataFixerResult(
            status: .success,
            fixes: [MetadataFix(field: "dc:title", originalValue: nil, newValue: "Title", fixDescription: "Added title")],
            outputURL: URL(fileURLWithPath: "/tmp/fixed.pdf")
        )
    }
}

@Suite("ProcessorResult Tests")
struct ProcessorResultTests {

    // MARK: - Default Initialization

    @Test("Default init with only URL")
    func defaultInit() {
        let result = ProcessorResult(documentURL: Self.testURL)

        #expect(result.documentURL == Self.testURL)
        #expect(result.validationResult == nil)
        #expect(result.featureResult == nil)
        #expect(result.fixerResult == nil)
        #expect(result.errors.isEmpty)
    }

    // MARK: - Full Initialization

    @Test("Full init with all results")
    func fullInit() {
        let validation = Self.makeValidationResult()
        let features = Self.makeFeatureResult()
        let fixer = Self.makeFixerResult()

        let result = ProcessorResult(
            documentURL: Self.testURL,
            validationResult: validation,
            featureResult: features,
            fixerResult: fixer,
            errors: []
        )

        #expect(result.documentURL == Self.testURL)
        #expect(result.validationResult != nil)
        #expect(result.featureResult != nil)
        #expect(result.fixerResult != nil)
        #expect(result.errors.isEmpty)
    }

    @Test("Init with errors")
    func initWithErrors() {
        let errors: [VerificarError] = [
            .validationFailed(reason: "Something went wrong"),
            .ioError(path: "/tmp/test.pdf", reason: "Write failed")
        ]

        let result = ProcessorResult(
            documentURL: Self.testURL,
            errors: errors
        )

        #expect(result.errors.count == 2)
    }

    // MARK: - isSuccessful

    @Test("isSuccessful returns true when no errors")
    func isSuccessfulTrue() {
        let result = ProcessorResult(documentURL: Self.testURL, errors: [])
        #expect(result.isSuccessful == true)
    }

    @Test("isSuccessful returns false when errors present")
    func isSuccessfulFalse() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            errors: [.configurationError(reason: "test")]
        )
        #expect(result.isSuccessful == false)
    }

    // MARK: - hasErrors

    @Test("hasErrors returns false when no errors")
    func hasErrorsFalse() {
        let result = ProcessorResult(documentURL: Self.testURL)
        #expect(result.hasErrors == false)
    }

    @Test("hasErrors returns true when errors present")
    func hasErrorsTrue() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            errors: [.validationFailed(reason: "test")]
        )
        #expect(result.hasErrors == true)
    }

    // MARK: - errorCount

    @Test("errorCount returns zero for empty errors")
    func errorCountZero() {
        let result = ProcessorResult(documentURL: Self.testURL)
        #expect(result.errorCount == 0)
    }

    @Test("errorCount returns correct count")
    func errorCountCorrect() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            errors: [
                .validationFailed(reason: "a"),
                .configurationError(reason: "b"),
                .ioError(path: nil, reason: "c")
            ]
        )
        #expect(result.errorCount == 3)
    }

    // MARK: - hasValidation

    @Test("hasValidation returns true when validation result present")
    func hasValidationTrue() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            validationResult: Self.makeValidationResult()
        )
        #expect(result.hasValidation == true)
    }

    @Test("hasValidation returns false when validation result absent")
    func hasValidationFalse() {
        let result = ProcessorResult(documentURL: Self.testURL)
        #expect(result.hasValidation == false)
    }

    // MARK: - hasFeatures

    @Test("hasFeatures returns true when feature result present")
    func hasFeaturesTrue() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            featureResult: Self.makeFeatureResult()
        )
        #expect(result.hasFeatures == true)
    }

    @Test("hasFeatures returns false when feature result absent")
    func hasFeaturesFalse() {
        let result = ProcessorResult(documentURL: Self.testURL)
        #expect(result.hasFeatures == false)
    }

    // MARK: - hasFixer

    @Test("hasFixer returns true when fixer result present")
    func hasFixerTrue() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            fixerResult: Self.makeFixerResult()
        )
        #expect(result.hasFixer == true)
    }

    @Test("hasFixer returns false when fixer result absent")
    func hasFixerFalse() {
        let result = ProcessorResult(documentURL: Self.testURL)
        #expect(result.hasFixer == false)
    }

    // MARK: - isCompliant

    @Test("isCompliant returns true when document is compliant")
    func isCompliantTrue() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            validationResult: Self.makeValidationResult(isCompliant: true)
        )
        #expect(result.isCompliant == true)
    }

    @Test("isCompliant returns false when document is non-compliant")
    func isCompliantFalse() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            validationResult: Self.makeValidationResult(isCompliant: false)
        )
        #expect(result.isCompliant == false)
    }

    @Test("isCompliant returns nil when no validation")
    func isCompliantNil() {
        let result = ProcessorResult(documentURL: Self.testURL)
        #expect(result.isCompliant == nil)
    }

    // MARK: - completedPhaseCount

    @Test("completedPhaseCount is zero with no results")
    func completedPhaseCountZero() {
        let result = ProcessorResult(documentURL: Self.testURL)
        #expect(result.completedPhaseCount == 0)
    }

    @Test("completedPhaseCount is one with validation only")
    func completedPhaseCountOne() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            validationResult: Self.makeValidationResult()
        )
        #expect(result.completedPhaseCount == 1)
    }

    @Test("completedPhaseCount is two with validation and features")
    func completedPhaseCountTwo() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            validationResult: Self.makeValidationResult(),
            featureResult: Self.makeFeatureResult()
        )
        #expect(result.completedPhaseCount == 2)
    }

    @Test("completedPhaseCount is three with all results")
    func completedPhaseCountThree() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            validationResult: Self.makeValidationResult(),
            featureResult: Self.makeFeatureResult(),
            fixerResult: Self.makeFixerResult()
        )
        #expect(result.completedPhaseCount == 3)
    }

    @Test("completedPhaseCount is one with fixer only")
    func completedPhaseCountFixerOnly() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            fixerResult: Self.makeFixerResult()
        )
        #expect(result.completedPhaseCount == 1)
    }

    // MARK: - Equatable

    @Test("Same results are equal")
    func equality() {
        let a = ProcessorResult(documentURL: Self.testURL)
        let b = ProcessorResult(documentURL: Self.testURL)
        #expect(a == b)
    }

    @Test("Different URLs are not equal")
    func inequalityURL() {
        let a = ProcessorResult(documentURL: URL(fileURLWithPath: "/tmp/a.pdf"))
        let b = ProcessorResult(documentURL: URL(fileURLWithPath: "/tmp/b.pdf"))
        #expect(a != b)
    }

    @Test("With vs without validation are not equal")
    func inequalityValidation() {
        let a = ProcessorResult(documentURL: Self.testURL)
        let b = ProcessorResult(
            documentURL: Self.testURL,
            validationResult: Self.makeValidationResult()
        )
        #expect(a != b)
    }

    @Test("With vs without errors are not equal")
    func inequalityErrors() {
        let a = ProcessorResult(documentURL: Self.testURL, errors: [])
        let b = ProcessorResult(
            documentURL: Self.testURL,
            errors: [.configurationError(reason: "test")]
        )
        #expect(a != b)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes document name")
    func descriptionIncludesDocumentName() {
        let result = ProcessorResult(documentURL: Self.testURL)
        #expect(result.description.contains("test.pdf"))
    }

    @Test("Description includes compliant for compliant document")
    func descriptionIncludesCompliant() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            validationResult: Self.makeValidationResult(isCompliant: true)
        )
        #expect(result.description.contains("compliant"))
    }

    @Test("Description includes non-compliant for non-compliant document")
    func descriptionIncludesNonCompliant() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            validationResult: Self.makeValidationResult(isCompliant: false)
        )
        #expect(result.description.contains("non-compliant"))
    }

    @Test("Description includes features when present")
    func descriptionIncludesFeatures() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            featureResult: Self.makeFeatureResult()
        )
        #expect(result.description.contains("features"))
    }

    @Test("Description includes fixed when fixer result present")
    func descriptionIncludesFixed() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            fixerResult: Self.makeFixerResult()
        )
        #expect(result.description.contains("fixed"))
    }

    @Test("Description includes error count when errors present")
    func descriptionIncludesErrors() {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            errors: [.configurationError(reason: "test"), .validationFailed(reason: "test")]
        )
        #expect(result.description.contains("2 errors"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let result = ProcessorResult(
            documentURL: Self.testURL,
            validationResult: Self.makeValidationResult(),
            errors: []
        )

        let transferred = await Task {
            result
        }.value

        #expect(transferred == result)
    }
}
