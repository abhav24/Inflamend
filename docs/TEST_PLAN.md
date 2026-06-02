# Inflamend Test Plan

## Baseline Test Status

Current automated test status:

```text
xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:InflamendTests
Result: TEST SUCCEEDED.
Coverage: 48 unit tests in HealthLogicTests plus 28 UI smoke tests in InflamendUITests.
```

The previous blocker, missing test target/test action, is resolved.
The app now has both unit and UI test targets wired into the shared `Inflamend` scheme.

Latest checkpoint verification:

```text
xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:InflamendTests/HealthLogicTests/testOfflineReachabilityPausesSyncRetryWithoutMutatingQueue
Result: TEST SUCCEEDED with 1 focused unit test.

xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:InflamendTests/HealthLogicTests/testAutomaticSyncRetryRunsOnlyDueMutationsWhenOnline
Result: TEST SUCCEEDED with 1 focused unit test.

xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:InflamendTests/HealthLogicTests/testMedicationDoseStatusPersistsAndQueuesStructuredLog
Result: TEST SUCCEEDED with 1 focused unit test.

xcodebuild test -quiet -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:InflamendTests/HealthLogicTests/testMedicationReminderSettingsPersistExportAndQueuePreference
Result: TEST SUCCEEDED with 1 focused unit test.

xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:InflamendUITests/InflamendUITests/testProfileSyncRetryPausesWhenNetworkOfflineSmoke
Result: TEST SUCCEEDED with 1 UI smoke test.

xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:InflamendUITests/InflamendUITests/testProfileSyncRetryShowsBackendBlockedSmoke -only-testing:InflamendUITests/InflamendUITests/testProfileSyncRetryPausesWhenNetworkOfflineSmoke
Result: TEST SUCCEEDED with 2 UI smoke tests.

xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:InflamendUITests/InflamendUITests/testMedicationDoseUpdatesHomeSummarySmoke -only-testing:InflamendUITests/InflamendUITests/testMedicationLogCanBeEditedFromTimelineSmoke
Result: TEST SUCCEEDED with 2 UI smoke tests.

xcodebuild test -quiet -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:InflamendUITests/InflamendUITests/testProfileMedicationReminderSettingsSmoke
Result: TEST SUCCEEDED with 1 UI smoke test.

xcodebuild test -quiet -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:InflamendTests
Result: TEST SUCCEEDED with 48 unit tests.

xcodebuild clean build -quiet -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
Result: BUILD SUCCEEDED.
```

## Unit Test Priorities

1. Red-flag detection:
- Severe abdominal pain.
- Heavy bleeding or black/tarry stool.
- High fever.
- Fainting.
- Severe dehydration or inability to keep fluids down.
- Chest pain or shortness of breath.
- Rapid weight loss or rapid worsening.
- Suicidal ideation/self-harm language.

Status: started. Text and structured bowel-log red flags are covered.

2. Risk score logic:
- Low-risk baseline.
- Increased bowel frequency.
- Blood present.
- High urgency.
- High pain.
- Poor sleep.
- Missed medication.
- Rapid worsening.
- Score caps at 0 and 100.
- Returned factors use cautious, non-diagnostic wording.

Status: started. Stable and high-risk scenarios are covered.

3. Voice parsing:
- Meal logging examples.
- Bowel movement examples.
- Medication taken examples.
- Symptom check-in examples.
- Note examples.
- Sleep examples.
- Weight examples.
- Ambiguous transcript handling.
- No auto-save without confirmation.

Status: started. Bowel, medication, and weight examples are covered, including spoken number words.

4. Medication schedule calculations:
- Daily, weekly, and multiple-dose schedules.
- Taken/skipped/snoozed status.
- Reminder enablement and lead-time preferences.
- Missed-dose history.
- Timezone-safe date grouping.

Status: started. Twice-daily schedule calculation, persisted dose status, skipped status snapshot restore, local reminder preference persistence/export/replay, and structured medication replay payloads are covered.

