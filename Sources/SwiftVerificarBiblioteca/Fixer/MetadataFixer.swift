import Foundation

/// Protocol for components that repair PDF metadata for standards compliance.
///
/// A `MetadataFixer` examines a parsed PDF document and the results of a
/// prior validation run, then writes a repaired copy of the document to
/// the specified output URL. The fixer may adjust the Info dictionary,
/// XMP metadata, or both to bring the document closer to conformance
/// with its declared profile (e.g., PDF/UA-2 or PDF/A-2b).
///
/// ## Java-to-Swift Mapping
///
/// | Java Class                | Swift Mapping                         |
/// |--------------------------|---------------------------------------|
/// | `MetadataFixer` interface | ``MetadataFixer`` protocol            |
/// | `FixerFactory`            | Consolidated into ``Foundry``         |
///
/// ## Thread Safety
///
/// All conforming types must be `Sendable`.
///
/// ## Example
///
/// ```swift
/// struct MyFixer: MetadataFixer {
///     func fix(
///         document: any ParsedDocument,
///         validationResult: ValidationResult,
///         outputURL: URL
///     ) async throws -> MetadataFixerResult {
///         // Repair metadata and write fixed copy
///         return MetadataFixerResult(status: .success, fixes: [])
///     }
/// }
/// ```
public protocol MetadataFixer: Sendable {

    /// Fixes metadata in a parsed PDF document based on validation results.
    ///
    /// The fixer inspects the validation result for metadata-related failures
    /// and applies corrections to the document's Info dictionary and/or XMP
    /// metadata. A corrected copy is written to `outputURL`.
    ///
    /// - Parameters:
    ///   - document: The parsed PDF document to fix.
    ///   - validationResult: The result of a prior validation run, used to
    ///     identify which metadata fields need correction.
    ///   - outputURL: The file URL where the fixed document should be written.
    /// - Returns: A ``MetadataFixerResult`` describing the repairs performed.
    /// - Throws: ``VerificarError`` if the fixing operation fails.
    func fix(
        document: any ParsedDocument,
        validationResult: ValidationResult,
        outputURL: URL
    ) async throws -> MetadataFixerResult
}
