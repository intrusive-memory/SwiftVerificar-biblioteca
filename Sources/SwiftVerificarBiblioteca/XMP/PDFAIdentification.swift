import Foundation

/// PDF/A identification schema extracted from XMP metadata.
///
/// `PDFAIdentification` represents the `pdfaid` XMP schema that identifies
/// a document's PDF/A conformance level. It consolidates the Java
/// `AXLPDFAIdentification` class from veraPDF-library.
///
/// The `part` indicates which part of the PDF/A standard the document conforms to:
/// - 1: PDF/A-1 (ISO 19005-1)
/// - 2: PDF/A-2 (ISO 19005-2)
/// - 3: PDF/A-3 (ISO 19005-3)
/// - 4: PDF/A-4 (ISO 19005-4)
///
/// The `conformance` indicates the conformance level:
/// - "a": Level A (accessible)
/// - "b": Level B (basic)
/// - "u": Level U (Unicode)
/// - "e": Level E (engineering)
/// - "f": Level F (file attachments)
///
/// ## Example
/// ```swift
/// let id = PDFAIdentification(part: 2, conformance: "u")
/// print(id.displayName)  // "PDF/A-2u"
/// ```
public struct PDFAIdentification: Sendable, Codable, Equatable, Hashable {

    /// The PDF/A part number (1, 2, 3, or 4).
    public let part: Int

    /// The conformance level string (e.g., "a", "b", "u", "e", "f").
    public let conformance: String

    /// An optional amendment identifier.
    public let amendment: String?

    /// An optional revision identifier.
    public let revision: String?

    /// Creates a PDF/A identification schema.
    ///
    /// - Parameters:
    ///   - part: The PDF/A part number (1, 2, 3, or 4).
    ///   - conformance: The conformance level string.
    ///   - amendment: An optional amendment identifier. Defaults to `nil`.
    ///   - revision: An optional revision identifier. Defaults to `nil`.
    public init(
        part: Int,
        conformance: String,
        amendment: String? = nil,
        revision: String? = nil
    ) {
        self.part = part
        self.conformance = conformance
        self.amendment = amendment
        self.revision = revision
    }

    /// A human-readable display name for this PDF/A identification.
    ///
    /// For example, part 2 with conformance "u" produces "PDF/A-2u".
    public var displayName: String {
        var name = "PDF/A-\(part)\(conformance)"
        if let amendment {
            name += " (Amendment \(amendment))"
        }
        return name
    }

    /// Whether the part number is a valid PDF/A part (1, 2, 3, or 4).
    public var isValidPart: Bool {
        (1...4).contains(part)
    }

    /// The set of valid conformance level strings.
    public static let validConformanceLevels: Set<String> = ["a", "b", "u", "e", "f"]

    /// Whether the conformance level is a recognized PDF/A conformance string.
    public var isValidConformance: Bool {
        Self.validConformanceLevels.contains(conformance.lowercased())
    }

    /// Whether both part and conformance are valid.
    public var isValid: Bool {
        isValidPart && isValidConformance
    }
}

// MARK: - CustomStringConvertible

extension PDFAIdentification: CustomStringConvertible {
    public var description: String {
        var desc = "PDFAIdentification(part: \(part), conformance: \"\(conformance)\""
        if let amendment {
            desc += ", amendment: \"\(amendment)\""
        }
        if let revision {
            desc += ", revision: \"\(revision)\""
        }
        desc += ")"
        return desc
    }
}
