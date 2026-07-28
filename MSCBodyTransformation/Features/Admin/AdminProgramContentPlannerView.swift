import SwiftUI

@MainActor
struct AdminProgramContentPlannerView: View {
    @Binding var draft: AdminProgramDraft
    let state: AdminProgramEditorState

    @State private var showsScheduleSyncConfirmation = false
    @State private var dayPendingDeletion: AdminDayDraft?

    var body: some View {
        List {
            Section {
                LabeledContent {
                    VStack(alignment: .trailing) {
                        Text(
                            draft.startDate,
                            format: dateFormat
                        )
                        Text(
                            draft.endDate,
                            format: dateFormat
                        )
                    }
                } label: {
                    Label("Rentang jadwal", systemImage: "calendar")
                }

                Label(
                    state.isScheduleSynchronized
                        ? "Hari sudah sesuai dengan jadwal."
                        : "Perubahan jadwal belum diterapkan ke hari.",
                    systemImage: state.isScheduleSynchronized
                        ? "checkmark.circle.fill"
                        : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(
                    state.isScheduleSynchronized
                        ? Color.appSuccess
                        : Color.appWarning
                )

                Button(action: requestScheduleSynchronization) {
                    Label(
                        "Sinkronkan hari dengan jadwal",
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                }
                .disabled(state.isScheduleSynchronized)
                .accessibilityIdentifier("admin.program.days.sync")
            } header: {
                Text("Jadwal")
            } footer: {
                Text(
                    "Sinkronisasi mempertahankan isi hari yang sudah ada. "
                        + "Konfirmasi diminta bila ada hari berisi konten "
                        + "yang akan dipangkas."
                )
            }

            Section("Hari program") {
                if draft.days.isEmpty {
                    ContentUnavailableView(
                        "Belum ada hari",
                        systemImage: "calendar.badge.plus",
                        description: Text(
                            "Sinkronkan jadwal atau tambahkan hari baru."
                        )
                    )
                } else {
                    ForEach(draft.days) { day in
                        NavigationLink {
                            AdminProgramDayEditorView(
                                draft: $draft,
                                dayID: day.id,
                                timeZoneIdentifier:
                                    draft.timeZoneIdentifier,
                                state: state
                            )
                            .singlePressNavigationBackButton()
                        } label: {
                            AdminProgramDayRow(day: day)
                        }
                        .accessibilityIdentifier(
                            "admin.program.day.open.\(day.id)"
                        )
                        .swipeActions(edge: .leading) {
                            Button {
                                applyStateMutation {
                                    state.duplicateDay(day.id)
                                }
                            } label: {
                                Label(
                                    "Duplikasi",
                                    systemImage: "plus.square.on.square"
                                )
                            }
                            .tint(.appInfo)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                dayPendingDeletion = day
                            } label: {
                                Label("Hapus", systemImage: "trash")
                            }
                        }
                    }
                    .onMove { offsets, destination in
                        applyStateMutation {
                            state.moveDay(
                                from: offsets,
                                to: destination
                            )
                        }
                    }
                }
            }

            Section {
                Button {
                    applyStateMutation {
                        state.appendDay()
                    }
                } label: {
                    Label("Tambah hari", systemImage: "plus")
                }
                .accessibilityIdentifier("admin.program.day.add")
            } footer: {
                Text(
                    "Menambah hari juga memperpanjang tanggal selesai "
                        + "program satu hari."
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Konten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .confirmationDialog(
            "Sinkronkan dan pangkas hari?",
            isPresented: $showsScheduleSyncConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sinkronkan", role: .destructive) {
                applyStateMutation {
                    state.synchronizeDays()
                }
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text(
                "Hari di luar jadwal beserta langkah dan pertanyaannya "
                    + "akan dihapus dari draft."
            )
        }
        .confirmationDialog(
            "Hapus hari program?",
            isPresented: Binding(
                get: { dayPendingDeletion != nil },
                set: { if !$0 { dayPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Hapus hari", role: .destructive) {
                if let dayPendingDeletion {
                    applyStateMutation {
                        state.removeDay(dayPendingDeletion.id)
                    }
                }
                dayPendingDeletion = nil
            }
            Button("Batal", role: .cancel) {
                dayPendingDeletion = nil
            }
        } message: {
            Text(
                dayPendingDeletion?.steps.isEmpty == false
                    ? "Semua langkah dan pertanyaan di hari ini ikut dihapus."
                    : "Tanggal selesai program akan disesuaikan."
            )
        }
        .accessibilityIdentifier("admin.program.content")
    }

    private var dateFormat: Date.FormatStyle {
        .dateTime
            .day()
            .month(.abbreviated)
            .year()
            .locale(Locale(identifier: "id-ID"))
    }

    private func requestScheduleSynchronization() {
        if state.scheduleSyncRemovesContent {
            showsScheduleSyncConfirmation = true
        } else {
            applyStateMutation {
                state.synchronizeDays()
            }
        }
    }

    private func applyStateMutation(_ mutation: () -> Void) {
        mutation()
        if let updatedDraft = state.draft {
            draft = updatedDraft
        }
    }
}

@MainActor
private struct AdminProgramDayRow: View {
    let day: AdminDayDraft

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text("Hari ke-\(day.dayNumber) · \(day.title)")
                    .font(AppTypography.cardTitle)
                Text(
                    "\(day.steps.count.formatted(.number.locale(Locale(identifier: "id-ID")))) langkah · \(questionCount.formatted(.number.locale(Locale(identifier: "id-ID")))) pertanyaan"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
            }
        } icon: {
            Image(systemName: "calendar")
                .foregroundStyle(Color.brandPrimary)
        }
    }

    private var questionCount: Int {
        day.steps
            .flatMap { $0.quiz?.questions ?? [] }
            .count
    }
}

@MainActor
struct AdminProgramDayEditorView: View {
    @Binding var draft: AdminProgramDraft
    let dayID: UUID
    let timeZoneIdentifier: String
    let state: AdminProgramEditorState

    var body: some View {
        Group {
            if let day = currentDay {
                List {
                    Section("Hari program") {
                        TextField("Nama hari", text: day.title)
                        TextField(
                            "Deskripsi",
                            text: day.summary,
                            axis: .vertical
                        )
                        .lineLimit(2...6)
                        LabeledContent {
                            Text(
                                day.wrappedValue.scheduledDate,
                                format: dateFormat
                            )
                            .environment(
                                \.timeZone,
                                TimeZone(
                                    identifier: timeZoneIdentifier
                                ) ?? .gmt
                            )
                        } label: {
                            Label("Tanggal", systemImage: "calendar")
                        }
                    }

                    Section("Langkah") {
                        if day.wrappedValue.steps.isEmpty {
                            ContentUnavailableView(
                                "Belum ada langkah",
                                systemImage: "list.bullet.rectangle",
                                description: Text(
                                    "Tambahkan artikel, video, atau kuis."
                                )
                            )
                        } else {
                            ForEach(day.wrappedValue.steps) { stepValue in
                                let step = stepBinding(
                                    stepValue.id,
                                    day: day
                                )
                                NavigationLink {
                                    AdminStepContentEditorView(
                                        step: step,
                                        scheduledDate:
                                            day.wrappedValue.scheduledDate,
                                        timeZoneIdentifier:
                                            timeZoneIdentifier,
                                        onDuplicate: {
                                            applyStateMutation {
                                                state.duplicateStep(
                                                    stepValue.id,
                                                    in: dayID
                                                )
                                            }
                                        },
                                        onDelete: {
                                            applyStateMutation {
                                                state.removeStep(
                                                    stepValue.id,
                                                    from: dayID
                                                )
                                            }
                                        }
                                    )
                                    .singlePressNavigationBackButton()
                                } label: {
                                    AdminProgramStepRow(step: stepValue)
                                }
                                .accessibilityIdentifier(
                                    "admin.program.step.open."
                                        + "\(stepValue.id)"
                                )
                                .swipeActions(edge: .leading) {
                                    Button {
                                        applyStateMutation {
                                            state.duplicateStep(
                                                stepValue.id,
                                                in: dayID
                                            )
                                        }
                                    } label: {
                                        Label(
                                            "Duplikasi",
                                            systemImage:
                                                "plus.square.on.square"
                                        )
                                    }
                                    .tint(.appInfo)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        applyStateMutation {
                                            state.removeStep(
                                                stepValue.id,
                                                from: dayID
                                            )
                                        }
                                    } label: {
                                        Label(
                                            "Hapus",
                                            systemImage: "trash"
                                        )
                                    }
                                }
                            }
                            .onMove { offsets, destination in
                                applyStateMutation {
                                    state.moveStep(
                                        dayID: dayID,
                                        from: offsets,
                                        to: destination
                                    )
                                }
                            }
                        }

                        AdminAddContentButton(dayID: dayID) { kind in
                            applyStateMutation {
                                state.addStep(
                                    to: dayID,
                                    contentKind: kind
                                )
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.appBackground)
            } else {
                ContentUnavailableView(
                    "Hari tidak tersedia",
                    systemImage: "calendar.badge.exclamationmark"
                )
            }
        }
        .navigationTitle(
            "Hari ke-\(currentDay?.wrappedValue.dayNumber ?? 0)"
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .accessibilityIdentifier("admin.program.day.editor")
    }

    private var currentDay: Binding<AdminDayDraft>? {
        guard draft.days.contains(where: { $0.id == dayID }) else {
            return nil
        }
        return Binding(
            get: {
                draft.days.first(where: { $0.id == dayID })
                    ?? draft.days[0]
            },
            set: { updatedDay in
                guard let index = draft.days.firstIndex(where: {
                    $0.id == dayID
                }) else { return }
                draft.days[index] = updatedDay
                state.updateValidation()
            }
        )
    }

    private var dateFormat: Date.FormatStyle {
        .dateTime
            .weekday(.wide)
            .day()
            .month(.wide)
            .year()
            .locale(Locale(identifier: "id-ID"))
    }

    private func stepBinding(
        _ stepID: UUID,
        day: Binding<AdminDayDraft>
    ) -> Binding<AdminStepDraft> {
        Binding(
            get: {
                day.wrappedValue.steps.first(where: {
                    $0.id == stepID
                }) ?? day.wrappedValue.steps[0]
            },
            set: { updatedStep in
                guard let index = day.wrappedValue.steps.firstIndex(
                    where: { $0.id == stepID }
                ) else { return }
                day.wrappedValue.steps[index] = updatedStep
                state.updateValidation()
            }
        )
    }

    private func applyStateMutation(_ mutation: () -> Void) {
        mutation()
        if let updatedDraft = state.draft {
            draft = updatedDraft
        }
    }
}

@MainActor
private struct AdminProgramStepRow: View {
    let step: AdminStepDraft

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text("\(step.order). \(step.title)")
                    .font(AppTypography.cardTitle)
                Text(
                    "\(step.contentKind.adminTitle) · \(questionCount.formatted(.number.locale(Locale(identifier: "id-ID")))) pertanyaan"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
            }
        } icon: {
            Image(systemName: step.contentKind.systemImage)
                .foregroundStyle(Color.brandPrimary)
        }
    }

    private var questionCount: Int {
        step.quiz?.questions.count ?? 0
    }
}

@MainActor
struct AdminAddContentButton: View {
    let dayID: UUID
    let onAdd: (AdminStepContentKind) -> Void

    @State private var showsContentTypes = false

    var body: some View {
        Button {
            showsContentTypes = true
        } label: {
            Label("Tambah langkah", systemImage: "plus")
        }
        .confirmationDialog(
            "Pilih jenis langkah",
            isPresented: $showsContentTypes,
            titleVisibility: .visible
        ) {
            ForEach(AdminStepContentKind.allCases, id: \.self) { kind in
                Button(kind.adminTitle) {
                    onAdd(kind)
                }
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Langkah ditambahkan ke hari program ini.")
        }
        .accessibilityIdentifier("admin.editor.add-step.\(dayID)")
    }
}
