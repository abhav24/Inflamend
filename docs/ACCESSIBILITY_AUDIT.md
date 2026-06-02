# Accessibility Audit

## Baseline

The app uses native SwiftUI controls and readable contrast in most places, but accessibility has not been systematically implemented. Several custom buttons, charts, and visual-only indicators need explicit labels and summaries.

## Screen Checklist

| Screen | VoiceOver | Dynamic Type | Contrast | Tap Targets | Non-color Cues | Status |
|---|---|---|---|---|---|---|
| Today/Home | Partial | Unverified | Likely acceptable | Mostly >=44pt | Safety card uses text | Needs work |
| Log | Partial | Unverified | Likely acceptable | Mostly >=44pt | Voice confirmation and blood choices use text | Needs work |
| Insights | Low | Unverified | Mixed chart colors | Mostly OK | Charts need summaries | Needs work |
| Care/Chat | Partial | Unverified | Likely acceptable | Composer OK | Safety copy visible | Needs work |
| Profile | Partial | Unverified | Likely acceptable | Rows OK | Destructive actions have labels but need confirmation dialogs | Needs work |

## Required Fixes

- Add accessibility labels to tab bar icons and rapid log controls.
- Add chart summaries for line/bar/heatmap views.
- Respect Reduce Motion for staggered animations.
- Verify largest Dynamic Type sizes do not overlap.
- Ensure red-flag safety cards are announced clearly.
- Avoid color-only risk/trigger communication.
- Add confirmation dialogs for destructive Profile actions.
- Add UI tests or manual VoiceOver notes for check-in, voice confirmation, and privacy toggles.

## Status

Core safety/privacy UI exists. Accessibility polish and manual assistive-technology verification are still pending.
