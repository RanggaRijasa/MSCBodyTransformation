import Foundation
import Observation

@MainActor
@Observable
final class AuthenticationFlowState {
    private let environment: AppEnvironment
    private let store: ParticipantJourneyStore
    private let scenario: AppDemoScenario

    var destination: AuthenticationDestination
    var email = ""
    var password = ""
    var passwordConfirmation = ""
    var showsPassword = false
    var displayName = ""
    var phoneNumber = ""
    var memberLevel = MemberLevel.member
    var accountPurpose = AccountPurpose.participant
    var hasCompletedHOMSTS = false
    var hasCompletedICT = false
    var selectedParticipantCoach: CoachProfile?
    var application: CoachApplication?
    var authenticationOutcome = FakeAuthenticationOutcome.success
    var recoveryOutcome = FakeRecoveryOutcome.success
    var purchaseOutcome = FakeCoachPurchaseOutcome.success
    var isSubmitting = false
    var errorMessage: String?
    var recoveryWasRequested = false

    private var registrationProvider: AuthenticationProvider?
    private var registrationEmail: String?
    private var registrationPassword: String?

    init(
        environment: AppEnvironment,
        store: ParticipantJourneyStore,
        presentation: AuthenticationPresentation,
        scenario: AppDemoScenario
    ) {
        self.environment = environment
        self.store = store
        self.scenario = scenario
        destination = presentation.destination
    }

    var eligibility: CoachEligibility {
        CoachEligibilityService().evaluate(
            memberLevel: memberLevel,
            hasCompletedHOMSTS: hasCompletedHOMSTS,
            hasCompletedICT: hasCompletedICT
        )
    }

    var paymentPreview: CoachPaymentPreview? {
        CoachPricingService().paymentPreview(for: memberLevel)
    }

    var canSubmitEmailLogin: Bool {
        isValidEmail(email) && !password.isEmpty && !isSubmitting
    }

    var canSubmitEmailRegistration: Bool {
        isValidEmail(email)
            && password.count >= 8
            && password == passwordConfirmation
            && !isSubmitting
    }

    var canCreateParticipantAccount: Bool {
        selectedParticipantCoach != nil && !isSubmitting
    }

    var isEmailPasswordAuthenticationVisible: Bool {
        environment.configuration.isEmailPasswordAuthenticationVisible
    }

    var isLocalDemo: Bool {
        environment.configuration.mode == .localDemo
    }

    func prepareDemoStateIfNeeded() async {
        if environment.configuration.mode != .localDemo,
           registrationProvider == nil,
           let session = try? await environment.repositories?.session
               .restoreSession(),
           session.onboardingStatus == .provisional
                || session.onboardingStatus == .coachHandoffPending {
            registrationProvider = .email
            if let name = session.user?.displayName,
               name != "Peserta baru" {
                displayName = name
            }
            destination = .profileOnboarding
            return
        }
        switch scenario {
        case .authProfileOnboarding:
            prepareRegistrationDraft(
                level: .member,
                purpose: .participant
            )
        case .coachApplicationEligible:
            prepareRegistrationDraft(
                level: .sc,
                purpose: .coachApplicant,
                hasCompletedHOMSTS: true,
                hasCompletedICT: true
            )
        case .coachApplicationIneligible:
            prepareRegistrationDraft(
                level: .member,
                purpose: .coachApplicant
            )
        case .coachPaymentSuccess:
            prepareRegistrationDraft(
                level: .tabTeam,
                purpose: .coachApplicant,
                hasCompletedHOMSTS: true,
                hasCompletedICT: true
            )
        case .coachPendingApproval:
            prepareRegistrationDraft(
                level: .millionaireTeam,
                purpose: .coachApplicant,
                hasCompletedHOMSTS: true,
                hasCompletedICT: true
            )
            await finalizePendingCoachDemo()
        default:
            break
        }
    }

    func openEmailLogin() {
        clearError()
        destination = .loginEmail
    }

    func openEmailRegistration() {
        clearError()
        destination = .registerEmail
    }

    func openLogin() {
        clearCredentials()
        clearError()
        destination = .login
    }

    func openRegister() {
        clearCredentials()
        clearError()
        destination = .register
    }

    func synchronizeDestinationAfterNavigation(
        _ destination: AuthenticationDestination
    ) {
        clearError()
        self.destination = destination
    }

