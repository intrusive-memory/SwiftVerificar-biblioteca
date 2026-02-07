import Foundation

/// Configuration controlling how a ``MetadataFixer`` behaves.
///
/// `FixerConfig` specifies which metadata sources to fix and whether
/// to synchronize the Info dictionary with XMP metadata. All options
/// default to `true` for maximum compliance.
///
/// This is the Swift equivalent of Java's `MetadataFixerConfig` interface
/// and its implementation in veraPDF-library, consolidated into a single
/// value type.
///
/// ## Java-to-Swift Mapping
///
/// | Java Class                  | Swift Equivalent            |
/// |----------------------------|-----------------------------|
/// | `MetadataFixerConfig`       | ``FixerConfig`` struct      |
/// | `MetadataFixerConfigImpl`   | Consolidated into struct    |
///
/// ## Example
///
/// ```swift
/// // Fix everything (default)
/// let config = FixerConfig()
///
/// // Only fix XMP metadata, do not touch Info dictionary
/// var xmpOnly = FixerConfig()
/// xmpOnly.fixInfoDictionary = false
///
/// // Disable all fixing (effectively a no-op fixer)
/// let disabled = FixerConfig(
///     fixInfoDictionary: false,
///     fixXMPMetadata: false,
///     syncInfoAndXMP: false
/// )
/// ```
public struct FixerConfig: Sendable, Equatable, Hashable {

    /// Whether to fix the PDF Info dictionary.
    ///
    /// When `true`, the fixer may add, modify, or remove entries in
    /// the document's Info dictionary to satisfy profile requirements.
    ///
    /// Defaults to `true`.
    public var fixInfoDictionary: Bool

    /// Whether to fix the XMP metadata packet.
    ///
    /// When `true`, the fixer may modify the document's XMP metadata
    /// to ensure it correctly declares conformance (e.g., `pdfaid:part`,
    /// `pdfuaid:part`) and that required schemas are present.
    ///
    /// Defaults to `true`.
    public var fixXMPMetadata: Bool

    /// Whether to synchronize the Info dictionary and XMP metadata.
    ///
    /// When `true`, the fixer ensures that values present in both
    /// the Info dictionary and XMP metadata are consistent. For example,
    /// if the Info dictionary's `Title` differs from `dc:title` in XMP,
    /// the fixer reconciles them.
    ///
    /// Defaults to `true`.
    public var syncInfoAndXMP: Bool

    /// Creates a fixer configuration.
    ///
    /// - Parameters:
    ///   - fixInfoDictionary: Whether to fix the Info dictionary. Defaults to `true`.
    ///   - fixXMPMetadata: Whether to fix XMP metadata. Defaults to `true`.
    ///   - syncInfoAndXMP: Whether to synchronize Info and XMP. Defaults to `true`.
    public init(
        fixInfoDictionary: Bool = true,
        fixXMPMetadata: Bool = true,
        syncInfoAndXMP: Bool = true
    ) {
        self.fixInfoDictionary = fixInfoDictionary
        self.fixXMPMetadata = fixXMPMetadata
        self.syncInfoAndXMP = syncInfoAndXMP
    }

    // MARK: - Derived Properties

    /// Whether any fixing is enabled.
    ///
    /// Returns `true` if at least one of the three fixing options is enabled.
    public var isAnyFixingEnabled: Bool {
        fixInfoDictionary || fixXMPMetadata || syncInfoAndXMP
    }

    /// Whether all fixing options are enabled.
    ///
    /// Returns `true` when all three options are `true`.
    public var isFullFixingEnabled: Bool {
        fixInfoDictionary && fixXMPMetadata && syncInfoAndXMP
    }

    // MARK: - Static Factories

    /// A configuration with all fixing options enabled.
    ///
    /// This is equivalent to the default `init()`.
    public static let all = FixerConfig()

    /// A configuration with all fixing options disabled.
    ///
    /// Useful when the fixer should be instantiated but effectively skip
    /// all repairs.
    public static let none = FixerConfig(
        fixInfoDictionary: false,
        fixXMPMetadata: false,
        syncInfoAndXMP: false
    )

    /// A configuration that only fixes the Info dictionary.
    public static let infoOnly = FixerConfig(
        fixInfoDictionary: true,
        fixXMPMetadata: false,
        syncInfoAndXMP: false
    )

    /// A configuration that only fixes XMP metadata.
    public static let xmpOnly = FixerConfig(
        fixInfoDictionary: false,
        fixXMPMetadata: true,
        syncInfoAndXMP: false
    )
}

// MARK: - Codable

extension FixerConfig: Codable {}

// MARK: - CustomStringConvertible

extension FixerConfig: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        if fixInfoDictionary { parts.append("info") }
        if fixXMPMetadata { parts.append("xmp") }
        if syncInfoAndXMP { parts.append("sync") }
        if parts.isEmpty {
            return "FixerConfig(none)"
        }
        return "FixerConfig(\(parts.joined(separator: ", ")))"
    }
}
