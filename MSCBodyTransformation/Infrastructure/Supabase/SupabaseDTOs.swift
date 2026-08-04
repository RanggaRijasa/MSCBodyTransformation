import Foundation

nonisolated enum SupabaseDTOError: Error, Equatable, Sendable {
    case invalidField(String)
}

nonisolated struct SupabaseProgramDTO: Decodable, Sendable {
    let id: UUID
    let sourceProgramID: UUID?
    let title: String
    let summary: String
    let category: String?
    let coverPath: String?
    let coverAltText: String?
    let status: String
    let pace: String
    let durationMode: String
    let startsOn: String
    let endsOn: String
    let timezone: String
    let participantLimit: Int?
    let pastStepPolicy: String
    let futureStepPolicy: String
    let wellnessDisclaimer: String
    let pointsPerActivity: Int
    let pointsPerWeightKg: Decimal
    let quizPassingPercentage: Int
    let pricingMode: String
    let desiredPrice: Decimal?
    let programDays: [SupabaseProgramDayDTO]

    private enum CodingKeys: String, CodingKey {
        case id
        case sourceProgramID = "source_program_id"
        case title
        case summary
        case category
        case coverPath = "cover_path"
        case coverAltText = "cover_alt_text"
        case status
        case pace
        case durationMode = "duration_mode"
        case startsOn = "starts_on"
        case endsOn = "ends_on"
        case timezone
        case participantLimit = "participant_limit"
        case pastStepPolicy = "past_step_policy"
        case futureStepPolicy = "future_step_policy"
        case wellnessDisclaimer = "wellness_disclaimer"
        case pointsPerActivity = "points_per_activity"
        case pointsPerWeightKg = "points_per_weight_kg"
        case quizPassingPercentage = "quiz_passing_percentage"
        case pricingMode = "pricing_mode"
        case desiredPrice = "desired_price"
        case programDays = "program_days"
    }

    func domain() throws -> Program {
        guard let status = ProgramStatus(rawValue: status) else {
            throw SupabaseDTOError.invalidField("program.status")
        }
        guard let pace = AdminProgramPace(rawValue: pace) else {
            throw SupabaseDTOError.invalidField("program.pace")
        }
        guard let durationMode = AdminProgramDurationMode(
            rawValue: durationMode
        ) else {
            throw SupabaseDTOError.invalidField("program.durationMode")
        }
        guard let pastPolicy = PastStepPolicy(
            rawValue: pastStepPolicy
        ) else {
            throw SupabaseDTOError.invalidField("program.pastStepPolicy")
        }
        guard let futurePolicy = FutureStepPolicy(
            rawValue: futureStepPolicy
        ) else {
            throw SupabaseDTOError.invalidField("program.futureStepPolicy")
        }
        guard let pricingMode = ProgramPricingMode(
            rawValue: pricingMode
        ) else {
            throw SupabaseDTOError.invalidField("program.pricingMode")
        }
        let startDate = try SupabaseDateParser.date(startsOn)
        let endDate = try SupabaseDateParser.date(endsOn)

        return Program(
            id: id,
            sourceProgramID: sourceProgramID,
            title: title,
            summary: summary,
            category: category,
            coverLocalReference: coverPath,
            coverAlternativeText: coverAltText,
            price: desiredPrice,
            status: status,
            startDate: startDate,
            endDate: endDate,
            timeZoneIdentifier: timezone,
            weightPointsPerKilogram: pointsPerWeightKg,
            scoringConfiguration: ProgramScoringConfiguration(
                pointsPerActivity: pointsPerActivity,
                pointsPerWeightLossKilogram: pointsPerWeightKg,
                quizPassingPercentage: quizPassingPercentage
            ),
            commerceConfiguration: ProgramCommerceConfiguration(
                pricingMode: pricingMode,
                desiredPrice: desiredPrice,
                platformAvailability: CommercePlatform.allCases.map {
                    ProgramPlatformAvailability(
                        platform: $0,
                        isEnabled: true,
                        provisioningStatus: pricingMode == .free
                            ? .notRequired
                            : .notRequested
                    )
                }
            ),
            pace: pace,
            durationMode: durationMode,
            participantLimit: participantLimit,
            pastStepPolicy: pastPolicy,
            futureStepPolicy: futurePolicy,
            wellnessDisclaimer: wellnessDisclaimer,
            days: try programDays
                .sorted { $0.dayNumber < $1.dayNumber }
                .map { try $0.domain(programID: id) }
        )
    }
}

