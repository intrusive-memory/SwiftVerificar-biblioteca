import Foundation
import SwiftVerificarValidationProfiles

/// A parsed PDF document ready for validation.
///
/// This protocol defines the contract that a parsed PDF document must
/// satisfy for the validation engine to evaluate rules against it.
/// The parser (``PDFParser``) produces a conforming value, and the
/// validator (``PDFValidator``) consumes it.
///
/// ## Relationship to Other Packages
///
/// The actual parsing logic lives in `SwiftVerificar-parser`. This
/// protocol lives in `SwiftVerificar-biblioteca` because it is the
/// integration-layer contract that connects the parser output to the
/// validation input.
///
/// ## Java-to-Swift Mapping
///
/// This protocol consolidates several Java interfaces from veraPDF:
///
/// | Java Class               | Swift Mapping                        |
/// |-------------------------|--------------------------------------|
/// | `PDFAParser.getParsedDocument()` | ``ParsedDocument`` protocol   |
/// | `GFCosDocument` (partially)      | Via ``objects(ofType:)``      |
/// | `GFPDDocument` (partially)       | Via ``metadata`` / ``pageCount`` |
///
/// ## Thread Safety
///
/// All conforming types must be `Sendable`.
public protocol ParsedDocument: Sendable {

    /// The URL of the PDF document that was parsed.
    var url: URL { get }

    /// The detected PDF flavour (e.g., `.pdfUA2`, `.pdfA2b`), if any.
    ///
    /// Returns `nil` if the document does not declare a conformance
    /// level via XMP metadata or other identification mechanisms.
    var flavour: PDFFlavour? { get }

    /// The number of pages in the document.
    ///
    /// Returns `0` if the page count could not be determined.
    var pageCount: Int { get }

    /// Document-level metadata, if available.
    ///
    /// This includes the document's title, author, creation date,
    /// and other information dictionary and XMP metadata values.
    /// Returns `nil` if no metadata could be extracted.
    var metadata: DocumentMetadata? { get }

    /// Whether the document has a structure tree root.
    ///
    /// A structure tree is required for tagged PDFs (PDF/UA).
    /// This is a lightweight check that avoids fully parsing the
    /// structure tree.
    var hasStructureTree: Bool { get }

    /// Returns all validation objects of the specified type.
    ///
    /// The `objectType` string corresponds to the `object` attribute
    /// in validation profile rules (e.g., "CosDocument", "PDPage",
    /// "SEFigure"). The validator uses this to find all objects that
    /// a given rule should be evaluated against.
    ///
    /// - Parameter objectType: The type identifier to query.
    /// - Returns: An array of validation objects matching the type.
    func objects(ofType objectType: String) -> [any ValidationObject]
}

/// A PDF object that can be validated against profile rules.
///
/// Each `ValidationObject` exposes a dictionary of properties
/// that the rule expression evaluator reads when checking whether
/// the object satisfies a rule's test expression.
public protocol ValidationObject: Sendable {

    /// The properties of this object available for rule evaluation.
    ///
    /// Keys are property names as they appear in the validation profile
    /// rule test expressions. Values are the property values.
    var validationProperties: [String: String] { get }

    /// The location of this object within the PDF document.
    ///
    /// Used to populate the ``PDFLocation`` in ``TestAssertion``
    /// results so the user can find the flagged element.
    var location: PDFLocation? { get }
}

/// Document-level metadata extracted from a parsed PDF.
///
/// Contains information from the PDF's Info dictionary and/or
/// XMP metadata packet. This struct provides the metadata that
/// the validation engine and feature extractor need without
/// exposing the raw XMP XML or COS dictionary.
///
/// ## Java-to-Swift Mapping
///
/// | Java Class                | Swift Mapping                  |
/// |--------------------------|--------------------------------|
/// | `InfoDictionary`          | ``DocumentMetadata`` fields    |
/// | `XMPMetadata` (partial)   | ``DocumentMetadata`` fields    |
public struct DocumentMetadata: Sendable, Equatable, Codable {

    /// The document title.
    public let title: String?

    /// The document author.
    public let author: String?

    /// The document subject.
    public let subject: String?

    /// Keywords associated with the document.
    public let keywords: String?

    /// The name of the application that created the original document.
    public let creator: String?

    /// The name of the application that produced the PDF.
    public let producer: String?

    /// The document creation date.
    public let creationDate: Date?

    /// The date the document was last modified.
    public let modificationDate: Date?

    /// Whether the document contains XMP metadata.
    public let hasXMPMetadata: Bool

    /// Creates a new `DocumentMetadata`.
    ///
    /// All parameters are optional because not every PDF contains
    /// all metadata fields.
    ///
    /// - Parameters:
    ///   - title: The document title.
    ///   - author: The document author.
    ///   - subject: The document subject.
    ///   - keywords: Keywords associated with the document.
    ///   - creator: The application that created the original document.
    ///   - producer: The application that produced the PDF.
    ///   - creationDate: The document creation date.
    ///   - modificationDate: The date the document was last modified.
    ///   - hasXMPMetadata: Whether the document contains XMP metadata.
    public init(
        title: String? = nil,
        author: String? = nil,
        subject: String? = nil,
        keywords: String? = nil,
        creator: String? = nil,
        producer: String? = nil,
        creationDate: Date? = nil,
        modificationDate: Date? = nil,
        hasXMPMetadata: Bool = false
    ) {
        self.title = title
        self.author = author
        self.subject = subject
        self.keywords = keywords
        self.creator = creator
        self.producer = producer
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.hasXMPMetadata = hasXMPMetadata
    }
}

// MARK: - CustomStringConvertible

extension DocumentMetadata: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        if let title { parts.append("title=\"\(title)\"") }
        if let author { parts.append("author=\"\(author)\"") }
        if hasXMPMetadata { parts.append("xmp=true") }
        if parts.isEmpty {
            return "DocumentMetadata(empty)"
        }
        return "DocumentMetadata(\(parts.joined(separator: ", ")))"
    }
}

// MARK: - Hashable

extension DocumentMetadata: Hashable {}
