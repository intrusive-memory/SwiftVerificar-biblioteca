import Testing
import Foundation
@testable import SwiftVerificarBiblioteca
import SwiftVerificarValidationProfiles

// MARK: - Cross-Package Integration Tests

@Suite("Cross-Package Integration Tests")
struct CrossPackageIntegrationTests {

    // MARK: - 1. PDFFlavour Type Agreement

    @Suite("PDFFlavour Type Agreement")
    struct PDFFlavourTypeAgreementTests {

        @Test("PDFFlavour enum cases are accessible from SwiftVerificarValidationProfiles")
        func flavourCasesAccessible() {
            // Verify all major enum cases can be referenced from the profiles package
            let cases: [PDFFlavour] = [
                .pdfUA1, .pdfUA2,
                .pdfA1a, .pdfA1b,
                .pdfA2a, .pdfA2b, .pdfA2u,
                .pdfA3a, .pdfA3b, .pdfA3u,
                .pdfA4,
                .wcag22,
            ]
            #expect(cases.count == 12)
            // Verify each case has a distinct raw value
            let rawValues = Set(cases.map(\.rawValue))
            #expect(rawValues.count == 12)
        }

        @Test("PDFFlavour.displayName returns human-readable strings")
        func flavourDisplayNames() {
            #expect(PDFFlavour.pdfUA1.displayName == "PDF/UA-1")
            #expect(PDFFlavour.pdfUA2.displayName == "PDF/UA-2")
            #expect(PDFFlavour.pdfA1a.displayName == "PDF/A-1a")
            #expect(PDFFlavour.pdfA1b.displayName == "PDF/A-1b")
            #expect(PDFFlavour.pdfA2a.displayName == "PDF/A-2a")
            #expect(PDFFlavour.pdfA2b.displayName == "PDF/A-2b")
            #expect(PDFFlavour.pdfA2u.displayName == "PDF/A-2u")
            #expect(PDFFlavour.pdfA3a.displayName == "PDF/A-3a")
            #expect(PDFFlavour.pdfA3b.displayName == "PDF/A-3b")
            #expect(PDFFlavour.pdfA3u.displayName == "PDF/A-3u")
            #expect(PDFFlavour.pdfA4.displayName == "PDF/A-4")
            #expect(PDFFlavour.wcag22.displayName == "WCAG 2.2")
        }

        @Test("PDFFlavour isPDFA and isPDFUA computed properties work")
        func flavourComputedProperties() {
            #expect(PDFFlavour.pdfA1a.isPDFA == true)
            #expect(PDFFlavour.pdfA2b.isPDFA == true)
            #expect(PDFFlavour.pdfUA2.isPDFA == false)

            #expect(PDFFlavour.pdfUA1.isPDFUA == true)
            #expect(PDFFlavour.pdfUA2.isPDFUA == true)
            #expect(PDFFlavour.pdfA1a.isPDFUA == false)
        }

        @Test("PDFFlavour isAccessibilityRelated identifies accessibility flavours")
        func flavourAccessibilityRelated() {
            #expect(PDFFlavour.pdfUA1.isAccessibilityRelated == true)
            #expect(PDFFlavour.pdfUA2.isAccessibilityRelated == true)
            #expect(PDFFlavour.wcag22.isAccessibilityRelated == true)
            #expect(PDFFlavour.pdfA1a.isAccessibilityRelated == false)
            #expect(PDFFlavour.pdfA2b.isAccessibilityRelated == false)
        }

        @Test("PDFFlavour round-trips through ParsedDocument.flavour property type")
        func flavourRoundTripsThroughParsedDocument() {
            // Verify that the ParsedDocument protocol uses PDFFlavour? (not String?)
            // by creating a mock that stores and returns a PDFFlavour
            struct MockDocument: ParsedDocument {
                let url: URL
                let flavour: PDFFlavour?
                let pageCount: Int = 0
                let metadata: DocumentMetadata? = nil
                let hasStructureTree: Bool = false
                func objects(ofType objectType: String) -> [any ValidationObject] { [] }
            }

            let flavours: [PDFFlavour] = [.pdfUA2, .pdfA1b, .wcag22, .pdfA3u]
            for flavour in flavours {
                let doc = MockDocument(
                    url: URL(fileURLWithPath: "/tmp/test.pdf"),
                    flavour: flavour
                )
                #expect(doc.flavour == flavour)
                #expect(doc.flavour?.displayName == flavour.displayName)
            }

            // Verify nil case
            let nilDoc = MockDocument(
                url: URL(fileURLWithPath: "/tmp/test.pdf"),
                flavour: nil
            )
            #expect(nilDoc.flavour == nil)
        }

