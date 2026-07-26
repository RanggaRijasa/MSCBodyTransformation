import Foundation

nonisolated struct ProgramProgressCalculator: Sendable {
    func percentage(
        totalStepCount: Int,
        submissions: [StepSubmission]
    ) -> Int {
        let completedStepCount = Set(
            submissions
                .filter { $0.status != .rejected }
                .map(\.stepID)
        ).count
        return ProgressCalculator().percentage(
            completed: completedStepCount,
            total: totalStepCount
        )
    }
}

nonisolated struct ProgramDayAccessCalculator: Sendable {
    func access(
        for day: ProgramDay,
        now: Date,
        timeZoneIdentifier: String
    ) -> ProgramDayAccess {
        VisibilityPolicyEvaluator().access(
            for: day,
            now: now,
            timeZoneIdentifier: timeZoneIdentifier,
            pastPolicy: .readOnly,
            futurePolicy: .locked
        )
    }
}

nonisolated struct WeightScoreCalculator: Sendable {
    func calculate(
        initialWeightKilograms: Decimal,
        finalWeightKilograms: Decimal,
        pointsPerKilogram: Decimal
    ) -> Int {
        (
            try? score(
                initialWeightKilograms: initialWeightKilograms,
                finalWeightKilograms: finalWeightKilograms,
                pointsPerKilogram: pointsPerKilogram
            ).points
        ) ?? 0
    }
}

extension Decimal {
    nonisolated func rounded(
        scale: Int,
        mode: Decimal.RoundingMode = .plain
    ) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, mode)
        return result
    }
}
