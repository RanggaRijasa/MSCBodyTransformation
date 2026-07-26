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
    }

    private func validDraft() throws -> AdminProgramDraft {
        let seed = try MockSeedData.load()
        let program = try #require(
            seed.programs.first { $0.id == activeProgramID }
        )
        return AdminProgramDraft(program: program, updatedAt: fixedDate)
    }

    private func makeRepository() throws -> InMemoryAppRepository {
        InMemoryAppRepository(seed: try MockSeedData.load())
    }
}
