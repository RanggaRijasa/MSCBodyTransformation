import Foundation

nonisolated struct JoinProgramWithCoachUseCase: Sendable {
    let enrollments: any EnrollmentRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        programID: UUID,
        participantID: UUID,
        coachID: UUID
    ) async throws -> ProgramEnrollment {
        if let existing = try await enrollments.enrollment(
            programID: programID,
            participantID: participantID
        ) {
            return existing
        }

        return try await enrollments.createEnrollment(
            ProgramEnrollment(
                id: identifierGenerator.makeIdentifier(),
                programID: programID,
                participantID: participantID,
                coachID: coachID,
                status: .active,
                enrolledAt: clock.now()
            )
        )
    }
}

nonisolated struct TodayProgram: Equatable, Sendable {
    let program: Program
    let day: ProgramDay?
    let access: ProgramDayAccess?
}

nonisolated struct LoadTodayProgramUseCase: Sendable {
    let repository: any ProgramRepository
    let clock: any AppClock
    let accessCalculator: ProgramDayAccessCalculator

    func callAsFunction() async throws -> TodayProgram? {
        guard let program = try await repository.activeProgram() else {
            return nil
        }

        let now = clock.now()
        let day = ProgramDayResolver().activeDay(
            in: program,
            at: now
        )

        return TodayProgram(
            program: program,
            day: day,
            access: day.map {
                accessCalculator.access(
                    for: $0,
                    in: program,
                    now: now
                )
            }
        )
    }
}

nonisolated struct CompleteTypedStepUseCase: Sendable {
    let repository: any SubmissionRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock

    func callAsFunction(
        enrollmentID: UUID,
        step: ProgramStep,
        answers: [StepSubmissionAnswer],
        scoring: ProgramScoringConfiguration
    ) async throws -> StepSubmission {
        guard let content = step.content else {
            throw DomainError.validation(
                field: "content",
                reason: "Konten langkah belum tersedia."
            )
        }
        if !content.questions.isEmpty || content.kind == .form
            || content.kind == .quiz {
            try StepAnswerValidator().validate(
                questions: content.questions,
                answers: answers
            )
        }

        let quizResult: QuizAttemptResult?
        if content.kind == .quiz {
            let evaluation = try QuizEvaluator().evaluate(
                questions: content.questions,
                answers: answers,
                scoring: scoring
            )
            quizResult = QuizAttemptResult(
                id: identifierGenerator.makeIdentifier(),
                enrollmentID: enrollmentID,
                stepID: step.id,
                sequence: 1,
                correctAnswerCount: evaluation.correctAnswerCount,
                totalQuestionCount: evaluation.totalQuestionCount,
                percentage: evaluation.percentage,
                isPassed: evaluation.isPassed,
                awardedPoints: evaluation.awardedPoints,
                submittedAt: clock.now()
            )
        } else {
            quizResult = nil
        }

        let needsReview = step.verificationMode == .coachReview
            && content.kind != .quiz
        return try await repository.completeStep(
            submission: StepSubmission(
                id: identifierGenerator.makeIdentifier(),
                enrollmentID: enrollmentID,
                stepID: step.id,
                status: needsReview ? .pending : .approved,
                submittedAt: clock.now(),
                reviewedAt: nil,
                reviewerID: nil,
                reviewNote: nil,
                answers: answers,
                attemptSequence: content.kind == .quiz ? 1 : nil,
                quizResult: quizResult
            )
        )
    }
}

nonisolated struct SubmitLocalWeighInUseCase: Sendable {
    let repository: any WeighInRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock
    let validator: WeighInValidator

    func callAsFunction(
        enrollmentID: UUID,
        stepID: UUID? = nil,
        type: WeighInType,
        weightKilograms: Decimal
    ) async throws -> WeighIn {
        try validator.validate(weightKilograms: weightKilograms)
        if type == .daily, stepID == nil {
            throw DomainError.validation(
                field: "stepID",
                reason: "Timbang harian harus terkait dengan satu langkah."
            )
        }
        return try await repository.save(
            weighIn: WeighIn(
                id: identifierGenerator.makeIdentifier(),
                enrollmentID: enrollmentID,
                stepID: stepID,
                type: type,
                weightKilograms: weightKilograms,
                recordedAt: clock.now()
            )
        )
    }
}

nonisolated struct CalculateProgressUseCase: Sendable {
    let calculator: ProgramProgressCalculator

    func callAsFunction(
        totalStepCount: Int,
        submissions: [StepSubmission]
    ) -> Int {
        calculator.percentage(
            totalStepCount: totalStepCount,
            submissions: submissions
        )
    }
}

nonisolated struct LoadLeaderboardUseCase: Sendable {
    let repository: any LeaderboardRepository

    func callAsFunction(programID: UUID) async throws -> [LeaderboardEntry] {
        try await repository.leaderboard(programID: programID)
    }
}
