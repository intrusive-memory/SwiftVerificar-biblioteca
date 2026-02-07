import Foundation
import PDFKit
// DO NOT import SwiftVerificarValidation — severe type collisions with
// FeatureType, FeatureNode, and FeatureReport, plus module-name shadowing.

/// A real feature extractor that produces `FeatureExtractionResult` from a
/// `ParsedDocument` by reading its validation objects and PDFKit data.
///
/// `SwiftFeatureExtractor` conforms to `FeatureExtractorProvider` and extracts
/// features directly from the
/// `ParsedDocument`'s `CosDocumentObject`, `PDPageObject`, `DocumentMetadata`,
/// and raw PDFKit APIs, avoiding any import of `SwiftVerificarValidation`.
///
/// ## Extraction Strategy
///
/// For each enabled `FeatureType`, the extractor builds a `FeatureNode` branch
/// from the data sources available in the parsed document. Feature types that
/// lack data sources (e.g., `signatures`, `embeddedFiles`) are silently
/// skipped rather than producing errors.
///
/// ## Thread Safety
///
/// `SwiftFeatureExtractor` is a value type with no mutable state and conforms
/// to `Sendable`.
public struct SwiftFeatureExtractor: FeatureExtractorProvider, Sendable {

    /// The configuration controlling which features to extract.
    public let config: FeatureExtractorConfiguration

    /// Component metadata for this extractor.
    public let info: ComponentInfo

    /// Creates a new `SwiftFeatureExtractor`.
    ///
    /// - Parameter config: The configuration specifying which features to
    ///   extract and whether to include sub-features.
    public init(config: FeatureExtractorConfiguration) {
        self.config = config
        self.info = ComponentInfo(
            name: "SwiftFeatureExtractor",
            version: SwiftVerificarBiblioteca.version,
            componentDescription: "PDF feature extractor using PDFKit",
            provider: "SwiftVerificar Project"
        )
    }

    // MARK: - Extract

    /// Extract features from a parsed document.
    ///
    /// Iterates over each enabled feature type and builds a `FeatureNode`
    /// branch from the document's validation objects and PDFKit data.
    /// Feature types without available data are silently skipped.
    ///
    /// - Parameter document: The parsed document to extract features from.
    /// - Returns: A `FeatureExtractionResult` containing the feature tree.
    public func extract(from document: any ParsedDocument) -> FeatureExtractionResult {
        var children: [FeatureNode] = []
        var errors: [FeatureError] = []

        // Extract features for each enabled type
        if isEnabled(.lowLevelInfo) {
            if let node = extractLowLevelInfo(from: document) {
                children.append(node)
            }
        }
        if isEnabled(.informationDictionary) {
            if let node = extractInfoDictionary(from: document) {
                children.append(node)
            }
        }
        if isEnabled(.metadata) {
            if let node = extractMetadata(from: document) {
                children.append(node)
            }
        }
        if isEnabled(.pages) {
            if let node = extractPages(from: document) {
                children.append(node)
            }
        }
        if isEnabled(.fonts) {
            if let node = extractFontsFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.annotations) {
            if let node = extractAnnotationsFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.documentSecurity) {
            if let node = extractDocumentSecurity(from: document) {
                children.append(node)
            }
        }
        if isEnabled(.outlines) {
            if let node = extractOutlinesFromURL(document.url) {
                children.append(node)
            }
        }

        // Feature types without data sources are silently skipped:
        // signatures, embeddedFiles, iccProfiles, outputIntents,
        // graphicsStates, colorSpaces, patterns, shadings, xObjects,
        // properties, interactiveFormFields

        let root = FeatureNode.branch(
            name: "Document",
            children: children,
            attributes: ["url": document.url.lastPathComponent]
        )

        return FeatureExtractionResult(
            documentURL: document.url,
            features: root,
            errors: errors
        )
    }

    // MARK: - Private Helpers

    /// Whether a specific feature type is enabled in the configuration.
    ///
    /// The configuration stores enabled features as `Set<String>` using
    /// the raw values of `FeatureType`.
    private func isEnabled(_ type: FeatureType) -> Bool {
        config.enabledFeatures.contains(type.rawValue)
    }

