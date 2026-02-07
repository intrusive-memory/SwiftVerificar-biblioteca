import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

// MARK: - Test Double

/// A minimal ValidationFoundry for Foundry actor tests.
private struct TestFoundry: ValidationFoundry, Equatable {
    let label: String

    init(label: String = "test") {
        self.label = label
    }

    func createParser(for url: URL) async throws -> any PDFParserProvider {
        StubPDFParser(url: url)
    }

    func createValidator(
        profileName: String,
        config: ValidatorConfiguration
    ) throws -> any PDFValidatorProvider {
        StubPDFValidator(profileName: profileName, config: config)
    }

    func createMetadataFixer(
        config: MetadataFixerConfiguration
    ) -> any MetadataFixerProvider {
        StubMetadataFixer(config: config)
    }

    func createFeatureExtractor(
        config: FeatureExtractorConfiguration
    ) -> any FeatureExtractorProvider {
        StubFeatureExtractor(config: config)
    }
}

// MARK: - Foundry Actor Tests

@Suite("Foundry Actor Tests")
struct FoundryTests {

    // Use a fresh Foundry instance per test for isolation (not the shared singleton)
    private func makeFreshFoundry() -> Foundry {
        Foundry()
    }

    @Test("Shared singleton exists")
    func sharedExists() async {
        // Just accessing shared to verify it compiles and is accessible
        let foundry = Foundry.shared
        _ = foundry
    }

    @Test("Fresh instance has no provider registered")
    func freshHasNoProvider() async {
        let foundry = makeFreshFoundry()
        let registered = await foundry.isRegistered

        #expect(registered == false)
    }

    @Test("current() throws when no provider registered")
    func currentThrowsWhenEmpty() async {
        let foundry = makeFreshFoundry()

        await #expect(throws: VerificarError.self) {
            _ = try await foundry.current()
        }
    }

    @Test("current() throws configurationError with descriptive message")
    func currentThrowsConfigError() async {
        let foundry = makeFreshFoundry()

        do {
            _ = try await foundry.current()
            Issue.record("Expected error was not thrown")
        } catch let error as VerificarError {
            switch error {
            case .configurationError(let reason):
                #expect(reason.contains("No foundry registered"))
            default:
                Issue.record("Expected configurationError, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("register() then current() returns the foundry")
    func registerThenCurrent() async throws {
        let foundry = makeFreshFoundry()
        let testFoundry = TestFoundry(label: "alpha")

        await foundry.register(testFoundry)
        let retrieved = try await foundry.current()

        #expect(retrieved is TestFoundry)
    }

    @Test("isRegistered is true after registration")
    func isRegisteredAfterRegister() async {
        let foundry = makeFreshFoundry()

        await foundry.register(TestFoundry())
        let registered = await foundry.isRegistered

        #expect(registered == true)
    }

    @Test("register(nil) clears the registration")
    func registerNilClears() async {
        let foundry = makeFreshFoundry()

        await foundry.register(TestFoundry())
        #expect(await foundry.isRegistered == true)

        await foundry.register(nil)
        #expect(await foundry.isRegistered == false)

        await #expect(throws: VerificarError.self) {
            _ = try await foundry.current()
        }
    }

    @Test("register() replaces existing foundry")
    func registerReplaces() async throws {
        let foundry = makeFreshFoundry()

        await foundry.register(TestFoundry(label: "first"))
        let first = try await foundry.current()

        await foundry.register(TestFoundry(label: "second"))
        let second = try await foundry.current()

        // They should be different instances (label differs)
        let firstLabel = (first as? TestFoundry)?.label
        let secondLabel = (second as? TestFoundry)?.label

        #expect(firstLabel == "first")
        #expect(secondLabel == "second")
    }

    @Test("registerAndReturn returns the same instance")
    func registerAndReturn() async {
        let foundry = makeFreshFoundry()
        let original = TestFoundry(label: "returned")

        let returned = await foundry.registerAndReturn(original)

        #expect(returned == original)
        #expect(returned.label == "returned")
    }

    @Test("registerAndReturn makes foundry available via current()")
    func registerAndReturnMakesCurrent() async throws {
        let foundry = makeFreshFoundry()

        await foundry.registerAndReturn(TestFoundry(label: "via-return"))
        let current = try await foundry.current()

        #expect((current as? TestFoundry)?.label == "via-return")
    }

    @Test("Foundry current() returns a usable foundry")
    func currentIsUsable() async throws {
        let foundry = makeFreshFoundry()
        await foundry.register(TestFoundry())

        let current = try await foundry.current()
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test.pdf")
        let parser = try await current.createParser(for: tempURL)

        #expect(parser.url == tempURL)
    }

    @Test("Multiple registrations only keep the last")
    func multipleRegistrations() async throws {
        let foundry = makeFreshFoundry()

        await foundry.register(TestFoundry(label: "a"))
        await foundry.register(TestFoundry(label: "b"))
        await foundry.register(TestFoundry(label: "c"))

        let current = try await foundry.current()
        #expect((current as? TestFoundry)?.label == "c")
    }

    @Test("Foundry is Sendable across tasks")
    func sendable() async {
        let foundry = makeFreshFoundry()
        await foundry.register(TestFoundry(label: "cross-task"))

        let registered = await Task {
            await foundry.isRegistered
        }.value

        #expect(registered == true)
    }

    @Test("Concurrent access is safe")
    func concurrentAccess() async {
        let foundry = makeFreshFoundry()

        // Register from multiple tasks concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await foundry.register(TestFoundry(label: "task-\(i)"))
                }
            }
        }

        // After all tasks complete, exactly one foundry should be registered
        let registered = await foundry.isRegistered
        #expect(registered == true)

        // current() should not throw
        let current = try? await foundry.current()
        #expect(current != nil)
    }
}
