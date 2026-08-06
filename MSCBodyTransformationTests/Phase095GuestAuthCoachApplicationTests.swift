import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Phase 09.5 — Guest, Auth, dan pengajuan Coach")
struct Phase095GuestAuthCoachApplicationTests {
    @Test("Sembilan level memakai raw value stabil dan harga yang benar")
    func memberLevelAndPricingContract() {
        #expect(MemberLevel.allCases.count == 9)
        #expect(MemberLevel.worldTeam.rawValue == "world_team")
        #expect(MemberLevel.tabTeam.rawValue == "tab_team")
        #expect(MemberLevel.getTeam.rawValue == "get_team")
        #expect(
            MemberLevel.presidentsTeam.rawValue == "presidents_team"
        )

        let pricing = CoachPricingService()
        #expect(pricing.priceBand(for: .member) == nil)
        #expect(
            pricing.paymentPreview(for: .sc)?.amountMinorUnits
                == 100_000
        )
        #expect(
            pricing.paymentPreview(for: .sb)?.amountMinorUnits
                == 100_000
        )
        #expect(
            pricing.paymentPreview(for: .supervisor)?.amountMinorUnits
                == 150_000
        )
        #expect(
            pricing.paymentPreview(for: .worldTeam)?.amountMinorUnits
                == 150_000
        )
        for level in [
            MemberLevel.tabTeam,
            .getTeam,
            .millionaireTeam,
            .presidentsTeam
        ] {
            #expect(
                pricing.paymentPreview(for: level)?.amountMinorUnits
                    == 200_000
            )
        }
    }

    @Test("Eligibility memerlukan level SC, HOM STS, dan ICT")
    func coachEligibilityRequiresAllRules() {
        let service = CoachEligibilityService()
        #expect(
            !service.evaluate(
                memberLevel: .member,
                hasCompletedHOMSTS: true,
                hasCompletedICT: true
            ).isComplete
        )
        #expect(
            !service.evaluate(
                memberLevel: .sc,
                hasCompletedHOMSTS: false,
                hasCompletedICT: true
            ).isComplete
        )
        #expect(
            !service.evaluate(
                memberLevel: .sc,
                hasCompletedHOMSTS: true,
                hasCompletedICT: false
            ).isComplete
        )
        #expect(
            service.evaluate(
                memberLevel: .sc,
                hasCompletedHOMSTS: true,
                hasCompletedICT: true
            ).isComplete
        )
    }

    @MainActor
    @Test("Guest memuat data publik tanpa AppUser atau profil")
    func guestLoadsOnlyPublicBrowsingSnapshot() async throws {
        let seed = try MockSeedData.load()
        let repository = InMemoryAppRepository(
            seed: seed,
            sessionScenario: .loggedOut
        )
        let environment = AppEnvironment(
            configuration: .localDemo,
            clock: FixedClock(
                now: Date(timeIntervalSince1970: 1_785_456_000)
            ),
            identifierGenerator: DeterministicIdentifierGenerator(
                identifier: UUID(
                    uuidString:
                        "90000000-0000-0000-0000-000000000001"
                )!
            ),
            repositories: AppRepositories(repository: repository),
            bootstrapError: nil
        )
        let store = ParticipantJourneyStore(
            environment: environment,
            allowsGuestAccess: true
        )

        await store.load()

        #expect(store.isGuest)
        #expect(store.snapshot == nil)
        #expect(store.guestSnapshot != nil)
        #expect(!store.programs.isEmpty)
        #expect(
            store.publicCoaches.allSatisfy {
                $0.isApproved && $0.isPublic
            }
        )
        #expect(AppTab.tabs(for: .participant).count == 5)
    }

