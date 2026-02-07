import Foundation

/// Protocol for PDF document validators.
///
/// A `PDFValidator` evaluates a parsed PDF document against a set of
/// validation rules (identified by a profile name) and produces a
/// ``ValidationResult`` containing individual ``TestAssertion`` outcomes.
///
/// This protocol consolidates several Java classes from veraPDF-library:
///
/// | Java Class           | Swift Mapping                        |
/// |---------------------|--------------------------------------|
/// | `PDFAValidator`      | `PDFValidator` protocol              |
/// | `BaseValidator`      | Implementation detail (internal)     |
/// | `FastFailValidator`  | Controlled via `ValidatorConfig`     |
/// | `FlavourValidator`   | Implementation detail (internal)     |
/// | `ValidatorFactory`   | Part of ``Foundry``                  |
///
/// ## Thread Safety
///
/// All conforming types must be `Sendable`. The `validate` methods are
/// asynchronous to support long-running validation operations and
/// potential parallelism within the validation engine.
///
/// ## Usage
///
/// ```swift
/// let validator: any PDFValidator = SwiftPDFValidator(
///     profileName: "PDF/UA-2",
///     config: ValidatorConfig()
/// )
/// let result = try await validator.validate(contentsOf: pdfURL)
/// print(result.isCompliant)
/// ```
public protocol PDFValidator: Sendable {

    /// The name of the validation profile being used.
    ///
    /// This identifies the set of rules the validator evaluates
    /// (e.g., "PDF/UA-2 validation profile", "PDF/A-2b").
    var profileName: String { get }

    /// The configuration controlling validator behavior.
    var config: ValidatorConfig { get }

    /// Validate a pre-parsed PDF document.
    ///
    /// This is the primary validation entry point when the caller
    /// has already parsed the document using a `PDFParser`.
    ///
    /// - Parameter document: A parsed PDF document conforming to
    ///   ``ParsedDocument``.
    /// - Returns: A ``ValidationResult`` with all assertions.
    /// - Throws: ``VerificarError`` if the validation engine
    ///   encounters an internal error (distinct from the document
    ///   being non-compliant).
    func validate(_ document: any ParsedDocument) async throws -> ValidationResult

    /// Validate a PDF document from a file URL.
    ///
    /// This convenience method parses and validates in one step.
    /// Implementations typically delegate to a parser internally.
    ///
    /// - Parameter url: The file URL of the PDF document.
    /// - Returns: A ``ValidationResult`` with all assertions.
    /// - Throws: ``VerificarError/parsingFailed(url:reason:)`` if
    ///   the document cannot be parsed, or other ``VerificarError``
    ///   cases for validation engine failures.
    func validate(contentsOf url: URL) async throws -> ValidationResult
}
