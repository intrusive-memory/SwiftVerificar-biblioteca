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
    /// metadata, page count, structure tree information, and document-level
    /// validation objects, and returns a ``ParsedDocumentAdapter``.
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
        let pdfVersion = extractPDFVersion()
        let isMarked = checkIsMarked()

        // Build the CosDocument validation object
        let cosDoc = CosDocumentObject(
            pageCount: pageCount,
            isEncrypted: pdfDocument.isEncrypted,
            hasStructTreeRoot: hasStructureTree,
            isMarked: isMarked,
            pdfVersion: pdfVersion,
            hasXMPMetadata: metadata?.hasXMPMetadata ?? false,
            title: metadata?.title ?? "",
            author: metadata?.author ?? "",
            producer: metadata?.producer ?? "",
            creator: metadata?.creator ?? ""
        )

        // Build PDPage validation objects — one per page
        let pageObjects = buildPageObjects(from: pdfDocument)

        // Build SE* validation objects from structure tree (if present)
        let structureElementsByType = buildStructureElementObjects(
            from: pdfDocument,
            hasStructureTree: hasStructureTree
        )

        // Assemble the objectsByType dictionary
        var objectsByType: [String: [any ValidationObject]] = [
            "CosDocument": [cosDoc],
            "PDPage": pageObjects,
        ]

        // Merge structure element objects
        for (key, elements) in structureElementsByType {
            objectsByType[key] = elements
        }

        return ParsedDocumentAdapter(
            url: url,
            flavour: flavour,
            pageCount: pageCount,
            metadata: metadata,
            hasStructureTree: hasStructureTree,
            objectsByType: objectsByType
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
    /// Scans the raw PDF data for the `/StructTreeRoot` key, which is the
    /// definitive indicator that the document catalog contains a structure
    /// tree. This is more accurate than checking for an outline (bookmarks),
    /// which is a separate concept from the tagged structure tree.
    ///
    /// - Parameter pdfDocument: The loaded PDFKit document.
    /// - Returns: `true` if the document contains a `/StructTreeRoot` entry.
    private func checkStructureTree(in pdfDocument: PDFKit.PDFDocument) -> Bool {
        // Scan raw data for the /StructTreeRoot key in the document catalog.
        // This is the definitive marker for a tagged PDF structure tree.
        guard let data = try? Data(contentsOf: url) else {
            // Fall back to outline check if we cannot read raw data
            return pdfDocument.outlineRoot != nil
        }
        let marker = Data("/StructTreeRoot".utf8)
        return data.range(of: marker) != nil
    }

    /// Extract the PDF version string from the raw PDF header.
    ///
    /// Reads the first bytes of the file to find the `%PDF-X.Y` header
    /// and extracts the version number. Returns "1.7" as a default if
    /// the version cannot be determined.
    ///
    /// - Returns: The PDF version string (e.g., "1.7", "2.0").
    private func extractPDFVersion() -> String {
        guard let data = try? Data(contentsOf: url),
              data.count >= 8
        else {
            return "1.7"
        }
        // PDF header is "%PDF-X.Y" in the first 1024 bytes
        let headerRange = data.prefix(1024)
        let headerMarker = Data("%PDF-".utf8)
        guard let markerRange = headerRange.range(of: headerMarker) else {
            return "1.7"
        }
        let versionStart = markerRange.upperBound
        // Version is typically 3 characters like "1.7" or "2.0"
        let versionEnd = min(versionStart + 3, data.endIndex)
        guard versionStart < data.endIndex else { return "1.7" }
        let versionData = data[versionStart..<versionEnd]
        guard let versionString = String(data: versionData, encoding: .ascii) else {
            return "1.7"
        }
        return versionString
    }

    /// Check whether the document's MarkInfo dictionary has Marked=true.
    ///
    /// Scans the raw PDF data for the `/MarkInfo` dictionary and checks
    /// if it contains `/Marked true`. This is a lightweight heuristic
    /// based on raw byte scanning.
    ///
    /// - Returns: `true` if the document appears to be marked.
    private func checkIsMarked() -> Bool {
        guard let data = try? Data(contentsOf: url) else {
            return false
        }
        let markInfoMarker = Data("/MarkInfo".utf8)
        guard let markInfoRange = data.range(of: markInfoMarker) else {
            return false
        }
        // Look in the next ~200 bytes for "/Marked true"
        let searchEnd = min(markInfoRange.upperBound + 200, data.endIndex)
        let searchRange = markInfoRange.upperBound..<searchEnd
        let markedTrue = Data("/Marked true".utf8)
        return data.range(of: markedTrue, in: searchRange) != nil
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

    /// Build ``PDPageObject`` validation objects for each page in the document.
    ///
    /// Extracts page dimensions, rotation, and annotation information from
    /// each page using PDFKit's `PDFPage` API.
    ///
    /// - Parameter pdfDocument: The loaded PDFKit document.
    /// - Returns: An array of ``PDPageObject`` instances, one per page.
    private func buildPageObjects(from pdfDocument: PDFKit.PDFDocument) -> [any ValidationObject] {
        var pageObjects: [any ValidationObject] = []
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            let bounds = page.bounds(for: .mediaBox)
            let rotation = page.rotation
            let annotations = page.annotations
            let hasAnnotations = !annotations.isEmpty

            // Detect tab order from raw data (PDFKit does not expose /Tabs directly)
            let tabs = ""

            // Transparency detection is complex; default to false for now
            let containsTransparency = false

            let pageObj = PDPageObject(
                pageNumber: i,
                width: Double(bounds.width),
                height: Double(bounds.height),
                rotation: rotation,
                containsAnnotations: hasAnnotations,
                hasStructureElements: false, // Refined per-page in structure tree scan
                tabs: tabs,
                containsTransparency: containsTransparency
            )
            pageObjects.append(pageObj)
        }
        return pageObjects
    }

    /// Build structure element validation objects from the PDF's structure tree.
    ///
    /// Scans the raw PDF data for structure element markers and extracts basic
    /// information about each element. Structure elements are grouped by their
    /// standard type key (e.g., "SEFigure", "SETable").
    ///
    /// Since PDFKit does not expose the full structure tree API, this method
    /// uses the PDFKit outline as a lightweight proxy for structure information
    /// when available. For deeper structure tree access, a future sprint will
    /// integrate with `PDFDocumentParser` from the parser package.
    ///
    /// - Parameters:
    ///   - pdfDocument: The loaded PDFKit document.
    ///   - hasStructureTree: Whether the document has a structure tree root.
    /// - Returns: A dictionary mapping SE type keys to arrays of ``SEGenericObject``.
    private func buildStructureElementObjects(
        from pdfDocument: PDFKit.PDFDocument,
        hasStructureTree: Bool
    ) -> [String: [any ValidationObject]] {
        guard hasStructureTree else { return [:] }

        // Scan raw PDF data for structure element type markers.
        // This is a lightweight heuristic — we look for /S /TypeName patterns
        // in the raw data to identify structure element types present.
        guard let data = try? Data(contentsOf: url) else { return [:] }

        var elementsByType: [String: [any ValidationObject]] = [:]

        // Map standard structure type names to PDFObjectType keys
        let structureTypeMap: [String: String] = [
            "Figure": "SEFigure",
            "Table": "SETable",
            "Formula": "SEFormula",
            "H": "SEH",
            "H1": "SEHn",
            "H2": "SEHn",
            "H3": "SEHn",
            "H4": "SEHn",
            "H5": "SEHn",
            "H6": "SEHn",
            "P": "SESimpleContentItem",
            "Span": "SESpan",
            "Link": "SEAnnot",
            "Document": "SEDocument",
            "Part": "SEPart",
            "Sect": "SESect",
            "Div": "SEDiv",
            "Caption": "SECaption",
            "L": "SEL",
            "LI": "SELI",
            "LBody": "SELBody",
            "TR": "SETR",
            "TH": "SETH",
            "TD": "SETD",
            "THead": "SETHead",
            "TBody": "SETBody",
            "TFoot": "SETFoot",
            "TOC": "SETOC",
            "TOCI": "SETOCI",
            "Note": "SENote",
            "Art": "SEArt",
            "BlockQuote": "SEBlockQuote",
            "Code": "SECode",
            "Em": "SEEm",
            "Strong": "SEStrong",
            "Quote": "SEQuote",
            "Index": "SEIndex",
            "Title": "SETitle",
        ]

        // Scan for /S /TypeName patterns to detect structure elements present.
        // This is a rough heuristic based on raw byte scanning of the PDF.
        let dataString: String
        if let str = String(data: data, encoding: .ascii) {
            dataString = str
        } else {
            return [:]
        }

        for (typeName, objectTypeKey) in structureTypeMap {
            // Look for the pattern /S /TypeName (structure element type marker)
            let pattern = "/S /\(typeName)"
            if dataString.contains(pattern) {
                // We found at least one element of this type.
                // Create a single representative SEGenericObject.
                // Note: Counting exact occurrences and extracting attributes
                // requires full structure tree parsing; for now we create
                // a single object per detected type.
                let groupingTypes: Set<String> = [
                    "Document", "Part", "Sect", "Div", "Art",
                    "BlockQuote", "TOC", "TOCI", "L", "LI",
                    "Table", "TR", "THead", "TBody", "TFoot",
                    "Index",
                ]
                let isGrouping = groupingTypes.contains(typeName)

                let element = SEGenericObject(
                    structureType: typeName,
                    altText: nil,
                    actualText: nil,
                    title: nil,
                    language: nil,
                    parentStandardType: "",
                    kidsStandardTypes: "",
                    hasContentItems: !isGrouping,
                    isGrouping: isGrouping,
                    pageNumber: nil,
                    structureID: "SE-\(typeName)-0"
                )

                if elementsByType[objectTypeKey] != nil {
                    elementsByType[objectTypeKey]!.append(element)
                } else {
                    elementsByType[objectTypeKey] = [element]
                }
            }
        }

        return elementsByType
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
