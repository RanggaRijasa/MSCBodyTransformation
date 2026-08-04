import PhotosUI
import SwiftUI

@MainActor
struct ParticipantStepDetailView: View {
    let store: ParticipantJourneyStore
    let stepID: UUID

    @State private var evidenceMedia = LocalEvidenceMediaState()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showsCamera = false
    @State private var actionError: String?
    @State private var typedTextAnswers: [UUID: String] = [:]
    @State private var typedSelections: [UUID: Set<UUID>] = [:]
    @State private var typedPhotoReferences: [UUID: String] = [:]
    @State private var activePhotoQuestionID: UUID?
    @State private var weighInInput = ""
    @State private var videoCompletionPercentage = 0

    var body: some View {
        Group {
            if let step = store.step(id: stepID) {
                stepContent(step)
            } else {
                ErrorStateView(error: .notFound(resource: "step"))
            }
        }
        .navigationTitle(Text("participant.step.navigation_title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsCamera) {
            NativeCameraCaptureSheet { data in
                Task {
                    await evidenceMedia.importCameraData(data)
                    if let activePhotoQuestionID,
                       let reference =
                        evidenceMedia.result?.localURL.absoluteString {
                        typedPhotoReferences[activePhotoQuestionID] =
                            reference
                    }
                }
            }
        }
        .task {
            await evidenceMedia.cleanupOrphans()
        }
    }

    private func stepContent(_ step: ProgramStep) -> some View {
        let submission = store.submission(for: step.id)
        let access = store.access(for: step)

        return Form {
            Section {
                Text(step.title)
                    .font(AppTypography.sectionTitle)
                LabeledContent(
                    "metric.points",
                    value: ParticipantFormatting.points(
                        pointsDisplayed(for: step)
                    )
                )
                Text(step.instructions)
                    .foregroundStyle(Color.appSecondaryText)
            }

            instructionMediaSection(step)
            if let content = step.content {
                typedContentSection(
                    content,
                    step: step,
                    submission: submission
                )
            } else {
                Section {
                    ContentUnavailableView(
                        "Konten belum tersedia",
                        systemImage: "exclamationmark.triangle",
                        description: Text(
                            "Muat ulang program atau hubungi Admin."
                        )
                    )
                }
            }

            if let submission {
                submissionSection(submission)
            }

            if access != .available {
                Section {
                    LockedContentView(
                        title: "state.locked.title",
                        message: access == .readOnly
                            ? "participant.step.read_only.message"
                            : "state.locked.message"
                    )
                }
            } else if submission?.status != .approved
                        && submission?.status != .pending {
                typedCompletionSection(step)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                await evidenceMedia.importPhoto(item)
                if let activePhotoQuestionID,
                   let reference =
                    evidenceMedia.result?.localURL.absoluteString {
                    typedPhotoReferences[activePhotoQuestionID] = reference
                }
                selectedPhotoItem = nil
            }
        }
        .accessibilityIdentifier("participant.step.detail")
    }

    @ViewBuilder
    private func typedContentSection(
        _ content: ProgramStepContent,
        step: ProgramStep,
        submission: StepSubmission?
    ) -> some View {
        switch content.kind {
        case .article:
            Section("Aktivitas") {
                Label(
                    "Baca materi, lalu tandai selesai.",
                    systemImage: "doc.text"
                )
            }
        case .video:
            Section("Penyelesaian video") {
                if content.videoConfiguration?.isRequiredToWatch == true {
                    LabeledContent(
                        "Wajib ditonton",
                        value: "\(content.videoConfiguration?.completionThresholdPercentage ?? 100)%"
                    )
                } else {
                    Text("Video dapat ditandai selesai setelah ditonton.")
                }
            }
        case .form, .quiz:
            ForEach(
                content.questions.sorted { $0.order < $1.order }
            ) { question in
                typedQuestionSection(
                    question,
                    isDisabled: submission?.status == .pending
                        || submission?.status == .approved
                )
            }
        case .initialWeighIn, .dailyWeighIn, .finalWeighIn:
            Section(
                weighInTitle(for: content.kind)
            ) {
                TextField(
                    "Berat (kg)",
                    text: $weighInInput
                )
                .keyboardType(.decimalPad)
                .disabled(
                    submission?.status == .pending
                        || submission?.status == .approved
                )
                Text(
                    "Gunakan angka kilogram, misalnya 72,5. Nilai berat "
                        + "tidak ditampilkan di leaderboard publik."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }

        if let result = submission?.quizResult {
            Section("Hasil kuis") {
                LabeledContent(
                    "Jawaban benar",
                    value: "\(result.correctAnswerCount) dari "
                        + "\(result.totalQuestionCount)"
                )
                LabeledContent("Nilai", value: "\(result.percentage)%")
                StatusBadge(
                    title: result.isPassed ? "Lulus" : "Belum lulus",
                    kind: result.isPassed ? .success : .warning
                )
                Text(
                    "Jawaban benar hanya dapat dilihat oleh Coach dan Admin."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func typedQuestionSection(
        _ question: ProgramQuestionDefinition,
        isDisabled: Bool
    ) -> some View {
        switch question.kind {
        case .heading:
            Section {
                Text(question.prompt)
                    .font(AppTypography.sectionTitle)
            }
        case .text:
            Section {
                Text(question.prompt)
                    .foregroundStyle(.secondary)
            }
        case .shortAnswer:
            Section(question.prompt) {
                TextField(
                    "Jawaban",
                    text: textBinding(for: question.id)
                )
                .disabled(isDisabled)
            }
        case .longAnswer:
            Section(question.prompt) {
                TextField(
                    "Jawaban",
                    text: textBinding(for: question.id),
                    axis: .vertical
                )
                .lineLimit(3...8)
                .disabled(isDisabled)
            }
        case .number:
            Section(question.prompt) {
                TextField(
                    "Angka",
                    text: textBinding(for: question.id)
                )
                .keyboardType(.decimalPad)
                .disabled(isDisabled)
            }
        case .singleChoice, .multipleChoice, .imageChoice:
            Section(question.prompt) {
                ForEach(
                    question.options.sorted { $0.order < $1.order }
                ) { option in
                    Toggle(
                        isOn: selectionBinding(
                            question: question,
                            optionID: option.id
                        )
                    ) {
                        HStack {
                            if question.kind == .imageChoice {
                                Image(systemName: "photo")
                                    .foregroundStyle(Color.brandPrimary)
                            }
                            Text(option.title)
                        }
                    }
                    .disabled(isDisabled)
                }
            }
        case .photoUpload:
            Section(question.prompt) {
                let hasPhoto = typedPhotoReferences[question.id] != nil
                if let reference = typedPhotoReferences[question.id] {
                    Label(
                        "Foto siap dikirim",
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(Color.appSuccess)
                    Text(reference)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(
                        !hasPhoto
                            ? "Pilih foto"
                            : "Ganti foto",
                        systemImage: "photo.on.rectangle"
                    )
                    .frame(minHeight: 44)
                }
                .simultaneousGesture(
                    TapGesture().onEnded {
                        activePhotoQuestionID = question.id
                    }
                )
                .disabled(isDisabled || evidenceMedia.isProcessing)

                Button {
                    activePhotoQuestionID = question.id
                    showsCamera = true
                } label: {
                    Label("Ambil foto", systemImage: "camera")
                        .frame(minHeight: 44)
                }
                .disabled(isDisabled || evidenceMedia.isProcessing)
            }
        }
    }

    private func typedCompletionSection(
        _ step: ProgramStep
    ) -> some View {
        Section {
            if let actionError {
                Text(actionError)
                    .foregroundStyle(Color.appDestructive)
            }
            Button {
                Task {
                    await completeTypedStep(step)
                }
            } label: {
                Text(
                    step.content?.weighInKind == nil
                        ? "Kirim langkah"
                        : "Kirim hasil timbang"
                )
            }
            .disabled(
                store.isPerformingAction
                    || evidenceMedia.isProcessing
                    || isRequiredVideoIncomplete(step)
            )
            .accessibilityIdentifier("participant.step.complete")
            if isRequiredVideoIncomplete(step) {
                Text(
                    "Tonton video hingga ambang yang ditentukan sebelum "
                        + "mengirim langkah."
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
            }
        }
    }

    private func completeTypedStep(_ step: ProgramStep) async {
        do {
            if step.content?.weighInKind != nil {
                try await store.submitWeighInStep(
                    step,
                    input: weighInInput
                )
            } else {
                try await store.completeStep(
                    step,
                    answers: try typedAnswers(for: step)
                )
            }
            actionError = nil
        } catch let error as DomainError {
            actionError = ParticipantFormatting.fieldReason(error)
        } catch {
            actionError = String(
                localized: "participant.error.generic",
                defaultValue: "Terjadi kendala. Coba lagi."
            )
        }
    }

    private func typedAnswers(
        for step: ProgramStep
    ) throws -> [StepSubmissionAnswer] {
        guard let questions = step.content?.questions else {
            return []
        }
        return try questions.compactMap { question in
            guard question.requiresAnswer else { return nil }
            let text = typedTextAnswers[question.id]?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let number: Decimal?
            if question.kind == .number, let text, !text.isEmpty {
                number = Decimal(
                    string: text.replacingOccurrences(of: ",", with: "."),
                    locale: Locale(identifier: "en_US_POSIX")
                )
                guard number != nil else {
                    throw DomainError.validation(
                        field: "answers",
                        reason: "Masukkan angka yang valid."
                    )
                }
            } else {
                number = nil
            }
            return StepSubmissionAnswer(
                id: question.id,
                questionID: question.id,
                textValue: question.kind == .shortAnswer
                    || question.kind == .longAnswer ? text : nil,
                numberValue: number,
                selectedOptionIDs: Array(
                    typedSelections[question.id] ?? []
                ),
                localPhotoReference:
                    typedPhotoReferences[question.id]
            )
        }
    }

    private func textBinding(for questionID: UUID) -> Binding<String> {
        Binding(
            get: { typedTextAnswers[questionID] ?? "" },
            set: { typedTextAnswers[questionID] = $0 }
        )
    }

    private func selectionBinding(
        question: ProgramQuestionDefinition,
        optionID: UUID
    ) -> Binding<Bool> {
        Binding(
            get: {
                typedSelections[question.id]?.contains(optionID) == true
            },
            set: { selected in
                if selected {
                    if question.kind == .multipleChoice {
                        typedSelections[question.id, default: []]
                            .insert(optionID)
                    } else {
                        typedSelections[question.id] = [optionID]
                    }
                } else {
                    typedSelections[question.id]?.remove(optionID)
                }
            }
        )
    }

    @ViewBuilder
    private func instructionMediaSection(_ step: ProgramStep) -> some View {
        if let media = step.instructionMedia {
            Section("participant.step.instruction_media") {
                if media.kind == .video {
                    LocalVideoPlayerView(
                        resourceName: media.resourceName,
                        textAlternative: media.accessibilityLabel,
                        configuration: step.content?.videoConfiguration,
                        completionPercentage: $videoCompletionPercentage
                    )
                } else {
                    MediaThumbnail(
                        title: LocalizedStringKey(
                            media.accessibilityLabel
                        ),
                        systemImage: "photo.fill",
                        kindLabel: "participant.media.image_instruction"
                    )
                }
            }
        }
    }

    private func isRequiredVideoIncomplete(_ step: ProgramStep) -> Bool {
        guard let configuration = step.content?.videoConfiguration,
              configuration.isRequiredToWatch else {
            return false
        }
        return videoCompletionPercentage
            < configuration.completionThresholdPercentage
    }

    private func submissionSection(
        _ submission: StepSubmission
    ) -> some View {
        Section {
            EvidenceStatusView(status: submission.status)

            if submission.status == .pending {
                Text("state.pending.message")
            } else if submission.status == .rejected {
                Text("state.rejected.message")
                if let note = submission.reviewNote {
                    LabeledContent(
                        "participant.evidence.rejection_reason",
                        value: note
                    )
                }
                Label(
                    "participant.evidence.retry_ready",
                    systemImage: "arrow.clockwise"
                )
            } else {
                Text("participant.evidence.approved_message")
            }
        } header: {
            Text("participant.step.submission_status")
        }
    }

    private func pointsDisplayed(for step: ProgramStep) -> Int {
        guard let kind = step.content?.kind else { return 0 }
        switch kind {
        case .article, .video, .form, .quiz:
            return store.currentProgram?.effectiveScoringConfiguration
                .pointsPerActivity ?? 0
        case .initialWeighIn, .dailyWeighIn, .finalWeighIn:
            return 0
        }
    }

    private func weighInTitle(
        for kind: ProgramContentKind
    ) -> String {
        switch kind {
        case .initialWeighIn:
            "Timbang awal"
        case .dailyWeighIn:
            "Timbang harian"
        case .finalWeighIn:
            "Timbang akhir"
        case .article, .video, .form, .quiz:
            ""
        }
    }

    @ViewBuilder
    private var photoAccessExplanation: some View {
        switch evidenceMedia.libraryAccess {
        case .limited:
            Label(
                "Akses foto terbatas. Anda tetap dapat memilih foto lain.",
                systemImage: "photo.badge.checkmark"
            )
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
        case .denied, .restricted:
            Label(
                "Akses pustaka dibatasi. Gunakan kamera atau ubah izin "
                    + "Foto di Pengaturan.",
                systemImage: "photo.badge.exclamationmark"
            )
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
        case .full, .notDetermined:
            EmptyView()
        }
    }

    private func mediaErrorMessage(
        _ error: LocalMediaError
    ) -> String {
        switch error {
        case .unsupportedMIMEType:
            "Pilih foto berformat JPEG, PNG, HEIC, atau HEIF."
        case .inputTooLarge:
            "Ukuran foto terlalu besar. Pilih foto hingga 20 MB."
        case .invalidImage:
            "Foto tidak dapat dibaca. Pilih foto lain."
        case .processingFailed:
            "Foto gagal diproses. Coba lagi."
        case .permissionDenied:
            "Akses foto ditolak. Gunakan kamera atau ubah izin di Pengaturan."
        case .cameraUnavailable:
            "Kamera tidak tersedia pada perangkat ini."
        case .cameraUsageDescriptionMissing:
            "Kamera belum dikonfigurasi untuk build ini."
        }
    }
}

#Preview("Langkah — bukti belum ada") {
    ParticipantStepPreview(stepIndex: 6)
}

#Preview("Langkah — menunggu pemeriksaan") {
    ParticipantStepPreview(stepIndex: 3)
}

#Preview("Langkah — ditolak") {
    ParticipantStepPreview(stepIndex: 4)
}

@MainActor
private struct ParticipantStepPreview: View {
    let stepIndex: Int
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )

    var body: some View {
        NavigationStack {
            if let stepID = store.currentProgram?.days
                .flatMap(\.steps)
                .dropFirst(stepIndex)
                .first?
                .id {
                ParticipantStepDetailView(
                    store: store,
                    stepID: stepID
                )
            } else {
                LoadingStateView()
            }
        }
        .task {
            await store.load()
            if let day = store.currentProgram?.days.first(where: {
                $0.steps.contains(where: {
                    $0.id == store.currentProgram?.days
                        .flatMap(\.steps)
                        .dropFirst(stepIndex)
                        .first?
                        .id
                })
            }) {
                store.selectDay(day.dayNumber)
            }
        }
    }
}