5. Report generation:
- 7-day, 30-day, and custom range summaries.
- BM frequency and Bristol distribution.
- Blood/urgency flags.
- Medication adherence summary.
- Notes and doctor questions.
- CSV/plain text export shape.
- Full local user-data JSON export shape.

Status: started. Plain-text report wording, possible-pattern language, local doctor-report content generation, 30-day `loggedAt` range filtering, typed blood payload and food-tag report extraction, Profile doctor-report export UI, and local user-data JSON export are covered.

6. Offline/sync queue:
- Pending mutation enqueue.
- Retry state blocked by missing backend setup.
- Local deletion coalesces unreplayed health-log creates and queues deletion mutations for existing records.
- Timeline deletion undo restores the local row, restores pending create/update mutations, and removes staged delete mutations.
- Local edits coalesce into unreplayed health-log creates or queue update mutations for existing records.
- Replay plan routes each pending mutation to a future Supabase table/function action.
- Replay metadata carries stable idempotency keys plus optional server record and receipt IDs.
- Replay payload snapshots carry typed health-log create/update fields into future backend plans.
- Backend-blocked retries store per-record attempt timestamps and error details.
- Automatic retry execution runs only due blocked/retryable mutations while online and leaves non-due or offline records untouched.
- Legacy queued mutations decode with generated idempotency metadata.
- Legacy queued mutations without replay payload snapshots decode safely.
- Structured log timestamps persist and legacy timeline logs without `loggedAt` decode safely.
- Typed local log payloads persist and legacy timeline logs without `payload` decode safely.
- Home timeline text edits preserve existing typed payloads for display-only changes, food timeline edits can replace typed meal/tag payloads, bowel timeline edits can replace typed Bristol/blood/pain fields and publish safety guidance, symptom timeline edits can replace typed pain/fatigue/mood fields and publish safety guidance, sleep timeline edits can replace typed quality/wake fields, weight timeline edits can replace typed value/unit fields, medication timeline edits can replace typed dose status fields and reconcile adherence state, check-in timeline edits can replace typed status/pain/fatigue/urgency/stool/blood/medication-taken fields and refresh mood/risk/safety/adherence state, while generic model edits can still clear stale typed payloads until broader type-specific edit forms exist.
- Conflict state.
- Last sync timestamp.
- No data loss after app restart once persistence exists.

Status: local snapshot restore, structured log timestamp and typed payload persistence, pending queue persistence, local log edit/delete/undo queue behavior, timeline edit typed-payload preservation, food/bowel/symptom/sleep/weight/medication/check-in structured timeline edits, deterministic replay planning with health-log payload snapshots, idempotency/server/receipt metadata, retry backoff metadata, automatic due-retry execution, reachability-aware offline retry pause, per-record backend-blocked errors, Profile sync blocked/offline-state detail UI, legacy snapshot/mutation decode, and corrupt snapshot fallback are covered. Network replay, returned server IDs/receipts, live backend typed-payload serialization, auth refresh, and conflict behavior are pending.

7. Validation helpers:
- Numeric ranges for pain, urgency, Bristol type, weight, sleep, and water.
- Required fields for save actions.
- Safe human-readable errors.

8. Insights:
- Empty states when no local logs exist.
- Pain/fatigue summaries derived from local logs instead of demo arrays.
- Food pattern summaries framed as frequency, not trigger causation.
- Recent-range summaries filter by structured `loggedAt` dates instead of display text.
- Typed payload summaries prefer structured fields over display text, and bowel payload pain is excluded from the overall symptom pain average.

Status: started. Empty, local-log, typed-payload, and 7-day recent summary behavior is covered by unit tests, and no-data plus populated local-log UI smoke coverage exists, including populated chart accessibility summary assertions.

9. Care/AI safety:
- Red-flag prompt bypasses general advice.
- Medication-change prompt refuses prescription-change guidance.
- Food guidance avoids unsupported trigger claims.