    // MARK: - Low-Level Info

    /// Extract low-level document information from `CosDocumentObject`.
    private func extractLowLevelInfo(from document: any ParsedDocument) -> FeatureNode? {
        let cosDocObjects = document.objects(ofType: "CosDocument")
        guard let cosDoc = cosDocObjects.first else { return nil }
        let props = cosDoc.validationProperties

        return .branch(name: "Low-Level Info", children: [
            .leaf(name: "PDF Version", value: props["pdfVersion"]),
            .leaf(name: "Page Count", value: props["nrPages"]),
            .leaf(name: "Is Encrypted", value: props["isEncrypted"]),
            .leaf(name: "Has Structure Tree", value: props["hasStructTreeRoot"]),
            .leaf(name: "Is Marked", value: props["isMarked"]),
            .leaf(name: "Has XMP Metadata", value: props["hasXMPMetadata"]),
        ], attributes: [:])
    }

    // MARK: - Information Dictionary

    /// Extract information dictionary entries from `CosDocumentObject`.
    private func extractInfoDictionary(from document: any ParsedDocument) -> FeatureNode? {
        let cosDocObjects = document.objects(ofType: "CosDocument")
        guard let cosDoc = cosDocObjects.first else { return nil }
        let props = cosDoc.validationProperties

        return .branch(name: "Information Dictionary", children: [
            .leaf(name: "Title", value: props["title"]),
            .leaf(name: "Author", value: props["author"]),
            .leaf(name: "Producer", value: props["producer"]),
            .leaf(name: "Creator", value: props["creator"]),
        ], attributes: [:])
    }

    // MARK: - Metadata

    /// Extract metadata from the document's `DocumentMetadata`.
    private func extractMetadata(from document: any ParsedDocument) -> FeatureNode? {
        guard let meta = document.metadata else { return nil }

        var children: [FeatureNode] = []
        children.append(.leaf(name: "Title", value: meta.title))
        children.append(.leaf(name: "Author", value: meta.author))
        children.append(.leaf(name: "Subject", value: meta.subject))
        children.append(.leaf(name: "Keywords", value: meta.keywords))
        children.append(.leaf(name: "Creator", value: meta.creator))
        children.append(.leaf(name: "Producer", value: meta.producer))
        children.append(.leaf(name: "Has XMP", value: String(meta.hasXMPMetadata)))

        if let creationDate = meta.creationDate {
            children.append(.leaf(name: "Creation Date", value: ISO8601DateFormatter().string(from: creationDate)))
        }
        if let modDate = meta.modificationDate {
            children.append(.leaf(name: "Modification Date", value: ISO8601DateFormatter().string(from: modDate)))
        }

        return .branch(name: "Metadata", children: children, attributes: [:])
    }

    // MARK: - Pages

    /// Extract page information from `PDPageObject` validation objects.
    private func extractPages(from document: any ParsedDocument) -> FeatureNode? {
        let pageObjects = document.objects(ofType: "PDPage")
        guard !pageObjects.isEmpty else { return nil }

        let pageChildren: [FeatureNode] = pageObjects.compactMap { obj in
            let props = obj.validationProperties
            return .branch(name: "Page", children: [
                .leaf(name: "Page Number", value: props["pageNumber"]),
                .leaf(name: "Width", value: props["width"]),
                .leaf(name: "Height", value: props["height"]),
                .leaf(name: "Rotation", value: props["rotation"]),
                .leaf(name: "Orientation", value: props["orientation"]),
                .leaf(name: "Contains Annotations", value: props["containsAnnotations"]),
                .leaf(name: "Has Structure Elements", value: props["hasStructureElements"]),
            ], attributes: ["number": props["pageNumber"] ?? ""])
        }

        return .branch(
            name: "Pages",
            children: pageChildren,
            attributes: ["count": String(pageChildren.count)]
        )
    }

    // MARK: - Fonts

