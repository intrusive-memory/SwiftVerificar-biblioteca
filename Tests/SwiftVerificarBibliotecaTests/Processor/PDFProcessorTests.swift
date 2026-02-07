import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("PDFProcessor Tests")
struct PDFProcessorTests {

    private let testURL = URL(fileURLWithPath: "/tmp/test.pdf")

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

    // MARK: - process with validate task (stub behavior)

    @Test("process with validate task returns configuration error (stub)")
    func processValidateStub() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.validate])

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.documentURL == testURL)
        #expect(result.hasErrors)
        #expect(result.errors.count == 1)
    }

    @Test("process with validate task has nil validation result (stub)")
    func processValidateNilResult() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.validate])

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.validationResult == nil)
    }

    // MARK: - process with extractFeatures task (stub behavior)

    @Test("process with extractFeatures task returns configuration error (stub)")
    func processExtractFeaturesStub() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.extractFeatures])

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.hasErrors)
        #expect(result.featureResult == nil)
    }

    // MARK: - process with fixMetadata task (stub behavior)

    @Test("process with fixMetadata task returns configuration error (stub)")
    func processFixMetadataStub() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.fixMetadata])

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.hasErrors)
        #expect(result.fixerResult == nil)
    }

    // MARK: - process with all tasks (stub behavior)

    @Test("process with all tasks returns errors for all phases (stub)")
    func processAllTasksStub() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig.all

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.documentURL == testURL)
        #expect(result.errors.count == 3)
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

    // MARK: - process with validate and extractFeatures

    @Test("process with two tasks returns two errors (stub)")
    func processTwoTasks() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(
            featureConfig: FeatureConfig(),
            tasks: [.validate, .extractFeatures]
        )

        let result = try await processor.process(url: testURL, config: config)

        #expect(result.errors.count == 2)
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

    // MARK: - Stub error messages

    @Test("Stub errors contain 'reconciliation' hint")
    func stubErrorsContainReconciliationHint() async throws {
        let processor = PDFProcessor()
        let config = ProcessorConfig(tasks: [.validate])

        let result = try await processor.process(url: testURL, config: config)

        for error in result.errors {
            if case .configurationError(let reason) = error {
                #expect(reason.contains("reconciliation") || reason.contains("No processing tasks"))
            }
        }
    }
}
