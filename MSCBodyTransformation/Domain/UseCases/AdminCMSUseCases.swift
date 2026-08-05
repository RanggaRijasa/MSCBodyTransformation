import Foundation

nonisolated struct AdminDayScheduleSync: Equatable, Sendable {
    let days: [AdminDayDraft]
    let removedDays: [AdminDayDraft]

    var removesContent: Bool {
        removedDays.contains { !$0.steps.isEmpty }
    }
}

nonisolated struct AdminProgramDraftValidator: Sendable {
    func validate(_ draft: AdminProgramDraft) -> [AdminValidationIssue] {
        var issues: [AdminValidationIssue] = []
        if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(
                issue(.title, "Nama program wajib diisi.")
            )
        }
        if draft.coverLocalReference?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty == false,
           draft.coverAlternativeText.trimmingCharacters(
               in: .whitespacesAndNewlines
           ).isEmpty {
            issues.append(
                issue(
                    .cover,
                    "Teks alternatif wajib diisi saat cover digunakan."
                )
            )
        }
        if draft.durationMode == .fixedDuration,
           !(1...365).contains(draft.fixedDurationDays) {
            issues.append(
                issue(
                    .dates,
                    "Durasi tetap harus antara 1 dan 365 hari."
                )
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
        if draft.pointsPerActivity < 0 {
            issues.append(
                issue(.scoring, "Poin aktivitas tidak boleh negatif.")
            )
        }
        if draft.weightPointsPerKilogram < 0 {
            issues.append(
                issue(.scoring, "Poin per kilogram tidak boleh negatif.")
            )
        }
        if !(0...100).contains(draft.quizPassingPercentage) {
            issues.append(
                issue(
                    .scoring,
                    "Nilai minimum kuis harus antara 0 dan 100 persen."
                )
            )
        }
        if let participantLimit = draft.participantLimit,
           participantLimit <= 0 {
            issues.append(
                issue(
                    .participantLimit,
                    "Batas peserta harus lebih dari nol."
                )
            )
        }
        if let registrationClosesAt = draft.registrationClosesAt,
           let timeZone = TimeZone(identifier: draft.timeZoneIdentifier) {
            var deadlineCalendar = Calendar(identifier: .gregorian)
            deadlineCalendar.timeZone = timeZone
            let deadlineDay = deadlineCalendar.startOfDay(
                for: registrationClosesAt
            )
            let endDay = deadlineCalendar.startOfDay(for: draft.endDate)
            if deadlineDay > endDay {
                issues.append(
                    issue(
                        .registrationDeadline,
                        "Batas pendaftaran tidak boleh setelah program selesai."
                    )
                )
            }
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
        if let expectedDays = try? generateDays(
            startDate: draft.startDate,
            endDate: draft.endDate,
            timeZoneIdentifier: draft.timeZoneIdentifier,
            programID: draft.id
        ) {
            let expectedDates = expectedDays.map {
                calendar.startOfDay(for: $0.scheduledDate)
            }
            if dayDates != expectedDates {
                issues.append(
                    issue(
                        .days,
                        "Susunan hari perlu disinkronkan dengan jadwal."
                    )
                )
            }
        }

        let dayIdentifiers = draft.days.map(\.id)
        if Set(dayIdentifiers).count != dayIdentifiers.count {
            issues.append(
                issue(.days, "Setiap hari harus memiliki ID yang unik.")
            )
        }

        let allSteps = draft.days.flatMap(\.steps)
        let stepIdentifiers = allSteps.map(\.id)
        if Set(stepIdentifiers).count != stepIdentifiers.count {
            issues.append(
                issue(.steps, "Setiap langkah harus memiliki ID yang unik.")
            )
        }
        let questionIdentifiers = allSteps
            .flatMap { $0.quiz?.questions ?? [] }
            .map(\.id)
        if Set(questionIdentifiers).count != questionIdentifiers.count {
            issues.append(
                issue(
                    .content,
                    "Setiap pertanyaan harus memiliki ID yang unik."
                )
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
            if activeSteps.contains(where: {
                $0.title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
            }) {
                issues.append(
                    issue(
                        .content,
                        "Semua langkah aktif pada hari ke-\(day.dayNumber) "
                            + "memerlukan nama."
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
            for step in activeSteps {
                let questions = step.quiz?.questions ?? []
                if step.contentKind == .quiz, questions.isEmpty {
                    issues.append(
                        issue(
                            .content,
                            "Kuis \(step.title) memerlukan pertanyaan."
                        )
                    )
                    continue
                }

                let questionIdentifiers = questions.map(\.id)
                if Set(questionIdentifiers).count
                    != questionIdentifiers.count {
                    issues.append(
                        issue(
                            .content,
                            "Pertanyaan pada \(step.title) "
                                + "harus memiliki ID yang unik."
                        )
                    )
                }

                let questionOrders = questions.map(\.order).sorted()
                let expectedQuestionOrders = questions.isEmpty
                    ? []
                    : Array(1...questions.count)
                if questionOrders != expectedQuestionOrders {
                    issues.append(
                        issue(
                            .content,
                            "Urutan pertanyaan pada \(step.title) "
                                + "harus dimulai dari 1 tanpa jeda."
                        )
                    )
                }

                if questions.contains(where: {
                    $0.prompt.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                }) {
                    issues.append(
                        issue(
                            .content,
                            "Semua pertanyaan kuis \(step.title) "
                                + "memerlukan isi."
                        )
                    )
                }
                if questions.contains(where: { question in
                    guard question.kind.acceptsOptions else { return false }
                    let normalizedOptions = question.options.map {
                        $0.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }
                    return normalizedOptions.count < 2
                        || normalizedOptions.contains(where: \.isEmpty)
                        || Set(normalizedOptions).count
                            != normalizedOptions.count
                }) {
                    issues.append(
                        issue(
                            .content,
                            "Pertanyaan pilihan pada \(step.title) "
                                + "memerlukan minimal dua pilihan unik."
                        )
                    )
                }
                if questions.contains(where: { question in
                    guard question.kind == .imageChoice else {
                        return false
                    }
                    return question.optionMediaReferences.count
                            != question.options.count
                        || question.optionMediaReferences.contains {
                            ($0 ?? "").trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty
                        }
                }) {
                    issues.append(
                        issue(
                            .content,
                            "Pilihan gambar pada \(step.title) "
                                + "memerlukan satu gambar untuk setiap "
                                + "pilihan."
                        )
                    )
                }
                if step.contentKind == .quiz {
                    let objectiveQuestions = questions.filter {
                        switch $0.kind {
                        case .number, .singleChoice, .multipleChoice,
                             .imageChoice:
                            true
                        case .shortAnswer, .longAnswer, .photoUpload,
                             .heading, .text:
                            false
                        }
                    }
                    if objectiveQuestions.isEmpty {
                        issues.append(
                            issue(
                                .content,
                                "Kuis \(step.title) memerlukan minimal "
                                    + "satu pertanyaan objektif."
                            )
                        )
                    }
                    if objectiveQuestions.contains(where: {
                        guard let key = $0.answerKey else { return true }
                        switch $0.kind {
                        case .number:
                            return key.numberValue == nil
                        case .singleChoice, .multipleChoice, .imageChoice:
                            return key.selectedOptionIDs.isEmpty
                        case .shortAnswer, .longAnswer, .photoUpload,
                             .heading, .text:
                            return false
                        }
                    }) {
                        issues.append(
                            issue(
                                .content,
                                "Jawaban benar kuis \(step.title) belum "
                                    + "lengkap."
                            )
                        )
                    }
                }
            }
        }
        let contractIssues = ProgramContractValidator().validate(
            draft.program()
        )
        issues.append(
            contentsOf: contractIssues.map { issue(.content, $0) }
        )
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

    func synchronizeDays(
        existingDays: [AdminDayDraft],
        startDate: Date,
        endDate: Date,
        timeZoneIdentifier: String,
        programID: UUID
    ) throws -> AdminDayScheduleSync {
        let templates = try generateDays(
            startDate: startDate,
            endDate: endDate,
            timeZoneIdentifier: timeZoneIdentifier,
            programID: programID
        )
        let calendar = calendar(for: timeZoneIdentifier)
        var available = existingDays.enumerated().map {
            (index: $0.offset, day: $0.element)
        }
        var synchronized: [AdminDayDraft] = []

        for (targetIndex, template) in templates.enumerated() {
            let targetDate = calendar.startOfDay(
                for: template.scheduledDate
            )
            let matchIndex = available.firstIndex {
                $0.index == targetIndex
            } ?? available.firstIndex {
                calendar.startOfDay(for: $0.day.scheduledDate)
                    == targetDate
            }

            if let matchIndex {
                var retained = available.remove(at: matchIndex).day
                retained.dayNumber = targetIndex + 1
                retained.scheduledDate = template.scheduledDate
                synchronized.append(retained)
            } else {
                synchronized.append(template)
            }
        }

        return AdminDayScheduleSync(
            days: synchronized,
            removedDays: available.map { $0.day }
        )
    }

    func normalized(_ draft: AdminProgramDraft) -> AdminProgramDraft {
        var result = draft
        result.initialWeighInWindowHours = 0
        result.finalWeighInWindowHours = 0
        if result.durationMode == .fixedDuration {
            let calendar = calendar(for: result.timeZoneIdentifier)
            result.endDate = calendar.date(
                byAdding: .day,
                value: max(result.fixedDurationDays - 1, 0),
                to: result.startDate
            ) ?? result.endDate
        }
        result.days = result.days
            .enumerated()
            .map { dayIndex, day in
                var updated = day
                updated.dayNumber = dayIndex + 1
                updated.steps = day.steps
                    .enumerated()
                    .map { stepIndex, step in
                        var updatedStep = step
                        updatedStep.order = stepIndex + 1
                        if updatedStep.contentKind == .video {
                            updatedStep.mediaKind = .video
                        } else {
                            updatedStep.mediaKind = nil
                        }
                        if (
                            updatedStep.contentKind == .quiz
                                || updatedStep.contentKind == .form
                        ),
                           updatedStep.quiz == nil {
                            updatedStep.quiz = AdminQuizDraft(
                                title: updatedStep.title,
                                questions: []
                            )
                        }
                        if var questionGroup = updatedStep.quiz {
                            questionGroup.title = updatedStep.title
                            questionGroup.questions = questionGroup.questions
                                .enumerated()
                                .map { questionIndex, question in
                                    var updatedQuestion = question
                                    updatedQuestion.order = questionIndex + 1
                                    if updatedQuestion.optionIDs.count
                                        != updatedQuestion.options.count {
                                        updatedQuestion.optionIDs =
                                            updatedQuestion.options.indices
                                            .map { optionIndex in
                                                childIdentifier(
                                                    parent:
                                                        updatedQuestion.id,
                                                    discriminator:
                                                        optionIndex + 1
                                                )
                                            }
                                        updatedQuestion.answerKey?
                                            .selectedOptionIDs = []
                                    }
                                    return updatedQuestion
                                }
                            updatedStep.quiz = questionGroup
                        }
                        return updatedStep
                    }
                return updated
            }
        return result
    }

    func childIdentifier(parent: UUID, discriminator: Int) -> UUID {
        let parentBytes = withUnsafeBytes(of: parent.uuid) {
            Array($0)
        }
        var input = parentBytes
        var value = UInt64(bitPattern: Int64(discriminator))
        for _ in 0..<8 {
            input.append(UInt8(truncatingIfNeeded: value))
            value >>= 8
        }

        let first = stableDigest(
            input,
            seed: 0xCBF2_9CE4_8422_2325
        )
        let second = stableDigest(
            input.reversed(),
            seed: 0x8422_2325_CBF2_9CE4
        )
        var bytes = withUnsafeBytes(of: first.bigEndian) {
            Array($0)
        }
        bytes.append(
            contentsOf: withUnsafeBytes(of: second.bigEndian) {
                Array($0)
            }
        )
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(
            uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15]
            )
        )
    }

    private func calendar(for identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier) ?? .gmt
        return calendar
    }

    private func stableDigest<S: Sequence>(
        _ bytes: S,
        seed: UInt64
    ) -> UInt64 where S.Element == UInt8 {
        bytes.reduce(seed) { partialResult, byte in
            (partialResult ^ UInt64(byte)) &* 0x0000_0100_0000_01B3
        }
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
        let firstDay = AdminDayDraft(
            id: AdminProgramDraftValidator().childIdentifier(
                parent: id,
                discriminator: 1
            ),
            dayNumber: 1,
            title: "Hari ke-1",
            summary: "",
            scheduledDate: now,
            steps: []
        )
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
            weightPointsPerKilogram: 0,
            pastStepPolicy: .readOnly,
            futureStepPolicy: .locked,
            status: .draft,
            days: [firstDay],
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
        program: Program,
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
        guard program.status == .scheduled || program.status == .active else {
            throw DomainError.conflict(
                reason: "Program belum tersedia untuk pendaftaran."
            )
        }
        guard coachID != nil else {
            throw DomainError.validation(
                field: "coach",
                reason: "Peserta harus memiliki Coach aktif."
            )
        }
        guard !program.effectiveCommerceConfiguration.requiresPayment else {
            throw DomainError.conflict(
                reason: "Pembayaran program harus diverifikasi server."
            )
        }
        if let existing = try await enrollments.enrollment(
            programID: program.id,
            participantID: participantID
        ) {
            return existing
        }
        if let participantLimit = program.participantLimit {
            let enrolledCount = try await enrollments.allEnrollments().count {
                $0.programID == program.id
                    && ($0.status == .active || $0.status == .completed)
            }
            guard enrolledCount < participantLimit else {
                throw DomainError.conflict(
                    reason: "Kapasitas program sudah penuh."
                )
            }
        }
        let now = clock.now()
        let enrollment = try await enrollments.createEnrollment(
            ProgramEnrollment(
                id: identifierGenerator.makeIdentifier(),
                programID: program.id,
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
    let enrollments: any EnrollmentRepository
    let submissions: any SubmissionRepository
    let weighIns: any WeighInRepository
    let audit: any AuditRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        program: Program,
        programID: UUID,
        adminID: UUID
    ) async throws -> [ProgramWinner] {
        let existing = try await leaderboard.winners(programID: programID)
        guard existing.isEmpty else {
            return existing
        }
        let preflight = try await LoadProgramClosurePreflightUseCase(
            enrollments: enrollments,
            submissions: submissions,
            weighIns: weighIns
        )(program: program)
        guard preflight.canLockWinners else {
            let pendingReviews = preflight.count(for: .pendingReview)
            let missingFinalWeighIns = preflight.count(
                for: .missingFinalWeighIn
            )
            throw DomainError.conflict(
                reason: "Selesaikan \(pendingReviews) pemeriksaan tertunda "
                    + "dan \(missingFinalWeighIns) timbang akhir sebelum "
                    + "mengunci pemenang."
            )
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

nonisolated struct ReopenQuizAttemptUseCase: Sendable {
    let submissions: any SubmissionRepository
    let audit: any AuditRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        enrollmentID: UUID,
        stepID: UUID,
        adminID: UUID,
        reason: String
    ) async throws -> QuizAttemptResult {
        let result = try await submissions.reopenQuizAttempt(
            enrollmentID: enrollmentID,
            stepID: stepID,
            adminID: adminID,
            reason: reason,
            reopenedAt: clock.now()
        )
        _ = try await audit.append(
            auditEvent: AuditEvent(
                id: identifierGenerator.makeIdentifier(),
                kind: .quizAttemptReopened,
                actorUserID: adminID,
                subjectID: result.id,
                summary: "Percobaan kuis dibuka kembali: "
                    + (result.reopenReason ?? ""),
                createdAt: clock.now()
            )
        )
        return result
    }
}

nonisolated struct CorrectWeighInUseCase: Sendable {
    let weighIns: any WeighInRepository
    let audit: any AuditRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        enrollmentID: UUID,
        type: WeighInType,
        stepID: UUID? = nil,
        weightKilograms: Decimal,
        adminID: UUID,
        reason: String
    ) async throws -> WeighIn {
        let trimmedReason = reason.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedReason.isEmpty else {
            throw DomainError.validation(
                field: "reason",
                reason: "Alasan koreksi timbang wajib diisi."
            )
        }
        let corrected = try await weighIns.correctWeighIn(
            enrollmentID: enrollmentID,
            type: type,
            stepID: stepID,
            weightKilograms: weightKilograms,
            correctedAt: clock.now()
        )
        _ = try await audit.append(
            auditEvent: AuditEvent(
                id: identifierGenerator.makeIdentifier(),
                kind: .weighInCorrected,
                actorUserID: adminID,
                subjectID: corrected.id,
                summary: "Timbang \(type.rawValue) dikoreksi: "
                    + trimmedReason,
                createdAt: clock.now()
            )
        )
        return corrected
    }
}

nonisolated struct LoadProgramClosurePreflightUseCase: Sendable {
    let enrollments: any EnrollmentRepository
    let submissions: any SubmissionRepository
    let weighIns: any WeighInRepository

    func callAsFunction(program: Program) async throws
        -> ProgramClosurePreflight {
        let programEnrollments = try await enrollments.allEnrollments()
            .filter {
                $0.programID == program.id
                    && ($0.status == .active || $0.status == .completed)
            }
        let requiresFinalWeighIn = program.days
            .flatMap(\.steps)
            .contains { $0.content?.kind == .finalWeighIn }
        var issues: [ProgramClosureIssue] = []

        for enrollment in programEnrollments {
            let enrollmentSubmissions = try await submissions.submissions(
                enrollmentID: enrollment.id
            )
            let pendingCount = enrollmentSubmissions.filter {
                $0.status == .pending
            }.count
            if pendingCount > 0 {
                issues.append(
                    issue(
                        enrollment: enrollment,
                        kind: .pendingReview,
                        count: pendingCount,
                        blocksWinnerLock: true
                    )
                )
            }

            if requiresFinalWeighIn {
                let enrollmentWeighIns = try await weighIns.weighIns(
                    enrollmentID: enrollment.id
                )
                if !enrollmentWeighIns.contains(where: { $0.type == .final }) {
                    issues.append(
                        issue(
                            enrollment: enrollment,
                            kind: .missingFinalWeighIn,
                            count: 1,
                            blocksWinnerLock: true
                        )
                    )
                }
            }

            let failedQuizCount = enrollmentSubmissions.filter {
                $0.quizResult?.isPassed == false
            }.count
            if failedQuizCount > 0 {
                issues.append(
                    issue(
                        enrollment: enrollment,
                        kind: .failedQuiz,
                        count: failedQuizCount,
                        blocksWinnerLock: false
                    )
                )
            }
        }

        return ProgramClosurePreflight(
            programID: program.id,
            enrollmentCount: programEnrollments.count,
            issues: issues
        )
    }

    private func issue(
        enrollment: ProgramEnrollment,
        kind: ProgramClosureIssueKind,
        count: Int,
        blocksWinnerLock: Bool
    ) -> ProgramClosureIssue {
        ProgramClosureIssue(
            id: "\(enrollment.id.uuidString)-\(kind.rawValue)",
            enrollmentID: enrollment.id,
            participantID: enrollment.participantID,
            kind: kind,
            count: count,
            blocksWinnerLock: blocksWinnerLock
        )
    }
}

nonisolated struct ManagedContentValidator: Sendable {
    func validate(_ content: ManagedContent) throws {
        if content.kind == .winnerBanner {
            guard let mediaReference = content.localMediaReference?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !mediaReference.isEmpty else {
                throw DomainError.validation(
                    field: "winnerPoster",
                    reason: "Poster pemenang wajib dipilih."
                )
            }
            if content.isPublished,
               (content.programID == nil || content.winnerSnapshotID == nil) {
                throw DomainError.validation(
                    field: "winnerSnapshot",
                    reason: "Poster harus terkait program dan snapshot "
                        + "pemenang yang sudah dikunci."
                )
            }
        }
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
