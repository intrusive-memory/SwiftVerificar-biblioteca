import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("ComponentInfo Tests")
struct ComponentInfoTests {

    // MARK: - Initialization

    @Test("Init stores all fields correctly")
    func initStoresFields() {
        let info = ComponentInfo(
            name: "MyComponent",
            version: "2.3.1",
            componentDescription: "A great component",
            provider: "Acme Corp"
        )

        #expect(info.name == "MyComponent")
        #expect(info.version == "2.3.1")
        #expect(info.componentDescription == "A great component")
        #expect(info.provider == "Acme Corp")
    }

    @Test("Init with empty strings")
    func initWithEmptyStrings() {
        let info = ComponentInfo(
            name: "",
            version: "",
            componentDescription: "",
            provider: ""
        )

        #expect(info.name == "")
        #expect(info.version == "")
        #expect(info.componentDescription == "")
        #expect(info.provider == "")
    }

    @Test("Init with Unicode content")
    func initWithUnicode() {
        let info = ComponentInfo(
            name: "Validador PDF/UA",
            version: "1.0.0-beta",
            componentDescription: "Validador de accesibilidad PDF",
            provider: "Proyecto SwiftVerificar"
        )

        #expect(info.name == "Validador PDF/UA")
        #expect(info.componentDescription == "Validador de accesibilidad PDF")
    }

    // MARK: - Equatable

    @Test("Equal instances are equal")
    func equalInstances() {
        let info1 = ComponentInfo(
            name: "Parser", version: "1.0", componentDescription: "Desc", provider: "Prov"
        )
        let info2 = ComponentInfo(
            name: "Parser", version: "1.0", componentDescription: "Desc", provider: "Prov"
        )

        #expect(info1 == info2)
    }

    @Test("Different name makes unequal")
    func differentName() {
        let info1 = ComponentInfo(
            name: "Parser", version: "1.0", componentDescription: "Desc", provider: "Prov"
        )
        let info2 = ComponentInfo(
            name: "Validator", version: "1.0", componentDescription: "Desc", provider: "Prov"
        )

        #expect(info1 != info2)
    }

    @Test("Different version makes unequal")
    func differentVersion() {
        let info1 = ComponentInfo(
            name: "Parser", version: "1.0", componentDescription: "Desc", provider: "Prov"
        )
        let info2 = ComponentInfo(
            name: "Parser", version: "2.0", componentDescription: "Desc", provider: "Prov"
        )

        #expect(info1 != info2)
    }

    @Test("Different description makes unequal")
    func differentDescription() {
        let info1 = ComponentInfo(
            name: "Parser", version: "1.0", componentDescription: "Desc A", provider: "Prov"
        )
        let info2 = ComponentInfo(
            name: "Parser", version: "1.0", componentDescription: "Desc B", provider: "Prov"
        )

        #expect(info1 != info2)
    }

    @Test("Different provider makes unequal")
    func differentProvider() {
        let info1 = ComponentInfo(
            name: "Parser", version: "1.0", componentDescription: "Desc", provider: "Prov A"
        )
        let info2 = ComponentInfo(
            name: "Parser", version: "1.0", componentDescription: "Desc", provider: "Prov B"
        )

        #expect(info1 != info2)
    }

    // MARK: - Hashable

    @Test("Equal instances hash to same value")
    func hashConsistency() {
        let info1 = ComponentInfo(
            name: "Parser", version: "1.0", componentDescription: "Desc", provider: "Prov"
        )
        let info2 = ComponentInfo(
            name: "Parser", version: "1.0", componentDescription: "Desc", provider: "Prov"
        )

        #expect(info1.hashValue == info2.hashValue)
    }

    @Test("Can be used as dictionary key")
    func dictionaryKey() {
        let info = ComponentInfo(
            name: "Parser", version: "1.0", componentDescription: "Desc", provider: "Prov"
        )

        var dict: [ComponentInfo: String] = [:]
        dict[info] = "test"

        #expect(dict[info] == "test")
    }

    @Test("Can be used in a Set")
    func setMembership() {
        let info1 = ComponentInfo(
            name: "A", version: "1.0", componentDescription: "D", provider: "P"
        )
        let info2 = ComponentInfo(
            name: "A", version: "1.0", componentDescription: "D", provider: "P"
        )
        let info3 = ComponentInfo(
            name: "B", version: "1.0", componentDescription: "D", provider: "P"
        )

        var set: Set<ComponentInfo> = [info1, info2, info3]
        #expect(set.count == 2)
        #expect(set.contains(info1))
        #expect(set.contains(info3))
    }

    // MARK: - Codable

    @Test("Encodes and decodes to JSON")
    func jsonRoundTrip() throws {
        let original = ComponentInfo(
            name: "Parser",
            version: "1.0.0",
            componentDescription: "PDF parser",
            provider: "SwiftVerificar"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ComponentInfo.self, from: data)

        #expect(original == decoded)
    }

    @Test("JSON contains expected keys")
    func jsonKeys() throws {
        let info = ComponentInfo(
            name: "Test",
            version: "1.0",
            componentDescription: "Desc",
            provider: "Prov"
        )

        let data = try JSONEncoder().encode(info)
        let json = String(data: data, encoding: .utf8)

        #expect(json != nil)
        #expect(json?.contains("\"name\"") == true)
        #expect(json?.contains("\"version\"") == true)
        #expect(json?.contains("\"componentDescription\"") == true)
        #expect(json?.contains("\"provider\"") == true)
    }

    // MARK: - CustomStringConvertible

    @Test("Description formats correctly")
    func descriptionFormat() {
        let info = ComponentInfo(
            name: "SwiftParser",
            version: "3.2.1",
            componentDescription: "A parser",
            provider: "Acme"
        )

        #expect(info.description == "SwiftParser v3.2.1 (Acme)")
    }

    @Test("Description with empty fields")
    func descriptionEmpty() {
        let info = ComponentInfo(
            name: "",
            version: "",
            componentDescription: "",
            provider: ""
        )

        #expect(info.description == " v ()")
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let info = ComponentInfo(
            name: "Async",
            version: "1.0",
            componentDescription: "Async safe",
            provider: "Test"
        )

        let result = await Task {
            info.name
        }.value

        #expect(result == "Async")
    }
}
