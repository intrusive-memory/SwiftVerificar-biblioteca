import Foundation
import SwiftVerificarValidationProfiles

/// A complete validation report with per-rule summaries.
///
/// `ValidationReport` wraps a ``ValidationResult`` and provides
/// aggregated ``RuleSummary`` instances for each rule that was
/// evaluated. The summaries are sorted by ``RuleSummary/failedCount``
/// descending so the most problematic rules appear first.
///
/// Use ``generate(from:)`` to create a report from a validation result.
///
/// This is the Swift equivalent of Java's `ValidationReport` and
/// `ValidationDetails` interfaces in veraPDF-library, consolidated into
/// a single value type.
///
/// ## Example
/// ```swift
/// let result = try await validator.validate(document)
/// let report = ValidationReport.generate(from: result)
/// for summary in report.summaries {
///     print("\(summary.ruleID.uniqueID): \(summary.failedCount) failures")
/// }
/// ```
public struct ValidationReport: Sendable, Codable, Equatable {

    /// The underlying validation result.
    public let result: ValidationResult

    /// Per-rule summaries sorted by failed count descending.
    ///
    /// Each summary aggregates the assertions for a single rule,
    /// providing pass/fail counts and failure rates.
    public let summaries: [RuleSummary]

    /// Creates a new `ValidationReport`.
    ///
    /// - Parameters:
    ///   - result: The underlying validation result.
    ///   - summaries: Per-rule summaries.
    public init(result: ValidationResult, summaries: [RuleSummary]) {
        self.result = result
        self.summaries = summaries
    }

    /// Generates a `ValidationReport` from a ``ValidationResult``.
    ///
    /// Groups assertions by ``TestAssertion/ruleID``, computes pass/fail
    /// counts for each rule, and sorts the resulting summaries by
    /// ``RuleSummary/failedCount`` descending (most failures first).
    ///
    /// - Parameter result: The validation result to summarize.
    /// - Returns: A new ``ValidationReport`` with per-rule summaries.
    public static func generate(from result: ValidationResult) -> ValidationReport {
        let grouped = Dictionary(grouping: result.assertions) { $0.ruleID }
        let summaries = grouped.map { (ruleID, assertions) in
            RuleSummary(
                ruleID: ruleID,
                passedCount: assertions.count(where: { $0.status == .passed }),
                failedCount: assertions.count(where: { $0.status == .failed }),
                ruleDescription: assertions.first?.message ?? ""
            )
        }
        .sorted { $0.failedCount > $1.failedCount }

        return ValidationReport(result: result, summaries: summaries)
    }

    // MARK: - Computed Properties

    /// The total number of rules that were evaluated.
    public var ruleCount: Int {
        summaries.count
    }

    /// The number of rules that have at least one failure.
    public var failedRuleCount: Int {
        summaries.count(where: { $0.failedCount > 0 })
    }

    /// The number of rules where all assertions passed.
    public var passedRuleCount: Int {
        summaries.count(where: { $0.failedCount == 0 })
    }

    /// The overall failure rate across all assertions.
    ///
    /// Returns `0.0` when there are no assertions.
    public var overallFailureRate: Double {
        let total = summaries.reduce(0) { $0 + $1.totalChecks }
        guard total > 0 else { return 0.0 }
        let failed = summaries.reduce(0) { $0 + $1.failedCount }
        return Double(failed) / Double(total)
    }

    /// Summaries filtered to only rules that have at least one failure.
    public var failedSummaries: [RuleSummary] {
        summaries.filter { $0.failedCount > 0 }
    }

    /// Summaries filtered to only rules where all assertions passed.
    public var passedSummaries: [RuleSummary] {
        summaries.filter { $0.failedCount == 0 }
    }
}

// MARK: - CustomStringConvertible

extension ValidationReport: CustomStringConvertible {
    public var description: String {
        let status = result.isCompliant ? "COMPLIANT" : "NON-COMPLIANT"
        return "ValidationReport(\(status): \(ruleCount) rules, " +
               "\(failedRuleCount) with failures)"
    }
}
