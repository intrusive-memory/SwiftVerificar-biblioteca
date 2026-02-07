import Foundation

/// XMP (Extensible Metadata Platform) metadata container.
///
/// `XMPMetadata` is the top-level container for all XMP metadata associated
/// with a PDF document. It holds a collection of `XMPPackage` instances,
/// each representing a different metadata schema (e.g., Dublin Core, PDF/A ID,
/// PDF/UA ID).
///
/// This consolidates the Java `XMPMeta` interface from veraPDF-library into a
/// Swift value type with computed accessors for common metadata schemas.
///
/// ## Example
/// ```swift
/// let metadata = XMPMetadata(packages: [
///     XMPPackage(
///         namespace: XMPProperty.Namespace.pdfaID,
///         prefix: "pdfaid",
///         properties: [
///             XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "part", value: "2"),
///             XMPProperty(namespace: XMPProperty.Namespace.pdfaID, name: "conformance", value: "u")
///         ]
///     )
/// ])
///
/// if let pdfa = metadata.pdfaIdentification {
///     print(pdfa.displayName)  // "PDF/A-2u"
/// }
/// ```
public struct XMPMetadata: Sendable, Codable, Equatable {

    /// The XMP packages contained in this metadata block.
    ///
    /// Each package corresponds to a different XMP schema namespace.
    public let packages: [XMPPackage]

    /// Creates an XMP metadata container.
    ///
    /// - Parameter packages: The XMP packages. Defaults to an empty array.
    public init(packages: [XMPPackage] = []) {
        self.packages = packages
    }

    // MARK: - Computed Schema Accessors

    /// The PDF/A identification schema, if present in the metadata.
    ///
    /// Searches all packages for properties in the `pdfaid` namespace
    /// and extracts the part and conformance level.
    public var pdfaIdentification: PDFAIdentification? {
        guard let pdfaPackage = package(forNamespace: XMPProperty.Namespace.pdfaID) else {
            return nil
        }
        guard let partString = pdfaPackage.property(named: "part")?.value,
              let part = Int(partString) else {
            return nil
        }

        let conformance = pdfaPackage.property(named: "conformance")?.value ?? ""
        let amendment = pdfaPackage.property(named: "amd")?.value
        let revision = pdfaPackage.property(named: "rev")?.value

        return PDFAIdentification(
            part: part,
            conformance: conformance,
            amendment: amendment,
            revision: revision
        )
    }

    /// The PDF/UA identification schema, if present in the metadata.
    ///
    /// Searches all packages for properties in the `pdfuaid` namespace
    /// and extracts the part number.
    public var pdfuaIdentification: PDFUAIdentification? {
        guard let pdfuaPackage = package(forNamespace: XMPProperty.Namespace.pdfuaID) else {
            return nil
        }
        guard let partString = pdfuaPackage.property(named: "part")?.value,
              let part = Int(partString) else {
            return nil
        }

        let revision = pdfuaPackage.property(named: "rev")?.value

        return PDFUAIdentification(part: part, revision: revision)
    }

    /// The Dublin Core metadata, if present.
    ///
    /// Searches all packages for properties in the Dublin Core namespace
    /// and creates a `DublinCoreMetadata` instance.
    public var dublinCore: DublinCoreMetadata? {
        guard let dcPackage = package(forNamespace: XMPProperty.Namespace.dublinCore) else {
            return nil
        }
        let dc = DublinCoreMetadata.from(package: dcPackage)
        return dc.isEmpty ? nil : dc
    }

    // MARK: - Package Lookup

    /// Returns the first package matching the given namespace URI.
    ///
    /// - Parameter namespace: The namespace URI to search for.
    /// - Returns: The matching package, or `nil` if not found.
    public func package(forNamespace namespace: String) -> XMPPackage? {
        packages.first { $0.namespace == namespace }
    }

    /// Returns the first package matching the given prefix.
    ///
    /// - Parameter prefix: The namespace prefix to search for.
    /// - Returns: The matching package, or `nil` if not found.
    public func package(forPrefix prefix: String) -> XMPPackage? {
        packages.first { $0.prefix == prefix }
    }

    /// Returns all packages matching the given namespace URI.
    ///
    /// In some XMP serializations, the same namespace may appear in
    /// multiple packages.
    ///
    /// - Parameter namespace: The namespace URI to search for.
    /// - Returns: An array of matching packages.
    public func packages(forNamespace namespace: String) -> [XMPPackage] {
        packages.filter { $0.namespace == namespace }
    }

    /// Whether this metadata block contains any packages.
    public var isEmpty: Bool {
        packages.isEmpty
    }

    /// The total number of packages.
    public var packageCount: Int {
        packages.count
    }

    /// The total number of properties across all packages.
    public var totalPropertyCount: Int {
        packages.reduce(0) { $0 + $1.propertyCount }
    }

    /// All unique namespace URIs present in the metadata.
    public var namespaces: Set<String> {
        Set(packages.map(\.namespace))
    }

    /// Searches all packages for a property with the given namespace and name.
    ///
    /// - Parameters:
    ///   - namespace: The namespace URI.
    ///   - name: The local property name.
    /// - Returns: The first matching property, or `nil` if not found.
    public func property(namespace: String, name: String) -> XMPProperty? {
        for pkg in packages where pkg.namespace == namespace {
            if let prop = pkg.property(named: name) {
                return prop
            }
        }
        return nil
    }
}

// MARK: - CustomStringConvertible

extension XMPMetadata: CustomStringConvertible {
    public var description: String {
        var parts: [String] = ["packages: \(packages.count)"]
        if let pdfa = pdfaIdentification {
            parts.append("pdfa: \(pdfa.displayName)")
        }
        if let pdfua = pdfuaIdentification {
            parts.append("pdfua: \(pdfua.displayName)")
        }
        if dublinCore != nil {
            parts.append("dublinCore: present")
        }
        return "XMPMetadata(\(parts.joined(separator: ", ")))"
    }
}
