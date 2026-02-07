import Foundation
import Testing
@testable import SwiftVerificarBiblioteca

@Suite("ProcessorConfig Tests")
struct ProcessorConfigTests {

    // MARK: - Default Initialization

    @Test("Default init has default validator config")
    func defaultValidatorConfig() {
        let config = ProcessorConfig()
        #expect(config.validatorConfig == ValidatorConfig())
    }

    @Test("Default init has nil feature config")
    func defaultFeatureConfig() {
        let config = ProcessorConfig()
        #expect(config.featureConfig == nil)
    }

    @Test("Default init has nil fixer config")
    func defaultFixerConfig() {
        let config = ProcessorConfig()
        #expect(config.fixerConfig == nil)
    }

    @Test("Default init has validate-only tasks")
    func defaultTasks() {
        let config = ProcessorConfig()
        #expect(config.tasks == [.validate])
    }

    @Test("Default init has exactly one task")
    func defaultTaskCount() {
        let config = ProcessorConfig()
        #expect(config.taskCount == 1)
    }

    // MARK: - Custom Initialization

    @Test("Custom init with all tasks")
    func customInitAllTasks() {
        let config = ProcessorConfig(
            validatorConfig: ValidatorConfig(maxFailures: 10),
            featureConfig: FeatureConfig(enabledFeatures: [.fonts]),
            fixerConfig: FixerConfig(),
            tasks: Set(ProcessorTask.allCases)
        )

        #expect(config.validatorConfig.maxFailures == 10)
        #expect(config.featureConfig != nil)
        #expect(config.fixerConfig != nil)
        #expect(config.tasks.count == 3)
    }

    @Test("Custom init with empty tasks")
    func customInitEmptyTasks() {
        let config = ProcessorConfig(tasks: [])
        #expect(config.tasks.isEmpty)
    }

    @Test("Custom init with extract features only")
    func customInitExtractOnly() {
        let config = ProcessorConfig(
            featureConfig: FeatureConfig(),
            tasks: [.extractFeatures]
        )

        #expect(config.tasks == [.extractFeatures])
        #expect(config.featureConfig != nil)
    }

    @Test("Custom init with fix metadata only")
    func customInitFixOnly() {
        let config = ProcessorConfig(
            fixerConfig: FixerConfig(),
            tasks: [.fixMetadata]
        )

        #expect(config.tasks == [.fixMetadata])
        #expect(config.fixerConfig != nil)
    }

    @Test("Custom init with validate and extract")
    func customInitValidateAndExtract() {
        let config = ProcessorConfig(
            featureConfig: FeatureConfig(),
            tasks: [.validate, .extractFeatures]
        )

        #expect(config.tasks.count == 2)
        #expect(config.tasks.contains(.validate))
        #expect(config.tasks.contains(.extractFeatures))
    }

    // MARK: - Derived Properties

    @Test("shouldValidate returns true when validate is in tasks")
    func shouldValidateTrue() {
        let config = ProcessorConfig(tasks: [.validate])
        #expect(config.shouldValidate == true)
    }

    @Test("shouldValidate returns false when validate is not in tasks")
    func shouldValidateFalse() {
        let config = ProcessorConfig(tasks: [.extractFeatures])
        #expect(config.shouldValidate == false)
    }

    @Test("shouldExtractFeatures returns true when extractFeatures is in tasks")
    func shouldExtractFeaturesTrue() {
        let config = ProcessorConfig(tasks: [.extractFeatures])
        #expect(config.shouldExtractFeatures == true)
    }

    @Test("shouldExtractFeatures returns false when extractFeatures is not in tasks")
    func shouldExtractFeaturesFalse() {
        let config = ProcessorConfig(tasks: [.validate])
        #expect(config.shouldExtractFeatures == false)
    }

    @Test("shouldFixMetadata returns true when fixMetadata is in tasks")
    func shouldFixMetadataTrue() {
        let config = ProcessorConfig(tasks: [.fixMetadata])
        #expect(config.shouldFixMetadata == true)
    }

    @Test("shouldFixMetadata returns false when fixMetadata is not in tasks")
    func shouldFixMetadataFalse() {
        let config = ProcessorConfig(tasks: [.validate])
        #expect(config.shouldFixMetadata == false)
    }

    @Test("hasTasks returns true when tasks is non-empty")
    func hasTasksTrue() {
        let config = ProcessorConfig(tasks: [.validate])
        #expect(config.hasTasks == true)
    }

    @Test("hasTasks returns false when tasks is empty")
    func hasTasksFalse() {
        let config = ProcessorConfig(tasks: [])
        #expect(config.hasTasks == false)
    }

    @Test("taskCount returns correct count")
    func taskCountReturnsCorrectValue() {
        #expect(ProcessorConfig(tasks: []).taskCount == 0)
        #expect(ProcessorConfig(tasks: [.validate]).taskCount == 1)
        #expect(ProcessorConfig(tasks: [.validate, .extractFeatures]).taskCount == 2)
        #expect(ProcessorConfig(tasks: Set(ProcessorTask.allCases)).taskCount == 3)
    }

