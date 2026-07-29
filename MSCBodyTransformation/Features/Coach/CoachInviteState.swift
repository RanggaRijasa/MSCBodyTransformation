import Foundation
import Observation

@MainActor
@Observable
final class CoachInviteComposerState {
    private let service: CoachDataService

    var state: CoachFeatureLoadState<CoachInviteSnapshot> = .idle

    init(environment: AppEnvironment) {
        service = CoachDataService(environment: environment)
    }

    func load() async {
        state = .loading
        do {
            let identity = try await service.identity()
            guard !Task.isCancelled else { return }
            state = .loaded(
                CoachInviteSnapshot(profile: identity.profile)
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
