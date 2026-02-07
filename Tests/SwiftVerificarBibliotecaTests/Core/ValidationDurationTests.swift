import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("ValidationDuration Tests")
struct ValidationDurationTests {

    // MARK: - Initialization

    @Test("Init stores start and end dates")
    func initStoresDates() {
        let start = Date(timeIntervalSince1970: 1000)
        let end = Date(timeIntervalSince1970: 1005)
        let duration = ValidationDuration(start: start, end: end)

        #expect(duration.start == start)
        #expect(duration.end == end)
    }

    // MARK: - Duration Computation

    @Test("Duration computes correct positive elapsed time")
    func positiveDuration() {
        let start = Date(timeIntervalSince1970: 1000)
        let end = Date(timeIntervalSince1970: 1005)
        let duration = ValidationDuration(start: start, end: end)

        #expect(duration.duration == 5.0)
    }

    @Test("Duration is zero when start equals end")
    func zeroDuration() {
        let instant = Date(timeIntervalSince1970: 1000)
        let duration = ValidationDuration(start: instant, end: instant)

        #expect(duration.duration == 0.0)
    }

    @Test("Duration is negative when end precedes start")
    func negativeDuration() {
        let start = Date(timeIntervalSince1970: 1005)
        let end = Date(timeIntervalSince1970: 1000)
        let duration = ValidationDuration(start: start, end: end)

        #expect(duration.duration == -5.0)
    }

    @Test("Duration handles sub-second intervals")
    func subSecondDuration() {
        let start = Date(timeIntervalSince1970: 1000.0)
        let end = Date(timeIntervalSince1970: 1000.123)
        let duration = ValidationDuration(start: start, end: end)

        #expect(abs(duration.duration - 0.123) < 0.001)
    }

    @Test("Duration handles large intervals")
    func largeDuration() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 3600) // 1 hour
        let duration = ValidationDuration(start: start, end: end)

        #expect(duration.duration == 3600.0)
    }

    // MARK: - Static Factory

    @Test("zero() creates a duration with zero elapsed time")
    func zeroFactory() {
        let instant = Date(timeIntervalSince1970: 500)
        let duration = ValidationDuration.zero(at: instant)

        #expect(duration.start == instant)
        #expect(duration.end == instant)
        #expect(duration.duration == 0.0)
    }

    @Test("zero() with default parameter uses current time")
    func zeroDefaultParameter() {
        let before = Date()
        let duration = ValidationDuration.zero()
        let after = Date()

        // Start should be between before and after
        #expect(duration.start >= before)
        #expect(duration.start <= after)
        #expect(duration.duration == 0.0)
    }

    // MARK: - Equatable

    @Test("Equal durations are equal")
    func equalDurations() {
        let start = Date(timeIntervalSince1970: 1000)
        let end = Date(timeIntervalSince1970: 2000)

        let d1 = ValidationDuration(start: start, end: end)
        let d2 = ValidationDuration(start: start, end: end)

        #expect(d1 == d2)
    }

    @Test("Different start times make unequal")
    func differentStarts() {
        let end = Date(timeIntervalSince1970: 2000)
        let d1 = ValidationDuration(start: Date(timeIntervalSince1970: 1000), end: end)
        let d2 = ValidationDuration(start: Date(timeIntervalSince1970: 1001), end: end)

        #expect(d1 != d2)
    }

    @Test("Different end times make unequal")
    func differentEnds() {
        let start = Date(timeIntervalSince1970: 1000)
        let d1 = ValidationDuration(start: start, end: Date(timeIntervalSince1970: 2000))
        let d2 = ValidationDuration(start: start, end: Date(timeIntervalSince1970: 2001))

        #expect(d1 != d2)
    }

    // MARK: - Hashable

    @Test("Equal durations hash to same value")
    func hashConsistency() {
        let start = Date(timeIntervalSince1970: 1000)
        let end = Date(timeIntervalSince1970: 2000)

        let d1 = ValidationDuration(start: start, end: end)
        let d2 = ValidationDuration(start: start, end: end)

        #expect(d1.hashValue == d2.hashValue)
    }

    @Test("Can be used in a Set")
    func setMembership() {
        let d1 = ValidationDuration(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 1)
        )
        let d2 = ValidationDuration(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 1)
        )
        let d3 = ValidationDuration(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 2)
        )

        let set: Set<ValidationDuration> = [d1, d2, d3]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("Encodes and decodes to JSON")
    func jsonRoundTrip() throws {
        let original = ValidationDuration(
            start: Date(timeIntervalSince1970: 1000),
            end: Date(timeIntervalSince1970: 1005)
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ValidationDuration.self, from: data)

        #expect(original == decoded)
        #expect(decoded.duration == 5.0)
    }

    // MARK: - CustomStringConvertible

    @Test("Description shows milliseconds for sub-second durations")
    func descriptionMilliseconds() {
        let duration = ValidationDuration(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 0.5)
        )

        #expect(duration.description == "500.0 ms")
    }

    @Test("Description shows seconds for 1+ second durations")
    func descriptionSeconds() {
        let duration = ValidationDuration(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 2.5)
        )

        #expect(duration.description == "2.50 s")
    }

    @Test("Description shows zero for zero duration")
    func descriptionZero() {
        let duration = ValidationDuration.zero(at: Date(timeIntervalSince1970: 0))

        #expect(duration.description == "0.0 ms")
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let duration = ValidationDuration(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 10)
        )

        let result = await Task {
            duration.duration
        }.value

        #expect(result == 10.0)
    }
}
