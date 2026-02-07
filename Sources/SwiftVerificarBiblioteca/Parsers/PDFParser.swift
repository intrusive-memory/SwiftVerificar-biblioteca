import Foundation
import SwiftVerificarValidationProfiles

/// Protocol for PDF document parsers.
///
/// A `PDFParser` reads a PDF file from disk and produces a
/// ``ParsedDocument`` that the validation engine can evaluate
/// rules against. It also supports flavour detection, which
/// determines the document's declared conformance level
/// (e.g., PDF/A-2b, PDF/UA-1) by inspecting XMP metadata or
/// other identification mechanisms.
///
/// This protocol is the Swift equivalent of Java's `PDFAParser`
/// interface in veraPDF-library:
///
/// | Java Class       | Swift Mapping                    |
/// |-----------------|----------------------------------|
/// | `PDFAParser`     | `PDFParser` protocol             |
/// | `GFModelParser`  | ``SwiftPDFParser`` (concrete)    |
///
/// ## Thread Safety
///
/// All conforming types must be `Sendable`. The `parse()` and
/// `detectFlavour()` methods are asynchronous to support
/// long-running I/O operations.
///
/// ## Usage
///
/// ```swift
/// let parser: any PDFParser = SwiftPDFParser(url: pdfURL)
/// let document = try await parser.parse()
/// let flavour = try await parser.detectFlavour()
/// ```
public protocol PDFParser: Sendable {

    /// The URL of the PDF document to be parsed.
    ///
    /// This is the file URL that was provided when the parser was
    /// created. It does not change over the parser's lifetime.
    var url: URL { get }

    /// Parse the PDF document and return a validation-ready representation.
    ///
    /// The returned ``ParsedDocument`` contains the document's structural
    /// and content information needed by the validation engine to evaluate
    /// profile rules.
    ///
    /// - Returns: A parsed document ready for validation.
    /// - Throws: ``VerificarError/parsingFailed(url:reason:)`` if the
    ///   document cannot be read or interpreted.
    /// - Throws: ``VerificarError/encryptedPDF(url:)`` if the document
    ///   is encrypted and cannot be parsed without a password.
    func parse() async throws -> any ParsedDocument

    /// Detect the PDF flavour declared by the document.
    ///
    /// Inspects XMP metadata and other identification markers to determine
    /// whether the document declares conformance to a specific PDF standard
    /// (e.g., PDF/A-2b, PDF/UA-1, PDF/UA-2).
    ///
    /// - Returns: A ``PDFFlavour`` value (e.g., `.pdfUA2`, `.pdfA2b`),
    ///   or `nil` if no flavour can be detected.
    /// - Throws: ``VerificarError/parsingFailed(url:reason:)`` if the
    ///   metadata cannot be read.
    func detectFlavour() async throws -> PDFFlavour?
}
