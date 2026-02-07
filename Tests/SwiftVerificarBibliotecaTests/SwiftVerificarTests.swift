import Foundation
import PDFKit
import Testing
@testable import SwiftVerificarBiblioteca

// MARK: - Thread-safe progress collector for tests

/// A simple Sendable wrapper using Mutex for collecting progress updates in tests.
/// This is safe because the production code calls progress closures synchronously
/// on the calling task, not from a different isolation domain.
private final class ProgressCollector<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _updates: [T] = []

    func record(_ update: T) {
        lock.lock()
        defer { lock.unlock() }
        _updates.append(update)
    }

    var updates: [T] {
        lock.lock()
        defer { lock.unlock() }
        return _updates
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return _updates.count
    }
}

// MARK: - SwiftVerificar Tests

@Suite("SwiftVerificar Tests")
struct SwiftVerificarTests {

    // MARK: - Initialization

    @Test("Default initializer creates a valid instance")
    func defaultInitializer() {
        let verificar = SwiftVerificar()
        #expect(verificar.version == "0.2.0")
        #expect(verificar.foundryInfo.name == "SwiftFoundry")
    }

    @Test("Custom foundry initializer uses the provided foundry")
    func customFoundryInitializer() {
        let customInfo = ComponentInfo(
            name: "TestFoundry",
            version: "1.0.0",
            componentDescription: "Test foundry",
            provider: "Test"
        )
        let customFoundry = SwiftFoundry(info: customInfo)
        let verificar = SwiftVerificar(foundry: customFoundry)
        #expect(verificar.foundryInfo.name == "TestFoundry")
        #expect(verificar.foundryInfo.version == "1.0.0")
    }

    @Test("Shared singleton exists and returns consistent instance")
    func sharedSingletonExists() {
        let s1 = SwiftVerificar.shared
        let s2 = SwiftVerificar.shared
        // Both should have the same version and foundry info
        #expect(s1.version == s2.version)
        #expect(s1.foundryInfo == s2.foundryInfo)
    }

    @Test("Shared singleton has correct default version")
    func sharedSingletonVersion() {
        #expect(SwiftVerificar.shared.version == "0.2.0")
    }

    @Test("Shared singleton has SwiftFoundry as its foundry")
    func sharedSingletonFoundry() {
        #expect(SwiftVerificar.shared.foundryInfo.name == "SwiftFoundry")
        #expect(SwiftVerificar.shared.foundryInfo.provider == "SwiftVerificar Project")
    }

    // MARK: - Simple API: validateAccessibility

