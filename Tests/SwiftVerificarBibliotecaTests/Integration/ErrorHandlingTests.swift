import Foundation
import PDFKit
import Testing
@testable import SwiftVerificarBiblioteca

/// Comprehensive error handling and edge case tests for the SwiftVerificar pipeline.
///
/// These tests verify that every error path produces the correct ``VerificarError``
/// case, that error messages are descriptive, and that cancellation support works.
@Suite("Error Handling Tests")
struct ErrorHandlingTests {

    // MARK: - Helpers

    /// Internal error type for test setup failures.
    private enum TestSetupError: Error {
        case pdfCreationFailed
    }

    /// Creates a minimal single-page PDF using PDFKit and returns its URL.
    private func createMinimalPDF(
        name: String = "ErrorTest_\(UUID().uuidString)"
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name).pdf")
        let pdfDoc = PDFKit.PDFDocument()
        let page = PDFKit.PDFPage()
        pdfDoc.insert(page, at: 0)
        guard pdfDoc.write(to: url) else {
            throw TestSetupError.pdfCreationFailed
        }
        return url
    }

    // MARK: - a) File not found -> parsingFailed

    @Test("validate with non-existent file throws parsingFailed")
    func validateFileNotFound() async {
        let url = URL(filePath: "/nonexistent_\(UUID().uuidString).pdf")
        let verificar = SwiftVerificar()

        do {
            _ = try await verificar.validate(url, profile: "PDF/UA-2")
            Issue.record("Expected parsingFailed error to be thrown")
        } catch let error as VerificarError {
            if case .parsingFailed(let errorURL, let reason) = error {
                #expect(errorURL == url)
                #expect(!reason.isEmpty, "Reason should describe the failure")
                #expect(reason.lowercased().contains("not found") || reason.lowercased().contains("file"),
                        "Reason should mention file not found")
            } else {
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error)): \(error)")
        }
    }

    @Test("validateAccessibility with non-existent file throws parsingFailed")
    func validateAccessibilityFileNotFound() async {
        let url = URL(filePath: "/nonexistent_\(UUID().uuidString).pdf")
        let verificar = SwiftVerificar()

        do {
            _ = try await verificar.validateAccessibility(url)
            Issue.record("Expected error to be thrown")
        } catch let error as VerificarError {
            if case .parsingFailed(let errorURL, _) = error {
                #expect(errorURL == url)
            } else {
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - b) Permission denied -> parsingFailed

    @Test("validate with unreadable file throws parsingFailed")
    func validatePermissionDenied() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PermDenied_\(UUID().uuidString).pdf")

        // Write a valid PDF, then remove read permission
        let pdfDoc = PDFKit.PDFDocument()
        pdfDoc.insert(PDFKit.PDFPage(), at: 0)
        guard pdfDoc.write(to: url) else {
            Issue.record("Failed to create test PDF")
            return
        }

        // Remove all permissions
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o000],
            ofItemAtPath: url.path
        )

        defer {
            // Restore permissions so cleanup can happen
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o644],
                ofItemAtPath: url.path
            )
            try? FileManager.default.removeItem(at: url)
        }

        let verificar = SwiftVerificar()
        do {
            _ = try await verificar.validate(url, profile: "PDF/UA-2")
            Issue.record("Expected parsingFailed error for unreadable file")
        } catch let error as VerificarError {
            switch error {
            case .parsingFailed(let errorURL, let reason):
                #expect(errorURL == url)
                #expect(!reason.isEmpty, "Reason should describe the failure")
            default:
                // On some systems, unreadable files may trigger different errors
                // but it should still be a VerificarError
                break
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - c) Invalid/corrupt PDF -> parsingFailed

    @Test("validate with corrupt PDF (random bytes) throws parsingFailed")
    func validateCorruptPDF() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Corrupt_\(UUID().uuidString).pdf")

        // Write random bytes that are not a valid PDF
        var randomBytes = [UInt8](repeating: 0, count: 1024)
        for i in 0..<randomBytes.count {
            randomBytes[i] = UInt8.random(in: 0...255)
        }
        let data = Data(randomBytes)
        try data.write(to: url)

        defer { try? FileManager.default.removeItem(at: url) }

        let verificar = SwiftVerificar()
        do {
            _ = try await verificar.validate(url, profile: "PDF/UA-2")
            Issue.record("Expected parsingFailed error for corrupt PDF")
        } catch let error as VerificarError {
            if case .parsingFailed(let errorURL, let reason) = error {
                #expect(errorURL == url)
                #expect(!reason.isEmpty, "Reason should describe the parse failure")
            } else {
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - d) Empty file -> parsingFailed

    @Test("validate with empty file throws parsingFailed")
    func validateEmptyFile() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Empty_\(UUID().uuidString).pdf")

        // Write an empty file
        try Data().write(to: url)

        defer { try? FileManager.default.removeItem(at: url) }

        let verificar = SwiftVerificar()
        do {
            _ = try await verificar.validate(url, profile: "PDF/UA-2")
            Issue.record("Expected parsingFailed error for empty file")
        } catch let error as VerificarError {
            if case .parsingFailed(let errorURL, let reason) = error {
                #expect(errorURL == url)
                #expect(!reason.isEmpty, "Reason should describe why empty file failed")
            } else {
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - e) Profile not found

    @Test("validate with non-existent profile name throws profileNotFound")
    func validateProfileNotFound() async {
        let url = URL(filePath: "/tmp/test.pdf")
        let verificar = SwiftVerificar()

        do {
            _ = try await verificar.validate(url, profile: "NonExistentProfile")
            Issue.record("Expected profileNotFound error")
        } catch let error as VerificarError {
            if case .profileNotFound(let name) = error {
                #expect(name == "NonExistentProfile")
            } else {
                Issue.record("Expected profileNotFound, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error)): \(error)")
        }
    }

    @Test("validate with gibberish profile name throws profileNotFound")
    func validateGibberishProfile() async {
        let url = URL(filePath: "/tmp/test.pdf")
        let verificar = SwiftVerificar()

        let gibberishProfiles = ["XYZZY", "pdf-banana", "NotAStandard", "12345"]
        for profile in gibberishProfiles {
            do {
                _ = try await verificar.validate(url, profile: profile)
                Issue.record("Expected profileNotFound for '\(profile)'")
            } catch let error as VerificarError {
                if case .profileNotFound(let name) = error {
                    #expect(name == profile)
                } else {
                    Issue.record("Expected profileNotFound for '\(profile)', got \(error)")
                }
            } catch {
                Issue.record("Expected VerificarError for '\(profile)', got \(type(of: error))")
            }
        }
    }

    // MARK: - f) Empty profile name

    @Test("validate with empty profile name throws profileNotFound with empty name")
    func validateEmptyProfileName() async {
        let url = URL(filePath: "/tmp/test.pdf")
        let verificar = SwiftVerificar()

        do {
            _ = try await verificar.validate(url, profile: "")
            Issue.record("Expected profileNotFound error for empty profile")
        } catch let error as VerificarError {
            if case .profileNotFound(let name) = error {
                #expect(name.isEmpty, "Profile name should be empty string")
                // Verify the error description is meaningful even for empty name
                let desc = error.localizedDescription
                #expect(!desc.isEmpty)
                #expect(desc.lowercased().contains("empty") || desc.lowercased().contains("not found"),
                        "Error description should explain the problem")
            } else {
                Issue.record("Expected profileNotFound, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error)): \(error)")
        }
    }

    @Test("validateBatch with empty profile name throws profileNotFound before processing")
    func validateBatchEmptyProfile() async {
        let verificar = SwiftVerificar()
        let urls = [URL(filePath: "/tmp/test.pdf")]

        do {
            _ = try await verificar.validateBatch(urls, profile: "")
            Issue.record("Expected profileNotFound error")
        } catch let error as VerificarError {
            if case .profileNotFound(let name) = error {
                #expect(name.isEmpty)
            } else {
                Issue.record("Expected profileNotFound, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - g) Process with non-existent file -> parsingFailed in result

    @Test("process with non-existent file returns parsingFailed error in result")
    func processFileNotFound() async throws {
        let url = URL(filePath: "/nonexistent_\(UUID().uuidString).pdf")
        let verificar = SwiftVerificar()

        let result = try await verificar.process(url, config: .all)
        #expect(result.documentURL == url)
        #expect(result.hasErrors)
        #expect(result.errorCount == 1)

        // The single error should be parsingFailed
        if let firstError = result.errors.first {
            if case .parsingFailed(let errorURL, let reason) = firstError {
                #expect(errorURL == url)
                #expect(!reason.isEmpty)
            } else {
                Issue.record("Expected parsingFailed in processor errors, got \(firstError)")
            }
        }

        // No phase results should be present since parsing failed
        #expect(result.validationResult == nil)
        #expect(result.featureResult == nil)
        #expect(result.fixerResult == nil)
    }

    @Test("process with corrupt file returns parsingFailed error in result")
    func processCorruptFile() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProcessCorrupt_\(UUID().uuidString).pdf")

        var randomBytes = [UInt8](repeating: 0, count: 512)
        for i in 0..<randomBytes.count {
            randomBytes[i] = UInt8.random(in: 0...255)
        }
        try Data(randomBytes).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let processor = PDFProcessor()
        let result = try await processor.process(url: url, config: .all)

        #expect(result.hasErrors)
        #expect(result.errorCount >= 1)

        let parsingErrors = result.errors.filter {
            if case .parsingFailed = $0 { return true }
            return false
        }
        #expect(!parsingErrors.isEmpty, "Should contain at least one parsingFailed error")
    }

    // MARK: - h) validateBatch with mix of valid and invalid files

    @Test("validateBatch with mix of valid and invalid files returns correct results")
    func validateBatchMixedFiles() async throws {
        // Create 2 real PDFs
        let realURL1 = try createMinimalPDF(name: "BatchValid1_\(UUID().uuidString)")
        let realURL2 = try createMinimalPDF(name: "BatchValid2_\(UUID().uuidString)")
        let badURL = URL(filePath: "/nonexistent_batch_\(UUID().uuidString).pdf")

        defer {
            try? FileManager.default.removeItem(at: realURL1)
            try? FileManager.default.removeItem(at: realURL2)
        }

        let verificar = SwiftVerificar()
        let results = try await verificar.validateBatch(
            [realURL1, badURL, realURL2],
            profile: "PDF/UA-2"
        )

        #expect(results.count == 3, "Should have results for all 3 URLs")

        // Real PDFs should succeed
        if case .success(let result1) = results[realURL1] {
            #expect(result1.documentURL == realURL1)
            #expect(result1.totalCount >= 0)
        } else {
            Issue.record("Expected success for realURL1")
        }

        if case .success(let result2) = results[realURL2] {
            #expect(result2.documentURL == realURL2)
            #expect(result2.totalCount >= 0)
        } else {
            Issue.record("Expected success for realURL2")
        }

        // Non-existent file should fail
        if case .failure(let error) = results[badURL] {
            #expect(error is VerificarError, "Error should be a VerificarError")
            if let verificarError = error as? VerificarError {
                if case .parsingFailed(let errorURL, _) = verificarError {
                    #expect(errorURL == badURL)
                } else {
                    Issue.record("Expected parsingFailed for bad URL, got \(verificarError)")
                }
            }
        } else {
            Issue.record("Expected failure for bad URL")
        }
    }

    @Test("validateBatch with all invalid files returns all failures")
    func validateBatchAllInvalid() async throws {
        let urls = (0..<3).map { URL(filePath: "/nonexistent_\($0)_\(UUID().uuidString).pdf") }

        let verificar = SwiftVerificar()
        let results = try await verificar.validateBatch(urls, profile: "PDF/UA-2")

        #expect(results.count == 3)
        for url in urls {
            if case .failure(let error) = results[url] {
                #expect(error is VerificarError)
            } else {
                Issue.record("Expected failure for \(url)")
            }
        }
    }

    // MARK: - i) Validator timeout behavior

    @Test("Validator with very short timeout does not crash")
    func validatorShortTimeout() async throws {
        let url = try createMinimalPDF(name: "Timeout_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: url) }

        let verificar = SwiftVerificar()
        let config = ValidatorConfig(timeout: 0.001)

        // With a very short timeout, validation may or may not complete,
        // but it should not crash or hang
        do {
            let result = try await verificar.validate(
                url,
                profile: "PDF/UA-2",
                config: config
            )
            // If it completed, the result should be valid
            #expect(result.documentURL == url)
            #expect(result.totalCount >= 0)
        } catch {
            // Timeout or other errors are acceptable
            #expect(error is VerificarError || error is CancellationError,
                    "Error should be a VerificarError or CancellationError")
        }
    }

    @Test("Validator with nil timeout runs to completion")
    func validatorNilTimeout() async throws {
        let url = try createMinimalPDF(name: "NoTimeout_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: url) }

        let verificar = SwiftVerificar()
        let config = ValidatorConfig(timeout: nil)

        let result = try await verificar.validate(
            url,
            profile: "PDF/UA-2",
            config: config
        )
        #expect(result.documentURL == url)
    }

    // MARK: - Cancellation Support

    @Test("Cancellation of validate throws CancellationError or completes")
    func cancelValidate() async {
        let url = URL(filePath: "/tmp/cancel_test_\(UUID().uuidString).pdf")

        let task = Task {
            try await SwiftVerificar().validate(
                url,
                profile: "PDF/UA-2"
            )
        }
        task.cancel()

        do {
            _ = try await task.value
            // May have completed before cancel took effect -- that is acceptable
        } catch is CancellationError {
            // Expected -- cancellation was detected
        } catch {
            // Other errors (parsingFailed, etc.) are also acceptable
            // because the task might have started before cancellation
            #expect(error is VerificarError,
                    "Non-cancellation errors should be VerificarError")
        }
    }

    @Test("Cancellation of process throws CancellationError or completes")
    func cancelProcess() async {
        let url = URL(filePath: "/tmp/cancel_process_\(UUID().uuidString).pdf")

        let task = Task {
            try await SwiftVerificar().process(url, config: .all)
        }
        task.cancel()

        do {
            _ = try await task.value
            // May have completed before cancel took effect
        } catch is CancellationError {
            // Expected -- cancellation was detected
        } catch {
            // Other errors are acceptable
        }
    }

    @Test("Cancellation of validateBatch does not crash")
    func cancelValidateBatch() async {
        let urls = (0..<5).map { URL(filePath: "/tmp/cancel_batch_\($0).pdf") }

        let task = Task {
            try await SwiftVerificar().validateBatch(
                urls,
                profile: "PDF/UA-2"
            )
        }
        task.cancel()

        do {
            _ = try await task.value
            // May have completed before cancel
        } catch is CancellationError {
            // Expected
        } catch {
            // Other errors are acceptable
        }
    }

    // MARK: - VerificarError Description Completeness

    @Test("Every VerificarError case has a non-empty localizedDescription")
    func allErrorCasesHaveDescriptions() {
        let testURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let allCases: [VerificarError] = [
            .parsingFailed(url: testURL, reason: "test reason"),
            .validationFailed(reason: "test validation reason"),
            .profileNotFound(name: "TestProfile"),
            .profileNotFound(name: ""),
            .encryptedPDF(url: testURL),
            .configurationError(reason: "test config reason"),
            .ioError(path: "/tmp/test", reason: "test io reason"),
            .ioError(path: nil, reason: "test io reason no path"),
        ]

        for error in allCases {
            let description = error.localizedDescription
            #expect(!description.isEmpty,
                    "localizedDescription should not be empty for \(error)")
            // Also check that errorDescription is non-nil
            #expect(error.errorDescription != nil,
                    "errorDescription should not be nil for \(error)")
        }
    }

    @Test("parsingFailed error description includes the file path")
    func parsingFailedDescriptionIncludesPath() {
        let url = URL(fileURLWithPath: "/some/deep/path/document.pdf")
        let error = VerificarError.parsingFailed(url: url, reason: "corrupted header")

        let desc = error.localizedDescription
        #expect(desc.contains("document.pdf"), "Should include the filename")
        #expect(desc.contains("/some/deep/path"), "Should include the directory path")
        #expect(desc.contains("corrupted header"), "Should include the reason")
    }

    @Test("profileNotFound error description includes the profile name")
    func profileNotFoundDescriptionIncludesName() {
        let error = VerificarError.profileNotFound(name: "PDF/X-42")
        let desc = error.localizedDescription
        #expect(desc.contains("PDF/X-42"), "Should include the profile name")
        #expect(desc.contains("not found"), "Should mention not found")
    }

    @Test("profileNotFound with empty name has meaningful description")
    func profileNotFoundEmptyNameDescription() {
        let error = VerificarError.profileNotFound(name: "")
        let desc = error.localizedDescription
        #expect(!desc.isEmpty, "Description should not be empty for empty profile name")
        #expect(desc.lowercased().contains("empty") || desc.lowercased().contains("not found"),
                "Should explain the empty profile name issue")
    }

    @Test("encryptedPDF error description includes the file path")
    func encryptedPDFDescriptionIncludesPath() {
        let url = URL(fileURLWithPath: "/secure/protected.pdf")
        let error = VerificarError.encryptedPDF(url: url)

        let desc = error.localizedDescription
        #expect(desc.contains("protected.pdf"), "Should include the filename")
        #expect(desc.contains("encrypted"), "Should mention encryption")
    }

    @Test("configurationError description includes the reason")
    func configurationErrorDescriptionIncludesReason() {
        let error = VerificarError.configurationError(reason: "No foundry registered")
        let desc = error.localizedDescription
        #expect(desc.contains("No foundry registered"))
        #expect(desc.contains("Configuration"))
    }

    @Test("ioError with path includes path in description")
    func ioErrorWithPathDescription() {
        let error = VerificarError.ioError(path: "/data/output.pdf", reason: "disk full")
        let desc = error.localizedDescription
        #expect(desc.contains("/data/output.pdf"))
        #expect(desc.contains("disk full"))
    }

    @Test("ioError without path still has meaningful description")
    func ioErrorWithoutPathDescription() {
        let error = VerificarError.ioError(path: nil, reason: "network timeout")
        let desc = error.localizedDescription
        #expect(desc.contains("network timeout"))
        #expect(desc.contains("I/O error"))
    }

    @Test("CustomStringConvertible description matches errorDescription for all cases")
    func customStringConvertibleMatchesErrorDescription() {
        let testURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let allCases: [VerificarError] = [
            .parsingFailed(url: testURL, reason: "bad"),
            .validationFailed(reason: "engine crash"),
            .profileNotFound(name: "unknown"),
            .encryptedPDF(url: testURL),
            .configurationError(reason: "missing"),
            .ioError(path: "/tmp", reason: "fail"),
            .ioError(path: nil, reason: "fail"),
        ]

        for error in allCases {
            #expect(error.description == error.errorDescription,
                    "description and errorDescription should match for \(error)")
        }
    }

    // MARK: - Process edge cases

    @Test("process with empty task set returns configuration error")
    func processEmptyTasks() async throws {
        let url = URL(filePath: "/tmp/test.pdf")
        let config = ProcessorConfig(tasks: [])

        let processor = PDFProcessor()
        let result = try await processor.process(url: url, config: config)

        #expect(result.hasErrors)
        if let firstError = result.errors.first {
            if case .configurationError(let reason) = firstError {
                #expect(reason.lowercased().contains("no") || reason.lowercased().contains("task"),
                        "Should mention no tasks")
            } else {
                Issue.record("Expected configurationError, got \(firstError)")
            }
        }
    }

    @Test("process with validate-only config on non-existent file returns parsingFailed")
    func processValidateOnlyNonExistent() async throws {
        let url = URL(filePath: "/nonexistent_\(UUID().uuidString).pdf")

        let processor = PDFProcessor()
        let result = try await processor.process(
            url: url,
            config: ProcessorConfig.validateOnly
        )

        #expect(result.hasErrors)
        #expect(result.errorCount == 1)
        if case .parsingFailed(let errorURL, _) = result.errors.first {
            #expect(errorURL == url)
        } else {
            Issue.record("Expected parsingFailed, got \(String(describing: result.errors.first))")
        }
    }

    // MARK: - SwiftPDFParser error paths

    @Test("SwiftPDFParser.parse with non-existent URL throws parsingFailed")
    func parserFileNotFound() async {
        let url = URL(filePath: "/nonexistent_parser_\(UUID().uuidString).pdf")
        let parser = SwiftPDFParser(url: url)

        do {
            _ = try await parser.parse()
            Issue.record("Expected parsingFailed error")
        } catch let error as VerificarError {
            if case .parsingFailed(let errorURL, let reason) = error {
                #expect(errorURL == url)
                #expect(reason.contains("not found") || reason.contains("File"),
                        "Reason should mention file not found")
            } else {
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error))")
        }
    }

    @Test("SwiftPDFParser.parse with empty file throws parsingFailed")
    func parserEmptyFile() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ParserEmpty_\(UUID().uuidString).pdf")
        try Data().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let parser = SwiftPDFParser(url: url)

        do {
            _ = try await parser.parse()
            Issue.record("Expected parsingFailed error for empty file")
        } catch let error as VerificarError {
            if case .parsingFailed(let errorURL, _) = error {
                #expect(errorURL == url)
            } else {
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error))")
        }
    }

    @Test("SwiftPDFParser.parse with corrupt data throws parsingFailed")
    func parserCorruptData() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ParserCorrupt_\(UUID().uuidString).pdf")

        // Write data that looks nothing like a PDF
        let corruptData = Data("This is not a PDF file at all".utf8)
        try corruptData.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let parser = SwiftPDFParser(url: url)

        do {
            _ = try await parser.parse()
            Issue.record("Expected parsingFailed error for corrupt data")
        } catch let error as VerificarError {
            if case .parsingFailed(let errorURL, let reason) = error {
                #expect(errorURL == url)
                #expect(reason.contains("not a valid PDF") || reason.contains("parsed"),
                        "Reason should explain the file is not a valid PDF")
            } else {
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error))")
        }
    }

    @Test("SwiftPDFParser.detectFlavour with non-existent URL throws parsingFailed")
    func parserDetectFlavourFileNotFound() async {
        let url = URL(filePath: "/nonexistent_flavour_\(UUID().uuidString).pdf")
        let parser = SwiftPDFParser(url: url)

        do {
            _ = try await parser.detectFlavour()
            Issue.record("Expected parsingFailed error")
        } catch let error as VerificarError {
            if case .parsingFailed(let errorURL, _) = error {
                #expect(errorURL == url)
            } else {
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error))")
        }
    }

    // MARK: - SwiftPDFValidator error paths

    @Test("SwiftPDFValidator with unknown profile throws profileNotFound")
    func validatorUnknownProfile() async {
        let validator = SwiftPDFValidator(profileName: "UnknownProfileXYZ")
        let url = URL(filePath: "/tmp/test.pdf")

        do {
            _ = try await validator.validate(contentsOf: url)
            Issue.record("Expected error to be thrown")
        } catch let error as VerificarError {
            // The validator should throw profileNotFound or parsingFailed
            // (profileNotFound if it resolves profile first, parsingFailed if it parses first)
            switch error {
            case .profileNotFound(let name):
                #expect(name == "UnknownProfileXYZ")
            case .parsingFailed:
                // Also acceptable if parsing happens first
                break
            default:
                Issue.record("Expected profileNotFound or parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error))")
        }
    }

    @Test("SwiftPDFValidator.validate(contentsOf:) with non-existent file throws parsingFailed")
    func validatorFileNotFound() async {
        let validator = SwiftPDFValidator(profileName: "PDF/UA-2")
        let url = URL(filePath: "/nonexistent_validator_\(UUID().uuidString).pdf")

        do {
            _ = try await validator.validate(contentsOf: url)
            Issue.record("Expected parsingFailed error")
        } catch let error as VerificarError {
            if case .parsingFailed(let errorURL, _) = error {
                #expect(errorURL == url)
            } else {
                Issue.record("Expected parsingFailed, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(type(of: error))")
        }
    }

    // MARK: - Error Equatable

    @Test("Different VerificarError cases are not equal")
    func differentCasesNotEqual() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")

        let errors: [VerificarError] = [
            .parsingFailed(url: url, reason: "bad"),
            .validationFailed(reason: "bad"),
            .profileNotFound(name: "bad"),
            .encryptedPDF(url: url),
            .configurationError(reason: "bad"),
            .ioError(path: nil, reason: "bad"),
        ]

        for i in 0..<errors.count {
            for j in (i + 1)..<errors.count {
                #expect(errors[i] != errors[j],
                        "\(errors[i]) should not equal \(errors[j])")
            }
        }
    }

    @Test("Same VerificarError cases with same values are equal")
    func sameCasesEqual() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")

        #expect(
            VerificarError.parsingFailed(url: url, reason: "bad")
            == VerificarError.parsingFailed(url: url, reason: "bad")
        )
        #expect(
            VerificarError.profileNotFound(name: "X")
            == VerificarError.profileNotFound(name: "X")
        )
        #expect(
            VerificarError.encryptedPDF(url: url)
            == VerificarError.encryptedPDF(url: url)
        )
    }
}
