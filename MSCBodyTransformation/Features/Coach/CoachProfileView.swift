import SwiftUI

@MainActor
struct CoachProfileView: View {
    let state: CoachProfileState
    let router: ShellTabRouter

    @State private var presentedSheet: CoachProfileSheet?
    @State private var actionError: String?

    var body: some View {
        @Bindable var state = state

        if state.isLoggedOut {
            loggedOutState
        } else {
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
                    profileForm(
                        snapshot: snapshot,
                        bindableState: $state
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .task {
                if state.state == .idle {
                    await state.load()
                }
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .edit(let snapshot):
                    CoachProfileEditorSheet(
                        state: state,
                        snapshot: snapshot
                    )
                case .delete(let email):
                    AccountDeletionView(email: email)
                }
            }
            .alert(
                "coach.profile.saved.title",
                isPresented: $state.saveConfirmationVisible
            ) {
                Button("action.close", role: .cancel) {}
            } message: {
                Text("coach.profile.saved.message")
            }
        }
    }

    private func profileForm(
        snapshot: CoachProfileSnapshot,
        bindableState: Bindable<CoachProfileState>
    ) -> some View {
        Form {
            identitySection(snapshot)
            profileDataSection(snapshot)
            coachSettingsSection(
                snapshot.profile,
                bindableState: bindableState
            )
            qrSection
            settingsSection(bindableState: bindableState)
            legalSection
            accountSection(email: snapshot.user.email)
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .refreshable {
            await state.load()
        }
        .accessibilityIdentifier("coach.profile")
    }

    private func identitySection(
        _ snapshot: CoachProfileSnapshot
    ) -> some View {
        Section {
            VStack(spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: snapshot.profile.displayName,
                    imageName: snapshot.profile.localPhotoReference,
                    size: 96
                )
                .accessibilityIdentifier("coach.profile.photo")

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
                    presentedSheet = .edit(snapshot)
                } label: {
                    Text("participant.profile.edit")
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandPrimary)
                .accessibilityIdentifier("coach.profile.edit")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.small)
        } header: {
            Text("coach.profile.identity.title")
        }
    }

    private func profileDataSection(
        _ snapshot: CoachProfileSnapshot
    ) -> some View {
        Section("participant.profile.data") {
            LabeledContent(
                "participant.profile.field.name",
                value: snapshot.profile.displayName
            )
            .accessibilityIdentifier("coach.profile.name")

            LabeledContent(
                "participant.profile.field.email",
                value: snapshot.user.email
            )

            LabeledContent(
                "participant.profile.field.city",
                value: snapshot.profile.city
            )

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("coach.profile.biography")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appSecondaryText)
                Text(snapshot.profile.biography)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appPrimaryText)
            }
            .padding(.vertical, AppSpacing.xSmall)
        }
    }

    private func coachSettingsSection(
        _ profile: CoachProfile,
        bindableState: Bindable<CoachProfileState>
    ) -> some View {
        Section {
            Toggle(
                "coach.profile.visibility.toggle",
                isOn: bindableState.isPublic
            )

            LabeledContent("coach.profile.visibility.status") {
                StatusBadge(
                    title: state.isPublic
                        ? "coach.profile.visibility.public"
                        : "coach.profile.visibility.private",
                    kind: state.isPublic ? .success : .neutral
                )
            }

            LabeledContent("coach.profile.approval.status") {
                StatusBadge(
                    title: profile.isApproved
                        ? "status.approved"
                        : "status.awaiting_approval",
                    kind: profile.isApproved ? .success : .pending
                )
            }

            Button {
                Task {
                    await saveSettings()
                }
            } label: {
                if state.isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("coach.profile.save_settings")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(state.isSaving)
            .accessibilityIdentifier("coach.profile.save-settings")

            if let actionError {
                Label(
                    actionError,
                    systemImage: "exclamationmark.circle"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appDestructive)
            }
        } header: {
            Text("coach.profile.coach_settings")
        } footer: {
            Text("coach.profile.visibility.footer")
        }
    }

    private var qrSection: some View {
        Section {
            Button {
                router.navigate(
                    to: .coach(.coachIdentifier),
                    in: .coach(.profile)
                )
            } label: {
                Label(
                    "coach.identifier.title",
                    systemImage: "qrcode"
                )
                .frame(minHeight: 44)
            }
            .accessibilityIdentifier("coach.profile.open-qr")
        } header: {
            Text("coach.identifier.profile_section")
        } footer: {
            Text("coach.identifier.stable_notice")
        }
    }

    private func settingsSection(
        bindableState: Bindable<CoachProfileState>
    ) -> some View {
        Section("participant.profile.settings") {
            Toggle(
                "coach.profile.notifications",
                isOn: bindableState.notificationsEnabled
            )
            LabeledContent(
                "participant.profile.dark_preview",
                value: String(
                    localized:
                        "participant.profile.appearance.system",
                    defaultValue: "Otomatis"
                )
            )
            LabeledContent(
                "coach.profile.language",
                value: "Bahasa Indonesia"
            )
            LabeledContent(
                "coach.profile.mode",
                value: String(
                    localized: "configuration.mode.local_demo",
                    defaultValue: "Mode pengembangan lokal"
                )
            )
        }
    }

    private var legalSection: some View {
        Section("participant.profile.privacy") {
            NavigationLink {
                CoachLegalPlaceholderView(
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
            .accessibilityIdentifier("coach.profile.legal.privacy")

            NavigationLink {
                CoachLegalPlaceholderView(
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
            .accessibilityIdentifier("coach.profile.legal.terms")

        }
    }

    private func accountSection(email: String) -> some View {
        Section {
            Button(
                state.isLocalDemo
                    ? "participant.logout"
                    : "participant.logout.account",
                role: .destructive
            ) {
                Task {
                    await state.logoutLocalDemo()
                    router.resetAllPaths()
                }
            }
            .accessibilityIdentifier("coach.logout")

            if !state.isLocalDemo {
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
                    "coach.account-deletion.open"
                )
            }
        } footer: {
            Text(
                state.isLocalDemo
                    ? "participant.logout.local_notice"
                    : "participant.logout.account_notice"
            )
        }
    }

    private var loggedOutState: some View {
        ContentUnavailableView {
            Label(
                "coach.profile.logged_out.title",
                systemImage: "person.crop.circle"
            )
        } description: {
            Text("coach.profile.logged_out.message")
        } actions: {
            Button("coach.profile.logged_out.action") {
                Task {
                    await state.resumeLocalDemo()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brandPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .accessibilityIdentifier("coach.profile.logged-out")
    }

    private func saveSettings() async {
        do {
            try await state.saveSettings()
            actionError = nil
        } catch let error as DomainError {
            actionError = CoachFormatting.reason(error)
        } catch {
            actionError = String(
                localized: "coach.error.generic",
                defaultValue: "Terjadi kendala. Coba lagi."
            )
        }
    }
}

private enum CoachProfileSheet: Identifiable {
    case edit(CoachProfileSnapshot)
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

private struct CoachLegalPlaceholderView: View {
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

#Preview("Profil Coach") {
    NavigationStack {
        CoachProfilePreview()
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

@MainActor
private struct CoachProfilePreview: View {
    @State private var state = CoachProfileState(environment: .preview)
    @State private var router = ShellTabRouter()

    var body: some View {
        CoachProfileView(state: state, router: router)
            .navigationTitle(Text("tab.coach.profile"))
    }
}