nonisolated struct SupabaseProgramDayDTO: Decodable, Sendable {
    let id: UUID
    let dayNumber: Int
    let title: String
    let summary: String?
    let scheduledOn: String
    let programSteps: [SupabaseProgramStepDTO]

    private enum CodingKeys: String, CodingKey {
        case id
        case dayNumber = "day_number"
        case title
        case summary
        case scheduledOn = "scheduled_on"
        case programSteps = "program_steps"
    }

    func domain(programID: UUID) throws -> ProgramDay {
        ProgramDay(
            id: id,
            programID: programID,
            dayNumber: dayNumber,
            title: title,
            scheduledDate: try SupabaseDateParser.date(scheduledOn),
            visibilityMode: .standard,
            steps: try programSteps
                .sorted { $0.stepOrder < $1.stepOrder }
                .map { try $0.domain(programDayID: id) },
            summary: summary
        )
    }
}

nonisolated struct SupabaseProgramStepDTO: Decodable, Sendable {
    let id: UUID
    let stepOrder: Int
    let title: String
    let instructions: String
    let contentKind: String
    let completionPolicy: String
    let verificationMode: String
    let mediaPath: String?
    let mediaAltText: String?
    let videoRequired: Bool
    let videoThreshold: Int?
    let videoAutoplay: Bool
    let programQuestions: [SupabaseProgramQuestionDTO]

    private enum CodingKeys: String, CodingKey {
        case id
        case stepOrder = "step_order"
        case title
        case instructions
        case contentKind = "content_kind"
        case completionPolicy = "completion_policy"
        case verificationMode = "verification_mode"
        case mediaPath = "media_path"
        case mediaAltText = "media_alt_text"
        case videoRequired = "video_required"
        case videoThreshold = "video_threshold"
        case videoAutoplay = "video_autoplay"
        case programQuestions = "program_questions"
    }

    func domain(programDayID: UUID) throws -> ProgramStep {
        guard let kind = ProgramContentKind(rawValue: contentKind) else {
            throw SupabaseDTOError.invalidField("step.contentKind")
        }
        guard let completion = ProgramStepCompletionPolicy(
            rawValue: completionPolicy
        ) else {
            throw SupabaseDTOError.invalidField("step.completionPolicy")
        }
        guard let verification = SubmissionVerificationMode(
            rawValue: verificationMode
        ) else {
            throw SupabaseDTOError.invalidField("step.verificationMode")
        }
        let media: StepInstructionMedia? = if let mediaPath {
            StepInstructionMedia(
                kind: kind == .video ? .video : .image,
                resourceName: mediaPath,
                accessibilityLabel: mediaAltText ?? title
            )
        } else {
            nil
        }
        let videoConfiguration: ProgramVideoCompletionConfiguration? =
            if kind == .video {
                ProgramVideoCompletionConfiguration(
                    isRequiredToWatch: videoRequired,
                    completionThresholdPercentage: videoThreshold ?? 0,
                    isAutoplayEnabled: videoAutoplay
                )
            } else {
                nil
            }

        return ProgramStep(
            id: id,
            programDayID: programDayID,
            order: stepOrder,
            title: title,
            instructions: instructions,
            instructionMedia: media,
            verificationMode: verification,
            content: ProgramStepContent(
                kind: kind,
                questions: try programQuestions
                    .sorted { $0.questionOrder < $1.questionOrder }
                    .map { try $0.domain() },
                completionPolicy: completion,
                videoConfiguration: videoConfiguration
            )
        )
    }
}

