# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-02-07

### Changed
- All 55+ public types are now backed by real implementations (previously stubs)
- PDF parsing uses PDFKit via ParsedDocumentAdapter for reliable document ingestion
- Validation engine fully wired to SwiftVerificar-validation with real rule evaluation
- Feature extraction produces real FeatureNode trees from parsed documents
- Metadata fixer applies real XMP repairs via the processing pipeline
- XMP parser performs real XML parsing of XMP metadata packets
- Foundry and SwiftFoundry create real validator, parser, and fixer components
- PDFProcessor orchestrates the full validate → extract → fix pipeline
- SwiftVerificar main API delegates to real components end-to-end
- Report generation produces real ValidationReport and FeatureReport output

### Added
- WCAG accessibility algorithm integration via SwiftVerificar-wcag-algs
- Cancellation support throughout the async validation pipeline
- CosDocumentObject and objects(ofType:) for PDF object model queries
- PDPageObject and SEGenericObject structure tree wiring
- 1609+ tests (up from ~1400), including integration, end-to-end, and performance tests
- Error handling for edge cases (corrupt PDFs, empty documents, cancelled tasks)

## [0.1.0] - 2026-02-07

### Added
- Initial release of SwiftVerificarBiblioteca
- Main API: SwiftVerificar struct with shared singleton, validateAccessibility(), validate(), process(), validateBatch()
- Core types: ValidatorComponent protocol, ComponentInfo, ValidationDuration, VerificarError
- Foundry system: ValidationFoundry protocol, Foundry actor, SwiftFoundry component factory
- Validation results: ValidationResult, TestAssertion, AssertionStatus, PDFLocation
- Metadata results: MetadataFixerResult, MetadataFix, RepairStatus
- Validators: PDFValidator protocol, ValidatorConfig, SwiftPDFValidator, ParsedDocument protocol
- Parsers: PDFParser protocol, SwiftPDFParser, DocumentMetadata
- Feature extraction: FeatureType enum (19 cases), FeatureNode, FeatureConfig, FeatureExtractionResult, FeatureReporter
- Metadata fixing: MetadataFixer protocol, FixerConfig
- Processing pipeline: PDFProcessor, ProcessorTask, OutputFormat, ProcessorConfig, ProcessorResult
- XMP model: XMPMetadata, XMPParser, XMPProperty, XMPValidator, MainXMPPackage, PDFAIdentification, PDFUAIdentification
- Reports: ValidationReport, RuleSummary, FeatureReport, ReportGenerator
- Cross-package integration: PDFFlavour type agreement, ProfileLoader wiring, 38 integration tests
- 1400 tests with ~95% coverage

[0.2.0]: https://github.com/intrusive-memory/SwiftVerificar-biblioteca/releases/tag/v0.2.0
[0.1.0]: https://github.com/intrusive-memory/SwiftVerificar-biblioteca/releases/tag/v0.1.0
