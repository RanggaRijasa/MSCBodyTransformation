import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Phase 11 public Guest reads", .serialized)
struct Phase11PublicGuestReadsTests {
    @Test("Public transport sends apikey without user bearer token")
    func publicTransportOmitsAuthorization() async throws {
        let configuration = try SupabaseRuntimeConfiguration(
            projectURL: URL(string: "https://public.test.invalid")!,
            publishableKey: "publishable-test-key"
        )
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [
            Phase11RequestCaptureURLProtocol.self
        ]
        let session = URLSession(configuration: sessionConfiguration)
        Phase11RequestCaptureURLProtocol.capturedRequest = nil
        defer {
            Phase11RequestCaptureURLProtocol.capturedRequest = nil
        }
        let client = URLSessionSupabaseClient(
            configuration: configuration,
            authorization: .publicAnon,
            session: session
        )

        _ = try await client.execute(
            SupabaseRequest(
                method: .post,
                path: "/rest/v1/rpc/list_public_programs",
                headers: [
                    "Content-Type": "application/json",
                    "Authorization": "Bearer must-not-leak"
                ],
                body: Data("{}".utf8)
            )
        )
        let request = try #require(
            Phase11RequestCaptureURLProtocol.capturedRequest
        )

        #expect(
            request.value(forHTTPHeaderField: "apikey")
                == "publishable-test-key"
        )
        #expect(
            request.value(forHTTPHeaderField: "Authorization") == nil
        )
    }

    @Test("Public DTOs map only public identifiers and total score")
    func publicDTOsMapSafeDomainValues() throws {
        let coach = try SupabaseJSON.decoder.decode(
            SupabasePublicCoachDTO.self,
            from: Data(
                """
                {
                  "id": "d1000000-0000-0000-0000-000000000001",
                  "display_name": "Coach Publik",
                  "biography": "",
                  "city": "Denpasar",
                  "photo_reference": null
                }
                """.utf8
            )
        ).domain()
        let leaderboard = try SupabaseJSON.decoder.decode(
            SupabasePublicLeaderboardDTO.self,
            from: Data(
                """
                {
                  "id": "d2000000-0000-0000-0000-000000000001",
                  "program_id": "d3000000-0000-0000-0000-000000000001",
                  "participant_id":
                    "d4000000-0000-0000-0000-000000000001",
                  "participant_display_name": "Peserta Publik",
                  "rank": 1,
                  "progress_percentage": 100,
                  "total_points": 425
                }
                """.utf8
            )
        ).domain()

        #expect(coach.id == coach.userID)
        #expect(coach.enrollmentIdentifier.isEmpty)
        #expect(coach.isPublic)
        #expect(coach.isApproved)
        #expect(leaderboard.score.totalPoints == 425)
        #expect(leaderboard.score.weightPoints == 0)
        #expect(!leaderboard.isCurrentUser)
    }

    @Test("Public repositories use fixed RPC contracts")
    func publicRepositoriesUseRPCs() async throws {
        let programID = UUID(
            uuidString: "d3000000-0000-0000-0000-000000000001"
        )!
        let client = Phase11RecordingSupabaseClient(
            responses: [
                Data(Self.programPayload.utf8),
                Data(Self.coachPayload.utf8),
                Data(Self.leaderboardPayload.utf8),
                Data(Self.winnerPayload.utf8),
                Data(Self.contentPayload.utf8)
            ]
        )

        let programs = try await SupabasePublicProgramRepository(
            client: client
        ).programs()
        let coaches = try await SupabasePublicCoachDirectoryRepository(
            client: client
        ).publicCoaches()
        let leaderboardRepository = SupabasePublicLeaderboardRepository(
            client: client
        )
        let leaderboard = try await leaderboardRepository.leaderboard(
            programID: programID
        )
        let winners = try await leaderboardRepository.winners(
            programID: programID
        )
        let content = try await SupabasePublicManagedContentRepository(
            client: client
        ).managedContent()
        let requests = await client.requests()

        #expect(programs.count == 1)
        #expect(coaches.count == 1)
        #expect(leaderboard.first?.score.totalPoints == 425)
        #expect(winners.first?.rank == 1)
        #expect(content.first?.kind == .winnerBanner)
        #expect(
            requests.map(\.path) == [
                "/rest/v1/rpc/list_public_programs",
                "/rest/v1/rpc/list_public_coaches",
                "/rest/v1/rpc/list_public_leaderboard",
                "/rest/v1/rpc/list_public_winners",
                "/rest/v1/rpc/list_public_winner_posters"
            ]
        )
    }

    private static let programPayload = """
    [
      {
        "id": "d3000000-0000-0000-0000-000000000001",
        "source_program_id": null,
        "title": "Program Publik",
        "summary": "Program pengujian Guest.",
        "category": null,
        "cover_path": null,
        "cover_alt_text": null,
        "status": "active",
        "pace": "scheduled",
        "duration_mode": "fixed_duration",
        "starts_on": "2026-08-01",
        "ends_on": "2026-08-31",
        "timezone": "Asia/Jakarta",
        "participant_limit": null,
        "registration_closes_at": null,
        "past_step_policy": "available",
        "future_step_policy": "locked",
        "wellness_disclaimer": "Program non-diagnostik.",
        "points_per_activity": 10,
        "points_per_weight_kg": 100,
        "quiz_passing_percentage": 70,
        "pricing_mode": "free",
        "desired_price": null,
        "program_days": []
      }
    ]
    """

    private static let coachPayload = """
    [
      {
        "id": "d1000000-0000-0000-0000-000000000001",
        "display_name": "Coach Publik",
        "biography": "",
        "city": "Denpasar",
        "photo_reference": null
      }
    ]
    """

    private static let leaderboardPayload = """
    [
      {
        "id": "d2000000-0000-0000-0000-000000000001",
        "program_id": "d3000000-0000-0000-0000-000000000001",
        "participant_id": "d4000000-0000-0000-0000-000000000001",
        "participant_display_name": "Peserta Publik",
        "rank": 1,
        "progress_percentage": 100,
        "total_points": 425
      }
    ]
    """

    private static let winnerPayload = """
    [
      {
        "id": "d5000000-0000-0000-0000-000000000001",
        "program_id": "d3000000-0000-0000-0000-000000000001",
        "participant_id": "d4000000-0000-0000-0000-000000000001",
        "rank": 1,
        "participant_display_name": "Peserta Publik",
        "total_points": 425,
        "locked_at": "2026-08-01T00:00:00Z"
      }
    ]
    """

    private static let contentPayload = """
    [
      {
        "id": "d6000000-0000-0000-0000-000000000001",
        "kind": "winner_banner",
        "title": "Program Publik",
        "body": "Poster pemenang",
        "media_reference": "winner-posters/public.jpg",
        "program_id": "d3000000-0000-0000-0000-000000000001",
        "winner_snapshot_id":
          "d7000000-0000-0000-0000-000000000001",
        "visible_from": "2026-08-01T00:00:00Z",
        "visible_until": null,
        "sort_order": 1,
        "is_published": true,
        "is_archived": false,
        "updated_at": "2026-08-01T00:00:00Z"
      }
    ]
    """
}

private final class Phase11RequestCaptureURLProtocol:
    URLProtocol,
    @unchecked Sendable
{
    nonisolated(unsafe) static var capturedRequest: URLRequest?

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
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(
            self,
            didReceive: response,
            cacheStoragePolicy: .notAllowed
        )
        client?.urlProtocol(self, didLoad: Data("[]".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private actor Phase11RecordingSupabaseClient:
    SupabaseClientProviding
{
    private var responses: [Data]
    private var recordedRequests: [SupabaseRequest] = []

    init(responses: [Data]) {
        self.responses = responses
    }

    func execute(_ request: SupabaseRequest) async throws -> Data {
        recordedRequests.append(request)
        guard !responses.isEmpty else {
            throw DomainError.unknown
        }
        return responses.removeFirst()
    }

    func requests() -> [SupabaseRequest] {
        recordedRequests
    }
}
