# SwiftVerificar-biblioteca Progress

## Current State
- Last completed sprint: Wiring Sprint 14 (FINAL)
- Build status: passing
- Total test count: 1609+
- Cumulative coverage: ~95%
- **Wiring phase COMPLETE. All 55+ types fully implemented.**

## Completed Sprints
- Sprint 1: Dependency Setup + Core Errors -- 4 types, 68 tests
- Sprint 2: Foundry System -- 3 types + 4 placeholder protocols + 3 configuration structs, 81 tests
- Sprint 3: Validation Results Core -- 4 types, 81 tests
- Sprint 4: Validation Results Extended -- 3 types, 100 tests
- Sprint 5: Validators -- 5 types (PDFValidator protocol, ValidatorConfig struct, SwiftPDFValidator struct, ParsedDocument protocol, ValidationObject protocol), 91 tests
- Sprint 6: Parsers -- 3 types (PDFParser protocol, SwiftPDFParser struct, DocumentMetadata struct) + expanded ParsedDocument protocol, 85 tests
- Sprint 7: Feature Extraction -- 7 types (FeatureType enum, FeatureNode indirect enum, FeatureError struct, FeatureConfig struct, FeatureExtractionResult struct, FeatureReporter struct, FeatureData protocol), 191 tests
- Sprint 8: Metadata + Processor -- 7 types (MetadataFixer protocol, FixerConfig struct, ProcessorTask enum, OutputFormat enum, ProcessorConfig struct, ProcessorResult struct, PDFProcessor struct), 200 tests
- Sprint 9: XMP Model -- 10 types (XMPMetadata, XMPParser, XMPProperty, XMPValidator, MainXMPPackage, PDFAIdentification, PDFUAIdentification, XMPPackage, DublinCoreMetadata, XMPValidationIssue), 289 tests
- Sprint 10: Reports -- 4 types (ValidationReport struct, RuleSummary struct, FeatureReport struct, ReportGenerator enum + ReportGeneratorError enum), 124 tests
- Sprint 11: Main Public API -- 1 type (SwiftVerificar struct), 52 tests -- FINAL SPRINT

## Files Created (cumulative)
### Sources
- Sources/SwiftVerificarBiblioteca/SwiftVerificarBiblioteca.swift
- Sources/SwiftVerificarBiblioteca/SwiftVerificar.swift
- Sources/SwiftVerificarBiblioteca/Core/ValidatorComponent.swift
- Sources/SwiftVerificarBiblioteca/Core/ComponentInfo.swift
- Sources/SwiftVerificarBiblioteca/Core/ValidationDuration.swift
- Sources/SwiftVerificarBiblioteca/Core/VerificarError.swift
- Sources/SwiftVerificarBiblioteca/Foundry/ValidationFoundry.swift
- Sources/SwiftVerificarBiblioteca/Foundry/Foundry.swift
- Sources/SwiftVerificarBiblioteca/Foundry/SwiftFoundry.swift
- Sources/SwiftVerificarBiblioteca/Results/AssertionStatus.swift
- Sources/SwiftVerificarBiblioteca/Results/PDFLocation.swift
- Sources/SwiftVerificarBiblioteca/Results/TestAssertion.swift
- Sources/SwiftVerificarBiblioteca/Results/ValidationResult.swift
- Sources/SwiftVerificarBiblioteca/Results/RepairStatus.swift
- Sources/SwiftVerificarBiblioteca/Results/MetadataFix.swift
- Sources/SwiftVerificarBiblioteca/Results/MetadataFixerResult.swift
- Sources/SwiftVerificarBiblioteca/Validators/ParsedDocument.swift (expanded in Sprint 6: added pageCount, metadata, hasStructureTree + DocumentMetadata struct)
- Sources/SwiftVerificarBiblioteca/Validators/PDFValidator.swift
- Sources/SwiftVerificarBiblioteca/Validators/ValidatorConfig.swift
- Sources/SwiftVerificarBiblioteca/Validators/SwiftPDFValidator.swift
- Sources/SwiftVerificarBiblioteca/Parsers/PDFParser.swift
- Sources/SwiftVerificarBiblioteca/Parsers/ParsedDocumentAdapter.swift (new in Wiring Sprint 1)
- Sources/SwiftVerificarBiblioteca/Parsers/SwiftPDFParser.swift (wired to PDFKit in Wiring Sprint 1)
- Sources/SwiftVerificarBiblioteca/Features/FeatureType.swift
- Sources/SwiftVerificarBiblioteca/Features/FeatureNode.swift
- Sources/SwiftVerificarBiblioteca/Features/FeatureError.swift
- Sources/SwiftVerificarBiblioteca/Features/FeatureConfig.swift
- Sources/SwiftVerificarBiblioteca/Features/FeatureExtractionResult.swift
- Sources/SwiftVerificarBiblioteca/Features/FeatureReporter.swift
- Sources/SwiftVerificarBiblioteca/Features/FeatureData.swift
- Sources/SwiftVerificarBiblioteca/Fixer/MetadataFixer.swift
- Sources/SwiftVerificarBiblioteca/Fixer/FixerConfig.swift
- Sources/SwiftVerificarBiblioteca/Processor/ProcessorTask.swift
- Sources/SwiftVerificarBiblioteca/Processor/OutputFormat.swift
- Sources/SwiftVerificarBiblioteca/Processor/ProcessorConfig.swift
- Sources/SwiftVerificarBiblioteca/Processor/ProcessorResult.swift
- Sources/SwiftVerificarBiblioteca/Processor/PDFProcessor.swift
- Sources/SwiftVerificarBiblioteca/XMP/PDFAIdentification.swift
- Sources/SwiftVerificarBiblioteca/XMP/PDFUAIdentification.swift
- Sources/SwiftVerificarBiblioteca/XMP/XMPProperty.swift
- Sources/SwiftVerificarBiblioteca/XMP/XMPPackage.swift
- Sources/SwiftVerificarBiblioteca/XMP/DublinCoreMetadata.swift
- Sources/SwiftVerificarBiblioteca/XMP/XMPValidationIssue.swift
- Sources/SwiftVerificarBiblioteca/XMP/MainXMPPackage.swift
- Sources/SwiftVerificarBiblioteca/XMP/XMPMetadata.swift
- Sources/SwiftVerificarBiblioteca/XMP/XMPParser.swift
- Sources/SwiftVerificarBiblioteca/XMP/XMPValidator.swift
- Sources/SwiftVerificarBiblioteca/Reports/RuleSummary.swift
- Sources/SwiftVerificarBiblioteca/Reports/ValidationReport.swift
- Sources/SwiftVerificarBiblioteca/Reports/FeatureReport.swift
- Sources/SwiftVerificarBiblioteca/Reports/ReportGenerator.swift
- Sources/SwiftVerificarBiblioteca/Adapters/SemanticNodeAdapter.swift (new in Wiring Sprint 6)
- Sources/SwiftVerificarBiblioteca/Adapters/WCAGResultMapper.swift (new in Wiring Sprint 6)
- Sources/SwiftVerificarBiblioteca/Fixer/SwiftMetadataFixer.swift (new in Wiring Sprint 8)
- Sources/SwiftVerificarBiblioteca/Adapters/FeatureExtractorAdapter.swift (new in Wiring Sprint 7)
- Sources/SwiftVerificarBiblioteca/Adapters/WCAGCheckRunner.swift (new in Wiring Sprint 7)

