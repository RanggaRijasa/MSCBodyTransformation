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

nonisolated struct ParticipantProgramDayUIState: Equatable, Sendable {
    let showsActivities: Bool
    let allowsStepNavigation: Bool
    let allowsCompletion: Bool
    let showsUnavailableMessage: Bool

    init(access: ProgramDayAccess) {
        switch access {
        case .available:
            showsActivities = true
            allowsStepNavigation = true
            allowsCompletion = true
            showsUnavailableMessage = false
        case .readOnly:
            showsActivities = true
            allowsStepNavigation = true
            allowsCompletion = false
            showsUnavailableMessage = false
        case .locked, .hidden:
            showsActivities = false
            allowsStepNavigation = false
            allowsCompletion = false
            showsUnavailableMessage = true
        }
    }
}

nonisolated struct ParticipantEntryStagePresentation: Equatable, Sendable {
    let currentStep: Int
    let totalSteps: Int
    let titleKey: String

    init(stage: ParticipantEntryStage) {
        totalSteps = 4
        switch stage {
        case .login:
            currentStep = 1
            titleKey = "participant.entry.stage.login"
        case .profile:
            currentStep = 2
            titleKey = "participant.entry.stage.profile"
        case .disclaimer:
            currentStep = 3
            titleKey = "participant.entry.stage.disclaimer"
        case .initialWeighIn:
            currentStep = 4
            titleKey = "participant.entry.stage.initial_weigh_in"
        case .complete:
            currentStep = 4
            titleKey = "participant.entry.stage.complete"
        }
    }
}

nonisolated struct ParticipantLeaderboardStatusPresentation:
    Equatable,
    Sendable
{
    let isFinal: Bool
    let badgeTitleKey: String
    let statusTitleKey: String
    let statusMessageKey: String

    init(
        program: Program,
        showsFinalLeaderboard: Bool,
        hasLockedWinners: Bool
    ) {
        isFinal = showsFinalLeaderboard
            || program.isLeaderboardArchive
            || hasLockedWinners
        badgeTitleKey = isFinal
            ? "participant.leaderboard.status.completed"
            : "participant.leaderboard.status.in_progress"
        statusTitleKey = isFinal
            ? "participant.leaderboard.status.final.title"
            : "participant.leaderboard.status.provisional.title"
        statusMessageKey = isFinal
            ? "participant.leaderboard.status.final.message"
            : "participant.leaderboard.status.provisional.message"
    }
}

nonisolated extension Program {
    var isLeaderboardArchive: Bool {
        status == .completed || status == .archived
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

    static func currency(_ value: Decimal) -> String {
        value.formatted(
            .currency(code: "IDR")
                .locale(locale)
                .precision(.fractionLength(0))
        )
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
