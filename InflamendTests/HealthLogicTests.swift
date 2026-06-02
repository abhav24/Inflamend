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
        XCTAssertTrue(report.contains("do not prove triggers or causes"))
        XCTAssertFalse(report.contains("caused"))
    }

    func testDoctorReportExporterBuildsLocalLogReportWithoutTriggerClaims() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let generatedAt = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 2)))
        let logs = [
            LogEntry(type: .food, title: "Dinner", sub: "Dairy", time: "7:00pm", loggedAt: generatedAt),
            LogEntry(type: .bowel, title: "Bristol 6 · urgency 7/10", sub: "visible blood", time: "9:00am", loggedAt: generatedAt)
        ]

        let report = DoctorReportExporter.buildPlainTextReport(
            logs: logs,
            medsTaken: 3,
            medsTotal: 4,
            displayName: "Soham",
            generatedAt: generatedAt,
            calendar: calendar
        )

        XCTAssertTrue(report.contains("Prepared for: Soham"))
        XCTAssertTrue(report.contains("Range: Last 30 days (2026-05-04 to 2026-06-02)"))
        XCTAssertTrue(report.contains("Bowel movements logged: 1"))
        XCTAssertTrue(report.contains("Blood flags: 1"))
        XCTAssertTrue(report.contains("Dairy appeared in 1 food log; frequency only, not a trigger claim."))
        XCTAssertFalse(report.contains("caused"))
        XCTAssertEqual(DoctorReportExporter.fileName(generatedAt: generatedAt, calendar: calendar), "Inflamend-Doctor-Report-2026-06-02.txt")
    }

    func testDoctorReportExporterUsesLastThirtyDayLoggedAtRange() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let generatedAt = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 12)))
        let recentDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 20, hour: 8)))
        let oldDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 15, hour: 8)))
        let logs = [
            LogEntry(type: .food, title: "Old coffee", sub: "Coffee", loggedAt: oldDate),
            LogEntry(type: .food, title: "Dinner", sub: "Dairy", loggedAt: recentDate),
            LogEntry(type: .bowel, title: "Bristol 6 · urgency 7/10", sub: "visible blood", loggedAt: recentDate)
        ]

        let report = DoctorReportExporter.buildPlainTextReport(
            logs: logs,
            medsTaken: 3,
            medsTotal: 4,
            displayName: "Soham",
            generatedAt: generatedAt,
            calendar: calendar
        )

        XCTAssertTrue(report.contains("Range: Last 30 days (2026-05-04 to 2026-06-02)"))
        XCTAssertTrue(report.contains("Local logs included: 2"))
        XCTAssertTrue(report.contains("Bowel movements logged: 1"))
        XCTAssertTrue(report.contains("Blood flags: 1"))
        XCTAssertTrue(report.contains("Dairy appeared in 1 food log; frequency only, not a trigger claim."))
        XCTAssertFalse(report.contains("Coffee appeared"))
        XCTAssertFalse(report.contains("Old coffee"))
    }

    func testDoctorReportExporterUsesTypedPayloadBloodAndFoodTags() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let generatedAt = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 12)))
        let logs = [
            LogEntry(
                type: .food,
                title: "Breakfast",
                sub: "Tracked",
                loggedAt: generatedAt,
                payload: .food(mealTime: "breakfast", description: "Breakfast", tags: ["Caffeine"])
            ),
            LogEntry(
                type: .bowel,
                title: "Bowel movement",
                sub: "Tracked",
                loggedAt: generatedAt,
                payload: .bowel(bristol: 6, urgency: 7, blood: .visible, mucus: false, pain: 4, nighttime: false)
            )
        ]

        let report = DoctorReportExporter.buildPlainTextReport(
            logs: logs,
            medsTaken: 3,
            medsTotal: 4,
            displayName: "Soham",
            generatedAt: generatedAt,
            calendar: calendar
        )

        XCTAssertTrue(report.contains("Blood flags: 1"))
        XCTAssertTrue(report.contains("Coffee appeared in 1 food log; frequency only, not a trigger claim."))
        XCTAssertFalse(report.contains("Caffeine appeared"))
    }

    func testUserDataExporterBuildsLocalJSONSnapshot() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let generatedAt = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 2)))
        let snapshot = AppSnapshot(
            authSession: .local(email: "export@example.com", displayName: "Export Patient"),
            onboardingProfile: OnboardingProfile(
                diagnosis: "Ulcerative colitis",
                primaryGoal: "Prepare doctor reports",
                baselineStoolCount: 3,
                hasFlarePlan: true,
                skippedSensitiveQuestions: false,
                completedAt: generatedAt
            ),
            riskScore: 38,
            mood: .ok,
            medsTaken: 2,
            medsTotal: 4,
            latestSafetyMessage: nil,
            aiMemoryEnabled: false,
            voiceTranscriptStorageEnabled: false,
            lastSyncStatus: "Saved locally",
            logs: [
                LogEntry(type: .note, title: "Exported note", sub: "Local only", time: "8:00am")
            ],
            chatMessages: [
                ChatMessage(role: .assistant, content: "Local message")
            ]
        )

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-user-data-\(UUID().uuidString)", isDirectory: true)
        let export = try UserDataExporter.writeJSONExport(
            snapshot: snapshot,
            generatedAt: generatedAt,
            directory: directory,
            calendar: calendar
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(UserDataExportPayload.self, from: Data(export.content.utf8))

        XCTAssertEqual(export.fileName, "Inflamend-User-Data-2026-06-02.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: export.fileURL.path))
        XCTAssertTrue(export.content.contains(UserDataExporter.privacyNotice))
        XCTAssertEqual(decoded.snapshot.authSession?.email, "export@example.com")
        XCTAssertEqual(decoded.snapshot.logs.first?.title, "Exported note")

        try? FileManager.default.removeItem(at: directory)
    }

    func testCareResponseBlocksMedicationChangeAdvice() {
        let response = CareResponseService.respond(to: "Should I stop mesalamine if my flare feels bad?")

        XCTAssertFalse(response.redFlagAssessment.hasRedFlags)
        XCTAssertTrue(response.message.contains("can't recommend"))
        XCTAssertTrue(response.message.contains("GI clinician or pharmacist"))
        XCTAssertFalse(response.message.contains("You should stop"))
    }

    func testCareResponseUsesRedFlagSafetyBeforeGeneralAdvice() {
        let response = CareResponseService.respond(to: "I have severe abdominal pain and lots of blood")

        XCTAssertTrue(response.redFlagAssessment.hasRedFlags)
        XCTAssertTrue(response.message.contains("urgent medical care"))
        XCTAssertFalse(response.message.contains("track context"))
    }

    func testCareFoodResponseAvoidsTriggerClaims() {
        let response = CareResponseService.respond(to: "What should I eat tonight during a flare?")

        XCTAssertFalse(response.redFlagAssessment.hasRedFlags)
        XCTAssertTrue(response.message.contains("log what you try"))
        XCTAssertTrue(response.message.contains("should not label foods as triggers"))
        XCTAssertFalse(response.message.contains("works best for you"))
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

    func testInsightSummaryRecentRangeUsesLoggedAtDates() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let endingAt = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 12)))
        let recentDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 8)))
        let oldDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 10, hour: 8)))
        let logs = [
            LogEntry(type: .bowel, title: "Bristol 6 · urgency 4/10", sub: "no blood", loggedAt: recentDate),
            LogEntry(type: .symptom, title: "Pain 2/10 · fatigue 3/10", sub: "Mood 6/10", loggedAt: recentDate),
            LogEntry(type: .food, title: "Dinner", sub: "Dairy", loggedAt: oldDate),
            LogEntry(type: .checkin, title: "Flare check-in · pain 9/10", sub: "Fatigue 9/10 · urgency 8/10 · stool 6", loggedAt: oldDate)
        ]

        let recentSummary = InsightSummaryBuilder.build(
            logs: logs,
            recentDays: 7,
            endingAt: endingAt,
            calendar: calendar
        )
        let allSummary = InsightSummaryBuilder.build(logs: logs)

        XCTAssertEqual(recentSummary.logCount, 2)
        XCTAssertEqual(recentSummary.painValues, [2])
        XCTAssertEqual(recentSummary.averagePain ?? -1, 2.0, accuracy: 0.001)
        XCTAssertEqual(recentSummary.bowelLogCount, 1)
        XCTAssertEqual(recentSummary.flareMentionCount, 0)
        XCTAssertFalse(recentSummary.foodPatterns.contains { $0.label == "Dairy" })
        XCTAssertEqual(allSummary.logCount, 4)
        XCTAssertEqual(allSummary.averagePain ?? -1, 5.5, accuracy: 0.001)
        XCTAssertEqual(allSummary.flareMentionCount, 1)
        XCTAssertTrue(allSummary.foodPatterns.contains { $0.label == "Dairy" })
    }

    func testInsightSummaryPrefersTypedPayloadOverDisplayText() {
        let logs = [
            LogEntry(
                type: .food,
                title: "Meal without visible tags",
                sub: "Tracked",
                payload: .food(mealTime: "lunch", description: "Meal without visible tags", tags: ["Raw veg", "Caffeine"])
            ),
            LogEntry(
                type: .bowel,
                title: "Bowel movement pain 9/10",
                sub: "fatigue 9/10",
                payload: .bowel(bristol: 6, urgency: 7, blood: .none, mucus: false, pain: 9, nighttime: false)
            ),
            LogEntry(
                type: .symptom,
                title: "Symptoms logged",
                sub: "No numeric summary",
                payload: .symptom(pain: 3, fatigue: 4, mood: 5)
            ),
            LogEntry(
                type: .checkin,
                title: "Daily update",
                sub: "No numeric summary",
                payload: .checkIn(
                    status: .flare,
                    pain: 6,
                    fatigue: 7,
                    urgency: 8,
                    stoolCount: 4,
                    bloodPresent: false,
                    medicationTaken: true
                )
            )
        ]

        let summary = InsightSummaryBuilder.build(logs: logs)

        XCTAssertEqual(summary.painValues, [6, 3])
        XCTAssertEqual(summary.fatigueValues, [7, 4])
        XCTAssertTrue(summary.bowelValues.contains(4))
        XCTAssertEqual(summary.flareMentionCount, 1)
        XCTAssertTrue(summary.foodPatterns.contains { $0.label == "Raw vegetables" })
        XCTAssertTrue(summary.foodPatterns.contains { $0.label == "Coffee" })
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
    func testAppStatePersistsStructuredLogTimestamp() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-log-timestamp-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let loggedAt = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 13, minute: 15)))

        let appState = AppState(store: store)
        appState.signUp(email: "timestamp@example.com", displayName: "Timestamp")
        appState.addLog(type: .note, title: "Timestamped note", sub: "Structured", date: loggedAt)

        XCTAssertEqual(appState.logs.first?.loggedAt, loggedAt)
        XCTAssertFalse(appState.logs.first?.time.isEmpty ?? true)

        let restored = AppState(store: store)
        XCTAssertEqual(restored.logs.first?.title, "Timestamped note")
        XCTAssertEqual(restored.logs.first?.loggedAt, loggedAt)
        XCTAssertEqual(restored.logs.first?.time, appState.logs.first?.time)

        store.delete()
    }

    @MainActor
    func testAppStatePersistsTypedLogPayloadAndLegacyPayloadDecode() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-log-payload-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        let appState = AppState(store: store)
        appState.signUp(email: "payload@example.com", displayName: "Payload")
        appState.recordBowel(bristol: 6, urgency: 7, blood: .visible, mucus: true, pain: 5, nighttime: false)

        XCTAssertEqual(appState.logs.first?.payload?.kind, .bowel)
        XCTAssertEqual(appState.logs.first?.payload?.bristolType, 6)
        XCTAssertEqual(appState.logs.first?.payload?.blood, .visible)

        let restored = AppState(store: store)
        XCTAssertEqual(restored.logs.first?.payload?.kind, .bowel)
        XCTAssertEqual(restored.logs.first?.payload?.mucus, true)
        XCTAssertEqual(restored.logs.first?.payload?.painScore, 5)

        let legacyLogJSON = """
        {
          "id": "99999999-9999-9999-9999-999999999999",
          "type": "food",
          "title": "Legacy meal",
          "sub": "Dairy",
          "time": "8:00am",
          "loggedAt": "2026-06-02T08:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let legacyLog = try decoder.decode(LogEntry.self, from: Data(legacyLogJSON.utf8))
        XCTAssertNil(legacyLog.payload)
        XCTAssertEqual(legacyLog.title, "Legacy meal")

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
        let idempotencyKeys = appState.pendingSyncMutations.map(\.idempotencyKey)
        XCTAssertEqual(Set(idempotencyKeys).count, idempotencyKeys.count)
        XCTAssertTrue(idempotencyKeys.allSatisfy { !$0.isEmpty && $0.hasPrefix("inflamend.") })

        appState.retryPendingSyncScaffold()
        XCTAssertTrue(appState.pendingSyncMutations.allSatisfy { $0.status == .blockedNoBackend })
        XCTAssertTrue(appState.lastSyncStatus.contains("Supabase not configured"))

        let restored = AppState(store: store)
        XCTAssertEqual(restored.pendingSyncCount, appState.pendingSyncCount)
        XCTAssertTrue(restored.pendingSyncMutations.contains { $0.kind == .healthLog })
        XCTAssertTrue(restored.pendingSyncMutations.contains { $0.kind == .onboardingProfile })
        XCTAssertEqual(
            Set(restored.pendingSyncMutations.map(\.idempotencyKey)),
            Set(appState.pendingSyncMutations.map(\.idempotencyKey))
        )

        store.delete()
    }

    @MainActor
    func testDeleteLogRemovesEntryAndCoalescesPendingCreate() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-delete-log-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        let appState = AppState(store: store)
        appState.signUp(email: "delete-log@example.com", displayName: "Delete Log")
        appState.addLog(type: .note, title: "Mistaken note", sub: "Remove")

        let logID = appState.logs[0].id
        XCTAssertTrue(appState.pendingSyncMutations.contains { $0.kind == .healthLog && $0.localRecordId == logID.uuidString })

        appState.deleteLog(id: logID)

        XCTAssertFalse(appState.logs.contains { $0.id == logID })
        XCTAssertFalse(appState.pendingSyncMutations.contains { $0.kind == .healthLog && $0.localRecordId == logID.uuidString })
        XCTAssertFalse(appState.pendingSyncMutations.contains { $0.kind == .healthLogDeletion && $0.localRecordId == logID.uuidString })

        let syncedLikeEntry = LogEntry(type: .food, title: "Existing backend food", sub: "Local copy", time: "8:00am")
        appState.logs = [syncedLikeEntry]
        appState.deleteLog(id: syncedLikeEntry.id)

        XCTAssertTrue(appState.logs.isEmpty)
        XCTAssertTrue(appState.pendingSyncMutations.contains { $0.kind == .healthLogDeletion && $0.localRecordId == syncedLikeEntry.id.uuidString })

        store.delete()
    }

    @MainActor
    func testUndoDeleteRestoresLogAndPendingMutations() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-undo-delete-log-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        let appState = AppState(store: store)
        appState.signUp(email: "undo-delete@example.com", displayName: "Undo Delete")
        appState.addLog(type: .note, title: "Undoable note", sub: "Restore")

        let createdLogID = appState.logs[0].id
        let createdMutationID = appState.pendingSyncMutations.first {
            $0.kind == .healthLog && $0.localRecordId == createdLogID.uuidString
        }?.id
        guard let createdMutationID else {
            XCTFail("Expected pending create mutation before delete")
            store.delete()
            return
        }

        appState.deleteLog(id: createdLogID)
        XCTAssertFalse(appState.logs.contains { $0.id == createdLogID })
        XCTAssertFalse(appState.pendingSyncMutations.contains {
            $0.kind == .healthLog && $0.localRecordId == createdLogID.uuidString
        })
        XCTAssertEqual(appState.toastActionTitle, "Undo")

        appState.performToastAction()
        XCTAssertEqual(appState.logs.first?.id, createdLogID)
        XCTAssertTrue(appState.pendingSyncMutations.contains {
            $0.id == createdMutationID && $0.kind == .healthLog && $0.localRecordId == createdLogID.uuidString
        })
        XCTAssertEqual(appState.toast, "Log restored")

        let existingEntry = LogEntry(type: .food, title: "Existing food", sub: "Local copy", time: "8:00am")
        appState.logs = [existingEntry]
        XCTAssertTrue(appState.updateLog(id: existingEntry.id, title: "Existing food edited", sub: "Dinner detail"))
        let updateMutationID = appState.pendingSyncMutations.first {
            $0.kind == .healthLogUpdate && $0.localRecordId == existingEntry.id.uuidString
        }?.id
        guard let updateMutationID else {
            XCTFail("Expected pending update mutation before delete")
            store.delete()
            return
        }

        appState.deleteLog(id: existingEntry.id)
        XCTAssertFalse(appState.pendingSyncMutations.contains {
            $0.kind == .healthLogUpdate && $0.localRecordId == existingEntry.id.uuidString
        })
        XCTAssertTrue(appState.pendingSyncMutations.contains {
            $0.kind == .healthLogDeletion && $0.localRecordId == existingEntry.id.uuidString
        })

        appState.performToastAction()
        XCTAssertEqual(appState.logs.first?.id, existingEntry.id)
        XCTAssertFalse(appState.pendingSyncMutations.contains {
            $0.kind == .healthLogDeletion && $0.localRecordId == existingEntry.id.uuidString
        })
        XCTAssertTrue(appState.pendingSyncMutations.contains {
            $0.id == updateMutationID && $0.kind == .healthLogUpdate && $0.localRecordId == existingEntry.id.uuidString
        })

        store.delete()
    }

    @MainActor
    func testUpdateLogPersistsAndCoalescesPendingCreate() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-update-log-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        let appState = AppState(store: store)
        appState.signUp(email: "update-log@example.com", displayName: "Update Log")
        appState.addLog(type: .note, title: "Original note", sub: "Original detail", payload: .note("Original note"))

        let logID = appState.logs[0].id
        XCTAssertTrue(appState.updateLog(id: logID, title: " Updated note ", sub: " Updated detail "))
        XCTAssertEqual(appState.logs[0].title, "Updated note")
        XCTAssertEqual(appState.logs[0].sub, "Updated detail")
        XCTAssertNil(appState.logs[0].payload)
        XCTAssertTrue(appState.pendingSyncMutations.contains {
            $0.kind == .healthLog && $0.localRecordId == logID.uuidString && $0.summary.contains("Updated note")
        })
        XCTAssertFalse(appState.pendingSyncMutations.contains {
            $0.kind == .healthLogUpdate && $0.localRecordId == logID.uuidString
        })

        let restored = AppState(store: store)
        XCTAssertEqual(restored.logs[0].title, "Updated note")
        XCTAssertEqual(restored.logs[0].sub, "Updated detail")

        let syncedLikeEntry = LogEntry(type: .food, title: "Existing food", sub: "Local copy", time: "8:00am")
        appState.logs = [syncedLikeEntry]
        XCTAssertTrue(appState.updateLog(id: syncedLikeEntry.id, title: "Existing food edited", sub: "Dinner detail"))
        XCTAssertTrue(appState.updateLog(id: syncedLikeEntry.id, title: "Existing food edited again", sub: "Second dinner detail"))
        XCTAssertTrue(appState.pendingSyncMutations.contains {
            $0.kind == .healthLogUpdate && $0.localRecordId == syncedLikeEntry.id.uuidString && $0.summary.contains("Existing food edited again")
        })
        XCTAssertEqual(appState.pendingSyncMutations.filter {
            $0.kind == .healthLogUpdate && $0.localRecordId == syncedLikeEntry.id.uuidString
        }.count, 1)
        XCTAssertFalse(appState.updateLog(id: syncedLikeEntry.id, title: "   ", sub: "Blank title"))

        store.delete()
    }

    @MainActor
    func testSyncReplayPlanRoutesMutationsAndStoresBlockedErrors() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-sync-plan-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        let appState = AppState(store: store)
        appState.signUp(email: "sync-plan@example.com", displayName: "Sync Plan")
        appState.completeOnboarding(
            diagnosis: "Ulcerative colitis",
            primaryGoal: "Track flares",
            baselineStoolCount: 2,
            hasFlarePlan: false
        )
        appState.addLog(type: .note, title: "Create note", sub: "Replay me")

        let existingEntry = LogEntry(type: .food, title: "Existing food", sub: "Local copy", time: "8:00am")
        appState.logs.insert(existingEntry, at: 0)
        XCTAssertTrue(appState.updateLog(id: existingEntry.id, title: "Existing food edited", sub: "Dinner detail"))
        XCTAssertTrue(appState.pendingSyncMutations.contains {
            $0.kind == .healthLogUpdate && $0.localRecordId == existingEntry.id.uuidString
        })

        appState.deleteLog(id: existingEntry.id)
        XCTAssertFalse(appState.pendingSyncMutations.contains {
            $0.kind == .healthLogUpdate && $0.localRecordId == existingEntry.id.uuidString
        })
        XCTAssertTrue(appState.pendingSyncMutations.contains {
            $0.kind == .healthLogDeletion && $0.localRecordId == existingEntry.id.uuidString
        })

        appState.setAIMemoryEnabled(true)
        appState.addChatMessage(role: .user, content: "Sync this consented Care message")

        let plan = appState.pendingSyncReplayPlan
        XCTAssertTrue(plan.contains { $0.kind == .authSession && $0.action == .authenticate && $0.target == "supabase.auth.session" })
        XCTAssertTrue(plan.contains { $0.kind == .onboardingProfile && $0.action == .upsert && $0.target == "public.onboarding_responses" })
        XCTAssertTrue(plan.contains { $0.kind == .healthLog && $0.action == .upsert && $0.target == "public.log_notes" })
        XCTAssertTrue(plan.contains { $0.kind == .healthLogDeletion && $0.action == .softDelete && $0.requiresReceipt })
        XCTAssertTrue(plan.contains { $0.kind == .privacyPreference && $0.action == .upsert && $0.target == "public.user_settings" })
        XCTAssertTrue(plan.contains { $0.kind == .chatMessage && $0.action == .insert && $0.target == "public.chat_messages" })
        for mutation in appState.pendingSyncMutations {
            let planItem = plan.first { $0.mutationId == mutation.id }
            XCTAssertEqual(planItem?.idempotencyKey, mutation.idempotencyKey)
            XCTAssertEqual(planItem?.serverRecordId, mutation.serverRecordId)
            XCTAssertEqual(planItem?.receiptId, mutation.receiptId)
        }

        appState.retryPendingSyncScaffold()
        XCTAssertTrue(appState.syncSummary.contains("blocked"))
        XCTAssertTrue(appState.pendingSyncMutations.allSatisfy { $0.status == .blockedNoBackend })
        XCTAssertTrue(appState.pendingSyncMutations.allSatisfy { $0.lastAttemptedAt != nil })
        XCTAssertTrue(appState.pendingSyncMutations.allSatisfy { $0.lastError?.contains("Supabase not configured") == true })

        let blockedDeletion = appState.pendingSyncMutations.first {
            $0.kind == .healthLogDeletion && $0.localRecordId == existingEntry.id.uuidString
        }
        XCTAssertEqual(blockedDeletion?.attemptCount, 1)
        XCTAssertTrue(blockedDeletion?.lastError?.contains("softDelete public.log_notes.deleted_at") == true)

        let restored = AppState(store: store)
        XCTAssertEqual(restored.pendingSyncCount, appState.pendingSyncCount)
        XCTAssertTrue(restored.pendingSyncMutations.contains {
            $0.kind == .healthLogDeletion && $0.lastError?.contains("public.log_notes.deleted_at") == true
        })

        store.delete()
    }

    @MainActor
    func testSyncReplayPlanCarriesHealthLogPayloadSnapshots() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-sync-payload-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        let appState = AppState(store: store)
        appState.signUp(email: "sync-payload@example.com", displayName: "Sync Payload")
        appState.addLog(
            type: .food,
            title: "Breakfast",
            sub: "Dairy",
            payload: .food(mealTime: "breakfast", description: "Breakfast", tags: ["Dairy"])
        )

        let createdLog = try XCTUnwrap(appState.logs.first)
        let createMutation = try XCTUnwrap(appState.pendingSyncMutations.first {
            $0.kind == .healthLog && $0.localRecordId == createdLog.id.uuidString
        })
        XCTAssertEqual(createMutation.payload?.kind, .healthLog)
        XCTAssertEqual(createMutation.payload?.healthLog?.title, "Breakfast")
        XCTAssertEqual(createMutation.payload?.healthLog?.typedPayload?.kind, .food)
        XCTAssertEqual(createMutation.payload?.healthLog?.typedPayload?.foodTags, ["Dairy"])

        let restored = AppState(store: store)
        let createPlan = try XCTUnwrap(restored.pendingSyncReplayPlan.first {
            $0.kind == .healthLog && $0.localRecordId == createdLog.id.uuidString
        })
        XCTAssertEqual(createPlan.payload?.kind, createMutation.payload?.kind)
        XCTAssertEqual(createPlan.payload?.healthLog?.localId, createdLog.id.uuidString)
        XCTAssertEqual(createPlan.payload?.healthLog?.title, "Breakfast")
        XCTAssertEqual(createPlan.payload?.healthLog?.typedPayload?.foodTags, ["Dairy"])
        XCTAssertEqual(
            createPlan.payload?.healthLog?.loggedAt.timeIntervalSince1970 ?? 0,
            createdLog.loggedAt.timeIntervalSince1970,
            accuracy: 1
        )

        XCTAssertTrue(restored.updateLog(id: createdLog.id, title: "Breakfast edited", sub: "Edited details"))
        let coalescedCreate = try XCTUnwrap(restored.pendingSyncMutations.first {
            $0.kind == .healthLog && $0.localRecordId == createdLog.id.uuidString
        })
        XCTAssertEqual(coalescedCreate.payload?.healthLog?.title, "Breakfast edited")
        XCTAssertNil(coalescedCreate.payload?.healthLog?.typedPayload)

        let existingEntry = LogEntry(
            type: .food,
            title: "Existing dinner",
            sub: "Coffee",
            payload: .food(mealTime: "dinner", description: "Existing dinner", tags: ["Coffee"])
        )
        restored.logs.insert(existingEntry, at: 0)
        XCTAssertTrue(restored.updateLog(id: existingEntry.id, title: "Existing dinner edited", sub: "Manual edit"))
        let updateMutation = try XCTUnwrap(restored.pendingSyncMutations.first {
            $0.kind == .healthLogUpdate && $0.localRecordId == existingEntry.id.uuidString
        })
        XCTAssertEqual(updateMutation.payload?.healthLog?.title, "Existing dinner edited")
        XCTAssertNil(updateMutation.payload?.healthLog?.typedPayload)

        store.delete()
    }

    func testLegacyPendingSyncMutationDecodesWithReplayMetadata() throws {
        let legacyMutation = """
        {
          "attemptCount": 0,
          "createdAt": "2026-06-02T09:00:00Z",
          "id": "11111111-1111-1111-1111-111111111111",
          "kind": "healthLog",
          "lastError": null,
          "localRecordId": "22222222-2222-2222-2222-222222222222",
          "status": "pending",
          "summary": "Note: legacy"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let mutation = try decoder.decode(PendingSyncMutation.self, from: Data(legacyMutation.utf8))

        XCTAssertEqual(mutation.kind, .healthLog)
        XCTAssertEqual(mutation.localRecordId, "22222222-2222-2222-2222-222222222222")
        XCTAssertTrue(mutation.idempotencyKey.hasPrefix("inflamend.healthLog.22222222-2222-2222-2222-222222222222."))
        XCTAssertNil(mutation.serverRecordId)
        XCTAssertNil(mutation.receiptId)
        XCTAssertNil(mutation.receiptRecordedAt)
        XCTAssertNil(mutation.payload)
    }

    @MainActor
    func testClearAIHistoryLeavesLocalConfirmationMessage() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-clear-ai-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        let appState = AppState(store: store)
        appState.addChatMessage(role: .user, content: "What should I eat?")
        appState.addChatMessage(role: .assistant, content: "Track context.")
        XCTAssertGreaterThan(appState.chatMessages.count, 1)

        appState.clearAIHistory()

        XCTAssertEqual(appState.chatMessages.count, 1)
        XCTAssertTrue(appState.chatMessages[0].content.contains("AI history cleared"))

        store.delete()
    }

    @MainActor
    func testAccountDeletionRequestQueuesAndLogsScaffold() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-delete-account-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        let appState = AppState(store: store)
        appState.signUp(email: "delete@example.com", displayName: "Delete User")
        appState.requestAccountDeletionScaffold()

        XCTAssertTrue(appState.pendingSyncMutations.contains { $0.kind == .accountDeletion })
        XCTAssertTrue(appState.logs.contains { $0.title == "Account deletion requested" })

        store.delete()
    }

    @MainActor
    func testPrepareUserDataExportCreatesLocalFileAndAuditLog() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("inflamend-user-export-state-\(UUID().uuidString).json")
        let store = AppSnapshotStore(fileURL: url)
        store.delete()

        let appState = AppState(store: store)
        appState.signUp(email: "local-export@example.com", displayName: "Local Export")
        appState.addLog(type: .note, title: "Persistent export note", sub: "Included")

        let export = try appState.prepareUserDataExport()

        XCTAssertTrue(FileManager.default.fileExists(atPath: export.fileURL.path))
        XCTAssertTrue(export.content.contains("local-export@example.com"))
        XCTAssertTrue(export.content.contains("Persistent export note"))
        XCTAssertTrue(appState.logs.contains { $0.title == "User data exported" })
        XCTAssertTrue(appState.pendingSyncMutations.contains { $0.kind == .reportExport && $0.summary.contains("User data JSON") })

        try? FileManager.default.removeItem(at: export.fileURL.deletingLastPathComponent())
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
          "logs": [
            {
              "id": "33333333-3333-3333-3333-333333333333",
              "type": "note",
              "title": "Legacy note",
              "sub": "No loggedAt field",
              "time": "8:00am"
            }
          ],
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
        XCTAssertEqual(appState.logs.first?.title, "Legacy note")
        XCTAssertEqual(appState.logs.first?.time, "8:00am")
        XCTAssertLessThan(abs(appState.logs.first?.loggedAt.timeIntervalSinceNow ?? -100), 60)
        XCTAssertTrue(appState.pendingSyncMutations.isEmpty)
        XCTAssertEqual(appState.lastSyncStatus, "Legacy saved")

        store.delete()
    }
}
