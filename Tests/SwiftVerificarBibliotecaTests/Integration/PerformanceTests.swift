import Foundation
import PDFKit
import Testing
@testable import SwiftVerificarBiblioteca

// MARK: - Performance Integration Tests

/// Basic performance tests that verify the pipeline completes within
/// reasonable time bounds and that concurrent operations do not deadlock.
@Suite("Performance Integration Tests")
struct PerformanceTests {

    // MARK: - Helpers

    private enum PerfTestError: Error {
        case pdfCreationFailed
    }

    private func createMinimalPDF(
        name: String = "Perf_\(UUID().uuidString)"
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name).pdf")
        let pdfDoc = PDFKit.PDFDocument()
        pdfDoc.insert(PDFKit.PDFPage(), at: 0)
        guard pdfDoc.write(to: url) else {
            throw PerfTestError.pdfCreationFailed
        }
        return url
    }

    // MARK: - Timing Tests

    @Test("Validation of a single-page PDF completes within 5 seconds")
    func validationCompletesInReasonableTime() async throws {
        let url = try createMinimalPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let start = Date()

        let verificar = SwiftVerificar()
        _ = try await verificar.validateAccessibility(url)

        let elapsed = Date().timeIntervalSince(start)
        #expect(elapsed < 5.0,
                "Validation took \(String(format: "%.2f", elapsed))s, expected < 5s")
    }

    @Test("Full process() pipeline completes within 10 seconds")
    func fullPipelineCompletesInReasonableTime() async throws {
        let url = try createMinimalPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let start = Date()

        let verificar = SwiftVerificar()
        _ = try await verificar.process(url, config: .all)

        let elapsed = Date().timeIntervalSince(start)
        #expect(elapsed < 10.0,
                "Full pipeline took \(String(format: "%.2f", elapsed))s, expected < 10s")
    }

    @Test("Parsing a single-page PDF completes within 2 seconds")
    func parsingCompletesInReasonableTime() async throws {
        let url = try createMinimalPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let start = Date()

        let parser = SwiftPDFParser(url: url)
        _ = try await parser.parse()

        let elapsed = Date().timeIntervalSince(start)
        #expect(elapsed < 2.0,
                "Parsing took \(String(format: "%.2f", elapsed))s, expected < 2s")
    }

    // MARK: - Concurrency / Deadlock Tests

    @Test("Concurrent validation of 5 PDFs completes without deadlock")
    func concurrentValidationDoesNotDeadlock() async throws {
        let urls = try (0..<5).map { i in try createMinimalPDF(name: "Perf_Conc_\(i)_\(UUID().uuidString)") }
        defer { urls.forEach { try? FileManager.default.removeItem(at: $0) } }

        let verificar = SwiftVerificar()
        let results = try await verificar.validateBatch(
            urls,
            profile: "PDF/UA-2",
            maxConcurrency: 5
        )

        // All 5 should complete
        #expect(results.count == 5, "Expected 5 results, got \(results.count)")
    }

    @Test("Concurrent process() calls complete without deadlock")
    func concurrentProcessDoesNotDeadlock() async throws {
        let urls = try (0..<3).map { i in try createMinimalPDF(name: "Perf_ProcConc_\(i)_\(UUID().uuidString)") }
        defer { urls.forEach { try? FileManager.default.removeItem(at: $0) } }

        let processor = PDFProcessor()

        let results = await withTaskGroup(
            of: (URL, ProcessorResult?).self
        ) { group in
            for url in urls {
                group.addTask {
                    let result = try? await processor.process(url: url, config: .all)
                    return (url, result)
                }
            }

            var collected: [(URL, ProcessorResult?)] = []
            for await pair in group {
                collected.append(pair)
            }
            return collected
        }

        #expect(results.count == 3, "Expected 3 results, got \(results.count)")
        for (url, result) in results {
            #expect(result != nil, "Processing failed for \(url.lastPathComponent)")
        }
    }

    @Test("Multiple SwiftVerificar.shared calls from concurrent tasks all succeed")
    func sharedInstanceConcurrentAccess() async throws {
        let url = try createMinimalPDF()
        defer { try? FileManager.default.removeItem(at: url) }

        let results = await withTaskGroup(of: String.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    SwiftVerificar.shared.version
                }
            }
            var versions: [String] = []
            for await version in group {
                versions.append(version)
            }
            return versions
        }

        #expect(results.count == 10)
        // All should return the same version
        let uniqueVersions = Set(results)
        #expect(uniqueVersions.count == 1)
    }
}