    /// Extract font information from the PDF using PDFKit.
    ///
    /// Enumerates each page's attributed string to discover font names used
    /// in the document.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch containing font entries, or `nil`.
    private func extractFontsFromURL(_ url: URL) -> FeatureNode? {
        guard let pdfDoc = PDFDocument(url: url) else { return nil }
        var fontNames = Set<String>()

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i) else { continue }
            if let attrStr = page.attributedString {
                attrStr.enumerateAttribute(
                    .font,
                    in: NSRange(location: 0, length: attrStr.length)
                ) { value, _, _ in
                    #if canImport(AppKit)
                    if let font = value as? NSFont {
                        fontNames.insert(font.fontName)
                    }
                    #elseif canImport(UIKit)
                    if let font = value as? UIFont {
                        fontNames.insert(font.fontName)
                    }
                    #endif
                }
            }
        }

        let fontChildren = fontNames.sorted().map { name in
            FeatureNode.leaf(name: "Font", value: name)
        }

        return .branch(
            name: "Fonts",
            children: fontChildren,
            attributes: ["count": String(fontChildren.count)]
        )
    }

    // MARK: - Annotations

    /// Extract annotation information from the PDF using PDFKit.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch containing annotation entries, or `nil`.
    private func extractAnnotationsFromURL(_ url: URL) -> FeatureNode? {
        guard let pdfDoc = PDFDocument(url: url) else { return nil }
        var annotationNodes: [FeatureNode] = []

        for i in 0..<pdfDoc.pageCount {
            guard let page = pdfDoc.page(at: i) else { continue }
            for annotation in page.annotations {
                let annotType = annotation.type ?? "Unknown"
                annotationNodes.append(.branch(
                    name: "Annotation",
                    children: [
                        .leaf(name: "Type", value: annotType),
                        .leaf(name: "Page", value: String(i + 1)),
                    ],
                    attributes: ["page": String(i + 1)]
                ))
            }
        }

        if annotationNodes.isEmpty { return nil }

        return .branch(
            name: "Annotations",
            children: annotationNodes,
            attributes: ["count": String(annotationNodes.count)]
        )
    }

    // MARK: - Document Security

    /// Extract document security information from `CosDocumentObject`.
    private func extractDocumentSecurity(from document: any ParsedDocument) -> FeatureNode? {
        let cosDocObjects = document.objects(ofType: "CosDocument")
        guard let cosDoc = cosDocObjects.first else { return nil }
        let props = cosDoc.validationProperties

        return .branch(name: "Document Security", children: [
            .leaf(name: "Is Encrypted", value: props["isEncrypted"]),
        ], attributes: [:])
    }

    // MARK: - Outlines

    /// Extract outline (bookmark) information from the PDF using PDFKit.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch containing outline entries, or `nil`.
    private func extractOutlinesFromURL(_ url: URL) -> FeatureNode? {
        guard let pdfDoc = PDFDocument(url: url) else { return nil }
        guard let outlineRoot = pdfDoc.outlineRoot else { return nil }

        let outlineChildren = buildOutlineNodes(from: outlineRoot)
        if outlineChildren.isEmpty { return nil }

        return .branch(
            name: "Outlines",
            children: outlineChildren,
            attributes: ["count": String(outlineChildren.count)]
        )
    }

    /// Recursively build outline nodes from a PDFKit outline item.
    private func buildOutlineNodes(from outline: PDFOutline) -> [FeatureNode] {
        var nodes: [FeatureNode] = []
        for i in 0..<outline.numberOfChildren {
            guard let child = outline.child(at: i) else { continue }
            let label = child.label ?? "Untitled"
            let childOutlineNodes = buildOutlineNodes(from: child)
            if childOutlineNodes.isEmpty {
                nodes.append(.leaf(name: "Outline Entry", value: label))
            } else {
                nodes.append(.branch(
                    name: "Outline Entry",
                    children: [.leaf(name: "Title", value: label)] + childOutlineNodes,
                    attributes: ["title": label]
                ))
            }
        }
        return nodes
    }
}
