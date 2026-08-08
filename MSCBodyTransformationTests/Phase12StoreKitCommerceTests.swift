import Foundation
import StoreKit
import StoreKitTest
import Testing
@testable import MSCBodyTransformation

@Suite("Phase 12 StoreKit commerce", .serialized)
struct Phase12StoreKitCommerceTests {
    private let programProductID = "local.msc.program.phase12.cohort"
    private let coachProductIDs: Set<String> = [
        "local.msc.coach.access.entry.3months",
        "local.msc.coach.access.growth.3months",
        "local.msc.coach.access.leadership.3months"
    ]

    @Test("Local StoreKit configuration contains the authoritative product types")
    func configurationProductsLoad() async throws {
        let session = try makeSession()
        session.clearTransactions()

        let products = try await Product.products(
            for: coachProductIDs.union([programProductID])
        )
        #expect(products.count == 4)
        #expect(
            products.first { $0.id == programProductID }?.type
                == .nonConsumable
        )
        #expect(
            products.filter { coachProductIDs.contains($0.id) }
                .allSatisfy { $0.type == .nonRenewable }
        )
    }

    @Test("Verified purchase reaches the server before StoreKit finishes it")
    func verifiedPurchaseUsesIntentAndFinishesAfterServer() async throws {
        let session = try makeSession()
        session.clearTransactions()
        let server = Phase12CommerceServerDouble()
        let service = StoreKitProgramPurchaseService(server: server)
        let offering = try await service.prepareProgramPurchase(
            programID: Phase12CommerceServerDouble.programID,
            idempotencyKey: "phase12-program-success"
        )
        let stages = Phase12StageRecorder()

        let outcome = try await service.purchase(offering) { stage in
            await stages.record(stage)
        }

        guard case .fulfilled(let fulfillment) = outcome else {
            Issue.record("Pembelian harus dipenuhi")
            return
        }
        #expect(fulfillment.programID == Phase12CommerceServerDouble.programID)
        #expect(await server.pendingIntentIDs() == [offering.intent.id])
        #expect(await server.verifiedIntentIDs() == [offering.intent.id])
        #expect(await stages.values() == [.purchasing, .verifying])
        #expect(await unfinishedTransactions().isEmpty)

        let transaction = try #require(session.allTransactions().first)
        #expect(transaction.productIdentifier == programProductID)
    }

    @Test("Server failure leaves the transaction unfinished and recoverable")
    func failedServerVerificationDoesNotFinishTransaction() async throws {
        let session = try makeSession()
        session.clearTransactions()
        let server = Phase12CommerceServerDouble(
            verificationError: .offline
        )
        let service = StoreKitProgramPurchaseService(server: server)
        let offering = try await service.prepareProgramPurchase(
            programID: Phase12CommerceServerDouble.programID,
            idempotencyKey: "phase12-program-offline"
        )

        await #expect(throws: DomainError.offline) {
            try await service.purchase(offering) { _ in }
        }
        #expect(!(await unfinishedTransactions()).isEmpty)

        let recoveryServer = Phase12CommerceServerDouble()
        let recoveryService = StoreKitProgramPurchaseService(
            server: recoveryServer
        )
        let recovered = try await recoveryService
            .recoverUnfinishedTransactions()
        #expect(recovered.count == 1)
        #expect(await unfinishedTransactions().isEmpty)
    }

    @Test("Ask to Buy returns pending without server fulfillment")
    func askToBuyIsPending() async throws {
        let session = try makeSession()
        session.clearTransactions()
        session.askToBuyEnabled = true
        let server = Phase12CommerceServerDouble()
        let service = StoreKitProgramPurchaseService(server: server)
        let offering = try await service.prepareCoachAccessPurchase(
            idempotencyKey: "phase12-coach-pending"
        )

        let outcome = try await service.purchase(offering) { _ in }

        #expect(outcome == .pending)
        #expect(await server.pendingIntentIDs() == [offering.intent.id])
        #expect(await server.verifiedIntentIDs().isEmpty)
    }

    @Test("Refund removes a non-consumable from current entitlements")
    func refundChangesCurrentEntitlement() async throws {
        let session = try makeSession()
        session.clearTransactions()
        let transaction = try await session.buyProduct(
            identifier: programProductID,
            options: [
                .appAccountToken(Phase12CommerceServerDouble.appAccountToken)
            ]
        )
        let testTransaction = try #require(
            session.allTransactions().first {
                $0.identifier == transaction.id
            }
        )

        try session.refundTransaction(identifier: testTransaction.identifier)

        var activeTransactionIDs: [UInt64] = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let value) = result,
               value.productID == programProductID {
                activeTransactionIDs.append(value.id)
            }
        }
        #expect(!activeTransactionIDs.contains(transaction.id))
    }

    @Test("Supabase adapter sends only opaque intent and signed transaction")
    func supabaseAdapterUsesCommerceContract() async throws {
        let intentID = UUID(
            uuidString: "c1200000-0000-0000-0000-000000000001"
        )!
        let client = Phase12RecordingSupabaseClient(
            responses: [
                "functions/v1/commerce/programs/\(Phase12CommerceServerDouble.programID.uuidString.lowercased())/preflight":
                    Data(Self.intentPayload.utf8),
                "functions/v1/commerce/apple/verify":
                    Data(Self.fulfillmentPayload.utf8)
            ]
        )
        let repository = SupabaseCommerceRepository(client: client)

        _ = try await repository.prepareProgramPurchase(
            programID: Phase12CommerceServerDouble.programID,
            idempotencyKey: "phase12-contract"
        )
        _ = try await repository.verifyApplePurchase(
            intentID: intentID,
            signedTransaction: "header.payload.signature"
        )
        let requests = await client.requests()
        let preflight = try #require(requests.first)
        let verification = try #require(requests.last)

        #expect(preflight.headers["Idempotency-Key"] == "phase12-contract")
        #expect(preflight.body == nil)
        let body = try #require(verification.body)
        let object = try #require(
            JSONSerialization.jsonObject(with: body) as? [String: String]
        )
        #expect(Set(object.keys) == ["purchaseIntentId", "signedTransaction"])
        #expect(object["signedTransaction"] == "header.payload.signature")
    }

    private func makeSession() throws -> SKTestSession {
        guard let configurationURL = Bundle.main.url(
            forResource: "Products",
            withExtension: "storekit"
        ) else {
            throw DomainError.notFound(resource: "Konfigurasi StoreKit")
        }
        let session = try SKTestSession(contentsOf: configurationURL)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.askToBuyEnabled = false
        session.interruptedPurchasesEnabled = false
        return session
    }

    private func unfinishedTransactions() async -> [Transaction] {
        var values: [Transaction] = []
        for await result in Transaction.unfinished {
            if case .verified(let transaction) = result {
                values.append(transaction)
            }
        }
        return values
    }

    private static let intentPayload = """
    {
      "purchaseIntentId": "c1200000-0000-0000-0000-000000000001",
      "subjectKind": "program",
      "productId": "local.msc.program.phase12.cohort",
      "appAccountToken": "c1200000-0000-0000-0000-000000000002",
      "environment": "xcode",
      "expiresAt": "2026-08-08T10:30:00Z",
      "status": "reserved"
    }
    """

    private static let fulfillmentPayload = """
    {
      "transactionId": "c1200000-0000-0000-0000-000000000003",
      "subjectKind": "program",
      "status": "verified",
      "programId": "c1200000-0000-0000-0000-000000000010",
      "enrollmentId": "c1200000-0000-0000-0000-000000000011",
      "programEntitlementId": "c1200000-0000-0000-0000-000000000012",
      "coachApplicationId": null,
      "coachEntitlementId": null,
      "coachAccessStartsAt": null,
      "coachAccessEndsAt": null,
      "idempotent": false
    }
    """
}

