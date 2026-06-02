# Accessibility Audit

## Baseline

The app uses native SwiftUI controls and readable contrast in most places, but accessibility has not been systematically implemented. Several custom buttons, charts, and visual-only indicators need explicit labels and summaries.

## Screen Checklist

| Screen | VoiceOver | Dynamic Type | Contrast | Tap Targets | Non-color Cues | Status |
|---|---|---|---|---|---|---|
| Today/Home | Partial | Unverified | Likely acceptable | Mostly >=44pt | Risk needs text | Needs work |
| Log | Partial | Unverified | Likely acceptable | Mostly >=44pt | Pill states need labels | Needs work |
| Insights | Low | Unverified | Mixed chart colors | Mostly OK | Charts need summaries | Needs work |
| Care/Chat | Partial | Unverified | Likely acceptable | Composer OK | Safety states needed | Needs work |
| Profile | Partial | Unverified | Likely acceptable | Rows OK | Destructive actions need clarity | Needs work |

## Required Fixes

- Add accessibility labels to tab bar icons and rapid log controls.
- Add chart summaries for line/bar/heatmap views.
- Respect Reduce Motion for staggered animations.
- Verify largest Dynamic Type sizes do not overlap.
- Ensure red-flag safety cards are announced clearly.
- Avoid color-only risk/trigger communication.

## Status

Documentation complete. UI fixes pending.
