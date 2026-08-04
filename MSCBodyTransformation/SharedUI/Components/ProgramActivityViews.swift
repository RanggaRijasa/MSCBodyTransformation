import SwiftUI

nonisolated enum ProgramActivityAudience: String, Sendable {
    case participant
    case coach
}

nonisolated struct ProgramActivityCapabilities: Sendable {
    let audience: ProgramActivityAudience
    let canOpenSteps: Bool
}

nonisolated struct ProgramActivityDayUIState: Equatable, Sendable {
    let showsActivities: Bool
    let allowsStepNavigation: Bool
    let allowsCompletion: Bool
    let showsUnavailableMessage: Bool

    init(access: ProgramDayAccess) {
        switch access {
        case .available:
            showsActivities = true
            allowsStepNavigation = true
            allowsCompletion = true
            showsUnavailableMessage = false
        case .readOnly:
            showsActivities = true
            allowsStepNavigation = true
            allowsCompletion = false
            showsUnavailableMessage = false
        case .locked, .hidden:
            showsActivities = false
            allowsStepNavigation = false
            allowsCompletion = false
            showsUnavailableMessage = true
        }
    }
}

struct CoachProgramParticipantContext: View {
    let displayName: String
    let imageName: String?
    let accessibilityIdentifier: String

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            UserAvatar(
                displayName: displayName,
                imageName: imageName,
                size: 52
            )

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(
                    String(
                        localized: "coach.program.monitored_participant",
                        defaultValue: "Peserta yang dipantau"
                    )
                )
                .font(AppTypography.label)
                .foregroundStyle(Color.appSecondaryText)

                Text(displayName)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
            }
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

struct ProgramActivityRenderer: View {
    let program: Program
    let submissions: [StepSubmission]
    let focusedDayID: UUID?
    let referenceDate: Date
    let capabilities: ProgramActivityCapabilities
    let accessibilityPrefix: String
    let accessForDay: (ProgramDay) -> ProgramDayAccess
    let onOpenStep: (ProgramStep) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            ProgramActivityHeader(
                program: program,
                submissions: submissions
            )

            ProgramActivityDaysSection(
                program: program,
                days: program.days.sorted {
                    $0.dayNumber < $1.dayNumber
                },
                submissions: submissions,
                focusedDayID: focusedDayID,
                referenceDate: referenceDate,
                capabilities: capabilities,
                accessibilityPrefix: accessibilityPrefix,
                showsSectionTitle: true,
                accessForDay: accessForDay,
                onOpenStep: onOpenStep
            )
        }
    }
}

struct ProgramActivityHeader: View {
    let program: Program
    let submissions: [StepSubmission]

    private var programStepIDs: Set<UUID> {
        Set(program.days.flatMap(\.steps).map(\.id))
    }

    private var completedStepCount: Int {
        Set(
            submissions
                .filter { $0.status != .rejected }
                .map(\.stepID)
        )
        .intersection(programStepIDs)
        .count
    }

    private var totalStepCount: Int {
        programStepIDs.count
    }

