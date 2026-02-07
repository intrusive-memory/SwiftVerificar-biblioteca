import Foundation
import SwiftVerificarValidationProfiles

/// A concrete ``ParsedDocument`` implementation that wraps parsing output.
///
/// `ParsedDocumentAdapter` bridges the gap between the parser's raw output
/// and the ``ParsedDocument`` protocol that the validation engine consumes.
/// It stores pre-computed values for the URL, detected flavour, page count,
/// metadata, and structure tree presence.
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

    /// Creates a new `ParsedDocumentAdapter`.
    ///
    /// - Parameters:
    ///   - url: The URL of the PDF document.
    ///   - flavour: The detected PDF flavour, or `nil` if none detected.
    ///   - pageCount: The number of pages. Defaults to `0`.
    ///   - metadata: Document-level metadata. Defaults to `nil`.
    ///   - hasStructureTree: Whether the document has a structure tree. Defaults to `false`.
    public init(
        url: URL,
        flavour: PDFFlavour? = nil,
        pageCount: Int = 0,
        metadata: DocumentMetadata? = nil,
        hasStructureTree: Bool = false
    ) {
        self.url = url
        self.flavour = flavour
        self.pageCount = pageCount
        self.metadata = metadata
        self.hasStructureTree = hasStructureTree
    }

    /// Returns all validation objects of the specified type.
    ///
    /// Currently returns an empty array for all object types.
    /// Full object model traversal will be implemented in a future sprint.
    ///
    /// - Parameter objectType: The type identifier to query.
    /// - Returns: An empty array (Sprint 2 will flesh this out).
    public func objects(ofType objectType: String) -> [any ValidationObject] {
        []
    }
}
