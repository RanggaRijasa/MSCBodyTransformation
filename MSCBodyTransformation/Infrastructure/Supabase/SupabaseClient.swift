import Foundation

nonisolated struct SupabaseRuntimeConfiguration:
    Equatable,
    Sendable
{
    static let urlEnvironmentKey = "MSC_SUPABASE_URL"
    static let publishableKeyEnvironmentKey =
        "MSC_SUPABASE_PUBLISHABLE_KEY"

    let projectURL: URL
    let publishableKey: String

    init(projectURL: URL, publishableKey: String) throws {
        guard let scheme = projectURL.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              projectURL.host != nil else {
            throw DomainError.validation(
                field: "supabaseURL",
                reason: "URL Supabase tidak valid."
            )
        }
        guard !publishableKey.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            throw DomainError.validation(
                field: "supabasePublishableKey",
                reason: "Publishable key Supabase belum tersedia."
            )
        }
        self.projectURL = projectURL
        self.publishableKey = publishableKey
    }

    static func debugLocal(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> Self {
#if DEBUG
        guard let rawURL = environment[urlEnvironmentKey],
              let projectURL = URL(string: rawURL),
              let publishableKey = environment[
                publishableKeyEnvironmentKey
              ] else {
            throw DomainError.validation(
                field: "supabaseConfiguration",
                reason: "Konfigurasi Supabase Debug belum tersedia."
            )
        }
        guard projectURL.host == "127.0.0.1"
                || projectURL.host == "localhost" else {
            throw DomainError.validation(
                field: "supabaseURL",
                reason: "Mode lokal hanya menerima alamat loopback."
            )
        }
        return try Self(
            projectURL: projectURL,
            publishableKey: publishableKey
        )
#else
        throw DomainError.permissionDenied
#endif
    }
}

nonisolated protocol SupabaseAccessTokenProviding: Sendable {
    func accessToken() async throws -> String
}

nonisolated struct FixedSupabaseAccessTokenProvider:
    SupabaseAccessTokenProviding,
    Sendable
{
    private let token: String

    init(token: String) {
        self.token = token
    }

    func accessToken() async throws -> String {
        guard !token.isEmpty else {
            throw DomainError.sessionExpired
        }
        return token
    }
}

nonisolated struct SessionSupabaseAccessTokenProvider:
    SupabaseAccessTokenProviding,
    Sendable
{
    private let sessionRepository: any SessionRepository

    init(sessionRepository: any SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    func accessToken() async throws -> String {
        try await sessionRepository.validAccessToken()
    }
}

nonisolated enum SupabaseHTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

nonisolated struct SupabaseRequest: Sendable {
    let method: SupabaseHTTPMethod
    let path: String
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?
}

nonisolated protocol SupabaseClientProviding: Sendable {
    func execute(_ request: SupabaseRequest) async throws -> Data
}

nonisolated enum SupabaseClientAuthorization: Sendable {
    case publicAnon
    case authenticated(any SupabaseAccessTokenProviding)
}

actor URLSessionSupabaseClient: SupabaseClientProviding {
    private let configuration: SupabaseRuntimeConfiguration
    private let authorization: SupabaseClientAuthorization
    private let session: URLSession

    init(
        configuration: SupabaseRuntimeConfiguration,
        accessTokenProvider: any SupabaseAccessTokenProviding,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        authorization = .authenticated(accessTokenProvider)
        self.session = session
    }

    init(
        configuration: SupabaseRuntimeConfiguration,
        authorization: SupabaseClientAuthorization,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.authorization = authorization
        self.session = session
    }

    func execute(_ request: SupabaseRequest) async throws -> Data {
        let url = try makeURL(request)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = 30
        for (name, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }
        urlRequest.setValue(
            configuration.publishableKey,
            forHTTPHeaderField: "apikey"
        )
        switch authorization {
        case .publicAnon:
            urlRequest.setValue(nil, forHTTPHeaderField: "Authorization")
        case .authenticated(let accessTokenProvider):
            let token = try await accessTokenProvider.accessToken()
            urlRequest.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DomainError.unknown
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw SupabaseErrorMapper.map(
                    statusCode: httpResponse.statusCode,
                    responseData: data
                )
            }
            return data
        } catch let error as DomainError {
            throw error
        } catch let error as URLError {
            throw SupabaseErrorMapper.map(urlError: error)
        } catch {
            throw DomainError.unknown
        }
    }

    private func makeURL(_ request: SupabaseRequest) throws -> URL {
        let baseURL = configuration.projectURL
            .appendingPathComponent(
                request.path.trimmingCharacters(
                    in: CharacterSet(charactersIn: "/")
                )
            )
        guard var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw DomainError.validation(
                field: "supabaseRequest",
                reason: "Permintaan Supabase tidak valid."
            )
        }
        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }
        guard let url = components.url else {
            throw DomainError.validation(
                field: "supabaseRequest",
                reason: "Permintaan Supabase tidak valid."
            )
        }
        return url
    }
}

nonisolated enum SupabaseErrorMapper {
    private struct ErrorPayload: Decodable {
        let code: String?
        let message: String?
        let hint: String?
    }

    static func map(
        statusCode: Int,
        responseData: Data
    ) -> DomainError {
        let payload = try? JSONDecoder().decode(
            ErrorPayload.self,
            from: responseData
        )
        let serverCode = payload?.message ?? payload?.code ?? ""

        switch serverCode {
        case "permission_denied":
            return .permissionDenied
        case "coach_qr_invalid":
            return .validation(
                field: "coachQR",
                reason: "QR Coach tidak valid."
            )
        case "coach_mismatch":
            return .conflict(
                reason: "QR berasal dari Coach yang berbeda."
            )
        case "program_full":
            return .conflict(reason: "Kapasitas program sudah penuh.")
        case "registration_closed":
            return .conflict(
                reason: "Pendaftaran program sudah ditutup."
            )
        case "payment_required":
            return .conflict(
                reason: "Pembayaran program belum terverifikasi."
            )
        case "coach_required", "coach_invalid":
            return .validation(
                field: "coach",
                reason: "Peserta memerlukan Coach aktif yang disetujui."
            )
        case "program_unavailable", "step_unavailable":
            return .conflict(
                reason: "Program atau langkah belum tersedia."
            )
        case "answers_incomplete", "answer_type_invalid",
             "answer_option_invalid", "private_photo_invalid":
            return .validation(
                field: "answers",
                reason: "Jawaban belum lengkap atau tidak valid."
            )
        case "submission_already_finalized",
             "submission_already_reviewed",
             "idempotency_key_mismatch":
            return .conflict(reason: serverCode)
        default:
            break
        }

        switch statusCode {
        case 400, 422:
            return .validation(
                field: "request",
                reason: payload?.message ?? "Permintaan tidak valid."
            )
        case 401:
            return .sessionExpired
        case 403:
            return .permissionDenied
        case 404:
            return .notFound(resource: "Supabase")
        case 409:
            return .conflict(
                reason: payload?.message ?? "Data mengalami konflik."
            )
        case 408, 504:
            return .timeout
        default:
            return .unknown
        }
    }

    static func map(urlError: URLError) -> DomainError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return .offline
        case .timedOut:
            return .timeout
        case .userAuthenticationRequired:
            return .sessionExpired
        default:
            return .unknown
        }
    }
}
