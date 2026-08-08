import Foundation
import Observation

nonisolated enum ParticipantEntryStage: Equatable, Sendable {
    case login
    case profile
    case disclaimer
    case complete
}

nonisolated enum ProgramParticipationAccount: Sendable {
    case participant
    case coach

    var sessionRole: UserRole {
        switch self {
        case .participant:
            .participant
        case .coach:
            .coach
        }
    }
}

nonisolated enum ParticipantJourneyLoadState: Equatable, Sendable {
    case idle
    case loading
    case guestLoaded(GuestBrowsingSnapshot)
    case loaded(ParticipantJourneySnapshot)
    case failed(DomainError)
}

nonisolated struct GuestBrowsingSnapshot: Equatable, Sendable {
    let programs: [Program]
    let featuredWinnerPosters: [ManagedContent]
    let coaches: [CoachProfile]
    let managedContent: [ManagedContent]
}

nonisolated struct ParticipantJourneySnapshot: Equatable, Sendable {
    let user: AppUser
    let profile: ParticipantProfile
    let publicProfileID: UUID?
    let programs: [Program]
    let enrollments: [ProgramEnrollment]
    let enrollmentContexts: [ProgramEnrollmentContext]
    let activeProgram: Program?
    let activeEnrollment: ProgramEnrollment?
    let submissions: [StepSubmission]
    let weighIns: [WeighIn]
    let leaderboard: [LeaderboardEntry]
    let winners: [ProgramWinner]
    let featuredWinnerPosters: [ManagedContent]
    let coaches: [CoachProfile]
    let managedContent: [ManagedContent]
    let dayAccessStates: [AuthenticatedProgramDayAccessState]
    let dashboardSummary: AuthenticatedDashboardSummary?

    init(
        user: AppUser,
        profile: ParticipantProfile,
        publicProfileID: UUID? = nil,
        programs: [Program],
        enrollments: [ProgramEnrollment],
        enrollmentContexts: [ProgramEnrollmentContext],
        activeProgram: Program?,
        activeEnrollment: ProgramEnrollment?,
        submissions: [StepSubmission],
        weighIns: [WeighIn],
        leaderboard: [LeaderboardEntry],
        winners: [ProgramWinner],
        featuredWinnerPosters: [ManagedContent],
        coaches: [CoachProfile],
        managedContent: [ManagedContent],
        dayAccessStates: [AuthenticatedProgramDayAccessState] = [],
        dashboardSummary: AuthenticatedDashboardSummary? = nil
    ) {
        self.user = user
        self.profile = profile
        self.publicProfileID = publicProfileID
        self.programs = programs
        self.enrollments = enrollments
        self.enrollmentContexts = enrollmentContexts
        self.activeProgram = activeProgram
        self.activeEnrollment = activeEnrollment
        self.submissions = submissions
        self.weighIns = weighIns
        self.leaderboard = leaderboard
        self.winners = winners
        self.featuredWinnerPosters = featuredWinnerPosters
        self.coaches = coaches
        self.managedContent = managedContent
        self.dayAccessStates = dayAccessStates
        self.dashboardSummary = dashboardSummary
    }
}

nonisolated enum ParticipantLeaderboardLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded(ParticipantLeaderboardProgramSnapshot)
    case failed(DomainError)
}

nonisolated struct ParticipantLeaderboardProgramSnapshot:
    Equatable,
    Sendable
{
    let program: Program
    let entries: [LeaderboardEntry]
    let winners: [ProgramWinner]
}

@MainActor
@Observable
final class ParticipantJourneyStore {
    private let environment: AppEnvironment
    private let participationAccount: ProgramParticipationAccount
    private let shouldStartWithoutEnrollment: Bool
    private let allowsGuestAccess: Bool
    private var didPrepareInitialScenario = false
    private var didRestorePendingEnrollmentIntent = false

