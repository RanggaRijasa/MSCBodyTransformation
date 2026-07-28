import Foundation

nonisolated enum PastStepPolicy: String, Codable, CaseIterable, Sendable {
    case available
    case readOnly = "read_only"
    case hidden
}

nonisolated enum FutureStepPolicy: String, Codable, CaseIterable, Sendable {
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

nonisolated enum AdminProgramAccess:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case publicAccess = "public"
    case approvalRequired = "approval_required"
    case inviteOnly = "invite_only"
}

nonisolated enum AdminCoverMediaKind:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case image
    case video
}

nonisolated enum AdminStepContentKind:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case article
    case video
    case quiz
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
    case fileUpload = "file_upload"
    case heading
    case text

    var acceptsOptions: Bool {
        switch self {
        case .singleChoice, .multipleChoice, .imageChoice:
            true
        case .shortAnswer, .longAnswer, .number, .fileUpload,
             .heading, .text:
            false
        }
    }

    var isLayoutElement: Bool {
        self == .heading || self == .text
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
    var isRequired: Bool
    var options: [String]
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
    var points: Int
    var requiresPhoto: Bool
    var isPhotoRequired: Bool
    var requiresTextAnswer: Bool
    var isTextAnswerRequired: Bool
    var mediaKind: StepInstructionMediaKind?
    var localMediaReference: String?
    var isActive: Bool
    var verificationMode: SubmissionVerificationMode
    var contentKind: AdminStepContentKind
    var isVideoRequiredToWatch: Bool
    var isVideoAutoplayEnabled: Bool
    var quiz: AdminQuizDraft?

    init(
        id: UUID,
        order: Int,
        title: String,
        instructions: String,
        points: Int,
        requiresPhoto: Bool,
        isPhotoRequired: Bool,
        requiresTextAnswer: Bool,
        isTextAnswerRequired: Bool,
        mediaKind: StepInstructionMediaKind?,
        localMediaReference: String?,
        isActive: Bool,
        verificationMode: SubmissionVerificationMode,
        contentKind: AdminStepContentKind = .article,
        isVideoRequiredToWatch: Bool = false,
        isVideoAutoplayEnabled: Bool = false,
        quiz: AdminQuizDraft? = nil
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.instructions = instructions
        self.points = points
        self.requiresPhoto = requiresPhoto
        self.isPhotoRequired = isPhotoRequired
        self.requiresTextAnswer = requiresTextAnswer
        self.isTextAnswerRequired = isTextAnswerRequired
        self.mediaKind = mediaKind
        self.localMediaReference = localMediaReference
        self.isActive = isActive
        self.verificationMode = verificationMode
        self.contentKind = contentKind
        self.isVideoRequiredToWatch = isVideoRequiredToWatch
        self.isVideoAutoplayEnabled = isVideoAutoplayEnabled
        self.quiz = quiz
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
    var title: String
    var summary: String
    var category: String
    var coverLocalReference: String?
    var coverMediaKind: AdminCoverMediaKind
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
    var pastStepPolicy: PastStepPolicy
    var futureStepPolicy: FutureStepPolicy
    var access: AdminProgramAccess
    var participantLimit: Int?
    var status: ProgramStatus
    var days: [AdminDayDraft]
    var updatedAt: Date

    init(
        id: UUID,
        title: String,
        summary: String,
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
        coverMediaKind: AdminCoverMediaKind = .image,
        coverAlternativeText: String = "",
        pace: AdminProgramPace = .scheduled,
        durationMode: AdminProgramDurationMode = .specificDates,
        fixedDurationDays: Int = 7,
        access: AdminProgramAccess = .inviteOnly,
        participantLimit: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.coverLocalReference = coverLocalReference
        self.coverMediaKind = coverMediaKind
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
        self.pastStepPolicy = pastStepPolicy
        self.futureStepPolicy = futureStepPolicy
        self.access = access
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
        title = program.title
        summary = program.summary
        category = ""
        coverLocalReference = nil
        coverMediaKind = .image
        coverAlternativeText = ""
        verificationMode = .coachReview
        wellnessDisclaimer =
            "Program ini mendukung kebiasaan hidup sehat dan bukan "
            + "pengganti diagnosis atau perawatan medis."
        pace = .scheduled
        durationMode = .specificDates
        fixedDurationDays = program.durationInDays
        startDate = program.startDate
        endDate = program.endDate
        timeZoneIdentifier = program.timeZoneIdentifier
        initialWeighInWindowHours = 24
        finalWeighInWindowHours = 24
        weightPointsPerKilogram = program.weightPointsPerKilogram
        pastStepPolicy = .readOnly
        futureStepPolicy = .locked
        access = .inviteOnly
        participantLimit = nil
        status = program.status
        days = program.days.map { day in
            AdminDayDraft(
                id: day.id,
                dayNumber: day.dayNumber,
                title: day.title,
                summary: "",
                scheduledDate: day.scheduledDate,
                steps: day.steps.map { step in
                    let photo = step.requirements.first {
                        $0.kind == .photoEvidence
                    }
                    let text = step.requirements.first {
                        $0.kind == .textAnswer
                    }
                    return AdminStepDraft(
                        id: step.id,
                        order: step.order,
                        title: step.title,
                        instructions: step.instructions,
                        points: step.points,
                        requiresPhoto: photo != nil,
                        isPhotoRequired: photo?.isRequired ?? false,
                        requiresTextAnswer: text != nil,
                        isTextAnswerRequired: text?.isRequired ?? false,
                        mediaKind: step.instructionMedia?.kind,
                        localMediaReference:
                            step.instructionMedia?.resourceName,
                        isActive: true,
                        verificationMode: step.verificationMode
                    )
                }
            )
        }
        self.updatedAt = updatedAt
    }

    func program() -> Program {
        Program(
            id: id,
            title: title,
            summary: summary,
            status: status,
            startDate: startDate,
            endDate: endDate,
            timeZoneIdentifier: timeZoneIdentifier,
            weightPointsPerKilogram: weightPointsPerKilogram,
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
                            points: step.points,
                            instructionMedia: media(for: step),
                            requirements: requirements(for: step),
                            verificationMode: step.verificationMode
                        )
                    }
                )
            }
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

    private func requirements(
        for step: AdminStepDraft
    ) -> [StepRequirement] {
        var result: [StepRequirement] = []
        if step.requiresPhoto {
            result.append(
                StepRequirement(
                    id: step.id,
                    kind: .photoEvidence,
                    isRequired: step.isPhotoRequired,
                    prompt: "Tambahkan bukti foto."
                )
            )
        }
        if step.requiresTextAnswer {
            var identifierBytes = step.id.uuid
            identifierBytes.15 &+= 1
            result.append(
                StepRequirement(
                    id: UUID(uuid: identifierBytes),
                    kind: .textAnswer,
                    isRequired: step.isTextAnswerRequired,
                    prompt: "Tulis jawaban singkat."
                )
            )
        }
        return result
    }
}

nonisolated enum AdminValidationField: String, Sendable {
    case title
    case cover
    case dates
    case timeZone
    case scoring
    case access
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
