import Foundation
import StoreKit

nonisolated protocol ProgramPurchaseVerificationSubmitting: Sendable {
    func verifyAppleTransaction(
        jwsRepresentation: String,
        programID: UUID,
        participantID: UUID,
        coachID: UUID
    ) async throws -> ProgramEntitlement
}

nonisolated enum ProgramPurchaseOutcome: Equatable, Sendable {
    case entitled(ProgramEntitlement)
    case pending
    case cancelled
}

nonisolated struct StoreProductPresentation:
    Equatable,
    Identifiable,
    Sendable
{
    let id: String
    let displayName: String
    let description: String
    let displayPrice: String
}

actor StoreKitProgramPurchaseService {
    private let verifier: any ProgramPurchaseVerificationSubmitting
    private var productsByID: [String: Product] = [:]

    init(verifier: any ProgramPurchaseVerificationSubmitting) {
        self.verifier = verifier
    }

    func loadProduct(
        productID: String
    ) async throws -> StoreProductPresentation {
        let products = try await Product.products(for: [productID])
        guard let product = products.first(where: { $0.id == productID }) else {
            throw DomainError.notFound(resource: "store_product")
        }
        productsByID[product.id] = product
        return StoreProductPresentation(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice
        )
    }

    func purchase(
        productID: String,
        programID: UUID,
        participantID: UUID,
        validatedCoachID: UUID
    ) async throws -> ProgramPurchaseOutcome {
        let product: Product
        if let cached = productsByID[productID] {
            product = cached
        } else {
            _ = try await loadProduct(productID: productID)
            guard let loaded = productsByID[productID] else {
                throw DomainError.notFound(resource: "store_product")
            }
            product = loaded
        }

        switch try await product.purchase() {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                let entitlement = try await verifier.verifyAppleTransaction(
                    jwsRepresentation: verification.jwsRepresentation,
                    programID: programID,
                    participantID: participantID,
                    coachID: validatedCoachID
                )
                await transaction.finish()
                return .entitled(entitlement)
            case .unverified:
                throw DomainError.conflict(
                    reason: "Transaksi tidak dapat diverifikasi."
                )
            }
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            throw DomainError.unknown
        }
    }

    func recoverCurrentEntitlements(
        productIDs: Set<String>,
        programByProductID: [String: UUID],
        participantID: UUID,
        validatedCoachID: UUID
    ) async -> [ProgramEntitlement] {
        var entitlements: [ProgramEntitlement] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  productIDs.contains(transaction.productID),
                  let programID = programByProductID[
                      transaction.productID
                  ],
                  let entitlement = try? await verifier
                      .verifyAppleTransaction(
                          jwsRepresentation: result.jwsRepresentation,
                          programID: programID,
                          participantID: participantID,
                          coachID: validatedCoachID
                      ) else {
                continue
            }
            await transaction.finish()
            entitlements.append(entitlement)
        }
        return entitlements
    }

    /// The feature layer owns and cancels the task running this method.
    /// Enrollment is still created only after the server verifier returns an
    /// entitlement.
    func listenForTransactionUpdates(
        productIDs: Set<String>,
        programByProductID: [String: UUID],
        participantID: UUID,
        validatedCoachID: UUID,
        onEntitlement: @Sendable (ProgramEntitlement) async -> Void
    ) async {
        for await result in Transaction.updates {
            guard !Task.isCancelled else { return }
            guard case .verified(let transaction) = result,
                  productIDs.contains(transaction.productID),
                  let programID = programByProductID[
                      transaction.productID
                  ],
                  let entitlement = try? await verifier
                      .verifyAppleTransaction(
                          jwsRepresentation: result.jwsRepresentation,
                          programID: programID,
                          participantID: participantID,
                          coachID: validatedCoachID
                      ) else {
                continue
            }
            await transaction.finish()
            await onEntitlement(entitlement)
        }
    }
}
