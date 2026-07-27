import SwiftUI

@MainActor
struct CoachParticipantDetailDestinationView: View {
    @State private var state: CoachParticipantDetailState?

    init(
        participantID: UUID,
        features: CoachFeatureContainer
    ) {
        _state = State(
            initialValue: features.makeParticipantDetailState(
                participantID: participantID
            )
        )
    }

    var body: some View {
        if let state {
            CoachParticipantDetailView(state: state)
        } else {
            ErrorStateView(error: .permissionDenied)
                .padding(AppSpacing.medium)
                .background(Color.appBackground)
        }
    }
}

@MainActor
struct CoachParticipantDetailView: View {
    let state: CoachParticipantDetailState

    @State private var selectedEvidence: SubmissionEvidence?

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
            case .loaded(let summary):
                detail(summary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle(Text("coach.participant.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if state.state == .idle {
                await state.load()
            }
        }
        .sheet(item: $selectedEvidence) { evidence in
            CoachEvidenceViewer(evidence: evidence)
        }
        .accessibilityIdentifier("coach.participant.detail")
    }

    private func detail(
        _ summary: CoachParticipantSummary
    ) -> some View {
        List {
            privateDataWarning
            profileSection(summary)
            enrollmentSection(summary)
            weightSection(summary)
            scoreSection(summary)
            timelineSection(summary)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .refreshable {
            await state.load()
        }
    }

    private var privateDataWarning: some View {
        Section {
            Label {
                Text("coach.participant.private_data.message")
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(Color.appWarning)
            }
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appPrimaryText)
        } footer: {
            Text("coach.participant.private_data.footer")
        }
    }

    private func profileSection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        Section("coach.participant.profile.title") {
            HStack(spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: summary.profile.displayName,
                    size: 64
                )
                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(summary.profile.displayName)
                        .font(AppTypography.cardTitle)
                    Text(summary.profile.city)
                        .foregroundStyle(Color.appSecondaryText)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func enrollmentSection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        Section("coach.participant.enrollment.title") {
            LabeledContent(
                "coach.participant.program",
                value: summary.program?.title
                    ?? String(localized: "coach.program.none")
            )
            if let enrollment = summary.enrollment {
                LabeledContent("coach.participant.enrolled_at") {
                    Text(CoachFormatting.date(enrollment.enrolledAt))
                }
                LabeledContent("coach.participant.enrollment_status") {
                    StatusBadge(
                        title: LocalizedStringKey(
                            "coach.enrollment.\(enrollment.status.rawValue)"
                        ),
                        kind: enrollment.status == .completed
                            ? .success
                            : .neutral
                    )
                }
            }
            LabeledContent("metric.progress") {
                Text(
                    CoachFormatting.percentage(
                        summary.progressPercentage
                    )
                )
                .monospacedDigit()
            }
            LabeledContent("coach.metric.missing_steps") {
                Text(CoachFormatting.number(summary.missingStepCount))
                    .monospacedDigit()
            }
        }
    }

    private func weightSection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        Section {
            LabeledContent("participant.weigh.initial.label") {
                if let weight = summary.initialWeighIn {
                    Text(
                        CoachFormatting.weight(
                            weight.weightKilograms
                        )
                    )
                    .monospacedDigit()
                } else {
                    Text("coach.weight.unavailable")
                        .foregroundStyle(Color.appSecondaryText)
                }
            }
            LabeledContent("participant.weigh.final.label") {
                if let weight = summary.finalWeighIn {
                    Text(
                        CoachFormatting.weight(
                            weight.weightKilograms
                        )
                    )
                    .monospacedDigit()
                } else {
                    Text("coach.weight.unavailable")
                        .foregroundStyle(Color.appSecondaryText)
                }
            }
        } header: {
            Text("coach.participant.weight.title")
        } footer: {
            Text("coach.participant.weight.footer")
        }
    }

    private func scoreSection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        let score = summary.leaderboardEntry?.score
            ?? ScoreBreakdown(
                approvedStepPoints: 0,
                weightPoints: 0,
                adjustmentPoints: 0
            )
        return Section("coach.participant.score.title") {
            scoreRow(
                title: "coach.score.step",
                value: score.approvedStepPoints
            )
            scoreRow(
                title: "coach.score.weight",
                value: score.weightPoints
            )
            scoreRow(
                title: "coach.score.adjustment",
                value: score.adjustmentPoints
            )
            scoreRow(
                title: "metric.points",
                value: score.totalPoints,
                isEmphasized: true
            )
        }
    }

    private func scoreRow(
        title: LocalizedStringKey,
        value: Int,
        isEmphasized: Bool = false
    ) -> some View {
        LabeledContent(title) {
            Text(CoachFormatting.number(value))
                .font(
                    isEmphasized
                        ? AppTypography.cardTitle.monospacedDigit()
                        : AppTypography.body.monospacedDigit()
                )
        }
    }

    private func timelineSection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        Section("coach.participant.timeline.title") {
            if let program = summary.program {
                ForEach(
                    program.days.sorted { $0.dayNumber < $1.dayNumber }
                ) { day in
                    CoachParticipantDayDisclosure(
                        day: day,
                        submissions: summary.submissions,
                        selectEvidence: { selectedEvidence = $0 }
                    )
                }
            } else {
                Text("coach.participant.timeline.empty")
                    .foregroundStyle(Color.appSecondaryText)
            }
        }
    }
}

