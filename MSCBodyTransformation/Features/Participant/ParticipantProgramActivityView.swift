import SwiftUI

@MainActor
struct ParticipantProgramActivityView: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    let program: Program
    let store: ParticipantJourneyStore
    let router: ShellTabRouter
    let navigationContext: ProgramParticipationNavigationContext

    private var submissions: [StepSubmission] {
        store.snapshot?.submissions ?? []
    }

    private var focusedDayID: UUID? {
        ProgramDayResolver()
            .activeDay(in: program, at: store.effectiveDate)?
            .id
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ProgramActivityRenderer(
                    program: program,
                    submissions: submissions,
                    focusedDayID: focusedDayID,
                    referenceDate: store.effectiveDate,
                    capabilities: ProgramActivityCapabilities(
                        audience:
                            isCoachContext ? .coach : .participant,
                        canOpenSteps:
                            !isCoachContext
                            && program.id == store.currentProgram?.id
                    ),
                    accessibilityPrefix:
                        isCoachContext
                            ? "coach.program"
                            : "participant.program",
                    accessForDay: access,
                    onOpenStep: openStep
                )
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
            in: program,
            now: store.effectiveDate
        )
    }

    private func openStep(_ step: ProgramStep) {
        guard !isCoachContext else { return }
        router.navigate(
            to: navigationContext.stepDetailRoute(stepID: step.id),
            in: navigationContext.tab
        )
    }

    private var isCoachContext: Bool {
        navigationContext == .coach
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
