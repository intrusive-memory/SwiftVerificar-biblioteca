import Testing
import Foundation
@testable import SwiftVerificarBiblioteca

// MARK: - ValidatorConfig Tests

@Suite("ValidatorConfig Tests")
struct ValidatorConfigTests {

    // MARK: - Initialization

    @Test("Default initializer produces expected defaults")
    func defaultInitializer() {
        let config = ValidatorConfig()
        #expect(config.maxFailures == 0)
        #expect(config.recordPassedAssertions == false)
        #expect(config.logProgress == false)
        #expect(config.timeout == nil)
        #expect(config.parallelValidation == true)
    }

    @Test("Custom initializer stores all values")
    func customInitializer() {
        let config = ValidatorConfig(
            maxFailures: 25,
            recordPassedAssertions: true,
            logProgress: true,
            timeout: 120.0,
            parallelValidation: false
        )
        #expect(config.maxFailures == 25)
        #expect(config.recordPassedAssertions == true)
        #expect(config.logProgress == true)
        #expect(config.timeout == 120.0)
        #expect(config.parallelValidation == false)
    }

    @Test("Partial custom initializer uses defaults for unspecified parameters")
    func partialCustomInitializer() {
        let config = ValidatorConfig(maxFailures: 5)
        #expect(config.maxFailures == 5)
        #expect(config.recordPassedAssertions == false)
        #expect(config.logProgress == false)
        #expect(config.timeout == nil)
        #expect(config.parallelValidation == true)
    }

    @Test("Timeout-only initializer leaves other values at defaults")
    func timeoutOnlyInitializer() {
        let config = ValidatorConfig(timeout: 30.0)
        #expect(config.maxFailures == 0)
        #expect(config.timeout == 30.0)
    }

    // MARK: - Mutability

    @Test("Properties are mutable via var binding")
    func mutability() {
        var config = ValidatorConfig()
        config.maxFailures = 10
        config.recordPassedAssertions = true
        config.logProgress = true
        config.timeout = 60.0
        config.parallelValidation = false

        #expect(config.maxFailures == 10)
        #expect(config.recordPassedAssertions == true)
        #expect(config.logProgress == true)
        #expect(config.timeout == 60.0)
        #expect(config.parallelValidation == false)
    }

    @Test("Timeout can be set back to nil")
    func timeoutNilReset() {
        var config = ValidatorConfig(timeout: 30.0)
        #expect(config.timeout == 30.0)
        config.timeout = nil
        #expect(config.timeout == nil)
    }

    // MARK: - Derived Properties

    @Test("isFastFail is false when maxFailures is 0")
    func isFastFailZero() {
        let config = ValidatorConfig(maxFailures: 0)
        #expect(config.isFastFail == false)
    }

    @Test("isFastFail is true when maxFailures is positive")
    func isFastFailPositive() {
        let config = ValidatorConfig(maxFailures: 1)
        #expect(config.isFastFail == true)
    }

    @Test("isFastFail is true for large maxFailures")
    func isFastFailLarge() {
        let config = ValidatorConfig(maxFailures: 1000)
        #expect(config.isFastFail == true)
    }

    @Test("hasTimeout is false when timeout is nil")
    func hasTimeoutNil() {
        let config = ValidatorConfig(timeout: nil)
        #expect(config.hasTimeout == false)
    }

    @Test("hasTimeout is true when timeout is positive")
    func hasTimeoutPositive() {
        let config = ValidatorConfig(timeout: 60.0)
        #expect(config.hasTimeout == true)
    }

    @Test("hasTimeout is false when timeout is zero")
    func hasTimeoutZero() {
        let config = ValidatorConfig(timeout: 0.0)
        #expect(config.hasTimeout == false)
    }

    @Test("hasTimeout is false when timeout is negative")
    func hasTimeoutNegative() {
        let config = ValidatorConfig(timeout: -1.0)
        #expect(config.hasTimeout == false)
    }

    // MARK: - Equatable

    @Test("Two default configs are equal")
    func equatableDefaults() {
        let a = ValidatorConfig()
        let b = ValidatorConfig()
        #expect(a == b)
    }

    @Test("Configs with same custom values are equal")
    func equatableSameValues() {
        let a = ValidatorConfig(maxFailures: 5, timeout: 30.0)
        let b = ValidatorConfig(maxFailures: 5, timeout: 30.0)
        #expect(a == b)
    }

    @Test("Configs with different maxFailures are not equal")
    func notEqualMaxFailures() {
        let a = ValidatorConfig(maxFailures: 5)
        let b = ValidatorConfig(maxFailures: 10)
        #expect(a != b)
    }

    @Test("Configs with different recordPassedAssertions are not equal")
    func notEqualRecordPassed() {
        let a = ValidatorConfig(recordPassedAssertions: true)
        let b = ValidatorConfig(recordPassedAssertions: false)
        #expect(a != b)
    }