private struct CoachParticipantDayDisclosure: View {
    let day: ProgramDay
    let submissions: [StepSubmission]
    let selectEvidence: (SubmissionEvidence) -> Void

    private var completedCount: Int {
        day.steps.filter { step in
            submissions.contains { $0.stepID == step.id }
        }.count
    }

    var body: some View {
        DisclosureGroup {
            ForEach(day.steps.sorted { $0.order < $1.order }) { step in
                CoachParticipantStepReviewRow(
                    step: step,
                    submission: submissions.first {
                        $0.stepID == step.id
                    },
                    selectEvidence: selectEvidence
                )
            }
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                let dayNumber = Text(
                    day.dayNumber,
                    format: .number.locale(CoachFormatting.locale)
                )
                Text(
                    "\(Text("participant.day.label")) \(dayNumber) — \(Text(day.title))"
                )
                .font(AppTypography.cardTitle)
                Text(
                    String(
                        format: String(
                            localized: "coach.timeline.completion_format"
                        ),
                        completedCount,
                        day.steps.count
                    )
                )
                .font(AppTypography.secondary.monospacedDigit())
                .foregroundStyle(Color.appSecondaryText)
            }
        }
    }
}

private struct CoachParticipantStepReviewRow: View {
    let step: ProgramStep
    let submission: StepSubmission?
    let selectEvidence: (SubmissionEvidence) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text(step.title)
                    .font(AppTypography.cardTitle)
                Spacer()
                statusBadge
            }
            Text(step.instructions)
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)

            if let submission {
                ForEach(submission.evidence) { evidence in
                    switch evidence.kind {
                    case .photo:
                        Button {
                            selectEvidence(evidence)
                        } label: {
                            MediaThumbnail(
                                title: "coach.evidence.thumbnail",
                                systemImage: "photo.fill",
                                kindLabel: "coach.evidence.photo"
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("coach.evidence.open")
                    case .text:
                        if let answer = evidence.textValue {
                            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                                Text("coach.evidence.answer")
                                    .font(AppTypography.label)
                                    .foregroundStyle(Color.appSecondaryText)
                                Text(answer)
                                    .font(AppTypography.body)
                            }
                        }
                    }
                }
                if let note = submission.reviewNote, !note.isEmpty {
                    Label(note, systemImage: "text.bubble")
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                }
            } else {
                Label(
                    "coach.step.missing",
                    systemImage: "exclamationmark.circle"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appWarning)
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if let submission {
            switch submission.status {
            case .pending:
                StatusBadge(title: "status.pending", kind: .pending)
            case .approved:
                StatusBadge(title: "status.approved", kind: .success)
            case .rejected:
                StatusBadge(title: "status.rejected", kind: .error)
            }
        } else {
            StatusBadge(
                title: "coach.step.missing",
                kind: .warning
            )
        }
    }
}

struct CoachEvidenceViewer: View {
    @Environment(\.dismiss) private var dismiss
    let evidence: SubmissionEvidence

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.large) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.largeTitle)
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityHidden(true)
                Text("coach.evidence.viewer.title")
                    .font(AppTypography.sectionTitle)
                Text("coach.evidence.viewer.local_placeholder")
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
                Label(
                    "coach.evidence.viewer.privacy",
                    systemImage: "lock.fill"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appPrimaryText)
            }
            .frame(maxWidth: 520)
            .padding(AppSpacing.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .navigationTitle(Text("coach.evidence.viewer.navigation_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("coach.evidence.viewer")
    }
}
