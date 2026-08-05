import Foundation
import SwiftUI

@MainActor
struct RootView: View {
    let router: AppRouter

    @Environment(\.appEnvironment) private var appEnvironment

#if DEBUG
    @State private var selectedRole: DemoRole
    @State private var selectedScenario: AppDemoScenario
    @State private var sessionSwitchState = DemoSessionSwitchState.switching
    @State private var activeDemo: DemoShellLaunch?
#endif

    init(
        router: AppRouter,
        launchArguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.router = router
#if DEBUG
        let launchConfiguration = DebugLaunchConfiguration(
            arguments: launchArguments
        )
        _selectedRole = State(initialValue: launchConfiguration.role)
        _selectedScenario = State(initialValue: launchConfiguration.scenario)
        _activeDemo = State(
            initialValue: launchConfiguration.skipsLanding
                ? DemoShellLaunch(
                    role: launchConfiguration.role,
                    scenario: launchConfiguration.scenario
                )
                : nil
        )
#endif
    }

    var body: some View {
        if appEnvironment.configuration.mode != .localDemo {
            externalSessionRoot
        } else {
#if DEBUG
            Group {
                if let activeDemo {
                    RoleAppShellView(
                        demoRole: activeDemo.role,
                        scenario: activeDemo.scenario
                    )
                } else {
                    debugLanding
                }
            }
#else
            configurationFailure
#endif
        }
    }

    @ViewBuilder
    private var externalSessionRoot: some View {
        if let sessionRepository = appEnvironment.repositories?.session {
            SessionManagedRootView(repository: sessionRepository)
        } else {
            configurationFailure
        }
    }

