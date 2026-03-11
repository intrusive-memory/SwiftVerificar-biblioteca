import Testing
@testable import SwiftVerificarBiblioteca

@Suite("SwiftVerificarBiblioteca Tests")
struct SwiftVerificarBibliotecaTests {

    @Test("Library version is set correctly")
    func versionIsSet() {
        #expect(SwiftVerificarBiblioteca.version == "0.3.0")
    }

    @Test("Library can be instantiated")
    func canInstantiate() {
        let library = SwiftVerificarBiblioteca()
        #expect(library != nil)
    }
}