    private var progress: Double {
        guard totalStepCount > 0 else { return 0 }
        return Double(completedStepCount) / Double(totalStepCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            ProgramCoverImage(
                reference: program.coverLocalReference,
                alternativeText:
                    program.coverAlternativeText
                    ?? String(
                        localized: "program.cover.default_alternative",
                        defaultValue: "Cover program"
                    )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
            )

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(program.title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(periodText)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                HStack(alignment: .firstTextBaseline) {
                    Text(
                        String(
                            localized: "program.activity.progress",
                            defaultValue: "Progres program"
                        )
                    )
                    .font(AppTypography.label.weight(.semibold))
                    .foregroundStyle(Color.appPrimaryText)

                    Spacer(minLength: AppSpacing.small)

                    progressLabel
                        .font(AppTypography.label.monospacedDigit())
                        .foregroundStyle(Color.appSecondaryText)
                }

                ProgressView(value: progress)
                    .tint(Color.brandPrimary)
                    .accessibilityLabel(
                        Text(
                            String(
                                localized: "program.activity.progress",
                                defaultValue: "Progres program"
                            )
                        )
                    )
                    .accessibilityValue(progressLabel)
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
        .accessibilityIdentifier("program.activity.header")
    }

    private var periodText: String {
        let firstDate = program.days.map(\.scheduledDate).min()
            ?? program.startDate
        let lastDate = program.days.map(\.scheduledDate).max()
            ?? program.endDate
        let start = ProgramActivityFormatting.date(
            firstDate,
            timeZoneIdentifier: program.timeZoneIdentifier
        )
        let end = ProgramActivityFormatting.date(
            lastDate,
            timeZoneIdentifier: program.timeZoneIdentifier
        )
        return "\(start) – \(end)"
    }

    private var progressLabel: Text {
        let completed = Text(
            completedStepCount,
            format: .number.locale(ProgramActivityFormatting.locale)
        )
        let total = Text(
            totalStepCount,
            format: .number.locale(ProgramActivityFormatting.locale)
        )
        return Text(
            "\(completed) \(Text("participant.program.activity.of")) \(total) \(Text("participant.program.activity.steps_completed"))"
        )
    }
}

struct ProgramActivityDaysSection: View {
    let program: Program
    let days: [ProgramDay]
    let submissions: [StepSubmission]
    let focusedDayID: UUID?
    let referenceDate: Date
    let capabilities: ProgramActivityCapabilities
    let accessibilityPrefix: String
    let showsSectionTitle: Bool
    let accessForDay: (ProgramDay) -> ProgramDayAccess
    let onOpenStep: (ProgramStep) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            if showsSectionTitle {
                Text(
                    String(
                        localized: "program.activity.title",
                        defaultValue: "Aktivitas program"
                    )
                )
                .font(AppTypography.sectionTitle)
                .foregroundStyle(Color.appPrimaryText)
                .accessibilityAddTraits(.isHeader)
            }

            if days.isEmpty {
                ContentUnavailableView {
                    Label(
                        "participant.program.timeline.empty.title",
                        systemImage: "calendar"
                    )
                } description: {
                    Text("participant.program.timeline.empty.message")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.large)
            } else {
                LazyVStack(spacing: AppSpacing.small) {
                    ForEach(days) { day in
                        ProgramActivityDayAccordion(
                            day: day,
                            access: accessForDay(day),
                            timeZoneIdentifier:
                                program.timeZoneIdentifier,
                            submissions: submissions,
                            isFocusedDay: day.id == focusedDayID,
                            referenceDate: referenceDate,
                            capabilities: capabilities,
                            accessibilityPrefix: accessibilityPrefix,
                            onOpenStep: onOpenStep
                        )
                        .id(day.id)
                    }
                }
            }
        }
    }
}

struct ProgramActivityDayAccordion: View {
    let day: ProgramDay
    let access: ProgramDayAccess
    let timeZoneIdentifier: String
    let submissions: [StepSubmission]
    let isFocusedDay: Bool
    let referenceDate: Date
    let capabilities: ProgramActivityCapabilities
    let accessibilityPrefix: String
    let onOpenStep: (ProgramStep) -> Void

    @State private var isExpanded: Bool

    init(
        day: ProgramDay,
        access: ProgramDayAccess,
        timeZoneIdentifier: String,
        submissions: [StepSubmission],
        isFocusedDay: Bool,
        referenceDate: Date,
        capabilities: ProgramActivityCapabilities,
        accessibilityPrefix: String,
        onOpenStep: @escaping (ProgramStep) -> Void
    ) {
        self.day = day
        self.access = access
        self.timeZoneIdentifier = timeZoneIdentifier
        self.submissions = submissions
        self.isFocusedDay = isFocusedDay
        self.referenceDate = referenceDate
        self.capabilities = capabilities
        self.accessibilityPrefix = accessibilityPrefix
        self.onOpenStep = onOpenStep
        _isExpanded = State(initialValue: isFocusedDay)
    }

    private var sortedSteps: [ProgramStep] {
        day.steps.sorted { $0.order < $1.order }
    }

