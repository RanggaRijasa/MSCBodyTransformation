import Foundation

nonisolated struct CoachPricingService: Sendable {
    func priceBand(for level: MemberLevel) -> CoachPriceBand? {
        switch level {
        case .member:
            nil
        case .sc, .sb:
            .entry
        case .supervisor, .worldTeam:
            .growth
        case .tabTeam, .getTeam, .millionaireTeam, .presidentsTeam:
            .leadership
        }
    }

    func paymentPreview(for level: MemberLevel) -> CoachPaymentPreview? {
        guard let band = priceBand(for: level) else {
            return nil
        }
        return CoachPaymentPreview(
            priceBand: band,
            amountMinorUnits: band.amountMinorUnits
        )
    }
}

nonisolated struct CoachEligibilityService: Sendable {
    func evaluate(
        memberLevel: MemberLevel,
        hasCompletedHOMSTS: Bool,
        hasCompletedICT: Bool
    ) -> CoachEligibility {
        CoachEligibility(
            memberLevel: memberLevel,
            hasCompletedHOMSTS: hasCompletedHOMSTS,
            hasCompletedICT: hasCompletedICT
        )
    }
}

nonisolated struct CoachAccessPeriodCalculator: Sendable {
    func period(
        startingAt startDate: Date,
        durationMonths: Int = 3
    ) -> (start: Date, end: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let endDate = calendar.date(
            byAdding: .month,
            value: durationMonths,
            to: startDate
        ) ?? startDate
        return (startDate, endDate)
    }

    func isExpired(
        _ payment: CoachPaymentPreview,
        at date: Date
    ) -> Bool {
        guard let accessEndsAt = payment.accessEndsAt else {
            return false
        }
        return date >= accessEndsAt
    }
}

nonisolated struct CoachApplicationValidator: Sendable {
    func validateForPayment(_ application: CoachApplication) throws {
        guard application.eligibility.isComplete else {
            throw DomainError.validation(
                field: "coachEligibility",
                reason: "Lengkapi seluruh syarat Coach sebelum pembayaran."
            )
        }
        guard application.payment != nil else {
            throw DomainError.validation(
                field: "coachPrice",
                reason: "Level Member ini belum mempunyai harga akses Coach."
            )
        }
    }

    func validateForApproval(_ application: CoachApplication) throws {
        guard application.eligibility.isComplete else {
            throw DomainError.validation(
                field: "coachEligibility",
                reason: "Syarat Coach belum lengkap."
            )
        }
        guard application.payment?.state == .verified else {
            throw DomainError.validation(
                field: "coachPayment",
                reason: "Pembayaran Coach belum terverifikasi."
            )
        }
    }
}
