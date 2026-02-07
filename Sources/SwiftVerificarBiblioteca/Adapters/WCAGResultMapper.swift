import Foundation
import SwiftVerificarWCAGAlgs
import SwiftVerificarValidationProfiles

/// Maps WCAG algorithm results to biblioteca's ``TestAssertion`` format.
///
/// `WCAGResultMapper` bridges the gap between the WCAG validation
/// results (from `SwiftVerificarWCAGAlgs`) and the biblioteca's
/// ``TestAssertion`` instances that flow into ``ValidationResult``.
///
/// ## Type Collision Avoidance
///
/// Both `SwiftVerificarWCAGAlgs` and biblioteca define a type named
/// `ValidationReport`. To avoid ambiguity, this mapper takes
/// `[AccessibilityCheckResult]` (the `.results` property of the
/// wcag-algs report) rather than the report struct itself.
///
/// ## Mapping Strategy
///
/// - Each ``AccessibilityCheckResult`` maps to one or more ``TestAssertion`` instances.
/// - Passed checks map to a single passed assertion (if `recordPassed` is true).
/// - Failed checks map to one assertion per violation, plus a summary assertion.
/// - ``HeadingHierarchyValidationResult`` issues map to individual failed assertions.
///
/// ## Thread Safety
///
/// `WCAGResultMapper` is a stateless enum with static methods. It is `Sendable`.
public enum WCAGResultMapper: Sendable {

    // MARK: - WCAG Check Results

    /// Maps WCAG accessibility check results to ``TestAssertion`` instances.
    ///
    /// - Parameters:
    ///   - results: The accessibility check results from ``WCAGValidator``.
    ///   - recordPassed: Whether to include assertions for passed checks.
    /// - Returns: An array of ``TestAssertion`` instances.
    public static func mapReport(
        _ results: [AccessibilityCheckResult],
        recordPassed: Bool
    ) -> [TestAssertion] {
        var assertions: [TestAssertion] = []

        for result in results {
            if result.passed {
                if recordPassed {
                    assertions.append(mapPassedResult(result))
                }
            } else {
                assertions.append(contentsOf: mapFailedResult(result))
            }
        }

        return assertions
    }

    // MARK: - Heading Hierarchy Results

    /// Maps heading hierarchy validation results to ``TestAssertion`` instances.
    ///
    /// - Parameters:
    ///   - result: The heading hierarchy validation result.
    ///   - recordPassed: Whether to include a passed assertion when the hierarchy is valid.
    /// - Returns: An array of ``TestAssertion`` instances.
    public static func mapHeadingResult(
        _ result: HeadingHierarchyValidationResult,
        recordPassed: Bool
    ) -> [TestAssertion] {
        var assertions: [TestAssertion] = []

        if result.isValid {
            if recordPassed {
                let ruleID = RuleID(
                    specification: .wcag22,
                    clause: "1.3.1",
                    testNumber: 100
                )
                assertions.append(TestAssertion(
                    ruleID: ruleID,
                    status: .passed,
                    message: "Heading hierarchy is valid (\(result.totalHeadingCount) headings)",
                    context: "HeadingHierarchy"
                ))
            }
        } else {
            for issue in result.issues {
                assertions.append(mapHeadingIssue(issue))
            }
        }

        return assertions
    }

    // MARK: - Private: Result Mapping

    /// Maps a passed ``AccessibilityCheckResult`` to a single ``TestAssertion``.
    private static func mapPassedResult(
        _ result: AccessibilityCheckResult
    ) -> TestAssertion {
        let ruleID = ruleIDForCriterion(result.criterion)
        return TestAssertion(
            ruleID: ruleID,
            status: .passed,
            message: "WCAG \(result.criterion.rawValue) (\(result.criterion.name)): Passed",
            context: result.context ?? "WCAG"
        )
    }

