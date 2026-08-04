import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Coach experience Phase 04")
struct Phase04CoachTests {
    private let coachID = UUID(
        uuidString: "30000000-0000-0000-0000-000000000101"
    )!

    @MainActor
    @Test("Filter Coach mencakup pencarian, review, dan urutan")
    func coachFilters() async throws {
        let state = CoachParticipantsState(environment: .preview)
        await state.load()
        let participants = try loadedParticipants(from: state)
        #expect(participants.count == 6)

        state.query = "Ayu"
        #expect(state.filteredParticipants.map(\.profile.displayName) == [
            "Ayu Lestari"
        ])

        state.query = ""
        state.reviewFilter = .pending
        #expect(state.filteredParticipants.count == 2)
        #expect(
            state.filteredParticipants.allSatisfy {
                $0.pendingReviewCount > 0
            }
        )

        state.reviewFilter = .all
        state.sort = .points
        let points = state.filteredParticipants.map(\.points)
        #expect(points == points.sorted(by: >))

        state.prepare(for: .needsAttention)
        #expect(
            state.filteredParticipants.allSatisfy {
                $0.isFallingBehind
            }
        )

        let programID = try #require(participants.first?.program?.id)
        state.prepare(for: .program(programID))
        #expect(
            state.filteredParticipants.allSatisfy {
                $0.program?.id == programID
            }
        )

        state.prepare(for: .all)
        #expect(state.filteredParticipants.count == participants.count)

        let historyProgramID = UUID(
            uuidString: "10000000-0000-0000-0000-000000000004"
        )!
        #expect(
            state.availablePrograms.contains {
                $0.id == historyProgramID
            }
        )
        state.selectedProgramID = historyProgramID
        #expect(
            state.filteredParticipants.map(\.profile.displayName)
                == ["Ayu Lestari"]
        )
    }

    @MainActor
    @Test("Status perhatian membedakan pendaftaran dan progres")
    func attentionReasonDistinguishesEnrollmentAndProgress() async throws {
        let state = CoachParticipantsState(environment: .preview)
        await state.load()
        let participants = try loadedParticipants(from: state)
        let enrolledNotStarted = try #require(
            participants.first {
                $0.enrollment != nil && $0.progressPercentage == 0
            }
        )
        let enrolledBehind = try #require(
            participants.first {
                $0.enrollment != nil
                    && $0.progressPercentage > 0
                    && $0.isFallingBehind
            }
        )
        let notEnrolled = CoachParticipantSummary(
            profile: enrolledNotStarted.profile,
            enrollment: nil,
            program: nil,
            submissions: [],
            weighIns: [],
            leaderboardEntry: nil,
            associatedPrograms: []
        )
        var cancelledEnrollment = try #require(
            enrolledNotStarted.enrollment
        )
        cancelledEnrollment.status = .cancelled
        let cancelled = CoachParticipantSummary(
            profile: enrolledNotStarted.profile,
            enrollment: cancelledEnrollment,
            program: enrolledNotStarted.program,
            submissions: [],
            weighIns: [],
            leaderboardEntry: nil,
            associatedPrograms: enrolledNotStarted.associatedPrograms
        )

        #expect(notEnrolled.attentionReason == .notEnrolled)
        #expect(cancelled.attentionReason == .notEnrolled)
        #expect(enrolledNotStarted.attentionReason == .notStarted)
        #expect(enrolledBehind.attentionReason == .fallingBehind)
    }

    @MainActor
    @Test("Aktivitas Coach menampilkan hari ini sebelum riwayat")
    func activityDefaultsToTodayBeforeHistory() async throws {
        let state = CoachActivityState(environment: .preview)

        await state.load()

        let snapshot = try #require(state.snapshot)
        #expect(!snapshot.items.isEmpty)
        #expect(!state.filteredItems.isEmpty)
        #expect(
            state.filteredItems.allSatisfy {
                state.calendar.isDate(
                    $0.occurredAt,
                    inSameDayAs: state.referenceDate
                )
            }
        )
        #expect(state.sections.count == 1)
        #expect(state.hasOlderMatchingActivity)

        state.showPreviousActivity()

        #expect(state.timeRange == .lastThirtyDays)
        #expect(state.sections.count > 1)
        #expect(
            state.filteredItems.contains {
                !state.calendar.isDate(
                    $0.occurredAt,
                    inSameDayAs: state.referenceDate
                )
            }
        )
    }

    @MainActor
    @Test("Filter aktivitas memakai program dan jenis yang dipilih")
    func activityFiltersByProgramAndKind() async throws {
        let state = CoachActivityState(environment: .preview)
        await state.load()
        state.timeRange = .lastThirtyDays

        let evidence = state.filteredItems.filter {
            $0.kind == .evidenceSubmitted
        }
        let programID = try #require(evidence.first?.programID)

        state.kindFilter = .evidenceSubmitted
        state.selectedProgramID = programID

        #expect(!state.filteredItems.isEmpty)
        #expect(
            state.filteredItems.allSatisfy {
                $0.kind == .evidenceSubmitted
                    && $0.programID == programID
            }
        )
        #expect(
            state.filteredItems.contains {
                $0.requiresReview
            }
        )

        state.resetFilters()

        #expect(state.selectedProgramID == nil)
        #expect(state.kindFilter == .all)
        #expect(state.timeRange == .today)
    }

    @MainActor
    @Test("Profil Coach memuat identitas akun dan menyimpan data publik")
    func coachProfileLoadsAccountIdentityAndSavesPublicData() async throws {
        let environment = AppEnvironment.preview
        let state = CoachProfileState(environment: environment)

        await state.load()
        guard case .loaded(let initialSnapshot) = state.state else {
            Issue.record("Profil Coach gagal dimuat.")
            return
        }

        #expect(initialSnapshot.user.email == "coach@demo.local")
        #expect(initialSnapshot.profile.displayName == "Coach Raka")

        state.isPublic = false
        try await state.save(
            displayName: "Coach Raka Utama",
            biography: "Mendampingi kebiasaan aktif dengan konsisten.",
            city: "Badung",
            localPhotoReference: "/tmp/coach-profile.jpg"
        )

        guard case .loaded(let updatedSnapshot) = state.state else {
            Issue.record("Profil Coach gagal dimuat ulang.")
            return
        }

        #expect(updatedSnapshot.profile.displayName == "Coach Raka Utama")
        #expect(updatedSnapshot.profile.city == "Badung")
        #expect(
            updatedSnapshot.profile.biography
                == "Mendampingi kebiasaan aktif dengan konsisten."
        )
        #expect(
            updatedSnapshot.profile.localPhotoReference
                == "/tmp/coach-profile.jpg"
        )
        #expect(updatedSnapshot.profile.isPublic == false)
    }

    @MainActor
    @Test("Peringkat Coach menandai peserta dampingan")
    func leaderboardMarksAssignedParticipants() async throws {
        let state = CoachLeaderboardState(environment: .preview)

        await state.load()
        guard case .loaded(let snapshot) = state.state else {
            Issue.record("Peringkat Coach gagal dimuat.")
            return
        }

        let assignedEntries = snapshot.entries.filter {
            snapshot.assignedParticipantIDs.contains($0.participantID)
        }

        #expect(assignedEntries.count == 6)
        #expect(
            assignedEntries.allSatisfy {
                snapshot.assignedParticipantIDs.contains($0.participantID)
            }
        )
        #expect(
            assignedEntries
                .sorted { $0.rank < $1.rank }
                .map(\.participantDisplayName)
                == [
                    "Farhan Rizki",
                    "Citra Dewi",
                    "Eka Sari",
                    "Bima Putra",
                    "Dimas Arta",
                    "Ayu Lestari"
                ]
        )
    }

    @Test("Status program mengikuti rentang tanggal")
    func programLifecycleUsesReferenceDate() throws {
        var program = try #require(
            MockSeedData.load().programs.first {
                $0.status == .active
            }
        )

        #expect(
            program.lifecycleStatus(
                at: program.startDate.addingTimeInterval(-1)
            ) == .scheduled
        )
        #expect(
            program.lifecycleStatus(at: program.startDate) == .active
        )
        #expect(
            program.lifecycleStatus(
                at: program.endDate.addingTimeInterval(1)
            ) == .completed
        )

        program.status = .archived
        #expect(
            program.lifecycleStatus(at: program.startDate) == .archived
        )
    }

    @Test("Filter program memisahkan program berjalan dan riwayat")
    func programFilterSeparatesCurrentAndHistory() throws {
        let programs = try MockSeedData.load().programs
        let referenceDate = try Date.ISO8601FormatStyle().parse(
            "2026-08-01T00:00:00Z"
        )
        let selectedHistoryProgramID = UUID(
            uuidString: "10000000-0000-0000-0000-000000000005"
        )!

        let catalog = ProgramFilterCatalog(
            programs: programs,
            selectedProgramID: selectedHistoryProgramID,
            referenceDate: referenceDate
        )

        #expect(
            catalog.currentPrograms.map(\.title)
                == ["Gerak bersama Agustus"]
        )
        #expect(
            catalog.historyPrograms.map(\.title)
                == [
                    "Transformasi 7 hari",
                    "Gerak konsisten 3 hari",
                    "Konsisten Juni"
                ]
        )
        #expect(
            catalog.programsShownInMainPicker.map(\.title)
                == [
                    "Gerak bersama Agustus",
                    "Gerak konsisten 3 hari"
                ]
        )
        #expect(
            catalog.currentPrograms.allSatisfy {
                $0.status != .draft
            }
        )
    }

    @MainActor
    @Test("Coach dapat mengikuti program melalui alur peserta yang sama")
    func coachCanJoinProgramThroughSharedParticipantJourney() async throws {
        let environment = AppEnvironment.preview
        let repositories = try #require(environment.repositories)
        _ = try await repositories.session.switchDebugRole(to: .coach)
        let store = ParticipantJourneyStore(
            environment: environment,
            participationAccount: .coach
        )

        await store.load()

        let snapshot = try #require(store.snapshot)
        #expect(snapshot.user.role == .coach)
        #expect(
            snapshot.profile.userID
                == UUID(
                    uuidString: "00000000-0000-0000-0000-000000000101"
                )
        )
        let program = try #require(
            snapshot.programs.first { $0.status == .active }
        )
        let coach = try #require(
            snapshot.coaches.first {
                $0.id
                    == UUID(
                        uuidString:
                            "30000000-0000-0000-0000-000000000102"
                    )
            }
        )

        try await store.joinProgram(
            programID: program.id,
            with: coach
        )

        let joinedSnapshot = try #require(store.snapshot)
        let enrollment = try #require(
            joinedSnapshot.enrollments.first {
                $0.programID == program.id
            }
        )
        #expect(enrollment.participantID == joinedSnapshot.profile.id)
        #expect(enrollment.coachID == coach.id)
        #expect(store.currentProgram?.id == program.id)
        #expect(
            try await repositories.session.loadCurrentSession().role
                == .coach
        )
    }

    @Test("Penolakan wajib memiliki alasan")
    func rejectionReasonIsRequired() async throws {
        let repository = try makeRepository()
        let submission = try #require(
            try await repository.reviewQueue(coachID: coachID).first
        )
        let useCase = ReviewLocalSubmissionUseCase(
            repository: repository,
            clock: FixedClock(
                now: Date(timeIntervalSince1970: 1_785_028_400)
            )
        )

        do {
            _ = try await useCase(
                submissionID: submission.id,
                reviewerID: coachID,
                status: .rejected,
                note: "   "
            )
            Issue.record("Penolakan kosong seharusnya gagal.")
        } catch let error as DomainError {
            #expect(
                error == .validation(
                    field: "reviewNote",
                    reason: "Alasan penolakan wajib diisi."
                )
            )
        }
    }

    @MainActor
    @Test("Persetujuan menambah poin langkah tanpa menghapus skor historis")
    func approvalAddsExactStepPoints() async throws {
        let environment = AppEnvironment.preview
        let features = CoachFeatureContainer(environment: environment)
        await features.prepareIdentity()
        await features.reviewQueue.load()
        guard case .loaded(let items) = features.reviewQueue.state else {
            Issue.record("Antrean review gagal dimuat.")
            return
        }
        let item = try #require(items.first)

        try await features.review(
            item: item,
            status: .approved,
            note: nil
        )

        let result = try #require(features.reviewQueue.lastDecision)
        #expect(result.status == .approved)
        #expect(result.pointsAfter >= result.pointsBefore)
        #expect(
            try await environment.repositories?.submissions
                .submissions(enrollmentID: item.enrollment.id)
                .first { $0.id == item.submission.id }?.status
                == .approved
        )
    }

    @MainActor
    @Test("Pusat bukti memuat verifikasi manual dan poin otomatis")
    func evidenceHubIncludesManualAndAutomaticEvidence() async throws {
        let state = CoachReviewQueueState(environment: .preview)

        await state.load()
        guard case .loaded(let items) = state.state else {
            Issue.record("Pusat bukti gagal dimuat.")
            return
        }

        #expect(
            items.contains {
                $0.step.verificationMode == .coachReview
                    && $0.submission.status == .pending
            }
        )
        #expect(
            items.contains {
                $0.step.verificationMode == .automatic
                    && $0.submission.status == .approved
            }
        )
        #expect(items.allSatisfy { !$0.submission.typedAnswers.isEmpty })
    }

    @MainActor
    @Test("Rating Coach tersimpan tanpa mengubah status atau poin")
    func coachRatingIsIndependentFromApprovalAndPoints() async throws {
        let features = CoachFeatureContainer(environment: .preview)
        await features.prepareIdentity()
        await features.reviewQueue.load()
        guard case .loaded(let items) = features.reviewQueue.state else {
            Issue.record("Pusat bukti gagal dimuat.")
            return
        }
        let item = try #require(
            items.first {
                $0.step.verificationMode == .automatic
            }
        )
        let originalStatus = item.submission.status
        let originalPoints = item.scoreBeforeReview

        try await features.saveRating(item: item, rating: 4)

        guard case .loaded(let updatedItems) = features.reviewQueue.state else {
            Issue.record("Pusat bukti gagal dimuat ulang.")
            return
        }
        let updated = try #require(
            updatedItems.first { $0.id == item.id }
        )
        #expect(updated.submission.coachRating == 4)
        #expect(updated.submission.status == originalStatus)
        #expect(updated.scoreBeforeReview == originalPoints)
    }

    @Test("Rating Coach hanya menerima satu sampai lima bintang")
    func coachRatingRangeIsValidated() async throws {
        let repository = try makeRepository()
        let submission = try #require(
            try await repository.reviewQueue(coachID: coachID).first
        )
        let useCase = RateLocalSubmissionUseCase(repository: repository)

        do {
            _ = try await useCase(
                submissionID: submission.id,
                reviewerID: coachID,
                rating: 6
            )
            Issue.record("Rating di luar rentang seharusnya gagal.")
        } catch let error as DomainError {
            #expect(
                error == .validation(
                    field: "coachRating",
                    reason: "Penilaian harus antara 1 sampai 5 bintang."
                )
            )
        }
    }

    @MainActor
    @Test("Penolakan bukti pending tidak mengurangi poin")
    func rejectionKeepsScoreForPendingEvidence() async throws {
        let features = CoachFeatureContainer(environment: .preview)
        await features.prepareIdentity()
        await features.reviewQueue.load()
        guard case .loaded(let items) = features.reviewQueue.state else {
            Issue.record("Antrean review gagal dimuat.")
            return
        }
        let item = try #require(items.first)

        try await features.review(
            item: item,
            status: .rejected,
            note: "Bukti belum sesuai petunjuk."
        )

        let result = try #require(features.reviewQueue.lastDecision)
        #expect(result.status == .rejected)
        #expect(result.pointsAfter == result.pointsBefore)
    }

    @Test("Setiap coach memiliki identifier pendaftaran unik")
    func coachEnrollmentIdentifiersAreUnique() throws {
        let coaches = try MockSeedData.load().coachProfiles
        let identifiers = coaches.map(\.enrollmentIdentifier)

        #expect(identifiers.allSatisfy { !$0.isEmpty })
        #expect(Set(identifiers).count == coaches.count)
    }

    @Test("Enrollment melalui QR Coach tetap idempoten")
    func coachQREnrollmentIsIdempotent() async throws {
        let seed = try MockSeedData.load()
        let repository = try makeRepository()
        let existing = try #require(
            seed.enrollments.first {
                $0.coachID == coachID && $0.status == .active
            }
        )
        let duplicate = try await repository.createEnrollment(
            ProgramEnrollment(
                id: UUID(),
                programID: existing.programID,
                participantID: existing.participantID,
                coachID: coachID,
                status: .active,
                enrolledAt: existing.enrolledAt
            )
        )

        #expect(duplicate.id == existing.id)
    }

    @Test("Coach tidak dapat membuka peserta yang bukan assignment")
    func unrelatedParticipantAccessIsBlocked() async throws {
        let repository = try makeRepository()
        let unrelatedParticipantID = UUID(
            uuidString: "20000000-0000-0000-0000-000000000007"
        )!

        do {
            _ = try await repository.assignedParticipant(
                id: unrelatedParticipantID,
                coachID: coachID
            )
            Issue.record("Akses peserta Coach lain seharusnya ditolak.")
        } catch let error as DomainError {
            #expect(error == .permissionDenied)
        }
    }

    @MainActor
    private func loadedParticipants(
        from state: CoachParticipantsState
    ) throws -> [CoachParticipantSummary] {
        guard case .loaded(let participants) = state.state else {
            throw DomainError.unknown
        }
        return participants
    }

    private func makeRepository() throws -> InMemoryAppRepository {
        InMemoryAppRepository(seed: try MockSeedData.load())
    }
}
