import Foundation

nonisolated struct AuthenticatedProfile: Equatable, Sendable {
    let userID: UUID
    let role: UserRole
    let displayName: String
    let phoneNumber: String?
    let currentCoachID: UUID?
    let providerAvatarURL: URL?
    let memberLevel: MemberLevel?
    let onboardingStatus: ProfileOnboardingStatus
    let accountPurpose: AccountPurpose
}

nonisolated protocol SupabaseProfileClientProviding: Sendable {
    func profile(
        userID: UUID,
        accessToken: String
    ) async throws -> AuthenticatedProfile
    func updateMyProfile(
        displayName: String,
        phoneNumber: String,
        memberLevel: MemberLevel,
        accountPurpose: AccountPurpose,
        accessToken: String
    ) async throws -> AuthenticatedProfile
    func applyProviderProfileDefaults(
        displayName: String?,
        avatarURL: URL?,
        accessToken: String
    ) async throws -> AuthenticatedProfile
    func finalizeParticipantOnboarding(
        coachQROpaqueValue: String,
        accessToken: String
    ) async throws -> AuthenticatedProfile
    func prepareCoachApplicationHandoff(
        accessToken: String
    ) async throws -> AuthenticatedProfile
    func pendingProgramEnrollmentAvailability(
        programID: UUID,
        accessToken: String
    ) async throws -> PendingProgramEnrollmentAvailability
    func cancelProvisionalIdentity(accessToken: String) async throws
}

actor URLSessionSupabaseProfileClient: SupabaseProfileClientProviding {
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
        self.decoder = decoder
    }

    func profile(
        userID: UUID,
        accessToken: String
    ) async throws -> AuthenticatedProfile {
        let values: [ProfileDTO] = try await execute(
            path: "rest/v1/profiles",
            method: "GET",
            queryItems: [
                URLQueryItem(
                    name: "select",
                    value: "user_id,role,display_name,phone_number,current_coach_id,provider_avatar_url,member_level,onboarding_status,account_purpose"
                ),
                URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)")
            ],
            body: Optional<EmptyPayload>.none,
            accessToken: accessToken
        )
        guard let profile = values.first, values.count == 1 else {
            throw AuthenticationError.profileProvisioning
        }
        return try profile.domainValue
    }

    func updateMyProfile(
        displayName: String,
        phoneNumber: String,
        memberLevel: MemberLevel,
        accountPurpose: AccountPurpose,
        accessToken: String
    ) async throws -> AuthenticatedProfile {
        let profile: ProfileDTO = try await execute(
            path: "rest/v1/rpc/update_my_profile",
            method: "POST",
            body: UpdateProfilePayload(
                newDisplayName: displayName,
                newPhoneNumber: phoneNumber,
                newMemberLevel: memberLevel.rawValue,
                newAccountPurpose: accountPurpose.rawValue
            ),
            accessToken: accessToken
        )
        return try profile.domainValue
    }

    func finalizeParticipantOnboarding(
        coachQROpaqueValue: String,
        accessToken: String
    ) async throws -> AuthenticatedProfile {
        let profile: ProfileDTO = try await execute(
            path: "rest/v1/rpc/finalize_participant_onboarding",
            method: "POST",
            body: CoachQRPayload(coachQR: coachQROpaqueValue),
            accessToken: accessToken
        )
        return try profile.domainValue
    }

    func applyProviderProfileDefaults(
        displayName: String?,
        avatarURL: URL?,
        accessToken: String
    ) async throws -> AuthenticatedProfile {
        let profile: ProfileDTO = try await execute(
            path: "rest/v1/rpc/apply_provider_profile_defaults",
            method: "POST",
            body: ProviderProfileDefaultsPayload(
                providerDisplayName: displayName,
                providerAvatarURL: avatarURL?.absoluteString
            ),
            accessToken: accessToken
        )
        return try profile.domainValue
    }

    func prepareCoachApplicationHandoff(
        accessToken: String
    ) async throws -> AuthenticatedProfile {
        let profile: ProfileDTO = try await execute(
            path: "rest/v1/rpc/prepare_coach_application_handoff",
            method: "POST",
            body: EmptyPayload(),
            accessToken: accessToken
        )
        return try profile.domainValue
    }

    func pendingProgramEnrollmentAvailability(
        programID: UUID,
        accessToken: String
    ) async throws -> PendingProgramEnrollmentAvailability {
        try await execute(
            path: "rest/v1/rpc/pending_program_enrollment_availability",
            method: "POST",
            body: ProgramIDPayload(targetProgramID: programID),
            accessToken: accessToken
        )
    }

    func cancelProvisionalIdentity(accessToken: String) async throws {
        let _: Bool = try await execute(
            path: "rest/v1/rpc/cancel_my_provisional_identity",
            method: "POST",
            body: EmptyPayload(),
            accessToken: accessToken
        )
    }

    private func execute<Response: Decodable, Body: Encodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Body?,
        accessToken: String
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
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw AuthenticationError.unknown
            }
            guard (200..<300).contains(response.statusCode) else {
                switch response.statusCode {
                case 401:
                    throw AuthenticationError.sessionExpired
                case 403:
                    throw AuthenticationError.roleLoad
                case 409:
                    throw AuthenticationError.conflict
                default:
                    throw AuthenticationError.profileProvisioning
                }
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
            default:
                throw AuthenticationError.unknown
            }
        } catch {
            throw AuthenticationError.unknown
        }
    }
}

