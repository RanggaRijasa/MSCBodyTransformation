import Foundation

nonisolated enum EnrollmentStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case active
    case completed
    case cancelled
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
    case final
}

nonisolated struct WeighIn: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let enrollmentID: UUID
    let type: WeighInType
    let weightKilograms: Decimal
    let recordedAt: Date
}

nonisolated enum SubmissionEvidenceKind: String, Codable, CaseIterable, Sendable {
    case photo
    case text
}

nonisolated struct SubmissionEvidence: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let kind: SubmissionEvidenceKind
    let localReference: String?
    let textValue: String?
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
    var evidence: [SubmissionEvidence]
    var status: SubmissionStatus
    let submittedAt: Date
    var reviewedAt: Date?
    var reviewerID: UUID?
    var reviewNote: String?
    var coachRating: Int? = nil
}
