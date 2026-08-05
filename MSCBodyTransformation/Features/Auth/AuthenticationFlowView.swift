import AuthenticationServices
import SwiftUI

private enum AuthenticationGestureMetrics {
    static let leadingEdgeWidth: CGFloat = 28
    static let minimumHorizontalTravel: CGFloat = 88
}

@MainActor
struct AuthenticationFlowView: View {
    @State private var state: AuthenticationFlowState
    @State private var navigationPath: [AuthenticationDestination]

    init(
        environment: AppEnvironment,
        store: ParticipantJourneyStore,
        presentation: AuthenticationPresentation,
        scenario: AppDemoScenario
    ) {
        let initialState = AuthenticationFlowState(
            environment: environment,
            store: store,
            presentation: presentation,
            scenario: scenario
        )
        _state = State(initialValue: initialState)
        _navigationPath = State(
            initialValue: Self.navigationPath(
                to: presentation.destination
            )
        )
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            authenticationScreen(for: .login)
                .navigationDestination(
                    for: AuthenticationDestination.self
                ) { destination in
                    authenticationScreen(for: destination)
                }
        }
        .tint(.brandPrimary)
        .onChange(of: navigationPath) { _, path in
            let destination = path.last ?? .login
            if state.destination != destination {
                state.synchronizeDestinationAfterNavigation(destination)
            }
        }
        .onChange(of: state.destination) { _, destination in
            let targetPath = Self.navigationPath(to: destination)
            if navigationPath != targetPath {
                navigationPath = targetPath
            }
        }
        .task {
            await state.prepareDemoStateIfNeeded()
        }
    }

    @ViewBuilder
    private func authenticationScreen(
        for destination: AuthenticationDestination
    ) -> some View {
        destinationView(for: destination)
            .navigationTitle(Text(navigationTitle(for: destination)))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(
                destination == .pendingCoachApproval
            )
            .toolbar {
                if destination == .login
                    || destination == .pendingCoachApproval {
                    ToolbarItem(placement: .cancellationAction) {
                        closeButton
                    }
                } else {
                    ToolbarItem(placement: .confirmationAction) {
                        closeButton
                    }
                }
            }
    }

    @ViewBuilder
    private func destinationView(
        for destination: AuthenticationDestination
    ) -> some View {
        switch destination {
        case .login:
            AuthenticationProviderChoiceView(
                state: state,
                isRegistration: false
            )
            .simultaneousGesture(leadingEdgeDismissGesture)
        case .loginEmail:
            EmailAuthenticationView(
                state: state,
                isRegistration: false
            )
        case .register:
            AuthenticationProviderChoiceView(
                state: state,
                isRegistration: true
            )
        case .registerEmail:
            EmailAuthenticationView(
                state: state,
                isRegistration: true
            )
        case .forgotPassword:
            ForgotPasswordView(state: state)
        case .profileOnboarding:
            ProfileOnboardingView(state: state)
        case .participantCoachQR:
            ParticipantCoachQRRegistrationView(state: state)
        case .coachEligibility:
            CoachApplicationView(state: state)
        case .coachPayment:
            CoachPaymentPreviewView(state: state)
        case .pendingCoachApproval:
            CoachPendingApprovalView(state: state)
        }
    }

    private var closeButton: some View {
        Button("action.close") {
            Task { await state.cancel() }
        }
        .accessibilityIdentifier("auth.close")
    }

    private var leadingEdgeDismissGesture: some Gesture {
        DragGesture(
            minimumDistance: 18,
            coordinateSpace: .global
        )
        .onEnded { value in
            let isFromLeadingEdge =
                value.startLocation.x
                    <= AuthenticationGestureMetrics.leadingEdgeWidth
            let isHorizontal =
                abs(value.translation.width)
                    > abs(value.translation.height)
            let movedFarEnough =
                value.translation.width
                    >= AuthenticationGestureMetrics.minimumHorizontalTravel

            guard isFromLeadingEdge,
                  isHorizontal,
                  movedFarEnough else {
                return
            }
            Task { await state.cancel() }
        }
    }

    private func navigationTitle(
        for destination: AuthenticationDestination
    ) -> LocalizedStringKey {
        switch destination {
        case .login, .loginEmail:
            "auth.login.navigation_title"
        case .register, .registerEmail:
            "auth.register.navigation_title"
        case .forgotPassword:
            "auth.forgot.navigation_title"
        case .profileOnboarding:
            "auth.profile.navigation_title"
        case .participantCoachQR:
            "auth.participant_qr.navigation_title"
        case .coachEligibility:
            "coach.eligibility.navigation_title"
        case .coachPayment:
            "coach.payment.navigation_title"
        case .pendingCoachApproval:
            "coach.pending.navigation_title"
        }
    }

    private static func navigationPath(
        to destination: AuthenticationDestination
    ) -> [AuthenticationDestination] {
        switch destination {
        case .login:
            []
        case .loginEmail:
            [.loginEmail]
        case .register:
            [.register]
        case .registerEmail:
            [.register, .registerEmail]
        case .forgotPassword:
            [.loginEmail, .forgotPassword]
        case .profileOnboarding:
            [.register, .profileOnboarding]
        case .participantCoachQR:
            [
                .register,
                .profileOnboarding,
                .participantCoachQR
            ]
        case .coachEligibility:
            [
                .register,
                .profileOnboarding,
                .coachEligibility
            ]
        case .coachPayment:
            [
                .register,
                .profileOnboarding,
                .coachEligibility,
                .coachPayment
            ]
        case .pendingCoachApproval:
            [
                .register,
                .profileOnboarding,
                .coachEligibility,
                .coachPayment,
                .pendingCoachApproval
            ]
        }
    }
}

