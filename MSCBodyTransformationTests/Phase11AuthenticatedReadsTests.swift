import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Phase 11 authenticated reads", .serialized)
struct Phase11AuthenticatedReadsTests {
    @Test("Authenticated transport sends the current bearer token")
    func authenticatedTransportUsesAccessToken() async throws {
        let configuration = try SupabaseRuntimeConfiguration(
            projectURL: URL(string: "https://authenticated.test.invalid")!,
            publishableKey: "publishable-test-key"
        )
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [
            Phase11AuthenticatedRequestCaptureURLProtocol.self
        ]
        let session = URLSession(configuration: sessionConfiguration)
        Phase11AuthenticatedRequestCaptureURLProtocol.capturedRequest = nil
        defer {
            Phase11AuthenticatedRequestCaptureURLProtocol.capturedRequest = nil
        }
        let client = URLSessionSupabaseClient(
            configuration: configuration,
            accessTokenProvider: FixedSupabaseAccessTokenProvider(
                token: "current-access-token"
            ),
            session: session
        )

        _ = try await client.execute(
            SupabaseRequest(
                method: .get,
                path: "/rest/v1/profiles"
            )
        )
        let request = try #require(
            Phase11AuthenticatedRequestCaptureURLProtocol.capturedRequest
        )

        #expect(
            request.value(forHTTPHeaderField: "apikey")
                == "publishable-test-key"
        )
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == "Bearer current-access-token"
        )
    }

    @Test("Account and private submission DTOs map losslessly")
    func privateDTOsMapLosslessly() throws {
        let accountDTO = try SupabaseJSON.decoder.decode(
            SupabaseAuthenticatedAccountDTO.self,
            from: Data(Self.accountObject.utf8)
        )
        let account = try accountDTO.domain()
        let submissionDTO = try SupabaseJSON.decoder.decode(
            SupabaseSubmissionReadDTO.self,
            from: Data(Self.submissionObject.utf8)
        )
        let submission = try submissionDTO.domain()
        let answers = try #require(submission.answers)

        #expect(account.role == .participant)
        #expect(account.city == "Denpasar")
        #expect(account.memberLevel == nil)
        #expect(account.currentCoachID != nil)
        #expect(submission.status == .approved)
        #expect(answers.count == 1)
        #expect(answers[0].textValue == "")
        #expect(answers[0].selectedOptionIDs.isEmpty)
        #expect(submission.quizResult?.awardedPoints == 20)
        #expect(submission.quizResult?.reopenReason == nil)
    }

    @Test("Unknown server enums are rejected instead of defaulted")
    func unknownEnumsAreRejected() throws {
        let invalidPayload = Self.accountObject.replacingOccurrences(
            of: "\"role\": \"participant\"",
            with: "\"role\": \"owner\""
        )
        let dto = try SupabaseJSON.decoder.decode(
            SupabaseAuthenticatedAccountDTO.self,
            from: Data(invalidPayload.utf8)
        )

        #expect(throws: SupabaseDTOError.invalidField("profile.role")) {
            try dto.domain()
        }
    }

    @Test("Authenticated repository uses explicit caller filters")
    func repositoryUsesExplicitFilters() async throws {
        let userID = UUID(
            uuidString: "e1000000-0000-0000-0000-000000000001"
        )!
        let client = Phase11AuthenticatedRoutingClient(
            responses: [
                "/rest/v1/profiles": Data("[\(Self.accountObject)]".utf8),
                "/rest/v1/programs": Data(Self.programPayload.utf8),
                "/rest/v1/program_enrollments": Data("[]".utf8),
                "/rest/v1/rpc/get_my_assigned_coach": Data("[]".utf8),
                "/rest/v1/rpc/list_my_program_day_access": Data("[]".utf8),
                "/rest/v1/rpc/get_my_dashboard_summary":
                    Data(Self.dashboardPayload.utf8)
            ]
        )
        let repository = SupabaseAuthenticatedParticipantReadRepository(
            client: client
        )
        let user = AppUser(
            id: userID,
            email: "participant@test.invalid",
            displayName: "Peserta",
            role: .participant,
            hasCompletedOnboarding: true,
            isCoachApprovalPending: false,
            createdAt: Date(timeIntervalSince1970: 0)
        )

        let snapshot = try await repository.snapshot(user: user)
        let requests = await client.requests()
        let profileRequest = try #require(
            requests.first { $0.path == "/rest/v1/profiles" }
        )
        let enrollmentRequest = try #require(
            requests.first {
                $0.path == "/rest/v1/program_enrollments"
            }
        )

        #expect(snapshot.account.publicProfileID != user.id)
        #expect(snapshot.enrollments.isEmpty)
        #expect(snapshot.dashboardSummary.role == .participant)
        #expect(
            profileRequest.queryItems.contains {
                $0.name == "user_id"
                    && $0.value
                        == "eq.\(userID.uuidString.lowercased())"
            }
        )
        #expect(
            enrollmentRequest.queryItems.contains {
                $0.name == "participant_id"
                    && $0.value
                        == "eq.\(userID.uuidString.lowercased())"
            }
        )
        #expect(
            Set(requests.map(\.path)).isSuperset(of: [
                "/rest/v1/rpc/get_my_assigned_coach",
                "/rest/v1/rpc/list_my_program_day_access",
                "/rest/v1/rpc/get_my_dashboard_summary"
            ])
        )
    }

    @Test("Participant journey loads the authenticated repository without fallback")
    @MainActor
    func participantJourneyUsesAuthenticatedRepository() async throws {
        let fallback = InMemoryAppRepository(
            seed: try MockSeedData.load(),
            sessionScenario: .role(.participant)
        )
        let session = try await fallback.loadCurrentSession()
        let user = try #require(session.user)
        let serverSnapshot = AuthenticatedParticipantReadSnapshot(
            account: AuthenticatedAccountReadModel(
                publicProfileID: UUID(
                    uuidString:
                        "eb000000-0000-0000-0000-000000000001"
                )!,
                role: .participant,
                displayName: "Peserta dari server",
                city: "Denpasar",
                phoneNumber: nil,
                currentCoachID: nil,
                avatarReference: nil,
                memberLevel: nil,
                onboardingStatus: .active,
                accountPurpose: .participant
            ),
            programs: [],
            enrollments: [],
            enrollmentContexts: [],
            assignedCoach: nil,
            dayAccessStates: [],
            dashboardSummary: AuthenticatedDashboardSummary(
                role: .participant,
                activeEnrollmentCount: 0,
                completedEnrollmentCount: 0,
                pendingSubmissionCount: 0,
                assignedParticipantCount: 0
            )
        )
        let authenticatedReads = Phase11AuthenticatedSnapshotRepository(
            snapshot: serverSnapshot
        )
        let repositories = AppRepositories(
            session: fallback,
            authentication: fallback,
            profiles: fallback,
            authenticatedParticipantReads: authenticatedReads,
            publicCoachDirectory: fallback,
            publicPrograms: fallback,
            publicLeaderboard: fallback,
            publicManagedContent: fallback,
            phase11Fallback: fallback
        )
        let environment = AppEnvironment(
            configuration: .localDemo,
            clock: FixedClock(
                now: Date(timeIntervalSince1970: 1_785_028_400)
            ),
            identifierGenerator: UUIDIdentifierGenerator(),
            repositories: repositories,
            bootstrapError: nil
        )
        let store = ParticipantJourneyStore(environment: environment)

        await store.load()

        #expect(store.snapshot?.user.id == user.id)
        #expect(store.snapshot?.profile.displayName == "Peserta dari server")
        #expect(store.snapshot?.programs.isEmpty == true)
        #expect(await authenticatedReads.callCount() == 1)
    }

    private static let accountObject = """
    {
      "user_id": "e1000000-0000-0000-0000-000000000001",
      "public_profile_id": "e2000000-0000-0000-0000-000000000001",
      "role": "participant",
      "display_name": "Peserta",
      "city": "Denpasar",
      "phone_number": null,
      "current_coach_id": "e3000000-0000-0000-0000-000000000001",
      "provider_avatar_url": null,
      "member_level": null,
      "onboarding_status": "active",
      "account_purpose": "participant"
    }
    """

    private static let submissionObject = """
    {
      "id": "e4000000-0000-0000-0000-000000000001",
      "enrollment_id": "e5000000-0000-0000-0000-000000000001",
      "step_id": "e6000000-0000-0000-0000-000000000001",
      "attempt_sequence": 2,
      "status": "approved",
      "submitted_at": "2026-08-06T01:00:00Z",
      "reviewed_at": "2026-08-06T02:00:00Z",
      "reviewer_id": "e3000000-0000-0000-0000-000000000001",
      "review_note": null,
      "step_submission_answers": [
        {
          "id": "e7000000-0000-0000-0000-000000000001",
          "question_id": "e8000000-0000-0000-0000-000000000001",
          "text_value": "",
          "number_value": null,
          "selected_option_ids": [],
          "private_photo_path": null
        }
      ],
      "quiz_attempt_results": {
        "id": "e9000000-0000-0000-0000-000000000001",
        "correct_count": 2,
        "total_count": 2,
        "percentage": 100,
        "passed": true,
        "awarded_points": 20,
        "reopened_at": null,
        "reopened_by": null,
        "reopen_reason": null
      }
    }
    """

    private static let dashboardPayload = """
    [
      {
        "account_role": "participant",
        "active_enrollment_count": 0,
        "completed_enrollment_count": 0,
        "pending_submission_count": 0,
        "assigned_participant_count": 0
      }
    ]
    """

    private static let programPayload = """
    [
      {
        "id": "ea000000-0000-0000-0000-000000000001",
        "source_program_id": null,
        "title": "Program Auth",
        "summary": "Program pengujian.",
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
}

private final class Phase11AuthenticatedRequestCaptureURLProtocol:
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

private actor Phase11AuthenticatedRoutingClient:
    SupabaseClientProviding
{
    private let responses: [String: Data]
    private var recordedRequests: [SupabaseRequest] = []

    init(responses: [String: Data]) {
        self.responses = responses
    }

    func execute(_ request: SupabaseRequest) async throws -> Data {
        recordedRequests.append(request)
        guard let response = responses[request.path] else {
            throw DomainError.notFound(resource: request.path)
        }
        return response
    }

    func requests() -> [SupabaseRequest] {
        recordedRequests
    }
}

private actor Phase11AuthenticatedSnapshotRepository:
    AuthenticatedParticipantReadRepository
{
    private let storedSnapshot: AuthenticatedParticipantReadSnapshot
    private var calls = 0

    init(snapshot: AuthenticatedParticipantReadSnapshot) {
        storedSnapshot = snapshot
    }

    func snapshot(
        user: AppUser
    ) async throws -> AuthenticatedParticipantReadSnapshot {
        calls += 1
        guard user.role == .participant else {
            throw DomainError.permissionDenied
        }
        return storedSnapshot
    }

    func callCount() -> Int {
        calls
    }
}
