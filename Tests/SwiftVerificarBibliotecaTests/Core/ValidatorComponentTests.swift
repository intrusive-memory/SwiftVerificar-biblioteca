import Testing
@testable import SwiftVerificarBiblioteca

// MARK: - Test Double

/// A concrete type conforming to ValidatorComponent for testing purposes.
private struct MockComponent: ValidatorComponent {
    let info: ComponentInfo

    init(info: ComponentInfo) {
        self.info = info
    }
}

// MARK: - Tests

@Suite("ValidatorComponent Protocol Tests")
struct ValidatorComponentTests {

    @Test("Component exposes its info")
    func componentExposesInfo() {
        let info = ComponentInfo(
            name: "TestParser",
            version: "1.0.0",
            componentDescription: "A test parser",
            provider: "TestProvider"
        )
        let component = MockComponent(info: info)

        #expect(component.info.name == "TestParser")
        #expect(component.info.version == "1.0.0")
        #expect(component.info.componentDescription == "A test parser")
        #expect(component.info.provider == "TestProvider")
    }

    @Test("Component info equality through protocol")
    func componentInfoEquality() {
        let info1 = ComponentInfo(
            name: "Parser",
            version: "1.0.0",
            componentDescription: "Desc",
            provider: "Prov"
        )
        let info2 = ComponentInfo(
            name: "Parser",
            version: "1.0.0",
            componentDescription: "Desc",
            provider: "Prov"
        )
        let component1 = MockComponent(info: info1)
        let component2 = MockComponent(info: info2)

        #expect(component1.info == component2.info)
    }

    @Test("Different components can have different info")
    func differentComponentsDifferentInfo() {
        let parserInfo = ComponentInfo(
            name: "Parser",
            version: "1.0.0",
            componentDescription: "PDF Parser",
            provider: "SwiftVerificar"
        )
        let validatorInfo = ComponentInfo(
            name: "Validator",
            version: "2.0.0",
            componentDescription: "PDF Validator",
            provider: "SwiftVerificar"
        )
        let parser = MockComponent(info: parserInfo)
        let validator = MockComponent(info: validatorInfo)

        #expect(parser.info != validator.info)
        #expect(parser.info.name != validator.info.name)
    }

    @Test("ValidatorComponent is Sendable")
    func componentIsSendable() async {
        let info = ComponentInfo(
            name: "AsyncParser",
            version: "1.0.0",
            componentDescription: "Async parser",
            provider: "Test"
        )
        let component: any ValidatorComponent = MockComponent(info: info)

        // Use in async context to verify Sendable conformance compiles
        let capturedInfo = await Task {
            component.info
        }.value

        #expect(capturedInfo.name == "AsyncParser")
    }
}
