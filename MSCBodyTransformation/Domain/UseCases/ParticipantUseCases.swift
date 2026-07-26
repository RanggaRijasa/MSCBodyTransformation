import Foundation

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

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(identifier: program.timeZoneIdentifier) ?? .gmt
        let now = clock.now()
        let day = program.days.first {
            calendar.isDate($0.scheduledDate, inSameDayAs: now)
        }

        return TodayProgram(
            program: program,
            day: day,
            access: day.map {
                accessCalculator.access(
                    for: $0,
                    now: now,
                    timeZoneIdentifier: program.timeZoneIdentifier
                )
            }
        )
    }
}

nonisolated struct CompleteLocalStepUseCase: Sendable {
    let repository: any SubmissionRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock
    let validator: StepSubmissionValidator

    func callAsFunction(
        enrollmentID: UUID,
        step: ProgramStep,
        evidence: [SubmissionEvidence]
    ) async throws -> StepSubmission {
        try validator.validate(step: step, evidence: evidence)
        let status: SubmissionStatus =
            step.verificationMode == .automatic ? .approved : .pending
        let submission = StepSubmission(
            id: identifierGenerator.makeIdentifier(),
            enrollmentID: enrollmentID,
            stepID: step.id,
            evidence: evidence,
            status: status,
            submittedAt: clock.now(),
            reviewedAt: nil,
            reviewerID: nil,
            reviewNote: nil
        )
        return try await repository.completeStep(submission: submission)
    }
}

nonisolated struct SubmitLocalWeighInUseCase: Sendable {
    let repository: any WeighInRepository
    let identifierGenerator: any IdentifierGenerating
    let clock: any AppClock
    let validator: WeighInValidator

    func callAsFunction(
        enrollmentID: UUID,
        type: WeighInType,
        weightKilograms: Decimal
    ) async throws -> WeighIn {
        try validator.validate(weightKilograms: weightKilograms)
        return try await repository.save(
            weighIn: WeighIn(
                id: identifierGenerator.makeIdentifier(),
                enrollmentID: enrollmentID,
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
