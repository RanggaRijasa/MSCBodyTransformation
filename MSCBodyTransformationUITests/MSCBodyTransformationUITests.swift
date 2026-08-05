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
    func testCoachLeaderboardAndProfileUseParticipantInformationArchitecture()
        throws
    {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "coach",
            "-DemoScenario", "coach_review_queue",
            "-SkipDemoLanding"
        ]
        app.launch()

        XCTAssertFalse(tabButton(label: "Peserta", in: app).exists)
        XCTAssertFalse(tabButton(label: "Peringkat", in: app).exists)
        let leaderboardAction = app.buttons[
            "coach.dashboard.action.leaderboard"
        ]
        XCTAssertTrue(leaderboardAction.waitForExistence(timeout: 8))
        leaderboardAction.tap()

        XCTAssertTrue(
            element(identifier: "coach.leaderboard", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            element(
                identifier: "coach.leaderboard.program-selector",
                in: app
            )
                .waitForExistence(timeout: 5)
        )
        let assignedPodiumCards = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "coach.leaderboard.podium."
            )
        )
        XCTAssertGreaterThan(assignedPodiumCards.count, 0)
        XCTAssertGreaterThan(
            app.staticTexts
                .matching(NSPredicate(format: "label == %@", "Pesertamu"))
                .count,
            0
        )
        XCTAssertFalse(app.staticTexts["Rincian poin"].exists)

        let assignedPodiumCard = assignedPodiumCards.firstMatch
        XCTAssertTrue(assignedPodiumCard.waitForExistence(timeout: 5))
        XCTAssertTrue(assignedPodiumCard.isHittable)
        assignedPodiumCard.tap()

        XCTAssertTrue(
            element(
                identifier: "coach.leaderboard.score-detail-modal",
                in: app
            )
            .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["Poin langkah"].exists)
        app.navigationBars["Rincian poin"].buttons["Tutup"].tap()

        let assignedRankCard = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "coach.leaderboard.rank."
            )
        ).firstMatch
        for _ in 0..<6
        where !assignedRankCard.waitForExistence(timeout: 1)
            || !assignedRankCard.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(assignedRankCard.waitForExistence(timeout: 5))
        XCTAssertTrue(assignedRankCard.isHittable)
        assignedRankCard.tap()

        XCTAssertTrue(
            element(
                identifier: "coach.leaderboard.score-detail-modal",
                in: app
            )
            .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["Poin langkah"].exists)
        app.navigationBars["Rincian poin"].buttons["Tutup"].tap()

        tabButton(label: "Profil", in: app).tap()
        XCTAssertTrue(
            element(identifier: "coach.profile", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.staticTexts["coach@demo.local"].exists)

        let editProfile = app.buttons["coach.profile.edit"]
        XCTAssertTrue(editProfile.waitForExistence(timeout: 5))
        editProfile.tap()

        XCTAssertTrue(
            app.textFields["coach.profile.editor.name"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.buttons["coach.profile.editor.photo-picker"].exists
        )
        XCTAssertTrue(
            app.textFields["coach.profile.editor.biography"].exists
        )
        XCTAssertTrue(app.staticTexts["Bio publik"].exists)
        XCTAssertTrue(
            app.staticTexts[
                "Nama tampilan, kota, dan bio publik wajib diisi."
            ].exists
        )
        app.buttons["Batal"].tap()
    }

    @MainActor
    func testParticipantLeaderboardDoesNotExposeCoachScoreDetails() throws {
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
            element(identifier: "participant.leaderboard.podium", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertEqual(
            app.buttons.matching(
                NSPredicate(
                    format: "identifier BEGINSWITH %@",
                    "coach.leaderboard.podium."
                )
            ).count,
            0
        )
        XCTAssertEqual(
            app.buttons.matching(
                NSPredicate(
                    format: "identifier BEGINSWITH %@",
                    "coach.leaderboard.rank."
                )
            ).count,
            0
        )
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
    func testCoachDashboardProfileCardSelectsProfileTab() throws {
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

        let profileCard = app.buttons["coach.dashboard.profile"]
        XCTAssertTrue(profileCard.waitForExistence(timeout: 5))
        XCTAssertTrue(profileCard.isHittable)
        XCTAssertTrue(profileCard.label.contains("Selamat datang"))
        XCTAssertTrue(profileCard.label.contains("Coach Raka"))
        XCTAssertTrue(profileCard.label.contains("Coach"))
        XCTAssertTrue(tabButton(label: "Dashboard", in: app).exists)
        XCTAssertTrue(tabButton(label: "Program", in: app).exists)
        XCTAssertTrue(tabButton(label: "Profil", in: app).exists)
        XCTAssertFalse(tabButton(label: "Peserta", in: app).exists)
        XCTAssertFalse(tabButton(label: "Peringkat", in: app).exists)
        profileCard.tap()

        XCTAssertTrue(
            element(identifier: "coach.profile", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(tabButton(label: "Profil", in: app).isSelected)
        XCTAssertFalse(
            app.navigationBars["Profil"].buttons["BackButton"].exists
        )
    }

    @MainActor
    func testCoachDashboardAttentionAndExpiredProgramStatusIsAccurate()
        throws
    {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "coach",
            "-DemoScenario", "coach_review_queue",
            "-SkipDemoLanding"
        ]
        app.launch()

        let participants = app.buttons[
            "coach.dashboard.action.participants"
        ]
        XCTAssertTrue(participants.waitForExistence(timeout: 8))
        XCTAssertEqual(participants.value as? String, "6")
        participants.tap()
        XCTAssertTrue(
            element(identifier: "coach.participants", in: app)
                .waitForExistence(timeout: 8)
        )
        let attention = app.buttons.matching(
            NSPredicate(
                format: "label CONTAINS[c] %@",
                "perlu perhatian"
            )
        ).firstMatch
        XCTAssertTrue(attention.waitForExistence(timeout: 5))
        attention.tap()
        XCTAssertTrue(
            app.navigationBars["Perlu perhatian"]
                .waitForExistence(timeout: 5)
        )
        let attentionSummary = app.staticTexts.matching(
            NSPredicate(
                format: "label CONTAINS %@",
                "peserta perlu ditindaklanjuti"
            )
        ).firstMatch
        XCTAssertTrue(attentionSummary.waitForExistence(timeout: 5))

        let participantCard = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "coach.participant.open."
            )
        ).firstMatch
        XCTAssertTrue(participantCard.waitForExistence(timeout: 5))
        XCTAssertTrue(participantCard.isHittable)
        XCTAssertFalse(participantCard.label.contains("Lihat peserta"))
        participantCard.tap()
        XCTAssertTrue(
            element(identifier: "coach.participant.detail", in: app)
                .waitForExistence(timeout: 5)
        )

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            element(identifier: "coach.participants", in: app)
                .waitForExistence(timeout: 5)
        )

        let back = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()

        let dashboardBack = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(dashboardBack.waitForExistence(timeout: 5))
        dashboardBack.tap()

        let activeProgram = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "coach.dashboard.program."
            )
        ).firstMatch
        XCTAssertTrue(
            app.staticTexts["0, program aktif"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(activeProgram.exists)
    }

    @MainActor
    func testCoachParticipantDynamicLabelsFallbackToIndonesian() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-DemoRole", "coach",
            "-DemoScenario", "coach_review_queue",
            "-SkipDemoLanding"
        ]
        app.launch()

        let participants = app.buttons[
            "coach.dashboard.action.participants"
        ]
        XCTAssertTrue(participants.waitForExistence(timeout: 8))
        participants.tap()

        XCTAssertTrue(
            app.textFields["Cari nama atau kota"]
                .waitForExistence(timeout: 5)
        )
        let filter = app.buttons["Filter dan urutkan"]
        XCTAssertTrue(filter.waitForExistence(timeout: 5))
        filter.tap()

        XCTAssertTrue(
            element(identifier: "coach.participants.filter.sheet", in: app)
                .waitForExistence(timeout: 5)
        )
        let participantReset = app.buttons[
            "coach.participants.filter.reset"
        ]
        let participantApply = app.buttons[
            "coach.participants.filter.apply"
        ]
        XCTAssertTrue(participantReset.waitForExistence(timeout: 5))
        XCTAssertTrue(participantApply.waitForExistence(timeout: 5))
        XCTAssertEqual(
            participantReset.frame.height,
            participantApply.frame.height,
            accuracy: 1
        )
        app.buttons["Tutup"].tap()
        XCTAssertTrue(filter.waitForExistence(timeout: 5))

        let participant = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "coach.participant.open."
            )
        ).firstMatch
        XCTAssertTrue(participant.waitForExistence(timeout: 5))
        XCTAssertFalse(participant.label.contains("coach."))

        let rawKey = app.descendants(matching: .any).matching(
            NSPredicate(
                format: "label CONTAINS %@",
                "coach.participants."
            )
        ).firstMatch
        XCTAssertFalse(rawKey.exists)

        app.navigationBars.buttons.element(boundBy: 0).tap()
        let dashboardParticipants = app.buttons[
            "coach.dashboard.action.participants"
        ]
        XCTAssertTrue(
            dashboardParticipants.waitForExistence(timeout: 5)
        )
        dashboardParticipants.tap()
        let attention = app.buttons.matching(
            NSPredicate(
                format: "label CONTAINS[c] %@",
                "perlu perhatian"
            )
        ).firstMatch
        XCTAssertTrue(attention.waitForExistence(timeout: 5))
        attention.tap()

        let attentionSummary = app.staticTexts.matching(
            NSPredicate(
                format: "label CONTAINS %@",
                "peserta perlu ditindaklanjuti"
            )
        ).firstMatch
        XCTAssertTrue(attentionSummary.waitForExistence(timeout: 5))
        XCTAssertFalse(
            app.descendants(matching: .any).matching(
                NSPredicate(
                    format: "label CONTAINS %@",
                    "coach.participants."
                )
            ).firstMatch.exists
        )
    }

    @MainActor
    func testCoachRecentActivityDefaultsToTodayAndCanRevealHistory()
        throws
    {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-DemoRole", "coach",
            "-DemoScenario", "coach_review_queue",
            "-SkipDemoLanding"
        ]
        app.launch()

        XCTAssertFalse(
            app.buttons["coach.dashboard.action.attention"].exists
        )
        let activity = app.buttons["coach.dashboard.action.activity"]
        XCTAssertTrue(activity.waitForExistence(timeout: 8))
        activity.tap()

        XCTAssertTrue(
            element(identifier: "coach.activity", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.navigationBars["Aktivitas terbaru"]
                .waitForExistence(timeout: 5)
        )
        let filter = app.buttons["coach.activity.filter"]
        XCTAssertTrue(filter.waitForExistence(timeout: 5))
        XCTAssertTrue(filter.value as? String == [
            "Semua program",
            "Semua aktivitas",
            "Hari ini"
        ].joined(separator: " · "))

        let previous = app.buttons["coach.activity.previous"]
        XCTAssertTrue(previous.waitForExistence(timeout: 5))
        previous.tap()

        XCTAssertTrue(
            app.buttons.matching(
                NSPredicate(
                    format: "identifier BEGINSWITH %@",
                    "coach.activity.item."
                )
            ).firstMatch.waitForExistence(timeout: 5)
        )

        filter.tap()
        XCTAssertTrue(
            element(identifier: "coach.activity.filter.sheet", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.buttons["coach.activity.filter.reset"].exists
        )
        XCTAssertTrue(
            app.buttons["coach.activity.filter.apply"].exists
        )
        XCTAssertFalse(
            app.descendants(matching: .any).matching(
                NSPredicate(
                    format: "label CONTAINS %@",
                    "coach.activity."
                )
            ).firstMatch.exists
        )
    }

    @MainActor
    func testAppCopyStaysIndonesianWhenDeviceLanguageIsEnglish() throws {
        let launchCases = [
            (
                role: "participant",
                scenario: "participant_active",
                rootIdentifier: "participant.home",
                tabLabel: "Beranda"
            ),
            (
                role: "coach",
                scenario: "coach_review_queue",
                rootIdentifier: "coach.dashboard",
                tabLabel: "Dashboard"
            ),
            (
                role: "admin",
                scenario: "admin_winner_lock",
                rootIdentifier: "admin.dashboard",
                tabLabel: "Dashboard"
            )
        ]

        for launchCase in launchCases {
            let app = XCUIApplication()
            app.launchArguments = [
                "-AppleLanguages", "(en)",
                "-AppleLocale", "en_US",
                "-DemoRole", launchCase.role,
                "-DemoScenario", launchCase.scenario,
                "-SkipDemoLanding"
            ]
            app.launch()

            XCTAssertTrue(
                element(
                    identifier: launchCase.rootIdentifier,
                    in: app
                ).waitForExistence(timeout: 10),
                "Root \(launchCase.role) tidak tampil."
            )
            XCTAssertTrue(
                tabButton(label: launchCase.tabLabel, in: app)
                    .waitForExistence(timeout: 5),
                "Tab \(launchCase.role) tidak tetap berbahasa Indonesia."
            )
            assertNoVisibleLocalizationKeys(in: app)

            app.terminate()
        }
    }

    @MainActor
    func testParticipantEditsProfileWithoutChangingCoach() throws {
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

        XCTAssertFalse(
            app.buttons["participant.profile.change-coach"].exists
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
            tabButton(label: "Dashboard", in: app)
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

        let availableFilter = app.segmentedControls.buttons["Tersedia"]
        XCTAssertTrue(availableFilter.waitForExistence(timeout: 5))
        availableFilter.tap()

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

        let openReview = app.buttons["coach.dashboard.action.review"]
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
        XCTAssertTrue(app.staticTexts["Bukti demo lokal"].exists)
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
            element(identifier: "coach.review.evidence-list", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertFalse(
            element(identifier: "coach.review.result", in: app).exists
        )
        XCTAssertFalse(app.staticTexts["Poin lokal: 210 menjadi 220"].exists)

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["coach.dashboard.action.leaderboard"].tap()
        XCTAssertTrue(
            element(identifier: "coach.leaderboard", in: app)
                .waitForExistence(timeout: 8)
        )
        let leaderboardBack = app.navigationBars.buttons.element(
            boundBy: 0
        )
        XCTAssertTrue(leaderboardBack.waitForExistence(timeout: 5))
        leaderboardBack.tap()
        XCTAssertTrue(
            element(identifier: "coach.dashboard", in: app)
                .waitForExistence(timeout: 5)
        )
        tabButton(label: "Profil", in: app).tap()
        let openQR = app.buttons["coach.profile.open-qr"]
        for _ in 0..<4
        where !openQR.waitForExistence(timeout: 1)
            || !openQR.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(openQR.waitForExistence(timeout: 8))
        openQR.tap()

        XCTAssertTrue(
            app.staticTexts["QR pendaftaran saya"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.buttons["coach.identifier.share"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.staticTexts["COACH-RAKA-7K9Q"].exists)
        app.buttons["coach.identifier.share"].tap()
        XCTAssertTrue(
            app.otherElements["ActivityListView"]
                .waitForExistence(timeout: 5)
        )
        let closeShare = app.buttons["header.closeButton"]
        XCTAssertTrue(closeShare.waitForExistence(timeout: 5))
        closeShare.tap()
        tabButton(label: "Dashboard", in: app).tap()
        let participantsAction = app.buttons[
            "coach.dashboard.action.participants"
        ]
        XCTAssertTrue(participantsAction.waitForExistence(timeout: 5))
        participantsAction.tap()
        XCTAssertTrue(
            element(identifier: "coach.participants", in: app)
                .waitForExistence(timeout: 5)
        )
        let participant = app.buttons[
            "coach.participant.open."
                + "20000000-0000-0000-0000-000000000001"
        ]
        XCTAssertTrue(participant.waitForExistence(timeout: 5))
        if !participant.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(participant.isHittable)
        participant.tap()
        XCTAssertTrue(
            element(identifier: "coach.participant.detail", in: app)
                .waitForExistence(timeout: 5)
        )
        let dailyWeighIn = app.descendants(matching: .any)
            .matching(identifier: "coach.participant.weight-history")
            .matching(
                NSPredicate(
                    format: "label CONTAINS %@ AND label CONTAINS %@",
                    "Timbang harian",
                    "78,1 kg"
                )
            )
            .firstMatch
        XCTAssertTrue(dailyWeighIn.waitForExistence(timeout: 5))
    }

    @MainActor
    func testCoachParticipantFilterFindsAndKeepsHistoryProgram() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-DemoRole", "coach",
            "-DemoScenario", "coach_review_queue",
            "-SkipDemoLanding"
        ]
        app.launch()

        let participants = app.buttons[
            "coach.dashboard.action.participants"
        ]
        XCTAssertTrue(participants.waitForExistence(timeout: 8))
        participants.tap()

        let filter = app.buttons["Filter dan urutkan"]
        XCTAssertTrue(filter.waitForExistence(timeout: 5))
        filter.tap()

        let history = app.buttons[
            "coach.participants.filter.option.program.history"
        ]
        XCTAssertTrue(history.waitForExistence(timeout: 5))
        history.tap()

        XCTAssertTrue(
            element(identifier: "app.filter.program-history", in: app)
                .waitForExistence(timeout: 5)
        )
        let search = app.searchFields["Cari program selesai"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Transformasi")

        let historyProgramID =
            "10000000-0000-0000-0000-000000000001"
        let historyProgram = app.buttons[
            "coach.participants.filter.option.program.history."
                + historyProgramID
        ]
        XCTAssertTrue(historyProgram.waitForExistence(timeout: 5))
        historyProgram.tap()

        let selectedProgram = element(
            identifier:
                "coach.participants.filter.option.program."
                    + historyProgramID,
            in: app
        )
        XCTAssertTrue(selectedProgram.waitForExistence(timeout: 5))

        let apply = app.buttons["coach.participants.filter.apply"]
        XCTAssertTrue(apply.waitForExistence(timeout: 5))
        apply.tap()

        XCTAssertTrue(filter.waitForExistence(timeout: 5))
        XCTAssertTrue(
            (filter.value as? String)?.contains("Transformasi 7 hari")
                == true
        )

        filter.tap()
        XCTAssertTrue(selectedProgram.waitForExistence(timeout: 5))
    }

    @MainActor
    func testLeadingEdgeSwipePopsCustomBackDestinations() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "coach",
            "-DemoScenario", "coach_review_queue",
            "-SkipDemoLanding"
        ]
        app.launch()

        let openParticipants = app.buttons[
            "coach.dashboard.action.participants"
        ]
        XCTAssertTrue(openParticipants.waitForExistence(timeout: 8))
        openParticipants.tap()

        let participants = element(
            identifier: "coach.participants",
            in: app
        )
        XCTAssertTrue(participants.waitForExistence(timeout: 5))

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

        performLeadingEdgeBackSwipe(in: app)
        XCTAssertTrue(participants.waitForExistence(timeout: 5))

        performLeadingEdgeBackSwipe(in: app)
        XCTAssertTrue(openParticipants.waitForExistence(timeout: 5))
        XCTAssertFalse(participants.exists)

        performLeadingEdgeBackSwipe(in: app)
        XCTAssertTrue(openParticipants.waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["navigation.back"].exists)
    }

    @MainActor
    func testCoachViewsAutomaticEvidenceAndSavesOptionalRating() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-DemoRole", "coach",
            "-DemoScenario", "coach_review_queue",
            "-SkipDemoLanding"
        ]
        app.launch()

        let openReview = app.buttons["coach.dashboard.action.review"]
        XCTAssertTrue(openReview.waitForExistence(timeout: 8))
        openReview.tap()
        XCTAssertTrue(
            element(identifier: "coach.review.queue", in: app)
                .waitForExistence(timeout: 8)
        )

        let scopeControl = element(
            identifier: "coach.review.scope",
            in: app
        )
        let evidenceList = app.scrollViews["coach.review.evidence-list"]
        let fixedControls = element(
            identifier: "coach.review.fixed-controls",
            in: app
        )
        let filterButton = app.buttons["coach.review.filter.open"]
        XCTAssertTrue(scopeControl.waitForExistence(timeout: 5))
        XCTAssertTrue(evidenceList.waitForExistence(timeout: 5))
        XCTAssertTrue(fixedControls.waitForExistence(timeout: 5))
        XCTAssertTrue(filterButton.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(
            filterButton.frame.height,
            scopeControl.frame.height
        )

        let evidencePageFrame = element(
            identifier: "coach.review.queue",
            in: app
        ).frame

        let fixedControlsFrame = fixedControls.frame
        evidenceList.swipeUp()
        XCTAssertEqual(fixedControls.frame, fixedControlsFrame)
        XCTAssertEqual(
            element(identifier: "coach.review.queue", in: app).frame,
            evidencePageFrame
        )

        let allEvidence = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Semua bukti"))
            .firstMatch
        XCTAssertTrue(allEvidence.waitForExistence(timeout: 5))
        allEvidence.tap()

        filterButton.tap()
        XCTAssertTrue(
            element(identifier: "coach.review.filter.sheet", in: app)
                .waitForExistence(timeout: 5)
        )
        let resetFilter = app.buttons["coach.review.filter.reset"]
        let applyFilter = app.buttons["coach.review.filter.apply"]
        XCTAssertTrue(resetFilter.waitForExistence(timeout: 5))
        XCTAssertTrue(applyFilter.waitForExistence(timeout: 5))
        XCTAssertEqual(
            resetFilter.frame.height,
            applyFilter.frame.height,
            accuracy: 1
        )
        let automaticStatus = element(
            identifier: "coach.review.filter.option.status.automatic",
            in: app
        )
        XCTAssertTrue(automaticStatus.waitForExistence(timeout: 5))
        automaticStatus.tap()

        applyFilter.tap()
        XCTAssertTrue(
            filterButton.waitForExistence(timeout: 5)
        )

        let automaticEvidence = app.buttons[
            "coach.review.open.50000000-0000-0000-0000-000000000007"
        ]
        for _ in 0..<4
        where !automaticEvidence.waitForExistence(timeout: 1)
            || !automaticEvidence.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(automaticEvidence.waitForExistence(timeout: 5))
        XCTAssertTrue(automaticEvidence.label.contains("Poin otomatis"))
        XCTAssertFalse(automaticEvidence.label.contains("poin diberikan"))
        automaticEvidence.tap()

        XCTAssertTrue(
            app.staticTexts["Poin diberikan otomatis"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["Hari 3"].exists)
        XCTAssertTrue(
            app.staticTexts[
                "5 poin sudah diberikan saat peserta mengirim bukti."
            ].exists
        )
        XCTAssertFalse(app.buttons["coach.review.approve"].exists)
        XCTAssertFalse(app.buttons["coach.review.reject"].exists)

        let fourStars = app.buttons["coach.review.rating.4"]
        XCTAssertTrue(fourStars.waitForExistence(timeout: 5))
        fourStars.tap()

        let saveRating = app.buttons["coach.review.rating.save"]
        XCTAssertTrue(saveRating.waitForExistence(timeout: 5))
        XCTAssertTrue(saveRating.isEnabled)
        saveRating.tap()

        XCTAssertTrue(
            element(identifier: "coach.review.queue", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.staticTexts["4/5"].waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testCoachRejectionUsesSingleSheetNavigationFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "coach",
            "-DemoScenario", "coach_review_queue",
            "-SkipDemoLanding"
        ]
        app.launch()

        let openReview = app.buttons["coach.dashboard.action.review"]
        XCTAssertTrue(openReview.waitForExistence(timeout: 8))
        openReview.tap()

        let manualEvidence = app.buttons[
            "coach.review.open.50000000-0000-0000-0000-000000000006"
        ]
        XCTAssertTrue(manualEvidence.waitForExistence(timeout: 8))
        manualEvidence.tap()

        let reject = app.buttons["coach.review.reject"]
        XCTAssertTrue(reject.waitForExistence(timeout: 5))
        let sheetCountBeforeRejection = app.sheets.count
        reject.tap()

        let cancel = app.buttons["coach.review.rejection.cancel"]
        let submit = app.buttons["coach.review.rejection.submit"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        XCTAssertEqual(app.sheets.count, sheetCountBeforeRejection)
        XCTAssertFalse(submit.isEnabled)
        XCTAssertGreaterThan(cancel.frame.width, 120)
        XCTAssertGreaterThan(submit.frame.width, 120)
        XCTAssertEqual(
            cancel.frame.height,
            submit.frame.height,
            accuracy: 1
        )

        cancel.tap()
        XCTAssertTrue(reject.waitForExistence(timeout: 5))

        reject.tap()
        let reason = app.textViews[
            "coach.review.rejection-reason"
        ]
        XCTAssertTrue(reason.waitForExistence(timeout: 5))
        reason.tap()
        reason.typeText("Bukti belum sesuai petunjuk.")

        let submitRejection = app.buttons[
            "coach.review.rejection.submit"
        ]
        XCTAssertTrue(submitRejection.isEnabled)
        submitRejection.tap()

        XCTAssertTrue(
            element(identifier: "coach.review.evidence-list", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertFalse(
            element(identifier: "coach.review.result", in: app).exists
        )
        XCTAssertFalse(app.staticTexts["Bukti ditolak"].exists)
    }

    @MainActor
    func testCoachCanJoinProgramThroughSharedParticipantFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "coach",
            "-DemoScenario", "coach_review_queue",
            "-SkipDemoLanding"
        ]
        app.launch()

        let programAction = app.buttons[
            "coach.dashboard.action.program"
        ]
        XCTAssertTrue(programAction.waitForExistence(timeout: 8))
        programAction.tap()

        let programTab = tabButton(label: "Program", in: app)
        XCTAssertTrue(programTab.waitForExistence(timeout: 8))
        XCTAssertTrue(programTab.isSelected)

        XCTAssertTrue(
            element(identifier: "participant.program.catalog", in: app)
                .waitForExistence(timeout: 8)
        )
        let availableFilter = app.segmentedControls.buttons["Tersedia"]
        XCTAssertTrue(availableFilter.waitForExistence(timeout: 5))
        availableFilter.tap()

        let availableProgram = app.buttons[
            "participant.program.select."
                + "10000000-0000-0000-0000-000000000001"
        ]
        XCTAssertTrue(availableProgram.waitForExistence(timeout: 5))
        availableProgram.tap()

        let programIdentity = element(
            identifier: "participant.program.offer.identity",
            in: app
        )
        XCTAssertTrue(programIdentity.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(
            programIdentity.frame.width,
            app.windows.firstMatch.frame.width * 0.85
        )

        let joinProgram = app.buttons["participant.program.offer.join"]
        XCTAssertTrue(joinProgram.waitForExistence(timeout: 5))
        joinProgram.tap()
        XCTAssertTrue(
            app.navigationBars["Gabung program"]
                .waitForExistence(timeout: 5)
        )

        app.buttons["participant.join.scan"].tap()
        let useDemoQR = app.buttons["participant.qr.use-demo"]
        XCTAssertTrue(useDemoQR.waitForExistence(timeout: 5))
        useDemoQR.tap()

        let confirmCoach = app.buttons["participant.join.confirm-coach"]
        XCTAssertTrue(confirmCoach.waitForExistence(timeout: 5))
        confirmCoach.tap()

        let payment = app.buttons["participant.payment.demo"]
        XCTAssertTrue(payment.waitForExistence(timeout: 5))
        payment.tap()

        let completed = app.buttons["participant.join.completed"]
        XCTAssertTrue(completed.waitForExistence(timeout: 8))
        completed.tap()
        XCTAssertTrue(
            element(identifier: "participant.program.detail", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(programTab.isSelected)
    }

    @MainActor
    func testAdminCreatesDraftAddsDayStepPreviewsAndPublishes() throws {
        let app = launchAdmin(
            language: "en",
            locale: "en_US"
        )

        tabButton(label: "Program", in: app).tap()
        XCTAssertTrue(
            element(identifier: "admin.program.create", in: app)
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

        XCTAssertTrue(
            app.buttons["admin.program.editor.open.settings"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.buttons["admin.program.editor.open.content"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.buttons["admin.program.editor.open.review"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.buttons["Kelola program"].exists)
        XCTAssertFalse(app.buttons["Atur program"].exists)

        app.buttons["admin.program.editor.open.settings"].tap()
        XCTAssertTrue(
            element(identifier: "admin.program.settings-hub", in: app)
                .waitForExistence(timeout: 5)
        )
        app.buttons["admin.program.editor.open.info"].tap()
        XCTAssertTrue(
            app.buttons["admin.program.cover.picker"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.staticTexts["Jenis cover"].exists)
        XCTAssertFalse(
            app.textFields["Referensi gambar lokal"].exists
        )
        assertNoVisibleLocalizationKeys(in: app)
        app.buttons["navigation.back"].tap()
        app.buttons["admin.program.editor.open.schedule"].tap()
        let registrationDeadlineToggle = app.switches[
            "admin.program.registration-deadline-toggle"
        ]
        XCTAssertTrue(
            registrationDeadlineToggle.waitForExistence(timeout: 5)
        )
        for _ in 0..<4 where !registrationDeadlineToggle.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(registrationDeadlineToggle.isHittable)
        registrationDeadlineToggle.coordinate(
            withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)
        ).tap()
        app.swipeUp()
        XCTAssertEqual(
            app.switches[
                "admin.program.registration-deadline-toggle"
            ].value as? String,
            "1"
        )
        XCTAssertTrue(
            app.staticTexts[
                "Setelah waktu ini Peserta tidak dapat mendaftar sendiri. "
                    + "Admin tetap dapat mendaftarkan secara manual."
            ].waitForExistence(timeout: 5)
        )
        assertNoVisibleLocalizationKeys(in: app)
        app.buttons["navigation.back"].tap()
        app.buttons["admin.program.editor.open.rules"].tap()
        XCTAssertTrue(
            app.staticTexts["Poin langkah"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.staticTexts["Poin penurunan berat badan"].exists
        )
        assertNoVisibleLocalizationKeys(in: app)
        app.buttons["navigation.back"].tap()
        app.buttons["navigation.back"].tap()

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
        XCTAssertTrue(
            app.buttons["Timbang harian"].waitForExistence(timeout: 5)
        )
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

        app.buttons["admin.program.editor.open.review"].tap()
        XCTAssertTrue(
            element(identifier: "admin.program.review-publish", in: app)
                .waitForExistence(timeout: 5)
        )

        app.buttons["admin.program.editor.open.preview"].tap()
        XCTAssertTrue(
            element(identifier: "admin.editor.preview", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.buttons["Peserta"].exists)
        XCTAssertTrue(app.buttons["Coach"].exists)
        XCTAssertFalse(app.staticTexts["Perangkat kecil"].exists)
        XCTAssertFalse(app.staticTexts["Perangkat besar"].exists)
        let previewRolePicker = element(
            identifier: "admin.program.preview.role-picker",
            in: app
        )
        XCTAssertTrue(previewRolePicker.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(previewRolePicker.frame.height, 48)
        let pinnedRolePickerY = previewRolePicker.frame.minY
        app.swipeUp()
        XCTAssertTrue(previewRolePicker.isHittable)
        XCTAssertEqual(
            previewRolePicker.frame.minY,
            pinnedRolePickerY,
            accuracy: 2
        )
        XCTAssertTrue(
            app.staticTexts[
                "Tampilan ini sama dengan yang dilihat Peserta."
            ].exists
        )

        app.buttons["Coach"].tap()
        XCTAssertTrue(
            element(
                identifier:
                    "admin.program.preview.monitored-participant",
                in: app
            )
            .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.staticTexts[
                "Tampilan ini sama dengan yang dilihat Coach."
            ].exists
        )
        XCTAssertTrue(app.staticTexts["Ayu Lestari"].exists)
        app.buttons["navigation.back"].tap()

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
    func testAdminSwipeDeletesDayWithoutConfirmation() {
        let app = launchAdmin()

        tabButton(label: "Program", in: app).tap()
        XCTAssertTrue(
            app.buttons["admin.program.create"]
                .waitForExistence(timeout: 8)
        )
        app.buttons["admin.program.create"].tap()
        XCTAssertTrue(
            app.buttons["admin.program.editor.open.content"]
                .waitForExistence(timeout: 8)
        )
        app.buttons["admin.program.editor.open.content"].tap()

        let dayRow = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "admin.program.day.open."
            )
        ).firstMatch
        XCTAssertTrue(dayRow.waitForExistence(timeout: 5))

        let swipeStart = dayRow.coordinate(
            withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)
        )
        let swipeEnd = dayRow.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
        )
        swipeStart.press(forDuration: 0.05, thenDragTo: swipeEnd)

        let deleteAction = app.buttons["admin.program.day.delete"]
        XCTAssertTrue(deleteAction.waitForExistence(timeout: 5))
        XCTAssertTrue(deleteAction.isHittable)
        XCTAssertFalse(app.staticTexts["Hapus"].exists)
        deleteAction.tap()

        XCTAssertFalse(app.staticTexts["Hapus hari program?"].exists)
        XCTAssertTrue(
            app.staticTexts["Belum ada hari"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(dayRow.exists)

        let addDay = app.buttons["admin.program.day.add"]
        XCTAssertTrue(addDay.waitForExistence(timeout: 5))
        addDay.tap()

        let replacementDayRow = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "admin.program.day.open."
            )
        ).firstMatch
        XCTAssertTrue(replacementDayRow.waitForExistence(timeout: 5))
        XCTAssertTrue(replacementDayRow.isHittable)
        XCTAssertFalse(
            deleteAction.exists,
            "Hari baru tidak boleh mewarisi posisi swipe hari yang dihapus."
        )
    }

    @MainActor
    func testAdminCopiesDayContentToAnotherDay() {
        let app = launchAdmin(language: "en", locale: "en_US")

        tabButton(label: "Program", in: app).tap()
        XCTAssertTrue(
            app.buttons["admin.program.create"]
                .waitForExistence(timeout: 8)
        )
        app.buttons["admin.program.create"].tap()
        XCTAssertTrue(
            app.buttons["admin.program.editor.open.content"]
                .waitForExistence(timeout: 8)
        )
        app.buttons["admin.program.editor.open.content"].tap()

        let addDay = app.buttons["admin.program.day.add"]
        XCTAssertTrue(addDay.waitForExistence(timeout: 5))
        addDay.tap()

        let dayRows = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "admin.program.day.open."
            )
        )
        XCTAssertEqual(dayRows.count, 2)
        dayRows.element(boundBy: 0).tap()

        let addStep = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "admin.editor.add-step."
            )
        ).firstMatch
        XCTAssertTrue(addStep.waitForExistence(timeout: 5))
        addStep.tap()
        XCTAssertTrue(app.buttons["Artikel"].waitForExistence(timeout: 5))
        app.buttons["Artikel"].tap()

        let createdStep = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "admin.program.step.open."
            )
        ).firstMatch
        XCTAssertTrue(createdStep.waitForExistence(timeout: 5))

        let copyContent = app.buttons[
            "admin.program.day.copy-content"
        ]
        XCTAssertTrue(copyContent.waitForExistence(timeout: 5))
        XCTAssertTrue(copyContent.isEnabled)
        copyContent.tap()

        XCTAssertTrue(
            app.otherElements["admin.program.copy-content.sheet"]
                .waitForExistence(timeout: 5)
        )
        let copyTarget = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                "admin.program.copy-content.target."
            )
        ).firstMatch
        XCTAssertTrue(copyTarget.waitForExistence(timeout: 5))
        copyTarget.tap()

        let confirmCopy = app.buttons[
            "admin.program.copy-content.confirm"
        ]
        XCTAssertTrue(confirmCopy.isEnabled)
        confirmCopy.tap()
        XCTAssertFalse(
            app.otherElements["admin.program.copy-content.sheet"]
                .waitForExistence(timeout: 2)
        )

        app.buttons["navigation.back"].tap()

        let copiedTarget = app.buttons.matching(
            NSPredicate(
                format:
                    "identifier BEGINSWITH %@ AND label CONTAINS %@",
                "admin.program.day.open.",
                "Hari ke-2"
            )
        ).firstMatch
        XCTAssertTrue(copiedTarget.waitForExistence(timeout: 5))
        XCTAssertTrue(copiedTarget.label.contains("1 langkah"))
    }

    @MainActor
    func testAdminProgramHeaderStaysFixedWhileCardsScroll() throws {
        let app = launchAdmin()

        tabButton(label: "Program", in: app).tap()
        XCTAssertTrue(
            element(identifier: "admin.program.create", in: app)
                .waitForExistence(timeout: 8)
        )

        app.buttons["Filter status"].tap()
        let allStatuses = app.buttons["Semua status"]
        XCTAssertTrue(allStatuses.waitForExistence(timeout: 5))
        allStatuses.tap()

        let search = element(
            identifier: "admin.program.search",
            in: app
        )
        let cardScroll = app.scrollViews.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        XCTAssertTrue(cardScroll.waitForExistence(timeout: 5))

        let initialSearchFrame = search.frame
        let createButton = app.buttons["admin.program.create"]
        let initialCreateButtonFrame = createButton.frame
        cardScroll.swipeUp()

        XCTAssertEqual(
            search.frame.minY,
            initialSearchFrame.minY,
            accuracy: 1
        )
        XCTAssertEqual(
            createButton.frame.minY,
            initialCreateButtonFrame.minY,
            accuracy: 1
        )
        XCTAssertTrue(createButton.isHittable)
    }

    @MainActor
    func testPublishedAdminProgramIsReadOnlyAndDuplicatesAsDraft() throws {
        let app = launchAdmin()

        tabButton(label: "Program", in: app).tap()
        XCTAssertTrue(
            element(identifier: "admin.program.create", in: app)
                .waitForExistence(timeout: 8)
        )

        app.buttons["Filter status"].tap()
        let activeFilter = app.buttons["Aktif"]
        XCTAssertTrue(activeFilter.waitForExistence(timeout: 5))
        activeFilter.tap()

        let activeProgram = app.buttons[
            "admin.program.open."
                + "10000000-0000-0000-0000-000000000001"
        ]
        XCTAssertTrue(activeProgram.waitForExistence(timeout: 5))
        activeProgram.tap()

        XCTAssertTrue(
            app.buttons[
                "admin.program.editor.open.readonly-settings"
            ].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.buttons[
                "admin.program.editor.open.readonly-content"
            ].exists
        )
        XCTAssertTrue(
            app.buttons[
                "admin.program.editor.open.publication-status"
            ].exists
        )
        XCTAssertFalse(app.buttons["admin.editor.save"].exists)
        XCTAssertFalse(app.buttons["Atur program"].exists)
        XCTAssertFalse(app.buttons["Kelola program"].exists)

        let duplicate = app.buttons[
            "admin.program.duplicate-as-draft"
        ]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5))
        duplicate.tap()

        XCTAssertTrue(
            app.buttons["admin.editor.save"].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.buttons["admin.program.editor.open.settings"].exists
        )
        XCTAssertTrue(
            app.buttons["admin.program.editor.open.content"].exists
        )
        XCTAssertTrue(
            app.buttons["admin.program.editor.open.review"].exists
        )
    }

    @MainActor
    func testPublishedAdminProgramRequiresArchiveConfirmation() throws {
        let app = launchAdmin()

        tabButton(label: "Program", in: app).tap()
        app.buttons["Filter status"].tap()
        let activeFilter = app.buttons["Aktif"]
        XCTAssertTrue(activeFilter.waitForExistence(timeout: 5))
        activeFilter.tap()

        let activeProgram = app.buttons[
            "admin.program.open."
                + "10000000-0000-0000-0000-000000000001"
        ]
        XCTAssertTrue(activeProgram.waitForExistence(timeout: 5))
        activeProgram.tap()

        let archive = app.buttons["admin.program.archive"]
        XCTAssertTrue(archive.waitForExistence(timeout: 5))
        archive.tap()

        XCTAssertTrue(
            app.staticTexts["Arsipkan program?"]
                .waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testAdminDashboardUsesUniqueQuickActions() throws {
        let app = launchAdmin()
        tabButton(label: "Dashboard", in: app).tap()

        XCTAssertTrue(
            element(identifier: "admin.dashboard", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            element(
                identifier: "admin.dashboard.attention.reviews",
                in: app
            ).waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.buttons["admin.dashboard.action.createProgram"]
                .waitForExistence(timeout: 5)
        )
        let addPoster = app.buttons[
            "admin.dashboard.action.addWinnerPoster"
        ]
        XCTAssertTrue(addPoster.waitForExistence(timeout: 5))

        XCTAssertFalse(app.buttons["Kelola program"].exists)
        XCTAssertFalse(app.buttons["Kelola orang"].exists)

        addPoster.tap()
        XCTAssertTrue(
            app.buttons["admin.content.poster-picker"]
                .waitForExistence(timeout: 5)
        )
        app.buttons["Batal"].tap()

        let coachApprovals = app.buttons[
            "admin.dashboard.attention.coachApprovals"
        ]
        XCTAssertTrue(coachApprovals.waitForExistence(timeout: 5))
        coachApprovals.tap()
        XCTAssertTrue(
            element(identifier: "admin.people", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.staticTexts["Menampilkan persetujuan Coach tertunda."]
                .waitForExistence(timeout: 5)
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

        let roleFilter = app.segmentedControls[
            "admin.people.role-filter"
        ]
        XCTAssertTrue(roleFilter.waitForExistence(timeout: 5))
        let firstParticipant = app.buttons[
            "admin.people.open."
                + "00000000-0000-0000-0000-000000000001"
        ]
        XCTAssertTrue(firstParticipant.waitForExistence(timeout: 5))
        XCTAssertLessThan(
            firstParticipant.frame.minY - roleFilter.frame.maxY,
            28
        )

        XCTAssertTrue(
            app.segmentedControls.buttons["Peserta"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.segmentedControls.buttons["Coach"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.segmentedControls.buttons["Admin"]
                .waitForExistence(timeout: 5)
        )

        let applicant = app.buttons[
            "admin.people.open."
                + "00000000-0000-0000-0000-000000000105"
        ]
        for _ in 0..<4 where !applicant.exists {
            app.swipeUp()
        }
        XCTAssertTrue(applicant.waitForExistence(timeout: 5))
        applicant.tap()

        XCTAssertTrue(
            element(
                identifier: "admin.coach-application.detail",
                in: app
            ).waitForExistence(timeout: 5)
        )
        let approve = app.buttons["admin.coach-application.approve"]
        for _ in 0..<4 where !approve.exists || !approve.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(approve.waitForExistence(timeout: 5))
        XCTAssertTrue(approve.isEnabled)
        approve.tap()
        let confirmApproval = app.buttons
            .matching(
                identifier: "admin.coach-application.confirm-approve"
            )
            .firstMatch
        XCTAssertTrue(
            confirmApproval.waitForExistence(timeout: 5)
        )
        confirmApproval.tap()
        XCTAssertTrue(
            element(identifier: "admin.people", in: app)
                .waitForExistence(timeout: 8)
        )

        let participantSegment = app.segmentedControls.buttons["Peserta"]
        XCTAssertTrue(participantSegment.waitForExistence(timeout: 5))
        participantSegment.tap()

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
        for _ in 0..<5 where !reason.exists || !reason.isHittable {
            app.swipeUp()
        }
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
    func testAdminPersonDetailsMatchRoleProfiles() throws {
        let app = launchAdmin()
        tabButton(label: "Orang", in: app).tap()

        app.buttons[
            "admin.people.open."
                + "00000000-0000-0000-0000-000000000001"
        ].tap()
        XCTAssertTrue(
            app.navigationBars["Profil peserta"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            element(identifier: "admin.people.detail.phone", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            element(
                identifier: "admin.people.detail.participant-coach",
                in: app
            )
            .waitForExistence(timeout: 5)
        )
        app.buttons["Tutup"].tap()

        app.segmentedControls.buttons["Coach"].tap()
        app.buttons[
            "admin.people.open."
                + "00000000-0000-0000-0000-000000000102"
        ].tap()
        XCTAssertTrue(
            app.navigationBars["Profil Coach"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            element(
                identifier: "admin.people.detail.biography",
                in: app
            )
            .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            element(
                identifier: "admin.people.detail.coach-status",
                in: app
            )
            .waitForExistence(timeout: 5)
        )
        app.buttons["Tutup"].tap()

        app.segmentedControls.buttons["Admin"].tap()
        app.buttons[
            "admin.people.open."
                + "00000000-0000-0000-0000-000000000201"
        ].tap()
        XCTAssertTrue(
            app.navigationBars["Profil Admin"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            element(identifier: "admin.people.detail.email", in: app)
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(
            element(
                identifier: "admin.people.detail.biography",
                in: app
            ).exists
        )
    }

    @MainActor
    func testAdminPosterEditorRequiresPhotoSelection() throws {
        let app = launchAdmin()
        tabButton(label: "Konten", in: app).tap()
        XCTAssertTrue(
            element(identifier: "admin.content.create-banner", in: app)
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
    func testAdminContentHeaderStaysFixedWhilePostersScroll() throws {
        let app = launchAdmin()
        tabButton(label: "Konten", in: app).tap()

        let title = element(
            identifier: "admin.content.title",
            in: app
        )
        let createPoster = app.buttons[
            "admin.content.create-banner"
        ]
        let galleryInstruction = element(
            identifier: "admin.content.gallery-instruction",
            in: app
        )
        let posterScroll = app.scrollViews.firstMatch

        XCTAssertTrue(title.waitForExistence(timeout: 8))
        XCTAssertTrue(createPoster.waitForExistence(timeout: 8))
        XCTAssertTrue(galleryInstruction.waitForExistence(timeout: 5))
        XCTAssertTrue(posterScroll.waitForExistence(timeout: 5))

        let initialTitleFrame = title.frame
        let initialCreatePosterFrame = createPoster.frame
        let initialGalleryInstructionFrame = galleryInstruction.frame
        for _ in 0..<3 {
            posterScroll.swipeUp()
        }
        for _ in 0..<3 {
            posterScroll.swipeDown()
        }

        XCTAssertEqual(
            title.frame.minY,
            initialTitleFrame.minY,
            accuracy: 1
        )
        XCTAssertEqual(
            createPoster.frame.minY,
            initialCreatePosterFrame.minY,
            accuracy: 1
        )
        XCTAssertEqual(
            galleryInstruction.frame.minY,
            initialGalleryInstructionFrame.minY,
            accuracy: 1
        )
        XCTAssertTrue(createPoster.isHittable)
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
    func testRoleSwitchDefaultsAdminToDashboard() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID"
        ]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["root.title"].waitForExistence(timeout: 5)
        )
        app.buttons["Admin"].tap()

        let scenarioPicker = app.buttons["root.scenario-picker"]
        XCTAssertTrue(scenarioPicker.waitForExistence(timeout: 5))
        XCTAssertTrue(scenarioPicker.label.contains("Dashboard Admin"))

        let enterDemo = app.buttons["root.enter-demo"]
        let ready = NSPredicate(format: "enabled == true")
        expectation(for: ready, evaluatedWith: enterDemo)
        waitForExpectations(timeout: 5)
        enterDemo.tap()

        XCTAssertTrue(
            element(identifier: "admin.dashboard", in: app)
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(tabButton(label: "Dashboard", in: app).isSelected)
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
    func testCoachLoggedOutStateCanResumeLocalDemo() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-DemoRole", "coach",
            "-DemoScenario", "logged_out",
            "-SkipDemoLanding"
        ]
        app.launch()

        XCTAssertTrue(
            element(identifier: "state.logged-out", in: app)
                .waitForExistence(timeout: 8)
        )
        let resume = app.buttons["Masuk kembali ke demo"]
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        XCTAssertTrue(resume.isEnabled)
        resume.tap()

        XCTAssertTrue(
            element(identifier: "coach.dashboard", in: app)
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
    func testCoachIdentifierAndAdminWinnerScenariosRemainNavigable() throws {
        let coachApp = XCUIApplication()
        coachApp.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID",
            "-DemoRole", "coach",
            "-DemoScenario", "coach_identifier",
            "-SkipDemoLanding"
        ]
        coachApp.launch()
        XCTAssertTrue(
            element(identifier: "coach.identifier", in: coachApp)
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
            element(identifier: "admin.dashboard", in: adminApp)
                .waitForExistence(timeout: 10)
        )
        XCTAssertFalse(adminApp.buttons["Kelola pemenang"].exists)
    }

    @MainActor
    private func launchAdmin(
        language: String = "id",
        locale: String = "id_ID"
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
            "-DemoRole", "admin",
            "-DemoScenario", "admin_draft_editor",
            "-SkipDemoLanding"
        ]
        app.launch()
        XCTAssertTrue(
            tabButton(label: "Dashboard", in: app)
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
    private func assertNoVisibleLocalizationKeys(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let localizationKeyPrefixes = [
            "app.",
            "root.",
            "tab.",
            "participant.",
            "coach.",
            "admin.",
            "state.",
            "action.",
            "metric.",
            "program.",
            "leaderboard.",
            "configuration."
        ]

        for prefix in localizationKeyPrefixes {
            let rawKey = app.descendants(matching: .any).matching(
                NSPredicate(format: "label CONTAINS %@", prefix)
            ).firstMatch
            XCTAssertFalse(
                rawKey.exists,
                "Localization key \(prefix) terlihat: \(rawKey.label)",
                file: file,
                line: line
            )
        }
    }
}
