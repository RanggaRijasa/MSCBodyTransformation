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
            .flatMap(AppDemoScenario.init(rawValue:))
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
}
#endif
