import Foundation

nonisolated protocol SessionRepository: Sendable {
    func loadCurrentSession() async throws -> AppSession
    func register(
        request: AuthenticationRegistrationRequest
    ) async throws -> AppSession
    func signIn(credential: EmailCredential) async throws -> AppSession
    func signOut() async throws
    func restoreSession() async throws -> AppSession
    func refreshSession() async throws -> AppSession
    func requestPasswordReset(email: String) async throws
    func resendEmailVerification(email: String) async throws
    func updatePassword(_ password: String) async throws
    func handleAuthenticationCallback(_ url: URL) async throws -> AppSession
    func acceptExternalSession(
        _ material: AuthSessionMaterial
    ) async throws -> AppSession
    func reauthenticate(credential: EmailCredential) async throws
    func reauthenticate(
        externalSession material: AuthSessionMaterial
    ) async throws
    func clearLocalSessionAfterAccountDeletion() async
    func authenticationStateUpdates() async -> AsyncStream<AuthenticationStateUpdate>
    func validAccessToken() async throws -> String
    func switchDebugRole(to role: UserRole) async throws -> AppSession
    func setDebugScenario(_ scenario: DebugSessionScenario) async
}

nonisolated protocol ExternalAuthenticationProviding: Sendable {
    func authenticate(
        provider: AuthenticationProvider
    ) async throws -> AuthSessionMaterial
}

nonisolated protocol AuthenticationRepository: Sendable {
    func signIn(
        provider: AuthenticationProvider,
        email: String?,
        password: String?
    ) async throws -> AppSession
    func register(
        provider: AuthenticationProvider,
        email: String?,
        password: String?
    ) async throws -> AppSession
    func finalizeRegistration(
        _ completion: RegistrationCompletion
    ) async throws -> RegistrationResult
    func requestPasswordReset(email: String) async throws
    func savePendingEnrollmentIntent(programID: UUID) async throws
    func pendingEnrollmentIntent() async throws -> PendingEnrollmentIntent?
    func clearPendingEnrollmentIntent() async throws
    func cancelProvisionalRegistration() async throws
    func reauthenticateForAccountDeletion(
        _ reauthentication: AccountReauthentication
    ) async throws
    func deleteAccountAfterReauthentication() async throws
    func completeParticipantOnboarding(
        userID: UUID,
        displayName: String,
        phoneNumber: String,
        memberLevel: MemberLevel
    ) async throws -> AppSession
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
    func reassignCoach(
        participantID: UUID,
        coachID: UUID
    ) async throws -> [ProgramEnrollment]
}

nonisolated protocol SubmissionRepository: Sendable {
    func pendingReviewCount() async throws -> Int
    func submissions(enrollmentID: UUID) async throws -> [StepSubmission]
    func submissionHistory(
        enrollmentID: UUID,
        stepID: UUID
    ) async throws -> [StepSubmission]
    func quizAttempts(
        enrollmentID: UUID,
        stepID: UUID
    ) async throws -> [QuizAttemptResult]
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
    func saveCoachRating(
        submissionID: UUID,
        reviewerID: UUID,
        rating: Int
    ) async throws -> StepSubmission
    func reopenQuizAttempt(
        enrollmentID: UUID,
        stepID: UUID,
        adminID: UUID,
        reason: String,
        reopenedAt: Date
    ) async throws -> QuizAttemptResult
}

nonisolated protocol WeighInRepository: Sendable {
    func weighIns(enrollmentID: UUID) async throws -> [WeighIn]
    func save(weighIn: WeighIn) async throws -> WeighIn
    func correctWeighIn(
        enrollmentID: UUID,
        type: WeighInType,
        stepID: UUID?,
        weightKilograms: Decimal,
        correctedAt: Date
    ) async throws -> WeighIn
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
    func transferActiveCoach(
        participantID: UUID,
        coachID: UUID
    ) async throws -> ParticipantProfile
}

nonisolated protocol CoachApplicationRepository: Sendable {
    func coachApplication(userID: UUID) async throws -> CoachApplication?
    func coachApplicationsForAdministration() async throws
        -> [CoachApplication]
    func saveCoachApplication(
        _ application: CoachApplication
    ) async throws -> CoachApplication
    func recordCoachPayment(
        applicationID: UUID,
        result: FakeCoachPurchaseResult
    ) async throws -> CoachApplication
    func submitCoachApplication(
        applicationID: UUID
    ) async throws -> CoachApplication
    func approveCoachApplication(
        applicationID: UUID,
        adminUserID: UUID,
        decidedAt: Date
    ) async throws -> CoachApplication
    func rejectCoachApplication(
        applicationID: UUID,
        adminUserID: UUID,
        reason: String,
        decidedAt: Date
    ) async throws -> CoachApplication
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
