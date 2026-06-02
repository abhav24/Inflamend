import XCTest
@testable import Inflamend

final class HealthLogicTests: XCTestCase {
    func testRedFlagDetectorFindsHeavyBleedingAndSeverePain() {
        let assessment = RedFlagDetector.assess(text: "I have severe abdominal pain and lots of blood.")

        XCTAssertTrue(assessment.hasRedFlags)
        XCTAssertTrue(assessment.flags.contains(.severeAbdominalPain))
        XCTAssertTrue(assessment.flags.contains(.heavyBleeding))
        XCTAssertTrue(assessment.safetyCopy.contains("Inflamend is not a doctor"))
    }

    func testStructuredBowelLogCanTriggerRedFlag() {
        let assessment = RedFlagDetector.assess(
            bowelLog: BowelLogInput(bristolType: 6, urgencyScore: 9, blood: .visible, painScore: 8, nighttime: true)
        )

        XCTAssertTrue(assessment.flags.contains(.heavyBleeding))
        XCTAssertTrue(assessment.flags.contains(.severeAbdominalPain))
        XCTAssertTrue(assessment.flags.contains(.rapidWorsening))
    }

    func testRiskScoreUsesCautiousDeterministicFactors() {
        let result = RiskScoreService.calculate(
            RiskScoreInput(
                stoolCountToday: 7,
                baselineStoolCount: 2,
                blood: .visible,
                urgencyScore: 8,
                painScore: 7,
                sleepHours: 4.5,
                missedMedication: true,
                userMarkedFlare: false,
                rapidWorsening: true
            )
        )

        XCTAssertGreaterThanOrEqual(result.score, 80)
        XCTAssertEqual(result.tier, "high")
        XCTAssertTrue(result.factors.contains { $0.label.contains("Bowel frequency") })
        XCTAssertTrue(result.disclaimer.contains("not a diagnosis"))
    }

    func testRiskScoreStaysLowForStableInputs() {
        let result = RiskScoreService.calculate(
            RiskScoreInput(
                stoolCountToday: 1,
                baselineStoolCount: 2,
                blood: .none,
                urgencyScore: 1,
                painScore: 1,
                sleepHours: 8,
                missedMedication: false,
                userMarkedFlare: false,
                rapidWorsening: false
            )
        )

        XCTAssertLessThan(result.score, 30)
        XCTAssertEqual(result.tier, "low")
        XCTAssertTrue(result.factors.isEmpty)
    }

    func testVoiceParserParsesBowelMovementWithoutAutosave() {
        let draft = VoiceLogParser.parse("I had three bowel movements today, Bristol six, some urgency, no blood.")

        XCTAssertEqual(draft.type, .bowel)
        XCTAssertEqual(draft.fields["bristol_type"], "6")
        XCTAssertEqual(draft.fields["blood"], "none")
        XCTAssertTrue(draft.requiresConfirmation)
    }

    func testVoiceParserParsesMedication() {
        let draft = VoiceLogParser.parse("I took mesalamine at 9 AM.")

        XCTAssertEqual(draft.type, .medication)
        XCTAssertEqual(draft.fields["medication_name"], "mesalamine")
        XCTAssertEqual(draft.fields["status"], "taken")
    }

    func testVoiceParserParsesWeight() {
        let draft = VoiceLogParser.parse("My weight is 142 pounds.")

        XCTAssertEqual(draft.type, .weight)
        XCTAssertEqual(draft.fields["weight_value"], "142")
        XCTAssertEqual(draft.fields["unit"], "lb")
    }

    func testMedicationScheduleCalculatesTwiceDailyDoses() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let schedule = MedicationSchedule(
            medicationName: "Mesalamine",
            dose: "800mg",
            frequency: .twiceDaily,
            times: [
                DateComponents(hour: 8, minute: 0),
                DateComponents(hour: 20, minute: 0)
            ]
        )

        let doses = MedicationScheduleCalculator.doses(for: schedule, on: day, calendar: calendar)

