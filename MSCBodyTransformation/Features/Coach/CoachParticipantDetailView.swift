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

    @State private var selectedEvidence: SubmissionEvidence?
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
        case .pending:
            StatusBadge(title: "coach.enrollment.pending", kind: .pending)
        case .cancelled:
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

            ForEach(submission.evidence) { evidence in
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
                    .accessibilityIdentifier("coach.evidence.open")
                case .text:
                    if let answer = evidence.textValue {
                        VStack(
                            alignment: .leading,
                            spacing: AppSpacing.xxSmall
                        ) {
                            Text("coach.evidence.answer")
                                .font(AppTypography.label)
                                .foregroundStyle(
                                    Color.appSecondaryText
                                )
                            Text(answer)
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
        }
        .padding(AppSpacing.medium)
    }

    private func progressDetailSection(
        _ summary: CoachParticipantSummary
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "coach.participant.progress.detail.title")

            if let program = summary.program {
                VStack(spacing: 0) {
                    ForEach(
                        Array(
                            program.days
                                .sorted {
                                    $0.dayNumber < $1.dayNumber
                                }
                                .enumerated()
                        ),
                        id: \.element.id
                    ) { index, day in
                        CoachParticipantProgressDayDisclosure(
                            day: day,
                            submissions: summary.submissions
                        )

                        if index < program.days.count - 1 {
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
                    title: "participant.weigh.initial.label",
                    value: summary.initialWeighIn.map {
                        CoachFormatting.weight($0.weightKilograms)
                    } ?? String(
                        localized: "coach.weight.unavailable",
                        defaultValue: "Belum tersedia"
                    )
                )
                Divider()
                supportingDataRow(
                    title: "participant.weigh.final.label",
                    value: summary.finalWeighIn.map {
                        CoachFormatting.weight($0.weightKilograms)
                    } ?? String(
                        localized: "coach.weight.unavailable",
                        defaultValue: "Belum tersedia"
                    )
                )
                Divider()
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

private struct CoachParticipantProgressDayDisclosure: View {
    let day: ProgramDay
    let submissions: [StepSubmission]

    private var completedCount: Int {
        day.steps.filter { step in
            submissions.contains { $0.stepID == step.id }
        }.count
    }

    var body: some View {
        DisclosureGroup {
            VStack(spacing: AppSpacing.small) {
                ForEach(day.steps.sorted { $0.order < $1.order }) { step in
                    HStack(alignment: .firstTextBaseline) {
                        Text(step.title)
                            .font(AppTypography.body)
                            .foregroundStyle(Color.appPrimaryText)

                        Spacer(minLength: AppSpacing.small)

                        stepStatus(
                            submissions.first {
                                $0.stepID == step.id
                            }
                        )
                    }
                }
            }
            .padding(.top, AppSpacing.small)
        } label: {
            VStack(
                alignment: .leading,
                spacing: AppSpacing.xxSmall
            ) {
                Text(
                    "\(Text("participant.day.label")) \(Text(day.dayNumber, format: .number.locale(CoachFormatting.locale))) — \(Text(day.title))"
                )
                .font(AppTypography.cardTitle)
                .foregroundStyle(Color.appPrimaryText)

                Text(
                    String(
                        format: String(
                            localized:
                                "coach.timeline.completion_format",
                            defaultValue:
                                "%lld dari %lld langkah dikirim"
                        ),
                        completedCount,
                        day.steps.count
                    )
                )
                .font(AppTypography.secondary.monospacedDigit())
                .foregroundStyle(Color.appSecondaryText)
            }
        }
        .padding(AppSpacing.medium)
    }

    @ViewBuilder
    private func stepStatus(
        _ submission: StepSubmission?
    ) -> some View {
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
            StatusBadge(title: "coach.step.missing", kind: .neutral)
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
}
