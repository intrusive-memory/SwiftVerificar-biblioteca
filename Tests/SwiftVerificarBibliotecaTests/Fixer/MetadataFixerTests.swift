import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

// MARK: - Test Doubles

/// A mock MetadataFixer that returns a pre-configured result.
private struct SuccessMockFixer: MetadataFixer {
    let result: MetadataFixerResult

    init(result: MetadataFixerResult = MetadataFixerResult(status: .success)) {
        self.result = result
    }

    func fix(
        document: any ParsedDocument,
        validationResult: ValidationResult,
        outputURL: URL
    ) async throws -> MetadataFixerResult {
        result
    }
}

/// A mock MetadataFixer that checks compliance and returns accordingly.
private struct ComplianceCheckFixer: MetadataFixer {
    func fix(
        document: any ParsedDocument,
        validationResult: ValidationResult,
        outputURL: URL
    ) async throws -> MetadataFixerResult {
        if validationResult.isCompliant {
            return MetadataFixerResult.noFixesNeeded()
        }
        return MetadataFixerResult(status: .success)
    }
}

/// A mock MetadataFixer that always throws.
private struct ThrowingFixer: MetadataFixer {
    let error: VerificarError

    func fix(
        document: any ParsedDocument,
        validationResult: ValidationResult,
        outputURL: URL
    ) async throws -> MetadataFixerResult {
        throw error
    }
}

/// A mock MetadataFixer that includes the output URL in its result.
private struct OutputCapturingFixer: MetadataFixer {
    func fix(
        document: any ParsedDocument,
        validationResult: ValidationResult,
        outputURL: URL
    ) async throws -> MetadataFixerResult {
        MetadataFixerResult(
            status: .success,
            fixes: [MetadataFix(field: "dc:title", originalValue: nil, newValue: "Title", fixDescription: "Added title")],
            outputURL: outputURL
        )
    }
}

/// A minimal ParsedDocument for MetadataFixer testing.
private struct FixerTestDocument: ParsedDocument {
    let url: URL
    var flavour: String? = nil
    var pageCount: Int = 1
    var metadata: DocumentMetadata? = nil
    var hasStructureTree: Bool = false

    init(url: URL = URL(fileURLWithPath: "/tmp/test.pdf")) {
        self.url = url
    }

    func objects(ofType objectType: String) -> [any ValidationObject] {
        []
    }
}

/// Helper to create a ValidationResult for testing.
private func makeValidationResult(
    profileName: String = "Test Profile",
    isCompliant: Bool = false,
    assertions: [TestAssertion] = []
) -> ValidationResult {
    ValidationResult(
        profileName: profileName,
        documentURL: URL(fileURLWithPath: "/tmp/test.pdf"),
        isCompliant: isCompliant,
        assertions: assertions,
        duration: ValidationDuration(start: Date(), end: Date())
    )
}

@Suite("MetadataFixer Protocol Tests")
struct MetadataFixerTests {

    // MARK: - Protocol Conformance

    @Test("MockMetadataFixer conforms to MetadataFixer protocol")
    func protocolConformance() {
        let fixer: any MetadataFixer = SuccessMockFixer()
        #expect(type(of: fixer) is any MetadataFixer.Type)
    }

    @Test("MetadataFixer requires Sendable conformance")
    func sendableConformance() {
        let fixer = SuccessMockFixer()
        let _: any Sendable = fixer
        // Compiles: MetadataFixer requires Sendable
    }

    // MARK: - fix Method — Success Cases

    @Test("fix returns success result with fixes")
    func fixReturnsSuccess() async throws {
        let expectedFix = MetadataFix(field: "dc:title", originalValue: nil, newValue: "Fixed Title", fixDescription: "Added missing title")
        let fixer = SuccessMockFixer(
            result: MetadataFixerResult(status: .success, fixes: [expectedFix])
        )
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        let fixerResult = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)

