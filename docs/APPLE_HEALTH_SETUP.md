# Apple Health Setup

## Current Status

HealthKit is not implemented and no HealthKit entitlement exists.

## Candidate Imports

- Sleep duration.
- Weight.
- Steps/activity as context only.
- Heart rate only if product value is clearly justified.
- Mindfulness/stress proxy only with careful wording.

## Rules

- Request only necessary permissions.
- Explain why each permission is requested.
- App must work without Health permissions.
- Do not infer diagnosis from Health data.
- Do not send HealthKit data to AI without explicit consent.

## Setup Steps When Implemented

- Add HealthKit capability in Xcode.
- Add required Info.plist usage descriptions.
- Implement `HealthKitService`.
- Add permission-denied and partial-permission states.
- Document App Store review notes.