### Tests
- Tests/SwiftVerificarBibliotecaTests/SwiftVerificarBibliotecaTests.swift
- Tests/SwiftVerificarBibliotecaTests/SwiftVerificarTests.swift
- Tests/SwiftVerificarBibliotecaTests/Core/ValidatorComponentTests.swift
- Tests/SwiftVerificarBibliotecaTests/Core/ComponentInfoTests.swift
- Tests/SwiftVerificarBibliotecaTests/Core/ValidationDurationTests.swift
- Tests/SwiftVerificarBibliotecaTests/Core/VerificarErrorTests.swift
- Tests/SwiftVerificarBibliotecaTests/Foundry/ValidationFoundryTests.swift
- Tests/SwiftVerificarBibliotecaTests/Foundry/FoundryTests.swift
- Tests/SwiftVerificarBibliotecaTests/Foundry/SwiftFoundryTests.swift
- Tests/SwiftVerificarBibliotecaTests/Results/AssertionStatusTests.swift
- Tests/SwiftVerificarBibliotecaTests/Results/PDFLocationTests.swift
- Tests/SwiftVerificarBibliotecaTests/Results/TestAssertionTests.swift
- Tests/SwiftVerificarBibliotecaTests/Results/ValidationResultTests.swift
- Tests/SwiftVerificarBibliotecaTests/Results/RepairStatusTests.swift
- Tests/SwiftVerificarBibliotecaTests/Results/MetadataFixTests.swift
- Tests/SwiftVerificarBibliotecaTests/Results/MetadataFixerResultTests.swift
- Tests/SwiftVerificarBibliotecaTests/Validators/PDFValidatorTests.swift (modified in Sprint 6: updated MockParsedDocument for expanded protocol)
- Tests/SwiftVerificarBibliotecaTests/Validators/ValidatorConfigTests.swift
- Tests/SwiftVerificarBibliotecaTests/Validators/SwiftPDFValidatorTests.swift
- Tests/SwiftVerificarBibliotecaTests/Parsers/PDFParserTests.swift
- Tests/SwiftVerificarBibliotecaTests/Parsers/SwiftPDFParserTests.swift
- Tests/SwiftVerificarBibliotecaTests/Parsers/ParsedDocumentTests.swift
- Tests/SwiftVerificarBibliotecaTests/Features/FeatureTypeTests.swift
- Tests/SwiftVerificarBibliotecaTests/Features/FeatureNodeTests.swift
- Tests/SwiftVerificarBibliotecaTests/Features/FeatureErrorTests.swift
- Tests/SwiftVerificarBibliotecaTests/Features/FeatureConfigTests.swift
- Tests/SwiftVerificarBibliotecaTests/Features/FeatureExtractionResultTests.swift
- Tests/SwiftVerificarBibliotecaTests/Features/FeatureReporterTests.swift
- Tests/SwiftVerificarBibliotecaTests/Features/FeatureDataTests.swift
- Tests/SwiftVerificarBibliotecaTests/Fixer/MetadataFixerTests.swift
- Tests/SwiftVerificarBibliotecaTests/Fixer/FixerConfigTests.swift
- Tests/SwiftVerificarBibliotecaTests/Processor/ProcessorTaskTests.swift
- Tests/SwiftVerificarBibliotecaTests/Processor/OutputFormatTests.swift
- Tests/SwiftVerificarBibliotecaTests/Processor/ProcessorConfigTests.swift
- Tests/SwiftVerificarBibliotecaTests/Processor/ProcessorResultTests.swift
- Tests/SwiftVerificarBibliotecaTests/Processor/PDFProcessorTests.swift
- Tests/SwiftVerificarBibliotecaTests/XMP/PDFAIdentificationTests.swift
- Tests/SwiftVerificarBibliotecaTests/XMP/PDFUAIdentificationTests.swift
- Tests/SwiftVerificarBibliotecaTests/XMP/XMPPropertyTests.swift
- Tests/SwiftVerificarBibliotecaTests/XMP/XMPPackageTests.swift
- Tests/SwiftVerificarBibliotecaTests/XMP/DublinCoreMetadataTests.swift
- Tests/SwiftVerificarBibliotecaTests/XMP/XMPValidationIssueTests.swift
- Tests/SwiftVerificarBibliotecaTests/XMP/MainXMPPackageTests.swift
- Tests/SwiftVerificarBibliotecaTests/XMP/XMPMetadataTests.swift
- Tests/SwiftVerificarBibliotecaTests/XMP/XMPParserTests.swift
- Tests/SwiftVerificarBibliotecaTests/XMP/XMPValidatorTests.swift
- Tests/SwiftVerificarBibliotecaTests/Reports/RuleSummaryTests.swift
- Tests/SwiftVerificarBibliotecaTests/Reports/ValidationReportTests.swift
- Tests/SwiftVerificarBibliotecaTests/Reports/FeatureReportTests.swift
- Tests/SwiftVerificarBibliotecaTests/Reports/ReportGeneratorTests.swift
- Tests/SwiftVerificarBibliotecaTests/Integration/CrossPackageIntegrationTests.swift
- Tests/SwiftVerificarBibliotecaTests/Integration/ReportIntegrationTests.swift (new in Wiring Sprint 11)
- Tests/SwiftVerificarBibliotecaTests/Integration/EndToEndTests.swift (new in Wiring Sprint 12)
- Tests/SwiftVerificarBibliotecaTests/Integration/PerformanceTests.swift (new in Wiring Sprint 12)
- Tests/SwiftVerificarBibliotecaTests/Integration/ErrorHandlingTests.swift (new in Wiring Sprint 13)

