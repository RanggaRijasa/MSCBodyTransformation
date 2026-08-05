import Foundation
import Observation

nonisolated enum DemoRole: String, CaseIterable, Hashable, Identifiable, Sendable {
    case guest
    case participant
    case coach
    case admin

    var id: String { rawValue }

    var titleLocalizationKey: String {
        switch self {
        case .guest:
            "role.guest"
        case .participant:
            "role.participant"
        case .coach:
            "role.coach"
        case .admin:
            "role.admin"
        }
    }

    var systemImage: String {
        switch self {
        case .guest:
            "person.crop.circle.badge.questionmark"
        case .participant:
            "figure.walk"
        case .coach:
            "person.2"
        case .admin:
            "slider.horizontal.3"
        }
    }

    var userRole: UserRole? {
        switch self {
        case .guest:
            nil
        case .participant:
            .participant
        case .coach:
            .coach
        case .admin:
            .admin
        }
    }

    var shellRole: UserRole {
        userRole ?? .participant
    }
}

nonisolated enum AppRoute: Hashable {
    case localDemo(DemoRole, AppDemoScenario)
}

@MainActor
@Observable
final class AppRouter {
    var path: [AppRoute]

    init(path: [AppRoute] = []) {
        self.path = path
    }

    func enterLocalDemo(
        as role: DemoRole,
        scenario: AppDemoScenario
    ) {
        path.append(.localDemo(role, scenario))
    }

    func reset() {
        path.removeAll()
    }
}
