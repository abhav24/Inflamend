# Accessibility Audit

## Baseline

The app uses native SwiftUI controls and readable contrast in most places, but accessibility has not been systematically implemented. Several custom buttons, manual chart flows, and visual-only indicators still need explicit review.

## Screen Checklist

| Screen | VoiceOver | Dynamic Type | Contrast | Tap Targets | Non-color Cues | Status |
|---|---|---|---|---|---|---|
| Auth/Welcome | Partial | Unverified | Likely acceptable | Mostly >=44pt; keyboard Done and sign-in mode paths verified | Text labels on mode buttons | In progress |
| Onboarding | Partial | Unverified | Likely acceptable | Mostly >=44pt; finish action verified | Text labels on pill choices | In progress |
| Today/Home | Partial | Unverified | Likely acceptable | Mostly >=44pt; check-in, timeline edit, timeline delete confirmation, and delete undo paths verified | Safety card, edit sheet, delete confirmation, and undo toast use text | In progress |
| Log | Partial | Unverified | Likely acceptable | Mostly >=44pt; detailed bowel blood/save, food save, medication dose row, voice confirmation, and voice permission fallback paths verified | Voice permission fallback, voice confirmation, blood choices, food tags, and medication rows use text | In progress |
| Insights | Partial | Unverified | Mixed chart colors | Mostly OK; empty and populated summary paths plus chart containers are identifier-backed and smoke-tested | Empty and populated summaries use explanatory text; populated trend, bowel, and heatmap charts expose summary labels | In progress |
| Care/Chat | Partial | Unverified | Likely acceptable | Composer, submit, red-flag, and medication-refusal paths verified by UI smoke tests | Safety copy visible and identifier-backed | In progress |
| Profile | Partial | Unverified | Likely acceptable | Rows OK; sync status, medication reminders, preferences, flare history, Care Plan, IBD Library, report export, data export, privacy toggles, sign-out, and destructive rows verified by UI smoke tests | Sync blocked state, reminder setup state, preferences setup state, flare history empty/count states, Care Plan safety state, IBD Library source/safety state, and destructive actions use visible text | In progress |

## Latest Improvements

