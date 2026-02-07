import Foundation
import SwiftVerificarValidationProfiles

/// Summary statistics for a single validation rule across all assertions.
///
/// `RuleSummary` aggregates the pass/fail counts for a particular
/// ``SwiftVerificarValidationProfiles/RuleID`` within a
/// ``ValidationResult``. It is produced by ``ValidationReport/generate(from:)``
/// and sorted by ``failedCount`` descending so that the most problematic
/// rules appear first.
///
/// This is the Swift equivalent of Java's `RuleSummary` interface in
/// veraPDF-library, consolidated into a single value type.
///
/// ## Example
/// ```swift
/// let summary = RuleSummary(
///     ruleID: RuleID(specification: .iso142892, clause: "8.2.5.26", testNumber: 1),
///     passedCount: 12,
///     failedCount: 3,
///     ruleDescription: "Structure element does not have Alt text"
/// )
/// print(summary.totalChecks)   // 15
/// print(summary.failureRate)   // 0.2
/// ```
public struct RuleSummary: Sendable, Codable, Equatable, Hashable {

    /// The rule identifier this summary corresponds to.
    public let ruleID: RuleID

    /// The number of assertions that passed for this rule.
    public let passedCount: Int

    /// The number of assertions that failed for this rule.
    public let failedCount: Int

    /// A human-readable description of the rule (typically from the first assertion message).
    public let ruleDescription: String

    /// Creates a new `RuleSummary`.
    ///
    /// - Parameters:
    ///   - ruleID: The rule identifier.
    ///   - passedCount: The number of passing assertions.
    ///   - failedCount: The number of failing assertions.
    ///   - ruleDescription: A human-readable description of the rule.
    public init(
        ruleID: RuleID,
        passedCount: Int,
        failedCount: Int,
        ruleDescription: String
    ) {
        self.ruleID = ruleID
        self.passedCount = passedCount
        self.failedCount = failedCount
        self.ruleDescription = ruleDescription
    }

    /// The total number of assertions evaluated for this rule.
    public var totalChecks: Int {
        passedCount + failedCount
    }

    /// The proportion of failed assertions relative to total checks.
    ///
    /// Returns `0.0` when ``totalChecks`` is zero to avoid division by zero.
    public var failureRate: Double {
        guard totalChecks > 0 else { return 0.0 }
        return Double(failedCount) / Double(totalChecks)
    }

    /// The proportion of passed assertions relative to total checks.
    ///
    /// Returns `0.0` when ``totalChecks`` is zero.
    public var passRate: Double {
        guard totalChecks > 0 else { return 0.0 }
        return Double(passedCount) / Double(totalChecks)
    }

    /// Whether all assertions for this rule passed.
    public var isFullyPassing: Bool {
        failedCount == 0
    }

    /// Whether all assertions for this rule failed.
    public var isFullyFailing: Bool {
        passedCount == 0 && failedCount > 0
    }
}

// MARK: - CustomStringConvertible

extension RuleSummary: CustomStringConvertible {
    /// A textual representation of this summary.
    public var description: String {
        let rateStr = String(format: "%.1f%%", failureRate * 100)
        return "RuleSummary(\(ruleID.uniqueID): \(passedCount) passed, " +
               "\(failedCount) failed, \(rateStr) failure rate)"
    }
}