Status: started. Local Care response safety behavior is covered by unit tests, and red-flag plus medication-change refusal prompt UI smoke coverage exists.

10. Privacy and destructive actions:
- Local AI history clearing leaves a confirmation message.
- Account deletion requests create a local audit log and pending backend mutation.
- Destructive Profile actions require confirmation before running.

Status: started. Underlying AppState effects are covered; Profile destructive confirmation UI smoke coverage exists.

## UI Test Priorities

- Fresh install shows welcome/auth or Today depending on session scaffold. Status: started; fresh local sign-up UI smoke coverage exists.
- Sign up/sign in with mock service. Status: started; local sign-up and sign-in UI smoke coverage exists.
- Onboarding can be completed or skipped for sensitive fields. Status: started; default onboarding completion UI smoke coverage exists.
- Today check-in can be saved in under 30 seconds and corrected from the timeline. Status: covered by UI smoke tests.
- Timeline log deletion requires confirmation. Status: covered by UI smoke test.
- Timeline log deletion can be undone before the toast expires. Status: covered by UI smoke test.
- Timeline log editing updates a local row without changing entry count. Status: covered by UI smoke test, including structured food retagging plus structured bowel, symptom, sleep, weight, medication, and check-in correction through the timeline edit sheet.
- Bowel movement log with blood shows safety guidance. Status: covered by UI smoke test, including timeline correction from significant blood to no blood plus mucus.
- Food log saves as pattern tracking, not nutrition claims. Status: covered by UI smoke test, including timeline retagging from Dairy to Rice.
- Symptom log saves and structured pain/fatigue/mood edits are visible from Home. Status: covered by UI smoke test, including pain edit to 8/10 and safety card verification.
- Sleep log saves and structured quality/wake edits are visible from Home. Status: covered by UI smoke test, including quality edit to 9/10 and wake edit to 3.
- Weight log saves and structured value edits are visible from Home. Status: covered by UI smoke test, including 62.4 kg edit to 63.0 kg.
- Medication taken/skipped changes adherence state. Status: dose-taken path, persisted skipped status, local reminder settings, and timeline status correction covered by unit and UI smoke tests.
- Voice permission denied state is understandable. Status: deterministic denied-state scaffold covered by UI smoke test; real native Speech/microphone permission requests remain pending Apple setup.
- Voice transcript confirmation can be edited before saving. Status: covered by UI smoke test.
- Insights empty state avoids fake claims. Status: covered by UI smoke test.
- Populated Insights uses local logs, typed payloads, frequency framing, recent `loggedAt` filtering, and chart accessibility summaries. Status: covered by UI smoke test plus unit date-range/payload coverage.
- Care red-flag prompt shows urgent safety guidance and no diagnosis claim. Status: covered by UI smoke test.
- Care medication-change prompt refuses prescription advice and points to a clinician/pharmacist. Status: covered by UI smoke test.
- Report export scaffold explains missing setup or creates local export. Status: local doctor-report export covered by UI smoke test; 30-day `loggedAt` range filtering covered by unit test.
- Profile sync status shows pending/backend-blocked/offline state. Status: pending local queue, blocked retry state, next-retry detail text, reachability status, offline retry pause, and per-record detail sheet covered by UI smoke tests; backend network replay pending.
- Privacy controls expose export/delete/AI memory/transcript toggles. Status: covered for local export/delete confirmations plus AI memory and voice transcript toggles by UI smoke tests; backend enforcement pending.
- Dark mode, Dynamic Type, and VoiceOver labels for major screens.

## Backend Verification Plan

When Supabase CLI and credentials are available:

- Apply migrations cleanly on a local Supabase instance.
- Verify every user-owned table has RLS enabled.
- Verify own-user select/insert/update/delete succeeds.
- Verify cross-user access is denied.
- Verify Edge Functions reject unauthenticated requests.
- Verify Edge Functions never trust client-provided `user_id`.
- Verify health-log create/update replay serializes typed payload snapshots into approved backend columns or JSONB without logging PHI.
- Verify seed data creates realistic development records without PHI.
- Verify AI provider keys and service role keys are only server-side secrets.