    func openForgotPassword() {
        clearError()
        destination = .forgotPassword
    }

    func signInWithEmail() async {
        guard canSubmitEmailLogin else {
            errorMessage = String(
                localized: "auth.error.login_fields",
                defaultValue: "Periksa email dan password, lalu coba lagi."
            )
            return
        }
        await signIn(provider: .email, email: email)
    }

    func registerWithEmail() async {
        guard canSubmitEmailRegistration else {
            errorMessage = String(
                localized: "auth.error.register_fields",
                defaultValue:
                    "Gunakan email valid dan password minimal 8 karakter yang sama."
            )
            return
        }
        beginRegistration(
            provider: .email,
            email: email,
            password: password
        )
    }

    func authenticateWithProvider(
        _ provider: AuthenticationProvider,
        isRegistration: Bool
    ) async {
        guard !isSubmitting else { return }
        guard validateProviderOutcome() else { return }
        if isRegistration {
            if environment.configuration.mode == .localDemo {
                beginRegistration(
                    provider: provider,
                    email: nil,
                    password: nil
                )
                return
            }
            guard let repositories = environment.repositories else {
                errorMessage = genericErrorMessage
                return
            }
            isSubmitting = true
            defer { isSubmitting = false }
            do {
                _ = try await repositories.authentication.register(
                    provider: provider,
                    email: nil,
                    password: nil
                )
                registrationProvider = provider
                errorMessage = nil
            } catch {
                errorMessage = mappedMessage(for: error)
            }
        } else {
            await signIn(provider: provider, email: nil)
        }
    }

