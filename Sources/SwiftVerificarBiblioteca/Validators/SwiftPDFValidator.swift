import Foundation
import SwiftVerificarValidationProfiles

/// Default Swift implementation of the ``PDFValidator`` protocol.
///
/// `SwiftPDFValidator` is the main validator that orchestrates the
/// validation pipeline: it accepts a parsed document, groups rules
/// by object type, evaluates each rule's test expression against
/// every matching object, and assembles the results into a
/// ``ValidationResult``.
///
/// This type consolidates several Java classes from veraPDF-library:
///
/// | Java Class              | Swift Mapping                        |
/// |------------------------|--------------------------------------|
/// | `BaseValidator`         | `SwiftPDFValidator` struct            |
/// | `FastFailValidator`     | Controlled via ``ValidatorConfig``    |
/// | `FlavourValidator`      | Merged — profile name is a property  |
/// | `JavaScriptEvaluator`   | Expression evaluation via validation-profiles |
///
/// ## Validation Pipeline
///
/// 1. Resolve ``profileName`` to a ``PDFFlavour`` via name normalization.
/// 2. Load the ``ValidationProfile`` from ``ProfileLoader/shared``.
/// 3. Group the profile's rules by their target object type.
/// 4. For each object type, query ``ParsedDocument/objects(ofType:)`` for
///    matching objects.
/// 5. For each (rule, object) pair, convert the object's
///    ``ValidationObject/validationProperties`` to ``PropertyValue`` values
///    and evaluate the rule's test expression via ``RuleExpressionEvaluator``.
/// 6. Collect results as ``TestAssertion`` instances and assemble a
///    ``ValidationResult``.
///
/// ## Config Respect
///
/// - ``ValidatorConfig/maxFailures``: Stops evaluation after N failures
///   (fast-fail mode) when greater than zero.
/// - ``ValidatorConfig/recordPassedAssertions``: When `false`, only failed
///   and unknown assertions are included in the result.
/// - ``ValidatorConfig/timeout``: Cancels validation if it exceeds the
///   configured timeout in seconds.
///
/// ## Thread Safety
///
/// `SwiftPDFValidator` is a value type (`struct`) with no mutable
/// state, and conforms to `Sendable`.
///
/// ## Usage
///
/// ```swift
/// let validator = SwiftPDFValidator(
///     profileName: "PDF/UA-2",
///     config: ValidatorConfig(maxFailures: 10)
/// )
/// let result = try await validator.validate(parsedDocument)
/// ```
public struct SwiftPDFValidator: PDFValidator, Sendable, Equatable {

    /// The name of the validation profile being used.
    public let profileName: String

    /// The configuration controlling validator behavior.
    public let config: ValidatorConfig

    /// Creates a new `SwiftPDFValidator`.
    ///
    /// - Parameters:
    ///   - profileName: The name of the validation profile to use.
    ///   - config: Validator configuration. Defaults to
    ///     ``ValidatorConfig/init(maxFailures:recordPassedAssertions:logProgress:timeout:parallelValidation:)``
    ///     with all defaults.
    public init(
        profileName: String,
        config: ValidatorConfig = ValidatorConfig()
    ) {
        self.profileName = profileName
        self.config = config
    }

    // MARK: - PDFValidator

    /// Validate a pre-parsed PDF document.
    ///
    /// Loads the validation profile for ``profileName``, iterates over
    /// all rules grouped by object type, evaluates each rule's test
    /// expression against matching objects from the document, and
    /// assembles the results into a ``ValidationResult``.
    ///
    /// - Parameter document: A parsed PDF document.
    /// - Returns: A ``ValidationResult`` with all assertions.
    /// - Throws: ``VerificarError/profileNotFound(name:)`` if the
    ///   profile name cannot be resolved.
    /// - Throws: ``VerificarError/validationFailed(reason:)`` if an
    ///   internal error occurs during rule evaluation.
    public func validate(
        _ document: any ParsedDocument
    ) async throws -> ValidationResult {
        let startTime = Date()

        // 1. Resolve profile name to flavour
        let flavour = try resolveFlavour(from: profileName)

        // 2. Load the profile
        let profile = try await loadProfile(for: flavour)

        // 3. Evaluate rules
        let assertions = try await evaluateRules(
            from: profile,
            against: document,
            startTime: startTime
        )

        let endTime = Date()
        let duration = ValidationDuration(start: startTime, end: endTime)

        // Determine compliance: no failures means compliant
        let isCompliant = !assertions.contains { $0.status == .failed }

        return ValidationResult(
            profileName: profile.details.name,
            documentURL: document.url,
            isCompliant: isCompliant,
            assertions: assertions,
            duration: duration
        )
    }

