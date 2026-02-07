import Foundation

/// Base protocol for all validator components in the SwiftVerificar ecosystem.
///
/// Every major subsystem (parser, validator, feature extractor, metadata fixer)
/// conforms to this protocol, providing a uniform way to query component metadata.
///
/// Corresponds to the Java `Component` interface in veraPDF-library.
public protocol ValidatorComponent: Sendable {

    /// Metadata describing this component (name, version, description, provider).
    var info: ComponentInfo { get }
}
