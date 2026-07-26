import SwiftUI

@MainActor
struct ParticipantTodayView: View {
    let store: ParticipantJourneyStore
    let router: ShellTabRouter

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if store.entryStage != .complete {
            ParticipantEntryFlowView(store: store)
        } else if store.currentEnrollment == nil {
            EmptyStateView(
                title: "participant.today.empty.title",
                message: "participant.today.empty.message",
                systemImage: "calendar.badge.exclamationmark"
            )
        } else if let program = store.currentProgram {
            List {
                if store.showsOfflineSimulation {
                    OfflineBanner()
                }

                programHeader(program)
                weighInSection
                todayStepsSection

                if store.isTodayComplete {
                    completionCelebration
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .accessibilityIdentifier("participant.today")
        } else {
            EmptyStateView(
                title: "participant.today.empty.title",
                message: "participant.today.empty.message",
                systemImage: "calendar.badge.exclamationmark"
            )
        }
    }

    private func programHeader(_ program: Program) -> some View {
        Section {
            ProgramCard(
                title: LocalizedStringKey(program.title),
                summary: program.summary,
                statusTitle: "status.active",
                statusKind: .success,
                progress: Double(store.overallProgress) / 100
            )

            if let day = store.todayDay {
                LabeledContent(
                    "participant.today.day",
                    value: day.dayNumber.formatted(
                        .number.locale(ParticipantFormatting.locale)
                    )
                )
                LabeledContent(
                    "participant.today.date",
                    value: ParticipantFormatting.date(
                        day.scheduledDate,
                        timeZoneIdentifier: program.timeZoneIdentifier
                    )
                )
            } else {
                LockedContentView(
                    title: "participant.today.unavailable.title",
                    message: "participant.today.unavailable.message"
                )
            }

            HStack(spacing: AppSpacing.medium) {
                ProgressRing(
                    progress: Double(store.overallProgress) / 100,
                    label: "metric.progress"
                )
                MetricCard(
                    title: "metric.progress",
                    value: ParticipantFormatting.percentage(
                        store.overallProgress
                    ),
                    systemImage: "chart.line.uptrend.xyaxis"
                )
            }
        } header: {
            SectionHeader(
                title: "participant.today.header",
                subtitle: "participant.today.subtitle"
            )
        }
    }

    @ViewBuilder
    private var weighInSection: some View {
        Section {
            if let initial = store.initialWeighIn {
                LabeledContent(
                    "participant.weigh.initial.label",
                    value: ParticipantFormatting.weight(
                        initial.weightKilograms
                    )
                )
                .accessibilityIdentifier(
                    "participant.weigh.initial.completed"
                )
            } else {
                Button {
                    router.navigate(
                        to: .participant(.weighIn(.initial)),
                        in: .participant(.today)
                    )
                } label: {
                    Label(
                        "participant.weigh.initial.action",
                        systemImage: "scalemass"
                    )
                }
            }

            if isLastProgramDay {
                if let final = store.finalWeighIn {
                    LabeledContent(
                        "participant.weigh.final.label",
                        value: ParticipantFormatting.weight(
                            final.weightKilograms
                        )
                    )
                } else {
                    Button {
                        router.navigate(
                            to: .participant(.weighIn(.final)),
                            in: .participant(.today)
                        )
                    } label: {
                        Label(
                            "participant.weigh.final.action",
                            systemImage: "flag.checkered"
                        )
                    }
                }
            }
        } header: {
            Text("participant.weigh.section")
        } footer: {
            Text("participant.weigh.private_footer")
        }
    }

    @ViewBuilder
    private var todayStepsSection: some View {
        Section {
            if let day = store.todayDay {
                let access = store.access(for: day)
                if access == .locked || access == .hidden {
                    LockedContentView(
                        title: "state.locked.title",
                        message: "state.locked.message"
                    )
                } else if day.steps.isEmpty {
                    EmptyStateView(
                        title: "participant.today.steps.empty.title",
                        message: "participant.today.steps.empty.message",
                        systemImage: "checklist"
                    )
                } else {
                    ForEach(day.steps.sorted(by: { $0.order < $1.order })) {
                        step in
                        let submission = store.submission(for: step.id)
                        let presentation = ParticipantStepPresentation.make(
                            submission: submission,
                            access: access
                        )
                        Button {
                            router.navigate(
                                to: .participant(.stepDetail(step.id)),
                                in: .participant(.today)
                            )
                        } label: {
                            StepRow(
                                title: LocalizedStringKey(step.title),
                                detail: step.instructions,
                                points: step.points,
                                statusTitle: LocalizedStringKey(
                                    presentation.titleKey
                                ),
                                statusKind: presentation.kind
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(
                            "participant.step.open.\(step.order)"
                        )
                    }
                }
            }
        } header: {
            Text("participant.today.steps.title")
        }
    }

    private var completionCelebration: some View {
        Section {
            VStack(spacing: AppSpacing.small) {
                Image(systemName: "party.popper.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.brandAccent)
                    .scaleEffect(store.isTodayComplete ? 1 : 0.9)
                    .animation(
                        AppMotion.standard(reduceMotion: reduceMotion),
                        value: store.isTodayComplete
                    )
                    .accessibilityHidden(true)
                Text("participant.today.complete.title")
                    .font(AppTypography.sectionTitle)
                Text("participant.today.complete.message")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.medium)
            .accessibilityElement(children: .combine)
        }
    }

    private var isLastProgramDay: Bool {
        guard let current = store.todayDay?.dayNumber,
              let last = store.currentProgram?.days.map(\.dayNumber).max()
        else {
            return false
        }
        return current == last
    }
}

#Preview("Today — aktif sebagian") {
    ParticipantTodayPreview(day: 3)
}

#Preview("Today — selesai") {
    ParticipantTodayPreview(day: 3, completesDay: true)
}

#Preview("Today — tanpa enrollment") {
    ParticipantTodayEmptyPreview()
}

#Preview("Today — Dynamic Type terbesar") {
    ParticipantTodayPreview(day: 3)
        .dynamicTypeSize(.accessibility5)
}

#Preview("Today — gelap") {
    ParticipantTodayPreview(day: 3)
        .preferredColorScheme(.dark)
}

@MainActor
private struct ParticipantTodayPreview: View {
    let day: Int
    var completesDay = false
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )
    @State private var router = ShellTabRouter()

    var body: some View {
        NavigationStack {
            ParticipantTodayView(store: store, router: router)
                .task {
                    await store.load()
                    store.selectDay(day)
                    if completesDay, let currentDay = store.todayDay {
                        for step in currentDay.steps {
                            try? await store.completeStep(
                                step,
                                localPhotoReference:
                                    "local-demo://preview/evidence",
                                textAnswer: "Jawaban preview lokal."
                            )
                        }
                    }
                }
        }
    }
}

@MainActor
private struct ParticipantTodayEmptyPreview: View {
    @State private var store = ParticipantJourneyStore(
        environment: .preview,
        startsWithoutEnrollment: true
    )
    @State private var router = ShellTabRouter()

    var body: some View {
        ParticipantTodayView(store: store, router: router)
            .task {
                await store.load()
                store.entryStage = .complete
            }
    }
}
