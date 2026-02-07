import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("FeatureConfig Tests")
struct FeatureConfigTests {

    // MARK: - Default Initialization

    @Test("Default init enables all feature types")
    func defaultInit() {
        let config = FeatureConfig()

        #expect(config.enabledFeatures == Set(FeatureType.allCases))
        #expect(config.enabledFeatures.count == 19)
    }

    @Test("Default init enables includeSubFeatures")
    func defaultIncludeSubFeatures() {
        let config = FeatureConfig()
        #expect(config.includeSubFeatures == true)
    }

    // MARK: - Custom Initialization

    @Test("Custom init with specific features")
    func customInit() {
        let config = FeatureConfig(
            enabledFeatures: [.fonts, .colorSpaces, .pages],
            includeSubFeatures: false
        )

        #expect(config.enabledFeatures.count == 3)
        #expect(config.enabledFeatures.contains(.fonts))
        #expect(config.enabledFeatures.contains(.colorSpaces))
        #expect(config.enabledFeatures.contains(.pages))
        #expect(config.includeSubFeatures == false)
    }

    @Test("Custom init with empty features")
    func emptyFeaturesInit() {
        let config = FeatureConfig(enabledFeatures: [])
        #expect(config.enabledFeatures.isEmpty)
    }

    @Test("Custom init with single feature")
    func singleFeatureInit() {
        let config = FeatureConfig(enabledFeatures: [.metadata])
        #expect(config.enabledFeatures.count == 1)
        #expect(config.enabledFeatures.contains(.metadata))
    }

    // MARK: - Static Factories

    @Test("FeatureConfig.none has no features and no sub-features")
    func noneConfig() {
        let config = FeatureConfig.none
        #expect(config.enabledFeatures.isEmpty)
        #expect(config.includeSubFeatures == false)
    }

    @Test("FeatureConfig.all has all features and sub-features")
    func allConfig() {
        let config = FeatureConfig.all
        #expect(config.enabledFeatures == Set(FeatureType.allCases))
        #expect(config.includeSubFeatures == true)
    }

    // MARK: - isEnabled

    @Test("isEnabled returns true for enabled feature")
    func isEnabledTrue() {
        let config = FeatureConfig(enabledFeatures: [.fonts, .pages])
        #expect(config.isEnabled(.fonts))
        #expect(config.isEnabled(.pages))
    }

    @Test("isEnabled returns false for disabled feature")
    func isEnabledFalse() {
        let config = FeatureConfig(enabledFeatures: [.fonts])
        #expect(!config.isEnabled(.pages))
        #expect(!config.isEnabled(.metadata))
    }

    @Test("isEnabled returns false for empty config")
    func isEnabledEmpty() {
        let config = FeatureConfig(enabledFeatures: [])
        for featureType in FeatureType.allCases {
            #expect(!config.isEnabled(featureType))
        }
    }

    @Test("isEnabled returns true for all features in default config")
    func isEnabledAllDefault() {
        let config = FeatureConfig()
        for featureType in FeatureType.allCases {
            #expect(config.isEnabled(featureType))
        }
    }

    // MARK: - enabling / disabling

    @Test("enabling adds a feature type")
    func enabling() {
        let config = FeatureConfig(enabledFeatures: [.fonts])
        let updated = config.enabling(.pages)

        #expect(updated.enabledFeatures.contains(.fonts))
        #expect(updated.enabledFeatures.contains(.pages))
        #expect(updated.enabledFeatures.count == 2)
    }

    @Test("enabling an already-enabled feature is idempotent")
    func enablingIdempotent() {
        let config = FeatureConfig(enabledFeatures: [.fonts])
        let updated = config.enabling(.fonts)

        #expect(updated.enabledFeatures.count == 1)
        #expect(updated.enabledFeatures.contains(.fonts))
    }

