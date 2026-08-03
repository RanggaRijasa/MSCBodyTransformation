import Foundation

nonisolated struct ReviewLocalSubmissionUseCase: Sendable {
    let repository: any SubmissionRepository
    let clock: any AppClock

    func callAsFunction(
        submissionID: UUID,
        reviewerID: UUID,
        status: SubmissionStatus,
        note: String?
    ) async throws -> StepSubmission {
        guard status == .approved || status == .rejected else {
            throw DomainError.validation(
                field: "status",
                reason: "Pemeriksaan harus disetujui atau ditolak."
            )
        }
        let trimmedNote = note?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if status == .rejected, trimmedNote?.isEmpty != false {
            throw DomainError.validation(
                field: "reviewNote",
                reason: "Alasan penolakan wajib diisi."
            )
        }
        return try await repository.reviewSubmission(
            id: submissionID,
            reviewerID: reviewerID,
            status: status,
            note: trimmedNote?.isEmpty == false ? trimmedNote : nil,
            reviewedAt: clock.now()
        )
    }
}

nonisolated struct RateLocalSubmissionUseCase: Sendable {
    let repository: any SubmissionRepository

    func callAsFunction(
        submissionID: UUID,
        reviewerID: UUID,
        rating: Int
    ) async throws -> StepSubmission {
        guard (1...5).contains(rating) else {
            throw DomainError.validation(
                field: "coachRating",
                reason: "Penilaian harus antara 1 sampai 5 bintang."
            )
        }
        return try await repository.saveCoachRating(
            submissionID: submissionID,
            reviewerID: reviewerID,
            rating: rating
        )
    }
}

nonisolated struct CreateLocalDraftProgramUseCase: Sendable {
    let repository: any ProgramRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        title: String,
        summary: String,
        timeZoneIdentifier: String
    ) async throws -> Program {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw DomainError.validation(
                field: "title",
                reason: "Judul program wajib diisi."
            )
        }

        let startDate = clock.now()
        let program = Program(
            id: identifierGenerator.makeIdentifier(),
            title: trimmedTitle,
            summary: summary,
            price: nil,
            status: .draft,
            startDate: startDate,
            endDate: startDate,
            timeZoneIdentifier: timeZoneIdentifier,
            weightPointsPerKilogram: 800,
            days: []
        )
        return try await repository.save(program: program)
    }
}

nonisolated struct SaveLocalCMSDraftUseCase: Sendable {
    let repository: any ProgramRepository

    func callAsFunction(program: Program) async throws -> Program {
        guard program.status == .draft else {
            throw DomainError.validation(
                field: "status",
                reason: "Hanya draft program yang dapat disimpan dari CMS lokal."
            )
        }
        return try await repository.save(program: program)
    }
}

nonisolated struct ApplyLocalScoreAdjustmentUseCase: Sendable {
    let repository: any LeaderboardRepository

    func callAsFunction(
        entryID: UUID,
        points: Int
    ) async throws -> LeaderboardEntry {
        try await repository.applyScoreAdjustment(
            entryID: entryID,
            points: points
        )
    }
}
