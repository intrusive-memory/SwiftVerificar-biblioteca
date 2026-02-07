import Foundation

/// Identifies a processing task that ``PDFProcessor`` can perform.
///
/// Each case represents a discrete phase of PDF processing. A
/// ``ProcessorConfig`` holds a `Set<ProcessorTask>` indicating
/// which phases to execute during a processing run.
///
/// ## Java-to-Swift Mapping
///
/// | Java Class     | Swift Equivalent       |
/// |---------------|------------------------|
/// | `TaskType` enum | ``ProcessorTask`` enum |
///
/// ## Example
///
/// ```swift
/// let tasks: Set<ProcessorTask> = [.validate, .extractFeatures]
/// print(tasks.contains(.fixMetadata))  // false
/// ```
public enum ProcessorTask: String, Sendable, Hashable, CaseIterable, Codable {

    /// Validate the document against a standards profile (e.g., PDF/UA-2).
    case validate

    /// Extract PDF features (fonts, color spaces, annotations, etc.).
    case extractFeatures

    /// Fix metadata in the document to improve compliance.
    case fixMetadata
}

// MARK: - CustomStringConvertible

extension ProcessorTask: CustomStringConvertible {
    public var description: String {
        switch self {
        case .validate:
            return "Validate"
        case .extractFeatures:
            return "Extract Features"
        case .fixMetadata:
            return "Fix Metadata"
        }
    }
}

// MARK: - Convenience

extension ProcessorTask {

    /// A human-readable display name for the task.
    public var displayName: String {
        description
    }
}