    private var completedStepCount: Int {
        Set(
            submissions
                .filter { $0.status != .rejected }
                .map(\.stepID)
        )
        .intersection(Set(day.steps.map(\.id)))
        .count
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggleExpansion) {
                HStack(alignment: .center, spacing: AppSpacing.medium) {
                    dayIcon

                    VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                        dayTitle
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(Color.appPrimaryText)
                            .multilineTextAlignment(.leading)

                        Text(day.title)
                            .font(AppTypography.secondary)
                            .foregroundStyle(Color.appSecondaryText)
                            .multilineTextAlignment(.leading)

                        dayProgressLabel
                            .font(AppTypography.label.monospacedDigit())
                            .foregroundStyle(statusColor)
                    }

                    Spacer(minLength: AppSpacing.small)

                    Image(
                        systemName: isExpanded
                            ? "chevron.up"
                            : "chevron.down"
                    )
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appSecondaryText)
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
                }
                .padding(AppSpacing.medium)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(
                "\(accessibilityPrefix).day.\(day.dayNumber)"
            )
            .accessibilityValue(
                Text(
                    LocalizedStringKey(
                        isExpanded
                            ? "participant.program.activity.expanded"
                            : "participant.program.activity.collapsed"
                    )
                )
            )

            if isExpanded {
                Divider()
                    .padding(.leading, AppSpacing.medium)

                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            Color.appSurface,
            in: RoundedRectangle(
                cornerRadius: AppRadius.medium,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppRadius.medium,
                style: .continuous
            )
            .stroke(
                isFocusedDay
                    ? Color.brandPrimary.opacity(0.55)
                    : Color.appBorder,
                lineWidth: isFocusedDay ? 1.5 : 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppRadius.medium,
                style: .continuous
            )
        )
        .onChange(of: isFocusedDay) { _, shouldExpand in
            updateExpansionForFocusedDay(shouldExpand)
        }
    }

    private var dayIcon: some View {
        Image(systemName: dayIconName)
            .font(.body.weight(.semibold))
            .foregroundStyle(
                AppStatusStyle.style(for: statusKind).foregroundColor
            )
            .frame(width: 44, height: 44)
            .background(
                AppStatusStyle.style(for: statusKind).backgroundColor,
                in: Circle()
            )
            .accessibilityHidden(true)
    }

    private var dayIconName: String {
        switch access {
        case .locked, .hidden:
            "calendar.badge.exclamationmark"
        case .available, .readOnly:
            "calendar"
        }
    }

    private var dayTitle: Text {
        if isFocusedDay {
            return Text(
                "Hari ini • Hari ke-\(day.dayNumber, format: .number.locale(ProgramActivityFormatting.locale))"
            )
        }
        if isTomorrow {
            return Text(
                "Besok • Hari ke-\(day.dayNumber, format: .number.locale(ProgramActivityFormatting.locale))"
            )
        }
        return Text(
            "Hari ke-\(day.dayNumber, format: .number.locale(ProgramActivityFormatting.locale))"
        )
    }

    @ViewBuilder
    private var expandedContent: some View {
        if dayUIState.showsUnavailableMessage {
            ProgramActivityUnavailableActivities(
                message: "participant.program.activity.locked"
            )
        } else if dayUIState.showsActivities {
            if sortedSteps.isEmpty {
                ProgramActivityUnavailableActivities(
                    message: "participant.program.activity.empty"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(
                        Array(sortedSteps.enumerated()),
                        id: \.element.id
                    ) { item in
                        let index = item.offset
                        let step = item.element
                        ProgramActivityStepRow(
                            step: step,
                            dayNumber: day.dayNumber,
                            submission: submission(for: step.id),
                            capabilities: capabilities,
                            canOpen:
                                capabilities.canOpenSteps
                                && dayUIState.allowsStepNavigation,
                            accessibilityPrefix: accessibilityPrefix,
                            onOpen: { onOpenStep(step) }
                        )

                        if index < sortedSteps.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
    }

    private var dayUIState: ProgramActivityDayUIState {
        ProgramActivityDayUIState(access: access)
    }

    private var isTomorrow: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        guard let tomorrow = calendar.date(
            byAdding: .day,
            value: 1,
            to: referenceDate
        ) else {
            return false
        }
        return calendar.isDate(day.scheduledDate, inSameDayAs: tomorrow)
    }

    private var dayProgressLabel: Text {
        let completed = Text(
            completedStepCount,
            format: .number.locale(ProgramActivityFormatting.locale)
        )
        let total = Text(
            day.steps.count,
            format: .number.locale(ProgramActivityFormatting.locale)
        )
        return Text(
            "\(completed)/\(total) \(Text("participant.program.activity.steps"))"
        )
    }

    private var statusColor: Color {
        AppStatusStyle.style(for: statusKind).foregroundColor
    }

    private var statusKind: AppStatusKind {
        switch access {
        case .available:
            .information
        case .readOnly:
            completedStepCount == day.steps.count ? .success : .neutral
        case .locked:
            .locked
        case .hidden:
            .neutral
        }
    }

    private func submission(for stepID: UUID) -> StepSubmission? {
        submissions.first { $0.stepID == stepID }
    }

    private func toggleExpansion() {
        withAnimation(.snappy(duration: 0.24)) {
            isExpanded.toggle()
        }
    }

    private func updateExpansionForFocusedDay(_ shouldExpand: Bool) {
        withAnimation(.snappy(duration: 0.24)) {
            isExpanded = shouldExpand
        }
    }
}

struct ProgramActivityStepRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let step: ProgramStep
    let dayNumber: Int
    let submission: StepSubmission?
    let capabilities: ProgramActivityCapabilities
    let canOpen: Bool
    let accessibilityPrefix: String
    let onOpen: () -> Void

    var body: some View {
        Group {
            if canOpen {
                Button(action: onOpen) {
                    rowContent(showsChevron: true)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(
                    "\(accessibilityPrefix).step.\(dayNumber).\(step.order)"
                )
            } else {
                rowContent(showsChevron: false)
            }
        }
    }

    private func rowContent(showsChevron: Bool) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    stepIdentity
                    statusBadge
                }
            } else {
                HStack(spacing: AppSpacing.medium) {
                    stepIdentity
                    Spacer(minLength: AppSpacing.small)
                    statusBadge
                    if showsChevron {
                        chevron
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var stepIdentity: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: presentation.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(
                    AppStatusStyle.style(for: presentation.kind)
                        .foregroundColor
                )
                .frame(width: 44, height: 44)
                .background(
                    AppStatusStyle.style(for: presentation.kind)
                        .backgroundColor,
                    in: Circle()
                )
                .accessibilityHidden(true)

            Text(step.title)
                .font(AppTypography.body.weight(.semibold))
                .foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusBadge: some View {
        StatusBadge(
            title: LocalizedStringKey(presentation.statusKey),
            kind: presentation.kind
        )
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.appSecondaryText)
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)
    }

    private var presentation: ProgramActivityStepPresentation {
        ProgramActivityStepPresentation(
            step: step,
            submission: submission,
            audience: capabilities.audience
        )
    }
}

private struct ProgramActivityUnavailableActivities: View {
    let message: LocalizedStringKey

    var body: some View {
        Label(message, systemImage: "lock.fill")
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.medium)
    }
}

