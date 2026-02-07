import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("VerificarError Tests")
struct VerificarErrorTests {

    // MARK: - Case Construction

    @Test("parsingFailed case stores URL and reason")
    func parsingFailed() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let error = VerificarError.parsingFailed(url: url, reason: "Invalid header")

        if case .parsingFailed(let capturedURL, let reason) = error {
            #expect(capturedURL == url)
            #expect(reason == "Invalid header")
        } else {
            Issue.record("Expected parsingFailed case")
        }
    }

    @Test("validationFailed case stores reason")
    func validationFailed() {
        let error = VerificarError.validationFailed(reason: "Rule engine crash")

        if case .validationFailed(let reason) = error {
            #expect(reason == "Rule engine crash")
        } else {
            Issue.record("Expected validationFailed case")
        }
    }

    @Test("profileNotFound case stores name")
    func profileNotFound() {
        let error = VerificarError.profileNotFound(name: "pdfua2")

        if case .profileNotFound(let name) = error {
            #expect(name == "pdfua2")
        } else {
            Issue.record("Expected profileNotFound case")
        }
    }

    @Test("encryptedPDF case stores URL")
    func encryptedPDF() {
        let url = URL(fileURLWithPath: "/secure/protected.pdf")
        let error = VerificarError.encryptedPDF(url: url)

        if case .encryptedPDF(let capturedURL) = error {
            #expect(capturedURL == url)
        } else {
            Issue.record("Expected encryptedPDF case")
        }
    }

    @Test("configurationError case stores reason")
    func configurationError() {
        let error = VerificarError.configurationError(reason: "No foundry registered")

        if case .configurationError(let reason) = error {
            #expect(reason == "No foundry registered")
        } else {
            Issue.record("Expected configurationError case")
        }
    }

    @Test("ioError case stores path and reason")
    func ioErrorWithPath() {
        let error = VerificarError.ioError(path: "/tmp/output.pdf", reason: "Disk full")

        if case .ioError(let path, let reason) = error {
            #expect(path == "/tmp/output.pdf")
            #expect(reason == "Disk full")
        } else {
            Issue.record("Expected ioError case")
        }
    }

    @Test("ioError case works with nil path")
    func ioErrorNilPath() {
        let error = VerificarError.ioError(path: nil, reason: "Network unavailable")

        if case .ioError(let path, let reason) = error {
            #expect(path == nil)
            #expect(reason == "Network unavailable")
        } else {
            Issue.record("Expected ioError case")
        }
    }

    // MARK: - Equatable

    @Test("Same parsingFailed errors are equal")
    func parsingFailedEquality() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let e1 = VerificarError.parsingFailed(url: url, reason: "Bad header")
        let e2 = VerificarError.parsingFailed(url: url, reason: "Bad header")

        #expect(e1 == e2)
    }

    @Test("Different parsingFailed reasons are unequal")
    func parsingFailedInequality() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let e1 = VerificarError.parsingFailed(url: url, reason: "Bad header")
        let e2 = VerificarError.parsingFailed(url: url, reason: "Bad trailer")

        #expect(e1 != e2)
    }

    @Test("Different cases are unequal")
    func differentCasesUnequal() {
        let error1 = VerificarError.validationFailed(reason: "test")
        let error2 = VerificarError.configurationError(reason: "test")

        #expect(error1 != error2)
    }

    @Test("Same validationFailed errors are equal")
    func validationFailedEquality() {
        let e1 = VerificarError.validationFailed(reason: "fail")
        let e2 = VerificarError.validationFailed(reason: "fail")

        #expect(e1 == e2)
    }

    @Test("Same profileNotFound errors are equal")
    func profileNotFoundEquality() {
        let e1 = VerificarError.profileNotFound(name: "pdfua1")
        let e2 = VerificarError.profileNotFound(name: "pdfua1")

        #expect(e1 == e2)
    }

    @Test("Same encryptedPDF errors are equal")
    func encryptedPDFEquality() {
        let url = URL(fileURLWithPath: "/test.pdf")
        let e1 = VerificarError.encryptedPDF(url: url)
        let e2 = VerificarError.encryptedPDF(url: url)

        #expect(e1 == e2)
    }

    @Test("Same configurationError errors are equal")
    func configurationErrorEquality() {
        let e1 = VerificarError.configurationError(reason: "bad config")
        let e2 = VerificarError.configurationError(reason: "bad config")

        #expect(e1 == e2)
    }

    @Test("Same ioError errors are equal")
    func ioErrorEquality() {
        let e1 = VerificarError.ioError(path: "/a", reason: "fail")
        let e2 = VerificarError.ioError(path: "/a", reason: "fail")

        #expect(e1 == e2)
    }

    @Test("ioError nil path equality")
    func ioErrorNilPathEquality() {
        let e1 = VerificarError.ioError(path: nil, reason: "fail")
        let e2 = VerificarError.ioError(path: nil, reason: "fail")

        #expect(e1 == e2)
    }

    // MARK: - Error Protocol Conformance

    @Test("VerificarError conforms to Error")
    func conformsToError() {
        let error: any Error = VerificarError.validationFailed(reason: "test")
        #expect(error is VerificarError)
    }

    @Test("Can be thrown and caught")
    func throwAndCatch() {
        func throwingFunction() throws {
            throw VerificarError.profileNotFound(name: "pdfua2")
        }

        do {
            try throwingFunction()
            Issue.record("Should have thrown")
        } catch let error as VerificarError {
            if case .profileNotFound(let name) = error {
                #expect(name == "pdfua2")
            } else {
                Issue.record("Wrong error case")
            }
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: - LocalizedError

    @Test("parsingFailed has localized description")
    func parsingFailedDescription() {
        let url = URL(fileURLWithPath: "/tmp/doc.pdf")
        let error = VerificarError.parsingFailed(url: url, reason: "corrupt xref")

        #expect(error.errorDescription?.contains("doc.pdf") == true)
        #expect(error.errorDescription?.contains("corrupt xref") == true)
    }

    @Test("validationFailed has localized description")
    func validationFailedDescription() {
        let error = VerificarError.validationFailed(reason: "engine error")

        #expect(error.errorDescription?.contains("engine error") == true)
        #expect(error.errorDescription?.contains("Validation failed") == true)
    }

    @Test("profileNotFound has localized description")
    func profileNotFoundDescription() {
        let error = VerificarError.profileNotFound(name: "pdfua2")

        #expect(error.errorDescription?.contains("pdfua2") == true)
        #expect(error.errorDescription?.contains("not found") == true)
    }

    @Test("encryptedPDF has localized description")
    func encryptedPDFDescription() {
        let url = URL(fileURLWithPath: "/tmp/secret.pdf")
        let error = VerificarError.encryptedPDF(url: url)

        #expect(error.errorDescription?.contains("secret.pdf") == true)
        #expect(error.errorDescription?.contains("encrypted") == true)
    }

    @Test("configurationError has localized description")
    func configurationErrorDescription() {
        let error = VerificarError.configurationError(reason: "missing foundry")

        #expect(error.errorDescription?.contains("missing foundry") == true)
        #expect(error.errorDescription?.contains("Configuration") == true)
    }

    @Test("ioError with path has localized description")
    func ioErrorWithPathDescription() {
        let error = VerificarError.ioError(path: "/tmp/file.pdf", reason: "disk full")

        #expect(error.errorDescription?.contains("/tmp/file.pdf") == true)
        #expect(error.errorDescription?.contains("disk full") == true)
    }

    @Test("ioError without path has localized description")
    func ioErrorWithoutPathDescription() {
        let error = VerificarError.ioError(path: nil, reason: "generic failure")

        #expect(error.errorDescription?.contains("generic failure") == true)
        #expect(error.errorDescription?.contains("I/O error") == true)
    }

    // MARK: - CustomStringConvertible

    @Test("description matches errorDescription")
    func descriptionMatchesErrorDescription() {
        let error = VerificarError.validationFailed(reason: "test")

        #expect(error.description == error.errorDescription)
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let error = VerificarError.parsingFailed(
            url: URL(fileURLWithPath: "/tmp/test.pdf"),
            reason: "bad"
        )

        let result = await Task {
            error
        }.value

        #expect(result == error)
    }

    // MARK: - Exhaustiveness

    @Test("All 6 cases exist")
    func allCasesExist() {
        // Verify we can construct all 6 cases
        let cases: [VerificarError] = [
            .parsingFailed(url: URL(fileURLWithPath: "/a"), reason: "r"),
            .validationFailed(reason: "r"),
            .profileNotFound(name: "n"),
            .encryptedPDF(url: URL(fileURLWithPath: "/a")),
            .configurationError(reason: "r"),
            .ioError(path: nil, reason: "r"),
        ]

        #expect(cases.count == 6)

        // Verify they are all different
        for i in 0..<cases.count {
            for j in (i + 1)..<cases.count {
                #expect(cases[i] != cases[j])
            }
        }
    }
}
