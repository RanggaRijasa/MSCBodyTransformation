import Foundation
import Observation

nonisolated enum CommerceCoordinatorState: Equatable, Sendable {
    case idle
    case loadingProduct
    case ready(CommerceProductPresentation)
    case purchasing
    case pending
    case verifying
    case fulfilled(CommerceFulfillment)
    case cancelled
    case failed(DomainError)
    case refunded
    case revoked
}

@MainActor
@Observable
final class CommerceCoordinator {
    private let service: StoreKitProgramPurchaseService
    private let sessionRepository: (any SessionRepository)?
    private var listenerTask: Task<Void, Never>?
    private var activeAccountID: UUID?

    private(set) var state: CommerceCoordinatorState = .idle
    private(set) var latestFulfillment: CommerceFulfillment?
    private(set) var transactionHistory: [CommerceTransactionRecord] = []
    private(set) var roleRefreshError: DomainError?

    init(
        service: StoreKitProgramPurchaseService,
        sessionRepository: (any SessionRepository)? = nil
    ) {
        self.service = service
        self.sessionRepository = sessionRepository
    }

    func start(accountID: UUID) async {
        guard activeAccountID != accountID || listenerTask == nil else {
            return
        }
        stop()
        activeAccountID = accountID
        let coordinator = self
        listenerTask = Task { [service, coordinator] in
            await service.listenForTransactionUpdates { update in
                await coordinator.apply(update)
            }
        }
        do {
            let recovered = try await service.recoverUnfinishedTransactions()
            if let latest = recovered.last {
                await apply(latest)
            }
            transactionHistory = try await service.history()
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }

    func stop() {
        listenerTask?.cancel()
        listenerTask = nil
        activeAccountID = nil
        latestFulfillment = nil
        transactionHistory = []
        roleRefreshError = nil
        state = .idle
    }

    func prepareProgramPurchase(
        programID: UUID
    ) async throws -> CommerceProductPresentation {
        state = .loadingProduct
        do {
            let offering = try await service.prepareProgramPurchase(
                programID: programID,
                idempotencyKey: "program-\(programID.uuidString.lowercased())-\(UUID().uuidString.lowercased())"
            )
            state = .ready(offering)
            return offering
        } catch let error as DomainError {
            state = .failed(error)
            throw error
        } catch {
            state = .failed(.unknown)
            throw DomainError.unknown
        }
    }

    func prepareCoachAccessPurchase() async throws
        -> CommerceProductPresentation
    {
        state = .loadingProduct
        do {
            let offering = try await service.prepareCoachAccessPurchase(
                idempotencyKey: "coach-\(UUID().uuidString.lowercased())"
            )
            state = .ready(offering)
            return offering
        } catch let error as DomainError {
            state = .failed(error)
            throw error
        } catch {
            state = .failed(.unknown)
            throw DomainError.unknown
        }
    }

    func purchase(
        _ offering: CommerceProductPresentation
    ) async throws -> CommercePurchaseOutcome {
        do {
            let result = try await service.purchase(offering) { [weak self] stage in
                await self?.apply(stage)
            }
            switch result {
            case .fulfilled(let fulfillment):
                await apply(fulfillment)
                transactionHistory = try await service.history()
            case .pending:
                state = .pending
            case .cancelled:
                state = .cancelled
            }
            return result
        } catch let error as DomainError {
            state = .failed(error)
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            state = .failed(.unknown)
            throw DomainError.unknown
        }
    }

    func restorePurchases() async throws -> [CommerceFulfillment] {
        state = .verifying
        do {
            let results = try await service.restorePurchases()
            if let latest = results.last {
                await apply(latest)
            } else {
                state = .idle
            }
            transactionHistory = try await service.history()
            return results
        } catch let error as DomainError {
            state = .failed(error)
            throw error
        } catch {
            state = .failed(.unknown)
            throw DomainError.unknown
        }
    }

    func loadHistory() async throws {
        transactionHistory = try await service.history()
    }

    private func apply(_ stage: CommerceClientStage) {
        state = switch stage {
        case .purchasing: .purchasing
        case .verifying: .verifying
        }
    }

    private func apply(_ update: CommerceTransactionUpdate) async {
        switch update {
        case .fulfilled(let fulfillment):
            await apply(fulfillment)
        case .failed(let error):
            state = .failed(error)
        }
    }

    private func apply(_ fulfillment: CommerceFulfillment) async {
        latestFulfillment = fulfillment
        state = switch fulfillment.status {
        case .verified: .fulfilled(fulfillment)
        case .refunded: .refunded
        case .revoked: .revoked
        case .expired: .failed(
            .conflict(reason: "Akses pembelian sudah berakhir.")
        )
        }
        guard fulfillment.subjectKind == .coachAccess,
              fulfillment.status == .verified,
              let sessionRepository else {
            return
        }
        do {
            _ = try await sessionRepository.restoreSession()
            roleRefreshError = nil
        } catch let error as DomainError {
            roleRefreshError = error
        } catch {
            roleRefreshError = .unknown
        }
    }
}
