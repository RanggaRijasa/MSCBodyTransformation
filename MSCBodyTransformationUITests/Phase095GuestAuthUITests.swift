import XCTest

final class Phase095GuestAuthUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testGuestHomeShowsOAuthOnlyLoginAndRegister() {
        let app = launchGuest(scenario: "guest_home")

        XCTAssertTrue(
            element("participant.guest.home", in: app)
                .waitForExistence(timeout: 8)
        )
        let login = element("guest.home.login", in: app)
        XCTAssertTrue(login.waitForExistence(timeout: 5))
        XCTAssertFalse(element("guest.home.register", in: app).exists)
        XCTAssertFalse(element("participant.home.profile", in: app).exists)

        login.tap()
        XCTAssertTrue(
            element("auth.login", in: app).waitForExistence(timeout: 5)
        )
        XCTAssertTrue(element("auth.login.apple", in: app).exists)
        XCTAssertTrue(element("auth.login.google", in: app).exists)
        XCTAssertFalse(element("auth.login.email-option", in: app).exists)
        XCTAssertFalse(element("auth.login.email", in: app).exists)
        XCTAssertEqual(app.keyboards.count, 0)

        let openRegister = element("auth.login.open-register", in: app)
        for _ in 0..<3 where !openRegister.exists || !openRegister.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(openRegister.waitForExistence(timeout: 5))
        openRegister.tap()
        XCTAssertTrue(
            element("auth.register", in: app).waitForExistence(timeout: 5)
        )
        XCTAssertTrue(element("auth.register.apple", in: app).exists)
        XCTAssertTrue(element("auth.register.google", in: app).exists)
        XCTAssertFalse(element("auth.register.email-option", in: app).exists)
        XCTAssertFalse(element("auth.register.email", in: app).exists)