- Added stable accessibility identifiers for auth fields, auth primary action, onboarding completion, tab buttons, Profile data export row, and user-data export sheet actions.
- Added auth keyboard focus management and a keyboard toolbar Done action so the primary local sign-up button is not trapped behind the software keyboard.
- Added UI smoke coverage for fresh local sign-up, auth keyboard dismissal, default onboarding completion, and arrival on the Home tab.
- Added stable identifiers and UI smoke coverage for switching to local sign-in, submitting the auth form, and reaching onboarding.
- Added stable identifiers and UI smoke coverage for the Care composer and red-flag safety message.
- Added UI smoke coverage for the Care medication-change refusal branch through the visible assistant message.
- Added stable identifiers and UI smoke coverage for opening the Today check-in sheet, saving the default check-in, and verifying the new timeline row.
- Refactored Profile rows so actionable rows use a concrete `Button(action:)` and an explicit rectangular hit target.
- Added stable identifiers and UI smoke coverage for the Profile doctor-report row, report export sheet title, generated filename, and share action.
- Added a UI smoke test for navigating to Profile, tapping "Export my data", and verifying the user-data export sheet title and share action.
- Added stable identifiers and UI smoke coverage for destructive Profile confirmation prompts.
- Added stable identifiers and UI smoke coverage for Profile sign-out returning to the auth gate.
- Added stable identifiers and UI smoke coverage for Profile sync status retry showing the backend-blocked state.
- Added stable identifiers and combined accessibility labels for the Profile sync detail sheet rows so pending/blocked status, replay target, attempts, and errors are exposed to UI tests and assistive technology.
- Added Profile sync detail next-retry text to the combined row accessibility label and UI smoke assertion.
- Added Profile sync detail network status/detail identifiers and UI smoke coverage for the offline retry-pause path.
- Added Profile sync automatic retry detail text and UI smoke assertions for blocked and offline retry states.
- Added stable identifiers and UI smoke coverage for the Log Bowel tab, significant-blood choice, bowel save action, and Home safety card.
- Added stable identifiers and UI smoke coverage for Insights no-data empty states across trend, bowel, pain, and food pattern sections.
- Added stable identifiers and UI smoke coverage for populated Insights confidence text, stat tiles, chart containers, and food pattern rows.
- Added accessibility labels and UI assertions for populated Insights trend, bowel, and pain heatmap chart summaries.
- Replaced tiny medication dose toggles with full-row buttons, added visible dose status text, and added UI smoke coverage for Log medication dose tracking, Home meds summary, and timeline feedback.
- Added stable identifiers and UI smoke coverage for Log food description, food trigger tags, food save action, and Home timeline feedback.
- Added stable identifiers, keyboard Done controls, and UI smoke coverage for Log voice transcript parsing, editable confirmation fields, save/discard actions, and Home timeline feedback.
- Added stable identifiers and UI smoke coverage for Profile AI memory and voice transcript storage privacy toggles.
- Added stable identifiers and UI smoke coverage for the Profile medication reminder settings row, reminder toggle, lead-time selection, and notification-setup status copy.
- Added stable identifiers and UI smoke coverage for the Profile Preferences row, weight-unit buttons, device-timezone state, and unit-aware Weight logging path.
- Added stable identifiers and UI smoke coverage for the Profile Flare history row, sheet summary, empty state, and local flare event rows.
- Added stable identifiers and UI smoke coverage for the Profile Care Plan row, question list, and non-treatment safety note.
- Added stable identifiers and UI smoke coverage for the Profile IBD Library row, source-attributed article rows, source labels, and non-diagnostic safety note.
- Added stable identifiers and UI smoke coverage for Log voice permission-denied fallback copy and the manual transcript entry path.
- Added stable identifiers and UI smoke coverage for Home timeline delete buttons, destructive confirmation, and empty-timeline feedback.
- Added stable identifiers, keyboard Done control, and UI smoke coverage for Home timeline edit buttons, the edit sheet, and updated timeline row feedback.
- Added a separate accessible toast Undo button and UI smoke coverage for restoring a locally deleted timeline row.

## Required Fixes

- Add VoiceOver labels to tab bar icons and rapid log controls where generated labels are insufficient.
- Manually verify populated chart summaries with VoiceOver and large Dynamic Type.
- Respect Reduce Motion for staggered animations.
- Verify largest Dynamic Type sizes do not overlap.
- Ensure red-flag safety cards are announced clearly.
- Avoid color-only risk/trigger communication.
- Add manual VoiceOver notes for destructive Profile confirmation dialogs.
- Add manual VoiceOver notes for timeline delete confirmation dialogs.
- Add manual VoiceOver notes for the timeline edit sheet, weight unit controls, medication dose status rows, and row action order.
- Add manual VoiceOver notes for the timeline delete undo toast and action order.
- Add manual VoiceOver notes for privacy toggles, the Profile sync detail sheet including network and automatic retry status, the medication reminder settings sheet, the Profile Preferences sheet, the Profile Flare history sheet, the Profile Care Plan sheet, the Profile IBD Library sheet, and the voice permission fallback state.
- Add labels/hints for auth mode selection and onboarding pill selections.

## Status

Core safety/privacy UI exists, and the auth sign-up/sign-in/onboarding, Today check-in, timeline edit, timeline delete confirmation, timeline delete undo, Insights empty and populated summary states, Insights populated chart summaries, Log bowel red-flag, Log food, Log medication dose, Log voice confirmation, Log voice permission fallback, Care red-flag, Care medication-refusal, Profile sign-out, Profile sync status/detail including offline and automatic retry state, Profile privacy toggles, Profile medication reminder settings, Profile preferences, Profile flare history, Profile Care Plan, Profile IBD Library, Profile doctor-report export, Profile data export, and destructive confirmation paths now have smoke coverage. Accessibility polish, Dynamic Type review, and manual assistive-technology verification are still pending.
