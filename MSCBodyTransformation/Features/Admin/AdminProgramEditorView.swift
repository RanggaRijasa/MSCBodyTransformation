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
    let features: AdminFeatureContainer
    @State private var state: AdminProgramEditorState
    @State private var previewSize: PreviewSize = .small

    init(
        programID: UUID,
        features: AdminFeatureContainer
    ) {
        self.features = features
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
                editor(draft: draftBinding)
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
            ToolbarItemGroup(placement: .topBarTrailing) {
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
                    preconditionFailure("Draft harus tersedia saat editor tampil.")
                }
                return draft
            },
            set: {
                state.draft = $0
                state.updateValidation()
            }
        )
    }

    private func editor(
        draft: Binding<AdminProgramDraft>
    ) -> some View {
        VStack(spacing: 0) {
            Menu {
                ForEach(AdminProgramEditorState.Stage.allCases) { stage in
                    Button("\(stage.rawValue + 1). \(stage.title)") {
                        state.stage = stage
                    }
                }
            } label: {
                Label(
                    "\(state.stage.rawValue + 1). \(state.stage.title)",
                    systemImage: "list.number"
                )
            }
            .accessibilityIdentifier("admin.editor.stage")
            .padding(.horizontal, AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            stageContent(draft: draft)

            Divider()

            HStack {
                Button("Sebelumnya") {
                    moveStage(by: -1)
                }
                .disabled(state.stage == .basics)
                Spacer()
                Text(
                    "\(state.stage.rawValue + 1) dari "
                        + "\(AdminProgramEditorState.Stage.allCases.count)"
                )
                .font(AppTypography.label.monospacedDigit())
                .foregroundStyle(Color.appSecondaryText)
                Spacer()
                Button("Berikutnya") {
                    moveStage(by: 1)
                }
                .disabled(state.stage == .publish)
            }
            .padding(AppSpacing.medium)
            .background(Color.appSurface)
        }
        .background(Color.appBackground)
    }

    @ViewBuilder
    private func stageContent(
        draft: Binding<AdminProgramDraft>
    ) -> some View {
        switch state.stage {
        case .basics:
            basicsForm(draft: draft)
        case .dates:
            datesForm(draft: draft)
        case .scoring:
            scoringForm(draft: draft)
        case .days:
            daysForm(draft: draft)
        case .steps:
            stepsForm(draft: draft)
        case .preview:
            participantPreview(draft: draft.wrappedValue)
        case .publish:
            publishForm(draft: draft.wrappedValue)
        }
    }

    private func basicsForm(
        draft: Binding<AdminProgramDraft>
    ) -> some View {
        Form {
            Section("Identitas program") {
                TextField("Nama", text: draft.title)
                TextField(
                    "Deskripsi",
                    text: draft.summary,
                    axis: .vertical
                )
                .lineLimit(3...8)
                TextField(
                    "Referensi cover lokal",
                    text: optionalString(
                        root: draft,
                        keyPath: \.coverLocalReference
                    )
                )
            }
            Section("Pemeriksaan dan wellness") {
                Picker(
                    "Mode pemeriksaan",
                    selection: draft.verificationMode
                ) {
                    ForEach(
                        SubmissionVerificationMode.allCases,
                        id: \.self
                    ) { mode in
                        Text(mode.adminTitle).tag(mode)
                    }
                }
                TextField(
                    "Informasi wellness",
                    text: draft.wellnessDisclaimer,
                    axis: .vertical
                )
                .lineLimit(3...8)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }

    private func datesForm(
        draft: Binding<AdminProgramDraft>
    ) -> some View {
        Form {
            Section("Jadwal program") {
                DatePicker(
                    "Mulai",
                    selection: draft.startDate,
                    displayedComponents: .date
                )
                DatePicker(
                    "Selesai",
                    selection: draft.endDate,
                    displayedComponents: .date
                )
                Picker(
                    "Zona waktu IANA",
                    selection: draft.timeZoneIdentifier
                ) {
                    Text("Asia/Makassar").tag("Asia/Makassar")
                    Text("Asia/Jakarta").tag("Asia/Jakarta")
                    Text("Asia/Jayapura").tag("Asia/Jayapura")
                }
                LabeledContent(
                    "Durasi",
                    value: "\(draft.wrappedValue.durationInDays.formatted(.number.locale(Locale(identifier: "id-ID")))) hari"
                )
            }
            Section("Jendela timbang") {
                Stepper(
                    "Berat awal: \(draft.wrappedValue.initialWeighInWindowHours.formatted(.number.locale(Locale(identifier: "id-ID")))) jam",
                    value: draft.initialWeighInWindowHours,
                    in: 1...168
                )
                Stepper(
                    "Berat akhir: \(draft.wrappedValue.finalWeighInWindowHours.formatted(.number.locale(Locale(identifier: "id-ID")))) jam",
                    value: draft.finalWeighInWindowHours,
                    in: 1...168
                )
            }
            Section {
                Button("Buat hari dari rentang tanggal") {
                    state.generateDays()
                }
                .accessibilityIdentifier("admin.editor.generate-days")
            } footer: {
                Text(
                    "Pembuatan ulang mengganti daftar hari yang belum disimpan."
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }

    private func scoringForm(
        draft: Binding<AdminProgramDraft>
    ) -> some View {
        Form {
            Section("Poin") {
                TextField(
                    "Poin per kilogram",
                    value: draft.weightPointsPerKilogram,
                    format: .number.locale(Locale(identifier: "id-ID"))
                )
                .keyboardType(.decimalPad)
                Picker(
                    "Pemeriksaan default",
                    selection: draft.verificationMode
                ) {
                    ForEach(
                        SubmissionVerificationMode.allCases,
                        id: \.self
                    ) { mode in
                        Text(mode.adminTitle).tag(mode)
                    }
                }
            }
            Section("Visibilitas") {
                Picker(
                    "Langkah lampau",
                    selection: draft.pastStepPolicy
                ) {
                    ForEach(PastStepPolicy.allCases, id: \.self) {
                        Text($0.adminTitle).tag($0)
                    }
                }
                Picker(
                    "Langkah mendatang",
                    selection: draft.futureStepPolicy
                ) {
                    ForEach(FutureStepPolicy.allCases, id: \.self) {
                        Text($0.adminTitle).tag($0)
                    }
                }
            }
            Section("Pratinjau aturan") {
                Text(
                    "Setiap kilogram penurunan yang memenuhi aturan "
                        + "memberi \(draft.wrappedValue.weightPointsPerKilogram.formatted(.number.locale(Locale(identifier: "id-ID")))) poin."
                )
                Label(
                    "Skor ini hanya pratinjau lokal. Layanan pusat menjadi "
                        + "sumber resmi pada fase integrasi.",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(Color.appWarning)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }

    private func daysForm(
        draft: Binding<AdminProgramDraft>
    ) -> some View {
        List {
            if draft.wrappedValue.days.isEmpty {
                ContentUnavailableView(
                    "Belum ada hari",
                    systemImage: "calendar.badge.plus",
                    description: Text(
                        "Buat hari dari rentang tanggal terlebih dahulu."
                    )
                )
            } else {
                ForEach(
                    draft.wrappedValue.days.indices,
                    id: \.self
                ) { index in
                    let day = dayBinding(index, root: draft)
                    Section("Hari ke-\(day.wrappedValue.dayNumber)") {
                        TextField("Judul hari", text: day.title)
                        TextField(
                            "Deskripsi",
                            text: day.summary,
                            axis: .vertical
                        )
                        DatePicker(
                            "Tanggal",
                            selection: day.scheduledDate,
                            displayedComponents: .date
                        )
                        HStack {
                            Button("Duplikasi") {
                                state.duplicateDay(day.wrappedValue.id)
                            }
                            Spacer()
                            Button("Hapus", role: .destructive) {
                                state.removeDay(day.wrappedValue.id)
                            }
                        }
                    }
                }
                .onMove(perform: state.moveDay)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
    }

    private func stepsForm(
        draft: Binding<AdminProgramDraft>
    ) -> some View {
        List {
            if draft.wrappedValue.days.isEmpty {
                ContentUnavailableView(
                    "Hari belum dibuat",
                    systemImage: "list.number",
                    description: Text(
                        "Buat hari sebelum menambahkan langkah."
                    )
                )
            } else {
                ForEach(
                    draft.wrappedValue.days.indices,
                    id: \.self
                ) { dayIndex in
                    let day = dayBinding(dayIndex, root: draft)
                    Section(day.wrappedValue.title) {
                        ForEach(
                            day.wrappedValue.steps.indices,
                            id: \.self
                        ) { stepIndex in
                            stepEditor(
                                step: stepBinding(
                                    stepIndex,
                                    day: day
                                ),
                                dayID: day.wrappedValue.id
                            )
                        }
                        .onMove { offsets, destination in
                            state.moveStep(
                                dayID: day.wrappedValue.id,
                                from: offsets,
                                to: destination
                            )
                        }
                        Button("Tambah langkah") {
                            state.addStep(to: day.wrappedValue.id)
                        }
                        .accessibilityIdentifier(
                            "admin.editor.add-step.\(day.wrappedValue.id)"
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
    }

    private func stepEditor(
        step: Binding<AdminStepDraft>,
        dayID: UUID
    ) -> some View {
        DisclosureGroup(
            "\(step.wrappedValue.order). \(step.wrappedValue.title)"
        ) {
            TextField("Judul langkah", text: step.title)
            TextField(
                "Petunjuk",
                text: step.instructions,
                axis: .vertical
            )
            TextField(
                "Poin",
                value: step.points,
                format: .number.locale(Locale(identifier: "id-ID"))
            )
            .keyboardType(.numberPad)
            Toggle("Langkah aktif", isOn: step.isActive)
            Toggle("Minta foto", isOn: step.requiresPhoto)
            if step.wrappedValue.requiresPhoto {
                Toggle("Foto wajib", isOn: step.isPhotoRequired)
            }
            Toggle("Minta jawaban teks", isOn: step.requiresTextAnswer)
            if step.wrappedValue.requiresTextAnswer {
                Toggle(
                    "Jawaban teks wajib",
                    isOn: step.isTextAnswerRequired
                )
            }
            Picker(
                "Mode pemeriksaan",
                selection: step.verificationMode
            ) {
                ForEach(
                    SubmissionVerificationMode.allCases,
                    id: \.self
                ) { mode in
                    Text(mode.adminTitle).tag(mode)
                }
            }
            Toggle(
                "Tambahkan media",
                isOn: Binding(
                    get: { step.wrappedValue.mediaKind != nil },
                    set: { enabled in
                        step.wrappedValue.mediaKind = enabled
                            ? .image
                            : nil
                        if !enabled {
                            step.wrappedValue.localMediaReference = nil
                        }
                    }
                )
            )
            if step.wrappedValue.mediaKind != nil {
                Picker(
                    "Jenis media",
                    selection: Binding(
                        get: { step.wrappedValue.mediaKind ?? .image },
                        set: { step.wrappedValue.mediaKind = $0 }
                    )
                ) {
                    ForEach(
                        StepInstructionMediaKind.allCases,
                        id: \.self
                    ) { kind in
                        Text(kind.adminTitle).tag(kind)
                    }
                }
                TextField(
                    "Referensi media lokal",
                    text: optionalString(
                        root: step,
                        keyPath: \.localMediaReference
                    )
                )
            }
            Button("Hapus langkah", role: .destructive) {
                state.removeStep(step.wrappedValue.id, from: dayID)
            }
        }
    }

    private func participantPreview(
        draft: AdminProgramDraft
    ) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                Picker("Ukuran pratinjau", selection: $previewSize) {
                    ForEach(PreviewSize.allCases) {
                        Text($0.title).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text(draft.title)
                        .font(AppTypography.screenTitle)
                    Text(draft.summary)
                        .font(AppTypography.body)
                        .foregroundStyle(Color.appSecondaryText)

                    if let firstDay = draft.days.first {
                        SectionHeader(
                            title: "Hari ini • Hari ke-\(firstDay.dayNumber)",
                            subtitle: LocalizedStringKey(firstDay.title)
                        )
                        ForEach(firstDay.steps.filter(\.isActive)) { step in
                            StepRow(
                                title: LocalizedStringKey(step.title),
                                detail: step.instructions,
                                points: step.points,
                                statusTitle: "Tersedia",
                                statusKind: .success
                            )
                        }
                        if let step = firstDay.steps.first {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Detail langkah")
                                    .font(AppTypography.sectionTitle)
                                Text(step.title)
                                    .font(AppTypography.cardTitle)
                                Text(step.instructions)
                                if step.requiresPhoto {
                                    Label(
                                        step.isPhotoRequired
                                            ? "Bukti foto wajib"
                                            : "Bukti foto opsional",
                                        systemImage: "camera"
                                    )
                                }
                            }
                            .padding(AppSpacing.medium)
                            .background(
                                Color.appSurface,
                                in: RoundedRectangle(
                                    cornerRadius: AppRadius.medium
                                )
                            )
                        }
                    } else {
                        ContentUnavailableView(
                            "Hari belum dibuat",
                            systemImage: "calendar"
                        )
                    }

                    Label(
                        "Hari mendatang terkunci sesuai jadwal.",
                        systemImage: "lock.fill"
                    )
                    .foregroundStyle(Color.appSecondaryText)

                    Text(
                        "Poin total terdiri dari poin langkah yang "
                            + "disetujui, poin penurunan berat badan, "
                            + "dan penyesuaian terpisah."
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                }
                .padding(AppSpacing.medium)
                .frame(
                    maxWidth: previewSize == .small ? 390 : 720,
                    alignment: .leading
                )
                .background(
                    Color.appSecondaryBackground,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )
                .frame(maxWidth: .infinity)
            }
            .padding(AppSpacing.medium)
        }
        .background(Color.appBackground)
        .accessibilityIdentifier("admin.editor.preview")
    }

    private func publishForm(
        draft: AdminProgramDraft
    ) -> some View {
        Form {
            Section("Ringkasan validasi") {
                if state.issues.isEmpty {
                    Label(
                        "Draft siap untuk simulasi publish.",
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
            Section("Ringkasan program") {
                LabeledContent("Nama", value: draft.title)
                LabeledContent(
                    "Hari",
                    value: draft.days.count.formatted(
                        .number.locale(Locale(identifier: "id-ID"))
                    )
                )
                LabeledContent(
                    "Langkah aktif",
                    value: draft.days
                        .flatMap(\.steps)
                        .filter(\.isActive)
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
                        : "Simulasikan publikasi"
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
                    "Tindakan ini hanya mengubah status mock dan mencatat "
                        + "audit lokal. Tidak ada data yang dikirim."
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }

    private func dayBinding(
        _ index: Int,
        root: Binding<AdminProgramDraft>
    ) -> Binding<AdminDayDraft> {
        Binding(
            get: { root.wrappedValue.days[index] },
            set: {
                root.wrappedValue.days[index] = $0
                state.updateValidation()
            }
        )
    }

    private func stepBinding(
        _ index: Int,
        day: Binding<AdminDayDraft>
    ) -> Binding<AdminStepDraft> {
        Binding(
            get: { day.wrappedValue.steps[index] },
            set: {
                day.wrappedValue.steps[index] = $0
                state.updateValidation()
            }
        )
    }

    private func optionalString<Root>(
        root: Binding<Root>,
        keyPath: WritableKeyPath<Root, String?>
    ) -> Binding<String> {
        Binding(
            get: { root.wrappedValue[keyPath: keyPath] ?? "" },
            set: {
                root.wrappedValue[keyPath: keyPath] = $0.isEmpty ? nil : $0
            }
        )
    }

    private func moveStage(by offset: Int) {
        let value = state.stage.rawValue + offset
        guard let stage = AdminProgramEditorState.Stage(rawValue: value) else {
            return
        }
        state.stage = stage
    }
}

private extension AdminProgramEditorView {
    enum PreviewSize: String, CaseIterable, Identifiable {
        case small
        case large

        var id: String { rawValue }
        var title: String {
            switch self {
            case .small: "Perangkat kecil"
            case .large: "Perangkat besar"
            }
        }
    }
}
