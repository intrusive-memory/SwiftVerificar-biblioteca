import Testing
import Foundation
@testable import SwiftVerificarBiblioteca

// MARK: - SwiftPDFParser Tests

@Suite("SwiftPDFParser Tests")
struct SwiftPDFParserTests {

    // MARK: - Initialization

    @Test("Stores URL from initializer")
    func storesURL() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let parser = SwiftPDFParser(url: url)
        #expect(parser.url == url)
    }

    @Test("Accepts various URL paths")
    func variousURLPaths() {
        let paths = [
            "/tmp/test.pdf",
            "/Users/test/Documents/report.pdf",
            "/var/folders/cache/document.pdf",
            "/tmp/my documents/spaced file.pdf",
        ]
        for path in paths {
            let url = URL(fileURLWithPath: path)
            let parser = SwiftPDFParser(url: url)
            #expect(parser.url == url)
        }
    }

    @Test("URL last path component is accessible")
    func urlLastPathComponent() {
        let url = URL(fileURLWithPath: "/tmp/important.pdf")
        let parser = SwiftPDFParser(url: url)
        #expect(parser.url.lastPathComponent == "important.pdf")
    }

    // MARK: - PDFParser Conformance

    @Test("Conforms to PDFParser protocol")
    func conformsToPDFParser() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        let _: any PDFParser = parser
        // Compilation proves conformance
        #expect(parser.url.lastPathComponent == "test.pdf")
    }

    // MARK: - parse()

    @Test("parse() throws configurationError")
    func parseThrowsConfigurationError() async {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        await #expect(throws: VerificarError.self) {
            _ = try await parser.parse()
        }
    }

    @Test("parse() throws specific configurationError about parser integration")
    func parseThrowsSpecificError() async {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        do {
            _ = try await parser.parse()
            Issue.record("Expected configurationError to be thrown")
        } catch let error as VerificarError {
            switch error {
            case .configurationError(let reason):
                #expect(reason.contains("parser"))
                #expect(reason.contains("reconciliation"))
            default:
                Issue.record("Expected configurationError, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(error)")
        }
    }

    @Test("parse() throws for any URL")
    func parseThrowsForAnyURL() async {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.pdf"),
            URL(fileURLWithPath: "/tmp/b.pdf"),
            URL(fileURLWithPath: "/Users/test/c.pdf"),
        ]
        for url in urls {
            let parser = SwiftPDFParser(url: url)
            await #expect(throws: VerificarError.self) {
                _ = try await parser.parse()
            }
        }
    }

    // MARK: - detectFlavour()

    @Test("detectFlavour() throws configurationError")
    func detectFlavourThrowsConfigurationError() async {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        await #expect(throws: VerificarError.self) {
            _ = try await parser.detectFlavour()
        }
    }

    @Test("detectFlavour() throws specific configurationError about flavour detection")
    func detectFlavourThrowsSpecificError() async {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        do {
            _ = try await parser.detectFlavour()
            Issue.record("Expected configurationError to be thrown")
        } catch let error as VerificarError {
            switch error {
            case .configurationError(let reason):
                #expect(reason.contains("flavour"))
                #expect(reason.contains("reconciliation"))
            default:
                Issue.record("Expected configurationError, got \(error)")
            }
        } catch {
            Issue.record("Expected VerificarError, got \(error)")
        }
    }

    @Test("detectFlavour() throws for any URL")
    func detectFlavourThrowsForAnyURL() async {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.pdf"),
            URL(fileURLWithPath: "/tmp/b.pdf"),
        ]
        for url in urls {
            let parser = SwiftPDFParser(url: url)
            await #expect(throws: VerificarError.self) {
                _ = try await parser.detectFlavour()
            }
        }
    }

    // MARK: - ValidatorComponent Conformance

    @Test("Conforms to ValidatorComponent protocol")
    func conformsToValidatorComponent() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        let component: any ValidatorComponent = parser
        #expect(component.info.name == "SwiftPDFParser")
    }

    @Test("ComponentInfo has correct name")
    func componentInfoName() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        #expect(parser.info.name == "SwiftPDFParser")
    }

    @Test("ComponentInfo has correct version")
    func componentInfoVersion() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        #expect(parser.info.version == SwiftVerificarBiblioteca.version)
    }

    @Test("ComponentInfo description includes filename")
    func componentInfoDescription() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/report.pdf"))
        #expect(parser.info.componentDescription.contains("report.pdf"))
    }

    @Test("ComponentInfo has correct provider")
    func componentInfoProvider() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        #expect(parser.info.provider == "SwiftVerificar Project")
    }

    // MARK: - Equatable

    @Test("Two parsers with same URL are equal")
    func equatable() {
        let url = URL(fileURLWithPath: "/tmp/same.pdf")
        let a = SwiftPDFParser(url: url)
        let b = SwiftPDFParser(url: url)
        #expect(a == b)
    }

    @Test("Parsers with different URLs are not equal")
    func notEqual() {
        let a = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/a.pdf"))
        let b = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/b.pdf"))
        #expect(a != b)
    }

    @Test("Equality is symmetric")
    func equalitySymmetric() {
        let url = URL(fileURLWithPath: "/tmp/sym.pdf")
        let a = SwiftPDFParser(url: url)
        let b = SwiftPDFParser(url: url)
        #expect(a == b)
        #expect(b == a)
    }

    @Test("Equality is reflexive")
    func equalityReflexive() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/refl.pdf"))
        #expect(parser == parser)
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let url = URL(fileURLWithPath: "/tmp/sendable.pdf")
        let parser = SwiftPDFParser(url: url)
        let result = await Task {
            parser.url
        }.value
        #expect(result == url)
    }

    @Test("Can be passed to concurrent tasks")
    func concurrentSendable() async {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/concurrent.pdf"))
        let urls = await withTaskGroup(of: URL.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    parser.url
                }
            }
            var results: [URL] = []
            for await url in group {
                results.append(url)
            }
            return results
        }
        #expect(urls.count == 5)
        for url in urls {
            #expect(url == parser.url)
        }
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes filename")
    func descriptionIncludesFilename() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/myfile.pdf"))
        #expect(parser.description.contains("myfile.pdf"))
    }

    @Test("Description includes SwiftPDFParser prefix")
    func descriptionPrefix() {
        let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
        #expect(parser.description.hasPrefix("SwiftPDFParser("))
    }

    // MARK: - Existential Usage

    @Test("Can be used as existential PDFParser")
    func existentialPDFParser() async {
        let parser: any PDFParser = SwiftPDFParser(
            url: URL(fileURLWithPath: "/tmp/test.pdf")
        )
        #expect(parser.url.lastPathComponent == "test.pdf")
        await #expect(throws: VerificarError.self) {
            _ = try await parser.parse()
        }
    }

    @Test("Can be used as existential ValidatorComponent")
    func existentialValidatorComponent() {
        let parser: any ValidatorComponent = SwiftPDFParser(
            url: URL(fileURLWithPath: "/tmp/test.pdf")
        )
        #expect(parser.info.name == "SwiftPDFParser")
    }

    @Test("Can be stored in array of PDFParser existentials")
    func existentialArray() {
        let parsers: [any PDFParser] = [
            SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/a.pdf")),
            SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/b.pdf")),
        ]
        #expect(parsers.count == 2)
        #expect(parsers[0].url.lastPathComponent == "a.pdf")
        #expect(parsers[1].url.lastPathComponent == "b.pdf")
    }
}
