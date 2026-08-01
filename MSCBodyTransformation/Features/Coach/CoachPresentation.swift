import Foundation

nonisolated enum CoachFormatting {
    static let locale = Locale(identifier: "id-ID")

    static func number(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }

    static func percentage(_ value: Int) -> String {
        (Double(value) / 100).formatted(
            .percent
                .locale(locale)
                .precision(.fractionLength(0))
        )
    }

    static func weight(_ value: Decimal) -> String {
        value.formatted(
            .number
                .locale(locale)
                .precision(.fractionLength(0...2))
        ) + " kg"
    }

    static func date(_ value: Date) -> String {
        value.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .locale(locale)
        )
    }

    static func dateTime(
        _ value: Date,
        timeZoneIdentifier: String = "Asia/Makassar"
    ) -> String {
        let timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        let formatted = value.formatted(
            Date.FormatStyle(
                date: .abbreviated,
                time: .shortened,
                locale: locale,
                timeZone: timeZone
            )
        )
        return formatted + " " + (
            timeZone.abbreviation(for: value) ?? timeZoneIdentifier
        )
    }

    static func currency(_ value: Decimal) -> String {
        value.formatted(
            .currency(code: "IDR")
                .locale(locale)
                .precision(.fractionLength(0))
        )
    }

    static func relativeDate(_ value: Date) -> String {
        value.formatted(
            .relative(
                presentation: .numeric,
                unitsStyle: .wide
            )
            .locale(locale)
        )
    }

    static func relativeActivity(_ value: Date) -> String {
        String(
            format: String(
                localized: "coach.participants.activity_format",
                defaultValue: "Aktif %@"
            ),
            relativeDate(value)
        )
    }

    static func reason(_ error: DomainError) -> String {
        switch error {
        case .validation(_, let reason), .conflict(let reason):
            reason
        case .permissionDenied:
            String(
                localized: "coach.error.permission",
                defaultValue: "Anda tidak memiliki akses ke peserta ini."
            )
        case .offline:
            String(
                localized: "error.offline.message",
                defaultValue: "Periksa koneksi, lalu coba lagi."
            )
        default:
            String(
                localized: "coach.error.generic",
                defaultValue: "Terjadi kendala. Coba lagi."
            )
        }
    }
}

nonisolated enum CoachFeatureLoadState<Value>: Equatable, Sendable
where Value: Equatable & Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(DomainError)
}

nonisolated struct CoachParticipantSummary:
    Equatable,
    Identifiable,
    Sendable
{
    let profile: ParticipantProfile
    let enrollment: ProgramEnrollment?
    let program: Program?
    let submissions: [StepSubmission]
    let weighIns: [WeighIn]
    let leaderboardEntry: LeaderboardEntry?
    let associatedPrograms: [Program]

    var id: UUID { profile.id }

    var progressPercentage: Int {
        guard let program else {
            return 0
        }
        return ProgramProgressCalculator().percentage(
            totalStepCount: program.days.flatMap(\.steps).count,
            submissions: submissions
        )
    }

    var points: Int {
        leaderboardEntry?.score.totalPoints ?? 0
    }

    var pendingReviewCount: Int {
        submissions.filter { $0.status == .pending }.count
    }

    var rejectedCount: Int {
        submissions.filter { $0.status == .rejected }.count
    }

    var missingStepCount: Int {
        guard let program else {
            return 0
        }
        let submittedStepIDs = Set(submissions.map(\.stepID))
        return program.days
            .flatMap(\.steps)
            .filter { !submittedStepIDs.contains($0.id) }
            .count
    }

    var totalStepCount: Int {
        program?.days.flatMap(\.steps).count ?? 0
    }

    var completedStepCount: Int {
        let programStepIDs = Set(
            program?.days.flatMap(\.steps).map(\.id) ?? []
        )
        return Set(
            submissions
                .map(\.stepID)
                .filter(programStepIDs.contains)
        ).count
    }

    var evidenceCount: Int {
        submissions.map(\.evidence.count).reduce(0, +)
    }

    var activeDayCount: Int {
        guard let program else {
            return 0
        }
        let submittedStepIDs = Set(submissions.map(\.stepID))
        return program.days.filter { day in
            day.steps.contains { submittedStepIDs.contains($0.id) }
        }.count
    }

    var isComplete: Bool {
        enrollment?.status == .completed || progressPercentage == 100
    }

    var isFallingBehind: Bool {
        !isComplete && progressPercentage < 50
    }

    var lastActivityAt: Date {
        submissions.map(\.submittedAt).max()
            ?? enrollment?.enrolledAt
            ?? .distantPast
    }

    var initialWeighIn: WeighIn? {
        weighIns.first { $0.type == .initial }
    }

    var finalWeighIn: WeighIn? {
        weighIns.first { $0.type == .final }
    }
}

