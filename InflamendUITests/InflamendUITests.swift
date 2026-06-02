import XCTest

final class InflamendUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFreshSignUpCompletesOnboardingSmoke() {
        let app = XCUIApplication()
        app.launchArguments = ["--inflamend-reset-state"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Your IBD day, organized."].waitForExistence(timeout: 8))

        app.textFields["auth-name-field"].tap()
        app.textFields["auth-name-field"].typeText("UI Onboarding")

        app.textFields["auth-email-field"].tap()
        app.textFields["auth-email-field"].typeText("ui-onboarding@example.com")

        app.secureTextFields["auth-password-field"].tap()
        app.secureTextFields["auth-password-field"].typeText("localpass")
        dismissKeyboard(in: app)

        tapWhenVisible(app.buttons["auth-primary-button"], in: app)

        XCTAssertTrue(app.staticTexts["Make Inflamend fit your day"].waitForExistence(timeout: 5))

        tapWhenVisible(app.buttons["onboarding-finish-button"], in: app)

        XCTAssertTrue(app.staticTexts["How are you feeling?"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["tab-profile"].exists)
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
    func testProfileSignOutReturnsToAuthGateSmoke() {
        let app = openSeededProfile()

        tapWhenVisible(app.buttons["profile-sign-out-row"], in: app)

        XCTAssertTrue(app.staticTexts["Your IBD day, organized."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["auth-primary-button"].exists)
    }

    @MainActor
    func testCareRedFlagPromptShowsSafetyGuidanceSmoke() {
        let app = openSeededHome()

        app.buttons["tab-chat"].tap()
        XCTAssertTrue(app.staticTexts["CARE · SAFETY"].waitForExistence(timeout: 5))

        let prompt = "I have severe abdominal pain and lots of blood"
        app.textFields["care-input-field"].tap()
        app.textFields["care-input-field"].typeText(prompt)
        app.textFields["care-input-field"].typeText("\n")

        XCTAssertTrue(app.staticTexts[prompt].waitForExistence(timeout: 5))
        let safetyMessage = app.staticTexts["care-safety-message"]
        XCTAssertTrue(safetyMessage.waitForExistence(timeout: 5))
        XCTAssertTrue(safetyMessage.label.contains("cannot diagnose or triage emergencies"))
    }

    @MainActor
    func testTodayCheckInSavesToTimelineSmoke() {
        let app = openSeededHome()

        XCTAssertTrue(app.staticTexts["1 entries"].exists)
        tapWhenVisible(app.buttons["home-start-checkin-button"], in: app)

        XCTAssertTrue(app.staticTexts["checkin-sheet-title"].waitForExistence(timeout: 5))
        tapWhenVisible(app.buttons["checkin-save-button"], in: app)

        XCTAssertTrue(app.staticTexts["2 entries"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Okay check-in · pain 3/10"].exists)
    }

    @MainActor
    private func openSeededHome() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--inflamend-reset-state",
            "--inflamend-seed-complete-state"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["How are you feeling?"].waitForExistence(timeout: 8))

        return app
    }

    @MainActor
    private func openSeededProfile() -> XCUIApplication {
        let app = openSeededHome()

        app.buttons["tab-profile"].tap()
        XCTAssertTrue(app.staticTexts["YOUR ACCOUNT"].waitForExistence(timeout: 5))

        return app
    }

    @MainActor
    private func dismissKeyboard(in app: XCUIApplication) {
        let authDoneButton = app.buttons["auth-keyboard-done-button"]
        if authDoneButton.waitForExistence(timeout: 1) {
            authDoneButton.tap()
            return
        }

        if app.buttons["Done"].waitForExistence(timeout: 1) {
            app.buttons["Done"].tap()
            return
        }

        if app.buttons["Return"].waitForExistence(timeout: 1) {
            app.buttons["Return"].tap()
            return
        }

        guard app.keyboards.firstMatch.exists else { return }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.06)).tap()
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

            if app.scrollViews.firstMatch.exists {
                app.scrollViews.firstMatch.swipeUp()
            } else {
                app.swipeUp()
            }
        }

        XCTFail("Element was not hittable: \(element)", file: file, line: line)
    }
}
