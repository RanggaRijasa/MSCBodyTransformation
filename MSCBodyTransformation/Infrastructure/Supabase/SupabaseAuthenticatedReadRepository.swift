import Foundation

nonisolated struct SupabaseAuthenticatedParticipantReadRepository:
    AuthenticatedParticipantReadRepository,
    Sendable
{
    private let client: any SupabaseClientProviding
    private let programs: SupabaseProgramCatalogRepository

    init(client: any SupabaseClientProviding) {
        self.client = client
        programs = SupabaseProgramCatalogRepository(client: client)
    }

    func snapshot(
        user: AppUser
    ) async throws -> AuthenticatedParticipantReadSnapshot {
        async let accountTask = account(userID: user.id)
        async let programsTask = programs.programs()
        async let enrollmentsTask = enrollments(participantID: user.id)
        async let assignedCoachTask = assignedCoach()
        async let accessTask = dayAccessStates()
        async let dashboardTask = dashboardSummary()

        let account = try await accountTask
        guard account.role == .participant, user.role == .participant else {
            throw DomainError.permissionDenied
        }
        let programValues = try await programsTask
        let enrollmentValues = try await enrollmentsTask
        var contexts: [ProgramEnrollmentContext] = []

        for enrollment in enrollmentValues
        where enrollment.status == .active
            || enrollment.status == .completed {
            guard let program = programValues.first(where: {
                $0.id == enrollment.programID
            }) else {
                continue
            }
            async let submissionsTask = submissions(
                enrollmentID: enrollment.id
            )
            async let weighInsTask = weighIns(enrollmentID: enrollment.id)
            async let scoreTask = score(
                enrollment: enrollment,
                participantID: user.id,
                displayName: account.displayName
            )
            contexts.append(
                ProgramEnrollmentContext(
                    enrollment: enrollment,
                    program: program,
                    submissions: try await submissionsTask,
                    weighIns: try await weighInsTask,
                    leaderboardEntry: try await scoreTask
                )
            )
        }

        let dashboardSummary = try await dashboardTask
        guard dashboardSummary.role == account.role else {
            throw DomainError.permissionDenied
        }

        return AuthenticatedParticipantReadSnapshot(
            account: account,
            programs: programValues,
            enrollments: enrollmentValues,
            enrollmentContexts: contexts,
            assignedCoach: try await assignedCoachTask,
            dayAccessStates: try await accessTask,
            dashboardSummary: dashboardSummary
        )
    }

    private func account(
        userID: UUID
    ) async throws -> AuthenticatedAccountReadModel {
        let data = try await client.execute(
            SupabaseRequest(
                method: .get,
                path: "/rest/v1/profiles",
                queryItems: [
                    URLQueryItem(
                        name: "select",
                        value: Self.accountSelection
                    ),
                    URLQueryItem(
                        name: "user_id",
                        value: "eq.\(userID.uuidString.lowercased())"
                    ),
                    URLQueryItem(name: "limit", value: "1")
                ]
            )
        )
        let values = try decode([SupabaseAuthenticatedAccountDTO].self, data)
        guard values.count == 1 else {
            throw DomainError.notFound(resource: "Profil")
        }
        return try mapDTO { try values[0].domain() }
    }

    private func enrollments(
        participantID: UUID
    ) async throws -> [ProgramEnrollment] {
        let data = try await client.execute(
            SupabaseRequest(
                method: .get,
                path: "/rest/v1/program_enrollments",
                queryItems: [
                    URLQueryItem(
                        name: "select",
                        value: Self.enrollmentSelection
                    ),
                    URLQueryItem(
                        name: "participant_id",
                        value: "eq.\(participantID.uuidString.lowercased())"
                    ),
                    URLQueryItem(name: "order", value: "enrolled_at.asc")
                ]
            )
        )
        let values = try decode([SupabaseEnrollmentDTO].self, data)
        return try mapDTO {
            try values.map { try $0.domain() }
        }
    }

    private func assignedCoach()
    async throws -> AuthenticatedAssignedCoachReadModel? {
        let values: [SupabaseAssignedCoachDTO] = try await rpc(
            name: "get_my_assigned_coach"
        )
        guard values.count <= 1 else {
            throw DomainError.conflict(
                reason: "Relasi Coach aktif tidak konsisten."
            )
        }
        return values.first?.domain()
    }

    private func dayAccessStates()
    async throws -> [AuthenticatedProgramDayAccessState] {
        let values: [SupabaseProgramDayAccessDTO] = try await rpc(
            name: "list_my_program_day_access"
        )
        return try mapDTO {
            try values.map { try $0.domain() }
        }
    }

    private func dashboardSummary()
    async throws -> AuthenticatedDashboardSummary {
        let values: [SupabaseDashboardSummaryDTO] = try await rpc(
            name: "get_my_dashboard_summary"
        )
        guard values.count == 1 else {
            throw DomainError.notFound(resource: "Ringkasan akun")
        }
        return try mapDTO { try values[0].domain() }
    }

    private func submissions(
        enrollmentID: UUID
    ) async throws -> [StepSubmission] {
        let data = try await client.execute(
            SupabaseRequest(
                method: .get,
                path: "/rest/v1/step_submissions",
                queryItems: [
                    URLQueryItem(
                        name: "select",
                        value: Self.submissionSelection
                    ),
                    URLQueryItem(
                        name: "enrollment_id",
                        value: "eq.\(enrollmentID.uuidString.lowercased())"
                    ),
                    URLQueryItem(name: "order", value: "submitted_at.asc")
                ]
            )
        )
        let values = try decode([SupabaseSubmissionReadDTO].self, data)
        return try mapDTO {
            try values.map { try $0.domain() }
        }
    }

    private func weighIns(enrollmentID: UUID) async throws -> [WeighIn] {
        let data = try await client.execute(
            SupabaseRequest(
                method: .get,
                path: "/rest/v1/weigh_ins",
                queryItems: [
                    URLQueryItem(
                        name: "select",
                        value: Self.weighInSelection
                    ),
                    URLQueryItem(
                        name: "enrollment_id",
                        value: "eq.\(enrollmentID.uuidString.lowercased())"
                    ),
                    URLQueryItem(name: "order", value: "recorded_at.asc")
                ]
            )
        )
        let values = try decode([SupabaseWeighInReadDTO].self, data)
        return try mapDTO {
            try values.map { try $0.domain() }
        }
    }

    private func score(
        enrollment: ProgramEnrollment,
        participantID: UUID,
        displayName: String
    ) async throws -> LeaderboardEntry? {
        let data = try await client.execute(
            SupabaseRequest(
                method: .get,
                path: "/rest/v1/program_scores",
                queryItems: [
                    URLQueryItem(
                        name: "select",
                        value: Self.scoreSelection
                    ),
                    URLQueryItem(
                        name: "enrollment_id",
                        value: "eq.\(enrollment.id.uuidString.lowercased())"
                    ),
                    URLQueryItem(name: "limit", value: "1")
                ]
            )
        )
        let values = try decode([SupabaseProgramScoreDTO].self, data)
        guard values.count <= 1 else {
            throw DomainError.conflict(
                reason: "Skor enrollment tidak konsisten."
            )
        }
        return values.first?.ownLeaderboardEntry(
            programID: enrollment.programID,
            participantID: participantID,
            displayName: displayName
        )
    }

    private func rpc<Response: Decodable>(
        name: String
    ) async throws -> Response {
        let data = try await client.execute(
            SupabaseRequest(
                method: .post,
                path: "/rest/v1/rpc/\(name)",
                headers: ["Content-Type": "application/json"],
                body: Data("{}".utf8)
            )
        )
        return try decode(Response.self, data)
    }

    private func decode<Value: Decodable>(
        _ type: Value.Type,
        _ data: Data
    ) throws -> Value {
        do {
            return try SupabaseJSON.decoder.decode(type, from: data)
        } catch let error as SupabaseDTOError {
            throw mapDTOError(error)
        } catch {
            throw DomainError.unknown
        }
    }

    private func mapDTO<Value>(
        _ operation: () throws -> Value
    ) throws -> Value {
        do {
            return try operation()
        } catch let error as SupabaseDTOError {
            throw mapDTOError(error)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.unknown
        }
    }

    private func mapDTOError(_ error: SupabaseDTOError) -> DomainError {
        switch error {
        case .invalidField(let field):
            .validation(
                field: field,
                reason: "Data akun dari server tidak valid."
            )
        }
    }

    private static let accountSelection = """
    user_id,public_profile_id,role,display_name,city,phone_number,\
    current_coach_id,provider_avatar_url,member_level,onboarding_status,\
    account_purpose
    """

    private static let enrollmentSelection = """
    id,program_id,participant_id,coach_id,status,enrolled_at
    """

    private static let submissionSelection = """
    id,enrollment_id,step_id,attempt_sequence,status,submitted_at,reviewed_at,\
    reviewer_id,review_note,\
    step_submission_answers(\
    id,question_id,text_value,number_value,selected_option_ids,\
    private_photo_path),\
    quiz_attempt_results(\
    id,correct_count,total_count,percentage,passed,awarded_points,reopened_at,\
    reopened_by,reopen_reason)
    """

    private static let weighInSelection = """
    id,enrollment_id,step_id,kind,weight_kg,recorded_at
    """

    private static let scoreSelection = """
    public_id,enrollment_id,activity_points,quiz_points,weight_points,\
    adjustment_points,progress_percentage,rank
    """
}
