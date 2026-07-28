import SwiftUI

@MainActor
struct AdminNewProgramDestinationView: View {
    let features: AdminFeatureContainer

    @State private var createdID: UUID?
    @State private var error: DomainError?

    var body: some View {
        Group {
            if let createdID {
                AdminProgramEditorView(
                    programID: createdID,
                    features: features
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
    @State private var state: AdminProgramEditorState

    init(
        programID: UUID,
        features: AdminFeatureContainer
    ) {
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
                    state: state
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
        .navigationTitle(state.draft?.title ?? "Editor program")
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
        .alert(
            "Tindakan tidak dapat diselesaikan",
            isPresented: Binding(
                get: { state.error != nil },
                set: { if !$0 { state.error = nil } }
            )
        ) {
            Button("Tutup", role: .cancel) {}
        } message: {
            Text(state.error?.localizedAdminMessage ?? "")
        }
    }

    private var draftBinding: Binding<AdminProgramDraft> {
        Binding(
            get: {
                guard let draft = state.draft else {
                    preconditionFailure(
                        "Draft harus tersedia saat editor tampil."
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
}

@MainActor
private struct AdminProgramOverviewView: View {
    @Binding var draft: AdminProgramDraft
    let state: AdminProgramEditorState

    var body: some View {
        List {
            Section {
                LabeledContent("Status") {
                    Text(draft.status.adminTitle)
                        .foregroundStyle(statusColor)
                }
                if state.issues.isEmpty {
                    Label(
                        "Semua bagian utama sudah siap.",
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(Color.appSuccess)
                } else {
                    Label(
                        "\(state.issues.count.formatted(.number.locale(Locale(identifier: "id-ID")))) hal perlu diperiksa",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(Color.appWarning)
                }
            }

            Section("Pengaturan") {
                NavigationLink {
                    AdminProgramInformationView(draft: $draft)
                        .singlePressNavigationBackButton()
                } label: {
                    AdminProgramOverviewRow(
                        title: "Info program",
                        subtitle: infoSummary,
                        systemImage: "doc.text"
                    )
                }
                .disabled(!isEditable)
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
                .disabled(!isEditable)
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
                .disabled(!isEditable)
                .accessibilityIdentifier(
                    "admin.program.editor.open.rules"
                )
            }

            Section("Susunan program") {
                NavigationLink {
                    AdminProgramContentPlannerView(
                        draft: $draft,
                        state: state
                    )
                    .singlePressNavigationBackButton()
                } label: {
                    AdminProgramOverviewRow(
                        title: "Konten",
                        subtitle: contentSummary,
                        systemImage: "rectangle.stack"
                    )
                }
                .disabled(!isEditable)
                .accessibilityIdentifier(
                    "admin.program.editor.open.content"
                )
            }

            Section("Sebelum publikasi") {
                NavigationLink {
                    AdminProgramParticipantPreviewView(draft: draft)
                        .singlePressNavigationBackButton()
                } label: {
                    AdminProgramOverviewRow(
                        title: "Pratinjau peserta",
                        subtitle: "Lihat tampilan program sebelum diterbitkan",
                        systemImage: "iphone"
                    )
                }
                .accessibilityIdentifier(
                    "admin.program.editor.open.preview"
                )

                NavigationLink {
                    AdminProgramPublishView(
                        draft: draft,
                        state: state
                    )
                    .singlePressNavigationBackButton()
                } label: {
                    AdminProgramOverviewRow(
                        title: "Tinjau dan publikasi",
                        subtitle: publishSummary,
                        systemImage: "checkmark.seal"
                    )
                }
                .accessibilityIdentifier(
                    "admin.program.editor.open.publish"
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .accessibilityIdentifier("admin.program.editor.overview")
    }

    private var isEditable: Bool {
        draft.status == .draft
    }

    private var infoSummary: String {
        draft.category.isEmpty
            ? "Nama, deskripsi, kategori, dan cover"
            : draft.category
    }

    private var scheduleSummary: String {
        let dayCount = (
            draft.durationMode == .fixedDuration
                ? draft.fixedDurationDays
                : draft.durationInDays
        ).formatted(.number.locale(Locale(identifier: "id-ID")))
        return "\(draft.pace.adminTitle) · \(dayCount) hari · "
            + draft.access.adminTitle
    }

    private var rulesSummary: String {
        "\(draft.weightPointsPerKilogram.formatted(.number.locale(Locale(identifier: "id-ID")))) poin/kg · "
            + draft.verificationMode.adminTitle
    }

    private var contentSummary: String {
        "\(draft.days.count.formatted(.number.locale(Locale(identifier: "id-ID")))) hari · "
            + "\(stepCount.formatted(.number.locale(Locale(identifier: "id-ID")))) langkah · "
            + "\(questionCount.formatted(.number.locale(Locale(identifier: "id-ID")))) pertanyaan"
    }

    private var publishSummary: String {
        state.issues.isEmpty
            ? "Siap untuk simulasi publikasi"
            : "\(state.issues.count.formatted(.number.locale(Locale(identifier: "id-ID")))) hal perlu diperbaiki"
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

    private var statusColor: Color {
        switch draft.status {
        case .draft:
            .appWarning
        case .scheduled, .active:
            .appSuccess
        case .completed, .archived:
            .appSecondaryText
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
