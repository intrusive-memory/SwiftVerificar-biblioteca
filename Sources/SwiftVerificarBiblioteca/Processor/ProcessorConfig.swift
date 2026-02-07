import Foundation

/// Configuration for a ``PDFProcessor`` run.
///
/// `ProcessorConfig` bundles together the configurations for each
/// processing phase (validation, feature extraction, metadata fixing)
/// and specifies which tasks to perform via a set of ``ProcessorTask``
/// values.
///
/// ## Java-to-Swift Mapping
///
/// | Java Class          | Swift Equivalent            |
/// |--------------------|---------------------------- |
/// | `ProcessorConfig`   | ``ProcessorConfig`` struct  |
/// | `ProcessorConfigImpl` | Consolidated into struct  |
///
/// ## Example
///
/// ```swift
/// // Validate only (default)
/// let config = ProcessorConfig()
///
/// // Validate and extract features
/// var fullConfig = ProcessorConfig()
/// fullConfig.tasks = [.validate, .extractFeatures]
/// fullConfig.featureConfig = FeatureConfig(enabledFeatures: [.fonts, .pages])
///
/// // Everything: validate, extract features, and fix metadata
/// var everything = ProcessorConfig()
/// everything.tasks = [.validate, .extractFeatures, .fixMetadata]
/// everything.featureConfig = FeatureConfig()
/// everything.fixerConfig = FixerConfig()
/// ```
public struct ProcessorConfig: Sendable, Equatable {

    /// Configuration for the validation phase.
    ///
    /// Controls validator behavior such as max failures, timeout,
    /// and whether to record passed assertions. Always present
    /// because validation is the primary use case.
    public var validatorConfig: ValidatorConfig

    /// Configuration for the feature extraction phase.
    ///
    /// When non-`nil`, specifies which features to extract.
    /// When `nil` and `tasks` contains `.extractFeatures`,
    /// the processor uses a default ``FeatureConfig``.
    public var featureConfig: FeatureConfig?

    /// Configuration for the metadata fixing phase.
    ///
    /// When non-`nil`, specifies how to fix metadata.
    /// When `nil` and `tasks` contains `.fixMetadata`,
    /// the processor uses a default ``FixerConfig``.
    public var fixerConfig: FixerConfig?

    /// The set of processing tasks to perform.
    ///
    /// By default, only validation is performed. Add
    /// `.extractFeatures` or `.fixMetadata` to include those
    /// phases in the processing pipeline.
    public var tasks: Set<ProcessorTask>

    /// Creates a processor configuration.
    ///
    /// - Parameters:
    ///   - validatorConfig: Validation configuration. Defaults to a default ``ValidatorConfig``.
    ///   - featureConfig: Feature extraction configuration. Defaults to `nil`.
    ///   - fixerConfig: Metadata fixer configuration. Defaults to `nil`.
    ///   - tasks: Tasks to perform. Defaults to `[.validate]`.
    public init(
        validatorConfig: ValidatorConfig = .init(),
        featureConfig: FeatureConfig? = nil,
        fixerConfig: FixerConfig? = nil,
        tasks: Set<ProcessorTask> = [.validate]
    ) {
        self.validatorConfig = validatorConfig
        self.featureConfig = featureConfig
        self.fixerConfig = fixerConfig
        self.tasks = tasks
    }

    // MARK: - Derived Properties

    /// Whether the configuration includes a validation task.
    public var shouldValidate: Bool {
        tasks.contains(.validate)
    }

    /// Whether the configuration includes a feature extraction task.
    public var shouldExtractFeatures: Bool {
        tasks.contains(.extractFeatures)
    }

    /// Whether the configuration includes a metadata fixing task.
    public var shouldFixMetadata: Bool {
        tasks.contains(.fixMetadata)
    }

    /// Whether any tasks are configured.
    public var hasTasks: Bool {
        !tasks.isEmpty
    }

    /// The number of tasks to perform.
    public var taskCount: Int {
        tasks.count
    }

    // MARK: - Static Factories

    /// A configuration that only performs validation with default settings.
    public static let validateOnly = ProcessorConfig()

    /// A configuration that performs all three tasks with default settings.
    public static let all = ProcessorConfig(
        featureConfig: FeatureConfig(),
        fixerConfig: FixerConfig(),
        tasks: Set(ProcessorTask.allCases)
    )
}

// MARK: - CustomStringConvertible

extension ProcessorConfig: CustomStringConvertible {
    public var description: String {
        let taskNames = tasks
            .sorted(by: { $0.rawValue < $1.rawValue })
            .map(\.displayName)
            .joined(separator: ", ")
        return "ProcessorConfig(tasks: [\(taskNames)])"
    }
}
