import Foundation
import Observation

nonisolated enum ParticipantEntryStage: Equatable, Sendable {
    case login
    case profile
    case disclaimer
    case invite
    case confirmInvite
    case initialWeighIn
    case complete
}

nonisolated enum ParticipantJourneyLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded(ParticipantJourneySnapshot)
    case failed(DomainError)
}

nonisolated struct ParticipantJourneySnapshot: Equatable, Sendable {
    let user: AppUser
    let profile: ParticipantProfile
    let programs: [Program]
    let enrollments: [ProgramEnrollment]
    let activeProgram: Program?
    let activeEnrollment: ProgramEnrollment?
    let submissions: [StepSubmission]
    let weighIns: [WeighIn]
    let leaderboard: [LeaderboardEntry]
    let winners: [ProgramWinner]
    let coaches: [CoachProfile]
    let managedContent: [ManagedContent]
}

@MainActor
@Observable
final class ParticipantJourneyStore {
    private let environment: AppEnvironment
    private let shouldStartWithoutEnrollment: Bool
    private var didPrepareInitialScenario = false

    var state: ParticipantJourneyLoadState = .idle
    var entryStage: ParticipantEntryStage = .complete
    var pendingInviteCode = "MSC7HARI"
    var selectedDayNumber: Int?
    var debugDateOverride: Date?
    var showsOfflineSimulation = false
    var showsFinalLeaderboard = false
    var hidesActiveProgramForDemo = false
    var isPerformingAction = false

    init(
        environment: AppEnvironment,
        startsWithoutEnrollment: Bool = false
    ) {
        self.environment = environment
        shouldStartWithoutEnrollment = startsWithoutEnrollment
        entryStage = startsWithoutEnrollment ? .login : .complete
    }

    var snapshot: ParticipantJourneySnapshot? {
        guard case .loaded(let snapshot) = state else {
            return nil
        }
        return snapshot
    }

    var currentProgram: Program? {
        guard !hidesActiveProgramForDemo else {
            return nil
        }
        return snapshot?.activeProgram
    }

    var currentEnrollment: ProgramEnrollment? {
        guard !hidesActiveProgramForDemo else {
            return nil
        }
        return snapshot?.activeEnrollment
    }

    var todayDay: ProgramDay? {
        guard let program = currentProgram else {
            return nil
        }
        if let selectedDayNumber {
            return program.days.first {
                $0.dayNumber == selectedDayNumber
            }
        }
        return ProgramDayResolver().activeDay(
            in: program,
            at: effectiveDate
        )
    }

    var effectiveDate: Date {
        if let debugDateOverride {
            return debugDateOverride
        }
        if let selectedDayNumber,
           let date = currentProgram?.days.first(where: {
               $0.dayNumber == selectedDayNumber
           })?.scheduledDate {
            return date
        }
        return environment.clock.now()
    }

    var overallProgress: Int {
        guard let program = currentProgram else {
            return 0
        }
        return ProgramProgressCalculator().percentage(
            totalStepCount: program.days.flatMap(\.steps).count,
            submissions: snapshot?.submissions ?? []
        )
    }

    var isTodayComplete: Bool {
        guard let day = todayDay else {
            return false
        }
        return ProgressCalculator().calculate(
            requiredSteps: day.steps,
            currentDaySteps: day.steps,
            submissions: snapshot?.submissions ?? []
        ).isCurrentDayComplete
    }

    var initialWeighIn: WeighIn? {
        snapshot?.weighIns.first { $0.type == .initial }
    }

    var finalWeighIn: WeighIn? {
        snapshot?.weighIns.first { $0.type == .final }
    }

    var currentLeaderboardEntry: LeaderboardEntry? {
        snapshot?.leaderboard.first { $0.isCurrentUser }
    }

    var wellnessDisclaimer: ManagedContent? {
        snapshot?.managedContent.first {
            $0.kind == .wellnessDisclaimer && $0.isPublished
        }
    }

    var winnerBanner: ManagedContent? {
        snapshot?.managedContent.first {
            $0.kind == .winnerBanner && $0.isPublished
        }
    }