        XCTAssertEqual(doses.count, 2)
        XCTAssertEqual(calendar.component(.hour, from: doses[0].scheduledAt), 8)
        XCTAssertEqual(calendar.component(.hour, from: doses[1].scheduledAt), 20)
    }

    func testReportSummaryUsesPossiblePatternLanguage() {
        let report = ReportSummaryGenerator.plainText(
            ReportSummaryInput(
                daysLogged: 7,
                bowelMovementCount: 18,
                bloodEventCount: 1,
                medicationDosesTaken: 12,
                medicationDosesScheduled: 14,
                possiblePatterns: ["urgency may be higher within 48h of coffee"],
                notes: ["Ask about nighttime symptoms."]
            )
        )

        XCTAssertTrue(report.contains("Self-reported tracking summary"))
        XCTAssertTrue(report.contains("Possible pattern"))
        XCTAssertFalse(report.contains("caused"))
    }

    func testInsightSummaryReturnsEmptyStateForNoLogs() {
        let summary = InsightSummaryBuilder.build(logs: [])

        XCTAssertEqual(summary.logCount, 0)
        XCTAssertEqual(summary.confidenceLabel, "No local logs yet")
        XCTAssertNil(summary.averagePain)
        XCTAssertFalse(summary.hasTrendData)
        XCTAssertFalse(summary.hasFoodPatterns)
    }

    func testInsightSummaryUsesLocalLogsWithoutDemoData() {
        let logs = [
            LogEntry(type: .food, title: "Dinner", sub: "Dairy · Spicy", time: "7:00pm"),
            LogEntry(type: .symptom, title: "Pain 3/10 · fatigue 4/10", sub: "Mood 5/10", time: "2:00pm"),
            LogEntry(type: .checkin, title: "Flare check-in · pain 7/10", sub: "Fatigue 8/10 · urgency 7/10 · stool 5", time: "8:00am")
        ]

        let summary = InsightSummaryBuilder.build(logs: logs)

        XCTAssertEqual(summary.logCount, 3)
        XCTAssertEqual(summary.painValues, [7, 3])
        XCTAssertEqual(summary.fatigueValues, [8, 4])
        XCTAssertEqual(summary.averagePain ?? -1, 5.0, accuracy: 0.001)
        XCTAssertTrue(summary.bowelValues.contains(5))
        XCTAssertEqual(summary.flareMentionCount, 1)
        XCTAssertTrue(summary.foodPatterns.contains { $0.label == "Dairy" })
        XCTAssertTrue(summary.foodPatterns.contains { $0.label == "Spicy food" })
        XCTAssertEqual(summary.confidenceLabel, "Early local data")
    }

    func testValidationHelpers() {
        XCTAssertTrue(HealthLogValidator.isValidBristolType(4))
        XCTAssertFalse(HealthLogValidator.isValidBristolType(8))
        XCTAssertTrue(HealthLogValidator.isValidScale(10))
        XCTAssertFalse(HealthLogValidator.isValidScale(-1))
        XCTAssertTrue(HealthLogValidator.isValidWeight(142))
        XCTAssertFalse(HealthLogValidator.isValidWaterAmountMl(0))
    }

    @MainActor
    func testAppStatePersistsSessionOnboardingLogsAndPrivacyPreferences() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-test-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        let appState = AppState(store: store)
        XCTAssertFalse(appState.isAuthenticated)

        appState.signUp(email: "patient@example.com", displayName: "Patient One")
        appState.completeOnboarding(
            diagnosis: "Crohn's disease",
            primaryGoal: "Prepare doctor reports",
            baselineStoolCount: 3,
            hasFlarePlan: true
        )
        appState.setAIMemoryEnabled(true)
        appState.addLog(type: .note, title: "Persistent note", sub: "Test")

        let restored = AppState(store: store)
        XCTAssertTrue(restored.isAuthenticated)
        XCTAssertTrue(restored.hasCompletedOnboarding)
        XCTAssertEqual(restored.displayName, "Patient One")
        XCTAssertEqual(restored.onboardingProfile?.diagnosis, "Crohn's disease")
        XCTAssertEqual(restored.logs.first?.title, "Persistent note")
        XCTAssertTrue(restored.aiMemoryEnabled)

        restored.signOut()
        let signedOut = AppState(store: store)
        XCTAssertFalse(signedOut.isAuthenticated)
        XCTAssertEqual(signedOut.logs.first?.title, "Persistent note")

        store.delete()
    }

    @MainActor
    func testPendingSyncQueuePersistsAndMarksBlockedWithoutBackend() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-sync-test-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        let appState = AppState(store: store)
        appState.signUp(email: "sync@example.com", displayName: "Sync Patient")
        appState.completeOnboarding(
            diagnosis: "Ulcerative colitis",
            primaryGoal: "Track flares",
            baselineStoolCount: 2,
            hasFlarePlan: false
        )
        appState.addLog(type: .note, title: "Needs sync", sub: "Queued")

        let beforeChatCount = appState.pendingSyncCount
        appState.addChatMessage(role: .user, content: "Do not sync this while memory is off")
        XCTAssertEqual(appState.pendingSyncCount, beforeChatCount)

        appState.setAIMemoryEnabled(true)
        appState.addChatMessage(role: .user, content: "Syncable with memory on")
        XCTAssertTrue(appState.pendingSyncMutations.contains { $0.kind == .chatMessage })

        appState.retryPendingSyncScaffold()
        XCTAssertTrue(appState.pendingSyncMutations.allSatisfy { $0.status == .blockedNoBackend })
        XCTAssertTrue(appState.lastSyncStatus.contains("Supabase not configured"))

        let restored = AppState(store: store)
        XCTAssertEqual(restored.pendingSyncCount, appState.pendingSyncCount)
        XCTAssertTrue(restored.pendingSyncMutations.contains { $0.kind == .healthLog })
        XCTAssertTrue(restored.pendingSyncMutations.contains { $0.kind == .onboardingProfile })

        store.delete()
    }

    @MainActor
    func testCorruptSnapshotFallsBackToCleanState() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-corrupt-test-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()
        try Data("not-json".utf8).write(to: url)

        let appState = AppState(store: store)

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertTrue(appState.logs.isEmpty)
        XCTAssertTrue(appState.lastSyncStatus.contains("unreadable"))

        store.delete()
    }

    @MainActor
    func testLegacySnapshotWithoutQueueStillDecodes() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-legacy-test-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()
        let legacySnapshot = """
        {
          "aiMemoryEnabled": true,
          "chatMessages": [],
          "lastSyncStatus": "Legacy saved",
          "logs": [],
          "medsTaken": 1,
          "medsTotal": 2,
          "riskScore": 55,
          "voiceTranscriptStorageEnabled": false
        }
        """
        try Data(legacySnapshot.utf8).write(to: url)

        let appState = AppState(store: store)

        XCTAssertEqual(appState.riskScore, 55)
        XCTAssertEqual(appState.medsTaken, 1)
        XCTAssertEqual(appState.medsTotal, 2)
        XCTAssertTrue(appState.pendingSyncMutations.isEmpty)
        XCTAssertEqual(appState.lastSyncStatus, "Legacy saved")

        store.delete()
    }
}
