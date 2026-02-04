# SwiftVerificar-biblioteca — Agent Instructions

Swift port of [veraPDF-library](https://github.com/veraPDF/veraPDF-library).

See the parent [SwiftVerificar/AGENTS.md](../AGENTS.md) for ecosystem overview, implementation roadmap, and general guidelines.

## Purpose

This is the main integration library that ties together the other SwiftVerificar components to provide a unified PDF/A and PDF/UA validation API.

## Source Reference

- **Original**: [veraPDF-library](https://github.com/veraPDF/veraPDF-library)
- **Language**: Java → Swift
- **License**: GPLv3+ / MPLv2+

## Dependencies

This package depends on other SwiftVerificar packages:

- `SwiftVerificar-parser` — PDF parsing and structure tree
- `SwiftVerificar-validation` — Rule execution engine
- `SwiftVerificar-validation-profiles` — Validation rule definitions
- `SwiftVerificar-wcag-algs` — WCAG accessibility algorithms

## Key Responsibilities

- Unified validation API for Lazarillo
- Coordinating parser, validation engine, and profiles
- Providing `ValidationResult` compatible with Lazarillo's existing interface

## API Target

```swift
import SwiftVerificarBiblioteca

let validator = SwiftPDFValidator()
let result = try await validator.validate(pdfURL: url, profile: .pdfUA2)
```
