import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("FeatureNode Tests")
struct FeatureNodeTests {

    // MARK: - Leaf Construction

    @Test("Leaf with value stores name and value")
    func leafWithValue() {
        let node = FeatureNode.leaf(name: "Title", value: "My Document")

        #expect(node.name == "Title")
        #expect(node.value == "My Document")
        #expect(node.isLeaf)
    }

    @Test("Leaf with nil value stores name and nil")
    func leafWithNilValue() {
        let node = FeatureNode.leaf(name: "Empty", value: nil)

        #expect(node.name == "Empty")
        #expect(node.value == nil)
        #expect(node.isLeaf)
    }

    @Test("Leaf has empty children")
    func leafHasEmptyChildren() {
        let node = FeatureNode.leaf(name: "X", value: "Y")
        #expect(node.children.isEmpty)
    }

    @Test("Leaf has empty attributes")
    func leafHasEmptyAttributes() {
        let node = FeatureNode.leaf(name: "X", value: "Y")
        #expect(node.attributes.isEmpty)
    }

    // MARK: - Branch Construction

    @Test("Branch stores name, children, and attributes")
    func branchConstruction() {
        let children: [FeatureNode] = [
            .leaf(name: "A", value: "1"),
            .leaf(name: "B", value: "2"),
        ]
        let attributes = ["count": "2"]
        let node = FeatureNode.branch(name: "Group", children: children, attributes: attributes)

        #expect(node.name == "Group")
        #expect(node.children.count == 2)
        #expect(node.attributes == ["count": "2"])
        #expect(!node.isLeaf)
    }

    @Test("Branch with empty children")
    func branchEmptyChildren() {
        let node = FeatureNode.branch(name: "Empty", children: [], attributes: [:])

        #expect(node.name == "Empty")
        #expect(node.children.isEmpty)
        #expect(!node.isLeaf)
    }

    @Test("Branch value is nil")
    func branchValueIsNil() {
        let node = FeatureNode.branch(name: "Group", children: [], attributes: [:])
        #expect(node.value == nil)
    }

    // MARK: - Nested Tree

    @Test("Deeply nested tree")
    func deeplyNestedTree() {
        let tree = FeatureNode.branch(
            name: "Root",
            children: [
                .branch(name: "Level1", children: [
                    .branch(name: "Level2", children: [
                        .leaf(name: "DeepLeaf", value: "deep"),
                    ], attributes: [:]),
                ], attributes: [:]),
            ],
            attributes: [:]
        )

        #expect(tree.name == "Root")
        #expect(tree.children.count == 1)
        #expect(tree.children[0].children[0].children[0].value == "deep")
    }

    // MARK: - nodeCount

    @Test("Leaf has nodeCount of 1")
    func leafNodeCount() {
        let node = FeatureNode.leaf(name: "X", value: "Y")
        #expect(node.nodeCount == 1)
    }

    @Test("Branch with two leaves has nodeCount of 3")
    func branchNodeCount() {
        let node = FeatureNode.branch(name: "Root", children: [
            .leaf(name: "A", value: "1"),
            .leaf(name: "B", value: "2"),
        ], attributes: [:])
        #expect(node.nodeCount == 3)
    }

    @Test("Empty branch has nodeCount of 1")
    func emptyBranchNodeCount() {
        let node = FeatureNode.branch(name: "Empty", children: [], attributes: [:])
        #expect(node.nodeCount == 1)
    }

    @Test("Nested tree nodeCount")
    func nestedNodeCount() {
        let tree = FeatureNode.branch(name: "R", children: [
            .branch(name: "A", children: [
                .leaf(name: "X", value: "1"),
                .leaf(name: "Y", value: "2"),
            ], attributes: [:]),
            .leaf(name: "Z", value: "3"),
        ], attributes: [:])
        // R(1) + A(1) + X(1) + Y(1) + Z(1) = 5
        #expect(tree.nodeCount == 5)
    }

    // MARK: - depth

    @Test("Leaf has depth 0")
    func leafDepth() {
        #expect(FeatureNode.leaf(name: "X", value: "Y").depth == 0)
    }

    @Test("Branch with leaves has depth 1")
    func shallowBranchDepth() {
        let node = FeatureNode.branch(name: "R", children: [
            .leaf(name: "A", value: "1"),
        ], attributes: [:])
        #expect(node.depth == 1)
    }

    @Test("Empty branch has depth 0")
    func emptyBranchDepth() {
        let node = FeatureNode.branch(name: "R", children: [], attributes: [:])
        #expect(node.depth == 0)
    }

    @Test("Two-level nesting has depth 2")
    func twoLevelDepth() {
        let tree = FeatureNode.branch(name: "R", children: [
            .branch(name: "A", children: [
                .leaf(name: "X", value: "1"),
            ], attributes: [:]),
        ], attributes: [:])
        #expect(tree.depth == 2)
    }

    // MARK: - child(named:)

    @Test("child(named:) finds existing child")
    func childNamedFound() {
        let node = FeatureNode.branch(name: "Root", children: [
            .leaf(name: "Alpha", value: "a"),
            .leaf(name: "Beta", value: "b"),
        ], attributes: [:])

        let found = node.child(named: "Beta")
        #expect(found?.value == "b")
    }

    @Test("child(named:) returns nil for missing child")
    func childNamedMissing() {
        let node = FeatureNode.branch(name: "Root", children: [
            .leaf(name: "Alpha", value: "a"),
        ], attributes: [:])

        #expect(node.child(named: "Gamma") == nil)
    }

