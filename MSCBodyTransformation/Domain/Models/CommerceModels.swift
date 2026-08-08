import Foundation

nonisolated enum CommerceSubjectKind: String, Codable, Sendable {
    case program
    case coachAccess = "coach_access"
}

nonisolated enum CommerceEnvironment: String, Codable, Sendable {
    case xcode
    case localTesting = "local_testing"
    case sandbox
    case production
}

nonisolated enum CommercePurchaseIntentStatus: String, Codable, Sendable {
    case reserved
    case purchasePending = "purchase_pending"
    case fulfilled
    case cancelled
    case expired
    case failed
}

nonisolated struct CommercePurchaseIntent:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let purchaseIntentID: UUID
    let subjectKind: CommerceSubjectKind
    let productID: String
    let appAccountToken: UUID
    let environment: CommerceEnvironment
    let expiresAt: Date
    let status: CommercePurchaseIntentStatus

    var id: UUID { purchaseIntentID }

    private enum CodingKeys: String, CodingKey {
        case purchaseIntentID = "purchaseIntentId"
        case subjectKind
        case productID = "productId"
        case appAccountToken
        case environment
        case expiresAt
        case status
    }
}

nonisolated struct CommerceProductPresentation:
    Equatable,
    Identifiable,
    Sendable
{
    let intent: CommercePurchaseIntent
    let displayName: String
    let description: String
    let displayPrice: String

    var id: UUID { intent.id }
}

nonisolated enum CommerceFulfillmentStatus: String, Codable, Sendable {
    case verified
    case refunded
    case revoked
    case expired
}

nonisolated struct CommerceFulfillment: Codable, Equatable, Sendable {
    let transactionID: UUID
    let subjectKind: CommerceSubjectKind
    let status: CommerceFulfillmentStatus
    let programID: UUID?
    let enrollmentID: UUID?
    let programEntitlementID: UUID?
    let coachApplicationID: UUID?
    let coachEntitlementID: UUID?
    let coachAccessStartsAt: Date?
    let coachAccessEndsAt: Date?
    let isIdempotent: Bool

    private enum CodingKeys: String, CodingKey {
        case transactionID = "transactionId"
        case subjectKind
        case status
        case programID = "programId"
        case enrollmentID = "enrollmentId"
        case programEntitlementID = "programEntitlementId"
        case coachApplicationID = "coachApplicationId"
        case coachEntitlementID = "coachEntitlementId"
        case coachAccessStartsAt
        case coachAccessEndsAt
        case isIdempotent = "idempotent"
    }
}

nonisolated enum CommercePurchaseOutcome: Equatable, Sendable {
    case fulfilled(CommerceFulfillment)
    case pending
    case cancelled
}

nonisolated enum CommerceProductType: String, Codable, Sendable {
    case nonConsumable = "non_consumable"
    case nonRenewingSubscription = "non_renewing_subscription"
}

nonisolated enum CommerceTransactionStatus: String, Codable, Sendable {
    case pending
    case verified
    case refunded
    case revoked
    case expired
}

nonisolated struct CommerceTransactionRecord:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    let subjectKind: CommerceSubjectKind
    let programID: UUID?
    let coachApplicationID: UUID?
    let provider: String
    let environment: CommerceEnvironment
    let productID: String
    let productType: CommerceProductType
    let status: CommerceTransactionStatus
    let purchasedAt: Date?
    let expiresAt: Date?
    let revocationAt: Date?
    let currencyCode: String?
    let priceMilliunits: Int64?

    private enum CodingKeys: String, CodingKey {
        case id
        case subjectKind
        case programID = "programId"
        case coachApplicationID = "coachApplicationId"
        case provider
        case environment
        case productID = "productId"
        case productType
        case status
        case purchasedAt
        case expiresAt
        case revocationAt
        case currencyCode
        case priceMilliunits
    }
}

nonisolated protocol CommerceServerRepository: Sendable {
    func prepareProgramPurchase(
        programID: UUID,
        idempotencyKey: String
    ) async throws -> CommercePurchaseIntent
    func prepareCoachAccessPurchase(
        idempotencyKey: String
    ) async throws -> CommercePurchaseIntent
    func markPurchasePending(intentID: UUID) async throws
    func verifyApplePurchase(
        intentID: UUID,
        signedTransaction: String
    ) async throws -> CommerceFulfillment
    func restoreApplePurchases(
        signedTransactions: [String]
    ) async throws -> [CommerceFulfillment]
    func history() async throws -> [CommerceTransactionRecord]
}
