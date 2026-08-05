import SwiftUI

@MainActor
struct ParticipantCoachesView: View {
    let store: ParticipantJourneyStore
    let router: ShellTabRouter

    var body: some View {
        if !store.publicCoaches.isEmpty {
            List(store.publicCoaches) { coach in
                Button {
                    router.navigate(
                        to: .participant(.coach(coach.id)),
                        in: .participant(.coaches)
                    )
                } label: {
                    coachRow(coach)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(
                    "participant.coach.\(coach.id.uuidString)"
                )
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .accessibilityIdentifier("participant.coaches")
        } else {
            EmptyStateView(
                title: "participant.coaches.empty.title",
                message: "participant.coaches.empty.message",
                systemImage: "person.2"
            )
        }
    }

    private func coachRow(_ coach: CoachProfile) -> some View {
        HStack(spacing: AppSpacing.medium) {
            UserAvatar(displayName: coach.displayName, size: 60)
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(coach.displayName)
                    .font(AppTypography.cardTitle)
                Text(coach.city)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                Text(coach.biography)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if store.currentEnrollment?.coachID == coach.id {
                    StatusBadge(
                        title: "participant.coaches.assigned",
                        kind: .success
                    )
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.appSecondaryText)
                .accessibilityHidden(true)
        }
        .padding(.vertical, AppSpacing.xSmall)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

@MainActor
struct ParticipantCoachDetailView: View {
    let store: ParticipantJourneyStore
    let coachID: UUID

    var body: some View {
        if let coach = store.coach(id: coachID) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    HStack(spacing: AppSpacing.large) {
                        UserAvatar(
                            displayName: coach.displayName,
                            size: 88
                        )
                        VStack(alignment: .leading) {
                            Text(coach.displayName)
                                .font(AppTypography.sectionTitle)
                            Text(coach.city)
                                .foregroundStyle(Color.appSecondaryText)
                            if store.currentEnrollment?.coachID == coach.id {
                                StatusBadge(
                                    title: "participant.coaches.assigned",
                                    kind: .success
                                )
                            }
                        }
                    }

                    SectionHeader(
                        title: "participant.coach.about"
                    )
                    Text(coach.biography)
                        .font(AppTypography.body)
                        .foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Label(
                        "participant.coach.local_profile_notice",
                        systemImage: "info.circle"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                }
                .frame(maxWidth: 620, alignment: .leading)
                .padding(AppSpacing.large)
                .frame(maxWidth: .infinity)
            }
            .background(Color.appBackground)
            .navigationTitle(coach.displayName)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ErrorStateView(error: .notFound(resource: "coach"))
        }
    }
}

#Preview("Direktori coach") {
    ParticipantCoachesPreview()
}

@MainActor
private struct ParticipantCoachesPreview: View {
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )
    @State private var router = ShellTabRouter()

    var body: some View {
        NavigationStack {
            ParticipantCoachesView(store: store, router: router)
                .task { await store.load() }
        }
    }
}
