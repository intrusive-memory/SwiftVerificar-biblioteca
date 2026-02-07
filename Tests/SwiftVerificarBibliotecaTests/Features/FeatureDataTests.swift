import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

// MARK: - Test Doubles

/// A concrete implementation of FeatureData for testing.
private struct MockFontFeatureData: FeatureData {
    let fontName: String
    let fontType: String
    let encoding: String?

    var featureType: FeatureType { .fonts }

    func toFeatureNode() -> FeatureNode {
        var children: [FeatureNode] = [
            .leaf(name: "Name", value: fontName),
            .leaf(name: "Type", value: fontType),
        ]
        if let encoding {
            children.append(.leaf(name: "Encoding", value: encoding))
        }
        return .branch(name: "Font", children: children, attributes: [:])
    }
}

/// Another concrete implementation for a different feature type.
private struct MockPageFeatureData: FeatureData {
    let pageNumber: Int
    let width: Double
    let height: Double

    var featureType: FeatureType { .pages }

    func toFeatureNode() -> FeatureNode {
        .branch(name: "Page", children: [
            .leaf(name: "Number", value: "\(pageNumber)"),
            .leaf(name: "Width", value: "\(width)"),
            .leaf(name: "Height", value: "\(height)"),
        ], attributes: ["index": "\(pageNumber - 1)"])
    }
}

/// A minimal implementation with just a leaf.
private struct MockMetadataFeatureData: FeatureData {
    let key: String
    let value: String

    var featureType: FeatureType { .metadata }

    func toFeatureNode() -> FeatureNode {
        .leaf(name: key, value: value)
    }
}

/// An implementation with nil values.
private struct MockSignatureFeatureData: FeatureData {
    var featureType: FeatureType { .signatures }

    func toFeatureNode() -> FeatureNode {
        .leaf(name: "Signature", value: nil)
    }
}

// MARK: - Tests

@Suite("FeatureData Protocol Tests")
struct FeatureDataTests {

    // MARK: - Protocol Conformance

    @Test("MockFontFeatureData conforms to FeatureData")
    func fontFeatureDataConforms() {
        let data: any FeatureData = MockFontFeatureData(
            fontName: "Helvetica",
            fontType: "Type1",
            encoding: "WinAnsi"
        )
        #expect(data.featureType == .fonts)
    }

    @Test("MockPageFeatureData conforms to FeatureData")
    func pageFeatureDataConforms() {
        let data: any FeatureData = MockPageFeatureData(
            pageNumber: 1,
            width: 612.0,
            height: 792.0
        )
        #expect(data.featureType == .pages)
    }

    @Test("MockMetadataFeatureData conforms to FeatureData")
    func metadataFeatureDataConforms() {
        let data: any FeatureData = MockMetadataFeatureData(key: "Title", value: "Test Doc")
        #expect(data.featureType == .metadata)
    }

    // MARK: - toFeatureNode Output

    @Test("Font feature data produces branch with children")
    func fontFeatureNode() {
        let data = MockFontFeatureData(
            fontName: "Helvetica-Bold",
            fontType: "Type1",
            encoding: "MacRoman"
        )
        let node = data.toFeatureNode()

        #expect(node.name == "Font")
        #expect(!node.isLeaf)
        #expect(node.children.count == 3)
        #expect(node.child(named: "Name")?.value == "Helvetica-Bold")
        #expect(node.child(named: "Type")?.value == "Type1")
        #expect(node.child(named: "Encoding")?.value == "MacRoman")
    }

    @Test("Font feature data without encoding omits Encoding child")
    func fontFeatureNodeNoEncoding() {
        let data = MockFontFeatureData(
            fontName: "ArialMT",
            fontType: "TrueType",
            encoding: nil
        )
        let node = data.toFeatureNode()

        #expect(node.children.count == 2)
        #expect(node.child(named: "Encoding") == nil)
    }

    @Test("Page feature data produces branch with attributes")
    func pageFeatureNode() {
        let data = MockPageFeatureData(pageNumber: 3, width: 595.0, height: 842.0)
        let node = data.toFeatureNode()

        #expect(node.name == "Page")
        #expect(node.children.count == 3)
        #expect(node.attributes["index"] == "2")
        #expect(node.child(named: "Number")?.value == "3")
        #expect(node.child(named: "Width")?.value == "595.0")
    }

    @Test("Metadata feature data produces leaf")
    func metadataFeatureNode() {
        let data = MockMetadataFeatureData(key: "Author", value: "John Doe")
        let node = data.toFeatureNode()

        #expect(node.isLeaf)
        #expect(node.name == "Author")
        #expect(node.value == "John Doe")
    }

