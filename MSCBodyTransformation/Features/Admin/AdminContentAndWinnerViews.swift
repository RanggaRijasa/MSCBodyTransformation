import SwiftUI

@MainActor
struct AdminContentView: View {
    let features: AdminFeatureContainer
    let router: ShellTabRouter

    @State private var selectedContent: ManagedContent?
    @State private var error: DomainError?

    var body: some View {
        List {
            if case .loaded(let content) = features.contentState {
                if content.isEmpty {
                    ContentUnavailableView(
                        "Belum ada konten",
                        systemImage: "text.document",
                        description: Text(
                            "Buat banner pemenang untuk memulai."
                        )
                    )
                } else {
                    Section("Konten aplikasi") {
                        ForEach(
                            content.sorted {
                                if $0.sortOrder == $1.sortOrder {
                                    return $0.updatedAt > $1.updatedAt
                                }
                                return $0.sortOrder < $1.sortOrder
                            }
                        ) { item in
                            contentRow(item)
                        }
                    }
                }
            } else {
                AsyncContentView(
                    state: features.contentState,
                    retryAction: { Task { await features.load() } }
                ) { _ in EmptyView() }
            }

            Section("Pemenang") {
                if let program = activeProgram {
                    Button("Kelola pemenang \(program.title)") {
                        router.navigate(
                            to: .admin(.winnerManagement(program.id)),
                            in: .admin(.content)
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedContent = features.makeWinnerBanner(
                        programID: activeProgram?.id
                    )
                } label: {
                    Label("Buat banner", systemImage: "plus")
                }
                .accessibilityIdentifier("admin.content.create-banner")
            }
        }
        .sheet(item: $selectedContent) { content in
            AdminContentEditorSheet(
                initialContent: content,
                programs: programs,
                features: features
            )
        }
        .alert(
            "Konten tidak dapat disimpan",
            isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )
        ) {
            Button("Tutup", role: .cancel) {}
        } message: {
            Text(error?.localizedAdminMessage ?? "")
        }
        .accessibilityIdentifier("admin.content")
    }

    private func contentRow(_ content: ManagedContent) -> some View {
        Button {
            selectedContent = content
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.small) {
                Image(systemName: content.kind == .winnerBanner
                    ? "trophy.fill"
                    : "text.document")
                    .foregroundStyle(
                        content.kind == .winnerBanner
                            ? Color.brandAccent
                            : Color.brandPrimary
                    )
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(content.title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)
                    Text(content.body)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                        .lineLimit(3)
                    Text(content.isArchived
                        ? "Diarsipkan"
                        : content.isPublished ? "Aktif" : "Nonaktif")
                        .font(AppTypography.label)
                        .foregroundStyle(Color.appSecondaryText)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions {
            if !content.isArchived {
                Button("Arsipkan", role: .destructive) {
                    var archived = content
                    archived.isArchived = true
                    archived.isPublished = false
                    archived.updatedAt = features.environment.clock.now()
                    Task {
                        do {
                            try await features.saveContent(archived)
                        } catch let domainError as DomainError {
                            error = domainError
                        } catch {
                            self.error = .unknown
                        }
                    }
                }
            }
        }
    }

    private var programs: [AdminProgramDraft] {
        guard case .loaded(let programs) = features.programsState else {
            return []
        }
        return programs.filter { $0.status != .archived }
    }

    private var activeProgram: AdminProgramDraft? {
        programs.first { $0.status == .active }
    }
}

private struct AdminContentEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let programs: [AdminProgramDraft]
    let features: AdminFeatureContainer

    @State private var content: ManagedContent
    @State private var error: DomainError?
    @State private var isSaving = false

    init(
        initialContent: ManagedContent,
        programs: [AdminProgramDraft],
        features: AdminFeatureContainer
    ) {
        _content = State(initialValue: initialContent)
        self.programs = programs
        self.features = features
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Isi banner") {
                    TextField("Judul", text: $content.title)
                    TextField(
                        "Isi",
                        text: $content.body,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    TextField(
                        "Referensi media lokal",
                        text: optionalStringBinding(
                            for: \.localMediaReference
                        )
                    )
                }
                Section("Penayangan") {
                    Picker(
                        "Program",
                        selection: $content.programID
                    ) {
                        Text("Semua program").tag(Optional<UUID>.none)
                        ForEach(programs) { program in
                            Text(program.title)
                                .tag(Optional(program.id))
                        }
                    }
                    DatePicker(
                        "Mulai tampil",
                        selection: optionalDateBinding(
                            for: \.visibleFrom,
                            fallback: features.environment.clock.now()
                        )
                    )
                    DatePicker(
                        "Selesai tampil",
                        selection: optionalDateBinding(
                            for: \.visibleUntil,
                            fallback: features.environment.clock.now()
                        )
                    )
                    Stepper(
                        "Urutan: \(content.sortOrder.formatted(.number.locale(Locale(identifier: "id-ID"))))",
                        value: $content.sortOrder,
                        in: 0...100
                    )
                    Toggle("Aktif", isOn: $content.isPublished)
                }
                Section("Pratinjau peserta") {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Label(content.title, systemImage: "trophy.fill")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(Color.appPrimaryText)
                        Text(content.body)
                            .font(AppTypography.body)
                            .foregroundStyle(Color.appSecondaryText)
                        if let media = content.localMediaReference,
                           !media.isEmpty {
                            Label(media, systemImage: "photo")
                                .font(AppTypography.label)
                        }
                    }
                    .padding(.vertical, AppSpacing.small)
                }
            }
            .navigationTitle("Banner pemenang")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Menyimpan…" : "Simpan") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                    .accessibilityIdentifier("admin.content.save-banner")
                }
            }
            .alert(
                "Konten tidak dapat disimpan",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button("Tutup", role: .cancel) {}
            } message: {
                Text(error?.localizedAdminMessage ?? "")
            }
        }
    }

    private func optionalStringBinding(
        for keyPath: WritableKeyPath<ManagedContent, String?>
    ) -> Binding<String> {
        Binding(
            get: { content[keyPath: keyPath] ?? "" },
            set: { content[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }

    private func optionalDateBinding(
        for keyPath: WritableKeyPath<ManagedContent, Date?>,
        fallback: Date
    ) -> Binding<Date> {
        Binding(
            get: { content[keyPath: keyPath] ?? fallback },
            set: { content[keyPath: keyPath] = $0 }
        )
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        var updated = content
        updated.updatedAt = features.environment.clock.now()
        do {
            try await features.saveContent(updated)
            dismiss()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }
}

@MainActor
struct AdminWinnerManagementView: View {
    let programID: UUID
    let features: AdminFeatureContainer

    @State private var entryToAdjust: LeaderboardEntry?
    @State private var showsLockConfirmation = false
    @State private var error: DomainError?

    var body: some View {
        List {
            if let message = features.lastMessage {
                Section {
                    Label(message, systemImage: "info.circle")
                        .foregroundStyle(Color.appSecondaryText)
                }
            }

            Section("Papan peringkat") {
                AsyncContentView(
                    state: features.leaderboardState,
                    emptyTitle: "Belum ada peringkat",
                    emptyMessage: "Data peserta belum tersedia."
                ) { entries in
                    ForEach(entries) { entry in
                        Button {
                            entryToAdjust = entry
                        } label: {
                            HStack {
                                RankBadge(rank: entry.rank)
                                VStack(alignment: .leading) {
                                    Text(entry.participantDisplayName)
                                        .foregroundStyle(
                                            Color.appPrimaryText
                                        )
                                    Text(
                                        entry.score.totalPoints.formatted(
                                            .number.locale(
                                                Locale(identifier: "id-ID")
                                            )
                                        )
                                    )
                                    .font(AppTypography.secondary.monospacedDigit())
                                    .foregroundStyle(
                                        Color.appSecondaryText
                                    )
                                }
                                Spacer()
                                Image(systemName: "plusminus")
                                    .foregroundStyle(Color.brandPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(
                            "admin.winners.adjust.\(entry.id.uuidString)"
                        )
                    }
                }
            }

            Section("Snapshot pemenang") {
                switch features.winnersState {
                case .loaded(let winners):
                    ForEach(winners) { winner in
                        HStack {
                            RankBadge(rank: winner.rank)
                            Text(winner.participantDisplayName)
                            Spacer()
                            Text(
                                winner.totalPoints,
                                format: .number.locale(
                                    Locale(identifier: "id-ID")
                                )
                            )
                            .monospacedDigit()
                        }
                    }
                    Label(
                        "Snapshot terkunci. Perubahan poin berikutnya "
                            + "tidak mengubah urutan ini secara diam-diam.",
                        systemImage: "lock.fill"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                    if hasScoresChangedSinceLock(winners) {
                        Label(
                            "Skor berubah setelah snapshot dikunci. "
                                + "Pemenang terkunci tidak diubah otomatis.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appWarning)
                        .accessibilityIdentifier(
                            "admin.winners.changed-warning"
                        )
                    }
#if DEBUG
                    Button(
                        "Reset snapshot pemenang demo",
                        role: .destructive
                    ) {
                        Task {
                            await features.resetLockedWinners(
                                programID: programID
                            )
                        }
                    }
                    .accessibilityIdentifier("admin.winners.reset-debug")
#endif
                case .empty:
                    Button("Kunci lima pemenang") {
                        showsLockConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.brandPrimary)
                    .accessibilityIdentifier("admin.winners.lock")
                case .idle, .loading:
                    ProgressView()
                case .failed(let domainError):
                    ErrorStateView(error: domainError)
                case .offline:
                    OfflineBanner()
                }
            }

            Section {
                Button("Buat banner pemenang lokal") {
                    Task {
                        do {
                            try await features.saveContent(
                                features.makeWinnerBanner(
                                    programID: programID
                                )
                            )
                        } catch let domainError as DomainError {
                            error = domainError
                        } catch {
                            self.error = .unknown
                        }
                    }
                }
            } header: {
                Text("Banner lokal")
            } footer: {
                Text("Media tetap berupa referensi lokal pada fase ini.")
            }
        }
        .navigationTitle("Pemenang")
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .task(id: programID) {
            await features.loadLeaderboard(programID: programID)
        }
        .sheet(item: $entryToAdjust) { entry in
            AdminScoreAdjustmentSheet(
                entry: entry,
                features: features
            )
        }
        .confirmationDialog(
            "Kunci lima pemenang?",
            isPresented: $showsLockConfirmation,
            titleVisibility: .visible
        ) {
            Button("Kunci snapshot") {
                Task {
                    do {
                        try await features.lockWinners(
                            programID: programID
                        )
                    } catch let domainError as DomainError {
                        error = domainError
                    } catch {
                        self.error = .unknown
                    }
                }
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text(
                "Urutan yang dikunci tidak berubah otomatis setelah "
                    + "penyesuaian skor."
            )
        }
        .alert(
            "Tindakan tidak dapat diselesaikan",
            isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )
        ) {
            Button("Tutup", role: .cancel) {}
        } message: {
            Text(error?.localizedAdminMessage ?? "")
        }
        .accessibilityIdentifier("admin.winners")
    }

    private func hasScoresChangedSinceLock(
        _ winners: [ProgramWinner]
    ) -> Bool {
        guard case .loaded(let entries) = features.leaderboardState else {
            return false
        }
        return WinnerSelector().scoresChanged(
            lockedWinners: winners,
            currentEntries: entries
        )
    }
}

private struct AdminScoreAdjustmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: LeaderboardEntry
    let features: AdminFeatureContainer

    @State private var points = 0
    @State private var reason = ""
    @State private var error: DomainError?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Peserta", value: entry.participantDisplayName)
                    Stepper(
                        "Poin: \(points.formatted(.number.locale(Locale(identifier: "id-ID"))))",
                        value: $points,
                        in: -1_000...1_000
                    )
                    .accessibilityIdentifier("admin.adjust.points")
                    TextField(
                        "Alasan penyesuaian",
                        text: $reason,
                        axis: .vertical
                    )
                    .accessibilityIdentifier("admin.adjust.reason")
                } header: {
                    Text("Penyesuaian poin")
                } footer: {
                    Text(
                        "Penyesuaian dicatat terpisah dan wajib memiliki alasan."
                    )
                }
            }
            .navigationTitle("Sesuaikan poin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Menyimpan…" : "Simpan") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                    .accessibilityIdentifier("admin.adjust.save")
                }
            }
            .alert(
                "Data belum lengkap",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button("Tutup", role: .cancel) {}
            } message: {
                Text(error?.localizedAdminMessage ?? "")
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await features.adjustScore(
                entryID: entry.id,
                points: points,
                reason: reason
            )
            dismiss()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

}
