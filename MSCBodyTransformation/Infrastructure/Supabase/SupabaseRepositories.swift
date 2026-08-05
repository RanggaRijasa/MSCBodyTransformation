import Foundation

nonisolated struct SupabaseProgramCatalogRepository: Sendable {
    private let client: any SupabaseClientProviding

    init(client: any SupabaseClientProviding) {
        self.client = client
    }

    func programs() async throws -> [Program] {
        let data = try await client.execute(
            SupabaseRequest(
                method: .get,
                path: "/rest/v1/programs",
                queryItems: [
                    URLQueryItem(
                        name: "select",
                        value: Self.catalogSelection
                    ),
                    URLQueryItem(
                        name: "status",
                        value: "in.(scheduled,active,completed,archived)"
                    ),
                    URLQueryItem(
                        name: "order",
                        value: "starts_on.desc"
                    )
                ]
            )
        )
        do {
            return try SupabaseJSON.decoder
                .decode([SupabaseProgramDTO].self, from: data)
                .map { try $0.domain() }
        } catch let error as SupabaseDTOError {
            throw mapDTOError(error)
        } catch {
            throw DomainError.unknown
        }
    }

    func program(id: UUID) async throws -> Program {
        let data = try await client.execute(
            SupabaseRequest(
                method: .get,
                path: "/rest/v1/programs",
                queryItems: [
                    URLQueryItem(
                        name: "select",
                        value: Self.catalogSelection
                    ),
                    URLQueryItem(name: "id", value: "eq.\(id.uuidString)"),
                    URLQueryItem(name: "limit", value: "1")
                ]
            )
        )
        do {
            guard let program = try SupabaseJSON.decoder
                .decode([SupabaseProgramDTO].self, from: data)
                .first else {
                throw DomainError.notFound(resource: "Program")
            }
            return try program.domain()
        } catch let error as DomainError {
            throw error
        } catch let error as SupabaseDTOError {
            throw mapDTOError(error)
        } catch {
            throw DomainError.unknown
        }
    }

    private static let catalogSelection = """
    *,program_days(*,program_steps(*,program_questions(*,\
    program_question_options(*))))
    """

    private func mapDTOError(_ error: SupabaseDTOError) -> DomainError {
        switch error {
        case let .invalidField(field):
            .validation(
                field: field,
                reason: "Data program dari server tidak valid."
            )
        }
    }
}

nonisolated struct SupabaseEnrollmentCommandRepository: Sendable {
    private let client: any SupabaseClientProviding

    init(client: any SupabaseClientProviding) {
        self.client = client
    }

    func enrollFreeProgram(
        programID: UUID,
        coachQRPayload: String
    ) async throws -> ProgramEnrollment {
        struct Body: Encodable {
            let targetProgramID: UUID
            let scannedCoachQR: String

            enum CodingKeys: String, CodingKey {
                case targetProgramID = "target_program_id"
                case scannedCoachQR = "scanned_coach_qr"
            }
        }
        let data = try await client.execute(
            try rpcRequest(
                name: "enroll_free_program",
                body: Body(
                    targetProgramID: programID,
                    scannedCoachQR: coachQRPayload
                )
            )
        )
        do {
            return try SupabaseJSON.decoder
                .decode(SupabaseEnrollmentDTO.self, from: data)
                .domain()
        } catch {
            throw DomainError.unknown
        }
    }
}

nonisolated struct SupabaseAdminEnrollmentCommandRepository: Sendable {
    private let client: any SupabaseClientProviding

    init(client: any SupabaseClientProviding) {
        self.client = client
    }

    func enrollParticipant(
        programID: UUID,
        participantID: UUID,
        reason: String
    ) async throws -> ProgramEnrollment {
        struct Body: Encodable {
            let targetProgramID: UUID
            let targetParticipantID: UUID
            let reason: String

            enum CodingKeys: String, CodingKey {
                case targetProgramID = "target_program_id"
                case targetParticipantID = "target_participant_id"
                case reason
            }
        }

        let data = try await client.execute(
            try rpcRequest(
                name: "admin_enroll_participant",
                body: Body(
                    targetProgramID: programID,
                    targetParticipantID: participantID,
                    reason: reason
                )
            )
        )
        do {
            return try SupabaseJSON.decoder
                .decode(SupabaseEnrollmentDTO.self, from: data)
                .domain()
        } catch {
            throw DomainError.unknown
        }
    }
}

