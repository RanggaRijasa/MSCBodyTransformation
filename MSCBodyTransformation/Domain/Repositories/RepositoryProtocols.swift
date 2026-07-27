import Foundation

nonisolated protocol SessionRepository: Sendable {
    func loadCurrentSession() async throws -> AppSession
    func switchDebugRole(to role: UserRole) async throws -> AppSession
    func setDebugScenario(_ scenario: DebugSessionScenario) async
}

nonisolated protocol ProfileRepository: Sendable {
    func user(id: UUID) async throws -> AppUser
    func participantProfile(userID: UUID) async throws -> ParticipantProfile
    func save(participantProfile: ParticipantProfile) async throws
        -> ParticipantProfile
    func coachProfile(userID: UUID) async throws -> CoachProfile
    func save(coachProfile: CoachProfile) async throws -> CoachProfile
}

nonisolated protocol CoachDirectoryRepository: Sendable {
    func publicCoaches() async throws -> [CoachProfile]
}

nonisolated protocol ProgramRepository: Sendable {
    func programs() async throws -> [Program]
    func program(id: UUID) async throws -> Program
    func activeProgram() async throws -> Program?
    func save(program: Program) async throws -> Program
}

nonisolated protocol EnrollmentRepository: Sendable {
    func allEnrollments() async throws -> [ProgramEnrollment]
    func enrollments(participantID: UUID) async throws -> [ProgramEnrollment]
    func enrollment(
        programID: UUID,
        participantID: UUID
    ) async throws -> ProgramEnrollment?
    func createEnrollment(
        _ enrollment: ProgramEnrollment
    ) async throws -> ProgramEnrollment
}

nonisolated protocol SubmissionRepository: Sendable {
    func pendingReviewCount() async throws -> Int
    func submissions(enrollmentID: UUID) async throws -> [StepSubmission]
    func reviewQueue(coachID: UUID) async throws -> [StepSubmission]
    func completeStep(
        submission: StepSubmission
    ) async throws -> StepSubmission
    func reviewSubmission(
        id: UUID,
        reviewerID: UUID,
        status: SubmissionStatus,
        note: String?,
        reviewedAt: Date
    ) async throws -> StepSubmission
}

nonisolated protocol WeighInRepository: Sendable {
    func weighIns(enrollmentID: UUID) async throws -> [WeighIn]
    func save(weighIn: WeighIn) async throws -> WeighIn
}

nonisolated protocol LeaderboardRepository: Sendable {
    func leaderboard(programID: UUID) async throws -> [LeaderboardEntry]
    func winners(programID: UUID) async throws -> [ProgramWinner]
    func applyScoreAdjustment(
        entryID: UUID,
        points: Int
    ) async throws -> LeaderboardEntry
    func lockTopFive(
        programID: UUID,
        lockedAt: Date
    ) async throws -> [ProgramWinner]
    func resetLockedWinnersForDebug(programID: UUID) async
}

nonisolated protocol CoachParticipantRepository: Sendable {
    func assignedParticipants(
        coachID: UUID
    ) async throws -> [ParticipantProfile]
    func assignedParticipant(
        id participantID: UUID,
        coachID: UUID
    ) async throws -> ParticipantProfile
}

nonisolated protocol InviteRepository: Sendable {
    func invites(coachID: UUID) async throws -> [CoachInvite]
    func activeInvite(code: String, now: Date) async throws -> CoachInvite
    func createInvite(_ invite: CoachInvite) async throws -> CoachInvite
    func revokeInvite(
        id: UUID,
        coachID: UUID
    ) async throws -> CoachInvite
    func redeemInvite(
        code: String,
        participantID: UUID,
        enrollmentID: UUID,
        now: Date
    ) async throws -> ProgramEnrollment
}

nonisolated protocol WalletRepository: Sendable {
    func wallet(coachID: UUID) async throws -> CoachWallet
    func ledger(walletID: UUID) async throws -> [CreditLedgerEntry]
}

nonisolated protocol ManagedContentRepository: Sendable {
    func managedContent() async throws -> [ManagedContent]
    func save(content: ManagedContent) async throws -> ManagedContent
}

nonisolated protocol AdminPeopleRepository: Sendable {
    func usersForAdministration() async throws -> [AppUser]
    func participantProfilesForAdministration() async throws
        -> [ParticipantProfile]
    func coachProfilesForAdministration() async throws -> [CoachProfile]
    func usersAwaitingCoachApproval() async throws -> [AppUser]
    func setCoachApproval(
        userID: UUID,
        isApproved: Bool
    ) async throws -> AppUser
}

nonisolated protocol AdminProgramDraftRepository: Sendable {
    func programDraftsForAdministration() async throws
        -> [AdminProgramDraft]
    func programDraftForAdministration(id: UUID) async throws
        -> AdminProgramDraft
    func save(programDraft: AdminProgramDraft) async throws
        -> AdminProgramDraft
}

nonisolated protocol AuditRepository: Sendable {
    func auditEventsForAdministration() async throws -> [AuditEvent]
    func append(auditEvent: AuditEvent) async throws -> AuditEvent
}

nonisolated protocol ParticipantDemoRepository: Sendable {
    func resetParticipantDemo(participantID: UUID) async
    func resetParticipantProgress(participantID: UUID) async
    func markPreviousDaysComplete(
        participantID: UUID,
        throughDayNumber: Int,
        completedAt: Date
    ) async throws
    func simulateRejectedSubmission(
        participantID: UUID,
        dayNumber: Int,
        completedAt: Date
    ) async throws -> StepSubmission?
}

nonisolated protocol CoachDemoRepository: Sendable {
    func grantSeatCredits(
        coachID: UUID,
        amount: Int,
        grantedAt: Date
    ) async throws -> CoachWallet
    func setSeatCredits(
        coachID: UUID,
        amount: Int,
        updatedAt: Date
    ) async throws -> CoachWallet
}
