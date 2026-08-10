import AuthenticationServices
import Foundation
import UIKit

@MainActor
final class NativeProviderAuthenticationCoordinator:
    NSObject,
    ExternalAuthenticationProviding,
    ASWebAuthenticationPresentationContextProviding,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private let authClient: any SupabaseAuthClientProviding
    private let profileClient: any SupabaseProfileClientProviding
    private let appleLifecycleClient:
        any SupabaseAppleIdentityLifecycleClientProviding
    private let secureStore: any SessionSecureStoring
    private let configuration: AppConfiguration
    private let clock: any AppClock
    private let materialGenerator = SecureOAuthMaterialGenerator()
    private let callbackRouter = AuthenticationCallbackRouter()

    private var webSession: ASWebAuthenticationSession?
    private var appleContinuation: CheckedContinuation<
        AuthSessionMaterial,
        Error
    >?
    private var activeAppleAttempt: OAuthAuthorizationAttempt?

    init(
        authClient: any SupabaseAuthClientProviding,
        profileClient: any SupabaseProfileClientProviding,
        appleLifecycleClient:
            any SupabaseAppleIdentityLifecycleClientProviding,
        secureStore: any SessionSecureStoring,
        configuration: AppConfiguration,
        clock: any AppClock
    ) {
        self.authClient = authClient
        self.profileClient = profileClient
        self.appleLifecycleClient = appleLifecycleClient
        self.secureStore = secureStore
        self.configuration = configuration
        self.clock = clock
    }

    func authenticate(
        provider: AuthenticationProvider
    ) async throws -> AuthSessionMaterial {
        switch provider {
        case .google:
            try await authenticateWithGoogle()
        case .apple:
            try await authenticateWithApple()
        case .email:
            throw AuthenticationError.providerUnavailable
        }
    }

    func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        _ = session
        return currentPresentationAnchor()
    }

    func presentationAnchor(
        for controller: ASAuthorizationController
    ) -> ASPresentationAnchor {
        _ = controller
        return currentPresentationAnchor()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        _ = controller
        guard let credential = authorization.credential
            as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8),
              let attempt = activeAppleAttempt else {
            finishApple(
                with: .failure(AuthenticationError.callbackMismatch)
            )
            return
        }
        let providerDisplayName = credential.fullName.flatMap {
            PersonNameComponentsFormatter().string(from: $0)
        }.flatMap { $0.isEmpty ? nil : $0 }
        let client = authClient
        let profiles = profileClient
        let lifecycle = appleLifecycleClient
        let authorizationCode = credential.authorizationCode.flatMap {
            String(data: $0, encoding: .utf8)
        }
        let requiresServerCredential = configuration.mode == .hostedProduction
        Task {
            do {
                let material = try await client.signInWithAppleIdentityToken(
                    identityToken,
                    nonce: attempt.nonce
                )
                if requiresServerCredential {
                    guard let authorizationCode,
                          !authorizationCode.isEmpty else {
                        try? await client.signOut(
                            accessToken: material.accessToken
                        )
                        throw AuthenticationError.callbackMismatch
                    }
                    do {
                        try await lifecycle.registerAuthorizationCode(
                            authorizationCode,
                            accessToken: material.accessToken
                        )
                    } catch {
                        try? await client.signOut(
                            accessToken: material.accessToken
                        )
                        throw error
                    }
                }
                _ = try await profiles.applyProviderProfileDefaults(
                    displayName: providerDisplayName,
                    avatarURL: nil,
                    accessToken: material.accessToken
                )
                await MainActor.run {
                    self.finishApple(with: .success(material))
                }
            } catch {
                await MainActor.run {
                    self.finishApple(with: .failure(error))
                }
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        _ = controller
        if (error as? ASAuthorizationError)?.code == .canceled {
            finishApple(with: .failure(AuthenticationError.cancelled))
        } else {
            finishApple(
                with: .failure(AuthenticationError.providerUnavailable)
            )
        }
    }

    private func authenticateWithGoogle() async throws -> AuthSessionMaterial {
        let attempt = try materialGenerator.makeAttempt(
            provider: .google,
            environment: configuration.environmentIdentifier,
            now: clock.now()
        )
        try await secureStore.saveOAuthAttempt(attempt)
        let authorizationURL = try authClient.oauthAuthorizationURL(
            provider: .google,
            redirectURL: AppConfiguration.callbackURL,
            codeChallenge: materialGenerator.codeChallenge(
                for: attempt.codeVerifier
            )
        )
        let callbackURL = try await startWebSession(url: authorizationURL)
        let callback = try callbackRouter.parse(
            callbackURL,
            expectedOAuthAttempt: attempt,
            environment: configuration.environmentIdentifier,
            now: clock.now()
        )
        do {
            let material = try await authClient.exchangeCode(
                callback.authorizationCode,
                codeVerifier: attempt.codeVerifier
            )
            try? await secureStore.deleteOAuthAttempt()
            return material
        } catch {
            try? await secureStore.deleteOAuthAttempt()
            throw error
        }
    }

    private func authenticateWithApple() async throws -> AuthSessionMaterial {
        guard appleContinuation == nil else {
            throw AuthenticationError.conflict
        }
        let attempt = try materialGenerator.makeAttempt(
            provider: .apple,
            environment: configuration.environmentIdentifier,
            now: clock.now()
        )
        try await secureStore.saveOAuthAttempt(attempt)
        activeAppleAttempt = attempt

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = materialGenerator.nonceHash(for: attempt.nonce)
        let controller = ASAuthorizationController(
            authorizationRequests: [request]
        )
        controller.delegate = self
        controller.presentationContextProvider = self
        do {
            let material = try await withCheckedThrowingContinuation {
                continuation in
                appleContinuation = continuation
                controller.performRequests()
            }
            try? await secureStore.deleteOAuthAttempt()
            return material
        } catch {
            try? await secureStore.deleteOAuthAttempt()
            throw error
        }
    }

    private func startWebSession(url: URL) async throws -> URL {
        guard webSession == nil else {
            throw AuthenticationError.conflict
        }
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: AppConfiguration.callbackURL.scheme
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    self?.webSession = nil
                    if let error = error as? ASWebAuthenticationSessionError,
                       error.code == .canceledLogin {
                        continuation.resume(
                            throwing: AuthenticationError.cancelled
                        )
                    } else if let callbackURL {
                        continuation.resume(returning: callbackURL)
                    } else {
                        continuation.resume(
                            throwing: AuthenticationError.providerUnavailable
                        )
                    }
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            webSession = session
            guard session.start() else {
                webSession = nil
                continuation.resume(
                    throwing: AuthenticationError.providerUnavailable
                )
                return
            }
        }
    }

    private func finishApple(
        with result: Result<AuthSessionMaterial, Error>
    ) {
        let continuation = appleContinuation
        appleContinuation = nil
        activeAppleAttempt = nil
        switch result {
        case .success(let material):
            continuation?.resume(returning: material)
        case .failure(let error):
            continuation?.resume(throwing: error)
        }
    }

    private func currentPresentationAnchor() -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        if let window = scenes
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow }) {
            return window
        }
        if let scene = scenes.first {
            return ASPresentationAnchor(windowScene: scene)
        }
        preconditionFailure(
            "Autentikasi native memerlukan UIWindowScene yang aktif."
        )
    }
}
