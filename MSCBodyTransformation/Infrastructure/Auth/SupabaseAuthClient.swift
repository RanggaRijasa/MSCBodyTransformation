import Foundation

nonisolated struct SupabaseAuthUser: Equatable, Sendable {
    let id: UUID
    let email: String
    let createdAt: Date
    let isEmailConfirmed: Bool
}

nonisolated struct SupabaseAuthResult: Equatable, Sendable {
    let user: SupabaseAuthUser
    let session: AuthSessionMaterial?
}

nonisolated protocol SupabaseAuthClientProviding: Sendable {
    func signUp(
        request: AuthenticationRegistrationRequest,
        codeChallenge: String
    ) async throws -> SupabaseAuthResult
    func signIn(credential: EmailCredential) async throws -> AuthSessionMaterial
    func refresh(refreshToken: String) async throws -> AuthSessionMaterial
    func exchangeCode(
        _ code: String,
        codeVerifier: String
    ) async throws -> AuthSessionMaterial
    func signInWithAppleIdentityToken(
        _ identityToken: String,
        nonce: String
    ) async throws -> AuthSessionMaterial
    func requestPasswordRecovery(
        email: String,
        codeChallenge: String
    ) async throws
    func resendVerification(email: String) async throws
    func updatePassword(
        _ password: String,
        accessToken: String
    ) async throws
    func signOut(accessToken: String) async throws
    func user(accessToken: String) async throws -> SupabaseAuthUser
    func oauthAuthorizationURL(
        provider: AuthenticationProvider,
        redirectURL: URL,
        codeChallenge: String
    ) throws -> URL
}

actor URLSessionSupabaseAuthClient: SupabaseAuthClientProviding {
    private let configuration: SupabaseRuntimeConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        configuration: SupabaseRuntimeConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            if let date = ISO8601DateFormatter.authFractional.date(from: value)
                ?? ISO8601DateFormatter.authStandard.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Tanggal Auth tidak valid."
            )
        }
        self.decoder = decoder
    }

    func signUp(
        request: AuthenticationRegistrationRequest,
        codeChallenge: String
    ) async throws -> SupabaseAuthResult {
        let payload = SignUpPayload(
            email: request.credential.email,
            password: request.credential.password,
            data: ["display_name": request.displayName],
            codeChallenge: codeChallenge,
            codeChallengeMethod: "s256"
        )
        let response: AuthResponseDTO = try await execute(
            path: "auth/v1/signup",
            method: "POST",
            queryItems: [
                URLQueryItem(
                    name: "redirect_to",
                    value: AppConfiguration.callbackURL.absoluteString
                )
            ],
            body: payload
        )
        return try response.result(now: Date())
    }

    func signIn(credential: EmailCredential) async throws -> AuthSessionMaterial {
        let response: AuthResponseDTO = try await execute(
            path: "auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: PasswordPayload(
                email: credential.email,
                password: credential.password
            )
        )
        return try response.sessionMaterial(now: Date())
    }

    func refresh(refreshToken: String) async throws -> AuthSessionMaterial {
        let response: AuthResponseDTO = try await execute(
            path: "auth/v1/token",
            method: "POST",
            queryItems: [
                URLQueryItem(name: "grant_type", value: "refresh_token")
            ],
            body: RefreshPayload(refreshToken: refreshToken)
        )
        return try response.sessionMaterial(now: Date())
    }

    func exchangeCode(
        _ code: String,
        codeVerifier: String
    ) async throws -> AuthSessionMaterial {
        let response: AuthResponseDTO = try await execute(
            path: "auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "pkce")],
            body: PKCEPayload(authCode: code, codeVerifier: codeVerifier)
        )
        return try response.sessionMaterial(now: Date())
    }

    func signInWithAppleIdentityToken(
        _ identityToken: String,
        nonce: String
    ) async throws -> AuthSessionMaterial {
        let response: AuthResponseDTO = try await execute(
            path: "auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "id_token")],
            body: IDTokenPayload(
                provider: "apple",
                idToken: identityToken,
                nonce: nonce
            )
        )
        return try response.sessionMaterial(now: Date())
    }

    func requestPasswordRecovery(
        email: String,
        codeChallenge: String
    ) async throws {
        let _: EmptyResponse = try await execute(
            path: "auth/v1/recover",
            method: "POST",
            queryItems: [
                URLQueryItem(
                    name: "redirect_to",
                    value: AppConfiguration.callbackURL.absoluteString
                )
            ],
            body: RecoveryPayload(
                email: email,
                codeChallenge: codeChallenge,
                codeChallengeMethod: "s256"
            )
        )
    }

    func resendVerification(email: String) async throws {
        let _: EmptyResponse = try await execute(
            path: "auth/v1/resend",
            method: "POST",
            body: ResendPayload(type: "signup", email: email)
        )
    }

    func updatePassword(
        _ password: String,
        accessToken: String
    ) async throws {
        let _: UserDTO = try await execute(
            path: "auth/v1/user",
            method: "PUT",
            body: PasswordUpdatePayload(password: password),
            accessToken: accessToken
        )
    }

    func signOut(accessToken: String) async throws {
        let _: EmptyResponse = try await execute(
            path: "auth/v1/logout",
            method: "POST",
            body: EmptyPayload(),
            accessToken: accessToken
        )
    }

    func user(accessToken: String) async throws -> SupabaseAuthUser {
        let response: UserDTO = try await execute(
            path: "auth/v1/user",
            method: "GET",
            body: Optional<EmptyPayload>.none,
            accessToken: accessToken
        )
        return try response.domainValue
    }

    nonisolated func oauthAuthorizationURL(
        provider: AuthenticationProvider,
        redirectURL: URL,
        codeChallenge: String
    ) throws -> URL {
        guard provider == .google else {
            throw AuthenticationError.providerUnavailable
        }
        let baseURL = configuration.projectURL
            .appendingPathComponent("auth/v1/authorize")
        guard var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw AuthenticationError.validation
        }
        components.queryItems = [
            URLQueryItem(name: "provider", value: provider.rawValue),
            URLQueryItem(name: "redirect_to", value: redirectURL.absoluteString),
            URLQueryItem(name: "scopes", value: "openid email profile"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "s256")
        ]
        guard let url = components.url else {
            throw AuthenticationError.validation
        }
        return url
    }

    private func execute<Response: Decodable, Body: Encodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Body?,
        accessToken: String? = nil
    ) async throws -> Response {
        let baseURL = configuration.projectURL.appendingPathComponent(path)
        guard var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw AuthenticationError.validation
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw AuthenticationError.validation
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue(
            configuration.publishableKey,
            forHTTPHeaderField: "apikey"
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken {
            request.setValue(
                "Bearer \(accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        }
        if let body {
            request.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw AuthenticationError.unknown
            }
            guard (200..<300).contains(response.statusCode) else {
                throw Self.mapError(statusCode: response.statusCode, data: data)
            }
            if Response.self == EmptyResponse.self, data.isEmpty {
                return EmptyResponse() as! Response
            }
            return try decoder.decode(Response.self, from: data)
        } catch let error as AuthenticationError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost,
                 .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                throw AuthenticationError.offline
            case .timedOut:
                throw AuthenticationError.timeout
            case .cancelled:
                throw AuthenticationError.cancelled
            default:
                throw AuthenticationError.unknown
            }
        } catch {
            throw AuthenticationError.unknown
        }
    }

    private static func mapError(statusCode: Int, data: Data) -> AuthenticationError {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let payload = try? decoder.decode(AuthErrorDTO.self, from: data)
        let code = payload?.errorCode ?? payload?.code ?? ""
        switch code {
        case "invalid_credentials", "invalid_grant":
            return .invalidCredential
        case "email_not_confirmed":
            return .verificationRequired
        case "weak_password":
            return .weakPassword
        case "over_email_send_rate_limit", "over_request_rate_limit":
            return .rateLimited
        case "refresh_token_not_found", "refresh_token_already_used":
            return .sessionRevoked
        default:
            break
        }
        switch statusCode {
        case 401:
            return .sessionExpired
        case 409:
            return .conflict
        case 422:
            return .validation
        case 429:
            return .rateLimited
        case 500...599:
            return .unknown
        default:
            return .unknown
        }
    }
}

