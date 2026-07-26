import OSLog
import SwiftUI

@MainActor
struct RootView: View {
    let router: AppRouter

    @Environment(\.appEnvironment) private var appEnvironment

#if DEBUG
    @State private var selectedRole = DemoRole.participant
    @State private var sessionSwitchState = DemoSessionSwitchState.switching
#endif

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    header
                    localModeStatus

#if DEBUG
                    roleSelection
                    enterDemoButton
#else
                    releaseFoundationStatus
#endif

                    configurationDetails
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.xLarge)
                .frame(maxWidth: .infinity)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .localDemo(let role):
                    DemoPlaceholderView(role: role)
                }
            }
            .navigationTitle(Text("navigation.home"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(.brandPrimary)
#if DEBUG
        .task(id: selectedRole) {
            await switchDebugSession()
        }
#endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.brandPrimary)
                .accessibilityHidden(true)

            Text("app.title")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.appPrimaryText)
                .accessibilityIdentifier("root.title")

            Text("app.subtitle")
                .font(.body)
                .foregroundStyle(Color.appSecondaryText)
        }
    }

    private var localModeStatus: some View {
        Label("configuration.mode.local_demo", systemImage: "iphone.and.arrow.forward")
            .font(.headline)
            .foregroundStyle(Color.appPrimaryText)
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .adaptiveDemoSurface()
            .accessibilityIdentifier("root.local-mode")
    }

#if DEBUG
    private var roleSelection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("root.role_picker.title")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appPrimaryText)

                Text("root.role_picker.description")
                    .font(.body)
                    .foregroundStyle(Color.appSecondaryText)
            }

            Picker("root.role_picker.label", selection: $selectedRole) {
                ForEach(DemoRole.allCases) { role in
                    Text(LocalizedStringKey(role.titleLocalizationKey))
                        .tag(role)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("root.role-picker")

            HStack(spacing: AppSpacing.xSmall) {
                Image(systemName: selectedRole.systemImage)
                    .accessibilityHidden(true)

                Text("root.current_role")

                Text(LocalizedStringKey(selectedRole.titleLocalizationKey))
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(Color.appPrimaryText)
            .animation(.default, value: selectedRole)

            sessionStatus
        }
        .padding(AppSpacing.medium)
        .adaptiveDemoSurface()
    }

    private var enterDemoButton: some View {
        Button {
            AppLog.navigation.info("Membuka placeholder demo lokal.")
            router.enterLocalDemo(as: selectedRole)
        } label: {
            Label("root.enter_demo", systemImage: "arrow.right")
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .disabled(!sessionSwitchState.isReady(for: selectedRole.userRole))
        .accessibilityIdentifier("root.enter-demo")
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

    private func switchDebugSession() async {
        sessionSwitchState = .switching
        guard let repository = appEnvironment.repositories?.session else {
            sessionSwitchState = .failed(
                appEnvironment.bootstrapError ?? .unknown
            )
            return
        }

        do {
            let session = try await repository.switchDebugRole(
                to: selectedRole.userRole
            )
            guard !Task.isCancelled else {
                return
            }
            if let role = session.role {
                sessionSwitchState = .ready(role)
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
#endif

    private var releaseFoundationStatus: some View {
        Label("root.release_foundation", systemImage: "checkmark.seal")
            .font(.body)
            .foregroundStyle(Color.appPrimaryText)
            .padding(AppSpacing.medium)
            .adaptiveDemoSurface()
    }

    private var configurationDetails: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("root.configuration.title")
                .font(.headline)
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
        .font(.subheadline)
    }
}

#if DEBUG
private enum DemoSessionSwitchState: Equatable {
    case switching
    case ready(UserRole)
    case failed(DomainError)

    func isReady(for role: UserRole) -> Bool {
        self == .ready(role)
    }
}
#endif

#Preview("Terang") {
    RootView(router: AppRouter())
        .environment(\.appEnvironment, .preview)
        .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Gelap") {
    RootView(router: AppRouter())
        .environment(\.appEnvironment, .preview)
        .environment(\.locale, Locale(identifier: "id-ID"))
        .preferredColorScheme(.dark)
}

#Preview("Teks aksesibilitas") {
    RootView(router: AppRouter())
        .environment(\.appEnvironment, .preview)
        .environment(\.locale, Locale(identifier: "id-ID"))
        .dynamicTypeSize(.accessibility5)
}