## Wiring Sprints

### Wiring Sprint 1: Wire SwiftPDFParser to Real PDF Parsing
- **New file**: `Sources/SwiftVerificarBiblioteca/Parsers/ParsedDocumentAdapter.swift` -- `ParsedDocumentAdapter` struct conforming to `ParsedDocument`, wraps parser output with URL, flavour, page count, metadata, and structure tree flag. `objects(ofType:)` returns empty array (Sprint 2 will add object model traversal).
- **Modified**: `Sources/SwiftVerificarBiblioteca/Parsers/SwiftPDFParser.swift` -- Replaced stub implementations with real PDF parsing using Apple's `PDFKit` framework:
  - `parse()`: Loads PDF via `PDFKit.PDFDocument`, extracts page count, metadata (title, author, subject, etc.), structure tree presence (via outline proxy), and XMP-based flavour detection. Returns `ParsedDocumentAdapter`.
  - `detectFlavour()`: Loads PDF, searches raw data for XMP metadata packets, parses with `XMPParser`, maps PDF/A and PDF/UA identification schemas to `PDFFlavour` enum values.
  - Error handling: File not found -> `.parsingFailed`, invalid PDF -> `.parsingFailed`, encrypted+locked -> `.encryptedPDF`.
  - XMP detection: Searches raw PDF bytes for `<?xpacket begin` markers, extracts XMP string, delegates to biblioteca's `XMPParser`.
- **Modified**: `Tests/SwiftVerificarBibliotecaTests/Parsers/SwiftPDFParserTests.swift` -- Rewrote tests for real parsing behavior:
  - Added `createTestPDF()` helper using `PDFKit` to generate real PDF files in temp directory.
  - Tests for `parse()`: non-existent file throws `.parsingFailed`, non-PDF file throws `.parsingFailed`, real PDF succeeds with correct page count, multi-page PDF returns correct count, returns `ParsedDocumentAdapter` type, `objects(ofType:)` returns empty array.
  - Tests for `detectFlavour()`: non-existent file throws `.parsingFailed`, plain PDF without XMP returns `nil`.
  - Added `ParsedDocumentAdapter` unit tests: stores all properties, sensible defaults, conforms to `ParsedDocument`, is `Sendable`.
  - Retained all existing tests for initialization, Equatable, Sendable, ValidatorComponent, CustomStringConvertible, existential usage.
- **Modified**: `Tests/SwiftVerificarBibliotecaTests/Integration/CrossPackageIntegrationTests.swift` -- Updated 3 integration tests to expect `.parsingFailed` instead of `.configurationError` for non-existent file scenarios.
- Total tests: 1400 + 11 = 1411, all passing.
- **Strategy note**: Used `PDFKit` (macOS framework) for Sprint 1 instead of `PDFDocumentParser` from `SwiftVerificarParser`, because the parser package's `XRefParser` has known limitations (`skipWhitespace()` is a no-op, `parseTrailerDictionary()` returns empty). `PDFKit` provides reliable PDF parsing for macOS 14+. The `SwiftVerificarParser` package will be wired in a future sprint when its low-level parsing is more mature.