    var state: ParticipantJourneyLoadState = .idle
    var entryStage: ParticipantEntryStage = .complete
    var selectedDayNumber: Int?
    var debugDateOverride: Date?
    var showsOfflineSimulation = false
    var showsFinalLeaderboard = false
    var hidesActiveProgramForDemo = false {
        didSet {
            guard hidesActiveProgramForDemo,
                  case .loaded(let leaderboard) = leaderboardState,
                  leaderboard.program.status == .active else {
                return
            }
            selectedLeaderboardProgramID = nil
            leaderboardState = .idle
        }
    }
    var isPerformingAction = false
    var focusedProgramID: UUID?
    var selectedLeaderboardProgramID: UUID?
    var leaderboardState: ParticipantLeaderboardLoadState = .idle
    var accessState: AppAccessState = .guest
    var authenticationPresentation: AuthenticationPresentation?
    var pendingAuthenticatedIntent: PendingAuthenticatedIntent?
    var completedAuthenticatedIntent: PendingAuthenticatedIntent?

    init(
        environment: AppEnvironment,
        participationAccount: ProgramParticipationAccount = .participant,
        startsWithoutEnrollment: Bool = false,
        allowsGuestAccess: Bool = false
    ) {
        self.environment = environment
        self.participationAccount = participationAccount
        shouldStartWithoutEnrollment = startsWithoutEnrollment
        self.allowsGuestAccess = allowsGuestAccess
        entryStage = startsWithoutEnrollment ? .login : .complete
    }

    var snapshot: ParticipantJourneySnapshot? {
        guard case .loaded(let snapshot) = state else {
            return nil
        }
        return snapshot
    }

    var guestSnapshot: GuestBrowsingSnapshot? {
        guard case .guestLoaded(let snapshot) = state else {
            return nil
        }
        return snapshot
    }

    var isGuest: Bool {
        if case .guest = accessState {
            return true
        }
        return false
    }

    var isLocalDemo: Bool {
        environment.configuration.mode == .localDemo
    }

    var programs: [Program] {
        snapshot?.programs ?? guestSnapshot?.programs ?? []
    }

    var publicCoaches: [CoachProfile] {
        snapshot?.coaches ?? guestSnapshot?.coaches ?? []
    }

    var featuredWinnerPosters: [ManagedContent] {
        snapshot?.featuredWinnerPosters
            ?? guestSnapshot?.featuredWinnerPosters
            ?? []
    }

    var currentProgram: Program? {
        guard !hidesActiveProgramForDemo else {
            return nil
        }
        return snapshot?.activeProgram
    }

    var activeProgramContexts: [ProgramEnrollmentContext] {
        snapshot?.enrollmentContexts.filter {
            $0.enrollment.status == .active
                && ($0.program.status == .active
                    || $0.program.status == .scheduled)
        } ?? []
    }

    var currentEnrollment: ProgramEnrollment? {
        guard !hidesActiveProgramForDemo else {
            return nil
        }
        return snapshot?.activeEnrollment
    }

