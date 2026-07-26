import Foundation

nonisolated struct ProgramProgressCalculator: Sendable {
    func percentage(
        totalStepCount: Int,
        submissions: [StepSubmission]
    ) -> Int {
        guard totalStepCount > 0 else {
            return 0
        }

        let completedStepCount = Set(
            submissions
                .filter { $0.status != .rejected }
                .map(\.stepID)
        ).count
        let boundedCompletedCount = min(completedStepCount, totalStepCount)

        let percentage =
            (Decimal(boundedCompletedCount) / Decimal(totalStepCount) * 100)
                .rounded(scale: 0)
        return NSDecimalNumber(decimal: percentage).intValue
    }
}

nonisolated struct ProgramDayAccessCalculator: Sendable {
    func access(
        for day: ProgramDay,
        now: Date,
        timeZoneIdentifier: String
    ) -> ProgramDayAccess {
        switch day.visibilityMode {
        case .hidden:
            return .hidden
        case .readOnly:
            return .readOnly
        case .standard:
            break
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        let comparison = calendar.compare(
            day.scheduledDate,
            to: now,
            toGranularity: .day
        )

        switch comparison {
        case .orderedDescending:
            return .locked
        case .orderedAscending:
            return .readOnly
        case .orderedSame:
            return .available
        }
    }
}

nonisolated struct WeightScoreCalculator: Sendable {
    func calculate(
        initialWeightKilograms: Decimal,
        finalWeightKilograms: Decimal,
        pointsPerKilogram: Decimal
    ) -> Int {
        let loss = max(initialWeightKilograms - finalWeightKilograms, 0)
        let points = (loss * pointsPerKilogram).rounded(scale: 0)
        return NSDecimalNumber(decimal: points).intValue
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
