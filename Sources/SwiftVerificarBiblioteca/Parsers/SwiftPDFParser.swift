import Foundation
import PDFKit
import SwiftVerificarValidationProfiles

/// Default Swift implementation of the ``PDFParser`` protocol.
///
/// `SwiftPDFParser` is the concrete parser that uses Apple's `PDFKit`
/// framework to parse PDF documents and extract metadata, page count,
/// and structure tree information. It produces a ``ParsedDocumentAdapter``
/// that the validation engine can evaluate rules against.
///
/// ## Java-to-Swift Mapping
///
/// | Java Class        | Swift Mapping                         |
/// |------------------|---------------------------------------|
/// | `GFModelParser`   | `SwiftPDFParser` struct               |
///
/// ## Parsing Strategy
///
/// This implementation uses `PDFKit.PDFDocument` (macOS/iOS framework)
/// for reliable PDF parsing. The `SwiftVerificarParser` package's
/// `PDFDocumentParser` will be wired in a future sprint when its
/// low-level COS object parsing is more mature.
///
/// ## Thread Safety
///
/// `SwiftPDFParser` is a value type (`struct`) with no mutable
/// state, and conforms to `Sendable`.
///
/// ## Usage
///
/// ```swift
/// let parser = SwiftPDFParser(url: pdfURL)
/// let document = try await parser.parse()
/// let flavour = try await parser.detectFlavour()
/// ```
public struct SwiftPDFParser: PDFParser, Sendable, Equatable {

    /// The URL of the PDF document to be parsed.
    public let url: URL

    /// Creates a new `SwiftPDFParser` for the given document URL.
    ///
    /// - Parameter url: The file URL of the PDF document to parse.
    public init(url: URL) {
        self.url = url
    }

    // MARK: - PDFParser

    /// Parse the PDF document.
    ///
    /// Reads the PDF file at ``url`` using `PDFKit.PDFDocument`, extracts
    /// metadata, page count, and structure tree information, and returns
    /// a ``ParsedDocumentAdapter``.
    ///
    /// - Returns: A ``ParsedDocument`` representing the parsed PDF.
    /// - Throws: ``VerificarError/parsingFailed(url:reason:)`` if the file
    ///   cannot be read or is not a valid PDF.
    /// - Throws: ``VerificarError/encryptedPDF(url:)`` if the document
    ///   is encrypted and locked.
    public func parse() async throws -> any ParsedDocument {
        let pdfDocument = try loadPDFDocument()

        let pageCount = pdfDocument.pageCount
        let metadata = extractMetadata(from: pdfDocument)
        let hasStructureTree = checkStructureTree(in: pdfDocument)
        let flavour = detectFlavourFromMetadata(pdfDocument)

        return ParsedDocumentAdapter(
            url: url,
            flavour: flavour,
            pageCount: pageCount,
            metadata: metadata,
            hasStructureTree: hasStructureTree
        )
    }

    /// Detect the PDF flavour from the document's metadata.
    ///
    /// Inspects the document's XMP metadata and Info dictionary to
    /// determine whether it declares conformance to a specific PDF
    /// standard (e.g., PDF/A-2b, PDF/UA-1).
    ///
    /// - Returns: A ``PDFFlavour`` value, or `nil` if no flavour can be detected.
    /// - Throws: ``VerificarError/parsingFailed(url:reason:)`` if the
    ///   metadata cannot be read.
    /// - Throws: ``VerificarError/encryptedPDF(url:)`` if the document
    ///   is encrypted and locked.
    public func detectFlavour() async throws -> PDFFlavour? {
        let pdfDocument = try loadPDFDocument()
        return detectFlavourFromMetadata(pdfDocument)
    }

    // MARK: - Private Helpers

