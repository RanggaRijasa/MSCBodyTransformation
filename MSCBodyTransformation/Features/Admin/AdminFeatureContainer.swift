import Foundation
import Observation
import SwiftUI

nonisolated struct AdminDashboardSnapshot: Sendable {
    let programCounts: [ProgramStatus: Int]
    let activeParticipantCount: Int
    let pendingCoachApprovals: Int
    let pendingReviews: Int
    let auditEvents: [AuditEvent]
}

nonisolated struct AdminPersonSummary: Identifiable, Sendable {
    let user: AppUser
    let participantProfile: ParticipantProfile?
    let coachProfile: CoachProfile?
    let coachApplication: CoachApplication?
    let enrollments: [ProgramEnrollment]

    var id: UUID { user.id }
}

nonisolated enum AdminPeopleScope: Equatable, Sendable {
    case all
    case pendingCoachApprovals
}

@MainActor
@Observable
final class AdminFeatureContainer {
    let environment: AppEnvironment

    var dashboardState: AsyncContentState<AdminDashboardSnapshot> = .idle
    var programsState: AsyncContentState<[AdminProgramDraft]> = .idle
    var peopleState: AsyncContentState<[AdminPersonSummary]> = .idle
    var contentState: AsyncContentState<[ManagedContent]> = .idle
    var leaderboardState: AsyncContentState<[LeaderboardEntry]> = .idle
    var winnersState: AsyncContentState<[ProgramWinner]> = .idle
    var programQuery = ""
    var programStatusFilter: ProgramStatus?
    var peopleScope: AdminPeopleScope = .all
    var lastMessage: String?

    private(set) var adminID: UUID?

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    var filteredPrograms: [AdminProgramDraft] {
        guard case .loaded(let programs) = programsState else {
            return []
        }
        let query = programQuery.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return programs.filter { program in
            (query.isEmpty
                || program.title.localizedCaseInsensitiveContains(query))
                && (programStatusFilter == nil
                    || program.status == programStatusFilter)
        }
    }

    var filteredPeople: [AdminPersonSummary] {
        guard case .loaded(let people) = peopleState else {
            return []
        }
        switch peopleScope {
        case .all:
            return people
        case .pendingCoachApprovals:
            return people.filter {
                $0.coachApplication?.status == .submitted
                    || $0.coachApplication?.status == .pendingAdminApproval
            }
        }
    }

    var nextWinnerPosterSortOrder: Int {
        guard case .loaded(let content) = contentState else {
            return 1
        }
        return (
            content
                .filter {
                    $0.kind == .winnerBanner && !$0.isArchived
                }
                .map(\.sortOrder)
                .max() ?? 0
        ) + 1
    }

    func load() async {
        dashboardState = .loading
        programsState = .loading
        peopleState = .loading
        contentState = .loading
        do {
            let repositories = try repositories()
            let session = try await repositories.session.loadCurrentSession()
            guard let user = session.user, user.role == .admin else {
                throw DomainError.permissionDenied
            }
            adminID = user.id

            async let programs = repositories.adminProgramDrafts
                .programDraftsForAdministration()
            async let users = repositories.adminPeople
                .usersForAdministration()
            async let participants = repositories.adminPeople
                .participantProfilesForAdministration()
            async let coaches = repositories.adminPeople
                .coachProfilesForAdministration()
            async let coachApplications = repositories.coachApplications
                .coachApplicationsForAdministration()
            async let enrollments = repositories.enrollments.allEnrollments()
            async let content = repositories.managedContent.managedContent()
            async let pendingReviews = repositories.submissions
                .pendingReviewCount()
            async let audits = repositories.audit
                .auditEventsForAdministration()

            let values = try await (
                programs,
                users,
                participants,
                coaches,
                coachApplications,
                enrollments,
                content,
                pendingReviews,
                audits
            )
            guard !Task.isCancelled else { return }

            let programValues = values.0
            let userValues = values.1
            let participantValues = values.2
            let coachValues = values.3
            let coachApplicationValues = values.4
            let enrollmentValues = values.5
            programsState = programValues.isEmpty
                ? .empty
                : .loaded(programValues)
            peopleState = userValues.isEmpty
                ? .empty
                : .loaded(
                    userValues.map { user in
                        let participant = participantValues.first {
                            $0.userID == user.id
                        }
                        return AdminPersonSummary(
                            user: user,
                            participantProfile: participant,
                            coachProfile: coachValues.first {
                                $0.userID == user.id
                            },
                            coachApplication:
                                coachApplicationValues.first {
                                    $0.userID == user.id
                                },
                            enrollments: participant.map { profile in
                                enrollmentValues.filter {
                                    $0.participantID == profile.id
                                }
                            } ?? []
                        )
                    }
                )
            contentState = values.6.isEmpty
                ? .empty
                : .loaded(values.6)

            let counts = Dictionary(
                grouping: programValues,
                by: \.status
            ).mapValues(\.count)
            let activeProgramIDs = Set(
                programValues.filter { $0.status == .active }.map(\.id)
            )
            dashboardState = .loaded(
                AdminDashboardSnapshot(
                    programCounts: counts,
                    activeParticipantCount: Set(
                        enrollmentValues.filter {
                            activeProgramIDs.contains($0.programID)
                                && $0.status == .active
                        }.map(\.participantID)
                    ).count,
                    pendingCoachApprovals: coachApplicationValues.filter {
                        $0.status == .submitted
                            || $0.status == .pendingAdminApproval
                    }.count,
                    pendingReviews: values.7,
                    auditEvents: Array(values.8.prefix(6))
                )
            )
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            failAll(with: error)
        } catch {
            failAll(with: .unknown)
        }
    }

