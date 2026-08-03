import SwiftUI

@MainActor
struct AdminNewProgramDestinationView: View {
    let features: AdminFeatureContainer
    let router: ShellTabRouter

    @State private var createdID: UUID?
    @State private var error: DomainError?

    var body: some View {
        Group {
            if let createdID {
                AdminProgramEditorView(
                    programID: createdID,
                    features: features,
                    router: router
                )
            } else if let error {
                ErrorStateView(error: error) {
                    Task { await create() }
                }
                .padding(AppSpacing.medium)
            } else {
                LoadingStateView()
                    .padding(AppSpacing.medium)
            }
        }
        .task {
            guard createdID == nil else { return }
            await create()
        }
    }

    private func create() async {
        do {
            createdID = try await features.createDraft().id
            error = nil
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }
}

@MainActor
struct AdminProgramEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let features: AdminFeatureContainer
    private let router: ShellTabRouter
    @State private var state: AdminProgramEditorState
    @State private var actionError: DomainError?
    @State private var isPerformingProgramAction = false
    @State private var showsArchiveConfirmation = false
    @State private var showsDuplicateProgramSheet = false

    init(
        programID: UUID,
        features: AdminFeatureContainer,
        router: ShellTabRouter
    ) {
        self.features = features
        self.router = router
        _state = State(
            initialValue: AdminProgramEditorState(
                programID: programID,
                features: features
            )
        )
    }

    var body: some View {
        Group {
            if state.draft != nil {
                AdminProgramOverviewView(
                    draft: draftBinding,
                    state: state,
                    features: features,
                    isPerformingProgramAction: isPerformingProgramAction,
                    onDuplicate: {
                        showsDuplicateProgramSheet = true
                    },
                    onArchive: { showsArchiveConfirmation = true }
                )
            } else if let error = state.error {
                ErrorStateView(error: error) {
                    Task { await state.load() }
                }
                .padding(AppSpacing.medium)
            } else {
                LoadingStateView()
                    .padding(AppSpacing.medium)
            }
        }
        .navigationTitle(state.draft?.title ?? "Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if state.draft?.status == .draft {
                    Button(state.isSaving ? "Menyimpan…" : "Simpan") {
                        Task { await state.save() }
                    }
                    .disabled(state.isSaving)
                    .accessibilityIdentifier("admin.editor.save")
                }
            }
        }
        .task { await state.load() }
        .sheet(isPresented: $showsDuplicateProgramSheet) {
            if let source = state.draft {
                AdminDuplicateProgramSheet(source: source) { request in
                    duplicateAsDraft(request: request)
                }
            }
        }
        .confirmationDialog(
            "Arsipkan program?",
            isPresented: $showsArchiveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Arsipkan program", role: .destructive) {
                archiveProgram()
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text(
                "Program akan dipindahkan ke arsip dan tetap dapat "
                    + "dibuka dalam mode baca."
            )
        }
        .alert(
            "Tindakan tidak dapat diselesaikan",
            isPresented: Binding(
                get: { actionError != nil || state.error != nil },
                set: {
                    if !$0 {
                        actionError = nil
                        state.error = nil
                    }
                }
            )
        ) {
            Button("Tutup", role: .cancel) {}
        } message: {
            Text(
                (actionError ?? state.error)?.localizedAdminMessage ?? ""
            )
        }
    }

    private var draftBinding: Binding<AdminProgramDraft> {
        Binding(
            get: {
                guard let draft = state.draft else {
                    preconditionFailure(
                        "Program harus tersedia saat hub tampil."
                    )
                }
                return draft
            },
            set: {
                state.draft = $0
                state.updateValidation()
            }
        )
    }

    private func duplicateAsDraft(request: DuplicateProgramRequest) {
        guard let source = state.draft else { return }
        showsDuplicateProgramSheet = false
        isPerformingProgramAction = true
        Task {
            defer { isPerformingProgramAction = false }
            do {
                let duplicate = try await features.duplicate(
                    source,
                    request: request
                )
                router.navigate(
                    to: .admin(.programEditor(duplicate.id)),
                    in: .admin(.programs)
                )
            } catch let error as DomainError {
                actionError = error
            } catch {
                actionError = .unknown
            }
        }
    }

    private func archiveProgram() {
        guard let source = state.draft else { return }
        isPerformingProgramAction = true
        Task {
            defer { isPerformingProgramAction = false }
            do {
                try await features.archive(source)
                dismiss()
            } catch let error as DomainError {
                actionError = error
            } catch {
                actionError = .unknown
            }
        }
    }
}

