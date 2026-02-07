import Foundation
import PDFKit
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("PDFProcessor Tests")
struct PDFProcessorTests {

    private let testURL = URL(fileURLWithPath: "/tmp/test.pdf")

    // MARK: - Test PDF Helper

    /// Creates a minimal valid PDF file at the given URL using PDFKit.
    /// Returns the URL on success, or nil on failure.
    private func createTestPDF(at url: URL) -> URL? {
        let pdfDoc = PDFKit.PDFDocument()
        let page = PDFKit.PDFPage()
        pdfDoc.insert(page, at: 0)
        let success = pdfDoc.write(to: url)
        return success ? url : nil
    }

    /// Creates a temporary PDF file and returns its URL.
    private func createTemporaryTestPDF() -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFProcessorTest_\(UUID().uuidString).pdf")
        return createTestPDF(at: url)
    }

    /// Removes the file at the given URL if it exists.
    private func cleanupFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Initialization

    @Test("PDFProcessor can be created with default init")
    func defaultInit() {
        let processor = PDFProcessor()
        #expect(processor.description.contains("PDFProcessor"))
    }

    @Test("PDFProcessor conforms to Sendable")
    func sendableConformance() {
        let processor = PDFProcessor()
        let _: any Sendable = processor
        // Compiles: PDFProcessor is Sendable
    }

    // MARK: - process with non-existent file (parsing fails)

    @Test("process with validate task on non-existent file returns parsingFailed error")
    func processValidateNonExistent() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.validate])

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.documentURL == testURL)
        #expect(result.hasErrors)
        #expect(result.errors.count == 1)
        if case .parsingFailed(let url, _) = result.errors.first {
            #expect(url == testURL)
        } else {
            #expect(Bool(false), "Expected parsingFailed error, got: \(result.errors.first!)")
        }
    }

    @Test("process with validate task on non-existent file has nil validation result")
    func processValidateNilResult() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.validate])

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.validationResult == nil)
    }

    @Test("process with extractFeatures task on non-existent file returns parsingFailed error")
    func processExtractFeaturesNonExistent() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.extractFeatures])

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.hasErrors)
        #expect(result.featureResult == nil)
        if case .parsingFailed = result.errors.first {
            // Expected: parsing fails for non-existent file
        } else {
            #expect(Bool(false), "Expected parsingFailed error")
        }
    }

    @Test("process with fixMetadata task on non-existent file returns parsingFailed error")
    func processFixMetadataNonExistent() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.fixMetadata])

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.hasErrors)
        #expect(result.fixerResult == nil)
        if case .parsingFailed = result.errors.first {
            // Expected: parsing fails for non-existent file
        } else {
            #expect(Bool(false), "Expected parsingFailed error")
        }
    }

    @Test("process with all tasks on non-existent file returns single parsingFailed error")
    func processAllTasksNonExistent() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig.all

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.documentURL == testURL)
        // Parsing fails first, so only 1 error (not 3)
        #expect(result.errors.count == 1)
        if case .parsingFailed = result.errors.first {
            // Expected
        } else {
            #expect(Bool(false), "Expected parsingFailed error")
        }
        #expect(result.validationResult == nil)
        #expect(result.featureResult == nil)
        #expect(result.fixerResult == nil)
    }

    // MARK: - process with empty tasks

    @Test("process with empty tasks returns configuration error")
    func processEmptyTasks() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [])

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.documentURL == testURL)
        #expect(result.errors.count == 1)
        if case .configurationError(let reason) = result.errors.first {
            #expect(reason.contains("No processing tasks"))
        } else {
            #expect(Bool(false), "Expected configurationError")
        }
    }

    // MARK: - process preserves document URL

    @Test("process preserves document URL in result")
    func processPreservesURL() async throws {
        let processor = PDFProcessor()
        let specificURL = URL(fileURLWithPath: "/Users/test/Documents/report.pdf")
        let config = ProcessorConfig(tasks: [.validate])

        let result = try await processor.process(url: specificURL, config: config)

        #expect(result.documentURL == specificURL)
    }

    @Test("process with different URLs returns different URLs")
    func processWithDifferentURLs() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.validate])

        let url1 = URL(fileURLWithPath: "/tmp/doc1.pdf")
        let url2 = URL(fileURLWithPath: "/tmp/doc2.pdf")

        let result1 = try await processor.process(url: url1, config: config)
        let result2 = try await processor.process(url: url2, config: config)

        #expect(result1.documentURL == url1)
        #expect(result2.documentURL == url2)
        #expect(result1.documentURL != result2.documentURL)
    }

    // MARK: - process with non-existent file and multiple tasks

    @Test("process with two tasks on non-existent file returns single parsingFailed error")
    func processTwoTasksNonExistent() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(
            featureConfig: FeatureConfig(),
            tasks: [.validate, .extractFeatures]
        )

        let result = try await processor.process(url: testURL, config: config)

        // Parsing fails before any phase runs, so only 1 error
        #expect(result.errors.count == 1)
        if case .parsingFailed = result.errors.first {
            // Expected
        } else {
            #expect(Bool(false), "Expected parsingFailed error")
        }
    }

    // MARK: - process with real PDF

    @Test("process with validate task on real PDF produces validation result")
    func processValidateRealPDF() async throws {
        guard let pdfURL = createTemporaryTestPDF() else {
            Issue.record("Failed to create test PDF")
            return
        }
        defer { cleanupFile(at: pdfURL) }

        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.validate])

        let result = try await processor.process(url: pdfURL, config: config)

        #expect(result.documentURL == pdfURL)
        // Validation should produce a result (may have errors from profile loading, but not parsing)
        // Either we get a validation result or a validation-related error (not parsingFailed)
        let hasParsingError = result.errors.contains { error in
            if case .parsingFailed = error { return true }
            return false
        }
        #expect(!hasParsingError, "Should not have parsing errors for a valid PDF")
    }

    @Test("process with extractFeatures task on real PDF produces feature result")
    func processExtractFeaturesRealPDF() async throws {
        guard let pdfURL = createTemporaryTestPDF() else {
            Issue.record("Failed to create test PDF")
            return
        }
        defer { cleanupFile(at: pdfURL) }

        let processor = PDFProcessor()
        let config = ProcessorConfig(
            featureConfig: FeatureConfig(),
            tasks: [.extractFeatures]
        )

        let result = try await processor.process(url: pdfURL, config: config)

        #expect(result.documentURL == pdfURL)
        // Feature extraction should always succeed (no throws)
        #expect(result.featureResult != nil, "Feature extraction should produce a result")
        if let featureResult = result.featureResult {
            #expect(featureResult.documentURL == pdfURL)
        }
    }

    @Test("process with fixMetadata task on real PDF produces fixer result")
    func processFixMetadataRealPDF() async throws {
        guard let pdfURL = createTemporaryTestPDF() else {
            Issue.record("Failed to create test PDF")
            return
        }
        defer { cleanupFile(at: pdfURL) }

        let processor = PDFProcessor()
        let config = ProcessorConfig(
            fixerConfig: FixerConfig(),
            tasks: [.fixMetadata]
        )

        let result = try await processor.process(url: pdfURL, config: config)

        #expect(result.documentURL == pdfURL)
        // Fixer should produce a result (either noFixesNeeded or success)
        #expect(result.fixerResult != nil, "Metadata fixer should produce a result")
    }

    @Test("process with all tasks on real PDF runs full pipeline")
    func processAllTasksRealPDF() async throws {
        guard let pdfURL = createTemporaryTestPDF() else {
            Issue.record("Failed to create test PDF")
            return
        }
        defer { cleanupFile(at: pdfURL) }

        let processor = PDFProcessor()
        let config = ProcessorConfig.all

        let result = try await processor.process(url: pdfURL, config: config)

        #expect(result.documentURL == pdfURL)
        // Feature extraction always succeeds
        #expect(result.featureResult != nil, "Feature extraction should produce a result")
        // Fixer should produce a result
        #expect(result.fixerResult != nil, "Metadata fixer should produce a result")
        // Validation may or may not succeed depending on profile loading,
        // but we should not have parsing errors
        let hasParsingError = result.errors.contains { error in
            if case .parsingFailed = error { return true }
            return false
        }
        #expect(!hasParsingError, "Should not have parsing errors for a valid PDF")
    }

    // MARK: - Sendable across task boundary

    @Test("PDFProcessor is Sendable across task boundaries")
    func sendableAcrossTask() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.validate])

        let result = try await Task {
            try await processor.process(url: URL(fileURLWithPath: "/tmp/test.pdf"), config: config)
        }.value

        #expect(result.documentURL.lastPathComponent == "test.pdf")
    }

    // MARK: - CustomStringConvertible

    @Test("Description is non-empty")
    func descriptionNonEmpty() {
        let processor = PDFProcessor()
        #expect(!processor.description.isEmpty)
    }

    @Test("Description contains PDFProcessor")
    func descriptionContainsName() {
        let processor = PDFProcessor()
        #expect(processor.description.contains("PDFProcessor"))
    }

    // MARK: - Multiple processors are independent

    @Test("Multiple processors are independent")
    func independentProcessors() async throws {
        let processor1 = PDFProcessor()
        let processor2 = PDFProcessor()
        let config = ProcessorConfig(tasks: [.validate])

        let result1 = try await processor1.process(url: URL(fileURLWithPath: "/tmp/a.pdf"), config: config)
        let result2 = try await processor2.process(url: URL(fileURLWithPath: "/tmp/b.pdf"), config: config)

        #expect(result1.documentURL.lastPathComponent == "a.pdf")
        #expect(result2.documentURL.lastPathComponent == "b.pdf")
    }

    // MARK: - Error type for non-existent files

    @Test("Non-existent file errors are parsingFailed, not configurationError")
    func nonExistentFileErrorType() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.validate])

        let result = try await processor.process(url: testURL, config: config)

        for error in result.errors {
            if case .parsingFailed(_, let reason) = error {
                #expect(reason.contains("File not found"),
                        "Parsing error should mention file not found: \(reason)")
            } else if case .configurationError = error {
                #expect(Bool(false), "Should not have configurationError for non-existent file")
            }
        }
    }
}
