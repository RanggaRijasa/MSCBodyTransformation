import XCTest

final class MSCBodyTransformationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testParticipantShellOpensAllTabs() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_active"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["root.title"].waitForExistence(timeout: 5))

        let enterDemoButton = app.buttons["root.enter-demo"]
        XCTAssertTrue(enterDemoButton.exists)
        XCTAssertTrue(enterDemoButton.isEnabled)
        enterDemoButton.tap()

        XCTAssertTrue(
            tabButton(label: "Hari ini", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(tabButton(label: "Program", in: app).exists)
        XCTAssertTrue(tabButton(label: "Peringkat", in: app).exists)
        XCTAssertTrue(tabButton(label: "Coach", in: app).exists)
        XCTAssertTrue(tabButton(label: "Profil", in: app).exists)
    }

    @MainActor
    func testDebugLaunchArgumentsOpenAdminShell() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "admin",
            "-DemoScenario", "admin_draft_editor",
            "-SkipDemoLanding"
        ]
        app.launch()

        XCTAssertTrue(
            tabButton(label: "Ringkasan", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(tabButton(label: "Program", in: app).exists)
        XCTAssertTrue(tabButton(label: "Orang", in: app).exists)
        XCTAssertTrue(tabButton(label: "Konten", in: app).exists)
        XCTAssertTrue(tabButton(label: "Pengaturan", in: app).exists)
    }

    @MainActor
    func testParticipantCompletesLocalJourneySlice() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_onboarding",
            "-SkipDemoLanding"
        ]
        app.launch()

        let login = app.buttons["participant.login"]
        XCTAssertTrue(login.waitForExistence(timeout: 8))
        login.tap()

        let profileContinue = app.buttons["participant.profile.continue"]
        XCTAssertTrue(profileContinue.waitForExistence(timeout: 5))
        profileContinue.tap()

        let disclaimer = app.switches[
            "participant.disclaimer.acknowledgement"
        ]
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5))
        disclaimer.tap()
        app.buttons["participant.disclaimer.continue"].tap()

        let invitePreview = app.buttons["participant.invite.preview"]
        XCTAssertTrue(invitePreview.waitForExistence(timeout: 5))
        invitePreview.tap()

        let join = app.buttons["participant.join.confirm"]
        XCTAssertTrue(join.waitForExistence(timeout: 5))
        join.tap()

        let weightField = app.textFields["participant.weigh.input"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        weightField.typeText("78,5")
        app.buttons["Selesai"].tap()
        app.swipeUp()

        let submitWeight = app.buttons["participant.weigh.submit"]
        XCTAssertTrue(submitWeight.waitForExistence(timeout: 5))
        submitWeight.tap()

        let confirm = app.buttons["Konfirmasi"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        XCTAssertTrue(
            app.staticTexts["Berat badan awal"]
                .waitForExistence(timeout: 8)
        )

        let firstStep = app.buttons["participant.step.open.1"]
        if !firstStep.waitForExistence(timeout: 2) {
            app.swipeUp()
            app.swipeUp()
        }
        XCTAssertTrue(firstStep.waitForExistence(timeout: 5))
        firstStep.tap()

        let sampleEvidence = app.buttons[
            "participant.evidence.use-sample"
        ]
        XCTAssertTrue(sampleEvidence.waitForExistence(timeout: 5))
        sampleEvidence.tap()
        app.swipeUp()

        let completeStep = app.buttons["participant.step.complete"]
        XCTAssertTrue(completeStep.waitForExistence(timeout: 5))
        completeStep.tap()
        XCTAssertTrue(
            app.staticTexts["Menunggu pemeriksaan"]
                .waitForExistence(timeout: 5)
        )

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.staticTexts["5%"].waitForExistence(timeout: 5)
        )

        tabButton(label: "Peringkat", in: app).tap()
        XCTAssertTrue(
            app.staticTexts["Ayu Lestari"].waitForExistence(timeout: 5)
        )

        tabButton(label: "Coach", in: app).tap()
        XCTAssertTrue(
            app.staticTexts["Coach Raka"].waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testCoachCompletesCriticalLocalJourney() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "coach",
            "-DemoScenario", "coach_review_queue",
            "-SkipDemoLanding"
        ]
        app.launch()

        XCTAssertTrue(
            element(identifier: "coach.dashboard", in: app)
                .waitForExistence(timeout: 8)
        )

        let openReview = app.buttons["coach.open-review-queue"]
        if !openReview.waitForExistence(timeout: 2)
            || !openReview.isHittable {
            app.scrollViews["coach.dashboard"].swipeUp()
        }
        XCTAssertTrue(openReview.waitForExistence(timeout: 5))
        openReview.tap()
        XCTAssertTrue(
            element(identifier: "coach.review.queue", in: app)
                .waitForExistence(timeout: 5)
        )

        let reviewItem = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "coach.review.open."
            )
        ).firstMatch
        XCTAssertTrue(reviewItem.waitForExistence(timeout: 5))
        reviewItem.tap()

        let evidence = app.buttons["coach.review.evidence.open"]
        XCTAssertTrue(evidence.waitForExistence(timeout: 5))
        evidence.tap()
        XCTAssertTrue(
            element(identifier: "coach.evidence.viewer", in: app)
                .waitForExistence(timeout: 5)
        )
        app.navigationBars["Bukti peserta"].buttons["Tutup"].tap()

        let approve = app.buttons["coach.review.approve"]
        if !approve.waitForExistence(timeout: 2) || !approve.isHittable {
            app.swipeUp()
            app.swipeUp()
        }
        XCTAssertTrue(approve.waitForExistence(timeout: 5))
        approve.tap()
        let confirmApprove = app.sheets[
            "Konfirmasi pemeriksaan"
        ].buttons["Setujui bukti"]
        XCTAssertTrue(confirmApprove.waitForExistence(timeout: 5))
        confirmApprove.tap()
        XCTAssertTrue(
            element(identifier: "coach.review.result", in: app)
                .waitForExistence(timeout: 8)
        )

        app.navigationBars.buttons.element(boundBy: 0).tap()
        tabButton(label: "Undangan", in: app).tap()

        let generateInvite = app.buttons["coach.invite.generate"]
        XCTAssertTrue(generateInvite.waitForExistence(timeout: 5))
        generateInvite.tap()
        XCTAssertTrue(
            app.buttons["coach.invite.share"]
                .waitForExistence(timeout: 5)
        )

        let openStore = app.buttons["coach.invite.open-store"]
        if !openStore.waitForExistence(timeout: 2)
            || !openStore.isHittable {
            app.swipeUp()
            app.swipeUp()
        }
        XCTAssertTrue(openStore.waitForExistence(timeout: 5))
        openStore.tap()
        XCTAssertTrue(
            element(
                identifier: "coach.store.no-real-purchase",
                in: app
            )
                .waitForExistence(timeout: 5)
        )
        let firstPack = app.buttons["coach.store.pack.10"]
        if !firstPack.waitForExistence(timeout: 2)
            || !firstPack.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(firstPack.waitForExistence(timeout: 5))
        firstPack.tap()
        XCTAssertTrue(
            app.alerts["Jalankan pembelian demo?"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.alerts["Konfirmasi Pembelian"].exists)
        app.alerts.buttons["Batal"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()
        tabButton(label: "Peserta", in: app).tap()
        let participant = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "coach.participant.open."
            )
        ).firstMatch
        XCTAssertTrue(participant.waitForExistence(timeout: 5))
        participant.tap()
        XCTAssertTrue(
            element(identifier: "coach.participant.detail", in: app)
                .waitForExistence(timeout: 5)
        )
    }

    @MainActor
    private func tabButton(
        label: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        app.tabBars.buttons
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }

    @MainActor
    private func element(
        identifier: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
    }
}
