# Inflamend Test Plan

## Baseline Test Status

Current automated test status:

```text
xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
Result: TEST SUCCEEDED.
Coverage: 24 unit tests in HealthLogicTests plus 1 UI smoke test in InflamendUITests.
```

The previous blocker, missing test target/test action, is resolved.
The app now has both unit and UI test targets wired into the shared `Inflamend` scheme.

Latest checkpoint verification:

```text
xcodebuild clean build -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
Result: BUILD SUCCEEDED.

xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
Result: TEST SUCCEEDED with 25 tests.
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

Status: started. Plain-text report wording, possible-pattern language, local doctor-report content generation, and local user-data JSON export are covered.

6. Offline/sync queue:
- Pending mutation enqueue.
- Retry state blocked by missing backend setup.
- Conflict state.
- Last sync timestamp.
- No data loss after app restart once persistence exists.

Status: local snapshot restore, pending queue persistence, backend-blocked retry, legacy decode, and corrupt snapshot fallback are covered. Network replay and conflict behavior are pending.

7. Validation helpers:
- Numeric ranges for pain, urgency, Bristol type, weight, sleep, and water.
- Required fields for save actions.
- Safe human-readable errors.

8. Insights:
- Empty states when no local logs exist.
- Pain/fatigue summaries derived from local logs instead of demo arrays.
- Food pattern summaries framed as frequency, not trigger causation.

Status: started. Empty and local-log summary behavior is covered.

9. Care/AI safety:
- Red-flag prompt bypasses general advice.
- Medication-change prompt refuses prescription-change guidance.
- Food guidance avoids unsupported trigger claims.

Status: started. Local Care response safety behavior is covered.

10. Privacy and destructive actions:
- Local AI history clearing leaves a confirmation message.
- Account deletion requests create a local audit log and pending backend mutation.
- Destructive Profile actions require confirmation before running.

Status: started. Underlying AppState effects are covered; UI confirmation needs UI tests.

## UI Test Priorities

- Fresh install shows welcome/auth or Today depending on session scaffold.
- Sign up/sign in with mock service.
- Onboarding can be completed or skipped for sensitive fields.
- Today check-in can be saved in under 30 seconds.
- Bowel movement log with blood shows safety guidance.
- Food log saves as pattern tracking, not nutrition claims.
- Medication taken/skipped changes adherence state.
- Voice permission denied state is understandable.
- Voice transcript confirmation can be edited before saving.
- Insights empty state avoids fake claims.
- Report export scaffold explains missing setup or creates local export.
- Privacy controls expose export/delete/AI memory/transcript toggles. Status: started; Profile user-data export sheet smoke coverage exists.
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
| Auth | Logged out | Shows welcome/sign in/up scaffold | Implemented; needs UI test |
| Auth | Sign out | Session clears, no stale PHI visible | Implemented locally; needs UI test |
| Onboarding | Sensitive questions skipped | App remains usable | Implemented; needs UI test |
| Today | Check-in saved | Today and risk score update | Implemented in-memory; needs UI test |
| Logging | BM with blood | Log saves and red-flag guidance appears | Implemented in-memory; needs UI test |
| Logging | Meal log | Food pattern entry saves without nutrition claims | Implemented in-memory; needs UI test |
| Medications | Dose taken | Adherence state updates | Implemented in-memory; needs UI test |
| Voice | Permission denied | Manual fallback shown | Scaffolded as manual transcript path |
| Voice | Parsed transcript | Confirmation screen required before save | Implemented in-memory; needs UI test |
| AI | Red-flag prompt | Urgent care guidance, no diagnosis | Implemented in Care scaffold; needs UI test |
| AI | Medication-change prompt | Advises clinician/pharmacist, no prescription change | Implemented locally; needs UI test |
| Insights | No data | Empty state, no fake claims | Implemented in logic; needs UI test |
| Reports | Export | Plain text/CSV/PDF scaffold behaves safely | Local shareable text report implemented; CSV/PDF/backend export pending |
| Privacy | Export data | User-visible export path creates shareable local JSON | Implemented locally and covered by UI smoke test; backend export pending |
| Privacy | Delete AI history | Confirmation before local message clearing | Implemented locally; needs UI test |
| Privacy | Delete data/account | Confirmation before local deletion-request scaffold | Implemented locally; backend deletion pending |
| Offline | Log while offline | Local save or safe failure | Local snapshot and pending queue implemented; backend replay pending |
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

- `InflamendUITests.testProfileUserDataExportSheetSmoke`

## Device Targets

Available local simulator targets:

- iPhone 17, iOS 26.0, booted.
- iPhone 16e, iOS 26.0.
- iPhone 17 Pro Max, iOS 26.0.
- iPhone Air, iOS 26.0.
- iPad and iPad Pro simulators on iOS 26.0.

Prompt-requested `iPhone 16` is not installed. Use `iPhone 17` for current automated build/test unless a different simulator is added.
