import Foundation

nonisolated enum ParticipantTab: String, CaseIterable, Sendable {
    case today
    case program
    case leaderboard
    case coaches
    case profile
}

nonisolated enum CoachTab: String, CaseIterable, Sendable {
    case dashboard
    case participants
    case invite
    case leaderboard
    case profile
}

nonisolated enum AdminTab: String, CaseIterable, Sendable {
    case overview
    case programs
    case people
    case content
    case settings
}

nonisolated enum AppTab: Hashable, Identifiable, Sendable {
    case participant(ParticipantTab)
    case coach(CoachTab)
    case admin(AdminTab)

    var id: String {
        "\(role.rawValue).\(rawValue)"
    }

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

    var rawValue: String {
        switch self {
        case .participant(let tab):
            tab.rawValue
        case .coach(let tab):
            tab.rawValue
        case .admin(let tab):
            tab.rawValue
        }
    }

    var titleLocalizationKey: String {
        "tab.\(id)"
    }

    var systemImage: String {
        switch self {
        case .participant(.today):
            "sun.max"
        case .participant(.program):
            "list.bullet.rectangle"
        case .participant(.leaderboard):
            "trophy"
        case .participant(.coaches):
            "person.2"
        case .participant(.profile):
            "person.crop.circle"
        case .coach(.dashboard):
            "rectangle.grid.2x2"
        case .coach(.participants):
            "person.3"
        case .coach(.invite):
            "qrcode"
        case .coach(.leaderboard):
            "trophy"
        case .coach(.profile):
            "person.crop.circle"
        case .admin(.overview):
            "chart.bar"
        case .admin(.programs):
            "square.stack.3d.up"
        case .admin(.people):
            "person.2.badge.gearshape"
        case .admin(.content):
            "text.document"
        case .admin(.settings):
            "gearshape"
        }
    }

    var accessibilityIdentifier: String {
        "shell.tab.\(id)"
    }

    static func tabs(for role: UserRole) -> [Self] {
        switch role {
        case .participant:
            ParticipantTab.allCases.map(Self.participant)
        case .coach:
            CoachTab.allCases.map(Self.coach)
        case .admin:
            AdminTab.allCases.map(Self.admin)
        }
    }
}

nonisolated enum AppDemoScenario: String, CaseIterable, Identifiable, Sendable {
    case loading
    case error
    case empty
    case offline
    case participantOnboarding = "participant_onboarding"
    case participantActive = "participant_active"
    case coachReviewQueue = "coach_review_queue"
    case adminDraftEditor = "admin_draft_editor"

    var id: String { rawValue }

    var titleLocalizationKey: String {
        "scenario.\(rawValue)"
    }

    static func defaultScenario(for role: UserRole) -> Self {
        switch role {
        case .participant:
            .participantActive
        case .coach:
            .coachReviewQueue
        case .admin:
            .adminDraftEditor
        }
    }
}
