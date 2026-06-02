# App Store Readiness

## Current Status

Not ready for App Store submission.

## Audit

| Area | Status | Notes |
|---|---|---|
| App name | Draft | Inflamend |
| Bundle ID | Present | `com.inflamend.app`; ownership must be verified |
| Version/build | Present | `1.0` / `1` in project and UI footer |
| App icon | Incomplete | Catalog exists without artwork |
| Launch screen | Generated | Needs visual QA |
| Privacy manifest | Added scaffold | Must be reviewed before release |
| Permission strings | Missing for future voice/HealthKit | Add when features land |
| Medical claims | Risk | Copy must remain cautious |
| Account deletion | UI scaffolded | Required backend deletion still blocked until production auth/Supabase are live |
| Data export | Partial | Doctor report creates a local shareable text file; full user-data export, CSV/PDF, and backend export jobs are pending |
| Sign in with Apple | Not applicable yet | Local email scaffold exists; Sign in with Apple required if third-party/social login is added |
| Subscriptions | Not implemented | No fake gates |
| Notifications | Not implemented | Permission flow pending |
| Accessibility | Needs work | See accessibility audit |
| Debug labels | Present risk | Demo names/dates/version must be removed |

## Required Before Submission

- Production auth, onboarding profile sync, and backend account deletion.
- Privacy policy and terms URLs.
- App Store privacy questionnaire completed from `PRIVACY_DATA_INVENTORY.md`.
- Medical disclaimer in relevant UI.
- Production app icon and screenshots.
- Build/test pass on supported devices.
- Confirmation dialogs for destructive privacy/account actions.
