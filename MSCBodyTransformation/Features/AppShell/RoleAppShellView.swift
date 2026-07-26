import SwiftUI

@MainActor
struct RoleAppShellView: View {
    let role: UserRole
    let scenario: AppDemoScenario

    private let tabs: [AppTab]
    @State private var selectedTab: AppTab
    @State private var router = ShellTabRouter()

    init(role: UserRole, scenario: AppDemoScenario) {
        self.role = role
        self.scenario = scenario
        let tabs = AppTab.tabs(for: role)
        self.tabs = tabs
        _selectedTab = State(
            initialValue: tabs.first ?? .participant(.today)
        )
    }

    var body: some View {
        @Bindable var router = router

        TabView(selection: $selectedTab) {
            ForEach(tabs) { tab in
                NavigationStack(path: router.binding(for: tab)) {
                    ShellTabContentView(
                        tab: tab,
                        scenario: scenario,
                        router: router
                    )
                    .navigationDestination(for: ShellRoute.self) { route in
                        ShellRouteDestinationView(
                            route: route,
                            router: router
                        )
                    }
                }
                .tabItem {
                    Label(
                        LocalizedStringKey(tab.titleLocalizationKey),
                        systemImage: tab.systemImage
                    )
                    .accessibilityIdentifier(tab.accessibilityIdentifier)
                }
                .tag(tab)
            }
        }
        .tint(.brandPrimary)
        .accessibilityIdentifier("shell.\(role.rawValue)")
        .sheet(item: $router.presentedSheet) { sheet in
            ShellSheetView(sheet: sheet)
        }
        .alert(item: $router.presentedAlert) { alert in
            switch alert {
            case .invalidInvite:
                Alert(
                    title: Text("alert.invite.invalid.title"),
                    message: Text("alert.invite.invalid.message"),
                    dismissButton: .default(Text("action.close"))
                )
            case .unavailableRoute:
                Alert(
                    title: Text("alert.route.unavailable.title"),
                    message: Text("alert.route.unavailable.message"),
                    dismissButton: .default(Text("action.close"))
                )
            }
        }
        .onOpenURL(perform: handleDeepLink)
    }

    private func handleDeepLink(_ url: URL) {
        guard role == .participant,
              let code = LocalInviteDeepLinkParser().inviteCode(from: url),
              let todayTab = tabs.first(where: {
                  $0 == .participant(.today)
              }) else {
            router.presentedAlert = .invalidInvite
            return
        }

        selectedTab = todayTab
        router.navigate(
            to: .participant(.localInvite(code)),
            in: todayTab
        )
    }
}

#Preview("Shell peserta — terang") {
    RoleAppShellView(
        role: .participant,
        scenario: .participantActive
    )
    .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Shell coach — gelap") {
    RoleAppShellView(
        role: .coach,
        scenario: .coachReviewQueue
    )
    .environment(\.locale, Locale(identifier: "id-ID"))
    .preferredColorScheme(.dark)
}

#Preview("Shell admin — teks aksesibilitas") {
    RoleAppShellView(
        role: .admin,
        scenario: .adminDraftEditor
    )
    .environment(\.locale, Locale(identifier: "id-ID"))
    .dynamicTypeSize(.accessibility5)
}

#Preview("Shell — loading") {
    RoleAppShellView(role: .participant, scenario: .loading)
        .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Shell — kosong") {
    RoleAppShellView(role: .participant, scenario: .empty)
        .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Shell — error") {
    RoleAppShellView(role: .participant, scenario: .error)
        .environment(\.locale, Locale(identifier: "id-ID"))
}
