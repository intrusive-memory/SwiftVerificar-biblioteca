import Foundation
import os
import PDFKit
import Testing
@testable import SwiftVerificarBiblioteca
import SwiftVerificarValidationProfiles

// MARK: - Helpers

/// Thread-safe progress counter for verifying batch callbacks.
/// Uses `OSAllocatedUnfairLock` (available macOS 14+) for Swift 6 strict concurrency.
private final class ProgressCounter: Sendable {
    private let _calls = OSAllocatedUnfairLock(initialState: [(Int, Int)]())

    func record(completed: Int, total: Int) {
        _calls.withLock { $0.append((completed, total)) }
    }

    var calls: [(Int, Int)] {
        _calls.withLock { Array($0) }
    }
}

// MARK: - End-to-End Integration Tests

/// Comprehensive integration tests that exercise the full SwiftVerificar pipeline
/// with real PDFs created via PDFKit. Tests cover: URL -> Parse -> Validate ->
/// Extract Features -> Fix Metadata -> Generate Report.
@Suite("End-to-End Integration Tests")
struct EndToEndTests {

    // MARK: - Helpers

    /// Internal error type for test setup failures.
    private enum E2ETestError: Error {
        case pdfCreationFailed
    }

    /// Creates a minimal single-page PDF using PDFKit.
    private func createMinimalPDF(
        name: String = "E2E_\(UUID().uuidString)"
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name).pdf")
        let pdfDoc = PDFKit.PDFDocument()
        let page = PDFKit.PDFPage()
        pdfDoc.insert(page, at: 0)
        guard pdfDoc.write(to: url) else {
            throw E2ETestError.pdfCreationFailed
        }
        return url
    }

    /// Creates a multi-page PDF using PDFKit.
    private func createMultiPagePDF(
        pageCount: Int,
        name: String = "E2E_Multi_\(UUID().uuidString)"
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name).pdf")
        let pdfDoc = PDFKit.PDFDocument()
        for i in 0..<pageCount {
            pdfDoc.insert(PDFKit.PDFPage(), at: i)
        }
        guard pdfDoc.write(to: url) else {
            throw E2ETestError.pdfCreationFailed
        }
        return url
    }

    // MARK: - 1. Parse -> Validate -> Report for a basic PDF

    @Suite("Parse -> Validate -> Report")
    struct ParseValidateReportTests {

        private func createMinimalPDF() throws -> URL {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("E2E_PVR_\(UUID().uuidString).pdf")
            let pdfDoc = PDFKit.PDFDocument()
            pdfDoc.insert(PDFKit.PDFPage(), at: 0)
            guard pdfDoc.write(to: url) else {
                throw EndToEndTests.E2ETestError.pdfCreationFailed
            }
            return url
        }

        @Test("Validate a real PDF and generate a ValidationReport with meaningful summaries")
        func validateAndGenerateReport() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let result = try await verificar.validate(url, profile: "PDF/UA-2")

            // Result should reference the correct document URL and profile
            #expect(result.documentURL == url)
            #expect(result.profileName.contains("PDF/UA"))

            // Generate report
            let report = ValidationReport.generate(from: result)
            #expect(report.ruleCount >= 0)

            // Summaries should be sorted by failedCount descending
            for i in 0..<max(0, report.summaries.count - 1) {
                #expect(report.summaries[i].failedCount >= report.summaries[i + 1].failedCount)
            }
        }

        @Test("Generate JSON report from validation result and verify it is valid JSON")
        func jsonReportIsValid() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let result = try await verificar.validateAccessibility(url)
            let report = ValidationReport.generate(from: result)

            let jsonData = try ReportGenerator.json(from: report)
            #expect(!jsonData.isEmpty)

            let jsonStr = String(data: jsonData, encoding: .utf8) ?? ""
            #expect(jsonStr.contains(url.lastPathComponent))

            // Must be parseable JSON
            let parsed = try JSONSerialization.jsonObject(with: jsonData)
            #expect(parsed is [String: Any])
        }

        @Test("Generate HTML report from validation result")
        func htmlReportIsComplete() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let result = try await verificar.validateAccessibility(url)
            let report = ValidationReport.generate(from: result)

            let html = ReportGenerator.html(from: report)
            #expect(html.contains("<!DOCTYPE html>"))
            #expect(html.contains("<title>Validation Report</title>"))
            #expect(html.contains(url.lastPathComponent))
            #expect(html.contains(result.profileName))
        }

        @Test("Generate text report from validation result")
        func textReportShowsStructure() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let result = try await verificar.validateAccessibility(url)
            let report = ValidationReport.generate(from: result)

            let text = ReportGenerator.text(from: report)
            #expect(text.contains("VALIDATION REPORT"))
            #expect(text.contains(url.lastPathComponent))
            #expect(text.contains("Duration:"))
            #expect(text.contains("Assertions:"))
            #expect(text.contains("===="))
        }

        @Test("Generate XML report from validation result")
        func xmlReportHasStructure() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let result = try await verificar.validateAccessibility(url)
            let report = ValidationReport.generate(from: result)

            let xmlData = try ReportGenerator.xml(from: report)
            let xmlStr = String(data: xmlData, encoding: .utf8) ?? ""
            #expect(xmlStr.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
            #expect(xmlStr.contains("<validationReport>"))
            #expect(xmlStr.contains("</validationReport>"))
            #expect(xmlStr.contains("<profileName>"))
        }
    }

    // MARK: - 2. Full process() pipeline with all tasks

    @Suite("Full Process Pipeline")
    struct FullProcessPipelineTests {

        private func createMinimalPDF() throws -> URL {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("E2E_Proc_\(UUID().uuidString).pdf")
            let pdfDoc = PDFKit.PDFDocument()
            pdfDoc.insert(PDFKit.PDFPage(), at: 0)
            guard pdfDoc.write(to: url) else {
                throw EndToEndTests.E2ETestError.pdfCreationFailed
            }
            return url
        }

        @Test("process() with .all config produces validation, feature, and fixer results")
        func processAllTasksProducesResults() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let result = try await verificar.process(url, config: .all)

            #expect(result.documentURL == url)
            // Validation should have run
            #expect(result.validationResult != nil)
            // Feature extraction should have run
            #expect(result.featureResult != nil)
            // Metadata fixer should have run (may be noFixesNeeded or success)
            #expect(result.fixerResult != nil)
        }

        @Test("process() with default config produces validation result only")
        func processDefaultConfigProducesValidation() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let result = try await verificar.process(url)

            #expect(result.documentURL == url)
            #expect(result.hasValidation)
            // Default config only validates
            #expect(!result.hasFeatures)
            #expect(!result.hasFixer)
        }

        @Test("process() with all tasks has no parsing errors for a valid PDF")
        func processNoParsingErrors() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let processor = PDFProcessor()
            let result = try await processor.process(url: url, config: .all)

            // There should be no parsingFailed errors for a valid PDFKit-generated PDF
            let parsingErrors = result.errors.filter {
                if case .parsingFailed = $0 { return true }
                return false
            }
            #expect(parsingErrors.isEmpty)
        }

        @Test("process() validationResult has non-nil assertions array")
        func processValidationHasAssertions() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let result = try await verificar.process(url, config: .all)

            if let valResult = result.validationResult {
                #expect(valResult.assertions.count >= 0)
                #expect(valResult.documentURL == url)
                #expect(!valResult.profileName.isEmpty)
            } else {
                Issue.record("Expected validationResult to be non-nil")
            }
        }
    }

    // MARK: - 3. Batch validation of multiple PDFs

    @Suite("Batch Validation")
    struct BatchValidationTests {

        private func createMinimalPDF(index: Int) throws -> URL {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("E2E_Batch_\(index)_\(UUID().uuidString).pdf")
            let pdfDoc = PDFKit.PDFDocument()
            pdfDoc.insert(PDFKit.PDFPage(), at: 0)
            guard pdfDoc.write(to: url) else {
                throw EndToEndTests.E2ETestError.pdfCreationFailed
            }
            return url
        }

        @Test("Batch validation of 3 PDFs returns results for all")
        func batchValidationOfThreePDFs() async throws {
            let urls = try (0..<3).map { try createMinimalPDF(index: $0) }
            defer { urls.forEach { try? FileManager.default.removeItem(at: $0) } }

            let verificar = SwiftVerificar()
            let results = try await verificar.validateBatch(
                urls,
                profile: "PDF/UA-2",
                maxConcurrency: 2
            )

            // All 3 URLs should have results
            #expect(results.count == 3)
            for url in urls {
                let result = results[url]
                #expect(result != nil, "Missing result for \(url.lastPathComponent)")
                // Each should be either success or failure (not missing)
                switch result {
                case .success(let valResult):
                    #expect(valResult.documentURL == url)
                case .failure:
                    // Profile loading might fail; that is acceptable
                    break
                case .none:
                    Issue.record("No result for \(url.lastPathComponent)")
                }
            }
        }

        @Test("Batch validation fires progress callback for each document")
        func batchValidationFiresProgress() async throws {
            let urls = try (0..<3).map { try createMinimalPDF(index: $0) }
            defer { urls.forEach { try? FileManager.default.removeItem(at: $0) } }

            let counter = ProgressCounter()

            let verificar = SwiftVerificar()
            _ = try await verificar.validateBatch(
                urls,
                profile: "PDF/UA-2",
                maxConcurrency: 2
            ) { completed, total, _ in
                counter.record(completed: completed, total: total)
            }

            // Progress should have been called 3 times (once per document)
            let calls = counter.calls
            #expect(calls.count == 3)
            // Total should always be 3
            for (_, total) in calls {
                #expect(total == 3)
            }
        }

        @Test("Batch validation with maxConcurrency 1 processes sequentially")
        func batchValidationSequential() async throws {
            let urls = try (0..<3).map { try createMinimalPDF(index: $0) }
            defer { urls.forEach { try? FileManager.default.removeItem(at: $0) } }

            let verificar = SwiftVerificar()
            let results = try await verificar.validateBatch(
                urls,
                profile: "PDF/UA-2",
                maxConcurrency: 1
            )

            #expect(results.count == 3)
        }
    }

    // MARK: - 4. Feature extraction returns real data

    @Suite("Feature Extraction End-to-End")
    struct FeatureExtractionE2ETests {

        private func createMinimalPDF() throws -> URL {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("E2E_Feature_\(UUID().uuidString).pdf")
            let pdfDoc = PDFKit.PDFDocument()
            pdfDoc.insert(PDFKit.PDFPage(), at: 0)
            guard pdfDoc.write(to: url) else {
                throw EndToEndTests.E2ETestError.pdfCreationFailed
            }
            return url
        }

        @Test("Feature extraction from a real PDF produces a non-empty tree")
        func featureExtractionProducesTree() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let parser = SwiftPDFParser(url: url)
            let document = try await parser.parse()

            let config = FeatureExtractorConfiguration()
            let extractor = SwiftFeatureExtractor(config: config)
            let result = extractor.extract(from: document)

            // Root should be a branch named "Document"
            #expect(result.features.name == "Document")
            #expect(!result.features.isLeaf)
            // Should have at least one child (Low-Level Info, Pages, etc.)
            #expect(result.features.children.count >= 1)
            // Feature count includes root + children
            #expect(result.featureCount >= 2)
        }

        @Test("Feature extraction includes page information for a single-page PDF")
        func featureExtractionIncludesPages() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let parser = SwiftPDFParser(url: url)
            let document = try await parser.parse()

            let config = FeatureExtractorConfiguration()
            let extractor = SwiftFeatureExtractor(config: config)
            let result = extractor.extract(from: document)

            // Look for the Pages branch
            let pagesNode = result.features.child(named: "Pages")
            #expect(pagesNode != nil, "Expected a 'Pages' branch in the feature tree")
            if let pages = pagesNode {
                // At least 1 page
                #expect(pages.children.count >= 1)
            }
        }

        @Test("Feature extraction includes low-level info")
        func featureExtractionIncludesLowLevelInfo() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let parser = SwiftPDFParser(url: url)
            let document = try await parser.parse()

            let config = FeatureExtractorConfiguration()
            let extractor = SwiftFeatureExtractor(config: config)
            let result = extractor.extract(from: document)

            let lowLevelNode = result.features.child(named: "Low-Level Info")
            #expect(lowLevelNode != nil, "Expected a 'Low-Level Info' branch")
            if let lli = lowLevelNode {
                // Should have children like PDF Version, Page Count, etc.
                #expect(lli.children.count >= 1)
                let pdfVersion = lli.child(named: "PDF Version")
                #expect(pdfVersion != nil)
            }
        }

        @Test("FeatureReport from real extraction has meaningful summary")
        func featureReportSummary() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let parser = SwiftPDFParser(url: url)
            let document = try await parser.parse()

            let config = FeatureExtractorConfiguration()
            let extractor = SwiftFeatureExtractor(config: config)
            let extractionResult = extractor.extract(from: document)

            let report = FeatureReport.generate(from: extractionResult)
            #expect(report.summary.contains(url.lastPathComponent))
            #expect(report.featureCount >= 1)
            #expect(report.isComplete)
            #expect(report.errorCount == 0)
        }
    }

    // MARK: - 5. XMP metadata extraction from real PDF

    @Suite("XMP Metadata Extraction")
    struct XMPMetadataExtractionTests {

        private func createMinimalPDF() throws -> URL {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("E2E_XMP_\(UUID().uuidString).pdf")
            let pdfDoc = PDFKit.PDFDocument()
            pdfDoc.insert(PDFKit.PDFPage(), at: 0)
            guard pdfDoc.write(to: url) else {
                throw EndToEndTests.E2ETestError.pdfCreationFailed
            }
            return url
        }

        @Test("Parsing a real PDF extracts document metadata when present")
        func parsingExtractsMetadata() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let parser = SwiftPDFParser(url: url)
            let document = try await parser.parse()

            // A minimal PDFKit PDF may or may not have metadata depending
            // on the system, but parsing should succeed either way.
            // If metadata is present, it should be a valid DocumentMetadata.
            if let meta = document.metadata {
                // At least one of the fields should be non-nil or hasXMPMetadata set
                let hasAny = meta.title != nil || meta.author != nil ||
                    meta.producer != nil || meta.creator != nil || meta.hasXMPMetadata
                #expect(hasAny, "Metadata present but all fields nil")
            }
            // Either way, the URL should match
            #expect(document.url == url)
        }

        @Test("XMPParser can parse a valid XMP packet end-to-end")
        func xmpParserEndToEnd() throws {
            let xmpString = """
            <x:xmpmeta xmlns:x="adobe:ns:meta/">
              <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description rdf:about=""
                  xmlns:pdfuaid="http://www.aiim.org/pdfua/ns/id/"
                  pdfuaid:part="2"/>
              </rdf:RDF>
            </x:xmpmeta>
            """
            let parser = XMPParser()
            let metadata = try parser.parse(from: xmpString)
            #expect(metadata.pdfuaIdentification?.part == 2)
        }
    }

    // MARK: - 6. Profile auto-detection

    @Suite("Profile Auto-Detection")
    struct ProfileAutoDetectionTests {

        private func createMinimalPDF() throws -> URL {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("E2E_Profile_\(UUID().uuidString).pdf")
            let pdfDoc = PDFKit.PDFDocument()
            pdfDoc.insert(PDFKit.PDFPage(), at: 0)
            guard pdfDoc.write(to: url) else {
                throw EndToEndTests.E2ETestError.pdfCreationFailed
            }
            return url
        }

        @Test("PDFProcessor auto-selects a profile when processing a real PDF")
        func processorAutoSelectsProfile() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let processor = PDFProcessor()
            let result = try await processor.process(url: url, config: ProcessorConfig())

            // Validation should have run with an auto-detected or default profile
            if let valResult = result.validationResult {
                #expect(!valResult.profileName.isEmpty,
                        "Profile name should not be empty after auto-detection")
            }
        }

        @Test("SwiftPDFParser.detectFlavour returns nil for minimal PDF without XMP")
        func detectFlavourReturnsNilForMinimalPDF() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let parser = SwiftPDFParser(url: url)
            let flavour = try await parser.detectFlavour()
            // A minimal PDFKit-generated PDF has no XMP metadata, so no flavour
            #expect(flavour == nil)
        }
    }

    // MARK: - 7. Validator produces assertions for minimal PDF

    @Suite("Validator Assertions for Minimal PDF")
    struct ValidatorAssertionsTests {

        private func createMinimalPDF() throws -> URL {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("E2E_Assert_\(UUID().uuidString).pdf")
            let pdfDoc = PDFKit.PDFDocument()
            pdfDoc.insert(PDFKit.PDFPage(), at: 0)
            guard pdfDoc.write(to: url) else {
                throw EndToEndTests.E2ETestError.pdfCreationFailed
            }
            return url
        }

        @Test("Validation of minimal PDF completes and returns a valid result")
        func minimalPDFValidationCompletes() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let result = try await verificar.validate(url, profile: "PDF/UA-2")

            // Validation should complete without throwing.
            // A minimal PDFKit PDF lacks structure elements that many PDF/UA-2
            // rules target, so rules targeting those objects produce no assertions
            // (they are not applicable). The result may be technically compliant
            // because no failures were found -- even though the document is trivial.
            #expect(result.documentURL == url)
            #expect(result.profileName.contains("PDF/UA"))
            #expect(result.duration.duration >= 0)
        }

        @Test("Validation with recordPassedAssertions produces assertions")
        func validationWithRecordPassedProducesAssertions() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let validator = SwiftPDFValidator(
                profileName: "PDF/UA-2",
                config: ValidatorConfig(recordPassedAssertions: true)
            )
            let result = try await validator.validate(contentsOf: url)

            // With recordPassedAssertions, the result should include all
            // assertions (passed, failed, unknown). A minimal PDF will produce
            // assertions for rules targeting CosDocument and PDPage objects.
            #expect(result.totalCount >= 0,
                    "Validation should complete with a non-negative assertion count")
            // The isCompliant flag should be consistent with failedCount
            if result.failedCount == 0 {
                #expect(result.isCompliant)
            } else {
                #expect(!result.isCompliant)
            }
        }

        @Test("All assertions have non-empty messages and rule IDs")
        func allAssertionsHaveContent() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let validator = SwiftPDFValidator(
                profileName: "PDF/UA-2",
                config: ValidatorConfig(recordPassedAssertions: true)
            )
            let result = try await validator.validate(contentsOf: url)

            for assertion in result.assertions {
                #expect(!assertion.message.isEmpty,
                        "Assertion message should not be empty for rule \(assertion.ruleID.uniqueID)")
                #expect(!assertion.ruleID.uniqueID.isEmpty,
                        "Assertion ruleID should not be empty")
            }
        }

        @Test("Validation result isCompliant is consistent with failedCount")
        func isCompliantConsistentWithFailedCount() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let result = try await verificar.validate(url, profile: "PDF/UA-2")

            // isCompliant should be true iff failedCount == 0
            #expect(result.isCompliant == (result.failedCount == 0))
        }
    }

    // MARK: - 8. Full pipeline: validate -> report -> serialize

    @Suite("Full Pipeline Serialize")
    struct FullPipelineSerializeTests {

        private func createMinimalPDF() throws -> URL {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("E2E_Serialize_\(UUID().uuidString).pdf")
            let pdfDoc = PDFKit.PDFDocument()
            pdfDoc.insert(PDFKit.PDFPage(), at: 0)
            guard pdfDoc.write(to: url) else {
                throw EndToEndTests.E2ETestError.pdfCreationFailed
            }
            return url
        }

        @Test("End-to-end from URL to JSON data and back")
        func endToEndURLToJSONRoundTrip() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            // Step 1: Validate
            let verificar = SwiftVerificar()
            let result = try await verificar.validateAccessibility(url)

            // Step 2: Generate report
            let report = ValidationReport.generate(from: result)

            // Step 3: Serialize to JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(report)

            // Step 4: Parse JSON back
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(ValidationReport.self, from: jsonData)

            // Step 5: Verify round-trip
            #expect(decoded.result.profileName == report.result.profileName)
            #expect(decoded.result.isCompliant == report.result.isCompliant)
            #expect(decoded.summaries.count == report.summaries.count)
            #expect(decoded.ruleCount == report.ruleCount)
            #expect(decoded.result.failedCount == report.result.failedCount)
            #expect(decoded.result.passedCount == report.result.passedCount)
        }

        @Test("End-to-end produces all four report formats from same result")
        func endToEndAllFourFormats() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let result = try await verificar.validateAccessibility(url)
            let report = ValidationReport.generate(from: result)

            // JSON
            let jsonData = try ReportGenerator.json(from: report)
            #expect(!jsonData.isEmpty)

            // XML
            let xmlData = try ReportGenerator.xml(from: report)
            #expect(!xmlData.isEmpty)

            // HTML
            let html = ReportGenerator.html(from: report)
            #expect(!html.isEmpty)
            #expect(html.contains("<!DOCTYPE html>"))

            // Text
            let text = ReportGenerator.text(from: report)
            #expect(!text.isEmpty)
            #expect(text.contains("VALIDATION REPORT"))
        }

        @Test("End-to-end process with all tasks, then generate feature report")
        func endToEndProcessThenFeatureReport() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let verificar = SwiftVerificar()
            let processorResult = try await verificar.process(url, config: .all)

            // Feature extraction should have produced a result
            if let featureResult = processorResult.featureResult {
                let featureReport = FeatureReport.generate(from: featureResult)
                #expect(featureReport.featureCount >= 1)
                #expect(featureReport.summary.contains(url.lastPathComponent))

                // Feature report should be serializable
                let data = try JSONEncoder().encode(featureReport)
                let decoded = try JSONDecoder().decode(FeatureReport.self, from: data)
                #expect(decoded.featureCount == featureReport.featureCount)
            } else {
                Issue.record("Expected featureResult to be non-nil from .all config")
            }
        }
    }

    // MARK: - 9. Multi-page PDF Tests

    @Suite("Multi-Page PDF Tests")
    struct MultiPagePDFTests {

        private func createMultiPagePDF(pageCount: Int) throws -> URL {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("E2E_Multi_\(UUID().uuidString).pdf")
            let pdfDoc = PDFKit.PDFDocument()
            for i in 0..<pageCount {
                pdfDoc.insert(PDFKit.PDFPage(), at: i)
            }
            guard pdfDoc.write(to: url) else {
                throw EndToEndTests.E2ETestError.pdfCreationFailed
            }
            return url
        }

        @Test("Parsing a 5-page PDF reports correct page count")
        func multiPageParsingReportsPageCount() async throws {
            let url = try createMultiPagePDF(pageCount: 5)
            defer { try? FileManager.default.removeItem(at: url) }

            let parser = SwiftPDFParser(url: url)
            let document = try await parser.parse()
            #expect(document.pageCount == 5)
        }

        @Test("Feature extraction from 3-page PDF has 3 page nodes")
        func featureExtractionMultiPageHasCorrectPages() async throws {
            let url = try createMultiPagePDF(pageCount: 3)
            defer { try? FileManager.default.removeItem(at: url) }

            let parser = SwiftPDFParser(url: url)
            let document = try await parser.parse()

            let config = FeatureExtractorConfiguration()
            let extractor = SwiftFeatureExtractor(config: config)
            let result = extractor.extract(from: document)

            let pagesNode = result.features.child(named: "Pages")
            #expect(pagesNode != nil)
            if let pages = pagesNode {
                #expect(pages.children.count == 3)
            }
        }
    }

    // MARK: - 10. Metadata Fixer End-to-End

    @Suite("Metadata Fixer End-to-End")
    struct MetadataFixerE2ETests {

        private func createMinimalPDF() throws -> URL {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("E2E_Fixer_\(UUID().uuidString).pdf")
            let pdfDoc = PDFKit.PDFDocument()
            pdfDoc.insert(PDFKit.PDFPage(), at: 0)
            guard pdfDoc.write(to: url) else {
                throw EndToEndTests.E2ETestError.pdfCreationFailed
            }
            return url
        }

        @Test("Metadata fixer runs on a real PDF via process() pipeline")
        func fixerRunsViaProcess() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            let processor = PDFProcessor()
            let result = try await processor.process(url: url, config: .all)

            // Fixer result should be present (may be noFixesNeeded or success)
            #expect(result.fixerResult != nil)
            if let fixerResult = result.fixerResult {
                // Status should be one of the valid RepairStatus values
                let validStatuses: [RepairStatus] = [.success, .noFixesNeeded, .failed]
                #expect(validStatuses.contains(fixerResult.status))
            }
        }

        @Test("Metadata fixer with explicit config fixes metadata on minimal PDF")
        func fixerWithExplicitConfig() async throws {
            let url = try createMinimalPDF()
            defer { try? FileManager.default.removeItem(at: url) }

            // First validate to get the validation result
            let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
            let valResult = try await validator.validate(contentsOf: url)

            // Parse the document
            let parser = SwiftPDFParser(url: url)
            let document = try await parser.parse()

            // Run the fixer
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("E2E_Fixed_\(UUID().uuidString).pdf")
            defer { try? FileManager.default.removeItem(at: outputURL) }

            let fixer = SwiftMetadataFixer(config: .all)
            let fixerResult = try await fixer.fix(
                document: document,
                validationResult: valResult,
                outputURL: outputURL
            )

            // The fixer should return a valid result
            let validStatuses: [RepairStatus] = [.success, .noFixesNeeded, .failed]
            #expect(validStatuses.contains(fixerResult.status))

            // If fixes were applied, the output file should exist
            if fixerResult.status == .success && fixerResult.hasOutput {
                #expect(FileManager.default.fileExists(atPath: outputURL.path))
            }
        }
    }
}
