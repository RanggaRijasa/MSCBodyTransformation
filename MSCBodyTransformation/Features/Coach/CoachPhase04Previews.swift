#if DEBUG
import SwiftUI

#Preview("Coach dashboard — ringkasan") {
    NavigationStack {
        CoachDashboardScenarioPreview(mode: .standard)
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Coach dashboard — tanpa peserta") {
    NavigationStack {
        CoachDashboardScenarioPreview(mode: .noParticipants)
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Detail peserta — selesai") {
    NavigationStack {
        CoachParticipantScenarioPreview(
            participantID: CoachPreviewID.ayu,
            marksEnrollmentComplete: true
        )
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Detail peserta — perlu perhatian") {
    NavigationStack {
        CoachParticipantScenarioPreview(
            participantID: CoachPreviewID.bima,
            marksEnrollmentComplete: false
        )
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Detail peserta — bukti ditolak") {
    NavigationStack {
        CoachParticipantScenarioPreview(
            participantID: CoachPreviewID.ayu,
            marksEnrollmentComplete: false
        )
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

@MainActor
private struct CoachDashboardScenarioPreview: View {
    enum Mode {
        case standard
        case noParticipants
    }

    let mode: Mode
    @State private var state = CoachDashboardState(environment: .preview)
    @State private var router = ShellTabRouter()

    var body: some View {
        CoachDashboardView(
            state: state,
            router: router,
            onOpenProgram: {},
            onOpenProfile: {}
        )
            .navigationTitle(Text("tab.coach.dashboard"))
            .task {
                await state.load()
                guard case .loaded(let snapshot) = state.state else {
                    return
                }
                switch mode {
                case .standard:
                    state.state = .loaded(
                        CoachDashboardSnapshot(
                            profile: snapshot.profile,
                            activePrograms: snapshot.activePrograms,
                            participants: snapshot.participants
                        )
                    )
                case .noParticipants:
                    state.state = .loaded(
                        CoachDashboardSnapshot(
                            profile: snapshot.profile,
                            activePrograms: snapshot.activePrograms,
                            participants: []
                        )
                    )
                }
            }
    }
}

@MainActor
private struct CoachParticipantScenarioPreview: View {
    let participantID: UUID
    let marksEnrollmentComplete: Bool

    @State private var state: CoachParticipantDetailState

    init(
        participantID: UUID,
        marksEnrollmentComplete: Bool
    ) {
        self.participantID = participantID
        self.marksEnrollmentComplete = marksEnrollmentComplete
        _state = State(
            initialValue: CoachParticipantDetailState(
                participantID: participantID,
                coachID: CoachPreviewID.coach,
                environment: .preview
            )
        )
    }

    var body: some View {
        CoachParticipantDetailView(state: state)
            .task {
                await state.load()
                guard marksEnrollmentComplete,
                      case .loaded(let summary) = state.state,
                      var enrollment = summary.enrollment else {
                    return
                }
                enrollment.status = .completed
                state.state = .loaded(
                    CoachParticipantSummary(
                        profile: summary.profile,
                        enrollment: enrollment,
                        program: summary.program,
                        submissions: summary.submissions,
                        weighIns: summary.weighIns,
                        leaderboardEntry: summary.leaderboardEntry
                    )
                )
            }
    }
}

private enum CoachPreviewID {
    static let coach = UUID(
        uuidString: "30000000-0000-0000-0000-000000000101"
    )!
    static let ayu = UUID(
        uuidString: "20000000-0000-0000-0000-000000000001"
    )!
    static let bima = UUID(
        uuidString: "20000000-0000-0000-0000-000000000002"
    )!
}
#endif
