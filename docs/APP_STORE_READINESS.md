# App Store Readiness

## Current Status

Not ready for App Store submission.

## Audit

| Area | Status | Notes |
|---|---|---|
| App name | Draft | Inflamend |
| Bundle ID | Present | `com.inflamend.app`; ownership must be verified |
| Version/build | Present | `1.0` / `1` in project, UI footer says v2.4.0 build 184 and needs correction |
| App icon | Incomplete | Catalog exists without artwork |
| Launch screen | Generated | Needs visual QA |
| Privacy manifest | Added scaffold | Must be reviewed before release |
| Permission strings | Missing for future voice/HealthKit | Add when features land |
| Medical claims | Risk | Copy must remain cautious |
| Account deletion | UI scaffolded | Required backend deletion still blocked until auth/Supabase are live |
| Data export | UI scaffolded | Doctor report and data export are visible; real file/share/backend export pending |
| Sign in with Apple | Not applicable yet | Required if third-party/social login is added |
| Subscriptions | Not implemented | No fake gates |
| Notifications | Not implemented | Permission flow pending |
| Accessibility | Needs work | See accessibility audit |
| Debug labels | Present risk | Demo names/dates/version must be removed |

## Required Before Submission

- Real auth/onboarding/account deletion.
- Privacy policy and terms URLs.
- App Store privacy questionnaire completed from `PRIVACY_DATA_INVENTORY.md`.
- Medical disclaimer in relevant UI.
- Production app icon and screenshots.
- Build/test pass on supported devices.
- Confirmation dialogs for destructive privacy/account actions.
