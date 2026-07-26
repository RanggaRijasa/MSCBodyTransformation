import SwiftUI

@MainActor
struct ParticipantProfileView: View {
    let store: ParticipantJourneyStore
    let router: ShellTabRouter

    @State private var notificationsEnabled = true
    @State private var usesDarkAppearance = false

    var body: some View {
        if let snapshot = store.snapshot {
            Form {
                identitySection(snapshot)
                enrollmentSection(snapshot)
                settingsSection
                legalSection
#if DEBUG
                ParticipantDebugToolsView(store: store)
#endif
                accountSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .accessibilityIdentifier("participant.profile")
        } else {
            LoadingStateView()
        }
    }

    private func identitySection(
        _ snapshot: ParticipantJourneySnapshot
    ) -> some View {
        Section {
            HStack(spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: snapshot.profile.displayName,
                    size: 72
                )
                VStack(alignment: .leading) {
                    Text(snapshot.profile.displayName)
                        .font(AppTypography.sectionTitle)
                    Text(snapshot.user.email)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                    Text(snapshot.profile.city)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                }
            }
        } header: {
            Text("participant.profile.identity")
        }
    }

    private func enrollmentSection(
        _ snapshot: ParticipantJourneySnapshot
    ) -> some View {
        Section {
            if snapshot.enrollments.isEmpty {
                Text("participant.profile.enrollments.empty")
                    .foregroundStyle(Color.appSecondaryText)
            } else {
                ForEach(snapshot.enrollments) { enrollment in
                    let program = snapshot.programs.first {
                        $0.id == enrollment.programID
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text(
                            program?.title
                                ?? String(
                                    localized:
                                        "participant.program.unknown"
                                )
                        )
                        .font(AppTypography.cardTitle)
                        StatusBadge(
                            title: LocalizedStringKey(
                                enrollmentStatusKey(enrollment.status)
                            ),
                            kind: enrollment.status == .active
                                ? .success
                                : .neutral
                        )
                    }
                }
            }
        } header: {
            Text("participant.profile.enrollments")
        }
    }

    private var settingsSection: some View {
        Section("participant.profile.settings") {
            Toggle(
                "participant.profile.notifications",
                isOn: $notificationsEnabled
            )
            Toggle(
                "participant.profile.dark_preview",
                isOn: $usesDarkAppearance
            )
            .disabled(true)
        }
    }

    private var legalSection: some View {
        Section("participant.profile.privacy") {
            NavigationLink {
                ParticipantLegalPlaceholderView(
                    title: "participant.legal.privacy.title",
                    message: "participant.legal.privacy.message"
                )
            } label: {
                Label(
                    "participant.legal.privacy.title",
                    systemImage: "hand.raised"
                )
            }
            NavigationLink {
                ParticipantLegalPlaceholderView(
                    title: "participant.legal.terms.title",
                    message: "participant.legal.terms.message"
                )
            } label: {
                Label(
                    "participant.legal.terms.title",
                    systemImage: "doc.text"
                )
            }
            Label(
                "participant.delete_account.info",
                systemImage: "person.crop.circle.badge.minus"
            )
            .foregroundStyle(Color.appSecondaryText)
        }
    }

    private var accountSection: some View {
        Section {
            Button("participant.logout", role: .destructive) {
                Task {
                    await store.logoutLocalDemo()
                    router.resetAllPaths()
                }
            }
            .accessibilityIdentifier("participant.logout")
        } footer: {
            Text("participant.logout.local_notice")
        }
    }

    private func enrollmentStatusKey(
        _ status: EnrollmentStatus
    ) -> String {
        "participant.enrollment.\(status.rawValue)"
    }
}

private struct ParticipantLegalPlaceholderView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "doc.text")
        } description: {
            Text(message)
        }
        .navigationTitle(Text(title))
    }
}

#Preview("Profil peserta") {
    ParticipantProfilePreview()
}

@MainActor
private struct ParticipantProfilePreview: View {
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )
    @State private var router = ShellTabRouter()

    var body: some View {
        NavigationStack {
            ParticipantProfileView(store: store, router: router)
                .task { await store.load() }
        }
    }
}
