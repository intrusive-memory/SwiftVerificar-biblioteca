# SwiftVerificar-biblioteca

A direct Swift port of [veraPDF-library](https://github.com/veraPDF/veraPDF-library).

## Overview

SwiftVerificar-biblioteca is a native Swift implementation of the veraPDF validation library, providing PDF/A and PDF/UA validation capabilities for macOS and iOS applications. This project aims to bring the industry-standard PDF validation functionality of veraPDF to the Apple ecosystem, eliminating the Java runtime dependency.

**Primary Goal:** Provide native PDF/UA-2 validation for [Lazarillo](https://github.com/intrusive-memory/Lazarillo), a PDF accessibility remediation engine for macOS.

## Source Reference

This project ports components from the veraPDF ecosystem:
- **veraPDF-library**: [https://github.com/veraPDF/veraPDF-library](https://github.com/veraPDF/veraPDF-library)
- **veraPDF-parser**: [https://github.com/veraPDF/veraPDF-parser](https://github.com/veraPDF/veraPDF-parser)
- **veraPDF-validation**: [https://github.com/veraPDF/veraPDF-validation](https://github.com/veraPDF/veraPDF-validation)
- **veraPDF-validation-profiles**: [https://github.com/veraPDF/veraPDF-validation-profiles](https://github.com/veraPDF/veraPDF-validation-profiles)
- **veraPDF-wcag-algs**: [https://github.com/veraPDF/veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs)
- **veraPDF Website**: [https://verapdf.org](https://verapdf.org)

## Project Documentation

- **[REQUIREMENTS.md](REQUIREMENTS.md)** - Detailed porting analysis, architecture decisions, and implementation phases
- **[AGENTS.md](AGENTS.md)** - Development guidelines and implementation roadmap

## Requirements

- Swift 6.0+
- macOS 14.0+ / iOS 17.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/intrusive-memory/SwiftVerificar-biblioteca.git", from: "0.1.0")
]
```

Then add `SwiftVerificarBiblioteca` to your target dependencies.

## Usage

```swift
import SwiftVerificarBiblioteca

let validator = SwiftVerificarBiblioteca()
// PDF/A validation functionality coming soon
```

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

## AI Agent Instructions

This project includes configuration files for AI coding assistants:
- See [AGENTS.md](AGENTS.md) for general agent guidelines
- See [CLAUDE.md](CLAUDE.md) for Claude-specific instructions
- See [GEMINI.md](GEMINI.md) for Gemini-specific instructions

## License

This project is licensed under the same terms as the original veraPDF-library. See the LICENSE file for details.

## Acknowledgments

- The [veraPDF Consortium](https://verapdf.org) for the original Java implementation
- The PDF Association for PDF/A standards documentation
