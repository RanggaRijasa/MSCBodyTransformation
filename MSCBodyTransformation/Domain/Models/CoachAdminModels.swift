import Foundation

nonisolated enum ManagedContentKind: String, Codable, CaseIterable, Sendable {
    case winnerBanner = "winner_banner"
    case announcement
    case wellnessDisclaimer = "wellness_disclaimer"
}

nonisolated struct ManagedContent: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let kind: ManagedContentKind
    var title: String
    var body: String
    var localMediaReference: String?
    var programID: UUID?
    var winnerSnapshotID: UUID? = nil
    var visibleFrom: Date?
    var visibleUntil: Date?
    var sortOrder: Int
    var isPublished: Bool
    var isArchived: Bool
    var updatedAt: Date
}

nonisolated enum AuditEventKind: String, Codable, CaseIterable, Sendable {
    case programCreated = "program_created"
    case programUpdated = "program_updated"
    case submissionReviewed = "submission_reviewed"
    case scoreAdjusted = "score_adjusted"
    case programPublished = "program_published"
    case programArchived = "program_archived"
    case coachApproved = "coach_approved"
    case coachVisibilityChanged = "coach_visibility_changed"
    case coachTransferred = "coach_transferred"
    case participantEnrolled = "participant_enrolled"
    case managedContentUpdated = "managed_content_updated"
    case winnersLocked = "winners_locked"
    case quizAttemptReopened = "quiz_attempt_reopened"
    case weighInCorrected = "weigh_in_corrected"
}

nonisolated struct AdminFailedQuizAttempt:
    Equatable,
    Identifiable,
    Sendable
{
    var id: UUID { submissionID }
    let submissionID: UUID
    let enrollmentID: UUID
    let participantName: String
    let stepTitle: String
    let sequence: Int
}

nonisolated struct AuditEvent: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let kind: AuditEventKind
    let actorUserID: UUID
    let subjectID: UUID
    let summary: String
    let createdAt: Date
}
