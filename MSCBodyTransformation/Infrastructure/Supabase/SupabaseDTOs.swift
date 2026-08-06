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
    let registrationClosesAt: String?
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
        case registrationClosesAt = "registration_closes_at"
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
            registrationClosesAt: try registrationClosesAt.map(
                SupabaseDateParser.timestamp
            ),
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

nonisolated struct SupabasePublicCoachDTO: Decodable, Sendable {
    let id: UUID
    let displayName: String
    let biography: String
    let city: String
    let photoReference: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case biography
        case city
        case photoReference = "photo_reference"
    }

    func domain() -> CoachProfile {
        CoachProfile(
            id: id,
            userID: id,
            enrollmentIdentifier: "",
            displayName: displayName,
            biography: biography,
            city: city,
            localPhotoReference: photoReference,
            isPublic: true,
            isApproved: true
        )
    }
}

nonisolated struct SupabasePublicLeaderboardDTO: Decodable, Sendable {
    let id: UUID
    let programID: UUID
    let participantID: UUID
    let participantDisplayName: String
    let rank: Int
    let progressPercentage: Int
    let totalPoints: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case programID = "program_id"
        case participantID = "participant_id"
        case participantDisplayName = "participant_display_name"
        case rank
        case progressPercentage = "progress_percentage"
        case totalPoints = "total_points"
    }

    func domain() -> LeaderboardEntry {
        LeaderboardEntry(
            id: id,
            programID: programID,
            participantID: participantID,
            participantDisplayName: participantDisplayName,
            rank: rank,
            progressPercentage: progressPercentage,
            score: ScoreBreakdown(
                approvedStepPoints: totalPoints,
                quizPoints: 0,
                weightPoints: 0,
                adjustmentPoints: 0
            ),
            isCurrentUser: false
        )
    }
}

nonisolated struct SupabasePublicWinnerDTO: Decodable, Sendable {
    let id: UUID
    let programID: UUID
    let participantID: UUID
    let rank: Int
    let participantDisplayName: String
    let totalPoints: Int
    let lockedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case programID = "program_id"
        case participantID = "participant_id"
        case rank
        case participantDisplayName = "participant_display_name"
        case totalPoints = "total_points"
        case lockedAt = "locked_at"
    }

    func domain() -> ProgramWinner {
        ProgramWinner(
            id: id,
            programID: programID,
            participantID: participantID,
            rank: rank,
            participantDisplayName: participantDisplayName,
            totalPoints: totalPoints,
            lockedAt: lockedAt
        )
    }
}

nonisolated struct SupabasePublicManagedContentDTO: Decodable, Sendable {
    let id: UUID
    let kind: String
    let title: String
    let body: String
    let mediaReference: String?
    let programID: UUID?
    let winnerSnapshotID: UUID?
    let visibleFrom: Date?
    let visibleUntil: Date?
    let sortOrder: Int
    let isPublished: Bool
    let isArchived: Bool
    let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case body
        case mediaReference = "media_reference"
        case programID = "program_id"
        case winnerSnapshotID = "winner_snapshot_id"
        case visibleFrom = "visible_from"
        case visibleUntil = "visible_until"
        case sortOrder = "sort_order"
        case isPublished = "is_published"
        case isArchived = "is_archived"
        case updatedAt = "updated_at"
    }

    func domain() throws -> ManagedContent {
        guard let kind = ManagedContentKind(rawValue: kind) else {
            throw SupabaseDTOError.invalidField("managedContent.kind")
        }
        return ManagedContent(
            id: id,
            kind: kind,
            title: title,
            body: body,
            localMediaReference: mediaReference,
            programID: programID,
            winnerSnapshotID: winnerSnapshotID,
            visibleFrom: visibleFrom,
            visibleUntil: visibleUntil,
            sortOrder: sortOrder,
            isPublished: isPublished,
            isArchived: isArchived,
            updatedAt: updatedAt
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

nonisolated struct SupabaseAuthenticatedAccountDTO:
    Decodable,
    Sendable
{
    let userID: UUID
    let publicProfileID: UUID
    let role: String
    let displayName: String
    let city: String
    let phoneNumber: String?
    let currentCoachID: UUID?
    let providerAvatarURL: String?
    let memberLevel: String?
    let onboardingStatus: String
    let accountPurpose: String

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case publicProfileID = "public_profile_id"
        case role
        case displayName = "display_name"
        case city
        case phoneNumber = "phone_number"
        case currentCoachID = "current_coach_id"
        case providerAvatarURL = "provider_avatar_url"
        case memberLevel = "member_level"
        case onboardingStatus = "onboarding_status"
        case accountPurpose = "account_purpose"
    }

    func domain() throws -> AuthenticatedAccountReadModel {
        guard let role = UserRole(rawValue: role) else {
            throw SupabaseDTOError.invalidField("profile.role")
        }
        let memberLevel: MemberLevel?
        if let rawMemberLevel = self.memberLevel {
            guard let parsedMemberLevel = MemberLevel(
                rawValue: rawMemberLevel
            ) else {
                throw SupabaseDTOError.invalidField("profile.memberLevel")
            }
            memberLevel = parsedMemberLevel
        } else {
            memberLevel = nil
        }
        guard let onboardingStatus = ProfileOnboardingStatus(
            rawValue: onboardingStatus
        ) else {
            throw SupabaseDTOError.invalidField(
                "profile.onboardingStatus"
            )
        }
        guard let accountPurpose = AccountPurpose(
            rawValue: accountPurpose
        ) else {
            throw SupabaseDTOError.invalidField("profile.accountPurpose")
        }
        return AuthenticatedAccountReadModel(
            publicProfileID: publicProfileID,
            role: role,
            displayName: displayName,
            city: city,
            phoneNumber: phoneNumber,
            currentCoachID: currentCoachID,
            avatarReference: providerAvatarURL,
            memberLevel: memberLevel,
            onboardingStatus: onboardingStatus,
            accountPurpose: accountPurpose
        )
    }
}

nonisolated struct SupabaseAssignedCoachDTO: Decodable, Sendable {
    let userID: UUID
    let publicProfileID: UUID
    let displayName: String
    let city: String
    let providerAvatarURL: String?
    let isPublic: Bool
    let isApproved: Bool

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case publicProfileID = "public_profile_id"
        case displayName = "display_name"
        case city
        case providerAvatarURL = "provider_avatar_url"
        case isPublic = "is_public"
        case isApproved = "is_approved"
    }

    func domain() -> AuthenticatedAssignedCoachReadModel {
        AuthenticatedAssignedCoachReadModel(
            publicProfileID: publicProfileID,
            profile: CoachProfile(
                id: userID,
                userID: userID,
                enrollmentIdentifier: "",
                displayName: displayName,
                biography: "",
                city: city,
                localPhotoReference: providerAvatarURL,
                isPublic: isPublic,
                isApproved: isApproved
            )
        )
    }
}

