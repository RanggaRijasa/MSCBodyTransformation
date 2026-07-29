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

nonisolated struct GenerateLocalInviteUseCase: Sendable {
    let repository: any InviteRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        coachID: UUID,
        programID: UUID,
        validForDays: Int = 7
    ) async throws -> CoachInvite {
        guard validForDays > 0 else {
            throw DomainError.validation(
                field: "validForDays",
                reason: "Masa berlaku undangan harus lebih dari nol hari."
            )
        }

        let identifier = identifierGenerator.makeIdentifier()
        let createdAt = clock.now()
        let expiresAt = Calendar(identifier: .gregorian).date(
            byAdding: .day,
            value: validForDays,
            to: createdAt
        ) ?? createdAt
        let code = String(
            identifier.uuidString
                .replacingOccurrences(of: "-", with: "")
                .prefix(8)
        ).uppercased()

        return try await repository.createInvite(
            CoachInvite(
                id: identifier,
                code: code,
                coachID: coachID,
                programID: programID,
                status: .active,
                createdAt: createdAt,
                expiresAt: expiresAt,
                redeemedByParticipantID: nil
            )
        )
    }
}

nonisolated struct RedeemLocalInviteUseCase: Sendable {
    let repository: any InviteRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        code: String,
        participantID: UUID
    ) async throws -> ProgramEnrollment {
        try await repository.redeemInvite(
            code: code.trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased(),
            participantID: participantID,
            enrollmentID: identifierGenerator.makeIdentifier(),
            now: clock.now()
        )
    }
}

nonisolated struct PreviewLocalInviteUseCase: Sendable {
    let invites: any InviteRepository
    let programs: any ProgramRepository
    let clock: any AppClock

    func callAsFunction(code: String) async throws -> ProgramInvitePreview {
        let normalizedCode = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard !normalizedCode.isEmpty else {
            throw DomainError.validation(
                field: "inviteCode",
                reason: "Kode undangan wajib diisi."
            )
        }

        let invite = try await invites.activeInvite(
            code: normalizedCode,
            now: clock.now()
        )
        let program = try await programs.program(id: invite.programID)
        return ProgramInvitePreview(invite: invite, program: program)
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
