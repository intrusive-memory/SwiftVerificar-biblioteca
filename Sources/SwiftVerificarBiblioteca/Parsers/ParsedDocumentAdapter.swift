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
    /// document-level properties. For "PDPage", returns one ``PDPageObject`` per
    /// page. For structure element types (e.g., "SEFigure"), returns one
    /// ``SEGenericObject`` per matching structure element. For unrecognised
    /// types, returns an empty array.
    ///
    /// - Parameter objectType: The type identifier to query (e.g., "CosDocument", "PDPage", "SEFigure").
    /// - Returns: An array of validation objects matching the type, or empty if none.
    public func objects(ofType objectType: String) -> [any ValidationObject] {
        objectsByType[objectType] ?? []
    }

    /// Returns all object type keys that have been populated.
    ///
    /// Useful for inspecting what object types are available in the parsed document.
    public var availableObjectTypes: [String] {
        Array(objectsByType.keys).sorted()
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

// MARK: - PDPageObject

/// A ``ValidationObject`` representing a single PDF page.
///
/// This object exposes page-level properties that validation profile
/// rules for the "PDPage" object type evaluate against. It corresponds
/// to the Java `GFPDPage` class in veraPDF.
///
/// ## Properties Exposed
///
/// | Key                     | Description                                          |
/// |-------------------------|------------------------------------------------------|
/// | `pageNumber`            | Zero-based page index                                |
/// | `width`                 | Page width in points from MediaBox                   |
/// | `height`                | Page height in points from MediaBox                  |
/// | `rotation`              | Page rotation in degrees (0, 90, 180, 270)           |
/// | `orientation`           | Derived page orientation ("Portrait", "Landscape", or "Square") |
/// | `containsAnnotations`   | Whether the page has annotations ("true"/"false")    |
/// | `hasStructureElements`  | Whether the page has tagged structure elements        |
/// | `Tabs`                  | Tab order for annotations ("S", "R", "C", or "")     |
/// | `containsTransparency`  | Whether the page uses transparency                   |
///
/// ## Thread Safety
///
/// `PDPageObject` is a value type (`struct`) with only `let`
/// properties. It conforms to `Sendable`.
public struct PDPageObject: ValidationObject, Sendable {

    /// The page-level properties for rule evaluation.
    public let validationProperties: [String: String]

    /// The location of this object within the PDF document.
    public let location: PDFLocation?

    /// Creates a PDPageObject with the given page-level properties.
    ///
    /// - Parameters:
    ///   - pageNumber: The zero-based page index.
    ///   - width: The page width in points.
    ///   - height: The page height in points.
    ///   - rotation: The page rotation in degrees.
    ///   - containsAnnotations: Whether the page has annotations.
    ///   - hasStructureElements: Whether the page has structure elements.
    ///   - tabs: The tab order for annotations.
    ///   - containsTransparency: Whether the page uses transparency.
    public init(
        pageNumber: Int,
        width: Double = 612.0,
        height: Double = 792.0,
        rotation: Int = 0,
        containsAnnotations: Bool = false,
        hasStructureElements: Bool = false,
        tabs: String = "",
        containsTransparency: Bool = false
    ) {
        let orientation: String
        if abs(width - height) < 1.0 {
            orientation = "Square"
        } else if (rotation == 0 || rotation == 180) {
            orientation = width > height ? "Landscape" : "Portrait"
        } else {
            orientation = height > width ? "Landscape" : "Portrait"
        }

        self.validationProperties = [
            "pageNumber": String(pageNumber),
            "width": String(width),
            "height": String(height),
            "rotation": String(rotation),
            "orientation": orientation,
            "containsAnnotations": String(containsAnnotations),
            "hasStructureElements": String(hasStructureElements),
            "Tabs": tabs,
            "containsTransparency": String(containsTransparency),
        ]
        self.location = PDFLocation(pageNumber: pageNumber + 1)
    }
}

// MARK: - SEGenericObject

/// A ``ValidationObject`` representing a structure element in the tagged
/// PDF structure tree.
///
/// This object exposes structure-element-level properties that validation
/// profile rules for SE* object types evaluate against. It is a generic
/// representation: the parser creates one `SEGenericObject` per structure
/// element found in the document, and stores it under the appropriate
/// object type key (e.g., "SEFigure", "SETable", "SEH", "SESpan", etc.).
///
/// ## Properties Exposed
///
/// | Key                   | Description                                          |
/// |-----------------------|------------------------------------------------------|
/// | `structureType`       | The standard structure type (e.g., "Figure", "Table")|
/// | `Alt`                 | Alternate text for accessibility, or `null`           |
/// | `ActualText`          | Actual text replacement, or `null`                   |
/// | `title`               | Title of the structure element (or `null`)            |
/// | `Lang`                | Language tag (e.g., "en-US"), or `null`               |
/// | `parentStandardType`  | Standard type of the parent element (or "")           |
/// | `kidsStandardTypes`   | Ampersand-delimited child standard types              |
/// | `hasContentItems`     | Whether this element has content items                |
/// | `isGrouping`          | Whether this element is a grouping element            |
///
/// ## Null vs Empty Strings
///
/// For properties like `Alt` and `ActualText`, the validation rule
/// expressions use `!= null` checks. A property value of `"null"` (the
/// string literal) indicates absence, while any other string (including
/// `""`) indicates the property is present.
///
/// ## Thread Safety
///
/// `SEGenericObject` is a value type (`struct`) with only `let`
/// properties. It conforms to `Sendable`.
public struct SEGenericObject: ValidationObject, Sendable {

    /// The structure-element-level properties for rule evaluation.
    public let validationProperties: [String: String]

    /// The location of this object within the PDF document.
    public let location: PDFLocation?

    /// Creates an SEGenericObject with the given structure element properties.
    ///
    /// - Parameters:
    ///   - structureType: The standard structure type (e.g., "Figure").
    ///   - altText: The alternate text, or `nil` to store "null".
    ///   - actualText: The actual text replacement, or `nil` to store "null".
    ///   - title: The element title, or `nil` to store "null".
    ///   - language: The language tag, or `nil` to store "null".
    ///   - parentStandardType: The standard type of the parent element.
    ///   - kidsStandardTypes: Ampersand-delimited string of child standard types.
    ///   - hasContentItems: Whether the element has content items.
    ///   - isGrouping: Whether the element is a grouping element.
    ///   - pageNumber: The 1-based page number where this element appears.
    ///   - structureID: An identifier for this structure element.
    public init(
        structureType: String,
        altText: String? = nil,
        actualText: String? = nil,
        title: String? = nil,
        language: String? = nil,
        parentStandardType: String = "",
        kidsStandardTypes: String = "",
        hasContentItems: Bool = false,
        isGrouping: Bool = false,
        pageNumber: Int? = nil,
        structureID: String? = nil
    ) {
        self.validationProperties = [
            "structureType": structureType,
            "Alt": altText ?? "null",
            "ActualText": actualText ?? "null",
            "title": title ?? "null",
            "Lang": language ?? "null",
            "parentStandardType": parentStandardType,
            "kidsStandardTypes": kidsStandardTypes,
            "hasContentItems": String(hasContentItems),
            "isGrouping": String(isGrouping),
        ]
        self.location = PDFLocation(
            pageNumber: pageNumber,
            structureID: structureID
        )
    }
}
