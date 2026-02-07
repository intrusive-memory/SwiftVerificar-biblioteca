import Foundation
import SwiftVerificarWCAGAlgs

/// Orchestrates WCAG accessibility checks on a parsed document.
///
/// `WCAGCheckRunner` is a stateless helper that bridges the gap between
/// the ``SwiftPDFValidator`` (which imports `SwiftVerificarValidationProfiles`)
/// and the WCAG algorithms package (`SwiftVerificarWCAGAlgs`). By isolating
/// the WCAG import in this file, we avoid a name collision between
/// `ValidationProfile` types defined in both packages.
///
/// ## Checks Performed
///
/// 1. **WCAG Level AA**: Runs all Level A and AA accessibility checkers
///    (alt text, language, link purpose) against the semantic tree.
/// 2. **Heading Hierarchy**: Validates that heading levels are properly
///    nested (no skipped levels, non-empty headings).
///
/// ## Thread Safety
///
/// `WCAGCheckRunner` is a stateless enum with static methods. It is `Sendable`.
public enum WCAGCheckRunner: Sendable {

    /// Run WCAG accessibility checks on a parsed document.
    ///
    /// Builds a semantic tree from the document's structure elements using
    /// ``SemanticNodeAdapter/buildTree(from:)``, runs the ``WCAGValidator``
    /// (Level AA) and ``HeadingHierarchyChecker``, and maps the results
    /// to ``TestAssertion`` instances via ``WCAGResultMapper``.
    ///
    /// - Parameters:
    ///   - document: The parsed PDF document.
    ///   - recordPassed: Whether to include assertions for passed checks.
    /// - Returns: An array of ``TestAssertion`` instances from WCAG checks.
    ///   Returns an empty array if the document has no structure elements.
    public static func runChecks(
        on document: any ParsedDocument,
        recordPassed: Bool
    ) -> [TestAssertion] {
        guard let rootNode = SemanticNodeAdapter.buildTree(from: document) else {
            // No structure elements found -- skip WCAG checks
            return []
        }

        var assertions: [TestAssertion] = []

        // 1. WCAG Level AA check
        let wcagValidator = WCAGValidator.levelAA()
        let wcagReport = wcagValidator.validate(rootNode)
        // Use .results to get [AccessibilityCheckResult] -- avoids naming
        // the wcag-algs' ValidationReport type which collides with biblioteca's
        assertions.append(contentsOf: WCAGResultMapper.mapReport(
            wcagReport.results,
            recordPassed: recordPassed
        ))

        // 2. Heading hierarchy check
        let headingChecker = HeadingHierarchyChecker(options: .basic)
        let headingResult = headingChecker.validate(rootNode)
        assertions.append(contentsOf: WCAGResultMapper.mapHeadingResult(
            headingResult,
            recordPassed: recordPassed
        ))

        return assertions
    }
}
