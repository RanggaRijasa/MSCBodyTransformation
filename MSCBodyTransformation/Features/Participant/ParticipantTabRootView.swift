import SwiftUI

@MainActor
struct ParticipantTabRootView: View {
    let tab: ParticipantTab
    let store: ParticipantJourneyStore
    let router: ShellTabRouter
    let showsOfflineBanner: Bool

    var body: some View {
        switch store.state {
        case .idle, .loading:
            LoadingStateView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
        case .failed(let error):
            ScrollView {
                VStack(spacing: AppSpacing.medium) {
                    if error == .offline || showsOfflineBanner {
                        OfflineBanner()
                    }
                    ErrorStateView(error: error) {
                        Task {
                            await store.retryLoad()
                        }
                    }
                }
                .padding(AppSpacing.medium)
            }
            .background(Color.appBackground)
        case .loaded:
            if store.entryStage != .complete {
                ParticipantEntryFlowView(store: store)
            } else {
                tabContent
                    .safeAreaInset(edge: .top) {
                        if showsOfflineBanner {
                            OfflineBanner()
                                .padding(.horizontal, AppSpacing.medium)
                                .padding(.top, AppSpacing.xSmall)
                                .background(Color.appBackground)
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .today:
            ParticipantTodayView(store: store, router: router)
        case .program:
            ParticipantProgramView(store: store, router: router)
        case .leaderboard:
            ParticipantLeaderboardView(store: store)
        case .coaches:
            ParticipantCoachesView(store: store, router: router)
        case .profile:
            ParticipantProfileView(store: store, router: router)
        }
    }
}

#Preview("Today — loading") {
    ParticipantTabLoadingPreview()
}

@MainActor
private struct ParticipantTabLoadingPreview: View {
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )
    @State private var router = ShellTabRouter()

    var body: some View {
        ParticipantTabRootView(
            tab: .today,
            store: store,
            router: router,
            showsOfflineBanner: false
        )
    }
}
