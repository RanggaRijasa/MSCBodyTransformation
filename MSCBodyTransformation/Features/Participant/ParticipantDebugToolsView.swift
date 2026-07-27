import SwiftUI

#if DEBUG
@MainActor
struct ParticipantDebugToolsView: View {
    let store: ParticipantJourneyStore

    @State private var actionError: String?

    var body: some View {
        Section {
            if let program = store.currentProgram {
                DatePicker(
                    "participant.debug.date",
                    selection: debugDateBinding,
                    in: program.startDate...program.endDate,
                    displayedComponents: .date
                )

                Picker(
                    "participant.debug.day",
                    selection: dayBinding
                ) {
                    ForEach(
                        program.days.sorted(by: {
                            $0.dayNumber < $1.dayNumber
                        })
                    ) { day in
                        let dayNumber = Text(
                            day.dayNumber,
                            format: .number.locale(
                                ParticipantFormatting.locale
                            )
                        )
                        Text("\(Text("participant.day.label")) \(dayNumber)")
                        .tag(day.dayNumber)
                    }
                }
            }

            Button("participant.debug.mark_previous") {
                perform {
                    try await store.markPreviousDaysComplete()
                }
            }
            Button("participant.debug.reject_submission") {
                perform {
                    try await store.simulateRejectedSubmission()
                }
            }
            Button("participant.debug.offline") {
                store.simulateOffline()
            }
            Button("participant.debug.repository_error") {
                store.simulateRepositoryError()
            }
            Button("participant.debug.final_state") {
                perform {
                    try await store.simulateFinalProgramState()
                }
            }
            Button(
                "participant.debug.reset",
                role: .destructive
            ) {
                Task {
                    await store.resetDemoParticipant()
                }
            }

            if let actionError {
                Text(actionError)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appDestructive)
            }
        } header: {
            Text("participant.debug.title")
        } footer: {
            Text("participant.debug.footer")
        }
    }

    private var debugDateBinding: Binding<Date> {
        Binding(
            get: { store.debugDateOverride ?? store.effectiveDate },
            set: { store.setDebugDate($0) }
        )
    }

    private var dayBinding: Binding<Int> {
        Binding(
            get: {
                store.selectedDayNumber
                    ?? store.currentProgram?.days.first?.dayNumber
                    ?? 1
            },
            set: { store.selectDay($0) }
        )
    }

    private func perform(
        _ action: @escaping @MainActor () async throws -> Void
    ) {
        Task {
            do {
                try await action()
                actionError = nil
            } catch let error as DomainError {
                actionError = ParticipantFormatting.fieldReason(error)
            } catch {
                actionError = String(
                    localized: "participant.error.generic"
                )
            }
        }
    }
}
#endif