#if DEBUG
    @Test("Guest menjadi default dan skenario invalid kembali ke Guest Home")
    func guestLaunchConfigurationIsSafe() {
        let defaultLaunch = DebugLaunchConfiguration(arguments: [])
        #expect(defaultLaunch.role == .guest)
        #expect(defaultLaunch.scenario == .guestHome)

        let invalid = DebugLaunchConfiguration(
            arguments: [
                "MSCBodyTransformation",
                "-DemoRole", "participant",
                "-DemoScenario", "tidak_valid"
            ]
        )
        #expect(invalid.role == .guest)
        #expect(invalid.scenario == .guestHome)
        #expect(DemoRole.guest.userRole == nil)
        #expect(DemoRole.guest.shellRole == .participant)
    }
#endif

    @Test("Registrasi fake selalu membuat Participant yang perlu onboarding")
    func fakeRegistrationDefaultsToParticipant() async throws {
        let repository = try makeRepository()
        let session = try await repository.register(
            provider: .google,
            email: nil,
            password: nil
        )

        #expect(session.role == .participant)
        #expect(session.requiresOnboarding)

        let completed = try await repository
            .completeParticipantOnboarding(
                userID: try #require(session.user?.id),
                displayName: "Nadia Pratama",
                phoneNumber: "+6281200000901",
                memberLevel: .tabTeam
            )
        let profile = try await repository.participantProfile(
            userID: try #require(completed.user?.id)
        )

        #expect(completed.role == .participant)
        #expect(!completed.requiresOnboarding)
        #expect(profile.memberLevel == .tabTeam)
        #expect(profile.phoneNumber == "+6281200000901")
    }

    @Test("Payment verified tidak mengubah role sebelum Admin menyetujui")
    func paymentDoesNotSelfPromoteApplicant() async throws {
        let repository = try makeRepository()
        let application = try #require(
            try await repository.coachApplicationsForAdministration()
                .first {
                    $0.status == .pendingAdminApproval
                }
        )
        let userBefore = try await repository.user(id: application.userID)
        #expect(userBefore.role == .participant)

        let adminID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000201"
        )!
        let approved = try await repository.approveCoachApplication(
            applicationID: application.id,
            adminUserID: adminID,
            decidedAt: Date(timeIntervalSince1970: 1_785_456_100)
        )
        let duplicate = try await repository.approveCoachApplication(
            applicationID: application.id,
            adminUserID: adminID,
            decidedAt: Date(timeIntervalSince1970: 1_785_456_200)
        )
        let userAfter = try await repository.user(id: application.userID)
        let coach = try await repository.coachProfile(
            userID: application.userID
        )

        #expect(approved.status == .approved)
        #expect(duplicate == approved)
        #expect(userAfter.role == .coach)
        #expect(coach.isApproved)
        #expect(!coach.isPublic)
    }

    @Test("Admin tidak dapat menyetujui application tanpa pembayaran")
    func approvalRequiresVerifiedPayment() async throws {
        let repository = try makeRepository()
        let registration = try await repository.register(
            provider: .email,
            email: "baru@demo.local",
            password: nil
        )
        let userID = try #require(registration.user?.id)
        _ = try await repository.completeParticipantOnboarding(
            userID: userID,
            displayName: "Nadia Pratama",
            phoneNumber: "+6281200000901",
            memberLevel: .sc
        )
        let profile = try await repository.participantProfile(
            userID: userID
        )
        let application = CoachApplication(
            id: UUID(
                uuidString:
                    "90000000-0000-0000-0000-000000000002"
            )!,
            userID: userID,
            participantProfileID: profile.id,
            displayNameSnapshot: profile.displayName,
            phoneNumberSnapshot: profile.phoneNumber ?? "",
            memberLevel: .sc,
            hasCompletedHOMSTS: true,
            hasCompletedICT: true,
            termsVersion: "coach-terms-v1",
            status: .readyForPayment,
            payment: CoachPricingService().paymentPreview(for: .sc),
            createdAt: Date(timeIntervalSince1970: 1_785_456_000),
            submittedAt: nil,
            updatedAt: Date(timeIntervalSince1970: 1_785_456_000),
            decision: nil
        )
        _ = try await repository.saveCoachApplication(application)

        do {
            _ = try await repository.approveCoachApplication(
                applicationID: application.id,
                adminUserID: UUID(
                    uuidString:
                        "00000000-0000-0000-0000-000000000201"
                )!,
                decidedAt: Date(timeIntervalSince1970: 1_785_456_100)
            )
            Issue.record(
                "Application tanpa pembayaran seharusnya ditolak."
            )
        } catch let error as DomainError {
            guard case .validation(let field, _) = error else {
                Issue.record("Error seharusnya berupa validasi.")
                return
            }
            #expect(field == "coachPayment")
        }
        #expect(try await repository.user(id: userID).role == .participant)
    }

    @Test("Admin tidak dapat menyetujui application tanpa eligibility lengkap")
    func approvalRequiresCompleteEligibility() async throws {
        let repository = try makeRepository()
        var application = try #require(
            try await repository.coachApplicationsForAdministration().first
        )
        application.hasCompletedHOMSTS = false
        application.status = .pendingAdminApproval
        _ = try await repository.saveCoachApplication(application)

        await #expect(throws: DomainError.self) {
            try await repository.approveCoachApplication(
                applicationID: application.id,
                adminUserID: UUID(
                    uuidString:
                        "00000000-0000-0000-0000-000000000201"
                )!,
                decidedAt: Date(timeIntervalSince1970: 1_785_456_100)
            )
        }
        #expect(
            try await repository.user(id: application.userID).role
                == .participant
        )
    }

    @Test("Satu user hanya mendapat satu active Coach application")
    func duplicateActiveApplicationReturnsExistingRecord() async throws {
        let repository = try makeRepository()
        let registration = try await repository.register(
            provider: .email,
            email: "baru@demo.local",
            password: nil
        )
        let userID = try #require(registration.user?.id)
        _ = try await repository.completeParticipantOnboarding(
            userID: userID,
            displayName: "Nadia Pratama",
            phoneNumber: "+6281200000901",
            memberLevel: .sc
        )
        let profile = try await repository.participantProfile(userID: userID)
        let date = Date(timeIntervalSince1970: 1_785_456_000)
        let first = CoachApplication(
            id: UUID(
                uuidString:
                    "90000000-0000-0000-0000-000000000010"
            )!,
            userID: userID,
            participantProfileID: profile.id,
            displayNameSnapshot: profile.displayName,
            phoneNumberSnapshot: profile.phoneNumber ?? "",
            memberLevel: .sc,
            hasCompletedHOMSTS: true,
            hasCompletedICT: true,
            termsVersion: "coach-terms-v1",
            status: .draft,
            payment: CoachPricingService().paymentPreview(for: .sc),
            createdAt: date,
            submittedAt: nil,
            updatedAt: date,
            decision: nil
        )
        let duplicate = CoachApplication(
            id: UUID(
                uuidString:
                    "90000000-0000-0000-0000-000000000011"
            )!,
            userID: first.userID,
            participantProfileID: first.participantProfileID,
            displayNameSnapshot: first.displayNameSnapshot,
            phoneNumberSnapshot: first.phoneNumberSnapshot,
            memberLevel: first.memberLevel,
            hasCompletedHOMSTS: first.hasCompletedHOMSTS,
            hasCompletedICT: first.hasCompletedICT,
            termsVersion: first.termsVersion,
            status: first.status,
            payment: first.payment,
            createdAt: first.createdAt,
            submittedAt: first.submittedAt,
            updatedAt: first.updatedAt,
            decision: first.decision
        )

        let saved = try await repository.saveCoachApplication(first)
        let returned = try await repository.saveCoachApplication(duplicate)

        #expect(saved.id == first.id)
        #expect(returned.id == first.id)
    }

    @Test("Penolakan membutuhkan alasan dan bersifat idempoten")
    func rejectionRequiresReasonAndIsIdempotent() async throws {
        let repository = try makeRepository()
        let application = try #require(
            try await repository.coachApplicationsForAdministration()
                .first {
                    $0.status == .pendingAdminApproval
                }
        )
        let adminID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000201"
        )!

        await #expect(throws: DomainError.self) {
            try await repository.rejectCoachApplication(
                applicationID: application.id,
                adminUserID: adminID,
                reason: " ",
                decidedAt: Date(timeIntervalSince1970: 1_785_456_100)
            )
        }

        let rejected = try await repository.rejectCoachApplication(
            applicationID: application.id,
            adminUserID: adminID,
            reason: "Dokumen perlu diperbarui.",
            decidedAt: Date(timeIntervalSince1970: 1_785_456_100)
        )
        let duplicate = try await repository.rejectCoachApplication(
            applicationID: application.id,
            adminUserID: adminID,
            reason: "Dokumen perlu diperbarui.",
            decidedAt: Date(timeIntervalSince1970: 1_785_456_200)
        )

        #expect(rejected.status == .rejected)
        #expect(duplicate == rejected)
        #expect(
            try await repository.user(id: application.userID).role
                == .participant
        )
    }

    @Test("Periode akses tiga bulan memakai clock authoritative")
    func threeMonthAccessPeriodUsesInjectedDate() async throws {
        let start = Date(timeIntervalSince1970: 1_785_456_000)
        let preview = CoachPaymentPreview(
            priceBand: .entry,
            amountMinorUnits: 100_000
        )
        let result = try await FakeCoachPurchaseService(
            clock: FixedClock(now: start)
        ).purchase(preview: preview, outcome: .success)
        let end = try #require(result.accessEndsAt)

        #expect(result.state == .verified)
        #expect(result.accessStartsAt == start)
        #expect(
            CoachAccessPeriodCalculator().isExpired(
                CoachPaymentPreview(
                    priceBand: .entry,
                    amountMinorUnits: 100_000,
                    state: .verified,
                    verifiedAt: start,
                    accessStartsAt: start,
                    accessEndsAt: end
                ),
                at: end
            )
        )
    }

    @MainActor
    @Test("Provider fake memetakan cancel error dan success tanpa token")
    func providerOutcomesAreSafeAndRegistrationUsesCommonOnboarding()
        async throws
    {
        let (environment, store) = try await makeGuestEnvironment()
        let state = AuthenticationFlowState(
            environment: environment,
            store: store,
            presentation: AuthenticationPresentation(
                destination: .login,
                reason: nil
            ),
            scenario: .authLogin
        )

        state.authenticationOutcome = .cancelled
        await state.authenticateWithProvider(
            .apple,
            isRegistration: true
        )
        #expect(state.errorMessage == "Proses masuk dibatalkan.")
        #expect(store.isGuest)

        state.authenticationOutcome = .providerError
        await state.authenticateWithProvider(
            .google,
            isRegistration: true
        )
        #expect(state.errorMessage?.contains("Penyedia akun") == true)
        #expect(store.isGuest)

        state.authenticationOutcome = .success
        await state.authenticateWithProvider(
            .google,
            isRegistration: true
        )
        #expect(state.destination == .profileOnboarding)
        #expect(store.isGuest)
        #expect(store.snapshot == nil)
    }

    @MainActor
    @Test("Email validation dan recovery tidak menyimpan credential")
    func emailValidationAndRecoveryAreSafe() async throws {
        let (environment, store) = try await makeGuestEnvironment()
        let state = AuthenticationFlowState(
            environment: environment,
            store: store,
            presentation: AuthenticationPresentation(
                destination: .register,
                reason: nil
            ),
            scenario: .authRegister
        )

        state.email = "bukan-email"
        let testCredential = String(repeating: "x", count: 12)
        state.password = testCredential
        state.passwordConfirmation = testCredential
        await state.registerWithEmail()
        #expect(state.errorMessage != nil)
        #expect(store.isGuest)

        state.email = "akun-baru@demo.local"
        state.errorMessage = nil
        await state.registerWithEmail()
        #expect(state.destination == .profileOnboarding)
        #expect(state.password.isEmpty)
        #expect(state.passwordConfirmation.isEmpty)
        #expect(store.isGuest)
        #expect(store.snapshot == nil)

        let recovery = AuthenticationFlowState(
            environment: environment,
            store: store,
            presentation: AuthenticationPresentation(
                destination: .forgotPassword,
                reason: nil
            ),
            scenario: .authForgotPassword
        )
        recovery.email = "siapa-pun@demo.local"
        recovery.recoveryOutcome = .success
        await recovery.requestPasswordReset()
        #expect(recovery.recoveryWasRequested)
        #expect(recovery.errorMessage == nil)

        recovery.recoveryOutcome = .rateLimited
        await recovery.requestPasswordReset()
        #expect(recovery.errorMessage?.contains("Terlalu banyak") == true)
    }

    @Test("Registrasi Peserta atomik dan wajib QR Coach aktif")
    func participantRegistrationIsAtomicAndRequiresCoachQR() async throws {
        let repository = try makeRepository()
        let countBefore = try await repository
            .usersForAdministration().count
        let completion = RegistrationCompletion(
            provider: .google,
            email: nil,
            displayName: "Nadia Pratama",
            phoneNumber: "+6281200000901",
            memberLevel: .member,
            accountPurpose: .participant,
            participantCoachID: nil,
            hasCompletedHOMSTS: false,
            hasCompletedICT: false,
            coachPayment: nil,
            termsVersion: "coach-terms-v1"
        )

        await #expect(throws: DomainError.self) {
            try await repository.finalizeRegistration(completion)
        }
        #expect(
            try await repository.usersForAdministration().count
                == countBefore
        )

        let coachID = try #require(
            try await repository.publicCoaches().first?.id
        )
        let completed = try await repository.finalizeRegistration(
            RegistrationCompletion(
                provider: completion.provider,
                email: completion.email,
                displayName: completion.displayName,
                phoneNumber: completion.phoneNumber,
                memberLevel: completion.memberLevel,
                accountPurpose: completion.accountPurpose,
                participantCoachID: coachID,
                hasCompletedHOMSTS: false,
                hasCompletedICT: false,
                coachPayment: nil,
                termsVersion: completion.termsVersion
            )
        )
        let userID = try #require(completed.session.user?.id)
        let profile = try await repository.participantProfile(
            userID: userID
        )

        #expect(completed.session.role == .participant)
        #expect(!completed.session.requiresOnboarding)
        #expect(profile.coachID == coachID)
        #expect(
            try await repository.usersForAdministration().count
                == countBefore + 1
        )
    }

    @Test("Registrasi Coach tidak tersimpan sebelum pembayaran verified")
    func coachRegistrationRequiresVerifiedPaymentBeforeCommit()
        async throws
    {
        let repository = try makeRepository()
        let countBefore = try await repository
            .usersForAdministration().count
        let preview = try #require(
            CoachPricingService().paymentPreview(for: .sc)
        )
        let completion = RegistrationCompletion(
            provider: .apple,
            email: nil,
            displayName: "Nadia Pratama",
            phoneNumber: "+6281200000901",
            memberLevel: .sc,
            accountPurpose: .coachApplicant,
            participantCoachID: nil,
            hasCompletedHOMSTS: true,
            hasCompletedICT: true,
            coachPayment: preview,
            termsVersion: "coach-terms-v1"
        )

        await #expect(throws: DomainError.self) {
            try await repository.finalizeRegistration(completion)
        }
        #expect(
            try await repository.usersForAdministration().count
                == countBefore
        )

        let paid = try await FakeCoachPurchaseService(
            clock: FixedClock(
                now: Date(timeIntervalSince1970: 1_785_456_000)
            )
        ).purchase(preview: preview, outcome: .success)
        let result = try await repository.finalizeRegistration(
            RegistrationCompletion(
                provider: completion.provider,
                email: completion.email,
                displayName: completion.displayName,
                phoneNumber: completion.phoneNumber,
                memberLevel: completion.memberLevel,
                accountPurpose: completion.accountPurpose,
                participantCoachID: nil,
                hasCompletedHOMSTS: true,
                hasCompletedICT: true,
                coachPayment: CoachPaymentPreview(
                    priceBand: preview.priceBand,
                    amountMinorUnits: preview.amountMinorUnits,
                    state: .verified,
                    verifiedAt: paid.verifiedAt,
                    accessStartsAt: paid.accessStartsAt,
                    accessEndsAt: paid.accessEndsAt
                ),
                termsVersion: completion.termsVersion
            )
        )

        #expect(result.session.role == .participant)
        #expect(
            result.coachApplication?.status == .pendingAdminApproval
        )
        #expect(
            try await repository.usersForAdministration().count
                == countBefore + 1
        )
    }

    @MainActor
    @Test("Membatalkan draft registrasi mengembalikan Guest tanpa data baru")
    func cancellingRegistrationDraftDoesNotPersistAccount() async throws {
        let repository = InMemoryAppRepository(
            seed: try MockSeedData.load(),
            sessionScenario: .loggedOut
        )
        let countBefore = try await repository
            .usersForAdministration().count
        let environment = AppEnvironment(
            configuration: .localDemo,
            clock: FixedClock(
                now: Date(timeIntervalSince1970: 1_785_456_000)
            ),
            identifierGenerator: DeterministicIdentifierGenerator(
                identifier: UUID(
                    uuidString:
                        "90000000-0000-0000-0000-000000000099"
                )!
            ),
            repositories: AppRepositories(repository: repository),
            bootstrapError: nil
        )
        let store = ParticipantJourneyStore(
            environment: environment,
            allowsGuestAccess: true
        )
        await store.load()
        let state = AuthenticationFlowState(
            environment: environment,
            store: store,
            presentation: AuthenticationPresentation(
                destination: .register
            ),
            scenario: .authRegister
        )
        state.email = "draft@demo.local"
        state.password = "password-demo"
        state.passwordConfirmation = "password-demo"

        await state.registerWithEmail()
        state.displayName = "Draft User"
        state.phoneNumber = "+6281200000999"
        state.completeProfile()
        #expect(state.destination == .participantCoachQR)
        await state.cancel()

        #expect(store.isGuest)
        #expect(
            try await repository.usersForAdministration().count
                == countBefore
        )
        #expect(
            try await repository.loadCurrentSession().state == .loggedOut
        )
    }

    private func makeRepository() throws -> InMemoryAppRepository {
        InMemoryAppRepository(seed: try MockSeedData.load())
    }

    @MainActor
    private func makeGuestEnvironment() async throws
        -> (AppEnvironment, ParticipantJourneyStore)
    {
        let repository = InMemoryAppRepository(
            seed: try MockSeedData.load(),
            sessionScenario: .loggedOut
        )
        let environment = AppEnvironment(
            configuration: .localDemo,
            clock: FixedClock(
                now: Date(timeIntervalSince1970: 1_785_456_000)
            ),
            identifierGenerator: DeterministicIdentifierGenerator(
                identifier: UUID(
                    uuidString:
                        "90000000-0000-0000-0000-000000000099"
                )!
            ),
            repositories: AppRepositories(repository: repository),
            bootstrapError: nil
        )
        let store = ParticipantJourneyStore(
            environment: environment,
            allowsGuestAccess: true
        )
        await store.load()
        return (environment, store)
    }
}