        let openLogin = element("auth.register.open-login", in: app)
        for _ in 0..<3 where !openLogin.exists || !openLogin.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(openLogin.waitForExistence(timeout: 5))
        openLogin.tap()
        XCTAssertTrue(
            element("auth.login", in: app).waitForExistence(timeout: 5)
        )
        XCTAssertFalse(element("auth.login.email-option", in: app).exists)
        XCTAssertEqual(app.keyboards.count, 0)
    }

    @MainActor
    func testGuestJoinProgramRequiresLoginBeforeEnrollment() {
        let app = launchGuest(scenario: "guest_program_catalog")

        XCTAssertTrue(
            element("participant.program.catalog", in: app)
                .waitForExistence(timeout: 8)
        )

        let program = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "participant.program.select."
            )
        ).firstMatch
        XCTAssertTrue(program.waitForExistence(timeout: 5))
        program.tap()

        let join = app.buttons["participant.program.offer.join"]
        XCTAssertTrue(join.waitForExistence(timeout: 5))
        join.tap()

        XCTAssertTrue(
            element("auth.login", in: app).waitForExistence(timeout: 5)
        )
        XCTAssertFalse(element("participant.join.flow", in: app).exists)
    }

    @MainActor
    func testAuthLeadingEdgeSwipeUsesNativeNavigationHistory() {
        var app = launchGuest(scenario: "auth_login")

        XCTAssertTrue(
            element("auth.login", in: app).waitForExistence(timeout: 8)
        )

        let openRegister = element(
            "auth.login.open-register",
            in: app
        )
        for _ in 0..<3 where !openRegister.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(openRegister.waitForExistence(timeout: 5))
        openRegister.tap()
        XCTAssertTrue(
            element("auth.register", in: app)
                .waitForExistence(timeout: 5)
        )

        performLeadingEdgeBackSwipe(in: app)
        XCTAssertTrue(
            element("auth.login", in: app).waitForExistence(timeout: 5)
        )

        performLeadingEdgeBackSwipe(in: app)
        XCTAssertFalse(
            element("auth.login", in: app).waitForExistence(timeout: 2)
        )

        app.terminate()
        app = launchGuest(scenario: "guest_home")
        XCTAssertTrue(
            element("participant.guest.home", in: app)
                .waitForExistence(timeout: 8)
        )
        element("guest.home.login", in: app).tap()
        XCTAssertTrue(
            element("auth.login", in: app).waitForExistence(timeout: 5)
        )

        element("auth.login.open-register", in: app).tap()
        let appleRegistration = element("auth.register.apple", in: app)
        XCTAssertTrue(appleRegistration.waitForExistence(timeout: 5))
        appleRegistration.tap()
        XCTAssertTrue(
            element("auth.profile", in: app)
                .waitForExistence(timeout: 5)
        )

        performLeadingEdgeBackSwipe(in: app)
        XCTAssertTrue(
            element("auth.register", in: app)
                .waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testGuestCanBrowseEveryParticipantTabWithoutPersonalProfile() {
        let app = launchGuest(scenario: "guest_home")

        let destinations: [(String, String)] = [
            ("Program", "participant.program.catalog"),
            ("Peringkat", "participant.leaderboard"),
            ("Coach", "participant.coaches"),
            ("Profil", "participant.guest.profile"),
            ("Beranda", "participant.guest.home")
        ]

        for (tabLabel, destinationIdentifier) in destinations {
            let tab = app.tabBars.buttons[tabLabel]
            XCTAssertTrue(tab.waitForExistence(timeout: 8))
            tab.tap()
            XCTAssertTrue(
                element(destinationIdentifier, in: app)
                    .waitForExistence(timeout: 8)
            )
        }

        XCTAssertFalse(element("participant.home.profile", in: app).exists)
        XCTAssertFalse(element("participant.profile.edit", in: app).exists)
    }

    @MainActor
    func testLargestDynamicTypeKeepsGuestAndAuthActionsReachable() {
        let app = launchGuest(
            scenario: "guest_home",
            extraArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
            ]
        )

        let login = element("guest.home.login", in: app)
        for _ in 0..<8 where !login.exists || !login.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(login.waitForExistence(timeout: 8))
        XCTAssertTrue(login.isHittable)
        login.tap()

        XCTAssertTrue(
            element("auth.login", in: app).waitForExistence(timeout: 8)
        )
        let openRegister = element("auth.login.open-register", in: app)
        for _ in 0..<8
        where !openRegister.exists || !openRegister.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(openRegister.waitForExistence(timeout: 8))
        XCTAssertTrue(openRegister.isHittable)
    }

    @MainActor
    func testParticipantRegistrationRequiresCoachQRBeforeAccountCreation() {
        let app = launchGuest(scenario: "auth_register")

        let google = element("auth.register.google", in: app)
        XCTAssertTrue(google.waitForExistence(timeout: 8))
        google.tap()

        XCTAssertTrue(
            element("auth.profile", in: app).waitForExistence(timeout: 8)
        )
        let name = element("auth.profile.name", in: app)
        let phone = element("auth.profile.phone", in: app)
        name.tap()
        name.typeText("Nadia Pratama")
        phone.tap()
        phone.typeText("+6281200000901")
        app.keyboards.buttons["Done"].tapIfExists()
        if app.keyboards.count > 0 {
            app.swipeUp()
        }

        let continueButton = element("auth.profile.continue", in: app)
        for _ in 0..<5
        where !continueButton.exists || !continueButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(continueButton.waitForExistence(timeout: 8))
        continueButton.tap()

        XCTAssertTrue(
            element("auth.participant-qr", in: app)
                .waitForExistence(timeout: 8)
        )
        let createAccount = element(
            "auth.participant-qr.create-account",
            in: app
        )
        XCTAssertTrue(createAccount.exists)
        XCTAssertFalse(createAccount.isEnabled)

        element("auth.close", in: app).tap()
        XCTAssertTrue(
            element("participant.guest.home", in: app)
                .waitForExistence(timeout: 8)
        )
    }

    @MainActor
    func testCoachApplicationScenariosExposeEligibilityAndPendingStates() {
        let ineligible = launchGuest(
            scenario: "coach_application_ineligible"
        )
        XCTAssertTrue(
            element("coach.eligibility", in: ineligible)
                .waitForExistence(timeout: 8)
        )
        let payment = ineligible.buttons[
            "coach.eligibility.continue-payment"
        ]
        for _ in 0..<6 where !payment.exists {
            ineligible.swipeUp()
        }
        XCTAssertTrue(payment.exists)
        XCTAssertFalse(payment.isEnabled)
        ineligible.terminate()

        let pending = launchGuest(scenario: "coach_pending_approval")
        XCTAssertTrue(
            element("coach.pending", in: pending)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            pending.staticTexts["Pembayaran terverifikasi"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            pending.staticTexts["Akun tetap sebagai Peserta"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            pending.staticTexts["Menunggu pemeriksaan Admin"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(
            pending.staticTexts[
                "coach.pending.payment_verified"
            ].exists
        )
        XCTAssertFalse(
            pending.staticTexts[
                "coach.pending.participant_role"
            ].exists
        )
        XCTAssertFalse(
            pending.staticTexts[
                "coach.pending.admin_review"
            ].exists
        )
        let finish = pending.buttons["coach.pending.finish"]
        for _ in 0..<4 where !finish.exists {
            pending.swipeUp()
        }
        XCTAssertTrue(finish.exists)
    }

    @MainActor
    private func launchGuest(
        scenario: String,
        extraArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-DemoRole", "guest",
            "-DemoScenario", scenario,
            "-SkipDemoLanding"
        ] + extraArguments
        app.launch()
        return app
    }

    @MainActor
    private func performLeadingEdgeBackSwipe(
        in app: XCUIApplication
    ) {
        let window = app.windows.firstMatch
        let start = window.coordinate(
            withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5)
        )
        let end = window.coordinate(
            withNormalizedOffset: CGVector(dx: 0.82, dy: 0.5)
        )
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    @MainActor
    private func element(
        _ identifier: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
    }
}

private extension XCUIElement {
    func tapIfExists() {
        if exists && isHittable {
            tap()
        }
    }
}
