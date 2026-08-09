import Foundation
import StoreKit

nonisolated enum CommerceClientStage: Equatable, Sendable {
    case purchasing
    case verifying
}

nonisolated enum CommerceTransactionUpdate: Sendable {
    case fulfilled(CommerceFulfillment)
    case failed(DomainError)
}

actor StoreKitProgramPurchaseService {
    private let server: any CommerceServerRepository
    private var productsByID: [String: Product] = [:]

    init(server: any CommerceServerRepository) {
        self.server = server
    }

    func prepareProgramPurchase(
        programID: UUID,
        idempotencyKey: String
    ) async throws -> CommerceProductPresentation {
        let intent = try await server.prepareProgramPurchase(
            programID: programID,
            idempotencyKey: idempotencyKey
        )
        return try await presentation(for: intent)
    }

    func prepareCoachAccessPurchase(
        idempotencyKey: String
    ) async throws -> CommerceProductPresentation {
        let intent = try await server.prepareCoachAccessPurchase(
            idempotencyKey: idempotencyKey
        )
        return try await presentation(for: intent)
    }

    func purchase(
        _ offering: CommerceProductPresentation,
        onStage: @Sendable (CommerceClientStage) async -> Void
    ) async throws -> CommercePurchaseOutcome {
        let product = try await product(for: offering.intent.productID)
        try await server.markPurchasePending(intentID: offering.intent.id)
        await onStage(.purchasing)

        let result = try await product.purchase(
            options: [
                .appAccountToken(offering.intent.appAccountToken)
            ]
        )
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw DomainError.conflict(
                    reason: "Transaksi Apple tidak dapat diverifikasi."
                )
            }
            await onStage(.verifying)
            let fulfillment = try await server.verifyApplePurchase(
                intentID: offering.intent.id,
                signedTransaction: verification.jwsRepresentation
            )
            await transaction.finish()
            return .fulfilled(fulfillment)
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            throw DomainError.unknown
        }
    }

    func recoverUnfinishedTransactions() async throws
        -> [CommerceFulfillment]
    {
        var fulfillments: [CommerceFulfillment] = []
        for await verification in Transaction.unfinished {
            guard !Task.isCancelled else { throw CancellationError() }
            guard case .verified(let transaction) = verification else {
                throw DomainError.conflict(
                    reason: "Transaksi tertunda tidak dapat diverifikasi."
                )
            }
            let restored = try await server.restoreApplePurchases(
                signedTransactions: [verification.jwsRepresentation]
            )
            await transaction.finish()
            fulfillments.append(contentsOf: restored)
        }
        return fulfillments
    }

    func restorePurchases() async throws -> [CommerceFulfillment] {
        try await AppStore.sync()
        let productIDs = Set(try await server.history().map(\.productID))
        guard !productIDs.isEmpty else { return [] }

        var signedTransactions: [String] = []
        var transactions: [Transaction] = []
        for await verification in Transaction.currentEntitlements {
            guard !Task.isCancelled else { throw CancellationError() }
            guard case .verified(let transaction) = verification else {
                throw DomainError.conflict(
                    reason: "Pembelian tersimpan tidak dapat diverifikasi."
                )
            }
            guard productIDs.contains(transaction.productID) else { continue }
            signedTransactions.append(verification.jwsRepresentation)
            transactions.append(transaction)
        }
        guard !signedTransactions.isEmpty else { return [] }
        let fulfillments = try await server.restoreApplePurchases(
            signedTransactions: signedTransactions
        )
        for transaction in transactions {
            await transaction.finish()
        }
        return fulfillments
    }

    func history() async throws -> [CommerceTransactionRecord] {
        try await server.history()
    }

    /// The app-level coordinator owns and cancels the single task that calls
    /// this method. Every verified update is persisted server-side before the
    /// StoreKit transaction is finished.
    func listenForTransactionUpdates(
        onUpdate: @Sendable (CommerceTransactionUpdate) async -> Void
    ) async {
        for await verification in Transaction.updates {
            guard !Task.isCancelled else { return }
            do {
                guard case .verified(let transaction) = verification else {
                    throw DomainError.conflict(
                        reason: "Pembaruan transaksi tidak dapat diverifikasi."
                    )
                }
                let results = try await server.restoreApplePurchases(
                    signedTransactions: [verification.jwsRepresentation]
                )
                await transaction.finish()
                for result in results {
                    await onUpdate(.fulfilled(result))
                }
            } catch is CancellationError {
                return
            } catch let error as DomainError {
                await onUpdate(.failed(error))
            } catch {
                await onUpdate(.failed(.unknown))
            }
        }
    }

    private func presentation(
        for intent: CommercePurchaseIntent
    ) async throws -> CommerceProductPresentation {
        let product = try await product(for: intent.productID)
        return CommerceProductPresentation(
            intent: intent,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice
        )
    }

    private func product(for productID: String) async throws -> Product {
        if let product = productsByID[productID] {
            return product
        }
        let products = try await Product.products(for: [productID])
        guard let product = products.first(where: { $0.id == productID }) else {
            throw DomainError.notFound(resource: "Produk App Store")
        }
        productsByID[product.id] = product
        return product
    }
}
