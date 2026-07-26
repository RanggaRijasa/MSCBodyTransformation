import SwiftUI

@MainActor
struct ParticipantStepDetailView: View {
    let store: ParticipantJourneyStore
    let stepID: UUID

    @State private var localPhotoReference: String?
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
        .accessibilityIdentifier("participant.step.detail")
    }

    @ViewBuilder
    private func instructionMediaSection(_ step: ProgramStep) -> some View {
        if let media = step.instructionMedia {
            Section("participant.step.instruction_media") {
                MediaThumbnail(
                    title: LocalizedStringKey(media.accessibilityLabel),
                    systemImage: media.kind == .image
                        ? "photo.fill"
                        : "play.rectangle.fill",
                    kindLabel: media.kind == .image
                        ? "participant.media.image_instruction"
                        : "participant.media.video_placeholder"
                )
                if media.kind == .video {
                    Text("participant.media.video_local_notice")
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
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
                                localized: "participant.step.requirement"
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
        Section {
            EvidenceStatusView(status: submission?.status)

            if requiresPhoto(step) {
                if localPhotoReference != nil
                    || submission?.evidence.contains(where: {
                        $0.kind == .photo
                    }) == true {
                    MediaThumbnail(
                        title: "participant.evidence.local_sample",
                        systemImage: "photo.fill",
                        kindLabel: "participant.evidence.attached"
                    )
                }

                Button {
                    localPhotoReference =
                        "local-demo://evidence/sample-photo"
                    photoError = nil
                } label: {
                    Label(
                        localPhotoReference == nil
                            ? "participant.evidence.attach_action"
                            : "participant.evidence.replace_action",
                        systemImage: "photo.badge.plus"
                    )
                }
                .disabled(
                    submission?.status == .approved
                        || submission?.status == .pending
                )
                .accessibilityIdentifier(
                    "participant.evidence.use-sample"
                )

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
            .accessibilityIdentifier("participant.step.complete")
        }
    }

    private func complete(_ step: ProgramStep) async {
        do {
            try await store.completeStep(
                step,
                localPhotoReference: localPhotoReference,
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
            actionError = String(localized: "participant.error.generic")
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