        #expect(fixerResult.status == .success)
        #expect(fixerResult.fixCount == 1)
    }

    @Test("fix returns noFixesNeeded when document is compliant")
    func fixReturnsNoFixesNeeded() async throws {
        let fixer = ComplianceCheckFixer()
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult(isCompliant: true)
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        let fixerResult = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)

        #expect(fixerResult.status == .noFixesNeeded)
        #expect(fixerResult.fixCount == 0)
    }

    @Test("fix returns success when document is non-compliant")
    func fixReturnsSuccessForNonCompliant() async throws {
        let fixer = ComplianceCheckFixer()
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult(isCompliant: false)
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        let fixerResult = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)

        #expect(fixerResult.status == .success)
    }

    @Test("fix returns failed result")
    func fixReturnsFailed() async throws {
        let fixer = SuccessMockFixer(result: MetadataFixerResult.failed())
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        let fixerResult = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)

        #expect(fixerResult.status == .failed)
    }

    @Test("fix returns partialSuccess status")
    func fixReturnsPartialSuccess() async throws {
        let fixer = SuccessMockFixer(
            result: MetadataFixerResult(status: .partialSuccess, fixes: [
                MetadataFix(field: "dc:title", originalValue: nil, newValue: "Title", fixDescription: "Added")
            ])
        )
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        let fixerResult = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)

        #expect(fixerResult.status == .partialSuccess)
    }

    @Test("fix returns idRemoved status")
    func fixReturnsIdRemoved() async throws {
        let fixer = SuccessMockFixer(
            result: MetadataFixerResult(status: .idRemoved, fixes: [
                MetadataFix(field: "pdfaid:part", originalValue: "2", newValue: nil, fixDescription: "Removed invalid PDF/A ID")
            ])
        )
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        let fixerResult = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)

        #expect(fixerResult.status == .idRemoved)
    }

    // MARK: - fix Method — Output URL

    @Test("fix returns result with output URL")
    func fixReturnsResultWithOutputURL() async throws {
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")
        let fixer = OutputCapturingFixer()
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()

        let fixerResult = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)

        #expect(fixerResult.hasOutput)
        #expect(fixerResult.outputURL == outputURL)
    }

    @Test("fix with different output URLs produces different results")
    func fixWithDifferentOutputURLs() async throws {
        let fixer = OutputCapturingFixer()
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()

        let result1 = try await fixer.fix(
            document: doc,
            validationResult: validationResult,
            outputURL: URL(fileURLWithPath: "/tmp/a_fixed.pdf")
        )
        let result2 = try await fixer.fix(
            document: doc,
            validationResult: validationResult,
            outputURL: URL(fileURLWithPath: "/tmp/b_fixed.pdf")
        )

        #expect(result1.outputURL != result2.outputURL)
    }

    // MARK: - fix Method — Multiple Fixes

    @Test("fix returns result with multiple fixes")
    func fixReturnsMultipleFixes() async throws {
        let fixer = SuccessMockFixer(
            result: MetadataFixerResult(
                status: .success,
                fixes: [
                    MetadataFix(field: "dc:title", originalValue: nil, newValue: "Title", fixDescription: "Added title"),
                    MetadataFix(field: "dc:creator", originalValue: nil, newValue: "Author", fixDescription: "Added author"),
                    MetadataFix(field: "pdfuaid:part", originalValue: nil, newValue: "2", fixDescription: "Added PDF/UA ID"),
                ]
            )
        )
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        let fixerResult = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)

        #expect(fixerResult.fixCount == 3)
    }

    @Test("fix returns empty fixes for noFixesNeeded")
    func fixReturnsEmptyFixes() async throws {
        let fixer = SuccessMockFixer(result: MetadataFixerResult.noFixesNeeded())
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        let fixerResult = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)

        #expect(fixerResult.fixes.isEmpty)
    }

    // MARK: - fix Method — Error Handling

    @Test("fix can throw ioError")
    func fixCanThrowIOError() async {
        let fixer = ThrowingFixer(error: .ioError(path: "/tmp/test.pdf", reason: "Write failed"))
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        do {
            _ = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)
            #expect(Bool(false), "Should have thrown")
        } catch let error as VerificarError {
            if case .ioError(let path, _) = error {
                #expect(path == "/tmp/test.pdf")
            } else {
                #expect(Bool(false), "Expected ioError case")
            }
        } catch {
            #expect(Bool(false), "Expected VerificarError")
        }
    }

    @Test("fix can throw configurationError")
    func fixCanThrowConfigError() async {
        let fixer = ThrowingFixer(error: .configurationError(reason: "No fixer registered"))
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        do {
            _ = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)
            #expect(Bool(false), "Should have thrown")
        } catch let error as VerificarError {
            if case .configurationError(let reason) = error {
                #expect(reason.contains("No fixer registered"))
            } else {
                #expect(Bool(false), "Expected configurationError case")
            }
        } catch {
            #expect(Bool(false), "Expected VerificarError")
        }
    }

    // MARK: - Sendable across task boundary

    @Test("MetadataFixer can be passed across task boundaries")
    func sendableAcrossTaskBoundary() async throws {
        let fixer: any MetadataFixer = SuccessMockFixer()
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        let fixerResult = try await Task {
            try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)
        }.value

        #expect(fixerResult.status == .success)
    }

    // MARK: - Protocol as type constraint

    @Test("MetadataFixer works as generic constraint")
    func genericConstraint() async throws {
        func runFixer<F: MetadataFixer>(
            _ fixer: F,
            doc: any ParsedDocument,
            result: ValidationResult,
            outputURL: URL
        ) async throws -> MetadataFixerResult {
            try await fixer.fix(document: doc, validationResult: result, outputURL: outputURL)
        }

        let fixer = SuccessMockFixer()
        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        let fixerResult = try await runFixer(fixer, doc: doc, result: validationResult, outputURL: outputURL)
        #expect(fixerResult.status == .success)
    }

    @Test("MetadataFixer works as existential type in array")
    func existentialType() async throws {
        let fixers: [any MetadataFixer] = [
            SuccessMockFixer(result: MetadataFixerResult(status: .success)),
            SuccessMockFixer(result: MetadataFixerResult(status: .noFixesNeeded)),
        ]

        let doc = FixerTestDocument()
        let validationResult = makeValidationResult()
        let outputURL = URL(fileURLWithPath: "/tmp/fixed.pdf")

        var results: [MetadataFixerResult] = []
        for fixer in fixers {
            let r = try await fixer.fix(document: doc, validationResult: validationResult, outputURL: outputURL)
            results.append(r)
        }

        #expect(results.count == 2)
        #expect(results[0].status == .success)
        #expect(results[1].status == .noFixesNeeded)
    }

    // MARK: - Document properties are accessible

    @Test("fix can read document URL")
    func fixCanReadDocumentURL() async throws {
        let expectedURL = URL(fileURLWithPath: "/tmp/input.pdf")
        let doc = FixerTestDocument(url: expectedURL)
        #expect(doc.url == expectedURL)
    }

    @Test("fix can read document page count")
    func fixCanReadDocumentPageCount() async throws {
        var doc = FixerTestDocument()
        doc.pageCount = 42
        #expect(doc.pageCount == 42)
    }

    @Test("fix can read document metadata")
    func fixCanReadDocumentMetadata() async throws {
        var doc = FixerTestDocument()
        doc.metadata = DocumentMetadata(title: "Test Doc")
        #expect(doc.metadata?.title == "Test Doc")
    }
}