    @Test("Signature feature data produces leaf with nil value")
    func signatureFeatureNode() {
        let data = MockSignatureFeatureData()
        let node = data.toFeatureNode()

        #expect(node.isLeaf)
        #expect(node.name == "Signature")
        #expect(node.value == nil)
    }

    // MARK: - Existential Usage

    @Test("Can store heterogeneous FeatureData in an array")
    func heterogeneousArray() {
        let items: [any FeatureData] = [
            MockFontFeatureData(fontName: "Courier", fontType: "Type1", encoding: nil),
            MockPageFeatureData(pageNumber: 1, width: 612, height: 792),
            MockMetadataFeatureData(key: "Creator", value: "LaTeX"),
        ]

        #expect(items.count == 3)
        #expect(items[0].featureType == .fonts)
        #expect(items[1].featureType == .pages)
        #expect(items[2].featureType == .metadata)
    }

    @Test("Can map FeatureData to FeatureNodes")
    func mapToNodes() {
        let items: [any FeatureData] = [
            MockFontFeatureData(fontName: "Courier", fontType: "Type1", encoding: nil),
            MockMetadataFeatureData(key: "Title", value: "Test"),
        ]

        let nodes = items.map { $0.toFeatureNode() }

        #expect(nodes.count == 2)
        #expect(nodes[0].name == "Font")
        #expect(nodes[1].name == "Title")
    }

    @Test("Can filter FeatureData by type")
    func filterByType() {
        let items: [any FeatureData] = [
            MockFontFeatureData(fontName: "A", fontType: "T1", encoding: nil),
            MockPageFeatureData(pageNumber: 1, width: 100, height: 200),
            MockFontFeatureData(fontName: "B", fontType: "TT", encoding: nil),
        ]

        let fonts = items.filter { $0.featureType == .fonts }
        #expect(fonts.count == 2)
    }

    // MARK: - Building Trees from FeatureData

    @Test("Can build a feature tree from multiple FeatureData instances")
    func buildTree() {
        let fontData: [any FeatureData] = [
            MockFontFeatureData(fontName: "Helvetica", fontType: "Type1", encoding: nil),
            MockFontFeatureData(fontName: "Courier", fontType: "Type1", encoding: nil),
        ]

        let fontNodes = fontData.map { $0.toFeatureNode() }
        let tree = FeatureNode.branch(
            name: "Fonts",
            children: fontNodes,
            attributes: ["count": "\(fontNodes.count)"]
        )

        #expect(tree.name == "Fonts")
        #expect(tree.children.count == 2)
        #expect(tree.attributes["count"] == "2")
    }

    // MARK: - featureType Consistency

    @Test("featureType is consistent across multiple calls")
    func featureTypeConsistent() {
        let data = MockFontFeatureData(fontName: "X", fontType: "Y", encoding: nil)
        #expect(data.featureType == data.featureType)
        #expect(data.featureType == .fonts)
    }

    @Test("Different conformers return different feature types")
    func differentConformersReturnDifferentTypes() {
        let font: any FeatureData = MockFontFeatureData(fontName: "A", fontType: "B", encoding: nil)
        let page: any FeatureData = MockPageFeatureData(pageNumber: 1, width: 100, height: 200)
        let meta: any FeatureData = MockMetadataFeatureData(key: "K", value: "V")
        let sig: any FeatureData = MockSignatureFeatureData()

        let types = [font.featureType, page.featureType, meta.featureType, sig.featureType]
        let uniqueTypes = Set(types)
        #expect(uniqueTypes.count == 4)
    }

    @Test("toFeatureNode returns a node whose name is non-empty")
    func nodeNameNonEmpty() {
        let items: [any FeatureData] = [
            MockFontFeatureData(fontName: "A", fontType: "B", encoding: nil),
            MockPageFeatureData(pageNumber: 1, width: 100, height: 200),
            MockMetadataFeatureData(key: "K", value: "V"),
            MockSignatureFeatureData(),
        ]

        for item in items {
            let node = item.toFeatureNode()
            #expect(!node.name.isEmpty)
        }
    }

    // MARK: - Sendable

    @Test("FeatureData conformers are Sendable across task boundaries")
    func sendable() async {
        let data: any FeatureData = MockFontFeatureData(
            fontName: "Arial",
            fontType: "TrueType",
            encoding: nil
        )

        let node = await Task {
            data.toFeatureNode()
        }.value

        #expect(node.name == "Font")
        #expect(node.child(named: "Name")?.value == "Arial")
    }
}