    func createDraft() async throws -> AdminProgramDraft {
        let repositories = try repositories()
        let draft = try await CreateAdminProgramDraftUseCase(
            drafts: repositories.adminProgramDrafts,
            audit: repositories.audit,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock
        )(adminID: try requireAdminID())
        await load()
        return draft
    }

    @discardableResult
    func duplicate(
        _ source: AdminProgramDraft,
        request: DuplicateProgramRequest
    ) async throws -> AdminProgramDraft {
        let repositories = try repositories()
        let now = environment.clock.now()
        let duplicatedProgram = try DuplicateProgramAsDraftUseCase(
            identifierGenerator: environment.identifierGenerator
        )(
            source: source.program(),
            request: request
        )
        let duplicate = AdminProgramDraft(
            program: duplicatedProgram,
            updatedAt: now
        )
        _ = try await repositories.adminProgramDrafts.save(
            programDraft: duplicate
        )
        try await appendAudit(
            kind: .programCreated,
            subjectID: duplicate.id,
            summary: "Draft diduplikasi dari \(source.title)."
        )
        lastMessage = "Draft berhasil diduplikasi."
        await load()
        return duplicate
    }

    func archive(_ draft: AdminProgramDraft) async throws {
        var archived = draft
        archived.status = .archived
        archived.updatedAt = environment.clock.now()
        _ = try await repositories().adminProgramDrafts.save(
            programDraft: archived
        )
        try await appendAudit(
            kind: .programArchived,
            subjectID: draft.id,
            summary: "Program lokal diarsipkan."
        )
        lastMessage = "Program dipindahkan ke arsip."
        await load()
    }

    func approveCoach(applicationID: UUID) async throws {
        _ = try await repositories().coachApplications
            .approveCoachApplication(
                applicationID: applicationID,
                adminUserID: try requireAdminID(),
                decidedAt: environment.clock.now()
            )
        lastMessage = "Pengajuan Coach berhasil disetujui."
        await load()
    }

    func rejectCoach(
        applicationID: UUID,
        reason: String
    ) async throws {
        _ = try await repositories().coachApplications
            .rejectCoachApplication(
                applicationID: applicationID,
                adminUserID: try requireAdminID(),
                reason: reason,
                decidedAt: environment.clock.now()
            )
        lastMessage = "Pengajuan Coach ditolak."
        await load()
    }

    func approveLegacyCoach(userID: UUID) async throws {
        _ = try await repositories().adminPeople.setCoachApproval(
            userID: userID,
            isApproved: true
        )
        try await appendAudit(
            kind: .coachApproved,
            subjectID: userID,
            summary: "Coach disetujui dalam demo lokal."
        )
        lastMessage = "Coach berhasil disetujui."
        await load()
    }