nonisolated private struct SignUpPayload: Encodable {
    let email: String
    let password: String
    let data: [String: String]
    let codeChallenge: String
    let codeChallengeMethod: String
}

nonisolated private struct PasswordPayload: Encodable {
    let email: String
    let password: String
}

nonisolated private struct RefreshPayload: Encodable {
    let refreshToken: String
}

nonisolated private struct PKCEPayload: Encodable {
    let authCode: String
    let codeVerifier: String
}

nonisolated private struct IDTokenPayload: Encodable {
    let provider: String
    let idToken: String
    let nonce: String
}

nonisolated private struct RecoveryPayload: Encodable {
    let email: String
    let codeChallenge: String
    let codeChallengeMethod: String
}
nonisolated private struct ResendPayload: Encodable {
    let type: String
    let email: String
}
nonisolated private struct PasswordUpdatePayload: Encodable {
    let password: String
}
nonisolated private struct EmptyPayload: Encodable {}
nonisolated private struct EmptyResponse: Codable {}

nonisolated private struct AuthResponseDTO: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: TimeInterval?
    let expiresAt: TimeInterval?
    let user: UserDTO?

    func result(now: Date) throws -> SupabaseAuthResult {
        guard let user else {
            throw AuthenticationError.unknown
        }
        let session: AuthSessionMaterial?
        if accessToken != nil || refreshToken != nil {
            session = try sessionMaterial(now: now)
        } else {
            session = nil
        }
        return SupabaseAuthResult(user: try user.domainValue, session: session)
    }

    func sessionMaterial(now: Date) throws -> AuthSessionMaterial {
        guard let accessToken, let refreshToken, let user else {
            throw AuthenticationError.sessionExpired
        }
        let expiry = expiresAt.map(Date.init(timeIntervalSince1970:))
            ?? now.addingTimeInterval(expiresIn ?? 3600)
        return AuthSessionMaterial(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiry,
            userID: user.id,
            email: user.email ?? ""
        )
    }
}

nonisolated private struct UserDTO: Decodable {
    let id: UUID
    let email: String?
    let createdAt: Date
    let emailConfirmedAt: Date?
    let confirmedAt: Date?

    var domainValue: SupabaseAuthUser {
        get throws {
            SupabaseAuthUser(
                id: id,
                email: email ?? "",
                createdAt: createdAt,
                isEmailConfirmed: emailConfirmedAt != nil || confirmedAt != nil
            )
        }
    }
}

nonisolated private struct AuthErrorDTO: Decodable {
    let code: String?
    let errorCode: String?
}

private extension ISO8601DateFormatter {
    static let authFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let authStandard = ISO8601DateFormatter()
}
