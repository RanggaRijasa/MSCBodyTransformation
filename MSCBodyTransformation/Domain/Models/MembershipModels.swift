import Foundation

nonisolated enum AppAccessState: Equatable, Sendable {
    case guest
    case authenticated(AppSession)

    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
}

nonisolated enum AuthenticationProvider: String, Codable, CaseIterable, Sendable {
    case apple
    case google
    case email
}

nonisolated enum FakeAuthenticationOutcome: String, CaseIterable, Sendable {
    case success
    case cancelled
    case offline
    case providerError = "provider_error"
    case unknown

    var localizedTitle: String {
        switch self {
        case .success:
            String(
                localized: "auth.outcome.success",
                defaultValue: "Berhasil"
            )
        case .cancelled:
            String(
                localized: "auth.outcome.cancelled",
                defaultValue: "Dibatalkan"
            )
        case .offline:
            String(
                localized: "auth.outcome.offline",
                defaultValue: "Offline"
            )
        case .providerError:
            String(
                localized: "auth.outcome.provider_error",
                defaultValue: "Penyedia bermasalah"
            )
        case .unknown:
            String(
                localized: "auth.outcome.unknown",
                defaultValue: "Tidak diketahui"
            )
        }
    }
}

nonisolated enum FakeRecoveryOutcome: String, CaseIterable, Sendable {
    case success
    case rateLimited = "rate_limited"
    case offline

    var localizedTitle: String {
        switch self {
        case .success:
            String(
                localized: "auth.outcome.success",
                defaultValue: "Berhasil"
            )
        case .rateLimited:
            String(
                localized: "auth.outcome.rate_limited",
                defaultValue: "Terlalu banyak percobaan"
            )
        case .offline:
            String(
                localized: "auth.outcome.offline",
                defaultValue: "Offline"
            )
        }
    }
}

nonisolated enum AuthenticationDestination:
    String,
    Hashable,
    Identifiable,
    Sendable
{
    case login
    case loginEmail = "login_email"
    case register
    case registerEmail = "register_email"
    case forgotPassword = "forgot_password"
    case profileOnboarding = "profile_onboarding"
    case participantCoachQR = "participant_coach_qr"
    case coachEligibility = "coach_eligibility"
    case coachPayment = "coach_payment"
    case pendingCoachApproval = "pending_coach_approval"

    var id: String { rawValue }
}

nonisolated enum AuthGateReason: String, Sendable {
    case joinProgram = "join_program"
    case personalActivity = "personal_activity"
    case editProfile = "edit_profile"
    case accountSettings = "account_settings"
}

nonisolated enum PendingAuthenticatedIntent: Equatable, Sendable {
    case joinProgram(UUID)
    case openProfile
}

nonisolated struct AuthenticationPresentation:
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    var destination: AuthenticationDestination
    let reason: AuthGateReason?

    init(
        id: UUID = UUID(),
        destination: AuthenticationDestination,
        reason: AuthGateReason? = nil
    ) {
        self.id = id
        self.destination = destination
        self.reason = reason
    }
}

nonisolated enum MemberLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case member
    case sc
    case sb
    case supervisor
    case worldTeam = "world_team"
    case tabTeam = "tab_team"
    case getTeam = "get_team"
    case millionaireTeam = "millionaire_team"
    case presidentsTeam = "presidents_team"

    var id: String { rawValue }

    var titleLocalizationKey: String {
        "member.level.\(rawValue)"
    }

    var displayName: String {
        switch self {
        case .member:
            "Member"
        case .sc:
            "SC"
        case .sb:
            "SB"
        case .supervisor:
            "Supervisor"
        case .worldTeam:
            "World Team"
        case .tabTeam:
            "TAB Team"
        case .getTeam:
            "GET Team"
        case .millionaireTeam:
            "Millionaire Team"
        case .presidentsTeam:
            "President’s Team"
        }
    }

    var isCoachLevelEligible: Bool {
        self != .member
    }
}

nonisolated enum CoachPriceBand: String, Codable, Sendable {
    case entry
    case growth
    case leadership

    var amountMinorUnits: Int64 {
        switch self {
        case .entry:
            100_000
        case .growth:
            150_000
        case .leadership:
            200_000
        }
    }
}

nonisolated enum AccountPurpose:
    String,
    Codable,
    CaseIterable,
    Equatable,
    Sendable
{
    case participant
    case coachApplicant = "coach_applicant"
}

nonisolated struct RegistrationCompletion: Sendable {
    let provider: AuthenticationProvider
    let email: String?
    let displayName: String
    let phoneNumber: String
    let memberLevel: MemberLevel
    let accountPurpose: AccountPurpose
    let participantCoachID: UUID?
    let hasCompletedHOMSTS: Bool
    let hasCompletedICT: Bool
    let coachPayment: CoachPaymentPreview?
    let termsVersion: String
    var credential: EmailCredential? = nil
    var participantCoachQROpaqueValue: String? = nil
}

