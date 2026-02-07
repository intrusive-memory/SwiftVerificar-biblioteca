import Foundation

/// Metadata about a validator component.
///
/// Contains identifying information such as name, version, description,
/// and provider for a `ValidatorComponent`. This struct is the Swift
/// equivalent of Java's `ComponentDetails` in veraPDF-library.
///
/// All fields are immutable and the type is `Sendable`, `Equatable`,
/// `Hashable`, and `Codable` for use across concurrency boundaries
/// and serialization.
public struct ComponentInfo: Sendable, Equatable, Hashable, Codable {

    /// The human-readable name of the component.
    ///
    /// Example: `"SwiftVerificar Parser"`.
    public let name: String

    /// The semantic version string of the component.
    ///
    /// Example: `"0.1.0"`.
    public let version: String

    /// A brief description of what the component does.
    ///
    /// Example: `"PDF document parser for structure and content extraction"`.
    public let componentDescription: String

    /// The provider or author of the component.
    ///
    /// Example: `"SwiftVerificar Project"`.
    public let provider: String

    /// Creates a new `ComponentInfo`.
    ///
    /// - Parameters:
    ///   - name: The human-readable name of the component.
    ///   - version: The semantic version string.
    ///   - componentDescription: A brief description of the component's purpose.
    ///   - provider: The provider or author of the component.
    public init(
        name: String,
        version: String,
        componentDescription: String,
        provider: String
    ) {
        self.name = name
        self.version = version
        self.componentDescription = componentDescription
        self.provider = provider
    }
}

// MARK: - CustomStringConvertible

extension ComponentInfo: CustomStringConvertible {
    public var description: String {
        "\(name) v\(version) (\(provider))"
    }
}
