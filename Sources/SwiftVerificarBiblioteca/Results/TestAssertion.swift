import Foundation
import SwiftVerificarValidationProfiles

/// A single test assertion recording whether a validation rule passed or
/// failed for a specific PDF object.
///
/// Each `TestAssertion` captures the outcome of evaluating one
/// ``SwiftVerificarValidationProfiles/ValidationRule`` against one PDF
/// object, including the rule identifier, status, human-readable message,
/// optional location, and any arguments used for message formatting.
///
/// This is the Swift equivalent of Java's `TestAssertion` interface and
/// `TestAssertionImpl` class in veraPDF-library, consolidated into a
/// single `Identifiable` value type.
///
/// ## Example
/// ```swift
/// let assertion = TestAssertion(
///     id: UUID(),
///     ruleID: RuleID(specification: .iso142892, clause: "8.2.5.26", testNumber: 1),
///     status: .failed,
///     message: "Structure element does not have Alt text",
///     location: PDFLocation(pageNumber: 3, structureID: "SE-17"),
///     context: "Figure",
///     arguments: ["Alt", "Figure"]
/// )
/// ```
public struct TestAssertion: Sendable, Equatable, Codable, Identifiable, Hashable {

    /// Unique identifier for this assertion instance.
    public let id: UUID

    /// The rule that was evaluated to produce this assertion.
    ///
    /// References a ``SwiftVerificarValidationProfiles/RuleID`` from the
    /// validation-profiles package, linking this result back to the
    /// specification clause and test number.
    public let ruleID: RuleID

    /// The outcome of the rule evaluation.
    public let status: AssertionStatus

    /// A human-readable message describing the assertion outcome.
    ///
    /// For failed assertions this typically describes the violation.
    /// For passed assertions it may be empty or a confirmation message.
    public let message: String

    /// The location within the PDF document where the assertion applies.
    ///
    /// May be `nil` for document-level rules that are not tied to a
    /// specific object or location.
    public let location: PDFLocation?

    /// Additional context about the PDF object that was tested.
    ///
    /// For example, the type of structure element (e.g., "Figure", "Table")
    /// or the operator being checked. May be `nil` if no additional
    /// context is relevant.
    public let context: String?

    /// Arguments used for message formatting.
    ///
    /// These correspond to the `<argument>` elements in the XML error
    /// specification. They are property names whose values were substituted
    /// into the message template.
    public let arguments: [String]

    /// Creates a new `TestAssertion`.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new `UUID`.
    ///   - ruleID: The rule that was evaluated.
    ///   - status: The outcome of the evaluation.
    ///   - message: A human-readable message.
    ///   - location: The location in the PDF document. Defaults to `nil`.
    ///   - context: Additional context. Defaults to `nil`.
    ///   - arguments: Message formatting arguments. Defaults to an empty array.
    public init(
        id: UUID = UUID(),
        ruleID: RuleID,
        status: AssertionStatus,
        message: String,
        location: PDFLocation? = nil,
        context: String? = nil,
        arguments: [String] = []
    ) {
        self.id = id
        self.ruleID = ruleID
        self.status = status
        self.message = message
        self.location = location
        self.context = context
        self.arguments = arguments
    }
}

// MARK: - CustomStringConvertible

extension TestAssertion: CustomStringConvertible {
    public var description: String {
        let loc = location.map { " at \($0)" } ?? ""
        return "TestAssertion(\(ruleID.uniqueID): \(status)\(loc))"
    }
}
