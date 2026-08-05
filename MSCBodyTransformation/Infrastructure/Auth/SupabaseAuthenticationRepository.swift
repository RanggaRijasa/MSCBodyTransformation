import Foundation

actor SupabaseAuthenticationRepository: AuthenticationRepository {
    private let sessionRepository: any SessionRepository
    private let profileClient: any SupabaseProfileClientProviding
    private let accountDeletionClient:
        any SupabaseAccountDeletionClientProviding
    private let externalAuthentication: (any ExternalAuthenticationProviding)?
    private let secureStore: any SessionSecureStoring
    private let clock: any AppClock
    private let environmentIdentifier: String

    init(
        sessionRepository: any SessionRepository,
        profileClient: any SupabaseProfileClientProviding,
        accountDeletionClient: any SupabaseAccountDeletionClientProviding,
        externalAuthentication: (any ExternalAuthenticationProviding)? = nil,
        secureStore: any SessionSecureStoring,
        clock: any AppClock,
        environmentIdentifier: String
    ) {
        self.sessionRepository = sessionRepository
        self.profileClient = profileClient
        self.accountDeletionClient = accountDeletionClient
        self.externalAuthentication = externalAuthentication
        self.secureStore = secureStore
        self.clock = clock
        self.environmentIdentifier = environmentIdentifier
    }

    func signIn(
        provider: AuthenticationProvider,
        email: String?,
        password: String?
    ) async throws -> AppSession {
        if provider != .email {
            guard let externalAuthentication else {
                throw AuthenticationError.providerUnavailable
            }
            let material = try await externalAuthentication.authenticate(
                provider: provider
            )
            return try await sessionRepository.acceptExternalSession(material)
        }
        guard let email, let password else {
            throw AuthenticationError.validation
        }
        return try await sessionRepository.signIn(
            credential: EmailCredential(email: email, password: password)
        )
    }

    func register(
        provider: AuthenticationProvider,
        email: String?,
        password: String?
    ) async throws -> AppSession {
        if provider != .email {
            guard let externalAuthentication else {
                throw AuthenticationError.providerUnavailable
            }
            let material = try await externalAuthentication.authenticate(
                provider: provider
            )
            return try await sessionRepository.acceptExternalSession(material)
        }
        guard let email, let password else {
            throw AuthenticationError.validation
        }
        return try await sessionRepository.register(
            request: AuthenticationRegistrationRequest(
                credential: EmailCredential(email: email, password: password),
                displayName: "Peserta baru"
            )
        )
    }

    func finalizeRegistration(
        _ completion: RegistrationCompletion
    ) async throws -> RegistrationResult {
        var session: AppSession
        if let credential = completion.credential {
            try await secureStore.savePendingRegistrationDraft(
                PendingRegistrationDraft(
                    completion: completion,
                    createdAt: clock.now(),
                    environment: environmentIdentifier
                )
            )
            do {
                session = try await sessionRepository.register(
                    request: AuthenticationRegistrationRequest(
                        credential: credential,
                        displayName: completion.displayName
                    )
                )
            } catch {
                try? await secureStore.deletePendingRegistrationDraft()
                throw error
            }
            if session.requiresEmailVerification {
                return RegistrationResult(
                    session: session,
                    coachApplication: nil
                )
            }
        } else {
            session = try await sessionRepository.restoreSession()
        }

        let accessToken = try await sessionRepository.validAccessToken()
        _ = try await profileClient.updateMyProfile(
            displayName: completion.displayName,
            phoneNumber: completion.phoneNumber,
            memberLevel: completion.memberLevel,
            accountPurpose: completion.accountPurpose,
            accessToken: accessToken
        )

        switch completion.accountPurpose {
        case .participant:
            guard let coachQR = completion.participantCoachQROpaqueValue else {
                throw AuthenticationError.validation
            }
            _ = try await profileClient.finalizeParticipantOnboarding(
                coachQROpaqueValue: coachQR,
                accessToken: accessToken
            )
        case .coachApplicant:
            _ = try await profileClient.prepareCoachApplicationHandoff(
                accessToken: accessToken
            )
        }

        session = try await sessionRepository.restoreSession()
        try? await secureStore.deletePendingRegistrationDraft()
        return RegistrationResult(session: session, coachApplication: nil)
    }

    func requestPasswordReset(email: String) async throws {
        try await sessionRepository.requestPasswordReset(email: email)
    }

    func savePendingEnrollmentIntent(programID: UUID) async throws {
        try await secureStore.savePendingEnrollmentIntent(
            PendingEnrollmentIntent(
                programID: programID,
                createdAt: clock.now(),
                nonce: UUID(),
                environment: environmentIdentifier
            )
        )
    }

    func pendingEnrollmentIntent() async throws -> PendingEnrollmentIntent? {
        guard let intent = try await secureStore.loadPendingEnrollmentIntent()
        else {
            return nil
        }
        guard intent.isValid(
            at: clock.now(),
            environment: environmentIdentifier
        ) else {
            try? await secureStore.deletePendingEnrollmentIntent()
            return nil
        }
        let accessToken = try await sessionRepository.validAccessToken()
        let availability = try await profileClient
            .pendingProgramEnrollmentAvailability(
                programID: intent.programID,
                accessToken: accessToken
            )
        guard availability == .available else {
            try? await secureStore.deletePendingEnrollmentIntent()
            return nil
        }
        return intent
    }

    func clearPendingEnrollmentIntent() async throws {
        try await secureStore.deletePendingEnrollmentIntent()
    }

    func cancelProvisionalRegistration() async throws {
        let token = try await sessionRepository.validAccessToken()
        var cleanupError: Error?
        do {
            try await profileClient.cancelProvisionalIdentity(
                accessToken: token
            )
        } catch {
            cleanupError = error
        }
        do {
            try await sessionRepository.signOut()
        } catch where cleanupError == nil {
            cleanupError = error
        } catch {
            // The cleanup error is more actionable than a subsequent revoke error.
        }
        try? await secureStore.deletePendingRegistrationDraft()
        try? await secureStore.deletePendingEnrollmentIntent()
        if let cleanupError {
            throw cleanupError
        }
    }

    func deleteAccount(
        reauthentication: AccountReauthentication
    ) async throws {
        switch reauthentication {
        case .email(let email, let password):
            try await sessionRepository.reauthenticate(
                credential: EmailCredential(
                    email: email,
                    password: password
                )
            )
        case .provider(let provider):
            guard provider != .email, let externalAuthentication else {
                throw AuthenticationError.providerUnavailable
            }
            let material = try await externalAuthentication.authenticate(
                provider: provider
            )
            try await sessionRepository.reauthenticate(
                externalSession: material
            )
        }

        let accessToken = try await sessionRepository.validAccessToken()
        try await accountDeletionClient.deleteAccount(
            accessToken: accessToken
        )
        await sessionRepository.clearLocalSessionAfterAccountDeletion()
    }

    func completeParticipantOnboarding(
        userID: UUID,
        displayName: String,
        phoneNumber: String,
        memberLevel: MemberLevel
    ) async throws -> AppSession {
        let session = try await sessionRepository.restoreSession()
        guard session.user?.id == userID else {
            throw AuthenticationError.sessionRevoked
        }
        let token = try await sessionRepository.validAccessToken()
        _ = try await profileClient.updateMyProfile(
            displayName: displayName,
            phoneNumber: phoneNumber,
            memberLevel: memberLevel,
            accountPurpose: .participant,
            accessToken: token
        )
        return try await sessionRepository.restoreSession()
    }
}
