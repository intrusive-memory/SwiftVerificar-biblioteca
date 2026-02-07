import Foundation

/// A location within a PDF document where a validation assertion applies.
///
/// This struct pinpoints where in a PDF document a particular rule was
/// evaluated. It may reference any combination of a COS-level object key,
/// a page number, a structure element identifier, and a content path
/// through the logical document structure.
///
/// This is the Swift equivalent of Java's `Location` interface and
/// `LocationImpl` class in veraPDF-library, consolidated into a single
/// value type.
///
/// ## Example
/// ```swift
/// let location = PDFLocation(
///     objectKey: "42 0 obj",
///     pageNumber: 3,
///     structureID: "SE-17",
///     contentPath: "/Document/Part/P[3]"
/// )
/// ```
public struct PDFLocation: Sendable, Equatable, Codable, Hashable {

    /// The COS-level object key (e.g., "42 0 obj").
    ///
    /// This identifies the low-level PDF object associated with the assertion.
    /// May be `nil` if the assertion is not tied to a specific object.
    public let objectKey: String?

    /// The 1-based page number where the assertion applies.
    ///
    /// May be `nil` for document-level assertions that are not page-specific.
    public let pageNumber: Int?

    /// The structure element identifier within the document's structure tree.
    ///
    /// May be `nil` if the assertion is not related to a structure element.
    public let structureID: String?

    /// The path through the logical document structure (e.g., "/Document/Part/P[3]").
    ///
    /// This is similar to an XPath expression locating the element within
    /// the tagged structure tree. May be `nil` if not applicable.
    public let contentPath: String?

    /// Creates a new `PDFLocation`.
    ///
    /// All parameters are optional because not every assertion applies to
    /// every level of the document hierarchy.
    ///
    /// - Parameters:
    ///   - objectKey: The COS-level object key (e.g., "42 0 obj").
    ///   - pageNumber: The 1-based page number.
    ///   - structureID: The structure element identifier.
    ///   - contentPath: The path through the logical structure.
    public init(
        objectKey: String? = nil,
        pageNumber: Int? = nil,
        structureID: String? = nil,
        contentPath: String? = nil
    ) {
        self.objectKey = objectKey
        self.pageNumber = pageNumber
        self.structureID = structureID
        self.contentPath = contentPath
    }

    /// Whether this location has any identifying information.
    ///
    /// Returns `false` if all fields are `nil`.
    public var isEmpty: Bool {
        objectKey == nil && pageNumber == nil && structureID == nil && contentPath == nil
    }
}

// MARK: - CustomStringConvertible

extension PDFLocation: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        if let objectKey {
            parts.append("obj=\(objectKey)")
        }
        if let pageNumber {
            parts.append("page=\(pageNumber)")
        }
        if let structureID {
            parts.append("se=\(structureID)")
        }
        if let contentPath {
            parts.append("path=\(contentPath)")
        }
        if parts.isEmpty {
            return "PDFLocation(empty)"
        }
        return "PDFLocation(\(parts.joined(separator: ", ")))"
    }
}