    /// Load the PDF document from the URL, handling errors.
    ///
    /// - Returns: A loaded `PDFKit.PDFDocument`.
    /// - Throws: ``VerificarError/parsingFailed(url:reason:)`` or
    ///   ``VerificarError/encryptedPDF(url:)``.
    private func loadPDFDocument() throws -> PDFKit.PDFDocument {
        // Check that the file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw VerificarError.parsingFailed(
                url: url,
                reason: "File not found at path: \(url.path)"
            )
        }

        // Attempt to load the PDF data
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw VerificarError.parsingFailed(
                url: url,
                reason: "Failed to read file data: \(error.localizedDescription)"
            )
        }

        // Attempt to create a PDFKit document
        guard let pdfDocument = PDFKit.PDFDocument(data: data) else {
            throw VerificarError.parsingFailed(
                url: url,
                reason: "File is not a valid PDF or could not be parsed"
            )
        }

        // Check if the document is encrypted and locked
        if pdfDocument.isEncrypted && pdfDocument.isLocked {
            throw VerificarError.encryptedPDF(url: url)
        }

        return pdfDocument
    }

    /// Extract document-level metadata from a PDFKit document.
    ///
    /// - Parameter pdfDocument: The loaded PDFKit document.
    /// - Returns: A ``DocumentMetadata`` struct, or `nil` if no metadata is available.
    private func extractMetadata(from pdfDocument: PDFKit.PDFDocument) -> DocumentMetadata? {
        let attributes = pdfDocument.documentAttributes

        let title = attributes?[PDFDocumentAttribute.titleAttribute] as? String
        let author = attributes?[PDFDocumentAttribute.authorAttribute] as? String
        let subject = attributes?[PDFDocumentAttribute.subjectAttribute] as? String
        let keywords = attributes?[PDFDocumentAttribute.keywordsAttribute] as? String
        let creator = attributes?[PDFDocumentAttribute.creatorAttribute] as? String
        let producer = attributes?[PDFDocumentAttribute.producerAttribute] as? String
        let creationDate = attributes?[PDFDocumentAttribute.creationDateAttribute] as? Date
        let modificationDate = attributes?[PDFDocumentAttribute.modificationDateAttribute] as? Date

        // Check for XMP metadata by looking for the metadata stream in the catalog
        // PDFKit doesn't expose XMP directly, so we check if the document
        // has any metadata at all as a proxy
        let hasXMP = hasXMPMetadata(in: pdfDocument)

        // Only return metadata if at least something is populated
        if title == nil && author == nil && subject == nil && keywords == nil
            && creator == nil && producer == nil
            && creationDate == nil && modificationDate == nil && !hasXMP
        {
            return nil
        }

        return DocumentMetadata(
            title: title,
            author: author,
            subject: subject,
            keywords: keywords,
            creator: creator,
            producer: producer,
            creationDate: creationDate,
            modificationDate: modificationDate,
            hasXMPMetadata: hasXMP
        )
    }

    /// Check whether the PDF document has a structure tree root.
    ///
    /// Uses the PDFKit document's outline as a proxy for structure tree
    /// presence. A more accurate check would inspect the StructTreeRoot
    /// entry in the document catalog, which requires lower-level parsing.
    ///
    /// - Parameter pdfDocument: The loaded PDFKit document.
    /// - Returns: `true` if the document appears to have a structure tree.
    private func checkStructureTree(in pdfDocument: PDFKit.PDFDocument) -> Bool {
        // PDFKit doesn't expose the StructTreeRoot directly.
        // The outline (bookmarks) is a different concept, but for Sprint 1
        // we use it as a basic indicator. A more thorough check will be
        // implemented when the SwiftVerificarParser is fully wired.
        return pdfDocument.outlineRoot != nil
    }

    /// Check whether the document contains XMP metadata.
    ///
    /// Searches the raw PDF data for the XMP metadata packet markers.
    ///
    /// - Parameter pdfDocument: The loaded PDFKit document.
    /// - Returns: `true` if XMP metadata markers are found.
    private func hasXMPMetadata(in pdfDocument: PDFKit.PDFDocument) -> Bool {
        // Attempt to detect XMP by checking for the xpacket marker in the raw data
        guard let data = try? Data(contentsOf: url) else { return false }
        let xpacketBegin = Data("<?xpacket begin".utf8)
        return data.range(of: xpacketBegin) != nil
    }

    /// Detect the PDF flavour from a loaded PDFKit document's metadata.
    ///
    /// Searches the raw PDF data for XMP metadata containing PDF/A or PDF/UA
    /// identification schemas and maps them to ``PDFFlavour`` values.
    ///
    /// - Parameter pdfDocument: The loaded PDFKit document.
    /// - Returns: A ``PDFFlavour``, or `nil` if none detected.
    private func detectFlavourFromMetadata(_ pdfDocument: PDFKit.PDFDocument) -> PDFFlavour? {
        // Try to find XMP data in the file and extract flavour information
        guard let data = try? Data(contentsOf: url),
              let xmpString = extractXMPString(from: data)
        else {
            return nil
        }

        // Try to parse with the biblioteca XMPParser
        let xmpParser = XMPParser()
        guard let xmpMetadata = try? xmpParser.parse(from: xmpString) else {
            return nil
        }

        // Check for PDF/UA identification first (more specific)
        if let pdfua = xmpMetadata.pdfuaIdentification {
            switch pdfua.part {
            case 1: return .pdfUA1
            case 2: return .pdfUA2
            default: break
            }
        }

        // Check for PDF/A identification
        if let pdfa = xmpMetadata.pdfaIdentification {
            return mapPDFAToFlavour(part: pdfa.part, conformance: pdfa.conformance)
        }

        return nil
    }

    /// Extract the XMP metadata string from raw PDF data.
    ///
    /// Searches for the `<?xpacket begin` and `<?xpacket end` markers
    /// and returns the content between them.
    ///
    /// - Parameter data: The raw PDF file data.
    /// - Returns: The XMP metadata string, or `nil` if not found.
    private func extractXMPString(from data: Data) -> String? {
        let beginMarker = Data("<?xpacket begin".utf8)
        let endMarker = Data("<?xpacket end".utf8)

        guard let beginRange = data.range(of: beginMarker) else {
            return nil
        }

        // Find the end of the xpacket begin processing instruction
        guard let endRange = data.range(of: endMarker, in: beginRange.lowerBound..<data.endIndex) else {
            return nil
        }

        // Include a bit past the end marker to get the closing ?>
        let endSearchLimit = min(endRange.upperBound + 100, data.endIndex)
        let closingPI = Data("?>".utf8)
        let closingRange = data.range(of: closingPI, in: endRange.lowerBound..<endSearchLimit)
        let finalEnd = closingRange?.upperBound ?? endRange.upperBound

        let xmpData = data[beginRange.lowerBound..<finalEnd]
        return String(data: xmpData, encoding: .utf8)
    }

    /// Map a PDF/A part number and conformance level to a ``PDFFlavour``.
    ///
    /// - Parameters:
    ///   - part: The PDF/A part number (1, 2, 3, or 4).
    ///   - conformance: The conformance level string (e.g., "a", "b", "u").
    /// - Returns: The corresponding ``PDFFlavour``, or `nil` if the combination is unknown.
    private func mapPDFAToFlavour(part: Int, conformance: String) -> PDFFlavour? {
        let level = conformance.lowercased()
        switch (part, level) {
        case (1, "a"): return .pdfA1a
        case (1, "b"): return .pdfA1b
        case (2, "a"): return .pdfA2a
        case (2, "b"): return .pdfA2b
        case (2, "u"): return .pdfA2u
        case (3, "a"): return .pdfA3a
        case (3, "b"): return .pdfA3b
        case (3, "u"): return .pdfA3u
        case (4, ""): return .pdfA4
        case (4, "e"): return .pdfA4e
        case (4, "f"): return .pdfA4f
        default: return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: SwiftPDFParser, rhs: SwiftPDFParser) -> Bool {
        lhs.url == rhs.url
    }
}

// MARK: - ValidatorComponent

extension SwiftPDFParser: ValidatorComponent {
    /// Component metadata for this parser.
    public var info: ComponentInfo {
        ComponentInfo(
            name: "SwiftPDFParser",
            version: SwiftVerificarBiblioteca.version,
            componentDescription: "PDF document parser for: \(url.lastPathComponent)",
            provider: "SwiftVerificar Project"
        )
    }
}

// MARK: - CustomStringConvertible

extension SwiftPDFParser: CustomStringConvertible {
    public var description: String {
        "SwiftPDFParser(url: \(url.lastPathComponent))"
    }
}
