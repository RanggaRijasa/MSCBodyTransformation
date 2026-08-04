import SwiftUI

@MainActor
struct AdminProgramContentPlannerView: View {
    @Binding var draft: AdminProgramDraft
    let state: AdminProgramEditorState

    @State private var showsScheduleSyncConfirmation = false

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
                        SeamlessDeleteSwipeRow(id: day.id) {
                            applyStateMutation {
                                state.removeDay(day.id)
                            }
                        } content: {
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
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
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
private struct SeamlessDeleteSwipeRow<Content: View>: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @Environment(\.editMode)
    private var editMode

    @State private var currentOffset: CGFloat = 0
    @State private var dragStartOffset: CGFloat?

    let id: UUID
    let onDelete: () -> Void
    let content: Content

    private let actionWidth: CGFloat = 72

    init(
        id: UUID,
        onDelete: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.id = id
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Color.appDestructive

            content
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.xSmall)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 64,
                    alignment: .leading
                )
                .background(Color.appSecondaryBackground)
                .offset(x: visibleOffset)

            if visibleOffset < 0 {
                Button(role: .destructive, action: performDelete) {
                    Image(systemName: "trash")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .scaleEffect(0.72 + (0.28 * revealProgress))
                        .opacity(revealProgress)
                        .frame(width: actionWidth)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hapus")
                .accessibilityIdentifier("admin.program.day.delete")
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .simultaneousGesture(swipeGesture)
        .accessibilityAction(
            named: Text("Hapus"),
            performDelete
        )
        .onChange(of: editMode?.wrappedValue) { _, mode in
            guard mode == .active else { return }
            resetSwipeState()
        }
        .onChange(of: id) {
            resetSwipeState()
        }
    }

    private var visibleOffset: CGFloat {
        guard editMode?.wrappedValue != .active else { return 0 }
        return min(0, currentOffset)
    }

    private var revealProgress: CGFloat {
        min(max(-visibleOffset / actionWidth, 0), 1)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard editMode?.wrappedValue != .active,
                      abs(value.translation.width)
                        > abs(value.translation.height) else {
                    return
                }

                if dragStartOffset == nil {
                    dragStartOffset = currentOffset
                }
                currentOffset = min(
                    0,
                    (dragStartOffset ?? 0) + value.translation.width
                )
            }
            .onEnded { value in
                guard editMode?.wrappedValue != .active,
                      abs(value.translation.width)
                        > abs(value.translation.height) else {
                    dragStartOffset = nil
                    return
                }

                if value.translation.width < -(actionWidth * 2.4) {
                    dragStartOffset = nil
                    performDelete()
                    return
                }

                let startOffset = dragStartOffset ?? 0
                dragStartOffset = nil
                let projectedOffset =
                    startOffset + value.predictedEndTranslation.width
                settle(at: projectedOffset < -(actionWidth / 2)
                    ? -actionWidth
                    : 0)
            }
    }

    private func settle(at offset: CGFloat) {
        if reduceMotion {
            currentOffset = offset
        } else {
            withAnimation(
                .spring(response: 0.32, dampingFraction: 0.78)
            ) {
                currentOffset = offset
            }
        }
    }

    private func performDelete() {
        resetSwipeState()

        if reduceMotion {
            onDelete()
        } else {
            withAnimation(
                .spring(response: 0.28, dampingFraction: 0.86)
            ) {
                onDelete()
            }
        }
    }

    private func resetSwipeState() {
        currentOffset = 0
        dragStartOffset = nil
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

    @State private var copySourceDay: AdminDayDraft?

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

                    Section {
                        Button {
                            copySourceDay = day.wrappedValue
                        } label: {
                            Label(
                                "Salin isi ke hari lain",
                                systemImage: "doc.on.doc"
                            )
                        }
                        .disabled(
                            targetDays.isEmpty
                                || !hasCopyableContent(day.wrappedValue)
                        )
                        .accessibilityIdentifier(
                            "admin.program.day.copy-content"
                        )
                    } header: {
                        Text("Salin isi")
                    } footer: {
                        if targetDays.isEmpty {
                            Text(
                                "Tambahkan hari lain untuk menggunakan kembali isi hari ini."
                            )
                        } else if !hasCopyableContent(day.wrappedValue) {
                            Text(
                                "Tambahkan deskripsi atau langkah sebelum menyalin isi hari."
                            )
                        } else {
                            Text(
                                "Salin deskripsi dan seluruh langkah ke satu atau beberapa hari tujuan."
                            )
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
        .sheet(item: $copySourceDay) { sourceDay in
            AdminCopyDayContentSheet(
                sourceDay: sourceDay,
                targetDays: targetDays
            ) { targetDayIDs in
                applyStateMutation {
                    state.copyDayContent(
                        from: sourceDay.id,
                        to: targetDayIDs
                    )
                }
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

    private var targetDays: [AdminDayDraft] {
        draft.days
            .filter { $0.id != dayID }
            .sorted { $0.dayNumber < $1.dayNumber }
    }

    private func hasCopyableContent(_ day: AdminDayDraft) -> Bool {
        !day.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !day.steps.isEmpty
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