        @Test("PDFFlavour CaseIterable provides all cases")
        func flavourAllCases() {
            let allCases = PDFFlavour.allCases
            #expect(allCases.count >= 14) // At least the 14 known cases
            #expect(allCases.contains(.pdfUA2))
            #expect(allCases.contains(.pdfA1a))
            #expect(allCases.contains(.wcag22))
        }

        @Test("PDFFlavour is Codable")
        func flavourCodable() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let original = PDFFlavour.pdfUA2
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(PDFFlavour.self, from: data)
            #expect(decoded == original)
        }
    }

    // MARK: - 2. ProfileLoader Integration

    @Suite("ProfileLoader Integration")
    struct ProfileLoaderIntegrationTests {

        @Test("ProfileLoader.shared is accessible")
        func profileLoaderSharedAccessible() async {
            let count = await ProfileLoader.shared.cachedProfileCount
            // We just need this to compile and not crash
            #expect(count >= 0)
        }

        @Test("ProfileLoader.loadProfile can be called with pdfUA2")
        func loadProfilePdfUA2() async {
            // loadProfile may succeed or throw depending on whether XML
            // resources are bundled in the test target. Either outcome is
            // acceptable -- we are verifying the call path exists.
            do {
                let profile = try await ProfileLoader.shared.loadProfile(for: .pdfUA2)
                // If it succeeds, verify we get a ValidationProfile
                #expect(!profile.details.name.isEmpty)
            } catch {
                // Expected if XML resources are not bundled in the test target
                #expect(error is ProfileLoadError || error is ProfileParseError)
            }
        }

        @Test("ProfileLoader.loadProfile can be called with various flavours")
        func loadProfileVariousFlavours() async {
            let flavours: [PDFFlavour] = [.pdfUA1, .pdfA1a, .pdfA2b, .pdfA3u, .pdfA4, .wcag22]
            for flavour in flavours {
                do {
                    let profile = try await ProfileLoader.shared.loadProfile(for: flavour)
                    #expect(!profile.details.name.isEmpty)
                } catch {
                    // Either ProfileLoadError (resource not found) or
                    // ProfileParseError (malformed XML) is acceptable
                    #expect(error is ProfileLoadError || error is ProfileParseError)
                }
            }
        }

        @Test("ProfileLoader isCached returns a boolean")
        func profileLoaderIsCached() async {
            let cached = await ProfileLoader.shared.isCached(.pdfUA2)
            // Just verify the API compiles and returns a Bool
            #expect(cached == true || cached == false)
        }

        @Test("ProfileLoader cachedFlavours returns a set of PDFFlavour")
        func profileLoaderCachedFlavours() async {
            let flavours: Set<PDFFlavour> = await ProfileLoader.shared.cachedFlavours
            // Verify it returns a Set<PDFFlavour> (compilation proves the type path)
            #expect(flavours.count >= 0)
        }
    }

    // MARK: - 3. SwiftVerificar.validate() Cross-Package Path

    @Suite("SwiftVerificar Validate Cross-Package Path")
    struct SwiftVerificarValidateTests {

        @Test("validate with PDF/UA-2 throws parsingFailed for non-existent file")
        func validatePdfUA2ThrowsParsingFailed() async {
            let verificar = SwiftVerificar.shared
            let url = URL(fileURLWithPath: "/tmp/test.pdf")

            do {
                _ = try await verificar.validate(url, profile: "PDF/UA-2")
                Issue.record("Expected error to be thrown")
            } catch let error as VerificarError {
                // With the real pipeline wired, non-existent files cause parsingFailed.
                // Profile loading issues would cause configurationError.
                switch error {
                case .parsingFailed(let errorURL, _):
                    #expect(errorURL == url)
                case .configurationError:
                    // Acceptable if profile loading fails
                    break
                default:
                    Issue.record("Expected parsingFailed or configurationError, got \(error)")
                }
            } catch {
                Issue.record("Expected VerificarError, got \(error)")
            }
        }

        @Test("validate with invalid profile INVALID throws profileNotFound")
        func validateInvalidProfileThrows() async {
            let verificar = SwiftVerificar.shared
            let url = URL(fileURLWithPath: "/tmp/test.pdf")

            do {
                _ = try await verificar.validate(url, profile: "INVALID")
                Issue.record("Expected profileNotFound to be thrown")
            } catch let error as VerificarError {
                if case .profileNotFound(let name) = error {
                    #expect(name == "INVALID")
                } else {
                    Issue.record("Expected profileNotFound, got \(error)")
                }
            } catch {
                Issue.record("Expected VerificarError, got \(error)")
            }
        }

        @Test("validate with empty profile throws profileNotFound")
        func validateEmptyProfileThrows() async {
            let verificar = SwiftVerificar.shared
            let url = URL(fileURLWithPath: "/tmp/test.pdf")

            do {
                _ = try await verificar.validate(url, profile: "")
                Issue.record("Expected profileNotFound to be thrown")
            } catch let error as VerificarError {
                if case .profileNotFound(let name) = error {
                    #expect(name.isEmpty)
                } else {
                    Issue.record("Expected profileNotFound, got \(error)")
                }
            } catch {
                Issue.record("Expected VerificarError, got \(error)")
            }
        }

        @Test("validate with multiple valid profile names throws parsingFailed for non-existent file")
        func validateMultipleProfileNames() async {
            let verificar = SwiftVerificar.shared
            let url = URL(fileURLWithPath: "/tmp/test.pdf")
            let profiles = ["PDF/A-1a", "PDF/A-2b", "PDF/A-3u", "PDF/UA-1", "WCAG-2-2"]

            for profile in profiles {
                do {
                    _ = try await verificar.validate(url, profile: profile)
                    Issue.record("Expected error for profile \(profile)")
                } catch let error as VerificarError {
                    // With real pipeline, non-existent files produce parsingFailed.
                    // Profile loading issues produce configurationError.
                    switch error {
                    case .parsingFailed(let errorURL, _):
                        #expect(errorURL == url,
                                "Error URL should match input for '\(profile)'")
                    case .configurationError:
                        // Acceptable if profile loading fails
                        break
                    default:
                        Issue.record("Expected parsingFailed or configurationError for \(profile), got \(error)")
                    }
                } catch {
                    Issue.record("Unexpected error for \(profile): \(error)")
                }
            }
        }

        @Test("validateAccessibility delegates to PDF/UA-2 validation path")
        func validateAccessibilityPath() async {
            let verificar = SwiftVerificar.shared
            let url = URL(fileURLWithPath: "/tmp/test.pdf")

            do {
                _ = try await verificar.validateAccessibility(url)
                Issue.record("Expected error to be thrown")
            } catch let error as VerificarError {
                // With real pipeline, non-existent files cause parsingFailed
                switch error {
                case .parsingFailed(let errorURL, _):
                    #expect(errorURL == url)
                case .configurationError:
                    // Acceptable if profile loading fails
                    break
                default:
                    Issue.record("Expected parsingFailed or configurationError, got \(error)")
                }
            } catch {
                Issue.record("Expected VerificarError, got \(error)")
            }
        }
    }

    // MARK: - 4. PDFParser / SwiftPDFParser Type Path

    @Suite("SwiftPDFParser Cross-Package Type Path")
    struct SwiftPDFParserCrossPackageTests {

        @Test("SwiftPDFParser can be instantiated")
        func parserInstantiation() {
            let url = URL(fileURLWithPath: "/tmp/test.pdf")
            let parser = SwiftPDFParser(url: url)
            #expect(parser.url == url)
        }

        @Test("detectFlavour returns PDFFlavour? not String?")
        func detectFlavourReturnType() async {
            let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))

            // Verify the return type is PDFFlavour? via the PDFParser protocol
            do {
                let result: PDFFlavour? = try await parser.detectFlavour()
                // If it somehow succeeds, verify it is of the right type
                _ = result
            } catch let error as VerificarError {
                // Expected: parsingFailed for non-existent file
                if case .parsingFailed(_, _) = error {
                    // File doesn't exist, so parsingFailed is correct
                } else {
                    Issue.record("Expected parsingFailed, got \(error)")
                }
            } catch {
                Issue.record("Expected VerificarError, got \(error)")
            }
        }

        @Test("parse throws parsingFailed for non-existent file")
        func parseThrowsParsingFailed() async {
            let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))

            do {
                _ = try await parser.parse()
                Issue.record("Expected parsingFailed to be thrown")
            } catch let error as VerificarError {
                if case .parsingFailed(_, let reason) = error {
                    #expect(reason.contains("File not found"))
                } else {
                    Issue.record("Expected parsingFailed, got \(error)")
                }
            } catch {
                Issue.record("Expected VerificarError, got \(error)")
            }
        }

        @Test("SwiftPDFParser conforms to PDFParser protocol")
        func conformsToPDFParser() {
            let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
            let _: any PDFParser = parser
            // Compilation proves conformance
            #expect(parser.url.lastPathComponent == "test.pdf")
        }

        @Test("PDFParser protocol detectFlavour signature uses PDFFlavour")
        func protocolSignatureUsesPDFFlavour() async {
            // Verify via the existential that the protocol method
            // returns PDFFlavour? (not String?)
            let parser: any PDFParser = SwiftPDFParser(
                url: URL(fileURLWithPath: "/tmp/test.pdf")
            )
            do {
                let flavour: PDFFlavour? = try await parser.detectFlavour()
                _ = flavour // Compilation proves the type
            } catch {
                // Expected: parsingFailed for non-existent file
                #expect(error is VerificarError)
            }
        }
    }

    // MARK: - 5. XMPParser Cross-Package Import

    @Suite("XMPParser Cross-Package Integration")
    struct XMPParserCrossPackageTests {

        @Test("XMPParser can be instantiated from biblioteca")
        func parserInstantiation() {
            let parser = XMPParser()
            #expect(parser.description == "XMPParser()")
        }

        @Test("parse empty string throws XMPParserError.parsingFailed")
        func parseEmptyStringThrows() {
            let parser = XMPParser()

            do {
                _ = try parser.parse(from: "")
                Issue.record("Expected parsingFailed to be thrown")
            } catch let error as XMPParser.XMPParserError {
                if case .parsingFailed(let reason) = error {
                    #expect(reason.contains("Empty"))
                } else {
                    Issue.record("Expected parsingFailed, got \(error)")
                }
            } catch {
                Issue.record("Expected XMPParserError, got \(error)")
            }
        }

        @Test("parse valid XMP string returns XMPMetadata with real data")
        func parseValidXMPReturnsMetadata() throws {
            let parser = XMPParser()
            let xmpString = """
            <x:xmpmeta xmlns:x="adobe:ns:meta/">
              <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description rdf:about=""
                  xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/"
                  pdfaid:part="2"
                  pdfaid:conformance="u"/>
              </rdf:RDF>
            </x:xmpmeta>
            """
            let metadata: XMPMetadata = try parser.parse(from: xmpString)
            // Real parser extracts PDF/A identification from attributes
            #expect(metadata.packageCount >= 1)
            #expect(metadata.pdfaIdentification?.part == 2)
            #expect(metadata.pdfaIdentification?.conformance == "u")
        }

        @Test("XMPMetadata type is the biblioteca model type")
        func xmpMetadataIsBibliotecaType() throws {
            let parser = XMPParser()
            // Minimal XML with no rdf:Description, returns empty metadata
            let metadata = try parser.parse(from: "<x:xmpmeta/>")
            // Verify XMPMetadata properties are accessible
            #expect(metadata.isEmpty == true)
            #expect(metadata.totalPropertyCount == 0)
            #expect(metadata.namespaces.isEmpty)
            #expect(metadata.pdfaIdentification == nil)
            #expect(metadata.pdfuaIdentification == nil)
            #expect(metadata.dublinCore == nil)
        }

        @Test("parse from Data works for valid UTF-8")
        func parseFromDataWorks() throws {
            let parser = XMPParser()
            let xml = "<x:xmpmeta><rdf:RDF/></x:xmpmeta>"
            let data = Data(xml.utf8)
            let metadata = try parser.parse(from: data)
            // No rdf:Description with namespace properties, so empty
            #expect(metadata.packages.isEmpty)
        }
    }

    // MARK: - 6. PDFProcessor Cross-Package Import

    @Suite("PDFProcessor Cross-Package Integration")
    struct PDFProcessorCrossPackageTests {

        @Test("PDFProcessor can be instantiated")
        func processorInstantiation() {
            let processor = PDFProcessor()
            #expect(processor.description == "PDFProcessor()")
        }

        @Test("process returns ProcessorResult with errors for non-existent file")
        func processReturnsResult() async throws {
            let processor = PDFProcessor()
            let url = URL(fileURLWithPath: "/tmp/test.pdf")
            let config = ProcessorConfig()

            let result = try await processor.process(url: url, config: config)
            #expect(result.documentURL == url)
            // Non-existent file causes parsingFailed error
            #expect(result.hasErrors)
            #expect(result.errorCount >= 1)
        }

        @Test("process with all tasks on non-existent file returns parsingFailed")
        func processAllTasksReturnsErrors() async throws {
            let processor = PDFProcessor()
            let url = URL(fileURLWithPath: "/tmp/test.pdf")
            let config = ProcessorConfig.all

            let result = try await processor.process(url: url, config: config)
            #expect(result.documentURL == url)
            // Parsing fails first, so only 1 error (parsingFailed)
            #expect(result.errorCount == 1)
            // No actual results should be populated (parsing failed before any phase)
            #expect(result.validationResult == nil)
            #expect(result.featureResult == nil)
            #expect(result.fixerResult == nil)
        }

        @Test("process with empty tasks returns config error")
        func processEmptyTasksReturnsError() async throws {
            let processor = PDFProcessor()
            let url = URL(fileURLWithPath: "/tmp/test.pdf")
            let config = ProcessorConfig(tasks: [])

            let result = try await processor.process(url: url, config: config)
            #expect(result.hasErrors)
            #expect(result.errorCount == 1)
        }

        @Test("process error for non-existent file is parsingFailed")
        func processErrorIsParsingFailed() async throws {
            let processor = PDFProcessor()
            let url = URL(fileURLWithPath: "/tmp/test.pdf")
            let config = ProcessorConfig.all

            let result = try await processor.process(url: url, config: config)

            // With the real pipeline, non-existent files produce parsingFailed errors
            #expect(result.errorCount == 1)
            if case .parsingFailed(let errorURL, let reason) = result.errors.first {
                #expect(errorURL == url)
                #expect(reason.contains("File not found"))
            } else {
                Issue.record("Expected parsingFailed error, got: \(result.errors)")
            }
        }

        @Test("SwiftVerificar.process delegates to PDFProcessor correctly")
        func swiftVerificarProcessDelegates() async throws {
            let verificar = SwiftVerificar.shared
            let url = URL(fileURLWithPath: "/tmp/test.pdf")

            let result = try await verificar.process(url)
            #expect(result.documentURL == url)
            #expect(result.hasErrors)
        }
    }

    // MARK: - 7. Cross-Package Type Consistency

    @Suite("Cross-Package Type Consistency")
    struct TypeConsistencyTests {

        @Test("VerificarError cases are all accessible")
        func verificarErrorCases() {
            let url = URL(fileURLWithPath: "/tmp/test.pdf")

            let errors: [VerificarError] = [
                .parsingFailed(url: url, reason: "test"),
                .validationFailed(reason: "test"),
                .profileNotFound(name: "test"),
                .encryptedPDF(url: url),
                .configurationError(reason: "test"),
                .ioError(path: "/tmp", reason: "test"),
            ]

            #expect(errors.count == 6)
            // Verify each has a description
            for error in errors {
                #expect(!error.description.isEmpty)
                #expect(error.errorDescription != nil)
            }
        }

        @Test("PDFFlavour specification mapping works across packages")
        func flavourSpecificationMapping() {
            // Verify PDFFlavour.specification works (uses Specification from profiles pkg)
            #expect(PDFFlavour.pdfUA2.specification == .iso142892)
            #expect(PDFFlavour.pdfUA1.specification == .iso142891)
            #expect(PDFFlavour.pdfA1a.specification == .iso190051)
            #expect(PDFFlavour.pdfA2b.specification == .iso190052)
            #expect(PDFFlavour.pdfA3u.specification == .iso190053)
            #expect(PDFFlavour.pdfA4.specification == .iso190054)
            #expect(PDFFlavour.wcag22.specification == .wcag22)
        }

        @Test("SwiftVerificar is Sendable and can be passed across tasks")
        func swiftVerificarSendableAcrossTasks() async {
            let verificar = SwiftVerificar.shared
            let version = await Task {
                verificar.version
            }.value
            #expect(version == "0.3.0")
        }

        @Test("All integration types are Sendable")
        func allTypesSendable() async {
            // Verify key types compile as Sendable
            let parser = SwiftPDFParser(url: URL(fileURLWithPath: "/tmp/test.pdf"))
            let xmpParser = XMPParser()
            let processor = PDFProcessor()
            let verificar = SwiftVerificar.shared

            let results = await withTaskGroup(of: String.self) { group in
                group.addTask { parser.description }
                group.addTask { xmpParser.description }
                group.addTask { processor.description }
                group.addTask { verificar.version }

                var collected: [String] = []
                for await result in group {
                    collected.append(result)
                }
                return collected
            }

            #expect(results.count == 4)
        }
    }
}