    func requestPasswordReset() async {
        guard isValidEmail(email) else {
            errorMessage = String(
                localized: "auth.error.email_invalid",
                defaultValue: "Masukkan alamat email yang valid."
            )
            return
        }
        guard let repositories = environment.repositories else {
            errorMessage = genericErrorMessage
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        switch recoveryOutcome {
        case .rateLimited:
            errorMessage = String(
                localized: "auth.recovery.rate_limited",
                defaultValue:
                    "Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi."
            )
            return
        case .offline:
            errorMessage = String(
                localized: "auth.error.offline",
                defaultValue:
                    "Tidak ada koneksi. Periksa jaringan lalu coba lagi."
            )
            return
        case .success:
            break
        }
        do {
            try await repositories.authentication
                .requestPasswordReset(email: email)
            errorMessage = nil
            recoveryWasRequested = true
        } catch {
            errorMessage = genericRecoveryMessage
        }
    }

    func completeProfile() {
        guard validateProfile() else { return }
        selectedParticipantCoach = nil
        errorMessage = nil
        switch accountPurpose {
        case .participant:
            destination = .participantCoachQR
        case .coachApplicant:
            guard memberLevel.isCoachLevelEligible else {
                errorMessage = String(
                    localized: "auth.error.member_ineligible",
                    defaultValue:
                        "Level Member belum memenuhi syarat untuk mengajukan Coach."
                )
                return
            }
            destination = .coachEligibility
        }
    }

    func selectScannedParticipantCoach(identifier: String) async {
        let opaqueValue = identifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let normalized = opaqueValue
            .uppercased()
        if let resolver = environment.repositories?.coachQREnrollment {
            do {
                selectedParticipantCoach = try await resolver.resolveCoach(
                    qrOpaqueValue: opaqueValue
                )
                errorMessage = nil
            } catch {
                selectedParticipantCoach = nil
                errorMessage = mappedMessage(for: error)
            }
            return
        }
        let coaches: [CoachProfile]
        if store.publicCoaches.isEmpty {
            do {
                guard let repositories = environment.repositories else {
                    throw AuthenticationError.providerUnavailable
                }
                coaches = try await repositories.coachDirectory.publicCoaches()
            } catch {
                selectedParticipantCoach = nil
                errorMessage = mappedMessage(for: error)
                return
            }
        } else {
            coaches = store.publicCoaches
        }
        guard let coach = coaches.first(where: {
            $0.enrollmentIdentifier.uppercased() == normalized
                && $0.isApproved
                && $0.isPublic
        }) else {
            selectedParticipantCoach = nil
            errorMessage = String(
                localized: "auth.participant_qr.invalid",
                defaultValue: "QR Coach tidak valid atau Coach belum aktif."
            )
            return
        }
        selectedParticipantCoach = coach
        errorMessage = nil
    }

    func createParticipantAccount() async {
        guard let coach = selectedParticipantCoach else {
            errorMessage = String(
                localized: "auth.participant_qr.required",
                defaultValue: "Pindai dan konfirmasi QR Coach terlebih dahulu."
            )
            return
        }
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        await finalizeRegistration(
            coachID: coach.id,
            coachPayment: nil
        )
        guard errorMessage == nil else { return }
        await finish()
    }

    func continueCoachApplication() async {
        guard eligibility.isComplete else {
            errorMessage = String(
                localized: "coach.eligibility.error.incomplete",
                defaultValue:
                    "Lengkapi HOM STS dan ICT sebelum melanjutkan."
            )
            return
        }
        errorMessage = nil
        if isLocalDemo {
            destination = .coachPayment
            return
        }

        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        await finalizeRegistration(coachID: nil, coachPayment: nil)
        guard errorMessage == nil,
              let repositories = environment.repositories else {
            return
        }
        do {
            let session = try await repositories.session.restoreSession()
            guard let user = session.user else {
                throw AuthenticationError.sessionExpired
            }
            let now = environment.clock.now()
            let draft = CoachApplication(
                id: environment.identifierGenerator.makeIdentifier(),
                userID: user.id,
                participantProfileID: user.id,
                displayNameSnapshot: displayName,
                phoneNumberSnapshot: phoneNumber,
                memberLevel: memberLevel,
                hasCompletedHOMSTS: hasCompletedHOMSTS,
                hasCompletedICT: hasCompletedICT,
                termsVersion: "coach-terms-v1",
                status: .submitted,
                payment: nil,
                createdAt: now,
                submittedAt: nil,
                updatedAt: now,
                decision: nil
            )
            let saved = try await repositories.coachApplications
                .saveCoachApplication(draft)
            application = try await repositories.coachApplications
                .submitCoachApplication(applicationID: saved.id)
            errorMessage = nil
            destination = .pendingCoachApproval
        } catch {
            errorMessage = mappedMessage(for: error)
        }
    }

    func performPurchase() async {
        guard let preview = paymentPreview else {
            errorMessage = genericErrorMessage
            return
        }
        if !isLocalDemo {
            errorMessage = String(
                localized: "coach.payment.after_approval_only",
                defaultValue:
                    "Pembayaran Coach tersedia setelah pengajuan diterima Admin."
            )
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let result = try await FakeCoachPurchaseService(
                clock: environment.clock
            ).purchase(preview: preview, outcome: purchaseOutcome)
            switch result.state {
            case .verified:
                let verifiedPayment = CoachPaymentPreview(
                    priceBand: preview.priceBand,
                    amountMinorUnits: preview.amountMinorUnits,
                    durationMonths: preview.durationMonths,
                    state: .verified,
                    verifiedAt: result.verifiedAt,
                    accessStartsAt: result.accessStartsAt,
                    accessEndsAt: result.accessEndsAt
                )
                await finalizeRegistration(
                    coachID: nil,
                    coachPayment: verifiedPayment
                )
                if errorMessage == nil {
                    destination = .pendingCoachApproval
                }
            case .pending:
                errorMessage = String(
                    localized: "coach.payment.pending.message",
                    defaultValue:
                        "Pembayaran demo masih tertunda. Coba periksa lagi nanti."
                )
            case .cancelled:
                errorMessage = String(
                    localized: "coach.payment.cancelled.message",
                    defaultValue: "Pembayaran demo dibatalkan."
                )
            case .failed:
                errorMessage = String(
                    localized: "coach.payment.failed.message",
                    defaultValue: "Pembayaran demo gagal. Coba lagi."
                )
            case .interrupted:
                errorMessage = String(
                    localized: "coach.payment.interrupted.message",
                    defaultValue:
                        "Pembayaran demo terhenti. Kamu dapat mencoba lagi."
                )
            case .notStarted, .processing:
                errorMessage = genericErrorMessage
            }
        } catch {
            errorMessage = mappedMessage(for: error)
        }
    }

    func finish() async {
        clearTransientRegistration()
        await store.completeAuthenticationFlow()
    }

    func cancel() async {
        if environment.configuration.mode != .localDemo,
           let repositories = environment.repositories,
           let session = try? await repositories.session.restoreSession(),
           session.onboardingStatus == .provisional
                || session.onboardingStatus == .coachHandoffPending {
            do {
                try await repositories.authentication
                    .cancelProvisionalRegistration()
            } catch {
                errorMessage = mappedMessage(for: error)
                return
            }
        }
        clearTransientRegistration()
        store.cancelAuthentication()
    }

    func selectMemberLevel(_ level: MemberLevel) {
        memberLevel = level
        if !level.isCoachLevelEligible {
            accountPurpose = .participant
            hasCompletedHOMSTS = false
            hasCompletedICT = false
        }
        errorMessage = nil
    }

    private func signIn(
        provider: AuthenticationProvider,
        email: String?
    ) async {
        guard let repositories = environment.repositories,
              !isSubmitting else {
            return
        }
        if provider != .email, !validateProviderOutcome() {
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            _ = try await repositories.authentication.signIn(
                provider: provider,
                email: email,
                password: provider == .email ? password : nil
            )
            clearCredentials()
            errorMessage = nil
            await finish()
        } catch {
            errorMessage = mappedMessage(for: error)
        }
    }

    private func beginRegistration(
        provider: AuthenticationProvider,
        email: String?,
        password: String?
    ) {
        registrationProvider = provider
        registrationEmail = email?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        registrationPassword = password
        clearCredentials()
        errorMessage = nil
        destination = .profileOnboarding
    }

    private func finalizeRegistration(
        coachID: UUID?,
        coachPayment: CoachPaymentPreview?
    ) async {
        guard let repositories = environment.repositories,
              let registrationProvider else {
            errorMessage = genericErrorMessage
            return
        }
        guard validateProfile() else { return }
        var completion = RegistrationCompletion(
            provider: registrationProvider,
            email: registrationEmail,
            displayName: displayName.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            phoneNumber: compactPhoneNumber,
            memberLevel: memberLevel,
            accountPurpose: accountPurpose,
            participantCoachID: coachID,
            hasCompletedHOMSTS: hasCompletedHOMSTS,
            hasCompletedICT: hasCompletedICT,
            coachPayment: coachPayment,
            termsVersion: "coach-terms-v1"
        )
        if let registrationEmail, let registrationPassword {
            completion.credential = try? EmailCredential(
                email: registrationEmail,
                password: registrationPassword
            )
        }
        completion.participantCoachQROpaqueValue =
            selectedParticipantCoach?.enrollmentIdentifier
        do {
            let result = try await repositories.authentication
                .finalizeRegistration(completion)
            application = result.coachApplication
            await store.load()
            errorMessage = nil
        } catch {
            errorMessage = mappedMessage(for: error)
        }
    }

    private func validateProviderOutcome() -> Bool {
        switch authenticationOutcome {
        case .success:
            return true
        case .cancelled:
            errorMessage = String(
                localized: "auth.provider.cancelled",
                defaultValue: "Proses masuk dibatalkan."
            )
        case .offline:
            errorMessage = String(
                localized: "auth.error.offline",
                defaultValue:
                    "Tidak ada koneksi. Periksa jaringan lalu coba lagi."
            )
        case .providerError:
            errorMessage = String(
                localized: "auth.provider.error",
                defaultValue:
                    "Penyedia akun belum dapat digunakan. Coba lagi."
            )
        case .unknown:
            errorMessage = genericErrorMessage
        }
        return false
    }

    private func validateProfile() -> Bool {
        let trimmedName = displayName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard (2...80).contains(trimmedName.count) else {
            errorMessage = String(
                localized: "auth.error.name_invalid",
                defaultValue: "Masukkan nama antara 2 sampai 80 karakter."
            )
            return false
        }
        let phoneDigits = compactPhoneNumber.filter(\.isNumber)
        guard compactPhoneNumber.allSatisfy({
            $0.isNumber || $0 == "+"
        }), (8...15).contains(phoneDigits.count) else {
            errorMessage = String(
                localized: "auth.error.phone_invalid",
                defaultValue: "Masukkan nomor HP yang valid."
            )
            return false
        }
        return true
    }

    private var compactPhoneNumber: String {
        phoneNumber.filter { !$0.isWhitespace && $0 != "-" }
    }

    private func prepareRegistrationDraft(
        level: MemberLevel,
        purpose: AccountPurpose,
        hasCompletedHOMSTS: Bool = false,
        hasCompletedICT: Bool = false
    ) {
        registrationProvider = .email
        registrationEmail = "akun-baru@demo.local"
        displayName = "Nadia Pratama"
        phoneNumber = "+6281200000901"
        memberLevel = level
        accountPurpose = purpose
        self.hasCompletedHOMSTS = hasCompletedHOMSTS
        self.hasCompletedICT = hasCompletedICT
    }

    private func finalizePendingCoachDemo() async {
        guard let preview = paymentPreview else { return }
        do {
            let result = try await FakeCoachPurchaseService(
                clock: environment.clock
            ).purchase(preview: preview, outcome: .success)
            let verifiedPayment = CoachPaymentPreview(
                priceBand: preview.priceBand,
                amountMinorUnits: preview.amountMinorUnits,
                durationMonths: preview.durationMonths,
                state: .verified,
                verifiedAt: result.verifiedAt,
                accessStartsAt: result.accessStartsAt,
                accessEndsAt: result.accessEndsAt
            )
            await finalizeRegistration(
                coachID: nil,
                coachPayment: verifiedPayment
            )
        } catch {
            errorMessage = mappedMessage(for: error)
        }
    }

    private func clearError() {
        errorMessage = nil
    }

    private func clearCredentials() {
        password = ""
        passwordConfirmation = ""
        showsPassword = false
    }

    private func clearTransientRegistration() {
        clearCredentials()
        registrationProvider = nil
        registrationEmail = nil
        registrationPassword = nil
        displayName = ""
        phoneNumber = ""
        selectedParticipantCoach = nil
        application = nil
    }

    private func isValidEmail(_ value: String) -> Bool {
        let parts = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "@")
        return parts.count == 2
            && parts.allSatisfy { !$0.isEmpty }
            && parts[1].contains(".")
    }

