import Foundation

/// Represents a single XMP (Extensible Metadata Platform) property.
///
/// `XMPProperty` models an individual property within an XMP metadata package.
/// Each property has a namespace, name, and value, and may carry nested
/// qualifier properties (e.g., `xml:lang` attributes on localized text).
///
/// This consolidates the Java `XMPProperty` interface from the veraPDF
/// library into a Swift value type with recursive qualifier support.
///
/// ## Example
/// ```swift
/// let qualifier = XMPProperty(
///     namespace: "http://www.w3.org/XML/1998/namespace",
///     name: "lang",
///     value: "en-US"
/// )
///
/// let title = XMPProperty(
///     namespace: "http://purl.org/dc/elements/1.1/",
///     name: "title",
///     value: "My Document",
///     qualifiers: [qualifier]
/// )
/// ```
public struct XMPProperty: Sendable, Codable, Equatable {

    /// The XMP namespace URI for this property.
    ///
    /// For example, Dublin Core properties use `"http://purl.org/dc/elements/1.1/"`.
    public let namespace: String

    /// The local name of the property within its namespace.
    ///
    /// For example, `"title"`, `"creator"`, `"description"`.
    public let name: String

    /// The string value of the property.
    public let value: String

    /// Nested qualifier properties for this property.
    ///
    /// Qualifiers provide additional metadata about the property value.
    /// For example, an `xml:lang` qualifier indicates the language of
    /// a localized text value. An empty array means no qualifiers.
    public let qualifiers: [XMPProperty]

    /// Creates an XMP property.
    ///
    /// - Parameters:
    ///   - namespace: The XMP namespace URI.
    ///   - name: The local property name.
    ///   - value: The string value.
    ///   - qualifiers: Optional qualifier properties. Defaults to an empty array.
    public init(
        namespace: String,
        name: String,
        value: String,
        qualifiers: [XMPProperty] = []
    ) {
        self.namespace = namespace
        self.name = name
        self.value = value
        self.qualifiers = qualifiers
    }

    /// The fully qualified property name in the form `"{namespace}name"`.
    public var qualifiedName: String {
        "{\(namespace)}\(name)"
    }

    /// Whether this property has any qualifier properties.
    public var hasQualifiers: Bool {
        !qualifiers.isEmpty
    }

    /// Returns the first qualifier matching the given name, if any.
    ///
    /// - Parameter qualifierName: The local name of the qualifier to find.
    /// - Returns: The matching qualifier, or `nil` if not found.
    public func qualifier(named qualifierName: String) -> XMPProperty? {
        qualifiers.first { $0.name == qualifierName }
    }

    /// Returns all qualifiers matching the given namespace.
    ///
    /// - Parameter qualifierNamespace: The namespace URI to filter by.
    /// - Returns: An array of qualifiers in the given namespace.
    public func qualifiers(inNamespace qualifierNamespace: String) -> [XMPProperty] {
        qualifiers.filter { $0.namespace == qualifierNamespace }
    }
}

// MARK: - CustomStringConvertible

extension XMPProperty: CustomStringConvertible {
    public var description: String {
        if qualifiers.isEmpty {
            return "XMPProperty(\(name): \"\(value)\")"
        }
        return "XMPProperty(\(name): \"\(value)\", qualifiers: \(qualifiers.count))"
    }
}

// MARK: - Well-Known Namespaces

extension XMPProperty {

    /// Well-known XMP namespace URIs.
    public enum Namespace {
        /// Dublin Core namespace.
        public static let dublinCore = "http://purl.org/dc/elements/1.1/"

        /// XMP Basic namespace.
        public static let xmpBasic = "http://ns.adobe.com/xap/1.0/"

        /// Adobe PDF namespace.
        public static let adobePDF = "http://ns.adobe.com/pdf/1.3/"

        /// PDF/A Identification namespace.
        public static let pdfaID = "http://www.aiim.org/pdfa/ns/id/"

        /// PDF/UA Identification namespace.
        public static let pdfuaID = "http://www.aiim.org/pdfua/ns/id/"

        /// XMP Rights Management namespace.
        public static let xmpRights = "http://ns.adobe.com/xap/1.0/rights/"

        /// XML namespace.
        public static let xml = "http://www.w3.org/XML/1998/namespace"

        /// RDF namespace.
        public static let rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    }
}
