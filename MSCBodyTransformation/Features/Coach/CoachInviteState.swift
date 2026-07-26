import Foundation
import Observation

@MainActor
@Observable
final class CoachInviteComposerState {
    private let environment: AppEnvironment
    private let service: CoachDataService

    var state: CoachFeatureLoadState<CoachInviteSnapshot> = .idle
    var selectedProgramID: UUID?
    var validForDays = 7
    var isPerformingAction = false
    var latestGeneratedInviteID: UUID?

    init(environment: AppEnvironment) {
        self.environment = environment
        service = CoachDataService(environment: environment)
    }

    var snapshot: CoachInviteSnapshot? {
        guard case .loaded(let snapshot) = state else {
            return nil
        }
        return snapshot
    }

    var selectedProgram: Program? {
        let programID = selectedProgramID
        return snapshot?.programs.first { $0.id == programID }
    }

    var latestGeneratedInvite: CoachInvite? {
        guard let latestGeneratedInviteID else {
            return nil
        }
        return snapshot?.invites.first { $0.id == latestGeneratedInviteID }
    }

    func load() async {
        state = .loading
        do {
            let identity = try await service.identity()
            guard let repositories = environment.repositories else {
                throw environment.bootstrapError ?? DomainError.unknown
            }
            let programs = try await repositories.programs.programs()
                .filter {
                    $0.status == .active || $0.status == .scheduled
                }
            let wallet = try await repositories.wallet.wallet(
                coachID: identity.profile.id
            )
            let invites = try await repositories.invites.invites(
                coachID: identity.profile.id
            )
            if selectedProgramID == nil {
                selectedProgramID = programs.first?.id
            }
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(
                CoachInviteSnapshot(
                    profile: identity.profile,
                    programs: programs,
                    wallet: wallet,
                    invites: normalizedInvites(invites)
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

    func generateInvite() async throws {
        guard let repositories = environment.repositories,
              let programID = selectedProgramID else {
            throw DomainError.notFound(resource: "program")
        }
        let identity = try await service.identity()
        isPerformingAction = true
        defer { isPerformingAction = false }

        let invite = try await GenerateLocalInviteUseCase(
            repository: repositories.invites,
            identifierGenerator: environment.identifierGenerator,
            clock: environment.clock
        )(
            coachID: identity.profile.id,
            programID: programID,
            validForDays: validForDays
        )
        latestGeneratedInviteID = invite.id
        await load()
    }

    func revoke(_ invite: CoachInvite) async throws {
        guard let repositories = environment.repositories else {
            throw environment.bootstrapError ?? DomainError.unknown
        }
        let identity = try await service.identity()
        isPerformingAction = true
        defer { isPerformingAction = false }
        _ = try await repositories.invites.revokeInvite(
            id: invite.id,
            coachID: identity.profile.id
        )
        await load()
    }

    private func normalizedInvites(
        _ invites: [CoachInvite]
    ) -> [CoachInvite] {
        invites.map { invite in
            guard invite.status == .active,
                  invite.expiresAt < environment.clock.now() else {
                return invite
            }
            var expired = invite
            expired.status = .expired
            return expired
        }
    }
}

@MainActor
@Observable
final class CoachStorePreviewState {
    private let environment: AppEnvironment
    private let service: CoachDataService

    var state: CoachFeatureLoadState<CoachStoreSnapshot> = .idle
    var purchaseState: CoachPurchaseState = .loading
    var selectedPack: CoachSeatPack?

    init(environment: AppEnvironment) {
        self.environment = environment
        service = CoachDataService(environment: environment)
    }

    func load() async {
        state = .loading
        purchaseState = .loading
        do {
            let identity = try await service.identity()
            guard let repositories = environment.repositories else {
                throw environment.bootstrapError ?? DomainError.unknown
            }
            let wallet = try await repositories.wallet.wallet(
                coachID: identity.profile.id
            )
            let ledger = try await repositories.wallet.ledger(
                walletID: wallet.id
            )
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(
                CoachStoreSnapshot(
                    profile: identity.profile,
                    wallet: wallet,
                    ledger: ledger
                )
            )
            purchaseState = .available
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            state = .failed(error)
            purchaseState = .failed
        } catch {
            state = .failed(.unknown)
            purchaseState = .failed
        }
    }

    func prepareDemoPurchase(_ pack: CoachSeatPack) {
        selectedPack = pack
        purchaseState = .purchasing(pack)
    }

    func simulateSuccessfulPurchase() async throws {
        guard let pack = selectedPack,
              let repositories = environment.repositories else {
            throw DomainError.unknown
        }
        let identity = try await service.identity()
        purchaseState = .pending(pack)
        _ = try await repositories.coachDemo.grantSeatCredits(
            coachID: identity.profile.id,
            amount: pack.seatCredits,
            grantedAt: environment.clock.now()
        )
        purchaseState = .success(pack)
        await reloadSnapshotKeepingPurchaseState()
    }

    func simulateCancellation() {
        purchaseState = .cancelled
        selectedPack = nil
    }

    func simulateFailure() {
        purchaseState = .failed
    }

#if DEBUG
    func setPreviewState(_ state: CoachPurchaseState) {
        purchaseState = state
    }
#endif

    private func reloadSnapshotKeepingPurchaseState() async {
        let currentPurchaseState = purchaseState
        await load()
        purchaseState = currentPurchaseState
    }
}