nonisolated enum CoachCompletionFilter:
    String,
    CaseIterable,
    Identifiable,
    Sendable
{
    case all
    case inProgress = "in_progress"
    case complete
    case fallingBehind = "falling_behind"

    var id: String { rawValue }
    var titleKey: String { "coach.filter.completion.\(rawValue)" }
}

nonisolated enum CoachReviewFilter:
    String,
    CaseIterable,
    Identifiable,
    Sendable
{
    case all
    case pending
    case rejected

    var id: String { rawValue }
    var titleKey: String { "coach.filter.review.\(rawValue)" }
}

nonisolated enum CoachParticipantSort:
    String,
    CaseIterable,
    Identifiable,
    Sendable
{
    case progress
    case points
    case lastActivity = "last_activity"

    var id: String { rawValue }
    var titleKey: String { "coach.sort.\(rawValue)" }
}

nonisolated struct CoachDashboardSnapshot: Equatable, Sendable {
    let profile: CoachProfile
    let activePrograms: [Program]
    let participants: [CoachParticipantSummary]

    var averageProgress: Int {
        guard !participants.isEmpty else {
            return 0
        }
        return participants.map(\.progressPercentage).reduce(0, +)
            / participants.count
    }

    var completedParticipantCount: Int {
        participants.filter(\.isComplete).count
    }

    var missingStepCount: Int {
        participants.map(\.missingStepCount).reduce(0, +)
    }

    var pendingReviewCount: Int {
        participants.map(\.pendingReviewCount).reduce(0, +)
    }

    var needsAttentionCount: Int {
        participants.filter(\.isFallingBehind).count
    }
}

nonisolated struct CoachReviewItem: Equatable, Identifiable, Sendable {
    let submission: StepSubmission
    let participant: ParticipantProfile
    let enrollment: ProgramEnrollment
    let program: Program
    let day: ProgramDay
    let step: ProgramStep
    let scoreBeforeReview: Int

    var id: UUID { submission.id }
}

nonisolated struct CoachReviewDecisionResult: Equatable, Sendable {
    let submissionID: UUID
    let participantName: String
    let status: SubmissionStatus
    let pointsBefore: Int
    let pointsAfter: Int
}

nonisolated struct CoachInviteSnapshot: Equatable, Sendable {
    let profile: CoachProfile
}

nonisolated struct CoachLeaderboardSnapshot: Equatable, Sendable {
    let programs: [Program]
    let selectedProgram: Program
    let entries: [LeaderboardEntry]
    let winners: [ProgramWinner]
    let assignedParticipantIDs: Set<UUID>
    let referenceDate: Date

    var selectedProgramStatus: ProgramStatus {
        selectedProgram.lifecycleStatus(at: referenceDate)
    }

    var isProgramCompleted: Bool {
        selectedProgramStatus == .completed
            || selectedProgramStatus == .archived
    }

    var isFinal: Bool {
        isProgramCompleted && !winners.isEmpty
    }

    var isAwaitingWinnerLock: Bool {
        isProgramCompleted && winners.isEmpty
    }
}

nonisolated struct CoachProfileSnapshot: Equatable, Sendable {
    let user: AppUser
    let profile: CoachProfile
}
