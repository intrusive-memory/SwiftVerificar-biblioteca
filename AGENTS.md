# SwiftVerificarBiblioteca — Agent Instructions

This document teaches AI agents how to **use** the SwiftVerificarBiblioteca library. It covers the module name, public API surface, dependencies, build commands, and current implementation status.

## Module

```swift
import SwiftVerificarBiblioteca
```

## What It Does

SwiftVerificarBiblioteca is the main integration library for the SwiftVerificar ecosystem. It provides a unified async API for PDF/A and PDF/UA validation, feature extraction, metadata fixing, and batch processing. It orchestrates the parser, validation engine, validation profiles, and WCAG algorithms into a single entry point.

**Primary consumer:** [Lazarillo](https://github.com/intrusive-memory/Lazarillo), a PDF accessibility remediation engine for macOS.

## Dependencies

| Dependency | Module | Role |
|------------|--------|------|
| SwiftVerificar-parser | `SwiftVerificarParser` | PDF parsing, structure tree, XMP metadata |
| SwiftVerificar-validation-profiles | `SwiftVerificarValidationProfiles` | XML validation rule definitions for PDF/A and PDF/UA |
| SwiftVerificar-wcag-algs | `SwiftVerificarWCAGAlgs` | WCAG accessibility algorithms |
| SwiftVerificar-validation | `SwiftVerificarValidation` | Validation engine, feature reporting |

## Common Usage

```swift
import SwiftVerificarBiblioteca

// Simple accessibility validation (PDF/UA-2)
let result = try await SwiftVerificar.shared.validateAccessibility(pdfURL)

// Validate against specific profile
let result = try await SwiftVerificar.shared.validate(pdfURL, profile: "PDF/A-2u")

// Full processing pipeline
let processorResult = try await SwiftVerificar.shared.process(pdfURL, config: .all)

// Batch validation
let results = try await SwiftVerificar.shared.validateBatch([url1, url2], profile: "PDF/UA-2")
```

## Key Public Types

### Main API

- **`SwiftVerificar`** — Shared singleton struct. Entry point for all validation operations. Methods: `validateAccessibility()`, `validate()`, `process()`, `validateBatch()`.

### Core Protocols and Types

- **`ValidatorComponent`** — Protocol for all pluggable components in the validation pipeline.
- **`ComponentInfo`** — Metadata about a validator component (name, version, description).
- **`ValidationDuration`** — Timing information for validation runs.
- **`VerificarError`** — Error enum for all library errors (e.g., `.configurationError`, `.parsingError`, `.validationError`).

### Foundry (Component Factory)

- **`ValidationFoundry`** — Protocol defining the component factory interface.
- **`Foundry`** — Actor that manages component registration and creation.
- **`SwiftFoundry`** — Default implementation of `ValidationFoundry`.

### Validation Results

- **`ValidationResult`** — Complete result of a validation run, including assertions, duration, and profile info.
- **`TestAssertion`** — Individual test result within a validation run.
- **`AssertionStatus`** — Enum: `.passed`, `.failed`, `.notApplicable`, etc.
- **`PDFLocation`** — Location within a PDF document (page, object, context).

### Metadata Results

- **`MetadataFixerResult`** — Result of metadata fixing operations.
- **`MetadataFix`** — Individual metadata fix applied.
- **`RepairStatus`** — Enum indicating repair outcome.

### Validators

- **`PDFValidator`** — Protocol for PDF validation implementations.
- **`ValidatorConfig`** — Configuration for validation runs.
- **`SwiftPDFValidator`** — Default validator implementation.
- **`ParsedDocument`** — Protocol representing a parsed PDF document.
- **`ValidationObject`** — Protocol for objects that can be validated.

### Parsers

- **`PDFParser`** — Protocol for PDF parsing implementations.
- **`SwiftPDFParser`** — Default parser implementation.
- **`DocumentMetadata`** — Extracted document metadata.

### Feature Extraction

- **`FeatureType`** — Enum with 19 cases (e.g., `.annotations`, `.fonts`, `.images`, `.metadata`, `.pages`, `.structureTree`).
- **`FeatureNode`** — Indirect enum representing feature tree nodes.
- **`FeatureConfig`** — Configuration for feature extraction.
- **`FeatureExtractionResult`** — Result of feature extraction.
- **`FeatureReporter`** — Collects and reports extracted features.
- **`FeatureData`** — Protocol for types that provide feature data.

### Metadata Fixing

- **`MetadataFixer`** — Protocol for metadata fixing implementations.
- **`FixerConfig`** — Configuration for metadata fixing.

### Processing Pipeline

- **`PDFProcessor`** — Orchestrates multi-step PDF processing.
- **`ProcessorTask`** — Enum of tasks the processor can execute.
- **`OutputFormat`** — Enum of output formats for results.
- **`ProcessorConfig`** — Configuration for the processor.
- **`ProcessorResult`** — Combined result of all processor tasks.

### XMP Metadata

- **`XMPMetadata`** — Parsed XMP metadata container.
- **`XMPParser`** — XMP XML parser.
- **`XMPProperty`** — Individual XMP property.
- **`XMPValidator`** — Validates XMP metadata against standards.
- **`MainXMPPackage`** — Primary XMP package in a PDF.
- **`PDFAIdentification`** — PDF/A conformance identification from XMP.
- **`PDFUAIdentification`** — PDF/UA conformance identification from XMP.
- **`XMPPackage`** — Generic XMP package.
- **`DublinCoreMetadata`** — Dublin Core metadata extracted from XMP.

### Reports

- **`ValidationReport`** — Formatted validation report.
- **`RuleSummary`** — Summary of rule pass/fail counts.
- **`FeatureReport`** — Report of extracted features.
- **`ReportGenerator`** — Generates reports from validation results.

## Current Status

**Version 0.1.0** has all 55+ public types fully wired with real implementations. The validation engine, parser, metadata fixer, and feature extractor are connected to the SwiftVerificar dependency packages and produce real results. The API surface is complete and tested.

## Build and Test

**NEVER use `swift build` or `swift test`.** Always use `xcodebuild`.

```bash
# Build
xcodebuild build -scheme SwiftVerificarBiblioteca -destination 'platform=macOS'

# Test
xcodebuild test -scheme SwiftVerificarBiblioteca -destination 'platform=macOS'
```

## Technical Details

- **Swift version:** 6.0+
- **Concurrency:** All types are `Sendable`. Uses Swift strict concurrency throughout.
- **Testing framework:** Swift Testing (`import Testing`)
- **Test count:** 1609+ tests, including 38 cross-package integration tests and 100+ wiring integration tests
- **Platform requirements:** macOS 14.0+, iOS 17.0+

## Ecosystem

This package is part of the SwiftVerificar package collection:

| Package | Repository |
|---------|-----------|
| SwiftVerificar-biblioteca (this) | [intrusive-memory/SwiftVerificar-biblioteca](https://github.com/intrusive-memory/SwiftVerificar-biblioteca) |
| SwiftVerificar-parser | [intrusive-memory/SwiftVerificar-parser](https://github.com/intrusive-memory/SwiftVerificar-parser) |
| SwiftVerificar-validation | [intrusive-memory/SwiftVerificar-validation](https://github.com/intrusive-memory/SwiftVerificar-validation) |
| SwiftVerificar-validation-profiles | [intrusive-memory/SwiftVerificar-validation-profiles](https://github.com/intrusive-memory/SwiftVerificar-validation-profiles) |
| SwiftVerificar-wcag-algs | [intrusive-memory/SwiftVerificar-wcag-algs](https://github.com/intrusive-memory/SwiftVerificar-wcag-algs) |