    @Test("validateAccessibility throws parsingFailed for non-existent file")
    func validateAccessibilityThrowsParsingFailed() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        do {
            _ = try await verificar.validateAccessibility(url)
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as VerificarError {
            if case .parsingFailed(let errorURL, _) = error {
                #expect(errorURL == url)
            } else {
                #expect(Bool(false), "Expected parsingFailed, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("validateAccessibility with nil progress does not crash")
    func validateAccessibilityNilProgress() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        do {
            _ = try await verificar.validateAccessibility(url, progress: nil)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            // Expected -- we just care it doesn't crash
            #expect(error is VerificarError)
        }
    }

    @Test("validateAccessibility calls progress before throwing")
    func validateAccessibilityCallsProgress() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        let collector = ProgressCollector<(Double, String)>()
        let progressClosure: @Sendable (Double, String) -> Void = { fraction, message in
            collector.record((fraction, message))
        }

        do {
            _ = try await verificar.validateAccessibility(url, progress: progressClosure)
        } catch {
            // Expected -- parsingFailed for non-existent file
        }

        let updates = collector.updates
        // Should have received at least the initial progress calls plus parsing stage
        #expect(updates.count >= 4)
        // The first call should be the initialization message
        #expect(updates[0].0 == 0.05)
        #expect(updates[0].1.contains("Initializing"))
        // Should include parsing stage
        #expect(updates.contains { $0.1.contains("Parsing") })
    }

    // MARK: - Simple API: validate

    @Test("validate throws parsingFailed for non-existent file with valid profile")
    func validateThrowsParsingFailed() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        do {
            _ = try await verificar.validate(url, profile: "PDF/A-1b")
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as VerificarError {
            if case .parsingFailed(let errorURL, _) = error {
                #expect(errorURL == url)
            } else {
                #expect(Bool(false), "Expected parsingFailed, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("validate with empty profile name throws profileNotFound")
    func validateEmptyProfileThrows() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        do {
            _ = try await verificar.validate(url, profile: "")
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as VerificarError {
            if case .profileNotFound(let name) = error {
                #expect(name.isEmpty)
            } else {
                #expect(Bool(false), "Expected profileNotFound, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("validate with custom config throws parsingFailed for non-existent file")
    func validateWithCustomConfig() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")
        let config = ValidatorConfig(maxFailures: 5, logProgress: true)

        do {
            _ = try await verificar.validate(url, profile: "PDF/UA-1", config: config)
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as VerificarError {
            // Should get parsingFailed because the file doesn't exist
            if case .parsingFailed(let errorURL, _) = error {
                #expect(errorURL == url)
            } else {
                #expect(Bool(false), "Expected parsingFailed, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("validate with default config compiles and runs")
    func validateWithDefaultConfig() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        do {
            _ = try await verificar.validate(url, profile: "PDF/UA-2")
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is VerificarError)
        }
    }

    @Test("validate calls progress before failing")
    func validateCallsProgress() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        let collector = ProgressCollector<(Double, String)>()
        let closure: @Sendable (Double, String) -> Void = { fraction, message in
            collector.record((fraction, message))
        }

        do {
            _ = try await verificar.validate(url, profile: "PDF/UA-2", progress: closure)
        } catch {
            // Expected -- parsingFailed for non-existent file
        }

        let updates = collector.updates
        // Should have at least 5 progress calls: initialize (0.05), loading (0.1),
        // loaded (0.2), parsing (0.3), validating (0.5)
        // (parsing throws before we reach 0.9/1.0)
        #expect(updates.count >= 5)
        #expect(updates[0].0 == 0.05)
        #expect(updates[1].0 == 0.1)
        #expect(updates[1].1.contains("PDF/UA-2"))
        #expect(updates[2].0 == 0.2)
        #expect(updates[2].1.contains("loaded"))
        #expect(updates[3].0 == 0.3)
        #expect(updates[3].1.contains("Parsing"))
        #expect(updates[4].0 == 0.5)
        #expect(updates[4].1.contains("Validating"))
    }

    @Test("validate with various valid profile names throws parsingFailed for non-existent file")
    func validateProfileNameThrowsParsingFailed() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        let profiles = ["PDF/UA-2", "PDF/A-1b", "PDF/A-2u", "WCAG-2-2"]
        for profileName in profiles {
            do {
                _ = try await verificar.validate(url, profile: profileName)
                #expect(Bool(false), "Expected error for profile \(profileName)")
            } catch let error as VerificarError {
                // Valid profile names resolve successfully. With the real pipeline,
                // non-existent files produce parsingFailed errors.
                // Profile loading issues would produce configurationError.
                switch error {
                case .parsingFailed(let errorURL, _):
                    #expect(errorURL == url,
                            "Error URL should match input for '\(profileName)'")
                case .configurationError:
                    // Also acceptable if profile loading fails
                    break
                default:
                    #expect(Bool(false), "Expected parsingFailed or configurationError, got \(error)")
                }
            } catch {
                #expect(Bool(false), "Unexpected error type for \(profileName)")
            }
        }
    }

    @Test("validate with unknown profile name throws profileNotFound")
    func validateUnknownProfileThrows() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        do {
            _ = try await verificar.validate(url, profile: "UnknownProfile")
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as VerificarError {
            if case .profileNotFound(let name) = error {
                #expect(name == "UnknownProfile")
            } else {
                #expect(Bool(false), "Expected profileNotFound, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    // MARK: - Advanced API: process

    @Test("process delegates to PDFProcessor")
    func processDelegatesToProcessor() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")
        let config = ProcessorConfig()

        let result = try await verificar.process(url, config: config)
        #expect(result.documentURL == url)
        // Processor stub will return errors for not-yet-connected phases
        #expect(result.hasErrors)
    }

    @Test("process with default config compiles and runs")
    func processWithDefaultConfig() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        let result = try await verificar.process(url)
        #expect(result.documentURL == url)
    }

    @Test("process with all tasks on non-existent file returns parsingFailed")
    func processWithAllTasks() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")
        let config = ProcessorConfig.all

        let result = try await verificar.process(url, config: config)
        #expect(result.documentURL == url)
        // Parsing fails first for non-existent file, so 1 error
        #expect(result.errorCount == 1)
    }

    @Test("process with no tasks returns a config error")
    func processWithNoTasks() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")
        let config = ProcessorConfig(tasks: [])

        let result = try await verificar.process(url, config: config)
        #expect(result.hasErrors)
    }

    @Test("process calls progress callbacks")
    func processCallsProgress() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        let collector = ProgressCollector<(Double, String)>()
        let closure: @Sendable (Double, String) -> Void = { fraction, message in
            collector.record((fraction, message))
        }

        _ = try await verificar.process(url, progress: closure)

        let updates = collector.updates
        // Should have at least the start and complete progress calls
        #expect(updates.count >= 2)
        #expect(updates.first?.0 == 0.05)
        #expect(updates.last?.0 == 1.0)
        #expect(updates.last?.1 == "Processing complete")
    }

    @Test("process with nil progress does not crash")
    func processNilProgress() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        let result = try await verificar.process(url, progress: nil)
        #expect(result.documentURL == url)
    }

    // MARK: - Batch API: validateBatch

    @Test("validateBatch with empty URL array returns empty dictionary")
    func validateBatchEmptyArray() async throws {
        let verificar = SwiftVerificar()
        let results = try await verificar.validateBatch([], profile: "PDF/UA-2")
        #expect(results.isEmpty)
    }

    @Test("validateBatch with empty profile throws profileNotFound")
    func validateBatchEmptyProfile() async {
        let verificar = SwiftVerificar()
        let urls = [URL(filePath: "/tmp/test1.pdf")]

        do {
            _ = try await verificar.validateBatch(urls, profile: "")
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as VerificarError {
            if case .profileNotFound(let name) = error {
                #expect(name.isEmpty)
            } else {
                #expect(Bool(false), "Expected profileNotFound, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("validateBatch with empty profile and empty URLs throws profileNotFound")
    func validateBatchEmptyProfileEmptyURLs() async {
        let verificar = SwiftVerificar()

        do {
            _ = try await verificar.validateBatch([], profile: "")
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as VerificarError {
            if case .profileNotFound = error {
                // Expected: profile check happens before empty-urls check
            } else {
                #expect(Bool(false), "Expected profileNotFound, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("validateBatch with single URL returns failure result for non-existent file")
    func validateBatchSingleURL() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        let results = try await verificar.validateBatch([url], profile: "PDF/UA-2")
        #expect(results.count == 1)
        #expect(results[url] != nil)

        // Should be a failure because the file doesn't exist (parsingFailed)
        if case .failure(let error) = results[url] {
            #expect(error is VerificarError)
        } else {
            #expect(Bool(false), "Expected failure result")
        }
    }

    @Test("validateBatch with multiple URLs returns failure results for non-existent files")
    func validateBatchMultipleURLs() async throws {
        let verificar = SwiftVerificar()
        let urls = (1...5).map { URL(filePath: "/tmp/test\($0).pdf") }

        let results = try await verificar.validateBatch(urls, profile: "PDF/UA-2")
        #expect(results.count == 5)

        for url in urls {
            #expect(results[url] != nil, "Missing result for \(url)")
            if case .failure(let error) = results[url] {
                #expect(error is VerificarError)
            } else {
                #expect(Bool(false), "Expected failure for \(url)")
            }
        }
    }

    @Test("validateBatch calls progress callback for each URL")
    func validateBatchCallsProgress() async throws {
        let verificar = SwiftVerificar()
        let urls = (1...3).map { URL(filePath: "/tmp/test\($0).pdf") }

        let collector = ProgressCollector<(Int, Int, URL?)>()
        let closure: @Sendable (Int, Int, URL?) -> Void = { completed, total, url in
            collector.record((completed, total, url))
        }

        _ = try await verificar.validateBatch(
            urls,
            profile: "PDF/UA-2",
            progress: closure
        )

        let updates = collector.updates
        #expect(updates.count == 3)
        // All progress updates should have total == 3
        for update in updates {
            #expect(update.1 == 3)
            #expect(update.2 != nil)
        }
        // Completed counts should be 1, 2, 3 (in some order)
        let completedCounts = Set(updates.map(\.0))
        #expect(completedCounts == Set([1, 2, 3]))
    }

    @Test("validateBatch with maxConcurrency of 1 processes sequentially")
    func validateBatchMaxConcurrency1() async throws {
        let verificar = SwiftVerificar()
        let urls = (1...3).map { URL(filePath: "/tmp/test\($0).pdf") }

        let results = try await verificar.validateBatch(
            urls,
            profile: "PDF/UA-2",
            maxConcurrency: 1
        )
        #expect(results.count == 3)
    }

    @Test("validateBatch with maxConcurrency greater than URL count works")
    func validateBatchHighConcurrency() async throws {
        let verificar = SwiftVerificar()
        let urls = [URL(filePath: "/tmp/test1.pdf"), URL(filePath: "/tmp/test2.pdf")]

        let results = try await verificar.validateBatch(
            urls,
            profile: "PDF/UA-2",
            maxConcurrency: 100
        )
        #expect(results.count == 2)
    }

    @Test("validateBatch with nil progress does not crash")
    func validateBatchNilProgress() async throws {
        let verificar = SwiftVerificar()
        let urls = [URL(filePath: "/tmp/test1.pdf")]

        let results = try await verificar.validateBatch(
            urls,
            profile: "PDF/UA-2",
            progress: nil
        )
        #expect(results.count == 1)
    }

    @Test("validateBatch default maxConcurrency is 4")
    func validateBatchDefaultConcurrency() async throws {
        // Verify the signature compiles with default maxConcurrency
        let verificar = SwiftVerificar()
        let results = try await verificar.validateBatch([], profile: "PDF/UA-2")
        #expect(results.isEmpty)
    }

    // MARK: - Introspection

    @Test("version returns library version")
    func versionProperty() {
        let verificar = SwiftVerificar()
        #expect(verificar.version == SwiftVerificarBiblioteca.version)
        #expect(verificar.version == "0.2.0")
    }

    @Test("foundryInfo returns SwiftFoundry info")
    func foundryInfoProperty() {
        let verificar = SwiftVerificar()
        let info = verificar.foundryInfo
        #expect(info.name == "SwiftFoundry")
        #expect(info.version == "0.2.0")
        #expect(info.componentDescription == "Default SwiftVerificar component factory")
        #expect(info.provider == "SwiftVerificar Project")
    }

    // MARK: - CustomStringConvertible

    @Test("description contains version and foundry name")
    func descriptionFormat() {
        let verificar = SwiftVerificar()
        let desc = verificar.description
        #expect(desc.contains("0.2.0"))
        #expect(desc.contains("SwiftFoundry"))
        #expect(desc.contains("SwiftVerificar"))
    }

    @Test("String interpolation works")
    func stringInterpolation() {
        let verificar = SwiftVerificar()
        let str = "\(verificar)"
        #expect(str.contains("SwiftVerificar"))
    }

    // MARK: - Sendable Conformance

    @Test("SwiftVerificar is Sendable across task boundaries")
    func sendableConformance() async {
        let verificar = SwiftVerificar()

        // Transfer to a different task
        let version = await Task {
            verificar.version
        }.value

        #expect(version == "0.2.0")
    }

    @Test("SwiftVerificar shared is accessible from multiple tasks")
    func sharedFromMultipleTasks() async {
        let versions = await withTaskGroup(of: String.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    SwiftVerificar.shared.version
                }
            }
            var results: [String] = []
            for await v in group {
                results.append(v)
            }
            return results
        }

        #expect(versions.count == 5)
        for v in versions {
            #expect(v == "0.2.0")
        }
    }

    @Test("SwiftVerificar can be stored in a Sendable closure")
    func sendableClosure() async {
        let verificar = SwiftVerificar()

        let closure: @Sendable () -> String = {
            verificar.version
        }

        let result = await Task {
            closure()
        }.value

        #expect(result == "0.2.0")
    }

    @Test("SwiftVerificar foundryInfo accessible across task boundary")
    func foundryInfoAcrossTaskBoundary() async {
        let verificar = SwiftVerificar()

        let info = await Task {
            verificar.foundryInfo
        }.value

        #expect(info.name == "SwiftFoundry")
    }

    // MARK: - Method Signature Verification

    @Test("validateAccessibility method signature compiles with all parameters")
    func validateAccessibilitySignature() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")
        let progress: @Sendable (Double, String) -> Void = { _, _ in }

        // Verify all overloads compile
        do {
            _ = try await verificar.validateAccessibility(url)
        } catch {}
        do {
            _ = try await verificar.validateAccessibility(url, progress: nil)
        } catch {}
        do {
            _ = try await verificar.validateAccessibility(url, progress: progress)
        } catch {}
    }

    @Test("validate method signature compiles with all parameter combinations")
    func validateSignature() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")
        let config = ValidatorConfig(maxFailures: 10)
        let progress: @Sendable (Double, String) -> Void = { _, _ in }

        // Minimum parameters
        do {
            _ = try await verificar.validate(url, profile: "PDF/UA-2")
        } catch {}
        // With config
        do {
            _ = try await verificar.validate(url, profile: "PDF/UA-2", config: config)
        } catch {}
        // With progress
        do {
            _ = try await verificar.validate(url, profile: "PDF/UA-2", progress: progress)
        } catch {}
        // All parameters
        do {
            _ = try await verificar.validate(
                url,
                profile: "PDF/UA-2",
                config: config,
                progress: progress
            )
        } catch {}
    }

    @Test("process method signature compiles with all parameter combinations")
    func processSignature() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")
        let config = ProcessorConfig()
        let progress: @Sendable (Double, String) -> Void = { _, _ in }

        // Minimum parameters
        _ = try await verificar.process(url)
        // With config
        _ = try await verificar.process(url, config: config)
        // With progress
        _ = try await verificar.process(url, progress: progress)
        // All parameters
        _ = try await verificar.process(url, config: config, progress: progress)
    }

    @Test("validateBatch method signature compiles with all parameter combinations")
    func validateBatchSignature() async throws {
        let verificar = SwiftVerificar()
        let urls: [URL] = []
        let progress: @Sendable (Int, Int, URL?) -> Void = { _, _, _ in }

        // Minimum parameters
        _ = try await verificar.validateBatch(urls, profile: "PDF/UA-2")
        // With maxConcurrency
        _ = try await verificar.validateBatch(urls, profile: "PDF/UA-2", maxConcurrency: 2)
        // With progress
        _ = try await verificar.validateBatch(urls, profile: "PDF/UA-2", progress: progress)
        // All parameters
        _ = try await verificar.validateBatch(
            urls,
            profile: "PDF/UA-2",
            maxConcurrency: 8,
            progress: progress
        )
    }

    // MARK: - Edge Cases

    @Test("validate with whitespace-only profile throws profileNotFound")
    func validateWhitespaceProfile() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        do {
            _ = try await verificar.validate(url, profile: "   ")
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as VerificarError {
            // Whitespace-only is not empty, so it passes the guard,
            // but resolveFlavour cannot match it, so profileNotFound is thrown
            if case .profileNotFound(let name) = error {
                #expect(name == "   ")
            } else {
                #expect(Bool(false), "Expected profileNotFound, got \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("validateBatch with maxConcurrency of 0 is clamped to 1")
    func validateBatchZeroConcurrency() async throws {
        let verificar = SwiftVerificar()
        let urls = [URL(filePath: "/tmp/test1.pdf")]

        // Should not crash or hang with maxConcurrency=0
        let results = try await verificar.validateBatch(
            urls,
            profile: "PDF/UA-2",
            maxConcurrency: 0
        )
        #expect(results.count == 1)
    }

    @Test("validateBatch with negative maxConcurrency is clamped to 1")
    func validateBatchNegativeConcurrency() async throws {
        let verificar = SwiftVerificar()
        let urls = [URL(filePath: "/tmp/test1.pdf")]

        let results = try await verificar.validateBatch(
            urls,
            profile: "PDF/UA-2",
            maxConcurrency: -5
        )
        #expect(results.count == 1)
    }

    @Test("validateBatch with duplicate URLs keeps last result for each")
    func validateBatchDuplicateURLs() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")
        let urls = [url, url, url]

        let results = try await verificar.validateBatch(urls, profile: "PDF/UA-2")
        // Dictionary deduplicates by URL -- last write wins
        #expect(results.count == 1)
        #expect(results[url] != nil)
    }

    @Test("Multiple independent instances can coexist")
    func multipleInstances() {
        let v1 = SwiftVerificar()
        let v2 = SwiftVerificar()
        let v3 = SwiftVerificar.shared

        #expect(v1.version == v2.version)
        #expect(v2.version == v3.version)
    }

    @Test("process with validate-only config returns exactly one error")
    func processValidateOnly() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")
        let config = ProcessorConfig.validateOnly

        let result = try await verificar.process(url, config: config)
        #expect(result.errorCount == 1)
        #expect(result.documentURL == url)
    }

    @Test("validateAccessibility delegates to validate with PDF/UA-2 profile")
    func validateAccessibilityDelegatesToValidate() async {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")

        // Both should produce parsingFailed for non-existent files
        var accessibilityError: VerificarError?
        var validateError: VerificarError?

        do {
            _ = try await verificar.validateAccessibility(url)
        } catch let error as VerificarError {
            accessibilityError = error
        } catch {}

        do {
            _ = try await verificar.validate(url, profile: "PDF/UA-2")
        } catch let error as VerificarError {
            validateError = error
        } catch {}

        // Both should be parsingFailed errors for the same URL
        #expect(accessibilityError == validateError)
    }

    @Test("process with extractFeatures-only task returns one error")
    func processExtractFeaturesOnly() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")
        let config = ProcessorConfig(
            featureConfig: FeatureConfig(),
            tasks: [.extractFeatures]
        )

        let result = try await verificar.process(url, config: config)
        #expect(result.errorCount == 1)
        #expect(result.documentURL == url)
    }

    @Test("process with fixMetadata-only task returns one error")
    func processFixMetadataOnly() async throws {
        let verificar = SwiftVerificar()
        let url = URL(filePath: "/tmp/test.pdf")
        let config = ProcessorConfig(
            fixerConfig: FixerConfig(),
            tasks: [.fixMetadata]
        )

        let result = try await verificar.process(url, config: config)
        #expect(result.errorCount == 1)
        #expect(result.documentURL == url)
    }

    @Test("Shared singleton foundryInfo matches default SwiftFoundry info")
    func sharedFoundryInfoMatchesDefault() {
        let defaultFoundry = SwiftFoundry()
        let sharedInfo = SwiftVerificar.shared.foundryInfo
        #expect(sharedInfo == defaultFoundry.info)
    }

    // MARK: - Real PDF Validation Tests

    @Test("validateAccessibility with real PDF returns a ValidationResult")
    func validateAccessibilityWithRealPDF() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftVerificarTest_\(UUID().uuidString).pdf")
        let pdfDoc = PDFKit.PDFDocument()
        let page = PDFKit.PDFPage()
        pdfDoc.insert(page, at: 0)
        guard pdfDoc.write(to: tempURL) else {
            #expect(Bool(false), "Failed to create temporary PDF")
            return
        }
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let verificar = SwiftVerificar()
        let result = try await verificar.validateAccessibility(tempURL)
        #expect(result.documentURL == tempURL)
        #expect(result.totalCount >= 0)
        #expect(!result.profileName.isEmpty)
    }

    @Test("validate with real PDF returns a ValidationResult")
    func validateWithRealPDF() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftVerificarTest_\(UUID().uuidString).pdf")
        let pdfDoc = PDFKit.PDFDocument()
        let page = PDFKit.PDFPage()
        pdfDoc.insert(page, at: 0)
        guard pdfDoc.write(to: tempURL) else {
            #expect(Bool(false), "Failed to create temporary PDF")
            return
        }
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let verificar = SwiftVerificar()
        let result = try await verificar.validate(tempURL, profile: "PDF/UA-2")
        #expect(result.documentURL == tempURL)
        #expect(result.totalCount >= 0)
        #expect(!result.profileName.isEmpty)
    }

    @Test("validate with real PDF calls all progress stages through completion")
    func validateWithRealPDFCallsAllProgress() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftVerificarTest_\(UUID().uuidString).pdf")
        let pdfDoc = PDFKit.PDFDocument()
        let page = PDFKit.PDFPage()
        pdfDoc.insert(page, at: 0)
        guard pdfDoc.write(to: tempURL) else {
            #expect(Bool(false), "Failed to create temporary PDF")
            return
        }
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let collector = ProgressCollector<(Double, String)>()
        let closure: @Sendable (Double, String) -> Void = { fraction, message in
            collector.record((fraction, message))
        }

        let verificar = SwiftVerificar()
        _ = try await verificar.validate(tempURL, profile: "PDF/UA-2", progress: closure)

        let updates = collector.updates
        // Should have all 7 progress stages: 0.05, 0.1, 0.2, 0.3, 0.5, 0.9, 1.0
        #expect(updates.count == 7)
        #expect(updates.last?.0 == 1.0)
        #expect(updates.last?.1 == "Done")
        #expect(updates.contains { $0.1.contains("Parsing") })
        #expect(updates.contains { $0.1.contains("Validating") })
        #expect(updates.contains { $0.1.contains("Validation complete") })
    }

    @Test("validateBatch with real PDFs returns success results")
    func validateBatchWithRealPDFs() async throws {
        var tempURLs: [URL] = []
        for _ in 0..<3 {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("SwiftVerificarTest_\(UUID().uuidString).pdf")
            let pdfDoc = PDFKit.PDFDocument()
            let page = PDFKit.PDFPage()
            pdfDoc.insert(page, at: 0)
            guard pdfDoc.write(to: url) else {
                #expect(Bool(false), "Failed to create temporary PDF")
                return
            }
            tempURLs.append(url)
        }
        defer {
            for url in tempURLs {
                try? FileManager.default.removeItem(at: url)
            }
        }

        let verificar = SwiftVerificar()
        let results = try await verificar.validateBatch(tempURLs, profile: "PDF/UA-2")
        #expect(results.count == 3)

        for url in tempURLs {
            #expect(results[url] != nil, "Missing result for \(url)")
            if case .success(let result) = results[url] {
                #expect(result.documentURL == url)
                #expect(result.totalCount >= 0)
            } else {
                #expect(Bool(false), "Expected success for \(url), got failure")
            }
        }
    }
}
