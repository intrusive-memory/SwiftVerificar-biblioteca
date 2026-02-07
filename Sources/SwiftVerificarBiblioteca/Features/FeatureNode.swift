import Foundation

/// A tree node representing extracted PDF feature data.
///
/// `FeatureNode` models the hierarchical structure of PDF features.
/// It consolidates the Java `FeatureTreeNode` class from veraPDF-library
/// into a Swift indirect enum with two cases:
///
/// - `.leaf`: A terminal node with a name and an optional string value.
/// - `.branch`: An interior node with a name, an ordered list of children,
///   and a dictionary of attributes.
///
/// The tree structure allows representing arbitrarily nested PDF features
/// such as font cascades, color space hierarchies, or annotation trees.
///
/// ## Example
/// ```swift
/// let tree = FeatureNode.branch(
///     name: "Document",
///     children: [
///         .leaf(name: "Title", value: "My PDF"),
///         .branch(name: "Fonts", children: [
///             .leaf(name: "Font", value: "Helvetica"),
///             .leaf(name: "Font", value: "Times-Roman"),
///         ], attributes: ["count": "2"]),
///     ],
///     attributes: [:]
/// )
/// ```
public indirect enum FeatureNode: Sendable, Equatable {

    /// A terminal node carrying a name and an optional string value.
    ///
    /// - Parameters:
    ///   - name: The name of this feature entry.
    ///   - value: The value associated with this entry, or `nil` if absent.
    case leaf(name: String, value: String?)

    /// An interior node carrying a name, child nodes, and attributes.
    ///
    /// - Parameters:
    ///   - name: The name of this feature group.
    ///   - children: Ordered child nodes within this group.
    ///   - attributes: Key-value metadata associated with this node.
    case branch(name: String, children: [FeatureNode], attributes: [String: String])

    /// The name of this node regardless of case.
    public var name: String {
        switch self {
        case .leaf(let name, _):
            return name
        case .branch(let name, _, _):
            return name
        }
    }

    /// Whether this node is a leaf (has no children).
    public var isLeaf: Bool {
        switch self {
        case .leaf:
            return true
        case .branch:
            return false
        }
    }

    /// The value of a leaf node, or `nil` for branch nodes.
    public var value: String? {
        switch self {
        case .leaf(_, let value):
            return value
        case .branch:
            return nil
        }
    }

    /// The children of a branch node, or an empty array for leaf nodes.
    public var children: [FeatureNode] {
        switch self {
        case .leaf:
            return []
        case .branch(_, let children, _):
            return children
        }
    }

    /// The attributes of a branch node, or an empty dictionary for leaf nodes.
    public var attributes: [String: String] {
        switch self {
        case .leaf:
            return [:]
        case .branch(_, _, let attributes):
            return attributes
        }
    }

    /// The total number of nodes in the subtree rooted at this node (including self).
    public var nodeCount: Int {
        switch self {
        case .leaf:
            return 1
        case .branch(_, let children, _):
            return 1 + children.reduce(0) { $0 + $1.nodeCount }
        }
    }

    /// The depth of the deepest path from this node to a leaf.
    ///
    /// A leaf has depth 0. A branch with only leaf children has depth 1.
    public var depth: Int {
        switch self {
        case .leaf:
            return 0
        case .branch(_, let children, _):
            if children.isEmpty {
                return 0
            }
            return 1 + (children.map(\.depth).max() ?? 0)
        }
    }

    /// Returns the first child node with the given name, or `nil` if none.
    ///
    /// - Parameter childName: The name to search for among direct children.
    /// - Returns: The first matching child, or `nil`.
    public func child(named childName: String) -> FeatureNode? {
        children.first { $0.name == childName }
    }

    /// Returns all descendant leaf values, in depth-first order.
    public var allLeafValues: [String] {
        switch self {
        case .leaf(_, let value):
            if let value {
                return [value]
            }
            return []
        case .branch(_, let children, _):
            return children.flatMap(\.allLeafValues)
        }
    }
}

// MARK: - Codable

extension FeatureNode: Codable {

    private enum CodingKeys: String, CodingKey {
        case type
        case name
        case value
        case children
        case attributes
    }

    private enum NodeType: String, Codable {
        case leaf
        case branch
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(NodeType.self, forKey: .type)

        switch type {
        case .leaf:
            let name = try container.decode(String.self, forKey: .name)
            let value = try container.decodeIfPresent(String.self, forKey: .value)
            self = .leaf(name: name, value: value)
        case .branch:
            let name = try container.decode(String.self, forKey: .name)
            let children = try container.decode([FeatureNode].self, forKey: .children)
            let attributes = try container.decode([String: String].self, forKey: .attributes)
            self = .branch(name: name, children: children, attributes: attributes)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .leaf(let name, let value):
            try container.encode(NodeType.leaf, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(value, forKey: .value)
        case .branch(let name, let children, let attributes):
            try container.encode(NodeType.branch, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(children, forKey: .children)
            try container.encode(attributes, forKey: .attributes)
        }
    }
}

// MARK: - CustomStringConvertible

extension FeatureNode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .leaf(let name, let value):
            if let value {
                return "\(name): \(value)"
            }
            return name
        case .branch(let name, let children, _):
            return "\(name) [\(children.count) children]"
        }
    }
}