### Wiring Sprint 2: ParsedDocument Real Implementation
- **New type**: `CosDocumentObject` struct (in `ParsedDocumentAdapter.swift`) -- A `ValidationObject` representing the top-level COS document. Exposes 10 document-level properties for rule evaluation: `nrPages`, `isEncrypted`, `hasStructTreeRoot`, `isMarked`, `pdfVersion`, `hasXMPMetadata`, `title`, `author`, `producer`, `creator`.
- **Modified**: `Sources/SwiftVerificarBiblioteca/Parsers/ParsedDocumentAdapter.swift` -- Added `objectsByType` parameter to init and `objects(ofType:)` now returns stored validation objects by type key instead of always returning empty array.
- **Modified**: `Sources/SwiftVerificarBiblioteca/Parsers/SwiftPDFParser.swift`:
  - `parse()` now builds a `CosDocumentObject` with real document properties and passes it to `ParsedDocumentAdapter` via `objectsByType: ["CosDocument": [cosDoc]]`.
  - `checkStructureTree()` improved: now scans raw PDF data for `/StructTreeRoot` key instead of using outline as proxy. Falls back to outline check only if raw data cannot be read.
  - Added `extractPDFVersion()`: reads the `%PDF-X.Y` header from the first 1024 bytes of the file.
  - Added `checkIsMarked()`: scans raw PDF data for `/MarkInfo` dictionary with `/Marked true`.
- **Modified**: `Tests/SwiftVerificarBibliotecaTests/Parsers/SwiftPDFParserTests.swift`:
  - Updated existing test from "returns empty array" to verify CosDocument is returned with correct properties.
  - Added `parseObjectsReturnsEmptyForUnknownType` test.
  - Added `adapterReturnsObjects` test for ParsedDocumentAdapter with objectsByType.
  - Added `CosDocumentObject Tests` suite (16 tests): all property storage, default values, all property keys present, location, ValidationObject conformance, Sendable.
  - Added `Sprint 2: Real Parsing Integration Tests` suite (8 tests): metadata title/author extraction, multi-page count, CosDocument page count match, isEncrypted false, PDF version extraction, structure tree detection, XMP metadata reflection.
- **Modified**: `Tests/SwiftVerificarBibliotecaTests/Parsers/ParsedDocumentTests.swift`:
  - Added `ParsedDocumentAdapter CosDocument Integration Tests` suite (5 tests): adapter with CosDocument, multiple object types, CosDocument properties match metadata, empty objectsByType, Sendable with objects.
- Total tests: 1411 + 30 = 1441, all passing.

### Wiring Sprint 3: XMP Parser Real Implementation
- **Modified**: `Sources/SwiftVerificarBiblioteca/XMP/XMPParser.swift` -- Replaced stub `parse(from:)` with real XMP XML parsing using Foundation's `XMLParser`:
  - Uses non-namespace-aware mode (`shouldProcessNamespaces = false`) to preserve qualified attribute names like `pdfaid:part`.
  - Manually resolves `prefix:localName` qualified names against `xmlns:prefix="uri"` namespace declarations.
  - Extracts properties from both rdf:Description element attributes (e.g., `pdfaid:part="2"`) and child elements with text content (e.g., `<dc:title>My Doc</dc:title>`).
  - Groups extracted `XMPProperty` instances by namespace URI into `XMPPackage` instances.
  - Returns populated `XMPMetadata` with real packages -- the computed properties `pdfaIdentification`, `pdfuaIdentification`, and `dublinCore` now work on parsed data.
  - Internal `XMPXMLParserDelegate` class handles the `XMLParserDelegate` protocol.
  - Handles all key namespaces: `pdfaid:` (PDF/A ID), `pdfuaid:` (PDF/UA ID), `dc:` (Dublin Core), `xmp:` (XMP Basic), `pdf:` (Adobe PDF).
- **Modified**: `Sources/SwiftVerificarBiblioteca/XMP/XMPValidator.swift` -- Updated doc comment to remove "stub" reference; validation logic was already real (structural checks, PDF/A compliance, PDF/UA compliance).
- **Modified**: `Tests/SwiftVerificarBibliotecaTests/XMP/XMPParserTests.swift` -- Rewrote and expanded tests for real parsing behavior:
  - Updated existing tests: `parseFromDataValid` and `parseFromStringEmptyDescription` verify empty metadata for XML without namespace-prefixed properties.
  - Added 11 new tests: `parseFromDataRealXMP` (PDF/A from Data), `parsePDFA2uFromAttributes`, `parsePDFA1b`, `parsePDFAWithAmendment` (amd + rev), `parsePDFUA2`, `parsePDFUA1`, `parseDublinCoreTitle` (child elements), `parseDublinCoreFromAttributes`, `parseCombinedSchemas` (PDF/A + PDF/UA + DC), `parseXMPBasic` (CreatorTool, CreateDate), `parseChildElements` (pdfaid as child elements).
- **Modified**: `Tests/SwiftVerificarBibliotecaTests/XMP/XMPValidatorTests.swift` -- Added 3 new tests for full parse+validate pipeline:
  - `parseAndValidatePDFA2u`: Parse valid PDF/A-2u XMP then validate, expect no issues.
  - `parseAndValidatePDFUA2`: Parse valid PDF/UA-2 XMP then validate, expect no issues.
  - `parseAndValidateInvalidPDFAPart`: Parse invalid PDF/A part=5, validate, expect error.
- **Modified**: `Tests/SwiftVerificarBibliotecaTests/Integration/CrossPackageIntegrationTests.swift` -- Updated XMP integration tests to verify real parsing (not stub behavior):
  - `parseValidXMPReturnsMetadata`: Now verifies `packageCount >= 1` and checks `pdfaIdentification?.part == 2`.
  - `xmpMetadataIsBibliotecaType`: Updated comment to clarify minimal XML test.
  - `parseFromDataWorks`: Updated comment to clarify empty result for no-namespace XML.