    /// Validate a PDF document from a file URL.
    ///
    /// Parses the document using ``SwiftPDFParser`` and then validates
    /// the resulting ``ParsedDocument``.
    ///
    /// - Parameter url: The file URL of the PDF document.
    /// - Returns: A ``ValidationResult`` with all assertions.
    /// - Throws: ``VerificarError/parsingFailed(url:reason:)`` if the
    ///   document cannot be parsed.
    /// - Throws: ``VerificarError/profileNotFound(name:)`` if the
    ///   profile name cannot be resolved.
    public func validate(contentsOf url: URL) async throws -> ValidationResult {
        let parser = SwiftPDFParser(url: url)
        let document = try await parser.parse()
        return try await validate(document)
    }

    // MARK: - Equatable

    public static func == (lhs: SwiftPDFValidator, rhs: SwiftPDFValidator) -> Bool {
        lhs.profileName == rhs.profileName && lhs.config == rhs.config
    }

    // MARK: - Private: Profile Resolution

    /// Resolve a profile name string to a ``PDFFlavour``.
    ///
    /// Normalizes the name by lowercasing and stripping spaces,
    /// slashes, and hyphens, then matches against known flavour
    /// identifiers.
    ///
    /// - Parameter profileName: The profile name to resolve.
    /// - Returns: The matching ``PDFFlavour``.
    /// - Throws: ``VerificarError/profileNotFound(name:)`` if
    ///   the name does not match any known flavour.
    private func resolveFlavour(from profileName: String) throws -> PDFFlavour {
        let normalized = profileName
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "-", with: "")

