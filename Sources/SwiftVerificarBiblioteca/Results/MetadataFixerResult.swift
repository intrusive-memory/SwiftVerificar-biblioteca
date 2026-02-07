import Foundation

/// The result of a metadata fixing operation on a PDF document.
///
/// `MetadataFixerResult` aggregates the overall ``RepairStatus``, the
/// individual ``MetadataFix`` entries that were applied, and optionally
/// the URL of the output file if the fixer produced a modified copy of
/// the document.
///
/// This is the Swift equivalent of Java's `MetadataFixerResult` interface
/// and `MetadataFixerResultImpl` class in veraPDF-library, consolidated
/// into a single value type.
///
/// ## Example
/// ```swift
/// let fix = MetadataFix(
///     field: "dc:title",
///     originalValue: nil,
///     newValue: "My Document",
///     fixDescription: "Added missing dc:title"
/// )
/// let result = MetadataFixerResult(
///     status: .success,
///     fixes: [fix],
///     outputURL: URL(fileURLWithPath: "/tmp/fixed.pdf")
/// )
/// print(result.fixCount)    // 1
/// print(result.hasOutput)   // true
/// ```
public struct MetadataFixerResult: Sendable, Equatable, Codable, Hashable {

    /// The overall status of the repair operation.
    public let status: RepairStatus

    /// The individual metadata fixes that were applied.
    ///
    /// This array may be empty if the operation resulted in
    /// ``RepairStatus/noFixesNeeded`` or ``RepairStatus/failed``.
    public let fixes: [MetadataFix]

    /// The URL of the output file, if the fixer produced a modified document.
    ///
    /// `nil` when no output was produced (e.g., the status is
    /// ``RepairStatus/noFixesNeeded`` or ``RepairStatus/failed``).
    public let outputURL: URL?

    /// Creates a new `MetadataFixerResult`.
    ///
    /// - Parameters:
    ///   - status: The overall repair status.
    ///   - fixes: The individual fixes applied. Defaults to an empty array.
    ///   - outputURL: The URL of the modified document. Defaults to `nil`.
    public init(
        status: RepairStatus,
        fixes: [MetadataFix] = [],
        outputURL: URL? = nil
    ) {
        self.status = status
        self.fixes = fixes
        self.outputURL = outputURL
    }

    // MARK: - Computed Properties

    /// The number of fixes that were applied.
    public var fixCount: Int {
        fixes.count
    }

    /// Whether any fixes were applied.
    public var hasFixes: Bool {
        !fixes.isEmpty
    }

    /// Whether an output file was produced.
    public var hasOutput: Bool {
        outputURL != nil
    }

    /// All unique field names that were modified.
    public var modifiedFields: Set<String> {
        Set(fixes.map(\.field))
    }

    /// Fixes filtered to only additions (fields that were added).
    public var additions: [MetadataFix] {
        fixes.filter(\.isAddition)
    }

    /// Fixes filtered to only removals (fields that were removed).
    public var removals: [MetadataFix] {
        fixes.filter(\.isRemoval)
    }

    /// Fixes filtered to only modifications (fields whose values changed).
    public var modifications: [MetadataFix] {
        fixes.filter(\.isModification)
    }

    // MARK: - Factory Methods

    /// Creates a result representing a successful repair with no fixes needed.
    ///
    /// - Returns: A `MetadataFixerResult` with status ``RepairStatus/noFixesNeeded``
    ///   and an empty fix list.
    public static func noFixesNeeded() -> MetadataFixerResult {
        MetadataFixerResult(status: .noFixesNeeded)
    }

    /// Creates a result representing a failed repair.
    ///
    /// - Returns: A `MetadataFixerResult` with status ``RepairStatus/failed``
    ///   and an empty fix list.
    public static func failed() -> MetadataFixerResult {
        MetadataFixerResult(status: .failed)
    }
}

// MARK: - CustomStringConvertible

extension MetadataFixerResult: CustomStringConvertible {
    public var description: String {
        let output = hasOutput ? " -> \(outputURL?.lastPathComponent ?? "?")" : ""
        return "MetadataFixerResult(\(status): \(fixCount) fixes\(output))"
    }
}
