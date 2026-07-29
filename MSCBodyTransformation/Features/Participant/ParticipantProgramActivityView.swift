import SwiftUI

@MainActor
struct ParticipantProgramActivityView: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    let program: Program
    let store: ParticipantJourneyStore
    let router: ShellTabRouter
    let navigationTab: ParticipantTab

    private var sortedDays: [ProgramDay] {
        program.days.sorted { $0.dayNumber < $1.dayNumber }
    }

    private var submissions: [StepSubmission] {
        store.snapshot?.submissions ?? []
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

    private var programStepIDs: Set<UUID> {
        Set(program.days.flatMap(\.steps).map(\.id))
    }

    private var focusedDayID: UUID? {
        ProgramDayResolver()
            .activeDay(in: program, at: store.effectiveDate)?
            .id
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                    ParticipantProgramActivityHeader(
                        program: program,
                        completedStepCount: completedStepCount,
                        totalStepCount: totalStepCount
                    )

                    ParticipantProgramDaysSection(
                        program: program,
                        days: sortedDays,
                        submissions: submissions,
                        focusedDayID: focusedDayID,
                        accessForDay: access,
                        canOpenSteps: program.id == store.currentProgram?.id,
                        onOpenStep: openStep
                    )
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.large)
                .frame(maxWidth: .infinity)
            }
            .task(id: focusedDayID) {
                scrollToFocusedDay(using: proxy)
            }
        }
        .background(Color.appBackground)
        .accessibilityIdentifier("participant.program.detail")
        .navigationTitle(program.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func access(for day: ProgramDay) -> ProgramDayAccess {
        if program.id == store.currentProgram?.id {
            return store.access(for: day)
        }
        return ProgramDayAccessCalculator().access(
            for: day,
            now: store.effectiveDate,
            timeZoneIdentifier: program.timeZoneIdentifier
        )
    }

    private func openStep(_ step: ProgramStep) {
        router.navigate(
            to: .participant(.stepDetail(step.id)),
            in: .participant(navigationTab)
        )
    }

    private func scrollToFocusedDay(using proxy: ScrollViewProxy) {
        guard let focusedDayID else { return }
        if reduceMotion {
            proxy.scrollTo(focusedDayID, anchor: .top)
        } else {
            withAnimation(.easeInOut(duration: 0.28)) {
                proxy.scrollTo(focusedDayID, anchor: .top)
            }
        }
    }
}

private struct ParticipantProgramActivityHeader: View {
    let program: Program
    let completedStepCount: Int
    let totalStepCount: Int

    private var progress: Double {
        guard totalStepCount > 0 else { return 0 }
        return Double(completedStepCount) / Double(totalStepCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(program.title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(Color.appPrimaryText)

                Text(periodText)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                HStack {
                    Text("participant.program.activity.progress")
                        .font(AppTypography.label.weight(.semibold))
                        .foregroundStyle(Color.appPrimaryText)

                    Spacer()

                    progressLabel
                        .font(AppTypography.label.monospacedDigit())
                        .foregroundStyle(Color.appSecondaryText)
                }

                ProgressView(value: progress)
                    .tint(Color.brandPrimary)
                    .accessibilityValue(
                        Text(
                            completedStepCount,
                            format: .number.locale(
                                ParticipantFormatting.locale
                            )
                        )
                    )
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
    }

    private var periodText: String {
        let firstDate = program.days.map(\.scheduledDate).min()
            ?? program.startDate
        let lastDate = program.days.map(\.scheduledDate).max()
            ?? program.endDate
        let start = ParticipantFormatting.date(
            firstDate,
            timeZoneIdentifier: program.timeZoneIdentifier
        )
        let end = ParticipantFormatting.date(
            lastDate,
            timeZoneIdentifier: program.timeZoneIdentifier
        )
        return "\(start) – \(end)"
    }

    private var progressLabel: Text {
        let completed = Text(
            completedStepCount,
            format: .number.locale(ParticipantFormatting.locale)
        )
        let total = Text(
            totalStepCount,
            format: .number.locale(ParticipantFormatting.locale)
        )
        return Text(
            "\(completed) \(Text("participant.program.activity.of")) \(total) \(Text("participant.program.activity.steps_completed"))"
        )
    }
}

private struct ParticipantProgramDaysSection: View {
    let program: Program
    let days: [ProgramDay]
    let submissions: [StepSubmission]
    let focusedDayID: UUID?
    let accessForDay: (ProgramDay) -> ProgramDayAccess
    let canOpenSteps: Bool
    let onOpenStep: (ProgramStep) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("participant.program.activity.title")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(Color.appPrimaryText)

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
                        let access = accessForDay(day)
                        ParticipantProgramDayAccordion(
                            day: day,
                            access: access,
                            timeZoneIdentifier: program.timeZoneIdentifier,
                            submissions: submissions,
                            canOpenSteps: canOpenSteps,
                            isFocusedDay: day.id == focusedDayID,
                            onOpenStep: onOpenStep
                        )
                        .id(day.id)
                    }
                }
            }
        }
    }
}
