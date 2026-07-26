import Foundation
import Observation
import SwiftUI

nonisolated enum ParticipantRoute: Hashable, Sendable {
    case programDetail(UUID)
    case stepDetail(UUID)
    case weighIn(WeighInType)
    case leaderboard
    case coach(UUID)
    case profile
    case localInvite(String)
}

nonisolated enum CoachRoute: Hashable, Sendable {
    case participantDetail(UUID)
    case reviewQueue
    case invite
    case storePreview
    case leaderboard
    case profile
}

nonisolated enum AdminRoute: Hashable, Sendable {
    case programEditor(UUID?)
    case person(UUID)
    case managedContent(UUID)
    case settings
}

nonisolated enum ShellRoute: Hashable, Sendable {
    case participant(ParticipantRoute)
    case coach(CoachRoute)
    case admin(AdminRoute)

    var role: UserRole {
        switch self {
        case .participant:
            .participant
        case .coach:
            .coach
        case .admin:
            .admin
        }
    }
}

nonisolated enum ShellSheet: Identifiable, Hashable, Sendable {
    case confirmation
    case inviteCode(String)
    case scenarioInformation(String)

    var id: String {
        switch self {
        case .confirmation:
            "confirmation"
        case .inviteCode:
            "invite_code"
        case .scenarioInformation:
            "scenario_information"
        }
    }
}

nonisolated enum ShellAlert: Identifiable, Hashable, Sendable {
    case invalidInvite
    case unavailableRoute

    var id: String {
        switch self {
        case .invalidInvite:
            "invalid_invite"
        case .unavailableRoute:
            "unavailable_route"
        }
    }
}

@MainActor
@Observable
final class ShellTabRouter {
    private var paths: [AppTab: [ShellRoute]] = [:]
    var presentedSheet: ShellSheet?
    var presentedAlert: ShellAlert?

    func path(for tab: AppTab) -> [ShellRoute] {
        paths[tab, default: []]
    }

    func binding(for tab: AppTab) -> Binding<[ShellRoute]> {
        Binding(
            get: { [weak self] in
                self?.paths[tab, default: []] ?? []
            },
            set: { [weak self] newPath in
                self?.paths[tab] = newPath
            }
        )
    }

    func navigate(to route: ShellRoute, in tab: AppTab) {
        guard route.role == tab.role else {
            presentedAlert = .unavailableRoute
            return
        }
        paths[tab, default: []].append(route)
    }

    func resetAllPaths() {
        paths.removeAll()
    }
}

nonisolated struct LocalInviteDeepLinkParser: Sendable {
    func inviteCode(from url: URL) -> String? {
        guard url.scheme?.lowercased() == "mscbody",
              url.host?.lowercased() == "invite" else {
            return nil
        }
        let code = url.pathComponents
            .filter { $0 != "/" }
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard let code, !code.isEmpty else {
            return nil
        }
        return code
    }
}
