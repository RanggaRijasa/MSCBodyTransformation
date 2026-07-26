import SwiftUI

@MainActor
struct CoachLeaderboardView: View {
    let state: CoachLeaderboardState

    var body: some View {
        @Bindable var state = state

        Group {
            switch state.state {
            case .idle, .loading:
                LoadingStateView()
            case .failed(let error):
                ScrollView {
                    ErrorStateView(error: error) {
                        Task {
                            await state.load()
                        }
                    }
                    .padding(AppSpacing.medium)
                }
            case .loaded(let snapshot):
                leaderboard(snapshot, selectedProgramID: $state.selectedProgramID)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .task {
            if state.state == .idle {
                await state.load()
            }
        }
        .accessibilityIdentifier("coach.leaderboard")
    }

    private func leaderboard(
        _ snapshot: CoachLeaderboardSnapshot,
        selectedProgramID: Binding<UUID?>
    ) -> some View {
        List {
            Section("coach.leaderboard.program.title") {
                Picker(
                    "coach.leaderboard.program.picker",
                    selection: selectedProgramID
                ) {
                    ForEach(snapshot.programs) { program in
                        Text(program.title)
                            .tag(Optional(program.id))
                    }
                }
                .onChange(of: state.selectedProgramID) { _, newValue in
                    guard let newValue else {
                        return
                    }
                    Task {
                        await state.selectProgram(newValue)
                    }
                }
                HStack {
                    Text("coach.leaderboard.status")
                    Spacer()
                    StatusBadge(
                        title: snapshot.isFinal
                            ? "coach.leaderboard.final"
                            : "coach.leaderboard.provisional",
                        kind: snapshot.isFinal ? .success : .pending
                    )
                }
            }

            Section("coach.leaderboard.top_five") {
                if snapshot.isFinal {
                    ForEach(snapshot.winners.prefix(5)) { winner in
                        finalWinnerRow(
                            winner,
                            isAssigned: snapshot.assignedParticipantIDs
                                .contains(winner.participantID)
                        )
                    }
                } else if snapshot.entries.isEmpty {
                    ContentUnavailableView(
                        "coach.leaderboard.empty.title",
                        systemImage: "trophy",
                        description: Text("coach.leaderboard.empty.message")
                    )
                } else {
                    ForEach(snapshot.entries.prefix(5)) { entry in
                        provisionalRow(
                            entry,
                            isAssigned: snapshot.assignedParticipantIDs
                                .contains(entry.participantID)
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .refreshable {
            await state.load()
        }
    }

    private func provisionalRow(
        _ entry: LeaderboardEntry,
        isAssigned: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.medium) {
                RankBadge(rank: entry.rank)
                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(entry.participantDisplayName)
                        .font(AppTypography.cardTitle)
                    if isAssigned {
                        Label(
                            "coach.leaderboard.assigned_marker",
                            systemImage: "person.crop.circle.badge.checkmark"
                        )
                        .font(AppTypography.label)
                        .foregroundStyle(Color.brandPrimary)
                    }
                }
                Spacer()
                Text(CoachFormatting.number(entry.score.totalPoints))
                    .font(AppTypography.metric.monospacedDigit())
            }
            DisclosureGroup("coach.leaderboard.score_detail") {
                scoreRow("coach.score.step", entry.score.approvedStepPoints)
                scoreRow("coach.score.weight", entry.score.weightPoints)
                scoreRow(
                    "coach.score.adjustment",
                    entry.score.adjustmentPoints
                )
                scoreRow(
                    "metric.progress",
                    entry.progressPercentage,
                    isPercentage: true
                )
            }
            .font(AppTypography.secondary)
        }
        .padding(.vertical, AppSpacing.xSmall)
        .overlay {
            if isAssigned {
                RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
                .stroke(Color.brandPrimary, lineWidth: 2)
                .padding(.horizontal, -AppSpacing.xSmall)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func finalWinnerRow(
        _ winner: ProgramWinner,
        isAssigned: Bool
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            RankBadge(rank: winner.rank)
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(winner.participantDisplayName)
                    .font(AppTypography.cardTitle)
                if isAssigned {
                    Label(
                        "coach.leaderboard.assigned_marker",
                        systemImage: "person.crop.circle.badge.checkmark"
                    )
                    .font(AppTypography.label)
                    .foregroundStyle(Color.brandPrimary)
                }
            }
            Spacer()
            Text(CoachFormatting.number(winner.totalPoints))
                .font(AppTypography.metric.monospacedDigit())
        }
        .padding(.vertical, AppSpacing.xSmall)
        .overlay {
            if isAssigned {
                RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
                .stroke(Color.brandPrimary, lineWidth: 2)
                .padding(.horizontal, -AppSpacing.xSmall)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func scoreRow(
        _ title: LocalizedStringKey,
        _ value: Int,
        isPercentage: Bool = false
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(
                isPercentage
                    ? CoachFormatting.percentage(value)
                    : CoachFormatting.number(value)
            )
            .monospacedDigit()
        }
    }
}

#Preview("Papan peringkat Coach") {
    NavigationStack {
        CoachLeaderboardPreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

@MainActor
private struct CoachLeaderboardPreview: View {
    @State private var state = CoachLeaderboardState(environment: .preview)

    var body: some View {
        CoachLeaderboardView(state: state)
            .navigationTitle(Text("tab.coach.leaderboard"))
    }
}
