import Foundation

@MainActor
final class CoachFeatureContainer {
    let dashboard: CoachDashboardState
    let participants: CoachParticipantsState
    let reviewQueue: CoachReviewQueueState
    let invites: CoachInviteComposerState
    let storePreview: CoachStorePreviewState
    let leaderboard: CoachLeaderboardState
    let profile: CoachProfileState

    private let environment: AppEnvironment
    private(set) var coachID: UUID?

    init(environment: AppEnvironment) {
        self.environment = environment
        dashboard = CoachDashboardState(environment: environment)
        participants = CoachParticipantsState(environment: environment)
        reviewQueue = CoachReviewQueueState(environment: environment)
        invites = CoachInviteComposerState(environment: environment)
        storePreview = CoachStorePreviewState(environment: environment)
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
        async let leaderboardLoad: Void = leaderboard.load()
        _ = await (
            dashboardLoad,
            participantsLoad,
            leaderboardLoad
        )
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
