# Inflamend Test Plan

## Baseline Test Status

Current automated test status:

```text
xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
Result: TEST SUCCEEDED.
Coverage: 24 unit tests in HealthLogicTests plus 18 UI smoke tests in InflamendUITests.
```

The previous blocker, missing test target/test action, is resolved.
The app now has both unit and UI test targets wired into the shared `Inflamend` scheme.

Latest checkpoint verification:

```text
xcodebuild clean build -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
Result: BUILD SUCCEEDED.

xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
Result: TEST SUCCEEDED with 42 tests.
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
- Missed-dose history.
- Timezone-safe date grouping.

Status: started. Twice-daily schedule calculation is covered.

5. Report generation:
- 7-day, 30-day, and custom range summaries.
- BM frequency and Bristol distribution.
- Blood/urgency flags.
- Medication adherence summary.
- Notes and doctor questions.
- CSV/plain text export shape.
- Full local user-data JSON export shape.

Status: started. Plain-text report wording, possible-pattern language, local doctor-report content generation, Profile doctor-report export UI, and local user-data JSON export are covered.

6. Offline/sync queue:
- Pending mutation enqueue.
- Retry state blocked by missing backend setup.
- Conflict state.
- Last sync timestamp.
- No data loss after app restart once persistence exists.

Status: local snapshot restore, pending queue persistence, backend-blocked retry, Profile sync blocked-state UI, legacy decode, and corrupt snapshot fallback are covered. Network replay and conflict behavior are pending.

7. Validation helpers:
- Numeric ranges for pain, urgency, Bristol type, weight, sleep, and water.
- Required fields for save actions.
- Safe human-readable errors.

8. Insights:
- Empty states when no local logs exist.
- Pain/fatigue summaries derived from local logs instead of demo arrays.
- Food pattern summaries framed as frequency, not trigger causation.

Status: started. Empty and local-log summary behavior is covered by unit tests, and no-data plus populated local-log UI smoke coverage exists.

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
- Today check-in can be saved in under 30 seconds. Status: covered by UI smoke test.
- Bowel movement log with blood shows safety guidance. Status: covered by UI smoke test.
- Food log saves as pattern tracking, not nutrition claims. Status: covered by UI smoke test.
- Medication taken/skipped changes adherence state. Status: dose-taken path covered by UI smoke test.
- Voice permission denied state is understandable. Status: deterministic denied-state scaffold covered by UI smoke test; real native Speech/microphone permission requests remain pending Apple setup.
- Voice transcript confirmation can be edited before saving. Status: covered by UI smoke test.
- Insights empty state avoids fake claims. Status: covered by UI smoke test.
- Populated Insights uses local logs and frequency framing. Status: covered by UI smoke test.
- Care red-flag prompt shows urgent safety guidance and no diagnosis claim. Status: covered by UI smoke test.
- Care medication-change prompt refuses prescription advice and points to a clinician/pharmacist. Status: covered by UI smoke test.
- Report export scaffold explains missing setup or creates local export. Status: local doctor-report export covered by UI smoke test.
- Profile sync status shows pending/backend-blocked state. Status: pending local queue and blocked retry state covered by UI smoke test; backend replay pending.
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
- Verify seed data creates realistic development records without PHI.
- Verify AI provider keys and service role keys are only server-side secrets.

## Manual QA Matrix

| Area | Scenario | Expected Result | Status |
|---|---|---|---|
| Install | Fresh install | Starts without crash | Pending |
| Auth | Logged out | Shows welcome/sign in/up scaffold | Implemented and covered by fresh auth UI smoke tests |
| Auth | Sign out | Session clears, no stale PHI visible | Implemented locally and covered by UI smoke test |
| Onboarding | Sensitive questions skipped | App remains usable | Implemented and covered by default onboarding UI smoke test |
| Today | Check-in saved | Today and risk score update | Implemented locally and covered by UI smoke test |
| Logging | BM with blood | Log saves and red-flag guidance appears | Implemented locally and covered by UI smoke test |
| Logging | Meal log | Food pattern entry saves without nutrition claims | Implemented locally and covered by UI smoke test |
| Medications | Dose taken | Adherence state updates | Implemented locally and covered by UI smoke test |
| Voice | Permission denied | Manual fallback shown | Deterministic denied-state scaffold covered by UI smoke test; real OS permission prompt/native capture pending Apple Speech/microphone setup |
| Voice | Parsed transcript | Confirmation screen required before save | Implemented locally and covered by UI smoke test; native Speech/microphone integration pending |
| AI | Red-flag prompt | Urgent care guidance, no diagnosis | Implemented and covered by Care UI smoke test |
| AI | Medication-change prompt | Advises clinician/pharmacist, no prescription change | Implemented locally and covered by UI smoke test |
| Insights | No data | Empty state, no fake claims | Implemented locally and covered by UI smoke test |
| Insights | Local logs present | Charts, stats, and food patterns populate from local logs without trigger claims | Implemented locally and covered by UI smoke test; chart accessibility summaries pending |
| Reports | Export | Plain text/CSV/PDF scaffold behaves safely | Local shareable text report implemented and covered by UI smoke test; CSV/PDF/backend export pending |
| Privacy | Export data | User-visible export path creates shareable local JSON | Implemented locally and covered by UI smoke test; backend export pending |
| Privacy | AI memory toggle | Visible Off/On state updates and local preference persists | Implemented locally and covered by UI smoke test; backend AI enforcement pending |
| Privacy | Voice transcript storage toggle | Visible Off/On state updates and local preference persists | Implemented locally and covered by UI smoke test; backend retention enforcement pending |
| Privacy | Delete AI history | Confirmation before local message clearing | Implemented locally and covered by UI smoke test |
| Privacy | Delete data/account | Confirmation before local deletion-request scaffold | Implemented locally and covered by UI smoke test; backend deletion pending |
| Offline | Log while offline | Local save or safe failure | Local snapshot and pending queue implemented; Profile sync blocked retry covered by UI smoke test; backend replay pending |
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
- `testReportSummaryUsesPossiblePatternLanguage`
- `testDoctorReportExporterBuildsLocalLogReportWithoutTriggerClaims`
- `testUserDataExporterBuildsLocalJSONSnapshot`
- `testCareResponseBlocksMedicationChangeAdvice`
- `testCareResponseUsesRedFlagSafetyBeforeGeneralAdvice`
- `testCareFoodResponseAvoidsTriggerClaims`
- `testValidationHelpers`
- `testAppStatePersistsSessionOnboardingLogsAndPrivacyPreferences`
- `testPendingSyncQueuePersistsAndMarksBlockedWithoutBackend`
- `testClearAIHistoryLeavesLocalConfirmationMessage`
- `testAccountDeletionRequestQueuesAndLogsScaffold`
- `testPrepareUserDataExportCreatesLocalFileAndAuditLog`
- `testCorruptSnapshotFallsBackToCleanState`
- `testLegacySnapshotWithoutQueueStillDecodes`
- `testInsightSummaryReturnsEmptyStateForNoLogs`
- `testInsightSummaryUsesLocalLogsWithoutDemoData`

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
- `InflamendUITests.testProfileDoctorReportExportSheetSmoke`
- `InflamendUITests.testProfileUserDataExportSheetSmoke`
- `InflamendUITests.testProfileDestructiveActionsRequireConfirmation`
- `InflamendUITests.testProfilePrivacyTogglesUpdateVisibleStateSmoke`
- `InflamendUITests.testProfileSignOutReturnsToAuthGateSmoke`
- `InflamendUITests.testProfileSyncRetryShowsBackendBlockedSmoke`
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
