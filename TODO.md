# SwiftVerificar-biblioteca Porting TODO

## Source Repository

**Source:** [veraPDF-library](https://github.com/veraPDF/veraPDF-library)
**Branch:** `integration`
**License:** GPLv3+ / MPLv2+ (dual-licensed)

---

## Overview

This document provides a comprehensive porting plan for converting veraPDF-library (~250+ Java classes) to Swift. This is the **main integration library** that ties together all other SwiftVerificar components and provides the unified API for Lazarillo.

### Key Responsibilities

1. **Unified Validation API** - Single entry point for PDF/UA and PDF/A validation
2. **Component Coordination** - Orchestrates parser, validation engine, and profiles
3. **Result Management** - Provides `ValidationResult` compatible with Lazarillo
4. **Feature Extraction** - Extracts and reports PDF features
5. **Metadata Fixing** - Repairs XMP metadata for compliance

### Swift Advantages to Leverage

- **Result types** for comprehensive error handling
- **Async/await** for long-running validation operations
- **Actors** for thread-safe component management
- **Protocol-oriented design** for extensibility
- **SwiftUI integration** for progress reporting

---

## Phase 1: Core Interfaces and Types

### 1.1 PDF Flavours

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDFAFlavour` (enum) | `PDFFlavour` (enum) | **Already in validation-profiles** |
| `PDFAFlavour.Specification` | `Specification` (enum) | **Already in validation-profiles** |
| `PDFAFlavour.Level` | Part of `PDFFlavour` | Consolidated |
| `PDFAFlavours` | Extensions | Static utilities |
| `PDFFlavours` | Extensions | Static utilities |

### 1.2 Component System

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `Component` (interface) | `ValidatorComponent` (protocol) | Base component protocol |
| `ComponentDetails` | `ComponentInfo` (struct) | Component metadata |
| `Components` | Extensions | Factory methods |
| `AuditDuration` | `ValidationDuration` (struct) | Timing info |

```swift
/// Protocol for all verifiable components
public protocol ValidatorComponent: Sendable {
    var info: ComponentInfo { get }
}

/// Component metadata
public struct ComponentInfo: Sendable, Codable {
    public let name: String
    public let version: String
    public let description: String
    public let provider: String
}

/// Timing information for validation operations
public struct ValidationDuration: Sendable, Codable {
    public let start: Date
    public let end: Date
    public var duration: TimeInterval { end.timeIntervalSince(start) }
}
```

### 1.3 Core Exceptions → Result Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `VeraPDFException` | `VerificarError` (enum) | Base error |
| `ValidationException` | Case in `VerificarError` | Validation error |
| `ModelParsingException` | Case in `VerificarError` | Parsing error |
| `ProfileException` | Case in `VerificarError` | Profile error |
| `EncryptedPdfException` | Case in `VerificarError` | Encrypted PDF |
| `FeatureParsingException` | Case in `VerificarError` | Feature extraction error |

```swift
/// All errors from SwiftVerificar
public enum VerificarError: Error, Sendable {
    case parsingFailed(url: URL, reason: String)
    case validationFailed(reason: String)
    case profileNotFound(PDFFlavour)
    case profileParsingFailed(reason: String)
    case encryptedPDF(url: URL)
    case featureExtractionFailed(reason: String)
    case invalidPassword
    case cancelled
    case unknown(Error)
}
```

---

## Phase 2: Foundry System (Factory)

### 2.1 Main Factory

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `VeraPDFFoundry` (interface) | `ValidationFoundry` (protocol) | Factory interface |
| `AbstractFoundry` | Default impl | Protocol extension |
| `Foundries` | `Foundry` (actor) | Singleton registry |
| `VeraFoundryProvider` (interface) | Part of `Foundry` | Consolidated |

```swift
/// Protocol for validation component factories
public protocol ValidationFoundry: Sendable {
    /// Create a parser for a PDF document
    func createParser(for url: URL) async throws -> PDFParser

    /// Create a validator for a profile
    func createValidator(
        profile: ValidationProfile,
        config: ValidatorConfig
    ) -> PDFValidator

    /// Create a metadata fixer
    func createMetadataFixer(config: FixerConfig) -> MetadataFixer

    /// Create a feature extractor
    func createFeatureExtractor(config: FeatureConfig) -> FeatureExtractor
}

/// Singleton foundry registry
public actor Foundry {
    public static let shared = Foundry()

    private var provider: (any ValidationFoundry)?

    /// Register a foundry implementation
    public func register(_ foundry: any ValidationFoundry) {
        self.provider = foundry
    }

    /// Get the current foundry
    public func current() throws -> any ValidationFoundry {
        guard let provider else {
            throw VerificarError.validationFailed(reason: "No foundry registered")
        }
        return provider
    }
}

/// Default Swift implementation
public struct SwiftFoundry: ValidationFoundry {
    public init() {}

    public func createParser(for url: URL) async throws -> PDFParser {
        try await SwiftPDFParser(url: url)
    }

    public func createValidator(
        profile: ValidationProfile,
        config: ValidatorConfig
    ) -> PDFValidator {
        SwiftPDFValidator(profile: profile, config: config)
    }

    public func createMetadataFixer(config: FixerConfig) -> MetadataFixer {
        SwiftMetadataFixer(config: config)
    }

    public func createFeatureExtractor(config: FeatureConfig) -> FeatureExtractor {
        SwiftFeatureExtractor(config: config)
    }
}
```

---

## Phase 3: Validation Profiles API

### 3.1 Profile Management

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `ValidationProfile` (interface) | **Already in validation-profiles** | Profile struct |
| `ValidationProfileImpl` | **Already in validation-profiles** | Implementation |
| `ProfileDirectory` (interface) | **Already in validation-profiles** | Directory protocol |
| `ProfileDirectoryImpl` | **Already in validation-profiles** | Implementation |
| `Profiles` | Extensions | Factory methods |
| `Rule` (interface) | **Already in validation-profiles** | Rule struct |
| `RuleId` | **Already in validation-profiles** | Rule ID |
| `ErrorDetails` | **Already in validation-profiles** | Error details |
| `Reference` | **Already in validation-profiles** | Spec reference |
| `Variable` | **Already in validation-profiles** | Profile variable |

**Note:** Most profile types are already defined in `SwiftVerificar-validation-profiles`. The biblioteca package re-exports and extends them.

---

## Phase 4: Validation Results

### 4.1 Result Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `ValidationResult` (interface) | `ValidationResult` (struct) | Main result type |
| `ValidationResultImpl` | Part of struct | Consolidated |
| `TestAssertion` (interface) | `TestAssertion` (struct) | Single test result |
| `TestAssertion.Status` (enum) | `AssertionStatus` (enum) | Pass/fail/unknown |
| `TestAssertionImpl` | Part of struct | Consolidated |
| `Location` (interface) | `PDFLocation` (struct) | Location in PDF |
| `LocationImpl` | Part of struct | Consolidated |
| `ValidationResults` | Extensions | Factory methods |

```swift
/// Complete validation result
public struct ValidationResult: Sendable, Codable {
    /// Profile used for validation
    public let profile: ValidationProfile

    /// Document being validated
    public let documentURL: URL

    /// Overall compliance status
    public let isCompliant: Bool

    /// Individual test assertions
    public let assertions: [TestAssertion]

    /// Timing information
    public let duration: ValidationDuration

    /// Total assertions by status
    public var passedCount: Int {
        assertions.filter { $0.status == .passed }.count
    }

    public var failedCount: Int {
        assertions.filter { $0.status == .failed }.count
    }

    /// Failed assertions grouped by rule
    public var failedByRule: [RuleID: [TestAssertion]] {
        Dictionary(grouping: assertions.filter { $0.status == .failed }) { $0.ruleID }
    }

    /// All unique error codes
    public var errorCodes: Set<String> {
        Set(assertions.filter { $0.status == .failed }.map { $0.ruleID.uniqueID })
    }
}

/// Single test assertion result
public struct TestAssertion: Sendable, Codable, Identifiable {
    public let id: UUID
    public let ruleID: RuleID
    public let status: AssertionStatus
    public let message: String
    public let location: PDFLocation?
    public let context: String?

    /// Arguments for message formatting
    public let arguments: [String]
}

/// Assertion status
public enum AssertionStatus: String, Sendable, Codable {
    case passed
    case failed
    case unknown  // Could not be evaluated
}

/// Location within a PDF document
public struct PDFLocation: Sendable, Codable {
    public let objectKey: String?       // e.g., "1 0 obj"
    public let pageNumber: Int?
    public let structureID: String?
    public let contentPath: String?     // e.g., "/Document/Part/P[3]"
}
```

### 4.2 Metadata Fixer Results

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `MetadataFixerResult` (interface) | `MetadataFixerResult` (struct) | Fixer result |
| `MetadataFixerResult.RepairStatus` | `RepairStatus` (enum) | Repair status |
| `MetadataFixerResultImpl` | Part of struct | Consolidated |

```swift
/// Result of metadata fixing operation
public struct MetadataFixerResult: Sendable, Codable {
    public let status: RepairStatus
    public let fixes: [MetadataFix]
    public let outputURL: URL?
}

/// Status of repair operation
public enum RepairStatus: String, Sendable, Codable {
    case success           // All issues fixed
    case partialSuccess    // Some issues fixed
    case noFixesNeeded     // Document was compliant
    case failed            // Could not fix
    case idRemoved         // PDF/A ID removed (became invalid)
}

/// Single metadata fix applied
public struct MetadataFix: Sendable, Codable {
    public let field: String
    public let originalValue: String?
    public let newValue: String?
    public let description: String
}
```

---

## Phase 5: Validators

### 5.1 Validator Interface and Configuration

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDFAValidator` (interface) | `PDFValidator` (protocol) | Validator protocol |
| `ValidatorConfig` (interface) | `ValidatorConfig` (struct) | Configuration |
| `ValidatorConfigImpl` | Part of struct | Consolidated |
| `ValidatorConfigBuilder` | Builder pattern or init | Swift init |
| `ValidatorFactory` | Part of `Foundry` | Consolidated |
| `BaseValidator` | Implementation detail | Internal |
| `FastFailValidator` | Option in config | Consolidated |
| `FlavourValidator` | Implementation detail | Internal |
| `JavaScriptEvaluator` | **In validation-profiles** | Expression evaluator |

```swift
/// Protocol for PDF validators
public protocol PDFValidator: Sendable {
    /// The validation profile being used
    var profile: ValidationProfile { get }

    /// Validate a parsed document
    func validate(_ document: ParsedDocument) async throws -> ValidationResult

    /// Validate a PDF from URL
    func validate(contentsOf url: URL) async throws -> ValidationResult
}

/// Validator configuration
public struct ValidatorConfig: Sendable {
    /// Maximum number of failures before stopping (0 = unlimited)
    public var maxFailures: Int = 0

    /// Whether to record passed assertions (for reporting)
    public var recordPassedAssertions: Bool = false

    /// Whether to log progress during validation
    public var logProgress: Bool = false

    /// Timeout for validation (nil = no timeout)
    public var timeout: TimeInterval?

    /// Whether to validate in parallel where possible
    public var parallelValidation: Bool = true

    public init() {}
}

/// Default Swift validator implementation
public struct SwiftPDFValidator: PDFValidator {
    public let profile: ValidationProfile
    public let config: ValidatorConfig
    private let evaluator: RuleExpressionEvaluator

    public init(profile: ValidationProfile, config: ValidatorConfig = .init()) {
        self.profile = profile
        self.config = config
        self.evaluator = RuleExpressionEvaluator()
    }

    public func validate(_ document: ParsedDocument) async throws -> ValidationResult {
        let start = Date()
        var assertions: [TestAssertion] = []

        // Group rules by object type for efficient evaluation
        let rulesByObject = Dictionary(grouping: profile.rules) { $0.object }

        // Validate each object type
        for (objectType, rules) in rulesByObject {
            let objects = document.objects(ofType: objectType)

            for object in objects {
                for rule in rules {
                    let assertion = try await evaluateRule(rule, on: object)
                    assertions.append(assertion)

                    // Check fast-fail
                    if config.maxFailures > 0,
                       assertions.filter({ $0.status == .failed }).count >= config.maxFailures {
                        break
                    }
                }
            }
        }

        let end = Date()
        let isCompliant = assertions.allSatisfy { $0.status != .failed }

        return ValidationResult(
            profile: profile,
            documentURL: document.url,
            isCompliant: isCompliant,
            assertions: assertions,
            duration: ValidationDuration(start: start, end: end)
        )
    }

    public func validate(contentsOf url: URL) async throws -> ValidationResult {
        let parser = try await SwiftPDFParser(url: url)
        let document = try await parser.parse()
        return try await validate(document)
    }

    private func evaluateRule(_ rule: ValidationRule, on object: any ValidationObject) async throws -> TestAssertion {
        let properties = object.validationProperties
        let result = try evaluator.evaluate(expression: rule.test, properties: properties)

        return TestAssertion(
            id: UUID(),
            ruleID: rule.id,
            status: result ? .passed : .failed,
            message: formatMessage(rule.error.message, with: properties, args: rule.error.arguments),
            location: object.location,
            context: nil,
            arguments: rule.error.arguments.map { $0.name }
        )
    }

    private func formatMessage(_ template: String, with properties: [String: PropertyValue], args: [ErrorArgument]) -> String {
        var message = template
        for (index, arg) in args.enumerated() {
            let placeholder = "%\(index + 1)"
            if let value = properties[arg.name] {
                message = message.replacingOccurrences(of: placeholder, with: value.description)
            }
        }
        return message
    }
}
```

---

## Phase 6: Parsers

### 6.1 Parser Interface

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDFAParser` (interface) | `PDFParser` (protocol) | Parser protocol |
| `GFModelParser` | `SwiftPDFParser` (struct) | Implementation |

```swift
/// Protocol for PDF document parsers
public protocol PDFParser: Sendable {
    /// URL of the document being parsed
    var url: URL { get }

    /// Parse the document
    func parse() async throws -> ParsedDocument

    /// Detected PDF flavour (if any)
    func detectFlavour() async throws -> PDFFlavour?
}

/// Parsed PDF document ready for validation
public protocol ParsedDocument: Sendable {
    var url: URL { get }
    var flavour: PDFFlavour? { get }

    /// Get all validation objects of a specific type
    func objects(ofType: String) -> [any ValidationObject]

    /// Get the structure tree root (for PDF/UA)
    var structureTreeRoot: StructureTreeRoot? { get }

    /// Get document metadata
    var metadata: DocumentMetadata? { get }
}

/// Swift implementation using parser package
public struct SwiftPDFParser: PDFParser {
    public let url: URL

    public init(url: URL) async throws {
        self.url = url
        // Initialize parser from SwiftVerificar-parser
    }

    public func parse() async throws -> ParsedDocument {
        // Use SwiftVerificar-parser to parse document
        // Return wrapped document for validation
    }

    public func detectFlavour() async throws -> PDFFlavour? {
        // Check XMP metadata for PDF/A or PDF/UA identification
    }
}
```

---

## Phase 7: Feature Extraction

### 7.1 Feature Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `FeatureExtractorConfig` (interface) | `FeatureConfig` (struct) | Configuration |
| `FeatureExtractorConfigImpl` | Part of struct | Consolidated |
| `FeatureExtractionResult` | `FeatureExtractionResult` (struct) | Result |
| `FeaturesReporter` | `FeatureReporter` (struct) | Reporter |
| `FeatureObjectType` (enum) | `FeatureType` (enum) | Feature types |
| `FeatureTreeNode` | `FeatureNode` (indirect enum) | Tree node |
| `FeaturesData` (interface) | `FeatureData` (protocol) | Feature data |

```swift
/// Configuration for feature extraction
public struct FeatureConfig: Sendable {
    /// Feature types to extract
    public var enabledFeatures: Set<FeatureType>

    /// Whether to include sub-features
    public var includeSubFeatures: Bool = true

    public init(enabledFeatures: Set<FeatureType> = Set(FeatureType.allCases)) {
        self.enabledFeatures = enabledFeatures
    }
}

/// Types of extractable features
public enum FeatureType: String, CaseIterable, Sendable, Codable {
    case informationDictionary
    case metadata
    case documentSecurity
    case signatures
    case lowLevelInfo
    case embeddedFiles
    case iccProfiles
    case outputIntents
    case outlines
    case annotations
    case pages
    case graphicsStates
    case colorSpaces
    case patterns
    case shadings
    case xObjects
    case fonts
    case properties
    case interactiveFormFields
}

/// Result of feature extraction
public struct FeatureExtractionResult: Sendable, Codable {
    public let documentURL: URL
    public let features: FeatureNode
    public let errors: [FeatureError]
}

/// Tree node for extracted features
public indirect enum FeatureNode: Sendable, Codable {
    case leaf(name: String, value: String?)
    case branch(name: String, children: [FeatureNode], attributes: [String: String])

    public var name: String {
        switch self {
        case .leaf(let name, _): return name
        case .branch(let name, _, _): return name
        }
    }
}

/// Feature extractor protocol
public protocol FeatureExtractor: Sendable {
    func extract(from document: ParsedDocument) async throws -> FeatureExtractionResult
}
```

---

## Phase 8: Metadata Fixing

### 8.1 Fixer Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `MetadataFixer` (interface) | `MetadataFixer` (protocol) | Fixer protocol |
| `MetadataFixerConfig` (interface) | `FixerConfig` (struct) | Configuration |
| `FixerFactory` | Part of `Foundry` | Consolidated |
| Schema classes (4) | XMP schema types | From validation module |

```swift
/// Protocol for metadata fixers
public protocol MetadataFixer: Sendable {
    /// Fix metadata in a document
    func fix(
        document: ParsedDocument,
        validationResult: ValidationResult,
        outputURL: URL
    ) async throws -> MetadataFixerResult
}

/// Fixer configuration
public struct FixerConfig: Sendable {
    /// Whether to fix Info dictionary
    public var fixInfoDictionary: Bool = true

    /// Whether to fix XMP metadata
    public var fixXMPMetadata: Bool = true

    /// Whether to sync Info and XMP
    public var syncInfoAndXMP: Bool = true

    public init() {}
}
```

---

## Phase 9: Processor API (Main Entry Point)

### 9.1 Processor Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `Processor` (interface) | Part of `SwiftPDFValidator` | Consolidated |
| `ProcessorConfig` | `ProcessorConfig` (struct) | Configuration |
| `ProcessorImpl` | `PDFProcessor` (struct) | Main processor |
| `ProcessorFactory` | Part of `Foundry` | Consolidated |
| `ProcessorResult` (interface) | `ProcessorResult` (struct) | Combined result |
| `ItemProcessor` (interface) | `SingleFileProcessor` (protocol) | Single file |
| `BatchProcessor` (interface) | `BatchProcessor` (protocol) | Multiple files |
| `TaskType` (enum) | `ProcessorTask` (enum) | Task types |
| `FormatOption` (enum) | `OutputFormat` (enum) | Output formats |

```swift
/// Configuration for processing operations
public struct ProcessorConfig: Sendable {
    /// Validation configuration
    public var validatorConfig: ValidatorConfig = .init()

    /// Feature extraction configuration
    public var featureConfig: FeatureConfig?

    /// Metadata fixer configuration
    public var fixerConfig: FixerConfig?

    /// Tasks to perform
    public var tasks: Set<ProcessorTask> = [.validate]

    public init() {}
}

/// Processing tasks
public enum ProcessorTask: Sendable {
    case validate
    case extractFeatures
    case fixMetadata
}

/// Combined processing result
public struct ProcessorResult: Sendable {
    public let documentURL: URL
    public let validationResult: ValidationResult?
    public let featureResult: FeatureExtractionResult?
    public let fixerResult: MetadataFixerResult?
    public let errors: [VerificarError]
}

/// Output format options
public enum OutputFormat: String, CaseIterable, Sendable {
    case json
    case xml
    case text
    case html
}
```

---

## Phase 10: Main Public API

### 10.1 SwiftPDFValidator (Main Entry Point for Lazarillo)

```swift
/// Main entry point for SwiftVerificar - designed for Lazarillo integration
public struct SwiftVerificar {
    /// Shared instance
    public static let shared = SwiftVerificar()

    private let foundry: SwiftFoundry

    public init() {
        self.foundry = SwiftFoundry()
    }

    // MARK: - Simple API (Most Common Use Cases)

    /// Validate a PDF against PDF/UA-2 (most common for Lazarillo)
    public func validateAccessibility(
        _ url: URL,
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> ValidationResult {
        try await validate(url, profile: .pdfUA2, progress: progress)
    }

    /// Validate a PDF against a specific profile
    public func validate(
        _ url: URL,
        profile flavour: PDFFlavour,
        config: ValidatorConfig = .init(),
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> ValidationResult {
        progress?(0.1, "Loading profile...")
        let profile = try await ProfileLoader.shared.loadProfile(for: flavour)

        progress?(0.2, "Parsing document...")
        let parser = try await foundry.createParser(for: url)
        let document = try await parser.parse()

        progress?(0.4, "Validating...")
        let validator = foundry.createValidator(profile: profile, config: config)
        let result = try await validator.validate(document)

        progress?(1.0, "Complete")
        return result
    }

    // MARK: - Advanced API

    /// Full processing with validation, features, and fixing
    public func process(
        _ url: URL,
        config: ProcessorConfig,
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> ProcessorResult {
        var result = ProcessorResult(
            documentURL: url,
            validationResult: nil,
            featureResult: nil,
            fixerResult: nil,
            errors: []
        )

        // Parse document once
        let parser = try await foundry.createParser(for: url)
        let document = try await parser.parse()

        // Validation
        if config.tasks.contains(.validate) {
            progress?(0.2, "Validating...")
            if let flavour = try await parser.detectFlavour() {
                let profile = try await ProfileLoader.shared.loadProfile(for: flavour)
                let validator = foundry.createValidator(profile: profile, config: config.validatorConfig)
                result.validationResult = try await validator.validate(document)
            }
        }

        // Feature extraction
        if config.tasks.contains(.extractFeatures), let featureConfig = config.featureConfig {
            progress?(0.5, "Extracting features...")
            let extractor = foundry.createFeatureExtractor(config: featureConfig)
            result.featureResult = try await extractor.extract(from: document)
        }

        // Metadata fixing
        if config.tasks.contains(.fixMetadata),
           let fixerConfig = config.fixerConfig,
           let validationResult = result.validationResult,
           !validationResult.isCompliant {
            progress?(0.8, "Fixing metadata...")
            let fixer = foundry.createMetadataFixer(config: fixerConfig)
            let outputURL = url.deletingLastPathComponent()
                .appendingPathComponent(url.deletingPathExtension().lastPathComponent + "_fixed.pdf")
            result.fixerResult = try await fixer.fix(
                document: document,
                validationResult: validationResult,
                outputURL: outputURL
            )
        }

        progress?(1.0, "Complete")
        return result
    }

    // MARK: - Batch Processing

    /// Validate multiple PDFs concurrently
    public func validateBatch(
        _ urls: [URL],
        profile flavour: PDFFlavour,
        maxConcurrency: Int = 4,
        progress: ((Int, Int, URL?) -> Void)? = nil
    ) async throws -> [URL: Result<ValidationResult, Error>] {
        let profile = try await ProfileLoader.shared.loadProfile(for: flavour)

        return await withTaskGroup(of: (URL, Result<ValidationResult, Error>).self) { group in
            var results: [URL: Result<ValidationResult, Error>] = [:]
            var completed = 0

            for url in urls {
                group.addTask {
                    do {
                        let parser = try await self.foundry.createParser(for: url)
                        let document = try await parser.parse()
                        let validator = self.foundry.createValidator(profile: profile, config: .init())
                        let result = try await validator.validate(document)
                        return (url, .success(result))
                    } catch {
                        return (url, .failure(error))
                    }
                }
            }

            for await (url, result) in group {
                results[url] = result
                completed += 1
                progress?(completed, urls.count, url)
            }

            return results
        }
    }
}
```

---

## Phase 11: Reports and Output

### 11.1 Report Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `ValidationReport` (interface) | `ValidationReport` (struct) | Report |
| `ValidationDetails` (interface) | Part of `ValidationReport` | Consolidated |
| `RuleSummary` (interface) | `RuleSummary` (struct) | Per-rule summary |
| `FeaturesReport` | `FeatureReport` (struct) | Features report |
| `HTMLReport` | `HTMLReportGenerator` (struct) | HTML output |
| `XsltTransformer` | Not needed | Use Swift templates |
| `JsonHandler` | `Codable` conformance | Native Swift |

```swift
/// Complete validation report with summaries
public struct ValidationReport: Sendable, Codable {
    public let result: ValidationResult
    public let summaries: [RuleSummary]

    /// Generate from validation result
    public static func generate(from result: ValidationResult) -> ValidationReport {
        let summaries = Dictionary(grouping: result.assertions) { $0.ruleID }
            .map { (ruleID, assertions) in
                RuleSummary(
                    ruleID: ruleID,
                    passedCount: assertions.filter { $0.status == .passed }.count,
                    failedCount: assertions.filter { $0.status == .failed }.count,
                    description: assertions.first?.message ?? ""
                )
            }
            .sorted { $0.failedCount > $1.failedCount }

        return ValidationReport(result: result, summaries: summaries)
    }
}

/// Summary for a single rule
public struct RuleSummary: Sendable, Codable {
    public let ruleID: RuleID
    public let passedCount: Int
    public let failedCount: Int
    public let description: String

    public var totalChecks: Int { passedCount + failedCount }
    public var failureRate: Double {
        guard totalChecks > 0 else { return 0 }
        return Double(failedCount) / Double(totalChecks)
    }
}

/// Report output generators
public enum ReportGenerator {
    /// Generate JSON report
    public static func json(from report: ValidationReport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(report)
    }

    /// Generate XML report
    public static func xml(from report: ValidationReport) throws -> Data {
        // Use XMLEncoder or custom XML generation
    }

    /// Generate HTML report
    public static func html(from report: ValidationReport) -> String {
        // Generate HTML using string templates
    }
}
```

---

## Phase 12: XMP Model (Shared Types)

### 12.1 XMP Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `XMPMeta` (interface) | `XMPMetadata` (struct) | XMP metadata |
| `XMPMetaFactory` | `XMPParser` (struct) | Parser |
| `XMPProperty` (interface) | `XMPProperty` (struct) | Property |
| `XMPDateTime` (interface) | `Date` | Use stdlib |
| Various validators | `XMPValidator` (struct) | Consolidated |
| `AXLMainXMPPackage` | `MainXMPPackage` (struct) | Main package |
| `AXLPDFAIdentification` | `PDFAIdentification` (struct) | PDF/A ID |
| `AXLPDFUAIdentification` | `PDFUAIdentification` (struct) | PDF/UA ID |

```swift
/// XMP metadata container
public struct XMPMetadata: Sendable, Codable {
    public let packages: [XMPPackage]

    public var pdfaIdentification: PDFAIdentification? {
        // Extract from packages
    }

    public var pdfuaIdentification: PDFUAIdentification? {
        // Extract from packages
    }

    public var dublinCore: DublinCoreMetadata? {
        // Extract from packages
    }
}

/// PDF/A identification schema
public struct PDFAIdentification: Sendable, Codable {
    public let part: Int           // 1, 2, 3, or 4
    public let conformance: String // a, b, u, e, f
    public let amendment: String?
    public let revision: String?
}

/// PDF/UA identification schema
public struct PDFUAIdentification: Sendable, Codable {
    public let part: Int           // 1 or 2
    public let revision: String?
}
```

---

## Testing Strategy

### Unit Tests

1. **Foundry Tests**
   - Test component creation
   - Test configuration handling

2. **Validation Result Tests**
   - Test result aggregation
   - Test compliance calculation

3. **Processor Tests**
   - Test single file processing
   - Test batch processing
   - Test progress reporting

4. **Report Generation Tests**
   - Test JSON output
   - Test XML output
   - Test HTML output

### Integration Tests

1. **End-to-End Validation**
   - Validate reference PDFs
   - Compare with veraPDF results

2. **Lazarillo Integration**
   - Test API compatibility
   - Test result format

### Performance Tests

1. **Large Document Processing**
   - Memory usage
   - Processing time

2. **Batch Processing**
   - Concurrent validation
   - Resource utilization

---

## Phased Implementation

### Phase 1: MVP - Basic Validation
1. Core error types
2. Foundry system
3. Basic validator
4. ValidationResult type
5. Simple API for Lazarillo

### Phase 2: Complete Validation
1. Full validator implementation
2. All result types
3. Progress reporting
4. Batch processing

### Phase 3: Feature Extraction
1. Feature extractor
2. Feature types
3. Feature reporting

### Phase 4: Metadata Fixing
1. Metadata fixer
2. XMP handling
3. Document modification

### Phase 5: Reports and Output
1. Report generation
2. Multiple output formats
3. HTML reports

---

## Performance Optimizations

1. **Async Processing**
   - All I/O operations async
   - Progress reporting via callbacks

2. **Concurrent Validation**
   - Parallel rule evaluation
   - Concurrent batch processing

3. **Memory Efficiency**
   - Stream large documents
   - Release resources promptly

4. **Caching**
   - Cache parsed profiles
   - Cache compiled expressions

---

## Class Count Summary

| Category | Java Classes | Swift Types | Reduction |
|----------|-------------|-------------|-----------|
| Core/Components | 15 | 5 | 67% |
| Foundry/Factory | 10 | 3 | 70% |
| Validation | 25 | 8 | 68% |
| Results | 15 | 6 | 60% |
| Features | 20 | 8 | 60% |
| Metadata | 15 | 6 | 60% |
| Processor | 25 | 5 | 80% |
| Reports | 25 | 6 | 76% |
| XMP | 30 | 10 | 67% |
| Utils | 70 | 15 | 79% |
| **Total** | **~250** | **~72** | **71%** |

Major consolidations:
- Multiple exception classes → 1 error enum
- Factory + provider + registry → 1 actor
- Multiple handler classes → 1 processor struct
- Report writers → Codable + extensions
- XMP implementation classes → protocol-based structs
