import Foundation

#if DEBUG
nonisolated struct DebugLaunchConfiguration: Equatable, Sendable {
    let role: DemoRole
    let scenario: AppDemoScenario
    let skipsLanding: Bool

    init(arguments: [String]) {
        let roleValue = Self.value(after: "-DemoRole", in: arguments)
        let parsedRole = roleValue
            .flatMap(DemoRole.init(rawValue:))
            ?? .guest
        let scenarioValue = Self.value(
            after: "-DemoScenario",
            in: arguments
        )
        let parsedScenario = scenarioValue.flatMap(Self.scenario(named:))
        if scenarioValue != nil, parsedScenario == nil {
            role = .guest
            scenario = .guestHome
        } else if let parsedScenario,
                  !parsedScenario.supports(parsedRole) {
            if roleValue == nil,
               parsedScenario.supports(DemoRole.participant) {
                role = .participant
                scenario = parsedScenario
            } else {
                role = .guest
                scenario = .guestHome
            }
        } else {
            role = parsedRole
            scenario = parsedScenario
                ?? AppDemoScenario.defaultScenario(for: parsedRole)
        }
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
