import SwiftUI

@MainActor
struct AdminProgramInformationView: View {
    @Binding var draft: AdminProgramDraft

    var body: some View {
        Form {
            Section("Identitas program") {
                TextField("Nama", text: $draft.title)
                TextField("Kategori", text: $draft.category)
                TextField(
                    "Deskripsi",
                    text: $draft.summary,
                    axis: .vertical
                )
                .lineLimit(3...8)
                TextField(
                    "Harga",
                    value: $draft.price,
                    format: .number.locale(Locale(identifier: "id-ID"))
                )
                .keyboardType(.numberPad)
            }

            Section {
                Picker(
                    "Jenis cover",
                    selection: $draft.coverMediaKind
                ) {
                    ForEach(AdminCoverMediaKind.allCases, id: \.self) {
                        kind in
                        Text(kind.adminTitle).tag(kind)
                    }
                }
                TextField(
                    draft.coverMediaKind == .image
                        ? "Referensi gambar lokal"
                        : "Referensi video lokal",
                    text: optionalCoverReference
                )
                TextField(
                    "Teks alternatif cover",
                    text: $draft.coverAlternativeText,
                    axis: .vertical
                )
                .lineLimit(2...5)
            } header: {
                Text("Cover program")
            } footer: {
                Text(
                    "Jelaskan isi cover secara singkat untuk pengguna "
                        + "VoiceOver."
                )
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Info program")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.info")
    }

    private var optionalCoverReference: Binding<String> {
        Binding(
            get: { draft.coverLocalReference ?? "" },
            set: {
                draft.coverLocalReference = $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty ? nil : $0
            }
        )
    }
}

@MainActor
struct AdminProgramScheduleView: View {
    @Binding var draft: AdminProgramDraft