    func setCoachPublic(
        _ profile: CoachProfile,
        isPublic: Bool
    ) async throws {
        var updated = profile
        updated.isPublic = isPublic
        _ = try await repositories().profiles.save(coachProfile: updated)
        try await appendAudit(
            kind: .coachVisibilityChanged,
            subjectID: profile.id,
            summary: isPublic
                ? "Profil Coach ditampilkan secara publik."
                : "Profil Coach disembunyikan dari direktori publik."
        )
        await load()
    }

    func manualEnroll(
        participant: ParticipantProfile,
        programID: UUID,
        reason: String
    ) async throws {
        let repositories = try repositories()
        if let operations = repositories.authoritativeAdminOperations {
            _ = try await operations.adminEnrollParticipant(
                programID: programID,
                participantID: participant.id,
                reason: reason
            )
            lastMessage = "Peserta berhasil didaftarkan."
            await load()
            return
        }
        let programDraft = try await repositories.adminProgramDrafts
            .programDraftForAdministration(id: programID)
        _ = try await ManualAdminEnrollmentUseCase(
            enrollments: repositories.enrollments,
            audit: repositories.audit,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock
        )(
            program: programDraft.program(),
            participantID: participant.id,
            coachID: participant.coachID,
            reason: reason,
            adminID: try requireAdminID()
        )
        lastMessage = "Peserta berhasil didaftarkan."
        await load()
    }

    func transferCoach(
        participant: ParticipantProfile,
        to coach: CoachProfile,
        reason: String
    ) async throws {
        let trimmedReason = reason.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedReason.isEmpty else {
            throw DomainError.validation(
                field: "reason",
                reason: "Alasan perubahan Coach wajib diisi."
            )
        }
        guard participant.coachID != coach.id else {
            throw DomainError.validation(
                field: "coach",
                reason: "Coach yang dipilih sudah aktif."
            )
        }
        let oldCoachName = participant.coachID.flatMap { coachID in
            guard case .loaded(let people) = peopleState else { return nil }
            return people.compactMap(\.coachProfile).first {
                $0.id == coachID
            }?.displayName
        } ?? "Belum ada Coach"
        let repositories = try repositories()
        if let operations = repositories.authoritativeAdminOperations {
            _ = try await operations.adminTransferCoach(
                participantID: participant.id,
                coachID: coach.id,
                reason: trimmedReason
            )
        } else {
            _ = try await repositories.adminPeople.transferActiveCoach(
                participantID: participant.id,
                coachID: coach.id
            )
        }
        try await appendAudit(
            kind: .coachTransferred,
            subjectID: participant.id,
            summary: "Coach \(oldCoachName) → \(coach.displayName). "
                + "Alasan: \(trimmedReason)"
        )
        lastMessage = "Coach peserta berhasil diperbarui."
        await load()
    }

    func loadLeaderboard(programID: UUID) async {
        leaderboardState = .loading
        winnersState = .loading
        do {
            let repositories = try repositories()
            async let entries = repositories.leaderboard.leaderboard(
                programID: programID
            )
            async let winners = repositories.leaderboard.winners(
                programID: programID
            )
            let values = try await (entries, winners)
            leaderboardState = values.0.isEmpty ? .empty : .loaded(values.0)
            winnersState = values.1.isEmpty ? .empty : .loaded(values.1)
        } catch let error as DomainError {
            leaderboardState = .failed(error)
            winnersState = .failed(error)
        } catch {
            leaderboardState = .failed(.unknown)
            winnersState = .failed(.unknown)
        }
    }

    func adjustScore(
        entryID: UUID,
        points: Int,
        reason: String
    ) async throws {
        let repositories = try repositories()
        let entry: LeaderboardEntry
        if let operations = repositories.authoritativeAdminOperations {
            entry = try await operations.adminAdjustScore(
                entryID: entryID,
                points: points,
                reason: reason
            )
        } else {
            entry = try await AdjustAdminScoreUseCase(
                leaderboard: repositories.leaderboard,
                audit: repositories.audit,
                identifierGenerator: environment.identifierGenerator,
                clock: environment.clock
            )(
                entryID: entryID,
                points: points,
                reason: reason,
                adminID: try requireAdminID()
            )
        }
        let locked = try await repositories.leaderboard.winners(
            programID: entry.programID
        )
        lastMessage = locked.isEmpty
            ? "Penyesuaian poin disimpan."
            : "Poin berubah, tetapi snapshot pemenang tetap terkunci."
        await loadLeaderboard(programID: entry.programID)
        await load()
    }