    @Test("Configs with different logProgress are not equal")
    func notEqualLogProgress() {
        let a = ValidatorConfig(logProgress: true)
        let b = ValidatorConfig(logProgress: false)
        #expect(a != b)
    }

    @Test("Configs with different timeout are not equal")
    func notEqualTimeout() {
        let a = ValidatorConfig(timeout: 30.0)
        let b = ValidatorConfig(timeout: 60.0)
        #expect(a != b)
    }

    @Test("Config with timeout vs nil timeout are not equal")
    func notEqualTimeoutVsNil() {
        let a = ValidatorConfig(timeout: 30.0)
        let b = ValidatorConfig(timeout: nil)
        #expect(a != b)
    }

    @Test("Configs with different parallelValidation are not equal")
    func notEqualParallel() {
        let a = ValidatorConfig(parallelValidation: true)
        let b = ValidatorConfig(parallelValidation: false)
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Equal configs produce the same hash")
    func hashableEqual() {
        let a = ValidatorConfig(maxFailures: 5, timeout: 30.0)
        let b = ValidatorConfig(maxFailures: 5, timeout: 30.0)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Can be used as dictionary key")
    func hashableDictionaryKey() {
        let config = ValidatorConfig(maxFailures: 10)
        var dict: [ValidatorConfig: String] = [:]
        dict[config] = "test"
        #expect(dict[config] == "test")
    }

    @Test("Can be stored in a Set")
    func hashableSet() {
        let a = ValidatorConfig(maxFailures: 5)
        let b = ValidatorConfig(maxFailures: 10)
        let c = ValidatorConfig(maxFailures: 5)
        let set: Set<ValidatorConfig> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let original = ValidatorConfig(
            maxFailures: 15,
            recordPassedAssertions: true,
            logProgress: true,
            timeout: 45.5,
            parallelValidation: false
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ValidatorConfig.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip with nil timeout")
    func codableRoundTripNilTimeout() throws {
        let original = ValidatorConfig(timeout: nil)
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ValidatorConfig.self, from: data)
        #expect(decoded == original)
        #expect(decoded.timeout == nil)
    }

    @Test("Codable round-trip with defaults")
    func codableRoundTripDefaults() throws {
        let original = ValidatorConfig()
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ValidatorConfig.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes maxFailures")
    func descriptionIncludesMaxFailures() {
        let config = ValidatorConfig(maxFailures: 5)
        #expect(config.description.contains("maxFailures=5"))
    }

    @Test("Description includes recordPassed when true")
    func descriptionIncludesRecordPassed() {
        let config = ValidatorConfig(recordPassedAssertions: true)
        #expect(config.description.contains("recordPassed"))
    }

    @Test("Description excludes recordPassed when false")
    func descriptionExcludesRecordPassed() {
        let config = ValidatorConfig(recordPassedAssertions: false)
        #expect(!config.description.contains("recordPassed"))
    }

    @Test("Description includes logProgress when true")
    func descriptionIncludesLogProgress() {
        let config = ValidatorConfig(logProgress: true)
        #expect(config.description.contains("logProgress"))
    }

    @Test("Description includes timeout when set")
    func descriptionIncludesTimeout() {
        let config = ValidatorConfig(timeout: 30.0)
        #expect(config.description.contains("timeout=30.0s"))
    }

    @Test("Description excludes timeout when nil")
    func descriptionExcludesTimeout() {
        let config = ValidatorConfig(timeout: nil)
        #expect(!config.description.contains("timeout"))
    }

    @Test("Description includes parallel flag")
    func descriptionIncludesParallel() {
        let config = ValidatorConfig(parallelValidation: false)
        #expect(config.description.contains("parallel=false"))
    }

    @Test("Description starts with ValidatorConfig")
    func descriptionPrefix() {
        let config = ValidatorConfig()
        #expect(config.description.hasPrefix("ValidatorConfig("))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let config = ValidatorConfig(maxFailures: 5, timeout: 30.0)
        let result = await Task {
            config
        }.value
        #expect(result == config)
    }

    // MARK: - Edge Cases

    @Test("maxFailures can be set to Int.max")
    func maxFailuresIntMax() {
        let config = ValidatorConfig(maxFailures: Int.max)
        #expect(config.maxFailures == Int.max)
        #expect(config.isFastFail == true)
    }

    @Test("timeout can be very large")
    func timeoutVeryLarge() {
        let config = ValidatorConfig(timeout: Double.greatestFiniteMagnitude)
        #expect(config.timeout == Double.greatestFiniteMagnitude)
        #expect(config.hasTimeout == true)
    }

    @Test("timeout can be very small positive")
    func timeoutVerySmall() {
        let config = ValidatorConfig(timeout: 0.001)
        #expect(config.hasTimeout == true)
    }
}
