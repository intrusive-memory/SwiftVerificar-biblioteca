# AI Agent Guidelines for SwiftVerificar-biblioteca

This document provides guidelines for AI coding assistants working on this project.

## Project Overview

SwiftVerificar-biblioteca is a direct Swift port of [veraPDF-library](https://github.com/veraPDF/veraPDF-library). The goal is to provide native PDF/A and PDF/UA validation capabilities for the Apple ecosystem, eliminating the Java runtime dependency.

**Primary Consumer:** [Lazarillo](https://github.com/intrusive-memory/Lazarillo) - PDF accessibility remediation engine for macOS.

See [REQUIREMENTS.md](REQUIREMENTS.md) for detailed porting analysis and architecture decisions.

## Agent-Specific Instructions

- **Claude**: See [CLAUDE.md](CLAUDE.md) for Claude-specific instructions
- **Gemini**: See [GEMINI.md](GEMINI.md) for Gemini-specific instructions

## General Guidelines

### Code Style

- Follow Swift API Design Guidelines
- Use Swift 6.0+ features including strict concurrency
- Prefer value types (structs, enums) over reference types where appropriate
- Use async/await for asynchronous operations
- Mark types as `Sendable` for concurrency safety

### Architecture

When porting from the Java veraPDF ecosystem:

1. **Study the original**: Understand the Java implementation across:
   - https://github.com/veraPDF/veraPDF-parser
   - https://github.com/veraPDF/veraPDF-validation
   - https://github.com/veraPDF/veraPDF-validation-profiles
   - https://github.com/veraPDF/veraPDF-wcag-algs

2. **Swift idioms**: Convert Java patterns to Swift idioms:
   - Java interfaces → Swift protocols
   - Java abstract classes → Swift protocols with default implementations
   - Java static factories → Swift static methods or initializers
   - Java streams → Swift sequences and higher-order functions

3. **Memory safety**: Leverage Swift's memory safety features
4. **Concurrency**: Use Swift's structured concurrency model (actors for validators)

### Build System

- **NEVER use `swift build` or `swift test`** - always use `xcodebuild`
- Use XcodeBuildMCP tools when available
- All CI/CD uses GitHub Actions with `macos-26` runners

### Testing

- Write tests using Swift Testing framework (`import Testing`)
- Ensure all tests pass before submitting pull requests
- Target test coverage for critical validation logic
- Use reference PDFs from veraPDF test corpus when available

### Branch Workflow

1. Create feature branches from `development`
2. Submit pull requests to `development`
3. `development` merges to `main` only after CI passes
4. `main` branch is protected and represents stable releases

## Implementation Roadmap

### Phase 1: Foundation (MVP) - PDF/UA-2 Focus

| Task | Status | Notes |
|------|--------|-------|
| PDF document loading via PDFKit | Pending | Basic document access |
| Tagged PDF structure tree parsing | Pending | Critical for UA validation |
| XMP metadata extraction | Pending | Document properties |
| Validation result model | Pending | Match Lazarillo's `ValidationResult` |

### Phase 2: Profile System

| Task | Status | Notes |
|------|--------|-------|
| XML validation profile parser | Pending | Import veraPDF profiles |
| PDF/UA-2 profile import | Pending | Primary target |
| Rule expression evaluator | Pending | Execute validation tests |

### Phase 3: Core Validation Engine

| Task | Status | Notes |
|------|--------|-------|
| Structure tree validation | Pending | Hierarchy, roles, reading order |
| Document metadata validation | Pending | Required fields, language |
| Tagged content validation | Pending | Alt text, figure descriptions |
| Table structure validation | Pending | Header cells, scope |

### Phase 4: WCAG Algorithms

| Task | Status | Notes |
|------|--------|-------|
| Contrast ratio calculation | Pending | WCAG 2.1 AA/AAA |
| Text accessibility checks | Pending | Font embedding, encoding |
| List structure validation | Pending | Proper nesting |
| Link validation | Pending | Destination, alt text |

### Phase 5: Extended Profiles (Post-MVP)

| Task | Status | Notes |
|------|--------|-------|
| PDF/UA-1 profile | Pending | Legacy support |
| PDF/A-1a profile | Pending | Archive + accessibility |
| PDF/A-1b profile | Pending | Archive basic |
| PDF/A-2a/2b profiles | Pending | Extended archive |
| PDF/A-3a/3b profiles | Pending | Embedded files |

## Key Types to Implement

```swift
// Core Document Model
struct PDFDocument
struct PDFStructureTree
struct PDFStructureElement
struct XMPMetadata

// Validation System
protocol ValidationProfile
protocol ValidationRule
actor SwiftPDFValidator

// Results (match Lazarillo interface)
struct ValidationResult
struct ValidationTestResult
enum ValidationStatus
```

## API Compatibility Target

Must provide drop-in replacement for Lazarillo's current interface:

```swift
// Lazarillo's expected interface
let validator = SwiftPDFValidator()
let result = try await validator.validate(pdfURL: url, profile: .pdfUA2)
```

## Reference Materials

### veraPDF Source Repositories
- [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser) - PDF parsing
- [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation) - Validation engine
- [veraPDF-validation-profiles](https://github.com/veraPDF/veraPDF-validation-profiles) - XML rule definitions
- [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs) - Accessibility algorithms

### Standards
- [PDF/UA-2 (ISO 14289-2:2024)](https://www.pdfa.org/resource/iso-14289-pdfua/)
- [PDF 2.0 (ISO 32000-2:2020)](https://www.pdfa.org/resource/iso-32000-2/)
- [WCAG 2.1](https://www.w3.org/TR/WCAG21/)
- [Tagged PDF Reference](https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf) (Section 14.8)

### Apple Frameworks
- [PDFKit](https://developer.apple.com/documentation/pdfkit)
- [Core Graphics PDF](https://developer.apple.com/documentation/coregraphics/cgpdfdocument)

### Swift Guidelines
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
