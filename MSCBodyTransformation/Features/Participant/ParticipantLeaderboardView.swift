import SwiftUI

@MainActor
struct ParticipantLeaderboardView: View {
    let store: ParticipantJourneyStore

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion
    @State private var presentedSheet: PresentedSheet?

    var body: some View {
        Group {
            if availablePrograms.isEmpty {
                emptyState
            } else {
                leaderboardContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .task {
            await store.prepareLeaderboardSelection()
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .activePrograms:
                ParticipantLeaderboardProgramPickerView(store: store)
            case .archive:
                ParticipantLeaderboardArchiveView(store: store)
            }
        }
    }

    private var availablePrograms: [Program] {
        store.activeLeaderboardPrograms + store.archivedLeaderboardPrograms
    }

    private var selectedProgram: Program? {
        store.selectedLeaderboardProgram
            ?? store.activeLeaderboardPrograms.first
            ?? store.archivedLeaderboardPrograms.first
    }

    private var leaderboardContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                programSelection

                switch store.leaderboardState {
                case .idle, .loading:
                    LoadingStateView()
                        .frame(maxWidth: .infinity, minHeight: 280)
                case .failed(let error):
                    ErrorStateView(error: error) {
                        Task {
                            await store.retryLeaderboardSelection()
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                case .loaded(let snapshot):
                    ranking(snapshot)
                }
            }
            .frame(maxWidth: 720)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .frame(maxWidth: .infinity)
        }
        .animation(
            accessibilityReduceMotion ? nil : .easeInOut(duration: 0.25),
            value: store.leaderboardState
        )
        .accessibilityIdentifier("participant.leaderboard")
    }

    private var programSelection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            programSelector