## Manual QA Matrix

| Area | Scenario | Expected Result | Status |
|---|---|---|---|
| Install | Fresh install | Starts without crash | Pending |
| Auth | Logged out | Shows welcome/sign in/up scaffold | Implemented and covered by fresh auth UI smoke tests |
| Auth | Sign out | Session clears, no stale PHI visible | Implemented locally and covered by UI smoke test |
| Onboarding | Sensitive questions skipped | App remains usable | Implemented and covered by default onboarding UI smoke test |
| Today | Check-in saved and corrected | Today, risk score, safety state, mood, and adherence update | Implemented locally and covered by UI smoke tests |
| Logging | Edit timeline entry | Local title/details update without changing entry count | Implemented locally and covered by UI smoke test; Home timeline edits preserve typed payloads and replay snapshots for display-only changes; food timeline edits can update meal/tags; bowel timeline edits can update Bristol/blood/pain fields and safety guidance; symptom timeline edits can update pain/fatigue/mood fields and safety guidance; sleep timeline edits can update quality/wake fields; weight timeline edits can update value/unit fields; medication timeline edits can update dose status and adherence state; check-in timeline edits can update status, pain, fatigue, urgency, stool count, blood, medication-taken state, and derived mood/risk/safety/adherence state; generic model edits can still clear payloads; backend update replay is pending |
| Logging | Delete timeline entry | Confirmation appears before a local log is removed | Implemented locally and covered by UI smoke test; backend delete replay planned but not connected |
| Logging | Undo timeline deletion | Recently deleted local row is restored and pending sync mutations are restored/coalesced safely | Implemented locally and covered by unit plus UI smoke tests; backend delete/update replay still pending |
| Logging | BM with blood | Log saves and red-flag guidance appears | Implemented locally and covered by UI smoke test, including structured timeline bowel editing |
| Logging | Meal log | Food pattern entry saves without nutrition claims | Implemented locally and covered by UI smoke test, including timeline food tag editing |
| Logging | Symptom log | Pain, fatigue, and mood save and can be corrected from Home | Implemented locally and covered by UI smoke test |
| Logging | Sleep log | Sleep quality and bathroom wakes save and can be corrected from Home | Implemented locally and covered by UI smoke test |
| Logging | Weight log | Weight value saves and can be corrected from Home | Implemented locally and covered by UI smoke test |
| Medications | Dose taken/status corrected/reminder preference changed | Adherence state updates and reminder intent persists | Implemented locally with persisted dose statuses and reminder settings; covered by unit/UI smoke tests for dose taken, skipped persistence, Profile reminder settings, and timeline status correction |
| Voice | Permission denied | Manual fallback shown | Deterministic denied-state scaffold covered by UI smoke test; real OS permission prompt/native capture pending Apple Speech/microphone setup |
| Voice | Parsed transcript | Confirmation screen required before save | Implemented locally and covered by UI smoke test; native Speech/microphone integration pending |
| AI | Red-flag prompt | Urgent care guidance, no diagnosis | Implemented and covered by Care UI smoke test |
| AI | Medication-change prompt | Advises clinician/pharmacist, no prescription change | Implemented locally and covered by UI smoke test |
| Insights | No data | Empty state, no fake claims | Implemented locally and covered by UI smoke test |
| Insights | Local logs present | Charts, stats, and food patterns populate from recent local logs without trigger claims | Implemented locally with typed payloads and 7-day `loggedAt` filtering, covered by UI smoke and unit tests; chart accessibility summaries implemented and UI-asserted; manual VoiceOver/Dynamic Type pending |
| Reports | Export | Plain text/CSV/PDF scaffold behaves safely | Local shareable 30-day text report implemented with typed blood/tag payload extraction and covered by UI smoke and unit tests; CSV/PDF/backend export pending |
| Privacy | Export data | User-visible export path creates shareable local JSON | Implemented locally and covered by UI smoke test; backend export pending |
| Privacy | AI memory toggle | Visible Off/On state updates and local preference persists | Implemented locally and covered by UI smoke test; backend AI enforcement pending |
| Privacy | Voice transcript storage toggle | Visible Off/On state updates and local preference persists | Implemented locally and covered by UI smoke test; backend retention enforcement pending |
| Privacy | Delete AI history | Confirmation before local message clearing | Implemented locally and covered by UI smoke test |
| Privacy | Delete data/account | Confirmation before local deletion-request scaffold | Implemented locally and covered by UI smoke test; backend deletion pending |
| Offline | Log while offline | Local save or safe failure | Local snapshot, structured log timestamps, typed payload persistence, food/bowel/symptom/sleep/weight/medication/check-in structured timeline edits, pending queue, health-log replay payload snapshots, replay planning with idempotency metadata, retry backoff metadata, automatic due-retry execution, reachability-aware retry pause, and per-record blocked errors implemented; Profile sync detail sheet exposes blocked/offline records and retry metadata under UI smoke coverage; backend network replay pending |
| Accessibility | Dynamic Type | Text remains readable and non-overlapping | Pending |
| Accessibility | VoiceOver | Controls have useful labels | Pending |

