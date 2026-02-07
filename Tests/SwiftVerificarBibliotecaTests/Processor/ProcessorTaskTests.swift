import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("ProcessorTask Tests")
struct ProcessorTaskTests {

    // MARK: - Case Values

    @Test("validate case exists")
    func validateCase() {
        let task = ProcessorTask.validate
        #expect(task == .validate)
    }

    @Test("extractFeatures case exists")
    func extractFeaturesCase() {
        let task = ProcessorTask.extractFeatures
        #expect(task == .extractFeatures)
    }

    @Test("fixMetadata case exists")
    func fixMetadataCase() {
        let task = ProcessorTask.fixMetadata
        #expect(task == .fixMetadata)
    }

    // MARK: - CaseIterable

    @Test("CaseIterable has exactly 3 cases")
    func caseIterableCount() {
        #expect(ProcessorTask.allCases.count == 3)
    }

    @Test("CaseIterable contains all cases")
    func caseIterableContainsAll() {
        let allCases = ProcessorTask.allCases
        #expect(allCases.contains(.validate))
        #expect(allCases.contains(.extractFeatures))
        #expect(allCases.contains(.fixMetadata))
    }

    // MARK: - RawValue

    @Test("validate raw value is 'validate'")
    func validateRawValue() {
        #expect(ProcessorTask.validate.rawValue == "validate")
    }

    @Test("extractFeatures raw value is 'extractFeatures'")
    func extractFeaturesRawValue() {
        #expect(ProcessorTask.extractFeatures.rawValue == "extractFeatures")
    }

    @Test("fixMetadata raw value is 'fixMetadata'")
    func fixMetadataRawValue() {
        #expect(ProcessorTask.fixMetadata.rawValue == "fixMetadata")
    }

    @Test("Init from valid raw value succeeds")
    func initFromValidRawValue() {
        #expect(ProcessorTask(rawValue: "validate") == .validate)
        #expect(ProcessorTask(rawValue: "extractFeatures") == .extractFeatures)
        #expect(ProcessorTask(rawValue: "fixMetadata") == .fixMetadata)
    }

    @Test("Init from invalid raw value returns nil")
    func initFromInvalidRawValue() {
        #expect(ProcessorTask(rawValue: "invalid") == nil)
        #expect(ProcessorTask(rawValue: "") == nil)
        #expect(ProcessorTask(rawValue: "Validate") == nil)
    }

    // MARK: - Hashable

    @Test("Can be used in a Set")
    func hashable() {
        let set: Set<ProcessorTask> = [.validate, .extractFeatures, .fixMetadata]
        #expect(set.count == 3)
    }

    @Test("Duplicate elements in Set are deduplicated")
    func hashableDeduplicate() {
        let set: Set<ProcessorTask> = [.validate, .validate, .extractFeatures]
        #expect(set.count == 2)
    }

    @Test("Equal tasks have same hash value")
    func equalHashValues() {
        let a = ProcessorTask.validate
        let b = ProcessorTask.validate
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Can be used as Dictionary key")
    func dictionaryKey() {
        let dict: [ProcessorTask: String] = [
            .validate: "Validation",
            .extractFeatures: "Extraction",
            .fixMetadata: "Fixing"
        ]
        #expect(dict[.validate] == "Validation")
        #expect(dict[.extractFeatures] == "Extraction")
        #expect(dict[.fixMetadata] == "Fixing")
    }

    // MARK: - Codable

    @Test("Codable round-trip for all cases")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for task in ProcessorTask.allCases {
            let data = try encoder.encode(task)
            let decoded = try decoder.decode(ProcessorTask.self, from: data)
            #expect(decoded == task)
        }
    }

    @Test("JSON encoding produces raw value string")
    func jsonEncodesRawValue() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(ProcessorTask.validate)
        let string = String(data: data, encoding: .utf8)
        #expect(string == "\"validate\"")
    }

    @Test("JSON decoding from raw value string")
    func jsonDecodesRawValue() throws {
        let decoder = JSONDecoder()
        let data = "\"extractFeatures\"".data(using: .utf8)!
        let task = try decoder.decode(ProcessorTask.self, from: data)
        #expect(task == .extractFeatures)
    }

    @Test("Codable array round-trip")
    func codableArrayRoundTrip() throws {
        let original: [ProcessorTask] = [.validate, .extractFeatures, .fixMetadata]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode([ProcessorTask].self, from: data)

        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("validate description")
    func validateDescription() {
        #expect(ProcessorTask.validate.description == "Validate")
    }

    @Test("extractFeatures description")
    func extractFeaturesDescription() {
        #expect(ProcessorTask.extractFeatures.description == "Extract Features")
    }

    @Test("fixMetadata description")
    func fixMetadataDescription() {
        #expect(ProcessorTask.fixMetadata.description == "Fix Metadata")
    }

    // MARK: - displayName

    @Test("displayName matches description for all cases")
    func displayNameMatchesDescription() {
        for task in ProcessorTask.allCases {
            #expect(task.displayName == task.description)
        }
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let task = ProcessorTask.extractFeatures

        let result = await Task {
            task
        }.value

        #expect(result == .extractFeatures)
    }

    @Test("Set of tasks is Sendable across task boundaries")
    func setSendable() async {
        let tasks: Set<ProcessorTask> = [.validate, .fixMetadata]

        let result = await Task {
            tasks
        }.value

        #expect(result.count == 2)
        #expect(result.contains(.validate))
        #expect(result.contains(.fixMetadata))
    }
}