    // MARK: - Static Factories

    @Test("validateOnly has default validator config and validate task")
    func validateOnlyFactory() {
        let config = ProcessorConfig.validateOnly

        #expect(config.validatorConfig == ValidatorConfig())
        #expect(config.featureConfig == nil)
        #expect(config.fixerConfig == nil)
        #expect(config.tasks == [.validate])
    }

    @Test("all has all tasks and configs")
    func allFactory() {
        let config = ProcessorConfig.all

        #expect(config.featureConfig != nil)
        #expect(config.fixerConfig != nil)
        #expect(config.tasks.count == 3)
        #expect(config.shouldValidate)
        #expect(config.shouldExtractFeatures)
        #expect(config.shouldFixMetadata)
    }

    // MARK: - Mutability

    @Test("validatorConfig is mutable")
    func mutableValidatorConfig() {
        var config = ProcessorConfig()
        config.validatorConfig = ValidatorConfig(maxFailures: 5)
        #expect(config.validatorConfig.maxFailures == 5)
    }

    @Test("featureConfig is mutable")
    func mutableFeatureConfig() {
        var config = ProcessorConfig()
        config.featureConfig = FeatureConfig(enabledFeatures: [.fonts])
        #expect(config.featureConfig != nil)
        #expect(config.featureConfig?.enabledFeatures.contains(.fonts) == true)
    }

    @Test("fixerConfig is mutable")
    func mutableFixerConfig() {
        var config = ProcessorConfig()
        config.fixerConfig = FixerConfig.xmpOnly
        #expect(config.fixerConfig != nil)
        #expect(config.fixerConfig?.fixXMPMetadata == true)
        #expect(config.fixerConfig?.fixInfoDictionary == false)
    }

    @Test("tasks is mutable")
    func mutableTasks() {
        var config = ProcessorConfig()
        config.tasks.insert(.extractFeatures)
        #expect(config.tasks.count == 2)
        #expect(config.tasks.contains(.validate))
        #expect(config.tasks.contains(.extractFeatures))
    }

    @Test("tasks can be replaced entirely")
    func tasksReplaceable() {
        var config = ProcessorConfig()
        config.tasks = [.fixMetadata]
        #expect(config.tasks == [.fixMetadata])
    }

    // MARK: - Equatable

    @Test("Same configs are equal")
    func equality() {
        let a = ProcessorConfig()
        let b = ProcessorConfig()
        #expect(a == b)
    }

    @Test("Different validator configs are not equal")
    func inequalityValidatorConfig() {
        let a = ProcessorConfig(validatorConfig: ValidatorConfig(maxFailures: 0))
        let b = ProcessorConfig(validatorConfig: ValidatorConfig(maxFailures: 5))
        #expect(a != b)
    }

    @Test("Different feature configs are not equal")
    func inequalityFeatureConfig() {
        let a = ProcessorConfig(featureConfig: nil)
        let b = ProcessorConfig(featureConfig: FeatureConfig())
        #expect(a != b)
    }

    @Test("Different fixer configs are not equal")
    func inequalityFixerConfig() {
        let a = ProcessorConfig(fixerConfig: nil)
        let b = ProcessorConfig(fixerConfig: FixerConfig())
        #expect(a != b)
    }

    @Test("Different tasks are not equal")
    func inequalityTasks() {
        let a = ProcessorConfig(tasks: [.validate])
        let b = ProcessorConfig(tasks: [.extractFeatures])
        #expect(a != b)
    }

    @Test("all and validateOnly are not equal")
    func allNotEqualValidateOnly() {
        #expect(ProcessorConfig.all != ProcessorConfig.validateOnly)
    }

    // MARK: - CustomStringConvertible

    @Test("Description includes task names")
    func descriptionIncludesTasks() {
        let config = ProcessorConfig(tasks: [.validate])
        #expect(config.description.contains("Validate"))
    }

    @Test("Description includes multiple tasks")
    func descriptionIncludesMultipleTasks() {
        let config = ProcessorConfig(tasks: Set(ProcessorTask.allCases))
        let desc = config.description
        #expect(desc.contains("Validate"))
        #expect(desc.contains("Extract Features"))
        #expect(desc.contains("Fix Metadata"))
    }

    @Test("Description for empty tasks")
    func descriptionEmptyTasks() {
        let config = ProcessorConfig(tasks: [])
        #expect(config.description.contains("tasks"))
    }

    // MARK: - Sendable

    @Test("Is Sendable across task boundaries")
    func sendable() async {
        let config = ProcessorConfig(
            validatorConfig: ValidatorConfig(maxFailures: 3),
            featureConfig: FeatureConfig(),
            tasks: [.validate, .extractFeatures]
        )

        let result = await Task {
            config
        }.value

        #expect(result == config)
    }
}
