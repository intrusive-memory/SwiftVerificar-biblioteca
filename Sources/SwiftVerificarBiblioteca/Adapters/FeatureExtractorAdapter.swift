import Foundation
import PDFKit
import CoreGraphics
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
/// have no entries in the document return `nil` rather than producing errors.
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
    /// Feature types that have no entries in the document return `nil` and
    /// are omitted from the result tree rather than producing errors.
    ///
    /// - Parameter document: The parsed document to extract features from.
    /// - Returns: A `FeatureExtractionResult` containing the feature tree.
    public func extract(from document: any ParsedDocument) -> FeatureExtractionResult {
        var children: [FeatureNode] = []
        let errors: [FeatureError] = []

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
        if isEnabled(.signatures) {
            if let node = extractSignaturesFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.embeddedFiles) {
            if let node = extractEmbeddedFilesFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.iccProfiles) {
            if let node = extractICCProfilesFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.outputIntents) {
            if let node = extractOutputIntentsFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.graphicsStates) {
            if let node = extractGraphicsStatesFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.colorSpaces) {
            if let node = extractColorSpacesFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.patterns) {
            if let node = extractPatternsFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.shadings) {
            if let node = extractShadingsFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.xObjects) {
            if let node = extractXObjectsFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.properties) {
            if let node = extractPropertiesFromURL(document.url) {
                children.append(node)
            }
        }
        if isEnabled(.interactiveFormFields) {
            if let node = extractInteractiveFormFieldsFromURL(document.url) {
                children.append(node)
            }
        }

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

    // MARK: - Signatures

    /// Extract digital signature fields from the AcroForm.
    ///
    /// Enumerates AcroForm fields in the CGPDFDocument and collects any
    /// field whose /FT entry is /Sig (signature). The /SigFlags value from
    /// the AcroForm dictionary is also reported.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch, or `nil` if no signatures exist.
    private func extractSignaturesFromURL(_ url: URL) -> FeatureNode? {
        guard let cgDoc = CGPDFDocument(url as CFURL) else { return nil }
        guard let catalog = cgDoc.catalog else { return nil }

        var acroFormDict: CGPDFDictionaryRef? = nil
        guard CGPDFDictionaryGetDictionary(catalog, "AcroForm", &acroFormDict),
              let acroForm = acroFormDict else { return nil }

        var sigFlags: Int = 0
        var sigFlagsValue: CGPDFInteger = 0
        if CGPDFDictionaryGetInteger(acroForm, "SigFlags", &sigFlagsValue) {
            sigFlags = Int(sigFlagsValue)
        }

        // Collect signature fields from /Fields array
        var fieldsArray: CGPDFArrayRef? = nil
        var signatureNodes: [FeatureNode] = []
        if CGPDFDictionaryGetArray(acroForm, "Fields", &fieldsArray),
           let fields = fieldsArray {
            signatureNodes = collectSignatureFields(from: fields)
        }

        // Only produce a node if there are actual signature fields or SigFlags is non-zero
        guard !signatureNodes.isEmpty || sigFlags != 0 else { return nil }

        var children: [FeatureNode] = [
            .leaf(name: "SigFlags", value: String(sigFlags)),
        ]
        children.append(contentsOf: signatureNodes)

        return .branch(
            name: "Signatures",
            children: children,
            attributes: ["count": String(signatureNodes.count)]
        )
    }

    /// Recursively collect signature field nodes from a CGPDF fields array.
    private func collectSignatureFields(from fieldsArray: CGPDFArrayRef) -> [FeatureNode] {
        var nodes: [FeatureNode] = []
        let count = CGPDFArrayGetCount(fieldsArray)
        for i in 0..<count {
            var fieldDict: CGPDFDictionaryRef? = nil
            guard CGPDFArrayGetDictionary(fieldsArray, i, &fieldDict),
                  let field = fieldDict else { continue }

            // Check /FT (field type) — must be /Sig for a signature field
            var ftName: UnsafePointer<Int8>? = nil
            if CGPDFDictionaryGetName(field, "FT", &ftName),
               let name = ftName, String(cString: name) == "Sig" {
                // Extract /T (partial field name)
                var tString: CGPDFStringRef? = nil
                var fieldName = "Signature"
                if CGPDFDictionaryGetString(field, "T", &tString),
                   let ts = tString,
                   let s = CGPDFStringCopyTextString(ts) {
                    fieldName = s as String
                }
                nodes.append(.leaf(name: "Signature Field", value: fieldName))
            }

            // Recurse into /Kids
            var kidsArray: CGPDFArrayRef? = nil
            if CGPDFDictionaryGetArray(field, "Kids", &kidsArray),
               let kids = kidsArray {
                nodes.append(contentsOf: collectSignatureFields(from: kids))
            }
        }
        return nodes
    }

    // MARK: - Embedded Files

    /// Extract embedded file names from the document's /EmbeddedFiles name tree.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch, or `nil` if no embedded files exist.
    private func extractEmbeddedFilesFromURL(_ url: URL) -> FeatureNode? {
        guard let cgDoc = CGPDFDocument(url as CFURL) else { return nil }
        guard let catalog = cgDoc.catalog else { return nil }

        // /Names -> /EmbeddedFiles name tree
        var namesDict: CGPDFDictionaryRef? = nil
        guard CGPDFDictionaryGetDictionary(catalog, "Names", &namesDict),
              let names = namesDict else { return nil }

        var embeddedFilesDict: CGPDFDictionaryRef? = nil
        guard CGPDFDictionaryGetDictionary(names, "EmbeddedFiles", &embeddedFilesDict),
              let efTree = embeddedFilesDict else { return nil }

        var fileNodes: [FeatureNode] = []
        collectNameTreeLeafNames(from: efTree, into: &fileNodes)

        guard !fileNodes.isEmpty else { return nil }

        return .branch(
            name: "Embedded Files",
            children: fileNodes,
            attributes: ["count": String(fileNodes.count)]
        )
    }

    /// Walk a PDF name tree and collect leaf names as FeatureNode leaves.
    ///
    /// A name tree node has either a /Names array (leaf) or a /Kids array
    /// (intermediate). This function handles both cases recursively.
    private func collectNameTreeLeafNames(from treeNode: CGPDFDictionaryRef, into nodes: inout [FeatureNode]) {
        // Leaf node: /Names is an array of alternating name/value pairs
        var namesArray: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetArray(treeNode, "Names", &namesArray),
           let names = namesArray {
            let count = CGPDFArrayGetCount(names)
            var i = 0
            while i < count {
                var nameStr: CGPDFStringRef? = nil
                if CGPDFArrayGetString(names, i, &nameStr),
                   let ns = nameStr,
                   let s = CGPDFStringCopyTextString(ns) {
                    nodes.append(.leaf(name: "File", value: s as String))
                }
                i += 2 // skip value
            }
        }

        // Intermediate node: /Kids array of child nodes
        var kidsArray: CGPDFArrayRef? = nil
        if CGPDFDictionaryGetArray(treeNode, "Kids", &kidsArray),
           let kids = kidsArray {
            let count = CGPDFArrayGetCount(kids)
            for i in 0..<count {
                var kidDict: CGPDFDictionaryRef? = nil
                if CGPDFArrayGetDictionary(kids, i, &kidDict),
                   let kid = kidDict {
                    collectNameTreeLeafNames(from: kid, into: &nodes)
                }
            }
        }
    }

    // MARK: - ICC Profiles

    /// Extract ICC profile descriptions from /OutputIntents and page color spaces.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch, or `nil` if no ICC profiles exist.
    private func extractICCProfilesFromURL(_ url: URL) -> FeatureNode? {
        guard let cgDoc = CGPDFDocument(url as CFURL) else { return nil }
        var profileNames = Set<String>()

        // Scan OutputIntents for ICCBased profiles
        if let catalog = cgDoc.catalog {
            var outputIntentsArray: CGPDFArrayRef? = nil
            if CGPDFDictionaryGetArray(catalog, "OutputIntents", &outputIntentsArray),
               let oia = outputIntentsArray {
                let count = CGPDFArrayGetCount(oia)
                for i in 0..<count {
                    var intentDict: CGPDFDictionaryRef? = nil
                    if CGPDFArrayGetDictionary(oia, i, &intentDict),
                       let intent = intentDict {
                        // /OutputConditionIdentifier or /Info often names the ICC profile
                        var nameStr: CGPDFStringRef? = nil
                        if CGPDFDictionaryGetString(intent, "OutputConditionIdentifier", &nameStr),
                           let ns = nameStr,
                           let s = CGPDFStringCopyTextString(ns) {
                            profileNames.insert(s as String)
                        }
                        // /DestOutputProfile is the stream — note its presence by subtype
                        var subtypeName: UnsafePointer<Int8>? = nil
                        if CGPDFDictionaryGetName(intent, "S", &subtypeName),
                           let sn = subtypeName {
                            profileNames.insert("OutputIntent(\(String(cString: sn)))")
                        }
                    }
                }
            }
        }

        // Scan each page's resources for ICCBased color spaces
        for pageIndex in 1...max(1, cgDoc.numberOfPages) {
            guard let page = cgDoc.page(at: pageIndex) else { continue }
            guard let pageDict = page.dictionary else { continue }

            var resourcesDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else { continue }

            var colorSpaceDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(resources, "ColorSpace", &colorSpaceDict),
                  let csDict = colorSpaceDict else { continue }

            // Enumerate color spaces looking for ICCBased entries
            CGPDFDictionaryApplyBlock(csDict, { key, object, _ in
                // An ICCBased color space is an array whose first element is the name /ICCBased
                var csArray: CGPDFArrayRef? = nil
                if CGPDFObjectGetValue(object, .array, &csArray),
                   let arr = csArray,
                   CGPDFArrayGetCount(arr) >= 1 {
                    var typeName: UnsafePointer<Int8>? = nil
                    if CGPDFArrayGetName(arr, 0, &typeName),
                       let tn = typeName,
                       String(cString: tn) == "ICCBased" {
                        let csName = String(cString: key)
                        profileNames.insert("ICCBased(\(csName))")
                    }
                }
                return true
            }, nil)
        }

        guard !profileNames.isEmpty else { return nil }

        let profileChildren = profileNames.sorted().map { name in
            FeatureNode.leaf(name: "ICC Profile", value: name)
        }

        return .branch(
            name: "ICC Profiles",
            children: profileChildren,
            attributes: ["count": String(profileChildren.count)]
        )
    }

    // MARK: - Output Intents

    /// Extract /OutputIntents entries from the document catalog.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch, or `nil` if no output intents exist.
    private func extractOutputIntentsFromURL(_ url: URL) -> FeatureNode? {
        guard let cgDoc = CGPDFDocument(url as CFURL) else { return nil }
        guard let catalog = cgDoc.catalog else { return nil }

        var outputIntentsArray: CGPDFArrayRef? = nil
        guard CGPDFDictionaryGetArray(catalog, "OutputIntents", &outputIntentsArray),
              let oia = outputIntentsArray else { return nil }

        let count = CGPDFArrayGetCount(oia)
        guard count > 0 else { return nil }

        var intentNodes: [FeatureNode] = []
        for i in 0..<count {
            var intentDict: CGPDFDictionaryRef? = nil
            guard CGPDFArrayGetDictionary(oia, i, &intentDict),
                  let intent = intentDict else { continue }

            var subtypeName: UnsafePointer<Int8>? = nil
            let subtype: String
            if CGPDFDictionaryGetName(intent, "S", &subtypeName), let sn = subtypeName {
                subtype = String(cString: sn)
            } else {
                subtype = "Unknown"
            }

            var conditionStr: CGPDFStringRef? = nil
            var condition = ""
            if CGPDFDictionaryGetString(intent, "OutputConditionIdentifier", &conditionStr),
               let cs = conditionStr,
               let s = CGPDFStringCopyTextString(cs) {
                condition = s as String
            }

            intentNodes.append(.branch(
                name: "Output Intent",
                children: [
                    .leaf(name: "Subtype", value: subtype),
                    .leaf(name: "OutputConditionIdentifier", value: condition.isEmpty ? nil : condition),
                ],
                attributes: ["subtype": subtype]
            ))
        }

        guard !intentNodes.isEmpty else { return nil }

        return .branch(
            name: "Output Intents",
            children: intentNodes,
            attributes: ["count": String(intentNodes.count)]
        )
    }

    // MARK: - Graphics States

    /// Extract /ExtGState entries from all page resource dictionaries.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch, or `nil` if no graphics states exist.
    private func extractGraphicsStatesFromURL(_ url: URL) -> FeatureNode? {
        guard let cgDoc = CGPDFDocument(url as CFURL) else { return nil }
        var gsNames = Set<String>()

        for pageIndex in 1...max(1, cgDoc.numberOfPages) {
            guard let page = cgDoc.page(at: pageIndex) else { continue }
            guard let pageDict = page.dictionary else { continue }
            var resourcesDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else { continue }

            var extGStateDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(resources, "ExtGState", &extGStateDict),
                  let gsDict = extGStateDict else { continue }

            CGPDFDictionaryApplyBlock(gsDict, { key, _, _ in
                gsNames.insert(String(cString: key))
                return true
            }, nil)
        }

        guard !gsNames.isEmpty else { return nil }

        let gsChildren = gsNames.sorted().map { name in
            FeatureNode.leaf(name: "Graphics State", value: name)
        }

        return .branch(
            name: "Graphics States",
            children: gsChildren,
            attributes: ["count": String(gsChildren.count)]
        )
    }

    // MARK: - Color Spaces

    /// Extract named /ColorSpace entries from all page resource dictionaries.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch, or `nil` if no named color spaces exist.
    private func extractColorSpacesFromURL(_ url: URL) -> FeatureNode? {
        guard let cgDoc = CGPDFDocument(url as CFURL) else { return nil }
        var csNames = Set<String>()

        for pageIndex in 1...max(1, cgDoc.numberOfPages) {
            guard let page = cgDoc.page(at: pageIndex) else { continue }
            guard let pageDict = page.dictionary else { continue }
            var resourcesDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else { continue }

            var colorSpaceDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(resources, "ColorSpace", &colorSpaceDict),
                  let csDict = colorSpaceDict else { continue }

            CGPDFDictionaryApplyBlock(csDict, { key, _, _ in
                csNames.insert(String(cString: key))
                return true
            }, nil)
        }

        guard !csNames.isEmpty else { return nil }

        let csChildren = csNames.sorted().map { name in
            FeatureNode.leaf(name: "Color Space", value: name)
        }

        return .branch(
            name: "Color Spaces",
            children: csChildren,
            attributes: ["count": String(csChildren.count)]
        )
    }

    // MARK: - Patterns

    /// Extract /Pattern entries from all page resource dictionaries.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch, or `nil` if no patterns exist.
    private func extractPatternsFromURL(_ url: URL) -> FeatureNode? {
        guard let cgDoc = CGPDFDocument(url as CFURL) else { return nil }
        var patternNames = Set<String>()

        for pageIndex in 1...max(1, cgDoc.numberOfPages) {
            guard let page = cgDoc.page(at: pageIndex) else { continue }
            guard let pageDict = page.dictionary else { continue }
            var resourcesDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else { continue }

            var patternDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(resources, "Pattern", &patternDict),
                  let pDict = patternDict else { continue }

            CGPDFDictionaryApplyBlock(pDict, { key, _, _ in
                patternNames.insert(String(cString: key))
                return true
            }, nil)
        }

        guard !patternNames.isEmpty else { return nil }

        let patternChildren = patternNames.sorted().map { name in
            FeatureNode.leaf(name: "Pattern", value: name)
        }

        return .branch(
            name: "Patterns",
            children: patternChildren,
            attributes: ["count": String(patternChildren.count)]
        )
    }

    // MARK: - Shadings

    /// Extract /Shading entries from all page resource dictionaries.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch, or `nil` if no shadings exist.
    private func extractShadingsFromURL(_ url: URL) -> FeatureNode? {
        guard let cgDoc = CGPDFDocument(url as CFURL) else { return nil }
        var shadingNames = Set<String>()

        for pageIndex in 1...max(1, cgDoc.numberOfPages) {
            guard let page = cgDoc.page(at: pageIndex) else { continue }
            guard let pageDict = page.dictionary else { continue }
            var resourcesDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else { continue }

            var shadingDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(resources, "Shading", &shadingDict),
                  let sDict = shadingDict else { continue }

            CGPDFDictionaryApplyBlock(sDict, { key, _, _ in
                shadingNames.insert(String(cString: key))
                return true
            }, nil)
        }

        guard !shadingNames.isEmpty else { return nil }

        let shadingChildren = shadingNames.sorted().map { name in
            FeatureNode.leaf(name: "Shading", value: name)
        }

        return .branch(
            name: "Shadings",
            children: shadingChildren,
            attributes: ["count": String(shadingChildren.count)]
        )
    }

    // MARK: - XObjects

    /// Extract /XObject entries from all page resource dictionaries.
    ///
    /// Reports each XObject's resource name and its /Subtype (e.g., Image, Form).
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch, or `nil` if no XObjects exist.
    private func extractXObjectsFromURL(_ url: URL) -> FeatureNode? {
        guard let cgDoc = CGPDFDocument(url as CFURL) else { return nil }
        var xObjectEntries: [(name: String, subtype: String)] = []
        var seen = Set<String>()

        for pageIndex in 1...max(1, cgDoc.numberOfPages) {
            guard let page = cgDoc.page(at: pageIndex) else { continue }
            guard let pageDict = page.dictionary else { continue }
            var resourcesDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else { continue }

            var xObjectDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(resources, "XObject", &xObjectDict),
                  let xoDict = xObjectDict else { continue }

            CGPDFDictionaryApplyBlock(xoDict, { key, object, _ in
                let name = String(cString: key)
                guard !seen.contains(name) else { return true }
                seen.insert(name)

                var subtype = "Unknown"
                // XObjects are streams — try to get their dict via the stream dict
                var streamRef: CGPDFStreamRef? = nil
                if CGPDFObjectGetValue(object, .stream, &streamRef),
                   let stream = streamRef,
                   let streamDict = CGPDFStreamGetDictionary(stream) {
                    var subtypeName: UnsafePointer<Int8>? = nil
                    if CGPDFDictionaryGetName(streamDict, "Subtype", &subtypeName),
                       let sn = subtypeName {
                        subtype = String(cString: sn)
                    }
                }
                xObjectEntries.append((name: name, subtype: subtype))
                return true
            }, nil)
        }

        guard !xObjectEntries.isEmpty else { return nil }

        let xoChildren = xObjectEntries.sorted { $0.name < $1.name }.map { entry in
            FeatureNode.leaf(name: "XObject", value: "\(entry.name) (\(entry.subtype))")
        }

        return .branch(
            name: "XObjects",
            children: xoChildren,
            attributes: ["count": String(xoChildren.count)]
        )
    }

    // MARK: - Properties

    /// Extract /Properties entries (marked-content property lists) from page resources.
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch, or `nil` if no properties exist.
    private func extractPropertiesFromURL(_ url: URL) -> FeatureNode? {
        guard let cgDoc = CGPDFDocument(url as CFURL) else { return nil }
        var propertyNames = Set<String>()

        for pageIndex in 1...max(1, cgDoc.numberOfPages) {
            guard let page = cgDoc.page(at: pageIndex) else { continue }
            guard let pageDict = page.dictionary else { continue }
            var resourcesDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourcesDict),
                  let resources = resourcesDict else { continue }

            var propertiesDict: CGPDFDictionaryRef? = nil
            guard CGPDFDictionaryGetDictionary(resources, "Properties", &propertiesDict),
                  let pDict = propertiesDict else { continue }

            CGPDFDictionaryApplyBlock(pDict, { key, _, _ in
                propertyNames.insert(String(cString: key))
                return true
            }, nil)
        }

        guard !propertyNames.isEmpty else { return nil }

        let propChildren = propertyNames.sorted().map { name in
            FeatureNode.leaf(name: "Property", value: name)
        }

        return .branch(
            name: "Properties",
            children: propChildren,
            attributes: ["count": String(propChildren.count)]
        )
    }

    // MARK: - Interactive Form Fields

    /// Extract AcroForm field names from the document catalog.
    ///
    /// Recursively traverses the /Fields array of the /AcroForm dictionary
    /// collecting terminal fields (those without /Kids).
    ///
    /// - Parameter url: The URL of the PDF document.
    /// - Returns: A `FeatureNode` branch, or `nil` if no form fields exist.
    private func extractInteractiveFormFieldsFromURL(_ url: URL) -> FeatureNode? {
        guard let cgDoc = CGPDFDocument(url as CFURL) else { return nil }
        guard let catalog = cgDoc.catalog else { return nil }

        var acroFormDict: CGPDFDictionaryRef? = nil
        guard CGPDFDictionaryGetDictionary(catalog, "AcroForm", &acroFormDict),
              let acroForm = acroFormDict else { return nil }

        var fieldsArray: CGPDFArrayRef? = nil
        guard CGPDFDictionaryGetArray(acroForm, "Fields", &fieldsArray),
              let fields = fieldsArray else { return nil }

        var fieldNodes: [FeatureNode] = []
        collectFormFields(from: fields, into: &fieldNodes)

        guard !fieldNodes.isEmpty else { return nil }

        return .branch(
            name: "Interactive Form Fields",
            children: fieldNodes,
            attributes: ["count": String(fieldNodes.count)]
        )
    }

    /// Recursively collect form field nodes from a CGPDF fields array.
    private func collectFormFields(from fieldsArray: CGPDFArrayRef, into nodes: inout [FeatureNode]) {
        let count = CGPDFArrayGetCount(fieldsArray)
        for i in 0..<count {
            var fieldDict: CGPDFDictionaryRef? = nil
            guard CGPDFArrayGetDictionary(fieldsArray, i, &fieldDict),
                  let field = fieldDict else { continue }

            // /Kids means this is an intermediate node — recurse
            var kidsArray: CGPDFArrayRef? = nil
            if CGPDFDictionaryGetArray(field, "Kids", &kidsArray),
               let kids = kidsArray {
                collectFormFields(from: kids, into: &nodes)
                continue
            }

            // Terminal field — collect /T (partial name) and /FT (field type)
            var partialName = "Field"
            var tString: CGPDFStringRef? = nil
            if CGPDFDictionaryGetString(field, "T", &tString),
               let ts = tString,
               let s = CGPDFStringCopyTextString(ts) {
                partialName = s as String
            }

            var fieldType = "Unknown"
            var ftName: UnsafePointer<Int8>? = nil
            if CGPDFDictionaryGetName(field, "FT", &ftName), let fn = ftName {
                fieldType = String(cString: fn)
            }

            nodes.append(.leaf(name: "Field", value: "\(partialName) (\(fieldType))"))
        }
    }
}
