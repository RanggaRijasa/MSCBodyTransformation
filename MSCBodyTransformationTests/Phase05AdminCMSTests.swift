import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Admin CMS Phase 05")
struct Phase05AdminCMSTests {
    private let adminID = UUID(
        uuidString: "00000000-0000-0000-0000-000000000201"
    )!
    private let activeProgramID = UUID(
        uuidString: "10000000-0000-0000-0000-000000000001"
    )!
    private let fixedDate = Date(timeIntervalSince1970: 1_785_028_400)

    @Test("Akses cepat Dashboard tidak menduplikasi tab atau antrean")
    func dashboardQuickActionsAreUnique() {
        let titles = Set(
            AdminDashboardQuickAction.allCases.map(\.title)
        )
        let existingNavigationLabels: Set<String> = [
            "Dashboard",
            "Program",
            "Orang",
            "Konten",
            "Pengaturan",
            "Pemeriksaan tertunda",
            "Persetujuan Coach"
        ]

        #expect(
            AdminDashboardQuickAction.allCases
                == [.createProgram, .addWinnerPoster]
        )
        #expect(titles.isDisjoint(with: existingNavigationLabels))
    }

    @Test("Progres hub memisahkan masalah pengaturan dan konten")
    func programHubProgressGroupsValidationIssues() {
        let issues = [
            AdminValidationIssue(
                field: .title,
                message: "Nama program wajib diisi."
            ),
            AdminValidationIssue(
                field: .steps,
                message: "Tambahkan langkah aktif."
            )
        ]
        let progress = AdminProgramFlowProgress(issues: issues)

        #expect(progress.completedStageCount == 0)
        #expect(progress.issueCount(for: .settings) == 1)
        #expect(progress.issueCount(for: .content) == 1)
        #expect(progress.issueCount(for: .review) == 2)
        #expect(!progress.isComplete(.settings))
        #expect(!progress.isComplete(.content))
        #expect(!progress.isComplete(.review))
    }

    @Test("Hub valid menandai ketiga tahap siap")
    func validProgramHubMarksAllStagesReady() {
        let progress = AdminProgramFlowProgress(issues: [])

        #expect(progress.completedStageCount == 3)
        #expect(AdminProgramStage.allCases == [
            .settings,
            .content,
            .review
        ])
    }

    @Test("Validator editor menemukan field program yang belum valid")
    func programEditorValidation() throws {
        var draft = try validDraft()
        draft.title = " "
        draft.weightPointsPerKilogram = -1
        draft.days = []

        let fields = Set(
            AdminProgramDraftValidator().validate(draft).map(\.field)
        )

        #expect(fields.contains(.title))
        #expect(fields.contains(.scoring))
        #expect(fields.contains(.days))
    }

    @Test("Hari dibuat inklusif dari rentang tanggal")
    func dayGeneration() throws {
        let calendar = Calendar(identifier: .gregorian)
        let start = fixedDate
        let end = try #require(
            calendar.date(byAdding: .day, value: 2, to: start)
        )

        let days = try AdminProgramDraftValidator().generateDays(
            startDate: start,
            endDate: end,
            timeZoneIdentifier: "Asia/Makassar",
            programID: activeProgramID
        )

        #expect(days.map(\.dayNumber) == [1, 2, 3])
        #expect(Set(days.map(\.id)).count == 3)
    }

    @Test("ID langkah tetap unik pada program multi-hari")
    func multiDayStepIdentifiersAreUnique() throws {
        let calendar = Calendar(identifier: .gregorian)
        let end = try #require(
            calendar.date(byAdding: .day, value: 9, to: fixedDate)
        )
        let validator = AdminProgramDraftValidator()
        let days = try validator.generateDays(
            startDate: fixedDate,
            endDate: end,
            timeZoneIdentifier: "Asia/Makassar",
            programID: activeProgramID
        )
        let identifiers = days.map {
            validator.childIdentifier(parent: $0.id, discriminator: 1)
        }

        #expect(Set(identifiers).count == 10)
    }

    @Test("Sinkronisasi jadwal mempertahankan langkah dan pertanyaan")
    func scheduleSynchronizationPreservesNestedContent() throws {
        let validator = AdminProgramDraftValidator()
        let calendar = Calendar(identifier: .gregorian)
        let initialEnd = try #require(
            calendar.date(byAdding: .day, value: 1, to: fixedDate)
        )
        var days = try validator.generateDays(
            startDate: fixedDate,
            endDate: initialEnd,
            timeZoneIdentifier: "Asia/Makassar",
            programID: activeProgramID
        )
        let stepID = validator.childIdentifier(
            parent: days[0].id,
            discriminator: 1
        )
        days[0].steps = [
            AdminStepDraft(
                id: stepID,
                order: 1,
                title: "Refleksi",
                instructions: "Jawab sesuai kondisi hari ini.",
                points: 10,
                requiresPhoto: false,
                isPhotoRequired: false,
                requiresTextAnswer: false,
                isTextAnswerRequired: false,
                mediaKind: nil,
                localMediaReference: nil,
                isActive: true,
                verificationMode: .automatic,
                contentKind: .article,
                quiz: AdminQuizDraft(
                    title: "Refleksi",
                    questions: [
                        AdminQuizQuestionDraft(
                            id: validator.childIdentifier(
                                parent: stepID,
                                discriminator: 1_000
                            ),
                            order: 1,
                            kind: .shortAnswer,
                            prompt: "Apa yang terasa lebih mudah?",
                            isRequired: true,
                            options: []
                        )
                    ]
                )
            )
        ]
        let extendedEnd = try #require(
            calendar.date(byAdding: .day, value: 3, to: fixedDate)
        )

        let sync = try validator.synchronizeDays(
            existingDays: days,
            startDate: fixedDate,
            endDate: extendedEnd,
            timeZoneIdentifier: "Asia/Makassar",
            programID: activeProgramID
        )

        #expect(sync.days.count == 4)
        #expect(sync.days[0].id == days[0].id)
        #expect(sync.days[0].steps[0].id == stepID)
        #expect(
            sync.days[0].steps[0].quiz?.questions.first?.prompt
                == "Apa yang terasa lebih mudah?"
        )
        #expect(!sync.removesContent)

        let shiftedStart = try #require(
            calendar.date(byAdding: .day, value: 10, to: fixedDate)
        )
        let shiftedEnd = try #require(
            calendar.date(byAdding: .day, value: 13, to: fixedDate)
        )
        let shifted = try validator.synchronizeDays(
            existingDays: sync.days,
            startDate: shiftedStart,
            endDate: shiftedEnd,
            timeZoneIdentifier: "Asia/Makassar",
            programID: activeProgramID
        )
        #expect(shifted.days[0].id == days[0].id)
        #expect(shifted.days[0].steps[0].id == stepID)
        #expect(!shifted.removesContent)
    }

    @Test("Pemendekan jadwal melaporkan konten yang akan terhapus")
    func shorteningScheduleReportsRemovedContent() throws {
        let validator = AdminProgramDraftValidator()
        let calendar = Calendar(identifier: .gregorian)
        let end = try #require(
            calendar.date(byAdding: .day, value: 2, to: fixedDate)
        )
        var days = try validator.generateDays(
            startDate: fixedDate,
            endDate: end,
            timeZoneIdentifier: "Asia/Makassar",
            programID: activeProgramID
        )
        days[2].steps = [
            sampleStep(
                id: validator.childIdentifier(
                    parent: days[2].id,
                    discriminator: 1
                )
            )
        ]

        let sync = try validator.synchronizeDays(
            existingDays: days,
            startDate: fixedDate,
            endDate: fixedDate,
            timeZoneIdentifier: "Asia/Makassar",
            programID: activeProgramID
        )

        #expect(sync.days.count == 1)
        #expect(sync.removedDays.count == 2)
        #expect(sync.removesContent)
    }

    @Test("Normalisasi mempertahankan hasil reorder array")
    func normalizationPreservesReorderedHierarchy() throws {
        var draft = try validDraft()
        let originalDayIdentifiers = draft.days.map(\.id)
        draft.days.reverse()
        draft.days[0].steps.reverse()
        let expectedStepIdentifiers = draft.days[0].steps.map(\.id)
        let expectedOrders = expectedStepIdentifiers.isEmpty
            ? []
            : Array(1...expectedStepIdentifiers.count)

        let normalized = AdminProgramDraftValidator().normalized(draft)

        #expect(
            normalized.days.map(\.id)
                == Array(originalDayIdentifiers.reversed())
        )
        #expect(
            normalized.days[0].steps.map(\.id)
                == expectedStepIdentifiers
        )
        #expect(
            normalized.days[0].steps.map(\.order)
                == expectedOrders
        )
    }

    @Test("Rentang tanggal terbalik ditolak")
    func invalidDateRange() {
        do {
            _ = try AdminProgramDraftValidator().generateDays(
                startDate: fixedDate,
                endDate: fixedDate.addingTimeInterval(-86_400),
                timeZoneIdentifier: "Asia/Makassar",
                programID: activeProgramID
            )
            Issue.record("Rentang tanggal terbalik seharusnya gagal.")
        } catch let error as DomainError {
            #expect(
                error == .validation(
                    field: "dates",
                    reason: "Tanggal selesai tidak boleh sebelum mulai."
                )
            )
        } catch {
            Issue.record("Jenis error tidak sesuai.")
        }
    }

    @Test("Urutan langkah harus dimulai dari satu tanpa jeda")
    func stepOrderValidation() throws {
        var draft = try validDraft()
        draft.days[0].steps[0].order = 3

        let issues = AdminProgramDraftValidator().validate(draft)

        #expect(issues.contains { $0.field == .stepOrder })
    }

    @Test("Durasi tetap dinormalisasi dari jumlah hari")
    func fixedDurationNormalization() throws {
        var draft = try validDraft()
        draft.durationMode = .fixedDuration
        draft.fixedDurationDays = 15

        let normalized = AdminProgramDraftValidator().normalized(draft)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(
            TimeZone(identifier: draft.timeZoneIdentifier)
        )
        let difference = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: normalized.startDate),
            to: calendar.startOfDay(for: normalized.endDate)
        ).day

        #expect(difference == 14)
    }

    @Test("Cover dan batas peserta memiliki validasi aksesibilitas")
    func coverAndCapacityValidation() throws {
        var draft = try validDraft()
        draft.coverLocalReference = "cover_program"
        draft.coverAlternativeText = ""
        draft.participantLimit = 0

        let fields = Set(
            AdminProgramDraftValidator().validate(draft).map(\.field)
        )

        #expect(fields.contains(.cover))
        #expect(fields.contains(.access))
    }

    @Test("Kuis wajib memiliki nama dan pertanyaan")
    func quizContentValidation() throws {
        var draft = try validDraft()
        draft.days[0].steps[0].contentKind = .quiz
        draft.days[0].steps[0].quiz = AdminQuizDraft(
            title: "Kuis kebiasaan",
            questions: []
        )

        var issues = AdminProgramDraftValidator().validate(draft)
        #expect(issues.contains { $0.field == .content })

        draft.days[0].steps[0].quiz?.questions = [
            AdminQuizQuestionDraft(
                id: UUID(
                    uuidString:
                        "91000000-0000-0000-0000-000000000001"
                )!,
                order: 1,
                kind: .shortAnswer,
                prompt: "Apa fokusmu hari ini?",
                isRequired: true,
                options: []
            )
        ]
        issues = AdminProgramDraftValidator().validate(draft)
        #expect(!issues.contains { $0.field == .content })
    }

    @Test("Pertanyaan pilihan memerlukan pilihan unik dan terisi")
    func choiceQuestionValidation() throws {
        var draft = try validDraft()
        draft.days[0].steps[0].quiz = AdminQuizDraft(
            title: draft.days[0].steps[0].title,
            questions: [
                AdminQuizQuestionDraft(
                    id: UUID(
                        uuidString:
                            "91000000-0000-0000-0000-000000000002"
                    )!,
                    order: 1,
                    kind: .multipleChoice,
                    prompt: "Pilih kebiasaan yang sudah dilakukan.",
                    isRequired: true,
                    options: ["Minum air", " "]
                )
            ]
        )

        let issues = AdminProgramDraftValidator().validate(draft)

        #expect(issues.contains { $0.field == .content })
    }

    @Test("Program multi-hari menyimpan banyak langkah dan pertanyaan")
    func longProgramHierarchyPersists() async throws {
        let repository = try makeRepository()
        let validator = AdminProgramDraftValidator()
        let calendar = Calendar(identifier: .gregorian)
        let end = try #require(
            calendar.date(byAdding: .day, value: 4, to: fixedDate)
        )
        var draft = try validDraft()
        draft.status = .draft
        draft.startDate = fixedDate
        draft.endDate = end
        draft.days = try validator.generateDays(
            startDate: fixedDate,
            endDate: end,
            timeZoneIdentifier: draft.timeZoneIdentifier,
            programID: draft.id
        )

        for dayIndex in draft.days.indices {
            let dayID = draft.days[dayIndex].id
            draft.days[dayIndex].steps = (1...3).map { stepOrder in
                let stepID = validator.childIdentifier(
                    parent: dayID,
                    discriminator: stepOrder
                )
                let questions = (1...4).map { questionOrder in
                    AdminQuizQuestionDraft(
                        id: validator.childIdentifier(
                            parent: stepID,
                            discriminator: questionOrder + 1_000
                        ),
                        order: questionOrder,
                        kind: .shortAnswer,
                        prompt: "Pertanyaan \(questionOrder)",
                        isRequired: true,
                        options: []
                    )
                }
                return AdminStepDraft(
                    id: stepID,
                    order: stepOrder,
                    title: "Langkah \(stepOrder)",
                    instructions: "Petunjuk langkah.",
                    points: 10,
                    requiresPhoto: false,
                    isPhotoRequired: false,
                    requiresTextAnswer: false,
                    isTextAnswerRequired: false,
                    mediaKind: nil,
                    localMediaReference: nil,
                    isActive: true,
                    verificationMode: .automatic,
                    contentKind: .article,
                    quiz: AdminQuizDraft(
                        title: "Langkah \(stepOrder)",
                        questions: questions
                    )
                )
            }
        }

        let saved = try await SaveAdminProgramDraftUseCase(
            drafts: repository,
            audit: repository,
            identifierGenerator: DeterministicIdentifierGenerator(
                identifier: UUID(
                    uuidString:
                        "72000000-0000-0000-0000-000000000099"
                )!
            ),
            clock: FixedClock(now: fixedDate)
        )(draft: draft, adminID: adminID)
        let reloaded = try await repository
            .programDraftForAdministration(id: saved.id)
        let steps = reloaded.days.flatMap(\.steps)
        let questions = steps.flatMap {
            $0.quiz?.questions ?? []
        }

        #expect(reloaded.days.count == 5)
        #expect(steps.count == 15)
        #expect(questions.count == 60)
        #expect(Set(steps.map(\.id)).count == 15)
        #expect(Set(questions.map(\.id)).count == 60)
    }

    @Test("Publish memblokir draft invalid dan mencatat audit saat valid")
    func publishValidation() async throws {
        let repository = try makeRepository()
        var draft = try validDraft()
        draft.status = .draft
        let useCase = PublishAdminProgramDraftUseCase(
            drafts: repository,
            audit: repository,
            identifierGenerator: DeterministicIdentifierGenerator(
                identifier: UUID(
                    uuidString: "72000000-0000-0000-0000-000000000001"
                )!
            ),
            clock: FixedClock(now: fixedDate)
        )

        var invalid = draft
        invalid.days = []
        do {
            _ = try await useCase(draft: invalid, adminID: adminID)
            Issue.record("Draft tanpa hari seharusnya tidak dipublish.")
        } catch let error as DomainError {
            guard case .validation = error else {
                Issue.record("Error publish tidak sesuai.")
                return
            }
        }

        let published = try await useCase(draft: draft, adminID: adminID)
        let audits = try await repository.auditEventsForAdministration()
        #expect(published.status == .active)
        #expect(
            audits.contains {
                $0.kind == .programPublished
                    && $0.subjectID == draft.id
            }
        )
    }

    @Test("Enrollment manual wajib memiliki alasan")
    func manualEnrollmentReason() async throws {
        let repository = try makeRepository()
        let participantID = UUID(
            uuidString: "20000000-0000-0000-0000-000000000001"
        )!
        let scheduledProgramID = UUID(
            uuidString: "10000000-0000-0000-0000-000000000003"
        )!
        let useCase = ManualAdminEnrollmentUseCase(
            enrollments: repository,
            audit: repository,
            identifierGenerator: DeterministicIdentifierGenerator(
                identifier: UUID(
                    uuidString: "40000000-0000-0000-0000-000000009999"
                )!
            ),
            clock: FixedClock(now: fixedDate)
        )

        do {
            _ = try await useCase(
                programID: scheduledProgramID,
                participantID: participantID,
                coachID: nil,
                reason: " ",
                adminID: adminID
            )
            Issue.record("Alasan kosong seharusnya ditolak.")
        } catch let error as DomainError {
            #expect(
                error == .validation(
                    field: "reason",
                    reason: "Alasan enrollment manual wajib diisi."
                )
            )
        }
    }

    @Test("Penyesuaian skor wajib memiliki alasan")
    func scoreAdjustmentReason() async throws {
        let repository = try makeRepository()
        let entry = try #require(
            try await repository.leaderboard(
                programID: activeProgramID
            ).first
        )
        let useCase = AdjustAdminScoreUseCase(
            leaderboard: repository,
            audit: repository,
            identifierGenerator: DeterministicIdentifierGenerator(
                identifier: UUID(
                    uuidString: "72000000-0000-0000-0000-000000000002"
                )!
            ),
            clock: FixedClock(now: fixedDate)
        )

        do {
            _ = try await useCase(
                entryID: entry.id,
                points: 10,
                reason: "",
                adminID: adminID
            )
            Issue.record("Alasan kosong seharusnya ditolak.")
        } catch let error as DomainError {
            #expect(
                error == .validation(
                    field: "reason",
                    reason: "Alasan penyesuaian poin wajib diisi."
                )
            )
        }
    }

    @Test("Snapshot pemenang deterministik dan tidak berubah diam-diam")
    func winnerLockDeterminism() async throws {
        let repository = try makeRepository()
        let first = try await repository.lockTopFive(
            programID: activeProgramID,
            lockedAt: fixedDate
        )
        let lowestEntry = try #require(
            try await repository.leaderboard(
                programID: activeProgramID
            ).last
        )
        _ = try await repository.applyScoreAdjustment(
            entryID: lowestEntry.id,
            points: 1_000
        )
        let second = try await repository.lockTopFive(
            programID: activeProgramID,
            lockedAt: fixedDate.addingTimeInterval(100)
        )

        #expect(first.count == 5)
        #expect(first == second)
        #expect(first.map(\.rank) == [1, 2, 3, 4, 5])
    }

    @Test("Konten hanya terlihat dalam rentang aktif")
    func managedContentVisibility() {
        let content = ManagedContent(
            id: UUID(),
            kind: .winnerBanner,
            title: "Pemenang",
            body: "Selamat kepada para pemenang.",
            localMediaReference: "winner_local",
            programID: activeProgramID,
            visibleFrom: fixedDate.addingTimeInterval(-60),
            visibleUntil: fixedDate.addingTimeInterval(60),
            sortOrder: 1,
            isPublished: true,
            isArchived: false,
            updatedAt: fixedDate
        )
        let validator = ManagedContentValidator()

        #expect(validator.isVisible(content, at: fixedDate))
        #expect(
            !validator.isVisible(
                content,
                at: fixedDate.addingTimeInterval(120)
            )
        )
        var archived = content
        archived.isArchived = true
        #expect(!validator.isVisible(archived, at: fixedDate))

        var missingPoster = content
        missingPoster.localMediaReference = nil
        #expect(throws: DomainError.self) {
            try validator.validate(missingPoster)
        }
    }

    private func validDraft() throws -> AdminProgramDraft {
        let seed = try MockSeedData.load()
        let program = try #require(
            seed.programs.first { $0.id == activeProgramID }
        )
        var draft = AdminProgramDraft(
            program: program,
            updatedAt: fixedDate
        )
        if let lastScheduledDate = draft.days.last?.scheduledDate {
            draft.endDate = lastScheduledDate
        }
        draft.days = try AdminProgramDraftValidator().synchronizeDays(
            existingDays: draft.days,
            startDate: draft.startDate,
            endDate: draft.endDate,
            timeZoneIdentifier: draft.timeZoneIdentifier,
            programID: draft.id
        ).days
        return draft
    }

    private func sampleStep(id: UUID) -> AdminStepDraft {
        AdminStepDraft(
            id: id,
            order: 1,
            title: "Langkah contoh",
            instructions: "Ikuti petunjuk dengan aman.",
            points: 10,
            requiresPhoto: false,
            isPhotoRequired: false,
            requiresTextAnswer: false,
            isTextAnswerRequired: false,
            mediaKind: nil,
            localMediaReference: nil,
            isActive: true,
            verificationMode: .automatic
        )
    }

    private func makeRepository() throws -> InMemoryAppRepository {
        InMemoryAppRepository(seed: try MockSeedData.load())
    }
}
