import SwiftUI

@MainActor
struct ShellTabContentView: View {
    let tab: AppTab
    let scenario: AppDemoScenario
    let router: ShellTabRouter
    let participantStore: ParticipantJourneyStore?
    let coachFeatures: CoachFeatureContainer?
    let adminFeatures: AdminFeatureContainer?
    let didRetryRepositoryError: Bool
    let didResumeLoggedOutSession: Bool
    let isResumingLoggedOutSession: Bool
    let loggedOutRecoveryError: String?
    let onRetryRepositoryError: () -> Void
    let onResumeLoggedOutSession: () -> Void
    let onSelectTab: (AppTab) -> Void

    var body: some View {
        content
            .navigationTitle(
                usesPinnedContentTitle
                    ? Text("")
                    : Text(
                        LocalizedStringKey(
                            tab.titleLocalizationKey
                        )
                    )
            )
            .navigationBarTitleDisplayMode(
                usesPinnedContentTitle ? .inline : .automatic
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.presentedSheet = .scenarioInformation(
                            scenario.rawValue
                        )
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel(Text("action.scenario_information"))
                    .accessibilityIdentifier("shell.scenario-info")
                }
            }
    }

    private var usesPinnedContentTitle: Bool {
        tab == .admin(.people) || tab == .admin(.content)
    }

    @ViewBuilder
    private var content: some View {
        switch scenario {
        case .loading:
            stateContainer {
                LoadingStateView()
            }
        case .repositoryError:
            if didRetryRepositoryError {
                loadedContent(showsOfflineBanner: false)
            } else {
                stateContainer {
                    ErrorStateView(error: .unknown) {
                        onRetryRepositoryError()
                    }
                }
            }
        case .permissionDenied:
            if tab == permissionRecoveryTab {
                loadedContent(showsOfflineBanner: false)
            } else {
                stateContainer {
                    ErrorStateView(
                        error: .permissionDenied,
                        actionTitle: permissionRecoveryActionTitle
                    ) {
                        onSelectTab(permissionRecoveryTab)
                    }
                }
            }
        case .loggedOut:
            if didResumeLoggedOutSession {
                loadedContent(showsOfflineBanner: false)
            } else {
                stateContainer {
                    ContentUnavailableView {
                        Label(
                            "error.session_expired.title",
                            systemImage:
                                "person.crop.circle.badge.xmark"
                        )
                    } description: {
                        VStack(spacing: AppSpacing.xSmall) {
                            Text("error.session_expired.message")
                            if let loggedOutRecoveryError {
                                Text(loggedOutRecoveryError)
                                    .foregroundStyle(
                                        Color.appDestructive
                                    )
                            }
                        }
                    } actions: {
                        Button {
                            onResumeLoggedOutSession()
                        } label: {
                            if isResumingLoggedOutSession {
                                ProgressView()
                                    .accessibilityLabel(
                                        Text(
                                            "session.logged_out.resuming"
                                        )
                                    )
                            } else {
                                Text("session.logged_out.resume")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isResumingLoggedOutSession)
                        .accessibilityIdentifier(
                            "state.logged-out.resume"
                        )
                    }
                    .accessibilityIdentifier("state.logged-out")
                }
            }
        case .offline:
            loadedContent(showsOfflineBanner: true)
        case .participantOnboarding, .participantNoProgram,
             .participantActive,
             .participantDayOne, .participantMidProgram,
             .participantFinalWeighIn, .participantFinalLeaderboard,
             .coachWalletZero, .coachActiveParticipants,
             .coachReviewQueue, .adminDashboard, .adminDraftCMS,
             .adminActiveProgram, .adminWinnerLock:
            loadedContent(showsOfflineBanner: false)
        }
    }

    private func stateContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            content()
                .frame(maxWidth: 680)
                .padding(AppSpacing.medium)
                .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground)
    }

    private var permissionRecoveryTab: AppTab {
        switch tab.role {
        case .participant:
            .participant(.profile)
        case .coach:
            .coach(.profile)
        case .admin:
            .admin(.settings)
        }
    }

    private var permissionRecoveryActionTitle: LocalizedStringKey {
        tab.role == .admin
            ? "action.open_settings"
            : "action.open_profile"
    }

    @ViewBuilder
    private func loadedContent(showsOfflineBanner: Bool) -> some View {
        if case .participant(let participantTab) = tab,
           let participantStore {
            ParticipantTabRootView(
                tab: participantTab,
                store: participantStore,
                router: router,
                showsOfflineBanner: showsOfflineBanner,
                onSelectParticipantTab: { participantTab in
                    onSelectTab(.participant(participantTab))
                }
            )
        } else if case .coach(let coachTab) = tab,
                  let coachFeatures {
            CoachTabRootView(
                tab: coachTab,
                features: coachFeatures,
                programStore: participantStore,
                router: router,
                showsOfflineBanner: showsOfflineBanner,
                onSelectCoachTab: { coachTab in
                    onSelectTab(.coach(coachTab))
                }
            )
        } else if case .admin(let adminTab) = tab,
                  let adminFeatures {
            AdminTabRootView(
                tab: adminTab,
                features: adminFeatures,
                router: router,
                showsOfflineBanner: showsOfflineBanner,
                onSelectAdminTab: { adminTab in
                    onSelectTab(.admin(adminTab))
                }
            )
        } else {
            List {
                if showsOfflineBanner {
                    OfflineBanner()
                        .listRowInsets(
                            EdgeInsets(
                                top: AppSpacing.small,
                                leading: AppSpacing.medium,
                                bottom: AppSpacing.small,
                                trailing: AppSpacing.medium
                            )
                        )
                        .listRowBackground(Color.clear)
                }

                switch tab {
                case .participant(let participantTab):
                    ParticipantShellSections(
                        tab: participantTab,
                        router: router
                    )
                case .coach(let coachTab):
                    CoachShellSections(tab: coachTab, router: router)
                case .admin(let adminTab):
                    AdminShellSections(tab: adminTab, router: router)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
        }
    }

}

private struct ParticipantShellSections: View {
    let tab: ParticipantTab
    let router: ShellTabRouter

    var body: some View {
        switch tab {
        case .today:
            Section {
                ProgramCard(
                    title: "shell.demo.program.active_title",
                    summary: "shell.participant.today.summary",
                    statusTitle: "status.active",
                    statusKind: .success,
                    progress: 0.4
                )
                StepRow(
                    title: "shell.demo.step.title",
                    detail: "shell.participant.today.step_detail",
                    points: 10,
                    statusTitle: "status.pending",
                    statusKind: .pending
                )
            } header: {
                SectionHeader(
                    title: "shell.participant.today.title",
                    subtitle: "shell.participant.today.subtitle"
                )
            }
        case .program:
            Section {
                Button {
                    router.navigate(
                        to: .participant(
                            .programDetail(
                                ShellPlaceholderID.program,
                                .program
                            )
                        ),
                        in: .participant(.program)
                    )
                } label: {
                    ProgramCard(
                        title: "shell.demo.program.active_title",
                        summary: "shell.participant.program.summary",
                        statusTitle: "status.active",
                        statusKind: .success,
                        progress: 0.4
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("participant.open-program")
            } header: {
                SectionHeader(title: "shell.participant.program.title")
            }
        case .leaderboard:
            Section {
                HStack(spacing: AppSpacing.small) {
                    RankBadge(rank: 1)
                    RankBadge(rank: 2)
                    RankBadge(rank: 3)
                }
                MetricCard(
                    title: "metric.points",
                    value: "155",
                    systemImage: "star.fill",
                    accentColor: .brandAccent
                )
            } header: {
                SectionHeader(title: "shell.leaderboard.title")
            }
        case .coaches:
            Section {
                personRow(name: "Coach Raka", detail: "Denpasar")
                personRow(name: "Coach Maya", detail: "Makassar")
                personRow(name: "Coach Niko", detail: "Surabaya")
                personRow(name: "Coach Sinta", detail: "Jakarta")
            } header: {
                SectionHeader(title: "shell.participant.coaches.title")
            }
        case .profile:
            Section {
                personRow(name: "Ayu Lestari", detail: "Peserta")
                MetricCard(
                    title: "metric.progress",
                    value: 0.4.formatted(
                        .percent
                            .locale(Locale(identifier: "id-ID"))
                            .precision(.fractionLength(0))
                    ),
                    systemImage: "chart.line.uptrend.xyaxis"
                )
            } header: {
                SectionHeader(title: "shell.profile.title")
            }
        }
    }

    private func personRow(name: String, detail: String) -> some View {
        HStack(spacing: AppSpacing.medium) {
            UserAvatar(displayName: name)
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(name)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                Text(detail)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
        .accessibilityElement(children: .combine)
    }
}

private struct CoachShellSections: View {
    let tab: CoachTab
    let router: ShellTabRouter

    var body: some View {
        switch tab {
        case .dashboard:
            Section {
                MetricCard(
                    title: "metric.participants",
                    value: "6",
                    systemImage: "person.3"
                )
                MetricCard(
                    title: "metric.review_queue",
                    value: "3",
                    systemImage: "clock.fill",
                    accentColor: .brandAccent
                )
            } header: {
                SectionHeader(title: "shell.coach.dashboard.title")
            }
        case .program:
            Section {
                ProgramCard(
                    title: "shell.demo.program.active_title",
                    summary: "shell.participant.program.summary",
                    statusTitle: "status.active",
                    statusKind: .success,
                    progress: nil
                )
            } header: {
                SectionHeader(title: "shell.participant.program.title")
            }
        case .profile:
            Section {
                HStack(spacing: AppSpacing.medium) {
                    UserAvatar(displayName: "Coach Raka", size: 64)
                    VStack(alignment: .leading) {
                        Text("Coach Raka")
                            .font(AppTypography.cardTitle)
                        Text("Denpasar")
                            .foregroundStyle(Color.appSecondaryText)
                    }
                }
            } header: {
                SectionHeader(title: "shell.profile.title")
            }
        }
    }
}

private struct AdminShellSections: View {
    let tab: AdminTab
    let router: ShellTabRouter

    var body: some View {
        switch tab {
        case .overview:
            Section {
                MetricCard(
                    title: "metric.active_programs",
                    value: "1",
                    systemImage: "figure.run"
                )
                MetricCard(
                    title: "metric.pending_approvals",
                    value: "1",
                    systemImage: "person.badge.clock",
                    accentColor: .brandAccent
                )
            } header: {
                SectionHeader(title: "shell.admin.overview.title")
            }
        case .programs:
            Section {
                Button {
                    router.navigate(
                        to: .admin(
                            .programEditor(ShellPlaceholderID.program)
                        ),
                        in: .admin(.programs)
                    )
                } label: {
                    ProgramCard(
                        title: "shell.demo.program.draft_title",
                        summary: "shell.admin.programs.draft_summary",
                        statusTitle: "status.draft",
                        statusKind: .warning,
                        progress: nil
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("admin.open-draft")
            } header: {
                SectionHeader(title: "shell.admin.programs.title")
            }
        case .people:
            Section {
                Label("Tio Pranata", systemImage: "person.badge.clock")
                StatusBadge(
                    title: "status.awaiting_approval",
                    kind: .pending
                )
            } header: {
                SectionHeader(title: "shell.admin.people.title")
            }
        case .content:
            Section {
                Label(
                    "shell.admin.content.winner_banner",
                    systemImage: "trophy.fill"
                )
                Label(
                    "shell.admin.content.disclaimer",
                    systemImage: "heart.text.square"
                )
            } header: {
                SectionHeader(title: "shell.admin.content.title")
            }
        case .settings:
            EmptyView()
        }
    }
}

private enum ShellPlaceholderID {
    static let program = UUID(
        uuid: (
            16, 0, 0, 0,
            0, 0,
            0, 0,
            0, 0,
            0, 0, 0, 0, 0, 1
        )
    )
}
