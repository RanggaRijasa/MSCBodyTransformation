import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Phase 09 Supabase foundation")
struct Phase09SupabaseFoundationTests {
    @Test("Program DTO maps nested Data API payload without answer keys")
    func programDTOMapsNestedPayload() throws {
        let data = Data(Self.programPayload.utf8)
        let dto = try SupabaseJSON.decoder.decode(
            [SupabaseProgramDTO].self,
            from: data
        )
        let firstDTO = try #require(dto.first)
        let program = try firstDTO.domain()

        #expect(program.id.uuidString.lowercased()
            == "10000000-0000-0000-0000-000000000001")
        #expect(program.status == .active)
        #expect(program.pace == .scheduled)
        #expect(program.effectiveScoringConfiguration.pointsPerActivity == 10)
        #expect(
            program.effectiveScoringConfiguration
                .pointsPerWeightLossKilogram == Decimal(100)
        )
        #expect(program.days.count == 1)
        #expect(program.days[0].steps.count == 1)
        #expect(
            program.days[0].steps[0].content?.questions[0].kind
                == .singleChoice
        )
        #expect(
            program.days[0].steps[0].content?.questions[0].answerKey == nil
        )
    }

    @Test("Catalog repository sends an authenticated Data API selection")
    func catalogRepositoryMapsResponse() async throws {
        let client = RecordingSupabaseClient(
            responses: [Data(Self.programPayload.utf8)]
        )
        let repository = SupabaseProgramCatalogRepository(client: client)

        let programs = try await repository.programs()
        let requests = await client.recordedRequests()

        #expect(programs.count == 1)
        #expect(requests.count == 1)
        #expect(requests[0].method == .get)
        #expect(requests[0].path == "/rest/v1/programs")
        #expect(
            requests[0].queryItems.contains {
                $0.name == "select"
                    && ($0.value ?? "").contains("program_questions")
            }
        )
    }

    @Test("Submission adapter preserves idempotency from prepare to submit")
    func submissionAdapterPreservesIdempotency() async throws {
        let submissionID = UUID(
            uuidString: "60000000-0000-0000-0000-000000000001"
        )!
        let enrollmentID = UUID(
            uuidString: "50000000-0000-0000-0000-000000000001"
        )!
        let stepID = UUID(
            uuidString: "30000000-0000-0000-0000-000000000001"
        )!
        let draft = Self.submissionPayload(
            id: submissionID,
            enrollmentID: enrollmentID,
            stepID: stepID,
            status: "draft",
            finalizedAt: nil
        )
        let pending = Self.submissionPayload(
            id: submissionID,
            enrollmentID: enrollmentID,
            stepID: stepID,
            status: "pending",
            finalizedAt: "2026-08-04T06:00:00Z"
        )
        let client = RecordingSupabaseClient(
            responses: [draft, pending]
        )
        let repository = SupabaseSubmissionCommandRepository(
            client: client
        )
        let key = "submission-request-0001"

        let prepared = try await repository.prepare(
            enrollmentID: enrollmentID,
            stepID: stepID,
            idempotencyKey: key
        )
        let result = try await repository.submit(
            prepared: prepared,
            answers: [
                SupabaseSubmissionAnswerCommand(
                    questionID: UUID(
                        uuidString:
                            "40000000-0000-0000-0000-000000000001"
                    )!,
                    textValue: "Lengkap",
                    numberValue: nil,
                    selectedOptionIDs: [],
                    privatePhotoPath: nil
                )
            ]
        )
        let requests = await client.recordedRequests()
        let prepareBody = try #require(requests[0].body)
        let submitBody = try #require(requests[1].body)
        let prepareObject = try #require(
            JSONSerialization.jsonObject(with: prepareBody)
                as? [String: Any]
        )
        let submitObject = try #require(
            JSONSerialization.jsonObject(with: submitBody)
                as? [String: Any]
        )

        #expect(prepared.id == submissionID)
        #expect(result.status == .pending)
        #expect(
            prepareObject["request_idempotency_key"] as? String == key
        )
        #expect(
            submitObject["request_idempotency_key"] as? String == key
        )
    }

    @Test("Approved review keeps the nullable RPC argument")
    func approvedReviewEncodesNullReason() async throws {
        let submissionID = UUID(
            uuidString: "60000000-0000-0000-0000-000000000001"
        )!
        let enrollmentID = UUID(
            uuidString: "50000000-0000-0000-0000-000000000001"
        )!
        let stepID = UUID(
            uuidString: "30000000-0000-0000-0000-000000000001"
        )!
        let client = RecordingSupabaseClient(
            responses: [
                Self.submissionPayload(
                    id: submissionID,
                    enrollmentID: enrollmentID,
                    stepID: stepID,
                    status: "approved",
                    finalizedAt: "2026-08-04T06:00:00Z"
                )
            ]
        )
        let repository = SupabaseSubmissionCommandRepository(client: client)

        _ = try await repository.review(
            submissionID: submissionID,
            decision: .approved,
            reason: nil,
            idempotencyKey: "review-request-0001"
        )
        let requests = await client.recordedRequests()
        let request = try #require(requests.first)
        let body = try #require(request.body)
        let object = try #require(
            JSONSerialization.jsonObject(with: body) as? [String: Any]
        )

        #expect(object.keys.contains("review_reason"))
        #expect(object["review_reason"] is NSNull)
    }

    @Test("Processed photo is deleted only after durable submission response")
    func photoCoordinatorDeletesAfterSubmission() async throws {
        let participantID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000011"
        )!
        let enrollmentID = UUID(
            uuidString: "50000000-0000-0000-0000-000000000001"
        )!
        let stepID = UUID(
            uuidString: "30000000-0000-0000-0000-000000000001"
        )!
        let submissionID = UUID(
            uuidString: "60000000-0000-0000-0000-000000000001"
        )!
        let draft = Self.submissionPayload(
            id: submissionID,
            enrollmentID: enrollmentID,
            stepID: stepID,
            status: "draft",
            finalizedAt: nil
        )
        let pending = Self.submissionPayload(
            id: submissionID,
            enrollmentID: enrollmentID,
            stepID: stepID,
            status: "pending",
            finalizedAt: "2026-08-04T06:00:00Z"
        )
        let client = RecordingSupabaseClient(
            responses: [draft, Data("{}".utf8), pending]
        )
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "Phase09-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        let photoURL = temporaryDirectory
            .appendingPathComponent("processed.jpg")
        try Data([0xff, 0xd8, 0xff, 0xd9]).write(to: photoURL)
        let coordinator = SupabasePhotoSubmissionCoordinator(
            submissions: SupabaseSubmissionCommandRepository(client: client),
            photos: SupabasePrivatePhotoRepository(client: client),
            fileStore: LocalMediaFileStore(directory: temporaryDirectory)
        )

        _ = try await coordinator.submit(
            participantID: participantID,
            enrollmentID: enrollmentID,
            stepID: stepID,
            photoQuestionID: UUID(
                uuidString: "40000000-0000-0000-0000-000000000001"
            )!,
            processedPhotoURL: photoURL,
            otherAnswers: [],
            idempotencyKey: "photo-request-0001",
            objectID: UUID(
                uuidString: "90000000-0000-0000-0000-000000000001"
            )!
        )
        let requests = await client.recordedRequests()

        #expect(!FileManager.default.fileExists(atPath: photoURL.path))
        #expect(requests.count == 3)
        #expect(requests[1].path.contains("/question-photos/"))
        #expect(requests[1].headers["Content-Type"] == "image/jpeg")
    }

    @Test("Failed durable submission preserves the processed photo")
    func failedSubmissionPreservesPhoto() async throws {
        let enrollmentID = UUID()
        let stepID = UUID()
        let submissionID = UUID()
        let draft = Self.submissionPayload(
            id: submissionID,
            enrollmentID: enrollmentID,
            stepID: stepID,
            status: "draft",
            finalizedAt: nil
        )
        let client = RecordingSupabaseClient(
            results: [
                .success(draft),
                .success(Data("{}".utf8)),
                .failure(.conflict(reason: "submit_failed"))
            ]
        )
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "Phase09-Failure-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        let photoURL = temporaryDirectory
            .appendingPathComponent("processed.jpg")
        try Data([0xff, 0xd8, 0xff, 0xd9]).write(to: photoURL)
        let coordinator = SupabasePhotoSubmissionCoordinator(
            submissions: SupabaseSubmissionCommandRepository(client: client),
            photos: SupabasePrivatePhotoRepository(client: client),
            fileStore: LocalMediaFileStore(directory: temporaryDirectory)
        )

        await #expect(throws: DomainError.self) {
            _ = try await coordinator.submit(
                participantID: UUID(),
                enrollmentID: enrollmentID,
                stepID: stepID,
                photoQuestionID: UUID(),
                processedPhotoURL: photoURL,
                otherAnswers: [],
                idempotencyKey: "photo-request-failure",
                objectID: UUID()
            )
        }
        #expect(FileManager.default.fileExists(atPath: photoURL.path))
    }

    @Test("Transport errors map to stable domain errors")
    func transportErrorsMapToDomainErrors() {
        #expect(
            SupabaseErrorMapper.map(
                urlError: URLError(.notConnectedToInternet)
            ) == .offline
        )
        #expect(
            SupabaseErrorMapper.map(
                urlError: URLError(.timedOut)
            ) == .timeout
        )
        #expect(
            SupabaseErrorMapper.map(
                statusCode: 401,
                responseData: Data()
            ) == .sessionExpired
        )
        #expect(
            SupabaseErrorMapper.map(
                statusCode: 403,
                responseData: Data()
            ) == .permissionDenied
        )
        #expect(
            SupabaseErrorMapper.map(
                statusCode: 409,
                responseData: Data(#"{"message":"conflict"}"#.utf8)
            ) == .conflict(reason: "conflict")
        )
    }

    @Test("Debug local configuration rejects a hosted endpoint")
    func debugConfigurationRejectsHostedEndpoint() {
        #if DEBUG
        #expect(throws: DomainError.self) {
            _ = try SupabaseRuntimeConfiguration.debugLocal(
                environment: [
                    SupabaseRuntimeConfiguration.urlEnvironmentKey:
                        "https://example.supabase.co",
                    SupabaseRuntimeConfiguration
                        .publishableKeyEnvironmentKey: "publishable-test"
                ]
            )
        }
        #endif
    }

    @Test("iOS adapter completes the local Supabase vertical slice")
    func liveLocalVerticalSlice() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["MSC_PHASE09_LIVE"] == "1" else {
            return
        }
        let configuration = try SupabaseRuntimeConfiguration.debugLocal(
            environment: environment
        )
        let participantToken = try await Self.signIn(
            configuration: configuration,
            email: try #require(
                environment["MSC_PHASE09_PARTICIPANT_EMAIL"]
            ),
            password: try #require(
                environment["MSC_PHASE09_PARTICIPANT_PASSWORD"]
            )
        )
        let participantClient = URLSessionSupabaseClient(
            configuration: configuration,
            accessTokenProvider: FixedSupabaseAccessTokenProvider(
                token: participantToken
            )
        )
        let catalog = SupabaseProgramCatalogRepository(
            client: participantClient
        )
        let programs = try await catalog.programs()
        let rawProgramID = try #require(
            environment["MSC_PHASE09_PROGRAM_ID"]
        )
        let programID = try #require(UUID(uuidString: rawProgramID))
        let program = try #require(
            programs.first { $0.id == programID }
        )
        let enrollment = try await SupabaseEnrollmentCommandRepository(
            client: participantClient
        ).enrollFreeProgram(
            programID: programID,
            coachQRPayload: try #require(
                environment["MSC_PHASE09_COACH_QR"]
            )
        )
        let submissions = SupabaseSubmissionCommandRepository(
            client: participantClient
        )
        let currentScore = try await submissions.refreshScore(
            enrollmentID: enrollment.id
        )
        if currentScore.progressPercentage == 100 {
            #expect(currentScore.activityPoints == 10)
            #expect(currentScore.quizPoints == 0)
            return
        }
        let step = try #require(program.days.first?.steps.first)
        let question = try #require(step.content?.questions.first)
        let key = "ios-live-\(UUID().uuidString)"
        let prepared = try await submissions.prepare(
            enrollmentID: enrollment.id,
            stepID: step.id,
            idempotencyKey: key
        )
        let path = try await SupabasePrivatePhotoRepository(
            client: participantClient
        ).upload(
            jpegData: Data([0xff, 0xd8, 0xff, 0xd9]),
            participantID: enrollment.participantID,
            prepared: prepared,
            questionID: question.id,
            objectID: UUID(),
            isRetry: false
        )
        let pending = try await submissions.submit(
            prepared: prepared,
            answers: [
                SupabaseSubmissionAnswerCommand(
                    questionID: question.id,
                    textValue: nil,
                    numberValue: nil,
                    selectedOptionIDs: [],
                    privatePhotoPath: path
                )
            ]
        )

        let coachToken = try await Self.signIn(
            configuration: configuration,
            email: try #require(environment["MSC_PHASE09_COACH_EMAIL"]),
            password: try #require(
                environment["MSC_PHASE09_COACH_PASSWORD"]
            )
        )
        let coachClient = URLSessionSupabaseClient(
            configuration: configuration,
            accessTokenProvider: FixedSupabaseAccessTokenProvider(
                token: coachToken
            )
        )
        let coachSubmissions = SupabaseSubmissionCommandRepository(
            client: coachClient
        )
        let approved = try await coachSubmissions.review(
            submissionID: pending.id,
            decision: .approved,
            reason: nil,
            idempotencyKey: "ios-review-\(UUID().uuidString)"
        )
        let score = try await coachSubmissions.refreshScore(
            enrollmentID: enrollment.id
        )

        #expect(approved.status == .approved)
        #expect(score.activityPoints == 10)
        #expect(score.quizPoints == 0)
        #expect(score.progressPercentage == 100)
    }

    private static func signIn(
        configuration: SupabaseRuntimeConfiguration,
        email: String,
        password: String
    ) async throws -> String {
        struct AuthResponse: Decodable {
            let accessToken: String

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
            }
        }
        var components = URLComponents(
            url: configuration.projectURL
                .appendingPathComponent("/auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "grant_type", value: "password")
        ]
        let url = try #require(components?.url)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            configuration.publishableKey,
            forHTTPHeaderField: "apikey"
        )
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = try JSONEncoder().encode(
            ["email": email, "password": password]
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = try #require(
            (response as? HTTPURLResponse)?.statusCode
        )
        guard (200..<300).contains(statusCode) else {
            throw DomainError.sessionExpired
        }
        return try JSONDecoder()
            .decode(AuthResponse.self, from: data)
            .accessToken
    }

    private static func submissionPayload(
        id: UUID,
        enrollmentID: UUID,
        stepID: UUID,
        status: String,
        finalizedAt: String?
    ) -> Data {
        let finalized = finalizedAt.map { #""\#($0)""# } ?? "null"
        return Data(
            """
            {
              "id": "\(id.uuidString.lowercased())",
              "enrollment_id": "\(enrollmentID.uuidString.lowercased())",
              "step_id": "\(stepID.uuidString.lowercased())",
              "attempt_sequence": 1,
              "status": "\(status)",
              "submitted_at": "2026-08-04T06:00:00Z",
              "reviewed_at": null,
              "reviewer_id": null,
              "review_note": null,
              "finalized_at": \(finalized)
            }
            """.utf8
        )
    }

    private static let programPayload = """
    [
      {
        "id": "10000000-0000-0000-0000-000000000001",
        "source_program_id": null,
        "title": "Program Supabase",
        "summary": "Program pengujian.",
        "category": "Kebugaran",
        "cover_path": "covers/program.jpg",
        "cover_alt_text": "Sampul program",
        "status": "active",
        "pace": "scheduled",
        "duration_mode": "fixed_duration",
        "starts_on": "2026-08-01",
        "ends_on": "2026-08-31",
        "timezone": "Asia/Jakarta",
        "participant_limit": 20,
        "past_step_policy": "available",
        "future_step_policy": "locked",
        "wellness_disclaimer": "Program non-diagnostik.",
        "points_per_activity": 10,
        "points_per_weight_kg": 100,
        "quiz_passing_percentage": 70,
        "pricing_mode": "free",
        "desired_price": null,
        "program_days": [
          {
            "id": "20000000-0000-0000-0000-000000000001",
            "day_number": 1,
            "title": "Hari pertama",
            "summary": "Mulai perlahan.",
            "scheduled_on": "2026-08-01",
            "program_steps": [
              {
                "id": "30000000-0000-0000-0000-000000000001",
                "step_order": 1,
                "title": "Kuis",
                "instructions": "Pilih jawaban.",
                "content_kind": "quiz",
                "completion_policy": "automatic_quiz",
                "verification_mode": "automatic",
                "media_path": null,
                "media_alt_text": null,
                "video_required": false,
                "video_threshold": null,
                "video_autoplay": false,
                "program_questions": [
                  {
                    "id": "40000000-0000-0000-0000-000000000001",
                    "question_order": 1,
                    "kind": "single_choice",
                    "prompt": "Pilih jawaban",
                    "program_question_options": [
                      {
                        "id": "41000000-0000-0000-0000-000000000001",
                        "option_order": 1,
                        "title": "Benar",
                        "media_path": null,
                        "media_alt_text": null
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
    """
}

private actor RecordingSupabaseClient: SupabaseClientProviding {
    private var results: [Result<Data, DomainError>]
    private var requests: [SupabaseRequest] = []

    init(responses: [Data]) {
        results = responses.map(Result.success)
    }

    init(results: [Result<Data, DomainError>]) {
        self.results = results
    }

    func execute(_ request: SupabaseRequest) async throws -> Data {
        requests.append(request)
        guard !results.isEmpty else {
            throw DomainError.unknown
        }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [SupabaseRequest] {
        requests
    }
}