nonisolated struct SupabaseProgramQuestionDTO: Decodable, Sendable {
    let id: UUID
    let questionOrder: Int
    let kind: String
    let prompt: String
    let programQuestionOptions: [SupabaseProgramQuestionOptionDTO]

    private enum CodingKeys: String, CodingKey {
        case id
        case questionOrder = "question_order"
        case kind
        case prompt
        case programQuestionOptions = "program_question_options"
    }

    func domain() throws -> ProgramQuestionDefinition {
        guard let kind = ProgramQuestionKind(rawValue: kind) else {
            throw SupabaseDTOError.invalidField("question.kind")
        }
        return ProgramQuestionDefinition(
            id: id,
            order: questionOrder,
            kind: kind,
            prompt: prompt,
            options: programQuestionOptions
                .sorted { $0.optionOrder < $1.optionOrder }
                .map { $0.domain() },
            answerKey: nil
        )
    }
}

nonisolated struct SupabaseProgramQuestionOptionDTO:
    Decodable,
    Sendable
{
    let id: UUID
    let optionOrder: Int
    let title: String
    let mediaPath: String?
    let mediaAltText: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case optionOrder = "option_order"
        case title
        case mediaPath = "media_path"
        case mediaAltText = "media_alt_text"
    }

    func domain() -> ProgramQuestionOption {
        ProgramQuestionOption(
            id: id,
            order: optionOrder,
            title: title,
            mediaReference: mediaPath,
            mediaAlternativeText: mediaAltText
        )
    }
}

nonisolated struct SupabaseEnrollmentDTO: Decodable, Sendable {
    let id: UUID
    let programID: UUID
    let participantID: UUID
    let coachID: UUID
    let status: String
    let enrolledAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case programID = "program_id"
        case participantID = "participant_id"
        case coachID = "coach_id"
        case status
        case enrolledAt = "enrolled_at"
    }

    func domain() throws -> ProgramEnrollment {
        guard let status = EnrollmentStatus(rawValue: status) else {
            throw SupabaseDTOError.invalidField("enrollment.status")
        }
        return ProgramEnrollment(
            id: id,
            programID: programID,
            participantID: participantID,
            coachID: coachID,
            status: status,
            enrolledAt: enrolledAt
        )
    }
}

nonisolated struct SupabaseSubmissionDTO: Decodable, Sendable {
    let id: UUID
    let enrollmentID: UUID
    let stepID: UUID
    let attemptSequence: Int
    let status: String
    let submittedAt: Date
    let reviewedAt: Date?
    let reviewerID: UUID?
    let reviewNote: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case enrollmentID = "enrollment_id"
        case stepID = "step_id"
        case attemptSequence = "attempt_sequence"
        case status
        case submittedAt = "submitted_at"
        case reviewedAt = "reviewed_at"
        case reviewerID = "reviewer_id"
        case reviewNote = "review_note"
    }

    func domain() throws -> StepSubmission {
        guard status != "draft",
              let status = SubmissionStatus(rawValue: status) else {
            throw SupabaseDTOError.invalidField("submission.status")
        }
        return StepSubmission(
            id: id,
            enrollmentID: enrollmentID,
            stepID: stepID,
            status: status,
            submittedAt: submittedAt,
            reviewedAt: reviewedAt,
            reviewerID: reviewerID,
            reviewNote: reviewNote,
            attemptSequence: attemptSequence
        )
    }
}

nonisolated struct SupabaseProgramScoreDTO: Decodable, Sendable {
    let enrollmentID: UUID
    let activityPoints: Int
    let quizPoints: Int
    let weightPoints: Int
    let adjustmentPoints: Int
    let progressPercentage: Int
    let rank: Int?

    private enum CodingKeys: String, CodingKey {
        case enrollmentID = "enrollment_id"
        case activityPoints = "activity_points"
        case quizPoints = "quiz_points"
        case weightPoints = "weight_points"
        case adjustmentPoints = "adjustment_points"
        case progressPercentage = "progress_percentage"
        case rank
    }
}

nonisolated enum SupabaseDateParser {
    static func date(_ value: String) throws -> Date {
        let components = value.split(separator: "-")
        guard components.count == 3,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]),
              let date = Calendar(identifier: .gregorian).date(
                from: DateComponents(
                    timeZone: TimeZone(secondsFromGMT: 0),
                    year: year,
                    month: month,
                    day: day
                )
              ) else {
            throw SupabaseDTOError.invalidField("date")
        }
        return date
    }
}

nonisolated enum SupabaseJSON {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static let encoder = JSONEncoder()
}
