import CryptoKit
import Foundation
import Security

nonisolated struct AuthenticationCallbackRouter: Sendable {
    let callbackURL: URL

    init(callbackURL: URL = AppConfiguration.callbackURL) {
        self.callbackURL = callbackURL
    }

    func parse(
        _ url: URL,
        expectedOAuthAttempt: OAuthAuthorizationAttempt? = nil,
        environment: String,
        now: Date
    ) throws -> AuthenticationCallback {
        guard url.scheme?.lowercased() == callbackURL.scheme?.lowercased(),
              url.host?.lowercased() == callbackURL.host?.lowercased(),
              url.path == callbackURL.path,
              url.fragment == nil || url.fragment?.isEmpty == true,
              let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
              ) else {
            throw AuthenticationError.callbackMismatch
        }
        var values: [String: String] = [:]
        for item in components.queryItems ?? [] {
            guard values[item.name] == nil else {
                throw AuthenticationError.callbackMismatch
            }
            values[item.name] = item.value ?? ""
        }
        if values["error"] != nil || values["error_code"] != nil {
            throw AuthenticationError.cancelled
        }
        guard let code = values["code"], !code.isEmpty else {
            // Tokens in URL fragments are intentionally rejected; mobile Auth
            // callbacks use a one-time authorization code and PKCE instead.
            throw AuthenticationError.callbackMismatch
        }

        let type = values["type"]
        let kind: AuthenticationCallbackKind
        if type == AuthenticationCallbackKind.passwordRecovery.rawValue {
            kind = .passwordRecovery
        } else if type == AuthenticationCallbackKind.emailVerification.rawValue {
            kind = .emailVerification
        } else {
            kind = .oauth
        }

        guard let attempt = expectedOAuthAttempt,
              attempt.isValid(at: now, environment: environment) else {
            throw AuthenticationError.callbackMismatch
        }
        let resolvedKind = type == nil ? attempt.callbackKind : kind
        guard resolvedKind == attempt.callbackKind else {
            throw AuthenticationError.callbackMismatch
        }
        return AuthenticationCallback(
            kind: resolvedKind,
            authorizationCode: code,
            state: values["state"]
        )
    }
}

nonisolated struct SecureOAuthMaterialGenerator: Sendable {
    func makeAttempt(
        provider: AuthenticationProvider,
        callbackKind: AuthenticationCallbackKind = .oauth,
        environment: String,
        now: Date,
        timeToLive: TimeInterval = 5 * 60
    ) throws -> OAuthAuthorizationAttempt {
        OAuthAuthorizationAttempt(
            provider: provider,
            callbackKind: callbackKind,
            state: try randomBase64URL(byteCount: 32),
            nonce: try randomBase64URL(byteCount: 32),
            codeVerifier: try randomBase64URL(byteCount: 48),
            environment: environment,
            expiresAt: now.addingTimeInterval(timeToLive)
        )
    }

    func codeChallenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    func nonceHash(for nonce: String) -> String {
        SHA256.hash(data: Data(nonce.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func randomBase64URL(byteCount: Int) throws -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        guard SecRandomCopyBytes(
            kSecRandomDefault,
            bytes.count,
            &bytes
        ) == errSecSuccess else {
            throw AuthenticationError.unknown
        }
        return Data(bytes).base64URLEncodedString()
    }
}

nonisolated private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
