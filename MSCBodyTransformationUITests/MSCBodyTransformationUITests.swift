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
    private func tabButton(
        label: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        app.tabBars.buttons
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }
}