- **PDFAIdentification, PDFUAIdentification, DublinCoreMetadata, MainXMPPackage, XMPPackage, XMPProperty, XMPValidationIssue**: No source changes needed -- these types were already fully implemented. They work correctly with the now-populated `XMPMetadata` returned by the real parser.
- **XMPValidator**: Already had real validation logic (not stubs). Now that `XMPParser` returns real data, the full parse -> validate pipeline works end-to-end.
- Total tests: 1441 + 14 = 1455, all passing.

### Wiring Sprint 4: Validation Object Mapping & Rule Evaluation
- **New types**: `PDPageObject` and `SEGenericObject` structs (in `ParsedDocumentAdapter.swift`) -- Two new `ValidationObject` types for page-level and structure-element-level validation.
  - `PDPageObject` exposes 9 page-level properties: `pageNumber`, `width`, `height`, `rotation`, `orientation` (computed from dimensions and rotation), `containsAnnotations`, `hasStructureElements`, `Tabs`, `containsTransparency`. Location uses 1-based page number.
  - `SEGenericObject` exposes 9 structure-element properties: `structureType`, `Alt`, `ActualText`, `title`, `Lang`, `parentStandardType`, `kidsStandardTypes`, `hasContentItems`, `isGrouping`. Properties use `"null"` (string literal) when absent to match veraPDF rule expression semantics (`!= null` checks).
- **Modified**: `Sources/SwiftVerificarBiblioteca/Parsers/ParsedDocumentAdapter.swift`:
  - Added `availableObjectTypes` computed property to list all stored object type keys.
  - Updated `objects(ofType:)` doc comment to mention PDPage and SE* types.
  - Added `PDPageObject` struct with orientation derivation logic (Portrait/Landscape/Square based on width, height, and rotation).
  - Added `SEGenericObject` struct with null-handling convention for optional properties.
- **Modified**: `Sources/SwiftVerificarBiblioteca/Parsers/SwiftPDFParser.swift`:
  - `parse()` now builds PDPage objects from PDFKit's `PDFPage` API (page dimensions, rotation, annotations) and SE* objects from raw data scanning.
  - Added `buildPageObjects(from:)`: iterates over all pages, extracts MediaBox dimensions, rotation, and annotation count via PDFKit.
  - Added `buildStructureElementObjects(from:hasStructureTree:)`: scans raw PDF bytes for `/S /TypeName` patterns to detect structure element types. Creates one `SEGenericObject` per detected standard type. Maps 37 standard types to their PDFObjectType keys (e.g., "Figure" -> "SEFigure", "Table" -> "SETable", "H1" -> "SEHn").
  - `objectsByType` dictionary now includes "PDPage" (one per page) and SE type keys (one per detected structure type).
- **Modified**: `Tests/SwiftVerificarBibliotecaTests/Parsers/SwiftPDFParserTests.swift`:
  - Added `PDPageObject Tests` suite (16 tests): all property storage, orientation computation (Portrait, Landscape, Square, rotation effects), default values, location with 1-based page number, all property keys present, ValidationObject conformance, Sendable.
  - Added `SEGenericObject Tests` suite (19 tests): structureType storage, Alt/ActualText/title/Lang null handling, parentStandardType, kidsStandardTypes, hasContentItems, isGrouping, default values, location with page+structureID, location when no page/ID, all property keys, ValidationObject conformance, Sendable.
  - Added `Sprint 4: PDPage Parsing Integration Tests` suite (8 tests): parse returns PDPage objects for each page, sequential page numbers, width/height from MediaBox, location with 1-based page number, page count matches document, orientation property, availableObjectTypes includes both types, single page PDF verification.
- **Modified**: `Tests/SwiftVerificarBibliotecaTests/Parsers/ParsedDocumentTests.swift`:
  - Added `ParsedDocumentAdapter Multi-Type Integration Tests` suite (6 tests): adapter with PDPage objects, adapter with SEGenericObject, adapter with all three types (CosDocument + PDPage + SEFigure), availableObjectTypes listing, adapter distinguishes between SE types, Sendable with all object types.
- Total tests: 1455 + 49 = 1504, all passing.
- **Strategy note**: Structure element detection uses raw byte scanning for `/S /TypeName` patterns as a lightweight heuristic. PDFKit does not expose the PDF structure tree API directly. This approach detects the presence of structure element types but creates only one representative object per type rather than enumerating every instance. Full structure tree traversal will be added when `PDFDocumentParser` from the parser package is wired (future sprint).

