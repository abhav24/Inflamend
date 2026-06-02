# Accessibility Audit

## Baseline

The app uses native SwiftUI controls and readable contrast in most places, but accessibility has not been systematically implemented. Several custom buttons, charts, and visual-only indicators need explicit labels and summaries.

## Screen Checklist

| Screen | VoiceOver | Dynamic Type | Contrast | Tap Targets | Non-color Cues | Status |
|---|---|---|---|---|---|---|
| Auth/Welcome | Partial | Unverified | Likely acceptable | Mostly >=44pt | Text labels on mode buttons | Needs work |
| Onboarding | Partial | Unverified | Likely acceptable | Mostly >=44pt | Text labels on pill choices | Needs work |
| Today/Home | Partial | Unverified | Likely acceptable | Mostly >=44pt | Safety card uses text | Needs work |
| Log | Partial | Unverified | Likely acceptable | Mostly >=44pt | Voice confirmation and blood choices use text | Needs work |
| Insights | Low | Unverified | Mixed chart colors | Mostly OK | Charts need summaries | Needs work |
| Care/Chat | Partial | Unverified | Likely acceptable | Composer OK | Safety copy visible | Needs work |
| Profile | Partial | Unverified | Likely acceptable | Rows OK; export and destructive rows verified by UI smoke tests | Destructive actions use confirmation dialogs | In progress |

## Latest Improvements

- Added stable accessibility identifiers for auth fields, auth primary action, onboarding completion, tab buttons, Profile data export row, and user-data export sheet actions.
- Refactored Profile rows so actionable rows use a concrete `Button(action:)` and an explicit rectangular hit target.
- Added a UI smoke test for navigating to Profile, tapping "Export my data", and verifying the user-data export sheet title and share action.
- Added stable identifiers and UI smoke coverage for destructive Profile confirmation prompts.

## Required Fixes

- Add accessibility labels to tab bar icons and rapid log controls.
- Add chart summaries for line/bar/heatmap views.
- Respect Reduce Motion for staggered animations.
- Verify largest Dynamic Type sizes do not overlap.
- Ensure red-flag safety cards are announced clearly.
- Avoid color-only risk/trigger communication.
- Add manual VoiceOver notes for destructive Profile confirmation dialogs.
- Add UI tests or manual VoiceOver notes for check-in, voice confirmation, and privacy toggles.
- Add labels/hints for auth mode selection and onboarding pill selections.

## Status

Core safety/privacy UI exists, and the Profile data export plus destructive confirmation paths now have smoke coverage. Accessibility polish, Dynamic Type review, and manual assistive-technology verification are still pending.
