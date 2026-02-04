# AI Agent Guidelines for SwiftVerificar-biblioteca

This document provides guidelines for AI coding assistants working on this project.

## Project Overview

SwiftVerificar-biblioteca is a direct Swift port of [veraPDF-library](https://github.com/veraPDF/veraPDF-library). The goal is to provide native PDF/A validation capabilities for the Apple ecosystem.

## Agent-Specific Instructions

- **Claude**: See [CLAUDE.md](CLAUDE.md) for Claude-specific instructions
- **Gemini**: See [GEMINI.md](GEMINI.md) for Gemini-specific instructions

## General Guidelines

### Code Style

- Follow Swift API Design Guidelines
- Use Swift 6.0+ features including strict concurrency
- Prefer value types (structs, enums) over reference types where appropriate
- Use async/await for asynchronous operations

### Architecture

When porting from the Java veraPDF-library:

1. **Study the original**: Understand the Java implementation at https://github.com/veraPDF/veraPDF-library
2. **Swift idioms**: Convert Java patterns to Swift idioms (e.g., Java interfaces → Swift protocols)
3. **Memory safety**: Leverage Swift's memory safety features
4. **Concurrency**: Use Swift's structured concurrency model

### Build System

- **NEVER use `swift build` or `swift test`** - always use `xcodebuild`
- Use XcodeBuildMCP tools when available
- All CI/CD uses GitHub Actions with `macos-26` runners

### Testing

- Write tests using Swift Testing framework (`import Testing`)
- Ensure all tests pass before submitting pull requests
- Target test coverage for critical validation logic

### Branch Workflow

1. Create feature branches from `development`
2. Submit pull requests to `development`
3. `development` merges to `main` only after CI passes
4. `main` branch is protected and represents stable releases

## TODO / Future Work

The following tasks are planned for this project:

- [ ] Port core PDF parsing infrastructure
- [ ] Implement PDF/A-1 validation profiles
- [ ] Implement PDF/A-2 validation profiles
- [ ] Implement PDF/A-3 validation profiles
- [ ] Add PDF/A-4 support
- [ ] Create comprehensive test suite with reference PDFs
- [ ] Add documentation and API reference
- [ ] Performance benchmarking against Java implementation

## Reference Materials

- [veraPDF-library source](https://github.com/veraPDF/veraPDF-library)
- [veraPDF validation profiles](https://github.com/veraPDF/veraPDF-validation-profiles)
- [PDF/A specifications](https://www.pdfa.org/resource/pdfa-specification/)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
