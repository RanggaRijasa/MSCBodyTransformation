import SwiftUI

@MainActor
struct CoachTabRootView: View {
    let tab: CoachTab
    let features: CoachFeatureContainer
    let programStore: ParticipantJourneyStore?
    let router: ShellTabRouter
    let showsOfflineBanner: Bool
    let onSelectCoachTab: (CoachTab) -> Void

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
                router: router,
                onOpenProgram: {
                    onSelectCoachTab(.program)
                },
                onOpenProfile: {
                    onSelectCoachTab(.profile)
                }
            )
        case .program:
            if let programStore {
                ParticipantTabRootView(
                    tab: .program,
                    store: programStore,
                    router: router,
                    showsOfflineBanner: false,
                    onSelectParticipantTab: { _ in },
                    programNavigationContext: .coach
                )
            } else {
                LoadingStateView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
            }
        case .profile:
            CoachProfileView(
                state: features.profile,
                router: router
            )
        }
    }
}