    var visibleEnrollments: [ProgramEnrollment] {
        guard let snapshot else {
            return []
        }
        guard hidesActiveProgramForDemo else {
            return snapshot.enrollments
        }
        return snapshot.enrollments.filter {
            $0.status == .completed || $0.status == .cancelled
        }
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

    func registrationAvailability(
        for program: Program
    ) -> ProgramRegistrationAvailability {
        program.registrationAvailability(at: environment.clock.now())
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

    var activeLeaderboardPrograms: [Program] {
        if isGuest {
            return programs
                .filter { $0.status == .active || $0.status == .scheduled }
                .sorted {
                    if $0.startDate == $1.startDate {
                        return $0.title.localizedStandardCompare($1.title)
                            == .orderedAscending
                    }
                    return $0.startDate > $1.startDate
                }
        }
        guard let snapshot, !hidesActiveProgramForDemo else {
            return []
        }
        let activeEnrollmentProgramIDs = Set(
            snapshot.enrollments.compactMap { enrollment in
                enrollment.status == .active ? enrollment.programID : nil
            }
        )
        return snapshot.programs
            .filter {
                $0.status == .active
                    && activeEnrollmentProgramIDs.contains($0.id)
            }
            .sorted {
                if $0.startDate == $1.startDate {
                    return $0.title.localizedStandardCompare($1.title)
                        == .orderedAscending
                }
                return $0.startDate > $1.startDate
            }
    }

    var archivedLeaderboardPrograms: [Program] {
        if isGuest {
            return programs
                .filter {
                    $0.status == .completed || $0.status == .archived
                }
                .sorted { $0.endDate > $1.endDate }
        }
        guard let snapshot else {
            return []
        }
        let historicalProgramIDs = Set(
            snapshot.enrollments.compactMap { enrollment in
                switch enrollment.status {
                case .completed:
                    enrollment.programID
                case .initiated, .waitingForPayment, .active,
                     .cancelled, .refunded:
                    nil
                }
            }
        )
        return snapshot.programs
            .filter {
                ($0.status == .completed || $0.status == .archived)
                    && historicalProgramIDs.contains($0.id)
            }
            .sorted {
                if $0.endDate == $1.endDate {
                    return $0.title.localizedStandardCompare($1.title)
                        == .orderedAscending
                }
                return $0.endDate > $1.endDate
            }
    }

    var selectedLeaderboardProgram: Program? {
        guard let selectedLeaderboardProgramID else {
            return nil
        }
        return (activeLeaderboardPrograms + archivedLeaderboardPrograms)
            .first { $0.id == selectedLeaderboardProgramID }
    }

    var wellnessDisclaimer: ManagedContent? {
        (snapshot?.managedContent ?? guestSnapshot?.managedContent ?? []).first {
            $0.kind == .wellnessDisclaimer && $0.isPublished
        }
    }

    var winnerBanner: ManagedContent? {
        (snapshot?.managedContent ?? guestSnapshot?.managedContent ?? []).first {
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
                if allowsGuestAccess {
                    accessState = .guest
                    try await loadGuestSnapshot(repositories: repositories)
                    return
                } else {
                    session = try await repositories.session.switchDebugRole(
                        to: participationAccount.sessionRole
                    )
                }
            }
            guard let user = session.user,
                  user.role == participationAccount.sessionRole else {
                throw DomainError.permissionDenied
            }
            accessState = .authenticated(session)
            if let authenticatedReads =
                repositories.authenticatedParticipantReads {
                let readSnapshot = try await authenticatedReads.snapshot(
                    user: user
                )
                let profile = try readSnapshot.account.participantProfile(
                    userID: user.id
                )
                try await loadAuthenticatedSnapshot(
                    repositories: repositories,
                    user: user,
                    profile: profile,
                    readSnapshot: readSnapshot
                )
                if selectedDayNumber == nil {
                    selectedDayNumber = defaultDayNumber()
                }
                if !didRestorePendingEnrollmentIntent,
                   let intent = try await repositories.authentication
                       .pendingEnrollmentIntent() {
                    didRestorePendingEnrollmentIntent = true
                    completedAuthenticatedIntent = .joinProgram(
                        intent.programID
                    )
                }
                return
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
            if !didRestorePendingEnrollmentIntent,
               let intent = try await repositories.authentication
                   .pendingEnrollmentIntent() {
                didRestorePendingEnrollmentIntent = true
                completedAuthenticatedIntent = .joinProgram(intent.programID)
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
                to: participationAccount.sessionRole
            )
            await load()
            entryStage = .profile
        } catch let error as DomainError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }

    func requestAuthentication(
        destination: AuthenticationDestination = .login,
        reason: AuthGateReason? = nil,
        intent: PendingAuthenticatedIntent? = nil
    ) async {
        if let intent {
            pendingAuthenticatedIntent = intent
            if case .joinProgram(let programID) = intent {
                try? await environment.repositories?.authentication
                    .savePendingEnrollmentIntent(programID: programID)
            }
        }
        guard authenticationPresentation == nil else {
            return
        }
        authenticationPresentation = AuthenticationPresentation(
            destination: destination,
            reason: reason
        )
    }

    func updateAuthenticationDestination(
        _ destination: AuthenticationDestination
    ) async {
        guard var presentation = authenticationPresentation else {
            await requestAuthentication(destination: destination)
            return
        }
        presentation.destination = destination
        authenticationPresentation = presentation
    }

    func cancelAuthentication() {
        authenticationPresentation = nil
        pendingAuthenticatedIntent = nil
    }

    func completeAuthenticationFlow() async {
        await load()
        completedAuthenticatedIntent = pendingAuthenticatedIntent
        pendingAuthenticatedIntent = nil
        authenticationPresentation = nil
    }

    func consumeCompletedAuthenticatedIntent()
        -> PendingAuthenticatedIntent?
    {
        defer { completedAuthenticatedIntent = nil }
        return completedAuthenticatedIntent
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
        entryStage = .complete
    }

    func submitWeighIn(
        type: WeighInType,
        input: String,
        stepID: UUID? = nil
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
            stepID: stepID,
            type: type,
            weightKilograms: weight
        )
        try await reloadSnapshot()
        entryStage = .complete
    }

    func submitWeighInStep(
        _ step: ProgramStep,
        input: String
    ) async throws {
        guard let kind = step.content?.weighInKind else {
            throw DomainError.validation(
                field: "step",
                reason: "Langkah ini bukan langkah timbang."
            )
        }
        let type: WeighInType = switch kind {
        case .initial:
            .initial
        case .daily:
            .daily
        case .final:
            .final
        }
        if type == .final, initialWeighIn == nil {
            throw DomainError.validation(
                field: "weight",
                reason: "Isi timbang awal sebelum mengirim timbang akhir."
            )
        }
        try await submitWeighIn(
            type: type,
            input: input,
            stepID: step.id
        )

        guard let repositories = environment.repositories,
              let enrollmentID = currentEnrollment?.id,
              let program = currentProgram else {
            throw DomainError.notFound(resource: "enrollment")
        }
        _ = try await CompleteTypedStepUseCase(
            repository: repositories.submissions,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock
        )(
            enrollmentID: enrollmentID,
            step: step,
            answers: [],
            scoring: program.effectiveScoringConfiguration
        )
        try await reloadSnapshot()
    }

    func completeStep(
        _ step: ProgramStep,
        answers: [StepSubmissionAnswer]
    ) async throws {
        guard access(for: step) == .available else {
            throw DomainError.validation(
                field: "step",
                reason: "Langkah yang terkunci tidak dapat diselesaikan."
            )
        }
        guard let repositories = environment.repositories,
              let enrollmentID = currentEnrollment?.id,
              let program = currentProgram else {
            throw DomainError.notFound(resource: "enrollment")
        }
        guard step.content?.weighInKind == nil else {
            throw DomainError.validation(
                field: "step",
                reason: "Gunakan form timbang untuk menyelesaikan langkah ini."
            )
        }

        isPerformingAction = true
        defer { isPerformingAction = false }
        _ = try await CompleteTypedStepUseCase(
            repository: repositories.submissions,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock
        )(
            enrollmentID: enrollmentID,
            step: step,
            answers: answers,
            scoring: program.effectiveScoringConfiguration
        )
        try await reloadSnapshot()
    }

    func submission(for stepID: UUID) -> StepSubmission? {
        snapshot?.submissions.first { $0.stepID == stepID }
    }

    func selectProgram(_ programID: UUID) {
        guard activeProgramContexts.contains(where: {
            $0.program.id == programID
        }) else {
            return
        }
        focusedProgramID = programID
        selectedDayNumber = nil
        debugDateOverride = nil
        Task {
            try? await reloadSnapshot()
            selectedDayNumber = defaultDayNumber()
        }
    }

    func access(for day: ProgramDay) -> ProgramDayAccess {
        guard let program = currentProgram else {
            return .hidden
        }
        if let enrollmentID = currentEnrollment?.id,
           let serverAccess = snapshot?.dayAccessStates.first(where: {
               $0.enrollmentID == enrollmentID
                   && $0.programDayID == day.id
           }) {
            return serverAccess.access
        }
        return ProgramDayAccessCalculator().access(
            for: day,
            in: program,
            now: effectiveDate
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
        publicCoaches.first { $0.id == id }
    }

    func enrollment(for programID: UUID) -> ProgramEnrollment? {
        snapshot?.enrollments.first {
            $0.programID == programID
                && $0.status != .cancelled
        }
    }

    func coach(matchingEnrollmentIdentifier input: String) async throws
        -> CoachProfile
    {
        let opaqueValue = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedIdentifier = opaqueValue
            .uppercased()
        guard !normalizedIdentifier.isEmpty else {
            throw DomainError.validation(
                field: "coachIdentifier",
                reason: "QR coach tidak valid."
            )
        }
        if let resolver = environment.repositories?.coachQREnrollment {
            return try await resolver.resolveCoach(qrOpaqueValue: opaqueValue)
        }
        guard let coach = snapshot?.coaches.first(where: {
            $0.enrollmentIdentifier.uppercased() == normalizedIdentifier
        }) else {
            throw DomainError.notFound(resource: "coach")
        }
        return coach
    }

    func updateParticipantProfile(
        displayName: String,
        phoneNumber: String,
        localPhotoReference: String?
    ) async throws {
        guard let repositories = environment.repositories,
              var profile = snapshot?.profile else {
            throw DomainError.unknown
        }
        let trimmedName = displayName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty else {
            throw DomainError.validation(
                field: "displayName",
                reason: "Nama tampilan wajib diisi."
            )
        }

        let compactPhone = phoneNumber.filter {
            !$0.isWhitespace && $0 != "-"
        }
        let phoneDigits = compactPhone.filter(\.isNumber)
        if !compactPhone.isEmpty {
            let hasValidCharacters = compactPhone.allSatisfy {
                $0.isNumber || $0 == "+"
            }
            let plusIsValid = !compactPhone.contains("+")
                || (
                    compactPhone.first == "+"
                        && compactPhone.dropFirst().allSatisfy(\.isNumber)
                )
            guard hasValidCharacters,
                  plusIsValid,
                  (8...15).contains(phoneDigits.count) else {
                throw DomainError.validation(
                    field: "phoneNumber",
                    reason: "Masukkan nomor HP yang valid."
                )
            }
        }

        profile.displayName = trimmedName
        profile.phoneNumber = compactPhone.isEmpty ? nil : compactPhone
        profile.localPhotoReference = localPhotoReference.flatMap {
            $0.isEmpty ? nil : $0
        }
        _ = try await repositories.profiles.save(
            participantProfile: profile
        )
        try await reloadSnapshot()
    }

    func joinProgram(
        programID: UUID,
        with coach: CoachProfile
    ) async throws {
        guard let repositories = environment.repositories,
              let snapshot else {
            throw DomainError.unknown
        }
        guard let program = snapshot.programs.first(where: {
            $0.id == programID
        }), program.status == .active || program.status == .scheduled else {
            throw DomainError.validation(
                field: "program",
                reason: "Program ini belum dapat diikuti."
            )
        }
        guard coach.isApproved else {
            throw DomainError.permissionDenied
        }

        isPerformingAction = true
        defer { isPerformingAction = false }

        _ = try await JoinProgramWithCoachUseCase(
            enrollments: repositories.enrollments,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock,
            coachQREnrollment: repositories.coachQREnrollment
        )(
            program: program,
            participantID: snapshot.profile.id,
            coach: coach
        )
        focusedProgramID = programID
        try await reloadSnapshot()
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
        selectedLeaderboardProgramID = nil
        leaderboardState = .idle
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

    func prepareLeaderboardSelection() async {
        guard case .idle = leaderboardState else {
            return
        }
        guard let program = selectedLeaderboardProgram
                ?? activeLeaderboardPrograms.first
                ?? archivedLeaderboardPrograms.first else {
            return
        }
        await selectLeaderboardProgram(program.id)
    }

    func selectLeaderboardProgram(_ programID: UUID) async {
        let availablePrograms =
            activeLeaderboardPrograms + archivedLeaderboardPrograms
        guard let program = availablePrograms.first(where: {
            $0.id == programID
        }), let repositories = environment.repositories else {
            leaderboardState = .failed(.notFound(resource: "program"))
            return
        }

        selectedLeaderboardProgramID = program.id
        leaderboardState = .loading
        do {
            let entries: [LeaderboardEntry]
            let winners: [ProgramWinner]
            if isGuest {
                async let entriesTask =
                    repositories.publicLeaderboard.leaderboard(
                        programID: program.id
                    )
                async let winnersTask =
                    repositories.publicLeaderboard.winners(
                        programID: program.id
                    )
                entries = try await entriesTask
                winners = try await winnersTask
            } else if repositories.authenticatedParticipantReads != nil {
                async let entriesTask =
                    repositories.publicLeaderboard.leaderboard(
                        programID: program.id
                    )
                async let winnersTask =
                    repositories.publicLeaderboard.winners(
                        programID: program.id
                    )
                entries = markingCurrentParticipant(
                    in: try await entriesTask,
                    publicProfileID: snapshot?.publicProfileID
                )
                winners = try await winnersTask
            } else {
                async let entriesTask =
                    repositories.leaderboard.leaderboard(
                        programID: program.id
                    )
                async let winnersTask = repositories.leaderboard.winners(
                    programID: program.id
                )
                entries = try await entriesTask
                winners = try await winnersTask
            }
            guard !Task.isCancelled else {
                return
            }
            leaderboardState = .loaded(
                ParticipantLeaderboardProgramSnapshot(
                    program: program,
                    entries: entries,
                    winners: winners
                )
            )
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            leaderboardState = .failed(error)
        } catch {
            leaderboardState = .failed(.unknown)
        }
    }

    func retryLeaderboardSelection() async {
        guard let programID = selectedLeaderboardProgramID
                ?? activeLeaderboardPrograms.first?.id
                ?? archivedLeaderboardPrograms.first?.id else {
            return
        }
        await selectLeaderboardProgram(programID)
    }

    func logoutLocalDemo() async {
        if isLocalDemo {
            await environment.repositories?.session
                .setDebugScenario(.loggedOut)
        } else {
            try? await environment.repositories?.session.signOut()
        }
        if allowsGuestAccess {
            entryStage = .complete
            await load()
        } else {
            entryStage = .login
        }
    }

    private func loadGuestSnapshot(
        repositories: AppRepositories
    ) async throws {
        async let programsTask = repositories.publicPrograms.programs()
        async let coachesTask =
            repositories.publicCoachDirectory.publicCoaches()
        async let managedContentTask =
            repositories.publicManagedContent.managedContent()
        let allPrograms = try await programsTask
        let programValues = allPrograms.filter {
            $0.status == .active
                || $0.status == .scheduled
                || $0.status == .completed
                || $0.status == .archived
        }
        let managedContent = try await managedContentTask
        let featuredWinnerPosters = managedContent
            .filter {
                $0.kind == .winnerBanner
                    && ManagedContentValidator().isVisible(
                        $0,
                        at: environment.clock.now()
                    )
                    && $0.localMediaReference?.isEmpty == false
            }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.updatedAt > $1.updatedAt
                }
                return $0.sortOrder < $1.sortOrder
            }
        state = .guestLoaded(
            GuestBrowsingSnapshot(
                programs: programValues,
                featuredWinnerPosters: featuredWinnerPosters,
                coaches: try await coachesTask,
                managedContent: managedContent.filter(\.isPublished)
            )
        )
        focusedProgramID = nil
        selectedDayNumber = nil
        selectedLeaderboardProgramID = nil
        leaderboardState = .idle
    }

    private func loadAuthenticatedSnapshot(
        repositories: AppRepositories,
        user: AppUser,
        profile: ParticipantProfile,
        readSnapshot: AuthenticatedParticipantReadSnapshot
    ) async throws {
        async let publicCoachesTask =
            repositories.publicCoachDirectory.publicCoaches()
        async let managedContentTask =
            repositories.publicManagedContent.managedContent()

        let programs = readSnapshot.programs
        let enrollments = readSnapshot.enrollments
        let eligibleEnrollments = enrollments.filter { enrollment in
            enrollment.status == .active
                && programs.contains {
                    $0.id == enrollment.programID
                        && ($0.status == .active || $0.status == .scheduled)
                }
        }
        let activeEnrollment =
            eligibleEnrollments.first {
                $0.programID == focusedProgramID
            } ?? eligibleEnrollments.first
        let activeProgram = activeEnrollment.flatMap { enrollment in
            programs.first { $0.id == enrollment.programID }
        }
        if focusedProgramID == nil {
            focusedProgramID = activeProgram?.id
        }

        let activeContext = activeEnrollment.flatMap { enrollment in
            readSnapshot.enrollmentContexts.first {
                $0.enrollment.id == enrollment.id
            }
        }
        let submissions = activeContext?.submissions ?? []
        let weighIns = activeContext?.weighIns ?? []

        let leaderboard: [LeaderboardEntry]
        let winners: [ProgramWinner]
        if let activeProgram {
            async let leaderboardTask =
                repositories.publicLeaderboard.leaderboard(
                    programID: activeProgram.id
                )
            async let winnersTask = repositories.publicLeaderboard.winners(
                programID: activeProgram.id
            )
            leaderboard = markingCurrentParticipant(
                in: try await leaderboardTask,
                publicProfileID: readSnapshot.account.publicProfileID
            )
            winners = try await winnersTask
        } else {
            leaderboard = []
            winners = []
        }

        let managedContent = try await managedContentTask
        let featuredWinnerPosters = managedContent
            .filter {
                $0.kind == .winnerBanner
                    && ManagedContentValidator().isVisible(
                        $0,
                        at: environment.clock.now()
                    )
                    && $0.localMediaReference?.isEmpty == false
            }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.updatedAt > $1.updatedAt
                }
                return $0.sortOrder < $1.sortOrder
            }

