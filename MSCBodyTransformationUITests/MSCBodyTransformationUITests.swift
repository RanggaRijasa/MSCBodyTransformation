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
            tabButton(label: "Beranda", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            element(identifier: "participant.home", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            element(identifier: "participant.home.profile", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(tabButton(label: "Program", in: app).exists)
        XCTAssertTrue(tabButton(label: "Peringkat", in: app).exists)
        XCTAssertTrue(tabButton(label: "Coach", in: app).exists)
        XCTAssertTrue(tabButton(label: "Profil", in: app).exists)
    }

    @MainActor
    func testParticipantHomeViewAllSelectsLeaderboardTab() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_active",
            "-SkipDemoLanding"
        ]
        app.launch()

        XCTAssertTrue(
            element(identifier: "participant.home", in: app)
                .waitForExistence(timeout: 8)
        )

        let leaderboardTab = tabButton(label: "Peringkat", in: app)
        leaderboardTab.tap()
        XCTAssertTrue(
            element(identifier: "participant.leaderboard", in: app)
                .waitForExistence(timeout: 8)
        )

        let selector = app.buttons[
            "participant.leaderboard.program-selector"
        ]
        XCTAssertTrue(selector.waitForExistence(timeout: 5))
        selector.tap()

        let alternateProgram = app.buttons[
            "participant.leaderboard.program."
                + "10000000-0000-0000-0000-000000000005"
        ]
        XCTAssertTrue(alternateProgram.waitForExistence(timeout: 5))
        alternateProgram.tap()
        XCTAssertTrue(
            element(identifier: "participant.leaderboard.podium", in: app)
                .waitForExistence(timeout: 8)
        )

        let homeTab = tabButton(label: "Beranda", in: app)
        homeTab.tap()
        XCTAssertTrue(
            element(identifier: "participant.home", in: app)
                .waitForExistence(timeout: 8)
        )

        let programTitle = app.staticTexts[
            "participant.home.leaderboard.program-title"
        ]
        XCTAssertTrue(programTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(programTitle.label, "Gerak konsisten 3 hari")

        let viewAll = app.buttons[
            "participant.home.leaderboard.view-all"
        ]
        for _ in 0..<4
        where !viewAll.waitForExistence(timeout: 1) || !viewAll.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(viewAll.waitForExistence(timeout: 5))
        XCTAssertTrue(viewAll.isHittable)
        viewAll.tap()

        XCTAssertTrue(
            element(identifier: "participant.leaderboard", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(leaderboardTab.isSelected)
        XCTAssertTrue(
            app.buttons["participant.leaderboard.program-selector"]
                .label
                .contains("Gerak konsisten 3 hari")
        )
        XCTAssertFalse(
            app.navigationBars["Peringkat"].buttons["BackButton"].exists
        )
    }

    @MainActor
    func testParticipantHomeProfileCardSelectsProfileTab() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_active",
            "-SkipDemoLanding"
        ]
        app.launch()

        XCTAssertTrue(
            element(identifier: "participant.home", in: app)
                .waitForExistence(timeout: 8)
        )

        let profileCard = app.buttons["participant.home.profile"]
        XCTAssertTrue(profileCard.waitForExistence(timeout: 5))
        XCTAssertTrue(profileCard.isHittable)
        profileCard.tap()

        XCTAssertTrue(
            element(identifier: "participant.profile", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(tabButton(label: "Profil", in: app).isSelected)
        XCTAssertFalse(app.staticTexts["AL"].exists)
        XCTAssertFalse(
            app.navigationBars["Profil"].buttons["BackButton"].exists
        )

        let privacyLink = app.buttons[
            "participant.profile.legal.privacy"
        ]
        for _ in 0..<4
        where !privacyLink.waitForExistence(timeout: 1)
            || !privacyLink.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(privacyLink.waitForExistence(timeout: 5))
        privacyLink.tap()

        let legalBackButton = app.buttons["navigation.back"]
        XCTAssertTrue(legalBackButton.waitForExistence(timeout: 5))
        legalBackButton.tap()
        XCTAssertTrue(
            element(identifier: "participant.profile", in: app)
                .waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testParticipantEditsProfileAndChangesCoachByQR() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_active",
            "-SkipDemoLanding"
        ]
        app.launch()

        let profileTab = tabButton(label: "Profil", in: app)
        XCTAssertTrue(profileTab.waitForExistence(timeout: 8))
        profileTab.tap()
        XCTAssertTrue(
            element(identifier: "participant.profile", in: app)
                .waitForExistence(timeout: 8)
        )

        let editButton = app.buttons["participant.profile.edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let nameField = app.textFields[
            "participant.profile.editor.name"
        ]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeKey("a", modifierFlags: .command)
        nameField.typeText("Ayu Baru")

        let phoneField = app.textFields[
            "participant.profile.editor.phone"
        ]
        phoneField.tap()
        phoneField.typeKey("a", modifierFlags: .command)
        phoneField.typeText("+628123456700")

        XCTAssertTrue(
            app.buttons["participant.profile.editor.photo-picker"].exists
        )
        XCTAssertFalse(
            app.buttons["participant.profile.editor.photo-demo"].exists
        )

        let saveButton = app.buttons[
            "participant.profile.editor.save"
        ]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(
            app.staticTexts["Ayu Baru"].waitForExistence(timeout: 8)
        )
        let phoneRow = element(
            identifier: "participant.profile.phone",
            in: app
        )
        XCTAssertTrue(phoneRow.waitForExistence(timeout: 5))
        XCTAssertTrue(phoneRow.label.contains("+628123456700"))

        let changeCoach = app.buttons[
            "participant.profile.change-coach"
        ]
        for _ in 0..<3
        where !changeCoach.waitForExistence(timeout: 1)
            || !changeCoach.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(changeCoach.waitForExistence(timeout: 5))
        changeCoach.tap()

        let demoQR = app.buttons["participant.qr.use-demo"]
        XCTAssertTrue(demoQR.waitForExistence(timeout: 8))
        demoQR.tap()

        let confirmCoach = app.sheets[
            "Ganti coach pendamping?"
        ].buttons["Ganti coach"]
        XCTAssertTrue(confirmCoach.waitForExistence(timeout: 5))
        confirmCoach.tap()

        XCTAssertTrue(
            app.staticTexts["Coach Maya"].waitForExistence(timeout: 8)
        )
        XCTAssertFalse(app.textFields["Kode coach"].exists)
    }

    @MainActor
    func testParticipantHomeShowsWinnersAndCoachDiscovery() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_active",
            "-SkipDemoLanding"
        ]
        app.launch()

        XCTAssertTrue(
            element(identifier: "participant.home", in: app)
                .waitForExistence(timeout: 8)
        )

        let firstWinner = app.images[
            "participant.home.winner."
                + "70000000-0000-0000-0000-000000000001"
        ]
        for _ in 0..<5 where !firstWinner.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(firstWinner.waitForExistence(timeout: 5))
        let homeLeaderboard = element(
            identifier: "participant.home.leaderboard",
            in: app
        )
        XCTAssertTrue(homeLeaderboard.exists)
        XCTAssertEqual(
            app.staticTexts["Leaderboard Top 5"].label,
            "Leaderboard Top 5"
        )
        XCTAssertLessThan(
            homeLeaderboard.frame.minY,
            firstWinner.frame.minY,
            "Leaderboard harus tampil sebelum bagian poster pemenang."
        )
        XCTAssertTrue(
            app.images[
                "participant.home.winner."
                    + "70000000-0000-0000-0000-000000000003"
            ].exists,
            "Home harus memuat tepat dua gambar poster pemenang."
        )
        XCTAssertFalse(
            app.buttons[
                "participant.home.winner."
                    + "70000000-0000-0000-0000-000000000001"
            ].exists,
            "Gambar poster tidak boleh menjadi tombol."
        )

        let coachRaka = app.buttons[
            "participant.home.coach."
                + "30000000-0000-0000-0000-000000000101"
        ]
        for _ in 0..<5 where !coachRaka.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(coachRaka.waitForExistence(timeout: 5))
        XCTAssertTrue(coachRaka.label.contains("Coach-mu"))
        XCTAssertTrue(
            app.buttons[
                "participant.home.coach."
                    + "30000000-0000-0000-0000-000000000102"
            ].exists
        )

        let viewAllCoaches = app.buttons[
            "participant.home.coaches.view-all"
        ]
        for _ in 0..<4
        where !viewAllCoaches.waitForExistence(timeout: 1)
            || !viewAllCoaches.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(viewAllCoaches.waitForExistence(timeout: 5))
        XCTAssertTrue(viewAllCoaches.isHittable)
        viewAllCoaches.tap()

        XCTAssertTrue(
            element(identifier: "participant.coaches", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(tabButton(label: "Coach", in: app).isSelected)
    }

    @MainActor
    func testParticipantSelectsProgramBeforeOpeningDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_mid_program",
            "-SkipDemoLanding"
        ]
        app.launch()

        let programTab = tabButton(label: "Program", in: app)
        XCTAssertTrue(programTab.waitForExistence(timeout: 8))
        programTab.tap()

        XCTAssertTrue(
            element(identifier: "participant.program.catalog", in: app)
                .waitForExistence(timeout: 8)
        )

        let followedProgram = app.buttons[
            "participant.program.select."
                + "10000000-0000-0000-0000-000000000001"
        ]
        XCTAssertTrue(
            followedProgram.waitForExistence(timeout: 5),
            "Program yang sedang diikuti harus tampil di tab Diikuti."
        )

        let availableProgram = app.buttons[
            "participant.program.select."
                + "10000000-0000-0000-0000-000000000003"
        ]
        XCTAssertFalse(availableProgram.exists)

        let availableFilter = app.segmentedControls.buttons["Tersedia"]
        XCTAssertTrue(availableFilter.waitForExistence(timeout: 5))
        availableFilter.tap()
        XCTAssertTrue(
            availableProgram.waitForExistence(timeout: 5),
            "Program yang belum diikuti harus tampil di tab Tersedia."
        )
        XCTAssertFalse(followedProgram.exists)

        let historyFilter = app.segmentedControls.buttons["Riwayat"]
        XCTAssertTrue(historyFilter.waitForExistence(timeout: 5))
        historyFilter.tap()
        XCTAssertTrue(
            app.buttons[
                "participant.program.select."
                    + "10000000-0000-0000-0000-000000000004"
            ].waitForExistence(timeout: 5)
        )

        availableFilter.tap()

        XCTAssertTrue(availableProgram.waitForExistence(timeout: 5))
        availableProgram.tap()
        let joinProgram = app.buttons["participant.program.offer.join"]
        XCTAssertTrue(joinProgram.waitForExistence(timeout: 5))
        joinProgram.tap()
        XCTAssertTrue(
            app.navigationBars["Gabung program"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(
            app.staticTexts["Masukkan kode secara manual"].exists
        )
        XCTAssertFalse(
            app.textFields["participant.join.code"].exists
        )

        app.buttons["participant.join.scan"].tap()
        XCTAssertTrue(
            element(identifier: "participant.qr.scanner", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.buttons["Masukkan kode manual"].exists)
        app.buttons["participant.qr.use-demo"].tap()
        XCTAssertTrue(
            app.buttons["participant.join.confirm-coach"]
                .waitForExistence(timeout: 8)
        )
        let joinBackButton = app.buttons["navigation.back"]
        XCTAssertTrue(joinBackButton.waitForExistence(timeout: 5))
        joinBackButton.tap()
        XCTAssertTrue(joinProgram.waitForExistence(timeout: 5))
        XCTAssertTrue(joinBackButton.waitForExistence(timeout: 5))
        joinBackButton.tap()
        XCTAssertTrue(
            element(identifier: "participant.program.catalog", in: app)
                .waitForExistence(timeout: 5)
        )

        let followedFilter = app.segmentedControls.buttons["Diikuti"]
        XCTAssertTrue(followedFilter.waitForExistence(timeout: 5))
        followedFilter.tap()

        let activeProgram = app.buttons[
            "participant.program.select."
                + "10000000-0000-0000-0000-000000000001"
        ]
        XCTAssertTrue(activeProgram.waitForExistence(timeout: 5))
        activeProgram.tap()

        XCTAssertTrue(
            element(identifier: "participant.program.detail", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.navigationBars["Transformasi 7 hari"].exists
        )
        XCTAssertTrue(
            app.staticTexts["Aktivitas program"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.staticTexts["Aturan dan poin"].exists)

        let currentDay = app.buttons["participant.program.day.4"]
        XCTAssertTrue(currentDay.waitForExistence(timeout: 5))
        let openDeadline = Date().addingTimeInterval(5)
        while currentDay.value as? String != "Dibuka",
              Date() < openDeadline {
            RunLoop.current.run(
                until: Date().addingTimeInterval(0.2)
            )
        }
        XCTAssertEqual(currentDay.value as? String, "Dibuka")
        XCTAssertTrue(app.staticTexts["Hari ini"].exists)
        XCTAssertTrue(
            app.buttons["participant.program.step.4.1"]
                .waitForExistence(timeout: 5)
        )

        let previousDay = app.buttons["participant.program.day.3"]
        XCTAssertTrue(previousDay.waitForExistence(timeout: 5))
        previousDay.tap()
        XCTAssertTrue(
            app.buttons["participant.program.step.3.1"]
                .waitForExistence(timeout: 5)
        )
        app.buttons["participant.program.step.3.1"].tap()
        XCTAssertTrue(
            element(identifier: "participant.step.detail", in: app)
                .waitForExistence(timeout: 5),
            "Langkah pada hari lampau yang sudah terbit harus dapat dibuka."
        )
        let stepBackButton = app.buttons["navigation.back"]
        XCTAssertTrue(stepBackButton.waitForExistence(timeout: 5))
        stepBackButton.tap()
        XCTAssertTrue(previousDay.waitForExistence(timeout: 5))

        let futureDay = app.buttons["participant.program.day.5"]
        XCTAssertTrue(futureDay.waitForExistence(timeout: 5))
        futureDay.tap()
        XCTAssertTrue(
            app.staticTexts["Aktivitas belum tersedia."]
                .waitForExistence(timeout: 5)
        )

        currentDay.tap()
        XCTAssertFalse(app.buttons["participant.program.step.4.1"].exists)
        currentDay.tap()
        XCTAssertTrue(
            app.buttons["participant.program.step.4.1"]
                .waitForExistence(timeout: 5)
        )

        for pressDuration in [0.15, 0.35, 1.0] {
            let detailBackButton = app.buttons["navigation.back"]
            XCTAssertTrue(detailBackButton.waitForExistence(timeout: 5))
            detailBackButton.press(forDuration: pressDuration)
            XCTAssertFalse(app.menus.firstMatch.exists)
            XCTAssertTrue(
                element(identifier: "participant.program.catalog", in: app)
                    .waitForExistence(timeout: 5)
            )

            if pressDuration != 1 {
                let program = app.buttons[
                    "participant.program.select."
                        + "10000000-0000-0000-0000-000000000001"
                ]
                XCTAssertTrue(program.waitForExistence(timeout: 5))
                program.tap()
                XCTAssertTrue(
                    element(identifier: "participant.program.detail", in: app)
                        .waitForExistence(timeout: 5)
                )
            }
        }
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

        tabButton(label: "Program", in: app).tap()
        XCTAssertTrue(
            element(identifier: "participant.program.catalog", in: app)
                .waitForExistence(timeout: 5)
        )

        let availableProgram = app.buttons[
            "participant.program.select."
                + "10000000-0000-0000-0000-000000000003"
        ]
        XCTAssertTrue(availableProgram.waitForExistence(timeout: 5))
        availableProgram.tap()
        XCTAssertTrue(
            app.staticTexts["Tentang program"]
                .waitForExistence(timeout: 5)
        )

        app.buttons["participant.program.offer.join"].tap()
        let scanCoach = app.buttons["participant.join.scan"]
        XCTAssertTrue(scanCoach.waitForExistence(timeout: 5))
        scanCoach.tap()
        XCTAssertTrue(
            element(identifier: "participant.qr.scanner", in: app)
                .waitForExistence(timeout: 5)
        )
        let useDemoQR = app.buttons["participant.qr.use-demo"]
        XCTAssertTrue(useDemoQR.waitForExistence(timeout: 5))
        useDemoQR.tap()

        let confirmCoach = app.buttons["participant.join.confirm-coach"]
        XCTAssertTrue(confirmCoach.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Coach Raka"].exists)
        confirmCoach.tap()

        let payment = app.buttons["participant.payment.demo"]
        XCTAssertTrue(payment.waitForExistence(timeout: 5))
        XCTAssertFalse(app.alerts["Konfirmasi Pembelian"].exists)
        payment.tap()

        let completed = app.buttons["participant.join.completed"]
        XCTAssertTrue(completed.waitForExistence(timeout: 8))
        completed.tap()
        XCTAssertTrue(
            element(identifier: "participant.program.detail", in: app)
                .waitForExistence(timeout: 8)
        )
    }

    @MainActor
    func testParticipantOpensNativePhotoPicker() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_active",
            "-SkipDemoLanding"
        ]
        app.launch()

        let firstStep = app.buttons["participant.step.open.1"]
        if !firstStep.waitForExistence(timeout: 2) {
            app.swipeUp()
            app.swipeUp()
        }
        XCTAssertTrue(firstStep.waitForExistence(timeout: 8))
        firstStep.tap()

        let picker = app.buttons["participant.evidence.photo-picker"]
        if !picker.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()

        let cancelPicker = app.buttons.matching(
            NSPredicate(
                format: "identifier == %@ OR label == %@ OR label == %@",
                "Cancel",
                "Batalkan",
                "Cancel"
            )
        ).firstMatch
        XCTAssertTrue(cancelPicker.waitForExistence(timeout: 8))
        cancelPicker.tap()
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
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

        XCUIDevice.shared.press(.home)
        app.activate()
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
        tabButton(label: "Peringkat", in: app).tap()
        XCTAssertTrue(
            element(identifier: "coach.leaderboard", in: app)
                .waitForExistence(timeout: 8)
        )
        tabButton(label: "QR saya", in: app).tap()

        XCTAssertTrue(
            app.staticTexts["QR pendaftaran saya"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.buttons["coach.invite.share"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.staticTexts["COACH-RAKA-7K9Q"].exists)
        app.buttons["coach.invite.share"].tap()
        XCTAssertTrue(
            app.otherElements["ActivityListView"]
                .waitForExistence(timeout: 5)
        )
        let closeShare = app.buttons["header.closeButton"]
        XCTAssertTrue(closeShare.waitForExistence(timeout: 5))
        closeShare.tap()
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
    func testAdminCreatesDraftAddsDayStepPreviewsAndPublishes() throws {
        let app = launchAdmin()

        tabButton(label: "Program", in: app).tap()
        XCTAssertTrue(
            element(identifier: "admin.programs", in: app)
                .waitForExistence(timeout: 8)
        )
        app.buttons["admin.program.create"].tap()
        XCTAssertTrue(
            element(
                identifier: "admin.program.editor.overview",
                in: app
            )
                .waitForExistence(timeout: 8)
        )

        app.buttons["admin.program.editor.open.content"].tap()
        XCTAssertTrue(
            app.buttons["navigation.back"].waitForExistence(timeout: 5)
        )
        let firstDay = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "admin.program.day.open."
            )
        ).firstMatch
        XCTAssertTrue(firstDay.waitForExistence(timeout: 5))
        firstDay.tap()
        let addStep = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "admin.editor.add-step."
            )
        ).firstMatch
        XCTAssertTrue(addStep.waitForExistence(timeout: 5))
        addStep.tap()
        let article = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Artikel")
        ).firstMatch
        XCTAssertTrue(article.waitForExistence(timeout: 5))
        article.tap()
        let createdStep = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "admin.program.step.open."
            )
        ).firstMatch
        XCTAssertTrue(createdStep.waitForExistence(timeout: 5))

        app.buttons["navigation.back"].tap()
        app.buttons["navigation.back"].tap()

        app.buttons["admin.program.editor.open.preview"].tap()
        XCTAssertTrue(
            element(identifier: "admin.editor.preview", in: app)
                .waitForExistence(timeout: 5)
        )
        app.buttons["navigation.back"].tap()

        app.buttons["admin.program.editor.open.publish"].tap()
        let publish = app.buttons["admin.editor.publish"]
        if !publish.waitForExistence(timeout: 3) || !publish.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(publish.waitForExistence(timeout: 5))
        XCTAssertTrue(
            publish.isEnabled,
            app.staticTexts.allElementsBoundByIndex
                .map(\.label)
                .joined(separator: " | ")
        )
        publish.tap()
        XCTAssertTrue(
            app.buttons["Publikasi demo selesai"]
                .waitForExistence(timeout: 8)
        )
    }

    @MainActor
    func testAdminApprovesCoachAndManuallyEnrollsParticipant() throws {
        let app = launchAdmin()
        tabButton(label: "Orang", in: app).tap()
        XCTAssertTrue(
            element(identifier: "admin.people", in: app)
                .waitForExistence(timeout: 8)
        )

        let approve = app.buttons[
            "admin.people.approve."
                + "00000000-0000-0000-0000-000000000105"
        ]
        for _ in 0..<4 where !approve.exists {
            app.swipeUp()
        }
        XCTAssertTrue(approve.waitForExistence(timeout: 5))
        approve.tap()

        let participant = app.buttons[
            "admin.people.open."
                + "00000000-0000-0000-0000-000000000001"
        ]
        for _ in 0..<5 where !participant.exists || !participant.isHittable {
            app.swipeDown()
        }
        XCTAssertTrue(participant.waitForExistence(timeout: 5))
        participant.tap()

        let reason = app.textFields["admin.people.enroll-reason"]
        XCTAssertTrue(reason.waitForExistence(timeout: 5))
        reason.tap()
        reason.typeText("Koreksi enrollment demo")
        app.buttons["Daftarkan peserta"].tap()
        XCTAssertTrue(
            element(identifier: "admin.people", in: app)
                .waitForExistence(timeout: 8)
        )
    }

    @MainActor
    func testAdminPosterEditorRequiresPhotoSelection() throws {
        let app = launchAdmin()
        tabButton(label: "Konten", in: app).tap()
        XCTAssertTrue(
            element(identifier: "admin.content", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            element(
                identifier: "admin.content.poster-gallery",
                in: app
            ).waitForExistence(timeout: 5)
        )
        XCTAssertFalse(
            app.buttons.matching(
                NSPredicate(
                    format: "label BEGINSWITH %@",
                    "Kelola pemenang"
                )
            ).firstMatch.exists
        )
        app.buttons["admin.content.create-banner"].tap()
        let save = app.buttons["admin.content.save-banner"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertFalse(save.isEnabled)
        XCTAssertTrue(
            app.buttons["admin.content.poster-picker"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.buttons["admin.content.poster-demo"].exists)
    }

    @MainActor
    func testRoleSwitchOpensCoachScenario() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID"
        ]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["root.title"].waitForExistence(timeout: 5)
        )
        app.buttons["Coach"].tap()

        let enterDemo = app.buttons["root.enter-demo"]
        let ready = NSPredicate(format: "enabled == true")
        expectation(for: ready, evaluatedWith: enterDemo)
        waitForExpectations(timeout: 5)
        enterDemo.tap()

        XCTAssertTrue(
            element(identifier: "coach.dashboard", in: app)
                .waitForExistence(timeout: 8)
        )
    }

    @MainActor
    func testDarkModeFinalLeaderboardLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-AppleInterfaceStyle", "Dark",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_final_leaderboard",
            "-SkipDemoLanding"
        ]
        app.launch()

        XCTAssertTrue(
            element(identifier: "participant.leaderboard", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(tabButton(label: "Peringkat", in: app).isSelected)
        XCTAssertTrue(
            app.staticTexts["Selesai"].waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.staticTexts["Berlangsung"].exists)
    }

    @MainActor
    func testParticipantOpensArchivedLeaderboard() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_active",
            "-SkipDemoLanding"
        ]
        app.launch()

        tabButton(label: "Peringkat", in: app).tap()
        XCTAssertTrue(
            element(identifier: "participant.leaderboard", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            element(
                identifier: "participant.leaderboard.program-selector",
                in: app
            )
            .waitForExistence(timeout: 5)
        )
        let initialSelector = app.buttons[
            "participant.leaderboard.program-selector"
        ]
        XCTAssertTrue(initialSelector.waitForExistence(timeout: 5))
        initialSelector.tap()
        XCTAssertTrue(
            app.navigationBars["Pilih program"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.buttons[
                "participant.leaderboard.program."
                    + "10000000-0000-0000-0000-000000000005"
            ]
            .waitForExistence(timeout: 5)
        )
        let firstActiveProgram = app.buttons[
            "participant.leaderboard.program."
                + "10000000-0000-0000-0000-000000000001"
        ]
        XCTAssertTrue(firstActiveProgram.waitForExistence(timeout: 5))
        firstActiveProgram.tap()
        XCTAssertTrue(
            element(
                identifier: "participant.leaderboard.podium",
                in: app
            )
            .waitForExistence(timeout: 5)
        )

        let archive = element(
            identifier: "participant.leaderboard.archive",
            in: app
        )
        XCTAssertTrue(archive.waitForExistence(timeout: 5))
        archive.tap()
        XCTAssertTrue(
            app.navigationBars["Riwayat peringkat"]
                .waitForExistence(timeout: 5)
        )

        let completedProgram = element(
            identifier:
                "participant.leaderboard.archive."
                + "10000000-0000-0000-0000-000000000004",
            in: app
        )
        XCTAssertTrue(completedProgram.waitForExistence(timeout: 5))
        completedProgram.tap()

        XCTAssertTrue(
            app.staticTexts["Hasil akhir"].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.staticTexts["Konsisten Juni"].waitForExistence(timeout: 5)
        )

        let programSelector = app.buttons[
            "participant.leaderboard.program-selector"
        ]
        XCTAssertTrue(programSelector.waitForExistence(timeout: 5))
        programSelector.tap()
        XCTAssertTrue(
            app.navigationBars["Pilih program"].waitForExistence(timeout: 5)
        )

        let activeProgram = app.buttons[
            "participant.leaderboard.program."
                + "10000000-0000-0000-0000-000000000001"
        ]
        XCTAssertTrue(activeProgram.waitForExistence(timeout: 5))
        activeProgram.tap()
        XCTAssertTrue(
            app.staticTexts["Peringkat sementara"]
                .waitForExistence(timeout: 8)
        )
    }

    @MainActor
    func testLargestAccessibilitySizeKeepsTodayNavigable() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "-UIAccessibilityDarkerSystemColorsEnabled", "YES",
            "-UIAccessibilityReduceTransparencyEnabled", "YES",
            "-UIAccessibilityDifferentiateWithoutColor", "YES",
            "-UIAccessibilityReduceMotionEnabled", "YES",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_onboarding",
            "-SkipDemoLanding"
        ]
        app.launch()

        let login = app.buttons["participant.login"]
        XCTAssertTrue(login.waitForExistence(timeout: 8))
        XCTAssertTrue(login.isHittable)
        XCTAssertTrue(
            element(identifier: "participant.entry.progress", in: app)
                .exists
        )
        XCTAssertEqual(app.tabBars.count, 0)
        login.tap()

        let continueButton = app.buttons["participant.profile.continue"]
        if !continueButton.waitForExistence(timeout: 3)
            || !continueButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertTrue(continueButton.isHittable)
    }

    @MainActor
    func testOfflineAndPermissionScenariosAreExplicit() throws {
        let offlineApp = XCUIApplication()
        offlineApp.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "offline",
            "-SkipDemoLanding"
        ]
        offlineApp.launch()
        XCTAssertTrue(
            element(identifier: "state.offline-banner", in: offlineApp)
                .waitForExistence(timeout: 8)
        )
        offlineApp.terminate()

        let permissionApp = XCUIApplication()
        permissionApp.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "permission_denied",
            "-SkipDemoLanding"
        ]
        permissionApp.launch()
        XCTAssertTrue(
            permissionApp.staticTexts["Akses tidak tersedia"]
                .waitForExistence(timeout: 8)
        )
        let openProfile = permissionApp.buttons["Buka profil"]
        XCTAssertTrue(openProfile.waitForExistence(timeout: 5))
        openProfile.tap()
        XCTAssertTrue(
            element(identifier: "participant.profile", in: permissionApp)
                .waitForExistence(timeout: 8)
        )
    }

    @MainActor
    func testRepositoryErrorRetryPersistsAcrossTabs() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "repository_error",
            "-SkipDemoLanding"
        ]
        app.launch()

        let retry = app.buttons["Coba lagi"]
        XCTAssertTrue(retry.waitForExistence(timeout: 8))
        retry.tap()
        XCTAssertTrue(
            element(identifier: "participant.home", in: app)
                .waitForExistence(timeout: 8)
        )

        tabButton(label: "Profil", in: app).tap()
        XCTAssertTrue(
            element(identifier: "participant.profile", in: app)
                .waitForExistence(timeout: 8)
        )
    }

    @MainActor
    func testLegacyCoachAndAdminWinnerScenariosRemainNavigable() throws {
        let coachApp = XCUIApplication()
        coachApp.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "coach",
            "-DemoScenario", "coach_wallet_zero",
            "-SkipDemoLanding"
        ]
        coachApp.launch()
        XCTAssertTrue(
            element(identifier: "coach.invite", in: coachApp)
                .waitForExistence(timeout: 8)
        )
        coachApp.terminate()

        let adminApp = XCUIApplication()
        adminApp.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "admin",
            "-DemoScenario", "admin_winner_lock",
            "-SkipDemoLanding"
        ]
        adminApp.launch()
        XCTAssertTrue(
            element(identifier: "admin.overview", in: adminApp)
                .waitForExistence(timeout: 10)
        )
        XCTAssertFalse(adminApp.buttons["Kelola pemenang"].exists)
    }

    @MainActor
    private func launchAdmin() -> XCUIApplication {
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
                .waitForExistence(timeout: 8)
        )
        return app
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
