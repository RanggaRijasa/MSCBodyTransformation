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
        RoleAppShellView(
            demoRole: .guest,
            scenario: .guestHome
        )
#endif
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
