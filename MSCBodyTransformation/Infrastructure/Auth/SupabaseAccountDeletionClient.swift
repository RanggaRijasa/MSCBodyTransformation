import Foundation

nonisolated protocol SupabaseAccountDeletionClientProviding: Sendable {
    func deleteAccount(accessToken: String) async throws
}

actor URLSessionSupabaseAccountDeletionClient:
    SupabaseAccountDeletionClientProviding
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

    func deleteAccount(accessToken: String) async throws {
        let url = configuration.projectURL
            .appendingPathComponent("functions/v1/delete-account")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue(
            configuration.publishableKey,
            forHTTPHeaderField: "apikey"
        )
        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw AuthenticationError.accountDeletionFailed
            }
            guard (200..<300).contains(response.statusCode) else {
                throw Self.mapError(
                    statusCode: response.statusCode,
                    data: data
                )
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
                throw AuthenticationError.accountDeletionFailed
            }
        } catch {
            throw AuthenticationError.accountDeletionFailed
        }
    }

    private static func mapError(
        statusCode: Int,
        data: Data
    ) -> AuthenticationError {
        let payload = try? JSONDecoder().decode(
            AccountDeletionErrorPayload.self,
            from: data
        )
        switch payload?.code {
        case "recent_reauthentication_required":
            return .recentReauthenticationRequired
        case "admin_account_deletion_not_allowed":
            return .accountDeletionNotAllowed
        case "account_relationships_require_transfer":
            return .accountRelationshipsRequireTransfer
        default:
            break
        }
        if statusCode == 401 {
            return .recentReauthenticationRequired
        }
        return .accountDeletionFailed
    }
}

nonisolated private struct AccountDeletionErrorPayload: Decodable {
    let code: String
}
