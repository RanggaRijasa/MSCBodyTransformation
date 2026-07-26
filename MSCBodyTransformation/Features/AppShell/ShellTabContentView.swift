import SwiftUI

@MainActor
struct ShellTabContentView: View {
    let tab: AppTab
    let scenario: AppDemoScenario
    let router: ShellTabRouter
    let participantStore: ParticipantJourneyStore?
    let coachFeatures: CoachFeatureContainer?

    var body: some View {
        content
            .navigationTitle(
                Text(LocalizedStringKey(tab.titleLocalizationKey))
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
            .safeAreaInset(edge: .bottom) {
                contextualAction
            }
    }

    @ViewBuilder
    private var content: some View {
        switch scenario {
        case .loading:
            stateContainer {
                LoadingStateView()
            }
        case .error:
            stateContainer {
                ErrorStateView(error: .unknown)
            }
        case .empty:
            stateContainer {
                EmptyStateView(
                    title: "state.empty.title",
                    message: "state.empty.message",
                    systemImage: "tray"
                )
            }
        case .offline:
            loadedContent(showsOfflineBanner: true)
        case .participantOnboarding, .participantActive,
             .coachReviewQueue, .adminDraftEditor:
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

    @ViewBuilder
    private func loadedContent(showsOfflineBanner: Bool) -> some View {
        if case .participant(let participantTab) = tab,
           let participantStore {
            ParticipantTabRootView(
                tab: participantTab,
                store: participantStore,
                router: router,
                showsOfflineBanner: showsOfflineBanner
            )
        } else if case .coach(let coachTab) = tab,
                  let coachFeatures {
            CoachTabRootView(
                tab: coachTab,
                features: coachFeatures,
                router: router,
                showsOfflineBanner: showsOfflineBanner
            )
        } else if tab == .admin(.settings) {
            AdminSettingsPlaceholderView(
                showsOfflineBanner: showsOfflineBanner
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

    @ViewBuilder
    private var contextualAction: some View {
        switch tab {
        case .participant(.today):
            if participantStore?.currentEnrollment != nil,
               participantStore?.entryStage == .complete {
                PrimaryActionBar(
                    title: "action.view_program",
                    systemImage: "arrow.right"
                ) {
                    router.navigate(
                        to: .participant(
                            .programDetail(ShellPlaceholderID.program)
                        ),
                        in: tab
                    )
                }
            }
        case .admin(.programs):
            PrimaryActionBar(
                title: "action.open_draft",
                systemImage: "square.and.pencil"
            ) {
                router.navigate(
                    to: .admin(.programEditor(ShellPlaceholderID.program)),
                    in: tab
                )
            }
        default:
            EmptyView()
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
                            .programDetail(ShellPlaceholderID.program)
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
        case .participants:
            Section {
                participantRow(name: "Ayu Lestari", progress: 0.4)
                participantRow(name: "Bima Putra", progress: 0.9)
                participantRow(name: "Citra Dewi", progress: 0.9)
            } header: {
                SectionHeader(title: "shell.coach.participants.title")
            }
        case .invite:
            Section {
                AdaptiveGlassControlGroup {
                    HStack(spacing: AppSpacing.small) {
                        compactAction(
                            title: "action.show_invite",
                            systemImage: "qrcode"
                        ) {
                            router.presentedSheet = .inviteCode("MSC7HARI")
                        }
                        compactAction(
                            title: "action.confirm",
                            systemImage: "checkmark.circle"
                        ) {
                            router.presentedSheet = .confirmation
                        }
                    }
                }
                MetricCard(
                    title: "metric.seat_credits",
                    value: "8",
                    systemImage: "person.badge.plus",
                    accentColor: .brandAccent
                )
            } header: {
                SectionHeader(title: "shell.coach.invite.title")
            }
        case .leaderboard:
            Section {
                RankBadge(rank: 1)
                MetricCard(
                    title: "metric.participants",
                    value: "12",
                    systemImage: "trophy"
                )
            } header: {
                SectionHeader(title: "shell.leaderboard.title")
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

    private func participantRow(
        name: String,
        progress: Double
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            UserAvatar(displayName: name)
            Text(name)
                .font(AppTypography.cardTitle)
            Spacer()
            ProgressRing(progress: progress, label: "metric.progress")
                .scaleEffect(0.72)
                .frame(width: 56, height: 56)
        }
        .accessibilityElement(children: .combine)
    }

    private func compactAction(
        title: LocalizedStringKey,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppTypography.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, AppSpacing.small)
        }
        .buttonStyle(.plain)
        .adaptiveGlassSurface(
            cornerRadius: AppRadius.prominent,
            isInteractive: true
        )
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

private struct AdminSettingsPlaceholderView: View {
    let showsOfflineBanner: Bool
    @State private var notificationsEnabled = true

    var body: some View {
        Form {
            if showsOfflineBanner {
                OfflineBanner()
            }

            Section("shell.admin.settings.section") {
                Toggle(
                    "shell.admin.settings.notifications",
                    isOn: $notificationsEnabled
                )
                LabeledContent(
                    "shell.admin.settings.timezone",
                    value: "WITA"
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
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