@MainActor
private struct AuthenticationProviderChoiceView: View {
    let state: AuthenticationFlowState
    let isRegistration: Bool

    var body: some View {
        AuthFlowContainer {
            VStack(spacing: AppSpacing.large) {
                AuthFlowHeader(
                    systemImage: isRegistration
                        ? "person.badge.plus"
                        : "figure.run",
                    title: isRegistration
                        ? "auth.register.title"
                        : "auth.login.title",
                    message: isRegistration
                        ? "auth.register.message"
                        : "auth.login.message"
                )
                .accessibilityIdentifier(
                    isRegistration ? "auth.register" : "auth.login"
                )

#if DEBUG
                if state.isLocalDemo {
                    Label(
                        "auth.demo.compact_notice",
                        systemImage: "hammer.fill"
                    )
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appInfo)
                }
#endif

                VStack(spacing: AppSpacing.small) {
                    AuthenticationAppleButton {
                        Task {
                            await state.authenticateWithProvider(
                                .apple,
                                isRegistration: isRegistration
                            )
                        }
                    }
                    .accessibilityIdentifier(
                        isRegistration
                            ? "auth.register.apple"
                            : "auth.login.apple"
                    )

                    OfficialGoogleSignInButton {
                        Task {
                            await state.authenticateWithProvider(
                                .google,
                                isRegistration: isRegistration
                            )
                        }
                    }
                    .accessibilityIdentifier(
                        isRegistration
                            ? "auth.register.google"
                            : "auth.login.google"
                    )

                    if state.isEmailPasswordAuthenticationVisible {
                        Button {
                            if isRegistration {
                                state.openEmailRegistration()
                            } else {
                                state.openEmailLogin()
                            }
                        } label: {
                            Label(
                                isRegistration
                                    ? "auth.provider.email.register"
                                    : "auth.provider.email.login",
                                systemImage: "envelope"
                            )
                        }
                        .buttonStyle(
                            SecondaryActionButtonStyle(
                                foregroundColor: .appPrimaryText
                            )
                        )
                        .frame(maxWidth: 360)
                        .accessibilityIdentifier(
                            isRegistration
                                ? "auth.register.email-option"
                                : "auth.login.email-option"
                        )
                    }
                }
                .frame(maxWidth: .infinity)

                if let errorMessage = state.errorMessage {
                    AuthErrorBanner(message: errorMessage)
                }

                Spacer(minLength: AppSpacing.large)

                AuthSwitchDestinationButton(
                    prompt: isRegistration
                        ? "auth.register.login_prompt"
                        : "auth.login.register_prompt",
                    actionTitle: isRegistration
                        ? "auth.register.login_action"
                        : "auth.login.register_action",
                    identifier: isRegistration
                        ? "auth.register.open-login"
                        : "auth.login.open-register"
                ) {
                    if isRegistration {
                        state.openLogin()
                    } else {
                        state.openRegister()
                    }
                }
            }
            .frame(minHeight: 580)
        }
    }
}

