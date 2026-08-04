import Foundation

nonisolated enum PastStepPolicy: String, Codable, CaseIterable, Sendable {
    case available
    case readOnly = "read_only"
    case hidden
}

nonisolated enum FutureStepPolicy: String, Codable, CaseIterable, Sendable {
    case available
    case locked
    case hidden
}

nonisolated enum AdminProgramPace:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case selfPaced = "self_paced"
    case scheduled
}

nonisolated enum AdminProgramDurationMode:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case fixedDuration = "fixed_duration"
    case specificDates = "specific_dates"
}

nonisolated enum AdminStepContentKind:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case article
    case video
    case form
    case quiz
    case initialWeighIn = "initial_weigh_in"
    case dailyWeighIn = "daily_weigh_in"
    case finalWeighIn = "final_weigh_in"

    var isWeighIn: Bool {
        switch self {
        case .initialWeighIn, .dailyWeighIn, .finalWeighIn:
            true
        case .article, .video, .form, .quiz:
            false
        }
    }
}

nonisolated enum AdminQuizQuestionKind:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case shortAnswer = "short_answer"
    case longAnswer = "long_answer"
    case number
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
    case imageChoice = "image_choice"
    case photoUpload = "photo_upload"
    case heading
    case text

    var acceptsOptions: Bool {
        switch self {
        case .singleChoice, .multipleChoice, .imageChoice:
            true
        case .shortAnswer, .longAnswer, .number, .photoUpload,
             .heading, .text:
            false
        }
    }

    var isLayoutElement: Bool {
        self == .heading || self == .text
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        if value == "file_upload" {
            self = .photoUpload
            return
        }
        guard let decoded = Self(rawValue: value) else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Jenis pertanyaan tidak dikenal: \(value)"
            )
        }
        self = decoded
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

nonisolated struct AdminQuizQuestionDraft:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    var order: Int
    var kind: AdminQuizQuestionKind
    var prompt: String
    var options: [String]
    var optionIDs: [UUID]
    var optionMediaReferences: [String?]
    var answerKey: ProgramQuestionAnswerKey?

    init(
        id: UUID,
        order: Int,
        kind: AdminQuizQuestionKind,
        prompt: String,
        options: [String],
        optionIDs: [UUID] = [],
        optionMediaReferences: [String?] = [],
        answerKey: ProgramQuestionAnswerKey? = nil
    ) {
        self.id = id
        self.order = order
        self.kind = kind
        self.prompt = prompt
        self.options = options
        self.optionIDs = optionIDs
        self.optionMediaReferences = optionMediaReferences
        self.answerKey = answerKey
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case order
        case kind
        case prompt
        case options
        case optionIDs
        case optionMediaReferences
        case answerKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        order = try container.decode(Int.self, forKey: .order)
        kind = try container.decode(AdminQuizQuestionKind.self, forKey: .kind)
        prompt = try container.decode(String.self, forKey: .prompt)
        options = try container.decodeIfPresent(
            [String].self,
            forKey: .options
        ) ?? []
        optionIDs = try container.decodeIfPresent(
            [UUID].self,
            forKey: .optionIDs
        ) ?? []
        optionMediaReferences = try container.decodeIfPresent(
            [String?].self,
            forKey: .optionMediaReferences
        ) ?? []
        answerKey = try container.decodeIfPresent(
            ProgramQuestionAnswerKey.self,
            forKey: .answerKey
        )
    }
}

nonisolated struct AdminQuizDraft: Codable, Equatable, Sendable {
    var title: String
    var questions: [AdminQuizQuestionDraft]
}

nonisolated struct AdminStepDraft: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var order: Int
    var title: String
    var instructions: String
    var mediaKind: StepInstructionMediaKind?
    var localMediaReference: String?
    var isActive: Bool
    var verificationMode: SubmissionVerificationMode
    var contentKind: AdminStepContentKind
    var isVideoRequiredToWatch: Bool
    var isVideoAutoplayEnabled: Bool
    var quiz: AdminQuizDraft?
    var publishedContent: ProgramStepContent?

    init(
        id: UUID,
        order: Int,
        title: String,
        instructions: String,
        mediaKind: StepInstructionMediaKind?,
        localMediaReference: String?,
        isActive: Bool,
        verificationMode: SubmissionVerificationMode,
        contentKind: AdminStepContentKind = .article,
        isVideoRequiredToWatch: Bool = false,
        isVideoAutoplayEnabled: Bool = false,
        quiz: AdminQuizDraft? = nil,
        publishedContent: ProgramStepContent? = nil
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.instructions = instructions
        self.mediaKind = mediaKind
        self.localMediaReference = localMediaReference
        self.isActive = isActive
        self.verificationMode = verificationMode
        self.contentKind = contentKind
        self.isVideoRequiredToWatch = isVideoRequiredToWatch
        self.isVideoAutoplayEnabled = isVideoAutoplayEnabled
        self.quiz = quiz
        self.publishedContent = publishedContent
    }
}

