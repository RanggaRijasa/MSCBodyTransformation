import Foundation

@MainActor
final class CoachFeatureContainer {
    let dashboard: CoachDashboardState
    let participants: CoachParticipantsState
    let activity: CoachActivityState
    let reviewQueue: CoachReviewQueueState
    let identifier: CoachIdentifierState
    let leaderboard: CoachLeaderboardState
    let profile: CoachProfileState

    private let environment: AppEnvironment
    private(set) var coachID: UUID?

    init(environment: AppEnvironment) {
        self.environment = environment
        dashboard = CoachDashboardState(environment: environment)
        participants = CoachParticipantsState(environment: environment)
        activity = CoachActivityState(environment: environment)
        reviewQueue = CoachReviewQueueState(environment: environment)
        identifier = CoachIdentifierState(environment: environment)
        leaderboard = CoachLeaderboardState(environment: environment)
        profile = CoachProfileState(environment: environment)
    }

    func prepareIdentity() async {
        do {
            coachID = try await CoachDataService(
                environment: environment
            ).identity().profile.id
        } catch {
            coachID = nil
        }
    }

    func review(
        item: CoachReviewItem,
        status: SubmissionStatus,
        note: String?
    ) async throws {
        try await reviewQueue.review(
            item: item,
            status: status,
            note: note
        )
        async let dashboardLoad: Void = dashboard.load()
        async let participantsLoad: Void = participants.load()
        async let activityLoad: Void = activity.load()
        async let leaderboardLoad: Void = leaderboard.load()
        _ = await (
            dashboardLoad,
            participantsLoad,
            activityLoad,
            leaderboardLoad
        )
    }

    func saveRating(
        item: CoachReviewItem,
        rating: Int
    ) async throws {
        try await reviewQueue.saveRating(item: item, rating: rating)
    }

    func makeParticipantDetailState(
        participantID: UUID
    ) -> CoachParticipantDetailState? {
        guard let coachID else {
            return nil
        }
        return CoachParticipantDetailState(
            participantID: participantID,
            coachID: coachID,
            environment: environment
        )
    }
}