## Current Unit Test List

- `testRedFlagDetectorFindsHeavyBleedingAndSeverePain`
- `testStructuredBowelLogCanTriggerRedFlag`
- `testRiskScoreUsesCautiousDeterministicFactors`
- `testRiskScoreStaysLowForStableInputs`
- `testVoiceParserParsesBowelMovementWithoutAutosave`
- `testVoiceParserParsesMedication`
- `testVoiceParserParsesWeight`
- `testMedicationScheduleCalculatesTwiceDailyDoses`
- `testMedicationDoseStatusPersistsAndQueuesStructuredLog`
- `testReportSummaryUsesPossiblePatternLanguage`
- `testDoctorReportExporterBuildsLocalLogReportWithoutTriggerClaims`
- `testDoctorReportExporterUsesLastThirtyDayLoggedAtRange`
- `testDoctorReportExporterUsesTypedPayloadBloodAndFoodTags`
- `testUserDataExporterBuildsLocalJSONSnapshot`
- `testCareResponseBlocksMedicationChangeAdvice`
- `testCareResponseUsesRedFlagSafetyBeforeGeneralAdvice`
- `testCareFoodResponseAvoidsTriggerClaims`
- `testValidationHelpers`
- `testAppStatePersistsSessionOnboardingLogsAndPrivacyPreferences`
- `testAppStatePersistsStructuredLogTimestamp`
- `testAppStatePersistsTypedLogPayloadAndLegacyPayloadDecode`
- `testPendingSyncQueuePersistsAndMarksBlockedWithoutBackend`
- `testOfflineReachabilityPausesSyncRetryWithoutMutatingQueue`
- `testClearAIHistoryLeavesLocalConfirmationMessage`
- `testAccountDeletionRequestQueuesAndLogsScaffold`
- `testPrepareUserDataExportCreatesLocalFileAndAuditLog`
- `testCorruptSnapshotFallsBackToCleanState`
- `testLegacySnapshotWithoutQueueStillDecodes`
- `testInsightSummaryReturnsEmptyStateForNoLogs`
- `testInsightSummaryUsesLocalLogsWithoutDemoData`
- `testInsightSummaryRecentRangeUsesLoggedAtDates`
- `testInsightSummaryPrefersTypedPayloadOverDisplayText`
- `testDeleteLogRemovesEntryAndCoalescesPendingCreate`
- `testUpdateLogPersistsAndCoalescesPendingCreate`
- `testUpdateLogCanPreserveTypedPayloadsForTimelineEdits`
- `testUpdateLogCanReplaceBowelPayloadAndPublishSafety`
- `testUpdateLogCanReplaceSymptomPayloadAndPublishSafety`
- `testUpdateLogCanReplaceSleepPayloadAndReplaySnapshot`
- `testUpdateLogCanReplaceWeightPayloadAndReplaySnapshot`
- `testUpdateLogCanReplaceMedicationPayloadAndReconcileAdherence`
- `testUpdateLogCanReplaceCheckInPayloadAndRefreshDerivedState`
- `testSyncReplayPlanRoutesMutationsAndStoresBlockedErrors`
- `testSyncReplayPlanCarriesHealthLogPayloadSnapshots`
- `testSyncReplayBackoffSchedulesAndResetsAfterLocalEdit`
- `testAutomaticSyncRetryRunsOnlyDueMutationsWhenOnline`
- `testUndoDeleteRestoresLogAndPendingMutations`
- `testLegacyPendingSyncMutationDecodesWithReplayMetadata`

