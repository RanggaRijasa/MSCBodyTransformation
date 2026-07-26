import SwiftUI

nonisolated struct ParticipantStepPresentation: Sendable {
    let titleKey: String
    let kind: AppStatusKind
    let systemImage: String

    static func make(
        submission: StepSubmission?,
        access: ProgramDayAccess
    ) -> Self {
        if access == .locked || access == .hidden {
            return Self(
                titleKey: "status.locked",
                kind: .locked,
                systemImage: "lock.fill"
            )
        }
        guard let submission else {
            return Self(
                titleKey: "participant.status.not_started",
                kind: .neutral,
                systemImage: "circle"
            )
        }
        switch submission.status {
        case .pending:
            return Self(
                titleKey: "status.pending",
                kind: .pending,
                systemImage: "clock.fill"
            )
        case .approved:
            return Self(
                titleKey: "status.approved",
                kind: .success,
                systemImage: "checkmark.circle.fill"
            )
        case .rejected:
            return Self(
                titleKey: "status.rejected",
                kind: .error,
                systemImage: "exclamationmark.triangle.fill"
            )
        }
    }
}

nonisolated enum ParticipantFormatting {
    static let locale = Locale(identifier: "id-ID")

    static func points(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }

    static func percentage(_ value: Int) -> String {
        (Double(value) / 100).formatted(
            .percent
                .locale(locale)
                .precision(.fractionLength(0))
        )
    }

    static func weight(_ value: Decimal) -> String {
        value.formatted(
            .number
                .locale(locale)
                .precision(.fractionLength(0...2))
        ) + " kg"
    }

    static func date(
        _ value: Date,
        timeZoneIdentifier: String? = nil
    ) -> String {
        let timeZone = timeZoneIdentifier.flatMap(TimeZone.init(identifier:))
            ?? .current
        return value.formatted(
            Date.FormatStyle(
                date: .long,
                time: .omitted,
                locale: locale,
                timeZone: timeZone
            )
        )
    }

    static func fieldReason(_ error: DomainError) -> String {
        switch error {
        case .validation(_, let reason), .conflict(let reason):
            reason
        case .notFound:
            String(localized: "participant.error.not_found")
        case .offline:
            String(localized: "participant.error.offline")
        default:
            String(localized: "participant.error.generic")
        }
    }
}
