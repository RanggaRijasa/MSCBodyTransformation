import Foundation

nonisolated struct DuplicateProgramRequest: Equatable, Sendable {
    let title: String
    let startDate: Date
    let endDate: Date?
}

nonisolated struct DuplicateProgramAsDraftUseCase: Sendable {
    let identifierGenerator: any IdentifierGenerating

    func callAsFunction(
        source: Program,
        request: DuplicateProgramRequest
    ) throws -> Program {
        guard let timeZone = TimeZone(identifier: source.timeZoneIdentifier) else {
            throw DomainError.validation(
                field: "timeZone",
                reason: "Zona waktu program tidak valid."
            )
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let sourceStart = calendar.startOfDay(for: source.startDate)
        let requestedStart = calendar.startOfDay(for: request.startDate)
        let sourceEnd = calendar.startOfDay(for: source.endDate)
        let inclusiveDuration = max(
            (calendar.dateComponents(
                [.day],
                from: sourceStart,
                to: sourceEnd
            ).day ?? 0) + 1,
            1
        )
        let duplicatedEnd = request.endDate.map(calendar.startOfDay(for:))
            ?? calendar.date(
                byAdding: .day,
                value: inclusiveDuration - 1,
                to: requestedStart
            )
            ?? requestedStart
        guard duplicatedEnd >= requestedStart else {
            throw DomainError.validation(
                field: "dates",
                reason: "Tanggal selesai tidak boleh sebelum tanggal mulai."
            )
        }

        let programID = identifierGenerator.makeIdentifier()
        let duplicatedDays = source.days.map { sourceDay in
            duplicate(
                day: sourceDay,
                sourceStart: sourceStart,
                duplicatedStart: requestedStart,
                programID: programID,
                calendar: calendar
            )
        }

        return Program(
            id: programID,
            sourceProgramID: source.id,
            title: request.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            summary: source.summary,
            category: source.category,
            coverLocalReference: source.coverLocalReference,
            coverAlternativeText: source.coverAlternativeText,
            price: source.price,
            status: .draft,
            startDate: requestedStart,
            endDate: duplicatedEnd,
            timeZoneIdentifier: source.timeZoneIdentifier,
            weightPointsPerKilogram: source.weightPointsPerKilogram,
            scoringConfiguration: source.scoringConfiguration,
            commerceConfiguration: duplicatedCommerce(
                source.effectiveCommerceConfiguration
            ),
            pace: source.pace,
            durationMode: source.durationMode,
            participantLimit: source.participantLimit,
            pastStepPolicy: source.pastStepPolicy,
            futureStepPolicy: source.futureStepPolicy,
            wellnessDisclaimer: source.wellnessDisclaimer,
            days: duplicatedDays
        )
    }

    private func duplicatedCommerce(
        _ source: ProgramCommerceConfiguration
    ) -> ProgramCommerceConfiguration {
        ProgramCommerceConfiguration(
            pricingMode: source.pricingMode,
            desiredPrice: source.desiredPrice,
            platformAvailability: source.platformAvailability.map {
                ProgramPlatformAvailability(
                    platform: $0.platform,
                    isEnabled: $0.isEnabled,
                    provisioningStatus: source.requiresPayment
                        ? .notRequested
                        : .notRequired
                )
            }
        )
    }

    private func duplicate(
        day: ProgramDay,
        sourceStart: Date,
        duplicatedStart: Date,
        programID: UUID,
        calendar: Calendar
    ) -> ProgramDay {
        let dayID = identifierGenerator.makeIdentifier()
        let sourceDay = calendar.startOfDay(for: day.scheduledDate)
        let offset = calendar.dateComponents(
            [.day],
            from: sourceStart,
            to: sourceDay
        ).day ?? 0
        let duplicatedDate = calendar.date(
            byAdding: .day,
            value: offset,
            to: duplicatedStart
        ) ?? duplicatedStart

        return ProgramDay(
            id: dayID,
            programID: programID,
            dayNumber: day.dayNumber,
            title: day.title,
            scheduledDate: duplicatedDate,
            visibilityMode: day.visibilityMode,
            steps: day.steps.map {
                duplicate(step: $0, programDayID: dayID)
            }
        )
    }

    private func duplicate(
        step: ProgramStep,
        programDayID: UUID
    ) -> ProgramStep {
        ProgramStep(
            id: identifierGenerator.makeIdentifier(),
            programDayID: programDayID,
            order: step.order,
            title: step.title,
            instructions: step.instructions,
            instructionMedia: step.instructionMedia,
            verificationMode: step.verificationMode,
            content: step.content.map(duplicate(content:))
        )
    }

    private func duplicate(content: ProgramStepContent) -> ProgramStepContent {
        ProgramStepContent(
            kind: content.kind,
            questions: content.questions.map(duplicate(question:)),
            completionPolicy: content.completionPolicy,
            videoConfiguration: content.videoConfiguration
        )
    }

    private func duplicate(
        question: ProgramQuestionDefinition
    ) -> ProgramQuestionDefinition {
        var optionIDMap: [UUID: UUID] = [:]
        let options = question.options.map { option in
            let optionID = identifierGenerator.makeIdentifier()
            optionIDMap[option.id] = optionID
            return ProgramQuestionOption(
                id: optionID,
                order: option.order,
                title: option.title,
                mediaReference: option.mediaReference,
                mediaAlternativeText: option.mediaAlternativeText
            )
        }
        let answerKey = question.answerKey.map {
            ProgramQuestionAnswerKey(
                acceptedTextValues: $0.acceptedTextValues,
                numberValue: $0.numberValue,
                selectedOptionIDs: $0.selectedOptionIDs.compactMap {
                    optionIDMap[$0]
                },
                matchingMode: $0.matchingMode
            )
        }
        return ProgramQuestionDefinition(
            id: identifierGenerator.makeIdentifier(),
            order: question.order,
            kind: question.kind,
            prompt: question.prompt,
            options: options,
            answerKey: answerKey
        )
    }
}

nonisolated struct ProgramContractValidator: Sendable {
    func validate(_ program: Program) -> [String] {
        var issues: [String] = []
        let scoring = program.effectiveScoringConfiguration
        if scoring.pointsPerActivity < 0 {
            issues.append("Poin aktivitas tidak boleh negatif.")
        }
        if scoring.pointsPerWeightLossKilogram < 0 {
            issues.append("Poin per kilogram tidak boleh negatif.")
        }
        if !(0...100).contains(scoring.quizPassingPercentage) {
            issues.append("Nilai minimum kuis harus antara 0 dan 100 persen.")
        }
        if program.startDate > program.endDate {
            issues.append("Tanggal selesai tidak boleh sebelum tanggal mulai.")
        }
        if TimeZone(identifier: program.timeZoneIdentifier) == nil {
            issues.append("Zona waktu program tidak valid.")
        }
        let commerce = program.effectiveCommerceConfiguration
        if program.commerceConfiguration != nil, commerce.requiresPayment {
            if commerce.desiredPrice == nil || commerce.desiredPrice ?? 0 <= 0 {
                issues.append(
                    "Program berbayar memerlukan harga yang diinginkan."
                )
            }
            let enabledPlatforms = commerce.platformAvailability.filter(
                \.isEnabled
            )
            if enabledPlatforms.isEmpty {
                issues.append(
                    "Aktifkan setidaknya satu platform pembayaran."
                )
            } else if enabledPlatforms.contains(where: {
                $0.provisioningStatus != .ready
            }) {
                issues.append(
                    "Pembayaran App Store dan Google Play harus siap "
                        + "sebelum program berbayar diterbitkan."
                )
            }
        }

        let steps = program.days.flatMap(\.steps)
        let weighKinds = steps.compactMap { $0.content?.weighInKind }
        if scoring.pointsPerWeightLossKilogram > 0,
           steps.contains(where: { $0.content != nil }) {
            if weighKinds.filter({ $0 == .initial }).count != 1
                || weighKinds.filter({ $0 == .final }).count != 1 {
                issues.append(
                    "Program dengan poin timbang memerlukan tepat satu "
                        + "timbang awal dan satu timbang akhir."
                )
            }
        }

        for step in steps {
            guard let content = step.content else {
                continue
            }
            for question in content.questions {
                if question.kind.isInteractive,
                   question.prompt.trimmingCharacters(
                       in: .whitespacesAndNewlines
                   ).isEmpty {
                    issues.append("Semua pertanyaan wajib mempunyai teks.")
                }
                if question.kind.acceptsOptions {
                    let titles = question.options.map {
                        $0.title.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }
                    if titles.count < 2
                        || titles.contains(where: \.isEmpty)
                        || Set(titles.map { $0.lowercased() }).count
                            != titles.count {
                        issues.append(
                            "Pilihan jawaban harus berisi minimal dua nilai "
                                + "yang unik."
                        )
                    }
                }
            }
            if content.kind == .quiz {
                let objectiveQuestions = content.questions.filter {
                    $0.kind.isObjective
                }
                if objectiveQuestions.isEmpty {
                    issues.append(
                        "Kuis memerlukan minimal satu pertanyaan objektif."
                    )
                }
                if objectiveQuestions.contains(where: { $0.answerKey == nil }) {
                    issues.append("Answer key kuis belum lengkap.")
                }
            }
        }
        return Array(Set(issues)).sorted()
    }
}

nonisolated struct StepAnswerValidator: Sendable {
    func validate(
        questions: [ProgramQuestionDefinition],
        answers: [StepSubmissionAnswer]
    ) throws {
        let answerByQuestion = Dictionary(
            answers.map { ($0.questionID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        for question in questions where question.requiresAnswer {
            guard let answer = answerByQuestion[question.id], answer.hasValue else {
                throw DomainError.validation(
                    field: "answers",
                    reason: "Semua pertanyaan wajib dijawab sebelum dikirim."
                )
            }
            if question.kind.acceptsOptions {
                let validIDs = Set(question.options.map(\.id))
                guard !answer.selectedOptionIDs.isEmpty,
                      Set(answer.selectedOptionIDs).isSubset(of: validIDs) else {
                    throw DomainError.validation(
                        field: "answers",
                        reason: "Pilihan jawaban tidak valid."
                    )
                }
            }
        }
        guard questions.contains(where: \.requiresAnswer)
                || !answers.isEmpty else {
            throw DomainError.validation(
                field: "answers",
                reason: "Submission kosong tidak dapat dikirim."
            )
        }
    }
}

nonisolated struct QuizEvaluation: Equatable, Sendable {
    let correctAnswerCount: Int
    let totalQuestionCount: Int
    let percentage: Int
    let isPassed: Bool
    let awardedPoints: Int
}

nonisolated struct QuizEvaluator: Sendable {
    func evaluate(
        questions: [ProgramQuestionDefinition],
        answers: [StepSubmissionAnswer],
        scoring: ProgramScoringConfiguration
    ) throws -> QuizEvaluation {
        try StepAnswerValidator().validate(
            questions: questions,
            answers: answers
        )
        let objectiveQuestions = questions.filter { $0.kind.isObjective }
        guard !objectiveQuestions.isEmpty else {
            throw DomainError.validation(
                field: "quiz",
                reason: "Kuis belum mempunyai pertanyaan objektif."
            )
        }
        let answerByQuestion = Dictionary(
            answers.map { ($0.questionID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let correctCount = objectiveQuestions.reduce(into: 0) { count, question in
            guard let answer = answerByQuestion[question.id],
                  let key = question.answerKey else {
                return
            }
            if isCorrect(answer: answer, question: question, key: key) {
                count += 1
            }
        }
        let percentage = NSDecimalNumber(
            decimal:
                (Decimal(correctCount)
                    / Decimal(objectiveQuestions.count) * 100)
                    .rounded(0)
        ).intValue
        return QuizEvaluation(
            correctAnswerCount: correctCount,
            totalQuestionCount: objectiveQuestions.count,
            percentage: percentage,
            isPassed: percentage >= scoring.quizPassingPercentage,
            awardedPoints: correctCount * scoring.pointsPerActivity
        )
    }

    private func isCorrect(
        answer: StepSubmissionAnswer,
        question: ProgramQuestionDefinition,
        key: ProgramQuestionAnswerKey
    ) -> Bool {
        switch question.kind {
        case .number:
            return answer.numberValue == key.numberValue
        case .singleChoice, .multipleChoice, .imageChoice:
            return Set(answer.selectedOptionIDs) == Set(key.selectedOptionIDs)
        case .shortAnswer, .longAnswer:
            guard let text = answer.textValue else {
                return false
            }
            switch key.matchingMode {
            case .exact:
                return key.acceptedTextValues.contains(text)
            case .caseInsensitiveText:
                return key.acceptedTextValues.contains {
                    $0.caseInsensitiveCompare(text) == .orderedSame
                }
            }
        case .photoUpload, .heading, .text:
            return false
        }
    }
}

private nonisolated extension Decimal {
    func rounded(_ scale: Int) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, .plain)
        return result
    }
}
