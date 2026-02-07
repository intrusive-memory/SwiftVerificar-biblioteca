import Foundation
import SwiftVerificarParser

/// Parses XMP data from raw bytes or XML strings.
///
/// `XMPParser` provides methods to parse XMP metadata from `Data` or a raw
/// XML string into an `XMPMetadata` container. Uses Foundation's `XMLParser`
/// with an `XMLParserDelegate` to extract namespace-prefixed properties from
/// the RDF/XML structure used by XMP.
///
/// This consolidates the Java `XMPMetaFactory` class from veraPDF-library.
///
/// ## Parser Package XMP Types
///
/// The `SwiftVerificarParser` package provides its own XMP handling via
/// `SwiftVerificarParser.XMPMetadata`, which represents parsed XMP metadata
/// at the parser level (Dublin Core properties, PDF/A identification,
/// PDF/UA identification). This biblioteca-level `XMPParser` produces the
/// biblioteca's own `XMPMetadata` model type, which is populated by parsing
/// the raw XMP XML using Foundation's `XMLParser`.
///
/// ## Example
/// ```swift
/// let parser = XMPParser()
///
/// let xmpXML = """
/// <x:xmpmeta xmlns:x="adobe:ns:meta/">
///   <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
///     <rdf:Description rdf:about=""
///       xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/"
///       pdfaid:part="2"
///       pdfaid:conformance="u"/>
///   </rdf:RDF>
/// </x:xmpmeta>
/// """
///
/// let metadata = try parser.parse(from: xmpXML)
/// // metadata.pdfaIdentification?.displayName == "PDF/A-2u"
/// ```
public struct XMPParser: Sendable {

    /// Creates an XMP parser.
    public init() {}