    private var configurationFailure: some View {
        ErrorStateView(
            error: appEnvironment.bootstrapError ?? .unknown
        )
        .padding(AppSpacing.medium)
        .background(Color.appBackground.ignoresSafeArea())
    }

#if DEBUG
    private var debugLanding: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    header
                    localModeStatus
                    demoConfiguration
                    enterDemoButton
                    configurationDetails
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.xLarge)
                .frame(maxWidth: .infinity)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(Text("navigation.home"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(.brandPrimary)
        .onChange(of: selectedRole) { _, role in
            selectedScenario = .defaultScenario(for: role)
        }
        .task(id: selectedRole) {
            await switchDebugSession()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Image(systemName: "figure.run.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.brandPrimary)
                .accessibilityHidden(true)

            Text("app.title")
                .font(AppTypography.screenTitle)
                .foregroundStyle(Color.appPrimaryText)
                .accessibilityIdentifier("root.title")

            Text("app.subtitle")
                .font(AppTypography.body)
                .foregroundStyle(Color.appSecondaryText)
        }
    }

    private var localModeStatus: some View {
        Label(
            "configuration.mode.local_demo",
            systemImage: "iphone.and.arrow.forward"
        )
        .font(AppTypography.cardTitle)
        .foregroundStyle(Color.appPrimaryText)
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .adaptiveGlassSurface()
        .accessibilityIdentifier("root.local-mode")
    }

    private var demoConfiguration: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(
                title: "root.role_picker.title",
                subtitle: "root.role_picker.description"
            )

            Picker("root.role_picker.label", selection: $selectedRole) {
                ForEach(DemoRole.allCases) { role in
                    Text(LocalizedStringKey(role.titleLocalizationKey))
                        .tag(role)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("root.role-picker")

            Picker(
                "root.scenario_picker.label",
                selection: validScenarioSelection
            ) {
                ForEach(availableScenarios) { scenario in
                    Text(
                        LocalizedStringKey(
                            scenario.titleLocalizationKey
                        )
                    )
                    .tag(scenario)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .accessibilityIdentifier("root.scenario-picker")

            sessionStatus
        }
        .padding(AppSpacing.medium)
        .adaptiveGlassSurface()
    }

    private var enterDemoButton: some View {
        Button {
            openSelectedDemo()
        } label: {
            Label("root.enter_demo", systemImage: "arrow.right")
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .disabled(!sessionSwitchState.isReady(for: selectedRole))
        .accessibilityIdentifier("root.enter-demo")
    }

    private var availableScenarios: [AppDemoScenario] {
        AppDemoScenario.scenarios(for: selectedRole)
    }

    private var validScenarioSelection: Binding<AppDemoScenario> {
        Binding(
            get: {
                guard availableScenarios.contains(selectedScenario) else {
                    return AppDemoScenario.defaultScenario(
                        for: selectedRole
                    )
                }
                return selectedScenario
            },
            set: { selectedScenario = $0 }
        )
    }

    @ViewBuilder
    private var sessionStatus: some View {
        switch sessionSwitchState {
        case .switching:
            Label(
                "root.session.switching",
                systemImage: "arrow.triangle.2.circlepath"
            )
            .foregroundStyle(Color.appSecondaryText)
        case .ready:
            Label("root.session.ready", systemImage: "checkmark.circle")
                .foregroundStyle(Color.appPrimaryText)
        case .failed(let error):
            let message = DomainErrorMessageMapper.message(for: error)
            Label(
                LocalizedStringKey(message.messageKey),
                systemImage: "exclamationmark.triangle"
            )
            .foregroundStyle(Color.appSecondaryText)
        }
    }

    private var configurationDetails: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("root.configuration.title")
                .font(AppTypography.cardTitle)
                .foregroundStyle(Color.appPrimaryText)

            configurationRow(
                title: "root.configuration.build",
                value: appEnvironment.configuration.build == .debug
                    ? "configuration.build.debug"
                    : "configuration.build.release"
            )
            configurationRow(
                title: "root.configuration.locale",
                value: appEnvironment.configuration.localeIdentifier
            )
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

    private func configurationRow(
        title: LocalizedStringKey,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.medium) {
            Text(title)
                .foregroundStyle(Color.appSecondaryText)
            Spacer(minLength: AppSpacing.medium)
            Text(LocalizedStringKey(value))
                .foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(.trailing)
        }
        .font(AppTypography.secondary)
    }

    private func switchDebugSession() async {
        sessionSwitchState = .switching
        guard let repository = appEnvironment.repositories?.session else {
            sessionSwitchState = .failed(
                appEnvironment.bootstrapError ?? .unknown
            )
            return
        }

        do {
            guard let userRole = selectedRole.userRole else {
                await repository.setDebugScenario(.loggedOut)
                sessionSwitchState = .ready(.guest)
                return
            }
            let session = try await repository.switchDebugRole(to: userRole)
            guard !Task.isCancelled else {
                return
            }
            if session.role != nil {
                sessionSwitchState = .ready(selectedRole)
            } else {
                sessionSwitchState = .failed(.unknown)
            }
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            sessionSwitchState = .failed(error)
        } catch {
            sessionSwitchState = .failed(.unknown)
        }
    }

    private func openSelectedDemo() {
        activeDemo = DemoShellLaunch(
            role: selectedRole,
            scenario: selectedScenario
        )
    }
#endif
}

@MainActor
private struct SessionManagedRootView: View {
    @State private var store: SessionStore
    @Environment(\.appEnvironment) private var appEnvironment

    init(repository: any SessionRepository) {
        _store = State(initialValue: SessionStore(repository: repository))
    }

    var body: some View {
        Group {
            switch store.route {
            case .bootstrapping:
                LoadingStateView()
                    .padding(AppSpacing.medium)
            case .loggedOut:
                RoleAppShellView(demoRole: .guest, scenario: .guestHome)
            case .authenticated(let role):
                RoleAppShellView(
                    role: role,
                    scenario: .defaultScenario(for: DemoRole(role: role))
                )
            case .awaitingEmailVerification:
                EmailVerificationPendingView(store: store)
            case .passwordRecovery:
                PasswordRecoveryCompletionView(store: store)
            case .profileProvisioning:
                sessionMessage(
                    title: "auth.profile_provisioning.title",
                    message: "auth.profile_provisioning.message",
                    systemImage: "person.crop.circle.badge.clock"
                )
            case .provisionalOnboarding:
                ProvisionalOnboardingHost(
                    environment: appEnvironment
                )
            case .provisionalCleanupPending:
                sessionMessage(
                    title: "auth.cleanup.title",
                    message: "auth.cleanup.message",
                    systemImage: "clock.arrow.circlepath"
                )
            case .expired:
                sessionMessage(
                    title: "error.session_expired.title",
                    message: "error.session_expired.message",
                    systemImage: "person.crop.circle.badge.xmark"
                )
            case .recoverableError:
                ErrorStateView(error: .unknown) {
                    Task { await store.retry() }
                }
                .padding(AppSpacing.medium)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { await store.bootstrap() }
        .task { await store.observeSessionChanges() }
        .onOpenURL { url in
            Task { await store.handleAuthenticationCallback(url) }
        }
    }

    private func sessionMessage(
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        systemImage: String
    ) -> some View {
        EmptyStateView(
            title: title,
            message: message,
            systemImage: systemImage
        )
        .padding(AppSpacing.medium)
    }
}

@MainActor
private struct ProvisionalOnboardingHost: View {
    private let environment: AppEnvironment
    @State private var participantStore: ParticipantJourneyStore

    init(environment: AppEnvironment) {
        self.environment = environment
        _participantStore = State(
            initialValue: ParticipantJourneyStore(
                environment: environment,
                allowsGuestAccess: true
            )
        )
    }

    var body: some View {
        AuthenticationFlowView(
            environment: environment,
            store: participantStore,
            presentation: AuthenticationPresentation(
                destination: .profileOnboarding
            ),
            scenario: .guestHome
        )
        .task { await participantStore.load() }
    }
}

@MainActor
private struct EmailVerificationPendingView: View {
    let store: SessionStore
    @State private var isSending = false
    @State private var feedback: String?

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            EmptyStateView(
                title: "auth.verification.title",
                message: "auth.verification.message",
                systemImage: "envelope.badge"
            )
            if let feedback {
                Text(feedback)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            Button("auth.verification.resend") {
                Task { await resend() }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(isSending)
            Button("action.cancel", role: .cancel) {
                Task { await store.signOut() }
            }
            .frame(minHeight: 44)
        }
        .padding(AppSpacing.medium)
    }

    private func resend() async {
        isSending = true
        defer { isSending = false }
        do {
            try await store.resendVerification()
            feedback = String(
                localized: "auth.verification.resent",
                defaultValue: "Email verifikasi telah dikirim ulang."
            )
        } catch {
            feedback = String(
                localized: "auth.verification.resend_error",
                defaultValue: "Email belum dapat dikirim ulang. Coba lagi nanti."
            )
        }
    }
}

@MainActor
private struct PasswordRecoveryCompletionView: View {
    let store: SessionStore
    @State private var password = ""
    @State private var confirmation = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("auth.password_reset.new_password", text: $password)
                    SecureField(
                        "auth.password_reset.confirm_password",
                        text: $confirmation
                    )
                } header: {
                    Text("auth.password_reset.title")
                } footer: {
                    Text("auth.password_reset.requirement")
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(Color.appDestructive)
                }
                Button("auth.password_reset.save") {
                    Task { await updatePassword() }
                }
                .disabled(
                    password.count < 8
                        || password != confirmation
                        || isSubmitting
                )
            }
            .navigationTitle(Text("auth.password_reset.title"))
        }
    }

    private func updatePassword() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await store.updatePassword(password)
            errorMessage = nil
        } catch {
            errorMessage = String(
                localized: "auth.password_reset.error",
                defaultValue: "Password belum dapat diperbarui. Coba lagi."
            )
        }
    }
}

private extension DemoRole {
    init(role: UserRole) {
        switch role {
        case .participant:
            self = .participant
        case .coach:
            self = .coach
        case .admin:
            self = .admin
        }
    }
}

#if DEBUG
private enum DemoSessionSwitchState: Equatable {
    case switching
    case ready(DemoRole)
    case failed(DomainError)

    func isReady(for role: DemoRole) -> Bool {
        self == .ready(role)
    }
}

private struct DemoShellLaunch: Equatable {
    let role: DemoRole
    let scenario: AppDemoScenario
}
#endif

#Preview("Root — terang") {
    RootView(router: AppRouter(), launchArguments: [])
        .environment(\.appEnvironment, .preview)
        .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Root — gelap") {
    RootView(router: AppRouter(), launchArguments: [])
        .environment(\.appEnvironment, .preview)
        .environment(\.locale, Locale(identifier: "id-ID"))
        .preferredColorScheme(.dark)
}

#Preview("Root — teks aksesibilitas") {
    RootView(router: AppRouter(), launchArguments: [])
        .environment(\.appEnvironment, .preview)
        .environment(\.locale, Locale(identifier: "id-ID"))
        .dynamicTypeSize(.accessibility5)
}
