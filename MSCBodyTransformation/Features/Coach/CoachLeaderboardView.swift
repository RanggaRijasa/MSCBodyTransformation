import SwiftUI

@MainActor
struct CoachLeaderboardView: View {
    let state: CoachLeaderboardState

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion
    @State private var presentedSheet: CoachLeaderboardPresentedSheet?

    var body: some View {
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
                leaderboard(snapshot)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .task {
            if state.state == .idle {
                await state.load()
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .activePrograms(let programs, let selectedProgramID):
                CoachLeaderboardProgramPickerView(
                    title: "Pilih program",
                    programs: programs,
                    selectedProgramID: selectedProgramID,
                    state: state
                )
            case .archive(let programs, let selectedProgramID):
                CoachLeaderboardProgramPickerView(
                    title: "Riwayat peringkat",
                    programs: programs,
                    selectedProgramID: selectedProgramID,
                    state: state
                )
            case .scoreDetail(let detail):
                CoachLeaderboardScoreDetailSheet(detail: detail)
            }
        }
        .accessibilityIdentifier("coach.leaderboard")
    }

    private func leaderboard(
        _ snapshot: CoachLeaderboardSnapshot
    ) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                programSelection(snapshot)
                ranking(snapshot)
            }
            .frame(maxWidth: 720)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            await state.load()
        }
        .animation(
            accessibilityReduceMotion ? nil : .easeInOut(duration: 0.25),
            value: state.state
        )
    }

    private func programSelection(
        _ snapshot: CoachLeaderboardSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if canChooseActiveProgram(in: snapshot) {
                Button {
                    presentedSheet = .activePrograms(
                        programs: activePrograms(in: snapshot),
                        selectedProgramID: state.selectedProgramID
                    )
                } label: {
                    ParticipantLeaderboardProgramSelector(
                        program: snapshot.selectedProgram,
                        showsSelectionControl: true
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint(
                    Text("Pilih program aktif yang ingin dilihat.")
                )
                .accessibilityIdentifier(
                    "coach.leaderboard.program-selector"
                )
            } else {
                ParticipantLeaderboardProgramSelector(
                    program: snapshot.selectedProgram,
                    showsSelectionControl: false
                )
                .accessibilityIdentifier(
                    "coach.leaderboard.program-selector"
                )
            }

            HStack(spacing: AppSpacing.small) {
                StatusBadge(
                    title: snapshot.isFinal
                        ? "participant.leaderboard.status.completed"
                        : "participant.leaderboard.status.in_progress",
                    kind: snapshot.isFinal ? .success : .information
                )

                Spacer()

                if !archivedPrograms(in: snapshot).isEmpty {
                    Button {
                        presentedSheet = .archive(
                            programs: archivedPrograms(in: snapshot),
                            selectedProgramID: state.selectedProgramID
                        )
                    } label: {
                        Label(
                            "Riwayat",
                            systemImage: "clock.arrow.circlepath"
                        )
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(
                        "coach.leaderboard.archive"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func ranking(
        _ snapshot: CoachLeaderboardSnapshot
    ) -> some View {
        let entries = displayEntries(snapshot)

        if entries.isEmpty {
            ContentUnavailableView(
                "coach.leaderboard.empty.title",
                systemImage: "trophy",
                description: Text("coach.leaderboard.empty.message")
            )
            .frame(maxWidth: .infinity, minHeight: 320)
        } else {
            rankingStatus(isFinal: snapshot.isFinal)

            ParticipantLeaderboardPodium(
                entries: Array(entries.prefix(3)),
                interactionAccessibilityPrefix: "coach.leaderboard"
            ) { entry in
                presentScoreDetail(for: entry, in: snapshot)
            }

            let remainingEntries = entries.filter { $0.rank > 3 }
            if !remainingEntries.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Peringkat lainnya")
                        .font(AppTypography.sectionTitle)

                    LazyVStack(spacing: AppSpacing.small) {
                        ForEach(remainingEntries) { entry in
                            rankingEntry(entry, in: snapshot)
                        }
                    }
                }
            }

            privacyNotice(isFinal: snapshot.isFinal)
        }
    }

    private func rankingStatus(isFinal: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(
                LocalizedStringKey(
                    isFinal
                    ? "participant.leaderboard.status.final.title"
                    : "participant.leaderboard.status.provisional.title"
                )
            )
            .font(AppTypography.cardTitle)

            Text(
                LocalizedStringKey(
                    isFinal
                    ? "participant.leaderboard.status.final.message"
                    : "participant.leaderboard.status.provisional.message"
                )
            )
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func rankingEntry(
        _ entry: ParticipantLeaderboardDisplayEntry,
        in snapshot: CoachLeaderboardSnapshot
    ) -> some View {
        if entry.isAssignedToCoach {
            Button {
                presentScoreDetail(for: entry, in: snapshot)
            } label: {
                ParticipantLeaderboardRankRow(entry: entry)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .accessibilityHint(
                Text("coach.leaderboard.score_detail.hint")
            )
            .accessibilityIdentifier(
                "coach.leaderboard.rank.\(entry.participantID.uuidString)"
            )
        } else {
            ParticipantLeaderboardRankRow(entry: entry)
        }
    }

    private func presentScoreDetail(
        for displayEntry: ParticipantLeaderboardDisplayEntry,
        in snapshot: CoachLeaderboardSnapshot
    ) {
        guard displayEntry.isAssignedToCoach else {
            return
        }

        let leaderboardEntry = snapshot.entries.first {
            $0.participantID == displayEntry.participantID
        }
        presentedSheet = .scoreDetail(
            CoachLeaderboardScoreDetail(
                participantID: displayEntry.participantID,
                displayName: displayEntry.displayName,
                rank: displayEntry.rank,
                totalPoints: displayEntry.totalPoints,
                progressPercentage:
                    leaderboardEntry?.progressPercentage
                    ?? displayEntry.progressPercentage,
                score: leaderboardEntry?.score
            )
        )
    }

    private func privacyNotice(isFinal: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Label(
                "coach.leaderboard.privacy_notice",
                systemImage: "hand.raised.fill"
            )
            Label(
                "coach.leaderboard.assigned_notice",
                systemImage: "person.crop.circle.badge.checkmark"
            )
            if !isFinal {
                Label(
                    "Poin pada demo ini dihitung secara lokal.",
                    systemImage: "iphone"
                )
            }
        }
        .font(AppTypography.label)
        .foregroundStyle(Color.appSecondaryText)
        .padding(.bottom, AppSpacing.large)
    }

    private func displayEntries(
        _ snapshot: CoachLeaderboardSnapshot
    ) -> [ParticipantLeaderboardDisplayEntry] {
        if snapshot.isFinal {
            let pointCounts = Dictionary(
                grouping: snapshot.winners,
                by: \.totalPoints
            )
            .mapValues(\.count)

            return snapshot.winners
                .sorted {
                    if $0.rank == $1.rank {
                        return $0.participantDisplayName
                            .localizedStandardCompare(
                                $1.participantDisplayName
                            ) == .orderedAscending
                    }
                    return $0.rank < $1.rank
                }
                .map { winner in
                    ParticipantLeaderboardDisplayEntry(
                        id: winner.id,
                        participantID: winner.participantID,
                        displayName: winner.participantDisplayName,
                        rank: winner.rank,
                        totalPoints: winner.totalPoints,
                        progressPercentage: nil,
                        isCurrentUser: false,
                        isAssignedToCoach: snapshot.assignedParticipantIDs
                            .contains(winner.participantID),
                        hasTie:
                            pointCounts[winner.totalPoints, default: 0] > 1
                    )
                }
        }

        let pointCounts = Dictionary(
            grouping: snapshot.entries,
            by: { $0.score.totalPoints }
        )
        .mapValues(\.count)

        return snapshot.entries
            .sorted {
                if $0.rank == $1.rank {
                    return $0.participantDisplayName
                        .localizedStandardCompare(
                            $1.participantDisplayName
                        ) == .orderedAscending
                }
                return $0.rank < $1.rank
            }
            .map { entry in
                ParticipantLeaderboardDisplayEntry(
                    id: entry.id,
                    participantID: entry.participantID,
                    displayName: entry.participantDisplayName,
                    rank: entry.rank,
                    totalPoints: entry.score.totalPoints,
                    progressPercentage: entry.progressPercentage,
                    isCurrentUser: false,
                    isAssignedToCoach: snapshot.assignedParticipantIDs
                        .contains(entry.participantID),
                    hasTie:
                        pointCounts[entry.score.totalPoints, default: 0] > 1
                )
            }
    }

    private func activePrograms(
        in snapshot: CoachLeaderboardSnapshot
    ) -> [Program] {
        snapshot.programs
            .filter { $0.status == .active }
            .sorted { $0.startDate > $1.startDate }
    }

    private func archivedPrograms(
        in snapshot: CoachLeaderboardSnapshot
    ) -> [Program] {
        snapshot.programs
            .filter(\.isLeaderboardArchive)
            .sorted { $0.endDate > $1.endDate }
    }

    private func canChooseActiveProgram(
        in snapshot: CoachLeaderboardSnapshot
    ) -> Bool {
        let activePrograms = activePrograms(in: snapshot)
        return activePrograms.count > 1
            || snapshot.selectedProgram.isLeaderboardArchive
    }
}

private struct CoachLeaderboardScoreDetail: Identifiable {
    let participantID: UUID
    let displayName: String
    let rank: Int
    let totalPoints: Int
    let progressPercentage: Int?
    let score: ScoreBreakdown?

    var id: UUID { participantID }
}

@MainActor
private struct CoachLeaderboardScoreDetailSheet: View {
    let detail: CoachLeaderboardScoreDetail

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                participantSummary
                if let score = detail.score {
                    pointBreakdown(score)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("coach.leaderboard.score_detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") {
                        dismiss()
                    }
                }
            }
            .accessibilityIdentifier(
                "coach.leaderboard.score-detail-modal"
            )
        }
        .background(Color.appBackground)
        .presentationBackground(Color.appBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var participantSummary: some View {
        Section {
            VStack(spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: detail.displayName,
                    size: 72
                )

                Text(detail.displayName)
                    .font(AppTypography.sectionTitle)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xSmall)

            scoreRow(
                "Peringkat",
                CoachFormatting.number(detail.rank)
            )
            scoreRow(
                "participant.leaderboard.total_points",
                CoachFormatting.number(detail.totalPoints)
            )
        }
    }

    private func pointBreakdown(
        _ score: ScoreBreakdown
    ) -> some View {
        Section {
            scoreRow(
                "coach.score.step",
                CoachFormatting.number(
                    score.approvedStepPoints
                )
            )
            scoreRow(
                "coach.score.weight",
                CoachFormatting.number(score.weightPoints)
            )
            scoreRow(
                "coach.score.adjustment",
                CoachFormatting.number(
                    score.adjustmentPoints
                )
            )
            if let progressPercentage = detail.progressPercentage {
                scoreRow(
                    "metric.progress",
                    CoachFormatting.percentage(
                        progressPercentage
                    )
                )
            }
        } header: {
            Text("coach.leaderboard.score_detail")
        } footer: {
            Text("coach.leaderboard.score_detail.privacy")
        }
    }

    private func scoreRow(
        _ title: LocalizedStringKey,
        _ value: String
    ) -> some View {
        LabeledContent(title) {
            Text(value)
                .font(AppTypography.cardTitle.monospacedDigit())
                .foregroundStyle(Color.appPrimaryText)
        }
    }
}

@MainActor
private struct CoachLeaderboardProgramPickerView: View {
    let title: LocalizedStringKey
    let programs: [Program]
    let selectedProgramID: UUID?
    let state: CoachLeaderboardState

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if programs.isEmpty {
                    ContentUnavailableView(
                        "coach.program.none",
                        systemImage: "trophy",
                        description: Text(
                            "coach.leaderboard.program.empty.message"
                        )
                    )
                } else {
                    List(programs) { program in
                        Button {
                            Task {
                                await state.selectProgram(program.id)
                                dismiss()
                            }
                        } label: {
                            ParticipantLeaderboardProgramPickerRow(
                                program: program,
                                isSelected: program.id == selectedProgramID
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(
                            "coach.leaderboard.program.\(program.id)"
                        )
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.appBackground)
                }
            }
            .navigationTitle(Text(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") {
                        dismiss()
                    }
                }
            }
        }
        .background(Color.appBackground)
        .presentationBackground(Color.appBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private enum CoachLeaderboardPresentedSheet: Identifiable {
    case activePrograms(programs: [Program], selectedProgramID: UUID?)
    case archive(programs: [Program], selectedProgramID: UUID?)
    case scoreDetail(CoachLeaderboardScoreDetail)

    var id: String {
        switch self {
        case .activePrograms:
            "active-programs"
        case .archive:
            "archive"
        case .scoreDetail(let detail):
            "score-detail-\(detail.id)"
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
