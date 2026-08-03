import Foundation

actor InMemoryAppRepository:
    SessionRepository,
    ProfileRepository,
    CoachDirectoryRepository,
    ProgramRepository,
    EnrollmentRepository,
    SubmissionRepository,
    WeighInRepository,
    LeaderboardRepository,
    CoachParticipantRepository,
    ManagedContentRepository,
    AdminPeopleRepository,
    AdminProgramDraftRepository,
    AuditRepository,
    ParticipantDemoRepository
{
    private var users: [AppUser]
    private var participantProfiles: [ParticipantProfile]
    private var coachProfiles: [CoachProfile]
    private var programsStorage: [Program]
    private var adminProgramDraftsStorage: [AdminProgramDraft]
    private var enrollmentsStorage: [ProgramEnrollment]
    private var weighInsStorage: [WeighIn]
    private var submissionsStorage: [StepSubmission]
    private var submissionHistoryStorage: [StepSubmission]
    private var quizAttemptsStorage: [QuizAttemptResult]
    private var leaderboardEntries: [LeaderboardEntry]
    private var winners: [ProgramWinner]
    private var managedContentStorage: [ManagedContent]
    private var auditEvents: [AuditEvent]
    private var sessionScenario: DebugSessionScenario

    init(
        seed: MockSeedData,
        sessionScenario: DebugSessionScenario = .role(.participant)
    ) {
        users = seed.users
        participantProfiles = seed.participantProfiles
        coachProfiles = seed.coachProfiles
        programsStorage = seed.programs
        adminProgramDraftsStorage = seed.programs.map {
            AdminProgramDraft(program: $0, updatedAt: $0.startDate)
        }
        enrollmentsStorage = seed.enrollments
        weighInsStorage = seed.weighIns
        submissionsStorage = seed.submissions
        submissionHistoryStorage = []
        quizAttemptsStorage = seed.submissions.compactMap(\.quizResult)
        leaderboardEntries = seed.leaderboardEntries
        winners = seed.winners
        managedContentStorage = seed.managedContent
        auditEvents = seed.auditEvents
        self.sessionScenario = sessionScenario
    }

    func loadCurrentSession() async throws -> AppSession {
        switch sessionScenario {
        case .role(let role):
            return AppSession(
                user: try userForSession(role: role),
                state: .active
            )
        case .loggedOut:
            return AppSession(user: nil, state: .loggedOut)
        case .onboardingIncomplete(let role):
            var user = try userForSession(role: role)
            user.hasCompletedOnboarding = false
            return AppSession(user: user, state: .active)
        case .expired:
            throw DomainError.sessionExpired
        }
    }

    func switchDebugRole(to role: UserRole) async throws -> AppSession {
        sessionScenario = .role(role)
        return AppSession(
            user: try userForSession(role: role),
            state: .active
        )
    }

    func setDebugScenario(_ scenario: DebugSessionScenario) async {
        sessionScenario = scenario
    }

    func user(id: UUID) async throws -> AppUser {
        guard let user = users.first(where: { $0.id == id }) else {
            throw DomainError.notFound(resource: "user")
        }
        return user
    }

    func participantProfile(userID: UUID) async throws -> ParticipantProfile {
        guard let profile = participantProfiles.first(
            where: { $0.userID == userID }
        ) else {
            throw DomainError.notFound(resource: "participant_profile")
        }
        return profile
    }

    func save(
        participantProfile: ParticipantProfile
    ) async throws -> ParticipantProfile {
        if let index = participantProfiles.firstIndex(where: {
            $0.id == participantProfile.id
        }) {
            participantProfiles[index] = participantProfile
        } else {
            participantProfiles.append(participantProfile)
        }
        return participantProfile
    }

    func coachProfile(userID: UUID) async throws -> CoachProfile {
        guard let profile = coachProfiles.first(
            where: { $0.userID == userID }
        ) else {
            throw DomainError.notFound(resource: "coach_profile")
        }
        return profile
    }

    func save(coachProfile: CoachProfile) async throws -> CoachProfile {
        guard let index = coachProfiles.firstIndex(where: {
            $0.id == coachProfile.id
                && $0.userID == coachProfile.userID
        }) else {
            throw DomainError.notFound(resource: "coach_profile")
        }
        coachProfiles[index] = coachProfile
        return coachProfile
    }

    func publicCoaches() async throws -> [CoachProfile] {
        coachProfiles
            .filter { $0.isPublic && $0.isApproved }
            .sorted { $0.displayName < $1.displayName }
    }

    func programs() async throws -> [Program] {
        programsStorage.sorted { $0.startDate < $1.startDate }
    }

    func program(id: UUID) async throws -> Program {
        guard let program = programsStorage.first(where: { $0.id == id }) else {
            throw DomainError.notFound(resource: "program")
        }
        return program
    }

    func activeProgram() async throws -> Program? {
        programsStorage.first { $0.status == .active }
    }

    func save(program: Program) async throws -> Program {
        if let index = programsStorage.firstIndex(where: {
            $0.id == program.id
        }) {
            programsStorage[index] = program
        } else {
            programsStorage.append(program)
        }
        return program
    }

    func enrollments(
        participantID: UUID
    ) async throws -> [ProgramEnrollment] {
        enrollmentsStorage.filter { $0.participantID == participantID }
    }

    func allEnrollments() async throws -> [ProgramEnrollment] {
        enrollmentsStorage.sorted { $0.enrolledAt > $1.enrolledAt }
    }

    func enrollment(
        programID: UUID,
        participantID: UUID
    ) async throws -> ProgramEnrollment? {
        enrollmentsStorage.first {
            $0.programID == programID
                && $0.participantID == participantID
        }
    }

    func createEnrollment(
        _ enrollment: ProgramEnrollment
    ) async throws -> ProgramEnrollment {
        guard let scannedCoachID = enrollment.coachID,
              coachProfiles.contains(where: {
                  $0.id == scannedCoachID && $0.isApproved
              }) else {
            throw DomainError.permissionDenied
        }
        guard let participantIndex = participantProfiles.firstIndex(where: {
            $0.id == enrollment.participantID
        }) else {
            throw DomainError.notFound(resource: "participant_profile")
        }
        if let currentCoachID = participantProfiles[participantIndex].coachID,
           currentCoachID != scannedCoachID {
            throw DomainError.conflict(
                reason:
                    "QR ini bukan milik Coach pendampingmu. "
                    + "Pindai QR Coach yang sama untuk melanjutkan."
            )
        }
        if let existing = enrollmentsStorage.first(where: {
            $0.programID == enrollment.programID
                && $0.participantID == enrollment.participantID
        }) {
            return existing
        }
        guard let program = programsStorage.first(where: {
            $0.id == enrollment.programID
        }) else {
            throw DomainError.notFound(resource: "program")
        }
        if let participantLimit = program.participantLimit {
            let enrollmentCount = enrollmentsStorage.filter {
                $0.programID == program.id
                    && $0.status != .cancelled
                    && $0.status != .refunded
            }.count
            guard enrollmentCount < participantLimit else {
                throw DomainError.conflict(
                    reason: "Kapasitas program sudah penuh."
                )
            }
        }
        if participantProfiles[participantIndex].coachID == nil {
            participantProfiles[participantIndex].coachID = scannedCoachID
        }
        enrollmentsStorage.append(enrollment)
        if enrollment.status == .active,
           !leaderboardEntries.contains(where: {
               $0.programID == enrollment.programID
                   && $0.participantID == enrollment.participantID
           }) {
            leaderboardEntries.append(
                LeaderboardEntry(
                    id: derivedLeaderboardIdentifier(
                        enrollmentID: enrollment.id
                    ),
                    programID: enrollment.programID,
                    participantID: enrollment.participantID,
                    participantDisplayName:
                        participantProfiles[participantIndex].displayName,
                    rank: 0,
                    progressPercentage: 0,
                    score: ScoreBreakdown(
                        approvedStepPoints: 0,
                        weightPoints: 0,
                        adjustmentPoints: 0
                    ),
                    isCurrentUser: true
                )
            )
            recalculateRanks(programID: enrollment.programID)
        }
        return enrollment
    }

    func reassignCoach(
        participantID: UUID,
        coachID: UUID
    ) async throws -> [ProgramEnrollment] {
        for index in enrollmentsStorage.indices
        where enrollmentsStorage[index].participantID == participantID
            && (
                enrollmentsStorage[index].status == .initiated
                    || enrollmentsStorage[index].status
                        == .waitingForPayment
                    || enrollmentsStorage[index].status == .active
            ) {
            enrollmentsStorage[index].coachID = coachID
        }
        return enrollmentsStorage.filter {
            $0.participantID == participantID
                && (
                    $0.status == .initiated
                        || $0.status == .waitingForPayment
                        || $0.status == .active
                )
        }
    }

    func submissions(
        enrollmentID: UUID
    ) async throws -> [StepSubmission] {
        submissionsStorage
            .filter { $0.enrollmentID == enrollmentID }
            .sorted { $0.submittedAt < $1.submittedAt }
    }

    func pendingReviewCount() async throws -> Int {
        submissionsStorage.filter { $0.status == .pending }.count
    }

    func submissionHistory(
        enrollmentID: UUID,
        stepID: UUID
    ) async throws -> [StepSubmission] {
        (
            submissionHistoryStorage
                + submissionsStorage.filter {
                    $0.enrollmentID == enrollmentID && $0.stepID == stepID
                }
        )
        .filter {
            $0.enrollmentID == enrollmentID && $0.stepID == stepID
        }
        .sorted { $0.submittedAt < $1.submittedAt }
    }

    func quizAttempts(
        enrollmentID: UUID,
        stepID: UUID
    ) async throws -> [QuizAttemptResult] {
        quizAttemptsStorage
            .filter {
                $0.enrollmentID == enrollmentID && $0.stepID == stepID
            }
            .sorted { $0.sequence < $1.sequence }
    }

    func reviewQueue(coachID: UUID) async throws -> [StepSubmission] {
        let participantIDs = Set(
            participantProfiles
                .filter { $0.coachID == coachID }
                .map(\.id)
        )
        let enrollmentIDs = Set(
            enrollmentsStorage
                .filter { participantIDs.contains($0.participantID) }
                .map(\.id)
        )
        return submissionsStorage
            .filter {
                enrollmentIDs.contains($0.enrollmentID)
                    && $0.status == .pending
            }
            .sorted { $0.submittedAt < $1.submittedAt }
    }

    func completeStep(
        submission: StepSubmission
    ) async throws -> StepSubmission {
        if let index = submissionsStorage.firstIndex(where: {
            $0.enrollmentID == submission.enrollmentID
                && $0.stepID == submission.stepID
        }) {
            if submissionsStorage[index].id == submission.id {
                return submissionsStorage[index]
            }
            if let previousResult = submissionsStorage[index].quizResult {
                guard previousResult.reopenedAt != nil else {
                    throw DomainError.conflict(
                        reason: "Kuis hanya dapat dikerjakan satu kali."
                    )
                }
                var replacement = submission
                replacement.attemptSequence = previousResult.sequence + 1
                if let result = submission.quizResult {
                    replacement.quizResult = QuizAttemptResult(
                        id: result.id,
                        enrollmentID: result.enrollmentID,
                        stepID: result.stepID,
                        sequence: previousResult.sequence + 1,
                        correctAnswerCount: result.correctAnswerCount,
                        totalQuestionCount: result.totalQuestionCount,
                        percentage: result.percentage,
                        isPassed: result.isPassed,
                        awardedPoints: result.awardedPoints,
                        submittedAt: result.submittedAt
                    )
                }
                submissionsStorage[index] = replacement
                if let result = replacement.quizResult {
                    quizAttemptsStorage.append(result)
                }
                refreshLeaderboard(enrollmentID: submission.enrollmentID)
                return replacement
            }
            guard submissionsStorage[index].status == .rejected else {
                return submissionsStorage[index]
            }
            submissionHistoryStorage.append(submissionsStorage[index])
            submissionsStorage[index] = submission
            refreshLeaderboard(enrollmentID: submission.enrollmentID)
            return submission
        }
        submissionsStorage.append(submission)
        if let result = submission.quizResult {
            quizAttemptsStorage.append(result)
        }
        refreshLeaderboard(enrollmentID: submission.enrollmentID)
        return submission
    }

    func reviewSubmission(
        id: UUID,
        reviewerID: UUID,
        status: SubmissionStatus,
        note: String?,
        reviewedAt: Date
    ) async throws -> StepSubmission {
        guard let index = submissionsStorage.firstIndex(
            where: { $0.id == id }
        ) else {
            throw DomainError.notFound(resource: "submission")
        }
        guard submissionsStorage[index].status == .pending else {
            throw DomainError.conflict(
                reason: "Submission sudah diperiksa."
            )
        }
        let reviewedSubmission = submissionsStorage[index]
        submissionsStorage[index].status = status
        submissionsStorage[index].reviewerID = reviewerID
        submissionsStorage[index].reviewedAt = reviewedAt
        submissionsStorage[index].reviewNote = note
        applyReviewScoreChange(
            submission: reviewedSubmission,
            decision: status
        )
        return submissionsStorage[index]
    }

    func saveCoachRating(
        submissionID: UUID,
        reviewerID: UUID,
        rating: Int
    ) async throws -> StepSubmission {
        guard let index = submissionsStorage.firstIndex(
            where: { $0.id == submissionID }
        ) else {
            throw DomainError.notFound(resource: "submission")
        }
        guard (1...5).contains(rating) else {
            throw DomainError.validation(
                field: "coachRating",
                reason: "Penilaian harus antara 1 sampai 5 bintang."
            )
        }
        submissionsStorage[index].coachRating = rating
        if submissionsStorage[index].reviewerID == nil {
            submissionsStorage[index].reviewerID = reviewerID
        }
        return submissionsStorage[index]
    }

    func reopenQuizAttempt(
        enrollmentID: UUID,
        stepID: UUID,
        adminID: UUID,
        reason: String,
        reopenedAt: Date
    ) async throws -> QuizAttemptResult {
        let trimmedReason = reason.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedReason.isEmpty else {
            throw DomainError.validation(
                field: "reason",
                reason: "Alasan membuka ulang percobaan wajib diisi."
            )
        }
        guard let submissionIndex = submissionsStorage.firstIndex(where: {
            $0.enrollmentID == enrollmentID
                && $0.stepID == stepID
                && $0.quizResult != nil
        }), var result = submissionsStorage[submissionIndex].quizResult else {
            throw DomainError.notFound(resource: "quiz_attempt")
        }
        guard result.reopenedAt == nil else {
            return result
        }
        result.reopenedAt = reopenedAt
        result.reopenedByAdminID = adminID
        result.reopenReason = trimmedReason
        submissionsStorage[submissionIndex].quizResult = result
        if let historyIndex = quizAttemptsStorage.firstIndex(where: {
            $0.id == result.id
        }) {
            quizAttemptsStorage[historyIndex] = result
        } else {
            quizAttemptsStorage.append(result)
        }
        refreshLeaderboard(enrollmentID: enrollmentID)
        return result
    }

    func weighIns(enrollmentID: UUID) async throws -> [WeighIn] {
        weighInsStorage
            .filter { $0.enrollmentID == enrollmentID }
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    func save(weighIn: WeighIn) async throws -> WeighIn {
        if let existing = weighInsStorage.first(where: {
            isSameWeighInSlot($0, weighIn)
        }) {
            return existing
        }
        weighInsStorage.append(weighIn)
        refreshLeaderboard(enrollmentID: weighIn.enrollmentID)
        return weighIn
    }

    func correctWeighIn(
        enrollmentID: UUID,
        type: WeighInType,
        stepID: UUID?,
        weightKilograms: Decimal,
        correctedAt: Date
    ) async throws -> WeighIn {
        try WeighInValidator().validate(
            weightKilograms: weightKilograms
        )
        guard let index = weighInsStorage.firstIndex(where: {
            $0.enrollmentID == enrollmentID
                && $0.type == type
                && (type != .daily || $0.stepID == stepID)
        }) else {
            throw DomainError.notFound(resource: "weigh_in")
        }
        let corrected = WeighIn(
            id: weighInsStorage[index].id,
            enrollmentID: enrollmentID,
            stepID: weighInsStorage[index].stepID,
            type: type,
            weightKilograms: weightKilograms,
            recordedAt: correctedAt
        )
        weighInsStorage[index] = corrected
        refreshLeaderboard(enrollmentID: enrollmentID)
        return corrected
    }

    private func isSameWeighInSlot(
        _ left: WeighIn,
        _ right: WeighIn
    ) -> Bool {
        guard left.enrollmentID == right.enrollmentID,
              left.type == right.type else {
            return false
        }
        return left.type != .daily || left.stepID == right.stepID
    }

    func leaderboard(
        programID: UUID
    ) async throws -> [LeaderboardEntry] {
        recalculateRanks(programID: programID)
        return leaderboardEntries
            .filter { $0.programID == programID }
            .sorted { $0.rank < $1.rank }
    }

    func winners(programID: UUID) async throws -> [ProgramWinner] {
        winners
            .filter { $0.programID == programID }
            .sorted { $0.rank < $1.rank }
    }

    func applyScoreAdjustment(
        entryID: UUID,
        points: Int
    ) async throws -> LeaderboardEntry {
        guard let index = leaderboardEntries.firstIndex(
            where: { $0.id == entryID }
        ) else {
            throw DomainError.notFound(resource: "leaderboard_entry")
        }
        leaderboardEntries[index].score.adjustmentPoints += points
        recalculateRanks(
            programID: leaderboardEntries[index].programID
        )
        guard let updated = leaderboardEntries.first(
            where: { $0.id == entryID }
        ) else {
            throw DomainError.unknown
        }
        return updated
    }

    func lockTopFive(
        programID: UUID,
        lockedAt: Date
    ) async throws -> [ProgramWinner] {
        let existing = winners
            .filter { $0.programID == programID }
            .sorted { $0.rank < $1.rank }
        guard existing.isEmpty else {
            return existing
        }

        recalculateRanks(programID: programID)
        let rankedEntries = leaderboardEntries
            .filter { $0.programID == programID }
            .sorted { $0.rank < $1.rank }
        let locked = WinnerSelector().select(
            from: rankedEntries,
            programID: programID,
            lockedAt: lockedAt
        )
        winners.append(contentsOf: locked)
        return locked
    }

    func resetLockedWinnersForDebug(programID: UUID) async {
        winners.removeAll { $0.programID == programID }
    }

    func assignedParticipants(
        coachID: UUID
    ) async throws -> [ParticipantProfile] {
        participantProfiles
            .filter { $0.coachID == coachID }
            .sorted { $0.displayName < $1.displayName }
    }

    func assignedParticipant(
        id participantID: UUID,
        coachID: UUID
    ) async throws -> ParticipantProfile {
        guard let participant = participantProfiles.first(where: {
            $0.id == participantID && $0.coachID == coachID
        }) else {
            throw DomainError.permissionDenied
        }
        return participant
    }

    func managedContent() async throws -> [ManagedContent] {
        managedContentStorage.sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(content: ManagedContent) async throws -> ManagedContent {
        if let index = managedContentStorage.firstIndex(
            where: { $0.id == content.id }
        ) {
            managedContentStorage[index] = content
        } else {
            managedContentStorage.append(content)
        }
        return content
    }

    func usersAwaitingCoachApproval() async throws -> [AppUser] {
        users
            .filter { $0.isCoachApprovalPending }
            .sorted { $0.displayName < $1.displayName }
    }

    func usersForAdministration() async throws -> [AppUser] {
        users.sorted { $0.displayName < $1.displayName }
    }

    func participantProfilesForAdministration() async throws
        -> [ParticipantProfile]
    {
        participantProfiles.sorted { $0.displayName < $1.displayName }
    }

    func coachProfilesForAdministration() async throws -> [CoachProfile] {
        coachProfiles.sorted { $0.displayName < $1.displayName }
    }

    func setCoachApproval(
        userID: UUID,
        isApproved: Bool
    ) async throws -> AppUser {
        guard let userIndex = users.firstIndex(
            where: { $0.id == userID }
        ) else {
            throw DomainError.notFound(resource: "user")
        }
        users[userIndex].isCoachApprovalPending = !isApproved

        if let coachIndex = coachProfiles.firstIndex(
            where: { $0.userID == userID }
        ) {
            coachProfiles[coachIndex].isApproved = isApproved
        }
        return users[userIndex]
    }

    func transferActiveCoach(
        participantID: UUID,
        coachID: UUID
    ) async throws -> ParticipantProfile {
        guard let coach = coachProfiles.first(where: {
            $0.id == coachID && $0.isApproved
        }) else {
            throw DomainError.validation(
                field: "coach",
                reason: "Pilih Coach yang telah disetujui."
            )
        }
        guard let participantIndex = participantProfiles.firstIndex(
            where: { $0.id == participantID }
        ) else {
            throw DomainError.notFound(resource: "participant")
        }
        participantProfiles[participantIndex].coachID = coach.id
        for index in enrollmentsStorage.indices
        where enrollmentsStorage[index].participantID == participantID
            && (
                enrollmentsStorage[index].status == .initiated
                    || enrollmentsStorage[index].status
                        == .waitingForPayment
                    || enrollmentsStorage[index].status == .active
            ) {
            enrollmentsStorage[index].coachID = coach.id
        }
        return participantProfiles[participantIndex]
    }

    func programDraftsForAdministration() async throws
        -> [AdminProgramDraft]
    {
        adminProgramDraftsStorage.sorted { $0.updatedAt > $1.updatedAt }
    }

    func programDraftForAdministration(id: UUID) async throws
        -> AdminProgramDraft
    {
        guard let draft = adminProgramDraftsStorage.first(where: {
            $0.id == id
        }) else {
            throw DomainError.notFound(resource: "program_draft")
        }
        return draft
    }

    func save(programDraft: AdminProgramDraft) async throws
        -> AdminProgramDraft
    {
        if let index = adminProgramDraftsStorage.firstIndex(where: {
            $0.id == programDraft.id
        }) {
            adminProgramDraftsStorage[index] = programDraft
        } else {
            adminProgramDraftsStorage.append(programDraft)
        }
        _ = try await save(program: programDraft.program())
        return programDraft
    }

    func auditEventsForAdministration() async throws -> [AuditEvent] {
        auditEvents.sorted { $0.createdAt > $1.createdAt }
    }

    func append(auditEvent: AuditEvent) async throws -> AuditEvent {
        auditEvents.append(auditEvent)
        return auditEvent
    }

    func resetParticipantDemo(participantID: UUID) async {
        let enrollmentIDs = Set(
            enrollmentsStorage
                .filter { $0.participantID == participantID }
                .map(\.id)
        )
        enrollmentsStorage.removeAll {
            enrollmentIDs.contains($0.id)
        }
        submissionsStorage.removeAll {
            enrollmentIDs.contains($0.enrollmentID)
        }
        weighInsStorage.removeAll {
            enrollmentIDs.contains($0.enrollmentID)
        }
        for index in leaderboardEntries.indices
        where leaderboardEntries[index].participantID == participantID {
            leaderboardEntries[index].progressPercentage = 0
            leaderboardEntries[index].score.approvedStepPoints = 0
            leaderboardEntries[index].score.weightPoints = 0
            recalculateRanks(
                programID: leaderboardEntries[index].programID
            )
        }
    }

    func resetParticipantProgress(participantID: UUID) async {
        let enrollmentIDs = Set(
            enrollmentsStorage
                .filter {
                    $0.participantID == participantID
                        && $0.status == .active
                }
                .map(\.id)
        )
        submissionsStorage.removeAll {
            enrollmentIDs.contains($0.enrollmentID)
        }
        weighInsStorage.removeAll {
            enrollmentIDs.contains($0.enrollmentID) && $0.type == .final
        }

        for index in leaderboardEntries.indices
        where leaderboardEntries[index].participantID == participantID {
            leaderboardEntries[index].progressPercentage = 0
            leaderboardEntries[index].score.approvedStepPoints = 0
            leaderboardEntries[index].score.weightPoints = 0
            recalculateRanks(
                programID: leaderboardEntries[index].programID
            )
        }
    }

    func markPreviousDaysComplete(
        participantID: UUID,
        throughDayNumber: Int,
        completedAt: Date
    ) async throws {
        guard let enrollment = enrollmentsStorage.first(where: {
            $0.participantID == participantID && $0.status == .active
        }) else {
            throw DomainError.notFound(resource: "enrollment")
        }
        guard let program = programsStorage.first(where: {
            $0.id == enrollment.programID
        }) else {
            throw DomainError.notFound(resource: "program")
        }

        for day in program.days where day.dayNumber < throughDayNumber {
            for step in day.steps where !submissionsStorage.contains(where: {
                $0.enrollmentID == enrollment.id && $0.stepID == step.id
            }) {
                submissionsStorage.append(
                    StepSubmission(
                        id: step.id,
                        enrollmentID: enrollment.id,
                        stepID: step.id,
                        status: .approved,
                        submittedAt: completedAt,
                        reviewedAt: completedAt,
                        reviewerID: enrollment.coachID,
                        reviewNote: nil,
                        answers: debugAnswers(for: step)
                    )
                )
            }
        }
        refreshLeaderboard(enrollmentID: enrollment.id)
    }

    func simulateRejectedSubmission(
        participantID: UUID,
        dayNumber: Int,
        completedAt: Date
    ) async throws -> StepSubmission? {
        guard let enrollment = enrollmentsStorage.first(where: {
            $0.participantID == participantID && $0.status == .active
        }), let program = programsStorage.first(where: {
            $0.id == enrollment.programID
        }) else {
            throw DomainError.notFound(resource: "enrollment")
        }
        guard let step = program.days
            .first(where: { $0.dayNumber == dayNumber })?
            .steps
            .sorted(by: { $0.order < $1.order })
            .first(where: { candidate in
                !submissionsStorage.contains(where: {
                    $0.enrollmentID == enrollment.id
                        && $0.stepID == candidate.id
                })
            }) else {
            return nil
        }

        let submission = StepSubmission(
            id: step.id,
            enrollmentID: enrollment.id,
            stepID: step.id,
            status: .rejected,
            submittedAt: completedAt,
            reviewedAt: completedAt,
            reviewerID: enrollment.coachID,
            reviewNote: "Jawaban demo perlu diperbaiki sebelum dikirim ulang.",
            answers: debugAnswers(for: step)
        )
        submissionsStorage.append(submission)
        refreshLeaderboard(enrollmentID: enrollment.id)
        return submission
    }

    private func userForSession(role: UserRole) throws -> AppUser {
        guard let user = users.first(where: {
            $0.role == role && !$0.isCoachApprovalPending
        }) else {
            throw DomainError.notFound(resource: "session_user")
        }
        return user
    }

    private func debugAnswers(
        for step: ProgramStep
    ) -> [StepSubmissionAnswer] {
        (step.content?.questions ?? []).compactMap { question in
            guard question.kind.isInteractive else { return nil }
            let textValue: String?
            switch question.kind {
            case .shortAnswer, .longAnswer:
                textValue = "Diselesaikan melalui alat Debug."
            default:
                textValue = nil
            }
            return StepSubmissionAnswer(
                id: question.id,
                questionID: question.id,
                textValue: textValue,
                numberValue: question.kind == .number ? 1 : nil,
                selectedOptionIDs: question.kind.acceptsOptions
                    ? Array(question.options.prefix(1).map(\.id))
                    : [],
                localPhotoReference: question.kind == .photoUpload
                    ? "local-demo://debug/photo-answer"
                    : nil
            )
        }
    }

    private func refreshLeaderboard(enrollmentID: UUID) {
        guard let enrollment = enrollmentsStorage.first(where: {
            $0.id == enrollmentID
        }), let program = programsStorage.first(where: {
            $0.id == enrollment.programID
        }), let entryIndex = leaderboardEntries.firstIndex(where: {
            $0.programID == enrollment.programID
                && $0.participantID == enrollment.participantID
        }) else {
            return
        }

        let enrollmentSubmissions = submissionsStorage.filter {
            $0.enrollmentID == enrollmentID
        }
        let enrollmentWeighIns = weighInsStorage.filter {
            $0.enrollmentID == enrollmentID
        }
        let adjustment = leaderboardEntries[entryIndex]
            .score.adjustmentPoints
        guard let result = try? EnrollmentScoreCalculator().calculate(
            program: program,
            submissions: enrollmentSubmissions,
            weighIns: enrollmentWeighIns,
            adjustmentPoints: adjustment
        ) else {
            return
        }
        leaderboardEntries[entryIndex].score = result.score
        leaderboardEntries[entryIndex].progressPercentage =
            result.progress.overallPercentage
        recalculateRanks(programID: program.id)
    }

    private func applyReviewScoreChange(
        submission: StepSubmission,
        decision: SubmissionStatus
    ) {
        refreshLeaderboard(enrollmentID: submission.enrollmentID)
    }

    private func recalculateRanks(programID: UUID) {
        let candidates = leaderboardEntries
            .filter { $0.programID == programID }
            .map {
                LeaderboardRankingCandidate(
                    entry: $0,
                    completionTimestamp: completionTimestamp(for: $0),
                    enrollmentID: enrollmentID(for: $0)
                )
            }
        let ranked = LeaderboardSorter().sort(candidates)
        for entry in ranked {
            if let index = leaderboardEntries.firstIndex(where: {
                $0.id == entry.id
            }) {
                leaderboardEntries[index].rank = entry.rank
            }
        }
    }

    private func completionTimestamp(
        for entry: LeaderboardEntry
    ) -> Date? {
        guard let enrollment = enrollmentsStorage.first(where: {
            $0.programID == entry.programID
                && $0.participantID == entry.participantID
        }) else {
            return nil
        }
        let submissionDates = submissionsStorage
            .filter {
                $0.enrollmentID == enrollment.id
                    && $0.status != .rejected
            }
            .map { $0.reviewedAt ?? $0.submittedAt }
        let finalWeightDate = weighInsStorage.first {
            $0.enrollmentID == enrollment.id && $0.type == .final
        }?.recordedAt
        return (submissionDates + [finalWeightDate].compactMap { $0 }).max()
    }

    private func enrollmentID(
        for entry: LeaderboardEntry
    ) -> UUID? {
        enrollmentsStorage.first {
            $0.programID == entry.programID
                && $0.participantID == entry.participantID
        }?.id
    }

    private func derivedLeaderboardIdentifier(
        enrollmentID: UUID
    ) -> UUID {
        var bytes = enrollmentID.uuid
        bytes.15 ^= 0xA5
        let candidate = UUID(uuid: bytes)
        guard !leaderboardEntries.contains(where: { $0.id == candidate }) else {
            bytes.14 ^= 0x5A
            return UUID(uuid: bytes)
        }
        return candidate
    }
}
