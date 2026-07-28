import SwiftUI

@MainActor
struct AdminStepContentEditorView: View {
    @Binding var step: AdminStepDraft
    let scheduledDate: Date
    let timeZoneIdentifier: String
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showsDeleteConfirmation = false

    var body: some View {
        Form {
            Section("Informasi langkah") {
                TextField("Nama langkah", text: $step.title)
                LabeledContent {
                    Text(
                        scheduledDate,
                        format: .dateTime
                            .day()
                            .month(.wide)
                            .year()
                            .locale(Locale(identifier: "id-ID"))
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
                Picker("Jenis langkah", selection: $step.contentKind) {
                    ForEach(
                        AdminStepContentKind.allCases,
                        id: \.self
                    ) { kind in
                        Label(
                            kind.adminTitle,
                            systemImage: kind.systemImage
                        )
                        .tag(kind)
                    }
                }
            }

            contentSection

            Section {
                NavigationLink {
                    AdminStepQuestionListView(
                        questions: questionsBinding,
                        stepID: step.id
                    )
                    .singlePressNavigationBackButton()
                } label: {
                    LabeledContent {
                        Text(
                            questionCount,
                            format: .number.locale(
                                Locale(identifier: "id-ID")
                            )
                        )
                    } label: {
                        Label(
                            "Pertanyaan",
                            systemImage: "questionmark.bubble"
                        )
                    }
                }
                .accessibilityIdentifier("admin.step.questions.open")
            } header: {
                Text("Pertanyaan peserta")
            } footer: {
                Text(
                    step.contentKind == .quiz
                        ? "Langkah kuis memerlukan minimal satu pertanyaan."
                        : "Pertanyaan pendamping bersifat opsional."
                )
            }

            Section {
                Toggle("Langkah aktif", isOn: $step.isActive)
                Toggle("Minta bukti foto", isOn: $step.requiresPhoto)
                if step.requiresPhoto {
                    Toggle(
                        "Bukti foto wajib",
                        isOn: $step.isPhotoRequired
                    )
                }
                Picker(
                    "Mode pemeriksaan",
                    selection: $step.verificationMode
                ) {
                    ForEach(
                        SubmissionVerificationMode.allCases,
                        id: \.self
                    ) { mode in
                        Text(mode.adminTitle).tag(mode)
                    }
                }
            } header: {
                Text("Penyelesaian")
            } footer: {
                Text(
                    "Gunakan daftar Pertanyaan untuk meminta jawaban "
                        + "teks, angka, pilihan, atau file."
                )
            }

            Section("Poin") {
                TextField(
                    "Poin langkah",
                    value: $step.points,
                    format: .number.locale(Locale(identifier: "id-ID"))
                )
                .keyboardType(.numberPad)
            }

            Section {
                Button(action: onDuplicate) {
                    Label(
                        "Duplikasi langkah",
                        systemImage: "plus.square.on.square"
                    )
                }
                Button(role: .destructive) {
                    showsDeleteConfirmation = true
                } label: {
                    Label("Hapus langkah", systemImage: "trash")
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle(step.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: step.title) {
            step.quiz?.title = step.title
        }
        .onChange(of: step.contentKind) {
            synchronizeContentKind()
        }
        .confirmationDialog(
            "Hapus langkah ini?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Hapus langkah", role: .destructive) {
                dismiss()
                onDelete()
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text(
                "Semua pertanyaan di dalam langkah ini juga akan dihapus."
            )
        }
        .accessibilityIdentifier("admin.step.editor")
    }

    @ViewBuilder
    private var contentSection: some View {
        switch step.contentKind {
        case .article:
            Section("Artikel") {
                TextField(
                    "Tulis petunjuk atau isi artikel",
                    text: $step.instructions,
                    axis: .vertical
                )
                .lineLimit(6...16)
            }
        case .video:
            Section {
                TextField(
                    "Referensi video lokal",
                    text: optionalMediaReference
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                TextField(
                    "Deskripsi video",
                    text: $step.instructions,
                    axis: .vertical
                )
                .lineLimit(3...8)

                Toggle(
                    "Wajib ditonton sampai selesai",
                    isOn: $step.isVideoRequiredToWatch
                )
                Toggle(
                    "Putar otomatis",
                    isOn: $step.isVideoAutoplayEnabled
                )
            } header: {
                Text("Video")
            } footer: {
                Text(
                    "Video memakai referensi lokal selama fase demo."
                )
            }
        case .quiz:
            Section("Petunjuk kuis") {
                TextField(
                    "Jelaskan cara mengisi kuis",
                    text: $step.instructions,
                    axis: .vertical
                )
                .lineLimit(3...8)
            }
        }
    }

    private var questionCount: Int {
        step.quiz?.questions.count ?? 0
    }

    private var questionsBinding: Binding<[AdminQuizQuestionDraft]> {
        Binding(
            get: { step.quiz?.questions ?? [] },
            set: { questions in
                if step.quiz == nil {
                    step.quiz = AdminQuizDraft(
                        title: step.title,
                        questions: questions
                    )
                } else {
                    step.quiz?.title = step.title
                    step.quiz?.questions = questions
                }
            }
        )
    }

    private var optionalMediaReference: Binding<String> {
        Binding(
            get: { step.localMediaReference ?? "" },
            set: {
                step.localMediaReference = $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty ? nil : $0
            }
        )
    }

    private func synchronizeContentKind() {
        switch step.contentKind {
        case .article, .quiz:
            step.mediaKind = nil
            step.isVideoRequiredToWatch = false
            step.isVideoAutoplayEnabled = false
        case .video:
            step.mediaKind = .video
        }
        if step.contentKind == .quiz, step.quiz == nil {
            step.quiz = AdminQuizDraft(
                title: step.title,
                questions: []
            )
        }
    }
}

@MainActor
private struct AdminStepQuestionListView: View {
    @Binding var questions: [AdminQuizQuestionDraft]
    let stepID: UUID

    var body: some View {
        List {
            Section {
                if questions.isEmpty {
                    ContentUnavailableView(
                        "Belum ada pertanyaan",
                        systemImage: "questionmark.bubble",
                        description: Text(
                            "Tambahkan pertanyaan atau teks penjelas."
                        )
                    )
                } else {
                    ForEach($questions) { $question in
                        NavigationLink {
                            AdminQuestionEditorView(
                                question: $question
                            )
                            .singlePressNavigationBackButton()
                        } label: {
                            AdminQuestionRow(question: question)
                        }
                        .accessibilityIdentifier(
                            "admin.program.question.open.\(question.id)"
                        )
                    }
                    .onMove(perform: moveQuestions)
                    .onDelete(perform: deleteQuestions)
                }
            }

            Section {
                Menu {
                    Section("Jenis pertanyaan") {
                        addButton(.shortAnswer)
                        addButton(.longAnswer)
                        addButton(.number)
                        addButton(.singleChoice)
                        addButton(.multipleChoice)
                        addButton(.imageChoice)
                        addButton(.fileUpload)
                    }
                    Section("Elemen penjelas") {
                        addButton(.heading)
                        addButton(.text)
                    }
                } label: {
                    Label("Tambah pertanyaan", systemImage: "plus")
                }
                .accessibilityIdentifier(
                    "admin.program.question.add.\(stepID)"
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Pertanyaan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .accessibilityIdentifier("admin.step.questions")
    }

    private func addButton(
        _ kind: AdminQuizQuestionKind
    ) -> some View {
        Button {
            addQuestion(kind)
        } label: {
            Label(kind.adminTitle, systemImage: kind.systemImage)
        }
    }

    private func addQuestion(_ kind: AdminQuizQuestionKind) {
        let order = questions.count + 1
        questions.append(
            AdminQuizQuestionDraft(
                id: availableQuestionIdentifier(startingAt: order),
                order: order,
                kind: kind,
                prompt: "",
                isRequired: !kind.isLayoutElement,
                options: kind.acceptsOptions ? ["", ""] : []
            )
        )
    }

    private func availableQuestionIdentifier(
        startingAt value: Int
    ) -> UUID {
        var discriminator = value + 1_000
        while true {
            let identifier = AdminProgramDraftValidator().childIdentifier(
                parent: stepID,
                discriminator: discriminator
            )
            if !questions.contains(where: { $0.id == identifier }) {
                return identifier
            }
            discriminator += 1
        }
    }

    private func moveQuestions(
        from offsets: IndexSet,
        to destination: Int
    ) {
        questions.move(fromOffsets: offsets, toOffset: destination)
        normalizeQuestionOrder()
    }

    private func deleteQuestions(at offsets: IndexSet) {
        questions.remove(atOffsets: offsets)
        normalizeQuestionOrder()
    }

    private func normalizeQuestionOrder() {
        for index in questions.indices {
            questions[index].order = index + 1
        }
    }
}

@MainActor
private struct AdminQuestionRow: View {
    let question: AdminQuizQuestionDraft

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(
                    question.prompt.isEmpty
                        ? "Pertanyaan \(question.order)"
                        : question.prompt
                )
                .font(AppTypography.cardTitle)
                Text(question.kind.adminTitle)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }
        } icon: {
            Image(systemName: question.kind.systemImage)
                .foregroundStyle(Color.brandPrimary)
        }
    }
}

@MainActor
private struct AdminQuestionEditorView: View {
    @Binding var question: AdminQuizQuestionDraft

    var body: some View {
        Form {
            Section("Pertanyaan") {
                Picker("Jenis", selection: $question.kind) {
                    ForEach(
                        AdminQuizQuestionKind.allCases,
                        id: \.self
                    ) { kind in
                        Label(
                            kind.adminTitle,
                            systemImage: kind.systemImage
                        )
                        .tag(kind)
                    }
                }
                TextField(
                    question.kind.isLayoutElement
                        ? "Isi elemen"
                        : "Isi pertanyaan",
                    text: $question.prompt,
                    axis: .vertical
                )
                .lineLimit(2...8)
                if !question.kind.isLayoutElement {
                    Toggle(
                        "Wajib dijawab",
                        isOn: $question.isRequired
                    )
                }
            }

            if question.kind.acceptsOptions {
                Section("Pilihan jawaban") {
                    ForEach(
                        question.options.indices,
                        id: \.self
                    ) { index in
                        HStack {
                            TextField(
                                "Pilihan \(index + 1)",
                                text: optionBinding(index)
                            )
                            Button(role: .destructive) {
                                question.options.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .accessibilityLabel(
                                "Hapus pilihan \(index + 1)"
                            )
                        }
                    }
                    Button {
                        question.options.append("")
                    } label: {
                        Label("Tambah pilihan", systemImage: "plus")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Pertanyaan \(question.order)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: question.kind) {
            if question.kind.isLayoutElement {
                question.isRequired = false
            } else if question.kind.acceptsOptions,
                      question.options.count < 2 {
                question.options = ["", ""]
            }
        }
        .accessibilityIdentifier("admin.question.editor")
    }

    private func optionBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { question.options[index] },
            set: { question.options[index] = $0 }
        )
    }
}
