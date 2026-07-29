import SwiftUI

@MainActor
struct CoachDashboardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let state: CoachDashboardState
    let router: ShellTabRouter

    private var metricColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: AppSpacing.small)]
        }
        return [
            GridItem(.adaptive(minimum: 150), spacing: AppSpacing.small)
        ]
    }

    var body: some View {
        Group {
            switch state.state {
            case .idle, .loading:
                LoadingStateView()
            case .failed(let error):
                ScrollView {
                    ErrorStateView(error: error) {
                        Task {
                            await state.load()
                        }
                    }
                    .padding(AppSpacing.medium)
                }
            case .loaded(let snapshot):
                dashboard(snapshot)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .task {
            if state.state == .idle {
                await state.load()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    openReviewQueue()
                } label: {
                    Label(
                        "coach.action.review_queue",
                        systemImage: "checkmark.bubble"
                    )
                }
                .accessibilityIdentifier("coach.open-review-queue")
            }
        }
    }

    private func dashboard(
        _ snapshot: CoachDashboardSnapshot
    ) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                identity(snapshot.profile)
                metrics(snapshot)
                quickActions
                activePrograms(snapshot.activePrograms)
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            await state.load()
        }
        .accessibilityIdentifier("coach.dashboard")
    }

    private func identity(_ profile: CoachProfile) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            UserAvatar(displayName: profile.displayName, size: 68)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(profile.displayName)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(Color.appPrimaryText)
                Text(profile.city)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                StatusBadge(
                    title: profile.isPublic
                        ? "coach.profile.visibility.public"
                        : "coach.profile.visibility.private",
                    kind: profile.isPublic ? .success : .neutral
                )
                Text(profile.biography)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appSecondaryText)
            }
        }
        .padding(AppSpacing.medium)
        .background(
            Color.appSurface,
            in: RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
            .stroke(Color.appBorder, lineWidth: 1)
        }
    }

    private func metrics(
        _ snapshot: CoachDashboardSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(
                title: "coach.dashboard.metrics.title",
                subtitle: "coach.dashboard.metrics.subtitle"
            )
            LazyVGrid(columns: metricColumns, spacing: AppSpacing.small) {
                MetricCard(
                    title: "metric.active_programs",
                    value: CoachFormatting.number(
                        snapshot.activePrograms.count
                    ),
                    systemImage: "figure.run"
                )
                MetricCard(
                    title: "metric.participants",
                    value: CoachFormatting.number(
                        snapshot.participants.count
                    ),
                    systemImage: "person.3"
                )
                MetricCard(
                    title: "metric.progress",
                    value: CoachFormatting.percentage(
                        snapshot.averageProgress
                    ),
                    systemImage: "chart.line.uptrend.xyaxis"
                )
                MetricCard(
                    title: "coach.metric.completed",
                    value: CoachFormatting.number(
                        snapshot.completedParticipantCount
                    ),
                    systemImage: "checkmark.seal"
                )
                MetricCard(
                    title: "coach.metric.missing_steps",
                    value: CoachFormatting.number(
                        snapshot.missingStepCount
                    ),
                    systemImage: "exclamationmark.circle"
                )
                MetricCard(
                    title: "metric.review_queue",
                    value: CoachFormatting.number(
                        snapshot.pendingReviewCount
                    ),
                    systemImage: "clock.fill",
                    accentColor: .brandAccent
                )
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "coach.dashboard.quick_actions")
            AdaptiveGlassControlGroup {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.small) {
                        reviewButton
                        inviteButton
                    }
                    VStack(spacing: AppSpacing.small) {
                        reviewButton
                        inviteButton
                    }
                }
            }
        }
    }

    private var reviewButton: some View {
        compactAction(
            title: "coach.action.review_queue",
            systemImage: "checkmark.bubble"
        ) {
            openReviewQueue()
        }
        .accessibilityIdentifier("coach.quick-review-queue")
    }

    private var inviteButton: some View {
        compactAction(
            title: "coach.action.show_identifier",
            systemImage: "qrcode"
        ) {
            router.navigate(
                to: .coach(.invite),
                in: .coach(.dashboard)
            )
        }
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

    private func activePrograms(_ programs: [Program]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "coach.dashboard.active_programs")
            if programs.isEmpty {
                ContentUnavailableView(
                    "coach.programs.empty.title",
                    systemImage: "figure.run",
                    description: Text("coach.programs.empty.message")
                )
            } else {
                ForEach(programs) { program in
                    ProgramCard(
                        title: LocalizedStringKey(program.title),
                        summary: program.summary,
                        statusTitle: "status.active",
                        statusKind: .success,
                        progress: nil
                    )
                }
            }
        }
    }

    private func openReviewQueue() {
        router.navigate(
            to: .coach(.reviewQueue),
            in: .coach(.dashboard)
        )
    }
}

#Preview("Coach dashboard — normal") {
    NavigationStack {
        CoachDashboardPreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Coach dashboard — teks terbesar dan gelap") {
    NavigationStack {
        CoachDashboardPreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
    .dynamicTypeSize(.accessibility5)
    .preferredColorScheme(.dark)
}

@MainActor
private struct CoachDashboardPreview: View {
    @State private var state = CoachDashboardState(environment: .preview)
    @State private var router = ShellTabRouter()

    var body: some View {
        CoachDashboardView(state: state, router: router)
            .navigationTitle(Text("tab.coach.dashboard"))
    }
}
