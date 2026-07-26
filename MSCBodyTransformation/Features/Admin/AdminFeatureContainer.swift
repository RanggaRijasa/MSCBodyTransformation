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
    let enrollments: [ProgramEnrollment]

    var id: UUID { user.id }
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
            let enrollmentValues = values.4
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
                            enrollments: participant.map { profile in
                                enrollmentValues.filter {
                                    $0.participantID == profile.id
                                }
                            } ?? []
                        )
                    }
                )
            contentState = values.5.isEmpty
                ? .empty
                : .loaded(values.5)

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
                    pendingCoachApprovals: userValues.filter(
                        \.isCoachApprovalPending
                    ).count,
                    pendingReviews: values.6,
                    auditEvents: Array(values.7.prefix(6))
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

    func duplicate(_ source: AdminProgramDraft) async throws {
        let repositories = try repositories()
        let now = environment.clock.now()
        let newID = environment.identifierGenerator.makeIdentifier()
        let validator = AdminProgramDraftValidator()
        let days = source.days.enumerated().map { dayIndex, day in
            let dayID = validator.childIdentifier(
                parent: newID,
                discriminator: dayIndex + 1
            )
            return AdminDayDraft(
                id: dayID,
                dayNumber: dayIndex + 1,
                title: day.title,
                summary: day.summary,
                scheduledDate: day.scheduledDate,
                steps: day.steps.enumerated().map { stepIndex, step in
                    AdminStepDraft(
                        id: validator.childIdentifier(
                            parent: dayID,
                            discriminator: stepIndex + 1
                        ),
                        order: stepIndex + 1,
                        title: step.title,
                        instructions: step.instructions,
                        points: step.points,
                        requiresPhoto: step.requiresPhoto,
                        isPhotoRequired: step.isPhotoRequired,
                        requiresTextAnswer: step.requiresTextAnswer,
                        isTextAnswerRequired: step.isTextAnswerRequired,
                        mediaKind: step.mediaKind,
                        localMediaReference: step.localMediaReference,
                        isActive: step.isActive,
                        verificationMode: step.verificationMode
                    )
                }
            )
        }
        let duplicate = AdminProgramDraft(
            id: newID,
            title: "\(source.title) — salinan",
            summary: source.summary,
            coverLocalReference: source.coverLocalReference,
            verificationMode: source.verificationMode,
            wellnessDisclaimer: source.wellnessDisclaimer,
            startDate: source.startDate,
            endDate: source.endDate,
            timeZoneIdentifier: source.timeZoneIdentifier,
            initialWeighInWindowHours:
                source.initialWeighInWindowHours,
            finalWeighInWindowHours: source.finalWeighInWindowHours,
            weightPointsPerKilogram: source.weightPointsPerKilogram,
            pastStepPolicy: source.pastStepPolicy,
            futureStepPolicy: source.futureStepPolicy,
            status: .draft,
            days: days,
            updatedAt: now
        )
        _ = try await repositories.adminProgramDrafts.save(
            programDraft: duplicate
        )
        try await appendAudit(
            kind: .programCreated,
            subjectID: newID,
            summary: "Draft program lokal diduplikasi."
        )
        lastMessage = "Draft berhasil diduplikasi."
        await load()
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

    func approveCoach(userID: UUID) async throws {
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
        _ = try await ManualAdminEnrollmentUseCase(
            enrollments: repositories.enrollments,
            audit: repositories.audit,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock
        )(
            programID: programID,
            participantID: participant.id,
            coachID: participant.coachID,
            reason: reason,
            adminID: try requireAdminID()
        )
        lastMessage = "Peserta berhasil didaftarkan."
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
        let entry = try await AdjustAdminScoreUseCase(
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
        _ = try await LockAdminWinnersUseCase(
            leaderboard: repositories.leaderboard,
            audit: repositories.audit,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock
        )(
            programID: programID,
            adminID: try requireAdminID()
        )
        lastMessage = "Snapshot lima pemenang berhasil dikunci."
        await loadLeaderboard(programID: programID)
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

    func makeWinnerBanner(programID: UUID?) -> ManagedContent {
        let now = environment.clock.now()
        return ManagedContent(
            id: environment.identifierGenerator.makeIdentifier(),
            kind: .winnerBanner,
            title: "Selamat kepada para pemenang",
            body: "Lihat peserta dengan perolehan poin tertinggi.",
            localMediaReference: "winner_banner_local",
            programID: programID,
            visibleFrom: now,
            visibleUntil: Calendar(identifier: .gregorian).date(
                byAdding: .month,
                value: 1,
                to: now
            ),
            sortOrder: 1,
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
    enum Stage: Int, CaseIterable, Identifiable {
        case basics
        case dates
        case scoring
        case days
        case steps
        case preview
        case publish

        var id: Int { rawValue }
    }

    private let programID: UUID
    private let features: AdminFeatureContainer

    var stage: Stage = .basics
    var draft: AdminProgramDraft?
    var issues: [AdminValidationIssue] = []
    var error: DomainError?
    var isSaving = false
    var didPublish = false

    init(programID: UUID, features: AdminFeatureContainer) {
        self.programID = programID
        self.features = features
    }

    func load() async {
        do {
            guard let repositories = features.environment.repositories else {
                throw features.environment.bootstrapError
                    ?? DomainError.unknown
            }
            draft = try await repositories.adminProgramDrafts
                .programDraftForAdministration(id: programID)
            updateValidation()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    func generateDays() {
        guard var draft else { return }
        do {
            draft.days = try AdminProgramDraftValidator().generateDays(
                startDate: draft.startDate,
                endDate: draft.endDate,
                timeZoneIdentifier: draft.timeZoneIdentifier,
                programID: draft.id
            )
            self.draft = draft
            updateValidation()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    func addStep(to dayID: UUID) {
        guard var draft,
              let dayIndex = draft.days.firstIndex(where: {
                  $0.id == dayID
              }) else { return }
        let order = draft.days[dayIndex].steps.count + 1
        let id = AdminProgramDraftValidator().childIdentifier(
            parent: dayID,
            discriminator: order
        )
        draft.days[dayIndex].steps.append(
            AdminStepDraft(
                id: id,
                order: order,
                title: "Langkah baru",
                instructions: "Tambahkan petunjuk yang jelas dan aman.",
                points: 10,
                requiresPhoto: false,
                isPhotoRequired: false,
                requiresTextAnswer: false,
                isTextAnswerRequired: false,
                mediaKind: nil,
                localMediaReference: nil,
                isActive: true,
                verificationMode: draft.verificationMode
            )
        )
        self.draft = draft
        updateValidation()
    }

    func duplicateDay(_ dayID: UUID) {
        guard var draft,
              let source = draft.days.first(where: { $0.id == dayID }),
              let last = draft.days.sorted(by: {
                  $0.dayNumber < $1.dayNumber
              }).last else { return }
        let number = last.dayNumber + 1
        let id = AdminProgramDraftValidator().childIdentifier(
            parent: draft.id,
            discriminator: number
        )
        let date = Calendar(identifier: .gregorian).date(
            byAdding: .day,
            value: 1,
            to: last.scheduledDate
        ) ?? last.scheduledDate
        draft.days.append(
            AdminDayDraft(
                id: id,
                dayNumber: number,
                title: "\(source.title) — salinan",
                summary: source.summary,
                scheduledDate: date,
                steps: source.steps.enumerated().map { index, step in
                    AdminStepDraft(
                        id: AdminProgramDraftValidator().childIdentifier(
                            parent: id,
                            discriminator: index + 1
                        ),
                        order: index + 1,
                        title: step.title,
                        instructions: step.instructions,
                        points: step.points,
                        requiresPhoto: step.requiresPhoto,
                        isPhotoRequired: step.isPhotoRequired,
                        requiresTextAnswer: step.requiresTextAnswer,
                        isTextAnswerRequired: step.isTextAnswerRequired,
                        mediaKind: step.mediaKind,
                        localMediaReference: step.localMediaReference,
                        isActive: step.isActive,
                        verificationMode: step.verificationMode
                    )
                }
            )
        )
        draft.endDate = max(draft.endDate, date)
        self.draft = draft
        updateValidation()
    }

    func removeDay(_ dayID: UUID) {
        guard var draft else { return }
        draft.days.removeAll { $0.id == dayID }
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
}