    /// Parses XMP metadata from raw `Data`.
    ///
    /// The data is expected to contain a valid XMP/XML document. It is first
    /// decoded as UTF-8 text and then parsed as XML.
    ///
    /// - Parameter data: The raw XMP data bytes.
    /// - Returns: The parsed `XMPMetadata`.
    /// - Throws: `XMPParserError.invalidData` if the data cannot be decoded,
    ///   or `XMPParserError.parsingFailed` if the XML is malformed.
    public func parse(from data: Data) throws -> XMPMetadata {
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw XMPParserError.invalidData("Unable to decode XMP data as UTF-8")
        }
        return try parse(from: xmlString)
    }

    /// Parses XMP metadata from an XML string.
    ///
    /// Uses Foundation's `XMLParser` to extract XMP properties from the
    /// RDF/XML structure. Properties are grouped into `XMPPackage` instances
    /// by their namespace URI.
    ///
    /// The parser operates without namespace processing (`shouldProcessNamespaces = false`)
    /// and manually resolves `prefix:localName` qualified names against `xmlns:` declarations.
    /// This avoids Foundation's `XMLParser` limitation where namespace-aware mode
    /// strips prefix information from attributes.
    ///
    /// - Parameter xmlString: The XMP XML string.
    /// - Returns: The parsed `XMPMetadata`.
    /// - Throws: `XMPParserError.parsingFailed` if the XML is malformed or empty.
    public func parse(from xmlString: String) throws -> XMPMetadata {
        guard !xmlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw XMPParserError.parsingFailed("Empty XMP string")
        }

        guard let data = xmlString.data(using: .utf8) else {
            throw XMPParserError.parsingFailed("Unable to encode XMP string as UTF-8 data")
        }

        let delegate = XMPXMLParserDelegate()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = delegate
        // Do NOT enable namespace processing -- we manually resolve prefixes
        // from xmlns: declarations. This preserves qualified attribute names
        // like "pdfaid:part" that we need for correct namespace resolution.
        xmlParser.shouldProcessNamespaces = false
        xmlParser.shouldReportNamespacePrefixes = false

        let success = xmlParser.parse()

        // If parsing failed but we still collected some properties, use them.
        // Return empty metadata for non-XMP XML or parsing failures with no data.
        if !success && delegate.allProperties.isEmpty {
            return XMPMetadata(packages: [])
        }

        return buildMetadata(from: delegate)
    }

    /// Builds `XMPMetadata` from the collected properties in the delegate.
    private func buildMetadata(from delegate: XMPXMLParserDelegate) -> XMPMetadata {
        // Group properties by namespace URI
        var propertiesByNamespace: [String: [XMPProperty]] = [:]

        for prop in delegate.allProperties {
            propertiesByNamespace[prop.namespace, default: []].append(prop)
        }

        // Build packages from grouped properties
        var packages: [XMPPackage] = []
        for (namespace, properties) in propertiesByNamespace {
            // Skip RDF and XMP meta namespaces -- they are structural, not metadata
            if namespace == XMPProperty.Namespace.rdf { continue }
            if namespace == "adobe:ns:meta/" { continue }
            if namespace == "http://www.w3.org/XML/1998/namespace" { continue }

            let prefix = delegate.prefixForURI[namespace] ?? inferPrefix(for: namespace)

            let package = XMPPackage(
                namespace: namespace,
                prefix: prefix,
                properties: properties
            )
            packages.append(package)
        }

        // Sort packages for deterministic output (alphabetical by namespace)
        packages.sort { $0.namespace < $1.namespace }

        return XMPMetadata(packages: packages)
    }

    /// Infers a prefix from a namespace URI when no explicit mapping is available.
    private func inferPrefix(for namespace: String) -> String {
        switch namespace {
        case XMPProperty.Namespace.pdfaID: return "pdfaid"
        case XMPProperty.Namespace.pdfuaID: return "pdfuaid"
        case XMPProperty.Namespace.dublinCore: return "dc"
        case XMPProperty.Namespace.xmpBasic: return "xmp"
        case XMPProperty.Namespace.adobePDF: return "pdf"
        case XMPProperty.Namespace.xmpRights: return "xmpRights"
        default:
            // Extract last path component or use a generic prefix
            if let lastSlash = namespace.lastIndex(of: "/"),
               lastSlash < namespace.endIndex {
                let afterSlash = namespace[namespace.index(after: lastSlash)...]
                if !afterSlash.isEmpty {
                    return String(afterSlash)
                }
            }
            return "ns"
        }
    }

    /// Errors that can occur during XMP parsing.
    public enum XMPParserError: Error, Sendable, Equatable {
        /// The input data could not be decoded.
        case invalidData(String)

        /// The XML parsing failed.
        case parsingFailed(String)
    }
}

// MARK: - XMP XML Parser Delegate

/// Internal XMLParserDelegate that extracts XMP properties from RDF/XML structure.
///
/// XMP metadata is serialized as RDF/XML within `<x:xmpmeta>` and `<rdf:RDF>`
/// elements. Properties can appear as:
/// 1. Attributes on `<rdf:Description>` elements (simple properties)
/// 2. Child elements of `<rdf:Description>` (simple or structured properties)
///
/// This delegate operates WITHOUT namespace processing, manually resolving
/// `prefix:localName` qualified names against `xmlns:prefix="uri"` declarations
/// found on elements. This avoids Foundation's `XMLParser` limitation where
/// namespace-aware mode strips prefix information from attributes.
private final class XMPXMLParserDelegate: NSObject, XMLParserDelegate, @unchecked Sendable {

    /// All extracted XMP properties (from both attributes and child elements).
    var allProperties: [XMPProperty] = []

    /// Prefix -> URI namespace mappings (from xmlns: declarations).
    /// Maps prefix string to namespace URI string.
    var prefixToURI: [String: String] = [:]

    /// URI -> prefix reverse mapping.
    var prefixForURI: [String: String] = [:]

    /// Whether we are currently inside an rdf:Description element.
    private var insideDescription = false

    /// Current child element qualified name (when inside a property child element).
    private var currentElementQName: String?

    /// Accumulated text content for the current element.
    private var currentTextContent: String = ""

