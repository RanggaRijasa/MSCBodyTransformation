import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Participant Phase 03")
struct Phase03ParticipantTests {
    private let currentDate = Date(
        timeIntervalSince1970: 1_785_027_600
    )

    @Test("Today memetakan hari program aktif")
    func todayStateMapping() async throws {
        let repository = InMemoryAppRepository(
            seed: try MockSeedData.load()
        )
        let today = try await LoadTodayProgramUseCase(
            repository: repository,
            clock: FixedClock(now: currentDate),
            accessCalculator: ProgramDayAccessCalculator()
        )()

        #expect(today?.day?.dayNumber == 3)
        #expect(today?.access == .available)
    }

    @Test("Validasi langkah memerlukan foto dan jawaban")
    func stepValidation() throws {
        let program = try MockSeedData.load().programs.first {
            $0.status == .active
        }
        let photoStep = try #require(
            program?.days.flatMap(\.steps).first {
                $0.requirements.contains {
                    $0.kind == .photoEvidence
                }
            }
        )
        let textStep = try #require(
            program?.days.flatMap(\.steps).first {
                $0.requirements.contains {
                    $0.kind == .textAnswer
                }
            }
        )

        #expect(throws: DomainError.self) {
            try StepSubmissionValidator().validate(
                step: photoStep,
                evidence: []
            )
        }
        #expect(throws: DomainError.self) {
            try StepSubmissionValidator().validate(
                step: textStep,
                evidence: []
            )
        }
    }

    @Test("Input berat Indonesia dan batas berat divalidasi")
    func weighInValidation() throws {
        let value = try IndonesianWeightInputParser().parse("78,5")

        #expect(value == Decimal(string: "78.5"))
        #expect(throws: DomainError.self) {
            try WeighInValidator().validate(weightKilograms: 24)
        }
        #expect(throws: DomainError.self) {
            try WeighInValidator().validate(weightKilograms: 351)
        }
        try WeighInValidator().validate(weightKilograms: value)
    }

    @Test("Progress menghitung submission unik yang tidak ditolak")
    func progressCalculation() throws {
        let seed = try MockSeedData.load()
        let enrollment = try #require(seed.enrollments.first)
        let submissions = seed.submissions.filter {
            $0.enrollmentID == enrollment.id
        }
        let totalSteps = try #require(
            seed.programs.first { $0.status == .active }
        ).days.flatMap(\.steps).count

        let progress = ProgramProgressCalculator().percentage(
            totalStepCount: totalSteps,
            submissions: submissions
        )

        #expect(progress == 14)
    }

    @Test("Hari mendatang tetap terkunci")
    func lockedStepBehavior() throws {
        let program = try #require(
            try MockSeedData.load().programs.first {
                $0.status == .active
            }
        )
        let futureDay = try #require(
            program.days.first { $0.dayNumber == 5 }
        )

        #expect(
            ProgramDayAccessCalculator().access(
                for: futureDay,
                now: currentDate,
                timeZoneIdentifier: program.timeZoneIdentifier
            ) == .locked
        )
    }

    @Test("Workflow lokal dapat join, timbang, dan menyelesaikan langkah")
    func localParticipantCompletion() async throws {
        let seed = try MockSeedData.load()
        let repository = InMemoryAppRepository(seed: seed)
        let profile = try #require(seed.participantProfiles.first)
        let program = try #require(
            seed.programs.first { $0.status == .active }
        )
        let automaticStep = try #require(
            program.days.first { $0.dayNumber == 3 }?
                .steps.first { $0.verificationMode == .automatic }
        )
        let identifier = UUID(
            uuidString: "90000000-0000-0000-0000-000000000001"
        )!
        let identifiers = DeterministicIdentifierGenerator(
            identifier: identifier
        )
        let clock = FixedClock(now: currentDate)

        await repository.resetParticipantDemo(
            participantID: profile.id
        )
        let enrollment = try await RedeemLocalInviteUseCase(
            repository: repository,
            identifierGenerator: identifiers,
            clock: clock
        )(
            code: "MSC7HARI",
            participantID: profile.id
        )
        _ = try await SubmitLocalWeighInUseCase(
            repository: repository,
            identifierGenerator: identifiers,
            clock: clock,
            validator: WeighInValidator()
        )(
            enrollmentID: enrollment.id,
            type: .initial,
            weightKilograms: Decimal(string: "78.5")!
        )
        _ = try await CompleteLocalStepUseCase(
            repository: repository,
            identifierGenerator: identifiers,
            clock: clock,
            validator: StepSubmissionValidator()
        )(
            enrollmentID: enrollment.id,
            step: automaticStep,
            evidence: [
                SubmissionEvidence(
                    id: identifier,
                    kind: .text,
                    localReference: nil,
                    textValue: "Saya ingin tetap bergerak setiap pagi."
                )
            ]
        )

        #expect(
            try await repository.enrollment(
                programID: program.id,
                participantID: profile.id
            ) != nil
        )
        #expect(
            try await repository.weighIns(
                enrollmentID: enrollment.id
            ).count == 1
        )
        #expect(
            try await repository.submissions(
                enrollmentID: enrollment.id
            ).count == 1
        )
        let entry = try #require(
            try await repository.leaderboard(
                programID: program.id
            ).first { $0.participantID == profile.id }
        )
        #expect(entry.progressPercentage == 5)
        #expect(entry.score.approvedStepPoints == automaticStep.points)
    }

    @Test("Berat akhir memperbarui poin lokal pada hari terakhir")
    func finalWeightFlow() async throws {
        let seed = try MockSeedData.load()
        let repository = InMemoryAppRepository(seed: seed)
        let enrollment = try #require(seed.enrollments.first)
        let program = try #require(
            seed.programs.first { $0.id == enrollment.programID }
        )
        let finalDate = try #require(
            program.days.max(by: {
                $0.dayNumber < $1.dayNumber
            })?.scheduledDate
        )

        try WeighInWindowValidator().validate(
            type: .final,
            now: finalDate,
            program: program
        )
        _ = try await SubmitLocalWeighInUseCase(
            repository: repository,
            identifierGenerator: DeterministicIdentifierGenerator(
                identifier: UUID(
                    uuidString:
                        "90000000-0000-0000-0000-000000000002"
                )!
            ),
            clock: FixedClock(now: finalDate),
            validator: WeighInValidator()
        )(
            enrollmentID: enrollment.id,
            type: .final,
            weightKilograms: Decimal(string: "76.0")!
        )

        let entry = try #require(
            try await repository.leaderboard(
                programID: program.id
            ).first { $0.participantID == enrollment.participantID }
        )
        #expect(entry.score.weightPoints == 25)
    }

    @Test("Berat akhir ditolak sebelum hari terakhir")
    func finalWeightWindowErrorMapping() throws {
        let program = try #require(
            try MockSeedData.load().programs.first {
                $0.status == .active
            }
        )

        #expect(throws: DomainError.self) {
            try WeighInWindowValidator().validate(
                type: .final,
                now: currentDate,
                program: program
            )
        }
        let message = DomainErrorMessageMapper.message(
            for: .validation(
                field: "weightKilograms",
                reason: "Belum tersedia."
            )
        )
        #expect(message.titleKey == "error.validation.title")
    }
}
