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
    @State private var didRetryRepositoryError = false
    @State private var didResumeLoggedOutSession = false
    @State private var isResumingLoggedOutSession = false
    @State private var loggedOutRecoveryError: String?

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

        shellContent
            .tint(.brandPrimary)
            .accessibilityIdentifier("shell.\(role.rawValue)")
            .sheet(item: $router.presentedSheet) { sheet in
                ShellSheetView(sheet: sheet)
            }
            .alert(item: $router.presentedAlert) { alert in
                switch alert {
                case .unavailableRoute:
                    Alert(
                        title: Text("alert.route.unavailable.title"),
                        message: Text("alert.route.unavailable.message"),
                        dismissButton: .default(Text("action.close"))
                    )
                }
            }
            .task(id: "\(role.rawValue).\(scenario.rawValue)") {
                await prepareFeatureStateIfNeeded()
            }
    }

    @ViewBuilder
    private var shellContent: some View {
        if role == .participant,
           let participantStore,
           participantStore.entryStage != .complete {
            participantEntryShell(participantStore)
        } else if role == .participant,
                  scenario == .participantOnboarding,
                  participantStore == nil {
            NavigationStack {
                LoadingStateView()
                    .padding(AppSpacing.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
            }
        } else {
            tabShell
        }
    }

    private var tabShell: some View {
        TabView(selection: $selectedTab) {
            ForEach(tabs) { tab in
                NavigationStack(path: router.binding(for: tab)) {
                    ShellTabContentView(
                        tab: tab,
                        scenario: scenario,
                        router: router,
                        participantStore: participantStore,
                        coachFeatures: coachFeatures,
                        adminFeatures: adminFeatures,
                        didRetryRepositoryError: didRetryRepositoryError,
                        didResumeLoggedOutSession:
                            didResumeLoggedOutSession,
                        isResumingLoggedOutSession:
                            isResumingLoggedOutSession,
                        loggedOutRecoveryError: loggedOutRecoveryError,
                        onRetryRepositoryError: {
                            didRetryRepositoryError = true
                        },
                        onResumeLoggedOutSession:
                            resumeLoggedOutSession,
                        onSelectTab: selectTab
                    )
                    .navigationDestination(for: ShellRoute.self) { route in
                        ShellRouteDestinationView(
                            route: route,
                            router: router,
                            participantStore: participantStore,
                            coachFeatures: coachFeatures,
                            adminFeatures: adminFeatures
                        )
                        .singlePressNavigationBackButton()
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
    }

    private func participantEntryShell(
        _ store: ParticipantJourneyStore
    ) -> some View {
        NavigationStack {
            ParticipantEntryFlowView(store: store)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            router.presentedSheet = .scenarioInformation(
                                scenario.rawValue
                            )
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .accessibilityLabel(
                            Text("action.scenario_information")
                        )
                        .accessibilityIdentifier("shell.scenario-info")
                    }
                }
        }
    }

    private func selectTab(_ tab: AppTab) {
        guard tabs.contains(tab) else {
            router.presentedAlert = .unavailableRoute
            return
        }
        selectedTab = tab
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
        await prepareFeaturesForRole()
    }

    private func prepareFeaturesForRole() async {
        switch role {
        case .participant:
            coachFeatures = nil
            adminFeatures = nil
            await prepareParticipantStoreIfNeeded()
        case .coach:
            adminFeatures = nil
            await prepareCoachFeaturesIfNeeded()
            await prepareCoachProgramStoreIfNeeded()
        case .admin:
            participantStore = nil
            coachFeatures = nil
            await prepareAdminFeaturesIfNeeded()
        }
    }

    private func resumeLoggedOutSession() {
        guard !isResumingLoggedOutSession else {
            return
        }
        isResumingLoggedOutSession = true
        loggedOutRecoveryError = nil

        Task {
            defer {
                isResumingLoggedOutSession = false
            }
            do {
                guard let session = appEnvironment.repositories?.session else {
                    throw appEnvironment.bootstrapError
                        ?? DomainError.unknown
                }
                _ = try await session.switchDebugRole(to: role)
                await prepareFeaturesForRole()
                didResumeLoggedOutSession = true
            } catch {
                loggedOutRecoveryError = String(
                    localized: "session.logged_out.recovery_error",
                    defaultValue:
                        "Sesi belum dapat dipulihkan. Coba lagi."
                )
            }
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
        coachFeatures = features
    }

    private func prepareCoachProgramStoreIfNeeded() async {
        guard participantStore == nil else {
            return
        }
        let store = ParticipantJourneyStore(
            environment: appEnvironment,
            participationAccount: .coach
        )
        participantStore = store
        await store.load()
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