    func load() async {
        state = .loading
        guard let repositories = environment.repositories else {
            state = .failed(environment.bootstrapError ?? .unknown)
            return
        }

        do {
            var session = try await repositories.session.loadCurrentSession()
            if session.state == .loggedOut {
                session = try await repositories.session.switchDebugRole(
                    to: .participant
                )
            }
            guard let user = session.user, user.role == .participant else {
                throw DomainError.permissionDenied
            }
            let profile = try await repositories.profiles.participantProfile(
                userID: user.id
            )

            if shouldStartWithoutEnrollment && !didPrepareInitialScenario {
                await repositories.participantDemo.resetParticipantDemo(
                    participantID: profile.id
                )
                didPrepareInitialScenario = true
            }

            try await loadSnapshot(
                repositories: repositories,
                user: user,
                profile: profile
            )
            if selectedDayNumber == nil {
                selectedDayNumber = defaultDayNumber()
            }
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }

    func localLogin() async {
        guard let repositories = environment.repositories else {
            state = .failed(environment.bootstrapError ?? .unknown)
            return
        }
        isPerformingAction = true
        defer { isPerformingAction = false }

        do {
            _ = try await repositories.session.switchDebugRole(
                to: .participant
            )
            await load()
            entryStage = .profile
        } catch let error as DomainError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }

    func saveProfile(
        displayName: String,
        city: String
    ) async throws {
        guard let repositories = environment.repositories,
              var profile = snapshot?.profile else {
            throw DomainError.unknown
        }
        let trimmedName = displayName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let trimmedCity = city.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty else {
            throw DomainError.validation(
                field: "displayName",
                reason: "Nama tampilan wajib diisi."
            )
        }
        guard !trimmedCity.isEmpty else {
            throw DomainError.validation(
                field: "city",
                reason: "Kota wajib diisi."
            )
        }

        profile.displayName = trimmedName
        profile.city = trimmedCity
        _ = try await repositories.profiles.save(
            participantProfile: profile
        )
        try await reloadSnapshot()
        entryStage = .disclaimer
    }

    func acceptDisclaimer() {
        entryStage = .invite
    }

    func preservePendingInvite(code: String) {
        let normalized = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard !normalized.isEmpty else { return }
        pendingInviteCode = normalized
    }

    func previewInvite(code: String) throws {
        let normalized = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard !normalized.isEmpty else {
            throw DomainError.validation(
                field: "inviteCode",
                reason: "Kode undangan wajib diisi."
            )
        }
        guard currentProgram != nil else {
            throw DomainError.notFound(resource: "program")
        }
        preservePendingInvite(code: normalized)
        entryStage = .confirmInvite
    }

    func loadInvitePreview(
        code: String
    ) async throws -> ProgramInvitePreview {
        guard let repositories = environment.repositories else {
            throw DomainError.unknown
        }
        isPerformingAction = true
        defer { isPerformingAction = false }

        let preview = try await PreviewLocalInviteUseCase(
            invites: repositories.invites,
            programs: repositories.programs,
            clock: environment.clock
        )(code: code)
        preservePendingInvite(code: preview.invite.code)
        return preview
    }

    func joinPendingInvite() async throws {
        guard let repositories = environment.repositories,
              let participantID = snapshot?.profile.id else {
            throw DomainError.unknown
        }
        isPerformingAction = true
        defer { isPerformingAction = false }

        let useCase = RedeemLocalInviteUseCase(
            repository: repositories.invites,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock
        )
        _ = try await useCase(
            code: pendingInviteCode,
            participantID: participantID
        )
        try await reloadSnapshot()
        if shouldStartWithoutEnrollment,
           let firstDayNumber = currentProgram?.days
               .sorted(by: { $0.dayNumber < $1.dayNumber })
               .first?.dayNumber {
            selectDay(firstDayNumber)
        }
        entryStage = initialWeighIn == nil ? .initialWeighIn : .complete
    }

    func submitWeighIn(
        type: WeighInType,
        input: String
    ) async throws {
        guard let repositories = environment.repositories,
              let enrollmentID = currentEnrollment?.id,
              let program = currentProgram else {
            throw DomainError.notFound(resource: "enrollment")
        }
        let weight = try IndonesianWeightInputParser().parse(input)
        try WeighInWindowValidator().validate(
            type: type,
            now: effectiveDate,
            program: program
        )

        isPerformingAction = true
        defer { isPerformingAction = false }
        let useCase = SubmitLocalWeighInUseCase(
            repository: repositories.weighIns,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock,
            validator: WeighInValidator()
        )
        _ = try await useCase(
            enrollmentID: enrollmentID,
            type: type,
            weightKilograms: weight
        )
        try await reloadSnapshot()
        entryStage = .complete
    }

    func completeStep(
        _ step: ProgramStep,
        localPhotoReference: String?,
        textAnswer: String?
    ) async throws {
        guard access(for: step) == .available else {
            throw DomainError.validation(
                field: "step",
                reason: "Langkah yang terkunci tidak dapat diselesaikan."
            )
        }
        guard let repositories = environment.repositories,
              let enrollmentID = currentEnrollment?.id else {
            throw DomainError.notFound(resource: "enrollment")
        }

        var evidence: [SubmissionEvidence] = []
        if let localPhotoReference {
            evidence.append(
                SubmissionEvidence(
                    id: environment.identifierGenerator.makeIdentifier(),
                    kind: .photo,
                    localReference: localPhotoReference,
                    textValue: nil
                )
            )
        }
        if let textAnswer {
            evidence.append(
                SubmissionEvidence(
                    id: environment.identifierGenerator.makeIdentifier(),
                    kind: .text,
                    localReference: nil,
                    textValue: textAnswer
                )
            )
        }

        isPerformingAction = true
        defer { isPerformingAction = false }
        let useCase = CompleteLocalStepUseCase(
            repository: repositories.submissions,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock,
            validator: StepSubmissionValidator()
        )
        _ = try await useCase(
            enrollmentID: enrollmentID,
            step: step,
            evidence: evidence
        )
        try await reloadSnapshot()
    }

    func submission(for stepID: UUID) -> StepSubmission? {
        snapshot?.submissions.first { $0.stepID == stepID }
    }

    func access(for day: ProgramDay) -> ProgramDayAccess {
        guard let program = currentProgram else {
            return .hidden
        }
        return ProgramDayAccessCalculator().access(
            for: day,
            now: effectiveDate,
            timeZoneIdentifier: program.timeZoneIdentifier
        )
    }

    func access(for step: ProgramStep) -> ProgramDayAccess {
        guard let day = currentProgram?.days.first(where: {
            $0.id == step.programDayID
        }) else {
            return .hidden
        }
        return access(for: day)
    }

    func step(id: UUID) -> ProgramStep? {
        currentProgram?.days
            .flatMap(\.steps)
            .first { $0.id == id }
    }

    func coach(id: UUID) -> CoachProfile? {
        snapshot?.coaches.first { $0.id == id }
    }

    func selectDay(_ dayNumber: Int) {
        selectedDayNumber = dayNumber
        if let date = currentProgram?.days.first(where: {
            $0.dayNumber == dayNumber
        })?.scheduledDate {
            debugDateOverride = date
        }
    }

    func setDebugDate(_ date: Date) {
        debugDateOverride = date
        guard let program = currentProgram else {
            return
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(identifier: program.timeZoneIdentifier) ?? .gmt
        selectedDayNumber = program.days.first {
            calendar.isDate($0.scheduledDate, inSameDayAs: date)
        }?.dayNumber
    }

    func resetDemoParticipant() async {
        guard let repository = environment.repositories?.participantDemo,
              let participantID = snapshot?.profile.id else {
            return
        }
        await repository.resetParticipantDemo(
            participantID: participantID
        )
        entryStage = .login
        selectedDayNumber = nil
        debugDateOverride = nil
        showsFinalLeaderboard = false
        try? await reloadSnapshot()
    }

    func prepareDayOneDemo() async {
        guard let repository = environment.repositories?.participantDemo,
              let participantID = snapshot?.profile.id else {
            return
        }
        await repository.resetParticipantProgress(
            participantID: participantID
        )
        try? await reloadSnapshot()
        selectDay(1)
    }

    func markPreviousDaysComplete() async throws {
        guard let repository = environment.repositories?.participantDemo,
              let participantID = snapshot?.profile.id else {
            throw DomainError.unknown
        }
        try await repository.markPreviousDaysComplete(
            participantID: participantID,
            throughDayNumber: selectedDayNumber ?? 1,
            completedAt: effectiveDate
        )
        try await reloadSnapshot()
    }

    func simulateRejectedSubmission() async throws {
        guard let repository = environment.repositories?.participantDemo,
              let participantID = snapshot?.profile.id else {
            throw DomainError.unknown
        }
        _ = try await repository.simulateRejectedSubmission(
            participantID: participantID,
            dayNumber: selectedDayNumber ?? 1,
            completedAt: effectiveDate
        )
        try await reloadSnapshot()
    }

    func simulateOffline() {
        showsOfflineSimulation = true
        state = .failed(.offline)
    }

    func simulateRepositoryError() {
        state = .failed(.unknown)
    }

    func simulateFinalProgramState() async throws {
        guard let lastDay = currentProgram?.days.max(by: {
            $0.dayNumber < $1.dayNumber
        }) else {
            return
        }
        selectDay(lastDay.dayNumber)
        try await markPreviousDaysComplete()
        showsFinalLeaderboard = true
    }

    func retryLoad() async {
        showsOfflineSimulation = false
        await load()
    }

    func logoutLocalDemo() async {
        await environment.repositories?.session.setDebugScenario(.loggedOut)
        entryStage = .login
    }

    private func loadSnapshot(
        repositories: AppRepositories,
        user: AppUser,
        profile: ParticipantProfile
    ) async throws {
        async let programsTask = repositories.programs.programs()
        async let enrollmentsTask = repositories.enrollments.enrollments(
            participantID: profile.id
        )
        async let coachesTask = repositories.coachDirectory.publicCoaches()
        async let managedContentTask =
            repositories.managedContent.managedContent()

        let programs = try await programsTask
        let enrollments = try await enrollmentsTask
        let activeProgram = programs.first { $0.status == .active }
        let activeEnrollment = activeProgram.flatMap { program in
            enrollments.first {
                $0.programID == program.id && $0.status == .active
            }
        }

        let submissions: [StepSubmission]
        let weighIns: [WeighIn]
        if let activeEnrollment {
            async let submissionsTask = repositories.submissions.submissions(
                enrollmentID: activeEnrollment.id
            )
            async let weighInsTask = repositories.weighIns.weighIns(
                enrollmentID: activeEnrollment.id
            )
            submissions = try await submissionsTask
            weighIns = try await weighInsTask
        } else {
            submissions = []
            weighIns = []
        }

        let leaderboard: [LeaderboardEntry]
        let winners: [ProgramWinner]
        if let activeProgram {
            async let leaderboardTask = repositories.leaderboard.leaderboard(
                programID: activeProgram.id
            )
            async let winnersTask = repositories.leaderboard.winners(
                programID: activeProgram.id
            )
            leaderboard = try await leaderboardTask
            winners = try await winnersTask
        } else {
            leaderboard = []
            winners = []
        }

        state = .loaded(
            ParticipantJourneySnapshot(
                user: user,
                profile: profile,
                programs: programs,
                enrollments: enrollments,
                activeProgram: activeProgram,
                activeEnrollment: activeEnrollment,
                submissions: submissions,
                weighIns: weighIns,
                leaderboard: leaderboard,
                winners: winners,
                coaches: try await coachesTask,
                managedContent: try await managedContentTask
            )
        )
    }

    private func reloadSnapshot() async throws {
        guard let repositories = environment.repositories,
              let userID = snapshot?.user.id else {
            throw DomainError.unknown
        }
        let user = try await repositories.profiles.user(id: userID)
        let profile = try await repositories.profiles.participantProfile(
            userID: userID
        )
        try await loadSnapshot(
            repositories: repositories,
            user: user,
            profile: profile
        )
    }

    private func defaultDayNumber() -> Int? {
        guard let program = currentProgram else {
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(identifier: program.timeZoneIdentifier) ?? .gmt
        return program.days.first {
            calendar.isDate(
                $0.scheduledDate,
                inSameDayAs: environment.clock.now()
            )
        }?.dayNumber ?? program.days.first?.dayNumber
    }
}
