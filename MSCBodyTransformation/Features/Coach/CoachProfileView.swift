import SwiftUI

@MainActor
struct CoachProfileView: View {
    let state: CoachProfileState
    let router: ShellTabRouter

    @State private var actionError: String?

    var body: some View {
        @Bindable var state = state

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
                    profile: snapshot.profile,
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
        .alert(
            "coach.profile.saved.title",
            isPresented: $state.saveConfirmationVisible
        ) {
            Button("action.close", role: .cancel) {}
        } message: {
            Text("coach.profile.saved.message")
        }
        .accessibilityIdentifier("coach.profile")
    }

    private func profileForm(
        profile: CoachProfile,
        bindableState: Bindable<CoachProfileState>
    ) -> some View {
        Form {
            identitySection(bindableState: bindableState)
            visibilitySection(bindableState: bindableState)
            enrollmentIdentifierSection(profile)
            settingsSection(bindableState: bindableState)
            saveSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .refreshable {
            await state.load()
        }
    }

    private func identitySection(
        bindableState: Bindable<CoachProfileState>
    ) -> some View {
        Section("coach.profile.identity.title") {
            TextField(
                "coach.profile.name",
                text: bindableState.displayName
            )
            TextField(
                "coach.profile.city",
                text: bindableState.city
            )
            TextField(
                "coach.profile.biography",
                text: bindableState.biography,
                axis: .vertical
            )
            .lineLimit(3...8)
        }
    }

    private func visibilitySection(
        bindableState: Bindable<CoachProfileState>
    ) -> some View {
        Section {
            Toggle(
                "coach.profile.visibility.toggle",
                isOn: bindableState.isPublic
            )
            HStack {
                Text("coach.profile.visibility.status")
                Spacer()
                StatusBadge(
                    title: state.isPublic
                        ? "coach.profile.visibility.public"
                        : "coach.profile.visibility.private",
                    kind: state.isPublic ? .success : .neutral
                )
            }
        } header: {
            Text("coach.profile.visibility.title")
        } footer: {
            Text("coach.profile.visibility.footer")
        }
    }

    private func enrollmentIdentifierSection(
        _ profile: CoachProfile
    ) -> some View {
        Section {
            LabeledContent("coach.identifier.code_label") {
                Text(profile.enrollmentIdentifier)
                    .font(.body.monospacedDigit())
                    .textSelection(.enabled)
            }
        } header: {
            Text("coach.identifier.profile_section")
        } footer: {
            Text("coach.identifier.stable_notice")
        }
    }

    private func settingsSection(
        bindableState: Bindable<CoachProfileState>
    ) -> some View {
        Section("coach.profile.settings.title") {
            Toggle(
                "coach.profile.notifications",
                isOn: bindableState.notificationsEnabled
            )
            LabeledContent(
                "coach.profile.language",
                value: "Bahasa Indonesia"
            )
            LabeledContent(
                "coach.profile.mode",
                value: String(localized: "configuration.mode.local_demo")
            )
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                Task {
                    await save()
                }
            } label: {
                if state.isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("coach.profile.save")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandPrimary)
            .disabled(state.isSaving)
            .accessibilityIdentifier("coach.profile.save")

            if let actionError {
                Label(
                    actionError,
                    systemImage: "exclamationmark.circle"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appDestructive)
            }
        }
    }

    private func save() async {
        do {
            try await state.save()
            actionError = nil
        } catch let error as DomainError {
            actionError = CoachFormatting.reason(error)
        } catch {
            actionError = String(localized: "coach.error.generic")
        }
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
