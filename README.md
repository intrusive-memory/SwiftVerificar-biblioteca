# SwiftVerificar-biblioteca

Main integration library for the SwiftVerificar ecosystem. Provides a unified, async Swift API for PDF/A and PDF/UA validation, designed as the primary entry point for applications needing PDF accessibility and compliance checking. Orchestrates the parser, validation engine, validation profiles, and WCAG algorithms into a simple, Sendable-safe interface.

**Primary consumer:** [Lazarillo](https://github.com/intrusive-memory/Lazarillo), a PDF accessibility remediation engine for macOS.

## Overview

SwiftVerificar-biblioteca is a native Swift implementation of the [veraPDF-library](https://github.com/veraPDF/veraPDF-library), providing PDF/A and PDF/UA validation capabilities for macOS and iOS applications. This project brings the industry-standard PDF validation functionality of veraPDF to the Apple ecosystem, eliminating the Java runtime dependency.

## SwiftVerificar Ecosystem

| Package | Ports | Description |
|---------|-------|-------------|
| **[SwiftVerificar-biblioteca](https://github.com/intrusive-memory/SwiftVerificar-biblioteca)** (this) | [veraPDF-library](https://github.com/veraPDF/veraPDF-library) | Main integration library, unified API |
| **[SwiftVerificar-parser](https://github.com/intrusive-memory/SwiftVerificar-parser)** | [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser) | PDF parsing, structure tree, XMP metadata |
| **[SwiftVerificar-validation](https://github.com/intrusive-memory/SwiftVerificar-validation)** | [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation) | Validation engine, feature reporting |
| **[SwiftVerificar-validation-profiles](https://github.com/intrusive-memory/SwiftVerificar-validation-profiles)** | [veraPDF-validation-profiles](https://github.com/veraPDF/veraPDF-validation-profiles) | XML validation rules for PDF/A and PDF/UA |
| **[SwiftVerificar-wcag-algs](https://github.com/intrusive-memory/SwiftVerificar-wcag-algs)** | [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs) | WCAG accessibility algorithms |

## Requirements

- Swift 6.0+
- macOS 14.0+ / iOS 17.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/intrusive-memory/SwiftVerificar-biblioteca.git", from: "0.2.0")
]
```

Then add `SwiftVerificarBiblioteca` to your target dependencies.

## Usage

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

## Porting Process

This library was ported from its Java source using a structured, AI-assisted methodology. The original veraPDF Java codebase was analyzed to extract type hierarchies, public APIs, and behavioral contracts. An execution plan decomposed the port into sequential sprints, each targeting a cohesive set of types with explicit entry/exit criteria (build must pass, all tests must pass, 90%+ coverage). AI coding agents (Claude) executed each sprint autonomously — translating Java patterns to idiomatic Swift (enums for sealed hierarchies, structs for value types, actors for thread-safe singletons, async/await for concurrency), writing Swift Testing framework tests, and verifying builds with xcodebuild. A supervisor process coordinated sprint sequencing, tracked cross-package dependencies, and performed reconciliation passes to ensure type agreement across the five-package ecosystem. The result is a clean-room Swift implementation that preserves the original's validation semantics while embracing Swift 6 strict concurrency, value semantics, and protocol-oriented design.

**Stats:** 55+ public types, 1609+ tests (including 38 cross-package integration tests and 100+ end-to-end tests).

## Development

This project follows a standard development workflow:

1. All development happens on the `development` branch
2. Features and fixes are merged to `development` via pull requests
3. Releases are merged from `development` to `main` after passing all tests
4. The `main` branch is protected and requires passing CI checks

### Building

```bash
xcodebuild build -scheme SwiftVerificarBiblioteca -destination 'platform=macOS'
```

### Testing

```bash
xcodebuild test -scheme SwiftVerificarBiblioteca -destination 'platform=macOS'
```

**NEVER use `swift build` or `swift test`.**

## AI Agent Instructions

This project includes configuration files for AI coding assistants:
- See [AGENTS.md](AGENTS.md) for general agent guidelines and full API reference
- See [CLAUDE.md](CLAUDE.md) for Claude-specific instructions
- See [GEMINI.md](GEMINI.md) for Gemini-specific instructions

## License

This project is licensed under the same terms as the original veraPDF-library. See the LICENSE file for details.

## Acknowledgments

- The [veraPDF Consortium](https://verapdf.org) for the original Java implementation
- The PDF Association for PDF/A standards documentation
