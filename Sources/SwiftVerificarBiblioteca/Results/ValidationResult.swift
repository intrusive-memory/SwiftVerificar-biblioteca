import Foundation
import SwiftVerificarValidationProfiles

/// The top-level result of validating a PDF document against a profile.
///
/// `ValidationResult` is the primary type consumed by the Lazarillo app.
/// It aggregates all ``TestAssertion`` instances produced during a
/// validation run, provides overall compliance status, and carries timing
/// information via ``ValidationDuration``.
///
/// This is the Swift equivalent of Java's `ValidationResult` interface and
/// `ValidationResultImpl` class in veraPDF-library, consolidated into a
/// single value type.
///
/// ## Example
/// ```swift
/// let result = ValidationResult(
///     profileName: "PDF/UA-2 validation profile",
///     documentURL: pdfURL,
///     isCompliant: false,
///     assertions: [assertion1, assertion2],
///     duration: ValidationDuration(start: startDate, end: endDate)
/// )
/// print(result.failedCount)       // number of failures
/// print(result.failedByRule)      // failures grouped by rule
/// ```
///
/// - Note: The `profileName` field is a `String` rather than a direct
///   ``SwiftVerificarValidationProfiles/ValidationProfile`` reference to
///   keep serialization lightweight and avoid embedding the full profile
///   in every result.
public struct ValidationResult: Sendable, Equatable, Codable, Hashable {

    /// The name of the validation profile used.
    ///
    /// This is a human-readable identifier (e.g., "PDF/UA-2 validation profile")
    /// rather than the full ``SwiftVerificarValidationProfiles/ValidationProfile``
    /// struct to keep the result lightweight and serializable.
    public let profileName: String

    /// The URL of the PDF document that was validated.
    public let documentURL: URL

    /// Whether the document is fully compliant with the profile.
    ///
    /// `true` if and only if no assertion has a ``AssertionStatus/failed`` status.
    public let isCompliant: Bool

    /// All individual test assertions produced during validation.
    ///
    /// This includes passed, failed, and unknown assertions depending on
    /// the validator configuration (e.g., `recordPassedAssertions`).
    public let assertions: [TestAssertion]

    /// Timing information for the validation run.
    public let duration: ValidationDuration

    /// Creates a new `ValidationResult`.
    ///
    /// - Parameters:
    ///   - profileName: The name of the validation profile used.
    ///   - documentURL: The URL of the validated PDF document.
    ///   - isCompliant: Whether the document is fully compliant.
    ///   - assertions: All test assertions.
    ///   - duration: Timing information.
    public init(
        profileName: String,
        documentURL: URL,
        isCompliant: Bool,
        assertions: [TestAssertion],
        duration: ValidationDuration
    ) {
        self.profileName = profileName
        self.documentURL = documentURL
        self.isCompliant = isCompliant
        self.assertions = assertions
        self.duration = duration
    }

    // MARK: - Computed Properties

    /// The number of assertions that passed.
    public var passedCount: Int {
        assertions.count(where: { $0.status == .passed })
    }

    /// The number of assertions that failed.
    public var failedCount: Int {
        assertions.count(where: { $0.status == .failed })
    }

    /// The number of assertions with unknown status.
    public var unknownCount: Int {
        assertions.count(where: { $0.status == .unknown })
    }

    /// The total number of assertions.
    public var totalCount: Int {
        assertions.count
    }

    /// Failed assertions grouped by their rule identifier.
    ///
    /// Useful for summarizing failures per rule rather than per object.
    public var failedByRule: [RuleID: [TestAssertion]] {
        Dictionary(grouping: assertions.filter { $0.status == .failed }) { $0.ruleID }
    }

    /// All unique rule identifiers that have at least one failure.
    public var failedRuleIDs: Set<RuleID> {
        Set(assertions.filter { $0.status == .failed }.map(\.ruleID))
    }

    /// All unique error codes (rule unique IDs) for failed assertions.
    public var errorCodes: Set<String> {
        Set(assertions.filter { $0.status == .failed }.map { $0.ruleID.uniqueID })
    }

    /// All assertions filtered by the given status.
    ///
    /// - Parameter status: The status to filter by.
    /// - Returns: An array of assertions matching the given status.
    public func assertions(withStatus status: AssertionStatus) -> [TestAssertion] {
        assertions.filter { $0.status == status }
    }

    // MARK: - Factory Methods

    /// Creates a `ValidationResult` representing a compliant document with no assertions.
    ///
    /// - Parameters:
    ///   - profileName: The name of the validation profile.
    ///   - documentURL: The URL of the validated document.
    ///   - duration: Timing information.
    /// - Returns: A compliant result with an empty assertion list.
    public static func compliant(
        profileName: String,
        documentURL: URL,
        duration: ValidationDuration
    ) -> ValidationResult {
        ValidationResult(
            profileName: profileName,
            documentURL: documentURL,
            isCompliant: true,
            assertions: [],
            duration: duration
        )
    }
}

// MARK: - CustomStringConvertible

extension ValidationResult: CustomStringConvertible {
    public var description: String {
        let status = isCompliant ? "COMPLIANT" : "NON-COMPLIANT"
        return "ValidationResult(\(status): \(passedCount) passed, \(failedCount) failed, \(unknownCount) unknown — \(duration))"
    }
}
