import Foundation

/// Dublin Core metadata extracted from an XMP metadata block.
///
/// `DublinCoreMetadata` provides a structured view of the Dublin Core
/// elements commonly found in PDF document metadata. Dublin Core is a
/// widely-used metadata standard that provides basic bibliographic
/// information about a document.
///
/// The Dublin Core namespace URI is `http://purl.org/dc/elements/1.1/`.
///
/// Note: The Dublin Core "description" element is exposed as `dcDescription`
/// to avoid conflict with the `CustomStringConvertible` `description` property.
///
/// ## Example
/// ```swift
/// let dc = DublinCoreMetadata(
///     title: "Accessibility Report",
///     creator: "SwiftVerificar",
///     dcDescription: "PDF/UA compliance validation results",
///     subject: ["accessibility", "PDF/UA", "validation"]
/// )
/// ```
public struct DublinCoreMetadata: Sendable, Codable, Equatable {

    /// The document title.
    public let title: String?

    /// The document creator (author).
    public let creator: String?

    /// A description or abstract of the document.
    ///
    /// Named `dcDescription` to avoid conflict with `CustomStringConvertible.description`.
    /// This maps to the Dublin Core `dc:description` element.
    public let dcDescription: String?

    /// Subject keywords or categories.
    public let subject: [String]

    /// The document publisher.
    public let publisher: String?

    /// A contributor to the document.
    public let contributor: String?

    /// The date associated with the document (e.g., creation date).
    public let date: String?

    /// The document type (e.g., "report", "article").
    public let type: String?

    /// The document format (e.g., "application/pdf").
    public let format: String?

    /// A unique identifier for the document.
    public let identifier: String?

    /// The source from which this document was derived.
    public let source: String?

    /// The language of the document content.
    public let language: String?

    /// A related resource.
    public let relation: String?

    /// The extent or scope of the document content.
    public let coverage: String?

    /// Information about rights held in and over the document.
    public let rights: String?

    /// Creates a Dublin Core metadata instance.
    ///
    /// All parameters are optional and default to `nil` or empty arrays.
    ///
    /// - Parameters:
    ///   - title: The document title.
    ///   - creator: The document creator.
    ///   - dcDescription: A document description (Dublin Core `dc:description`).
    ///   - subject: Subject keywords. Defaults to an empty array.
    ///   - publisher: The publisher.
    ///   - contributor: A contributor.
    ///   - date: A date string.
    ///   - type: The document type.
    ///   - format: The document format.
    ///   - identifier: A unique identifier.
    ///   - source: The source.
    ///   - language: The language.
    ///   - relation: A related resource.
    ///   - coverage: The coverage.
    ///   - rights: Rights information.
    public init(
        title: String? = nil,
        creator: String? = nil,
        dcDescription: String? = nil,
        subject: [String] = [],
        publisher: String? = nil,
        contributor: String? = nil,
        date: String? = nil,
        type: String? = nil,
        format: String? = nil,
        identifier: String? = nil,
        source: String? = nil,
        language: String? = nil,
        relation: String? = nil,
        coverage: String? = nil,
        rights: String? = nil
    ) {
        self.title = title
        self.creator = creator
        self.dcDescription = dcDescription
        self.subject = subject
        self.publisher = publisher
        self.contributor = contributor
        self.date = date
        self.type = type
        self.format = format
        self.identifier = identifier
        self.source = source
        self.language = language
        self.relation = relation
        self.coverage = coverage
        self.rights = rights
    }

    /// Whether all Dublin Core fields are empty (nil or empty).
    public var isEmpty: Bool {
        title == nil &&
        creator == nil &&
        dcDescription == nil &&
        subject.isEmpty &&
        publisher == nil &&
        contributor == nil &&
        date == nil &&
        type == nil &&
        format == nil &&
        identifier == nil &&
        source == nil &&
        language == nil &&
        relation == nil &&
        coverage == nil &&
        rights == nil
    }

    /// The number of non-nil fields populated in this metadata.
    public var populatedFieldCount: Int {
        var count = 0
        if title != nil { count += 1 }
        if creator != nil { count += 1 }
        if dcDescription != nil { count += 1 }
        if !subject.isEmpty { count += 1 }
        if publisher != nil { count += 1 }
        if contributor != nil { count += 1 }
        if date != nil { count += 1 }
        if type != nil { count += 1 }
        if format != nil { count += 1 }
        if identifier != nil { count += 1 }
        if source != nil { count += 1 }
        if language != nil { count += 1 }
        if relation != nil { count += 1 }
        if coverage != nil { count += 1 }
        if rights != nil { count += 1 }
        return count
    }

    /// Creates a `DublinCoreMetadata` from an `XMPPackage` in the Dublin Core namespace.
    ///
    /// This factory method extracts Dublin Core fields from the XMP properties
    /// in the given package. Properties not in the Dublin Core namespace are ignored.
    ///
    /// - Parameter package: The XMP package to extract Dublin Core from.
    /// - Returns: A `DublinCoreMetadata` populated from the package's properties.
    public static func from(package: XMPPackage) -> DublinCoreMetadata {
        DublinCoreMetadata(
            title: package.property(named: "title")?.value,
            creator: package.property(named: "creator")?.value,
            dcDescription: package.property(named: "description")?.value,
            subject: package.properties(named: "subject").map(\.value),
            publisher: package.property(named: "publisher")?.value,
            contributor: package.property(named: "contributor")?.value,
            date: package.property(named: "date")?.value,
            type: package.property(named: "type")?.value,
            format: package.property(named: "format")?.value,
            identifier: package.property(named: "identifier")?.value,
            source: package.property(named: "source")?.value,
            language: package.property(named: "language")?.value,
            relation: package.property(named: "relation")?.value,
            coverage: package.property(named: "coverage")?.value,
            rights: package.property(named: "rights")?.value
        )
    }
}

// MARK: - CustomStringConvertible

extension DublinCoreMetadata: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        if let title { parts.append("title: \"\(title)\"") }
        if let creator { parts.append("creator: \"\(creator)\"") }
        if let dcDescription { parts.append("description: \"\(dcDescription)\"") }
        if !subject.isEmpty { parts.append("subject: \(subject)") }
        if parts.isEmpty {
            return "DublinCoreMetadata(empty)"
        }
        return "DublinCoreMetadata(\(parts.joined(separator: ", ")))"
    }
}
