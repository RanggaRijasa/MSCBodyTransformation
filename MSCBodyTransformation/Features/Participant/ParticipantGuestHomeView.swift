import SwiftUI

@MainActor
struct ParticipantGuestHomeView: View {
    let store: ParticipantJourneyStore
    let router: ShellTabRouter
    let onSelectTab: (ParticipantTab) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                authenticationCard
                programSection
                focusSection
                leaderboardSection
                winnersSection
                coachesSection
            }
            .frame(maxWidth: 760)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground)
        .accessibilityIdentifier("participant.guest.home")
        .task {
            await store.prepareLeaderboardSelection()
        }
    }

    private var authenticationCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Label(
                "guest.home.auth.title",
                systemImage: "person.crop.circle.badge.plus"
            )
            .font(AppTypography.sectionTitle)
            .foregroundStyle(Color.appPrimaryText)

            Text("guest.home.auth.message")
                .font(AppTypography.body)
                .foregroundStyle(Color.appSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            loginButton
        }
        .padding(AppSpacing.large)
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

    private var loginButton: some View {
        Button("auth.action.login") {
            Task { await store.requestAuthentication(destination: .login) }
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .accessibilityIdentifier("guest.home.login")
    }

    @ViewBuilder
    private var programSection: some View {
        let availablePrograms = store.programs
            .filter { $0.status == .active || $0.status == .scheduled }
            .sorted { $0.startDate < $1.startDate }

        VStack(alignment: .leading, spacing: AppSpacing.small) {
            sectionHeader(
                title: "participant.home.program.title",
                actionTitle: "participant.home.view_all"
            ) {
                onSelectTab(.program)
            }

            if availablePrograms.isEmpty {
                ContentUnavailableView {
                    Label(
                        "participant.home.program.empty.title",
                        systemImage: "rectangle.stack"
                    )
                } description: {
                    Text("participant.home.program.empty.message")
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: AppSpacing.medium) {
                        ForEach(availablePrograms) { program in
                            Button {
                                router.navigate(
                                    to: .participant(
                                        .programDetail(program.id, .today)
                                    ),
                                    in: .participant(.today)
                                )
                            } label: {
                                ParticipantProgramPoster(
                                    program: program,
                                    participationStatus: .notEnrolled
                                )
                                .frame(width: 320)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier(
                                "guest.home.program.\(program.id)"
                            )
                        }
                    }
                }
            }
        }
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            sectionHeader(title: "participant.home.focus.title")
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label(
                    "guest.home.focus.title",
                    systemImage: "checklist"
                )
                .font(AppTypography.cardTitle)
                Text("guest.home.focus.message")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                Button("auth.action.login") {
                    Task {
                        await store.requestAuthentication(
                            destination: .login,
                            reason: .personalActivity
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandPrimary)
                .frame(minHeight: 44)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.appSurface,
                in: RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
            )
        }
    }

    @ViewBuilder
    private var leaderboardSection: some View {
        if case .loaded(let snapshot) = store.leaderboardState {
            let entries = Array(
                snapshot.entries
                    .sorted { $0.rank < $1.rank }
                    .prefix(5)
            )
            if !entries.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    sectionHeader(
                        title: "participant.home.leaderboard.title",
                        actionTitle: "participant.home.view_all"
                    ) {
                        onSelectTab(.leaderboard)
                    }
                    Text(snapshot.program.title)
                        .font(AppTypography.label)
                        .foregroundStyle(Color.appSecondaryText)

                    VStack(spacing: AppSpacing.xSmall) {
                        ForEach(entries) { entry in
                            HStack(spacing: AppSpacing.small) {
                                Text(
                                    entry.rank,
                                    format: .number.locale(
                                        ParticipantFormatting.locale
                                    )
                                )
                                .font(AppTypography.label.monospacedDigit())
                                .frame(width: 28, height: 28)
                                .background(Color.brandAccent, in: Circle())
                                .foregroundStyle(Color.black)

                                UserAvatar(
                                    displayName:
                                        entry.participantDisplayName,
                                    size: 40
                                )
                                Text(entry.participantDisplayName)
                                    .font(AppTypography.secondary)
                                Spacer(minLength: AppSpacing.small)
                                Text(
                                    entry.score.totalPoints,
                                    format: .number.locale(
                                        ParticipantFormatting.locale
                                    )
                                )
                                .font(AppTypography.label.monospacedDigit())
                            }
                            .accessibilityElement(children: .combine)
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
                }
            }
        }
    }

    @ViewBuilder
    private var winnersSection: some View {
        let posters = Array(store.featuredWinnerPosters.prefix(2))
        if !posters.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                sectionHeader(title: "participant.home.winners.title")
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: AppSpacing.medium) {
                        ForEach(posters) { poster in
                            WinnerPosterImage(
                                reference: poster.localMediaReference,
                                alternativeText: poster.title
                            )
                            .frame(width: 250)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var coachesSection: some View {
        if !store.publicCoaches.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                sectionHeader(
                    title: "participant.home.coaches.title",
                    actionTitle: "participant.home.coaches.view_all"
                ) {
                    onSelectTab(.coaches)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: AppSpacing.small) {
                        ForEach(store.publicCoaches) { coach in
                            Button {
                                router.navigate(
                                    to: .participant(.coach(coach.id)),
                                    in: .participant(.today)
                                )
                            } label: {
                                VStack(spacing: AppSpacing.xSmall) {
                                    UserAvatar(
                                        displayName: coach.displayName,
                                        imageName:
                                            coach.localPhotoReference,
                                        size: 72
                                    )
                                    Text(coach.displayName)
                                        .font(AppTypography.label)
                                        .frame(width: 96)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(
        title: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(Color.appPrimaryText)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: AppSpacing.small)
            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                        .font(AppTypography.secondary.weight(.semibold))
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.brandPrimary)
            }
        }
    }
}
