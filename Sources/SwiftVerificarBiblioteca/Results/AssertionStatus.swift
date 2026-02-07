import Foundation

/// The outcome status of a single test assertion.
///
/// This enum represents the three possible outcomes when a validation rule
/// is evaluated against a PDF object. It is the Swift equivalent of Java's
/// `TestAssertion.Status` enum in veraPDF-library.
///
/// ## Usage
/// ```swift
/// let status: AssertionStatus = .passed
/// print(status.isPassed) // true
/// ```
///
/// - Note: The "unknown" case is used when a rule could not be evaluated,
///   for example due to a missing property or an expression evaluation error.
public enum AssertionStatus: String, Sendable, Codable, CaseIterable, Equatable, Hashable {

    /// The rule's test expression evaluated to `true` for the PDF object.
    case passed

    /// The rule's test expression evaluated to `false` for the PDF object.
    case failed

    /// The rule could not be evaluated (e.g., missing property, expression error).
    case unknown

    // MARK: - Convenience

    /// Whether this status represents a passing assertion.
    public var isPassed: Bool {
        self == .passed
    }

    /// Whether this status represents a failing assertion.
    public var isFailed: Bool {
        self == .failed
    }

    /// Whether this status is indeterminate.
    public var isUnknown: Bool {
        self == .unknown
    }
}

// MARK: - CustomStringConvertible

extension AssertionStatus: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