        switch normalized {
        case "pdfua2": return .pdfUA2
        case "pdfua1": return .pdfUA1
        case "pdfa1a": return .pdfA1a
        case "pdfa1b": return .pdfA1b
        case "pdfa2a": return .pdfA2a
        case "pdfa2b": return .pdfA2b
        case "pdfa2u": return .pdfA2u
        case "pdfa3a": return .pdfA3a
        case "pdfa3b": return .pdfA3b
        case "pdfa3u": return .pdfA3u
        case "pdfa4": return .pdfA4
        case "pdfa4e": return .pdfA4e
        case "pdfa4f": return .pdfA4f
        case "wcag22", "wcag2.2": return .wcag22
        case "wtpdf1accessibility": return .wtpdf1Accessibility
        case "wtpdf1reuse": return .wtpdf1Reuse
        default:
            throw VerificarError.profileNotFound(name: profileName)
        }
    }

    /// Load a validation profile from the shared ``ProfileLoader``.
    ///
    /// - Parameter flavour: The flavour to load.
    /// - Returns: The loaded ``ValidationProfile``.
    /// - Throws: ``VerificarError/profileNotFound(name:)`` if the
    ///   profile cannot be found in the resource bundle.
    private func loadProfile(for flavour: PDFFlavour) async throws -> ValidationProfile {
        do {
            return try await ProfileLoader.shared.loadProfile(for: flavour)
        } catch {
            throw VerificarError.profileNotFound(name: flavour.displayName)
        }
    }

    // MARK: - Private: Rule Evaluation

    /// Evaluate all rules from a profile against a document.
    ///
    /// Groups rules by object type, queries the document for matching
    /// objects, converts properties to ``PropertyValue`` dictionaries,
    /// and evaluates each rule's test expression.
    ///
    /// Respects ``ValidatorConfig/maxFailures``,
    /// ``ValidatorConfig/recordPassedAssertions``, and
    /// ``ValidatorConfig/timeout``.
    ///
    /// - Parameters:
    ///   - profile: The validation profile containing rules.
    ///   - document: The parsed document to validate.
    ///   - startTime: When validation started (for timeout checking).
    /// - Returns: An array of ``TestAssertion`` instances.
    private func evaluateRules(
        from profile: ValidationProfile,
        against document: any ParsedDocument,
        startTime: Date
    ) async throws -> [TestAssertion] {
        let evaluator = RuleExpressionEvaluator()
        var assertions: [TestAssertion] = []
        var failureCount = 0

        // Group rules by object type for efficient querying
        let rulesByObjectType = Dictionary(grouping: profile.rules) { $0.object }

        // Build profile-level variable bindings
        let variableBindings = buildVariableBindings(from: profile.variables)

        for (objectType, rules) in rulesByObjectType {
            // Check timeout
            if let timeout = config.timeout, timeout > 0 {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed >= timeout {
                    break
                }
            }

            // Check fast-fail
            if config.isFastFail && failureCount >= config.maxFailures {
                break
            }

            // Get matching objects from the document
            let objects = document.objects(ofType: objectType)

            // If there are no objects for this type, the rules simply
            // produce no assertions (they are not applicable)
            guard !objects.isEmpty else { continue }

            for rule in rules {
                // Check fast-fail before each rule
                if config.isFastFail && failureCount >= config.maxFailures {
                    break
                }

                // Check timeout before each rule
                if let timeout = config.timeout, timeout > 0 {
                    let elapsed = Date().timeIntervalSince(startTime)
                    if elapsed >= timeout {
                        break
                    }
                }

                for object in objects {
                    // Check fast-fail before each object
                    if config.isFastFail && failureCount >= config.maxFailures {
                        break
                    }

                    // Convert string properties to PropertyValue
                    let properties = convertToPropertyValues(
                        object.validationProperties,
                        mergedWith: variableBindings
                    )

                    // Evaluate the rule's test expression
                    let assertion = evaluateRule(
                        rule,
                        properties: properties,
                        location: object.location,
                        objectType: objectType,
                        evaluator: evaluator
                    )

                    // Record the assertion based on config
                    switch assertion.status {
                    case .failed:
                        failureCount += 1
                        assertions.append(assertion)
                    case .passed:
                        if config.recordPassedAssertions {
                            assertions.append(assertion)
                        }
                    case .unknown:
                        assertions.append(assertion)
                    }
                }
            }
        }

        return assertions
    }

    /// Evaluate a single rule against a set of properties.
    ///
    /// - Parameters:
    ///   - rule: The rule to evaluate.
    ///   - properties: The property values for evaluation.
    ///   - location: The location of the object in the document.
    ///   - objectType: The object type string for context.
    ///   - evaluator: The expression evaluator to use.
    /// - Returns: A ``TestAssertion`` recording the outcome.
    private func evaluateRule(
        _ rule: ValidationRule,
        properties: [String: PropertyValue],
        location: PDFLocation?,
        objectType: String,
        evaluator: RuleExpressionEvaluator
    ) -> TestAssertion {
        do {
            let passed = try evaluator.evaluate(
                expression: rule.test,
                properties: properties
            )

            let status: AssertionStatus = passed ? .passed : .failed
            let message: String
            if passed {
                message = rule.description
            } else {
                // Format the error message with property values
                let propertyStringValues = properties.mapValues { $0.stringValue }
                message = rule.error.formattedMessage(with: propertyStringValues)
            }

            let argumentNames = rule.error.arguments.map { $0.name }

            return TestAssertion(
                ruleID: rule.id,
                status: status,
                message: message,
                location: location,
                context: objectType,
                arguments: argumentNames
            )
        } catch {
            // Expression evaluation failed — record as unknown
            return TestAssertion(
                ruleID: rule.id,
                status: .unknown,
                message: "Expression evaluation error: \(error)",
                location: location,
                context: objectType,
                arguments: []
            )
        }
    }

    /// Convert string properties from a ``ValidationObject`` to
    /// ``PropertyValue`` values for the expression evaluator.
    ///
    /// Uses heuristic type inference:
    /// - `"true"` / `"false"` → `.bool`
    /// - `"null"` → `.null`
    /// - Integer strings → `.int`
    /// - Decimal strings → `.double`
    /// - Everything else → `.string`
    ///
    /// - Parameters:
    ///   - stringProperties: The string-typed properties from the object.
    ///   - variableBindings: Profile-level variable bindings to merge.
    /// - Returns: A dictionary of ``PropertyValue`` values.
    private func convertToPropertyValues(
        _ stringProperties: [String: String],
        mergedWith variableBindings: [String: PropertyValue]
    ) -> [String: PropertyValue] {
        var result = variableBindings

        for (key, value) in stringProperties {
            result[key] = inferPropertyValue(from: value)
        }

        return result
    }

    /// Infer a ``PropertyValue`` from a string representation.
    ///
    /// - Parameter string: The string value to convert.
    /// - Returns: The inferred ``PropertyValue``.
    private func inferPropertyValue(from string: String) -> PropertyValue {
        // Check for null
        if string == "null" {
            return .null
        }

        // Check for boolean
        if string == "true" {
            return .bool(true)
        }
        if string == "false" {
            return .bool(false)
        }

        // Check for integer
        if let intVal = Int64(string) {
            return .int(intVal)
        }

        // Check for double (only if it contains a decimal point to
        // avoid converting integers to doubles)
        if string.contains("."), let doubleVal = Double(string) {
            return .double(doubleVal)
        }

        // Default to string
        return .string(string)
    }

    /// Build profile-level variable bindings from ``ProfileVariable`` values.
    ///
    /// - Parameter variables: The profile's variables.
    /// - Returns: A dictionary mapping variable names to ``PropertyValue``.
    private func buildVariableBindings(
        from variables: [ProfileVariable]
    ) -> [String: PropertyValue] {
        var bindings: [String: PropertyValue] = [:]
        for variable in variables {
            bindings[variable.name] = inferPropertyValue(from: variable.defaultValue)
        }
        return bindings
    }
}

// MARK: - ValidatorComponent

extension SwiftPDFValidator: ValidatorComponent {
    /// Component metadata for this validator.
    public var info: ComponentInfo {
        ComponentInfo(
            name: "SwiftPDFValidator",
            version: SwiftVerificarBiblioteca.version,
            componentDescription: "PDF validator for profile: \(profileName)",
            provider: "SwiftVerificar Project"
        )
    }
}

// MARK: - CustomStringConvertible

extension SwiftPDFValidator: CustomStringConvertible {
    public var description: String {
        "SwiftPDFValidator(profile: \(profileName), config: \(config))"
    }
}