nonisolated struct RegistrationResult: Sendable {
    let session: AppSession
    let coachApplication: CoachApplication?
}

nonisolated struct CoachEligibility: Codable, Equatable, Sendable {
    let memberLevel: MemberLevel
    let hasCompletedHOMSTS: Bool
    let hasCompletedICT: Bool

    var isLevelEligible: Bool {
        memberLevel.isCoachLevelEligible
    }

    var isComplete: Bool {
        isLevelEligible && hasCompletedHOMSTS && hasCompletedICT
    }

    var missingRequirementKeys: [String] {
        var keys: [String] = []
        if !isLevelEligible {
            keys.append("coach.eligibility.requirement.level")
        }
        if !hasCompletedHOMSTS {
            keys.append("coach.eligibility.requirement.hom_sts")
        }
        if !hasCompletedICT {
            keys.append("coach.eligibility.requirement.ict")
        }
        return keys
    }
}

nonisolated enum CoachApplicationStatus:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case draft
    case ineligible
    case readyForPayment = "ready_for_payment"
    case paymentProcessing = "payment_processing"
    case paymentVerified = "payment_verified"
    case pendingAdminApproval = "pending_admin_approval"
    case submitted
    case acceptedPendingPayment = "accepted_pending_payment"
    case active
    case approved
    case rejected
    case expired

    var isActive: Bool {
        switch self {
        case .draft, .ineligible, .readyForPayment, .paymentProcessing,
             .paymentVerified, .pendingAdminApproval, .submitted,
             .acceptedPendingPayment, .active:
            true
        case .approved, .rejected, .expired:
            false
        }
    }
}

nonisolated enum CoachPaymentState: String, Codable, Sendable {
    case notStarted = "not_started"
    case processing
    case pending
    case verified
    case cancelled
    case failed
    case interrupted
}

nonisolated struct CoachPaymentPreview: Codable, Equatable, Sendable {
    let priceBand: CoachPriceBand
    let amountMinorUnits: Int64
    let durationMonths: Int
    var state: CoachPaymentState
    var verifiedAt: Date?
    var accessStartsAt: Date?
    var accessEndsAt: Date?

    init(
        priceBand: CoachPriceBand,
        amountMinorUnits: Int64,
        durationMonths: Int = 3,
        state: CoachPaymentState = .notStarted,
        verifiedAt: Date? = nil,
        accessStartsAt: Date? = nil,
        accessEndsAt: Date? = nil
    ) {
        self.priceBand = priceBand
        self.amountMinorUnits = amountMinorUnits
        self.durationMonths = durationMonths
        self.state = state
        self.verifiedAt = verifiedAt
        self.accessStartsAt = accessStartsAt
        self.accessEndsAt = accessEndsAt
    }
}

nonisolated struct CoachApplicationDecision: Codable, Equatable, Sendable {
    let adminUserID: UUID
    let decidedAt: Date
    let rejectionReason: String?
}

nonisolated struct CoachApplication:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    let userID: UUID
    let participantProfileID: UUID
    var displayNameSnapshot: String
    var phoneNumberSnapshot: String
    var memberLevel: MemberLevel
    var hasCompletedHOMSTS: Bool
    var hasCompletedICT: Bool
    let termsVersion: String
    var status: CoachApplicationStatus
    var payment: CoachPaymentPreview?
    let createdAt: Date
    var submittedAt: Date?
    var updatedAt: Date
    var decision: CoachApplicationDecision?

    var eligibility: CoachEligibility {
        CoachEligibility(
            memberLevel: memberLevel,
            hasCompletedHOMSTS: hasCompletedHOMSTS,
            hasCompletedICT: hasCompletedICT
        )
    }

    var isReadyForAdminApproval: Bool {
        eligibility.isComplete
            && (status == .submitted || status == .pendingAdminApproval)
    }
}

nonisolated enum FakeCoachPurchaseOutcome: String, CaseIterable, Sendable {
    case success
    case cancelled
    case pending
    case failed
    case interrupted

    var localizedTitle: String {
        switch self {
        case .success:
            String(
                localized: "coach.payment.outcome.success",
                defaultValue: "Berhasil"
            )
        case .cancelled:
            String(
                localized: "coach.payment.outcome.cancelled",
                defaultValue: "Dibatalkan"
            )
        case .pending:
            String(
                localized: "coach.payment.outcome.pending",
                defaultValue: "Tertunda"
            )
        case .failed:
            String(
                localized: "coach.payment.outcome.failed",
                defaultValue: "Gagal"
            )
        case .interrupted:
            String(
                localized: "coach.payment.outcome.interrupted",
                defaultValue: "Terhenti"
            )
        }
    }
}

nonisolated struct FakeCoachPurchaseResult: Equatable, Sendable {
    let state: CoachPaymentState
    let verifiedAt: Date?
    let accessStartsAt: Date?
    let accessEndsAt: Date?
}
