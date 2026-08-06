import Foundation

nonisolated enum SessionState: String, Codable, CaseIterable, Sendable {
    case active
    case loggedOut = "logged_out"
    case expired
}

nonisolated struct AppSession: Codable, Equatable, Sendable {
    let user: AppUser?
    let state: SessionState
    var onboardingStatus: ProfileOnboardingStatus? = nil
    var requiresEmailVerification = false
    var isPasswordRecovery = false

    var role: UserRole? {
        user?.role
    }

    var requiresOnboarding: Bool {
        state == .active
            && (user?.hasCompletedOnboarding == false
                || onboardingStatus == .provisional
                || onboardingStatus == .coachHandoffPending)
    }
}

nonisolated enum DebugSessionScenario: Equatable, Sendable {
    case role(UserRole)
    case user(UUID)
    case loggedOut
    case onboardingIncomplete(UserRole)
    case expired
}
