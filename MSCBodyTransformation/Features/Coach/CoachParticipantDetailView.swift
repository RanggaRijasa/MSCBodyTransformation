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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let state: CoachParticipantDetailState

    @State private var selectedEvidence: StepSubmissionAnswer?
    @State private var isSupportingDataExpanded = false

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
        .navigationBarTitleDisplayMode(.large)
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
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                    profileCard(summary)
                    progressCard(summary)
                    weightHistorySection(summary)
                    summarySection(summary)
                    recentActivitySection(summary)
                    actionButtons(proxy: proxy)
                    evidenceSection(summary)
                        .id(CoachParticipantDetailSection.evidence)
                    progressDetailSection(summary)
                        .id(CoachParticipantDetailSection.progress)
                    supportingDataSection(summary)
                    privacyNotice
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding(AppSpacing.medium)
                .padding(.bottom, AppSpacing.large)
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                await state.load()
            }
        }
    }

    private func profileCard(
        _ summary: CoachParticipantSummary
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            UserAvatar(
                displayName: summary.profile.displayName,
                imageName: summary.profile.localPhotoReference,
                size: 88
            )

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(summary.profile.displayName)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(Color.appPrimaryText)

                Label(summary.profile.city, systemImage: "mappin")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)

                enrollmentStatus(summary)

                Divider()

                Label {
                    Text(
                        summary.program?.title
                            ?? String(
                                localized: "coach.program.none",
                                defaultValue: "Belum ada program"
                            )
                    )
                } icon: {
                    Image(systemName: "checklist")
                }
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
            }
        }
        .padding(AppSpacing.medium)
        .background(
            Color.appSurface,
            in: RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
            .stroke(Color.appBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func enrollmentStatus(
        _ summary: CoachParticipantSummary
    ) -> some View {
        switch summary.enrollment?.status {
        case .active:
            StatusBadge(title: "coach.enrollment.active", kind: .success)
        case .completed:
            StatusBadge(title: "status.completed", kind: .success)
        case .initiated, .waitingForPayment:
            StatusBadge(title: "coach.enrollment.pending", kind: .pending)
        case .cancelled, .refunded:
            StatusBadge(title: "coach.enrollment.cancelled", kind: .neutral)
        case .none:
            StatusBadge(title: "coach.program.none", kind: .neutral)
        }
    }

    private func progressCard(
        _ summary: CoachParticipantSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("coach.participant.progress.title")
                .font(AppTypography.cardTitle)
                .foregroundStyle(Color.appPrimaryText)

            HStack(spacing: AppSpacing.medium) {
                ProgressView(
                    value: Double(summary.progressPercentage),
                    total: 100
                )
                .tint(Color.brandPrimary)

                Text(
                    CoachFormatting.percentage(
                        summary.progressPercentage
                    )
                )
                .font(AppTypography.sectionTitle.monospacedDigit())
                .foregroundStyle(Color.appPrimaryText)
            }

            Text(
                String(
                    format: String(
                        localized:
                            "coach.participant.progress.day_format",
                        defaultValue: "Hari %lld dari %lld"
                    ),
                    currentProgramDay(summary),
                    summary.program?.durationInDays ?? 0
                )
            )
            .font(AppTypography.body)
            .foregroundStyle(Color.appPrimaryText)

            Text(
                String(
                    format: String(
                        localized:
                            "coach.participant.progress.steps_format",
                        defaultValue:
                            "%lld dari %lld langkah selesai"
                    ),
                    summary.completedStepCount,
                    summary.totalStepCount
                )
            )
            .font(AppTypography.secondary.monospacedDigit())
            .foregroundStyle(Color.appSecondaryText)
        }
        .padding(AppSpacing.medium)
        .background(
            Color.appSurface,
            in: RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
            .stroke(Color.appBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func currentProgramDay(
        _ summary: CoachParticipantSummary
    ) -> Int {
        guard let program = summary.program else {
            return 0
        }
        let sortedDays = program.days.sorted {
            $0.scheduledDate < $1.scheduledDate
        }
        return sortedDays.last {
            $0.scheduledDate <= Date.now
        }?.dayNumber ?? sortedDays.first?.dayNumber ?? 0
    }

    private func summarySection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "coach.participant.summary.title")

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 0) {
                        summaryMetrics(summary)
                    }
                } else {
                    HStack(spacing: 0) {
                        summaryMetrics(summary)
                    }
                }
            }
            .padding(.vertical, AppSpacing.medium)
            .background(
                Color.appSurface,
                in: RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
                .stroke(Color.appBorder, lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private func summaryMetrics(
        _ summary: CoachParticipantSummary
    ) -> some View {
        CoachParticipantDetailMetric(
            value: CoachFormatting.number(summary.points),
            title: "metric.points",
            systemImage: "star"
        )

        detailMetricDivider

        CoachParticipantDetailMetric(
            value: CoachFormatting.number(summary.activeDayCount),
            title: "coach.participant.summary.active_days",
            systemImage: "calendar"
        )

        detailMetricDivider

        CoachParticipantDetailMetric(
            value: CoachFormatting.number(summary.evidenceCount),
            title: "coach.participant.summary.evidence",
            systemImage: "photo"
        )
    }

    @ViewBuilder
    private var detailMetricDivider: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Divider()
                .padding(.horizontal, AppSpacing.medium)
        } else {
            Divider()
                .padding(.vertical, AppSpacing.xSmall)
        }
    }

    private func recentActivitySection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "coach.participant.activity.title")

            VStack(spacing: 0) {
                if recentSubmissions(summary).isEmpty {
                    Text("coach.participant.activity.empty")
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.medium)
                } else {
                    ForEach(
                        Array(recentSubmissions(summary).enumerated()),
                        id: \.element.id
                    ) { index, submission in
                        recentActivityRow(
                            submission,
                            summary: summary
                        )

                        if index < recentSubmissions(summary).count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            .background(
                Color.appSurface,
                in: RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
                .stroke(Color.appBorder, lineWidth: 1)
            }
        }
    }

    private func recentSubmissions(
        _ summary: CoachParticipantSummary
    ) -> [StepSubmission] {
        Array(
            summary.submissions
                .sorted { $0.submittedAt > $1.submittedAt }
                .prefix(2)
        )
    }

    private func recentActivityRow(
        _ submission: StepSubmission,
        summary: CoachParticipantSummary
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: submissionStatusImage(submission.status))
                .font(.title3)
                .foregroundStyle(submissionStatusColor(submission.status))
                .frame(width: 44, height: 44)
                .background(
                    submissionStatusColor(submission.status).opacity(0.1),
                    in: Circle()
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(stepTitle(submission.stepID, summary: summary))
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)

                Text(submissionStatusTitle(submission.status))
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }

            Spacer()
        }
        .padding(AppSpacing.medium)
        .accessibilityElement(children: .combine)
    }

    private func actionButtons(
        proxy: ScrollViewProxy
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.small) {
                evidenceButton(proxy: proxy)
                progressButton(proxy: proxy)
            }

            VStack(spacing: AppSpacing.small) {
                progressButton(proxy: proxy)
                evidenceButton(proxy: proxy)
            }
        }
    }

    private func evidenceButton(
        proxy: ScrollViewProxy
    ) -> some View {
        Button {
            withAnimation {
                proxy.scrollTo(
                    CoachParticipantDetailSection.evidence,
                    anchor: .top
                )
            }
        } label: {
            Text("coach.participant.action.evidence")
                .font(AppTypography.button)
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundStyle(Color.brandPrimary)
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppRadius.medium,
                        style: .continuous
                    )
                    .stroke(Color.brandPrimary, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("coach.participant.action.evidence")
    }

    private func progressButton(
        proxy: ScrollViewProxy
    ) -> some View {
        Button {
            withAnimation {
                proxy.scrollTo(
                    CoachParticipantDetailSection.progress,
                    anchor: .top
                )
            }
        } label: {
            Text("coach.participant.action.progress")
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .accessibilityIdentifier("coach.participant.action.progress")
    }

    private func evidenceSection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "coach.participant.evidence.title")

            if summary.submissions.isEmpty {
                ContentUnavailableView(
                    "coach.participant.evidence.empty.title",
                    systemImage: "photo.badge.plus",
                    description: Text(
                        "coach.participant.evidence.empty.message"
                    )
                )
                .padding(AppSpacing.medium)
                .frame(maxWidth: .infinity)
                .background(
                    Color.appSurface,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(
                        Array(
                            summary.submissions
                                .sorted {
                                    $0.submittedAt > $1.submittedAt
                                }
                                .enumerated()
                        ),
                        id: \.element.id
                    ) { index, submission in
                        evidenceRow(
                            submission,
                            summary: summary
                        )

                        if index < summary.submissions.count - 1 {
                            Divider()
                                .padding(.leading, AppSpacing.medium)
                        }
                    }
                }
                .background(
                    Color.appSurface,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                    .stroke(Color.appBorder, lineWidth: 1)
                }
            }
        }
    }

    private func evidenceRow(
        _ submission: StepSubmission,
        summary: CoachParticipantSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(stepTitle(submission.stepID, summary: summary))
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)

                    Text(
                        CoachFormatting.dateTime(
                            submission.submittedAt,
                            timeZoneIdentifier:
                                summary.program?.timeZoneIdentifier
                                    ?? "Asia/Makassar"
                        )
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                }

                Spacer(minLength: AppSpacing.small)

                submissionStatusBadge(submission.status)
            }

            ForEach(submission.typedAnswers) { answer in
                if let localPhotoReference = answer.localPhotoReference {
                    Button {
                        selectedEvidence = answer
                    } label: {
                        MediaThumbnail(
                            title: "coach.evidence.thumbnail",
                            systemImage: "photo.fill",
                            kindLabel: "coach.evidence.photo",
                            imageReference: localPhotoReference,
                            showsDemoBadge:
                                LocalMediaImageResolver
                                    .isBundledEvidenceFixture(
                                        localPhotoReference
                                    )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("coach.evidence.open")
                } else if let text = answer.textValue {
                        VStack(
                            alignment: .leading,
                            spacing: AppSpacing.xxSmall
                        ) {
                            Text("coach.evidence.answer")
                                .font(AppTypography.label)
                                .foregroundStyle(
                                    Color.appSecondaryText
                                )
                            Text(text)
                                .font(AppTypography.body)
                                .foregroundStyle(Color.appPrimaryText)
                        }
                        .padding(AppSpacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Color.appSecondaryBackground,
                            in: RoundedRectangle(
                                cornerRadius: AppRadius.medium,
                                style: .continuous
                            )
                        )
                }
            }
        }
        .padding(AppSpacing.medium)
    }

    private func progressDetailSection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "coach.participant.progress.detail.title")

            if let program = summary.program {
                ProgramActivityDaysSection(
                    program: program,
                    days: program.days.sorted {
                        $0.dayNumber < $1.dayNumber
                    },
                    submissions: summary.submissions,
                    focusedDayID: ProgramDayResolver()
                        .activeDay(in: program, at: .now)?
                        .id,
                    referenceDate: .now,
                    capabilities: ProgramActivityCapabilities(
                        audience: .coach,
                        canOpenSteps: false
                    ),
                    accessibilityPrefix: "coach.participant.program",
                    showsSectionTitle: false,
                    accessForDay: {
                        ProgramDayAccessCalculator().access(
                            for: $0,
                            in: program,
                            now: .now
                        )
                    },
                    onOpenStep: { _ in }
                )
            } else {
                Text("coach.participant.timeline.empty")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }
        }
    }

    private func supportingDataSection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        DisclosureGroup(
            isExpanded: $isSupportingDataExpanded
        ) {
            VStack(spacing: AppSpacing.small) {
                supportingDataRow(
                    title: "metric.points",
                    value: CoachFormatting.number(summary.points)
                )
            }
            .padding(.top, AppSpacing.medium)
        } label: {
            Label(
                "coach.participant.supporting_data.title",
                systemImage: "chart.bar.doc.horizontal"
            )
            .font(AppTypography.cardTitle)
            .foregroundStyle(Color.appPrimaryText)
        }
        .padding(AppSpacing.medium)
        .background(
            Color.appSurface,
            in: RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
            .stroke(Color.appBorder, lineWidth: 1)
        }
    }

    private func weightHistorySection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(
                title: "coach.participant.weight_history.title"
            )

            if summary.weighIns.isEmpty {
                EmptyStateView(
                    title: "Belum ada timbang",
                    message:
                        "Timbang awal, harian, dan akhir akan tampil di sini.",
                    systemImage: "scalemass"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(
                        Array(
                            summary.weighIns
                                .sorted { $0.recordedAt > $1.recordedAt }
                                .enumerated()
                        ),
                        id: \.element.id
                    ) { index, weighIn in
                        if index > 0 {
                            Divider()
                                .padding(.leading, AppSpacing.medium)
                        }
                        weightHistoryRow(
                            weighIn,
                            timeZoneIdentifier:
                                summary.program?.timeZoneIdentifier
                                    ?? "Asia/Makassar"
                        )
                    }
                }
                .background(
                    Color.appSurface,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                    .stroke(Color.appBorder, lineWidth: 1)
                }
            }
        }
        .accessibilityIdentifier("coach.participant.weight-history")
    }

    private func weightHistoryRow(
        _ weighIn: WeighIn,
        timeZoneIdentifier: String
    ) -> some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            Image(systemName: "scalemass")
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 44, height: 44)
                .background(
                    Color.brandPrimary.opacity(0.12),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(weightHistoryTitle(weighIn.type))
                    .font(AppTypography.body.weight(.semibold))
                    .foregroundStyle(Color.appPrimaryText)
                Text(
                    CoachFormatting.dateTime(
                        weighIn.recordedAt,
                        timeZoneIdentifier: timeZoneIdentifier
                    )
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
            }

            Spacer(minLength: AppSpacing.small)

            Text(CoachFormatting.weight(weighIn.weightKilograms))
                .font(AppTypography.cardTitle.monospacedDigit())
                .foregroundStyle(Color.appPrimaryText)
        }
        .padding(AppSpacing.medium)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(
            "coach.participant.weight.\(weighIn.id.uuidString)"
        )
    }

    private func weightHistoryTitle(_ type: WeighInType) -> String {
        switch type {
        case .initial:
            String(
                localized: "coach.weigh.kind.initial",
                defaultValue: "Timbang awal"
            )
        case .daily:
            String(
                localized: "coach.weigh.kind.daily",
                defaultValue: "Timbang harian"
            )
        case .final:
            String(
                localized: "coach.weigh.kind.final",
                defaultValue: "Timbang akhir"
            )
        }
    }

    private func supportingDataRow(
        title: LocalizedStringKey,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
            Spacer()
            Text(value)
                .font(AppTypography.body.monospacedDigit())
                .foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private var privacyNotice: some View {
        Label {
            Text("coach.participant.private_data.message")
        } icon: {
            Image(systemName: "lock.shield")
                .foregroundStyle(Color.appWarning)
        }
        .font(AppTypography.label)
        .foregroundStyle(Color.appSecondaryText)
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.appSurface,
            in: RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
    }

    private func stepTitle(
        _ stepID: UUID,
        summary: CoachParticipantSummary
    ) -> String {
        summary.program?
            .days
            .flatMap(\.steps)
            .first { $0.id == stepID }?
            .title
            ?? String(
                localized: "coach.participant.activity.unknown_step",
                defaultValue: "Langkah program"
            )
    }

    private func submissionStatusTitle(
        _ status: SubmissionStatus
    ) -> LocalizedStringKey {
        switch status {
        case .pending:
            "status.pending"
        case .approved:
            "status.approved"
        case .rejected:
            "status.rejected"
        }
    }

    private func submissionStatusImage(
        _ status: SubmissionStatus
    ) -> String {
        switch status {
        case .pending:
            "clock"
        case .approved:
            "checkmark"
        case .rejected:
            "xmark"
        }
    }

    private func submissionStatusColor(
        _ status: SubmissionStatus
    ) -> Color {
        switch status {
        case .pending:
            .appWarning
        case .approved:
            .appSuccess
        case .rejected:
            .appDestructive
        }
    }

    @ViewBuilder
    private func submissionStatusBadge(
        _ status: SubmissionStatus
    ) -> some View {
        switch status {
        case .pending:
            StatusBadge(title: "status.pending", kind: .pending)
        case .approved:
            StatusBadge(title: "status.approved", kind: .success)
        case .rejected:
            StatusBadge(title: "status.rejected", kind: .error)
        }
    }
}

