import PhotosUI
import SwiftUI

@MainActor
struct ParticipantStepDetailView: View {
    let store: ParticipantJourneyStore
    let stepID: UUID

    @State private var evidenceMedia = LocalEvidenceMediaState()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showsCamera = false
    @State private var textAnswer = ""
    @State private var photoError: String?
    @State private var textError: String?
    @State private var actionError: String?
    @FocusState private var isAnswerFocused: Bool

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
                    value: ParticipantFormatting.points(step.points)
                )
                Text(step.instructions)
                    .foregroundStyle(Color.appSecondaryText)
            }

            instructionMediaSection(step)
            requirementsSection(step)
            evidenceSection(step, submission: submission)

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
                completionSection(step)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                await evidenceMedia.importPhoto(item)
                selectedPhotoItem = nil
            }
        }
        .accessibilityIdentifier("participant.step.detail")
    }

    @ViewBuilder
    private func instructionMediaSection(_ step: ProgramStep) -> some View {
        if let media = step.instructionMedia {
            Section("participant.step.instruction_media") {
                if media.kind == .video {
                    LocalVideoPlayerView(
                        resourceName: media.resourceName,
                        textAlternative: media.accessibilityLabel
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

    private func requirementsSection(_ step: ProgramStep) -> some View {
        Section {
            if step.requirements.isEmpty {
                Label(
                    "participant.step.requirements.none",
                    systemImage: "checkmark.circle"
                )
            } else {
                ForEach(step.requirements) { requirement in
                    Label(
                        requirement.prompt
                            ?? String(
                                localized: "participant.step.requirement",
                                defaultValue: "Persyaratan langkah"
                            ),
                        systemImage: requirement.kind == .photoEvidence
                            ? "photo"
                            : "text.bubble"
                    )
                }
            }
        } header: {
            Text("participant.step.requirements.title")
        }
    }

    private func evidenceSection(
        _ step: ProgramStep,
        submission: StepSubmission?
    ) -> some View {
        let hasDraftEvidence = evidenceMedia.result != nil

        return Section {
            EvidenceStatusView(status: submission?.status)

            if requiresPhoto(step) {
                if let result = evidenceMedia.result {
                    LocalMediaThumbnailView(result: result)
                    LabeledContent("Ukuran hasil") {
                        Text(
                            "\(result.width) × \(result.height) px"
                        )
                        .monospacedDigit()
                    }
                    LabeledContent("Format", value: result.mimeType)
                } else if submission?.evidence.contains(where: {
                        $0.kind == .photo
                    }) == true {
                    MediaThumbnail(
                        title: "participant.evidence.local_sample",
                        systemImage: "photo.fill",
                        kindLabel: "participant.evidence.attached"
                    )
                }

                if evidenceMedia.isProcessing {
                    ProgressView(
                        value: evidenceMedia.progress,
                        total: 1
                    ) {
                        Text("Memproses bukti foto…")
                    }
                    .accessibilityIdentifier(
                        "participant.evidence.processing"
                    )
                }

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(
                        hasDraftEvidence
                            ? "Ganti dari foto"
                            : "Pilih dari foto",
                        systemImage: "photo.on.rectangle"
                    )
                    .frame(minHeight: 44)
                }
                .disabled(
                    submission?.status == .approved
                        || submission?.status == .pending
                        || evidenceMedia.isProcessing
                )
                .accessibilityIdentifier(
                    "participant.evidence.photo-picker"
                )

                Button {
                    showsCamera = true
                } label: {
                    Label("Ambil foto", systemImage: "camera.fill")
                        .frame(minHeight: 44)
                }
                .disabled(
                    submission?.status == .approved
                        || submission?.status == .pending
                        || evidenceMedia.isProcessing
                )
                .accessibilityIdentifier("participant.evidence.camera")

                if evidenceMedia.result != nil {
                    Button("Hapus foto", role: .destructive) {
                        evidenceMedia.remove()
                    }
                    .disabled(evidenceMedia.isProcessing)
                    .accessibilityIdentifier(
                        "participant.evidence.remove"
                    )
                }

                if let mediaError = evidenceMedia.error {
                    Label(
                        mediaErrorMessage(mediaError),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(Color.appDestructive)
                    Button("Coba lagi") {
                        Task { await evidenceMedia.retry() }
                    }
                    .disabled(evidenceMedia.isProcessing)
                    .accessibilityIdentifier(
                        "participant.evidence.retry"
                    )
                }

                photoAccessExplanation

                if let photoError {
                    Text(photoError)
                        .foregroundStyle(Color.appDestructive)
                        .accessibilityIdentifier(
                            "participant.evidence.validation"
                        )
                }
            }

            if requiresText(step) {
                TextField(
                    "participant.evidence.answer_field",
                    text: $textAnswer,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .focused($isAnswerFocused)
                .disabled(
                    submission?.status == .approved
                        || submission?.status == .pending
                )
                .accessibilityIdentifier("participant.evidence.answer")

                if let textError {
                    Text(textError)
                        .foregroundStyle(Color.appDestructive)
                        .accessibilityIdentifier(
                            "participant.answer.validation"
                        )
                }
            }
        } header: {
            Text("participant.evidence.title")
        } footer: {
            Text("participant.evidence.local_notice")
        }
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

    private func completionSection(_ step: ProgramStep) -> some View {
        Section {
            if let actionError {
                Text(actionError)
                    .foregroundStyle(Color.appDestructive)
            }

            Button {
                Task {
                    await complete(step)
                }
            } label: {
                Text(
                    store.submission(for: step.id)?.status == .rejected
                        ? "participant.step.retry_action"
                        : "participant.step.complete_action"
                )
            }
            .disabled(store.isPerformingAction)
            .disabled(evidenceMedia.isProcessing)
            .accessibilityIdentifier("participant.step.complete")
        }
    }

    private func complete(_ step: ProgramStep) async {
        do {
            try await store.completeStep(
                step,
                localPhotoReference:
                    evidenceMedia.result?.localURL.absoluteString,
                textAnswer: textAnswer.isEmpty ? nil : textAnswer
            )
            photoError = nil
            textError = nil
            actionError = nil
        } catch let error as DomainError {
            switch error {
            case .validation(let field, let reason):
                if field == "photoEvidence" {
                    photoError = reason
                } else if field == "textAnswer" {
                    textError = reason
                } else {
                    actionError = reason
                }
            default:
                actionError = ParticipantFormatting.fieldReason(error)
            }
        } catch {
            actionError = String(
                localized: "participant.error.generic",
                defaultValue: "Terjadi kendala. Coba lagi."
            )
        }
    }

    private func requiresPhoto(_ step: ProgramStep) -> Bool {
        step.requirements.contains {
            $0.kind == .photoEvidence && $0.isRequired
        }
    }

    private func requiresText(_ step: ProgramStep) -> Bool {
        step.requirements.contains {
            $0.kind == .textAnswer && $0.isRequired
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