nonisolated struct AdminDayDraft: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var dayNumber: Int
    var title: String
    var summary: String
    var scheduledDate: Date
    var steps: [AdminStepDraft]
}

nonisolated struct AdminProgramDraft:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    var sourceProgramID: UUID?
    var title: String
    var summary: String
    var price: Decimal?
    var category: String
    var coverLocalReference: String?
    var coverAlternativeText: String
    var verificationMode: SubmissionVerificationMode
    var wellnessDisclaimer: String
    var pace: AdminProgramPace
    var durationMode: AdminProgramDurationMode
    var fixedDurationDays: Int
    var startDate: Date
    var endDate: Date
    var timeZoneIdentifier: String
    var initialWeighInWindowHours: Int
    var finalWeighInWindowHours: Int
    var weightPointsPerKilogram: Decimal
    var pointsPerActivity: Int
    var quizPassingPercentage: Int
    var commerceConfiguration: ProgramCommerceConfiguration?
    var pastStepPolicy: PastStepPolicy
    var futureStepPolicy: FutureStepPolicy
    var participantLimit: Int?
    var status: ProgramStatus
    var days: [AdminDayDraft]
    var updatedAt: Date

    init(
        id: UUID,
        title: String,
        summary: String,
        price: Decimal? = nil,
        coverLocalReference: String?,
        verificationMode: SubmissionVerificationMode,
        wellnessDisclaimer: String,
        startDate: Date,
        endDate: Date,
        timeZoneIdentifier: String,
        initialWeighInWindowHours: Int,
        finalWeighInWindowHours: Int,
        weightPointsPerKilogram: Decimal,
        pastStepPolicy: PastStepPolicy,
        futureStepPolicy: FutureStepPolicy,
        status: ProgramStatus,
        days: [AdminDayDraft],
        updatedAt: Date,
        category: String = "",
        coverAlternativeText: String = "",
        pace: AdminProgramPace = .scheduled,
        durationMode: AdminProgramDurationMode = .specificDates,
        fixedDurationDays: Int = 7,
        participantLimit: Int? = nil,
        sourceProgramID: UUID? = nil,
        pointsPerActivity: Int = 10,
        quizPassingPercentage: Int = 70,
        commerceConfiguration: ProgramCommerceConfiguration? = nil
    ) {
        self.id = id
        self.sourceProgramID = sourceProgramID
        self.title = title
        self.summary = summary
        self.price = price
        self.category = category
        self.coverLocalReference = coverLocalReference
        self.coverAlternativeText = coverAlternativeText
        self.verificationMode = verificationMode
        self.wellnessDisclaimer = wellnessDisclaimer
        self.pace = pace
        self.durationMode = durationMode
        self.fixedDurationDays = fixedDurationDays
        self.startDate = startDate
        self.endDate = endDate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.initialWeighInWindowHours = initialWeighInWindowHours
        self.finalWeighInWindowHours = finalWeighInWindowHours
        self.weightPointsPerKilogram = weightPointsPerKilogram
        self.pointsPerActivity = pointsPerActivity
        self.quizPassingPercentage = quizPassingPercentage
        self.commerceConfiguration = commerceConfiguration
        self.pastStepPolicy = pastStepPolicy
        self.futureStepPolicy = futureStepPolicy
        self.participantLimit = participantLimit
        self.status = status
        self.days = days
        self.updatedAt = updatedAt
    }

    var durationInDays: Int {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return max(
            (calendar.dateComponents([.day], from: start, to: end).day ?? 0)
                + 1,
            0
        )
    }

    init(program: Program, updatedAt: Date) {
        id = program.id
        sourceProgramID = program.sourceProgramID
        title = program.title
        summary = program.summary
        price = program.price
        category = program.category ?? ""
        coverLocalReference = program.coverLocalReference
        coverAlternativeText = program.coverAlternativeText ?? ""
        verificationMode = .coachReview
        wellnessDisclaimer = program.wellnessDisclaimer
            ?? (
                "Program ini mendukung kebiasaan hidup sehat dan bukan "
                    + "pengganti diagnosis atau perawatan medis."
            )
        pace = program.pace ?? .scheduled
        durationMode = program.durationMode ?? .specificDates
        fixedDurationDays = program.durationInDays
        startDate = program.startDate
        endDate = program.endDate
        timeZoneIdentifier = program.timeZoneIdentifier
        initialWeighInWindowHours = 24
        finalWeighInWindowHours = 24
        weightPointsPerKilogram = program.weightPointsPerKilogram
        pointsPerActivity =
            program.effectiveScoringConfiguration.pointsPerActivity
        quizPassingPercentage =
            program.effectiveScoringConfiguration.quizPassingPercentage
        commerceConfiguration = program.commerceConfiguration
        pastStepPolicy = program.pastStepPolicy ?? .available
        futureStepPolicy = program.futureStepPolicy ?? .locked
        participantLimit = program.participantLimit
        status = program.status
        days = program.days.map { day in
            AdminDayDraft(
                id: day.id,
                dayNumber: day.dayNumber,
                title: day.title,
                summary: day.summary ?? "",
                scheduledDate: day.scheduledDate,
                steps: day.steps.map { step in
                    return AdminStepDraft(
                        id: step.id,
                        order: step.order,
                        title: step.title,
                        instructions: step.instructions,
                        mediaKind: step.instructionMedia?.kind,
                        localMediaReference:
                            step.instructionMedia?.resourceName,
                        isActive: true,
                        verificationMode: step.verificationMode,
                        contentKind: Self.adminContentKind(for: step.content),
                        isVideoRequiredToWatch:
                            step.content?.videoConfiguration?
                                .isRequiredToWatch ?? false,
                        isVideoAutoplayEnabled:
                            step.content?.videoConfiguration?
                                .isAutoplayEnabled ?? false,
                        quiz: Self.adminQuestions(
                            from: step.content,
                            title: step.title
                        ),
                        publishedContent: step.content
                    )
                }
            )
        }
        self.updatedAt = updatedAt
    }

    func program() -> Program {
        Program(
            id: id,
            sourceProgramID: sourceProgramID,
            title: title,
            summary: summary,
            category: category,
            coverLocalReference: coverLocalReference,
            coverAlternativeText: coverAlternativeText,
            price: price,
            status: status,
            startDate: startDate,
            endDate: endDate,
            timeZoneIdentifier: timeZoneIdentifier,
            weightPointsPerKilogram: weightPointsPerKilogram,
            scoringConfiguration: ProgramScoringConfiguration(
                pointsPerActivity: pointsPerActivity,
                pointsPerWeightLossKilogram: weightPointsPerKilogram,
                quizPassingPercentage: quizPassingPercentage
            ),
            commerceConfiguration: commerceConfiguration
                ?? ProgramCommerceConfiguration(
                    pricingMode: price == nil ? .free : .paid,
                    desiredPrice: price,
                    platformAvailability: CommercePlatform.allCases.map {
                        ProgramPlatformAvailability(
                            platform: $0,
                            isEnabled: true,
                            provisioningStatus: price == nil
                                ? .notRequired
                                : .notRequested
                        )
                    }
                ),
            pace: pace,
            durationMode: durationMode,
            participantLimit: participantLimit,
            pastStepPolicy: pastStepPolicy,
            futureStepPolicy: futureStepPolicy,
            wellnessDisclaimer: wellnessDisclaimer,
            days: days.map { day in
                ProgramDay(
                    id: day.id,
                    programID: id,
                    dayNumber: day.dayNumber,
                    title: day.title,
                    scheduledDate: day.scheduledDate,
                    visibilityMode: .standard,
                    steps: day.steps.filter(\.isActive).map { step in
                        ProgramStep(
                            id: step.id,
                            programDayID: day.id,
                            order: step.order,
                            title: step.title,
                            instructions: step.instructions,
                            instructionMedia: media(for: step),
                            verificationMode: step.contentKind.isWeighIn
                                ? .automatic
                                : step.verificationMode,
                            content: content(for: step)
                        )
                    },
                    summary: day.summary.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty ? nil : day.summary
                )
            }
        )
    }

    private static func adminContentKind(
        for content: ProgramStepContent?
    ) -> AdminStepContentKind {
        switch content?.kind {
        case .video:
            .video
        case .form:
            .form
        case .quiz:
            .quiz
        case .initialWeighIn:
            .initialWeighIn
        case .dailyWeighIn:
            .dailyWeighIn
        case .finalWeighIn:
            .finalWeighIn
        case .article, .none:
            .article
        }
    }

    private static func adminQuestions(
        from content: ProgramStepContent?,
        title: String
    ) -> AdminQuizDraft? {
        guard let content, !content.questions.isEmpty else {
            return content?.kind == .quiz || content?.kind == .form
                ? AdminQuizDraft(title: title, questions: [])
                : nil
        }
        return AdminQuizDraft(
            title: title,
            questions: content.questions.map { question in
                AdminQuizQuestionDraft(
                    id: question.id,
                    order: question.order,
                    kind: AdminQuizQuestionKind(
                        rawValue: question.kind.rawValue
                    ) ?? .shortAnswer,
                    prompt: question.prompt,
                    options: question.options.map(\.title),
                    optionIDs: question.options.map(\.id),
                    optionMediaReferences: question.options.map(
                        \.mediaReference
                    ),
                    answerKey: question.answerKey
                )
            }
        )
    }

    private func content(for step: AdminStepDraft) -> ProgramStepContent {
        let kind: ProgramContentKind
        switch step.contentKind {
        case .article:
            kind = .article
        case .video:
            kind = .video
        case .form:
            kind = .form
        case .quiz:
            kind = .quiz
        case .initialWeighIn:
            kind = .initialWeighIn
        case .dailyWeighIn:
            kind = .dailyWeighIn
        case .finalWeighIn:
            kind = .finalWeighIn
        }
        return ProgramStepContent(
            kind: kind,
            questions: (step.quiz?.questions ?? []).map {
                question(for: $0)
            },
            completionPolicy: completionPolicy(for: step),
            videoConfiguration: step.contentKind == .video
                ? ProgramVideoCompletionConfiguration(
                    isRequiredToWatch: step.isVideoRequiredToWatch,
                    completionThresholdPercentage:
                        step.isVideoRequiredToWatch ? 100 : 0,
                    isAutoplayEnabled: step.isVideoAutoplayEnabled
                )
                : nil
        )
    }

    private func completionPolicy(
        for step: AdminStepDraft
    ) -> ProgramStepCompletionPolicy {
        switch step.contentKind {
        case .article:
            .markComplete
        case .video:
            step.isVideoRequiredToWatch ? .watchVideo : .markComplete
        case .form:
            .answerAllQuestions
        case .quiz:
            .automaticQuiz
        case .initialWeighIn, .dailyWeighIn, .finalWeighIn:
            .submitWeighIn
        }
    }

    private func question(
        for draft: AdminQuizQuestionDraft
    ) -> ProgramQuestionDefinition {
        let optionIDs: [UUID] = draft.options.indices.map { index in
            if draft.optionIDs.indices.contains(index) {
                return draft.optionIDs[index]
            }
            return AdminProgramDraftValidator().childIdentifier(
                parent: draft.id,
                discriminator: index + 1
            )
        }
        let kind = ProgramQuestionKind(
            rawValue: draft.kind.rawValue
        ) ?? .shortAnswer
        let validOptionIDs = Set(optionIDs)
        let answerKey = draft.answerKey.map {
            ProgramQuestionAnswerKey(
                acceptedTextValues: $0.acceptedTextValues,
                numberValue: $0.numberValue,
                selectedOptionIDs: $0.selectedOptionIDs.filter {
                    validOptionIDs.contains($0)
                },
                matchingMode: $0.matchingMode
            )
        }
        return ProgramQuestionDefinition(
            id: draft.id,
            order: draft.order,
            kind: kind,
            prompt: draft.prompt,
            options: zip(optionIDs, draft.options.enumerated()).map {
                optionID, indexedTitle in
                ProgramQuestionOption(
                    id: optionID,
                    order: indexedTitle.offset + 1,
                    title: indexedTitle.element,
                    mediaReference:
                        draft.optionMediaReferences.indices.contains(
                            indexedTitle.offset
                        )
                        ? draft.optionMediaReferences[indexedTitle.offset]
                        : nil,
                    mediaAlternativeText:
                        draft.kind == .imageChoice
                        ? indexedTitle.element
                        : nil
                )
            },
            answerKey: answerKey
        )
    }

    private func media(for step: AdminStepDraft) -> StepInstructionMedia? {
        guard let kind = step.mediaKind,
              let reference = step.localMediaReference,
              !reference.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty else {
            return nil
        }
        return StepInstructionMedia(
            kind: kind,
            resourceName: reference,
            accessibilityLabel: "Media petunjuk \(step.title)"
        )
    }

}

nonisolated enum AdminValidationField: String, Sendable {
    case title
    case cover
    case dates
    case timeZone
    case scoring
    case participantLimit
    case days
    case dayNumbers
    case dayDates
    case steps
    case stepOrder
    case media
    case content
}

nonisolated struct AdminValidationIssue:
    Equatable,
    Identifiable,
    Sendable
{
    let field: AdminValidationField
    let message: String

    var id: String {
        "\(field.rawValue).\(message)"
    }
}
