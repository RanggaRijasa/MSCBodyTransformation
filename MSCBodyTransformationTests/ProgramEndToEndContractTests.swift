import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Kontrak program end-to-end")
struct ProgramEndToEndContractTests {
    @Test("Kontrak typed dapat encode dan decode tanpa kehilangan field")
    func contractJSONRoundTripIsLossless() throws {
        let source = makeProgram()
        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(Program.self, from: data)

        #expect(decoded == source)
        #expect(decoded.effectiveScoringConfiguration.pointsPerActivity == 25)
        #expect(decoded.days[0].steps[0].content?.kind == .quiz)
        #expect(
            decoded.days[0].steps[0].content?.questions[0].answerKey
                != nil
        )
    }

    @Test("Admin draft dan published contract mempunyai mapping lossless")
    func adminDraftPublishedRoundTripIsLossless() {
        let source = makeProgram()
        let draft = AdminProgramDraft(
            program: source,
            updatedAt: source.startDate
        )

        #expect(draft.program() == source)
    }

    @Test("Cover gambar dan timbang harian bertahan pada round trip Admin")
    func coverAndDailyWeighInSurviveAdminRoundTrip() {
        var source = makeProgram()
        let dayID = UUID()
        source.days.append(
            ProgramDay(
                id: dayID,
                programID: source.id,
                dayNumber: 2,
                title: "Hari 2",
                scheduledDate: source.startDate.addingTimeInterval(86_400),
                visibilityMode: .standard,
                steps: [
                    ProgramStep(
                        id: UUID(),
                        programDayID: dayID,
                        order: 1,
                        title: "Timbang harian",
                        instructions: "Catat progres hari ini.",
                        instructionMedia: nil,
                        verificationMode: .coachReview,
                        content: ProgramStepContent(
                            kind: .dailyWeighIn,
                            questions: [],
                            completionPolicy: .submitWeighIn
                        )
                    )
                ]
            )
        )

        let published = AdminProgramDraft(
            program: source,
            updatedAt: source.startDate
        ).program()

        #expect(published.coverLocalReference == "cover-juni")
        #expect(
            published.coverAlternativeText
                == "Peserta sedang berolahraga."
        )
        #expect(
            published.days[1].steps[0].content?.kind == .dailyWeighIn
        )
        #expect(
            published.days[1].steps[0].verificationMode == .automatic
        )
    }

    @Test("Langkah mendatang dapat dibuka, dikunci, atau disembunyikan")
    func futureDayPolicyHasThreeDistinctBehaviors() {
        var program = makeProgram()
        let referenceDate = program.startDate.addingTimeInterval(-86_400)
        let day = program.days[0]
        let calculator = ProgramDayAccessCalculator()

        program.futureStepPolicy = .available
        #expect(
            calculator.access(
                for: day,
                in: program,
                now: referenceDate
            ) == .available
        )

        program.futureStepPolicy = .locked
        #expect(
            calculator.access(
                for: day,
                in: program,
                now: referenceDate
            ) == .locked
        )

        program.futureStepPolicy = .hidden
        #expect(
            calculator.access(
                for: day,
                in: program,
                now: referenceDate
            ) == .hidden
        )
    }

    @Test("Timbang harian unik per langkah dan tidak mengubah poin berat")
    func dailyWeighInsAreStepScopedAndDoNotChangeWeightPoints()
        async throws
    {
        var program = makeProgram()
        let firstDailyStepID = UUID()
        let secondDailyStepID = UUID()
        let dailyStep = ProgramStep(
            id: firstDailyStepID,
            programDayID: program.days[0].id,
            order: 2,
            title: "Timbang harian",
            instructions: "Catat progres hari ini.",
            instructionMedia: nil,
            verificationMode: .automatic,
            content: ProgramStepContent(
                kind: .dailyWeighIn,
                questions: [],
                completionPolicy: .submitWeighIn
            )
        )
        program.days[0].steps.append(dailyStep)
        let setup = makeLocalSetup(programs: [program])
        let enrollment = try await setup.repository.createEnrollment(
            ProgramEnrollment(
                id: UUID(),
                programID: program.id,
                participantID: setup.participant.id,
                coachID: setup.coach.id,
                status: .active,
                enrolledAt: program.startDate
            )
        )
        let identifierGenerator = SequenceIdentifierGenerator()
        let useCase = SubmitLocalWeighInUseCase(
            repository: setup.repository,
            identifierGenerator: identifierGenerator,
            clock: FixedClock(now: program.startDate),
            validator: WeighInValidator()
        )
        _ = try await useCase(
            enrollmentID: enrollment.id,
            stepID: firstDailyStepID,
            type: .daily,
            weightKilograms: 79
        )
        _ = try await useCase(
            enrollmentID: enrollment.id,
            stepID: secondDailyStepID,
            type: .daily,
            weightKilograms: 78
        )
        _ = try await useCase(
            enrollmentID: enrollment.id,
            stepID: firstDailyStepID,
            type: .daily,
            weightKilograms: 77
        )

        let dailyWeighIns = try await setup.repository.weighIns(
            enrollmentID: enrollment.id
        )
        #expect(dailyWeighIns.count == 2)
        #expect(Set(dailyWeighIns.compactMap(\.stepID)).count == 2)

        let dailySubmission = try await CompleteTypedStepUseCase(
            repository: setup.repository,
            identifierGenerator: identifierGenerator,
            clock: FixedClock(now: program.startDate)
        )(
            enrollmentID: enrollment.id,
            step: dailyStep,
            answers: [],
            scoring: program.effectiveScoringConfiguration
        )
        #expect(dailySubmission.status == .approved)

        let score = try EnrollmentScoreCalculator().calculate(
            program: program,
            submissions: [dailySubmission],
            weighIns: [
                WeighIn(
                    id: UUID(),
                    enrollmentID: enrollment.id,
                    type: .initial,
                    weightKilograms: 80,
                    recordedAt: program.startDate
                ),
                dailyWeighIns[0],
                dailyWeighIns[1],
                WeighIn(
                    id: UUID(),
                    enrollmentID: enrollment.id,
                    type: .final,
                    weightKilograms: 77,
                    recordedAt: program.endDate
                )
            ],
            adjustmentPoints: 0
        )

        #expect(score.score.weightPoints == 300)
        #expect(score.score.approvedStepPoints == 0)
        #expect(score.progress.completedRequiredStepCount == 1)
        #expect(score.progress.overallPercentage == 50)
    }

    @Test("Timbang harian wajib terkait dengan langkah program")
    func dailyWeighInRequiresStepIdentifier() async throws {
        let program = makeProgram()
        let setup = makeLocalSetup(programs: [program])
        let enrollment = try await setup.repository.createEnrollment(
            ProgramEnrollment(
                id: UUID(),
                programID: program.id,
                participantID: setup.participant.id,
                coachID: setup.coach.id,
                status: .active,
                enrolledAt: program.startDate
            )
        )

        await #expect(throws: DomainError.self) {
            _ = try await SubmitLocalWeighInUseCase(
                repository: setup.repository,
                identifierGenerator: SequenceIdentifierGenerator(),
                clock: FixedClock(now: program.startDate),
                validator: WeighInValidator()
            )(
                enrollmentID: enrollment.id,
                type: .daily,
                weightKilograms: 79
            )
        }
    }

    @Test("Duplikasi mengganti semua ID dan menggeser tanggal kalender")
    func duplicateChangesIdentifiersAndShiftsCalendarDates() throws {
        let source = makeProgram()
        let identifiers = SequenceIdentifierGenerator()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Makassar"))
        let julyStart = try #require(
            calendar.date(
                from: DateComponents(year: 2026, month: 7, day: 5)
            )
        )

        let duplicate = try DuplicateProgramAsDraftUseCase(
            identifierGenerator: identifiers
        )(
            source: source,
            request: DuplicateProgramRequest(
                title: "Program Juli",
                startDate: julyStart,
                endDate: nil
            )
        )

        #expect(duplicate.id != source.id)
        #expect(duplicate.sourceProgramID == source.id)
        #expect(duplicate.status == .draft)
        #expect(duplicate.title == "Program Juli")
        #expect(
            calendar.component(.month, from: duplicate.days[0].scheduledDate)
                == 7
        )
        #expect(
            calendar.component(.day, from: duplicate.days[0].scheduledDate)
                == 5
        )
        #expect(duplicate.days[0].id != source.days[0].id)
        #expect(
            duplicate.days[0].steps[0].id
                != source.days[0].steps[0].id
        )
        let sourceQuestion = try #require(
            source.days[0].steps[0].content?.questions.first
        )
        let duplicatedQuestion = try #require(
            duplicate.days[0].steps[0].content?.questions.first
        )
        #expect(duplicatedQuestion.id != sourceQuestion.id)
        #expect(
            duplicatedQuestion.options[0].id
                != sourceQuestion.options[0].id
        )
        #expect(
            duplicatedQuestion.answerKey?.selectedOptionIDs
                == [duplicatedQuestion.options[0].id]
        )
        #expect(
            duplicate.effectiveCommerceConfiguration.desiredPrice
                == source.effectiveCommerceConfiguration.desiredPrice
        )
        #expect(
            duplicate.effectiveCommerceConfiguration.platformAvailability
                .allSatisfy { $0.provisioningStatus == .notRequested }
        )
    }

    @Test("Kuis dinilai sekali dengan poin per jawaban benar")
    func quizUsesProgramWidePoints() throws {
        let program = makeProgram()
        let question = try #require(
            program.days[0].steps[0].content?.questions.first
        )
        let answer = StepSubmissionAnswer(
            id: UUID(),
            questionID: question.id,
            textValue: nil,
            numberValue: nil,
            selectedOptionIDs: [question.options[0].id],
            localPhotoReference: nil
        )

        let result = try QuizEvaluator().evaluate(
            questions: [question],
            answers: [answer],
            scoring: program.effectiveScoringConfiguration
        )

        #expect(result.correctAnswerCount == 1)
        #expect(result.percentage == 100)
        #expect(result.isPassed)
        #expect(result.awardedPoints == 25)
    }

    @Test("Semua pertanyaan interaktif wajib dijawab")
    func interactiveQuestionsAreRequired() {
        let question = ProgramQuestionDefinition(
            id: UUID(),
            order: 1,
            kind: .shortAnswer,
            prompt: "Apa fokusmu?",
            options: [],
            answerKey: nil
        )

        #expect(throws: DomainError.self) {
            try StepAnswerValidator().validate(
                questions: [question],
                answers: []
            )
        }
    }

    @Test("Semua jenis pertanyaan memakai jawaban typed yang valid")
    func allQuestionKindsUseTypedAnswers() throws {
        let choiceOption = ProgramQuestionOption(
            id: UUID(),
            order: 1,
            title: "Pilihan",
            mediaReference: "choice-image",
            mediaAlternativeText: "Pilihan bergambar"
        )
        let interactiveKinds = ProgramQuestionKind.allCases.filter(
            \.isInteractive
        )
        let questions = interactiveKinds.enumerated().map { index, kind in
            ProgramQuestionDefinition(
                id: UUID(),
                order: index + 1,
                kind: kind,
                prompt: "Pertanyaan \(index + 1)",
                options: kind.acceptsOptions ? [choiceOption] : [],
                answerKey: nil
            )
        } + [
            ProgramQuestionDefinition(
                id: UUID(),
                order: interactiveKinds.count + 1,
                kind: .heading,
                prompt: "Bagian",
                options: [],
                answerKey: nil
            ),
            ProgramQuestionDefinition(
                id: UUID(),
                order: interactiveKinds.count + 2,
                kind: .text,
                prompt: "Petunjuk",
                options: [],
                answerKey: nil
            )
        ]
        let answers = questions.compactMap { question
            -> StepSubmissionAnswer? in
            guard question.kind.isInteractive else { return nil }
            return StepSubmissionAnswer(
                id: UUID(),
                questionID: question.id,
                textValue: {
                    switch question.kind {
                    case .shortAnswer, .longAnswer:
                        "Jawaban"
                    default:
                        nil
                    }
                }(),
                numberValue: question.kind == .number ? 42 : nil,
                selectedOptionIDs: question.kind.acceptsOptions
                    ? [choiceOption.id]
                    : [],
                localPhotoReference: question.kind == .photoUpload
                    ? "private/photo.jpg"
                    : nil
            )
        }

        try StepAnswerValidator().validate(
            questions: questions,
            answers: answers
        )
    }

    @Test("Kuis menolak percobaan kedua sampai Admin membuka ulang")
    func quizSecondAttemptIsRejected() async throws {
        let program = makeProgram()
        let setup = makeLocalSetup(programs: [program])
        let repository = setup.repository
        let enrollment = try await repository.createEnrollment(
            ProgramEnrollment(
                id: UUID(),
                programID: program.id,
                participantID: setup.participant.id,
                coachID: setup.coach.id,
                status: .active,
                enrolledAt: program.startDate
            )
        )
        let step = try #require(program.days.first?.steps.first)
        let question = try #require(step.content?.questions.first)
        let answer = StepSubmissionAnswer(
            id: UUID(),
            questionID: question.id,
            textValue: nil,
            numberValue: nil,
            selectedOptionIDs: [question.options[0].id],
            localPhotoReference: nil
        )
        let identifierGenerator = SequenceIdentifierGenerator()
        let first = try await CompleteTypedStepUseCase(
            repository: repository,
            identifierGenerator: identifierGenerator,
            clock: FixedClock(now: program.startDate)
        )(
            enrollmentID: enrollment.id,
            step: step,
            answers: [answer],
            scoring: program.effectiveScoringConfiguration
        )

        let callback = try await repository.completeStep(submission: first)
        #expect(callback.id == first.id)
        await #expect(throws: DomainError.self) {
            _ = try await CompleteTypedStepUseCase(
                repository: repository,
                identifierGenerator: identifierGenerator,
                clock: FixedClock(now: program.startDate)
            )(
                enrollmentID: enrollment.id,
                step: step,
                answers: [answer],
                scoring: program.effectiveScoringConfiguration
            )
        }

        let adminID = UUID(
            uuidString: "A0000000-0000-0000-0000-000000000001"
        )!
        let reopened = try await ReopenQuizAttemptUseCase(
            submissions: repository,
            audit: repository,
            identifierGenerator: identifierGenerator,
            clock: FixedClock(now: program.startDate)
        )(
            enrollmentID: enrollment.id,
            stepID: step.id,
            adminID: adminID,
            reason: "Peserta mengalami kendala teknis."
        )
        #expect(reopened.reopenedByAdminID == adminID)
        #expect(
            reopened.reopenReason == "Peserta mengalami kendala teknis."
        )

        let second = try await CompleteTypedStepUseCase(
            repository: repository,
            identifierGenerator: identifierGenerator,
            clock: FixedClock(now: program.startDate)
        )(
            enrollmentID: enrollment.id,
            step: step,
            answers: [answer],
            scoring: program.effectiveScoringConfiguration
        )
        #expect(second.quizResult?.sequence == 2)
        let history = try await repository.quizAttempts(
            enrollmentID: enrollment.id,
            stepID: step.id
        )
        #expect(history.map(\.sequence) == [1, 2])
        #expect(history.first?.reopenReason != nil)
        #expect(
            try await repository.auditEventsForAdministration().contains {
                $0.kind == .quizAttemptReopened
                    && $0.subjectID == reopened.id
            }
        )
    }

    @Test("Coach pertama berlaku untuk program lain dan QR berbeda ditolak")
    func firstCoachPersistsAcrossPrograms() async throws {
        let firstProgram = makeProgram()
        var secondProgram = makeProgram()
        secondProgram = Program(
            id: UUID(),
            title: "Program kedua",
            summary: secondProgram.summary,
            price: nil,
            status: .active,
            startDate: secondProgram.startDate,
            endDate: secondProgram.endDate,
            timeZoneIdentifier: secondProgram.timeZoneIdentifier,
            weightPointsPerKilogram: 0,
            days: []
        )
        let setup = makeLocalSetup(programs: [firstProgram, secondProgram])
        _ = try await setup.repository.createEnrollment(
            ProgramEnrollment(
                id: UUID(),
                programID: firstProgram.id,
                participantID: setup.participant.id,
                coachID: setup.coach.id,
                status: .active,
                enrolledAt: firstProgram.startDate
            )
        )
        let sameCoachEnrollment = try await setup.repository.createEnrollment(
            ProgramEnrollment(
                id: UUID(),
                programID: secondProgram.id,
                participantID: setup.participant.id,
                coachID: setup.coach.id,
                status: .active,
                enrolledAt: secondProgram.startDate
            )
        )

        #expect(sameCoachEnrollment.coachID == setup.coach.id)
        #expect(
            try await setup.repository.leaderboard(
                programID: secondProgram.id
            ).count == 1
        )

        let otherCoach = CoachProfile(
            id: UUID(),
            userID: UUID(),
            enrollmentIdentifier: "coach-lain",
            displayName: "Coach lain",
            biography: "",
            city: "Denpasar",
            localPhotoReference: nil,
            isPublic: true,
            isApproved: true
        )
        let setupWithOtherCoach = makeLocalSetup(
            programs: [firstProgram, secondProgram],
            extraCoaches: [otherCoach]
        )
        _ = try await setupWithOtherCoach.repository.createEnrollment(
            ProgramEnrollment(
                id: UUID(),
                programID: firstProgram.id,
                participantID: setupWithOtherCoach.participant.id,
                coachID: setupWithOtherCoach.coach.id,
                status: .active,
                enrolledAt: firstProgram.startDate
            )
        )
        await #expect(throws: DomainError.self) {
            _ = try await setupWithOtherCoach.repository.createEnrollment(
                ProgramEnrollment(
                    id: UUID(),
                    programID: secondProgram.id,
                    participantID: setupWithOtherCoach.participant.id,
                    coachID: otherCoach.id,
                    status: .active,
                    enrolledAt: secondProgram.startDate
                )
            )
        }
    }

    @Test("Review tertunda memblokir winner lock dan snapshot tetap stabil")
    func closureBlocksPendingReviewAndLocksStableSnapshot() async throws {
        var program = makeProgram()
        program.days[0].steps[0].verificationMode = .coachReview
        program.days[0].steps[0].content = ProgramStepContent(
            kind: .form,
            questions: [
                ProgramQuestionDefinition(
                    id: UUID(),
                    order: 1,
                    kind: .longAnswer,
                    prompt: "Refleksi",
                    options: [],
                    answerKey: nil
                )
            ],
            completionPolicy: .answerAllQuestions,
            videoConfiguration: nil
        )
        let setup = makeLocalSetup(programs: [program])
        let enrollment = try await setup.repository.createEnrollment(
            ProgramEnrollment(
                id: UUID(),
                programID: program.id,
                participantID: setup.participant.id,
                coachID: setup.coach.id,
                status: .active,
                enrolledAt: program.startDate
            )
        )
        let submission = try await setup.repository.completeStep(
            submission: StepSubmission(
                id: UUID(),
                enrollmentID: enrollment.id,
                stepID: program.days[0].steps[0].id,
                status: .pending,
                submittedAt: program.endDate,
                reviewedAt: nil,
                reviewerID: nil,
                reviewNote: nil,
                answers: [
                    StepSubmissionAnswer(
                        id: UUID(),
                        questionID: program.days[0].steps[0]
                            .content!.questions[0].id,
                        textValue: "Selesai",
                        numberValue: nil,
                        selectedOptionIDs: [],
                        localPhotoReference: nil
                    )
                ]
            )
        )
        let useCase = LockAdminWinnersUseCase(
            leaderboard: setup.repository,
            enrollments: setup.repository,
            submissions: setup.repository,
            weighIns: setup.repository,
            audit: setup.repository,
            identifierGenerator: SequenceIdentifierGenerator(),
            clock: FixedClock(now: program.endDate)
        )

        await #expect(throws: DomainError.self) {
            _ = try await useCase(
                program: program,
                programID: program.id,
                adminID: UUID()
            )
        }
        _ = try await setup.repository.reviewSubmission(
            id: submission.id,
            reviewerID: setup.coach.id,
            status: .approved,
            note: nil,
            reviewedAt: program.endDate
        )
        let first = try await useCase(
            program: program,
            programID: program.id,
            adminID: UUID()
        )
        _ = try await setup.repository.applyScoreAdjustment(
            entryID: try #require(
                try await setup.repository.leaderboard(
                    programID: program.id
                ).first?.id
            ),
            points: 500
        )
        let second = try await useCase(
            program: program,
            programID: program.id,
            adminID: UUID()
        )

        #expect(!first.isEmpty)
        #expect(second == first)
    }

    @Test("Poster terbit wajib terkait program dan snapshot")
    func publishedPosterRequiresSnapshotRelationship() throws {
        let poster = ManagedContent(
            id: UUID(),
            kind: .winnerBanner,
            title: "Poster pemenang",
            body: "Pemenang program.",
            localMediaReference: "poster.jpg",
            programID: UUID(),
            winnerSnapshotID: UUID(),
            visibleFrom: nil,
            visibleUntil: nil,
            sortOrder: 1,
            isPublished: true,
            isArchived: false,
            updatedAt: Date()
        )
        try ManagedContentValidator().validate(poster)

        var invalidPoster = poster
        invalidPoster.winnerSnapshotID = nil
        #expect(throws: DomainError.self) {
            try ManagedContentValidator().validate(invalidPoster)
        }
    }

    @Test("Koreksi timbang Admin memerlukan alasan dan tercatat di audit")
    func adminWeighInCorrectionIsAudited() async throws {
        let program = makeProgram()
        let setup = makeLocalSetup(programs: [program])
        let enrollment = try await setup.repository.createEnrollment(
            ProgramEnrollment(
                id: UUID(),
                programID: program.id,
                participantID: setup.participant.id,
                coachID: setup.coach.id,
                status: .active,
                enrolledAt: program.startDate
            )
        )
        let original = WeighIn(
            id: UUID(),
            enrollmentID: enrollment.id,
            type: .initial,
            weightKilograms: 80,
            recordedAt: program.startDate
        )
        _ = try await setup.repository.save(weighIn: original)

        await #expect(throws: DomainError.self) {
            _ = try await CorrectWeighInUseCase(
                weighIns: setup.repository,
                audit: setup.repository,
                identifierGenerator: SequenceIdentifierGenerator(),
                clock: FixedClock(now: program.startDate)
            )(
                enrollmentID: enrollment.id,
                type: .initial,
                weightKilograms: 79,
                adminID: UUID(),
                reason: " "
            )
        }

        let corrected = try await CorrectWeighInUseCase(
            weighIns: setup.repository,
            audit: setup.repository,
            identifierGenerator: SequenceIdentifierGenerator(),
            clock: FixedClock(now: program.startDate)
        )(
            enrollmentID: enrollment.id,
            type: .initial,
            weightKilograms: 79,
            adminID: UUID(),
            reason: "Salah input saat pencatatan."
        )
        #expect(corrected.id == original.id)
        #expect(corrected.weightKilograms == 79)
        #expect(
            try await setup.repository.auditEventsForAdministration()
                .contains { $0.kind == .weighInCorrected }
        )
    }

    @Test("Resubmission menyimpan histori penolakan")
    func rejectedSubmissionHistoryIsPreserved() async throws {
        let program = makeProgram()
        let setup = makeLocalSetup(programs: [program])
        let enrollment = try await setup.repository.createEnrollment(
            ProgramEnrollment(
                id: UUID(),
                programID: program.id,
                participantID: setup.participant.id,
                coachID: setup.coach.id,
                status: .active,
                enrolledAt: program.startDate
            )
        )
        let stepID = try #require(program.days.first?.steps.first?.id)
        let first = try await setup.repository.completeStep(
            submission: StepSubmission(
                id: UUID(),
                enrollmentID: enrollment.id,
                stepID: stepID,
                status: .pending,
                submittedAt: program.startDate,
                reviewedAt: nil,
                reviewerID: nil,
                reviewNote: nil,
                answers: []
            )
        )
        _ = try await setup.repository.reviewSubmission(
            id: first.id,
            reviewerID: setup.coach.id,
            status: .rejected,
            note: "Foto belum jelas.",
            reviewedAt: program.startDate
        )
        let replacement = StepSubmission(
            id: UUID(),
            enrollmentID: enrollment.id,
            stepID: stepID,
            status: .pending,
            submittedAt: program.endDate,
            reviewedAt: nil,
            reviewerID: nil,
            reviewNote: nil,
            answers: []
        )
        _ = try await setup.repository.completeStep(
            submission: replacement
        )
        let history = try await setup.repository.submissionHistory(
            enrollmentID: enrollment.id,
            stepID: stepID
        )
        #expect(history.count == 2)
        #expect(history.first?.status == .rejected)
        #expect(history.last?.id == replacement.id)
    }

    private func makeProgram() -> Program {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Makassar")!
        let start = calendar.date(
            from: DateComponents(year: 2026, month: 6, day: 5)
        )!
        let end = calendar.date(
            from: DateComponents(year: 2026, month: 6, day: 15)
        )!
        let programID = UUID(
            uuidString: "A0000000-0000-0000-0000-000000000001"
        )!
        let dayID = UUID(
            uuidString: "A0000000-0000-0000-0000-000000000002"
        )!
        let stepID = UUID(
            uuidString: "A0000000-0000-0000-0000-000000000003"
        )!
        let questionID = UUID(
            uuidString: "A0000000-0000-0000-0000-000000000004"
        )!
        let correctOptionID = UUID(
            uuidString: "A0000000-0000-0000-0000-000000000005"
        )!
        let wrongOptionID = UUID(
            uuidString: "A0000000-0000-0000-0000-000000000006"
        )!
        let question = ProgramQuestionDefinition(
            id: questionID,
            order: 1,
            kind: .singleChoice,
            prompt: "Pilih jawaban benar.",
            options: [
                ProgramQuestionOption(
                    id: correctOptionID,
                    order: 1,
                    title: "Benar",
                    mediaReference: nil,
                    mediaAlternativeText: nil
                ),
                ProgramQuestionOption(
                    id: wrongOptionID,
                    order: 2,
                    title: "Salah",
                    mediaReference: nil,
                    mediaAlternativeText: nil
                )
            ],
            answerKey: ProgramQuestionAnswerKey(
                selectedOptionIDs: [correctOptionID]
            )
        )
        let step = ProgramStep(
            id: stepID,
            programDayID: dayID,
            order: 1,
            title: "Kuis pembuka",
            instructions: "Jawab semua pertanyaan.",
            instructionMedia: nil,
            verificationMode: .automatic,
            content: ProgramStepContent(
                kind: .quiz,
                questions: [question],
                completionPolicy: .automaticQuiz,
                videoConfiguration: nil
            )
        )
        let day = ProgramDay(
            id: dayID,
            programID: programID,
            dayNumber: 1,
            title: "Hari 1",
            scheduledDate: start,
            visibilityMode: .standard,
            steps: [step]
        )
        return Program(
            id: programID,
            title: "Program Juni",
            summary: "Program lengkap.",
            category: "Kebiasaan",
            coverLocalReference: "cover-juni",
            coverAlternativeText: "Peserta sedang berolahraga.",
            price: 149_000,
            status: .active,
            startDate: start,
            endDate: end,
            timeZoneIdentifier: "Asia/Makassar",
            weightPointsPerKilogram: 100,
            scoringConfiguration: ProgramScoringConfiguration(
                pointsPerActivity: 25,
                pointsPerWeightLossKilogram: 100,
                quizPassingPercentage: 70
            ),
            commerceConfiguration: ProgramCommerceConfiguration(
                pricingMode: .paid,
                desiredPrice: 149_000,
                platformAvailability: CommercePlatform.allCases.map {
                    ProgramPlatformAvailability(
                        platform: $0,
                        isEnabled: true,
                        provisioningStatus: .ready
                    )
                }
            ),
            pace: .scheduled,
            durationMode: .specificDates,
            participantLimit: 100,
            pastStepPolicy: .available,
            futureStepPolicy: .locked,
            wellnessDisclaimer: "Program kebiasaan sehat.",
            days: [day]
        )
    }

    private func makeLocalSetup(
        programs: [Program],
        extraCoaches: [CoachProfile] = []
    ) -> (
        repository: InMemoryAppRepository,
        participant: ParticipantProfile,
        coach: CoachProfile
    ) {
        let participantUserID = UUID()
        let participant = ParticipantProfile(
            id: UUID(),
            userID: participantUserID,
            coachID: nil,
            displayName: "Peserta uji",
            city: "Denpasar",
            phoneNumber: nil,
            localPhotoReference: nil
        )
        let coachUserID = UUID()
        let coach = CoachProfile(
            id: UUID(),
            userID: coachUserID,
            enrollmentIdentifier: "coach-uji",
            displayName: "Coach uji",
            biography: "",
            city: "Denpasar",
            localPhotoReference: nil,
            isPublic: true,
            isApproved: true
        )
        let users = [
            AppUser(
                id: participantUserID,
                email: "peserta@example.invalid",
                displayName: participant.displayName,
                role: .participant,
                hasCompletedOnboarding: true,
                isCoachApprovalPending: false,
                createdAt: Date()
            ),
            AppUser(
                id: coachUserID,
                email: "coach@example.invalid",
                displayName: coach.displayName,
                role: .coach,
                hasCompletedOnboarding: true,
                isCoachApprovalPending: false,
                createdAt: Date()
            )
        ]
        return (
            InMemoryAppRepository(
                seed: MockSeedData(
                    users: users,
                    participantProfiles: [participant],
                    coachProfiles: [coach] + extraCoaches,
                    programs: programs,
                    enrollments: [],
                    weighIns: [],
                    submissions: [],
                    leaderboardEntries: [],
                    winners: [],
                    managedContent: [],
                    auditEvents: []
                )
            ),
            participant,
            coach
        )
    }
}

private final class SequenceIdentifierGenerator:
    IdentifierGenerating,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var sequence = 10_000

    func makeIdentifier() -> UUID {
        lock.lock()
        defer { lock.unlock() }
        sequence += 1
        return UUID(
            uuidString: String(
                format: "B0000000-0000-0000-0000-%012d",
                sequence
            )
        )!
    }
}