### Wiring Sprint 5: Wire SwiftPDFValidator to Validation Engine
- **Modified**: `Sources/SwiftVerificarBiblioteca/Validators/SwiftPDFValidator.swift` -- Replaced both `configurationError` stubs with real validation logic:
  - `validate(_ document:)`: Resolves `profileName` to `PDFFlavour` via internal `resolveFlavour()`, loads the `ValidationProfile` from `ProfileLoader.shared.loadProfile(for:)`, groups rules by object type, queries `document.objects(ofType:)` for matching objects, converts `ValidationObject.validationProperties` (String dictionary) to `PropertyValue` dictionary via heuristic type inference (bool/int/double/string/null), evaluates each rule's `test` expression using `RuleExpressionEvaluator` from validation-profiles, and collects results as `TestAssertion` instances. Assembles a `ValidationResult` with compliance status, timing duration, and all assertions.
  - `validate(contentsOf url:)`: Creates a `SwiftPDFParser(url:)`, calls `parse()` to get a `ParsedDocument`, then delegates to `validate(_:)`.
  - Config respect: `maxFailures` stops evaluation after N failures (fast-fail). `recordPassedAssertions` controls whether passed assertions appear in the result. `timeout` breaks evaluation if elapsed time exceeds the configured threshold.
  - Property inference: String values from `ValidationObject.validationProperties` are converted to `PropertyValue` using: `"true"`/`"false"` -> `.bool`, `"null"` -> `.null`, integer strings -> `.int`, decimal strings -> `.double`, everything else -> `.string`.
  - Profile variable bindings: `ProfileVariable.defaultValue` strings are converted to `PropertyValue` and merged with object properties for expression evaluation.
  - Error handling: Invalid profile name -> `profileNotFound`. Profile resource not found -> `profileNotFound`. Expression evaluation errors -> assertion with `.unknown` status. File not found in `validate(contentsOf:)` -> `parsingFailed` (from SwiftPDFParser).
- **Modified**: `Tests/SwiftVerificarBibliotecaTests/Validators/SwiftPDFValidatorTests.swift` -- Rewrote 4 tests that previously expected `configurationError` to test real validation behavior:
  - `validateDocumentReturnsResult`: Validates a `MockParsedDocument` with a `CosDocumentObject` against PDF/UA-2 profile, verifies a real `ValidationResult` is returned with the document URL and profile name.
  - `validateDocumentThrowsForInvalidProfile`: Verifies invalid profile name throws `profileNotFound` (was `configurationError`).
  - `validateDocumentThrowsSpecificError`: Verifies `profileNotFound` error carries the invalid profile name.
  - `validateURLThrowsForNonExistentFile`: Verifies non-existent file throws `parsingFailed` (was `configurationError`).
  - `validateURLThrowsParsingError`: Verifies `parsingFailed` error is thrown for non-existent file (was checking for "parser" in configurationError).
  - Added `Sprint 5: SwiftPDFValidator Real Validation` suite (14 new tests):
    - `validateWithPDFUA2Profile`: Loads real PDF/UA-2 profile, evaluates rules against CosDocument, verifies assertions are produced.
    - `validateWithPDFA2bProfile`: Loads real PDF/A-2b profile, evaluates rules.
    - `validateWithPDFUA1Profile`: Loads real PDF/UA-1 profile, evaluates rules.
    - `recordPassedAssertionsFalse`: Verifies passed assertions excluded when config says so.
    - `recordPassedAssertionsTrue`: Verifies more assertions with recordPassedAssertions=true vs false.
    - `maxFailuresLimitsFailures`: Verifies fast-fail stops at maxFailures.
    - `validateEmptyDocument`: Empty document returns compliant result with 0 assertions.
    - `assertionsHaveValidRuleIDs`: All assertions have non-empty clause and positive test number.
    - `assertionsIncludeContext`: All assertions for CosDocument have context="CosDocument".
    - `failedAssertionsHaveMessages`: All failed assertions have non-empty messages.
    - `resultHasDuration`: Duration is non-negative.
    - `validateContentsOfRealPDF`: Creates real PDF via PDFKit, validates with `validate(contentsOf:)`.
    - `variousProfileNameFormats`: Tests multiple profile names ("PDF/UA-2", "PDF/A-2b", "PDF/A-1a", "PDF/UA-1") all resolve and validate successfully.
- Total tests: 1504 + 14 = 1518, all passing.
- **Architecture note**: The validator uses a "direct evaluation" approach rather than wiring the full `ValidationEngine` from `SwiftVerificarValidation`. It loads profiles via `ProfileLoader`, iterates rules, and evaluates expressions via `RuleExpressionEvaluator` -- both from `SwiftVerificarValidationProfiles`. This is simpler and avoids the complexity of the full engine's `RuleExecutor` and `ObjectValidator` layers, while still producing real validation results from the actual bundled XML profile rules.

### Wiring Sprint 7: Feature Extraction Wiring
- Wired `SwiftFeatureExtractor` with real implementation backed by PDFKit.
- New `FeatureExtractorAdapter.swift` bridges parsed document data to feature extraction pipeline.
- New `WCAGCheckRunner.swift` consolidates WCAG check execution.
- Foundry updated to return `SwiftFeatureExtractor` instead of stub.

### Wiring Sprint 8: Metadata Fixer Wiring
- Real `SwiftMetadataFixer` implementation in `Fixer/SwiftMetadataFixer.swift`.
- Analyzes validation failures for metadata-related issues, plans XMP/Info dict fixes, writes corrected PDF copy via PDFKit.
- Foundry updated to return `SwiftMetadataFixer` instead of stub.
- All four foundry components now return real implementations.

### Wiring Sprint 9: PDFProcessor Full Pipeline
- Replaced all 3 stub processing phases (validation, feature extraction, metadata fixing) with real pipeline calls.
- `PDFProcessor.process()` now parses once, then runs validation via `SwiftPDFValidator`, feature extraction via `SwiftFeatureExtractor`, and metadata fixing via `SwiftMetadataFixer`.
- Error handling wraps phase failures into `ProcessorResult.errors`.

