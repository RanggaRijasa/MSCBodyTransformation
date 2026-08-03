import Foundation

nonisolated struct ScoreBreakdown: Codable, Equatable, Sendable {
    var approvedStepPoints: Int
    var quizPoints: Int = 0
    var weightPoints: Int
    var adjustmentPoints: Int

    var totalPoints: Int {
        approvedStepPoints + quizPoints + weightPoints + adjustmentPoints
    }

    init(
        approvedStepPoints: Int,
        quizPoints: Int = 0,
        weightPoints: Int,
        adjustmentPoints: Int
    ) {
        self.approvedStepPoints = approvedStepPoints
        self.quizPoints = quizPoints
        self.weightPoints = weightPoints
        self.adjustmentPoints = adjustmentPoints
    }

    private enum CodingKeys: String, CodingKey {
        case approvedStepPoints
        case quizPoints
        case weightPoints
        case adjustmentPoints
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        approvedStepPoints = try container.decode(
            Int.self,
            forKey: .approvedStepPoints
        )
        quizPoints = try container.decodeIfPresent(
            Int.self,
            forKey: .quizPoints
        ) ?? 0
        weightPoints = try container.decode(Int.self, forKey: .weightPoints)
        adjustmentPoints = try container.decode(
            Int.self,
            forKey: .adjustmentPoints
        )
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

nonisolated enum ProgramClosureIssueKind:
    String,
    Codable,
    CaseIterable,
    Sendable
{
    case pendingReview = "pending_review"
    case missingFinalWeighIn = "missing_final_weigh_in"
    case failedQuiz = "failed_quiz"
}

nonisolated struct ProgramClosureIssue:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: String
    let enrollmentID: UUID
    let participantID: UUID
    let kind: ProgramClosureIssueKind
    let count: Int
    let blocksWinnerLock: Bool
}

nonisolated struct ProgramClosurePreflight:
    Codable,
    Equatable,
    Sendable
{
    let programID: UUID
    let enrollmentCount: Int
    let issues: [ProgramClosureIssue]

    var blockingIssues: [ProgramClosureIssue] {
        issues.filter(\.blocksWinnerLock)
    }

    var canLockWinners: Bool {
        !issues.contains(where: \.blocksWinnerLock)
    }

    func count(for kind: ProgramClosureIssueKind) -> Int {
        issues
            .filter { $0.kind == kind }
            .reduce(0) { $0 + $1.count }
    }
}
