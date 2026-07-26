import Foundation

nonisolated struct AdminProgramDraftValidator: Sendable {
    func validate(_ draft: AdminProgramDraft) -> [AdminValidationIssue] {
        var issues: [AdminValidationIssue] = []
        if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(
                issue(.title, "Nama program wajib diisi.")
            )
        }
        if draft.startDate > draft.endDate {
            issues.append(
                issue(.dates, "Tanggal selesai tidak boleh sebelum mulai.")
            )
        }
        if TimeZone(identifier: draft.timeZoneIdentifier) == nil {
            issues.append(
                issue(.timeZone, "Pilih zona waktu IANA yang valid.")
            )
        }
        if draft.initialWeighInWindowHours <= 0
            || draft.finalWeighInWindowHours <= 0 {
            issues.append(
                issue(.dates, "Jendela timbang harus lebih dari nol jam.")
            )
        }
        if draft.weightPointsPerKilogram <= 0 {
            issues.append(
                issue(.scoring, "Poin per kilogram harus lebih dari nol.")
            )
        }
        if draft.days.isEmpty {
            issues.append(
                issue(.days, "Tambahkan setidaknya satu hari program.")
            )
        }

        let dayNumbers = draft.days.map(\.dayNumber)
        if Set(dayNumbers).count != dayNumbers.count
            || dayNumbers.contains(where: { $0 <= 0 }) {
            issues.append(
                issue(.dayNumbers, "Nomor hari harus positif dan unik.")
            )
        }
        let calendar = calendar(for: draft.timeZoneIdentifier)
        let dayDates = draft.days.map {
            calendar.startOfDay(for: $0.scheduledDate)
        }
        if Set(dayDates).count != dayDates.count {
            issues.append(
                issue(.dayDates, "Tanggal setiap hari harus unik.")
            )
        }

        for day in draft.days {
            let activeSteps = day.steps.filter(\.isActive)
            if activeSteps.isEmpty {
                issues.append(
                    issue(
                        .steps,
                        "Hari ke-\(day.dayNumber) memerlukan langkah aktif."
                    )
                )
            }
            let orders = activeSteps.map(\.order).sorted()
            let expectedOrders = activeSteps.isEmpty
                ? []
                : Array(1...activeSteps.count)
            if orders != expectedOrders {
                issues.append(
                    issue(
                        .stepOrder,
                        "Urutan langkah hari ke-\(day.dayNumber) "
                            + "harus dimulai dari 1 tanpa jeda."
                    )
                )
            }
            if activeSteps.contains(where: { $0.points < 0 }) {
                issues.append(
                    issue(
                        .scoring,
                        "Poin langkah hari ke-\(day.dayNumber) "
                            + "tidak boleh negatif."
                    )
                )
            }
            if activeSteps.contains(where: {
                $0.mediaKind != nil
                    && ($0.localMediaReference?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty != false)
            }) {
                issues.append(
                    issue(
                        .media,
                        "Media hari ke-\(day.dayNumber) "
                            + "memerlukan referensi lokal."
                    )
                )
            }
        }
        return issues
    }

    func generateDays(
        startDate: Date,
        endDate: Date,
        timeZoneIdentifier: String,
        programID: UUID
    ) throws -> [AdminDayDraft] {
        guard startDate <= endDate else {
            throw DomainError.validation(
                field: "dates",
                reason: "Tanggal selesai tidak boleh sebelum mulai."
            )
        }
        let calendar = calendar(for: timeZoneIdentifier)
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let count = (
            calendar.dateComponents([.day], from: start, to: end).day ?? 0
        ) + 1
        guard count > 0, count <= 365 else {
            throw DomainError.validation(
                field: "dates",
                reason: "Rentang program harus antara 1 dan 365 hari."
            )
        }

        return (0..<count).compactMap { offset in
            guard let date = calendar.date(
                byAdding: .day,
                value: offset,
                to: start
            ) else {
                return nil
            }
            return AdminDayDraft(
                id: childIdentifier(
                    parent: programID,
                    discriminator: offset + 1
                ),
                dayNumber: offset + 1,
                title: "Hari ke-\(offset + 1)",
                summary: "",
                scheduledDate: date,
                steps: []
            )
        }
    }

    func normalized(_ draft: AdminProgramDraft) -> AdminProgramDraft {
        var result = draft
        result.days = result.days
            .sorted {
                if $0.dayNumber == $1.dayNumber {
                    return $0.scheduledDate < $1.scheduledDate
                }
                return $0.dayNumber < $1.dayNumber
            }
            .enumerated()
            .map { dayIndex, day in
                var updated = day
                updated.dayNumber = dayIndex + 1
                updated.steps = day.steps
                    .sorted { $0.order < $1.order }
                    .enumerated()
                    .map { stepIndex, step in
                        var updatedStep = step
                        updatedStep.order = stepIndex + 1
                        return updatedStep
                    }
                return updated
            }
        return result
    }

    func childIdentifier(parent: UUID, discriminator: Int) -> UUID {
        var bytes = parent.uuid
        bytes.15 = UInt8(truncatingIfNeeded: discriminator)
        bytes.14 = UInt8(truncatingIfNeeded: discriminator >> 8)
        return UUID(uuid: bytes)
    }

    private func calendar(for identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier) ?? .gmt
        return calendar
    }

    private func issue(
        _ field: AdminValidationField,
        _ message: String
    ) -> AdminValidationIssue {
        AdminValidationIssue(field: field, message: message)
    }
}

