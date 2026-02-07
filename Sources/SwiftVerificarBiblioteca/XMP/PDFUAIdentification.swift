import Foundation

/// PDF/UA identification schema extracted from XMP metadata.
///
/// `PDFUAIdentification` represents the `pdfuaid` XMP schema that identifies
/// a document's PDF/UA conformance level. It consolidates the Java
/// `AXLPDFUAIdentification` class from veraPDF-library.
///
/// The `part` indicates which part of the PDF/UA standard the document conforms to:
/// - 1: PDF/UA-1 (ISO 14289-1)
/// - 2: PDF/UA-2 (ISO 14289-2)
///
/// ## Example
/// ```swift
/// let id = PDFUAIdentification(part: 2)
/// print(id.displayName)  // "PDF/UA-2"
/// ```
public struct PDFUAIdentification: Sendable, Codable, Equatable, Hashable {

    /// The PDF/UA part number (1 or 2).
    public let part: Int

    /// An optional revision identifier.
    public let revision: String?

    /// Creates a PDF/UA identification schema.
    ///
    /// - Parameters:
    ///   - part: The PDF/UA part number (1 or 2).
    ///   - revision: An optional revision identifier. Defaults to `nil`.
    public init(part: Int, revision: String? = nil) {
        self.part = part
        self.revision = revision
    }

    /// A human-readable display name for this PDF/UA identification.
    ///
    /// For example, part 2 produces "PDF/UA-2".
    public var displayName: String {
        var name = "PDF/UA-\(part)"
        if let revision {
            name += " (Revision \(revision))"
        }
        return name
    }

    /// Whether the part number is a valid PDF/UA part (1 or 2).
    public var isValidPart: Bool {
        part == 1 || part == 2
    }
}

// MARK: - CustomStringConvertible

extension PDFUAIdentification: CustomStringConvertible {
    public var description: String {
        var desc = "PDFUAIdentification(part: \(part)"
        if let revision {
            desc += ", revision: \"\(revision)\""
        }
        desc += ")"
        return desc
    }
}
