import SwiftUI

@MainActor
struct ParticipantProfileView: View {
    let store: ParticipantJourneyStore
    let router: ShellTabRouter

    @State private var notificationsEnabled = true
    @State private var presentedSheet: ParticipantProfileSheet?

    var body: some View {
        if store.isGuest {
            guestProfile
        } else if let snapshot = store.snapshot {
            Form {
                identitySection(snapshot)
                profileDataSection(snapshot)
                coachSection(snapshot)
                settingsSection
                legalSection
#if DEBUG
                ParticipantDebugToolsView(store: store)
#endif
                accountSection(email: snapshot.user.email)
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .accessibilityIdentifier("participant.profile")
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .edit(let profile, let email):
                    ParticipantProfileEditorSheet(
                        store: store,
                        profile: profile,
                        email: email
                    )
                case .delete(let email):
                    AccountDeletionView(email: email)
                }
            }
        } else {
            LoadingStateView()
        }
    }

    private var guestProfile: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Label(
                        "guest.profile.title",
                        systemImage: "person.crop.circle.badge.plus"
                    )
                    .font(AppTypography.sectionTitle)
                    Text("guest.profile.message")
                        .font(AppTypography.body)
                        .foregroundStyle(Color.appSecondaryText)

                    Button("auth.action.login") {
                        Task {
                            await store.requestAuthentication(
                                destination: .login,
                                reason: .accountSettings
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.brandPrimary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .accessibilityIdentifier("guest.profile.login")

                    Button("auth.action.register") {
                        Task {
                            await store.requestAuthentication(
                                destination: .register,
                                reason: .accountSettings
                            )
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .accessibilityIdentifier("guest.profile.register")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, AppSpacing.small)
            }
            legalSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .accessibilityIdentifier("participant.guest.profile")
    }

    private func identitySection(
        _ snapshot: ParticipantJourneySnapshot
    ) -> some View {
        Section {
            VStack(spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: snapshot.profile.displayName,
                    imageName: snapshot.profile.localPhotoReference,
                    size: 96
                )
                .accessibilityIdentifier("participant.profile.photo")

                VStack(spacing: AppSpacing.xxSmall) {
                    Text(snapshot.profile.displayName)
                        .font(AppTypography.sectionTitle)
                        .multilineTextAlignment(.center)
                    Text(snapshot.user.email)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                    Text(snapshot.profile.city)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                }

                Button {
                    presentedSheet = .edit(
                        snapshot.profile,
                        snapshot.user.email
                    )
                } label: {
                    Text("participant.profile.edit")
                    .frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandPrimary)
                .accessibilityIdentifier("participant.profile.edit")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.small)
        } header: {
            Text("participant.profile.identity")
        }
    }

    private func profileDataSection(
        _ snapshot: ParticipantJourneySnapshot
    ) -> some View {
        Section("participant.profile.data") {
            LabeledContent(
                "participant.profile.field.name",
                value: snapshot.profile.displayName
            )
            .accessibilityIdentifier("participant.profile.name")

            LabeledContent(
                "participant.profile.field.phone",
                value: snapshot.profile.phoneNumber
                    ?? String(
                        localized:
                            "participant.profile.phone.empty",
                        defaultValue: "Belum ditambahkan"
                    )
            )
            .accessibilityIdentifier("participant.profile.phone")

            LabeledContent(
                "participant.profile.field.email",
                value: snapshot.user.email
            )
        }
    }

    private func coachSection(
        _ snapshot: ParticipantJourneySnapshot
    ) -> some View {
        Section {
            if let coach = currentCoach(in: snapshot) {
                HStack(spacing: AppSpacing.medium) {
                    UserAvatar(
                        displayName: coach.displayName,
                        size: 56
                    )
                    VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                        Text(coach.displayName)
                            .font(AppTypography.cardTitle)
                        Text(coach.city)
                            .font(AppTypography.secondary)
                            .foregroundStyle(Color.appSecondaryText)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("participant.profile.coach")
            } else {
                Label(
                    "participant.profile.coach.empty",
                    systemImage: "person.crop.circle.badge.questionmark"
                )
                .foregroundStyle(Color.appSecondaryText)
            }

        } header: {
            Text("participant.profile.coach.section")
        } footer: {
            Text(
                "Coach ditetapkan saat pertama kali mengikuti program. "
                    + "Perubahan hanya dapat dilakukan Admin dengan alasan "
                    + "yang tercatat."
            )
        }
    }

    private var settingsSection: some View {
        Section("participant.profile.settings") {
            Toggle(
                "participant.profile.notifications",
                isOn: $notificationsEnabled
            )
            LabeledContent(
                "participant.profile.dark_preview",
                value: String(
                    localized:
                        "participant.profile.appearance.system",
                    defaultValue: "Otomatis"
                )
            )
        }
    }

    private var legalSection: some View {
        Section("participant.profile.privacy") {
            NavigationLink {
                ParticipantLegalPlaceholderView(
                    title: "participant.legal.privacy.title",
                    message: "participant.legal.privacy.message"
                )
                .singlePressNavigationBackButton()
            } label: {
                Label(
                    "participant.legal.privacy.title",
                    systemImage: "hand.raised"
                )
            }
            .accessibilityIdentifier("participant.profile.legal.privacy")

            NavigationLink {
                ParticipantLegalPlaceholderView(
                    title: "participant.legal.terms.title",
                    message: "participant.legal.terms.message"
                )
                .singlePressNavigationBackButton()
            } label: {
                Label(
                    "participant.legal.terms.title",
                    systemImage: "doc.text"
                )
            }
            .accessibilityIdentifier("participant.profile.legal.terms")

        }
    }

    private func accountSection(email: String) -> some View {
        Section {
            Button(
                store.isLocalDemo
                    ? "participant.logout"
                    : "participant.logout.account",
                role: .destructive
            ) {
                Task {
                    await store.logoutLocalDemo()
                    router.resetAllPaths()
                }
            }
            .accessibilityIdentifier("participant.logout")

            if !store.isLocalDemo {
                Button(
                    String(
                        localized: "account_deletion.action",
                        defaultValue: "Hapus akun"
                    ),
                    role: .destructive
                ) {
                    presentedSheet = .delete(email)
                }
                .accessibilityIdentifier(
                    "participant.account-deletion.open"
                )
            }
        } footer: {
            Text(
                store.isLocalDemo
                    ? "participant.logout.local_notice"
                    : "participant.logout.account_notice"
            )
        }
    }

    private func currentCoach(
        in snapshot: ParticipantJourneySnapshot
    ) -> CoachProfile? {
        snapshot.coaches.first {
            $0.id == snapshot.profile.coachID
        }
    }

}

private enum ParticipantProfileSheet: Identifiable {
    case edit(ParticipantProfile, String)
    case delete(String)

    var id: String {
        switch self {
        case .edit:
            "edit"
        case .delete:
            "delete"
        }
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
