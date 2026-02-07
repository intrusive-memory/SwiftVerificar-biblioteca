# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/intrusive-memory/SwiftVerificar-biblioteca/releases/tag/v0.1.0
