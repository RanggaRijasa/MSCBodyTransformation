import Foundation

nonisolated struct StepScoreCalculator: Sendable {
    func calculate(
        steps: [ProgramStep],
        submissions: [StepSubmission]
    ) throws -> Int {
        guard !steps.contains(where: { $0.points < 0 }) else {
            throw DomainError.validation(
                field: "stepPoints",
                reason: "Poin langkah aktif tidak boleh negatif."
            )
        }
        let publishedPoints = Dictionary(
            uniqueKeysWithValues: steps.map { ($0.id, $0.points) }
        )
        let approvedStepIDs = Set(
            submissions
                .filter { $0.status == .approved }
                .map(\.stepID)
        )
        return approvedStepIDs.reduce(into: 0) { total, stepID in
            total += publishedPoints[stepID] ?? 0
        }
    }
}

nonisolated enum WeightScoreCompletion: Equatable, Sendable {
    case incomplete
    case complete
}

nonisolated struct WeightScoreResult: Equatable, Sendable {
    let points: Int
    let lossKilograms: Decimal
    let completion: WeightScoreCompletion
}

extension WeightScoreCalculator {
    /// Uses Decimal `.plain` rounding, equivalent to nearest with halves away
    /// from zero. Canonical weight math never crosses through `Double`.
    nonisolated func score(
        initialWeightKilograms: Decimal?,
        finalWeightKilograms: Decimal?,
        pointsPerKilogram: Decimal
    ) throws -> WeightScoreResult {
        guard pointsPerKilogram > 0 else {
            throw DomainError.validation(
                field: "weightPointsPerKilogram",
                reason: "Pengali poin berat harus lebih dari nol."
            )
        }
        guard let initialWeightKilograms,
              let finalWeightKilograms else {
            return WeightScoreResult(
                points: 0,
                lossKilograms: 0,
                completion: .incomplete
            )
        }
        let loss = max(
            initialWeightKilograms - finalWeightKilograms,
            0
        )
        let roundedPoints = (loss * pointsPerKilogram).rounded(
            scale: 0,
            mode: .plain
        )
        return WeightScoreResult(
            points: NSDecimalNumber(decimal: roundedPoints).intValue,
            lossKilograms: loss,
            completion: .complete
        )
    }
}

nonisolated struct ProgressSnapshot: Equatable, Sendable {
    let requiredStepCount: Int
    let completedRequiredStepCount: Int
    let completedOptionalStepCount: Int
    let overallPercentage: Int
    let currentDayPercentage: Int
    let isOverallComplete: Bool
    let isCurrentDayComplete: Bool
}

nonisolated struct ProgressCalculator: Sendable {
    func calculate(
        requiredSteps: [ProgramStep],
        optionalSteps: [ProgramStep] = [],
        currentDaySteps: [ProgramStep],
        submissions: [StepSubmission]
    ) -> ProgressSnapshot {
        let completedStepIDs = Set(
            submissions
                .filter { $0.status != .rejected }
                .map(\.stepID)
        )
        let requiredIDs = Set(requiredSteps.map(\.id))
        let optionalIDs = Set(optionalSteps.map(\.id))
        let currentDayIDs = Set(currentDaySteps.map(\.id))
        let completedRequired = completedStepIDs
            .intersection(requiredIDs)
            .count
        let completedOptional = completedStepIDs
            .intersection(optionalIDs)
            .count
        let completedCurrentDay = completedStepIDs
            .intersection(currentDayIDs)
            .count

        return ProgressSnapshot(
            requiredStepCount: requiredSteps.count,
            completedRequiredStepCount: completedRequired,
            completedOptionalStepCount: completedOptional,
            overallPercentage: percentage(
                completed: completedRequired,
                total: requiredSteps.count
            ),
            currentDayPercentage: percentage(
                completed: completedCurrentDay,
                total: currentDaySteps.count
            ),
            isOverallComplete:
                !requiredSteps.isEmpty
                && completedRequired == requiredSteps.count,
            isCurrentDayComplete:
                !currentDaySteps.isEmpty
                && completedCurrentDay == currentDaySteps.count
        )
    }

    func percentage(completed: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let boundedCompleted = min(max(completed, 0), total)
        let value = (
            Decimal(boundedCompleted) / Decimal(total) * 100
        ).rounded(scale: 0)
        return NSDecimalNumber(decimal: value).intValue
    }
}

nonisolated struct EnrollmentScoreResult: Equatable, Sendable {
    let score: ScoreBreakdown
    let progress: ProgressSnapshot
    let weightCompletion: WeightScoreCompletion
}