    func lockWinners(programID: UUID) async throws {
        let repositories = try repositories()
        let program = try await repositories.programs.program(id: programID)
        if let operations = repositories.authoritativeAdminOperations {
            _ = try await operations.completeAndLockWinners(
                programID: programID,
                reason: "Program diselesaikan dan pemenang dikunci oleh Admin."
            )
        } else {
            _ = try await LockAdminWinnersUseCase(
                leaderboard: repositories.leaderboard,
                enrollments: repositories.enrollments,
                submissions: repositories.submissions,
                weighIns: repositories.weighIns,
                audit: repositories.audit,
                identifierGenerator: environment.identifierGenerator,
                clock: environment.clock
            )(
                program: program,
                programID: programID,
                adminID: try requireAdminID()
            )
        }
        lastMessage = "Snapshot lima pemenang berhasil dikunci."
        await loadLeaderboard(programID: programID)
        await load()
    }

    func loadClosurePreflight(programID: UUID) async throws
        -> ProgramClosurePreflight {
        let repositories = try repositories()
        let program = try await repositories.programs.program(id: programID)
        return try await LoadProgramClosurePreflightUseCase(
            enrollments: repositories.enrollments,
            submissions: repositories.submissions,
            weighIns: repositories.weighIns
        )(program: program)
    }

    func failedQuizAttempts(
        programID: UUID
    ) async throws -> [AdminFailedQuizAttempt] {
        let repositories = try repositories()
        let program = try await repositories.programs.program(id: programID)
        let profiles = try await repositories.adminPeople
            .participantProfilesForAdministration()
        let profilesByID = Dictionary(
            uniqueKeysWithValues: profiles.map { ($0.id, $0) }
        )
        let stepsByID = Dictionary(
            uniqueKeysWithValues: program.days
                .flatMap(\.steps)
                .map { ($0.id, $0) }
        )
        let enrollments = try await repositories.enrollments.allEnrollments()
            .filter { $0.programID == programID }
        var items: [AdminFailedQuizAttempt] = []
        for enrollment in enrollments {
            let submissions = try await repositories.submissions.submissions(
                enrollmentID: enrollment.id
            )
            items.append(
                contentsOf: submissions.compactMap { submission in
                    guard let result = submission.quizResult,
                          !result.isPassed,
                          result.reopenedAt == nil else {
                        return nil
                    }
                    return AdminFailedQuizAttempt(
                        submissionID: submission.id,
                        enrollmentID: enrollment.id,
                        participantName:
                            profilesByID[enrollment.participantID]?
                                .displayName ?? "Peserta",
                        stepTitle:
                            stepsByID[submission.stepID]?.title ?? "Kuis",
                        sequence: result.sequence
                    )
                }
            )
        }
        return items.sorted {
            if $0.participantName == $1.participantName {
                return $0.stepTitle < $1.stepTitle
            }
            return $0.participantName < $1.participantName
        }
    }

    func reopenQuizAttempt(
        _ item: AdminFailedQuizAttempt,
        reason: String
    ) async throws {
        let repositories = try repositories()
        guard let submission = try await repositories.submissions
            .submissions(enrollmentID: item.enrollmentID)
            .first(where: { $0.id == item.submissionID }) else {
            throw DomainError.notFound(resource: "quiz_attempt")
        }
        _ = try await ReopenQuizAttemptUseCase(
            submissions: repositories.submissions,
            audit: repositories.audit,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock
        )(
            enrollmentID: item.enrollmentID,
            stepID: submission.stepID,
            adminID: try requireAdminID(),
            reason: reason
        )
        lastMessage = "Satu percobaan kuis baru sudah dibuka."
        await load()
    }

#if DEBUG
    func resetLockedWinners(programID: UUID) async {
        guard let repositories = try? repositories() else { return }
        await repositories.leaderboard.resetLockedWinnersForDebug(
            programID: programID
        )
        lastMessage = "Snapshot pemenang lokal direset."
        await loadLeaderboard(programID: programID)
    }
#endif