        var coaches = try await publicCoachesTask
        if let assignedCoach = readSnapshot.assignedCoach {
            coaches.removeAll {
                $0.id == assignedCoach.publicProfileID
                    || $0.userID == assignedCoach.profile.userID
            }
            coaches.insert(assignedCoach.profile, at: 0)
        }

        let nextSnapshot = ParticipantJourneySnapshot(
            user: user,
            profile: profile,
            publicProfileID: readSnapshot.account.publicProfileID,
            programs: programs,
            enrollments: enrollments,
            enrollmentContexts: readSnapshot.enrollmentContexts,
            activeProgram: activeProgram,
            activeEnrollment: activeEnrollment,
            submissions: submissions,
            weighIns: weighIns,
            leaderboard: leaderboard,
            winners: winners,
            featuredWinnerPosters: featuredWinnerPosters,
            coaches: coaches,
            managedContent: managedContent,
            dayAccessStates: readSnapshot.dayAccessStates,
            dashboardSummary: readSnapshot.dashboardSummary
        )
        state = .loaded(nextSnapshot)
        updateLeaderboardSelectionAfterJourneyLoad(snapshot: nextSnapshot)
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
        let managedContent = try await managedContentTask
        let eligibleEnrollments = enrollments.filter { enrollment in
            enrollment.status == .active
                && programs.contains {
                    $0.id == enrollment.programID
                        && ($0.status == .active || $0.status == .scheduled)
                }
        }
        let activeEnrollment =
            eligibleEnrollments.first {
                $0.programID == focusedProgramID
            } ?? eligibleEnrollments.first
        let activeProgram = activeEnrollment.flatMap { enrollment in
            programs.first {
                $0.id == enrollment.programID
            }
        }
        if focusedProgramID == nil {
            focusedProgramID = activeProgram?.id
        }

