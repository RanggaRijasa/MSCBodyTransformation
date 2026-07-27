import SwiftUI

@MainActor
struct CoachReviewQueueView: View {
    let features: CoachFeatureContainer

    @State private var selectedItem: CoachReviewItem?

    private var state: CoachReviewQueueState {
        features.reviewQueue
    }

    var body: some View {
        Group {
            switch state.state {
            case .idle, .loading:
                LoadingStateView()
            case .failed(let error):
                ScrollView {
                    ErrorStateView(error: error) {
                        Task {
                            await state.load()
                        }
                    }
                    .padding(AppSpacing.medium)
                }
            case .loaded(let items):
                queue(items)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle(Text("coach.review.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if state.state == .idle {
                await state.load()
            }
        }
        .sheet(item: $selectedItem) { item in
            CoachReviewSheet(
                item: item,
                features: features
            )
        }
        .accessibilityIdentifier("coach.review.queue")
    }

    private func queue(_ items: [CoachReviewItem]) -> some View {
        List {
            if let decision = state.lastDecision {
                Section {
                    CoachReviewResultBanner(result: decision)
                }
            }

            if items.isEmpty {
                Section {
                    ContentUnavailableView(
                        "coach.review.empty.title",
                        systemImage: "checkmark.circle",
                        description: Text("coach.review.empty.message")
                    )
                }
            } else {
                Section {
                    ForEach(items) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            CoachReviewQueueRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(
                            "coach.review.open.\(item.id)"
                        )
                    }
                } header: {
                    SectionHeader(
                        title: "coach.review.pending.title",
                        subtitle: "coach.review.pending.subtitle"
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .refreshable {
            await state.load()
        }
    }
}

private struct CoachReviewQueueRow: View {
    let item: CoachReviewItem

    var body: some View {
        let dayNumber = Text(
            item.day.dayNumber,
            format: .number.locale(CoachFormatting.locale)
        )
        let submittedAt = Text(
            CoachFormatting.dateTime(
                item.submission.submittedAt,
                timeZoneIdentifier: item.program.timeZoneIdentifier
            )
        )

        HStack(alignment: .top, spacing: AppSpacing.medium) {
            UserAvatar(displayName: item.participant.displayName)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(item.participant.displayName)
                    .font(AppTypography.cardTitle)
                Text(item.step.title)
                    .font(AppTypography.body)
                Text(
                    "\(Text("participant.day.label")) \(dayNumber) • \(submittedAt)"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
            }
            Spacer(minLength: AppSpacing.small)
            StatusBadge(title: "status.pending", kind: .pending)
        }
        .padding(.vertical, AppSpacing.xSmall)
        .accessibilityElement(children: .combine)
    }
}

private struct CoachReviewResultBanner: View {
    let result: CoachReviewDecisionResult

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Label(
                result.status == .approved
                    ? "coach.review.result.approved"
                    : "coach.review.result.rejected",
                systemImage: result.status == .approved
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .font(AppTypography.cardTitle)
            .foregroundStyle(
                result.status == .approved
                    ? Color.appSuccess
                    : Color.appDestructive
            )
            Text(result.participantName)
                .font(AppTypography.body)
            Text(
                String(
                    format: String(
                        localized: "coach.review.result.points_format"
                    ),
                    CoachFormatting.number(result.pointsBefore),
                    CoachFormatting.number(result.pointsAfter)
                )
            )
            .font(AppTypography.secondary.monospacedDigit())
            .foregroundStyle(Color.appSecondaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("coach.review.result")
    }
}

private enum CoachPendingReviewDecision {
    case approve
    case reject
}

@MainActor
private struct CoachReviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: CoachReviewItem
    let features: CoachFeatureContainer

    @State private var rejectionReason = ""
    @State private var validationMessage: String?
    @State private var actionError: String?
    @State private var pendingDecision: CoachPendingReviewDecision?
    @State private var selectedEvidence: SubmissionEvidence?

    private var isConfirmationPresented: Binding<Bool> {
        Binding(
            get: { pendingDecision != nil },
            set: {
                if !$0 {
                    pendingDecision = nil
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                contextSection
                evidenceSection
                rejectionSection
                actionSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(Text("coach.review.sheet.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .sheet(item: $selectedEvidence) { evidence in
            CoachEvidenceViewer(evidence: evidence)
        }
        .confirmationDialog(
            "coach.review.confirm.title",
            isPresented: isConfirmationPresented,
            titleVisibility: .visible
        ) {
            if pendingDecision == .approve {
                Button("coach.review.approve") {
                    performReview(status: .approved, note: nil)
                }
            } else if pendingDecision == .reject {
                Button("coach.review.reject", role: .destructive) {
                    performReview(
                        status: .rejected,
                        note: rejectionReason
                    )
                }
            }
            Button("action.cancel", role: .cancel) {}
        } message: {
            Text(
                pendingDecision == .approve
                    ? "coach.review.confirm.approve"
                    : "coach.review.confirm.reject"
            )
        }
    }

    private var contextSection: some View {
        Section("coach.review.context.title") {
            LabeledContent(
                "coach.review.participant",
                value: item.participant.displayName
            )
            LabeledContent(
                "coach.review.program",
                value: item.program.title
            )
            LabeledContent("coach.review.day") {
                Text(
                    item.day.dayNumber,
                    format: .number.locale(CoachFormatting.locale)
                )
            }
            LabeledContent(
                "coach.review.step",
                value: item.step.title
            )
            Text(item.step.instructions)
                .font(AppTypography.body)
                .foregroundStyle(Color.appSecondaryText)
            LabeledContent("coach.review.step_points") {
                Text(
                    item.step.points,
                    format: .number.locale(CoachFormatting.locale)
                )
                .monospacedDigit()
            }
        }
    }

    private var evidenceSection: some View {
        Section("coach.review.evidence.title") {
            if item.submission.evidence.isEmpty {
                Text("coach.review.evidence.empty")
                    .foregroundStyle(Color.appSecondaryText)
            } else {
                ForEach(item.submission.evidence) { evidence in
                    switch evidence.kind {
                    case .photo:
                        Button {
                            selectedEvidence = evidence
                        } label: {
                            MediaThumbnail(
                                title: "coach.evidence.thumbnail",
                                systemImage: "photo.fill",
                                kindLabel: "coach.evidence.photo"
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("coach.review.evidence.open")
                    case .text:
                        Text(
                            evidence.textValue
                                ?? String(localized: "coach.review.evidence.empty")
                        )
                    }
                }
            }
        }
    }

    private var rejectionSection: some View {
        Section {
            TextField(
                "coach.review.rejection_reason.placeholder",
                text: $rejectionReason,
                axis: .vertical
            )
            .lineLimit(3...6)
            .accessibilityIdentifier("coach.review.rejection-reason")

            if let validationMessage {
                Label(
                    validationMessage,
                    systemImage: "exclamationmark.circle"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appDestructive)
            }
        } header: {
            Text("coach.review.rejection_reason.title")
        } footer: {
            Text("coach.review.rejection_reason.footer")
        }
    }

    private var actionSection: some View {
        Section {
            Button {
                validationMessage = nil
                pendingDecision = .approve
            } label: {
                Label(
                    "coach.review.approve",
                    systemImage: "checkmark.circle.fill"
                )
            }
            .disabled(features.reviewQueue.isPerformingAction)
            .accessibilityIdentifier("coach.review.approve")

            Button(role: .destructive) {
                guard !rejectionReason.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty else {
                    validationMessage = String(
                        localized: "coach.review.rejection_reason.required"
                    )
                    return
                }
                validationMessage = nil
                pendingDecision = .reject
            } label: {
                Label(
                    "coach.review.reject",
                    systemImage: "xmark.circle.fill"
                )
            }
            .disabled(features.reviewQueue.isPerformingAction)
            .accessibilityIdentifier("coach.review.reject")

            if features.reviewQueue.isPerformingAction {
                ProgressView("coach.review.saving")
            }
            if let actionError {
                Text(actionError)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appDestructive)
            }
        } footer: {
            Text("coach.review.no_undo")
        }
    }

    private func performReview(
        status: SubmissionStatus,
        note: String?
    ) {
        Task {
            do {
                try await features.review(
                    item: item,
                    status: status,
                    note: note
                )
                actionError = nil
                dismiss()
            } catch let error as DomainError {
                actionError = CoachFormatting.reason(error)
            } catch {
                actionError = String(localized: "coach.error.generic")
            }
        }
    }
}

#Preview("Antrean review") {
    NavigationStack {
        CoachReviewQueuePreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

@MainActor
private struct CoachReviewQueuePreview: View {
    @State private var features = CoachFeatureContainer(
        environment: .preview
    )

    var body: some View {
        CoachReviewQueueView(features: features)
            .task {
                await features.prepareIdentity()
            }
    }
}