    func saveContent(_ content: ManagedContent) async throws {
        try ManagedContentValidator().validate(content)
        _ = try await repositories().managedContent.save(content: content)
        try await appendAudit(
            kind: .managedContentUpdated,
            subjectID: content.id,
            summary: content.isArchived
                ? "Konten lokal diarsipkan."
                : "Konten lokal diperbarui."
        )
        lastMessage = "Konten berhasil disimpan."
        await load()
    }

    func makeWinnerBanner(
        programID: UUID?,
        winnerSnapshotID: UUID? = nil,
        sortOrder: Int = 1
    ) -> ManagedContent {
        let now = environment.clock.now()
        return ManagedContent(
            id: environment.identifierGenerator.makeIdentifier(),
            kind: .winnerBanner,
            title: "Selamat kepada para pemenang",
            body: "Lihat peserta dengan perolehan poin tertinggi.",
            localMediaReference: nil,
            programID: programID,
            winnerSnapshotID: winnerSnapshotID,
            visibleFrom: now,
            visibleUntil: Calendar(identifier: .gregorian).date(
                byAdding: .month,
                value: 1,
                to: now
            ),
            sortOrder: sortOrder,
            isPublished: true,
            isArchived: false,
            updatedAt: now
        )
    }

    private func appendAudit(
        kind: AuditEventKind,
        subjectID: UUID,
        summary: String
    ) async throws {
        _ = try await repositories().audit.append(
            auditEvent: AuditEvent(
                id: environment.identifierGenerator.makeIdentifier(),
                kind: kind,
                actorUserID: try requireAdminID(),
                subjectID: subjectID,
                summary: summary,
                createdAt: environment.clock.now()
            )
        )
    }

    private func repositories() throws -> AppRepositories {
        guard let repositories = environment.repositories else {
            throw environment.bootstrapError ?? DomainError.unknown
        }
        return repositories
    }

    private func requireAdminID() throws -> UUID {
        guard let adminID else {
            throw DomainError.permissionDenied
        }
        return adminID
    }

    private func failAll(with error: DomainError) {
        dashboardState = .failed(error)
        programsState = .failed(error)
        peopleState = .failed(error)
        contentState = .failed(error)
    }
}

@MainActor
@Observable
final class AdminProgramEditorState {
    private let programID: UUID
    private let features: AdminFeatureContainer

    var draft: AdminProgramDraft?
    var issues: [AdminValidationIssue] = []
    var error: DomainError?
    var isSaving = false
    var didPublish = false
    private var hasLoaded = false

    init(programID: UUID, features: AdminFeatureContainer) {
        self.programID = programID
        self.features = features
    }