## Current UI Test List

- `InflamendUITests.testCareRedFlagPromptShowsSafetyGuidanceSmoke`
- `InflamendUITests.testCareMedicationChangePromptRefusesPrescriptionAdviceSmoke`
- `InflamendUITests.testBowelLogWithSignificantBloodShowsSafetyGuidanceSmoke`
- `InflamendUITests.testFoodLogSavesPatternEntrySmoke`
- `InflamendUITests.testFreshSignUpCompletesOnboardingSmoke`
- `InflamendUITests.testInsightsEmptyStateAvoidsDemoClaimsSmoke`
- `InflamendUITests.testInsightsPopulatedSummaryUsesLocalLogsSmoke`
- `InflamendUITests.testLocalSignInReachesOnboardingSmoke`
- `InflamendUITests.testMedicationDoseUpdatesHomeSummarySmoke`
- `InflamendUITests.testMedicationLogCanBeEditedFromTimelineSmoke`
- `InflamendUITests.testCheckInLogCanBeEditedFromTimelineSmoke`
- `InflamendUITests.testProfileDoctorReportExportSheetSmoke`
- `InflamendUITests.testProfileUserDataExportSheetSmoke`
- `InflamendUITests.testProfileDestructiveActionsRequireConfirmation`
- `InflamendUITests.testProfilePrivacyTogglesUpdateVisibleStateSmoke`
- `InflamendUITests.testProfileSignOutReturnsToAuthGateSmoke`
- `InflamendUITests.testProfileSyncRetryShowsBackendBlockedSmoke`
- `InflamendUITests.testProfileSyncRetryPausesWhenNetworkOfflineSmoke`
- `InflamendUITests.testSymptomLogCanBeEditedFromTimelineSmoke`
- `InflamendUITests.testSleepLogCanBeEditedFromTimelineSmoke`
- `InflamendUITests.testWeightLogCanBeEditedFromTimelineSmoke`
- `InflamendUITests.testTimelineEntryDeleteRequiresConfirmationSmoke`
- `InflamendUITests.testTimelineEntryDeleteUndoRestoresLocalRowSmoke`
- `InflamendUITests.testTimelineEntryEditUpdatesLocalRowSmoke`
- `InflamendUITests.testTodayCheckInSavesToTimelineSmoke`
- `InflamendUITests.testVoicePermissionDeniedKeepsManualFallbackSmoke`
- `InflamendUITests.testVoiceTranscriptCanBeEditedBeforeSavingSmoke`

## Device Targets

Available local simulator targets:

- iPhone 17, iOS 26.0, booted.
- iPhone 16e, iOS 26.0.
- iPhone 17 Pro Max, iOS 26.0.
- iPhone Air, iOS 26.0.
- iPad and iPad Pro simulators on iOS 26.0.

Prompt-requested `iPhone 16` is not installed. Use `iPhone 17` for current automated build/test unless a different simulator is added.
