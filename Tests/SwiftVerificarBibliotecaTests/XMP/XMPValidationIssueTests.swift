import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("XMPValidationIssue Tests")
struct XMPValidationIssueTests {

    // MARK: - Initialization

    @Test("Init with all fields")
    func fullInit() {
        let issue = XMPValidationIssue(
            message: "Missing required field",
            property: "pdfaid:part",
            severity: .error
        )
        #expect(issue.message == "Missing required field")
        #expect(issue.property == "pdfaid:part")
        #expect(issue.severity == .error)
    }

    @Test("Init with nil property")
    func nilPropertyInit() {
        let issue = XMPValidationIssue(
            message: "General issue",
            severity: .warning
        )
        #expect(issue.property == nil)
        #expect(issue.severity == .warning)
    }

    @Test("Init with info severity")
    func infoSeverity() {
        let issue = XMPValidationIssue(
            message: "Informational note",
            severity: .info
        )
        #expect(issue.severity == .info)
    }

    // MARK: - Severity Convenience

    @Test("isError returns true for error severity")
    func isErrorTrue() {
        let issue = XMPValidationIssue(message: "msg", severity: .error)
        #expect(issue.isError)
        #expect(!issue.isWarning)
        #expect(!issue.isInfo)
    }

    @Test("isWarning returns true for warning severity")
    func isWarningTrue() {
        let issue = XMPValidationIssue(message: "msg", severity: .warning)
        #expect(!issue.isError)
        #expect(issue.isWarning)
        #expect(!issue.isInfo)
    }

    @Test("isInfo returns true for info severity")
    func isInfoTrue() {
        let issue = XMPValidationIssue(message: "msg", severity: .info)
        #expect(!issue.isError)
        #expect(!issue.isWarning)
        #expect(issue.isInfo)
    }

    // MARK: - Severity Enum

    @Test("Severity has all expected cases")
    func severityCases() {
        let all = XMPValidationIssue.Severity.allCases
        #expect(all.count == 3)
        #expect(all.contains(.error))
        #expect(all.contains(.warning))
        #expect(all.contains(.info))
    }

    @Test("Severity raw values are correct")
    func severityRawValues() {
        #expect(XMPValidationIssue.Severity.error.rawValue == "error")
        #expect(XMPValidationIssue.Severity.warning.rawValue == "warning")
        #expect(XMPValidationIssue.Severity.info.rawValue == "info")
    }

    @Test("Severity description matches raw value")
    func severityDescription() {
        #expect(XMPValidationIssue.Severity.error.description == "error")
        #expect(XMPValidationIssue.Severity.warning.description == "warning")
        #expect(XMPValidationIssue.Severity.info.description == "info")
    }

    // MARK: - Equatable

    @Test("Equal issues are equal")
    func equatable() {
        let a = XMPValidationIssue(message: "msg", property: "prop", severity: .error)
        let b = XMPValidationIssue(message: "msg", property: "prop", severity: .error)
        #expect(a == b)
    }

    @Test("Different messages are not equal")
    func differentMessages() {
        let a = XMPValidationIssue(message: "msg1", severity: .error)
        let b = XMPValidationIssue(message: "msg2", severity: .error)
        #expect(a != b)
    }

    @Test("Different severities are not equal")
    func differentSeverities() {
        let a = XMPValidationIssue(message: "msg", severity: .error)
        let b = XMPValidationIssue(message: "msg", severity: .warning)
        #expect(a != b)
    }

    @Test("Different properties are not equal")
    func differentProperties() {
        let a = XMPValidationIssue(message: "msg", property: "p1", severity: .error)
        let b = XMPValidationIssue(message: "msg", property: "p2", severity: .error)
        #expect(a != b)
    }

    @Test("Nil property vs non-nil property are not equal")
    func nilVsNonNilProperty() {
        let a = XMPValidationIssue(message: "msg", severity: .error)
        let b = XMPValidationIssue(message: "msg", property: "p", severity: .error)
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let original = XMPValidationIssue(
            message: "Missing field",
            property: "pdfaid:part",
            severity: .error
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(XMPValidationIssue.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trip with nil property")
    func codableRoundTripNilProperty() throws {
        let original = XMPValidationIssue(message: "General", severity: .warning)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(XMPValidationIssue.self, from: data)
        #expect(decoded == original)
    }

    @Test("Severity Codable round-trip")
    func severityCodable() throws {
        for severity in XMPValidationIssue.Severity.allCases {
            let data = try JSONEncoder().encode(severity)
            let decoded = try JSONDecoder().decode(XMPValidationIssue.Severity.self, from: data)
            #expect(decoded == severity)
        }
    }

    // MARK: - CustomStringConvertible

    @Test("Description with property includes severity and property")
    func descriptionWithProperty() {
        let issue = XMPValidationIssue(
            message: "Missing field",
            property: "pdfaid:part",
            severity: .error
        )
        #expect(issue.description.contains("[ERROR]"))
        #expect(issue.description.contains("pdfaid:part"))
        #expect(issue.description.contains("Missing field"))
    }

    @Test("Description without property omits property")
    func descriptionWithoutProperty() {
        let issue = XMPValidationIssue(message: "General issue", severity: .warning)
        #expect(issue.description.contains("[WARNING]"))
        #expect(issue.description.contains("General issue"))
    }

    @Test("Description for info severity")
    func descriptionInfo() {
        let issue = XMPValidationIssue(message: "Note", severity: .info)
        #expect(issue.description.contains("[INFO]"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let issue = XMPValidationIssue(message: "msg", severity: .error)
        let result = await Task { issue }.value
        #expect(result == issue)
    }

    @Test("Severity is Sendable across task boundaries")
    func severitySendable() async {
        let severity = XMPValidationIssue.Severity.error
        let result = await Task { severity }.value
        #expect(result == severity)
    }
}
