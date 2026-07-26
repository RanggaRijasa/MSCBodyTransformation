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
    AdminPeopleRepository,
    ParticipantDemoRepository,
    CoachDemoRepository
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
        if let index = submissionsStorage.firstIndex(where: {
            $0.enrollmentID == submission.enrollmentID
                && $0.stepID == submission.stepID
        }) {
            guard submissionsStorage[index].status == .rejected else {
                return submissionsStorage[index]
            }
            submissionsStorage[index] = submission
            refreshLeaderboard(enrollmentID: submission.enrollmentID)
            return submission
        }
        submissionsStorage.append(submission)
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
        submissionsStorage[index].status = status
        submissionsStorage[index].reviewerID = reviewerID
        submissionsStorage[index].reviewedAt = reviewedAt
        submissionsStorage[index].reviewNote = note
        refreshLeaderboard(
            enrollmentID: submissionsStorage[index].enrollmentID
        )
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
        refreshLeaderboard(enrollmentID: weighIn.enrollmentID)
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

    func invites(coachID: UUID) async throws -> [CoachInvite] {
        invitesStorage
            .filter { $0.coachID == coachID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func createInvite(_ invite: CoachInvite) async throws -> CoachInvite {
        guard !invitesStorage.contains(where: { $0.code == invite.code }) else {
            throw DomainError.conflict(
                reason: "Kode undangan sudah digunakan."
            )
        }

        invitesStorage.append(invite)
        return invite
    }

    func revokeInvite(
        id: UUID,
        coachID: UUID
    ) async throws -> CoachInvite {
        guard let index = invitesStorage.firstIndex(where: {
            $0.id == id && $0.coachID == coachID
        }) else {
            throw DomainError.permissionDenied
        }
        guard invitesStorage[index].status == .active else {
            throw DomainError.conflict(
                reason: "Hanya undangan aktif yang dapat dicabut."
            )
        }
        invitesStorage[index].status = .revoked
        return invitesStorage[index]
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

        guard let walletIndex = wallets.firstIndex(where: {
            $0.coachID == invite.coachID
        }) else {
            throw DomainError.notFound(resource: "coach_wallet")
        }
        guard wallets[walletIndex].availableSeatCredits > 0 else {
            throw DomainError.conflict(
                reason: "Kuota peserta tidak mencukupi."
            )
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
        wallets[walletIndex].availableSeatCredits -= 1
        wallets[walletIndex].updatedAt = now
        creditLedgerEntries.append(
            CreditLedgerEntry(
                id: enrollmentID,
                walletID: wallets[walletIndex].id,
                kind: .reservation,
                seatCreditDelta: -1,
                note: "Kuota terpakai setelah enrollment demo berhasil.",
                createdAt: now
            )
        )
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

    func grantSeatCredits(
        coachID: UUID,
        amount: Int,
        grantedAt: Date
    ) async throws -> CoachWallet {
        guard amount > 0 else {
            throw DomainError.validation(
                field: "amount",
                reason: "Jumlah kuota harus lebih dari nol."
            )
        }
        guard let index = wallets.firstIndex(where: {
            $0.coachID == coachID
        }) else {
            throw DomainError.notFound(resource: "coach_wallet")
        }
        wallets[index].availableSeatCredits += amount
        wallets[index].updatedAt = grantedAt
        let ledgerSequence = creditLedgerEntries.count + 1_000
        let ledgerID = UUID(
            uuidString: String(
                format: "32000000-0000-0000-0000-%012lld",
                Int64(ledgerSequence)
            )
        ) ?? wallets[index].id
        creditLedgerEntries.append(
            CreditLedgerEntry(
                id: ledgerID,
                walletID: wallets[index].id,
                kind: .purchase,
                seatCreditDelta: amount,
                note: "Kredit demo lokal—bukan transaksi App Store.",
                createdAt: grantedAt
            )
        )
        return wallets[index]
    }

    func setSeatCredits(
        coachID: UUID,
        amount: Int,
        updatedAt: Date
    ) async throws -> CoachWallet {
        guard amount >= 0 else {
            throw DomainError.validation(
                field: "amount",
                reason: "Saldo kuota tidak boleh negatif."
            )
        }
        guard let index = wallets.firstIndex(where: {
            $0.coachID == coachID
        }) else {
            throw DomainError.notFound(resource: "coach_wallet")
        }
        wallets[index].availableSeatCredits = amount
        wallets[index].updatedAt = updatedAt
        return wallets[index]
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
        for index in invitesStorage.indices
        where invitesStorage[index].redeemedByParticipantID == participantID {
            invitesStorage[index].status = .active
            invitesStorage[index].redeemedByParticipantID = nil
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
                        evidence: debugEvidence(for: step),
                        status: .approved,
                        submittedAt: completedAt,
                        reviewedAt: completedAt,
                        reviewerID: enrollment.coachID,
                        reviewNote: nil
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
            evidence: debugEvidence(for: step),
            status: .rejected,
            submittedAt: completedAt,
            reviewedAt: completedAt,
            reviewerID: enrollment.coachID,
            reviewNote: "Bukti demo perlu diperbaiki sebelum dikirim ulang."
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

    private func debugEvidence(
        for step: ProgramStep
    ) -> [SubmissionEvidence] {
        step.requirements.compactMap { requirement in
            guard requirement.isRequired else {
                return nil
            }
            switch requirement.kind {
            case .photoEvidence:
                return SubmissionEvidence(
                    id: requirement.id,
                    kind: .photo,
                    localReference: "local-demo://debug/evidence",
                    textValue: nil
                )
            case .textAnswer:
                return SubmissionEvidence(
                    id: requirement.id,
                    kind: .text,
                    localReference: nil,
                    textValue: "Diselesaikan melalui alat Debug."
                )
            }
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

        let submissions = submissionsStorage.filter {
            $0.enrollmentID == enrollmentID
        }
        let steps = program.days.flatMap(\.steps)
        let stepsByID = Dictionary(
            uniqueKeysWithValues: steps.map { ($0.id, $0) }
        )
        let approvedStepIDs = Set(
            submissions
                .filter { $0.status == .approved }
                .map(\.stepID)
        )
        leaderboardEntries[entryIndex].score.approvedStepPoints =
            approvedStepIDs.reduce(into: 0) { points, stepID in
                points += stepsByID[stepID]?.points ?? 0
            }
        leaderboardEntries[entryIndex].progressPercentage =
            ProgramProgressCalculator().percentage(
                totalStepCount: steps.count,
                submissions: submissions
            )

        let weighIns = weighInsStorage.filter {
            $0.enrollmentID == enrollmentID
        }
        if let initial = weighIns.first(where: { $0.type == .initial }),
           let final = weighIns.first(where: { $0.type == .final }) {
            leaderboardEntries[entryIndex].score.weightPoints =
                WeightScoreCalculator().calculate(
                    initialWeightKilograms: initial.weightKilograms,
                    finalWeightKilograms: final.weightKilograms,
                    pointsPerKilogram: program.weightPointsPerKilogram
                )
        } else {
            leaderboardEntries[entryIndex].score.weightPoints = 0
        }
        recalculateRanks(programID: program.id)
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
