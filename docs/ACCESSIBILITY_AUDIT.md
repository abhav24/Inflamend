# Accessibility Audit

## Baseline

The app uses native SwiftUI controls and readable contrast in most places, but accessibility has not been systematically implemented. Several custom buttons, charts, and visual-only indicators need explicit labels and summaries.

## Screen Checklist

| Screen | VoiceOver | Dynamic Type | Contrast | Tap Targets | Non-color Cues | Status |
|---|---|---|---|---|---|---|
| Auth/Welcome | Partial | Unverified | Likely acceptable | Mostly >=44pt; keyboard Done and sign-in mode paths verified | Text labels on mode buttons | In progress |
| Onboarding | Partial | Unverified | Likely acceptable | Mostly >=44pt; finish action verified | Text labels on pill choices | In progress |
| Today/Home | Partial | Unverified | Likely acceptable | Mostly >=44pt; check-in action path verified | Safety card uses text | In progress |
| Log | Partial | Unverified | Likely acceptable | Mostly >=44pt; detailed bowel blood/save, food save, medication dose row, and voice confirmation paths verified | Voice confirmation, blood choices, food tags, and medication rows use text | In progress |
| Insights | Partial | Unverified | Mixed chart colors | Mostly OK; empty states identifier-backed and smoke-tested | Empty states use explanatory text; charts need summaries | In progress |
| Care/Chat | Partial | Unverified | Likely acceptable | Composer, submit, red-flag, and medication-refusal paths verified by UI smoke tests | Safety copy visible and identifier-backed | In progress |
| Profile | Partial | Unverified | Likely acceptable | Rows OK; report export, data export, privacy toggles, sign-out, and destructive rows verified by UI smoke tests | Destructive actions use confirmation dialogs | In progress |

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
- Added stable identifiers and UI smoke coverage for the Log Bowel tab, significant-blood choice, bowel save action, and Home safety card.
- Added stable identifiers and UI smoke coverage for Insights no-data empty states across trend, bowel, pain, and food pattern sections.
- Replaced tiny medication dose toggles with full-row buttons and added UI smoke coverage for Log medication dose tracking, Home meds summary, and timeline feedback.
- Added stable identifiers and UI smoke coverage for Log food description, food trigger tags, food save action, and Home timeline feedback.
- Added stable identifiers, keyboard Done controls, and UI smoke coverage for Log voice transcript parsing, editable confirmation fields, save/discard actions, and Home timeline feedback.
- Added stable identifiers and UI smoke coverage for Profile AI memory and voice transcript storage privacy toggles.

## Required Fixes

- Add accessibility labels to tab bar icons and rapid log controls.
- Add chart summaries for line/bar/heatmap views.
- Respect Reduce Motion for staggered animations.
- Verify largest Dynamic Type sizes do not overlap.
- Ensure red-flag safety cards are announced clearly.
- Avoid color-only risk/trigger communication.
- Add manual VoiceOver notes for destructive Profile confirmation dialogs.
- Add manual VoiceOver notes for privacy toggles.
- Add labels/hints for auth mode selection and onboarding pill selections.

## Status

Core safety/privacy UI exists, and the auth sign-up/sign-in/onboarding, Today check-in, Insights empty state, Log bowel red-flag, Log food, Log medication dose, Log voice confirmation, Care red-flag, Care medication-refusal, Profile sign-out, Profile privacy toggles, Profile doctor-report export, Profile data export, and destructive confirmation paths now have smoke coverage. Accessibility polish, Dynamic Type review, and manual assistive-technology verification are still pending.
