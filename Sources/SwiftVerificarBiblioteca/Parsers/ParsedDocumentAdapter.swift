import Foundation
import SwiftVerificarValidationProfiles

/// A concrete ``ParsedDocument`` implementation that wraps parsing output.
///
/// `ParsedDocumentAdapter` bridges the gap between the parser's raw output
/// and the ``ParsedDocument`` protocol that the validation engine consumes.
/// It stores pre-computed values for the URL, detected flavour, page count,
/// metadata, structure tree presence, and a dictionary of validation objects
/// keyed by object type.
///
/// ## Usage
///
/// This type is created internally by ``SwiftPDFParser/parse()`` and should
/// not typically be constructed directly by library consumers.
///
/// ```swift
/// let adapter = ParsedDocumentAdapter(
///     url: pdfURL,
///     flavour: .pdfA2b,
///     pageCount: 5,
///     metadata: DocumentMetadata(title: "Test"),
///     hasStructureTree: true
/// )
/// ```
///
/// ## Thread Safety
///
/// `ParsedDocumentAdapter` is a value type (`struct`) with only immutable
/// stored properties. It conforms to `Sendable`.
public struct ParsedDocumentAdapter: ParsedDocument, Sendable {

    /// The URL of the PDF document that was parsed.
    public let url: URL

    /// The detected PDF flavour, if any.
    public let flavour: PDFFlavour?

    /// The number of pages in the document.
    public let pageCount: Int

    /// Document-level metadata, if available.
    public let metadata: DocumentMetadata?

    /// Whether the document has a structure tree root.
    public let hasStructureTree: Bool

    /// Validation objects indexed by object type string.
    ///
    /// The keys correspond to the `object` attribute in validation profile
    /// rules (e.g., "CosDocument", "PDPage"). The parser populates this
    /// dictionary when building the adapter.
    private let objectsByType: [String: [any ValidationObject]]

    /// Creates a new `ParsedDocumentAdapter`.
    ///
    /// - Parameters:
    ///   - url: The URL of the PDF document.
    ///   - flavour: The detected PDF flavour, or `nil` if none detected.
    ///   - pageCount: The number of pages. Defaults to `0`.
    ///   - metadata: Document-level metadata. Defaults to `nil`.
    ///   - hasStructureTree: Whether the document has a structure tree. Defaults to `false`.
    ///   - objectsByType: A dictionary of validation objects keyed by type string. Defaults to empty.
    public init(
        url: URL,
        flavour: PDFFlavour? = nil,
        pageCount: Int = 0,
        metadata: DocumentMetadata? = nil,
        hasStructureTree: Bool = false,
        objectsByType: [String: [any ValidationObject]] = [:]
    ) {
        self.url = url
        self.flavour = flavour
        self.pageCount = pageCount
        self.metadata = metadata
        self.hasStructureTree = hasStructureTree
        self.objectsByType = objectsByType
    }

    /// Returns all validation objects of the specified type.
    ///
    /// Looks up the `objectType` key in the adapter's stored objects dictionary.
    /// For "CosDocument", this returns a single ``CosDocumentObject`` containing
    /// document-level properties. For unrecognised types, returns an empty array.
    ///
    /// - Parameter objectType: The type identifier to query (e.g., "CosDocument", "PDPage").
    /// - Returns: An array of validation objects matching the type, or empty if none.
    public func objects(ofType objectType: String) -> [any ValidationObject] {
        objectsByType[objectType] ?? []
    }
}

// MARK: - CosDocumentObject

/// A ``ValidationObject`` representing the top-level COS document.
///
/// This object exposes document-level properties that validation profile
/// rules for the "CosDocument" object type evaluate against. It corresponds
/// to the Java `GFCosDocument` class in veraPDF.
///
/// ## Properties Exposed
///
/// | Key                     | Description                                     |
/// |-------------------------|-------------------------------------------------|
/// | `nrPages`               | Number of pages in the document                 |
/// | `isEncrypted`           | Whether the document is encrypted ("true"/"false") |
/// | `hasStructTreeRoot`     | Whether a StructTreeRoot is present              |
/// | `isMarked`              | Whether the document's MarkInfo dict has Marked=true |
/// | `pdfVersion`            | The PDF version string (e.g., "1.7", "2.0")     |
/// | `hasXMPMetadata`        | Whether the document contains XMP metadata       |
/// | `title`                 | The document title (or "")                       |
/// | `author`                | The document author (or "")                      |
/// | `producer`              | The PDF producer (or "")                         |
/// | `creator`               | The creating application (or "")                 |
///
/// ## Thread Safety
///
/// `CosDocumentObject` is a value type (`struct`) with only `let`
/// properties. It conforms to `Sendable`.
public struct CosDocumentObject: ValidationObject, Sendable {

    /// The document-level properties for rule evaluation.
    public let validationProperties: [String: String]

    /// The location of this object (document-level, so no specific page).
    public let location: PDFLocation?

    /// Creates a CosDocumentObject with the given document-level properties.
    ///
    /// - Parameters:
    ///   - pageCount: The number of pages.
    ///   - isEncrypted: Whether the document is encrypted.
    ///   - hasStructTreeRoot: Whether the document has a structure tree root.
    ///   - isMarked: Whether the document is marked (MarkInfo dictionary).
    ///   - pdfVersion: The PDF version string (e.g., "1.7").
    ///   - hasXMPMetadata: Whether XMP metadata is present.
    ///   - title: The document title.
    ///   - author: The document author.
    ///   - producer: The PDF producer application.
    ///   - creator: The creator application.
    public init(
        pageCount: Int,
        isEncrypted: Bool = false,
        hasStructTreeRoot: Bool = false,
        isMarked: Bool = false,
        pdfVersion: String = "1.7",
        hasXMPMetadata: Bool = false,
        title: String = "",
        author: String = "",
        producer: String = "",
        creator: String = ""
    ) {
        self.validationProperties = [
            "nrPages": String(pageCount),
            "isEncrypted": String(isEncrypted),
            "hasStructTreeRoot": String(hasStructTreeRoot),
            "isMarked": String(isMarked),
            "pdfVersion": pdfVersion,
            "hasXMPMetadata": String(hasXMPMetadata),
            "title": title,
            "author": author,
            "producer": producer,
            "creator": creator,
        ]
        self.location = PDFLocation()
    }
}