nonisolated struct CreateAdminProgramDraftUseCase: Sendable {
    let drafts: any AdminProgramDraftRepository
    let audit: any AuditRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(adminID: UUID) async throws -> AdminProgramDraft {
        let now = clock.now()
        let id = identifierGenerator.makeIdentifier()
        let draft = AdminProgramDraft(
            id: id,
            title: "Program baru",
            summary: "",
            coverLocalReference: nil,
            verificationMode: .coachReview,
            wellnessDisclaimer:
                "Program ini mendukung kebiasaan hidup sehat dan bukan "
                + "pengganti diagnosis atau perawatan medis.",
            startDate: now,
            endDate: now,
            timeZoneIdentifier: "Asia/Makassar",
            initialWeighInWindowHours: 24,
            finalWeighInWindowHours: 24,
            weightPointsPerKilogram: 800,
            pastStepPolicy: .readOnly,
            futureStepPolicy: .locked,
            status: .draft,
            days: [],
            updatedAt: now
        )
        let saved = try await drafts.save(programDraft: draft)
        _ = try await audit.append(
            auditEvent: AuditEvent(
                id: id,
                kind: .programCreated,
                actorUserID: adminID,
                subjectID: id,
                summary: "Draft program lokal dibuat.",
                createdAt: now
            )
        )
        return saved
    }
}

nonisolated struct SaveAdminProgramDraftUseCase: Sendable {
    let drafts: any AdminProgramDraftRepository
    let audit: any AuditRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        draft: AdminProgramDraft,
        adminID: UUID
    ) async throws -> AdminProgramDraft {
        guard draft.status == .draft else {
            throw DomainError.validation(
                field: "status",
                reason: "Hanya draft yang dapat diedit."
            )
        }
        var updated = AdminProgramDraftValidator().normalized(draft)
        updated.updatedAt = clock.now()
        let saved = try await drafts.save(programDraft: updated)
        _ = try await audit.append(
            auditEvent: AuditEvent(
                id: identifierGenerator.makeIdentifier(),
                kind: .programUpdated,
                actorUserID: adminID,
                subjectID: draft.id,
                summary: "Draft program lokal diperbarui.",
                createdAt: updated.updatedAt
            )
        )
        return saved
    }
}

nonisolated struct PublishAdminProgramDraftUseCase: Sendable {
    let drafts: any AdminProgramDraftRepository
    let audit: any AuditRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        draft: AdminProgramDraft,
        adminID: UUID
    ) async throws -> AdminProgramDraft {
        guard draft.status == .draft else {
            throw DomainError.validation(
                field: "status",
                reason: "Hanya draft yang dapat dipublikasikan."
            )
        }
        let validator = AdminProgramDraftValidator()
        let normalized = validator.normalized(draft)
        let issues = validator.validate(normalized)
        guard issues.isEmpty else {
            throw DomainError.validation(
                field: issues[0].field.rawValue,
                reason: issues[0].message
            )
        }
        var published = normalized
        published.status = published.startDate > clock.now()
            ? .scheduled
            : .active
        published.updatedAt = clock.now()
        let saved = try await drafts.save(programDraft: published)
        _ = try await audit.append(
            auditEvent: AuditEvent(
                id: identifierGenerator.makeIdentifier(),
                kind: .programPublished,
                actorUserID: adminID,
                subjectID: draft.id,
                summary: "Publikasi demo lokal disimulasikan.",
                createdAt: published.updatedAt
            )
        )
        return saved
    }
}

