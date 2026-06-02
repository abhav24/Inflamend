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
    func testLocalSignInReachesOnboardingSmoke() {
        let app = XCUIApplication()
        app.launchArguments = ["--inflamend-reset-state"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Your IBD day, organized."].waitForExistence(timeout: 8))

        app.buttons["auth-mode-sign-in-button"].tap()
        app.textFields["auth-email-field"].tap()
        app.textFields["auth-email-field"].typeText("returning@example.com")

        app.secureTextFields["auth-password-field"].tap()
        app.secureTextFields["auth-password-field"].typeText("localpass")
        dismissKeyboard(in: app)

        tapWhenVisible(app.buttons["auth-primary-button"], in: app)

        XCTAssertTrue(app.staticTexts["Make Inflamend fit your day"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testInsightsEmptyStateAvoidsDemoClaimsSmoke() {
        let app = openFreshOnboardedHome(
            displayName: "UI Insights",
            email: "ui-insights@example.com"
        )

        app.buttons["tab-insights"].tap()
        XCTAssertTrue(app.staticTexts["No local logs yet"].waitForExistence(timeout: 5))

        let trendEmptyState = app.descendants(matching: .any)["insights-empty-trend"]
        XCTAssertTrue(trendEmptyState.waitForExistence(timeout: 5))
        XCTAssertTrue(trendEmptyState.label.contains("Trend needs more logs"))

        let bowelEmptyState = app.descendants(matching: .any)["insights-empty-bowel"]
        waitForElement(bowelEmptyState, in: app)
        XCTAssertTrue(bowelEmptyState.label.contains("No bowel pattern yet"))

        let painEmptyState = app.descendants(matching: .any)["insights-empty-pain"]
        waitForElement(painEmptyState, in: app)
        XCTAssertTrue(painEmptyState.label.contains("No pain scores yet"))

        let foodEmptyState = app.descendants(matching: .any)["insights-empty-food"]
        waitForElement(foodEmptyState, in: app)
        XCTAssertTrue(foodEmptyState.label.contains("No food patterns yet"))
    }

    @MainActor
    func testInsightsPopulatedSummaryUsesLocalLogsSmoke() {
        let app = openFreshOnboardedHome(
            displayName: "UI Patterns",
            email: "ui-patterns@example.com"
        )

        app.buttons["tab-log"].tap()
        tapWhenVisible(app.buttons["rapid-log-flare"], in: app)
        tapWhenVisible(app.buttons["rapid-log-well"], in: app)
        tapWhenVisible(app.buttons["rapid-log-bm"], in: app)
        tapWhenVisible(app.buttons["rapid-log-meal"], in: app)

        app.buttons["tab-insights"].tap()

        let confidence = app.staticTexts["insights-confidence-label"]
        XCTAssertTrue(confidence.waitForExistence(timeout: 5))
        XCTAssertTrue(confidence.label.contains("Early local data"))

        let avgPain = app.descendants(matching: .any)["insights-stat-avg-pain"]
        waitForLabel(avgPain, contains: "3.5")

        let bowelLogs = app.descendants(matching: .any)["insights-stat-bm-logs"]
        waitForLabel(bowelLogs, contains: "1")

        let flareMarks = app.descendants(matching: .any)["insights-stat-flare-marks"]
        waitForLabel(flareMarks, contains: "1")

        let trendChart = app.descendants(matching: .any)["insights-populated-trend-chart"]
        XCTAssertTrue(trendChart.waitForExistence(timeout: 5))
        XCTAssertTrue(trendChart.label.contains("Pain scores 7, 0"))
        XCTAssertTrue(trendChart.label.contains("Fatigue scores 8, 1"))

        let bowelChart = app.descendants(matching: .any)["insights-populated-bowel-chart"]
        waitForElement(bowelChart, in: app)
        XCTAssertTrue(bowelChart.label.contains("Bowel chart values 5, 1, 1, 0"))

        let heatmap = app.descendants(matching: .any)["insights-populated-pain-heatmap"]
        waitForElement(heatmap, in: app)
        XCTAssertTrue(heatmap.label.contains("Highest intensity 4 of 5"))

        let foodPattern = app.descendants(matching: .any)["insights-food-pattern-meal-logged"]
        waitForElement(foodPattern, in: app)
        XCTAssertTrue(foodPattern.label.contains("Meal logged"))
        XCTAssertTrue(foodPattern.label.contains("1 food logs"))
    }

    @MainActor
    func testProfileUserDataExportSheetSmoke() {
        let app = openSeededProfile()

        tapWhenVisible(app.buttons["profile-export-data-row"], in: app)

        XCTAssertTrue(app.staticTexts["user-data-export-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["user-data-export-share-button"].exists)
    }

    @MainActor
    func testProfileDoctorReportExportSheetSmoke() {
        let app = openSeededProfile()

        tapWhenVisible(app.buttons["profile-export-report-row"], in: app)

        XCTAssertTrue(app.staticTexts["doctor-report-export-title"].waitForExistence(timeout: 5))
        let fileName = app.staticTexts["doctor-report-export-filename"]
        XCTAssertTrue(fileName.exists)
        XCTAssertTrue(fileName.label.hasPrefix("Inflamend-Doctor-Report-"))
        XCTAssertTrue(app.buttons["doctor-report-export-share-button"].exists)
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
    func testProfilePrivacyTogglesUpdateVisibleStateSmoke() {
        let app = openSeededProfile()

        let aiMemoryToggle = app.buttons["profile-ai-memory-toggle"]
        tapWhenVisible(aiMemoryToggle, in: app)
        waitForLabel(aiMemoryToggle, contains: "On")

        tapWhenVisible(aiMemoryToggle, in: app)
        waitForLabel(aiMemoryToggle, contains: "Off")

        let voiceStorageToggle = app.buttons["profile-voice-transcript-storage-toggle"]
        tapWhenVisible(voiceStorageToggle, in: app)
        waitForLabel(voiceStorageToggle, contains: "On")

        tapWhenVisible(voiceStorageToggle, in: app)
        waitForLabel(voiceStorageToggle, contains: "Off")
    }

    @MainActor
    func testProfileSyncRetryShowsBackendBlockedSmoke() {
        let app = openFreshOnboardedHome(
            displayName: "UI Sync",
            email: "ui-sync@example.com"
        )

        app.buttons["tab-profile"].tap()
        XCTAssertTrue(app.staticTexts["YOUR ACCOUNT"].waitForExistence(timeout: 5))

        let syncRow = app.buttons["profile-sync-status-row"]
        waitForLabel(syncRow, contains: "pending")
        tapWhenVisible(syncRow, in: app)
        waitForLabel(syncRow, contains: "Sync blocked: Supabase not configured")
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
    func testCareMedicationChangePromptRefusesPrescriptionAdviceSmoke() {
        let app = openSeededHome()

        app.buttons["tab-chat"].tap()
        XCTAssertTrue(app.staticTexts["CARE · SAFETY"].waitForExistence(timeout: 5))

        let prompt = "Should I stop mesalamine if my flare feels bad?"
        app.textFields["care-input-field"].tap()
        app.textFields["care-input-field"].typeText(prompt)
        app.textFields["care-input-field"].typeText("\n")

        XCTAssertTrue(app.staticTexts[prompt].waitForExistence(timeout: 5))
        let refusal = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS %@", "I can't recommend starting, stopping"))
            .firstMatch
        XCTAssertTrue(refusal.waitForExistence(timeout: 8))
        XCTAssertTrue(refusal.label.contains("GI clinician or pharmacist"))
        XCTAssertFalse(app.staticTexts["care-safety-message"].exists)
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
    func testCheckInLogCanBeEditedFromTimelineSmoke() {
        let app = openSeededHome()

        let initialSummary = app.descendants(matching: .any)["home-meds-summary-row"]
        XCTAssertTrue(initialSummary.waitForExistence(timeout: 5))
        XCTAssertTrue(initialSummary.label.contains("Meds 1 of 2"))

        tapWhenVisible(app.buttons["home-start-checkin-button"], in: app)
        XCTAssertTrue(app.staticTexts["checkin-sheet-title"].waitForExistence(timeout: 5))
        tapWhenVisible(app.buttons["checkin-save-button"], in: app)

        let checkInEntry = app.descendants(matching: .any)["timeline-entry-checkin"]
        waitForLabel(checkInEntry, contains: "Okay check-in · pain 3/10")

        let updatedSummary = app.descendants(matching: .any)["home-meds-summary-row"]
        waitForLabel(updatedSummary, contains: "Meds 2 of 2")

        tapWhenVisible(app.buttons["timeline-edit-checkin"], in: app)
        XCTAssertTrue(app.staticTexts["timeline-edit-sheet-title"].waitForExistence(timeout: 5))
        for _ in 0..<5 {
            tapWhenVisible(app.buttons["timeline-edit-checkin-pain-increment"], in: app)
        }
        tapWhenVisible(app.buttons["timeline-edit-checkin-medication-taken"], in: app)
        tapWhenVisible(app.buttons["timeline-save-edit-button"], in: app)

        let editedCheckInEntry = app.descendants(matching: .any)["timeline-entry-checkin"]
        waitForLabel(editedCheckInEntry, contains: "Okay check-in · pain 8/10")
        waitForLabel(editedCheckInEntry, contains: "medication not taken")
        waitForLabel(updatedSummary, contains: "Meds 1 of 2")
    }

    @MainActor
    func testTimelineEntryDeleteRequiresConfirmationSmoke() {
        let app = openSeededHome()

        XCTAssertTrue(app.staticTexts["1 entries"].exists)
        let noteEntry = app.descendants(matching: .any)["timeline-entry-note"]
        XCTAssertTrue(noteEntry.waitForExistence(timeout: 5))
        XCTAssertTrue(noteEntry.label.contains("UI test export note"))

        tapWhenVisible(app.buttons["timeline-delete-note"], in: app)
        XCTAssertTrue(app.staticTexts["Delete log entry?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Remove UI test export note from local logs on this device."].exists)

        app.buttons.matching(identifier: "timeline-confirm-delete-note-button").firstMatch.tap()

        XCTAssertTrue(app.staticTexts["0 entries"].waitForExistence(timeout: 5))
        XCTAssertTrue(noteEntry.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["timeline-empty-start-log-button"].exists)
    }

    @MainActor
    func testTimelineEntryDeleteUndoRestoresLocalRowSmoke() {
        let app = openSeededHome()

        XCTAssertTrue(app.staticTexts["1 entries"].exists)
        let noteEntry = app.descendants(matching: .any)["timeline-entry-note"]
        XCTAssertTrue(noteEntry.waitForExistence(timeout: 5))

        tapWhenVisible(app.buttons["timeline-delete-note"], in: app)
        XCTAssertTrue(app.staticTexts["Delete log entry?"].waitForExistence(timeout: 5))
        app.buttons.matching(identifier: "timeline-confirm-delete-note-button").firstMatch.tap()

        XCTAssertTrue(app.staticTexts["0 entries"].waitForExistence(timeout: 5))
        let undoButton = app.buttons["toast-action-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 5))
        undoButton.tap()

        XCTAssertTrue(app.staticTexts["1 entries"].waitForExistence(timeout: 5))
        let restoredEntry = app.descendants(matching: .any)["timeline-entry-note"]
        XCTAssertTrue(restoredEntry.waitForExistence(timeout: 5))
        XCTAssertTrue(restoredEntry.label.contains("UI test export note"), restoredEntry.label)
    }

    @MainActor
    func testTimelineEntryEditUpdatesLocalRowSmoke() {
        let app = openSeededHome()

        XCTAssertTrue(app.staticTexts["1 entries"].exists)
        let noteEntry = app.descendants(matching: .any)["timeline-entry-note"]
        XCTAssertTrue(noteEntry.waitForExistence(timeout: 5))
        XCTAssertTrue(noteEntry.label.contains("UI test export note"))

        tapWhenVisible(app.buttons["timeline-edit-note"], in: app)
        XCTAssertTrue(app.staticTexts["timeline-edit-sheet-title"].waitForExistence(timeout: 5))

        let titleField = app.descendants(matching: .any)["timeline-edit-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText(" updated")

        let detailField = app.descendants(matching: .any)["timeline-edit-detail-field"]
        XCTAssertTrue(detailField.waitForExistence(timeout: 5))
        detailField.tap()
        detailField.typeText(" reviewed")
        dismissKeyboard(in: app)

        tapWhenVisible(app.buttons["timeline-save-edit-button"], in: app)

        let editedEntry = app.descendants(matching: .any)["timeline-entry-note"]
        waitForLabel(editedEntry, contains: "UI test export note updated")
        XCTAssertTrue(editedEntry.label.contains("reviewed"), editedEntry.label)
        XCTAssertTrue(app.staticTexts["1 entries"].exists)
    }

    @MainActor
    func testBowelLogWithSignificantBloodShowsSafetyGuidanceSmoke() {
        let app = openSeededHome()

        app.buttons["tab-log"].tap()
        app.buttons["log-tab-bowel"].tap()
        tapWhenVisible(app.buttons["bowel-blood-significant"], in: app)
        tapWhenVisible(app.buttons["bowel-save-entry-button"], in: app)

        app.buttons["tab-home"].tap()
        let safetyCard = app.descendants(matching: .any)["home-safety-card"]
        XCTAssertTrue(safetyCard.waitForExistence(timeout: 5))
        XCTAssertTrue(safetyCard.label.contains("cannot diagnose or triage emergencies"))

        tapWhenVisible(app.buttons["timeline-edit-bowel"], in: app)
        XCTAssertTrue(app.staticTexts["timeline-edit-sheet-title"].waitForExistence(timeout: 5))
        tapWhenVisible(app.buttons["timeline-edit-bowel-bristol-6"], in: app)
        tapWhenVisible(app.buttons["timeline-edit-bowel-blood-none"], in: app)
        tapWhenVisible(app.buttons["timeline-edit-bowel-mucus"], in: app)
        tapWhenVisible(app.buttons["timeline-save-edit-button"], in: app)

        let editedBowelEntry = app.descendants(matching: .any)["timeline-entry-bowel"]
        waitForLabel(editedBowelEntry, contains: "Bristol 6")
        XCTAssertTrue(editedBowelEntry.label.contains("no blood"), editedBowelEntry.label)
        XCTAssertTrue(editedBowelEntry.label.contains("mucus"), editedBowelEntry.label)
        XCTAssertFalse(editedBowelEntry.label.contains("significant blood"), editedBowelEntry.label)
    }

    @MainActor
    func testSymptomLogCanBeEditedFromTimelineSmoke() {
        let app = openSeededHome()

        app.buttons["tab-log"].tap()
        tapHorizontalWhenVisible(app.buttons["log-tab-symptoms"], in: app)
        tapWhenVisible(app.buttons["symptom-save-entry-button"], in: app)

        app.buttons["tab-home"].tap()
        let symptomEntry = app.descendants(matching: .any)["timeline-entry-symptom"]
        waitForLabel(symptomEntry, contains: "Pain 4/10")

        tapWhenVisible(app.buttons["timeline-edit-symptom"], in: app)
        XCTAssertTrue(app.staticTexts["timeline-edit-sheet-title"].waitForExistence(timeout: 5))
        for _ in 0..<4 {
            tapWhenVisible(app.buttons["timeline-edit-symptom-pain-increment"], in: app)
        }
        tapWhenVisible(app.buttons["timeline-save-edit-button"], in: app)

        let editedSymptomEntry = app.descendants(matching: .any)["timeline-entry-symptom"]
        waitForLabel(editedSymptomEntry, contains: "Pain 8/10")
        XCTAssertTrue(editedSymptomEntry.label.contains("fatigue 6/10"), editedSymptomEntry.label)
        XCTAssertTrue(editedSymptomEntry.label.contains("Mood 5/10"), editedSymptomEntry.label)

        let safetyCard = app.descendants(matching: .any)["home-safety-card"]
        XCTAssertTrue(safetyCard.waitForExistence(timeout: 5))
        XCTAssertTrue(safetyCard.label.contains("cannot diagnose or triage emergencies"))
    }

    @MainActor
    func testSleepLogCanBeEditedFromTimelineSmoke() {
        let app = openSeededHome()

        app.buttons["tab-log"].tap()
        tapHorizontalWhenVisible(app.buttons["log-tab-sleep"], in: app)
        tapWhenVisible(app.buttons["sleep-save-entry-button"], in: app)

        app.buttons["tab-home"].tap()
        let sleepEntry = app.descendants(matching: .any)["timeline-entry-sleep"]
        waitForLabel(sleepEntry, contains: "Sleep quality 7/10")

        tapWhenVisible(app.buttons["timeline-edit-sleep"], in: app)
        XCTAssertTrue(app.staticTexts["timeline-edit-sheet-title"].waitForExistence(timeout: 5))
        for _ in 0..<2 {
            tapWhenVisible(app.buttons["timeline-edit-sleep-quality-increment"], in: app)
        }
        tapWhenVisible(app.buttons["timeline-edit-sleep-wake-3"], in: app)
        tapWhenVisible(app.buttons["timeline-save-edit-button"], in: app)

        let editedSleepEntry = app.descendants(matching: .any)["timeline-entry-sleep"]
        waitForLabel(editedSleepEntry, contains: "Sleep quality 9/10")
        XCTAssertTrue(editedSleepEntry.label.contains("3 bathroom wakes"), editedSleepEntry.label)
    }

    @MainActor
    func testWeightLogCanBeEditedFromTimelineSmoke() {
        let app = openSeededHome()

        app.buttons["tab-log"].tap()
        tapHorizontalWhenVisible(app.buttons["log-tab-weight"], in: app)
        tapWhenVisible(app.buttons["weight-save-entry-button"], in: app)

        app.buttons["tab-home"].tap()
        let weightEntry = app.descendants(matching: .any)["timeline-entry-weight"]
        waitForLabel(weightEntry, contains: "Weight · 62.4 kg")

        tapWhenVisible(app.buttons["timeline-edit-weight"], in: app)
        XCTAssertTrue(app.staticTexts["timeline-edit-sheet-title"].waitForExistence(timeout: 5))
        for _ in 0..<6 {
            tapWhenVisible(app.buttons["timeline-edit-weight-increment-tenth"], in: app)
        }
        tapWhenVisible(app.buttons["timeline-save-edit-button"], in: app)

        let editedWeightEntry = app.descendants(matching: .any)["timeline-entry-weight"]
        waitForLabel(editedWeightEntry, contains: "Weight · 63.0 kg")
        XCTAssertTrue(editedWeightEntry.label.contains("Manual entry"), editedWeightEntry.label)
    }

    @MainActor
    func testMedicationDoseUpdatesHomeSummarySmoke() {
        let app = openSeededHome()

        let initialSummary = app.descendants(matching: .any)["home-meds-summary-row"]
        XCTAssertTrue(initialSummary.waitForExistence(timeout: 5))
        XCTAssertTrue(initialSummary.label.contains("Meds 1 of 2"))

        app.buttons["tab-log"].tap()
        tapHorizontalWhenVisible(app.buttons["log-tab-meds"], in: app)
        tapWhenVisible(app.buttons["meds-dose-vitamin-d-8-00am-toggle"], in: app)

        app.buttons["tab-home"].tap()
        let updatedSummary = app.descendants(matching: .any)["home-meds-summary-row"]
        XCTAssertTrue(updatedSummary.waitForExistence(timeout: 5))
        XCTAssertTrue(updatedSummary.label.contains("Meds 2 of 2"))

        let medicationEntry = app.descendants(matching: .any)["timeline-entry-meds"]
        XCTAssertTrue(medicationEntry.waitForExistence(timeout: 5))
        XCTAssertTrue(medicationEntry.label.contains("Vitamin D"))
    }

    @MainActor
    func testMedicationLogCanBeEditedFromTimelineSmoke() {
        let app = openSeededHome()

        let initialSummary = app.descendants(matching: .any)["home-meds-summary-row"]
        XCTAssertTrue(initialSummary.waitForExistence(timeout: 5))
        XCTAssertTrue(initialSummary.label.contains("Meds 1 of 2"))

        app.buttons["tab-log"].tap()
        tapHorizontalWhenVisible(app.buttons["log-tab-meds"], in: app)
        tapWhenVisible(app.buttons["meds-dose-vitamin-d-8-00am-toggle"], in: app)

        app.buttons["tab-home"].tap()
        let updatedSummary = app.descendants(matching: .any)["home-meds-summary-row"]
        waitForLabel(updatedSummary, contains: "Meds 2 of 2")

        let medicationEntry = app.descendants(matching: .any)["timeline-entry-meds"]
        waitForLabel(medicationEntry, contains: "Vitamin D · taken")

        tapWhenVisible(app.buttons["timeline-edit-meds"], in: app)
        XCTAssertTrue(app.staticTexts["timeline-edit-sheet-title"].waitForExistence(timeout: 5))
        tapWhenVisible(app.buttons["timeline-edit-medication-status-skipped"], in: app)
        tapWhenVisible(app.buttons["timeline-save-edit-button"], in: app)

        let editedMedicationEntry = app.descendants(matching: .any)["timeline-entry-meds"]
        waitForLabel(editedMedicationEntry, contains: "Vitamin D · skipped")
        waitForLabel(updatedSummary, contains: "Meds 1 of 2")
    }

    @MainActor
    func testFoodLogSavesPatternEntrySmoke() {
        let app = openSeededHome()

        XCTAssertTrue(app.staticTexts["1 entries"].exists)
        app.buttons["tab-log"].tap()
        app.buttons["log-tab-food"].tap()

        app.textFields["food-name-field"].tap()
        app.textFields["food-name-field"].typeText("Greek yogurt and rice")
        dismissKeyboard(in: app)

        tapWhenVisible(app.buttons["food-trigger-dairy"], in: app)
        tapWhenVisible(app.buttons["food-save-entry-button"], in: app)

        app.buttons["tab-home"].tap()
        XCTAssertTrue(app.staticTexts["2 entries"].waitForExistence(timeout: 5))

        let foodEntry = app.descendants(matching: .any)["timeline-entry-food"]
        XCTAssertTrue(foodEntry.waitForExistence(timeout: 5))
        XCTAssertTrue(foodEntry.label.contains("Greek yogurt and rice"))
        XCTAssertTrue(foodEntry.label.contains("Dairy"))
        XCTAssertFalse(foodEntry.label.localizedCaseInsensitiveContains("calorie"))

        tapWhenVisible(app.buttons["timeline-edit-food"], in: app)
        XCTAssertTrue(app.staticTexts["timeline-edit-sheet-title"].waitForExistence(timeout: 5))
        tapWhenVisible(app.buttons["timeline-edit-food-tag-rice"], in: app)
        tapWhenVisible(app.buttons["timeline-edit-food-tag-dairy"], in: app)
        tapWhenVisible(app.buttons["timeline-save-edit-button"], in: app)

        let editedFoodEntry = app.descendants(matching: .any)["timeline-entry-food"]
        waitForLabel(editedFoodEntry, contains: "Rice")
        XCTAssertFalse(editedFoodEntry.label.contains("Dairy"), editedFoodEntry.label)
    }

    @MainActor
    func testVoiceTranscriptCanBeEditedBeforeSavingSmoke() {
        let app = openSeededHome()

        app.buttons["tab-log"].tap()
        tapHorizontalWhenVisible(app.buttons["log-tab-voice"], in: app)

        let transcriptField = app.descendants(matching: .any)["voice-transcript-field"]
        XCTAssertTrue(transcriptField.waitForExistence(timeout: 5))
        transcriptField.tap()
        transcriptField.typeText("I ate rice for dinner")
        dismissKeyboard(in: app)

        tapWhenVisible(app.buttons["voice-parse-button"], in: app)

        XCTAssertTrue(app.staticTexts["Confirm before saving"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["voice-draft-type"].label.contains("Meal"))

        let descriptionField = app.descendants(matching: .any)["voice-field-description"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 5))
        tapCenterWhenVisible(descriptionField, in: app)
        descriptionField.typeText(" with carrots")
        dismissKeyboard(in: app)

        tapWhenVisible(app.buttons["voice-save-confirmed-button"], in: app)

        app.buttons["tab-home"].tap()
        let voiceEntry = app.descendants(matching: .any)["timeline-entry-voice"]
        XCTAssertTrue(voiceEntry.waitForExistence(timeout: 5))
        XCTAssertTrue(voiceEntry.label.contains("Voice meal confirmed"))
        XCTAssertTrue(voiceEntry.label.contains("with carrots"))
        XCTAssertTrue(voiceEntry.label.contains("meal type: dinner"))
    }

    @MainActor
    func testVoicePermissionDeniedKeepsManualFallbackSmoke() {
        let app = openSeededHome(extraLaunchArguments: ["--inflamend-simulate-voice-permission-denied"])

        app.buttons["tab-log"].tap()
        tapHorizontalWhenVisible(app.buttons["log-tab-voice"], in: app)

        let status = app.staticTexts["voice-permission-status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Voice access denied"))

        let detail = app.staticTexts["voice-permission-detail"]
        waitForElement(detail, in: app)
        XCTAssertTrue(detail.label.contains("Settings"))
        XCTAssertTrue(detail.label.contains("Manual transcript entry remains available"))

        XCTAssertTrue(app.buttons["voice-use-manual-transcript-button"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["voice-transcript-field"].exists)
    }

    @MainActor
    private func openFreshOnboardedHome(displayName: String, email: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--inflamend-reset-state"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Your IBD day, organized."].waitForExistence(timeout: 8))

        app.textFields["auth-name-field"].tap()
        app.textFields["auth-name-field"].typeText(displayName)

        app.textFields["auth-email-field"].tap()
        app.textFields["auth-email-field"].typeText(email)

        app.secureTextFields["auth-password-field"].tap()
        app.secureTextFields["auth-password-field"].typeText("localpass")
        dismissKeyboard(in: app)

        tapWhenVisible(app.buttons["auth-primary-button"], in: app)
        XCTAssertTrue(app.staticTexts["Make Inflamend fit your day"].waitForExistence(timeout: 5))

        tapWhenVisible(app.buttons["onboarding-finish-button"], in: app)
        XCTAssertTrue(app.staticTexts["How are you feeling?"].waitForExistence(timeout: 8))

        return app
    }

    @MainActor
    private func openSeededHome(extraLaunchArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--inflamend-reset-state",
            "--inflamend-seed-complete-state"
        ] + extraLaunchArguments
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
        let authDoneButton = app.buttons["auth-keyboard-done-button"].firstMatch
        if authDoneButton.waitForExistence(timeout: 1) {
            authDoneButton.tap()
            return
        }

        let voiceTranscriptDoneButton = app.buttons["voice-transcript-keyboard-done-button"].firstMatch
        if voiceTranscriptDoneButton.waitForExistence(timeout: 1) {
            voiceTranscriptDoneButton.tap()
            return
        }

        let voiceFieldDoneButton = app.buttons["voice-field-keyboard-done-button"].firstMatch
        if voiceFieldDoneButton.waitForExistence(timeout: 1) {
            voiceFieldDoneButton.tap()
            return
        }

        let timelineEditDoneButton = app.buttons["timeline-edit-keyboard-done-button"].firstMatch
        if timelineEditDoneButton.waitForExistence(timeout: 1) {
            timelineEditDoneButton.tap()
            return
        }

        let doneButton = app.buttons["Done"].firstMatch
        if doneButton.waitForExistence(timeout: 1) {
            doneButton.tap()
            if app.keyboards.firstMatch.waitForNonExistence(timeout: 1) {
                return
            }
        }

        let returnButton = app.buttons["Return"].firstMatch
        if returnButton.waitForExistence(timeout: 1) {
            returnButton.tap()
            if app.keyboards.firstMatch.waitForNonExistence(timeout: 1) {
                return
            }
        }

        guard app.keyboards.firstMatch.exists else { return }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.06)).tap()
        _ = app.keyboards.firstMatch.waitForNonExistence(timeout: 1)
    }

    @MainActor
    private func waitForElement(
        _ element: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0..<6 {
            if element.exists {
                return
            }

            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
            start.press(forDuration: 0.01, thenDragTo: end)
        }

        XCTFail("Element did not exist: \(element)", file: file, line: line)
    }

    @MainActor
    private func waitForLabel(
        _ element: XCUIElement,
        contains expectedText: String,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if element.exists && element.label.contains(expectedText) {
                return
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        XCTFail("Element label did not contain \(expectedText): \(element)", file: file, line: line)
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

            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
            start.press(forDuration: 0.01, thenDragTo: end)
        }

        XCTFail("Element was not hittable: \(element)", file: file, line: line)
    }

    @MainActor
    private func tapCenterWhenVisible(
        _ element: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let screenFrame = app.windows.firstMatch.frame

        for _ in 0..<6 {
            if element.exists {
                let frame = element.frame
                let center = CGPoint(x: frame.midX, y: frame.midY)

                if !frame.isEmpty && screenFrame.contains(center) {
                    let normalizedPoint = CGVector(
                        dx: (center.x - screenFrame.minX) / screenFrame.width,
                        dy: (center.y - screenFrame.minY) / screenFrame.height
                    )
                    app.coordinate(withNormalizedOffset: normalizedPoint).tap()
                    return
                }
            }

            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
            start.press(forDuration: 0.01, thenDragTo: end)
        }

        XCTFail("Element center was not visible: \(element)", file: file, line: line)
    }

    @MainActor
    private func tapHorizontalWhenVisible(
        _ element: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let screenFrame = app.windows.firstMatch.frame

        for _ in 0..<8 {
            if element.exists {
                let frame = element.frame
                let center = CGPoint(x: frame.midX, y: frame.midY)

                if !frame.isEmpty && screenFrame.contains(center) {
                    element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                    return
                }
            }

            let tabStrip = app.scrollViews["log-tab-strip"]
            if tabStrip.exists {
                tabStrip.swipeLeft()
            } else {
                let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.16))
                let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.16))
                start.press(forDuration: 0.01, thenDragTo: end)
            }
        }

        if element.exists {
            let frame = element.frame
            let center = CGPoint(x: frame.midX, y: frame.midY)
            if !frame.isEmpty && screenFrame.contains(center) {
                element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                return
            }
        }

        XCTFail("Element was not hittable: \(element)", file: file, line: line)
    }
}
