import SwiftUI

@MainActor
struct ParticipantProgramView: View {
    let store: ParticipantJourneyStore
    let router: ShellTabRouter
    var programID: UUID?
    var navigationTab: ParticipantTab = .program

    var body: some View {
        Group {
            if let selectedProgram {
                programContent(selectedProgram)
            } else {
                EmptyStateView(
                    title: "participant.program.empty.title",
                    message: "participant.program.empty.message",
                    systemImage: "list.bullet.rectangle"
                )
            }
        }
    }

    @ViewBuilder
    private func programContent(_ program: Program) -> some View {
        if selectedEnrollment == nil,
           program.status == .active || program.status == .scheduled {
            ParticipantProgramOfferView(program: program) {
                openEnrollment(for: program)
            }
        } else {
            ParticipantProgramActivityView(
                program: program,
                store: store,
                router: router,
                navigationTab: navigationTab
            )
        }
    }

    private var selectedProgram: Program? {
        if let programID,
           let program = store.snapshot?.programs.first(where: {
               $0.id == programID
           }) {
            return program
        }
        return store.currentProgram
    }

    private var selectedEnrollment: ProgramEnrollment? {
        guard let selectedProgram else {
            return nil
        }
        return store.enrollment(for: selectedProgram.id)
    }

    private func openEnrollment(for program: Program) {
        router.navigate(
            to: .participant(.joinProgram(program.id)),
            in: .participant(navigationTab)
        )
    }
}

#Preview("Aktivitas program") {
    ParticipantProgramPreview()
}

@MainActor
private struct ParticipantProgramPreview: View {
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )
    @State private var router = ShellTabRouter()

    var body: some View {
        NavigationStack {
            ParticipantProgramView(store: store, router: router)
                .task {
                    await store.load()
                    store.selectDay(3)
                }
        }
    }
}
