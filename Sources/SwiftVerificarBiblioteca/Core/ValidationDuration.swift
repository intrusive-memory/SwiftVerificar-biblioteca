import Foundation

/// Timing information for a validation operation.
///
/// Captures the wall-clock start and end times of an operation and
/// exposes the elapsed duration as a computed property. This is the
/// Swift equivalent of Java's `AuditDuration` in veraPDF-library.
///
/// The struct is `Sendable`, `Equatable`, and `Codable`.
public struct ValidationDuration: Sendable, Equatable, Codable {

    /// The instant the operation started.
    public let start: Date

    /// The instant the operation finished.
    public let end: Date

    /// The elapsed wall-clock time in seconds.
    ///
    /// Computed as `end.timeIntervalSince(start)`. Returns a negative
    /// value if `end` precedes `start`.
    public var duration: TimeInterval {
        end.timeIntervalSince(start)
    }

    /// Creates a new `ValidationDuration`.
    ///
    /// - Parameters:
    ///   - start: The instant the operation started.
    ///   - end: The instant the operation finished.
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    /// Creates a `ValidationDuration` representing zero elapsed time at the given instant.
    ///
    /// - Parameter at: The instant to use for both start and end. Defaults to `Date.now`.
    /// - Returns: A duration with zero elapsed time.
    public static func zero(at instant: Date = Date()) -> ValidationDuration {
        ValidationDuration(start: instant, end: instant)
    }
}

// MARK: - CustomStringConvertible

extension ValidationDuration: CustomStringConvertible {
    public var description: String {
        let ms = duration * 1000
        if ms < 1000 {
            return String(format: "%.1f ms", ms)
        } else {
            return String(format: "%.2f s", duration)
        }
    }
}

// MARK: - Hashable

extension ValidationDuration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(start)
        hasher.combine(end)
    }
}