private struct ProgramActivityStepPresentation {
    let statusKey: String
    let systemImage: String
    let kind: AppStatusKind

    init(
        step: ProgramStep,
        submission: StepSubmission?,
        audience: ProgramActivityAudience
    ) {
        guard let submission else {
            statusKey = "participant.status.not_started"
            systemImage = Self.contentSystemImage(for: step.content?.kind)
            kind = .neutral
            return
        }

        switch submission.status {
        case .pending:
            statusKey = "status.pending"
            systemImage = "clock.fill"
            kind = .pending
        case .approved:
            statusKey =
                audience == .coach && Self.isWeighIn(step)
                ? "coach.program.weigh_recorded"
                : "status.completed"
            systemImage = "checkmark.circle.fill"
            kind = .success
        case .rejected:
            statusKey = "status.rejected"
            systemImage = "exclamationmark.triangle.fill"
            kind = .error
        }
    }

    private static func isWeighIn(_ step: ProgramStep) -> Bool {
        switch step.content?.kind {
        case .initialWeighIn, .dailyWeighIn, .finalWeighIn:
            true
        case .article, .video, .form, .quiz, nil:
            false
        }
    }

    private static func contentSystemImage(
        for kind: ProgramContentKind?
    ) -> String {
        switch kind {
        case .article:
            "doc.text"
        case .video:
            "play.rectangle"
        case .form:
            "list.clipboard"
        case .quiz:
            "questionmark.circle"
        case .initialWeighIn, .dailyWeighIn, .finalWeighIn:
            "scalemass"
        case nil:
            "circle"
        }
    }
}

private enum ProgramActivityFormatting {
    static let locale = Locale(identifier: "id-ID")

    static func date(
        _ date: Date,
        timeZoneIdentifier: String
    ) -> String {
        var format = Date.FormatStyle()
            .day()
            .month(.wide)
            .year()
            .locale(locale)
        format.timeZone =
            TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        return date.formatted(format)
    }
}