            HStack(spacing: AppSpacing.small) {
                if let presentation = selectedProgramStatusPresentation {
                    StatusBadge(
                        title: LocalizedStringKey(
                            presentation.badgeTitleKey
                        ),
                        kind: presentation.isFinal
                            ? .success
                            : .information
                    )
                }

                Spacer()

                if !store.archivedLeaderboardPrograms.isEmpty {
                    Button {
                        presentedSheet = .archive
                    } label: {
                        Label("Riwayat", systemImage: "clock.arrow.circlepath")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(
                        "participant.leaderboard.archive"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var programSelector: some View {
        if canChooseActiveProgram {
            Button {
                presentedSheet = .activePrograms
            } label: {
                ParticipantLeaderboardProgramSelector(
                    program: selectedProgram,
                    showsSelectionControl: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint(
                Text("Pilih program aktif yang ingin dilihat.")
            )
            .accessibilityIdentifier(
                "participant.leaderboard.program-selector"
            )
        } else {
            ParticipantLeaderboardProgramSelector(
                program: selectedProgram,
                showsSelectionControl: false
            )
            .accessibilityIdentifier(
                "participant.leaderboard.program-selector"
            )
        }
    }

    private var canChooseActiveProgram: Bool {
        guard !store.activeLeaderboardPrograms.isEmpty else {
            return false
        }
        return store.activeLeaderboardPrograms.count > 1
            || selectedProgram?.isLeaderboardArchive == true
    }

    @ViewBuilder
    private func ranking(
        _ snapshot: ParticipantLeaderboardProgramSnapshot
    ) -> some View {
        let statusPresentation = ParticipantLeaderboardStatusPresentation(
            program: snapshot.program,
            showsFinalLeaderboard: store.showsFinalLeaderboard,
            hasLockedWinners: !snapshot.winners.isEmpty
        )
        let isFinal = statusPresentation.isFinal
        let entries = displayEntries(
            snapshot: snapshot,
            isFinal: isFinal
        )

        if entries.isEmpty {
            ContentUnavailableView(
                "Peringkat belum tersedia",
                systemImage: "trophy",
                description: Text(
                    isFinal
                        ? "Hasil akhir belum dikunci untuk program ini."
                        : "Peringkat akan muncul setelah poin peserta tersedia."
                )
            )
            .frame(maxWidth: .infinity, minHeight: 320)
        } else {
            rankingStatus(statusPresentation)

            ParticipantLeaderboardPodium(
                entries: Array(entries.prefix(3))
            )

            if let currentUser = entries.first(where: \.isCurrentUser),
               currentUser.rank > 3 {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Peringkatmu")
                        .font(AppTypography.sectionTitle)
                    ParticipantLeaderboardCurrentRankCard(
                        entry: currentUser
                    )
                }
            }

            let remainingEntries = entries.filter {
                $0.rank > 3 && !$0.isCurrentUser
            }
            if !remainingEntries.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Peringkat lainnya")
                        .font(AppTypography.sectionTitle)

                    LazyVStack(spacing: AppSpacing.small) {
                        ForEach(remainingEntries) { entry in
                            ParticipantLeaderboardRankRow(entry: entry)
                        }
                    }
                }
            }

            privacyNotice(isFinal: isFinal)
        }
    }

    private func rankingStatus(
        _ presentation: ParticipantLeaderboardStatusPresentation
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(LocalizedStringKey(presentation.statusTitleKey))
                .font(AppTypography.cardTitle)
            Text(LocalizedStringKey(presentation.statusMessageKey))
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectedProgramStatusPresentation:
        ParticipantLeaderboardStatusPresentation?
    {
        guard let selectedProgram else {
            return nil
        }
        let hasLockedWinners: Bool
        if case .loaded(let snapshot) = store.leaderboardState,
           snapshot.program.id == selectedProgram.id {
            hasLockedWinners = !snapshot.winners.isEmpty
        } else {
            hasLockedWinners = false
        }
        return ParticipantLeaderboardStatusPresentation(
            program: selectedProgram,
            showsFinalLeaderboard: store.showsFinalLeaderboard,
            hasLockedWinners: hasLockedWinners
        )
    }

    private func privacyNotice(isFinal: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Label(
                "Nama yang tampil adalah nama publik. "
                    + "Nilai berat badan tidak ditampilkan.",
                systemImage: "hand.raised.fill"
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
        snapshot: ParticipantLeaderboardProgramSnapshot,
        isFinal: Bool
    ) -> [ParticipantLeaderboardDisplayEntry] {
        if isFinal, !snapshot.winners.isEmpty {
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
                        isCurrentUser:
                            winner.participantID == store.snapshot?.profile.id,
                        hasTie: pointCounts[winner.totalPoints, default: 0] > 1
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
                    isCurrentUser: store.isGuest ? false : entry.isCurrentUser,
                    hasTie:
                        pointCounts[entry.score.totalPoints, default: 0] > 1
                )
            }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                "Belum ada peringkat",
                systemImage: "trophy"
            )
        } description: {
            Text(
                "Peringkat tersedia untuk program aktif atau program "
                    + "selesai yang pernah kamu ikuti."
            )
        }
        .accessibilityIdentifier("participant.leaderboard.empty")
    }
}

@MainActor
private struct ParticipantLeaderboardProgramPickerView: View {
    let store: ParticipantJourneyStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(store.activeLeaderboardPrograms) { program in
                Button {
                    Task {
                        await store.selectLeaderboardProgram(program.id)
                        dismiss()
                    }
                } label: {
                    ParticipantLeaderboardProgramPickerRow(
                        program: program,
                        isSelected:
                            program.id == store.selectedLeaderboardProgramID
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(
                    "participant.leaderboard.program.\(program.id)"
                )
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Pilih program")
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

struct ParticipantLeaderboardProgramPickerRow: View {
    let program: Program
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: "trophy.fill")
                .font(.headline)
                .foregroundStyle(Color.brandAccent)
                .frame(width: 40, height: 40)
                .background(
                    Color.brandAccent.opacity(0.14),
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.medium,
                        style: .continuous
                    )
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(program.title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(ParticipantLeaderboardFormatting.range(program))
                    .font(AppTypography.label.monospacedDigit())
                    .foregroundStyle(Color.appSecondaryText)
            }

            Spacer(minLength: AppSpacing.small)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityLabel(Text("Dipilih"))
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

@MainActor
private struct ParticipantLeaderboardArchiveView: View {
    let store: ParticipantJourneyStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.archivedLeaderboardPrograms.isEmpty {
                    ContentUnavailableView(
                        "Belum ada riwayat",
                        systemImage: "clock.arrow.circlepath",
                        description: Text(
                            "Program yang selesai akan tersimpan di sini."
                        )
                    )
                } else {
                    List(store.archivedLeaderboardPrograms) { program in
                        Button {
                            Task {
                                await store.selectLeaderboardProgram(program.id)
                                dismiss()
                            }
                        } label: {
                            ParticipantLeaderboardArchiveRow(
                                program: program,
                                isSelected:
                                    program.id
                                    == store.selectedLeaderboardProgramID
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(
                            "participant.leaderboard.archive.\(program.id)"
                        )
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Riwayat peringkat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private enum PresentedSheet: String, Identifiable {
    case activePrograms
    case archive

    var id: String { rawValue }
}

#Preview("Papan peringkat — program aktif") {
    ParticipantLeaderboardPreview(mode: .active)
}

#Preview("Papan peringkat — hasil selesai") {
    ParticipantLeaderboardPreview(mode: .archive)
}

#Preview("Papan peringkat — Dynamic Type besar") {
    ParticipantLeaderboardPreview(mode: .active)
        .environment(
            \.dynamicTypeSize,
            DynamicTypeSize.accessibility3
        )
}

@MainActor
private struct ParticipantLeaderboardPreview: View {
    enum Mode {
        case active
        case archive
    }

    let mode: Mode
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )

    var body: some View {
        NavigationStack {
            ParticipantLeaderboardView(store: store)
                .navigationTitle("Peringkat")
                .task {
                    await store.load()
                    if mode == .archive,
                       let program = store.archivedLeaderboardPrograms.first {
                        await store.selectLeaderboardProgram(program.id)
                    }
                }
        }
        .environment(\.locale, Locale(identifier: "id-ID"))
    }
}
