import Testing
import Foundation
import PDFKit
@testable import SwiftVerificarBiblioteca
import SwiftVerificarValidationProfiles

// MARK: - Report Integration Tests

/// Integration tests that exercise report generation with real validation and
/// feature extraction results from actual (temporary) PDF documents.
///
/// These tests verify that the full pipeline -- PDF creation, parsing,
/// validation/extraction, report generation -- produces correct, non-empty
/// reports whose content reflects the input document.
@Suite("Report Integration Tests")
struct ReportIntegrationTests {

    // MARK: - Helpers

    /// Creates a temporary single-page PDF and returns its file URL.
    /// The caller is responsible for cleanup (use `defer`).
    private func createTempPDF(
        name: String = "ReportIntegration_\(UUID().uuidString)"
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name).pdf")
        let pdfDoc = PDFKit.PDFDocument()
        let page = PDFKit.PDFPage()
        pdfDoc.insert(page, at: 0)
        guard pdfDoc.write(to: url) else {
            throw ReportTestError.pdfCreationFailed
        }
        return url
    }

    /// Internal error type for test setup failures.
    private enum ReportTestError: Error {
        case pdfCreationFailed
    }

    // MARK: - JSON Report from Real Validation

    @Test("JSON report from real validation contains document filename")
    func jsonFromRealValidationContainsDocumentName() async throws {
        let url = try createTempPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let verificar = SwiftVerificar()
        let result = try await verificar.validateAccessibility(url)

        let report = ValidationReport.generate(from: result)
        let jsonData = try ReportGenerator.json(from: report)
        let jsonStr = String(data: jsonData, encoding: .utf8) ?? ""

        // The JSON should contain the temp file's name
        #expect(jsonStr.contains(url.lastPathComponent))
        // It should be valid JSON
        let parsed = try JSONSerialization.jsonObject(with: jsonData)
        #expect(parsed is [String: Any])
        // ruleCount should be non-negative
        #expect(report.ruleCount >= 0)
    }

    @Test("JSON report from real validation round-trips via Codable")
    func jsonFromRealValidationRoundTrips() async throws {
        let url = try createTempPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let verificar = SwiftVerificar()
        let result = try await verificar.validateAccessibility(url)
        let report = ValidationReport.generate(from: result)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(report)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ValidationReport.self, from: data)

        #expect(decoded.result.profileName == report.result.profileName)
        #expect(decoded.summaries.count == report.summaries.count)
        #expect(decoded.ruleCount == report.ruleCount)
    }

    // MARK: - HTML Report from Real Validation

    @Test("HTML report from real validation is a complete document")
    func htmlFromRealValidationIsComplete() async throws {
        let url = try createTempPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let verificar = SwiftVerificar()
        let result = try await verificar.validateAccessibility(url)
        let report = ValidationReport.generate(from: result)

        let html = ReportGenerator.html(from: report)

        // Verify it is a complete HTML document
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("<html"))
        #expect(html.contains("</html>"))
        #expect(html.contains("<title>Validation Report</title>"))

        // Should contain the document filename
        #expect(html.contains(url.lastPathComponent))

        // Should contain the profile name
        #expect(html.contains(result.profileName))

        // Should contain the compliance status
        let expectedStatus = result.isCompliant ? "COMPLIANT" : "NON-COMPLIANT"
        #expect(html.contains(expectedStatus))

        // Should contain inline CSS
        #expect(html.contains("<style>"))
    }

    // MARK: - Text Report from Real Validation

    @Test("Text report from real validation shows compliance status and structure")
    func textFromRealValidationShowsStatus() async throws {
        let url = try createTempPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let verificar = SwiftVerificar()
        let result = try await verificar.validateAccessibility(url)
        let report = ValidationReport.generate(from: result)

        let text = ReportGenerator.text(from: report)

        // Header
        #expect(text.contains("VALIDATION REPORT"))
        // Document name
        #expect(text.contains(url.lastPathComponent))
        // Profile name
        #expect(text.contains(result.profileName))
        // Compliance status
        let expectedStatus = result.isCompliant ? "COMPLIANT" : "NON-COMPLIANT"
        #expect(text.contains(expectedStatus))
        // Duration line
        #expect(text.contains("Duration:"))
        // Assertion counts
        #expect(text.contains("Assertions:"))
        // Separator lines
        #expect(text.contains("===="))
    }

    // MARK: - XML Report from Real Validation

    @Test("XML report from real validation contains correct structure")
    func xmlFromRealValidationHasStructure() async throws {
        let url = try createTempPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let verificar = SwiftVerificar()
        let result = try await verificar.validateAccessibility(url)
        let report = ValidationReport.generate(from: result)

        let xmlData = try ReportGenerator.xml(from: report)
        let xmlStr = String(data: xmlData, encoding: .utf8) ?? ""

        // XML declaration
        #expect(xmlStr.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        // Root element
        #expect(xmlStr.contains("<validationReport>"))
        #expect(xmlStr.contains("</validationReport>"))
        // Profile name
        #expect(xmlStr.contains("<profileName>"))
        #expect(xmlStr.contains(result.profileName))
        // Compliance status
        #expect(xmlStr.contains("<isCompliant>\(result.isCompliant)</isCompliant>"))
        // Summaries element
        #expect(xmlStr.contains("<summaries>"))
        #expect(xmlStr.contains("</summaries>"))
    }

    // MARK: - FeatureReport from Real Extraction

    @Test("FeatureReport from real PDF extraction contains meaningful data")
    func featureReportFromRealExtraction() async throws {
        let url = try createTempPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        // Parse the document
        let parser = SwiftPDFParser(url: url)
        let document = try await parser.parse()

        // Extract features with all standard features enabled
        let config = FeatureExtractorConfiguration()
        let extractor = SwiftFeatureExtractor(config: config)
        let extractionResult = extractor.extract(from: document)

        // Generate the report
        let report = FeatureReport.generate(from: extractionResult)

        // The summary should mention the document filename
        #expect(report.summary.contains(url.lastPathComponent))
        // Feature count should be positive (at least the root Document node)
        #expect(report.featureCount >= 1)
        // The document URL should match
        #expect(report.documentURL == url)
        // The extraction result should be stored
        #expect(report.extractionResult == extractionResult)
        // For a simple blank PDF, extraction should complete without errors
        #expect(report.isComplete)
        #expect(report.errorCount == 0)
        #expect(report.summary.contains("without errors"))
    }

    @Test("FeatureReport from real PDF is Codable")
    func featureReportFromRealPDFCodable() async throws {
        let url = try createTempPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let parser = SwiftPDFParser(url: url)
        let document = try await parser.parse()

        let config = FeatureExtractorConfiguration()
        let extractor = SwiftFeatureExtractor(config: config)
        let extractionResult = extractor.extract(from: document)
        let report = FeatureReport.generate(from: extractionResult)

        // Round-trip through JSON
        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(FeatureReport.self, from: data)
        #expect(decoded == report)
        #expect(decoded.summary == report.summary)
        #expect(decoded.featureCount == report.featureCount)
    }

    // MARK: - ValidationReport Summaries from Real Data

    @Test("ValidationReport summaries from real validation group assertions by rule")
    func validationReportSummariesGroupByRule() async throws {
        let url = try createTempPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let validator = SwiftPDFValidator(
            profileName: "PDF/UA-2",
            config: ValidatorConfig(recordPassedAssertions: true)
        )
        let result = try await validator.validate(contentsOf: url)
        let report = ValidationReport.generate(from: result)

        // Verify that summaries faithfully represent the assertion data
        // Total assertions across all summaries should equal the result's assertion count
        // (excluding unknown assertions, which generate looks at passed/failed only)
        let summaryTotal = report.summaries.reduce(0) { $0 + $1.totalChecks }
        let resultPassedFailed = result.assertions.count(where: {
            $0.status == .passed || $0.status == .failed
        })
        #expect(summaryTotal == resultPassedFailed)

        // Each summary ruleID should correspond to assertions in the result
        for summary in report.summaries {
            let matchingAssertions = result.assertions.filter { $0.ruleID == summary.ruleID }
            #expect(!matchingAssertions.isEmpty,
                    "Summary ruleID \(summary.ruleID.uniqueID) has no matching assertions")
        }

        // Summaries should be sorted by failedCount descending
        for i in 0..<max(0, report.summaries.count - 1) {
            #expect(report.summaries[i].failedCount >= report.summaries[i + 1].failedCount)
        }
    }

    // MARK: - All Report Formats from Same Result

    @Test("All four report formats produce non-empty output from the same validation result")
    func allFormatsProduceOutput() async throws {
        let url = try createTempPDF()
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

        // Text
        let text = ReportGenerator.text(from: report)
        #expect(!text.isEmpty)

        // All formats should reference the same profile name.
        // Note: JSONEncoder escapes "/" as "\/" in strings, so we check
        // for the escaped form in JSON output.
        let jsonStr = String(data: jsonData, encoding: .utf8) ?? ""
        let xmlStr = String(data: xmlData, encoding: .utf8) ?? ""
        let escapedProfileName = result.profileName.replacingOccurrences(of: "/", with: "\\/")
        #expect(jsonStr.contains(escapedProfileName))
        #expect(xmlStr.contains(result.profileName))
        #expect(html.contains(result.profileName))
        #expect(text.contains(result.profileName))
    }
}
