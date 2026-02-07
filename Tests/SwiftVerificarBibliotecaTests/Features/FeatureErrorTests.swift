import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("FeatureError Tests")
struct FeatureErrorTests {

    // MARK: - Construction

    @Test("Stores featureType, message, and objectIdentifier")
    func fullConstruction() {
        let error = FeatureError(
            featureType: .fonts,
            message: "Cannot parse font program",
            objectIdentifier: "Helvetica-Bold"
        )

        #expect(error.featureType == .fonts)
        #expect(error.message == "Cannot parse font program")
        #expect(error.objectIdentifier == "Helvetica-Bold")
    }

    @Test("objectIdentifier defaults to nil")
    func defaultObjectIdentifier() {
        let error = FeatureError(featureType: .metadata, message: "XMP parse error")

        #expect(error.featureType == .metadata)
        #expect(error.message == "XMP parse error")
        #expect(error.objectIdentifier == nil)
    }

    @Test("Supports all feature types")
    func allFeatureTypes() {
        for featureType in FeatureType.allCases {
            let error = FeatureError(featureType: featureType, message: "test")
            #expect(error.featureType == featureType)
        }
    }

    @Test("Empty message is allowed")
    func emptyMessage() {
        let error = FeatureError(featureType: .pages, message: "")
        #expect(error.message.isEmpty)
    }

    // MARK: - Equatable

    @Test("Same errors are equal")
    func equality() {
        let a = FeatureError(featureType: .fonts, message: "error", objectIdentifier: "F1")
        let b = FeatureError(featureType: .fonts, message: "error", objectIdentifier: "F1")
        #expect(a == b)
    }

    @Test("Different feature types are not equal")
    func featureTypeInequality() {
        let a = FeatureError(featureType: .fonts, message: "error")
        let b = FeatureError(featureType: .pages, message: "error")
        #expect(a != b)
    }

    @Test("Different messages are not equal")
    func messageInequality() {
        let a = FeatureError(featureType: .fonts, message: "error A")
        let b = FeatureError(featureType: .fonts, message: "error B")
        #expect(a != b)
    }

    @Test("Different objectIdentifiers are not equal")
    func objectIdentifierInequality() {
        let a = FeatureError(featureType: .fonts, message: "e", objectIdentifier: "F1")
        let b = FeatureError(featureType: .fonts, message: "e", objectIdentifier: "F2")
        #expect(a != b)
    }

    @Test("nil vs non-nil objectIdentifier are not equal")
    func nilVsNonNilIdentifier() {
        let a = FeatureError(featureType: .fonts, message: "e", objectIdentifier: nil)
        let b = FeatureError(featureType: .fonts, message: "e", objectIdentifier: "F1")
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Equal errors have same hash")
    func hashEquality() {
        let a = FeatureError(featureType: .iccProfiles, message: "bad", objectIdentifier: "sRGB")
        let b = FeatureError(featureType: .iccProfiles, message: "bad", objectIdentifier: "sRGB")
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Can be used in a Set")
    func setUsage() {
        let e1 = FeatureError(featureType: .fonts, message: "A")
        let e2 = FeatureError(featureType: .fonts, message: "B")
        let e3 = FeatureError(featureType: .fonts, message: "A")

        let set: Set<FeatureError> = [e1, e2, e3]
        #expect(set.count == 2)
    }

    // MARK: - Error Conformance

    @Test("Conforms to Error")
    func conformsToError() {
        let error: any Error = FeatureError(featureType: .fonts, message: "test")
        #expect(error is FeatureError)
    }

    @Test("Can be thrown and caught")
    func throwAndCatch() {
        func throwingFunction() throws {
            throw FeatureError(featureType: .annotations, message: "bad annotation")
        }

        do {
            try throwingFunction()
            Issue.record("Should have thrown")
        } catch let error as FeatureError {
            #expect(error.featureType == .annotations)
            #expect(error.message == "bad annotation")
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }

    // MARK: - LocalizedError

    @Test("errorDescription includes feature type and message")
    func errorDescriptionBasic() {
        let error = FeatureError(featureType: .fonts, message: "corrupt")

        #expect(error.errorDescription?.contains("Fonts") == true)
        #expect(error.errorDescription?.contains("corrupt") == true)
    }

    @Test("errorDescription includes objectIdentifier when present")
    func errorDescriptionWithIdentifier() {
        let error = FeatureError(
            featureType: .colorSpaces,
            message: "invalid",
            objectIdentifier: "DeviceRGB"
        )

        #expect(error.errorDescription?.contains("Color Spaces") == true)
        #expect(error.errorDescription?.contains("DeviceRGB") == true)
        #expect(error.errorDescription?.contains("invalid") == true)
    }

    @Test("errorDescription without objectIdentifier omits bracket notation")
    func errorDescriptionWithoutIdentifier() {
        let error = FeatureError(featureType: .pages, message: "missing")

        let desc = error.errorDescription ?? ""
        #expect(!desc.contains("["))
    }

    // MARK: - CustomStringConvertible

    @Test("description matches errorDescription")
    func descriptionMatchesErrorDescription() {
        let error = FeatureError(featureType: .signatures, message: "invalid signature")
        #expect(error.description == error.errorDescription)
    }

    // MARK: - Codable

    @Test("Codable round-trip with objectIdentifier")
    func codableRoundTripWithIdentifier() throws {
        let original = FeatureError(
            featureType: .fonts,
            message: "bad font",
            objectIdentifier: "Helvetica"
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FeatureError.self, from: data)

        #expect(decoded == original)
    }

    @Test("Codable round-trip without objectIdentifier")
    func codableRoundTripWithoutIdentifier() throws {
        let original = FeatureError(featureType: .metadata, message: "corrupt XMP")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FeatureError.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let error = FeatureError(featureType: .embeddedFiles, message: "test")

        let result = await Task {
            error
        }.value

        #expect(result == error)
    }
}
