import Foundation

/// Configuration controlling how a ``PDFValidator`` behaves during
/// a validation run.
///
/// `ValidatorConfig` consolidates Java's `ValidatorConfig` interface,
/// `ValidatorConfigImpl`, and `ValidatorConfigBuilder` into a single
/// Swift struct with sensible defaults. Callers can create an instance
/// with the default initializer and selectively override properties.
///
/// ## Java-to-Swift Mapping
///
/// | Java Class                | Swift Equivalent           |
/// |--------------------------|---------------------------|
/// | `ValidatorConfig`         | `ValidatorConfig` struct   |
/// | `ValidatorConfigImpl`     | Consolidated into struct   |
/// | `ValidatorConfigBuilder`  | Swift memberwise init      |
///
/// ## Usage
///
/// ```swift
/// // Defaults: unlimited failures, no passed recording, no logging
/// let defaultConfig = ValidatorConfig()
///
/// // Fast-fail after 10 failures, log progress
/// let fastFail = ValidatorConfig(maxFailures: 10, logProgress: true)
///
/// // Record everything with a 60-second timeout
/// var detailed = ValidatorConfig()
/// detailed.recordPassedAssertions = true
/// detailed.timeout = 60
/// ```
public struct ValidatorConfig: Sendable, Equatable, Hashable, Codable {

    /// Maximum number of failures before the validator stops.
    ///
    /// A value of `0` means the validator runs to completion regardless
    /// of how many failures are encountered. This replaces the separate
    /// `FastFailValidator` class in the Java codebase.
    public var maxFailures: Int

    /// Whether to record passed assertions in the result.
    ///
    /// When `false` (the default), only failed and unknown assertions
    /// appear in the ``ValidationResult``. Set to `true` for complete
    /// audit trails or reporting.
    public var recordPassedAssertions: Bool

    /// Whether to log progress information during validation.
    ///
    /// When `true`, the validator may emit diagnostic messages
    /// (via `os.Logger`) as it processes objects and rules.
    public var logProgress: Bool

    /// Maximum time in seconds allowed for the validation run.
    ///
    /// If the timeout elapses before validation completes, the
    /// validator stops and returns a partial result. A value of
    /// `nil` means no timeout (unlimited time).
    public var timeout: TimeInterval?

    /// Whether to evaluate rules in parallel where possible.
    ///
    /// When `true`, the validator may use structured concurrency
    /// to evaluate independent rule groups concurrently. When
    /// `false`, rules are evaluated sequentially.
    public var parallelValidation: Bool

    /// Creates a new `ValidatorConfig` with the given settings.
    ///
    /// All parameters have sensible defaults so callers can create
    /// a default configuration with `ValidatorConfig()` and
    /// customize individual properties as needed.
    ///
    /// - Parameters:
    ///   - maxFailures: Maximum failures before stopping. Defaults to `0` (unlimited).
    ///   - recordPassedAssertions: Whether to include passed assertions. Defaults to `false`.
    ///   - logProgress: Whether to log progress. Defaults to `false`.
    ///   - timeout: Maximum validation time in seconds. Defaults to `nil` (no timeout).
    ///   - parallelValidation: Whether to evaluate rules in parallel. Defaults to `true`.
    public init(
        maxFailures: Int = 0,
        recordPassedAssertions: Bool = false,
        logProgress: Bool = false,
        timeout: TimeInterval? = nil,
        parallelValidation: Bool = true
    ) {
        self.maxFailures = maxFailures
        self.recordPassedAssertions = recordPassedAssertions
        self.logProgress = logProgress
        self.timeout = timeout
        self.parallelValidation = parallelValidation
    }

    // MARK: - Derived Properties

    /// Whether the validator should stop after a fixed number of failures.
    ///
    /// Returns `true` when ``maxFailures`` is greater than zero.
    public var isFastFail: Bool {
        maxFailures > 0
    }

    /// Whether a timeout is configured.
    ///
    /// Returns `true` when ``timeout`` is non-nil and positive.
    public var hasTimeout: Bool {
        if let timeout {
            return timeout > 0
        }
        return false
    }
}

// MARK: - CustomStringConvertible

extension ValidatorConfig: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        parts.append("maxFailures=\(maxFailures)")
        if recordPassedAssertions { parts.append("recordPassed") }
        if logProgress { parts.append("logProgress") }
        if let timeout { parts.append("timeout=\(timeout)s") }
        parts.append("parallel=\(parallelValidation)")
        return "ValidatorConfig(\(parts.joined(separator: ", ")))"
    }
}
