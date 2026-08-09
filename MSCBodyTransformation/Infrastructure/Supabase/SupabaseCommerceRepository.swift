import Foundation

actor SupabaseCommerceRepository: CommerceServerRepository {
    private let client: any SupabaseClientProviding
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(client: any SupabaseClientProviding) {
        self.client = client
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func prepareProgramPurchase(
        programID: UUID,
        idempotencyKey: String
    ) async throws -> CommercePurchaseIntent {
        try await prepare(
            path: "functions/v1/commerce/programs/\(programID.uuidString.lowercased())/preflight",
            idempotencyKey: idempotencyKey
        )
    }

    func prepareCoachAccessPurchase(
        idempotencyKey: String
    ) async throws -> CommercePurchaseIntent {
        try await prepare(
            path: "functions/v1/commerce/coach-access/preflight",
            idempotencyKey: idempotencyKey
        )
    }

    func markPurchasePending(intentID: UUID) async throws {
        _ = try await client.execute(
            SupabaseRequest(
                method: .post,
                path: "functions/v1/commerce/intents/\(intentID.uuidString.lowercased())/pending"
            )
        )
    }

    func verifyApplePurchase(
        intentID: UUID,
        signedTransaction: String
    ) async throws -> CommerceFulfillment {
        struct Body: Encodable {
            let purchaseIntentId: UUID
            let signedTransaction: String
        }
        let data = try await client.execute(
            SupabaseRequest(
                method: .post,
                path: "functions/v1/commerce/apple/verify",
                headers: ["Content-Type": "application/json"],
                body: try encoder.encode(
                    Body(
                        purchaseIntentId: intentID,
                        signedTransaction: signedTransaction
                    )
                )
            )
        )
        return try decoder.decode(CommerceFulfillment.self, from: data)
    }

    func restoreApplePurchases(
        signedTransactions: [String]
    ) async throws -> [CommerceFulfillment] {
        struct Candidate: Encodable {
            let signedTransaction: String
        }
        struct Body: Encodable {
            let transactions: [Candidate]
        }
        struct Response: Decodable {
            let fulfillments: [CommerceFulfillment]
        }
        guard !signedTransactions.isEmpty else { return [] }
        let data = try await client.execute(
            SupabaseRequest(
                method: .post,
                path: "functions/v1/commerce/apple/restore",
                headers: ["Content-Type": "application/json"],
                body: try encoder.encode(
                    Body(
                        transactions: signedTransactions.map {
                            Candidate(signedTransaction: $0)
                        }
                    )
                )
            )
        )
        return try decoder.decode(Response.self, from: data).fulfillments
    }

    func history() async throws -> [CommerceTransactionRecord] {
        struct Response: Decodable {
            let transactions: [CommerceTransactionRecord]
        }
        let data = try await client.execute(
            SupabaseRequest(
                method: .get,
                path: "functions/v1/commerce/history"
            )
        )
        return try decoder.decode(Response.self, from: data).transactions
    }

    private func prepare(
        path: String,
        idempotencyKey: String
    ) async throws -> CommercePurchaseIntent {
        let data = try await client.execute(
            SupabaseRequest(
                method: .post,
                path: path,
                headers: ["Idempotency-Key": idempotencyKey]
            )
        )
        return try decoder.decode(CommercePurchaseIntent.self, from: data)
    }
}
