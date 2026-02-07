# SwiftVerificar-biblioteca Progress

## Current State
- Last completed sprint: Wiring Sprint 3
- Build status: passing
- Total test count: 1455
- Cumulative coverage: ~95%
- **Wiring phase in progress**

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

## Cross-Package Needs
- `SwiftPDFParser` now uses `PDFKit` for PDF parsing and `XMPParser` (biblioteca) for XMP metadata extraction. The `SwiftVerificarParser` package's `PDFDocumentParser` is not yet used directly -- its `XRefParser` needs `skipWhitespace()` and `parseTrailerDictionary()` fixes before it can reliably parse PDFs. Future wiring sprint will migrate from `PDFKit` to `PDFDocumentParser` for deeper COS object access.
- `ParsedDocumentAdapter.objects(ofType:)` now returns a `CosDocumentObject` for the "CosDocument" type. Page-level and structure-element-level objects are not yet populated -- Sprint 4 will implement full object enumeration by `PDFObjectType`.
- The `SwiftVerificar.validate()` method successfully loads profiles via `ProfileLoader` from `SwiftVerificarValidationProfiles`, but the validation pipeline is not yet connected to `PDFValidationEngine` from `SwiftVerificarValidation`. The `PDFProcessor` stubs reference `ValidationEngine`, `FeatureExtractor`, and `MetadataFixer` but do not yet instantiate or call them.