@MainActor
private struct EmailAuthenticationView: View {
    let state: AuthenticationFlowState
    let isRegistration: Bool

    var body: some View {
        @Bindable var bindableState = state

        AuthFlowContainer {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                AuthFlowHeader(
                    systemImage: "envelope.fill",
                    title: isRegistration
                        ? "auth.email.register.title"
                        : "auth.email.login.title",
                    message: isRegistration
                        ? "auth.email.register.message"
                        : "auth.email.login.message"
                )

                AuthFormSurface {
                    TextField(
                        String(
                            localized: "auth.field.email",
                            defaultValue: "Email"
                        ),
                        text: $bindableState.email
                    )
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .accessibilityIdentifier(
                        isRegistration
                            ? "auth.register.email"
                            : "auth.login.email"
                    )

                    Divider()

                    PasswordInputRow(
                        text: $bindableState.password,
                        showsPassword: $bindableState.showsPassword,
                        contentType: isRegistration
                            ? .newPassword
                            : .password,
                        identifier: isRegistration
                            ? "auth.register.password"
                            : "auth.login.password"
                    )

                    if isRegistration {
                        Divider()
                        PasswordInputRow(
                            text: $bindableState.passwordConfirmation,
                            showsPassword: $bindableState.showsPassword,
                            contentType: .newPassword,
                            placeholder: String(
                                localized: "auth.field.password_confirmation",
                                defaultValue: "Konfirmasi password"
                            ),
                            identifier:
                                "auth.register.password-confirmation"
                        )
                    }
                }

                if isRegistration {
                    Label(
                        "auth.register.password_guidance",
                        systemImage: "lock.shield"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                } else {
                    Button("auth.forgot.action") {
                        state.openForgotPassword()
                    }
                    .frame(minHeight: AppControlMetrics.minimumTouchTarget)
                    .accessibilityIdentifier("auth.login.forgot")
                }

                if let errorMessage = state.errorMessage {
                    AuthErrorBanner(message: errorMessage)
                }

                Button {
                    Task {
                        if isRegistration {
                            await state.registerWithEmail()
                        } else {
                            await state.signInWithEmail()
                        }
                    }
                } label: {
                    SubmittingButtonLabel(
                        title: isRegistration
                            ? "auth.action.register"
                            : "auth.action.login",
                        isSubmitting: state.isSubmitting
                    )
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(
                    isRegistration
                        ? !state.canSubmitEmailRegistration
                        : !state.canSubmitEmailLogin
                )
                .accessibilityIdentifier(
                    isRegistration
                        ? "auth.register.submit"
                        : "auth.login.submit"
                )
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

@MainActor
private struct ForgotPasswordView: View {
    let state: AuthenticationFlowState

    var body: some View {
        @Bindable var bindableState = state

        AuthFlowContainer {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                AuthFlowHeader(
                    systemImage: "key.fill",
                    title: "auth.forgot.title",
                    message: "auth.forgot.message"
                )
                .accessibilityIdentifier("auth.forgot")

                AuthFormSurface {
                    TextField(
                        String(
                            localized: "auth.field.email",
                            defaultValue: "Email"
                        ),
                        text: $bindableState.email
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("auth.forgot.email")
                }

                if state.recoveryWasRequested {
                    Label(
                        "auth.recovery.generic_response",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSuccess)
                    .accessibilityIdentifier("auth.forgot.success")
                }

                if let errorMessage = state.errorMessage {
                    AuthErrorBanner(message: errorMessage)
                }

                Button {
                    Task { await state.requestPasswordReset() }
                } label: {
                    SubmittingButtonLabel(
                        title: "auth.forgot.submit",
                        isSubmitting: state.isSubmitting
                    )
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(state.isSubmitting)
                .accessibilityIdentifier("auth.forgot.submit")
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct AuthFlowContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: 520, alignment: .leading)
                .padding(.horizontal, AppSpacing.large)
                .padding(.vertical, AppSpacing.large)
                .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground)
    }
}

struct AuthFlowHeader: View {
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
                .frame(
                    width: AppControlMetrics.minimumTouchTarget,
                    height: AppControlMetrics.minimumTouchTarget
                )
                .background(
                    Color.brandPrimary.opacity(0.12),
                    in: Circle()
                )
                .accessibilityHidden(true)

            Text(title)
                .font(AppTypography.screenTitle)
                .foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)

            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(Color.appSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AuthFormSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            content
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
        .overlay {
            RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
            .stroke(Color.appBorder, lineWidth: 1)
        }
    }
}

struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appDestructive)
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.appDestructive.opacity(0.08),
                in: RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
            )
            .accessibilityIdentifier("auth.error")
    }
}

private struct AuthSwitchDestinationButton: View {
    let prompt: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let identifier: String
    let action: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.xxSmall) {
                promptText
                actionButton
            }
            .fixedSize(horizontal: true, vertical: false)