    private func mappedMessage(for error: Error) -> String {
        if let error = error as? AuthenticationError {
            switch error {
            case .validation, .weakPassword:
                return String(
                    localized: "auth.error.validation",
                    defaultValue: "Periksa data yang dimasukkan, lalu coba lagi."
                )
            case .invalidCredential:
                return String(
                    localized: "auth.error.invalid_credential",
                    defaultValue: "Email atau password tidak sesuai."
                )
            case .verificationRequired:
                return String(
                    localized: "auth.error.verification_required",
                    defaultValue: "Verifikasi email sebelum masuk."
                )
            case .cancelled:
                return String(
                    localized: "auth.provider.cancelled",
                    defaultValue: "Proses masuk dibatalkan."
                )
            case .rateLimited:
                return String(
                    localized: "auth.recovery.rate_limited",
                    defaultValue: "Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi."
                )
            case .offline:
                return String(
                    localized: "auth.error.offline",
                    defaultValue: "Tidak ada koneksi. Periksa jaringan lalu coba lagi."
                )
            case .timeout:
                return String(
                    localized: "auth.error.timeout",
                    defaultValue: "Koneksi terlalu lama. Coba lagi."
                )
            case .profileProvisioning, .roleLoad:
                return String(
                    localized: "auth.error.profile",
                    defaultValue: "Profil belum dapat dimuat. Coba lagi."
                )
            case .providerUnavailable:
                return String(
                    localized: "auth.provider.error",
                    defaultValue: "Penyedia akun belum dapat digunakan. Coba lagi."
                )
            default:
                return genericErrorMessage
            }
        }
        if let domainError = error as? DomainError {
            switch domainError {
            case .validation(_, let reason):
                return reason
            case .offline:
                return String(
                    localized: "auth.error.offline",
                    defaultValue:
                        "Tidak ada koneksi. Periksa jaringan lalu coba lagi."
                )
            case .permissionDenied:
                return String(
                    localized: "auth.error.permission",
                    defaultValue:
                        "Akun ini tidak memiliki akses untuk tindakan tersebut."
                )
            default:
                return genericErrorMessage
            }
        }
        return genericErrorMessage
    }

    private var genericErrorMessage: String {
        String(
            localized: "auth.error.generic",
            defaultValue: "Terjadi kendala. Coba lagi."
        )
    }

    private var genericRecoveryMessage: String {
        String(
            localized: "auth.recovery.generic_response",
            defaultValue:
                "Jika email terdaftar, petunjuk pemulihan akan dikirim."
        )
    }
}