nonisolated struct EnrollmentScoreCalculator: Sendable {
    let stepCalculator: StepScoreCalculator
    let weightCalculator: WeightScoreCalculator
    let progressCalculator: ProgressCalculator

    init(
        stepCalculator: StepScoreCalculator = StepScoreCalculator(),
        weightCalculator: WeightScoreCalculator = WeightScoreCalculator(),
        progressCalculator: ProgressCalculator = ProgressCalculator()
    ) {
        self.stepCalculator = stepCalculator
        self.weightCalculator = weightCalculator
        self.progressCalculator = progressCalculator
    }

    func calculate(
        program: Program,
        submissions: [StepSubmission],
        weighIns: [WeighIn],
        adjustmentPoints: Int,
        currentDayID: UUID? = nil
    ) throws -> EnrollmentScoreResult {
        let activeSteps = program.days.flatMap(\.steps)
        let currentDaySteps = program.days.first {
            $0.id == currentDayID
        }?.steps ?? []
        let initialWeight = weighIns.first {
            $0.type == .initial
        }?.weightKilograms
        let finalWeight = weighIns.first {
            $0.type == .final
        }?.weightKilograms
        let weightResult = try weightCalculator.score(
            initialWeightKilograms: initialWeight,
            finalWeightKilograms: finalWeight,
            pointsPerKilogram: program.weightPointsPerKilogram
        )
        return EnrollmentScoreResult(
            score: ScoreBreakdown(
                approvedStepPoints: try stepCalculator.calculate(
                    steps: activeSteps,
                    submissions: submissions
                ),
                weightPoints: weightResult.points,
                adjustmentPoints: adjustmentPoints
            ),
            progress: progressCalculator.calculate(
                requiredSteps: activeSteps,
                currentDaySteps: currentDaySteps,
                submissions: submissions
            ),
            weightCompletion: weightResult.completion
        )
    }
}

nonisolated struct ProgramDayResolver: Sendable {
    func activeDay(
        in program: Program,
        at date: Date
    ) -> ProgramDay? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(identifier: program.timeZoneIdentifier) ?? .gmt
        return program.days.first {
            calendar.isDate($0.scheduledDate, inSameDayAs: date)
        }
    }
}

nonisolated enum TemporalVisibilityPolicy: Equatable, Sendable {
    case hidden
    case readOnly
    case open
    case locked
}

nonisolated struct VisibilityPolicyEvaluator: Sendable {
    func access(
        for day: ProgramDay,
        now: Date,
        timeZoneIdentifier: String,
        pastPolicy: TemporalVisibilityPolicy,
        futurePolicy: TemporalVisibilityPolicy
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
        switch calendar.compare(
            day.scheduledDate,
            to: now,
            toGranularity: .day
        ) {
        case .orderedAscending:
            return access(for: pastPolicy)
        case .orderedDescending:
            return access(for: futurePolicy)
        case .orderedSame:
            return .available
        }
    }

    private func access(
        for policy: TemporalVisibilityPolicy
    ) -> ProgramDayAccess {
        switch policy {
        case .hidden:
            .hidden
        case .readOnly:
            .readOnly
        case .open:
            .available
        case .locked:
            .locked
        }
    }
}

nonisolated struct LeaderboardRankingCandidate:
    Equatable,
    Sendable
{
    var entry: LeaderboardEntry
    let completionTimestamp: Date?
    var enrollmentID: UUID? = nil
}

nonisolated struct LeaderboardSorter: Sendable {
    func sort(
        _ candidates: [LeaderboardRankingCandidate]
    ) -> [LeaderboardEntry] {
        candidates.sorted(by: precedes).enumerated().map {
            position,
            candidate in
            var entry = candidate.entry
            entry.rank = position + 1
            return entry
        }
    }

    private func precedes(
        _ left: LeaderboardRankingCandidate,
        _ right: LeaderboardRankingCandidate
    ) -> Bool {
        if left.entry.score.totalPoints
            != right.entry.score.totalPoints {
            return left.entry.score.totalPoints
                > right.entry.score.totalPoints
        }
        if left.entry.score.approvedStepPoints
            != right.entry.score.approvedStepPoints {
            return left.entry.score.approvedStepPoints
                > right.entry.score.approvedStepPoints
        }
        if left.entry.score.weightPoints
            != right.entry.score.weightPoints {
            return left.entry.score.weightPoints
                > right.entry.score.weightPoints
        }
        let leftCompletion =
            left.completionTimestamp ?? Date.distantFuture
        let rightCompletion =
            right.completionTimestamp ?? Date.distantFuture
        if leftCompletion != rightCompletion {
            return leftCompletion < rightCompletion
        }
        let leftStableID = left.enrollmentID ?? left.entry.id
        let rightStableID = right.enrollmentID ?? right.entry.id
        return leftStableID.uuidString < rightStableID.uuidString
    }
}

nonisolated struct WinnerSelector: Sendable {
    func select(
        from rankedEntries: [LeaderboardEntry],
        programID: UUID,
        lockedAt: Date,
        limit: Int = 5
    ) -> [ProgramWinner] {
        rankedEntries.prefix(max(limit, 0)).enumerated().map {
            index,
            entry in
            ProgramWinner(
                id: entry.id,
                programID: programID,
                participantID: entry.participantID,
                rank: index + 1,
                participantDisplayName: entry.participantDisplayName,
                totalPoints: entry.score.totalPoints,
                lockedAt: lockedAt
            )
        }
    }

    func scoresChanged(
        lockedWinners: [ProgramWinner],
        currentEntries: [LeaderboardEntry]
    ) -> Bool {
        let locked = lockedWinners.sorted { $0.rank < $1.rank }
        let currentTop = currentEntries
            .sorted { $0.rank < $1.rank }
            .prefix(locked.count)
        guard currentTop.count == locked.count else {
            return true
        }
        return zip(locked, currentTop).contains { winner, entry in
            winner.participantID != entry.participantID
                || winner.totalPoints != entry.score.totalPoints
        }
    }
}
