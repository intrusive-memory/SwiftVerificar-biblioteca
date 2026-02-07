import Foundation

/// The main XMP package from a PDF document.
///
/// `MainXMPPackage` represents the primary XMP metadata package associated
/// with a PDF document. It provides direct access to the properties within
/// the package as well as computed accessors for PDF/A and PDF/UA identification
/// schemas.
///
/// This consolidates the Java `AXLMainXMPPackage` class from veraPDF-library
/// into a Swift value type.
///
/// ## Example
/// ```swift
/// let package = MainXMPPackage(
///     properties: [
///         XMPProperty(
///             namespace: XMPProperty.Namespace.pdfaID,
///             name: "part",
///             value: "2"
///         ),
///         XMPProperty(
///             namespace: XMPProperty.Namespace.pdfaID,
///             name: "conformance",
///             value: "u"
///         )
///     ]
/// )
///
/// print(package.pdfaIdentification?.displayName)  // "PDF/A-2u"
/// ```
public struct MainXMPPackage: Sendable, Codable, Equatable {

    /// The XMP properties contained in this main package.
    public let properties: [XMPProperty]

    /// An explicit PDF/A identification, if available.
    ///
    /// When set directly, this value takes priority over computed extraction
    /// from properties. When `nil`, the identification is computed from
    /// the `pdfaid:` properties.
    public let pdfaIdentification: PDFAIdentification?

    /// An explicit PDF/UA identification, if available.
    ///
    /// When set directly, this value takes priority over computed extraction
    /// from properties. When `nil`, the identification is computed from
    /// the `pdfuaid:` properties.
    public let pdfuaIdentification: PDFUAIdentification?

    /// Creates a main XMP package.
    ///
    /// - Parameters:
    ///   - properties: The XMP properties.
    ///   - pdfaIdentification: An explicit PDF/A identification. Defaults to `nil`.
    ///   - pdfuaIdentification: An explicit PDF/UA identification. Defaults to `nil`.
    public init(
        properties: [XMPProperty] = [],
        pdfaIdentification: PDFAIdentification? = nil,
        pdfuaIdentification: PDFUAIdentification? = nil
    ) {
        self.properties = properties
        self.pdfaIdentification = pdfaIdentification
        self.pdfuaIdentification = pdfuaIdentification
    }

    /// Extracts the PDF/A identification from the properties if no explicit value was set.
    ///
    /// Looks for `pdfaid:part` and `pdfaid:conformance` properties in the
    /// PDF/A Identification namespace.
    ///
    /// - Returns: The extracted `PDFAIdentification`, or `nil` if not found.
    public var resolvedPDFAIdentification: PDFAIdentification? {
        if let pdfaIdentification {
            return pdfaIdentification
        }
        return extractPDFAIdentification()
    }

    /// Extracts the PDF/UA identification from the properties if no explicit value was set.
    ///
    /// Looks for `pdfuaid:part` in the PDF/UA Identification namespace.
    ///
    /// - Returns: The extracted `PDFUAIdentification`, or `nil` if not found.
    public var resolvedPDFUAIdentification: PDFUAIdentification? {
        if let pdfuaIdentification {
            return pdfuaIdentification
        }
        return extractPDFUAIdentification()
    }

    /// The number of properties in this package.
    public var propertyCount: Int {
        properties.count
    }

    /// Whether this package has any properties.
    public var isEmpty: Bool {
        properties.isEmpty
    }

    /// Returns the first property matching the given name.
    ///
    /// - Parameter name: The local property name.
    /// - Returns: The matching property, or `nil` if not found.
    public func property(named name: String) -> XMPProperty? {
        properties.first { $0.name == name }
    }

    /// Returns all properties in the given namespace.
    ///
    /// - Parameter namespace: The namespace URI to filter by.
    /// - Returns: An array of properties in the namespace.
    public func properties(inNamespace namespace: String) -> [XMPProperty] {
        properties.filter { $0.namespace == namespace }
    }

    // MARK: - Private Extraction

    private func extractPDFAIdentification() -> PDFAIdentification? {
        let pdfaProperties = properties(inNamespace: XMPProperty.Namespace.pdfaID)
        guard let partString = pdfaProperties.first(where: { $0.name == "part" })?.value,
              let part = Int(partString) else {
            return nil
        }

        let conformance = pdfaProperties.first(where: { $0.name == "conformance" })?.value ?? ""
        let amendment = pdfaProperties.first(where: { $0.name == "amd" })?.value
        let revision = pdfaProperties.first(where: { $0.name == "rev" })?.value

        return PDFAIdentification(
            part: part,
            conformance: conformance,
            amendment: amendment,
            revision: revision
        )
    }

    private func extractPDFUAIdentification() -> PDFUAIdentification? {
        let pdfuaProperties = properties(inNamespace: XMPProperty.Namespace.pdfuaID)
        guard let partString = pdfuaProperties.first(where: { $0.name == "part" })?.value,
              let part = Int(partString) else {
            return nil
        }

        let revision = pdfuaProperties.first(where: { $0.name == "rev" })?.value

        return PDFUAIdentification(part: part, revision: revision)
    }
}

// MARK: - CustomStringConvertible

extension MainXMPPackage: CustomStringConvertible {
    public var description: String {
        var parts: [String] = ["properties: \(properties.count)"]
        if let pdfa = resolvedPDFAIdentification {
            parts.append("pdfa: \(pdfa.displayName)")
        }
        if let pdfua = resolvedPDFUAIdentification {
            parts.append("pdfua: \(pdfua.displayName)")
        }
        return "MainXMPPackage(\(parts.joined(separator: ", ")))"
    }
}
