import XCTest

final class MSCBodyTransformationUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)",
            "-AppleLocale", "id_ID"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["root.title"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Layar awal demo lokal"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