        var enrollmentContexts: [ProgramEnrollmentContext] = []
        for enrollment in enrollments
        where enrollment.status == .active || enrollment.status == .completed {
            guard let program = programs.first(where: {
                $0.id == enrollment.programID
            }) else {
                continue
            }
            async let contextSubmissions =
                repositories.submissions.submissions(
                    enrollmentID: enrollment.id
                )
            async let contextWeighIns = repositories.weighIns.weighIns(
                enrollmentID: enrollment.id
            )
            async let contextLeaderboard =
                repositories.leaderboard.leaderboard(
                    programID: program.id
                )
            let entries = try await contextLeaderboard
            enrollmentContexts.append(
                ProgramEnrollmentContext(
                    enrollment: enrollment,
                    program: program,
                    submissions: try await contextSubmissions,
                    weighIns: try await contextWeighIns,
                    leaderboardEntry: entries.first {
                        $0.participantID == profile.id
                    }
                )
            )
        }
        let activeContext = activeEnrollment.flatMap { enrollment in
            enrollmentContexts.first { $0.enrollment.id == enrollment.id }
        }
        let submissions = activeContext?.submissions ?? []
        let weighIns = activeContext?.weighIns ?? []

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

        let featuredWinnerPosters = managedContent
            .filter {
                $0.kind == .winnerBanner
                    && ManagedContentValidator().isVisible(
                        $0,
                        at: environment.clock.now()
                    )
                    && $0.localMediaReference?.isEmpty == false
            }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.updatedAt > $1.updatedAt
                }
                return $0.sortOrder < $1.sortOrder
            }

        let nextSnapshot = ParticipantJourneySnapshot(
            user: user,
            profile: profile,
            programs: programs,
            enrollments: enrollments,
            enrollmentContexts: enrollmentContexts,
            activeProgram: activeProgram,
            activeEnrollment: activeEnrollment,
            submissions: submissions,
            weighIns: weighIns,
            leaderboard: leaderboard,
            winners: winners,
            featuredWinnerPosters: featuredWinnerPosters,
            coaches: try await coachesTask,
            managedContent: managedContent
        )
        state = .loaded(nextSnapshot)
        updateLeaderboardSelectionAfterJourneyLoad(
            snapshot: nextSnapshot
        )
    }

    private func reloadSnapshot() async throws {
        guard let repositories = environment.repositories,
              let currentSnapshot = snapshot else {
            throw DomainError.unknown
        }
        if let authenticatedReads =
            repositories.authenticatedParticipantReads {
            let readSnapshot = try await authenticatedReads.snapshot(
                user: currentSnapshot.user
            )
            let profile = try readSnapshot.account.participantProfile(
                userID: currentSnapshot.user.id
            )
            try await loadAuthenticatedSnapshot(
                repositories: repositories,
                user: currentSnapshot.user,
                profile: profile,
                readSnapshot: readSnapshot
            )
            return
        }
        let userID = currentSnapshot.user.id
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

    private func markingCurrentParticipant(
        in entries: [LeaderboardEntry],
        publicProfileID: UUID?
    ) -> [LeaderboardEntry] {
        entries.map { entry in
            LeaderboardEntry(
                id: entry.id,
                programID: entry.programID,
                participantID: entry.participantID,
                participantDisplayName: entry.participantDisplayName,
                rank: entry.rank,
                progressPercentage: entry.progressPercentage,
                score: entry.score,
                isCurrentUser: entry.participantID == publicProfileID
            )
        }
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

    private func updateLeaderboardSelectionAfterJourneyLoad(
        snapshot: ParticipantJourneySnapshot
    ) {
        let enrolledProgramIDs = Set(
            snapshot.enrollments.compactMap { enrollment in
                switch enrollment.status {
                case .active, .completed:
                    enrollment.programID
                case .initiated, .waitingForPayment, .cancelled,
                     .refunded:
                    nil
                }
            }
        )
        let eligibleProgramIDs: Set<UUID> = Set(
            snapshot.programs
                .filter { program in
                    enrolledProgramIDs.contains(program.id)
                        && (
                            program.status == .active
                                || program.status == .completed
                                || program.status == .archived
                        )
                }
                .map(\.id)
        )

        if let selectedLeaderboardProgramID,
           !eligibleProgramIDs.contains(selectedLeaderboardProgramID) {
            self.selectedLeaderboardProgramID = nil
            leaderboardState = .idle
        }

        guard selectedLeaderboardProgramID == nil,
              let activeProgram = snapshot.activeProgram else {
            if selectedLeaderboardProgramID == snapshot.activeProgram?.id,
               let activeProgram = snapshot.activeProgram {
                leaderboardState = .loaded(
                    ParticipantLeaderboardProgramSnapshot(
                        program: activeProgram,
                        entries: snapshot.leaderboard,
                        winners: snapshot.winners
                    )
                )
            }
            return
        }

        selectedLeaderboardProgramID = activeProgram.id
        leaderboardState = .loaded(
            ParticipantLeaderboardProgramSnapshot(
                program: activeProgram,
                entries: snapshot.leaderboard,
                winners: snapshot.winners
            )
        )
    }
}