### Wiring Sprint 10: SwiftVerificar Main Public API
- Wired `SwiftVerificar.validate()` to delegate to `SwiftPDFValidator` instead of throwing `configurationError` stub.
- `validateAccessibility()`, `validate()`, `process()`, and `validateBatch()` all produce real results.
- Removed the last `configurationError` stub from the main public API path.

### Wiring Sprint 11: Report Generation Integration Tests
- New `ReportIntegrationTests.swift` with tests verifying `ReportGenerator` produces correct output from real validation results.
- Tests cover XML, JSON, and text report formats with real validation data.

### Wiring Sprint 12: End-to-End Integration Tests + Performance Tests
- New `EndToEndTests.swift` with full pipeline tests: parse -> validate -> fix -> extract -> report.
- New `PerformanceTests.swift` with timing benchmarks for parsing, validation, and feature extraction.
- Tests use real PDF files generated via PDFKit.

### Wiring Sprint 13: Error Handling & Edge Cases
- New `ErrorHandlingTests.swift` covering cancellation support, concurrent access, and edge case error descriptions.
- Added `Task.checkCancellation()` calls at key points in `SwiftPDFValidator`, `PDFProcessor`, and `SwiftVerificar`.
- Improved error descriptions for `VerificarError` cases.

### Wiring Sprint 14: Performance Optimization & Release Prep
- Removed 4 dead stub types from `SwiftFoundry.swift` (`StubPDFParser`, `StubPDFValidator`, `StubMetadataFixer`, `StubFeatureExtractor`).
- Updated outdated "placeholder" and "stub" comments across foundry system.
- Updated AGENTS.md, README.md, PROGRESS.md with final state.
- All 55+ types fully wired with real implementations, 1609+ tests passing.

## Reconciliation

### Reconciliation Pass 1, Sprint 3: Cross-package integration tests
- **New file**: `Tests/SwiftVerificarBibliotecaTests/Integration/CrossPackageIntegrationTests.swift` -- 38 tests across 7 test suites
- **PDFFlavour Type Agreement** (6 tests): Verifies all enum cases are accessible from SwiftVerificarValidationProfiles, displayName works, computed properties (isPDFA, isPDFUA, isAccessibilityRelated) work, round-trips through ParsedDocument.flavour, CaseIterable, and Codable conformance.
- **ProfileLoader Integration** (5 tests): Verifies ProfileLoader.shared is accessible, loadProfile(for:) can be called with .pdfUA2 and various flavours, isCached returns Bool, cachedFlavours returns Set<PDFFlavour>.
- **SwiftVerificar Validate Cross-Package Path** (5 tests): Verifies validate() with "PDF/UA-2" reaches the validation engine stub (past profile loading), "INVALID" throws profileNotFound, empty profile throws profileNotFound, multiple valid profiles reach configurationError, validateAccessibility delegates to PDF/UA-2 path.
- **SwiftPDFParser Cross-Package Type Path** (5 tests): Verifies instantiation, detectFlavour() returns PDFFlavour? not String?, parse() throws configurationError stub, conforms to PDFParser, protocol signature uses PDFFlavour.
- **XMPParser Cross-Package Integration** (4 tests): Verifies instantiation, empty string throws parsingFailed, valid XMP string returns XMPMetadata, XMPMetadata is the biblioteca model type, parse from Data works.
- **PDFProcessor Cross-Package Integration** (5 tests): Verifies instantiation, process returns ProcessorResult with errors, all tasks produce 3 errors, empty tasks return config error, error messages reference cross-package types, SwiftVerificar.process delegates correctly.
- **Cross-Package Type Consistency** (4 tests): Verifies all VerificarError cases accessible, PDFFlavour.specification mapping works, SwiftVerificar is Sendable across tasks, all integration types are Sendable.
- Total tests: 1362 + 38 = 1400, all passing.

### Reconciliation Pass 1, Sprint 2: Wire stubs to dependency types
- **SwiftVerificar.swift**: `validate()` now resolves profile names to `PDFFlavour` via `resolveFlavour()` helper and loads profiles via `ProfileLoader.shared.loadProfile(for:)` from `SwiftVerificarValidationProfiles`. After successful profile loading, throws `configurationError` with "Validation engine not yet connected" instead of "Profile loading not yet integrated".
- **SwiftPDFParser.swift**: Added `import SwiftVerificarParser`. Updated doc comments and error messages to reference `PDFDocumentParser` from the parser package.
- **XMPParser.swift**: Added `import SwiftVerificarParser`. Updated doc comments to reference `SwiftVerificarParser.XMPMetadata` for parser-level XMP handling.
- **PDFProcessor.swift**: Added `import SwiftVerificarValidation` and `import SwiftVerificarValidationProfiles`. Updated stub comments and error messages to reference `ValidationEngine`, `FeatureExtractor`, and `MetadataFixer` from the validation package.
- **Tests updated**: Test expectations updated for new error messages (profile loading now succeeds, "Validation engine not yet connected" replaces "Profile loading not yet integrated"; unknown profile names throw `profileNotFound`; whitespace-only profiles throw `profileNotFound`).

### Wiring Sprint 6: Foundry System & WCAG Integration
- **New file**: `Sources/SwiftVerificarBiblioteca/Adapters/SemanticNodeAdapter.swift` -- A `SemanticNode` adapter bridging biblioteca's `SEGenericObject` to wcag-algs' semantic tree model:
  - `fromSEGenericObject(_:depth:)`: Maps `validationProperties` keys (structureType, Alt, ActualText, Lang, title) to `SemanticType` and `AttributesDictionary`.
  - `buildTree(from:)`: Collects SE* objects from a `ParsedDocument`, converts each to a `SemanticNodeAdapter`, wraps under a `.document` root node. Scans 28 SE type keys.
  - Conforms to `SemanticNode`, `Sendable`, `Hashable` (hashed/equated by `UUID`).