    func load() async {
        guard !hasLoaded else { return }
        do {
            guard let repositories = features.environment.repositories else {
                throw features.environment.bootstrapError
                    ?? DomainError.unknown
            }
            draft = try await repositories.adminProgramDrafts
                .programDraftForAdministration(id: programID)
            hasLoaded = true
            updateValidation()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    var scheduleSyncRemovesContent: Bool {
        scheduleSyncPlan?.removesContent == true
    }

    var isScheduleSynchronized: Bool {
        guard let draft,
              let plan = scheduleSyncPlan else {
            return false
        }
        let calendar = configuredCalendar(for: draft)
        return plan.days.map {
            calendar.startOfDay(for: $0.scheduledDate)
        } == draft.days.map {
            calendar.startOfDay(for: $0.scheduledDate)
        }
    }

    func synchronizeDays() {
        guard var draft else { return }
        do {
            draft = AdminProgramDraftValidator().normalized(draft)
            draft.days = try AdminProgramDraftValidator().synchronizeDays(
                existingDays: draft.days,
                startDate: draft.startDate,
                endDate: draft.endDate,
                timeZoneIdentifier: draft.timeZoneIdentifier,
                programID: draft.id
            ).days
            self.draft = draft
            updateValidation()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    func appendDay() {
        guard var draft else { return }
        draft.days.append(
            AdminDayDraft(
                id: availableIdentifier(
                    parent: draft.id,
                    startingAt: draft.days.count + 1,
                    excluding: Set(draft.days.map(\.id))
                ),
                dayNumber: draft.days.count + 1,
                title: "Hari ke-\(draft.days.count + 1)",
                summary: "",
                scheduledDate: draft.endDate,
                steps: []
            )
        )
        alignScheduleToDayCount(&draft)
        self.draft = AdminProgramDraftValidator().normalized(draft)
        updateValidation()
    }

    func addStep(
        to dayID: UUID,
        contentKind: AdminStepContentKind = .article
    ) {
        guard var draft,
              let dayIndex = draft.days.firstIndex(where: {
                  $0.id == dayID
              }) else { return }
        let order = draft.days[dayIndex].steps.count + 1
        let id = availableIdentifier(
            parent: dayID,
            startingAt: order,
            excluding: Set(draft.days.flatMap(\.steps).map(\.id))
        )
        let title: String
        switch contentKind {
        case .article:
            title = "Artikel baru"
        case .video:
            title = "Video baru"
        case .form:
            title = "Form baru"
        case .quiz:
            title = "Kuis baru"
        case .initialWeighIn:
            title = "Timbang awal"
        case .dailyWeighIn:
            title = "Timbang harian"
        case .finalWeighIn:
            title = "Timbang akhir"
        }
        draft.days[dayIndex].steps.append(
            AdminStepDraft(
                id: id,
                order: order,
                title: title,
                instructions: "Tambahkan petunjuk yang jelas dan aman.",
                mediaKind: contentKind == .video ? .video : nil,
                localMediaReference: nil,
                isActive: true,
                verificationMode: contentKind.isWeighIn
                    ? .automatic
                    : draft.verificationMode,
                contentKind: contentKind,
                quiz: contentKind == .quiz || contentKind == .form
                    ? AdminQuizDraft(title: title, questions: [])
                    : nil
            )
        )
        self.draft = draft
        updateValidation()
    }

    func duplicateDay(_ dayID: UUID) {
        guard var draft,
              let sourceIndex = draft.days.firstIndex(where: {
                  $0.id == dayID
              }) else { return }
        let source = draft.days[sourceIndex]
        let number = sourceIndex + 2
        let id = availableIdentifier(
            parent: draft.id,
            startingAt: draft.days.count + 1,
            excluding: Set(draft.days.map(\.id))
        )
        let duplicatedSteps = source.steps.enumerated().map {
            stepIndex, step in
            let stepID = AdminProgramDraftValidator().childIdentifier(
                parent: id,
                discriminator: stepIndex + 1
            )
            return AdminDraftContentDuplicator().duplicatedStep(
                step,
                id: stepID,
                order: stepIndex + 1
            )
        }
        draft.days.insert(
            AdminDayDraft(
                id: id,
                dayNumber: number,
                title: "\(source.title) — salinan",
                summary: source.summary,
                scheduledDate: source.scheduledDate,
                steps: duplicatedSteps
            ),
            at: sourceIndex + 1
        )
        alignScheduleToDayCount(&draft)
        self.draft = AdminProgramDraftValidator().normalized(draft)
        updateValidation()
    }

    func duplicateStep(_ stepID: UUID, in dayID: UUID) {
        guard var draft,
              let dayIndex = draft.days.firstIndex(where: {
                  $0.id == dayID
              }),
              let source = draft.days[dayIndex].steps.first(where: {
                  $0.id == stepID
              }) else { return }
        let order = draft.days[dayIndex].steps.count + 1
        let id = availableIdentifier(
            parent: dayID,
            startingAt: order,
            excluding: Set(draft.days.flatMap(\.steps).map(\.id))
        )
        draft.days[dayIndex].steps.append(
            AdminDraftContentDuplicator().duplicatedStep(
                source,
                id: id,
                order: order,
                title: "\(source.title) — salinan"
            )
        )
        self.draft = draft
        updateValidation()
    }

    func copyDayContent(
        from sourceDayID: UUID,
        to targetDayIDs: Set<UUID>
    ) {
        guard let draft else { return }
        do {
            self.draft = try AdminDayContentCopyService()(
                draft: draft,
                sourceDayID: sourceDayID,
                targetDayIDs: targetDayIDs
            )
            error = nil
            updateValidation()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    func removeDay(_ dayID: UUID) {
        guard var draft else { return }
        draft.days.removeAll { $0.id == dayID }
        alignScheduleToDayCount(&draft)
        self.draft = AdminProgramDraftValidator().normalized(draft)
        updateValidation()
    }

    func removeStep(_ stepID: UUID, from dayID: UUID) {
        guard var draft,
              let dayIndex = draft.days.firstIndex(where: {
                  $0.id == dayID
              }) else { return }
        draft.days[dayIndex].steps.removeAll { $0.id == stepID }
        self.draft = AdminProgramDraftValidator().normalized(draft)
        updateValidation()
    }

    func moveDay(from offsets: IndexSet, to destination: Int) {
        guard var draft else { return }
        draft.days.move(fromOffsets: offsets, toOffset: destination)
        alignScheduleToDayCount(&draft)
        self.draft = AdminProgramDraftValidator().normalized(draft)
        updateValidation()
    }

    func moveStep(
        dayID: UUID,
        from offsets: IndexSet,
        to destination: Int
    ) {
        guard var draft,
              let dayIndex = draft.days.firstIndex(where: {
                  $0.id == dayID
              }) else { return }
        draft.days[dayIndex].steps.move(
            fromOffsets: offsets,
            toOffset: destination
        )
        self.draft = AdminProgramDraftValidator().normalized(draft)
        updateValidation()
    }

    func save() async {
        guard let draft,
              let repositories = features.environment.repositories,
              let adminID = features.adminID else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            self.draft = try await SaveAdminProgramDraftUseCase(
                drafts: repositories.adminProgramDrafts,
                audit: repositories.audit,
                identifierGenerator:
                    features.environment.identifierGenerator,
                clock: features.environment.clock
            )(draft: draft, adminID: adminID)
            error = nil
            await features.load()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    func publish() async {
        guard let draft,
              let repositories = features.environment.repositories,
              let adminID = features.adminID else { return }
        updateValidation()
        guard issues.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            self.draft = try await PublishAdminProgramDraftUseCase(
                drafts: repositories.adminProgramDrafts,
                audit: repositories.audit,
                identifierGenerator:
                    features.environment.identifierGenerator,
                clock: features.environment.clock
            )(draft: draft, adminID: adminID)
            didPublish = true
            error = nil
            await features.load()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    func updateValidation() {
        guard let draft else {
            issues = []
            return
        }
        issues = AdminProgramDraftValidator().validate(draft)
    }

    private var scheduleSyncPlan: AdminDayScheduleSync? {
        guard let draft else { return nil }
        let normalized = AdminProgramDraftValidator().normalized(draft)
        return try? AdminProgramDraftValidator().synchronizeDays(
            existingDays: normalized.days,
            startDate: normalized.startDate,
            endDate: normalized.endDate,
            timeZoneIdentifier: normalized.timeZoneIdentifier,
            programID: normalized.id
        )
    }

    private func availableIdentifier(
        parent: UUID,
        startingAt value: Int,
        excluding identifiers: Set<UUID>
    ) -> UUID {
        var discriminator = value
        while true {
            let identifier = AdminProgramDraftValidator().childIdentifier(
                parent: parent,
                discriminator: discriminator
            )
            if !identifiers.contains(identifier) {
                return identifier
            }
            discriminator += 1
        }
    }

    private func alignScheduleToDayCount(
        _ draft: inout AdminProgramDraft
    ) {
        let count = draft.days.count
        draft.fixedDurationDays = max(count, 1)
        let calendar = configuredCalendar(for: draft)
        draft.endDate = calendar.date(
            byAdding: .day,
            value: max(count - 1, 0),
            to: draft.startDate
        ) ?? draft.endDate
        for index in draft.days.indices {
            draft.days[index].dayNumber = index + 1
            draft.days[index].scheduledDate = calendar.date(
                byAdding: .day,
                value: index,
                to: draft.startDate
            ) ?? draft.days[index].scheduledDate
        }
    }

    private func configuredCalendar(
        for draft: AdminProgramDraft
    ) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(
            identifier: draft.timeZoneIdentifier
        ) ?? .gmt
        return calendar
    }
}
