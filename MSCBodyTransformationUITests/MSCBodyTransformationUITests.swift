import XCTest

final class MSCBodyTransformationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLocalDemoLaunchesAndOpensParticipantPlaceholder() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["root.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["root.local-mode"].exists)

        let enterDemoButton = app.buttons["root.enter-demo"]
        XCTAssertTrue(enterDemoButton.exists)
        enterDemoButton.tap()

        XCTAssertTrue(app.staticTexts["demo.role"].waitForExistence(timeout: 5))
    }
}
