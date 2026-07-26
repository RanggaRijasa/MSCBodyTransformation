import Foundation

nonisolated protocol SessionRepository: Sendable {
    func loadCurrentSession() async throws -> AppSession
    func switchDebugRole(to role: UserRole) async throws -> AppSession
    func setDebugScenario(_ scenario: DebugSessionScenario) async
}

nonisolated protocol ProfileRepository: Sendable {
    func user(id: UUID) async throws -> AppUser
    func participantProfile(userID: UUID) async throws -> ParticipantProfile
    func coachProfile(userID: UUID) async throws -> CoachProfile
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
    func applyScoreAdjustment(
        entryID: UUID,
        points: Int
    ) async throws -> LeaderboardEntry
}

nonisolated protocol CoachParticipantRepository: Sendable {
    func assignedParticipants(
        coachID: UUID
    ) async throws -> [ParticipantProfile]
}

nonisolated protocol InviteRepository: Sendable {
    func invites(coachID: UUID) async throws -> [CoachInvite]
    func createInvite(_ invite: CoachInvite) async throws -> CoachInvite
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
    func usersAwaitingCoachApproval() async throws -> [AppUser]
    func setCoachApproval(
        userID: UUID,
        isApproved: Bool
    ) async throws -> AppUser
}
