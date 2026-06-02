import XCTest

final class InflamendUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testProfileUserDataExportSheetSmoke() {
        let app = openSeededProfile()

        tapWhenVisible(app.buttons["profile-export-data-row"], in: app)

        XCTAssertTrue(app.staticTexts["user-data-export-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["user-data-export-share-button"].exists)
    }

    @MainActor
    func testProfileDestructiveActionsRequireConfirmation() {
        let app = openSeededProfile()

        tapWhenVisible(app.buttons["profile-delete-ai-history-row"], in: app)
        XCTAssertTrue(app.staticTexts["Delete AI history?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["2 messages"].exists)
        app.buttons.matching(identifier: "profile-confirm-delete-ai-history-button").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["1 messages"].waitForExistence(timeout: 5))

        tapWhenVisible(app.buttons["profile-delete-data-account-row"], in: app)
        XCTAssertTrue(app.staticTexts["Request data/account deletion?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(identifier: "profile-confirm-delete-data-account-button").firstMatch.exists)
    }

    @MainActor
    private func openSeededProfile() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--inflamend-reset-state",
            "--inflamend-seed-complete-state"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["How are you feeling?"].waitForExistence(timeout: 8))

        app.buttons["tab-profile"].tap()
        XCTAssertTrue(app.staticTexts["YOUR ACCOUNT"].waitForExistence(timeout: 5))

        return app
    }

    @MainActor
    private func tapWhenVisible(
        _ element: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0..<6 {
            if element.exists && element.isHittable {
                element.tap()
                return
            }
            app.swipeUp()
        }

        XCTFail("Element was not hittable: \(element)", file: file, line: line)
    }
}
