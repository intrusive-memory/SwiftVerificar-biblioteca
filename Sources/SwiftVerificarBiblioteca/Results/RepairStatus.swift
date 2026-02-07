import Foundation

/// The outcome status of a metadata repair operation.
///
/// This enum represents the possible outcomes when a metadata fixer
/// attempts to repair XMP metadata and/or the Info dictionary in a
/// PDF document to achieve compliance with a validation profile.
///
/// This is the Swift equivalent of Java's `MetadataFixerResult.RepairStatus`
/// enum in veraPDF-library.
///
/// ## Usage
/// ```swift
/// let status: RepairStatus = .success
/// print(status.isSuccess)     // true
/// print(status.isTerminal)    // true
/// ```
///
/// - Note: The ``idRemoved`` case indicates that the PDF/A or PDF/UA
///   identification was removed because the document could not be made
///   compliant, effectively "un-claiming" the standard.
public enum RepairStatus: String, Sendable, Codable, CaseIterable, Equatable, Hashable {

    /// All metadata issues were successfully fixed.
    case success

    /// Some metadata issues were fixed, but others could not be resolved.
    case partialSuccess

    /// The document's metadata was already compliant; no fixes were needed.
    case noFixesNeeded

    /// The fixer could not repair the metadata.
    case failed

    /// The PDF/A or PDF/UA identification was removed because the document
    /// could not be made compliant with the claimed standard.
    case idRemoved

    // MARK: - Convenience

    /// Whether this status represents a fully successful repair.
    public var isSuccess: Bool {
        self == .success
    }

    /// Whether this status indicates at least some fixes were applied.
    ///
    /// Returns `true` for ``success`` and ``partialSuccess``.
    public var hasAppliedFixes: Bool {
        self == .success || self == .partialSuccess
    }

    /// Whether the repair operation reached a terminal state.
    ///
    /// Returns `true` for all cases except ``partialSuccess``, which
    /// indicates the operation completed but with unresolved issues.
    public var isTerminal: Bool {
        switch self {
        case .success, .noFixesNeeded, .failed, .idRemoved:
            return true
        case .partialSuccess:
            return false
        }
    }
}

// MARK: - CustomStringConvertible

extension RepairStatus: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