nonisolated struct SupabasePreparedSubmission:
    Equatable,
    Sendable
{
    let id: UUID
    let enrollmentID: UUID
    let stepID: UUID
    let idempotencyKey: String
}

nonisolated struct SupabaseSubmissionAnswerCommand:
    Encodable,
    Equatable,
    Sendable
{
    let questionID: UUID
    var textValue: String?
    var numberValue: Decimal?
    var selectedOptionIDs: [UUID]
    var privatePhotoPath: String?

    enum CodingKeys: String, CodingKey {
        case questionID = "question_id"
        case textValue = "text_value"
        case numberValue = "number_value"
        case selectedOptionIDs = "selected_option_ids"
        case privatePhotoPath = "private_photo_path"
    }
}

nonisolated struct SupabaseSubmissionCommandRepository: Sendable {
    private let client: any SupabaseClientProviding

    init(client: any SupabaseClientProviding) {
        self.client = client
    }

    func prepare(
        enrollmentID: UUID,
        stepID: UUID,
        idempotencyKey: String
    ) async throws -> SupabasePreparedSubmission {
        struct Body: Encodable {
            let targetEnrollmentID: UUID
            let targetStepID: UUID
            let requestIdempotencyKey: String

            enum CodingKeys: String, CodingKey {
                case targetEnrollmentID = "target_enrollment_id"
                case targetStepID = "target_step_id"
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        let data = try await client.execute(
            try rpcRequest(
                name: "prepare_step_submission",
                body: Body(
                    targetEnrollmentID: enrollmentID,
                    targetStepID: stepID,
                    requestIdempotencyKey: idempotencyKey
                )
            )
        )
        let response = try SupabaseJSON.decoder.decode(
            SupabaseSubmissionDTO.self,
            from: data
        )
        guard response.status == "draft" else {
            throw DomainError.conflict(
                reason: "Submission sudah diselesaikan."
            )
        }
        return SupabasePreparedSubmission(
            id: response.id,
            enrollmentID: response.enrollmentID,
            stepID: response.stepID,
            idempotencyKey: idempotencyKey
        )
    }

    func submit(
        prepared: SupabasePreparedSubmission,
        answers: [SupabaseSubmissionAnswerCommand]
    ) async throws -> StepSubmission {
        struct Body: Encodable {
            let targetSubmissionID: UUID
            let submittedAnswers: [SupabaseSubmissionAnswerCommand]
            let requestIdempotencyKey: String

            enum CodingKeys: String, CodingKey {
                case targetSubmissionID = "target_submission_id"
                case submittedAnswers = "submitted_answers"
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        let data = try await client.execute(
            try rpcRequest(
                name: "submit_step_answers",
                body: Body(
                    targetSubmissionID: prepared.id,
                    submittedAnswers: answers,
                    requestIdempotencyKey: prepared.idempotencyKey
                )
            )
        )
        do {
            return try SupabaseJSON.decoder
                .decode(SupabaseSubmissionDTO.self, from: data)
                .domain()
        } catch {
            throw DomainError.unknown
        }
    }

    func review(
        submissionID: UUID,
        decision: SubmissionStatus,
        reason: String?,
        idempotencyKey: String
    ) async throws -> StepSubmission {
        guard decision == .approved || decision == .rejected else {
            throw DomainError.validation(
                field: "decision",
                reason: "Keputusan review tidak valid."
            )
        }
        struct Body: Encodable {
            let targetSubmissionID: UUID
            let reviewDecision: String
            let reviewReason: String?
            let requestIdempotencyKey: String

            enum CodingKeys: String, CodingKey {
                case targetSubmissionID = "target_submission_id"
                case reviewDecision = "review_decision"
                case reviewReason = "review_reason"
                case requestIdempotencyKey = "request_idempotency_key"
            }

            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(
                    keyedBy: CodingKeys.self
                )
                try container.encode(
                    targetSubmissionID,
                    forKey: .targetSubmissionID
                )
                try container.encode(
                    reviewDecision,
                    forKey: .reviewDecision
                )
                if let reviewReason {
                    try container.encode(
                        reviewReason,
                        forKey: .reviewReason
                    )
                } else {
                    try container.encodeNil(forKey: .reviewReason)
                }
                try container.encode(
                    requestIdempotencyKey,
                    forKey: .requestIdempotencyKey
                )
            }
        }
        let data = try await client.execute(
            try rpcRequest(
                name: "review_step_submission",
                body: Body(
                    targetSubmissionID: submissionID,
                    reviewDecision: decision.rawValue,
                    reviewReason: reason,
                    requestIdempotencyKey: idempotencyKey
                )
            )
        )
        do {
            return try SupabaseJSON.decoder
                .decode(SupabaseSubmissionDTO.self, from: data)
                .domain()
        } catch {
            throw DomainError.unknown
        }
    }

    func refreshScore(
        enrollmentID: UUID
    ) async throws -> SupabaseProgramScoreDTO {
        struct Body: Encodable {
            let targetEnrollmentID: UUID

            enum CodingKeys: String, CodingKey {
                case targetEnrollmentID = "target_enrollment_id"
            }
        }
        let data = try await client.execute(
            try rpcRequest(
                name: "refresh_enrollment_score",
                body: Body(targetEnrollmentID: enrollmentID)
            )
        )
        return try SupabaseJSON.decoder.decode(
            SupabaseProgramScoreDTO.self,
            from: data
        )
    }
}

nonisolated struct SupabasePrivatePhotoRepository: Sendable {
    private let client: any SupabaseClientProviding

    init(client: any SupabaseClientProviding) {
        self.client = client
    }

    func upload(
        jpegData: Data,
        participantID: UUID,
        prepared: SupabasePreparedSubmission,
        questionID: UUID,
        objectID: UUID,
        isRetry: Bool
    ) async throws -> String {
        guard jpegData.count <= 8 * 1_024 * 1_024 else {
            throw DomainError.validation(
                field: "photo",
                reason: "Ukuran foto melebihi batas 8 MiB."
            )
        }
        let path = [
            participantID.uuidString.lowercased(),
            prepared.enrollmentID.uuidString.lowercased(),
            prepared.id.uuidString.lowercased(),
            questionID.uuidString.lowercased(),
            "\(objectID.uuidString.lowercased()).jpg"
        ].joined(separator: "/")
        _ = try await client.execute(
            SupabaseRequest(
                method: .post,
                path: "/storage/v1/object/question-photos/\(path)",
                headers: [
                    "Content-Type": "image/jpeg",
                    "x-upsert": isRetry ? "true" : "false"
                ],
                body: jpegData
            )
        )
        return path
    }
}

nonisolated struct SupabasePhotoSubmissionCoordinator: Sendable {
    private let submissions: SupabaseSubmissionCommandRepository
    private let photos: SupabasePrivatePhotoRepository
    private let fileStore: LocalMediaFileStore

    init(
        submissions: SupabaseSubmissionCommandRepository,
        photos: SupabasePrivatePhotoRepository,
        fileStore: LocalMediaFileStore = LocalMediaFileStore()
    ) {
        self.submissions = submissions
        self.photos = photos
        self.fileStore = fileStore
    }

    func submit(
        participantID: UUID,
        enrollmentID: UUID,
        stepID: UUID,
        photoQuestionID: UUID,
        processedPhotoURL: URL,
        otherAnswers: [SupabaseSubmissionAnswerCommand],
        idempotencyKey: String,
        objectID: UUID
    ) async throws -> StepSubmission {
        let prepared = try await submissions.prepare(
            enrollmentID: enrollmentID,
            stepID: stepID,
            idempotencyKey: idempotencyKey
        )
        let jpegData: Data
        do {
            jpegData = try Data(contentsOf: processedPhotoURL)
        } catch {
            throw DomainError.notFound(resource: "Foto")
        }
        let privatePath = try await photos.upload(
            jpegData: jpegData,
            participantID: participantID,
            prepared: prepared,
            questionID: photoQuestionID,
            objectID: objectID,
            isRetry: true
        )
        var answers = otherAnswers
        answers.append(
            SupabaseSubmissionAnswerCommand(
                questionID: photoQuestionID,
                textValue: nil,
                numberValue: nil,
                selectedOptionIDs: [],
                privatePhotoPath: privatePath
            )
        )
        let submission = try await submissions.submit(
            prepared: prepared,
            answers: answers
        )

        // The server has now stored both the answer row and private path.
        // Removing the processed local artifact before this point would make
        // an interrupted retry unrecoverable.
        try? fileStore.remove(url: processedPhotoURL)
        return submission
    }
}

private nonisolated func rpcRequest<Body: Encodable>(
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
