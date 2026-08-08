import Foundation

actor SupabasePhase11Repository:
    ProfileRepository,
    CoachDirectoryRepository,
    ProgramRepository,
    EnrollmentRepository,
    CoachQREnrollmentRepository,
    SubmissionRepository,
    WeighInRepository,
    LeaderboardRepository,
    CoachParticipantRepository,
    ManagedContentRepository,
    AdminPeopleRepository,
    CoachApplicationRepository,
    AdminProgramDraftRepository,
    AuthoritativeAdminOperationsRepository,
    AuditRepository,
    ParticipantDemoRepository
{
    private let client: any SupabaseClientProviding
    private let sessionRepository: any SessionRepository
    private let profileClient: any SupabaseProfileClientProviding
    private let catalog: SupabaseProgramCatalogRepository
    private let publicLeaderboard: SupabasePublicLeaderboardRepository
    private let publicManagedContent: SupabasePublicManagedContentRepository
    private let submissionCommands: SupabaseSubmissionCommandRepository
    private let privatePhotos: SupabasePrivatePhotoRepository
    private let fileStore = LocalMediaFileStore()

    init(
        client: any SupabaseClientProviding,
        sessionRepository: any SessionRepository,
        profileClient: any SupabaseProfileClientProviding
    ) {
        self.client = client
        self.sessionRepository = sessionRepository
        self.profileClient = profileClient
        catalog = SupabaseProgramCatalogRepository(client: client)
        publicLeaderboard = SupabasePublicLeaderboardRepository(client: client)
        publicManagedContent = SupabasePublicManagedContentRepository(
            client: client
        )
        submissionCommands = SupabaseSubmissionCommandRepository(
            client: client
        )
        privatePhotos = SupabasePrivatePhotoRepository(client: client)
    }

    // MARK: - Profiles and people

    func user(id: UUID) async throws -> AppUser {
        let current = try await sessionRepository.loadCurrentSession().user
        if let current, current.id == id {
            return current
        }
        return try await profileRow(id: id).appUser(email: "")
    }

    func participantProfile(userID: UUID) async throws -> ParticipantProfile {
        let row = try await profileRow(id: userID)
        guard row.role == UserRole.participant.rawValue else {
            throw DomainError.permissionDenied
        }
        return try row.participantProfile()
    }

    func coachProfile(userID: UUID) async throws -> CoachProfile {
        let row = try await profileRow(id: userID)
        guard row.role == UserRole.coach.rawValue else {
            throw DomainError.permissionDenied
        }
        return row.coachProfile()
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
        let profile = try await profileClient.updateMyProfile(
            displayName: participantProfile.displayName,
            phoneNumber: phoneNumber,
            memberLevel: memberLevel,
            accountPurpose: .participant,
            accessToken: token
        )
        return ParticipantProfile(
            id: profile.userID,
            userID: profile.userID,
            coachID: profile.currentCoachID,
            displayName: profile.displayName,
            city: participantProfile.city,
            phoneNumber: profile.phoneNumber,
            localPhotoReference:
                profile.providerAvatarURL?.absoluteString,
            memberLevel: profile.memberLevel
        )
    }

    func save(coachProfile: CoachProfile) async throws -> CoachProfile {
        struct Body: Encodable {
            let targetCoachUserID: UUID
            let newDisplayName: String
            let newBiography: String
            let newCity: String
            let newIsPublic: Bool
            let reason: String

            enum CodingKeys: String, CodingKey {
                case targetCoachUserID = "target_coach_user_id"
                case newDisplayName = "new_display_name"
                case newBiography = "new_biography"
                case newCity = "new_city"
                case newIsPublic = "new_is_public"
                case reason
            }
        }
        let data = try await rpc(
            "update_coach_profile",
            Body(
                targetCoachUserID: coachProfile.userID,
                newDisplayName: coachProfile.displayName,
                newBiography: coachProfile.biography,
                newCity: coachProfile.city,
                newIsPublic: coachProfile.isPublic,
                reason: "Profil Coach diperbarui melalui aplikasi."
            )
        )
        return try decode(SupabaseProfileRowDTO.self, from: data)
            .coachProfile()
    }

    func publicCoaches() async throws -> [CoachProfile] {
        let data = try await rpc(
            "list_public_coaches",
            PaginationBody(resultLimit: 100, resultOffset: 0)
        )
        return try decode([SupabasePublicCoachDTO].self, from: data)
            .map { $0.domain() }
    }

    func usersForAdministration() async throws -> [AppUser] {
        try await allProfileRows().map { try $0.appUser(email: "") }
    }

    func participantProfilesForAdministration() async throws
        -> [ParticipantProfile] {
        try await allProfileRows()
            .filter { $0.role == UserRole.participant.rawValue }
            .map { try $0.participantProfile() }
    }

    func coachProfilesForAdministration() async throws -> [CoachProfile] {
        try await allProfileRows()
            .filter { $0.role == UserRole.coach.rawValue }
            .map { $0.coachProfile() }
    }

    func usersAwaitingCoachApproval() async throws -> [AppUser] {
        let applications = try await coachApplicationsForAdministration()
            .filter {
                $0.status == .submitted
                    || $0.status == .pendingAdminApproval
            }
        let identifiers = Set(applications.map(\.userID))
        return try await usersForAdministration().filter {
            identifiers.contains($0.id)
        }
    }

    func setCoachApproval(
        userID: UUID,
        isApproved: Bool
    ) async throws -> AppUser {
        guard let application = try await coachApplicationsForAdministration()
            .first(where: { $0.userID == userID }) else {
            throw DomainError.notFound(resource: "Pengajuan Coach")
        }
        if isApproved {
            _ = try await decideCoachApplication(
                id: application.id,
                decision: "approved",
                reason: nil,
                key: "approve-\(application.id.uuidString.lowercased())"
            )
        } else {
            _ = try await decideCoachApplication(
                id: application.id,
                decision: "rejected",
                reason: "Pengajuan ditolak oleh Admin.",
                key: "reject-\(application.id.uuidString.lowercased())"
            )
        }
        return try await user(id: userID)
    }

    func transferActiveCoach(
        participantID: UUID,
        coachID: UUID
    ) async throws -> ParticipantProfile {
        struct Body: Encodable {
            let targetParticipantID: UUID
            let targetCoachID: UUID
            let reason: String

            enum CodingKeys: String, CodingKey {
                case targetParticipantID = "target_participant_id"
                case targetCoachID = "target_coach_id"
                case reason
            }
        }
        _ = try await rpc(
            "admin_transfer_coach",
            Body(
                targetParticipantID: participantID,
                targetCoachID: coachID,
                reason: "Coach dialihkan melalui aplikasi Admin."
            )
        )
        return try await participantProfile(userID: participantID)
    }

    // MARK: - Programs and Admin CMS

    func programs() async throws -> [Program] {
        try await catalog.programs()
    }

    func program(id: UUID) async throws -> Program {
        try await catalog.program(id: id)
    }

    func activeProgram() async throws -> Program? {
        try await programs().first { $0.status == .active }
    }

    func save(program: Program) async throws -> Program {
        try await saveProgramDraft(
            AdminProgramDraft(program: program, updatedAt: Date())
        ).program()
    }

    func programDraftsForAdministration() async throws
        -> [AdminProgramDraft] {
        try await adminPrograms().map {
            AdminProgramDraft(program: try $0.domain(), updatedAt: Date())
        }
    }

    func programDraftForAdministration(
        id: UUID
    ) async throws -> AdminProgramDraft {
        guard let value = try await adminPrograms(id: id).first else {
            throw DomainError.notFound(resource: "Program")
        }
        return AdminProgramDraft(program: try value.domain(), updatedAt: Date())
    }

    func save(
        programDraft: AdminProgramDraft
    ) async throws -> AdminProgramDraft {
        if let sourceID = programDraft.sourceProgramID,
           (try? await adminPrograms(id: programDraft.id).isEmpty) == true {
            struct DuplicateBody: Encodable {
                let sourceProgramID: UUID
                let targetProgramID: UUID
                let targetTitle: String
                let targetStartsOn: String
                let requestIdempotencyKey: String

                enum CodingKeys: String, CodingKey {
                    case sourceProgramID = "source_target_id"
                    case targetProgramID = "target_program_id"
                    case targetTitle = "target_title"
                    case targetStartsOn = "target_starts_on"
                    case requestIdempotencyKey = "request_idempotency_key"
                }
            }
            _ = try await rpc(
                "duplicate_program_as_draft",
                DuplicateBody(
                    sourceProgramID: sourceID,
                    targetProgramID: programDraft.id,
                    targetTitle: programDraft.title,
                    targetStartsOn: Self.dateString(programDraft.startDate),
                    requestIdempotencyKey:
                        "duplicate-\(programDraft.id.uuidString.lowercased())"
                )
            )
        } else {
            _ = try await rpcData(
                "save_program_draft",
                jsonObject: [
                    "program_payload": Self.programPayload(programDraft),
                    "request_idempotency_key":
                        "draft-\(programDraft.id.uuidString.lowercased())-"
                        + String(Int(programDraft.updatedAt.timeIntervalSince1970))
                ]
            )
        }

        if programDraft.status == .scheduled
            || programDraft.status == .active {
            struct PublishBody: Encodable {
                let targetProgramID: UUID
                let requestIdempotencyKey: String
                enum CodingKeys: String, CodingKey {
                    case targetProgramID = "target_program_id"
                    case requestIdempotencyKey = "request_idempotency_key"
                }
            }
            _ = try await rpc(
                "publish_program",
                PublishBody(
                    targetProgramID: programDraft.id,
                    requestIdempotencyKey:
                        "publish-\(programDraft.id.uuidString.lowercased())"
                )
            )
        } else if programDraft.status != .draft {
            throw DomainError.validation(
                field: "status",
                reason: "Transisi status program harus melalui operasi server."
            )
        }
        return try await programDraftForAdministration(id: programDraft.id)
    }

    private func saveProgramDraft(
        _ draft: AdminProgramDraft
    ) async throws -> AdminProgramDraft {
        try await save(programDraft: draft)
    }

    // MARK: - QR and enrollment

    func resolveCoach(qrOpaqueValue: String) async throws -> CoachProfile {
        struct Body: Encodable {
            let scannedCoachQR: String
            enum CodingKeys: String, CodingKey {
                case scannedCoachQR = "scanned_coach_qr"
            }
        }
        let data = try await rpc(
            "resolve_coach_qr_for_enrollment",
            Body(scannedCoachQR: qrOpaqueValue)
        )
        let value = try decode(SupabaseResolvedCoachDTO.self, from: data)
        return value.domain(qrOpaqueValue: qrOpaqueValue)
    }

    func enrollFreeProgram(
        programID: UUID,
        coachQROpaqueValue: String
    ) async throws -> ProgramEnrollment {
        try await SupabaseEnrollmentCommandRepository(client: client)
            .enrollFreeProgram(
                programID: programID,
                coachQRPayload: coachQROpaqueValue
            )
    }

    func allEnrollments() async throws -> [ProgramEnrollment] {
        try await enrollmentRows().map { try $0.domain() }
    }

    func enrollments(
        participantID: UUID
    ) async throws -> [ProgramEnrollment] {
        try await enrollmentRows(participantID: participantID)
            .map { try $0.domain() }
    }

    func enrollment(
        programID: UUID,
        participantID: UUID
    ) async throws -> ProgramEnrollment? {
        try await enrollmentRows(
            participantID: participantID,
            programID: programID
        ).first.map { try $0.domain() }
    }

    func createEnrollment(
        _ enrollment: ProgramEnrollment
    ) async throws -> ProgramEnrollment {
        guard try await currentRole() == .admin else {
            throw DomainError.validation(
                field: "coachQR",
                reason: "Pendaftaran peserta memerlukan QR Coach yang valid."
            )
        }
        return try await SupabaseAdminEnrollmentCommandRepository(
            client: client
        ).enrollParticipant(
            programID: enrollment.programID,
            participantID: enrollment.participantID,
            reason: "Pendaftaran manual melalui aplikasi Admin."
        )
    }

    func adminEnrollParticipant(
        programID: UUID,
        participantID: UUID,
        reason: String
    ) async throws -> ProgramEnrollment {
        try await SupabaseAdminEnrollmentCommandRepository(client: client)
            .enrollParticipant(
                programID: programID,
                participantID: participantID,
                reason: reason
            )
    }

    func reassignCoach(
        participantID: UUID,
        coachID: UUID
    ) async throws -> [ProgramEnrollment] {
        _ = try await transferActiveCoach(
            participantID: participantID,
            coachID: coachID
        )
        return try await enrollments(participantID: participantID)
    }

    func adminTransferCoach(
        participantID: UUID,
        coachID: UUID,
        reason: String
    ) async throws -> ParticipantProfile {
        struct Body: Encodable {
            let targetParticipantID: UUID
            let targetCoachID: UUID
            let reason: String

            enum CodingKeys: String, CodingKey {
                case targetParticipantID = "target_participant_id"
                case targetCoachID = "target_coach_id"
                case reason
            }
        }
        _ = try await rpc(
            "admin_transfer_coach",
            Body(
                targetParticipantID: participantID,
                targetCoachID: coachID,
                reason: reason
            )
        )
        return try await participantProfile(userID: participantID)
    }

    // MARK: - Submission, media, quiz, and review

    func pendingReviewCount() async throws -> Int {
        try await submissionRows(status: .pending).count
    }

    func submissions(
        enrollmentID: UUID
    ) async throws -> [StepSubmission] {
        try await submissionRows(enrollmentID: enrollmentID)
            .map { try $0.domain() }
    }

    func submissionHistory(
        enrollmentID: UUID,
        stepID: UUID
    ) async throws -> [StepSubmission] {
        try await submissionRows(
            enrollmentID: enrollmentID,
            stepID: stepID
        ).map { try $0.domain() }
    }

    func quizAttempts(
        enrollmentID: UUID,
        stepID: UUID
    ) async throws -> [QuizAttemptResult] {
        try await submissionHistory(
            enrollmentID: enrollmentID,
            stepID: stepID
        ).compactMap(\.quizResult)
    }

    func reviewQueue(coachID: UUID) async throws -> [StepSubmission] {
        _ = coachID
        return try await submissionRows(status: .pending)
            .map { try $0.domain() }
    }

    func completeStep(
        submission: StepSubmission
    ) async throws -> StepSubmission {
        let key = "submission-\(submission.id.uuidString.lowercased())"
        let prepared = try await submissionCommands.prepare(
            enrollmentID: submission.enrollmentID,
            stepID: submission.stepID,
            idempotencyKey: key
        )
        let participantID = try await requireCurrentUserID()
        var commands: [SupabaseSubmissionAnswerCommand] = []
        var temporaryURLs: [URL] = []

        for answer in submission.typedAnswers {
            var privatePath: String?
            if let reference = answer.localPhotoReference,
               let url = URL(string: reference), url.isFileURL {
                let jpegData: Data
                do {
                    jpegData = try Data(contentsOf: url)
                } catch {
                    throw DomainError.notFound(resource: "Foto")
                }
                privatePath = try await privatePhotos.upload(
                    jpegData: jpegData,
                    participantID: participantID,
                    prepared: prepared,
                    questionID: answer.questionID,
                    objectID: answer.id,
                    isRetry: true
                )
                temporaryURLs.append(url)
            } else if answer.localPhotoReference?.isEmpty == false {
                privatePath = answer.localPhotoReference
            }
            commands.append(
                SupabaseSubmissionAnswerCommand(
                    questionID: answer.questionID,
                    textValue: answer.textValue,
                    numberValue: answer.numberValue,
                    selectedOptionIDs: answer.selectedOptionIDs,
                    privatePhotoPath: privatePath
                )
            )
        }
        let result = try await submissionCommands.submit(
            prepared: prepared,
            answers: commands
        )
        for url in temporaryURLs { try? fileStore.remove(url: url) }
        return result
    }

    func reviewSubmission(
        id: UUID,
        reviewerID: UUID,
        status: SubmissionStatus,
        note: String?,
        reviewedAt: Date
    ) async throws -> StepSubmission {
        _ = reviewerID
        return try await submissionCommands.review(
            submissionID: id,
            decision: status,
            reason: note,
            idempotencyKey:
                "review-\(id.uuidString.lowercased())-\(status.rawValue)-"
                + String(Int(reviewedAt.timeIntervalSince1970))
        )
    }

    func saveCoachRating(
        submissionID: UUID,
        reviewerID: UUID,
        rating: Int
    ) async throws -> StepSubmission {
        _ = submissionID
        _ = reviewerID
        _ = rating
        throw DomainError.validation(
            field: "coachRating",
            reason: "Penilaian bintang belum termasuk kontrak server Phase 11."
        )
    }

    func reopenQuizAttempt(
        enrollmentID: UUID,
        stepID: UUID,
        adminID: UUID,
        reason: String,
        reopenedAt: Date
    ) async throws -> QuizAttemptResult {
        _ = adminID
        struct Body: Encodable {
            let targetEnrollmentID: UUID
            let targetStepID: UUID
            let reason: String
            let requestIdempotencyKey: String
            enum CodingKeys: String, CodingKey {
                case targetEnrollmentID = "target_enrollment_id"
                case targetStepID = "target_step_id"
                case reason
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        _ = try await rpc(
            "reopen_quiz_attempt",
            Body(
                targetEnrollmentID: enrollmentID,
                targetStepID: stepID,
                reason: reason,
                requestIdempotencyKey:
                    "quiz-reopen-\(enrollmentID.uuidString.lowercased())-"
                    + "\(stepID.uuidString.lowercased())-"
                    + String(Int(reopenedAt.timeIntervalSince1970))
            )
        )
        guard let result = try await quizAttempts(
            enrollmentID: enrollmentID,
            stepID: stepID
        ).last else {
            throw DomainError.notFound(resource: "Percobaan kuis")
        }
        return result
    }

    // MARK: - Weigh-in and score

    func weighIns(enrollmentID: UUID) async throws -> [WeighIn] {
        try await weighInRows(enrollmentID: enrollmentID)
            .map { try $0.domain() }
    }

    func save(weighIn: WeighIn) async throws -> WeighIn {
        struct Body: Encodable {
            let targetEnrollmentID: UUID
            let targetStepID: UUID?
            let weighKind: String
            let weightKilograms: Decimal
            let requestIdempotencyKey: String
            enum CodingKeys: String, CodingKey {
                case targetEnrollmentID = "target_enrollment_id"
                case targetStepID = "target_step_id"
                case weighKind = "weigh_kind"
                case weightKilograms = "weight_kilograms"
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        let data = try await rpc(
            "submit_weigh_in",
            Body(
                targetEnrollmentID: weighIn.enrollmentID,
                targetStepID: weighIn.stepID,
                weighKind: weighIn.type.rawValue,
                weightKilograms: weighIn.weightKilograms,
                requestIdempotencyKey:
                    "weigh-\(weighIn.id.uuidString.lowercased())"
            )
        )
        return try decode(SupabaseWeighInReadDTO.self, from: data).domain()
    }

    func correctWeighIn(
        enrollmentID: UUID,
        type: WeighInType,
        stepID: UUID?,
        weightKilograms: Decimal,
        correctedAt: Date
    ) async throws -> WeighIn {
        guard let existing = try await weighIns(enrollmentID: enrollmentID)
            .last(where: { $0.type == type && $0.stepID == stepID }) else {
            throw DomainError.notFound(resource: "Timbang badan")
        }
        struct Body: Encodable {
            let targetWeighInID: UUID
            let correctedWeightKilograms: Decimal
            let reason: String
            let requestIdempotencyKey: String
            enum CodingKeys: String, CodingKey {
                case targetWeighInID = "target_weigh_in_id"
                case correctedWeightKilograms = "corrected_weight_kilograms"
                case reason
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        let data = try await rpc(
            "admin_correct_weigh_in",
            Body(
                targetWeighInID: existing.id,
                correctedWeightKilograms: weightKilograms,
                reason: "Koreksi timbang badan melalui aplikasi Admin.",
                requestIdempotencyKey:
                    "weigh-correction-\(existing.id.uuidString.lowercased())-"
                    + String(Int(correctedAt.timeIntervalSince1970))
            )
        )
        return try decode(SupabaseWeighInReadDTO.self, from: data).domain()
    }

    func leaderboard(programID: UUID) async throws -> [LeaderboardEntry] {
        try await publicLeaderboard.leaderboard(programID: programID)
    }

    func winners(programID: UUID) async throws -> [ProgramWinner] {
        try await publicLeaderboard.winners(programID: programID)
    }

    func applyScoreAdjustment(
        entryID: UUID,
        points: Int
    ) async throws -> LeaderboardEntry {
        let rows: [SupabaseScoreLookupDTO] = try await rest(
            path: "/rest/v1/program_scores",
            query: [
                URLQueryItem(name: "select", value: "enrollment_id"),
                URLQueryItem(
                    name: "public_id",
                    value: "eq.\(entryID.uuidString.lowercased())"
                ),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        guard let enrollmentID = rows.first?.enrollmentID else {
            throw DomainError.notFound(resource: "Skor")
        }
        struct Body: Encodable {
            let targetEnrollmentID: UUID
            let points: Int
            let reason: String
            let requestIdempotencyKey: String
            enum CodingKeys: String, CodingKey {
                case targetEnrollmentID = "target_enrollment_id"
                case points
                case reason
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        _ = try await rpc(
            "admin_adjust_score",
            Body(
                targetEnrollmentID: enrollmentID,
                points: points,
                reason: "Penyesuaian skor melalui aplikasi Admin.",
                requestIdempotencyKey:
                    "score-adjust-\(entryID.uuidString.lowercased())-\(points)"
            )
        )
        let enrollmentRows = try await enrollmentRows(id: enrollmentID)
        guard let enrollment = try enrollmentRows.first?.domain(),
              let result = try await leaderboard(
                programID: enrollment.programID
              ).first(where: { $0.id == entryID }) else {
            throw DomainError.notFound(resource: "Skor")
        }
        return result
    }

    func adminAdjustScore(
        entryID: UUID,
        points: Int,
        reason: String
    ) async throws -> LeaderboardEntry {
        let rows: [SupabaseScoreLookupDTO] = try await rest(
            path: "/rest/v1/program_scores",
            query: [
                URLQueryItem(name: "select", value: "enrollment_id"),
                URLQueryItem(
                    name: "public_id",
                    value: "eq.\(entryID.uuidString.lowercased())"
                ),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        guard let enrollmentID = rows.first?.enrollmentID else {
            throw DomainError.notFound(resource: "Skor")
        }
        struct Body: Encodable {
            let targetEnrollmentID: UUID
            let points: Int
            let reason: String
            let requestIdempotencyKey: String

            enum CodingKeys: String, CodingKey {
                case targetEnrollmentID = "target_enrollment_id"
                case points
                case reason
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        _ = try await rpc(
            "admin_adjust_score",
            Body(
                targetEnrollmentID: enrollmentID,
                points: points,
                reason: reason,
                requestIdempotencyKey:
                    "score-adjust-\(entryID.uuidString.lowercased())-"
                    + String(points) + "-" + stableKeyComponent(reason)
            )
        )
        let enrollmentRows = try await enrollmentRows(id: enrollmentID)
        guard let enrollment = try enrollmentRows.first?.domain(),
              let result = try await leaderboard(
                programID: enrollment.programID
              ).first(where: { $0.id == entryID }) else {
            throw DomainError.notFound(resource: "Skor")
        }
        return result
    }

    func lockTopFive(
        programID: UUID,
        lockedAt: Date
    ) async throws -> [ProgramWinner] {
        struct Body: Encodable {
            let targetProgramID: UUID
            let requestIdempotencyKey: String
            enum CodingKeys: String, CodingKey {
                case targetProgramID = "target_program_id"
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        _ = lockedAt
        _ = try await rpc(
            "lock_program_winners",
            Body(
                targetProgramID: programID,
                requestIdempotencyKey:
                    "winner-lock-\(programID.uuidString.lowercased())"
            )
        )
        return try await winners(programID: programID)
    }

    func completeAndLockWinners(
        programID: UUID,
        reason: String
    ) async throws -> [ProgramWinner] {
        struct CompleteBody: Encodable {
            let targetProgramID: UUID
            let reason: String
            let requestIdempotencyKey: String

            enum CodingKeys: String, CodingKey {
                case targetProgramID = "target_program_id"
                case reason
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        _ = try await rpc(
            "complete_program",
            CompleteBody(
                targetProgramID: programID,
                reason: reason,
                requestIdempotencyKey:
                    "program-complete-\(programID.uuidString.lowercased())"
            )
        )
        return try await lockTopFive(programID: programID, lockedAt: Date())
    }

    func resetLockedWinnersForDebug(programID: UUID) async {
        _ = programID
    }

    // MARK: - Coach monitoring

    func assignedParticipants(
        coachID: UUID
    ) async throws -> [ParticipantProfile] {
        _ = coachID
        let data = try await rpc("list_my_assigned_participants", EmptyBody())
        return try decode([SupabaseCoachRosterDTO].self, from: data)
            .map { try $0.profile.domain() }
    }

    func assignedParticipant(
        id participantID: UUID,
        coachID: UUID
    ) async throws -> ParticipantProfile {
        guard let profile = try await assignedParticipants(coachID: coachID)
            .first(where: { $0.id == participantID }) else {
            throw DomainError.notFound(resource: "Peserta")
        }
        return profile
    }

    // MARK: - Coach application

    func coachApplication(userID: UUID) async throws -> CoachApplication? {
        let currentUserID = try await requireCurrentUserID()
        guard userID == currentUserID else {
            throw DomainError.permissionDenied
        }
        let data = try await rpc("get_my_coach_application", EmptyBody())
        return try decode(
            SupabaseCoachApplicationAggregateDTO?.self,
            from: data
        )?.domain()
    }

    func coachApplicationsForAdministration() async throws
        -> [CoachApplication] {
        let data = try await rpc(
            "list_coach_applications_for_admin",
            EmptyBody()
        )
        return try decode(
            [SupabaseCoachApplicationAggregateDTO].self,
            from: data
        ).map { try $0.domain() }
    }

    func saveCoachApplication(
        _ application: CoachApplication
    ) async throws -> CoachApplication {
        struct Body: Encodable {
            let memberLevel: String
            let hasCompletedHOMSTS: Bool
            let hasCompletedICT: Bool
            let termsVersion: String
            let requestIdempotencyKey: String
            enum CodingKeys: String, CodingKey {
                case memberLevel = "member_level"
                case hasCompletedHOMSTS =
                    "applicant_has_completed_hom_sts"
                case hasCompletedICT = "applicant_has_completed_ict"
                case termsVersion = "accepted_terms_version"
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        _ = try await rpc(
            "save_my_coach_application_draft",
            Body(
                memberLevel: application.memberLevel.rawValue,
                hasCompletedHOMSTS: application.hasCompletedHOMSTS,
                hasCompletedICT: application.hasCompletedICT,
                termsVersion: application.termsVersion,
                requestIdempotencyKey:
                    "coach-draft-\(application.id.uuidString.lowercased())-"
                    + String(Int(application.updatedAt.timeIntervalSince1970))
            )
        )
        guard let result = try await coachApplication(userID: application.userID) else {
            throw DomainError.notFound(resource: "Pengajuan Coach")
        }
        return result
    }

    func submitCoachApplication(
        applicationID: UUID
    ) async throws -> CoachApplication {
        struct Body: Encodable {
            let targetApplicationID: UUID
            let requestIdempotencyKey: String
            enum CodingKeys: String, CodingKey {
                case targetApplicationID = "target_application_id"
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        _ = try await rpc(
            "submit_my_coach_application",
            Body(
                targetApplicationID: applicationID,
                requestIdempotencyKey:
                    "coach-submit-\(applicationID.uuidString.lowercased())"
            )
        )
        guard let result = try await coachApplication(
            userID: requireCurrentUserID()
        ) else {
            throw DomainError.notFound(resource: "Pengajuan Coach")
        }
        return result
    }

    func approveCoachApplication(
        applicationID: UUID,
        adminUserID: UUID,
        decidedAt: Date
    ) async throws -> CoachApplication {
        _ = adminUserID
        _ = decidedAt
        return try await decideCoachApplication(
            id: applicationID,
            decision: "approved",
            reason: nil,
            key: "coach-approve-\(applicationID.uuidString.lowercased())"
        )
    }

    func rejectCoachApplication(
        applicationID: UUID,
        adminUserID: UUID,
        reason: String,
        decidedAt: Date
    ) async throws -> CoachApplication {
        _ = adminUserID
        _ = decidedAt
        return try await decideCoachApplication(
            id: applicationID,
            decision: "rejected",
            reason: reason,
            key: "coach-reject-\(applicationID.uuidString.lowercased())"
        )
    }

    // MARK: - Managed content and audit

    func managedContent() async throws -> [ManagedContent] {
        try await publicManagedContent.managedContent()
    }

    func save(content: ManagedContent) async throws -> ManagedContent {
        guard content.kind == .winnerBanner,
              let programID = content.programID,
              let snapshotID = content.winnerSnapshotID,
              let mediaPath = content.localMediaReference,
              !mediaPath.isEmpty else {
            throw DomainError.validation(
                field: "winnerPoster",
                reason: "Poster memerlukan program, snapshot, dan media publik."
            )
        }
        struct Body: Encodable {
            let targetProgramID: UUID
            let targetSnapshotID: UUID
            let mediaPath: String
            let altText: String
            let requestIdempotencyKey: String
            enum CodingKeys: String, CodingKey {
                case targetProgramID = "target_program_id"
                case targetSnapshotID = "target_snapshot_id"
                case mediaPath = "media_path"
                case altText = "alt_text"
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        _ = try await rpc(
            "publish_winner_poster",
            Body(
                targetProgramID: programID,
                targetSnapshotID: snapshotID,
                mediaPath: mediaPath,
                altText: content.title,
                requestIdempotencyKey:
                    "winner-poster-\(content.id.uuidString.lowercased())"
            )
        )
        return content
    }

    func auditEventsForAdministration() async throws -> [AuditEvent] {
        let rows: [SupabaseAuditEventDTO] = try await rest(
            path: "/rest/v1/audit_events",
            query: [
                URLQueryItem(
                    name: "select",
                    value: "id,kind,actor_id,subject_id,summary,created_at"
                ),
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
        )
        return rows.compactMap { try? $0.domain() }
    }

    func append(auditEvent: AuditEvent) async throws -> AuditEvent {
        // Production mutations write audit events in the same server
        // transaction. This compatibility return avoids a second client-side
        // write while legacy local use cases are progressively retired.
        auditEvent
    }

    // MARK: - Demo controls are intentionally inert in real mode

    func resetParticipantDemo(participantID: UUID) async { _ = participantID }
    func resetParticipantProgress(participantID: UUID) async { _ = participantID }
    func markPreviousDaysComplete(
        participantID: UUID,
        throughDayNumber: Int,
        completedAt: Date
    ) async throws {
        _ = participantID
        _ = throughDayNumber
        _ = completedAt
        throw DomainError.permissionDenied
    }
    func simulateRejectedSubmission(
        participantID: UUID,
        dayNumber: Int,
        completedAt: Date
    ) async throws -> StepSubmission? {
        _ = participantID
        _ = dayNumber
        _ = completedAt
        throw DomainError.permissionDenied
    }

    // MARK: - Transport helpers

    private func profileRow(id: UUID) async throws -> SupabaseProfileRowDTO {
        let values: [SupabaseProfileRowDTO] = try await rest(
            path: "/rest/v1/profiles",
            query: [
                URLQueryItem(name: "select", value: Self.profileSelection),
                URLQueryItem(
                    name: "user_id",
                    value: "eq.\(id.uuidString.lowercased())"
                ),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        guard let value = values.first else {
            throw DomainError.notFound(resource: "Profil")
        }
        return value
    }

    private func allProfileRows() async throws -> [SupabaseProfileRowDTO] {
        try await rest(
            path: "/rest/v1/profiles",
            query: [
                URLQueryItem(name: "select", value: Self.profileSelection),
                URLQueryItem(name: "order", value: "display_name.asc")
            ]
        )
    }

    private func adminPrograms(
        id: UUID? = nil
    ) async throws -> [SupabaseProgramDTO] {
        var query = [
            URLQueryItem(name: "select", value: Self.adminProgramSelection),
            URLQueryItem(name: "order", value: "starts_on.desc")
        ]
        if let id {
            query.append(
                URLQueryItem(
                    name: "id",
                    value: "eq.\(id.uuidString.lowercased())"
                )
            )
        }
        return try await rest(path: "/rest/v1/programs", query: query)
    }

    private func enrollmentRows(
        id: UUID? = nil,
        participantID: UUID? = nil,
        programID: UUID? = nil
    ) async throws -> [SupabaseEnrollmentDTO] {
        var query = [
            URLQueryItem(name: "select", value: Self.enrollmentSelection),
            URLQueryItem(name: "order", value: "enrolled_at.asc")
        ]
        if let id {
            query.append(URLQueryItem(name: "id", value: "eq.\(id)"))
        }
        if let participantID {
            query.append(
                URLQueryItem(name: "participant_id", value: "eq.\(participantID)")
            )
        }
        if let programID {
            query.append(
                URLQueryItem(name: "program_id", value: "eq.\(programID)")
            )
        }
        return try await rest(
            path: "/rest/v1/program_enrollments",
            query: query
        )
    }

    private func submissionRows(
        enrollmentID: UUID? = nil,
        stepID: UUID? = nil,
        status: SubmissionStatus? = nil
    ) async throws -> [SupabaseSubmissionReadDTO] {
        var query = [
            URLQueryItem(name: "select", value: Self.submissionSelection),
            URLQueryItem(name: "order", value: "submitted_at.asc")
        ]
        if let enrollmentID {
            query.append(
                URLQueryItem(name: "enrollment_id", value: "eq.\(enrollmentID)")
            )
        }
        if let stepID {
            query.append(URLQueryItem(name: "step_id", value: "eq.\(stepID)"))
        }
        if let status {
            query.append(URLQueryItem(name: "status", value: "eq.\(status.rawValue)"))
        }
        return try await rest(path: "/rest/v1/step_submissions", query: query)
    }

    private func weighInRows(
        enrollmentID: UUID
    ) async throws -> [SupabaseWeighInReadDTO] {
        try await rest(
            path: "/rest/v1/weigh_ins",
            query: [
                URLQueryItem(name: "select", value: Self.weighInSelection),
                URLQueryItem(name: "enrollment_id", value: "eq.\(enrollmentID)"),
                URLQueryItem(name: "order", value: "recorded_at.asc")
            ]
        )
    }

    private func decideCoachApplication(
        id: UUID,
        decision: String,
        reason: String?,
        key: String
    ) async throws -> CoachApplication {
        struct Body: Encodable {
            let targetApplicationID: UUID
            let decision: String
            let decisionReason: String?
            let requestIdempotencyKey: String
            enum CodingKeys: String, CodingKey {
                case targetApplicationID = "target_application_id"
                case decision
                case decisionReason = "decision_reason"
                case requestIdempotencyKey = "request_idempotency_key"
            }
        }
        _ = try await rpc(
            "decide_coach_application",
            Body(
                targetApplicationID: id,
                decision: decision,
                decisionReason: reason,
                requestIdempotencyKey: key
            )
        )
        guard let result = try await coachApplicationsForAdministration()
            .first(where: { $0.id == id }) else {
            throw DomainError.notFound(resource: "Pengajuan Coach")
        }
        return result
    }

    private func currentRole() async throws -> UserRole {
        guard let role = try await sessionRepository.loadCurrentSession()
            .user?.role else {
            throw DomainError.sessionExpired
        }
        return role
    }

    private func requireCurrentUserID() async throws -> UUID {
        guard let id = try await sessionRepository.loadCurrentSession().user?.id else {
            throw DomainError.sessionExpired
        }
        return id
    }

    private func rest<Response: Decodable>(
        path: String,
        query: [URLQueryItem]
    ) async throws -> Response {
        let data = try await client.execute(
            SupabaseRequest(method: .get, path: path, queryItems: query)
        )
        return try decode(Response.self, from: data)
    }

    private func rpc<Body: Encodable>(
        _ name: String,
        _ body: Body
    ) async throws -> Data {
        try await client.execute(
            SupabaseRequest(
                method: .post,
                path: "/rest/v1/rpc/\(name)",
                headers: ["Content-Type": "application/json"],
                body: try SupabaseJSON.encoder.encode(body)
            )
        )
    }

    private func rpcData(
        _ name: String,
        jsonObject: Any
    ) async throws -> Data {
        let body: Data
        do {
            body = try JSONSerialization.data(withJSONObject: jsonObject)
        } catch {
            throw DomainError.validation(
                field: "request",
                reason: "Payload operasi server tidak valid."
            )
        }
        return try await client.execute(
            SupabaseRequest(
                method: .post,
                path: "/rest/v1/rpc/\(name)",
                headers: ["Content-Type": "application/json"],
                body: body
            )
        )
    }

    private func decode<Response: Decodable>(
        _ type: Response.Type,
        from data: Data
    ) throws -> Response {
        do {
            return try SupabaseJSON.decoder.decode(type, from: data)
        } catch let error as SupabaseDTOError {
            throw DomainError.validation(
                field: String(describing: error),
                reason: "Data server tidak valid."
            )
        } catch {
            throw DomainError.unknown
        }
    }

    private static func programPayload(
        _ draft: AdminProgramDraft
    ) -> [String: Any] {
        let calendar = Calendar(identifier: .gregorian)
        let days: [[String: Any]] = draft.days.map { day in
            let steps: [[String: Any]] = day.steps
                .filter(\.isActive)
                .map { step in
                    let questions: [[String: Any]] = (step.quiz?.questions ?? [])
                        .map { question in
                            var payload: [String: Any] = [
                                "id": question.id.uuidString.lowercased(),
                                "question_order": question.order,
                                "kind": question.kind.rawValue,
                                "prompt": question.prompt,
                                "options": question.options.enumerated().map {
                                    index, title in
                                    [
                                        "id": question.optionIDs.indices.contains(index)
                                            ? question.optionIDs[index].uuidString.lowercased()
                                            : UUID().uuidString.lowercased(),
                                        "option_order": index + 1,
                                        "title": title,
                                        "media_path": question.optionMediaReferences.indices.contains(index)
                                            ? jsonValue(question.optionMediaReferences[index])
                                            : NSNull()
                                    ] as [String: Any]
                                }
                            ]
                            if let key = question.answerKey {
                                payload["answer_key"] = [
                                    "accepted_text_values": key.acceptedTextValues,
                                    "number_value": jsonValue(key.numberValue.map {
                                        NSDecimalNumber(decimal: $0)
                                    }),
                                    "selected_option_ids": key.selectedOptionIDs.map {
                                        $0.uuidString.lowercased()
                                    },
                                    "matching_mode": key.matchingMode.rawValue
                                ]
                            }
                            return payload
                        }
                    let completionPolicy = step.publishedContent?
                        .completionPolicy.rawValue
                        ?? Self.defaultCompletionPolicy(step.contentKind)
                    return [
                        "id": step.id.uuidString.lowercased(),
                        "step_order": step.order,
                        "title": step.title,
                        "instructions": step.instructions,
                        "content_kind": step.contentKind.rawValue,
                        "completion_policy": completionPolicy,
                        "verification_mode": step.verificationMode.rawValue,
                        "media_path": jsonValue(step.localMediaReference),
                        "video_required": step.isVideoRequiredToWatch,
                        "video_threshold": jsonValue(
                            step.publishedContent?.videoConfiguration?
                                .completionThresholdPercentage
                        ),
                        "video_autoplay": step.isVideoAutoplayEnabled,
                        "questions": questions
                    ]
                }
            return [
                "id": day.id.uuidString.lowercased(),
                "day_number": day.dayNumber,
                "title": day.title,
                "summary": day.summary,
                "scheduled_on": dateString(day.scheduledDate, calendar: calendar),
                "steps": steps
            ]
        }
        let commerce = draft.commerceConfiguration
        var payload: [String: Any] = [
            "id": draft.id.uuidString.lowercased(),
            "title": draft.title,
            "summary": draft.summary,
            "category": draft.category,
            "cover_path": jsonValue(draft.coverLocalReference),
            "cover_alt_text": draft.coverAlternativeText,
            "pace": draft.pace.rawValue,
            "duration_mode": draft.durationMode.rawValue,
            "starts_on": dateString(draft.startDate, calendar: calendar),
            "ends_on": dateString(draft.endDate, calendar: calendar),
            "timezone": draft.timeZoneIdentifier,
            "participant_limit": jsonValue(draft.participantLimit),
            "registration_closes_at": jsonValue(
                draft.registrationClosesAt?.ISO8601Format()
            ),
            "past_step_policy": draft.pastStepPolicy.rawValue,
            "future_step_policy": draft.futureStepPolicy.rawValue,
            "wellness_disclaimer": draft.wellnessDisclaimer,
            "points_per_activity": draft.pointsPerActivity,
            "points_per_weight_kg": NSDecimalNumber(
                decimal: draft.weightPointsPerKilogram
            ),
            "quiz_passing_percentage": draft.quizPassingPercentage,
            "pricing_mode": commerce?.pricingMode.rawValue
                ?? (draft.price == nil ? "free" : "paid"),
            "desired_price": jsonValue(commerce?.desiredPrice.map {
                NSDecimalNumber(decimal: $0)
            }),
            "days": days
        ]
        if let sourceID = draft.sourceProgramID {
            payload["source_program_id"] = sourceID.uuidString.lowercased()
        }
        return payload
    }

    private static func defaultCompletionPolicy(
        _ kind: AdminStepContentKind
    ) -> String {
        switch kind {
        case .article: "mark_complete"
        case .video: "watch_video"
        case .form: "answer_all_questions"
        case .quiz: "automatic_quiz"
        case .initialWeighIn, .dailyWeighIn, .finalWeighIn:
            "submit_weigh_in"
        }
    }

    private static func jsonValue<Value>(_ value: Value?) -> Any {
        if let value { return value }
        return NSNull()
    }

    private func stableKeyComponent(_ value: String) -> String {
        String(
            Data(value.utf8)
                .base64EncodedString()
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "+", with: "-")
                .prefix(32)
        )
    }

    private static func dateString(
        _ date: Date,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 1970,
            components.month ?? 1,
            components.day ?? 1
        )
    }

    private static let profileSelection = """
    user_id,public_profile_id,role,display_name,city,phone_number,current_coach_id,\
    provider_avatar_url,member_level,onboarding_status,account_purpose,\
    coach_qr_identifier,coach_is_approved,coach_is_public,coach_biography,created_at
    """
    private static let enrollmentSelection =
        "id,program_id,participant_id,coach_id,status,enrolled_at"
    private static let weighInSelection =
        "id,enrollment_id,step_id,kind,weight_kg,recorded_at"
    private static let submissionSelection = """
    id,enrollment_id,step_id,attempt_sequence,status,submitted_at,reviewed_at,\
    reviewer_id,review_note,step_submission_answers(\
    id,question_id,text_value,number_value,selected_option_ids,private_photo_path),\
    quiz_attempt_results(id,correct_count,total_count,percentage,passed,\
    awarded_points,reopened_at,reopened_by,reopen_reason)
    """
    private static let adminProgramSelection = """
    *,program_days(*,program_steps(*,program_questions(*,\
    program_question_options(*),program_answer_keys(*))))
    """
}

private nonisolated struct EmptyBody: Encodable {}

private nonisolated struct PaginationBody: Encodable {
    let resultLimit: Int
    let resultOffset: Int
    enum CodingKeys: String, CodingKey {
        case resultLimit = "result_limit"
        case resultOffset = "result_offset"
    }
}

private nonisolated struct SupabaseProfileRowDTO: Decodable, Sendable {
    let userID: UUID
    let publicProfileID: UUID
    let role: String
    let displayName: String
    let city: String
    let phoneNumber: String?
    let currentCoachID: UUID?
    let providerAvatarURL: String?
    let memberLevel: String?
    let onboardingStatus: String
    let accountPurpose: String
    let coachQRIdentifier: String?
    let coachIsApproved: Bool
    let coachIsPublic: Bool
    let coachBiography: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case publicProfileID = "public_profile_id"
        case role
        case displayName = "display_name"
        case city
        case phoneNumber = "phone_number"
        case currentCoachID = "current_coach_id"
        case providerAvatarURL = "provider_avatar_url"
        case memberLevel = "member_level"
        case onboardingStatus = "onboarding_status"
        case accountPurpose = "account_purpose"
        case coachQRIdentifier = "coach_qr_identifier"
        case coachIsApproved = "coach_is_approved"
        case coachIsPublic = "coach_is_public"
        case coachBiography = "coach_biography"
        case createdAt = "created_at"
    }

    func appUser(email: String) throws -> AppUser {
        guard let role = UserRole(rawValue: role) else {
            throw SupabaseDTOError.invalidField("profile.role")
        }
        return AppUser(
            id: userID,
            email: email,
            displayName: displayName,
            role: role,
            hasCompletedOnboarding: onboardingStatus == "active",
            isCoachApprovalPending: accountPurpose == "coach_applicant"
                && role == .participant,
            createdAt: createdAt
        )
    }

    func participantProfile() throws -> ParticipantProfile {
        let level = try memberLevel.map {
            guard let result = MemberLevel(rawValue: $0) else {
                throw SupabaseDTOError.invalidField("profile.memberLevel")
            }
            return result
        }
        return ParticipantProfile(
            id: userID,
            userID: userID,
            coachID: currentCoachID,
            displayName: displayName,
            city: city,
            phoneNumber: phoneNumber,
            localPhotoReference: providerAvatarURL,
            memberLevel: level
        )
    }

    func coachProfile() -> CoachProfile {
        CoachProfile(
            id: userID,
            userID: userID,
            enrollmentIdentifier: coachQRIdentifier ?? "",
            displayName: displayName,
            biography: coachBiography,
            city: city,
            localPhotoReference: providerAvatarURL,
            isPublic: coachIsPublic,
            isApproved: coachIsApproved
        )
    }
}

private nonisolated struct SupabaseResolvedCoachDTO: Decodable, Sendable {
    let id: UUID
    let displayName: String
    let city: String
    let photoReference: String?
    let isPublic: Bool
    let isApproved: Bool
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case city
        case photoReference = "photo_reference"
        case isPublic = "is_public"
        case isApproved = "is_approved"
    }
    func domain(qrOpaqueValue: String) -> CoachProfile {
        CoachProfile(
            id: id,
            userID: id,
            enrollmentIdentifier: qrOpaqueValue,
            displayName: displayName,
            biography: "",
            city: city,
            localPhotoReference: photoReference,
            isPublic: isPublic,
            isApproved: isApproved
        )
    }
}

private nonisolated struct SupabaseCoachRosterDTO: Decodable, Sendable {
    let profile: SupabaseCoachRosterProfileDTO
}

private nonisolated struct SupabaseCoachRosterProfileDTO: Decodable, Sendable {
    let userID: UUID
    let displayName: String
    let city: String
    let phoneNumber: String?
    let avatarPath: String?
    let memberLevel: String?
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case city
        case phoneNumber = "phone_number"
        case avatarPath = "avatar_path"
        case memberLevel = "member_level"
    }
    func domain() throws -> ParticipantProfile {
        let level = try memberLevel.map {
            guard let result = MemberLevel(rawValue: $0) else {
                throw SupabaseDTOError.invalidField("profile.memberLevel")
            }
            return result
        }
        return ParticipantProfile(
            id: userID,
            userID: userID,
            coachID: nil,
            displayName: displayName,
            city: city,
            phoneNumber: phoneNumber,
            localPhotoReference: avatarPath,
            memberLevel: level
        )
    }
}

private nonisolated struct SupabaseScoreLookupDTO: Decodable, Sendable {
    let enrollmentID: UUID
    enum CodingKeys: String, CodingKey {
        case enrollmentID = "enrollment_id"
    }
}

private nonisolated struct SupabaseAuditEventDTO: Decodable, Sendable {
    let id: UUID
    let kind: String
    let actorID: UUID?
    let subjectID: UUID
    let summary: String
    let createdAt: Date
    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case actorID = "actor_id"
        case subjectID = "subject_id"
        case summary
        case createdAt = "created_at"
    }
    func domain() throws -> AuditEvent {
        guard let kind = AuditEventKind(rawValue: kind), let actorID else {
            throw SupabaseDTOError.invalidField("audit.kind")
        }
        return AuditEvent(
            id: id,
            kind: kind,
            actorUserID: actorID,
            subjectID: subjectID,
            summary: summary,
            createdAt: createdAt
        )
    }
}

private nonisolated struct SupabaseCoachApplicationAggregateDTO:
    Decodable,
    Sendable
{
    let application: SupabaseCoachApplicationRowDTO
    let payment: SupabaseCoachPaymentRowDTO?
    let entitlement: SupabaseCoachEntitlementRowDTO?

    func domain() throws -> CoachApplication {
        guard let level = MemberLevel(
            rawValue: application.memberLevelSnapshot
        ), let status = CoachApplicationStatus(rawValue: application.status)
        else {
            throw SupabaseDTOError.invalidField("coachApplication")
        }
        let paymentPreview: CoachPaymentPreview? = try payment.map { value in
            guard let band = CoachPriceBand(rawValue: value.priceBand),
                  let state = CoachPaymentState(rawValue: value.state) else {
                throw SupabaseDTOError.invalidField("coachPayment")
            }
            return CoachPaymentPreview(
                priceBand: band,
                amountMinorUnits: value.amountMinorUnits,
                durationMonths: value.durationMonths,
                state: state,
                verifiedAt: value.verifiedAt,
                accessStartsAt: entitlement?.startsAt,
                accessEndsAt: entitlement?.endsAt
            )
        }
        let decision = application.decidedBy.flatMap { adminID in
            application.decidedAt.map {
                CoachApplicationDecision(
                    adminUserID: adminID,
                    decidedAt: $0,
                    rejectionReason: application.rejectionReason
                )
            }
        }
        return CoachApplication(
            id: application.id,
            userID: application.applicantUserID,
            participantProfileID: application.participantProfileID,
            displayNameSnapshot: application.displayNameSnapshot,
            phoneNumberSnapshot: application.phoneNumberSnapshot,
            memberLevel: level,
            hasCompletedHOMSTS: application.hasCompletedHOMSTS,
            hasCompletedICT: application.hasCompletedICT,
            termsVersion: application.termsVersion,
            status: status,
            payment: paymentPreview,
            createdAt: application.createdAt,
            submittedAt: application.submittedAt,
            updatedAt: application.updatedAt,
            decision: decision
        )
    }
}

private nonisolated struct SupabaseCoachApplicationRowDTO:
    Decodable,
    Sendable
{
    let id: UUID
    let applicantUserID: UUID
    let participantProfileID: UUID
    let displayNameSnapshot: String
    let phoneNumberSnapshot: String
    let memberLevelSnapshot: String
    let hasCompletedHOMSTS: Bool
    let hasCompletedICT: Bool
    let termsVersion: String
    let status: String
    let submittedAt: Date?
    let decidedAt: Date?
    let decidedBy: UUID?
    let rejectionReason: String?
    let createdAt: Date
    let updatedAt: Date
    enum CodingKeys: String, CodingKey {
        case id
        case applicantUserID = "applicant_user_id"
        case participantProfileID = "participant_profile_id"
        case displayNameSnapshot = "display_name_snapshot"
        case phoneNumberSnapshot = "phone_number_snapshot"
        case memberLevelSnapshot = "member_level_snapshot"
        case hasCompletedHOMSTS = "has_completed_hom_sts"
        case hasCompletedICT = "has_completed_ict"
        case termsVersion = "terms_version"
        case status
        case submittedAt = "submitted_at"
        case decidedAt = "decided_at"
        case decidedBy = "decided_by"
        case rejectionReason = "rejection_reason"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private nonisolated struct SupabaseCoachPaymentRowDTO: Decodable, Sendable {
    let state: String
    let priceBand: String
    let amountMinorUnits: Int64
    let durationMonths: Int
    let verifiedAt: Date?
    enum CodingKeys: String, CodingKey {
        case state
        case priceBand = "price_band"
        case amountMinorUnits = "amount_minor_units"
        case durationMonths = "duration_months"
        case verifiedAt = "verified_at"
    }
}

private nonisolated struct SupabaseCoachEntitlementRowDTO:
    Decodable,
    Sendable
{
    let status: String
    let startsAt: Date
    let endsAt: Date
    enum CodingKeys: String, CodingKey {
        case status
        case startsAt = "starts_at"
        case endsAt = "ends_at"
    }
}
