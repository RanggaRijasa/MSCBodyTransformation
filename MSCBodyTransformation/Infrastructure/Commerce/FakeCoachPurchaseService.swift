import Foundation

nonisolated protocol CoachPurchaseServicing: Sendable {
    func purchase(
        preview: CoachPaymentPreview,
        outcome: FakeCoachPurchaseOutcome
    ) async throws -> FakeCoachPurchaseResult
}

nonisolated struct FakeCoachPurchaseService: CoachPurchaseServicing, Sendable {
    let clock: any AppClock

    func purchase(
        preview: CoachPaymentPreview,
        outcome: FakeCoachPurchaseOutcome
    ) async throws -> FakeCoachPurchaseResult {
        switch outcome {
        case .success:
            let period = CoachAccessPeriodCalculator().period(
                startingAt: clock.now(),
                durationMonths: preview.durationMonths
            )
            return FakeCoachPurchaseResult(
                state: .verified,
                verifiedAt: clock.now(),
                accessStartsAt: period.start,
                accessEndsAt: period.end
            )
        case .cancelled:
            return FakeCoachPurchaseResult(
                state: .cancelled,
                verifiedAt: nil,
                accessStartsAt: nil,
                accessEndsAt: nil
            )
        case .pending:
            return FakeCoachPurchaseResult(
                state: .pending,
                verifiedAt: nil,
                accessStartsAt: nil,
                accessEndsAt: nil
            )
        case .failed:
            return FakeCoachPurchaseResult(
                state: .failed,
                verifiedAt: nil,
                accessStartsAt: nil,
                accessEndsAt: nil
            )
        case .interrupted:
            return FakeCoachPurchaseResult(
                state: .interrupted,
                verifiedAt: nil,
                accessStartsAt: nil,
                accessEndsAt: nil
            )
        }
    }
}
