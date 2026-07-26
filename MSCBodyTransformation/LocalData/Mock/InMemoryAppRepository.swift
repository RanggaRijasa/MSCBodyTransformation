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
    InviteRepository,
    WalletRepository,
    ManagedContentRepository,
    AdminPeopleRepository
{
    private var users: [AppUser]
    private var participantProfiles: [ParticipantProfile]
    private var coachProfiles: [CoachProfile]
    private var programsStorage: [Program]
    private var enrollmentsStorage: [ProgramEnrollment]
    private var weighInsStorage: [WeighIn]
    private var submissionsStorage: [StepSubmission]
    private var leaderboardEntries: [LeaderboardEntry]
    private var winners: [ProgramWinner]
    private var wallets: [CoachWallet]
    private var creditLedgerEntries: [CreditLedgerEntry]
    private var invitesStorage: [CoachInvite]
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
        enrollmentsStorage = seed.enrollments
        weighInsStorage = seed.weighIns
        submissionsStorage = seed.submissions
        leaderboardEntries = seed.leaderboardEntries
        winners = seed.winners
        wallets = seed.wallets
        creditLedgerEntries = seed.creditLedgerEntries
        invitesStorage = seed.invites
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

    func coachProfile(userID: UUID) async throws -> CoachProfile {
        guard let profile = coachProfiles.first(
            where: { $0.userID == userID }
        ) else {
            throw DomainError.notFound(resource: "coach_profile")
        }
        return profile
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
        if let existing = enrollmentsStorage.first(where: {
            $0.programID == enrollment.programID
                && $0.participantID == enrollment.participantID
        }) {
            return existing
        }
        enrollmentsStorage.append(enrollment)
        return enrollment
    }

    func submissions(
        enrollmentID: UUID
    ) async throws -> [StepSubmission] {
        submissionsStorage
            .filter { $0.enrollmentID == enrollmentID }
            .sorted { $0.submittedAt < $1.submittedAt }
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
        if let existing = submissionsStorage.first(where: {
            $0.enrollmentID == submission.enrollmentID
                && $0.stepID == submission.stepID
        }) {
            return existing
        }
        submissionsStorage.append(submission)
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
        submissionsStorage[index].status = status
        submissionsStorage[index].reviewerID = reviewerID
        submissionsStorage[index].reviewedAt = reviewedAt
        submissionsStorage[index].reviewNote = note
        return submissionsStorage[index]
    }

    func weighIns(enrollmentID: UUID) async throws -> [WeighIn] {
        weighInsStorage
            .filter { $0.enrollmentID == enrollmentID }
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    func save(weighIn: WeighIn) async throws -> WeighIn {
        if let existing = weighInsStorage.first(where: {
            $0.enrollmentID == weighIn.enrollmentID
                && $0.type == weighIn.type
        }) {
            return existing
        }
        weighInsStorage.append(weighIn)
        return weighIn
    }

    func leaderboard(
        programID: UUID
    ) async throws -> [LeaderboardEntry] {
        leaderboardEntries
            .filter { $0.programID == programID }
            .sorted {
                if $0.rank == $1.rank {
                    return $0.participantDisplayName
                        < $1.participantDisplayName
                }
                return $0.rank < $1.rank
            }
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

    func assignedParticipants(
        coachID: UUID
    ) async throws -> [ParticipantProfile] {
        participantProfiles
            .filter { $0.coachID == coachID }
            .sorted { $0.displayName < $1.displayName }
    }

    func invites(coachID: UUID) async throws -> [CoachInvite] {
        invitesStorage
            .filter { $0.coachID == coachID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func createInvite(_ invite: CoachInvite) async throws -> CoachInvite {
        guard let walletIndex = wallets.firstIndex(
            where: { $0.coachID == invite.coachID }
        ) else {
            throw DomainError.notFound(resource: "coach_wallet")
        }
        guard wallets[walletIndex].availableSeatCredits > 0 else {
            throw DomainError.conflict(
                reason: "Kuota peserta tidak mencukupi."
            )
        }
        guard !invitesStorage.contains(where: { $0.code == invite.code }) else {
            throw DomainError.conflict(
                reason: "Kode undangan sudah digunakan."
            )
        }

        wallets[walletIndex].availableSeatCredits -= 1
        wallets[walletIndex].updatedAt = invite.createdAt
        creditLedgerEntries.append(
            CreditLedgerEntry(
                id: invite.id,
                walletID: wallets[walletIndex].id,
                kind: .reservation,
                seatCreditDelta: -1,
                note: "Reservasi undangan program lokal.",
                createdAt: invite.createdAt
            )
        )
        invitesStorage.append(invite)
        return invite
    }

    func redeemInvite(
        code: String,
        participantID: UUID,
        enrollmentID: UUID,
        now: Date
    ) async throws -> ProgramEnrollment {
        guard let inviteIndex = invitesStorage.firstIndex(
            where: { $0.code.caseInsensitiveCompare(code) == .orderedSame }
        ) else {
            throw DomainError.notFound(resource: "invite")
        }
        let invite = invitesStorage[inviteIndex]

        if invite.status == .redeemed,
           invite.redeemedByParticipantID == participantID,
           let existing = enrollmentsStorage.first(where: {
               $0.programID == invite.programID
                   && $0.participantID == participantID
           }) {
            return existing
        }
        guard invite.status == .active, invite.expiresAt >= now else {
            throw DomainError.conflict(
                reason: "Undangan sudah tidak dapat digunakan."
            )
        }

        if let existing = enrollmentsStorage.first(where: {
            $0.programID == invite.programID
                && $0.participantID == participantID
        }) {
            invitesStorage[inviteIndex].status = .redeemed
            invitesStorage[inviteIndex].redeemedByParticipantID = participantID
            return existing
        }

        let enrollment = ProgramEnrollment(
            id: enrollmentID,
            programID: invite.programID,
            participantID: participantID,
            coachID: invite.coachID,
            status: .active,
            enrolledAt: now
        )
        enrollmentsStorage.append(enrollment)
        invitesStorage[inviteIndex].status = .redeemed
        invitesStorage[inviteIndex].redeemedByParticipantID = participantID
        return enrollment
    }

    func wallet(coachID: UUID) async throws -> CoachWallet {
        guard let wallet = wallets.first(
            where: { $0.coachID == coachID }
        ) else {
            throw DomainError.notFound(resource: "coach_wallet")
        }
        return wallet
    }

    func ledger(walletID: UUID) async throws -> [CreditLedgerEntry] {
        creditLedgerEntries
            .filter { $0.walletID == walletID }
            .sorted { $0.createdAt > $1.createdAt }
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

    private func userForSession(role: UserRole) throws -> AppUser {
        guard let user = users.first(where: {
            $0.role == role && !$0.isCoachApprovalPending
        }) else {
            throw DomainError.notFound(resource: "session_user")
        }
        return user
    }

    private func recalculateRanks(programID: UUID) {
        let sortedIndices = leaderboardEntries.indices
            .filter { leaderboardEntries[$0].programID == programID }
            .sorted {
                let left = leaderboardEntries[$0]
                let right = leaderboardEntries[$1]
                if left.score.totalPoints == right.score.totalPoints {
                    return left.participantDisplayName
                        < right.participantDisplayName
                }
                return left.score.totalPoints > right.score.totalPoints
            }

        var previousScore: Int?
        var previousRank = 0
        for (position, index) in sortedIndices.enumerated() {
            let score = leaderboardEntries[index].score.totalPoints
            let rank: Int
            if score == previousScore {
                rank = previousRank
            } else {
                rank = position + 1
            }
            leaderboardEntries[index].rank = rank
            previousScore = score
            previousRank = rank
        }
    }
}
