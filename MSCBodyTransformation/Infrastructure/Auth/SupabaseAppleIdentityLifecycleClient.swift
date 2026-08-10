import Foundation

nonisolated protocol SupabaseAppleIdentityLifecycleClientProviding: Sendable {
    func registerAuthorizationCode(
        _ authorizationCode: String,
        accessToken: String
    ) async throws
}

actor URLSessionSupabaseAppleIdentityLifecycleClient:
    SupabaseAppleIdentityLifecycleClientProviding
{
    private let configuration: SupabaseRuntimeConfiguration
    private let session: URLSession

    init(
        configuration: SupabaseRuntimeConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func registerAuthorizationCode(
        _ authorizationCode: String,
        accessToken: String
    ) async throws {
        let trimmedCode = authorizationCode.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedCode.isEmpty else {
            throw AuthenticationError.callbackMismatch
        }
        let url = configuration.projectURL.appendingPathComponent(
            "functions/v1/apple-identity-lifecycle"
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue(
            configuration.publishableKey,
            forHTTPHeaderField: "apikey"
        )
        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(
            AppleAuthorizationCodePayload(authorizationCode: trimmedCode)
        )

        do {
            let (_, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw AuthenticationError.providerUnavailable
            }
            guard (200..<300).contains(response.statusCode) else {
                switch response.statusCode {
                case 400:
                    throw AuthenticationError.callbackMismatch
                case 401:
                    throw AuthenticationError.sessionRevoked
                default:
                    throw AuthenticationError.providerUnavailable
                }
            }
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
                throw AuthenticationError.providerUnavailable
            }
        } catch {
            throw AuthenticationError.providerUnavailable
        }
    }
}

nonisolated private struct AppleAuthorizationCodePayload: Encodable {
    let authorizationCode: String

    private enum CodingKeys: String, CodingKey {
        case authorizationCode = "authorization_code"
    }
}
