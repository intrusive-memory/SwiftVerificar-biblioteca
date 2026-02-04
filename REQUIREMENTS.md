# SwiftVerificar-biblioteca Porting Requirements

This document analyzes the veraPDF ecosystem and defines the minimal components needed for native Swift PDF/UA validation in Lazarillo.

## Current State: Lazarillo's veraPDF Integration

Lazarillo currently wraps veraPDF CLI to validate PDFs:

```
Lazarillo → veraPDF CLI → Java Runtime → PDF Validation
```

**Pain Points:**
- Requires Java runtime installation (~150MB+)
- Requires separate veraPDF installation
- External process execution overhead
- Distribution complexity (bundling Java)
- No native Apple Silicon optimization

**Goal:** Replace with native Swift implementation:
```
Lazarillo → SwiftVerificarBiblioteca → PDF Validation
```

## veraPDF Ecosystem Analysis

### Repository Dependencies

```
veraPDF-apps (CLI/GUI)
    └── veraPDF-library (main integration)
            ├── veraPDF-parser (PDF parsing)
            ├── veraPDF-validation (validation engine)
            │       ├── validation-model
            │       ├── feature-reporting
            │       ├── metadata-fixer
            │       └── wcag-validation
            ├── veraPDF-validation-profiles (XML rules)
            └── veraPDF-wcag-algs (accessibility algorithms)
```

### Component Breakdown

| Component | Purpose | Porting Priority |
|-----------|---------|------------------|
| **veraPDF-parser** | PDF structure parsing, object extraction | **Critical** |
| **veraPDF-validation** | Rule execution engine | **Critical** |
| **veraPDF-validation-profiles** | XML-based validation rules | **Critical** (can import directly) |
| **veraPDF-wcag-algs** | Contrast ratio, structure tree validation | **High** for PDF/UA |
| **veraPDF-library** | Integration layer | **Medium** (Swift architecture) |
| **veraPDF-model** | Validation DSL | **Low** (port rules, not DSL) |

## Lazarillo's Required Validation Profiles

Based on `PDFValidator.swift`, Lazarillo needs:

| Profile | Standard | Priority |
|---------|----------|----------|
| `ua2` | PDF/UA-2 (ISO 14289-2:2024) | **Primary** - Lazarillo's main use case |
| `ua1` | PDF/UA-1 (ISO 14289-1) | Secondary |
| `1a`, `1b` | PDF/A-1 (ISO 19005-1) | Optional |
| `2a`, `2b` | PDF/A-2 (ISO 19005-2) | Optional |

**MVP Focus: PDF/UA-2 validation only**

## Minimal Viable Port (MVP) Architecture

### Layer 1: PDF Parsing Foundation

```swift
// Core PDF Object Model
struct PDFDocument
struct PDFObject
struct PDFStream
struct PDFDictionary
struct PDFArray
struct PDFCrossReferenceTable

// Tagged PDF Structures (critical for UA)
struct PDFStructureTree
struct PDFStructureElement
struct PDFTaggedContent
struct PDFRoleMap

// Metadata
struct XMPMetadata
struct PDFDocumentInfo
```

**Options:**
1. **Use PDFKit + Extensions** - Leverage Apple's PDFKit for basic parsing, extend for tagged PDF structures
2. **Pure Swift Parser** - Port veraPDF-parser completely (significant effort)
3. **Hybrid** - PDFKit for rendering/basic ops, custom parser for structure tree

**Recommendation:** Option 3 (Hybrid) - Use PDFKit where possible, implement tagged PDF structure parsing natively.

### Layer 2: Validation Profile Loader

The validation profiles are XML files that can be imported directly:

```swift
struct ValidationProfile: Codable {
    let name: String
    let description: String
    let rules: [ValidationRule]
}

struct ValidationRule: Codable {
    let id: String
    let specification: String
    let clause: String
    let testNumber: Int
    let description: String
    let object: String          // PDF object type to check
    let test: String            // Test expression
    let errorMessage: String
    let errorArguments: [String]?
}
```

**Source:** https://github.com/veraPDF/veraPDF-validation-profiles

### Layer 3: Validation Engine

```swift
protocol ValidationEngine {
    func validate(_ document: PDFDocument, profile: ValidationProfile) async -> ValidationResult
}

actor SwiftPDFValidator: ValidationEngine {
    func validate(_ document: PDFDocument, profile: ValidationProfile) async -> ValidationResult
    func evaluateRule(_ rule: ValidationRule, on object: PDFObject) -> RuleResult
}
```

