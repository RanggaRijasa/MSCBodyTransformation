import Foundation

nonisolated enum CoachActivityKind:
    String,
    CaseIterable,
    Identifiable,
    Sendable
{
    case evidenceSubmitted = "evidence_submitted"
    case stepCompleted = "step_completed"
    case participantJoined = "participant_joined"
    case programCompleted = "program_completed"

    var id: String { rawValue }
}

nonisolated enum CoachActivityKindFilter:
    String,
    CaseIterable,
    Identifiable,
    Sendable
{
    case all
    case evidenceSubmitted = "evidence_submitted"
    case stepCompleted = "step_completed"
    case participantJoined = "participant_joined"
    case programCompleted = "program_completed"

    var id: String { rawValue }

    func includes(_ kind: CoachActivityKind) -> Bool {
        switch self {
        case .all:
            true
        case .evidenceSubmitted:
            kind == .evidenceSubmitted
        case .stepCompleted:
            kind == .stepCompleted
        case .participantJoined:
            kind == .participantJoined
        case .programCompleted:
            kind == .programCompleted
        }
    }
}

nonisolated enum CoachActivityTimeRange:
    String,
    CaseIterable,
    Identifiable,
    Sendable
{
    case today
    case lastSevenDays = "last_seven_days"
    case lastThirtyDays = "last_thirty_days"

    var id: String { rawValue }

    func startDate(
        referenceDate: Date,
        calendar: Calendar
    ) -> Date {
        let startOfToday = calendar.startOfDay(for: referenceDate)
        switch self {
        case .today:
            return startOfToday
        case .lastSevenDays:
            return calendar.date(
                byAdding: .day,
                value: -6,
                to: startOfToday
            ) ?? startOfToday
        case .lastThirtyDays:
            return calendar.date(
                byAdding: .day,
                value: -29,
                to: startOfToday
            ) ?? startOfToday
        }
    }
}

nonisolated struct CoachActivityItem:
    Equatable,
    Identifiable,
    Sendable
{
    let id: String
    let participantID: UUID
    let participantName: String
    let participantPhotoReference: String?
    let programID: UUID
    let programTitle: String
    let stepTitle: String?
    let points: Int?
    let kind: CoachActivityKind
    let evidenceStatus: SubmissionStatus?
    let occurredAt: Date
    let requiresReview: Bool
}

nonisolated struct CoachActivitySnapshot: Equatable, Sendable {
    let items: [CoachActivityItem]
    let programs: [Program]
}

nonisolated struct CoachActivitySection:
    Equatable,
    Identifiable,
    Sendable
{
    let day: Date
    let items: [CoachActivityItem]

    var id: Date { day }
}

