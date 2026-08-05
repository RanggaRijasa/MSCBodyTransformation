import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    private let repository: any SessionRepository

    private(set) var route = SessionRootRoute.bootstrapping
    private(set) var session: AppSession?

    init(repository: any SessionRepository) {
        self.repository = repository
    }

    func bootstrap() async {
        route = .bootstrapping
        do {
            apply(try await repository.restoreSession())
        } catch let error as AuthenticationError {
            route = Self.route(for: error)
        } catch let error as DomainError where error == .sessionExpired {
            route = .expired
        } catch {
            route = .recoverableError(.unknown)
        }
    }

    func observeSessionChanges() async {
        let updates = await repository.authenticationStateUpdates()
        for await update in updates {
            guard !Task.isCancelled else { return }
            switch update {
            case .signedOut:
                session = nil
                route = .loggedOut
            case .sessionChanged(let session):
                apply(session)
            case .expired:
                session = nil
                route = .expired
            case .recoveryRequired:
                route = .passwordRecovery
            }
        }
    }

    func retry() async {
        await bootstrap()
    }

    func handleAuthenticationCallback(_ url: URL) async {
        do {
            apply(try await repository.handleAuthenticationCallback(url))
        } catch let error as AuthenticationError
            where error == .callbackMismatch
                && route != .loggedOut
                && route != .awaitingEmailVerification {
            // A previously consumed callback is idempotently ignored.
        } catch let error as AuthenticationError {
            route = .recoverableError(error)
        } catch {
            route = .recoverableError(.unknown)
        }
    }

    func resendVerification() async throws {
        guard let email = session?.user?.email else {
            throw AuthenticationError.validation
        }
        try await repository.resendEmailVerification(email: email)
    }

    func updatePassword(_ password: String) async throws {
        try await repository.updatePassword(password)
        apply(try await repository.restoreSession())
    }

    func signOut() async {
        do {
            try await repository.signOut()
        } catch {
            // Local session is cleared even when remote revocation cannot be confirmed.
        }
        session = nil
        route = .loggedOut
    }

    private func apply(_ session: AppSession) {
        self.session = session
        if session.requiresEmailVerification {
            route = .awaitingEmailVerification
            return
        }
        if session.isPasswordRecovery {
            route = .passwordRecovery
            return
        }
        guard session.state == .active else {
            route = session.state == .expired ? .expired : .loggedOut
            return
        }
        guard let user = session.user else {
            route = .recoverableError(.roleLoad)
            return
        }
        switch session.onboardingStatus {
        case .provisional, .coachHandoffPending:
            route = .provisionalOnboarding
        case .cleanupPending:
            route = .provisionalCleanupPending
        case .active:
            route = .authenticated(user.role)
        case nil:
            route = user.hasCompletedOnboarding
                ? .authenticated(user.role)
                : .profileProvisioning
        }
    }

    private static func route(
        for error: AuthenticationError
    ) -> SessionRootRoute {
        switch error {
        case .verificationRequired:
            .awaitingEmailVerification
        case .sessionExpired, .sessionRevoked:
            .expired
        case .profileProvisioning:
            .profileProvisioning
        default:
            .recoverableError(error)
        }
    }
}
