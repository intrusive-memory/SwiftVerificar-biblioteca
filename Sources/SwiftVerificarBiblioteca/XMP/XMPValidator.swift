import Foundation

/// Validates XMP metadata for PDF/A and PDF/UA compliance.
///
/// `XMPValidator` checks XMP metadata against the requirements of various
/// PDF compliance standards. It can validate presence of required schemas,
/// correctness of identification values, and consistency of metadata fields.
///
/// This is a stub implementation that provides basic structural validation.
/// Full compliance checking will be integrated during reconciliation with
/// `SwiftVerificar-validation` and `SwiftVerificar-validation-profiles`.
///
/// ## Example
/// ```swift
/// let validator = XMPValidator()
/// let issues = validator.validate(metadata: xmpMetadata, profile: "PDF/UA-2")
///
/// for issue in issues where issue.isError {
///     print(issue)
/// }
/// ```
public struct XMPValidator: Sendable {

    /// Creates an XMP validator.
    public init() {}

    /// Validates XMP metadata against a compliance profile.
    ///
    /// When `profile` is `nil`, general XMP structural validation is performed.
    /// When a profile string is provided (e.g., `"PDF/A-2u"` or `"PDF/UA-2"`),
    /// additional profile-specific checks are applied.
    ///
    /// - Parameters:
    ///   - metadata: The XMP metadata to validate.
    ///   - profile: An optional profile identifier string. Defaults to `nil`.
    /// - Returns: An array of validation issues found. An empty array indicates
    ///   the metadata passed all checks.
    public func validate(
        metadata: XMPMetadata,
        profile: String? = nil
    ) -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        // General structural checks
        issues.append(contentsOf: validateStructure(metadata))

        // Profile-specific checks
        if let profile {
            let normalized = profile.lowercased()
            if normalized.contains("pdf/a") || normalized.contains("pdfa") {
                issues.append(contentsOf: validatePDFACompliance(metadata))
            }
            if normalized.contains("pdf/ua") || normalized.contains("pdfua") {
                issues.append(contentsOf: validatePDFUACompliance(metadata))
            }
        }

        return issues
    }

    // MARK: - Structural Validation

    /// Performs general structural validation on XMP metadata.
    ///
    /// - Parameter metadata: The metadata to validate.
    /// - Returns: Structural validation issues.
    public func validateStructure(_ metadata: XMPMetadata) -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        if metadata.isEmpty {
            issues.append(XMPValidationIssue(
                message: "XMP metadata contains no packages",
                severity: .warning
            ))
        }

        // Check for duplicate namespaces
        var seenNamespaces: Set<String> = []
        for pkg in metadata.packages {
            if seenNamespaces.contains(pkg.namespace) {
                issues.append(XMPValidationIssue(
                    message: "Duplicate namespace found: \(pkg.namespace)",
                    property: pkg.prefix,
                    severity: .warning
                ))
            }
            seenNamespaces.insert(pkg.namespace)
        }

        return issues
    }

    // MARK: - PDF/A Compliance

    /// Validates XMP metadata for PDF/A compliance.
    ///
    /// Checks that the PDF/A identification schema is present and has
    /// valid part and conformance values.
    ///
    /// - Parameter metadata: The metadata to validate.
    /// - Returns: PDF/A-specific validation issues.
    public func validatePDFACompliance(_ metadata: XMPMetadata) -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        guard let pdfa = metadata.pdfaIdentification else {
            issues.append(XMPValidationIssue(
                message: "Missing PDF/A identification schema (pdfaid)",
                property: "pdfaid:part",
                severity: .error
            ))
            return issues
        }

        if !pdfa.isValidPart {
            issues.append(XMPValidationIssue(
                message: "Invalid PDF/A part number: \(pdfa.part). Expected 1, 2, 3, or 4.",
                property: "pdfaid:part",
                severity: .error
            ))
        }

        if !pdfa.isValidConformance {
            issues.append(XMPValidationIssue(
                message: "Invalid PDF/A conformance level: \"\(pdfa.conformance)\". Expected a, b, u, e, or f.",
                property: "pdfaid:conformance",
                severity: .error
            ))
        }

        return issues
    }

    // MARK: - PDF/UA Compliance

    /// Validates XMP metadata for PDF/UA compliance.
    ///
    /// Checks that the PDF/UA identification schema is present and has
    /// a valid part number.
    ///
    /// - Parameter metadata: The metadata to validate.
    /// - Returns: PDF/UA-specific validation issues.
    public func validatePDFUACompliance(_ metadata: XMPMetadata) -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        guard let pdfua = metadata.pdfuaIdentification else {
            issues.append(XMPValidationIssue(
                message: "Missing PDF/UA identification schema (pdfuaid)",
                property: "pdfuaid:part",
                severity: .error
            ))
            return issues
        }

        if !pdfua.isValidPart {
            issues.append(XMPValidationIssue(
                message: "Invalid PDF/UA part number: \(pdfua.part). Expected 1 or 2.",
                property: "pdfuaid:part",
                severity: .error
            ))
        }

        return issues
    }
}

// MARK: - CustomStringConvertible

extension XMPValidator: CustomStringConvertible {
    public var description: String {
        "XMPValidator()"
    }
}
