import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("FeatureType Tests")
struct FeatureTypeTests {

    // MARK: - Case Count

    @Test("Has exactly 19 cases")
    func caseCount() {
        #expect(FeatureType.allCases.count == 19)
    }

    // MARK: - Raw Values

    @Test("informationDictionary raw value")
    func informationDictionaryRawValue() {
        #expect(FeatureType.informationDictionary.rawValue == "informationDictionary")
    }

    @Test("metadata raw value")
    func metadataRawValue() {
        #expect(FeatureType.metadata.rawValue == "metadata")
    }

    @Test("documentSecurity raw value")
    func documentSecurityRawValue() {
        #expect(FeatureType.documentSecurity.rawValue == "documentSecurity")
    }

    @Test("signatures raw value")
    func signaturesRawValue() {
        #expect(FeatureType.signatures.rawValue == "signatures")
    }

    @Test("lowLevelInfo raw value")
    func lowLevelInfoRawValue() {
        #expect(FeatureType.lowLevelInfo.rawValue == "lowLevelInfo")
    }

    @Test("embeddedFiles raw value")
    func embeddedFilesRawValue() {
        #expect(FeatureType.embeddedFiles.rawValue == "embeddedFiles")
    }

    @Test("iccProfiles raw value")
    func iccProfilesRawValue() {
        #expect(FeatureType.iccProfiles.rawValue == "iccProfiles")
    }

    @Test("outputIntents raw value")
    func outputIntentsRawValue() {
        #expect(FeatureType.outputIntents.rawValue == "outputIntents")
    }

    @Test("outlines raw value")
    func outlinesRawValue() {
        #expect(FeatureType.outlines.rawValue == "outlines")
    }

    @Test("annotations raw value")
    func annotationsRawValue() {
        #expect(FeatureType.annotations.rawValue == "annotations")
    }

    @Test("pages raw value")
    func pagesRawValue() {
        #expect(FeatureType.pages.rawValue == "pages")
    }

    @Test("graphicsStates raw value")
    func graphicsStatesRawValue() {
        #expect(FeatureType.graphicsStates.rawValue == "graphicsStates")
    }

    @Test("colorSpaces raw value")
    func colorSpacesRawValue() {
        #expect(FeatureType.colorSpaces.rawValue == "colorSpaces")
    }

    @Test("patterns raw value")
    func patternsRawValue() {
        #expect(FeatureType.patterns.rawValue == "patterns")
    }

    @Test("shadings raw value")
    func shadingsRawValue() {
        #expect(FeatureType.shadings.rawValue == "shadings")
    }

    @Test("xObjects raw value")
    func xObjectsRawValue() {
        #expect(FeatureType.xObjects.rawValue == "xObjects")
    }

    @Test("fonts raw value")
    func fontsRawValue() {
        #expect(FeatureType.fonts.rawValue == "fonts")
    }

    @Test("properties raw value")
    func propertiesRawValue() {
        #expect(FeatureType.properties.rawValue == "properties")
    }

    @Test("interactiveFormFields raw value")
    func interactiveFormFieldsRawValue() {
        #expect(FeatureType.interactiveFormFields.rawValue == "interactiveFormFields")
    }

    // MARK: - Raw Value Round-Trip

    @Test("All cases round-trip through raw value")
    func rawValueRoundTrip() {
        for featureType in FeatureType.allCases {
            let reconstructed = FeatureType(rawValue: featureType.rawValue)
            #expect(reconstructed == featureType)
        }
    }

    @Test("Invalid raw value returns nil")
    func invalidRawValue() {
        #expect(FeatureType(rawValue: "nonExistent") == nil)
        #expect(FeatureType(rawValue: "") == nil)
        #expect(FeatureType(rawValue: "FONTS") == nil)
    }

    // MARK: - Display Name

    @Test("informationDictionary display name")
    func informationDictionaryDisplayName() {
        #expect(FeatureType.informationDictionary.displayName == "Information Dictionary")
    }

    @Test("documentSecurity display name")
    func documentSecurityDisplayName() {
        #expect(FeatureType.documentSecurity.displayName == "Document Security")
    }

    @Test("interactiveFormFields display name")
    func interactiveFormFieldsDisplayName() {
        #expect(FeatureType.interactiveFormFields.displayName == "Interactive Form Fields")
    }

    @Test("All cases have non-empty display names")
    func allDisplayNamesNonEmpty() {
        for featureType in FeatureType.allCases {
            #expect(!featureType.displayName.isEmpty)
        }
    }

    // MARK: - Description

    @Test("Description matches raw value")
    func descriptionMatchesRawValue() {
        for featureType in FeatureType.allCases {
            #expect(featureType.description == featureType.rawValue)
        }
    }

    // MARK: - Codable

    @Test("Codable round-trip for all cases")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for featureType in FeatureType.allCases {
            let data = try encoder.encode(featureType)
            let decoded = try decoder.decode(FeatureType.self, from: data)
            #expect(decoded == featureType)
        }
    }

    // MARK: - Equatable and Hashable

    @Test("Same values are equal")
    func equality() {
        #expect(FeatureType.fonts == FeatureType.fonts)
        #expect(FeatureType.pages == FeatureType.pages)
    }

    @Test("Different values are not equal")
    func inequality() {
        #expect(FeatureType.fonts != FeatureType.pages)
        #expect(FeatureType.metadata != FeatureType.signatures)
    }

    @Test("Can be used in a Set")
    func hashable() {
        let set: Set<FeatureType> = [.fonts, .pages, .fonts, .metadata]
        #expect(set.count == 3)
        #expect(set.contains(.fonts))
        #expect(set.contains(.pages))
        #expect(set.contains(.metadata))
        #expect(!set.contains(.shadings))
    }

    @Test("All cases produce unique hash values")
    func uniqueHashes() {
        let allCasesSet = Set(FeatureType.allCases)
        #expect(allCasesSet.count == 19)
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let featureType = FeatureType.fonts

        let result = await Task {
            featureType
        }.value

        #expect(result == .fonts)
    }
}
