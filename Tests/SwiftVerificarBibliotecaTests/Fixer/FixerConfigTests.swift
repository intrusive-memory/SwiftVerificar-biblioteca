import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("FixerConfig Tests")
struct FixerConfigTests {

    // MARK: - Default Initialization

    @Test("Default init enables all fixing options")
    func defaultInit() {
        let config = FixerConfig()

        #expect(config.fixInfoDictionary == true)
        #expect(config.fixXMPMetadata == true)
        #expect(config.syncInfoAndXMP == true)
    }

    @Test("Default init is equivalent to .all")
    func defaultIsAll() {
        let config = FixerConfig()
        #expect(config == FixerConfig.all)
    }

    // MARK: - Custom Initialization

    @Test("Custom init with all false")
    func customInitAllFalse() {
        let config = FixerConfig(
            fixInfoDictionary: false,
            fixXMPMetadata: false,
            syncInfoAndXMP: false
        )

        #expect(config.fixInfoDictionary == false)
        #expect(config.fixXMPMetadata == false)
        #expect(config.syncInfoAndXMP == false)
    }

    @Test("Custom init with mixed values")
    func customInitMixed() {
        let config = FixerConfig(
            fixInfoDictionary: true,
            fixXMPMetadata: false,
            syncInfoAndXMP: true
        )

        #expect(config.fixInfoDictionary == true)
        #expect(config.fixXMPMetadata == false)
        #expect(config.syncInfoAndXMP == true)
    }

    @Test("Custom init with only info")
    func customInitInfoOnly() {
        let config = FixerConfig(
            fixInfoDictionary: true,
            fixXMPMetadata: false,
            syncInfoAndXMP: false
        )

        #expect(config.fixInfoDictionary == true)
        #expect(config.fixXMPMetadata == false)
        #expect(config.syncInfoAndXMP == false)
    }

    @Test("Custom init with only XMP")
    func customInitXMPOnly() {
        let config = FixerConfig(
            fixInfoDictionary: false,
            fixXMPMetadata: true,
            syncInfoAndXMP: false
        )

        #expect(config.fixInfoDictionary == false)
        #expect(config.fixXMPMetadata == true)
        #expect(config.syncInfoAndXMP == false)
    }

    @Test("Custom init with only sync")
    func customInitSyncOnly() {
        let config = FixerConfig(
            fixInfoDictionary: false,
            fixXMPMetadata: false,
            syncInfoAndXMP: true
        )

        #expect(config.fixInfoDictionary == false)
        #expect(config.fixXMPMetadata == false)
        #expect(config.syncInfoAndXMP == true)
    }

    // MARK: - Static Factories

    @Test("FixerConfig.all has all options enabled")
    func allFactory() {
        let config = FixerConfig.all

        #expect(config.fixInfoDictionary == true)
        #expect(config.fixXMPMetadata == true)
        #expect(config.syncInfoAndXMP == true)
    }

    @Test("FixerConfig.none has all options disabled")
    func noneFactory() {
        let config = FixerConfig.none

        #expect(config.fixInfoDictionary == false)
        #expect(config.fixXMPMetadata == false)
        #expect(config.syncInfoAndXMP == false)
    }

    @Test("FixerConfig.infoOnly only enables info dictionary fixing")
    func infoOnlyFactory() {
        let config = FixerConfig.infoOnly

        #expect(config.fixInfoDictionary == true)
        #expect(config.fixXMPMetadata == false)
        #expect(config.syncInfoAndXMP == false)
    }

    @Test("FixerConfig.xmpOnly only enables XMP fixing")
    func xmpOnlyFactory() {
        let config = FixerConfig.xmpOnly

        #expect(config.fixInfoDictionary == false)
        #expect(config.fixXMPMetadata == true)
        #expect(config.syncInfoAndXMP == false)
    }

    // MARK: - Derived Properties

    @Test("isAnyFixingEnabled returns true when at least one option is enabled")
    func isAnyFixingEnabledTrue() {
        #expect(FixerConfig.all.isAnyFixingEnabled == true)
        #expect(FixerConfig.infoOnly.isAnyFixingEnabled == true)
        #expect(FixerConfig.xmpOnly.isAnyFixingEnabled == true)
        #expect(FixerConfig(fixInfoDictionary: false, fixXMPMetadata: false, syncInfoAndXMP: true).isAnyFixingEnabled == true)
    }

    @Test("isAnyFixingEnabled returns false when all options are disabled")
    func isAnyFixingEnabledFalse() {
        #expect(FixerConfig.none.isAnyFixingEnabled == false)
    }

    @Test("isFullFixingEnabled returns true when all options are enabled")
    func isFullFixingEnabledTrue() {
        #expect(FixerConfig.all.isFullFixingEnabled == true)
        #expect(FixerConfig().isFullFixingEnabled == true)
    }

