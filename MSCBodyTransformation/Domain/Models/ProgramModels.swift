import Foundation

nonisolated enum ProgramStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case scheduled
    case active
    case completed
}

nonisolated enum ProgramDayVisibilityMode: String, Codable, CaseIterable, Sendable {
    case standard
    case hidden
    case readOnly = "read_only"
}

nonisolated enum ProgramDayAccess: String, Equatable, Sendable {
    case hidden
    case locked
    case readOnly = "read_only"
    case available
}

nonisolated enum StepRequirementKind: String, Codable, CaseIterable, Sendable {
    case photoEvidence = "photo_evidence"
    case textAnswer = "text_answer"
}

nonisolated struct StepRequirement: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let kind: StepRequirementKind
    let isRequired: Bool
    let prompt: String?
}

nonisolated enum StepInstructionMediaKind: String, Codable, CaseIterable, Sendable {
    case image
    case video
}

nonisolated struct StepInstructionMedia: Codable, Equatable, Sendable {
    let kind: StepInstructionMediaKind
    let resourceName: String
    let accessibilityLabel: String
}

nonisolated enum SubmissionVerificationMode: String, Codable, CaseIterable, Sendable {
    case automatic
    case coachReview = "coach_review"
}

nonisolated struct ProgramStep: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let programDayID: UUID
    var order: Int
    var title: String
    var instructions: String
    var points: Int
    var instructionMedia: StepInstructionMedia?
    var requirements: [StepRequirement]
    var verificationMode: SubmissionVerificationMode
}

nonisolated struct ProgramDay: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let programID: UUID
    var dayNumber: Int
    var title: String
    var scheduledDate: Date
    var visibilityMode: ProgramDayVisibilityMode
    var steps: [ProgramStep]
}

nonisolated struct Program: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var summary: String
    var status: ProgramStatus
    var startDate: Date
    var endDate: Date
    var timeZoneIdentifier: String
    var weightPointsPerKilogram: Decimal
    var days: [ProgramDay]
}