    @Test("disabling removes a feature type")
    func disabling() {
        let config = FeatureConfig(enabledFeatures: [.fonts, .pages])
        let updated = config.disabling(.fonts)

        #expect(!updated.enabledFeatures.contains(.fonts))
        #expect(updated.enabledFeatures.contains(.pages))
        #expect(updated.enabledFeatures.count == 1)
    }

    @Test("disabling an already-disabled feature is idempotent")
    func disablingIdempotent() {
        let config = FeatureConfig(enabledFeatures: [.pages])
        let updated = config.disabling(.fonts)

        #expect(updated.enabledFeatures.count == 1)
        #expect(updated.enabledFeatures.contains(.pages))
    }

    @Test("enabling and disabling do not mutate original")
    func immutability() {
        let config = FeatureConfig(enabledFeatures: [.fonts])
        _ = config.enabling(.pages)
        _ = config.disabling(.fonts)

        #expect(config.enabledFeatures == [.fonts])
    }

    @Test("enabling preserves includeSubFeatures")
    func enablingPreservesSubFeatures() {
        let config = FeatureConfig(enabledFeatures: [.fonts], includeSubFeatures: false)
        let updated = config.enabling(.pages)
        #expect(updated.includeSubFeatures == false)
    }

    // MARK: - Mutability

    @Test("enabledFeatures is mutable")
    func mutableEnabledFeatures() {
        var config = FeatureConfig(enabledFeatures: [.fonts])
        config.enabledFeatures.insert(.pages)

        #expect(config.enabledFeatures.count == 2)
    }

    @Test("includeSubFeatures is mutable")
    func mutableIncludeSubFeatures() {
        var config = FeatureConfig()
        config.includeSubFeatures = false

        #expect(config.includeSubFeatures == false)
    }

    // MARK: - Equatable

    @Test("Same configs are equal")
    func equality() {
        let a = FeatureConfig(enabledFeatures: [.fonts, .pages], includeSubFeatures: true)
        let b = FeatureConfig(enabledFeatures: [.fonts, .pages], includeSubFeatures: true)
        #expect(a == b)
    }

    @Test("Different feature sets are not equal")
    func featureSetInequality() {
        let a = FeatureConfig(enabledFeatures: [.fonts])
        let b = FeatureConfig(enabledFeatures: [.pages])
        #expect(a != b)
    }

    @Test("Different includeSubFeatures are not equal")
    func subFeaturesInequality() {
        let a = FeatureConfig(enabledFeatures: [.fonts], includeSubFeatures: true)
        let b = FeatureConfig(enabledFeatures: [.fonts], includeSubFeatures: false)
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Can be used in a Set")
    func hashable() {
        let a = FeatureConfig(enabledFeatures: [.fonts])
        let b = FeatureConfig(enabledFeatures: [.pages])
        let c = FeatureConfig(enabledFeatures: [.fonts])

        let set: Set<FeatureConfig> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = FeatureConfig(
            enabledFeatures: [.fonts, .pages, .metadata],
            includeSubFeatures: false
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FeatureConfig.self, from: data)

        #expect(decoded == original)
    }

    @Test("Empty features Codable round-trip")
    func emptyCodableRoundTrip() throws {
        let original = FeatureConfig.none
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FeatureConfig.self, from: data)

        #expect(decoded == original)
    }

    @Test("All features Codable round-trip")
    func allCodableRoundTrip() throws {
        let original = FeatureConfig.all
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FeatureConfig.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes feature names")
    func descriptionIncludesFeatures() {
        let config = FeatureConfig(enabledFeatures: [.fonts])
        #expect(config.description.contains("Fonts"))
    }

    @Test("Description includes includeSubFeatures")
    func descriptionIncludesSubFeatures() {
        let config = FeatureConfig(enabledFeatures: [], includeSubFeatures: false)
        #expect(config.description.contains("false"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let config = FeatureConfig(enabledFeatures: [.fonts, .pages])

        let result = await Task {
            config
        }.value

        #expect(result == config)
    }
}