### Layer 4: WCAG Algorithms

For PDF/UA-2 compliance, specific WCAG checks are needed:

```swift
// Structure Tree Validation
struct StructureTreeValidator {
    func validateHierarchy(_ tree: PDFStructureTree) -> [ValidationIssue]
    func validateRoleMapping(_ tree: PDFStructureTree) -> [ValidationIssue]
    func validateReadingOrder(_ tree: PDFStructureTree) -> [ValidationIssue]
}

// Contrast Ratio Calculator
struct ContrastChecker {
    func calculateContrastRatio(foreground: Color, background: Color) -> Double
    func meetsWCAGAAA(ratio: Double, isLargeText: Bool) -> Bool
    func meetsWCAGAA(ratio: Double, isLargeText: Bool) -> Bool
}

// Alt Text Validation
struct AltTextValidator {
    func validateImageAltText(_ element: PDFStructureElement) -> ValidationIssue?
    func validateFigureDescription(_ element: PDFStructureElement) -> ValidationIssue?
}
```

## Implementation Phases

### Phase 1: Foundation (MVP)
- [ ] PDF document loading via PDFKit
- [ ] Tagged PDF structure tree parsing
- [ ] XMP metadata extraction
- [ ] Basic validation result model (matching Lazarillo's `ValidationResult`)

### Phase 2: Profile System
- [ ] XML validation profile parser
- [ ] Import PDF/UA-2 validation profiles from veraPDF
- [ ] Rule expression evaluator

### Phase 3: Core Validation
- [ ] Structure tree validation rules
- [ ] Document metadata validation
- [ ] Tagged content validation
- [ ] Reading order validation

### Phase 4: WCAG Algorithms
- [ ] Contrast ratio calculation
- [ ] Text accessibility checks
- [ ] Table structure validation
- [ ] List structure validation

### Phase 5: Integration
- [ ] Drop-in replacement for Lazarillo's `PDFValidator`
- [ ] Async/await API matching current interface
- [ ] Performance optimization

## API Design (Lazarillo Integration)

The Swift port should provide an API compatible with Lazarillo's current usage:

```swift
// Current Lazarillo usage:
let validator = PDFValidator()
let result = try await validator.validate(pdfURL: url, profile: .pdfUA2)

// SwiftVerificarBiblioteca replacement:
import SwiftVerificarBiblioteca

let validator = SwiftPDFValidator()
let result = try await validator.validate(pdfURL: url, profile: .pdfUA2)
// Returns same ValidationResult structure
```

## External Resources

### veraPDF Source Code
- Parser: https://github.com/veraPDF/veraPDF-parser
- Validation: https://github.com/veraPDF/veraPDF-validation
- Profiles: https://github.com/veraPDF/veraPDF-validation-profiles
- WCAG: https://github.com/veraPDF/veraPDF-wcag-algs

### Standards Documentation
- PDF/UA-2: ISO 14289-2:2024
- PDF/UA-1: ISO 14289-1:2014
- PDF 2.0: ISO 32000-2:2020
- WCAG 2.1: https://www.w3.org/TR/WCAG21/
- Tagged PDF: ISO 32000-1 Section 14.8

### Apple Frameworks
- PDFKit: https://developer.apple.com/documentation/pdfkit
- Core Graphics PDF: https://developer.apple.com/documentation/coregraphics/cgpdfdocument

## Estimated Complexity

| Component | Effort | Notes |
|-----------|--------|-------|
| PDF Structure Parsing | High | Tagged PDF is complex |
| Validation Profiles | Medium | XML parsing straightforward |
| Rule Engine | High | Expression evaluation |
| WCAG Algorithms | Medium | Well-documented algorithms |
| Integration | Low | API already defined |

**Total Estimate:** Significant project, recommend iterative delivery starting with MVP.

## Success Criteria

1. **Functional Parity:** Produce same validation results as veraPDF for PDF/UA-2
2. **No External Dependencies:** No Java, no CLI subprocess
3. **Performance:** Equal or better than veraPDF CLI invocation
4. **API Compatibility:** Drop-in replacement for Lazarillo's PDFValidator
5. **Apple Silicon Optimized:** Native ARM64 binary
