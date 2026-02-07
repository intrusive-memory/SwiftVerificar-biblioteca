import Foundation

/// A parsed PDF document ready for validation.
///
/// This protocol defines the minimal contract that a parsed PDF document
/// must satisfy for the validation engine to evaluate rules against it.
/// It will be fully implemented in Sprint 6 when the `PDFParser` and
/// `SwiftPDFParser` types are built.
///
/// For now, this serves as the interface contract between the validator
/// (Sprint 5) and the parser (Sprint 6). The validator accepts any
/// `ParsedDocument` conformer and iterates over its validation objects.
///
/// ## Relationship to Other Packages
///
/// The actual parsing logic lives in `SwiftVerificar-parser`. This
/// protocol lives in `SwiftVerificar-biblioteca` because it is the
/// integration-layer contract that connects the parser output to the
/// validation input.
public protocol ParsedDocument: Sendable {

    /// The URL of the PDF document that was parsed.
    var url: URL { get }

    /// The detected PDF flavour (e.g., PDF/A-2b, PDF/UA-1), if any.
    ///
    /// Returns `nil` if the document does not declare a conformance
    /// level via XMP metadata or other identification mechanisms.
    var flavour: String? { get }

    /// Returns all validation objects of the specified type.
    ///
    /// The `objectType` string corresponds to the `object` attribute
    /// in validation profile rules (e.g., "CosDocument", "PDPage",
    /// "SEFigure"). The validator uses this to find all objects that
    /// a given rule should be evaluated against.
    ///
    /// - Parameter objectType: The type identifier to query.
    /// - Returns: An array of validation objects matching the type.
    func objects(ofType objectType: String) -> [any ValidationObject]
}

/// A PDF object that can be validated against profile rules.
///
/// Each `ValidationObject` exposes a dictionary of properties
/// that the rule expression evaluator reads when checking whether
/// the object satisfies a rule's test expression.
///
/// This protocol will be fully fleshed out in Sprint 6. For now
/// it captures the minimal interface the validator needs.
public protocol ValidationObject: Sendable {

    /// The properties of this object available for rule evaluation.
    ///
    /// Keys are property names as they appear in the validation profile
    /// rule test expressions. Values are the property values.
    var validationProperties: [String: String] { get }

    /// The location of this object within the PDF document.
    ///
    /// Used to populate the ``PDFLocation`` in ``TestAssertion``
    /// results so the user can find the flagged element.
    var location: PDFLocation? { get }
}