nonisolated private struct ProfileDTO: Decodable {
    let userId: UUID
    let role: String
    let displayName: String
    let phoneNumber: String?
    let currentCoachId: UUID?
    let providerAvatarUrl: URL?
    let memberLevel: String?
    let onboardingStatus: String
    let accountPurpose: String

    var domainValue: AuthenticatedProfile {
        get throws {
            guard let role = UserRole(rawValue: role),
                  let onboardingStatus = ProfileOnboardingStatus(
                    rawValue: onboardingStatus
                  ),
                  let accountPurpose = AccountPurpose(rawValue: accountPurpose)
            else {
                throw AuthenticationError.roleLoad
            }
            let memberLevel = memberLevel.flatMap(MemberLevel.init(rawValue:))
            return AuthenticatedProfile(
                userID: userId,
                role: role,
                displayName: displayName,
                phoneNumber: phoneNumber,
                currentCoachID: currentCoachId,
                providerAvatarURL: providerAvatarUrl,
                memberLevel: memberLevel,
                onboardingStatus: onboardingStatus,
                accountPurpose: accountPurpose
            )
        }
    }
}

actor SupabaseParticipantProfileRepository: ProfileRepository {
    private let sessionRepository: any SessionRepository
    private let profileClient: any SupabaseProfileClientProviding
    private let fallback: any ProfileRepository

    init(
        sessionRepository: any SessionRepository,
        profileClient: any SupabaseProfileClientProviding,
        fallback: any ProfileRepository
    ) {
        self.sessionRepository = sessionRepository
        self.profileClient = profileClient
        self.fallback = fallback
    }

    func user(id: UUID) async throws -> AppUser {
        let session = try await sessionRepository.loadCurrentSession()
        if let user = session.user, user.id == id {
            return user
        }
        return try await fallback.user(id: id)
    }

    func participantProfile(userID: UUID) async throws -> ParticipantProfile {
        let token = try await sessionRepository.validAccessToken()
        let profile = try await profileClient.profile(
            userID: userID,
            accessToken: token
        )
        guard profile.role == .participant else {
            throw DomainError.permissionDenied
        }
        return Self.participantProfile(from: profile)
    }

    func save(
        participantProfile: ParticipantProfile
    ) async throws -> ParticipantProfile {
        guard let phoneNumber = participantProfile.phoneNumber,
              let memberLevel = participantProfile.memberLevel else {
            throw DomainError.validation(
                field: "profile",
                reason: "Lengkapi nomor HP dan level Member."
            )
        }
        let token = try await sessionRepository.validAccessToken()
        let updated = try await profileClient.updateMyProfile(
            displayName: participantProfile.displayName,
            phoneNumber: phoneNumber,
            memberLevel: memberLevel,
            accountPurpose: .participant,
            accessToken: token
        )
        var result = Self.participantProfile(from: updated)
        result.city = participantProfile.city
        result.localPhotoReference = participantProfile.localPhotoReference
        return result
    }

    func coachProfile(userID: UUID) async throws -> CoachProfile {
        try await fallback.coachProfile(userID: userID)
    }

    func save(coachProfile: CoachProfile) async throws -> CoachProfile {
        try await fallback.save(coachProfile: coachProfile)
    }

    private static func participantProfile(
        from profile: AuthenticatedProfile
    ) -> ParticipantProfile {
        ParticipantProfile(
            id: profile.userID,
            userID: profile.userID,
            coachID: profile.currentCoachID,
            displayName: profile.displayName,
            city: "",
            phoneNumber: profile.phoneNumber,
            localPhotoReference: profile.providerAvatarURL?.absoluteString,
            memberLevel: profile.memberLevel
        )
    }
}

nonisolated private struct UpdateProfilePayload: Encodable {
    let newDisplayName: String
    let newPhoneNumber: String
    let newMemberLevel: String
    let newAccountPurpose: String
}

nonisolated private struct ProviderProfileDefaultsPayload: Encodable {
    let providerDisplayName: String?
    let providerAvatarURL: String?
}

nonisolated private struct CoachQRPayload: Encodable { let coachQR: String }
nonisolated private struct ProgramIDPayload: Encodable {
    let targetProgramID: UUID
}
nonisolated private struct EmptyPayload: Codable {}