    /// Depth of nesting inside rdf:Description to handle nested elements.
    private var descriptionDepth = 0

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        // Collect xmlns: declarations from attributes
        for (key, value) in attributeDict {
            if key.hasPrefix("xmlns:") {
                let prefix = String(key.dropFirst(6)) // Remove "xmlns:"
                prefixToURI[prefix] = value
                prefixForURI[value] = prefix
            }
        }

        // Check if this is an rdf:Description element
        if isRDFDescription(elementName) {
            insideDescription = true
            descriptionDepth = 0

            // Extract properties from non-xmlns, non-rdf attributes
            extractPropertiesFromAttributes(attributeDict)
            return
        }

        if insideDescription {
            descriptionDepth += 1

            // If direct child of Description, this element IS a property
            if descriptionDepth == 1 {
                currentElementQName = elementName
                currentTextContent = ""
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideDescription && descriptionDepth >= 1 {
            currentTextContent += string
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        // Check if we are ending an rdf:Description
        if isRDFDescription(elementName) {
            insideDescription = false
            descriptionDepth = 0
            return
        }

        if insideDescription {
            if descriptionDepth == 1,
               let qname = currentElementQName {
                let trimmed = currentTextContent.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    if let prop = resolveProperty(qualifiedName: qname, value: trimmed) {
                        allProperties.append(prop)
                    }
                }
                currentElementQName = nil
                currentTextContent = ""
            }

            descriptionDepth -= 1
        }
    }

    // MARK: - Helpers

    /// Checks whether an element name represents `rdf:Description`.
    private func isRDFDescription(_ elementName: String) -> Bool {
        // Without namespace processing, we get "rdf:Description"
        if elementName == "rdf:Description" { return true }
        // Or just "Description" with a prefix that maps to RDF
        if elementName.hasSuffix(":Description") {
            let prefix = String(elementName.dropLast(":Description".count))
            return prefixToURI[prefix] == XMPProperty.Namespace.rdf
        }
        return false
    }

    /// Extracts XMP properties from the attributes of an rdf:Description element.
    ///
    /// Qualified attribute names like `pdfaid:part="2"` are resolved against
    /// the `xmlns:pdfaid="..."` namespace declarations.
    private func extractPropertiesFromAttributes(_ attributes: [String: String]) {
        for (key, value) in attributes {
            // Skip xmlns declarations and rdf:about
            if key.hasPrefix("xmlns") { continue }
            if key == "rdf:about" { continue }
            // Also skip rdf:about when the prefix is different
            if key.hasSuffix(":about") {
                let prefix = String(key.dropLast(":about".count))
                if prefixToURI[prefix] == XMPProperty.Namespace.rdf { continue }
            }

            if let prop = resolveProperty(qualifiedName: key, value: value) {
                allProperties.append(prop)
            }
        }
    }

    /// Resolves a qualified name (e.g., `pdfaid:part`) to an `XMPProperty`
    /// by looking up the prefix in the namespace declarations.
    ///
    /// - Parameters:
    ///   - qualifiedName: The qualified attribute/element name (e.g., `pdfaid:part`).
    ///   - value: The property value.
    /// - Returns: An `XMPProperty` with the resolved namespace, or `nil` if
    ///   the prefix cannot be resolved.
    private func resolveProperty(qualifiedName: String, value: String) -> XMPProperty? {
        let parts = qualifiedName.split(separator: ":", maxSplits: 1)

        if parts.count == 2 {
            let prefix = String(parts[0])
            let localName = String(parts[1])

            guard let namespaceURI = prefixToURI[prefix] else {
                // Unknown prefix -- skip
                return nil
            }

            return XMPProperty(
                namespace: namespaceURI,
                name: localName,
                value: value
            )
        }

        // No prefix -- this is an unnamespaced attribute (skip it)
        return nil
    }
}

// MARK: - CustomStringConvertible

extension XMPParser: CustomStringConvertible {
    public var description: String {
        "XMPParser()"
    }
}

// MARK: - XMPParserError CustomStringConvertible

extension XMPParser.XMPParserError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidData(let reason):
            return "XMPParserError.invalidData: \(reason)"
        case .parsingFailed(let reason):
            return "XMPParserError.parsingFailed: \(reason)"
        }
    }
}