    @Test("isFullFixingEnabled returns false when any option is disabled")
    func isFullFixingEnabledFalse() {
        #expect(FixerConfig.none.isFullFixingEnabled == false)
        #expect(FixerConfig.infoOnly.isFullFixingEnabled == false)
        #expect(FixerConfig.xmpOnly.isFullFixingEnabled == false)
        #expect(FixerConfig(fixInfoDictionary: true, fixXMPMetadata: true, syncInfoAndXMP: false).isFullFixingEnabled == false)
    }

    // MARK: - Mutability

    @Test("fixInfoDictionary is mutable")
    func mutableFixInfoDictionary() {
        var config = FixerConfig()
        config.fixInfoDictionary = false
        #expect(config.fixInfoDictionary == false)
    }

    @Test("fixXMPMetadata is mutable")
    func mutableFixXMPMetadata() {
        var config = FixerConfig()
        config.fixXMPMetadata = false
        #expect(config.fixXMPMetadata == false)
    }

    @Test("syncInfoAndXMP is mutable")
    func mutableSyncInfoAndXMP() {
        var config = FixerConfig()
        config.syncInfoAndXMP = false
        #expect(config.syncInfoAndXMP == false)
    }

    // MARK: - Equatable

    @Test("Same configs are equal")
    func equality() {
        let a = FixerConfig(fixInfoDictionary: true, fixXMPMetadata: false, syncInfoAndXMP: true)
        let b = FixerConfig(fixInfoDictionary: true, fixXMPMetadata: false, syncInfoAndXMP: true)
        #expect(a == b)
    }

    @Test("Different fixInfoDictionary are not equal")
    func inequalityInfo() {
        let a = FixerConfig(fixInfoDictionary: true, fixXMPMetadata: false, syncInfoAndXMP: false)
        let b = FixerConfig(fixInfoDictionary: false, fixXMPMetadata: false, syncInfoAndXMP: false)
        #expect(a != b)
    }

    @Test("Different fixXMPMetadata are not equal")
    func inequalityXMP() {
        let a = FixerConfig(fixInfoDictionary: false, fixXMPMetadata: true, syncInfoAndXMP: false)
        let b = FixerConfig(fixInfoDictionary: false, fixXMPMetadata: false, syncInfoAndXMP: false)
        #expect(a != b)
    }

    @Test("Different syncInfoAndXMP are not equal")
    func inequalitySync() {
        let a = FixerConfig(fixInfoDictionary: false, fixXMPMetadata: false, syncInfoAndXMP: true)
        let b = FixerConfig(fixInfoDictionary: false, fixXMPMetadata: false, syncInfoAndXMP: false)
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Can be used in a Set")
    func hashable() {
        let a = FixerConfig.all
        let b = FixerConfig.none
        let c = FixerConfig.all

        let set: Set<FixerConfig> = [a, b, c]
        #expect(set.count == 2)
    }

    @Test("Equal configs have same hash value")
    func equalHashValues() {
        let a = FixerConfig.infoOnly
        let b = FixerConfig.infoOnly
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - Codable

    @Test("Codable round-trip with all enabled")
    func codableRoundTripAll() throws {
        let original = FixerConfig.all
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FixerConfig.self, from: data)

        #expect(decoded == original)
    }

    @Test("Codable round-trip with none enabled")
    func codableRoundTripNone() throws {
        let original = FixerConfig.none
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FixerConfig.self, from: data)

        #expect(decoded == original)
    }

    @Test("Codable round-trip with mixed values")
    func codableRoundTripMixed() throws {
        let original = FixerConfig(
            fixInfoDictionary: true,
            fixXMPMetadata: false,
            syncInfoAndXMP: true
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FixerConfig.self, from: data)

        #expect(decoded == original)
    }

    @Test("JSON contains expected keys")
    func jsonKeys() throws {
        let config = FixerConfig()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let data = try encoder.encode(config)
        let json = String(data: data, encoding: .utf8)

        #expect(json?.contains("fixInfoDictionary") == true)
        #expect(json?.contains("fixXMPMetadata") == true)
        #expect(json?.contains("syncInfoAndXMP") == true)
    }

    // MARK: - CustomStringConvertible

    @Test("Description for all-enabled config")
    func descriptionAll() {
        let config = FixerConfig.all
        #expect(config.description.contains("info"))
        #expect(config.description.contains("xmp"))
        #expect(config.description.contains("sync"))
    }

    @Test("Description for none config")
    func descriptionNone() {
        let config = FixerConfig.none
        #expect(config.description.contains("none"))
    }

    @Test("Description for infoOnly config")
    func descriptionInfoOnly() {
        let config = FixerConfig.infoOnly
        #expect(config.description.contains("info"))
        #expect(!config.description.contains("xmp"))
        #expect(!config.description.contains("sync"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let config = FixerConfig(fixInfoDictionary: true, fixXMPMetadata: false, syncInfoAndXMP: true)

        let result = await Task {
            config
        }.value

        #expect(result == config)
    }
}
