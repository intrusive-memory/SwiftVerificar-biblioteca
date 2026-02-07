import Foundation

/// Singleton registry for `ValidationFoundry` implementations.
///
/// The `Foundry` actor is the central point where a foundry implementation
/// is registered and retrieved. Exactly one foundry may be active at a
/// time. Calling ``register(_:)`` replaces any previously registered
/// foundry.
///
/// This is the Swift equivalent of Java's `Foundries` utility class and
/// `VeraFoundryProvider` interface, consolidated into a single actor for
/// thread-safe shared mutable state.
///
/// ## Usage
///
/// ```swift
/// // At application startup:
/// await Foundry.shared.register(SwiftFoundry())
///
/// // Later, when a component needs a parser:
/// let foundry = try await Foundry.shared.current()
/// let parser = try await foundry.createParser(for: pdfURL)
/// ```
///
/// ## Thread Safety
///
/// `Foundry` is an actor, so all access is serialized. The singleton
/// ``shared`` instance is safe to use from any concurrency context.
public actor Foundry {

    /// The shared singleton instance.
    public static let shared = Foundry()

    /// The currently registered foundry, if any.
    private var provider: (any ValidationFoundry)?

    /// Creates a new `Foundry` instance.
    ///
    /// Normally you should use ``shared`` instead. This initializer is
    /// exposed for testing purposes (e.g., creating isolated foundry
    /// instances per test).
    public init() {
        self.provider = nil
    }

    /// Register a foundry implementation.
    ///
    /// Replaces any previously registered foundry. Pass `nil` to clear
    /// the registration.
    ///
    /// - Parameter foundry: The foundry to register, or `nil` to clear.
    public func register(_ foundry: (any ValidationFoundry)?) {
        self.provider = foundry
    }

    /// Returns the currently registered foundry.
    ///
    /// - Returns: The active `ValidationFoundry`.
    /// - Throws: `VerificarError.configurationError` if no foundry
    ///   has been registered.
    public func current() throws -> any ValidationFoundry {
        guard let provider else {
            throw VerificarError.configurationError(
                reason: "No foundry registered. Call Foundry.shared.register(_:) first."
            )
        }
        return provider
    }

    /// Whether a foundry is currently registered.
    public var isRegistered: Bool {
        provider != nil
    }

    /// Convenience: register a foundry and return it.
    ///
    /// Useful for chaining or test setup:
    /// ```swift
    /// let foundry = await Foundry.shared.registerAndReturn(SwiftFoundry())
    /// ```
    ///
    /// - Parameter foundry: The foundry to register.
    /// - Returns: The same foundry that was registered.
    @discardableResult
    public func registerAndReturn<F: ValidationFoundry>(
        _ foundry: F
    ) -> F {
        self.provider = foundry
        return foundry
    }
}
