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
            tabButton(label: "Home", in: app)
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

        let homeTab = tabButton(label: "Home", in: app)
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
        XCTAssertFalse(
            app.navigationBars["Profil"].buttons["BackButton"].exists
        )

        let privacyLink = app.buttons[
            "participant.profile.legal.privacy"
        ]
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
    func testParticipantSelectsProgramBeforeOpeningDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "participant",
            "-DemoScenario", "participant_active",
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

        XCTAssertFalse(
            app.buttons[
                "participant.program.select."
                    + "10000000-0000-0000-0000-000000000003"
            ].exists
        )

        let historyFilter = app.segmentedControls.buttons["Riwayat"]
        XCTAssertTrue(historyFilter.waitForExistence(timeout: 5))
        historyFilter.tap()
        XCTAssertTrue(
            app.buttons[
                "participant.program.select."
                    + "10000000-0000-0000-0000-000000000004"
            ].waitForExistence(timeout: 5)
        )

        let availableFilter = app.segmentedControls.buttons["Aktif"]
        XCTAssertTrue(availableFilter.waitForExistence(timeout: 5))
        availableFilter.tap()

        let joinProgram = app.buttons["participant.program.join"]
        XCTAssertTrue(joinProgram.waitForExistence(timeout: 5))
        joinProgram.tap()
        XCTAssertTrue(
            app.navigationBars["Gabung program"]
                .waitForExistence(timeout: 5)
        )

        app.buttons["participant.join.scan"].tap()
        XCTAssertTrue(
            element(identifier: "participant.qr.scanner", in: app)
                .waitForExistence(timeout: 5)
        )
        app.buttons["participant.qr.use-demo"].tap()
        XCTAssertTrue(
            element(identifier: "participant.join.preview.result", in: app)
                .waitForExistence(timeout: 8)
        )
        let joinBackButton = app.buttons["navigation.back"]
        XCTAssertTrue(joinBackButton.waitForExistence(timeout: 5))
        joinBackButton.tap()

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

        let scanInvite = app.buttons["participant.invite.scan"]
        XCTAssertTrue(scanInvite.waitForExistence(timeout: 5))
        scanInvite.tap()
        XCTAssertTrue(
            element(identifier: "participant.qr.scanner", in: app)
                .waitForExistence(timeout: 5)
        )
        let useDemoQR = app.buttons["participant.qr.use-demo"]
        XCTAssertTrue(useDemoQR.waitForExistence(timeout: 5))
        useDemoQR.tap()

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
            element(identifier: "participant.home", in: app)
                .waitForExistence(timeout: 8)
        )

        let firstStep = app.buttons["participant.step.open.1"]
        for _ in 0..<3 where !firstStep.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(firstStep.waitForExistence(timeout: 5))
        firstStep.tap()

        let sampleEvidence = app.buttons[
            "participant.evidence.use-sample"
        ]
        for _ in 0..<3 where !sampleEvidence.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(sampleEvidence.waitForExistence(timeout: 5))

        let camera = app.buttons["participant.evidence.camera"]
        XCTAssertTrue(camera.waitForExistence(timeout: 5))
        camera.tap()
        XCTAssertTrue(
            app.staticTexts["Kamera tidak tersedia"]
                .waitForExistence(timeout: 5)
        )
        app.buttons["Pilih alternatif"].tap()

        sampleEvidence.tap()
        XCTAssertTrue(
            element(identifier: "participant.evidence.thumbnail", in: app)
                .waitForExistence(timeout: 8)
        )
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
            app.staticTexts["1/3"].waitForExistence(timeout: 5)
        )

        let secondStep = app.buttons["participant.step.open.2"]
        if !secondStep.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(secondStep.waitForExistence(timeout: 5))
        secondStep.tap()
        let videoPlayer = element(
            identifier: "participant.video.player",
            in: app
        )
        if !videoPlayer.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(
            videoPlayer.waitForExistence(timeout: 8)
        )
        app.navigationBars.buttons.element(boundBy: 0).tap()

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
        tabButton(label: "Undangan", in: app).tap()

        let generateInvite = app.buttons["coach.invite.generate"]
        XCTAssertTrue(generateInvite.waitForExistence(timeout: 5))
        generateInvite.tap()
        XCTAssertTrue(
            app.buttons["coach.invite.share"]
                .waitForExistence(timeout: 5)
        )
        app.buttons["coach.invite.share"].tap()
        XCTAssertTrue(
            app.otherElements["ActivityListView"]
                .waitForExistence(timeout: 5)
        )
        let closeShare = app.buttons["header.closeButton"]
        XCTAssertTrue(closeShare.waitForExistence(timeout: 5))
        closeShare.tap()

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
    func testAdminCreatesWinnerBanner() throws {
        let app = launchAdmin()
        tabButton(label: "Konten", in: app).tap()
        XCTAssertTrue(
            element(identifier: "admin.content", in: app)
                .waitForExistence(timeout: 8)
        )
        app.buttons["admin.content.create-banner"].tap()
        let save = app.buttons["admin.content.save-banner"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()
        XCTAssertTrue(
            element(identifier: "admin.content", in: app)
                .waitForExistence(timeout: 8)
        )
    }

    @MainActor
    func testAdminWinnerLockRemainsStableAfterAdjustment() throws {
        let app = launchAdmin()
        tabButton(label: "Konten", in: app).tap()

        let manage = app.buttons[
            "Kelola pemenang Transformasi 7 hari"
        ]
        XCTAssertTrue(manage.waitForExistence(timeout: 8))
        manage.tap()
        XCTAssertTrue(
            element(identifier: "admin.winners", in: app)
                .waitForExistence(timeout: 8)
        )

        let lock = app.buttons["admin.winners.lock"]
        if !lock.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(lock.waitForExistence(timeout: 5))
        lock.tap()
        let confirmLock = app.buttons["Kunci snapshot"]
        XCTAssertTrue(confirmLock.waitForExistence(timeout: 5))
        confirmLock.tap()
        let reset = app.buttons["admin.winners.reset-debug"]
        for _ in 0..<3 where !reset.exists {
            app.swipeUp()
        }
        XCTAssertTrue(reset.waitForExistence(timeout: 8))

        let adjustment = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "admin.winners.adjust."
            )
        ).firstMatch
        for _ in 0..<3 where !adjustment.exists {
            app.swipeDown()
        }
        XCTAssertTrue(adjustment.waitForExistence(timeout: 5))
        adjustment.tap()

        let stepper = app.steppers["admin.adjust.points"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        app.buttons["admin.adjust.points-Increment"].tap()
        let reason = app.textFields["admin.adjust.reason"]
        reason.tap()
        reason.typeText("Koreksi skor demo")
        app.buttons["admin.adjust.save"].tap()

        let changedWarning = element(
            identifier: "admin.winners.changed-warning",
            in: app
        )
        for _ in 0..<6 where !changedWarning.exists {
            app.swipeUp()
        }
        XCTAssertTrue(
            changedWarning.waitForExistence(timeout: 8)
        )
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
    }

    @MainActor
    func testCoachWalletZeroAndAdminWinnerLockScenarios() throws {
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
            coachApp.staticTexts[
                "Kuota habis. Undangan dapat dibuat, tetapi "
                    + "penukaran baru diblokir."
            ]
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
            element(identifier: "admin.winners", in: adminApp)
                .waitForExistence(timeout: 10)
        )
        let reset = adminApp.buttons["admin.winners.reset-debug"]
        for _ in 0..<4 where !reset.exists {
            adminApp.swipeUp()
        }
        XCTAssertTrue(reset.waitForExistence(timeout: 8))
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
