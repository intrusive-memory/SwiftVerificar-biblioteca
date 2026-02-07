import Foundation

/// A single metadata fix that was applied during a repair operation.
///
/// Each `MetadataFix` records what field was changed, its original value
/// (if any), the new value that replaced it (if any), and a human-readable
/// description of the change. This provides a complete audit trail of all
/// modifications made to a PDF document's metadata.
///
/// This is the Swift equivalent of the individual fix entries tracked by
/// Java's `MetadataFixerResultImpl` in veraPDF-library, extracted into
/// its own value type for clarity and testability.
///
/// ## Example
/// ```swift
/// let fix = MetadataFix(
///     field: "dc:title",
///     originalValue: nil,
///     newValue: "Untitled Document",
///     fixDescription: "Added missing dc:title to XMP metadata"
/// )
/// print(fix.isAddition)    // true
/// print(fix.isRemoval)     // false
/// print(fix.isModification) // false
/// ```
public struct MetadataFix: Sendable, Equatable, Codable, Hashable {

    /// The metadata field that was modified.
    ///
    /// This is typically an XMP property path (e.g., "dc:title",
    /// "pdfaid:part") or an Info dictionary key (e.g., "Title", "Author").
    public let field: String

    /// The original value of the field before the fix, or `nil` if the
    /// field did not exist prior to the fix.
    public let originalValue: String?

    /// The new value of the field after the fix, or `nil` if the field
    /// was removed by the fix.
    public let newValue: String?

    /// A human-readable summary of the fix that was applied.
    public let fixDescription: String

    /// Creates a new `MetadataFix`.
    ///
    /// - Parameters:
    ///   - field: The metadata field that was modified.
    ///   - originalValue: The value before the fix. Defaults to `nil`.
    ///   - newValue: The value after the fix. Defaults to `nil`.
    ///   - fixDescription: A human-readable summary of the fix.
    public init(
        field: String,
        originalValue: String? = nil,
        newValue: String? = nil,
        fixDescription: String
    ) {
        self.field = field
        self.originalValue = originalValue
        self.newValue = newValue
        self.fixDescription = fixDescription
    }

    // MARK: - Convenience

    /// Whether this fix represents a new field being added.
    ///
    /// `true` when `originalValue` is `nil` and `newValue` is non-`nil`.
    public var isAddition: Bool {
        originalValue == nil && newValue != nil
    }

    /// Whether this fix represents an existing field being removed.
    ///
    /// `true` when `originalValue` is non-`nil` and `newValue` is `nil`.
    public var isRemoval: Bool {
        originalValue != nil && newValue == nil
    }

    /// Whether this fix represents a field's value being changed.
    ///
    /// `true` when both `originalValue` and `newValue` are non-`nil`.
    public var isModification: Bool {
        originalValue != nil && newValue != nil
    }
}

// MARK: - CustomStringConvertible

extension MetadataFix: CustomStringConvertible {
    /// A textual representation including the field name and the type of change.
    public var description: String {
        if isAddition {
            return "MetadataFix(add \(field): \(newValue ?? ""))"
        } else if isRemoval {
            return "MetadataFix(remove \(field): was \(originalValue ?? ""))"
        } else if isModification {
            return "MetadataFix(modify \(field): \(originalValue ?? "") -> \(newValue ?? ""))"
        } else {
            return "MetadataFix(\(field): no value change)"
        }
    }
}