    @Test("child(named:) returns nil for leaf")
    func childNamedOnLeaf() {
        let node = FeatureNode.leaf(name: "Leaf", value: "v")
        #expect(node.child(named: "anything") == nil)
    }

    @Test("child(named:) returns first match when duplicates exist")
    func childNamedFirstMatch() {
        let node = FeatureNode.branch(name: "Root", children: [
            .leaf(name: "Item", value: "first"),
            .leaf(name: "Item", value: "second"),
        ], attributes: [:])

        let found = node.child(named: "Item")
        #expect(found?.value == "first")
    }

    // MARK: - allLeafValues

    @Test("allLeafValues from single leaf with value")
    func singleLeafValues() {
        let node = FeatureNode.leaf(name: "X", value: "hello")
        #expect(node.allLeafValues == ["hello"])
    }

    @Test("allLeafValues from leaf with nil value returns empty")
    func nilLeafValues() {
        let node = FeatureNode.leaf(name: "X", value: nil)
        #expect(node.allLeafValues.isEmpty)
    }

    @Test("allLeafValues from branch collects all descendant leaf values")
    func branchLeafValues() {
        let tree = FeatureNode.branch(name: "R", children: [
            .leaf(name: "A", value: "1"),
            .branch(name: "B", children: [
                .leaf(name: "C", value: "2"),
                .leaf(name: "D", value: nil),
                .leaf(name: "E", value: "3"),
            ], attributes: [:]),
        ], attributes: [:])

        #expect(tree.allLeafValues == ["1", "2", "3"])
    }

    @Test("allLeafValues from empty branch returns empty")
    func emptyBranchLeafValues() {
        let node = FeatureNode.branch(name: "R", children: [], attributes: [:])
        #expect(node.allLeafValues.isEmpty)
    }

    // MARK: - Equatable

    @Test("Same leaves are equal")
    func leafEquality() {
        let a = FeatureNode.leaf(name: "X", value: "Y")
        let b = FeatureNode.leaf(name: "X", value: "Y")
        #expect(a == b)
    }

    @Test("Leaves with different values are not equal")
    func leafInequality() {
        let a = FeatureNode.leaf(name: "X", value: "Y")
        let b = FeatureNode.leaf(name: "X", value: "Z")
        #expect(a != b)
    }

    @Test("Leaves with different names are not equal")
    func leafNameInequality() {
        let a = FeatureNode.leaf(name: "A", value: "Y")
        let b = FeatureNode.leaf(name: "B", value: "Y")
        #expect(a != b)
    }

    @Test("Leaf and branch are not equal")
    func leafBranchInequality() {
        let leaf = FeatureNode.leaf(name: "X", value: nil)
        let branch = FeatureNode.branch(name: "X", children: [], attributes: [:])
        #expect(leaf != branch)
    }

    @Test("Same branches are equal")
    func branchEquality() {
        let a = FeatureNode.branch(name: "R", children: [
            .leaf(name: "X", value: "1"),
        ], attributes: ["k": "v"])
        let b = FeatureNode.branch(name: "R", children: [
            .leaf(name: "X", value: "1"),
        ], attributes: ["k": "v"])
        #expect(a == b)
    }

    @Test("Branches with different attributes are not equal")
    func branchAttributeInequality() {
        let a = FeatureNode.branch(name: "R", children: [], attributes: ["a": "1"])
        let b = FeatureNode.branch(name: "R", children: [], attributes: ["a": "2"])
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("Leaf Codable round-trip")
    func leafCodableRoundTrip() throws {
        let original = FeatureNode.leaf(name: "Title", value: "Test")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FeatureNode.self, from: data)

        #expect(decoded == original)
    }

    @Test("Leaf with nil value Codable round-trip")
    func leafNilCodableRoundTrip() throws {
        let original = FeatureNode.leaf(name: "Empty", value: nil)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FeatureNode.self, from: data)

        #expect(decoded == original)
    }

    @Test("Branch Codable round-trip")
    func branchCodableRoundTrip() throws {
        let original = FeatureNode.branch(name: "Root", children: [
            .leaf(name: "A", value: "1"),
            .leaf(name: "B", value: "2"),
        ], attributes: ["count": "2"])
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FeatureNode.self, from: data)

        #expect(decoded == original)
    }

    @Test("Nested tree Codable round-trip")
    func nestedCodableRoundTrip() throws {
        let original = FeatureNode.branch(name: "Doc", children: [
            .branch(name: "Fonts", children: [
                .leaf(name: "Font", value: "Helvetica"),
                .leaf(name: "Font", value: "Times"),
            ], attributes: ["count": "2"]),
            .leaf(name: "PageCount", value: "10"),
        ], attributes: ["version": "1.7"])
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FeatureNode.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - CustomStringConvertible

    @Test("Leaf with value description")
    func leafDescription() {
        let node = FeatureNode.leaf(name: "Title", value: "Hello")
        #expect(node.description == "Title: Hello")
    }

    @Test("Leaf without value description")
    func leafNilDescription() {
        let node = FeatureNode.leaf(name: "Empty", value: nil)
        #expect(node.description == "Empty")
    }

    @Test("Branch description includes child count")
    func branchDescription() {
        let node = FeatureNode.branch(name: "Fonts", children: [
            .leaf(name: "F1", value: "Helvetica"),
            .leaf(name: "F2", value: "Times"),
        ], attributes: [:])
        #expect(node.description == "Fonts [2 children]")
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let node = FeatureNode.branch(name: "Root", children: [
            .leaf(name: "X", value: "Y"),
        ], attributes: [:])

        let result = await Task {
            node
        }.value

        #expect(result == node)
    }
}