            VStack(spacing: AppSpacing.xxSmall) {
                promptText
                actionButton
            }
        }
        .font(AppTypography.secondary)
        .frame(
            maxWidth: .infinity,
            minHeight: AppControlMetrics.minimumTouchTarget
        )
    }

    private var promptText: some View {
        Text(prompt)
            .foregroundStyle(Color.appSecondaryText)
            .fixedSize(horizontal: true, vertical: false)
    }

    private var actionButton: some View {
        Button(actionTitle, action: action)
            .fontWeight(.semibold)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier(identifier)
    }
}

private struct PasswordInputRow: View {
    @Binding var text: String
    @Binding var showsPassword: Bool
    let contentType: UITextContentType
    var placeholder = String(
        localized: "auth.field.password",
        defaultValue: "Password"
    )
    let identifier: String

    var body: some View {
        HStack {
            Group {
                if showsPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(contentType)
            .accessibilityIdentifier(identifier)

            Button {
                showsPassword.toggle()
            } label: {
                Image(systemName: showsPassword ? "eye.slash" : "eye")
                    .frame(
                        width: AppControlMetrics.minimumTouchTarget,
                        height: AppControlMetrics.minimumTouchTarget
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text(
                    showsPassword
                        ? "auth.password.hide"
                        : "auth.password.show"
                )
            )
        }
    }
}

struct AuthenticationAppleButton: View {
    let maximumWidth: CGFloat
    let action: () -> Void

    init(
        maximumWidth: CGFloat = 360,
        action: @escaping () -> Void
    ) {
        self.maximumWidth = maximumWidth
        self.action = action
    }

    var body: some View {
        ZStack {
            SignInWithAppleButton(
                .continue,
                onRequest: { _ in },
                onCompletion: { _ in }
            )
            .signInWithAppleButtonStyle(.black)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            Button(action: action) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text(
                    String(
                        localized: "auth.provider.apple.continue",
                        defaultValue: "Lanjutkan dengan Apple"
                    )
                )
            )
        }
        .frame(
            maxWidth: maximumWidth,
            minHeight: 50,
            maxHeight: 50
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppRadius.medium,
                style: .continuous
            )
        )
    }
}

struct OfficialGoogleSignInButton: View {
    let title: String
    let maximumWidth: CGFloat
    let action: () -> Void

    init(
        title: String = String(
            localized: "auth.provider.google.continue",
            defaultValue: "Lanjutkan dengan Google"
        ),
        maximumWidth: CGFloat = 360,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.maximumWidth = maximumWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.small) {
                Image("GoogleGLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)
                Text(title)
                .font(.system(.body, design: .default).weight(.medium))
            }
            .foregroundStyle(Color.appPrimaryText)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                Color.appSurface,
                in: RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
                .stroke(Color.appBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: maximumWidth)
        .accessibilityLabel(Text(title))
    }
}

struct SubmittingButtonLabel: View {
    let title: LocalizedStringKey
    let isSubmitting: Bool

    var body: some View {
        if isSubmitting {
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity)
        } else {
            Text(title)
                .frame(maxWidth: .infinity)
        }
    }
}