private actor Phase12CommerceServerDouble: CommerceServerRepository {
    static let programID = UUID(
        uuidString: "c1200000-0000-0000-0000-000000000010"
    )!
    static let appAccountToken = UUID(
        uuidString: "c1200000-0000-0000-0000-000000000002"
    )!

    private let verificationError: DomainError?
    private var pending: [UUID] = []
    private var verified: [UUID] = []

    init(verificationError: DomainError? = nil) {
        self.verificationError = verificationError
    }

    func prepareProgramPurchase(
        programID: UUID,
        idempotencyKey: String
    ) async throws -> CommercePurchaseIntent {
        intent(
            subject: .program,
            productID: "local.msc.program.phase12.cohort"
        )
    }

    func prepareCoachAccessPurchase(
        idempotencyKey: String
    ) async throws -> CommercePurchaseIntent {
        intent(
            subject: .coachAccess,
            productID: "local.msc.coach.access.entry.3months"
        )
    }

    func markPurchasePending(intentID: UUID) async throws {
        pending.append(intentID)
    }

    func verifyApplePurchase(
        intentID: UUID,
        signedTransaction: String
    ) async throws -> CommerceFulfillment {
        if let verificationError { throw verificationError }
        verified.append(intentID)
        return fulfillment(subject: .program)
    }

    func restoreApplePurchases(
        signedTransactions: [String]
    ) async throws -> [CommerceFulfillment] {
        if let verificationError { throw verificationError }
        return signedTransactions.map { _ in fulfillment(subject: .program) }
    }

    func history() async throws -> [CommerceTransactionRecord] { [] }

    func pendingIntentIDs() -> [UUID] { pending }
    func verifiedIntentIDs() -> [UUID] { verified }

    private func intent(
        subject: CommerceSubjectKind,
        productID: String
    ) -> CommercePurchaseIntent {
        CommercePurchaseIntent(
            purchaseIntentID: UUID(),
            subjectKind: subject,
            productID: productID,
            appAccountToken: Self.appAccountToken,
            environment: .xcode,
            expiresAt: Date().addingTimeInterval(1_800),
            status: .reserved
        )
    }

    private func fulfillment(
        subject: CommerceSubjectKind
    ) -> CommerceFulfillment {
        CommerceFulfillment(
            transactionID: UUID(),
            subjectKind: subject,
            status: .verified,
            programID: subject == .program ? Self.programID : nil,
            enrollmentID: subject == .program ? UUID() : nil,
            programEntitlementID: subject == .program ? UUID() : nil,
            coachApplicationID: nil,
            coachEntitlementID: nil,
            coachAccessStartsAt: nil,
            coachAccessEndsAt: nil,
            isIdempotent: false
        )
    }
}

private actor Phase12StageRecorder {
    private var stages: [CommerceClientStage] = []

    func record(_ stage: CommerceClientStage) {
        stages.append(stage)
    }

    func values() -> [CommerceClientStage] { stages }
}

private actor Phase12RecordingSupabaseClient: SupabaseClientProviding {
    private let responses: [String: Data]
    private var capturedRequests: [SupabaseRequest] = []

    init(responses: [String: Data]) {
        self.responses = responses
    }

    func execute(_ request: SupabaseRequest) async throws -> Data {
        capturedRequests.append(request)
        guard let response = responses[request.path] else {
            throw DomainError.notFound(resource: request.path)
        }
        return response
    }

    func requests() -> [SupabaseRequest] { capturedRequests }
}
