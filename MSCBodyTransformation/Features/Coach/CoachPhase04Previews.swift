#if DEBUG
import SwiftUI

#Preview("Coach dashboard — wallet nol") {
    NavigationStack {
        CoachDashboardScenarioPreview(mode: .walletZero)
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

#Preview("Undangan — kuota habis") {
    NavigationStack {
        CoachInviteExhaustedPreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Store Coach — status berhasil") {
    NavigationStack {
        CoachStoreSuccessScenarioPreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

@MainActor
private struct CoachDashboardScenarioPreview: View {
    enum Mode {
        case walletZero
        case noParticipants
    }

    let mode: Mode
    @State private var state = CoachDashboardState(environment: .preview)
    @State private var router = ShellTabRouter()

    var body: some View {
        CoachDashboardView(state: state, router: router)
            .navigationTitle(Text("tab.coach.dashboard"))
            .task {
                await state.load()
                guard case .loaded(let snapshot) = state.state else {
                    return
                }
                switch mode {
                case .walletZero:
                    var wallet = snapshot.wallet
                    wallet.availableSeatCredits = 0
                    state.state = .loaded(
                        CoachDashboardSnapshot(
                            profile: snapshot.profile,
                            wallet: wallet,
                            activePrograms: snapshot.activePrograms,
                            participants: snapshot.participants
                        )
                    )
                case .noParticipants:
                    state.state = .loaded(
                        CoachDashboardSnapshot(
                            profile: snapshot.profile,
                            wallet: snapshot.wallet,
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

@MainActor
private struct CoachInviteExhaustedPreview: View {
    private let environment: AppEnvironment
    @State private var state: CoachInviteComposerState
    @State private var router = ShellTabRouter()

    init() {
        let environment = AppEnvironment.preview
        self.environment = environment
        _state = State(
            initialValue: CoachInviteComposerState(
                environment: environment
            )
        )
    }

    var body: some View {
        CoachInviteView(state: state, router: router)
            .navigationTitle(Text("tab.coach.invite"))
            .task {
                _ = try? await environment.repositories?.coachDemo
                    .setSeatCredits(
                        coachID: CoachPreviewID.coach,
                        amount: 0,
                        updatedAt: environment.clock.now()
                    )
                await state.load()
            }
    }
}

@MainActor
private struct CoachStoreSuccessScenarioPreview: View {
    @State private var state = CoachStorePreviewState(
        environment: .preview
    )

    var body: some View {
        CoachStorePreviewView(state: state)
            .task {
                await state.load()
                state.setPreviewState(
                    .success(CoachSeatPack.samples[0])
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
