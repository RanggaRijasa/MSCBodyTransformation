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
                    isPerformingProgramAction: isPerformingProgramAction,
                    onDuplicate: duplicateAsDraft,
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

    private func duplicateAsDraft() {
        guard let source = state.draft else { return }
        isPerformingProgramAction = true
        Task {
            defer { isPerformingProgramAction = false }
            do {
                let duplicate = try await features.duplicate(source)
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
private struct AdminProgramOverviewView: View {
    @Binding var draft: AdminProgramDraft
    let state: AdminProgramEditorState
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
                AdminProgramPublicationStatusView(draft: draft)
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
        return "\(draft.pace.adminTitle) • \(dayCount) hari • "
            + draft.access.adminTitle
    }

    private var rulesSummary: String {
        "\(draft.weightPointsPerKilogram.formatted(.number.locale(Locale(identifier: "id-ID")))) poin/kg • "
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
                        title: "Pratinjau peserta",
                        subtitle: "Periksa tampilan sebelum diterbitkan",
                        systemImage: "iphone"
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
                LabeledContent("Akses", value: draft.access.adminTitle)
            }

            Section("Aturan dan poin") {
                LabeledContent(
                    "Poin per kg",
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
                                    "\(step.points.formatted(.number.locale(Locale(identifier: "id-ID")))) poin",
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
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Status publikasi")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.publication-status")
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