nonisolated struct ManualAdminEnrollmentUseCase: Sendable {
    let enrollments: any EnrollmentRepository
    let audit: any AuditRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        programID: UUID,
        participantID: UUID,
        coachID: UUID?,
        reason: String,
        adminID: UUID
    ) async throws -> ProgramEnrollment {
        let trimmedReason = reason.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedReason.isEmpty else {
            throw DomainError.validation(
                field: "reason",
                reason: "Alasan enrollment manual wajib diisi."
            )
        }
        if let existing = try await enrollments.enrollment(
            programID: programID,
            participantID: participantID
        ) {
            return existing
        }
        let now = clock.now()
        let enrollment = try await enrollments.createEnrollment(
            ProgramEnrollment(
                id: identifierGenerator.makeIdentifier(),
                programID: programID,
                participantID: participantID,
                coachID: coachID,
                status: .active,
                enrolledAt: now
            )
        )
        _ = try await audit.append(
            auditEvent: AuditEvent(
                id: enrollment.id,
                kind: .participantEnrolled,
                actorUserID: adminID,
                subjectID: participantID,
                summary: "Pendaftaran manual lokal: \(trimmedReason)",
                createdAt: now
            )
        )
        return enrollment
    }
}

nonisolated struct AdjustAdminScoreUseCase: Sendable {
    let leaderboard: any LeaderboardRepository
    let audit: any AuditRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        entryID: UUID,
        points: Int,
        reason: String,
        adminID: UUID
    ) async throws -> LeaderboardEntry {
        let trimmedReason = reason.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedReason.isEmpty else {
            throw DomainError.validation(
                field: "reason",
                reason: "Alasan penyesuaian poin wajib diisi."
            )
        }
        let updated = try await leaderboard.applyScoreAdjustment(
            entryID: entryID,
            points: points
        )
        _ = try await audit.append(
            auditEvent: AuditEvent(
                id: identifierGenerator.makeIdentifier(),
                kind: .scoreAdjusted,
                actorUserID: adminID,
                subjectID: entryID,
                summary: "Penyesuaian poin lokal: \(trimmedReason)",
                createdAt: clock.now()
            )
        )
        return updated
    }
}

nonisolated struct LockAdminWinnersUseCase: Sendable {
    let leaderboard: any LeaderboardRepository
    let audit: any AuditRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        programID: UUID,
        adminID: UUID
    ) async throws -> [ProgramWinner] {
        let existing = try await leaderboard.winners(programID: programID)
        guard existing.isEmpty else {
            return existing
        }
        let winners = try await leaderboard.lockTopFive(
            programID: programID,
            lockedAt: clock.now()
        )
        _ = try await audit.append(
            auditEvent: AuditEvent(
                id: identifierGenerator.makeIdentifier(),
                kind: .winnersLocked,
                actorUserID: adminID,
                subjectID: programID,
                summary: "Lima pemenang lokal dikunci.",
                createdAt: clock.now()
            )
        )
        return winners
    }
}

nonisolated struct ManagedContentValidator: Sendable {
    func validate(_ content: ManagedContent) throws {
        guard !content.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            throw DomainError.validation(
                field: "title",
                reason: "Judul konten wajib diisi."
            )
        }
        guard !content.body.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            throw DomainError.validation(
                field: "body",
                reason: "Isi konten wajib diisi."
            )
        }
        if let from = content.visibleFrom,
           let until = content.visibleUntil,
           from > until {
            throw DomainError.validation(
                field: "visibility",
                reason: "Tanggal selesai tampil tidak boleh sebelum mulai."
            )
        }
    }

    func isVisible(_ content: ManagedContent, at date: Date) -> Bool {
        guard content.isPublished, !content.isArchived else {
            return false
        }
        if let from = content.visibleFrom, date < from {
            return false
        }
        if let until = content.visibleUntil, date > until {
            return false
        }
        return true
    }
}
