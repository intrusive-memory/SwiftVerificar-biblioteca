import Foundation
import SwiftVerificarWCAGAlgs

/// A ``SemanticNode`` adapter that bridges biblioteca's ``SEGenericObject``
/// validation objects to the WCAG algorithms package's semantic tree model.
///
/// `SemanticNodeAdapter` converts the flat list of structure elements from
/// ``ParsedDocumentAdapter`` into a hierarchical tree structure suitable for
/// WCAG validation. Each adapter wraps an ``SEGenericObject`` and maps its
/// properties to the ``SemanticNode`` protocol requirements.
///
/// ## Mapping
///
/// | SEGenericObject Property | SemanticNode Property |
/// |--------------------------|----------------------|
/// | `structureType`          | `type` (via `SemanticType(structureTypeName:)`) |
/// | `Alt`                    | `attributes["Alt"]`   |
/// | `ActualText`             | `attributes["ActualText"]` |
/// | `Lang`                   | `attributes["Lang"]`  |
/// | `title`                  | `attributes["Title"]` |
///
/// ## Tree Building
///
/// The ``buildTree(from:)`` static method constructs a document root node
/// with all detected structure elements as children. Since the current
/// parser uses raw byte scanning heuristics (one ``SEGenericObject`` per
/// detected type, not per instance), the resulting tree is shallow: a
/// single root with one child per structure element type.
///
/// ## Thread Safety
///
/// `SemanticNodeAdapter` is a value type (`struct`) conforming to `Sendable`.
public struct SemanticNodeAdapter: SemanticNode, Sendable, Hashable {

    /// The unique identifier for this node.
    public let id: UUID

    /// The semantic type of this node.
    public let type: SemanticType

    /// The bounding box of this node, if it has a spatial location.
    public let boundingBox: BoundingBox?

    /// The child nodes of this node, in document order.
    public let children: [any SemanticNode]

    /// The attributes dictionary from the PDF structure element.
    public let attributes: AttributesDictionary

    /// The depth of this node in the structure tree.
    public let depth: Int

    /// Error codes detected during validation of this node.
    public var errorCodes: Set<SemanticErrorCode>

    /// Creates a new `SemanticNodeAdapter` with all properties.
    ///
    /// - Parameters:
    ///   - id: The unique identifier (defaults to a new UUID).
    ///   - type: The semantic type of this node.
    ///   - boundingBox: The spatial location, if any.
    ///   - children: The child nodes.
    ///   - attributes: The semantic node attributes.
    ///   - depth: The depth in the structure tree.
    ///   - errorCodes: Initial error codes (defaults to empty).
    public init(
        id: UUID = UUID(),
        type: SemanticType,
        boundingBox: BoundingBox? = nil,
        children: [any SemanticNode] = [],
        attributes: AttributesDictionary = [:],
        depth: Int = 0,
        errorCodes: Set<SemanticErrorCode> = []
    ) {
        self.id = id
        self.type = type
        self.boundingBox = boundingBox
        self.children = children
        self.attributes = attributes
        self.depth = depth
        self.errorCodes = errorCodes
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable

    public static func == (lhs: SemanticNodeAdapter, rhs: SemanticNodeAdapter) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Factory: Build from SEGenericObject

    /// Creates a ``SemanticNodeAdapter`` from an ``SEGenericObject``.
    ///
    /// Maps the validation object's string properties to the WCAG
    /// semantic node model. Properties with a value of `"null"` are
    /// treated as absent.
    ///
    /// - Parameters:
    ///   - seObject: The structure element validation object.
    ///   - depth: The depth in the tree (defaults to 1).
    /// - Returns: A semantic node adapter, or `nil` if the structure
    ///   type cannot be mapped to a ``SemanticType``.
    public static func fromSEGenericObject(
        _ seObject: SEGenericObject,
        depth: Int = 1
    ) -> SemanticNodeAdapter? {
        let props = seObject.validationProperties

        // Map the structure type name to a SemanticType
        guard let structureTypeName = props["structureType"],
              let semanticType = SemanticType(structureTypeName: structureTypeName) else {
            return nil
        }

        // Build the attributes dictionary, excluding "null" values
        var attrs: AttributesDictionary = [:]

        if let alt = props["Alt"], alt != "null" {
            attrs["Alt"] = .string(alt)
        }
        if let actualText = props["ActualText"], actualText != "null" {
            attrs["ActualText"] = .string(actualText)
        }
        if let title = props["title"], title != "null" {
            attrs["Title"] = .string(title)
        }
        if let lang = props["Lang"], lang != "null" {
            attrs["Lang"] = .string(lang)
        }

        return SemanticNodeAdapter(
            type: semanticType,
            attributes: attrs,
            depth: depth
        )
    }

    // MARK: - Tree Builder

    /// Builds a semantic tree from a ``ParsedDocument``.
    ///
    /// Collects all structure elements from the parsed document,
    /// converts each to a ``SemanticNodeAdapter``, and wraps them
    /// under a document root node.
    ///
    /// The resulting tree has depth 2: a root `.document` node at
    /// depth 0, with each structure element as a child at depth 1.
    ///
    /// - Parameter document: The parsed PDF document.
    /// - Returns: A root ``SemanticNodeAdapter`` with structure element
    ///   children, or `nil` if the document has no structure elements.
    public static func buildTree(from document: any ParsedDocument) -> SemanticNodeAdapter? {
        guard document.hasStructureTree else { return nil }

        // Collect all SE* objects from the document
        var seChildren: [any SemanticNode] = []

        // Known SE type keys that the parser may produce
        let seTypeKeys = [
            "SEFigure", "SETable", "SEFormula", "SEH", "SEHn",
            "SESimpleContentItem", "SESpan", "SEAnnot", "SEDocument",
            "SEPart", "SESect", "SEDiv", "SECaption", "SEL", "SELI",
            "SELBody", "SETR", "SETH", "SETD", "SETHead", "SETBody",
            "SETFoot", "SETOC", "SETOCI", "SENote", "SEArt",
            "SEBlockQuote", "SECode", "SEEm", "SEStrong", "SEQuote",
            "SEIndex", "SETitle",
        ]

        for typeKey in seTypeKeys {
            let objects = document.objects(ofType: typeKey)
            for object in objects {
                guard let seObject = object as? SEGenericObject else { continue }
                if let childNode = SemanticNodeAdapter.fromSEGenericObject(seObject, depth: 1) {
                    seChildren.append(childNode)
                }
            }
        }

        // If no structure elements were found, return nil
        guard !seChildren.isEmpty else { return nil }

        // Create a document root node
        return SemanticNodeAdapter(
            type: .document,
            children: seChildren,
            depth: 0
        )
    }
}
