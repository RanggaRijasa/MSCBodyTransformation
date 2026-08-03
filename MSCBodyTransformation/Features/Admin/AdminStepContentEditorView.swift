import PhotosUI
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

            if step.contentKind == .form || step.contentKind == .quiz {
                Section {
                    NavigationLink {
                        AdminStepQuestionListView(
                            questions: questionsBinding,
                            stepID: step.id,
                            isQuiz: step.contentKind == .quiz
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
                            ? "Kuis memerlukan pertanyaan objektif dan "
                                + "jawaban benar."
                            : "Semua pertanyaan interaktif wajib dijawab."
                    )
                }
            }

            Section {
                Toggle("Langkah aktif", isOn: $step.isActive)
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
                    "Jawaban subjektif dan unggahan foto dapat diperiksa "
                        + "Coach. Kuis tetap dinilai otomatis."
                )
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
        case .form:
            Section("Petunjuk form") {
                TextField(
                    "Jelaskan informasi yang perlu diisi",
                    text: $step.instructions,
                    axis: .vertical
                )
                .lineLimit(3...8)
            }
        case .initialWeighIn:
            Section("Timbang awal") {
                TextField(
                    "Petunjuk timbang awal",
                    text: $step.instructions,
                    axis: .vertical
                )
                .lineLimit(3...8)
                Text("Berat disimpan khusus untuk enrollment ini.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case .dailyWeighIn:
            Section("Timbang harian") {
                TextField(
                    "Petunjuk timbang harian",
                    text: $step.instructions,
                    axis: .vertical
                )
                .lineLimit(3...8)
                Text(
                    "Berat dicatat untuk memantau progres dan tidak "
                        + "menambah poin penurunan berat secara terpisah."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        case .finalWeighIn:
            Section("Timbang akhir") {
                TextField(
                    "Petunjuk timbang akhir",
                    text: $step.instructions,
                    axis: .vertical
                )
                .lineLimit(3...8)
                Text(
                    "Timbang akhir baru dapat dikirim setelah timbang awal."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
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
        case .article, .form, .quiz, .initialWeighIn, .dailyWeighIn,
             .finalWeighIn:
            step.mediaKind = nil
            step.isVideoRequiredToWatch = false
            step.isVideoAutoplayEnabled = false
        case .video:
            step.mediaKind = .video
        }
        if (step.contentKind == .quiz || step.contentKind == .form),
           step.quiz == nil {
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
    let isQuiz: Bool

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
                                question: $question,
                                isQuiz: isQuiz
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
                        addButton(.photoUpload)
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
        let questionID = availableQuestionIdentifier(startingAt: order)
        let options = kind.acceptsOptions ? ["", ""] : []
        let optionIDs = options.indices.map {
            AdminProgramDraftValidator().childIdentifier(
                parent: questionID,
                discriminator: $0 + 1
            )
        }
        questions.append(
            AdminQuizQuestionDraft(
                id: questionID,
                order: order,
                kind: kind,
                prompt: "",
                options: options,
                optionIDs: optionIDs,
                answerKey: isQuiz && objective(kind)
                    ? ProgramQuestionAnswerKey()
                    : nil
            )
        )
    }

    private func objective(_ kind: AdminQuizQuestionKind) -> Bool {
        switch kind {
        case .number, .singleChoice, .multipleChoice, .imageChoice:
            true
        case .shortAnswer, .longAnswer, .photoUpload, .heading, .text:
            false
        }
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
    let isQuiz: Bool

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
                    Label("Wajib dijawab", systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
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
                                if question.optionIDs.indices.contains(index) {
                                    let removedID =
                                        question.optionIDs.remove(at: index)
                                    question.answerKey?.selectedOptionIDs
                                        .removeAll { $0 == removedID }
                                }
                                if question.optionMediaReferences.indices
                                    .contains(index) {
                                    question.optionMediaReferences.remove(
                                        at: index
                                    )
                                }
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
                        question.optionIDs.append(
                            AdminProgramDraftValidator().childIdentifier(
                                parent: question.id,
                                discriminator: question.optionIDs.count + 1
                            )
                        )
                        question.optionMediaReferences.append(nil)
                    } label: {
                        Label("Tambah pilihan", systemImage: "plus")
                    }
                }
                if question.kind == .imageChoice {
                    Section("Gambar pilihan") {
                        ForEach(
                            question.options.indices,
                            id: \.self
                        ) { index in
                            AdminImageOptionPicker(
                                title: question.options[index].isEmpty
                                    ? "Pilihan \(index + 1)"
                                    : question.options[index],
                                reference: optionMediaBinding(index)
                            )
                        }
                    }
                }
            }

            if isQuiz, isObjective {
                Section("Jawaban benar") {
                    answerKeyEditor
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Pertanyaan \(question.order)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: question.kind) {
            if question.kind.acceptsOptions,
               question.options.count < 2 {
                question.options = ["", ""]
                question.optionIDs = question.options.indices.map {
                    AdminProgramDraftValidator().childIdentifier(
                        parent: question.id,
                        discriminator: $0 + 1
                    )
                }
                question.optionMediaReferences = Array(
                    repeating: nil,
                    count: question.options.count
                )
            }
            while question.optionMediaReferences.count
                < question.options.count {
                question.optionMediaReferences.append(nil)
            }
            if question.optionMediaReferences.count
                > question.options.count {
                question.optionMediaReferences = Array(
                    question.optionMediaReferences
                        .prefix(question.options.count)
                )
            }
            question.answerKey = isQuiz && isObjective
                ? (question.answerKey ?? ProgramQuestionAnswerKey())
                : nil
        }
        .accessibilityIdentifier("admin.question.editor")
    }

    private func optionBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { question.options[index] },
            set: { question.options[index] = $0 }
        )
    }

    private func optionMediaBinding(
        _ index: Int
    ) -> Binding<String?> {
        Binding(
            get: {
                guard question.optionMediaReferences.indices
                    .contains(index) else {
                    return nil
                }
                return question.optionMediaReferences[index]
            },
            set: { value in
                while question.optionMediaReferences.count <= index {
                    question.optionMediaReferences.append(nil)
                }
                question.optionMediaReferences[index] = value
            }
        )
    }

    private var isObjective: Bool {
        switch question.kind {
        case .number, .singleChoice, .multipleChoice, .imageChoice:
            true
        case .shortAnswer, .longAnswer, .photoUpload, .heading, .text:
            false
        }
    }

    @ViewBuilder
    private var answerKeyEditor: some View {
        switch question.kind {
        case .number:
            TextField(
                "Nilai yang benar",
                value: numberAnswer,
                format: .number.locale(Locale(identifier: "id-ID"))
            )
            .keyboardType(.decimalPad)
        case .singleChoice, .multipleChoice, .imageChoice:
            ForEach(question.options.indices, id: \.self) { index in
                Toggle(
                    question.options[index].isEmpty
                        ? "Pilihan \(index + 1)"
                        : question.options[index],
                    isOn: correctOptionBinding(index)
                )
            }
            Text(
                question.kind == .multipleChoice
                    ? "Pilih seluruh jawaban yang harus dipilih peserta."
                    : "Pilih satu jawaban benar."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        case .shortAnswer, .longAnswer, .photoUpload, .heading, .text:
            EmptyView()
        }
    }

    private var numberAnswer: Binding<Decimal?> {
        Binding(
            get: { question.answerKey?.numberValue },
            set: { value in
                if question.answerKey == nil {
                    question.answerKey = ProgramQuestionAnswerKey()
                }
                question.answerKey?.numberValue = value
            }
        )
    }

    private func correctOptionBinding(_ index: Int) -> Binding<Bool> {
        Binding(
            get: {
                guard question.optionIDs.indices.contains(index) else {
                    return false
                }
                return question.answerKey?.selectedOptionIDs.contains(
                    question.optionIDs[index]
                ) == true
            },
            set: { isSelected in
                guard question.optionIDs.indices.contains(index) else {
                    return
                }
                if question.answerKey == nil {
                    question.answerKey = ProgramQuestionAnswerKey()
                }
                let optionID = question.optionIDs[index]
                if isSelected {
                    if question.kind != .multipleChoice {
                        question.answerKey?.selectedOptionIDs = [optionID]
                    } else if question.answerKey?.selectedOptionIDs.contains(
                        optionID
                    ) == false {
                        question.answerKey?.selectedOptionIDs.append(optionID)
                    }
                } else {
                    question.answerKey?.selectedOptionIDs.removeAll {
                        $0 == optionID
                    }
                }
            }
        )
    }
}

@MainActor
private struct AdminImageOptionPicker: View {
    let title: String
    @Binding var reference: String?

    @State private var mediaState = LocalEvidenceMediaState()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        let actionTitle = reference == nil
            ? "Pilih gambar"
            : "Ganti gambar"
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(title)
                .font(AppTypography.cardTitle)
            if let result = mediaState.result {
                LocalMediaThumbnailView(result: result)
            } else if reference != nil {
                Label("Gambar dipilih", systemImage: "photo.fill")
                    .foregroundStyle(Color.appSecondaryText)
            }
            PhotosPicker(
                selection: $selectedItem,
                matching: .images
            ) {
                Label(
                    actionTitle,
                    systemImage: "photo.on.rectangle"
                )
                .frame(minHeight: AppControlMetrics.minimumTouchTarget)
            }
            .disabled(mediaState.isProcessing)
            if mediaState.isProcessing {
                ProgressView("Memproses gambar…")
            }
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task {
                await mediaState.importPhoto(item)
                reference = mediaState.result?.localURL.absoluteString
            }
        }
    }
}
