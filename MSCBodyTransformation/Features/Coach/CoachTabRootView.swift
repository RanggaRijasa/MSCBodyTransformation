import SwiftUI

@MainActor
struct CoachTabRootView: View {
    let tab: CoachTab
    let features: CoachFeatureContainer
    let router: ShellTabRouter
    let showsOfflineBanner: Bool

    var body: some View {
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

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .dashboard:
            CoachDashboardView(
                state: features.dashboard,
                router: router
            )
        case .participants:
            CoachParticipantsView(
                state: features.participants,
                router: router
            )
        case .invite:
            CoachInviteView(
                state: features.invites,
                router: router
            )
        case .leaderboard:
            CoachLeaderboardView(state: features.leaderboard)
        case .profile:
            CoachProfileView(
                state: features.profile,
                router: router
            )
        }
    }
}