@MainActor
private struct AdminDuplicateProgramSheet: View {
    @Environment(\.dismiss) private var dismiss

    let source: AdminProgramDraft
    let onConfirm: (DuplicateProgramRequest) -> Void

    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date

    init(
        source: AdminProgramDraft,
        onConfirm: @escaping (DuplicateProgramRequest) -> Void
    ) {
        self.source = source
        self.onConfirm = onConfirm

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(identifier: source.timeZoneIdentifier) ?? .gmt
        let sourceStart = calendar.startOfDay(for: source.startDate)
        let duration = max(
            (calendar.dateComponents(
                [.day],
                from: sourceStart,
                to: calendar.startOfDay(for: source.endDate)
            ).day ?? 0) + 1,
            1
        )
        let suggestedStart = calendar.date(
            byAdding: .month,
            value: 1,
            to: sourceStart
        ) ?? sourceStart
        let suggestedEnd = calendar.date(
            byAdding: .day,
            value: duration - 1,
            to: suggestedStart
        ) ?? suggestedStart
        _title = State(initialValue: "\(source.title) — salinan")
        _startDate = State(initialValue: suggestedStart)
        _endDate = State(initialValue: suggestedEnd)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Program baru") {
                    TextField("Nama program", text: $title)
                    DatePicker(
                        "Tanggal mulai",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Tanggal selesai",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: .date
                    )
                }

                Section("Ringkasan perubahan") {
                    LabeledContent(
                        "Periode sumber",
                        value: source.startDate.formatted(
                            date: .abbreviated,
                            time: .omitted
                        ) + " – " + source.endDate.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                    )
                    LabeledContent(
                        "Periode baru",
                        value: startDate.formatted(
                            date: .abbreviated,
                            time: .omitted
                        ) + " – " + endDate.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                    )
                    LabeledContent(
                        "Konten",
                        value: "\(source.days.count) hari disalin dan digeser"
                    )
                    LabeledContent(
                        "Harga",
                        value: source.price.map {
                            $0.formatted(
                                .currency(code: "IDR")
                                    .locale(Locale(identifier: "id-ID"))
                            )
                        } ?? "Gratis"
                    )
                    Text(
                        "Produk App Store dan Google Play tidak ikut disalin. "
                            + "Program berbayar perlu disiapkan kembali."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Duplikasikan program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Buat draft") {
                        onConfirm(
                            DuplicateProgramRequest(
                                title: title,
                                startDate: startDate,
                                endDate: endDate
                            )
                        )
                    }
                    .disabled(
                        title.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty || endDate < startDate
                    )
                }
            }
        }
    }
}

@MainActor
private struct AdminProgramOverviewView: View {
    @Binding var draft: AdminProgramDraft
    let state: AdminProgramEditorState
    let features: AdminFeatureContainer
    let isPerformingProgramAction: Bool
    let onDuplicate: () -> Void
    let onArchive: () -> Void

