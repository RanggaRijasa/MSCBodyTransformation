import SwiftUI

struct ParticipantProgramDayAccordion: View {
    let day: ProgramDay
    let access: ProgramDayAccess
    let timeZoneIdentifier: String
    let submissions: [StepSubmission]
    let canOpenSteps: Bool
    let isFocusedDay: Bool
    let onOpenStep: (ProgramStep) -> Void

    @State private var isExpanded: Bool

    init(
        day: ProgramDay,
        access: ProgramDayAccess,
        timeZoneIdentifier: String,
        submissions: [StepSubmission],
        canOpenSteps: Bool,
        isFocusedDay: Bool,
        onOpenStep: @escaping (ProgramStep) -> Void
    ) {
        self.day = day
        self.access = access
        self.timeZoneIdentifier = timeZoneIdentifier
        self.submissions = submissions
        self.canOpenSteps = canOpenSteps
        self.isFocusedDay = isFocusedDay
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
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text(day.scheduledDate, format: dateFormat)
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(Color.appPrimaryText)
                            .multilineTextAlignment(.leading)

                        Text(day.title)
                            .font(AppTypography.secondary)
                            .foregroundStyle(Color.appSecondaryText)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: AppSpacing.xSmall) {
                            dayProgressLabel
                                .font(
                                    AppTypography.label.monospacedDigit()
                                )
                                .foregroundStyle(statusColor)

                            if isFocusedDay {
                                Text("participant.program.activity.today")
                                    .font(
                                        AppTypography.label.weight(.semibold)
                                    )
                                    .foregroundStyle(Color.brandPrimary)
                            }
                        }
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
                "participant.program.day.\(day.dayNumber)"
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

    @ViewBuilder
    private var expandedContent: some View {
        if dayUIState.showsUnavailableMessage {
            ParticipantProgramUnavailableActivities(
                message: "participant.program.activity.locked"
            )
        } else if dayUIState.showsActivities {
            if sortedSteps.isEmpty {
                ParticipantProgramUnavailableActivities(
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
                        ParticipantProgramStepRow(
                            step: step,
                            dayNumber: day.dayNumber,
                            submission: submission(for: step.id),
                            canOpen:
                                canOpenSteps
                                && dayUIState.allowsStepNavigation,
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

    private var dayUIState: ParticipantProgramDayUIState {
        ParticipantProgramDayUIState(access: access)
    }

    private var dateFormat: Date.FormatStyle {
        var format = Date.FormatStyle()
            .weekday(.wide)
            .day()
            .month(.wide)
            .year()
            .locale(ParticipantFormatting.locale)
        format.timeZone =
            TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        return format
    }

    private var dayProgressLabel: Text {
        let completed = Text(
            completedStepCount,
            format: .number.locale(ParticipantFormatting.locale)
        )
        let total = Text(
            day.steps.count,
            format: .number.locale(ParticipantFormatting.locale)
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

private struct ParticipantProgramUnavailableActivities: View {
    let message: LocalizedStringKey

    var body: some View {
        Label(message, systemImage: "lock.fill")
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.medium)
    }
}
