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
        #expect(state.filteredParticipants.count == 3)
        #expect(
            state.filteredParticipants.allSatisfy {
                $0.pendingReviewCount > 0
            }
        )

        state.reviewFilter = .all
        state.sort = .points
        let points = state.filteredParticipants.map(\.points)
        #expect(points == points.sorted(by: >))
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
    @Test("Keputusan review menghitung ulang skor lokal")
    func reviewRecalculatesLocalScore() async throws {
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
        #expect(result.pointsAfter != result.pointsBefore)
        #expect(result.pointsAfter >= item.step.points)
    }

    @MainActor
    @Test("Penolakan menghitung ulang dan menghapus poin yang tidak sah")
    func rejectionRemovesLocallyAwardedPoints() async throws {
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
        #expect(result.pointsAfter < result.pointsBefore)
    }

    @Test("Membuat undangan tidak mengurangi kapasitas")
    func inviteCreationKeepsWalletBalance() async throws {
        let repository = try makeRepository()
        let walletBefore = try await repository.wallet(coachID: coachID)
        let programID = try #require(
            try await repository.activeProgram()?.id
        )
        let invite = try await GenerateLocalInviteUseCase(
            repository: repository,
            identifierGenerator: DeterministicIdentifierGenerator(
                identifier: UUID(
                    uuidString: "33000000-0000-0000-0000-000000009999"
                )!
            ),
            clock: FixedClock(
                now: Date(timeIntervalSince1970: 1_785_028_400)
            )
        )(
            coachID: coachID,
            programID: programID
        )
        let walletAfter = try await repository.wallet(coachID: coachID)

        #expect(invite.status == .active)
        #expect(
            walletAfter.availableSeatCredits
                == walletBefore.availableSeatCredits
        )
    }

    @Test("Enrollment lokal duplikat tidak memakai kuota tambahan")
    func duplicateInviteRedemptionIsIdempotent() async throws {
        let repository = try makeRepository()
        let participantID = UUID(
            uuidString: "20000000-0000-0000-0000-000000000001"
        )!
        let walletBefore = try await repository.wallet(coachID: coachID)

        let first = try await repository.redeemInvite(
            code: "MSC7HARI",
            participantID: participantID,
            enrollmentID: UUID(),
            now: Date(timeIntervalSince1970: 1_785_028_400)
        )
        let second = try await repository.redeemInvite(
            code: "MSC7HARI",
            participantID: participantID,
            enrollmentID: UUID(),
            now: Date(timeIntervalSince1970: 1_785_028_400)
        )
        let walletAfter = try await repository.wallet(coachID: coachID)

        #expect(first.id == second.id)
        #expect(
            walletAfter.availableSeatCredits
                == walletBefore.availableSeatCredits
        )
    }

    @Test("Redemption baru memakai tepat satu kuota setelah berhasil")
    func successfulRedemptionConsumesOneSeat() async throws {
        let repository = try makeRepository()
        let participantID = UUID(
            uuidString: "20000000-0000-0000-0000-000000009998"
        )!
        let enrollmentID = UUID(
            uuidString: "40000000-0000-0000-0000-000000009998"
        )!
        let walletBefore = try await repository.wallet(coachID: coachID)

        let enrollment = try await repository.redeemInvite(
            code: "MSC7HARI",
            participantID: participantID,
            enrollmentID: enrollmentID,
            now: Date(timeIntervalSince1970: 1_785_028_400)
        )
        let walletAfter = try await repository.wallet(coachID: coachID)

        #expect(enrollment.id == enrollmentID)
        #expect(
            walletAfter.availableSeatCredits
                == walletBefore.availableSeatCredits - 1
        )
    }

    @Test("Wallet nol memblokir redemption dan tidak menjadi negatif")
    func walletCannotBecomeNegative() async throws {
        let repository = try makeRepository()
        _ = try await repository.setSeatCredits(
            coachID: coachID,
            amount: 0,
            updatedAt: Date(timeIntervalSince1970: 1_785_028_400)
        )

        do {
            _ = try await repository.redeemInvite(
                code: "MSC7HARI",
                participantID: UUID(
                    uuidString: "20000000-0000-0000-0000-000000009999"
                )!,
                enrollmentID: UUID(),
                now: Date(timeIntervalSince1970: 1_785_028_400)
            )
            Issue.record("Redemption tanpa kuota seharusnya gagal.")
        } catch let error as DomainError {
            #expect(
                error == .conflict(
                    reason: "Kuota peserta tidak mencukupi."
                )
            )
        }

        let wallet = try await repository.wallet(coachID: coachID)
        #expect(wallet.availableSeatCredits == 0)
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

    @Test("Grant kuota demo menambah wallet tanpa StoreKit")
    func localDemoCreditGrant() async throws {
        let repository = try makeRepository()
        let before = try await repository.wallet(coachID: coachID)
        let after = try await repository.grantSeatCredits(
            coachID: coachID,
            amount: 10,
            grantedAt: Date(timeIntervalSince1970: 1_785_028_400)
        )

        #expect(
            after.availableSeatCredits
                == before.availableSeatCredits + 10
        )
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
