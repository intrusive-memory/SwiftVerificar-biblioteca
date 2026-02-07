import Foundation
import SwiftVerificarValidationProfiles

/// Default Swift implementation of the ``PDFParser`` protocol.
///
/// `SwiftPDFParser` is the concrete parser that will eventually
/// integrate with the `SwiftVerificar-parser` package to provide
/// full PDF parsing capabilities. Currently it serves as a
/// placeholder stub that validates input and throws an appropriate
/// error, because the real parser integration happens during the
/// reconciliation pass.
///
/// ## Java-to-Swift Mapping
///
/// | Java Class        | Swift Mapping                         |
/// |------------------|---------------------------------------|
/// | `GFModelParser`   | `SwiftPDFParser` struct               |
///
/// ## Current Limitations
///
/// - ``parse()`` throws ``VerificarError/configurationError(reason:)``
///   because the parser package integration is not yet wired up.
/// - ``detectFlavour()`` throws the same error for the same reason.
///
/// These will be replaced with real implementations during
/// reconciliation when `SwiftVerificar-parser` types are available.
///
/// ## Thread Safety
///
/// `SwiftPDFParser` is a value type (`struct`) with no mutable
/// state, and conforms to `Sendable`.
///
/// ## Usage
///
/// ```swift
/// let parser = SwiftPDFParser(url: pdfURL)
/// let document = try await parser.parse()  // Currently throws
/// ```
public struct SwiftPDFParser: PDFParser, Sendable, Equatable {

    /// The URL of the PDF document to be parsed.
    public let url: URL

    /// Creates a new `SwiftPDFParser` for the given document URL.
    ///
    /// - Parameter url: The file URL of the PDF document to parse.
    public init(url: URL) {
        self.url = url
    }

    // MARK: - PDFParser

    /// Parse the PDF document.
    ///
    /// **Current behavior**: Throws ``VerificarError/configurationError(reason:)``
    /// because the parser package integration is not yet available.
    /// This will be replaced with a real implementation during
    /// reconciliation.
    ///
    /// - Returns: A ``ParsedDocument`` representing the parsed PDF.
    /// - Throws: ``VerificarError/configurationError(reason:)`` always
    ///   (until reconciliation wires up the real parser).
    public func parse() async throws -> any ParsedDocument {
        throw VerificarError.configurationError(
            reason: "PDF parser not yet integrated. "
                + "SwiftVerificar-parser integration pending reconciliation."
        )
    }

    /// Detect the PDF flavour from the document's metadata.
    ///
    /// **Current behavior**: Throws ``VerificarError/configurationError(reason:)``
    /// because the parser package integration is not yet available.
    ///
    /// - Returns: A ``PDFFlavour`` value, or `nil`.
    /// - Throws: ``VerificarError/configurationError(reason:)`` always
    ///   (until reconciliation wires up the real parser).
    public func detectFlavour() async throws -> PDFFlavour? {
        throw VerificarError.configurationError(
            reason: "PDF flavour detection not yet integrated. "
                + "SwiftVerificar-parser integration pending reconciliation."
        )
    }

    // MARK: - Equatable

    public static func == (lhs: SwiftPDFParser, rhs: SwiftPDFParser) -> Bool {
        lhs.url == rhs.url
    }
}

// MARK: - ValidatorComponent

extension SwiftPDFParser: ValidatorComponent {
    /// Component metadata for this parser.
    public var info: ComponentInfo {
        ComponentInfo(
            name: "SwiftPDFParser",
            version: SwiftVerificarBiblioteca.version,
            componentDescription: "PDF document parser for: \(url.lastPathComponent)",
            provider: "SwiftVerificar Project"
        )
    }
}

// MARK: - CustomStringConvertible

extension SwiftPDFParser: CustomStringConvertible {
    public var description: String {
        "SwiftPDFParser(url: \(url.lastPathComponent))"
    }
}
