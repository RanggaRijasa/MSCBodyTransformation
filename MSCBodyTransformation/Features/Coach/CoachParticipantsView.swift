import SwiftUI

@MainActor
struct CoachParticipantsView: View {
    let state: CoachParticipantsState
    let router: ShellTabRouter

    var body: some View {
        @Bindable var state = state

        List {
            filterSection(state: $state)
            participantContent
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .searchable(
            text: $state.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("coach.participants.search")
        )
        .refreshable {
            await state.load()
        }
        .task {
            if state.state == .idle {
                await state.load()
            }
        }
        .accessibilityIdentifier("coach.participants")
    }

    private func filterSection(
        state: Bindable<CoachParticipantsState>
    ) -> some View {
        Section {
            Picker(
                "coach.filter.program",
                selection: state.selectedProgramID
            ) {
                Text("coach.filter.all_programs")
                    .tag(UUID?.none)
                ForEach(state.wrappedValue.availablePrograms) { program in
                    Text(program.title)
                        .tag(Optional(program.id))
                }
            }
            Picker(
                "coach.filter.completion",
                selection: state.completionFilter
            ) {
                ForEach(CoachCompletionFilter.allCases) { filter in
                    Text(LocalizedStringKey(filter.titleKey))
                        .tag(filter)
                }
            }
            Picker(
                "coach.filter.review",
                selection: state.reviewFilter
            ) {
                ForEach(CoachReviewFilter.allCases) { filter in
                    Text(LocalizedStringKey(filter.titleKey))
                        .tag(filter)
                }
            }
            Picker("coach.sort.label", selection: state.sort) {
                ForEach(CoachParticipantSort.allCases) { sort in
                    Text(LocalizedStringKey(sort.titleKey))
                        .tag(sort)
                }
            }
        } header: {
            Text("coach.filter.title")
        }
    }

    @ViewBuilder
    private var participantContent: some View {
        switch state.state {
        case .idle, .loading:
            Section {
                ForEach(0..<3, id: \.self) { _ in
                    CoachParticipantPlaceholderRow()
                }
                .redacted(reason: .placeholder)
            }
        case .failed(let error):
            Section {
                ErrorStateView(error: error) {
                    Task {
                        await state.load()
                    }
                }
            }
        case .loaded:
            if state.filteredParticipants.isEmpty {
                Section {
                    ContentUnavailableView(
                        "coach.participants.filtered_empty.title",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text(
                            "coach.participants.filtered_empty.message"
                        )
                    )
                }
            } else {
                Section("coach.participants.list.title") {
                    ForEach(state.filteredParticipants) { participant in
                        Button {
                            router.navigate(
                                to: .coach(
                                    .participantDetail(participant.id)
                                ),
                                in: .coach(.participants)
                            )
                        } label: {
                            CoachParticipantRow(summary: participant)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(
                            "coach.participant.open.\(participant.id)"
                        )
                    }
                }
            }
        }
    }
}

private struct CoachParticipantRow: View {
    let summary: CoachParticipantSummary

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            UserAvatar(displayName: summary.profile.displayName)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(summary.profile.displayName)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                Text(summary.program?.title ?? String(localized: "coach.program.none"))
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                HStack(spacing: AppSpacing.xSmall) {
                    if summary.pendingReviewCount > 0 {
                        StatusBadge(
                            title: "status.pending",
                            kind: .pending
                        )
                    } else if summary.rejectedCount > 0 {
                        StatusBadge(
                            title: "status.rejected",
                            kind: .error
                        )
                    } else if summary.isComplete {
                        StatusBadge(
                            title: "status.completed",
                            kind: .success
                        )
                    } else if summary.isFallingBehind {
                        StatusBadge(
                            title: "coach.status.falling_behind",
                            kind: .warning
                        )
                    }
                }
                Text(
                    String(
                        format: String(
                            localized: "coach.participant.points_format"
                        ),
                        CoachFormatting.number(summary.points)
                    )
                )
                .font(AppTypography.label.monospacedDigit())
                .foregroundStyle(Color.appSecondaryText)
            }
            Spacer(minLength: AppSpacing.small)
            ProgressRing(
                progress: Double(summary.progressPercentage) / 100,
                label: "metric.progress"
            )
            .scaleEffect(0.74)
            .frame(width: 58, height: 58)
        }
        .padding(.vertical, AppSpacing.xSmall)
        .accessibilityElement(children: .combine)
    }
}

private struct CoachParticipantPlaceholderRow: View {
    var body: some View {
        HStack {
            UserAvatar(displayName: "Peserta")
            VStack(alignment: .leading) {
                Text("Nama peserta")
                Text("Program aktif")
            }
            Spacer()
            ProgressView()
        }
    }
}

#Preview("Peserta Coach — normal") {
    NavigationStack {
        CoachParticipantsPreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Peserta Coach — gelap") {
    NavigationStack {
        CoachParticipantsPreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
    .preferredColorScheme(.dark)
}

@MainActor
private struct CoachParticipantsPreview: View {
    @State private var state = CoachParticipantsState(environment: .preview)
    @State private var router = ShellTabRouter()

    var body: some View {
        CoachParticipantsView(state: state, router: router)
            .navigationTitle(Text("tab.coach.participants"))
    }
}
