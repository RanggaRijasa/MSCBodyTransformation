import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Scoring dan leaderboard lokal Phase 07")
struct Phase07LocalScoringTests {
    @Test("Skor berat mengikuti matriks Decimal dan default 800")
    func weightMatrix() throws {
        let calculator = WeightScoreCalculator()

        #expect(
            try calculator.score(
                initialWeightKilograms: Decimal(string: "80.0"),
                finalWeightKilograms: Decimal(string: "79.9"),
                pointsPerKilogram: 800
            ).points == 80
        )
        #expect(
            try calculator.score(
                initialWeightKilograms: Decimal(string: "80.0"),
                finalWeightKilograms: Decimal(string: "79.0"),
                pointsPerKilogram: 800
            ).points == 800
        )
        #expect(
            try calculator.score(
                initialWeightKilograms: Decimal(string: "80.0"),
                finalWeightKilograms: Decimal(string: "80.0"),
                pointsPerKilogram: 800
            ).points == 0
        )
        #expect(
            try calculator.score(
                initialWeightKilograms: Decimal(string: "80.0"),
                finalWeightKilograms: Decimal(string: "81.0"),
                pointsPerKilogram: 800
            ).points == 0
        )
        #expect(
            try calculator.score(
                initialWeightKilograms: Decimal(string: "80.00"),
                finalWeightKilograms: Decimal(string: "79.95"),
                pointsPerKilogram: 800
            ).points == 40
        )
        #expect(
            try calculator.score(
                initialWeightKilograms: Decimal(string: "80.0"),
                finalWeightKilograms: Decimal(string: "79.9"),
                pointsPerKilogram: 100
            ).points == 10
        )
    }

    @Test("Berat akhir kosong menghasilkan state belum lengkap")
    func missingFinalWeight() throws {
        let result = try WeightScoreCalculator().score(
            initialWeightKilograms: 80,
            finalWeightKilograms: nil,
            pointsPerKilogram: 800
        )

        #expect(result.points == 0)
        #expect(result.completion == .incomplete)
    }

    @Test("Pengali berat wajib positif")
    func positiveWeightMultiplier() {
        #expect(throws: DomainError.self) {
            try WeightScoreCalculator().score(
                initialWeightKilograms: 80,
                finalWeightKilograms: 79,
                pointsPerKilogram: 0
            )
        }
    }

    @Test("Hanya submission approved unik mendapat poin fixture")
    func stepStatusMatrix() throws {
        let first = step(1, points: 10)
        let second = step(2, points: 20)
        let submissions = [
            submission(1, step: first, status: .approved),
            submission(2, step: first, status: .approved),
            submission(3, step: second, status: .pending),
            submission(4, step: second, status: .rejected)
        ]

        #expect(
            try StepScoreCalculator().calculate(
                steps: [first, second],
                submissions: [
                    submission(10, step: first, status: .approved),
                    submission(11, step: second, status: .approved)
                ]
            ) == 30
        )
        #expect(
            try StepScoreCalculator().calculate(
                steps: [first],
                submissions: [
                    submission(12, step: first, status: .pending)
                ]
            ) == 0
        )
        #expect(
            try StepScoreCalculator().calculate(
                steps: [first],
                submissions: [
                    submission(13, step: first, status: .rejected)
                ]
            ) == 0
        )
        #expect(
            try StepScoreCalculator().calculate(
                steps: [first, second],
                submissions: submissions
            ) == 10
        )
    }

    @Test("Langkah optional dan zero-point mengikuti poin terbit")
    func optionalAndZeroPointSteps() throws {
        let optional = step(
            1,
            points: 7,
            hasRequiredEvidence: false
        )
        let zero = step(2, points: 0)

        #expect(
            try StepScoreCalculator().calculate(
                steps: [optional, zero],
                submissions: [
                    submission(1, step: optional, status: .approved),
                    submission(2, step: zero, status: .approved)
                ]
            ) == 7
        )
    }

    @Test("Langkah inactive tidak dihitung dan poin negatif ditolak")
    func inactiveAndNegativeStep() {
        let inactive = step(1, points: 50)
        #expect(
            (
                try? StepScoreCalculator().calculate(
                    steps: [],
                    submissions: [
                        submission(1, step: inactive, status: .approved)
                    ]
                )
            ) == 0
        )
        #expect(throws: DomainError.self) {
            try StepScoreCalculator().calculate(
                steps: [step(2, points: -1)],
                submissions: []
            )
        }
    }

    @Test("Progress memisahkan required, optional, pending, dan rejected")
    func progressRules() {
        let required = [step(1, points: 10), step(2, points: 10)]
        let optional = [step(3, points: 5)]
        let result = ProgressCalculator().calculate(
            requiredSteps: required,
            optionalSteps: optional,
            currentDaySteps: required + optional,
            submissions: [
                submission(1, step: required[0], status: .pending),
                submission(2, step: required[1], status: .rejected),
                submission(3, step: optional[0], status: .approved)
            ]
        )

        #expect(result.requiredStepCount == 2)
        #expect(result.completedRequiredStepCount == 1)
        #expect(result.completedOptionalStepCount == 1)
        #expect(result.overallPercentage == 50)
        #expect(result.currentDayPercentage == 67)
        #expect(!result.isOverallComplete)
        #expect(!result.isCurrentDayComplete)
    }

    @Test("Enrollment score menjaga adjustment terpisah")
    func enrollmentScoreBreakdown() throws {
        let program = program(
            timeZone: "Asia/Makassar",
            days: [day(1, date: Date(), steps: [step(1, points: 25)])]
        )
        let result = try EnrollmentScoreCalculator().calculate(
            program: program,
            submissions: [
                submission(1, step: program.days[0].steps[0], status: .approved)
            ],
            weighIns: [
                weighIn(1, type: .initial, weight: 80),
                weighIn(2, type: .final, weight: 79)
            ],
            adjustmentPoints: -5,
            currentDayID: program.days[0].id
        )

        #expect(result.score.approvedStepPoints == 25)
        #expect(result.score.weightPoints == 800)
        #expect(result.score.adjustmentPoints == -5)
        #expect(result.score.totalPoints == 820)
        #expect(result.progress.isOverallComplete)
    }

    @Test("Ranking memakai urutan tie-break lengkap")
    func leaderboardTieBreakOrder() throws {
        let early = try date("2026-07-26T01:00:00Z")
        let late = try date("2026-07-26T02:00:00Z")
        let candidates = [
            candidate(5, step: 80, weight: 10, adjustment: 10, at: early),
            candidate(4, step: 80, weight: 15, adjustment: 5, at: early),
            candidate(3, step: 90, weight: 10, adjustment: 0, at: late),
            candidate(2, step: 90, weight: 10, adjustment: 0, at: early),
            candidate(1, step: 100, weight: 50, adjustment: 0, at: late)
        ]

        let ranked = LeaderboardSorter().sort(candidates)

        #expect(ranked.map(\.id) == [
            id(1), // total points tertinggi
            id(2), // step lebih tinggi, lalu selesai lebih awal
            id(3),
            id(4), // step sama, weight lebih tinggi
            id(5)
        ])
        #expect(ranked.map(\.rank) == [1, 2, 3, 4, 5])
    }

    @Test("UUID menjadi fallback ranking yang stabil")
    func deterministicUUIDFallback() {
        let candidates = [
            candidate(2, step: 10, weight: 0, adjustment: 0),
            candidate(1, step: 10, weight: 0, adjustment: 0)
        ]

        #expect(
            LeaderboardSorter().sort(candidates).map(\.id)
                == [id(1), id(2)]
        )
    }

    @Test("Winner selector mendukung kurang dari lima dan snapshot stabil")
    func winnerLockStability() throws {
        let lockedAt = try date("2026-07-27T00:00:00Z")
        let entries = LeaderboardSorter().sort([
            candidate(1, step: 100, weight: 0, adjustment: 0),
            candidate(2, step: 90, weight: 0, adjustment: 0),
            candidate(3, step: 80, weight: 0, adjustment: 0)
        ])
        let selector = WinnerSelector()
        let winners = selector.select(
            from: entries,
            programID: id(700),
            lockedAt: lockedAt
        )
        var changedEntries = entries
        changedEntries[2].score.adjustmentPoints = 1_000

        #expect(winners.count == 3)
        #expect(winners.map(\.participantID) == entries.map(\.participantID))
        #expect(
            selector.scoresChanged(
                lockedWinners: winners,
                currentEntries: changedEntries
            )
        )
        #expect(winners[0].totalPoints == 100)
    }

    @Test("Repository lock idempoten dan reset tersedia untuk Debug")
    func repositoryWinnerLockAndReset() async throws {
        let seed = try MockSeedData.load()
        let repository = InMemoryAppRepository(
            seed: seed
        )
        let programID = try #require(
            seed.programs.first { $0.status == .active }
        ).id
        let lockedAt = try date("2026-07-27T00:00:00Z")
        let first = try await repository.lockTopFive(
            programID: programID,
            lockedAt: lockedAt
        )
        let second = try await repository.lockTopFive(
            programID: programID,
            lockedAt: lockedAt.addingTimeInterval(3_600)
        )

        #expect(first.count == 5)
        #expect(first == second)
        await repository.resetLockedWinnersForDebug(programID: programID)
        #expect(try await repository.winners(programID: programID).isEmpty)
    }

    @MainActor
    @Test("Pilihan peringkat hanya memuat program yang diikuti peserta")
    func participantLeaderboardProgramSelection() async throws {
        let store = ParticipantJourneyStore(environment: .preview)

        await store.load()

        #expect(store.activeLeaderboardPrograms.map(\.title) == [
            "Gerak konsisten 3 hari",
            "Transformasi 7 hari"
        ])
        #expect(store.archivedLeaderboardPrograms.map(\.title) == [
            "Konsisten Juni"
        ])
        let currentProgram = try #require(store.snapshot?.activeProgram)
        #expect(store.selectedLeaderboardProgramID == currentProgram.id)

        let otherProgram = try #require(
            store.activeLeaderboardPrograms.first {
                $0.id != currentProgram.id
            }
        )
        await store.selectLeaderboardProgram(otherProgram.id)

        guard case .loaded(let snapshot) = store.leaderboardState else {
            Issue.record("Peringkat program kedua tidak berhasil dimuat.")
            return
        }
        #expect(snapshot.program.id == otherProgram.id)
        #expect(!snapshot.entries.isEmpty)
    }

    @MainActor
    @Test("Riwayat peringkat memuat snapshot pemenang program selesai")
    func participantLeaderboardArchiveSelection() async throws {
        let store = ParticipantJourneyStore(environment: .preview)
        await store.load()
        let archivedProgram = try #require(
            store.archivedLeaderboardPrograms.first
        )

        await store.selectLeaderboardProgram(archivedProgram.id)

        guard case .loaded(let snapshot) = store.leaderboardState else {
            Issue.record("Snapshot peringkat riwayat tidak berhasil dimuat.")
            return
        }
        #expect(snapshot.program.id == archivedProgram.id)
        #expect(snapshot.winners.count == 5)
        #expect(snapshot.winners.first?.rank == 1)
        #expect(store.selectedLeaderboardProgramID == archivedProgram.id)
    }

    @Test("Rentang tanggal peringkat mengikuti durasi hari program")
    func participantLeaderboardProgramDateRange() throws {
        let activeProgram = try #require(
            try MockSeedData.load().programs.first {
                $0.status == .active
            }
        )

        #expect(
            ParticipantLeaderboardFormatting.range(activeProgram)
                == "24 Jul 2026 – 30 Jul 2026"
        )
    }

    @Test("Poin lima digit memakai pemisah ribuan Indonesia")
    func participantLeaderboardFiveDigitPoints() {
        #expect(
            ParticipantLeaderboardFormatting.points(12_350) == "12.350"
        )
        #expect(
            ParticipantLeaderboardFormatting.points(98_765) == "98.765"
        )
    }

    @Test("Resolver hari memakai timezone program bukan timezone perangkat")
    func programTimezoneDiffersFromDevice() throws {
        let scheduled = try date("2026-01-02T10:00:00Z")
        let program = program(
            timeZone: "Pacific/Honolulu",
            days: [day(1, date: scheduled)]
        )
        let now = try date("2026-01-03T09:30:00Z")

        #expect(
            ProgramDayResolver().activeDay(in: program, at: now)?.dayNumber
                == 1
        )
    }

    @Test("Resolver stabil pada batas hari dan timezone daylight saving")
    func dayBoundaryAndDaylightSaving() throws {
        let makassarDay = day(
            1,
            date: try date("2026-07-25T16:00:00Z")
        )
        let makassarProgram = program(
            timeZone: "Asia/Makassar",
            days: [makassarDay]
        )
        #expect(
            ProgramDayResolver().activeDay(
                in: makassarProgram,
                at: try date("2026-07-26T15:59:59Z")
            )?.id == makassarDay.id
        )

        let newYorkDay = day(
            2,
            date: try date("2026-03-08T05:00:00Z")
        )
        let newYorkProgram = program(
            timeZone: "America/New_York",
            days: [newYorkDay]
        )
        #expect(
            ProgramDayResolver().activeDay(
                in: newYorkProgram,
                at: try date("2026-03-09T03:30:00Z")
            )?.id == newYorkDay.id
        )
    }

    @Test("Resolver mengembalikan nil sebelum mulai dan setelah selesai")
    func beforeStartAndAfterEnd() throws {
        let scheduled = try date("2026-07-26T00:00:00Z")
        let program = program(
            timeZone: "UTC",
            days: [day(1, date: scheduled)]
        )

        #expect(
            ProgramDayResolver().activeDay(
                in: program,
                at: try date("2026-07-25T23:59:59Z")
            ) == nil
        )
        #expect(
            ProgramDayResolver().activeDay(
                in: program,
                at: try date("2026-07-27T00:00:00Z")
            ) == nil
        )
    }

    @Test("Visibility menghormati hidden future dan read-only past")
    func visibilityPolicies() throws {
        let now = try date("2026-07-26T12:00:00Z")
        var future = day(
            1,
            date: try date("2026-07-27T00:00:00Z")
        )
        future.visibilityMode = .hidden
        let past = day(
            2,
            date: try date("2026-07-25T00:00:00Z")
        )
        let standardFuture = day(
            3,
            date: try date("2026-07-27T00:00:00Z")
        )
        let evaluator = VisibilityPolicyEvaluator()

        #expect(
            evaluator.access(
                for: future,
                now: now,
                timeZoneIdentifier: "UTC",
                pastPolicy: .readOnly,
                futurePolicy: .open
            ) == .hidden
        )
        #expect(
            evaluator.access(
                for: past,
                now: now,
                timeZoneIdentifier: "UTC",
                pastPolicy: .readOnly,
                futurePolicy: .open
            ) == .readOnly
        )
        #expect(
            evaluator.access(
                for: standardFuture,
                now: now,
                timeZoneIdentifier: "UTC",
                pastPolicy: .hidden,
                futurePolicy: .hidden
            ) == .hidden
        )
        #expect(
            evaluator.access(
                for: standardFuture,
                now: now,
                timeZoneIdentifier: "UTC",
                pastPolicy: .hidden,
                futurePolicy: .open
            ) == .available
        )
        #expect(
            evaluator.access(
                for: past,
                now: now,
                timeZoneIdentifier: "UTC",
                pastPolicy: .open,
                futurePolicy: .hidden
            ) == .available
        )
    }

    private func step(
        _ value: Int,
        points: Int,
        hasRequiredEvidence: Bool = true
    ) -> ProgramStep {
        ProgramStep(
            id: id(value),
            programDayID: id(900),
            order: value,
            title: "Langkah \(value)",
            instructions: "Petunjuk lokal.",
            points: points,
            instructionMedia: nil,
            requirements: hasRequiredEvidence
                ? [
                    StepRequirement(
                        id: id(value + 100),
                        kind: .photoEvidence,
                        isRequired: true,
                        prompt: nil
                    )
                ]
                : [],
            verificationMode: .coachReview
        )
    }

    private func submission(
        _ value: Int,
        step: ProgramStep,
        status: SubmissionStatus
    ) -> StepSubmission {
        StepSubmission(
            id: id(value + 200),
            enrollmentID: id(800),
            stepID: step.id,
            evidence: [],
            status: status,
            submittedAt: Date(timeIntervalSince1970: TimeInterval(value)),
            reviewedAt: nil,
            reviewerID: nil,
            reviewNote: nil
        )
    }

    private func weighIn(
        _ value: Int,
        type: WeighInType,
        weight: Decimal
    ) -> WeighIn {
        WeighIn(
            id: id(value + 300),
            enrollmentID: id(800),
            type: type,
            weightKilograms: weight,
            recordedAt: Date(timeIntervalSince1970: TimeInterval(value))
        )
    }

    private func candidate(
        _ value: Int,
        step: Int,
        weight: Int,
        adjustment: Int,
        at date: Date? = nil
    ) -> LeaderboardRankingCandidate {
        LeaderboardRankingCandidate(
            entry: LeaderboardEntry(
                id: id(value),
                programID: id(700),
                participantID: id(value + 500),
                participantDisplayName: "Peserta \(value)",
                rank: 0,
                progressPercentage: 100,
                score: ScoreBreakdown(
                    approvedStepPoints: step,
                    weightPoints: weight,
                    adjustmentPoints: adjustment
                ),
                isCurrentUser: false
            ),
            completionTimestamp: date
        )
    }

    private func day(
        _ value: Int,
        date: Date,
        steps: [ProgramStep] = []
    ) -> ProgramDay {
        ProgramDay(
            id: id(value + 900),
            programID: id(1_000),
            dayNumber: value,
            title: "Hari \(value)",
            scheduledDate: date,
            visibilityMode: .standard,
            steps: steps
        )
    }

    private func program(
        timeZone: String,
        days: [ProgramDay]
    ) -> Program {
        Program(
            id: id(1_000),
            title: "Program uji",
            summary: "Fixture deterministik.",
            status: .active,
            startDate: days.map(\.scheduledDate).min() ?? .distantPast,
            endDate: days.map(\.scheduledDate).max() ?? .distantFuture,
            timeZoneIdentifier: timeZone,
            weightPointsPerKilogram: 800,
            days: days
        )
    }

    private func id(_ value: Int) -> UUID {
        UUID(
            uuidString: String(
                format: "00000000-0000-0000-0000-%012d",
                value
            )
        )!
    }

    private func date(_ value: String) throws -> Date {
        try Date.ISO8601FormatStyle().parse(value)
    }
}
