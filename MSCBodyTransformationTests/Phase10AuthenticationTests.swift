import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Phase 10 authentication")
struct Phase10AuthenticationTests {
    private let now = Date(timeIntervalSince1970: 1_785_909_600)

    @Test("Provider autentikasi mengikuti identity Supabase yang terhubung")
    func connectedProvidersPreferSupabaseIdentities() {
        let providers = SupabaseAuthUser.connectedProviders(
            identityProviderValues: [
                "google",
                "apple",
                "provider-tidak-dikenal",
                "google"
            ],
            appMetadataProviderValues: ["email"]
        )

        #expect(providers == [.apple, .google])
    }

    @Test("Metadata provider dipakai saat daftar identity belum tersedia")
    func connectedProvidersUseMetadataFallback() {
        let providers = SupabaseAuthUser.connectedProviders(
            identityProviderValues: [],
            appMetadataProviderValues: ["google", "google"]
        )

        #expect(providers == [.google])
    }

    @Test("Fixture pengguna lama tetap dapat dibaca tanpa daftar provider")
    func appUserDecodesWithoutAuthenticationProviders() throws {
        let userID = UUID()
        let payload = """
        {
          "id": "\(userID.uuidString)",
          "email": "peserta@example.com",
          "displayName": "Peserta",
          "role": "participant",
          "hasCompletedOnboarding": true,
          "isCoachApprovalPending": false,
          "createdAt": 0
        }
        """

        let user = try JSONDecoder().decode(
            AppUser.self,
            from: Data(payload.utf8)
        )

        #expect(user.authenticationProviders == nil)
    }

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
                environment: [:],
                bundledConfiguration: [
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

    @Test("Build Release membaca konfigurasi publik dari bundle")
    func releaseModeUsesBundledPublicConfiguration() throws {
        let configuration = try AppConfiguration.load(
            environment: [:],
            bundledConfiguration: [
                AppConfiguration.modeEnvironmentKey:
                    AppConfiguration.Mode.hostedProduction.rawValue,
                SupabaseRuntimeConfiguration.urlEnvironmentKey:
                    "https://example-project.supabase.co",
                SupabaseRuntimeConfiguration.publishableKeyEnvironmentKey:
                    "sb_publishable_example"
            ],
            build: .release
        )

        #expect(configuration.mode == .hostedProduction)
        #expect(
            configuration.supabaseURL?.absoluteString
                == "https://example-project.supabase.co"
        )
        #expect(
            configuration.supabasePublishableKey
                == "sb_publishable_example"
        )
    }

    @Test("Build Release tidak dapat diarahkan ke lokal oleh Run scheme")
    func releaseModeIgnoresProcessEnvironmentOverride() throws {
        let configuration = try AppConfiguration.load(
            environment: [
                AppConfiguration.modeEnvironmentKey:
                    AppConfiguration.Mode.debugLocalSupabase.rawValue,
                SupabaseRuntimeConfiguration.urlEnvironmentKey:
                    "http://127.0.0.1:54321",
                SupabaseRuntimeConfiguration.publishableKeyEnvironmentKey:
                    "local-key"
            ],
            bundledConfiguration: [
                AppConfiguration.modeEnvironmentKey:
                    AppConfiguration.Mode.hostedProduction.rawValue,
                SupabaseRuntimeConfiguration.urlEnvironmentKey:
                    "https://example-project.supabase.co",
                SupabaseRuntimeConfiguration.publishableKeyEnvironmentKey:
                    "sb_publishable_example"
            ],
            build: .release
        )

        #expect(configuration.mode == .hostedProduction)
        #expect(
            configuration.supabaseURL?.host
                == "example-project.supabase.co"
        )
    }

    @Test("Build Release gagal tertutup saat konfigurasi bundle kosong")
    func releaseModeFailsClosedWithoutBundledConfiguration() {
        #expect(throws: AuthenticationError.validation) {
            try AppConfiguration.load(
                environment: [:],
                bundledConfiguration: [:],
                build: .release
            )
        }
    }

    @Test("Kode otorisasi Apple memakai kontrak snake case server")
    func appleIdentityLifecycleUsesServerContract() async throws {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [
            Phase13AppleIdentityRequestCaptureURLProtocol.self
        ]
        Phase13AppleIdentityRequestCaptureURLProtocol.capturedRequest = nil
        Phase13AppleIdentityRequestCaptureURLProtocol.capturedBody = nil
        defer {
            Phase13AppleIdentityRequestCaptureURLProtocol.capturedRequest = nil
            Phase13AppleIdentityRequestCaptureURLProtocol.capturedBody = nil
        }
        let runtime = try SupabaseRuntimeConfiguration(
            projectURL: URL(string: "https://example-project.supabase.co")!,
            publishableKey: "sb_publishable_example"
        )
        let client = URLSessionSupabaseAppleIdentityLifecycleClient(
            configuration: runtime,
            session: URLSession(configuration: sessionConfiguration)
        )

        try await client.registerAuthorizationCode(
            "native-authorization-code",
            accessToken: "access-token"
        )

        let request = try #require(
            Phase13AppleIdentityRequestCaptureURLProtocol.capturedRequest
        )
        #expect(
            request.url?.absoluteString
                == "https://example-project.supabase.co/functions/v1/apple-identity-lifecycle"
        )
        #expect(request.value(forHTTPHeaderField: "apikey") == "sb_publishable_example")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access-token")
        let body = try #require(
            Phase13AppleIdentityRequestCaptureURLProtocol.capturedBody
        )
        let object = try #require(
            JSONSerialization.jsonObject(with: body) as? [String: String]
        )
        #expect(object == ["authorization_code": "native-authorization-code"])
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

private final class Phase13AppleIdentityRequestCaptureURLProtocol:
    URLProtocol,
    @unchecked Sendable
{
    nonisolated(unsafe) static var capturedRequest: URLRequest?
    nonisolated(unsafe) static var capturedBody: Data?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.capturedRequest = request
        Self.capturedBody = request.httpBody ?? Self.readBody(
            from: request.httpBodyStream
        )
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(
            self,
            didReceive: response,
            cacheStoragePolicy: .notAllowed
        )
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func readBody(from stream: InputStream?) -> Data? {
        guard let stream else { return nil }
        stream.open()
        defer { stream.close() }
        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 { return nil }
            if count == 0 { break }
            body.append(buffer, count: count)
        }
        return body
    }
}