nonisolated struct SupabaseProgramDayAccessDTO: Decodable, Sendable {
    let enrollmentID: UUID
    let programID: UUID
    let programDayID: UUID
    let dayNumber: Int
    let accessState: String
    let isCurrentDay: Bool

    private enum CodingKeys: String, CodingKey {
        case enrollmentID = "enrollment_id"
        case programID = "program_id"
        case programDayID = "program_day_id"
        case dayNumber = "day_number"
        case accessState = "access_state"
        case isCurrentDay = "is_current_day"
    }

    func domain() throws -> AuthenticatedProgramDayAccessState {
        guard let access = ProgramDayAccess(rawValue: accessState) else {
            throw SupabaseDTOError.invalidField("programDay.access")
        }
        return AuthenticatedProgramDayAccessState(
            enrollmentID: enrollmentID,
            programID: programID,
            programDayID: programDayID,
            dayNumber: dayNumber,
            access: access,
            isCurrentDay: isCurrentDay
        )
    }
}

nonisolated struct SupabaseDashboardSummaryDTO: Decodable, Sendable {
    let accountRole: String
    let activeEnrollmentCount: Int
    let completedEnrollmentCount: Int
    let pendingSubmissionCount: Int
    let assignedParticipantCount: Int

    private enum CodingKeys: String, CodingKey {
        case accountRole = "account_role"
        case activeEnrollmentCount = "active_enrollment_count"
        case completedEnrollmentCount = "completed_enrollment_count"
        case pendingSubmissionCount = "pending_submission_count"
        case assignedParticipantCount = "assigned_participant_count"
    }

    func domain() throws -> AuthenticatedDashboardSummary {
        guard let role = UserRole(rawValue: accountRole) else {
            throw SupabaseDTOError.invalidField("dashboard.role")
        }
        return AuthenticatedDashboardSummary(
            role: role,
            activeEnrollmentCount: activeEnrollmentCount,
            completedEnrollmentCount: completedEnrollmentCount,
            pendingSubmissionCount: pendingSubmissionCount,
            assignedParticipantCount: assignedParticipantCount
        )
    }
}

nonisolated struct SupabaseSubmissionAnswerReadDTO:
    Decodable,
    Sendable
{
    let id: UUID
    let questionID: UUID
    let textValue: String?
    let numberValue: Decimal?
    let selectedOptionIDs: [UUID]
    let privatePhotoPath: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case questionID = "question_id"
        case textValue = "text_value"
        case numberValue = "number_value"
        case selectedOptionIDs = "selected_option_ids"
        case privatePhotoPath = "private_photo_path"
    }

    func domain() -> StepSubmissionAnswer {
        StepSubmissionAnswer(
            id: id,
            questionID: questionID,
            textValue: textValue,
            numberValue: numberValue,
            selectedOptionIDs: selectedOptionIDs,
            localPhotoReference: privatePhotoPath
        )
    }
}

