# Accessibility Audit

## Baseline

The app uses native SwiftUI controls and readable contrast in most places, but accessibility has not been systematically implemented. Several custom buttons, charts, and visual-only indicators need explicit labels and summaries.

## Screen Checklist

| Screen | VoiceOver | Dynamic Type | Contrast | Tap Targets | Non-color Cues | Status |
|---|---|---|---|---|---|---|
| Auth/Welcome | Partial | Unverified | Likely acceptable | Mostly >=44pt; keyboard Done and sign-in mode paths verified | Text labels on mode buttons | In progress |
| Onboarding | Partial | Unverified | Likely acceptable | Mostly >=44pt; finish action verified | Text labels on pill choices | In progress |
| Today/Home | Partial | Unverified | Likely acceptable | Mostly >=44pt; check-in action path verified | Safety card uses text | In progress |
| Log | Partial | Unverified | Likely acceptable | Mostly >=44pt; detailed bowel blood/save path verified | Voice confirmation and blood choices use text | In progress |
| Insights | Low | Unverified | Mixed chart colors | Mostly OK | Charts need summaries | Needs work |
| Care/Chat | Partial | Unverified | Likely acceptable | Composer, submit, red-flag, and medication-refusal paths verified by UI smoke tests | Safety copy visible and identifier-backed | In progress |
| Profile | Partial | Unverified | Likely acceptable | Rows OK; export, sign-out, and destructive rows verified by UI smoke tests | Destructive actions use confirmation dialogs | In progress |

## Latest Improvements

- Added stable accessibility identifiers for auth fields, auth primary action, onboarding completion, tab buttons, Profile data export row, and user-data export sheet actions.
- Added auth keyboard focus management and a keyboard toolbar Done action so the primary local sign-up button is not trapped behind the software keyboard.
- Added UI smoke coverage for fresh local sign-up, auth keyboard dismissal, default onboarding completion, and arrival on the Home tab.
- Added stable identifiers and UI smoke coverage for switching to local sign-in, submitting the auth form, and reaching onboarding.
- Added stable identifiers and UI smoke coverage for the Care composer and red-flag safety message.
- Added UI smoke coverage for the Care medication-change refusal branch through the visible assistant message.
- Added stable identifiers and UI smoke coverage for opening the Today check-in sheet, saving the default check-in, and verifying the new timeline row.
- Refactored Profile rows so actionable rows use a concrete `Button(action:)` and an explicit rectangular hit target.
- Added a UI smoke test for navigating to Profile, tapping "Export my data", and verifying the user-data export sheet title and share action.
- Added stable identifiers and UI smoke coverage for destructive Profile confirmation prompts.
- Added stable identifiers and UI smoke coverage for Profile sign-out returning to the auth gate.
- Added stable identifiers and UI smoke coverage for the Log Bowel tab, significant-blood choice, bowel save action, and Home safety card.

## Required Fixes

- Add accessibility labels to tab bar icons and rapid log controls.
- Add chart summaries for line/bar/heatmap views.
- Respect Reduce Motion for staggered animations.
- Verify largest Dynamic Type sizes do not overlap.
- Ensure red-flag safety cards are announced clearly.
- Avoid color-only risk/trigger communication.
- Add manual VoiceOver notes for destructive Profile confirmation dialogs.
- Add UI tests or manual VoiceOver notes for voice confirmation and privacy toggles.
- Add labels/hints for auth mode selection and onboarding pill selections.

## Status

Core safety/privacy UI exists, and the auth sign-up/sign-in/onboarding, Today check-in, Log bowel red-flag, Care red-flag, Care medication-refusal, Profile sign-out, Profile data export, and destructive confirmation paths now have smoke coverage. Accessibility polish, Dynamic Type review, and manual assistive-technology verification are still pending.