private enum CoachParticipantDetailSection: Hashable {
    case evidence
    case progress
}

private struct CoachParticipantDetailMetric: View {
    let value: String
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 40, height: 40)
                .background(
                    Color.brandPrimary.opacity(0.08),
                    in: Circle()
                )
                .accessibilityHidden(true)

            Text(value)
                .font(AppTypography.sectionTitle.monospacedDigit())
                .foregroundStyle(Color.appPrimaryText)

            Text(title)
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.xSmall)
        .accessibilityElement(children: .combine)
    }
}

struct CoachEvidenceViewer: View {
    @Environment(\.dismiss) private var dismiss
    let evidence: StepSubmissionAnswer

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    evidencePreview

                    if LocalMediaImageResolver.isBundledEvidenceFixture(
                        evidence.localPhotoReference ?? ""
                    ) {
                        Label(
                            "coach.evidence.demo_badge",
                            systemImage: "shippingbox.fill"
                        )
                        .font(AppTypography.label)
                        .foregroundStyle(Color.appSecondaryText)
                    }

                    Label(
                        "coach.evidence.viewer.privacy",
                        systemImage: "lock.fill"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appPrimaryText)
                }
                .frame(maxWidth: 620)
                .padding(AppSpacing.large)
                .frame(maxWidth: .infinity)
            }
            .background(Color.appBackground)
            .navigationTitle(
                Text("coach.evidence.viewer.navigation_title")
            )
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

    @ViewBuilder
    private var evidencePreview: some View {
        if let image = LocalMediaImageResolver.image(
            reference: evidence.localPhotoReference ?? ""
        ) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 600)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )
                .accessibilityLabel(Text("coach.evidence.thumbnail"))
                .accessibilityIdentifier("coach.evidence.viewer.image")
        } else {
            VStack(spacing: AppSpacing.small) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(Color.appDestructive)
                    .accessibilityHidden(true)
                Text("coach.evidence.viewer.title")
                    .font(AppTypography.sectionTitle)
                Text("coach.evidence.unavailable.message")
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(AppSpacing.large)
            .frame(maxWidth: .infinity, minHeight: 280)
            .background(
                Color.appSecondaryBackground,
                in: RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
            )
        }
    }
}
