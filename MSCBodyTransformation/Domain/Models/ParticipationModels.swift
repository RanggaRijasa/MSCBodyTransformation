import Foundation

nonisolated enum EnrollmentStatus: String, Codable, CaseIterable, Sendable {
    case initiated
    case waitingForPayment = "waiting_for_payment"
    case active
    case completed
    case cancelled
    case refunded
}

nonisolated struct ProgramEnrollment: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let programID: UUID
    let participantID: UUID
    var coachID: UUID?
    var status: EnrollmentStatus
    let enrolledAt: Date
}

nonisolated enum WeighInType:
    String,
    Codable,
    CaseIterable,
    Hashable,
    Sendable
{
    case initial
    case daily
    case final
}

nonisolated struct WeighIn: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let enrollmentID: UUID
    let stepID: UUID?
    let type: WeighInType
    let weightKilograms: Decimal
    let recordedAt: Date

    init(
        id: UUID,
        enrollmentID: UUID,
        stepID: UUID? = nil,
        type: WeighInType,
        weightKilograms: Decimal,
        recordedAt: Date
    ) {
        self.id = id
        self.enrollmentID = enrollmentID
        self.stepID = stepID
        self.type = type
        self.weightKilograms = weightKilograms
        self.recordedAt = recordedAt
    }
}

nonisolated enum SubmissionStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case approved
    case rejected
}

nonisolated struct StepSubmission: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let enrollmentID: UUID
    let stepID: UUID
    var status: SubmissionStatus
    let submittedAt: Date
    var reviewedAt: Date?
    var reviewerID: UUID?
    var reviewNote: String?
    var coachRating: Int? = nil
    var answers: [StepSubmissionAnswer]? = nil
    var attemptSequence: Int? = nil
    var quizResult: QuizAttemptResult? = nil

    var typedAnswers: [StepSubmissionAnswer] {
        answers ?? []
    }

    var photoAnswers: [StepSubmissionAnswer] {
        typedAnswers.filter {
            !($0.localPhotoReference ?? "").isEmpty
        }
    }
}