- **New file**: `Sources/SwiftVerificarBiblioteca/Adapters/WCAGResultMapper.swift` -- Maps WCAG algorithm results to biblioteca's `TestAssertion` format:
  - `mapReport(_:recordPassed:)`: Takes `[AccessibilityCheckResult]` (NOT `ValidationReport` to avoid type collision), maps passed checks to single assertions and failed checks to one assertion per violation.
  - `mapHeadingResult(_:recordPassed:)`: Maps `HeadingHierarchyValidationResult` issues to individual assertions with unique test numbers (101-107) under clause "1.3.1".
  - Maps `ViolationSeverity` and `HeadingHierarchyIssue.Severity` to `AssertionStatus`.
  - Stateless enum with static methods, `Sendable`.
  - **Type collision avoidance**: Both wcag-algs and biblioteca define `ValidationReport`. Additionally, `struct SwiftVerificarWCAGAlgs` shadows the module name, preventing module-qualified access. Solution: mapper takes `[AccessibilityCheckResult]` (the `.results` property) rather than the report struct.
- **Modified**: `Sources/SwiftVerificarBiblioteca/Foundry/SwiftFoundry.swift` -- Wired foundry to create real components:
  - `createParser(for:)`: Returns real `SwiftPDFParser` instead of `StubPDFParser`.
  - `createValidator(profile:config:)`: Returns real `SwiftPDFValidator` instead of `StubPDFValidator`. Maps `ValidatorConfiguration` to `ValidatorConfig`.
  - Added `SwiftPDFParser` conformance to `PDFParserProvider` and `SwiftPDFValidator` conformance to `PDFValidatorProvider`.
  - `MetadataFixer` and `FeatureExtractor` remain stubs (future sprints).
- **Modified**: `Sources/SwiftVerificarBiblioteca/Validators/SwiftPDFValidator.swift` -- Added WCAG accessibility integration:
  - Added `import SwiftVerificarWCAGAlgs`.
  - In `validate(_:)`, after rule evaluation, if `flavour.isAccessibilityRelated`, calls `runWCAGChecks(on:recordPassed:)`.
  - `runWCAGChecks(on:recordPassed:)`: Builds `SemanticNodeAdapter` tree, runs `WCAGValidator.levelAA().validate(_:)` for accessibility checks, runs `HeadingHierarchyChecker(options: .basic).validate(_:)` for heading checks. Uses `wcagReport.results` to get `[AccessibilityCheckResult]`, maps via `WCAGResultMapper`.
  - Added `extension SwiftPDFValidator: PDFValidatorProvider {}`.
- **Modified**: `Tests/SwiftVerificarBibliotecaTests/Foundry/SwiftFoundryTests.swift` -- Updated to expect real types:
  - `createParserReturnsConfiguredParser`: Changed expected description from "StubPDFParser" to "SwiftPDFParser".
  - `createValidatorReturnsConfiguredValidator`: Changed expected description from "StubPDFValidator" to "SwiftPDFValidator".
  - `createValidatorPassesConfig`: Changed cast from `StubPDFValidator` to `SwiftPDFValidator`, verifies `.config.maxFailures` and `.config.recordPassedAssertions`.
- Total tests: 1518 (unchanged -- no new tests added, existing tests updated to verify real types).
- **Architecture note**: WCAG integration uses `SemanticNodeAdapter.buildTree(from:)` to construct a shallow semantic tree (root + direct children) from SE* validation objects. This is sufficient for WCAG checks that examine individual element properties (Alt text, heading hierarchy) but not for checks requiring deep tree traversal. The `WCAGResultMapper` avoids the `ValidationReport` type name collision by accepting `[AccessibilityCheckResult]` directly.

## Cross-Package Needs (Final State)
- `SwiftPDFParser` uses `PDFKit` for PDF parsing and `XMPParser` (biblioteca) for XMP metadata extraction. The `SwiftVerificarParser` package's `PDFDocumentParser` is available but not yet used directly -- its `XRefParser` needs `skipWhitespace()` and `parseTrailerDictionary()` fixes before it can reliably parse PDFs. Future versions may migrate from `PDFKit` to `PDFDocumentParser` for deeper COS object access.
- `ParsedDocumentAdapter.objects(ofType:)` returns objects for three layers: `CosDocumentObject` for "CosDocument", `PDPageObject` for "PDPage" (one per page), and `SEGenericObject` for SE* types (one per detected structure element type). Structure element detection uses raw byte scanning heuristics; full per-element enumeration would require `PDFDocumentParser` integration.
- `SwiftPDFValidator` uses `ProfileLoader` (from validation-profiles) to load profiles and `RuleExpressionEvaluator` (from validation-profiles) to evaluate rule test expressions. It does NOT use the full `ValidationEngine` from `SwiftVerificarValidation` -- the "direct evaluation" approach is simpler and produces real results.
- `SwiftVerificar.validate()` delegates to `SwiftPDFValidator` for validation. All public API methods produce real results.
- `PDFProcessor` orchestrates the full pipeline: parsing via `SwiftPDFParser`, validation via `SwiftPDFValidator`, feature extraction via `SwiftFeatureExtractor`, and metadata fixing via `SwiftMetadataFixer`.
