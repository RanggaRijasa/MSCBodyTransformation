import Foundation
import Observation

@MainActor
@Observable
final class CoachDashboardState {
    private let service: CoachDataService
    private let environment: AppEnvironment

    var state: CoachFeatureLoadState<CoachDashboardSnapshot> = .idle

    init(environment: AppEnvironment) {
        self.environment = environment
        service = CoachDataService(environment: environment)
    }

    func load() async {
        state = .loading
        do {
            let identity = try await service.identity()
            guard let repositories = environment.repositories else {
                throw environment.bootstrapError ?? DomainError.unknown
            }
            let wallet = try await repositories.wallet.wallet(
                coachID: identity.profile.id
            )
            let programs = try await repositories.programs.programs()
            let participants = try await service.participantSummaries(
                coachID: identity.profile.id
            )
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(
                CoachDashboardSnapshot(
                    profile: identity.profile,
                    wallet: wallet,
                    activePrograms: programs.filter {
                        $0.status == .active
                    },
                    participants: participants
                )
            )
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }
}

@MainActor
@Observable
final class CoachParticipantsState {
    private let service: CoachDataService

    var state: CoachFeatureLoadState<[CoachParticipantSummary]> = .idle
    var query = ""
    var selectedProgramID: UUID?
    var completionFilter: CoachCompletionFilter = .all
    var reviewFilter: CoachReviewFilter = .all
    var sort: CoachParticipantSort = .progress

    init(environment: AppEnvironment) {
        service = CoachDataService(environment: environment)
    }

    var participants: [CoachParticipantSummary] {
        guard case .loaded(let participants) = state else {
            return []
        }
        return participants
    }

    var availablePrograms: [Program] {
        let programs = participants.compactMap(\.program)
        return Dictionary(
            grouping: programs,
            by: \.id
        ).compactMap { $0.value.first }
            .sorted { $0.startDate > $1.startDate }
    }

    var filteredParticipants: [CoachParticipantSummary] {
        let normalizedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return participants
            .filter { participant in
                normalizedQuery.isEmpty
                    || participant.profile.displayName.localizedCaseInsensitiveContains(
                        normalizedQuery
                    )
                    || participant.profile.city.localizedCaseInsensitiveContains(
                        normalizedQuery
                    )
            }
            .filter { participant in
                selectedProgramID == nil
                    || participant.program?.id == selectedProgramID
            }
            .filter(matchesCompletionFilter)
            .filter(matchesReviewFilter)
            .sorted(by: orderedBefore)
    }

    func load() async {
        state = .loading
        do {
            let identity = try await service.identity()
            let participants = try await service.participantSummaries(
                coachID: identity.profile.id
            )
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(participants)
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }

    private func matchesCompletionFilter(
        _ participant: CoachParticipantSummary
    ) -> Bool {
        switch completionFilter {
        case .all:
            true
        case .inProgress:
            !participant.isComplete && !participant.isFallingBehind
        case .complete:
            participant.isComplete
        case .fallingBehind:
            participant.isFallingBehind
        }
    }

    private func matchesReviewFilter(
        _ participant: CoachParticipantSummary
    ) -> Bool {
        switch reviewFilter {
        case .all:
            true
        case .pending:
            participant.pendingReviewCount > 0
        case .rejected:
            participant.rejectedCount > 0
        }
    }

    private func orderedBefore(
        _ left: CoachParticipantSummary,
        _ right: CoachParticipantSummary
    ) -> Bool {
        switch sort {
        case .progress:
            if left.progressPercentage == right.progressPercentage {
                return left.profile.displayName < right.profile.displayName
            }
            return left.progressPercentage > right.progressPercentage
        case .points:
            if left.points == right.points {
                return left.profile.displayName < right.profile.displayName
            }
            return left.points > right.points
        case .lastActivity:
            if left.lastActivityAt == right.lastActivityAt {
                return left.profile.displayName < right.profile.displayName
            }
            return left.lastActivityAt > right.lastActivityAt
        }
    }
}

@MainActor
@Observable
final class CoachParticipantDetailState {
    private let participantID: UUID
    private let coachID: UUID
    private let service: CoachDataService

    var state: CoachFeatureLoadState<CoachParticipantSummary> = .idle

    init(
        participantID: UUID,
        coachID: UUID,
        environment: AppEnvironment
    ) {
        self.participantID = participantID
        self.coachID = coachID
        service = CoachDataService(environment: environment)
    }

    func load() async {
        state = .loading
        do {
            let summary = try await service.participantSummary(
                participantID: participantID,
                coachID: coachID
            )
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(summary)
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }
}
