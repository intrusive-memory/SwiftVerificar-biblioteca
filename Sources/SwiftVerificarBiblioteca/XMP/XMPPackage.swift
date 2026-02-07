import Foundation

/// A package within XMP metadata.
///
/// `XMPPackage` represents a single schema package within an XMP metadata
/// block. Each package is associated with a namespace URI and prefix, and
/// contains a collection of properties defined in that namespace.
///
/// In XMP, metadata is organized into packages (also called schemas). Common
/// packages include Dublin Core (`dc:`), XMP Basic (`xmp:`), and PDF/A
/// Identification (`pdfaid:`).
///
/// ## Example
/// ```swift
/// let package = XMPPackage(
///     namespace: "http://purl.org/dc/elements/1.1/",
///     prefix: "dc",
///     properties: [
///         XMPProperty(
///             namespace: "http://purl.org/dc/elements/1.1/",
///             name: "title",
///             value: "My Document"
///         )
///     ]
/// )
/// ```
public struct XMPPackage: Sendable, Codable, Equatable {

    /// The namespace URI for this package.
    public let namespace: String

    /// The namespace prefix used in the XMP serialization.
    public let prefix: String

    /// The properties defined in this package.
    public let properties: [XMPProperty]

    /// Creates an XMP package.
    ///
    /// - Parameters:
    ///   - namespace: The namespace URI.
    ///   - prefix: The namespace prefix.
    ///   - properties: The properties in this package. Defaults to an empty array.
    public init(
        namespace: String,
        prefix: String,
        properties: [XMPProperty] = []
    ) {
        self.namespace = namespace
        self.prefix = prefix
        self.properties = properties
    }

    /// Whether this package contains any properties.
    public var isEmpty: Bool {
        properties.isEmpty
    }

    /// The number of properties in this package.
    public var propertyCount: Int {
        properties.count
    }

    /// Returns the first property matching the given name, if any.
    ///
    /// - Parameter name: The local property name to search for.
    /// - Returns: The matching property, or `nil` if not found.
    public func property(named name: String) -> XMPProperty? {
        properties.first { $0.name == name }
    }

    /// Returns all properties matching the given name.
    ///
    /// Some XMP schemas allow repeated property names (e.g., array items).
    ///
    /// - Parameter name: The local property name to search for.
    /// - Returns: An array of matching properties.
    public func properties(named name: String) -> [XMPProperty] {
        properties.filter { $0.name == name }
    }

    /// Whether this package contains a property with the given name.
    ///
    /// - Parameter name: The local property name to check.
    /// - Returns: `true` if a property with this name exists.
    public func containsProperty(named name: String) -> Bool {
        properties.contains { $0.name == name }
    }
}

// MARK: - CustomStringConvertible

extension XMPPackage: CustomStringConvertible {
    public var description: String {
        "XMPPackage(\(prefix): \(namespace), properties: \(properties.count))"
    }
}
