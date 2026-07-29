import Foundation

#if DEBUG
nonisolated struct DebugLaunchConfiguration: Equatable, Sendable {
    let role: DemoRole
    let scenario: AppDemoScenario
    let skipsLanding: Bool

    init(arguments: [String]) {
        role = Self.value(after: "-DemoRole", in: arguments)
            .flatMap(DemoRole.init(rawValue:))
            ?? .participant
        scenario = Self.value(after: "-DemoScenario", in: arguments)
            .flatMap(Self.scenario(named:))
            ?? AppDemoScenario.defaultScenario(for: role.userRole)
        skipsLanding = arguments.contains("-SkipDemoLanding")
    }

    private static func value(
        after key: String,
        in arguments: [String]
    ) -> String? {
        guard let index = arguments.firstIndex(of: key) else {
            return nil
        }
        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else {
            return nil
        }
        return arguments[valueIndex]
    }

    private static func scenario(named value: String) -> AppDemoScenario? {
        switch value {
        case "participant_active":
            .participantActive
        case "admin_draft_editor":
            .adminDraftCMS
        case "error":
            .repositoryError
        default:
            AppDemoScenario(rawValue: value)
        }
    }
}
#endif
