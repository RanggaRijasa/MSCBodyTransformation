import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Phase 10 authentication")
struct Phase10AuthenticationTests {
    private let now = Date(timeIntervalSince1970: 1_785_909_600)

    @Test("Email dinormalisasi tanpa mengubah password")
    func emailCredentialNormalizesOnlyEmail() throws {
        let credential = try EmailCredential(
            email: "  USER@Example.COM ",
            password: "  Rahasia-123  "
        )

        #expect(credential.email == "user@example.com")
        #expect(credential.password == "  Rahasia-123  ")
    }

    @Test("Password lemah ditolak")
    func weakPasswordIsRejected() {
        #expect(throws: AuthenticationError.weakPassword) {
            try EmailCredential(email: "user@example.com", password: "pendek")
        }
    }

    @Test("Build Debug menolak endpoint hosted pada mode lokal")
    func debugLocalModeRejectsHostedEndpoint() {
        #expect(throws: AuthenticationError.validation) {
            try AppConfiguration.load(
                environment: [
                    AppConfiguration.modeEnvironmentKey:
                        AppConfiguration.Mode.debugLocalSupabase.rawValue,
                    SupabaseRuntimeConfiguration.urlEnvironmentKey:
                        "https://project.supabase.co",
                    SupabaseRuntimeConfiguration.publishableKeyEnvironmentKey:
                        "public-key"
                ],
                build: .debug
            )
        }
    }

    @Test("Build Release menolak endpoint lokal")
    func releaseModeRejectsLocalEndpoint() {
        #expect(throws: AuthenticationError.validation) {
            try AppConfiguration.load(
                environment: [
                    AppConfiguration.modeEnvironmentKey:
                        AppConfiguration.Mode.hostedProduction.rawValue,
                    SupabaseRuntimeConfiguration.urlEnvironmentKey:
                        "http://127.0.0.1:54321",
                    SupabaseRuntimeConfiguration.publishableKeyEnvironmentKey:
                        "public-key"
                ],
                build: .release
            )
        }
    }

    @Test("Pending enrollment intent mematuhi TTL dan environment")
    func pendingEnrollmentIntentValidatesTTLAndEnvironment() {
        let intent = PendingEnrollmentIntent(
            programID: UUID(),
            coachQROpaqueValue: "opaque-test-value",
            createdAt: now,
            timeToLive: 60,
            nonce: UUID(),
            environment: "debug_local_supabase"
        )

        #expect(
            intent.isValid(
                at: now.addingTimeInterval(59),
                environment: "debug_local_supabase"
            )
        )
        #expect(
            !intent.isValid(
                at: now.addingTimeInterval(60),
                environment: "debug_local_supabase"
            )
        )
        #expect(!intent.isValid(at: now, environment: "hosted_production"))
    }

    @Test("OAuth callback menerima code dengan attempt PKCE yang valid")
    func callbackParserAcceptsValidOAuthAttempt() throws {
        let attempt = oauthAttempt()
        let callback = try AuthenticationCallbackRouter().parse(
            URL(
                string:
                    "mscbodytransformation://auth/callback?code=one-time"
            )!,
            expectedOAuthAttempt: attempt,
            environment: "debug_local_supabase",
            now: now
        )

        #expect(callback.kind == .oauth)
        #expect(callback.authorizationCode == "one-time")
    }

    @Test("Callback menolak code ganda dan token dalam fragment", arguments: [
        "mscbodytransformation://auth/callback?code=one&code=two",
        "mscbodytransformation://auth/callback?code=one-time#access_token=forbidden"
    ])
    func callbackParserRejectsMismatch(urlValue: String) {
        #expect(throws: AuthenticationError.callbackMismatch) {
            try AuthenticationCallbackRouter().parse(
                URL(string: urlValue)!,
                expectedOAuthAttempt: oauthAttempt(),
                environment: "debug_local_supabase",
                now: now
            )
        }
    }

    @Test("Callback email memakai jenis attempt saat redirect tidak membawa type")
    func emailCallbackInfersExpectedKind() throws {
        let attempt = OAuthAuthorizationAttempt(
            provider: .email,
            callbackKind: .passwordRecovery,
            state: "unused",
            nonce: "nonce",
            codeVerifier: "verifier",
            environment: "debug_local_supabase",
            expiresAt: now.addingTimeInterval(60)
        )
        let callback = try AuthenticationCallbackRouter().parse(
            URL(
                string:
                    "mscbodytransformation://auth/callback?code=recovery-code"
            )!,
            expectedOAuthAttempt: attempt,
            environment: "debug_local_supabase",
            now: now
        )

        #expect(callback.kind == .passwordRecovery)
    }

    @Test("Secure store in-memory menyimpan dan membersihkan material privat")
    func secureStoreRoundTrip() async throws {
        let store = InMemorySessionSecureStore()
        let session = AuthSessionMaterial(
            accessToken: "access-test",
            refreshToken: "refresh-test",
            expiresAt: now.addingTimeInterval(3600),
            userID: UUID(),
            email: "user@example.com"
        )
        let intent = PendingEnrollmentIntent(
            programID: UUID(),
            createdAt: now,
            nonce: UUID(),
            environment: "debug_local_supabase"
        )
        await store.saveSession(session)
        await store.savePendingEnrollmentIntent(intent)

        #expect(await store.loadSession() == session)
        #expect(await store.loadPendingEnrollmentIntent() == intent)

        await store.deleteAll()
        #expect(await store.loadSession() == nil)
        #expect(await store.loadPendingEnrollmentIntent() == nil)
    }

    @Test("Keychain menyimpan material hanya pada service test")
    func keychainRoundTrip() async throws {
        let store = KeychainSessionSecureStore(
            service: "id.msc.body-transformation.tests.\(UUID().uuidString)"
        )
        let session = AuthSessionMaterial(
            accessToken: "access-test",
            refreshToken: "refresh-test",
            expiresAt: now.addingTimeInterval(3600),
            userID: UUID(),
            email: "user@example.com"
        )
        try await store.saveSession(session)
        #expect(try await store.loadSession() == session)
        try await store.deleteAll()
        #expect(try await store.loadSession() == nil)
    }

    private func oauthAttempt() -> OAuthAuthorizationAttempt {
        OAuthAuthorizationAttempt(
            provider: .google,
            callbackKind: .oauth,
            state: "expected",
            nonce: "nonce",
            codeVerifier: "verifier",
            environment: "debug_local_supabase",
            expiresAt: now.addingTimeInterval(60)
        )
    }
}
