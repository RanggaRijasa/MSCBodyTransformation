import SwiftUI

@MainActor
struct ParticipantLeaderboardView: View {
    let store: ParticipantJourneyStore

    var body: some View {
        if store.currentEnrollment != nil,
           let snapshot = store.snapshot,
           !snapshot.leaderboard.isEmpty {
            List {
                statusSection
                currentUserSection
                topFiveSection(snapshot.leaderboard)
                fullRankingSection(snapshot.leaderboard)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .accessibilityIdentifier("participant.leaderboard")
        } else {
            EmptyStateView(
                title: "participant.leaderboard.empty.title",
                message: "participant.leaderboard.empty.message",
                systemImage: "trophy"
            )
        }
    }

    private var statusSection: some View {
        Section {
            if store.showsFinalLeaderboard || !store.snapshotWinners.isEmpty {
                StatusBadge(
                    title: "participant.leaderboard.final",
                    kind: .success
                )
                if let banner = store.winnerBanner {
                    Label {
                        VStack(alignment: .leading) {
                            Text(banner.title)
                                .font(AppTypography.cardTitle)
                            Text(banner.body)
                                .font(AppTypography.secondary)
                        }
                    } icon: {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color.brandAccent)
                    }
                }
            } else {
                StatusBadge(
                    title: "participant.leaderboard.provisional",
                    kind: .information
                )
                Text("participant.local_score_notice")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }
        }
    }

    @ViewBuilder
    private var currentUserSection: some View {
        if let entry = store.currentLeaderboardEntry {
            Section {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    HStack(spacing: AppSpacing.medium) {
                        RankBadge(rank: entry.rank)
                        VStack(alignment: .leading) {
                            Text(entry.participantDisplayName)
                                .font(AppTypography.cardTitle)
                            Text("participant.leaderboard.current_user")
                                .font(AppTypography.label)
                                .foregroundStyle(Color.appSecondaryText)
                        }
                    }

                    scoreBreakdown(entry.score)
                }
                .padding(AppSpacing.medium)
                .background(
                    Color.brandPrimary.opacity(0.08),
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                    .stroke(Color.brandPrimary, lineWidth: 2)
                }
            } header: {
                Text("participant.leaderboard.your_rank")
            }
        }
    }

    private func topFiveSection(
        _ entries: [LeaderboardEntry]
    ) -> some View {
        Section {
            ForEach(Array(entries.prefix(5))) { entry in
                leaderboardRow(entry, isEmphasized: true)
            }
        } header: {
            Text("participant.leaderboard.top_five")
        }
    }

    private func fullRankingSection(
        _ entries: [LeaderboardEntry]
    ) -> some View {
        Section {
            ForEach(entries) { entry in
                leaderboardRow(entry, isEmphasized: false)
            }
        } header: {
            Text("participant.leaderboard.full_ranking")
        }
    }

    private func leaderboardRow(
        _ entry: LeaderboardEntry,
        isEmphasized: Bool
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            RankBadge(rank: entry.rank)
            UserAvatar(displayName: entry.participantDisplayName)
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(entry.participantDisplayName)
                    .font(AppTypography.cardTitle)
                Text(
                    ParticipantFormatting.percentage(
                        entry.progressPercentage
                    )
                )
                .font(AppTypography.secondary.monospacedDigit())
                .foregroundStyle(Color.appSecondaryText)
                if hasTie(entry) {
                    Label(
                        "participant.leaderboard.tie",
                        systemImage: "equal.circle"
                    )
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appInfo)
                }
            }
            Spacer()
            Text(
                entry.score.totalPoints,
                format: .number.locale(ParticipantFormatting.locale)
            )
            .font(AppTypography.metric.monospacedDigit())
            .foregroundStyle(
                isEmphasized && entry.rank == 1
                    ? Color.appWarning
                    : Color.appPrimaryText
            )
            .accessibilityLabel(Text("metric.points"))
        }
        .padding(.vertical, AppSpacing.xSmall)
        .accessibilityElement(children: .combine)
    }

    private func scoreBreakdown(_ score: ScoreBreakdown) -> some View {
        Grid(alignment: .leading, horizontalSpacing: AppSpacing.medium) {
            scoreRow(
                title: "participant.leaderboard.step_points",
                value: score.approvedStepPoints
            )
            scoreRow(
                title: "participant.leaderboard.weight_points",
                value: score.weightPoints
            )
            scoreRow(
                title: "participant.leaderboard.total_points",
                value: score.totalPoints
            )
        }
    }

    private func scoreRow(
        title: LocalizedStringKey,
        value: Int
    ) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(Color.appSecondaryText)
            Text(
                value,
                format: .number.locale(ParticipantFormatting.locale)
            )
            .font(.body.monospacedDigit())
        }
    }

    private func hasTie(_ entry: LeaderboardEntry) -> Bool {
        (store.snapshot?.leaderboard.filter {
            $0.rank == entry.rank
        }.count ?? 0) > 1
    }
}

private extension ParticipantJourneyStore {
    var snapshotWinners: [ProgramWinner] {
        snapshot?.winners ?? []
    }
}

#Preview("Papan peringkat — peserta di luar lima besar") {
    ParticipantLeaderboardPreview(isFinal: false)
}

#Preview("Papan peringkat — pemenang final") {
    ParticipantLeaderboardPreview(isFinal: true)
}

@MainActor
private struct ParticipantLeaderboardPreview: View {
    let isFinal: Bool
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )

    var body: some View {
        NavigationStack {
            ParticipantLeaderboardView(store: store)
                .task {
                    await store.load()
                    store.showsFinalLeaderboard = isFinal
                }
        }
    }
}
