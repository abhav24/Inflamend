# Monetization and StoreKit

## Current Decision

No premium gates are implemented. Critical medical logging must remain free and must never be blocked by a paywall.

## If Premium Is Added Later

Use StoreKit 2 and include:

- Product definitions in App Store Connect.
- Restore Purchases.
- Manage Subscription link.
- Clear free vs premium feature matrix.
- No blocked emergency/safety/privacy flows.
- Graceful failure when StoreKit is unavailable.

## Potential Premium Features

Allowed candidates:

- Advanced report customization.
- Long-term pattern analysis.
- Optional cloud backup beyond core needs.
- Family/caregiver summaries if privacy model is explicit.

Not allowed:

- Basic symptom logging.
- Medication taken/skipped logging.
- Red-flag guidance.
- Data export/delete.
- Account deletion.

## Current Status

No StoreKit code exists. No fake gates found in baseline app.
