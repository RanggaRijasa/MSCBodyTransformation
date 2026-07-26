import Foundation
import Observation

@MainActor
@Observable
final class CoachReviewQueueState {
    private let environment: AppEnvironment
    private let service: CoachDataService

    var state: CoachFeatureLoadState<[CoachReviewItem]> = .idle
    var isPerformingAction = false
    var lastDecision: CoachReviewDecisionResult?

    init(environment: AppEnvironment) {
        self.environment = environment
        service = CoachDataService(environment: environment)
    }

    func load() async {
        state = .loading
        do {
            let identity = try await service.identity()
            let items = try await service.reviewItems(
                coachID: identity.profile.id
            )
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(items)
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }

    func review(
        item: CoachReviewItem,
        status: SubmissionStatus,
        note: String?
    ) async throws {
        guard let repositories = environment.repositories else {
            throw environment.bootstrapError ?? DomainError.unknown
        }
        let identity = try await service.identity()
        isPerformingAction = true
        defer { isPerformingAction = false }

        let useCase = ReviewLocalSubmissionUseCase(
            repository: repositories.submissions,
            clock: environment.clock
        )
        _ = try await useCase(
            submissionID: item.id,
            reviewerID: identity.user.id,
            status: status,
            note: note
        )
        let leaderboard = try await repositories.leaderboard.leaderboard(
            programID: item.program.id
        )
        let pointsAfter = leaderboard.first {
            $0.participantID == item.participant.id
        }?.score.totalPoints ?? item.scoreBeforeReview
        lastDecision = CoachReviewDecisionResult(
            participantName: item.participant.displayName,
            status: status,
            pointsBefore: item.scoreBeforeReview,
            pointsAfter: pointsAfter
        )
        await load()
    }
}