    /// Maps a failed ``AccessibilityCheckResult`` to ``TestAssertion`` instances.
    ///
    /// Produces one assertion per violation.
    private static func mapFailedResult(
        _ result: AccessibilityCheckResult
    ) -> [TestAssertion] {
        var assertions: [TestAssertion] = []

        for violation in result.violations {
            let ruleID = ruleIDForCriterion(result.criterion)
            let location = mapViolationLocation(violation)
            let status: AssertionStatus = mapSeverityToStatus(violation.severity)

            assertions.append(TestAssertion(
                ruleID: ruleID,
                status: status,
                message: "WCAG \(result.criterion.rawValue): \(violation.description)",
                location: location,
                context: violation.nodeType.rawValue,
                arguments: [violation.severity.rawValue]
            ))
        }

        // If there are no individual violations but the check failed,
        // emit a single summary assertion
        if assertions.isEmpty {
            let ruleID = ruleIDForCriterion(result.criterion)
            assertions.append(TestAssertion(
                ruleID: ruleID,
                status: .failed,
                message: "WCAG \(result.criterion.rawValue) (\(result.criterion.name)): Failed",
                context: result.context ?? "WCAG"
            ))
        }

        return assertions
    }

    /// Maps a ``HeadingHierarchyIssue`` to a ``TestAssertion``.
    private static func mapHeadingIssue(
        _ issue: HeadingHierarchyIssue
    ) -> TestAssertion {
        let ruleID = RuleID(
            specification: .wcag22,
            clause: "1.3.1",
            testNumber: headingIssueTestNumber(issue.type)
        )

        let status: AssertionStatus
        switch issue.severity {
        case .critical:
            status = .failed
        case .warning:
            status = .failed
        case .info:
            status = .passed
        }

        let location = PDFLocation(
            pageNumber: issue.pageIndex.map { $0 + 1 },
            structureID: "H\(issue.headingLevel)"
        )

        return TestAssertion(
            ruleID: ruleID,
            status: status,
            message: issue.message,
            location: location,
            context: "HeadingHierarchy",
            arguments: [issue.type.rawValue, issue.severity.rawValue]
        )
    }

    // MARK: - Private: Helpers

    /// Creates a ``RuleID`` for a WCAG success criterion.
    ///
    /// Uses `.wcag22` as the specification and the criterion's raw value
    /// (e.g., "1.1.1") as the clause.
    private static func ruleIDForCriterion(
        _ criterion: WCAGSuccessCriterion
    ) -> RuleID {
        RuleID(
            specification: .wcag22,
            clause: criterion.rawValue,
            testNumber: 1
        )
    }

    /// Maps a ``ViolationSeverity`` to an ``AssertionStatus``.
    ///
    /// All severities except `.minor` map to `.failed`. Minor violations
    /// still map to `.failed` since they are still violations.
    private static func mapSeverityToStatus(
        _ severity: ViolationSeverity
    ) -> AssertionStatus {
        // All violations are failures
        .failed
    }

    /// Maps a violation's location information to a ``PDFLocation``.
    private static func mapViolationLocation(
        _ violation: AccessibilityViolation
    ) -> PDFLocation? {
        guard let bbox = violation.location else { return nil }
        return PDFLocation(
            pageNumber: bbox.pageIndex + 1,
            structureID: violation.nodeId.uuidString
        )
    }

    /// Returns a test number for a heading hierarchy issue type.
    ///
    /// This provides a unique test number within the "1.3.1" clause
    /// for each type of heading issue.
    private static func headingIssueTestNumber(
        _ type: HeadingHierarchyIssue.IssueType
    ) -> Int {
        switch type {
        case .levelSkipped: return 101
        case .multipleH1: return 102
        case .emptyHeading: return 103
        case .firstHeadingNotH1: return 104
        case .levelIncreaseExcessive: return 105
        case .nonMeaningfulText: return 106
        case .logicalOrderViolation: return 107
        }
    }
}