    private var progress: AdminProgramFlowProgress {
        AdminProgramFlowProgress(issues: state.issues)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.medium) {
                headerCard

                if draft.status == .draft {
                    draftStages
                } else {
                    publishedStages
                    publishedActions
                }
            }
            .padding(AppSpacing.medium)
        }
        .background(Color.appBackground)
        .accessibilityIdentifier("admin.program.editor.overview")
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .top, spacing: AppSpacing.small) {
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(
                        draft.status == .draft
                            ? "Selesaikan 3 tahap"
                            : "Program sudah diterbitkan"
                    )
                    .font(AppTypography.sectionTitle)
                    Text(
                        draft.status == .draft
                            ? "Lengkapi pengaturan, konten, lalu tinjau sebelum diterbitkan."
                            : "Pengaturan dan konten dikunci agar program peserta tetap konsisten."
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                }
                Spacer(minLength: AppSpacing.small)
                StatusBadge(
                    title: LocalizedStringKey(draft.status.adminTitle),
                    kind: statusKind
                )
            }

            if draft.status == .draft {
                ProgressView(
                    value: Double(progress.completedStageCount),
                    total: 3
                )
                .tint(.brandPrimary)
                Text(
                    "\(progress.completedStageCount.formatted(.number.locale(indonesianLocale))) dari 3 tahap siap"
                )
                .font(AppTypography.label.monospacedDigit())
                .foregroundStyle(Color.appSecondaryText)
            } else {
                Label(dateRange, systemImage: "calendar")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }
        }
        .padding(AppSpacing.medium)
        .background(
            Color.appSurface,
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
            .stroke(Color.appBorder, lineWidth: 1)
        }
    }

    private var draftStages: some View {
        VStack(spacing: AppSpacing.medium) {
            NavigationLink {
                AdminProgramSettingsHubView(draft: $draft)
                    .singlePressNavigationBackButton()
            } label: {
                stageCard(
                    number: 1,
                    title: "Pengaturan program",
                    subtitle: "Info, jadwal, peserta, aturan, dan poin",
                    stage: .settings,
                    systemImage: "slider.horizontal.3"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(
                "admin.program.editor.open.settings"
            )

            NavigationLink {
                AdminProgramContentPlannerView(
                    draft: $draft,
                    state: state
                )
                .singlePressNavigationBackButton()
            } label: {
                stageCard(
                    number: 2,
                    title: "Konten program",
                    subtitle: contentSummary,
                    stage: .content,
                    systemImage: "rectangle.stack"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(
                "admin.program.editor.open.content"
            )

            NavigationLink {
                AdminProgramReviewAndPublishView(
                    draft: draft,
                    state: state
                )
                .singlePressNavigationBackButton()
            } label: {
                stageCard(
                    number: 3,
                    title: "Tinjau & terbitkan",
                    subtitle: "Pratinjau, validasi, dan publikasi",
                    stage: .review,
                    systemImage: "checkmark.seal"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(
                "admin.program.editor.open.review"
            )
        }
    }

    private var publishedStages: some View {
        VStack(spacing: AppSpacing.medium) {
            NavigationLink {
                AdminProgramReadOnlySettingsView(draft: draft)
                    .singlePressNavigationBackButton()
            } label: {
                publishedStageCard(
                    number: 1,
                    title: "Pengaturan program",
                    subtitle: "Info, jadwal, aturan, dan poin",
                    systemImage: "slider.horizontal.3"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(
                "admin.program.editor.open.readonly-settings"
            )

            NavigationLink {
                AdminProgramReadOnlyContentView(draft: draft)
                    .singlePressNavigationBackButton()
            } label: {
                publishedStageCard(
                    number: 2,
                    title: "Konten program",
                    subtitle: contentSummary,
                    systemImage: "rectangle.stack"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(
                "admin.program.editor.open.readonly-content"
            )

            NavigationLink {
                AdminProgramPublicationStatusView(
                    draft: draft,
                    features: features
                )
                    .singlePressNavigationBackButton()
            } label: {
                publishedStageCard(
                    number: 3,
                    title: "Status publikasi",
                    subtitle: publicationSummary,
                    systemImage: "checkmark.seal"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(
                "admin.program.editor.open.publication-status"
            )
        }
    }

    @ViewBuilder
    private var publishedActions: some View {
        Button(action: onDuplicate) {
            Label(
                isPerformingProgramAction
                    ? "Menyiapkan draft…"
                    : "Duplikasikan sebagai draft",
                systemImage: "doc.on.doc"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .disabled(isPerformingProgramAction)
        .accessibilityIdentifier("admin.program.duplicate-as-draft")

        if draft.status != .archived {
            Button(role: .destructive, action: onArchive) {
                Label("Arsipkan program", systemImage: "archivebox")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.appDestructive)
            .disabled(isPerformingProgramAction)
            .accessibilityIdentifier("admin.program.archive")
        }
    }

    private func stageCard(
        number: Int,
        title: String,
        subtitle: String,
        stage: AdminProgramStage,
        systemImage: String
    ) -> some View {
        let issueCount = progress.issueCount(for: stage)
        let isComplete = progress.isComplete(stage)
        return AdminProgramStageCard(
            number: number,
            title: title,
            subtitle: subtitle,
            statusTitle: isComplete
                ? (stage == .review ? "Siap diterbitkan" : "Selesai")
                : "\(issueCount.formatted(.number.locale(indonesianLocale))) hal perlu dilengkapi",
            systemImage: systemImage,
            isComplete: isComplete,
            isReadOnly: false
        )
    }

    private func publishedStageCard(
        number: Int,
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        AdminProgramStageCard(
            number: number,
            title: title,
            subtitle: subtitle,
            statusTitle: "Hanya baca",
            systemImage: systemImage,
            isComplete: true,
            isReadOnly: true
        )
    }

    private var contentSummary: String {
        "\(draft.days.count.formatted(.number.locale(indonesianLocale))) hari • "
            + "\(stepCount.formatted(.number.locale(indonesianLocale))) langkah • "
            + "\(questionCount.formatted(.number.locale(indonesianLocale))) pertanyaan"
    }

    private var publicationSummary: String {
        switch draft.status {
        case .draft:
            "Belum diterbitkan"
        case .preparingCommerce:
            "Pembayaran sedang disiapkan"
        case .scheduled:
            "Terjadwal dan tidak dapat diubah langsung"
        case .active:
            "Sedang berjalan dan tidak dapat diubah langsung"
        case .completed:
            "Program telah selesai"
        case .archived:
            "Program tersimpan di arsip"
        }
    }

    private var stepCount: Int {
        draft.days.flatMap(\.steps).count
    }

    private var questionCount: Int {
        draft.days
            .flatMap(\.steps)
            .flatMap { $0.quiz?.questions ?? [] }
            .count
    }

    private var dateRange: String {
        let style = Date.FormatStyle(
            date: .abbreviated,
            time: .omitted,
            locale: indonesianLocale,
            timeZone: TimeZone(
                identifier: draft.timeZoneIdentifier
            ) ?? .gmt
        )
        return "\(draft.startDate.formatted(style))–\(draft.endDate.formatted(style))"
    }

    private var indonesianLocale: Locale {
        Locale(identifier: "id-ID")
    }

    private var statusKind: AppStatusKind {
        switch draft.status {
        case .draft:
            .warning
        case .preparingCommerce:
            .pending
        case .scheduled, .active:
            .success
        case .completed, .archived:
            .neutral
        }
    }
}

@MainActor
private struct AdminProgramStageCard: View {
    let number: Int
    let title: String
    let subtitle: String
    let statusTitle: String
    let systemImage: String
    let isComplete: Bool
    let isReadOnly: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Text(
                number.formatted(
                    .number.locale(Locale(identifier: "id-ID"))
                )
            )
            .font(AppTypography.cardTitle.monospacedDigit())
            .foregroundStyle(Color.white)
            .frame(width: 44, height: 44)
            .background(Color.brandPrimary, in: Circle())
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Label(title, systemImage: systemImage)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                Text(subtitle)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                    .multilineTextAlignment(.leading)
                Label(
                    statusTitle,
                    systemImage: isReadOnly
                        ? "lock.fill"
                        : (isComplete
                            ? "checkmark.circle.fill"
                            : "circle.dotted")
                )
                .font(AppTypography.label)
                .foregroundStyle(
                    isComplete ? Color.appSuccess : Color.appWarning
                )
            }

            Spacer(minLength: AppSpacing.xSmall)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.appSecondaryText)
                .padding(.top, AppSpacing.small)
                .accessibilityHidden(true)
        }
        .padding(AppSpacing.medium)
        .background(
            Color.appSurface,
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
            .stroke(Color.appBorder, lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
}

@MainActor
private struct AdminProgramSettingsHubView: View {
    @Binding var draft: AdminProgramDraft

    var body: some View {
        List {
            Section {
                NavigationLink {
                    AdminProgramInformationView(draft: $draft)
                        .singlePressNavigationBackButton()
                } label: {
                    AdminProgramOverviewRow(
                        title: "Info program",
                        subtitle: draft.category.isEmpty
                            ? "Nama, deskripsi, kategori, dan cover"
                            : draft.category,
                        systemImage: "doc.text"
                    )
                }
                .accessibilityIdentifier(
                    "admin.program.editor.open.info"
                )

                NavigationLink {
                    AdminProgramScheduleView(draft: $draft)
                        .singlePressNavigationBackButton()
                } label: {
                    AdminProgramOverviewRow(
                        title: "Jadwal dan peserta",
                        subtitle: scheduleSummary,
                        systemImage: "calendar.badge.clock"
                    )
                }
                .accessibilityIdentifier(
                    "admin.program.editor.open.schedule"
                )

                NavigationLink {
                    AdminProgramRulesView(draft: $draft)
                        .singlePressNavigationBackButton()
                } label: {
                    AdminProgramOverviewRow(
                        title: "Aturan dan poin",
                        subtitle: rulesSummary,
                        systemImage: "slider.horizontal.3"
                    )
                }
                .accessibilityIdentifier(
                    "admin.program.editor.open.rules"
                )
            } footer: {
                Text(
                    "Ketiga bagian ini merupakan satu tahap. Kembali ke "
                        + "hub setelah pengaturan selesai."
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Pengaturan program")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.settings-hub")
    }

    private var scheduleSummary: String {
        let dayCount = (
            draft.durationMode == .fixedDuration
                ? draft.fixedDurationDays
                : draft.durationInDays
        ).formatted(.number.locale(Locale(identifier: "id-ID")))
        return "\(draft.pace.adminTitle) • \(dayCount) hari • Publik"
    }

    private var rulesSummary: String {
        "\(draft.pointsPerActivity.formatted(.number.locale(Locale(identifier: "id-ID")))) poin/langkah • "
            + "\(draft.weightPointsPerKilogram.formatted(.number.locale(Locale(identifier: "id-ID")))) poin/kg turun • "
            + draft.verificationMode.adminTitle
    }
}

@MainActor
private struct AdminProgramReviewAndPublishView: View {
    let draft: AdminProgramDraft
    let state: AdminProgramEditorState

    var body: some View {
        Form {
            Section("Pratinjau") {
                NavigationLink {
                    AdminProgramParticipantPreviewView(draft: draft)
                        .singlePressNavigationBackButton()
                } label: {
                    AdminProgramOverviewRow(
                        title: "Pratinjau program",
                        subtitle:
                            "Periksa tampilan Peserta dan Coach sebelum diterbitkan",
                        systemImage: "eye"
                    )
                }
                .accessibilityIdentifier(
                    "admin.program.editor.open.preview"
                )
            }

            Section("Validasi") {
                if state.issues.isEmpty {
                    Label(
                        "Semua bagian siap diterbitkan.",
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(Color.appSuccess)
                } else {
                    ForEach(state.issues) { issue in
                        Label(
                            issue.message,
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(Color.appWarning)
                    }
                }
            }

            Section("Ringkasan") {
                LabeledContent("Nama", value: draft.title)
                LabeledContent(
                    "Hari",
                    value: draft.days.count.formatted(
                        .number.locale(Locale(identifier: "id-ID"))
                    )
                )
                LabeledContent(
                    "Langkah",
                    value: draft.days.flatMap(\.steps).count.formatted(
                        .number.locale(Locale(identifier: "id-ID"))
                    )
                )
                LabeledContent(
                    "Pertanyaan",
                    value: draft.days
                        .flatMap(\.steps)
                        .flatMap { $0.quiz?.questions ?? [] }
                        .count
                        .formatted(
                            .number.locale(Locale(identifier: "id-ID"))
                        )
                )
            }

            Section {
                Button(
                    state.didPublish
                        ? "Publikasi demo selesai"
                        : "Terbitkan program"
                ) {
                    Task { await state.publish() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandPrimary)
                .disabled(
                    !state.issues.isEmpty
                        || state.isSaving
                        || draft.status != .draft
                )
                .accessibilityIdentifier("admin.editor.publish")
            } footer: {
                Text(
                    "Pada fase demo, publikasi mengubah status mock dan "
                        + "mencatat audit lokal."
                )
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Tinjau & terbitkan")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.review-publish")
    }
}

@MainActor
private struct AdminProgramReadOnlySettingsView: View {
    let draft: AdminProgramDraft

    var body: some View {
        Form {
            Section {
                Label(
                    "Pengaturan terkunci setelah program diterbitkan.",
                    systemImage: "lock.fill"
                )
                .foregroundStyle(Color.appSecondaryText)
            }

            Section("Info program") {
                LabeledContent("Nama", value: draft.title)
                LabeledContent(
                    "Kategori",
                    value: draft.category.isEmpty
                        ? "Belum ditentukan"
                        : draft.category
                )
                LabeledContent(
                    "Deskripsi",
                    value: draft.summary.isEmpty
                        ? "Belum ada deskripsi"
                        : draft.summary
                )
            }

            Section("Jadwal dan peserta") {
                LabeledContent(
                    "Mulai",
                    value: draft.startDate.formatted(dateStyle)
                )
                LabeledContent(
                    "Selesai",
                    value: draft.endDate.formatted(dateStyle)
                )
                LabeledContent("Zona waktu", value: draft.timeZoneIdentifier)
                LabeledContent("Akses", value: "Publik")
            }

            Section("Aturan dan poin") {
                LabeledContent(
                    "Poin setiap langkah selesai",
                    value: draft.pointsPerActivity.formatted(
                        .number.locale(Locale(identifier: "id-ID"))
                    )
                )
                LabeledContent(
                    "Poin setiap 1 kg turun",
                    value: draft.weightPointsPerKilogram.formatted(
                        .number.locale(Locale(identifier: "id-ID"))
                    )
                )
                LabeledContent(
                    "Pemeriksaan",
                    value: draft.verificationMode.adminTitle
                )
                LabeledContent(
                    "Hari terdahulu",
                    value: draft.pastStepPolicy.adminTitle
                )
                LabeledContent(
                    "Hari mendatang",
                    value: draft.futureStepPolicy.adminTitle
                )
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Pengaturan program")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.readonly-settings")
    }

    private var dateStyle: Date.FormatStyle {
        Date.FormatStyle(
            date: .abbreviated,
            time: .omitted,
            locale: Locale(identifier: "id-ID"),
            timeZone: TimeZone(
                identifier: draft.timeZoneIdentifier
            ) ?? .gmt
        )
    }
}

@MainActor
private struct AdminProgramReadOnlyContentView: View {
    let draft: AdminProgramDraft

    var body: some View {
        List {
            Section {
                Label(
                    "Konten terkunci setelah program diterbitkan.",
                    systemImage: "lock.fill"
                )
                .foregroundStyle(Color.appSecondaryText)
            }

            ForEach(draft.days) { day in
                Section("Hari ke-\(day.dayNumber): \(day.title)") {
                    if day.steps.isEmpty {
                        Text("Belum ada langkah")
                            .foregroundStyle(Color.appSecondaryText)
                    } else {
                        ForEach(day.steps) { step in
                            VStack(
                                alignment: .leading,
                                spacing: AppSpacing.xSmall
                            ) {
                                Text(step.title)
                                    .font(AppTypography.cardTitle)
                                Text(step.instructions)
                                    .font(AppTypography.secondary)
                                    .foregroundStyle(
                                        Color.appSecondaryText
                                    )
                                Label(
                                    step.contentKind.adminTitle,
                                    systemImage: step.contentKind.systemImage
                                )
                                .font(AppTypography.label.monospacedDigit())
                                .foregroundStyle(Color.appSecondaryText)
                            }
                            .padding(.vertical, AppSpacing.xxSmall)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Konten program")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.readonly-content")
    }
}

@MainActor
private struct AdminProgramPublicationStatusView: View {
    let draft: AdminProgramDraft
    let features: AdminFeatureContainer

    @State private var preflight: ProgramClosurePreflight?
    @State private var isLoadingClosure = false
    @State private var isLockingWinners = false
    @State private var selectedPoster: ManagedContent?
    @State private var showsFailedQuizAttempts = false
    @State private var error: DomainError?

    var body: some View {
        Form {
            Section("Status") {
                LabeledContent("Publikasi", value: draft.status.adminTitle)
                LabeledContent(
                    "Pembaruan terakhir",
                    value: draft.updatedAt.formatted(
                        Date.FormatStyle(
                            date: .abbreviated,
                            time: .shortened,
                            locale: Locale(identifier: "id-ID"),
                            timeZone: TimeZone(
                                identifier: draft.timeZoneIdentifier
                            ) ?? .gmt
                        )
                    )
                )
            }

            Section {
                Label(
                    "Program ini tidak dapat diubah langsung.",
                    systemImage: "lock.fill"
                )
                Text(
                    "Buat salinan draft dari hub program untuk menyiapkan "
                        + "versi baru tanpa mengubah pengalaman peserta."
                )
                .foregroundStyle(Color.appSecondaryText)
            }

            if isClosureAvailable {
                closureSection
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Status publikasi")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard isClosureAvailable else { return }
            await loadClosure()
        }
        .sheet(item: $selectedPoster) { poster in
            AdminPosterEditorSheet(
                initialContent: poster,
                features: features
            )
        }
        .sheet(isPresented: $showsFailedQuizAttempts) {
            AdminFailedQuizAttemptsSheet(
                programID: draft.id,
                features: features
            ) {
                Task { await loadClosure() }
            }
        }
        .alert(
            "Penutupan belum dapat diselesaikan",
            isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )
        ) {
            Button("Tutup", role: .cancel) {}
        } message: {
            Text(error?.localizedAdminMessage ?? "")
        }
        .accessibilityIdentifier("admin.program.publication-status")
    }

    @ViewBuilder
    private var closureSection: some View {
        Section {
            if isLoadingClosure {
                ProgressView("Memeriksa kesiapan penutupan…")
            } else if let preflight {
                LabeledContent(
                    "Peserta",
                    value: preflight.enrollmentCount.formatted(
                        .number.locale(
                            Locale(
                                identifier: AppConfiguration
                                    .indonesianLocaleIdentifier
                            )
                        )
                    )
                )
                closureRow(
                    title: "Pemeriksaan tertunda",
                    count: preflight.count(for: .pendingReview),
                    blocks: true
                )
                closureRow(
                    title: "Timbang akhir belum lengkap",
                    count: preflight.count(for: .missingFinalWeighIn),
                    blocks: true
                )
                closureRow(
                    title: "Kuis tidak lulus",
                    count: preflight.count(for: .failedQuiz),
                    blocks: false
                )
                if preflight.count(for: .failedQuiz) > 0 {
                    Button {
                        showsFailedQuizAttempts = true
                    } label: {
                        Label(
                            "Kelola percobaan kuis",
                            systemImage: "arrow.clockwise.circle"
                        )
                    }
                }

                switch features.winnersState {
                case .loaded(let winners) where !winners.isEmpty:
                    Label(
                        "Snapshot pemenang sudah dikunci.",
                        systemImage: "lock.fill"
                    )
                    .foregroundStyle(Color.appSuccess)

                    Button {
                        selectedPoster = features.makeWinnerBanner(
                            programID: draft.id,
                            winnerSnapshotID: winners.first?.id,
                            sortOrder: features.nextWinnerPosterSortOrder
                        )
                    } label: {
                        Label(
                            "Buat poster pemenang",
                            systemImage: "photo.stack.fill"
                        )
                    }
                default:
                    Button {
                        Task { await lockWinners() }
                    } label: {
                        Label(
                            isLockingWinners
                                ? "Mengunci pemenang…"
                                : "Tutup perhitungan dan kunci pemenang",
                            systemImage: "lock.fill"
                        )
                    }
                    .disabled(
                        !preflight.canLockWinners || isLockingWinners
                    )
                }
            } else {
                Button("Coba lagi") {
                    Task { await loadClosure() }
                }
            }
        } header: {
            Text("Penutupan program")
        } footer: {
            Text(
                "Kuis tidak lulus ditampilkan sebagai informasi dan tidak "
                    + "memblokir penutupan karena Peserta hanya memiliki "
                    + "satu percobaan."
            )
        }
    }

    @ViewBuilder
    private func closureRow(
        title: String,
        count: Int,
        blocks: Bool
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(
                count.formatted(
                    .number.locale(
                        Locale(
                            identifier: AppConfiguration
                                .indonesianLocaleIdentifier
                        )
                    )
                )
            )
            .monospacedDigit()
            Image(
                systemName: count == 0
                    ? "checkmark.circle.fill"
                    : (blocks ? "exclamationmark.triangle.fill" : "info.circle")
            )
            .foregroundStyle(
                count == 0
                    ? Color.appSuccess
                    : (blocks ? Color.appWarning : Color.appSecondaryText)
            )
            .accessibilityHidden(true)
        }
    }

    private var isClosureAvailable: Bool {
        draft.status == .completed
            || draft.status == .archived
            || draft.endDate < features.environment.clock.now()
    }

    private func loadClosure() async {
        isLoadingClosure = true
        defer { isLoadingClosure = false }
        do {
            async let loadedPreflight = features.loadClosurePreflight(
                programID: draft.id
            )
            async let loadedLeaderboard: Void = features.loadLeaderboard(
                programID: draft.id
            )
            preflight = try await loadedPreflight
            await loadedLeaderboard
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    private func lockWinners() async {
        isLockingWinners = true
        defer { isLockingWinners = false }
        do {
            try await features.lockWinners(programID: draft.id)
            preflight = try await features.loadClosurePreflight(
                programID: draft.id
            )
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }
}

@MainActor
private struct AdminFailedQuizAttemptsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let programID: UUID
    let features: AdminFeatureContainer
    let onChanged: () -> Void

    @State private var items: [AdminFailedQuizAttempt] = []
    @State private var selectedItem: AdminFailedQuizAttempt?
    @State private var isLoading = true
    @State private var error: DomainError?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Memuat percobaan kuis…")
                } else if let error {
                    ErrorStateView(error: error) {
                        Task { await load() }
                    }
                    .padding(AppSpacing.medium)
                } else if items.isEmpty {
                    ContentUnavailableView(
                        "Tidak ada kuis yang dapat dibuka",
                        systemImage: "checkmark.circle",
                        description: Text(
                            "Semua percobaan gagal sudah ditangani."
                        )
                    )
                } else {
                    List(items) { item in
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text(item.participantName)
                                .font(AppTypography.cardTitle)
                            Text(item.stepTitle)
                                .font(AppTypography.body)
                            Text("Percobaan \(item.sequence)")
                                .font(AppTypography.secondary.monospacedDigit())
                                .foregroundStyle(Color.appSecondaryText)
                            Button("Buka satu percobaan baru") {
                                selectedItem = item
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, AppSpacing.xSmall)
                    }
                }
            }
            .navigationTitle("Percobaan kuis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") { dismiss() }
                }
            }
        }
        .task { await load() }
        .sheet(item: $selectedItem) { item in
            AdminQuizReopenReasonSheet(item: item) { reason in
                try await features.reopenQuizAttempt(item, reason: reason)
                await load()
                onChanged()
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await features.failedQuizAttempts(
                programID: programID
            )
            error = nil
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }
}

@MainActor
private struct AdminQuizReopenReasonSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: AdminFailedQuizAttempt
    let onSubmit: (String) async throws -> Void

    @State private var reason = ""
    @State private var isSubmitting = false
    @State private var error: DomainError?

    var body: some View {
        NavigationStack {
            Form {
                Section("Kuis") {
                    LabeledContent("Peserta", value: item.participantName)
                    LabeledContent("Langkah", value: item.stepTitle)
                }
                Section {
                    TextField(
                        "Alasan membuka ulang",
                        text: $reason,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                } footer: {
                    Text(
                        "Alasan wajib diisi dan dicatat pada audit Admin. "
                            + "Percobaan lama tetap tersimpan."
                    )
                }
            }
            .navigationTitle("Buka ulang kuis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Menyimpan…" : "Buka") {
                        Task { await submit() }
                    }
                    .disabled(
                        isSubmitting
                            || reason.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty
                    )
                }
            }
        }
        .alert(
            "Percobaan belum dibuka",
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

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await onSubmit(reason)
            dismiss()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }
}

@MainActor
private struct AdminProgramOverviewRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(title)
                    .font(AppTypography.cardTitle)
                Text(subtitle)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.brandPrimary)
        }
        .padding(.vertical, AppSpacing.xxSmall)
    }
}
