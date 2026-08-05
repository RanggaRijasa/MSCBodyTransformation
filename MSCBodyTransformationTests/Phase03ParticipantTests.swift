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

    @Test("Validasi pertanyaan memerlukan foto dan jawaban")
    func stepValidation() throws {
        let program = try MockSeedData.load().programs.first {
            $0.status == .active
        }
        let photoQuestion = try #require(
            program?.days.flatMap(\.steps).first {
                $0.content?.questions.contains {
                    $0.kind == .photoUpload
                } == true
            }?.content?.questions.first { $0.kind == .photoUpload }
        )
        let textQuestion = try #require(
            program?.days.flatMap(\.steps).first {
                $0.content?.questions.contains {
                    $0.kind == .shortAnswer
                } == true
            }?.content?.questions.first { $0.kind == .shortAnswer }
        )

        #expect(throws: DomainError.self) {
            try StepAnswerValidator().validate(
                questions: [photoQuestion],
                answers: []
            )
        }
        #expect(throws: DomainError.self) {
            try StepAnswerValidator().validate(
                questions: [textQuestion],
                answers: []
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

        #expect(progress == 13)
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

    @Test("Hari lampau dengan aktivitas terbit tetap dapat dibuka")
    func publishedPastDayRemainsVisible() throws {
        let program = try #require(
            try MockSeedData.load().programs.first {
                $0.status == .active
            }
        )
        let publishedPastDay = try #require(
            program.days.first { $0.dayNumber == 4 }
        )
        let currentDay = try #require(
            program.days.first { $0.dayNumber == 5 }
        )

        #expect(publishedPastDay.visibilityMode == .standard)
        #expect(!publishedPastDay.steps.isEmpty)
        #expect(
            ProgramDayAccessCalculator().access(
                for: publishedPastDay,
                now: currentDay.scheduledDate,
                timeZoneIdentifier: program.timeZoneIdentifier
            ) == .available
        )
    }

    @Test("Presentasi hari mengikuti kontrak akses domain")
    func dayPresentationContract() {
        let available = ProgramActivityDayUIState(access: .available)
        let readOnly = ProgramActivityDayUIState(access: .readOnly)
        let locked = ProgramActivityDayUIState(access: .locked)
        let hidden = ProgramActivityDayUIState(access: .hidden)

        #expect(available.showsActivities)
        #expect(available.allowsStepNavigation)
        #expect(available.allowsCompletion)
        #expect(!available.showsUnavailableMessage)

        #expect(readOnly.showsActivities)
        #expect(readOnly.allowsStepNavigation)
        #expect(!readOnly.allowsCompletion)
        #expect(!readOnly.showsUnavailableMessage)

        #expect(!locked.showsActivities)
        #expect(!locked.allowsStepNavigation)
        #expect(!locked.allowsCompletion)
        #expect(locked.showsUnavailableMessage)

        #expect(hidden == locked)
    }

    @MainActor
    @Test("Home memuat dua poster pemenang dan direktori coach publik")
    func homeHighlightsLoadFromLocalRepositories() async throws {
        let store = ParticipantJourneyStore(environment: .preview)

        await store.load()

        let snapshot = try #require(store.snapshot)
        let featuredPosters = Array(
            snapshot.featuredWinnerPosters.prefix(2)
        )

        #expect(featuredPosters.count == 2)
        #expect(
            featuredPosters.allSatisfy {
                $0.kind == .winnerBanner
                    && $0.localMediaReference?.isEmpty == false
            }
        )
        #expect(featuredPosters.map(\.sortOrder) == [1, 2])
        #expect(snapshot.coaches.count == 4)
        #expect(
            snapshot.coaches.allSatisfy {
                $0.isPublic && $0.isApproved
            }
        )
        #expect(
            snapshot.coaches.contains {
                $0.id == snapshot.activeEnrollment?.coachID
            }
        )
    }

    @MainActor
    @Test("Profil dapat diperbarui tanpa mengubah Coach aktif")
    func participantProfileUpdatePreservesCoach() async throws {
        let store = ParticipantJourneyStore(environment: .preview)
        await store.load()
        let originalCoachID = try #require(store.snapshot).profile.coachID

        try await store.updateParticipantProfile(
            displayName: "Ayu Baru",
            phoneNumber: "+62 812-3456-7890",
            localPhotoReference: "/tmp/ayu-profile.jpg"
        )

        var snapshot = try #require(store.snapshot)
        #expect(snapshot.profile.displayName == "Ayu Baru")
        #expect(snapshot.profile.phoneNumber == "+6281234567890")
        #expect(
            snapshot.profile.localPhotoReference
                == "/tmp/ayu-profile.jpg"
        )

        snapshot = try #require(store.snapshot)
        #expect(snapshot.profile.coachID == originalCoachID)
        #expect(
            snapshot.enrollments
                .filter {
                    $0.status == .initiated
                        || $0.status == .waitingForPayment
                        || $0.status == .active
                }
                .allSatisfy { $0.coachID == originalCoachID }
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
        let coachID = try #require(profile.coachID)
        let enrollment = try await JoinProgramWithCoachUseCase(
            enrollments: repository,
            identifierGenerator: identifiers,
            clock: clock
        )(
            program: program,
            participantID: profile.id,
            coachID: coachID
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
        _ = try await CompleteTypedStepUseCase(
            repository: repository,
            identifierGenerator: identifiers,
            clock: clock
        )(
            enrollmentID: enrollment.id,
            step: automaticStep,
            answers: automaticStep.content?.questions.compactMap {
                question in
                guard question.kind.isInteractive else { return nil }
                return StepSubmissionAnswer(
                    id: identifiers.makeIdentifier(),
                    questionID: question.id,
                    textValue: question.kind == .shortAnswer
                        || question.kind == .longAnswer
                        ? "Jawaban lengkap."
                        : nil,
                    numberValue: question.kind == .number ? 1 : nil,
                    selectedOptionIDs: question.kind.acceptsOptions
                        ? Array(question.options.prefix(1).map(\.id))
                        : [],
                    localPhotoReference: question.kind == .photoUpload
                        ? "local-demo://test/photo"
                        : nil
                )
            } ?? [],
            scoring: program.effectiveScoringConfiguration
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
        #expect(
            entry.progressPercentage
                == ProgramProgressCalculator().percentage(
                    totalStepCount: program.days.flatMap(\.steps).count,
                    submissions: try await repository.submissions(
                        enrollmentID: enrollment.id
                    )
                )
        )
        #expect(
            entry.score.approvedStepPoints
                == program.effectiveScoringConfiguration.pointsPerActivity
        )
    }

    @Test("Program dapat diikuti melalui identifier coach tanpa kuota")
    func joinProgramWithCoachIdentifier() async throws {
        let seed = try MockSeedData.load()
        let repository = InMemoryAppRepository(seed: seed)
        let participant = try #require(seed.participantProfiles.first)
        let coach = try #require(seed.coachProfiles.first)
        let program = try #require(
            seed.programs.first { $0.status == .scheduled }
        )

        let enrollment = try await JoinProgramWithCoachUseCase(
            enrollments: repository,
            identifierGenerator: DeterministicIdentifierGenerator(
                identifier: UUID(
                    uuidString:
                        "40000000-0000-0000-0000-000000009997"
                )!
            ),
            clock: FixedClock(now: currentDate)
        )(
            program: program,
            participantID: participant.id,
            coachID: coach.id
        )

        #expect(enrollment.programID == program.id)
        #expect(enrollment.coachID == coach.id)
        #expect(coach.enrollmentIdentifier == "COACH-RAKA-7K9Q")
        #expect(program.price == 99_000)
    }

    @Test("Batas pendaftaran menutup enrollment tepat pada waktunya")
    func registrationDeadlineBlocksEnrollmentAtCutoff() async throws {
        let seed = try MockSeedData.load()
        let repository = InMemoryAppRepository(seed: seed)
        let participant = try #require(seed.participantProfiles.first)
        let coach = try #require(seed.coachProfiles.first)
        var program = try #require(
            seed.programs.first { $0.status == .scheduled }
        )
        program.registrationClosesAt = currentDate

        do {
            _ = try await JoinProgramWithCoachUseCase(
                enrollments: repository,
                identifierGenerator: DeterministicIdentifierGenerator(
                    identifier: UUID(
                        uuidString:
                            "40000000-0000-0000-0000-000000009996"
                    )!
                ),
                clock: FixedClock(now: currentDate)
            )(
                program: program,
                participantID: participant.id,
                coachID: coach.id
            )
            Issue.record("Enrollment pada waktu penutupan harus ditolak.")
        } catch let error as DomainError {
            #expect(
                error == .conflict(
                    reason: "Pendaftaran program sudah ditutup."
                )
            )
        }

        #expect(
            try await repository.enrollment(
                programID: program.id,
                participantID: participant.id
            ) == nil
        )
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
        #expect(entry.score.weightPoints == 2_000)
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
