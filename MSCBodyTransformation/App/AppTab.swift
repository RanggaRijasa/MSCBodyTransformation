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
    case program
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
            "house.fill"
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
        case .coach(.program):
            "list.bullet.rectangle"
        case .coach(.profile):
            "person.crop.circle"
        case .admin(.overview):
            "chart.bar.fill"
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
    case guestHome = "guest_home"
    case guestProgramCatalog = "guest_program_catalog"
    case authLogin = "auth_login"
    case authRegister = "auth_register"
    case authForgotPassword = "auth_forgot_password"
    case authProfileOnboarding = "auth_profile_onboarding"
    case coachApplicationEligible = "coach_application_eligible"
    case coachApplicationIneligible = "coach_application_ineligible"
    case coachPaymentSuccess = "coach_payment_success"
    case coachPendingApproval = "coach_pending_approval"
    case loggedOut = "logged_out"
    case loading
    case offline
    case permissionDenied = "permission_denied"
    case repositoryError = "repository_error"
    case participantOnboarding = "participant_onboarding"
    case participantNoProgram = "participant_no_program"
    case participantActive = "participant_active"
    case participantDayOne = "participant_day_1"
    case participantMidProgram = "participant_mid_program"
    case participantFinalWeighIn = "participant_final_weigh_in"
    case participantFinalLeaderboard = "participant_final_leaderboard"
    case coachIdentifier = "coach_identifier"
    case coachActiveParticipants = "coach_active_participants"
    case coachReviewQueue = "coach_review_queue"
    case adminDashboard = "admin_dashboard"
    case adminDraftCMS = "admin_draft_cms"
    case adminActiveProgram = "admin_active_program"
    case adminWinnerLock = "admin_winner_lock"

    var id: String { rawValue }

    var titleLocalizationKey: String {
        "scenario.\(rawValue)"
    }

    func supports(_ role: UserRole) -> Bool {
        switch self {
        case .guestHome, .guestProgramCatalog, .authLogin, .authRegister,
             .authForgotPassword, .authProfileOnboarding,
             .coachApplicationEligible, .coachApplicationIneligible,
             .coachPaymentSuccess, .coachPendingApproval:
            false
        case .loggedOut, .loading, .offline, .permissionDenied,
             .repositoryError:
            true
        case .participantOnboarding, .participantNoProgram,
             .participantActive,
             .participantDayOne, .participantMidProgram,
             .participantFinalWeighIn, .participantFinalLeaderboard:
            role == .participant
        case .coachIdentifier, .coachActiveParticipants,
             .coachReviewQueue:
            role == .coach
        case .adminDashboard, .adminDraftCMS, .adminActiveProgram,
             .adminWinnerLock:
            role == .admin
        }
    }

    func supports(_ role: DemoRole) -> Bool {
        switch role {
        case .guest:
            return switch self {
            case .guestHome, .guestProgramCatalog, .authLogin, .authRegister,
                 .authForgotPassword, .authProfileOnboarding,
                 .coachApplicationEligible, .coachApplicationIneligible,
                 .coachPaymentSuccess, .coachPendingApproval, .loading,
                 .offline, .repositoryError:
                true
            default:
                false
            }
        case .participant, .coach, .admin:
            guard let userRole = role.userRole else {
                return false
            }
            return supports(userRole)
        }
    }

    static func scenarios(for role: UserRole) -> [Self] {
        allCases.filter { $0.supports(role) }
    }

    static func scenarios(for role: DemoRole) -> [Self] {
        allCases.filter { $0.supports(role) }
    }

    static func defaultScenario(for role: UserRole) -> Self {
        switch role {
        case .participant:
            .participantActive
        case .coach:
            .coachReviewQueue
        case .admin:
            .adminDashboard
        }
    }

    static func defaultScenario(for role: DemoRole) -> Self {
        guard let userRole = role.userRole else {
            return .guestHome
        }
        return defaultScenario(for: userRole)
    }

    func initialTab(for role: UserRole) -> AppTab {
        switch self {
        case .participantFinalLeaderboard:
            .participant(.leaderboard)
        case .coachIdentifier:
            .coach(.dashboard)
        case .coachActiveParticipants:
            .coach(.dashboard)
        case .adminDashboard:
            .admin(.overview)
        case .adminDraftCMS, .adminActiveProgram:
            .admin(.programs)
        default:
            AppTab.tabs(for: role).first ?? .participant(.today)
        }
    }

    func initialTab(for role: DemoRole) -> AppTab {
        if role == .guest {
            return self == .guestProgramCatalog
                ? .participant(.program)
                : .participant(.today)
        }
        return initialTab(for: role.shellRole)
    }
}
