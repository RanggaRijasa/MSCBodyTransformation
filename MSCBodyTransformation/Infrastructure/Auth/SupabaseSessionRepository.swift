import Foundation

actor SupabaseSessionRepository:
    SessionRepository,
    SupabaseAccessTokenProviding
{
    private let authClient: any SupabaseAuthClientProviding
    private let profileClient: any SupabaseProfileClientProviding
    private let secureStore: any SessionSecureStoring
    private let clock: any AppClock
    private let environmentIdentifier: String
    private let callbackRouter = AuthenticationCallbackRouter()
    private let materialGenerator = SecureOAuthMaterialGenerator()
    private var refreshTask: Task<AuthSessionMaterial, Error>?
    private var stateContinuations: [
        UUID: AsyncStream<AuthenticationStateUpdate>.Continuation
    ] = [:]

    init(
        authClient: any SupabaseAuthClientProviding,
        profileClient: any SupabaseProfileClientProviding,
        secureStore: any SessionSecureStoring,
        clock: any AppClock,
        environmentIdentifier: String
    ) {
        self.authClient = authClient
        self.profileClient = profileClient
        self.secureStore = secureStore
        self.clock = clock
        self.environmentIdentifier = environmentIdentifier
    }

    func loadCurrentSession() async throws -> AppSession {
        try await restoreSession()
    }

    func register(
        request: AuthenticationRegistrationRequest
    ) async throws -> AppSession {
        let attempt = try materialGenerator.makeAttempt(
            provider: .email,
            callbackKind: .emailVerification,
            environment: environmentIdentifier,
            now: clock.now()
        )
        try await secureStore.saveOAuthAttempt(attempt)
        let result: SupabaseAuthResult
        do {
            result = try await authClient.signUp(
                request: request,
                codeChallenge: materialGenerator.codeChallenge(
                    for: attempt.codeVerifier
                )
            )
        } catch {
            try? await secureStore.deleteOAuthAttempt()
            throw error
        }
        guard let material = result.session else {
            let user = AppUser(
                id: result.user.id,
                email: result.user.email,
                displayName: request.displayName,
                role: .participant,
                hasCompletedOnboarding: false,
                isCoachApprovalPending: false,
                authenticationProviders:
                    result.user.authenticationProviders,
                createdAt: result.user.createdAt
            )
            let session = AppSession(
                user: user,
                state: .loggedOut,
                onboardingStatus: .provisional,
                requiresEmailVerification: true
            )
            broadcast(.sessionChanged(session))
            return session
        }
        try? await secureStore.deleteOAuthAttempt()
        try await secureStore.saveSession(material)
        return try await loadApplicationSession(material: material)
    }

    func signIn(credential: EmailCredential) async throws -> AppSession {
        let material = try await authClient.signIn(credential: credential)
        try await secureStore.saveSession(material)
        do {
            let session = try await loadApplicationSession(material: material)
            broadcast(.sessionChanged(session))
            return session
        } catch {
            try? await secureStore.deleteSession()
            throw error
        }
    }

    func signOut() async throws {
        let material = try? await secureStore.loadSession()
        var revokeError: Error?
        if let material {
            do {
                try await authClient.signOut(accessToken: material.accessToken)
            } catch {
                revokeError = error
            }
        }
        refreshTask?.cancel()
        refreshTask = nil
        try await secureStore.deleteAll()
        broadcast(.signedOut)
        if let revokeError {
            throw revokeError
        }
    }

    func restoreSession() async throws -> AppSession {
        guard var material = try await secureStore.loadSession() else {
            return AppSession(user: nil, state: .loggedOut)
        }
        if material.requiresRefresh(at: clock.now()) {
            do {
                material = try await coordinatedRefresh()
            } catch let error as AuthenticationError
                where error == .offline || error == .timeout {
                if material.expiresAt <= clock.now() {
                    try? await secureStore.deleteSession()
                    broadcast(.expired)
                    throw AuthenticationError.sessionExpired
                }
                throw error
            } catch {
                try? await secureStore.deleteSession()
                broadcast(.expired)
                throw error
            }
        }
        let session = try await loadApplicationSession(material: material)
        broadcast(.sessionChanged(session))
        return session
    }

    func refreshSession() async throws -> AppSession {
        let material = try await coordinatedRefresh()
        let session = try await loadApplicationSession(material: material)
        broadcast(.sessionChanged(session))
        return session
    }

    func requestPasswordReset(email: String) async throws {
        let normalized = try normalizedEmail(email)
        let attempt = try materialGenerator.makeAttempt(
            provider: .email,
            callbackKind: .passwordRecovery,
            environment: environmentIdentifier,
            now: clock.now()
        )
        try await secureStore.saveOAuthAttempt(attempt)
        do {
            try await authClient.requestPasswordRecovery(
                email: normalized,
                codeChallenge: materialGenerator.codeChallenge(
                    for: attempt.codeVerifier
                )
            )
        } catch {
            try? await secureStore.deleteOAuthAttempt()
            throw error
        }
    }

    func resendEmailVerification(email: String) async throws {
        let normalized = try normalizedEmail(email)
        try await authClient.resendVerification(email: normalized)
    }

    func updatePassword(_ password: String) async throws {
        guard password.count >= 8 else {
            throw AuthenticationError.weakPassword
        }
        let token = try await validAccessToken()
        try await authClient.updatePassword(password, accessToken: token)
        var session = try await restoreSession()
        session.isPasswordRecovery = false
        broadcast(.sessionChanged(session))
    }

    func handleAuthenticationCallback(
        _ url: URL
    ) async throws -> AppSession {
        guard let attempt = try await secureStore.loadOAuthAttempt() else {
            throw AuthenticationError.callbackMismatch
        }
        let callback = try callbackRouter.parse(
            url,
            expectedOAuthAttempt: attempt,
            environment: environmentIdentifier,
            now: clock.now()
        )
        let material = try await authClient.exchangeCode(
            callback.authorizationCode,
            codeVerifier: attempt.codeVerifier
        )
        try await secureStore.saveSession(material)
        try await secureStore.deleteOAuthAttempt()

        var session: AppSession
        if callback.kind == .emailVerification {
            session = try await finalizePendingRegistrationIfPresent(
                material: material
            )
        } else {
            session = try await loadApplicationSession(material: material)
        }
        if callback.kind == .passwordRecovery {
            session.isPasswordRecovery = true
            broadcast(.recoveryRequired)
        } else {
            broadcast(.sessionChanged(session))
        }
        return session
    }

    func authenticationStateUpdates() -> AsyncStream<AuthenticationStateUpdate> {
        let id = UUID()
        return AsyncStream { continuation in
            stateContinuations[id] = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeContinuation(id: id) }
            }
        }
    }

    func validAccessToken() async throws -> String {
        guard let material = try await secureStore.loadSession() else {
            throw AuthenticationError.sessionExpired
        }
        if material.requiresRefresh(at: clock.now()) {
            return try await coordinatedRefresh().accessToken
        }
        return material.accessToken
    }

    func accessToken() async throws -> String {
        try await validAccessToken()
    }

    func switchDebugRole(to role: UserRole) async throws -> AppSession {
        _ = role
        throw AuthenticationError.providerUnavailable
    }

    func setDebugScenario(_ scenario: DebugSessionScenario) async {
        _ = scenario
    }

    func acceptExternalSession(
        _ material: AuthSessionMaterial
    ) async throws -> AppSession {
        try await secureStore.saveSession(material)
        let session = try await loadApplicationSession(material: material)
        broadcast(.sessionChanged(session))
        return session
    }

    func reauthenticate(credential: EmailCredential) async throws {
        guard let current = try await secureStore.loadSession() else {
            throw AuthenticationError.sessionExpired
        }
        let material = try await authClient.signIn(credential: credential)
        guard material.userID == current.userID else {
            try? await authClient.signOut(accessToken: material.accessToken)
            throw AuthenticationError.invalidCredential
        }
        try await secureStore.saveSession(material)
    }

    func reauthenticate(
        externalSession material: AuthSessionMaterial
    ) async throws {
        guard let current = try await secureStore.loadSession() else {
            throw AuthenticationError.sessionExpired
        }
        guard material.userID == current.userID else {
            try? await authClient.signOut(accessToken: material.accessToken)
            throw AuthenticationError.invalidCredential
        }
        try await secureStore.saveSession(material)
    }

    func clearLocalSessionAfterAccountDeletion() async {
        refreshTask?.cancel()
        refreshTask = nil
        try? await secureStore.deleteAll()
        broadcast(.signedOut)
    }

    private func coordinatedRefresh() async throws -> AuthSessionMaterial {
        if let refreshTask {
            return try await refreshTask.value
        }
        guard let current = try await secureStore.loadSession() else {
            throw AuthenticationError.sessionExpired
        }
        let client = authClient
        let task = Task {
            try Task.checkCancellation()
            return try await client.refresh(refreshToken: current.refreshToken)
        }
        refreshTask = task
        do {
            let refreshed = try await task.value
            try await secureStore.saveSession(refreshed)
            refreshTask = nil
            return refreshed
        } catch {
            refreshTask = nil
            if let authError = error as? AuthenticationError,
               authError == .sessionRevoked || authError == .sessionExpired {
                try? await secureStore.deleteSession()
                broadcast(.expired)
            }
            throw error
        }
    }

    private func loadApplicationSession(
        material: AuthSessionMaterial
    ) async throws -> AppSession {
        let authUser = try await authClient.user(
            accessToken: material.accessToken
        )
        guard authUser.id == material.userID else {
            throw AuthenticationError.sessionRevoked
        }
        guard authUser.isEmailConfirmed else {
            throw AuthenticationError.verificationRequired
        }
        let profile = try await profileClient.profile(
            userID: authUser.id,
            accessToken: material.accessToken
        )
        guard profile.userID == authUser.id else {
            throw AuthenticationError.roleLoad
        }
        let hasCompletedOnboarding = profile.onboardingStatus == .active
        let user = AppUser(
            id: authUser.id,
            email: authUser.email,
            displayName: profile.displayName,
            role: profile.role,
            hasCompletedOnboarding: hasCompletedOnboarding,
            isCoachApprovalPending:
                profile.onboardingStatus == .coachHandoffPending,
            authenticationProviders: authUser.authenticationProviders,
            createdAt: authUser.createdAt
        )
        return AppSession(
            user: user,
            state: .active,
            onboardingStatus: profile.onboardingStatus
        )
    }

    private func finalizePendingRegistrationIfPresent(
        material: AuthSessionMaterial
    ) async throws -> AppSession {
        guard let draft = try await secureStore.loadPendingRegistrationDraft()
        else {
            return try await loadApplicationSession(material: material)
        }
        guard draft.isValid(
            at: clock.now(),
            environment: environmentIdentifier
        ) else {
            try? await secureStore.deletePendingRegistrationDraft()
            throw AuthenticationError.sessionExpired
        }

        _ = try await profileClient.updateMyProfile(
            displayName: draft.displayName,
            phoneNumber: draft.phoneNumber,
            memberLevel: draft.memberLevel,
            accountPurpose: draft.accountPurpose,
            accessToken: material.accessToken
        )
        switch draft.accountPurpose {
        case .participant:
            guard let coachQR = draft.participantCoachQROpaqueValue else {
                throw AuthenticationError.validation
            }
            _ = try await profileClient.finalizeParticipantOnboarding(
                coachQROpaqueValue: coachQR,
                accessToken: material.accessToken
            )
        case .coachApplicant:
            _ = try await profileClient.prepareCoachApplicationHandoff(
                accessToken: material.accessToken
            )
        }
        try await secureStore.deletePendingRegistrationDraft()
        return try await loadApplicationSession(material: material)
    }

    private func normalizedEmail(_ value: String) throws -> String {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let parts = normalized.split(separator: "@")
        guard parts.count == 2,
              parts.allSatisfy({ !$0.isEmpty }),
              parts[1].contains(".") else {
            throw AuthenticationError.validation
        }
        return normalized
    }

    private func broadcast(_ update: AuthenticationStateUpdate) {
        stateContinuations.values.forEach { $0.yield(update) }
    }

    private func removeContinuation(id: UUID) {
        stateContinuations[id] = nil
    }
}
