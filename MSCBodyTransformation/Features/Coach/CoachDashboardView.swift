import SwiftUI

@MainActor
struct CoachDashboardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let state: CoachDashboardState
    let router: ShellTabRouter
    let onOpenProgram: () -> Void
    let onOpenProfile: () -> Void

    private var quickActionColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: AppSpacing.small)]
        }
        return Array(
            repeating: GridItem(.flexible(), spacing: AppSpacing.small),
            count: 3
        )
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
    }

    private func dashboard(
        _ snapshot: CoachDashboardSnapshot
    ) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                identity(snapshot.profile)
                quickActions(snapshot)
                summary(snapshot)
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
        HomeProfileCard(
            displayName: profile.displayName,
            imageName: profile.localPhotoReference,
            badgeTitle: "role.coach",
            accessibilityHint: "coach.dashboard.profile.hint",
            accessibilityIdentifier: "coach.dashboard.profile",
            action: onOpenProfile
        )
    }

    private func quickActions(
        _ snapshot: CoachDashboardSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "coach.dashboard.quick_actions")
            LazyVGrid(
                columns: quickActionColumns,
                spacing: AppSpacing.small
            ) {
                quickAction(
                    title: "coach.action.review_queue",
                    systemImage: "checkmark.bubble",
                    badgeValue: snapshot.pendingReviewCount,
                    badgeKind: .pending,
                    accessibilityHint:
                        "coach.dashboard.action.review.hint",
                    accessibilityIdentifier:
                        "coach.dashboard.action.review"
                ) {
                    openReviewQueue()
                }

                quickAction(
                    title: "coach.dashboard.action.participants",
                    systemImage: "person.3",
                    badgeValue: snapshot.needsAttentionCount,
                    badgeKind: .attention,
                    accessibilityHint:
                        "coach.dashboard.action.participants.hint",
                    accessibilityIdentifier:
                        "coach.dashboard.action.participants"
                ) {
                    openParticipants(.all)
                }

                quickAction(
                    title: "coach.dashboard.action.activity",
                    systemImage: "clock.arrow.circlepath",
                    accessibilityHint:
                        "coach.dashboard.action.activity.hint",
                    accessibilityIdentifier:
                        "coach.dashboard.action.activity"
                ) {
                    router.navigate(
                        to: .coach(.activity),
                        in: .coach(.dashboard)
                    )
                }

                quickAction(
                    title: "tab.coach.leaderboard",
                    systemImage: "trophy",
                    accessibilityHint:
                        "coach.dashboard.action.leaderboard.hint",
                    accessibilityIdentifier:
                        "coach.dashboard.action.leaderboard"
                ) {
                    router.navigate(
                        to: .coach(.leaderboard),
                        in: .coach(.dashboard)
                    )
                }

                quickAction(
                    title: "coach.dashboard.action.program",
                    systemImage: "checklist",
                    accessibilityHint:
                        "coach.dashboard.action.program.hint",
                    accessibilityIdentifier:
                        "coach.dashboard.action.program",
                    action: onOpenProgram
                )

                quickAction(
                    title: "coach.dashboard.action.qr",
                    systemImage: "qrcode",
                    accessibilityHint:
                        "coach.dashboard.action.qr.hint",
                    accessibilityIdentifier:
                        "coach.dashboard.action.qr"
                ) {
                    router.navigate(
                        to: .coach(.coachIdentifier),
                        in: .coach(.dashboard)
                    )
                }
            }
        }
    }

    private func quickAction(
        title: LocalizedStringKey,
        systemImage: String,
        badgeValue: Int? = nil,
        badgeKind: CoachDashboardBadgeKind = .attention,
        accessibilityHint: LocalizedStringKey,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        let visibleBadge = badgeValue.flatMap { $0 > 0 ? $0 : nil }

        return Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: AppSpacing.small) {
                    Image(systemName: systemImage)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(Color.appPrimaryText)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appPrimaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Capsule()
                        .fill(Color.brandPrimary)
                        .frame(width: 36, height: 3)
                        .accessibilityHidden(true)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: dynamicTypeSize.isAccessibilitySize
                        ? 92
                        : 132
                )
                .padding(.horizontal, AppSpacing.xSmall)
                .padding(.vertical, AppSpacing.small)

                if let visibleBadge {
                    Text(
                        visibleBadge,
                        format: .number.locale(CoachFormatting.locale)
                    )
                    .font(AppTypography.label.monospacedDigit())
                    .foregroundStyle(badgeKind.foregroundColor)
                    .frame(minWidth: 28, minHeight: 28)
                    .background(badgeKind.backgroundColor, in: Circle())
                    .padding(AppSpacing.xSmall)
                }
            }
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
            .contentShape(
                RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(
            visibleBadge.map {
                Text(
                    $0,
                    format: .number.locale(CoachFormatting.locale)
                )
            } ?? Text("")
        )
        .accessibilityHint(Text(accessibilityHint))
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private func summary(
        _ snapshot: CoachDashboardSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "coach.dashboard.metrics.title")

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: AppSpacing.medium) {
                        summaryItems(snapshot)
                    }
                } else {
                    HStack(spacing: 0) {
                        summaryItems(snapshot)
                    }
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
    }

    @ViewBuilder
    private func summaryItems(
        _ snapshot: CoachDashboardSnapshot
    ) -> some View {
        CoachDashboardSummaryItem(
            value: CoachFormatting.number(snapshot.participants.count),
            title: "coach.dashboard.summary.participants",
            systemImage: "person.3"
        )

        summaryDivider

        CoachDashboardSummaryItem(
            value: CoachFormatting.percentage(snapshot.averageProgress),
            title: "coach.dashboard.summary.progress",
            systemImage: "chart.line.uptrend.xyaxis"
        )

        summaryDivider

        CoachDashboardSummaryItem(
            value: CoachFormatting.number(snapshot.activePrograms.count),
            title: "coach.dashboard.summary.active_programs",
            systemImage: "figure.run"
        )
    }

    @ViewBuilder
    private var summaryDivider: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Divider()
        } else {
            Divider()
                .frame(height: 72)
        }
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
                    Button {
                        openParticipants(.program(program.id))
                    } label: {
                        CoachDashboardProgramCard(program: program)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(
                        Text("coach.dashboard.program.open_hint")
                    )
                    .accessibilityIdentifier(
                        "coach.dashboard.program.\(program.id)"
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

    private func openParticipants(
        _ destination: CoachParticipantsDestination
    ) {
        router.navigate(
            to: .coach(.participants(destination)),
            in: .coach(.dashboard)
        )
    }
}

private enum CoachDashboardBadgeKind {
    case pending
    case attention

    var foregroundColor: Color {
        switch self {
        case .pending:
            Color.black
        case .attention:
            Color.white
        }
    }

    var backgroundColor: Color {
        switch self {
        case .pending:
            Color.brandAccent
        case .attention:
            Color.brandPrimary
        }
    }
}

private struct CoachDashboardSummaryItem: View {
    let value: String
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.appSecondaryText)
                .accessibilityHidden(true)

            Text(value)
                .font(AppTypography.metric)
                .foregroundStyle(Color.appPrimaryText)

            Text(title)
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct CoachDashboardProgramCard: View {
    let program: Program

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(program.title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.small) {
                        programMetadata
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        programMetadata
                    }
                }
            }

            Spacer(minLength: AppSpacing.xSmall)

            Image(systemName: "chevron.right")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
                .frame(
                    width: AppControlMetrics.minimumTouchTarget,
                    height: AppControlMetrics.minimumTouchTarget
                )
                .accessibilityHidden(true)
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
        .contentShape(
            RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var programMetadata: some View {
        StatusBadge(title: "status.active", kind: .success)

        Text(
            "\(Text("coach.dashboard.program.ends")) \(CoachFormatting.date(program.endDate))"
        )
        .font(AppTypography.secondary)
        .foregroundStyle(Color.appSecondaryText)
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
        CoachDashboardView(
            state: state,
            router: router,
            onOpenProgram: {},
            onOpenProfile: {}
        )
            .navigationTitle(Text("tab.coach.dashboard"))
    }
}
