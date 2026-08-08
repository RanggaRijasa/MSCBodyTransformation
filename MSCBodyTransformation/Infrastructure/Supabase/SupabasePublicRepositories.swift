import Foundation

nonisolated struct SupabasePublicProgramRepository:
    PublicProgramRepository,
    Sendable
{
    private let client: any SupabaseClientProviding

    init(client: any SupabaseClientProviding) {
        self.client = client
    }

    func programs() async throws -> [Program] {
        try await load(targetProgramID: nil, limit: 50)
    }

    func program(id: UUID) async throws -> Program {
        guard let program = try await load(
            targetProgramID: id,
            limit: 1
        ).first else {
            throw DomainError.notFound(resource: "Program")
        }
        return program
    }

    private func load(
        targetProgramID: UUID?,
        limit: Int
    ) async throws -> [Program] {
        struct Body: Encodable {
            let targetProgramID: UUID?
            let resultLimit: Int
            let resultOffset: Int

            enum CodingKeys: String, CodingKey {
                case targetProgramID = "target_program_id"
                case resultLimit = "result_limit"
                case resultOffset = "result_offset"
            }
        }

        let data = try await client.execute(
            try publicRPCRequest(
                name: "list_public_programs",
                body: Body(
                    targetProgramID: targetProgramID,
                    resultLimit: limit,
                    resultOffset: 0
                )
            )
        )
        do {
            return try SupabaseJSON.decoder
                .decode([SupabaseProgramDTO].self, from: data)
                .map { try $0.domain() }
        } catch let error as SupabaseDTOError {
            throw mapPublicDTOError(error)
        } catch {
            throw DomainError.unknown
        }
    }
}

nonisolated struct SupabasePublicCoachDirectoryRepository:
    PublicCoachDirectoryRepository,
    Sendable
{
    private let client: any SupabaseClientProviding

    init(client: any SupabaseClientProviding) {
        self.client = client
    }

    func publicCoaches() async throws -> [CoachProfile] {
        struct Body: Encodable {
            let resultLimit = 100
            let resultOffset = 0

            enum CodingKeys: String, CodingKey {
                case resultLimit = "result_limit"
                case resultOffset = "result_offset"
            }
        }

        let data = try await client.execute(
            try publicRPCRequest(
                name: "list_public_coaches",
                body: Body()
            )
        )
        do {
            return try SupabaseJSON.decoder
                .decode([SupabasePublicCoachDTO].self, from: data)
                .map { $0.domain() }
        } catch {
            throw DomainError.unknown
        }
    }
}

nonisolated struct SupabasePublicLeaderboardRepository:
    PublicLeaderboardRepository,
    Sendable
{
    private let client: any SupabaseClientProviding

    init(client: any SupabaseClientProviding) {
        self.client = client
    }

    func leaderboard(
        programID: UUID
    ) async throws -> [LeaderboardEntry] {
        struct Body: Encodable {
            let targetProgramID: UUID
            let resultLimit = 100
            let resultOffset = 0

            enum CodingKeys: String, CodingKey {
                case targetProgramID = "target_program_id"
                case resultLimit = "result_limit"
                case resultOffset = "result_offset"
            }
        }

        let data = try await client.execute(
            try publicRPCRequest(
                name: "list_public_leaderboard",
                body: Body(targetProgramID: programID)
            )
        )
        do {
            return try SupabaseJSON.decoder
                .decode([SupabasePublicLeaderboardDTO].self, from: data)
                .map { $0.domain() }
        } catch {
            throw DomainError.unknown
        }
    }

    func winners(programID: UUID) async throws -> [ProgramWinner] {
        struct Body: Encodable {
            let targetProgramID: UUID
            let resultLimit = 5
            let resultOffset = 0

            enum CodingKeys: String, CodingKey {
                case targetProgramID = "target_program_id"
                case resultLimit = "result_limit"
                case resultOffset = "result_offset"
            }
        }

        let data = try await client.execute(
            try publicRPCRequest(
                name: "list_public_winners",
                body: Body(targetProgramID: programID)
            )
        )
        do {
            return try SupabaseJSON.decoder
                .decode([SupabasePublicWinnerDTO].self, from: data)
                .map { $0.domain() }
        } catch {
            throw DomainError.unknown
        }
    }
}

nonisolated struct SupabasePublicManagedContentRepository:
    PublicManagedContentRepository,
    Sendable
{
    private let client: any SupabaseClientProviding

    init(client: any SupabaseClientProviding) {
        self.client = client
    }

    func managedContent() async throws -> [ManagedContent] {
        struct Body: Encodable {
            let resultLimit = 100
            let resultOffset = 0

            enum CodingKeys: String, CodingKey {
                case resultLimit = "result_limit"
                case resultOffset = "result_offset"
            }
        }

        let data = try await client.execute(
            try publicRPCRequest(
                name: "list_public_winner_posters",
                body: Body()
            )
        )
        do {
            return try SupabaseJSON.decoder
                .decode([SupabasePublicManagedContentDTO].self, from: data)
                .map { try $0.domain() }
        } catch let error as SupabaseDTOError {
            throw mapPublicDTOError(error)
        } catch {
            throw DomainError.unknown
        }
    }
}

private nonisolated func publicRPCRequest<Body: Encodable>(
    name: String,
    body: Body
) throws -> SupabaseRequest {
    SupabaseRequest(
        method: .post,
        path: "/rest/v1/rpc/\(name)",
        headers: ["Content-Type": "application/json"],
        body: try SupabaseJSON.encoder.encode(body)
    )
}

private nonisolated func mapPublicDTOError(
    _ error: SupabaseDTOError
) -> DomainError {
    switch error {
    case let .invalidField(field):
        .validation(
            field: field,
            reason: "Data publik dari server tidak valid."
        )
    }
}
