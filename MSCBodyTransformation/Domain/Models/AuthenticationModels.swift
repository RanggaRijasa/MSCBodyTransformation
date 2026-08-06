import Foundation

nonisolated struct EmailCredential: Equatable, Sendable {
    let email: String
    let password: String

    init(email: String, password: String) throws {
        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let parts = normalizedEmail.split(separator: "@")
        guard parts.count == 2,
              parts.allSatisfy({ !$0.isEmpty }),
              parts[1].contains(".") else {
            throw AuthenticationError.validation
        }
        guard password.count >= 8 else {
            throw AuthenticationError.weakPassword
        }
        self.email = normalizedEmail
        self.password = password
    }
}

nonisolated struct AuthenticationRegistrationRequest: Sendable {
    let credential: EmailCredential
    let displayName: String

    init(credential: EmailCredential, displayName: String) {
        self.credential = credential
        self.displayName = displayName
    }
}

nonisolated enum ProfileOnboardingStatus: String, Codable, Sendable {
    case provisional
    case coachHandoffPending = "coach_handoff_pending"
    case active
    case cleanupPending = "cleanup_pending"
}

nonisolated enum AuthenticationRecoveryState: Equatable, Sendable {
    case idle
    case emailRequested
    case passwordUpdateRequired
    case completed
}

nonisolated struct AuthSessionMaterial: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let userID: UUID
    let email: String

    func requiresRefresh(
        at date: Date,
        tolerance: TimeInterval = 60
    ) -> Bool {
        expiresAt.timeIntervalSince(date) <= tolerance
    }
}

nonisolated enum AuthenticationStateUpdate: Equatable, Sendable {
    case signedOut
    case sessionChanged(AppSession)
    case expired
    case recoveryRequired
}

nonisolated enum AuthenticationError: Error, Equatable, Sendable {
    case validation
    case weakPassword
    case invalidCredential
    case verificationRequired
    case cancelled
    case rateLimited
    case offline
    case timeout
    case callbackMismatch
    case conflict
    case sessionExpired
    case sessionRevoked
    case profileProvisioning
    case roleLoad
    case providerUnavailable
    case recentReauthenticationRequired
    case accountDeletionNotAllowed
    case accountRelationshipsRequireTransfer
    case accountDeletionFailed
    case unknown
}

nonisolated enum AccountReauthentication: Sendable {
    case email(email: String, password: String)
    case provider(AuthenticationProvider)
}

nonisolated struct PendingEnrollmentIntent: Codable, Equatable, Sendable {
    static let defaultTimeToLive: TimeInterval = 30 * 60

    let programID: UUID
    let coachQROpaqueValue: String?
    let createdAt: Date
    let expiresAt: Date
    let nonce: UUID
    let environment: String

    init(
        programID: UUID,
        coachQROpaqueValue: String? = nil,
        createdAt: Date,
        timeToLive: TimeInterval = defaultTimeToLive,
        nonce: UUID,
        environment: String
    ) {
        self.programID = programID
        self.coachQROpaqueValue = coachQROpaqueValue
        self.createdAt = createdAt
        expiresAt = createdAt.addingTimeInterval(timeToLive)
        self.nonce = nonce
        self.environment = environment
    }

    func isValid(at date: Date, environment: String) -> Bool {
        self.environment == environment && date < expiresAt
    }
}

nonisolated enum PendingProgramEnrollmentAvailability: String, Decodable,
    Sendable
{
    case available
    case programUnavailable = "program_unavailable"
    case registrationClosed = "registration_closed"
    case programFull = "program_full"
}

nonisolated enum AuthenticationCallbackKind: String, Codable, Sendable {
    case emailVerification = "signup"
    case passwordRecovery = "recovery"
    case oauth
}

nonisolated struct AuthenticationCallback: Equatable, Sendable {
    let kind: AuthenticationCallbackKind
    let authorizationCode: String
    let state: String?
}

nonisolated struct OAuthAuthorizationAttempt: Codable, Equatable, Sendable {
    let provider: AuthenticationProvider
    let callbackKind: AuthenticationCallbackKind
    let state: String
    let nonce: String
    let codeVerifier: String
    let environment: String
    let expiresAt: Date

    func isValid(at date: Date, environment: String) -> Bool {
        self.environment == environment && date < expiresAt
    }
}

nonisolated struct PendingRegistrationDraft: Codable, Equatable, Sendable {
    static let defaultTimeToLive: TimeInterval = 24 * 60 * 60

    let displayName: String
    let phoneNumber: String
    let memberLevel: MemberLevel
    let accountPurpose: AccountPurpose
    let participantCoachQROpaqueValue: String?
    let hasCompletedHOMSTS: Bool
    let hasCompletedICT: Bool
    let expiresAt: Date
    let environment: String

    init(
        completion: RegistrationCompletion,
        createdAt: Date,
        environment: String,
        timeToLive: TimeInterval = defaultTimeToLive
    ) {
        displayName = completion.displayName
        phoneNumber = completion.phoneNumber
        memberLevel = completion.memberLevel
        accountPurpose = completion.accountPurpose
        participantCoachQROpaqueValue =
            completion.participantCoachQROpaqueValue
        hasCompletedHOMSTS = completion.hasCompletedHOMSTS
        hasCompletedICT = completion.hasCompletedICT
        expiresAt = createdAt.addingTimeInterval(timeToLive)
        self.environment = environment
    }

    func isValid(at date: Date, environment: String) -> Bool {
        self.environment == environment && date < expiresAt
    }
}

nonisolated enum SessionRootRoute: Equatable, Sendable {
    case bootstrapping
    case loggedOut
    case awaitingEmailVerification
    case passwordRecovery
    case profileProvisioning
    case provisionalOnboarding
    case provisionalCleanupPending
    case authenticated(UserRole)
    case expired
    case recoverableError(AuthenticationError)
}
