import SwiftUI

@MainActor
struct RoleAppShellView: View {
    let role: UserRole
    let scenario: AppDemoScenario

    @Environment(\.appEnvironment) private var appEnvironment

    private let tabs: [AppTab]
    @State private var selectedTab: AppTab
    @State private var router = ShellTabRouter()
    @State private var participantStore: ParticipantJourneyStore?
    @State private var coachFeatures: CoachFeatureContainer?
    @State private var adminFeatures: AdminFeatureContainer?

    init(role: UserRole, scenario: AppDemoScenario) {
        self.role = role
        self.scenario = scenario
        let tabs = AppTab.tabs(for: role)
        self.tabs = tabs
        _selectedTab = State(
            initialValue: scenario.initialTab(for: role)
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
                        router: router,
                        participantStore: participantStore,
                        coachFeatures: coachFeatures,
                        adminFeatures: adminFeatures
                    )
                    .navigationDestination(for: ShellRoute.self) { route in
                        ShellRouteDestinationView(
                            route: route,
                            router: router,
                            participantStore: participantStore,
                            coachFeatures: coachFeatures,
                            adminFeatures: adminFeatures
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
        .task(id: "\(role.rawValue).\(scenario.rawValue)") {
            await prepareFeatureStateIfNeeded()
        }
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

    private func prepareFeatureStateIfNeeded() async {
        if scenario == .loggedOut {
            await appEnvironment.repositories?.session
                .setDebugScenario(.loggedOut)
            participantStore = nil
            coachFeatures = nil
            adminFeatures = nil
            return
        }

        _ = try? await appEnvironment.repositories?.session
            .switchDebugRole(to: role)

        switch role {
        case .participant:
            coachFeatures = nil
            adminFeatures = nil
            await prepareParticipantStoreIfNeeded()
        case .coach:
            participantStore = nil
            adminFeatures = nil
            await prepareCoachFeaturesIfNeeded()
        case .admin:
            participantStore = nil
            coachFeatures = nil
            await prepareAdminFeaturesIfNeeded()
        }
    }

    private func prepareParticipantStoreIfNeeded() async {
        guard participantStore == nil else {
            return
        }

        let store = ParticipantJourneyStore(
            environment: appEnvironment,
            startsWithoutEnrollment: scenario == .participantOnboarding
        )
        participantStore = store
        await store.load()

        switch scenario {
        case .participantNoProgram:
            store.hidesActiveProgramForDemo = true
        case .participantDayOne:
            await store.prepareDayOneDemo()
        case .participantMidProgram:
            let middleDay = max(
                1,
                ((store.currentProgram?.days.count ?? 1) + 1) / 2
            )
            store.selectDay(middleDay)
            try? await store.markPreviousDaysComplete()
        case .participantFinalWeighIn:
            if let finalDay = store.currentProgram?.days
                .map(\.dayNumber)
                .max() {
                store.selectDay(finalDay)
                try? await store.markPreviousDaysComplete()
            }
        case .participantFinalLeaderboard:
            try? await store.simulateFinalProgramState()
        default:
            break
        }
    }

    private func prepareCoachFeaturesIfNeeded() async {
        guard coachFeatures == nil else {
            return
        }
        let features = CoachFeatureContainer(environment: appEnvironment)
        await features.prepareIdentity()
        if scenario == .coachWalletZero,
           let coachID = features.coachID {
            _ = try? await appEnvironment.repositories?.coachDemo
                .setSeatCredits(
                    coachID: coachID,
                    amount: 0,
                    updatedAt: appEnvironment.clock.now()
                )
        }
        coachFeatures = features
    }

    private func prepareAdminFeaturesIfNeeded() async {
        guard adminFeatures == nil else {
            return
        }
        let features = AdminFeatureContainer(environment: appEnvironment)
        adminFeatures = features
        await features.load()

        guard case .loaded(let programs) = features.programsState else {
            return
        }
        switch scenario {
        case .adminDraftCMS:
            features.programStatusFilter = .draft
        case .adminActiveProgram:
            features.programStatusFilter = .active
        case .adminWinnerLock:
            if let program = programs.first(where: {
                $0.status == .active
            }) {
                try? await features.lockWinners(programID: program.id)
                router.navigate(
                    to: .admin(.winnerManagement(program.id)),
                    in: .admin(.overview)
                )
            }
        default:
            break
        }
    }
}

#Preview("Shell peserta — terang") {
    RoleAppShellView(
        role: .participant,
        scenario: .participantDayOne
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
        scenario: .adminDraftCMS
    )
    .environment(\.locale, Locale(identifier: "id-ID"))
    .dynamicTypeSize(.accessibility5)
}

#Preview("Shell — loading") {
    RoleAppShellView(role: .participant, scenario: .loading)
        .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Shell — tanpa program") {
    RoleAppShellView(
        role: .participant,
        scenario: .participantNoProgram
    )
        .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Shell — error") {
    RoleAppShellView(
        role: .participant,
        scenario: .repositoryError
    )
        .environment(\.locale, Locale(identifier: "id-ID"))
}
