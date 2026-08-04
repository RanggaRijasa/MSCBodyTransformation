import Foundation

nonisolated struct ProgramScoringConfiguration:
    Codable,
    Equatable,
    Sendable
{
    var pointsPerActivity: Int
    var pointsPerWeightLossKilogram: Decimal
    var quizPassingPercentage: Int

    init(
        pointsPerActivity: Int,
        pointsPerWeightLossKilogram: Decimal,
        quizPassingPercentage: Int
    ) {
        self.pointsPerActivity = pointsPerActivity
        self.pointsPerWeightLossKilogram = pointsPerWeightLossKilogram
        self.quizPassingPercentage = quizPassingPercentage
    }
}

nonisolated enum ProgramPricingMode: String, Codable, CaseIterable, Sendable {
    case free
    case paid
}

nonisolated enum CommercePlatform: String, Codable, CaseIterable, Sendable {
    case appStore = "app_store"
    case playStore = "play_store"
}

nonisolated enum StoreProvisioningStatus:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case notRequired = "not_required"
    case notRequested = "not_requested"
    case provisioning
    case waitingForStore = "waiting_for_store"
    case ready
    case actionRequired = "action_required"
    case retired
}

nonisolated struct ProgramPlatformAvailability:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    var id: CommercePlatform { platform }
    let platform: CommercePlatform
    var isEnabled: Bool
    var provisioningStatus: StoreProvisioningStatus
}

nonisolated struct ProgramCommerceConfiguration:
    Codable,
    Equatable,
    Sendable
{
    var pricingMode: ProgramPricingMode
    var desiredPrice: Decimal?
    var platformAvailability: [ProgramPlatformAvailability]

    var requiresPayment: Bool {
        pricingMode == .paid
    }
}

nonisolated enum ProgramContentKind:
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
}

nonisolated enum ProgramQuestionKind:
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

    var isInteractive: Bool {
        self != .heading && self != .text
    }

    var acceptsOptions: Bool {
        switch self {
        case .singleChoice, .multipleChoice, .imageChoice:
            true
        case .shortAnswer, .longAnswer, .number, .photoUpload, .heading, .text:
            false
        }
    }

    var isObjective: Bool {
        switch self {
        case .singleChoice, .multipleChoice, .imageChoice, .number:
            true
        case .shortAnswer, .longAnswer, .photoUpload, .heading, .text:
            false
        }
    }
}

nonisolated struct ProgramQuestionOption:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    var order: Int
    var title: String
    var mediaReference: String?
    var mediaAlternativeText: String?
}

nonisolated enum ProgramAnswerMatchingMode:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case exact
    case caseInsensitiveText = "case_insensitive_text"
}

nonisolated struct ProgramQuestionAnswerKey:
    Codable,
    Equatable,
    Sendable
{
    var acceptedTextValues: [String]
    var numberValue: Decimal?
    var selectedOptionIDs: [UUID]
    var matchingMode: ProgramAnswerMatchingMode

    init(
        acceptedTextValues: [String] = [],
        numberValue: Decimal? = nil,
        selectedOptionIDs: [UUID] = [],
        matchingMode: ProgramAnswerMatchingMode = .exact
    ) {
        self.acceptedTextValues = acceptedTextValues
        self.numberValue = numberValue
        self.selectedOptionIDs = selectedOptionIDs
        self.matchingMode = matchingMode
    }
}

nonisolated struct ProgramQuestionDefinition:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    var order: Int
    var kind: ProgramQuestionKind
    var prompt: String
    var options: [ProgramQuestionOption]
    var answerKey: ProgramQuestionAnswerKey?

    var requiresAnswer: Bool {
        kind.isInteractive
    }
}

nonisolated enum ProgramStepCompletionPolicy:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case markComplete = "mark_complete"
    case answerAllQuestions = "answer_all_questions"
    case watchVideo = "watch_video"
    case automaticQuiz = "automatic_quiz"
    case submitWeighIn = "submit_weigh_in"
}

nonisolated enum ProgramWeighInKind:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case initial
    case daily
    case final
}

nonisolated struct ProgramVideoCompletionConfiguration:
    Codable,
    Equatable,
    Sendable
{
    var isRequiredToWatch: Bool
    var completionThresholdPercentage: Int
    var isAutoplayEnabled: Bool
}

nonisolated struct ProgramStepContent:
    Codable,
    Equatable,
    Sendable
{
    var kind: ProgramContentKind
    var questions: [ProgramQuestionDefinition]
    var completionPolicy: ProgramStepCompletionPolicy
    var videoConfiguration: ProgramVideoCompletionConfiguration?

    var weighInKind: ProgramWeighInKind? {
        switch kind {
        case .initialWeighIn:
            .initial
        case .dailyWeighIn:
            .daily
        case .finalWeighIn:
            .final
        case .article, .video, .form, .quiz:
            nil
        }
    }
}

nonisolated struct ProgramEnrollmentContext:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    var id: UUID { enrollment.id }
    let enrollment: ProgramEnrollment
    let program: Program
    var submissions: [StepSubmission]
    var weighIns: [WeighIn]
    var leaderboardEntry: LeaderboardEntry?
}

nonisolated struct StepSubmissionAnswer:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    let questionID: UUID
    var textValue: String?
    var numberValue: Decimal?
    var selectedOptionIDs: [UUID]
    var localPhotoReference: String?

    var hasValue: Bool {
        if let textValue,
           !textValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return numberValue != nil
            || !selectedOptionIDs.isEmpty
            || !(localPhotoReference ?? "").isEmpty
    }
}

nonisolated struct QuizAttemptResult:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    let enrollmentID: UUID
    let stepID: UUID
    let sequence: Int
    let correctAnswerCount: Int
    let totalQuestionCount: Int
    let percentage: Int
    let isPassed: Bool
    let awardedPoints: Int
    let submittedAt: Date
    var reopenedAt: Date?
    var reopenedByAdminID: UUID?
    var reopenReason: String?
}

nonisolated struct ProgramStoreProduct:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    let programID: UUID
    let platform: CommercePlatform
    let externalProductID: String
    var status: StoreProvisioningStatus
    var actualPrice: Decimal?
    var currencyCode: String?
}

nonisolated enum ProgramPaymentStatus:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case initiated
    case pending
    case verified
    case cancelled
    case refunded
    case revoked
}

nonisolated struct ProgramPayment:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    let programID: UUID
    let participantID: UUID
    let platform: CommercePlatform
    let externalTransactionID: String?
    var status: ProgramPaymentStatus
    let createdAt: Date
    var verifiedAt: Date?
}

nonisolated enum ProgramEntitlementStatus:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case active
    case revoked
}

nonisolated struct ProgramEntitlement:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    let programID: UUID
    let participantID: UUID
    let sourcePaymentID: UUID?
    var status: ProgramEntitlementStatus
    let grantedAt: Date
    var revokedAt: Date?
}