    var body: some View {
        Form {
            Section {
                Label(
                    "Jadwal dikunci setelah peserta bergabung.",
                    systemImage: "info.circle"
                )
                .foregroundStyle(Color.appInfo)
            }

            Section {
                Picker("Pola program", selection: $draft.pace) {
                    ForEach(AdminProgramPace.allCases, id: \.self) { pace in
                        Text(pace.adminTitle).tag(pace)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Pola penyelesaian")
            } footer: {
                Text(
                    draft.pace == .scheduled
                        ? "Langkah tersedia pada hari yang ditentukan."
                        : "Peserta dapat memulai sesuai waktunya."
                )
            }

            Section("Jadwal program") {
                Picker("Jenis durasi", selection: $draft.durationMode) {
                    ForEach(
                        AdminProgramDurationMode.allCases,
                        id: \.self
                    ) { mode in
                        Text(mode.adminTitle).tag(mode)
                    }
                }

                DatePicker(
                    draft.durationMode == .fixedDuration
                        ? "Tanggal acuan"
                        : "Mulai",
                    selection: $draft.startDate,
                    displayedComponents: .date
                )

                if draft.durationMode == .specificDates {
                    DatePicker(
                        "Selesai",
                        selection: $draft.endDate,
                        displayedComponents: .date
                    )
                } else {
                    Stepper(
                        "Durasi: \(draft.fixedDurationDays.formatted(.number.locale(Locale(identifier: "id-ID")))) hari",
                        value: $draft.fixedDurationDays,
                        in: 1...365
                    )
                }

                Picker(
                    "Zona waktu",
                    selection: $draft.timeZoneIdentifier
                ) {
                    Text("WITA · Makassar").tag("Asia/Makassar")
                    Text("WIB · Jakarta").tag("Asia/Jakarta")
                    Text("WIT · Jayapura").tag("Asia/Jayapura")
                }
            }

            Section("Peserta") {
                Picker("Akses program", selection: $draft.access) {
                    ForEach(AdminProgramAccess.allCases, id: \.self) {
                        access in
                        Text(access.adminTitle).tag(access)
                    }
                }
                Text(draft.access.adminDescription)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)

                Toggle(
                    "Batasi jumlah peserta",
                    isOn: participantLimitToggle
                )
                if draft.participantLimit != nil {
                    Stepper(
                        "Maksimal \(draft.participantLimit?.formatted(.number.locale(Locale(identifier: "id-ID"))) ?? "0") peserta",
                        value: participantLimitValue,
                        in: 1...10_000
                    )
                }
            }

            Section("Jendela timbang") {
                Stepper(
                    "Berat awal: \(draft.initialWeighInWindowHours.formatted(.number.locale(Locale(identifier: "id-ID")))) jam",
                    value: $draft.initialWeighInWindowHours,
                    in: 1...168
                )
                Stepper(
                    "Berat akhir: \(draft.finalWeighInWindowHours.formatted(.number.locale(Locale(identifier: "id-ID")))) jam",
                    value: $draft.finalWeighInWindowHours,
                    in: 1...168
                )
            }

            Section {
                Label(
                    "Buka Konten setelah mengubah jadwal untuk "
                        + "menyinkronkan hari tanpa menghapus isi.",
                    systemImage: "arrow.triangle.2.circlepath"
                )
                .foregroundStyle(Color.appSecondaryText)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Jadwal dan peserta")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.schedule")
    }

    private var participantLimitToggle: Binding<Bool> {
        Binding(
            get: { draft.participantLimit != nil },
            set: { isLimited in
                draft.participantLimit = isLimited ? 50 : nil
            }
        )
    }

    private var participantLimitValue: Binding<Int> {
        Binding(
            get: { draft.participantLimit ?? 50 },
            set: { draft.participantLimit = $0 }
        )
    }
}

@MainActor
struct AdminProgramRulesView: View {
    @Binding var draft: AdminProgramDraft

    var body: some View {
        Form {
            Section("Poin dan pemeriksaan") {
                TextField(
                    "Poin per kilogram",
                    value: $draft.weightPointsPerKilogram,
                    format: .number.locale(Locale(identifier: "id-ID"))
                )
                .keyboardType(.decimalPad)
                Picker(
                    "Pemeriksaan default",
                    selection: $draft.verificationMode
                ) {
                    ForEach(
                        SubmissionVerificationMode.allCases,
                        id: \.self
                    ) { mode in
                        Text(mode.adminTitle).tag(mode)
                    }
                }
            }

            Section("Akses hari program") {
                Picker(
                    "Langkah lampau",
                    selection: $draft.pastStepPolicy
                ) {
                    ForEach(PastStepPolicy.allCases, id: \.self) {
                        Text($0.adminTitle).tag($0)
                    }
                }
                Picker(
                    "Langkah mendatang",
                    selection: $draft.futureStepPolicy
                ) {
                    ForEach(FutureStepPolicy.allCases, id: \.self) {
                        Text($0.adminTitle).tag($0)
                    }
                }
            }

            Section("Informasi wellness") {
                TextField(
                    "Informasi untuk peserta",
                    text: $draft.wellnessDisclaimer,
                    axis: .vertical
                )
                .lineLimit(3...8)
            }

            Section("Ringkasan aturan") {
                Text(
                    "Setiap kilogram penurunan yang memenuhi aturan "
                        + "memberi \(draft.weightPointsPerKilogram.formatted(.number.locale(Locale(identifier: "id-ID")))) poin."
                )
                Label(
                    "Skor ini masih berupa pratinjau lokal.",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(Color.appWarning)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Aturan dan poin")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.rules")
    }
}

@MainActor
struct AdminProgramParticipantPreviewView: View {
    let draft: AdminProgramDraft

    @State private var previewSize: PreviewSize = .small

    var body: some View {
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
                            VStack(
                                alignment: .leading,
                                spacing: AppSpacing.xSmall
                            ) {
                                StepRow(
                                    title: LocalizedStringKey(step.title),
                                    detail: step.instructions,
                                    points: step.points,
                                    statusTitle: "Tersedia",
                                    statusKind: .success
                                )
                                if let questions = step.quiz?.questions,
                                   !questions.isEmpty {
                                    Label(
                                        "\(questions.count.formatted(.number.locale(Locale(identifier: "id-ID")))) pertanyaan",
                                        systemImage: "questionmark.bubble"
                                    )
                                    .font(AppTypography.secondary)
                                    .foregroundStyle(
                                        Color.appSecondaryText
                                    )
                                    ForEach(questions.prefix(3)) { question in
                                        Text("• \(question.prompt)")
                                            .font(AppTypography.secondary)
                                    }
                                }
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "Hari belum dibuat",
                            systemImage: "calendar"
                        )
                    }

                    Label(
                        "Hari mendatang mengikuti jadwal program.",
                        systemImage: "lock.fill"
                    )
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
        .navigationTitle("Pratinjau peserta")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.editor.preview")
    }
}

private extension AdminProgramParticipantPreviewView {
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

@MainActor
struct AdminProgramPublishView: View {
    let draft: AdminProgramDraft
    let state: AdminProgramEditorState

    var body: some View {
        Form {
            Section("Ringkasan validasi") {
                if state.issues.isEmpty {
                    Label(
                        "Draft siap untuk simulasi publikasi.",
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
                    "Simulasi hanya mengubah status mock dan mencatat "
                        + "audit lokal."
                )
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Tinjau dan publikasi")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("admin.program.publish")
    }
}