nonisolated struct SupabaseQuizResultReadDTO: Decodable, Sendable {
    let id: UUID
    let correctCount: Int
    let totalCount: Int
    let percentage: Int
    let passed: Bool
    let awardedPoints: Int
    let reopenedAt: Date?
    let reopenedBy: UUID?
    let reopenReason: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case correctCount = "correct_count"
        case totalCount = "total_count"
        case percentage
        case passed
        case awardedPoints = "awarded_points"
        case reopenedAt = "reopened_at"
        case reopenedBy = "reopened_by"
        case reopenReason = "reopen_reason"
    }
}

nonisolated struct SupabaseSubmissionReadDTO: Decodable, Sendable {
    let id: UUID
    let enrollmentID: UUID
    let stepID: UUID
    let attemptSequence: Int
    let status: String
    let submittedAt: Date
    let reviewedAt: Date?
    let reviewerID: UUID?
    let reviewNote: String?
    let answers: [SupabaseSubmissionAnswerReadDTO]
    let quizResult: SupabaseQuizResultReadDTO?

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
        case answers = "step_submission_answers"
        case quizResult = "quiz_attempt_results"
    }

    func domain() throws -> StepSubmission {
        guard let status = SubmissionStatus(rawValue: status) else {
            throw SupabaseDTOError.invalidField("submission.status")
        }
        let mappedQuizResult = quizResult.map {
            QuizAttemptResult(
                id: $0.id,
                enrollmentID: enrollmentID,
                stepID: stepID,
                sequence: attemptSequence,
                correctAnswerCount: $0.correctCount,
                totalQuestionCount: $0.totalCount,
                percentage: $0.percentage,
                isPassed: $0.passed,
                awardedPoints: $0.awardedPoints,
                submittedAt: submittedAt,
                reopenedAt: $0.reopenedAt,
                reopenedByAdminID: $0.reopenedBy,
                reopenReason: $0.reopenReason
            )
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
            answers: answers.map { $0.domain() },
            attemptSequence: attemptSequence,
            quizResult: mappedQuizResult
        )
    }
}

nonisolated struct SupabaseWeighInReadDTO: Decodable, Sendable {
    let id: UUID
    let enrollmentID: UUID
    let stepID: UUID?
    let kind: String
    let weightKilograms: Decimal
    let recordedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case enrollmentID = "enrollment_id"
        case stepID = "step_id"
        case kind
        case weightKilograms = "weight_kg"
        case recordedAt = "recorded_at"
    }

    func domain() throws -> WeighIn {
        guard let type = WeighInType(rawValue: kind) else {
            throw SupabaseDTOError.invalidField("weighIn.kind")
        }
        return WeighIn(
            id: id,
            enrollmentID: enrollmentID,
            stepID: stepID,
            type: type,
            weightKilograms: weightKilograms,
            recordedAt: recordedAt
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
    let publicID: UUID?
    let enrollmentID: UUID
    let activityPoints: Int
    let quizPoints: Int
    let weightPoints: Int
    let adjustmentPoints: Int
    let progressPercentage: Int
    let rank: Int?

    private enum CodingKeys: String, CodingKey {
        case publicID = "public_id"
        case enrollmentID = "enrollment_id"
        case activityPoints = "activity_points"
        case quizPoints = "quiz_points"
        case weightPoints = "weight_points"
        case adjustmentPoints = "adjustment_points"
        case progressPercentage = "progress_percentage"
        case rank
    }

    func ownLeaderboardEntry(
        programID: UUID,
        participantID: UUID,
        displayName: String
    ) -> LeaderboardEntry {
        LeaderboardEntry(
            id: publicID ?? enrollmentID,
            programID: programID,
            participantID: participantID,
            participantDisplayName: displayName,
            rank: rank ?? 0,
            progressPercentage: progressPercentage,
            score: ScoreBreakdown(
                approvedStepPoints: activityPoints,
                quizPoints: quizPoints,
                weightPoints: weightPoints,
                adjustmentPoints: adjustmentPoints
            ),
            isCurrentUser: true
        )
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

    static func timestamp(_ value: String) throws -> Date {
        if let date = try? Date.ISO8601FormatStyle(
            includingFractionalSeconds: true
        ).parse(value) {
            return date
        }
        if let date = try? Date.ISO8601FormatStyle().parse(value) {
            return date
        }
        throw SupabaseDTOError.invalidField("timestamp")
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
