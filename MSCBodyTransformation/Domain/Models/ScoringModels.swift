import Foundation

nonisolated struct ScoreBreakdown: Codable, Equatable, Sendable {
    var approvedStepPoints: Int
    var weightPoints: Int
    var adjustmentPoints: Int

    var totalPoints: Int {
        approvedStepPoints + weightPoints + adjustmentPoints
    }
}

nonisolated struct LeaderboardEntry: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let programID: UUID
    let participantID: UUID
    var participantDisplayName: String
    var rank: Int
    var progressPercentage: Int
    var score: ScoreBreakdown
    var isCurrentUser: Bool
}

nonisolated struct ProgramWinner: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let programID: UUID
    let participantID: UUID
    let rank: Int
    let participantDisplayName: String
    let totalPoints: Int
    let lockedAt: Date
}
