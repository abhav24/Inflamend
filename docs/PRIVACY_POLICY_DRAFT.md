# Inflamend Privacy Policy Draft

Draft last updated: June 2, 2026.

Status: draft for product, legal, privacy, and security review. This document is not a published policy and must be reviewed by counsel before App Store submission or public use.

## Overview

Inflamend is an IBD tracking and care-preparation app. It helps users record self-reported symptoms, bowel movements, meals, medication status, sleep, weight, notes, Care messages, and appointment-preparation context.

Inflamend does not diagnose, treat, prescribe, triage emergencies, or replace professional medical care.

## Data Inflamend Handles

Inflamend may handle these categories of data:

- Account scaffold data: email address, display name, local user identifier, and local sign-in state.
- Onboarding profile: diagnosis label, primary goal, baseline stool count, and whether a clinician flare plan exists.
- Health logs: symptoms, bowel movement details, food tags, medication dose status, sleep, weight, notes, timestamps, and related safety messages.
- Medication reminder preferences: local reminder enabled state and lead time.
- App preferences: preferred weight unit and device-timezone preference.
- Care messages: user prompts and assistant responses saved locally on this device.
- Voice transcript data: manually entered or dictated transcript drafts and parsed fields after confirmation.
- Sync metadata: pending local mutation records, retry status, local identifiers, timestamps, and backend-blocked error details.
- Export files: local doctor-report text files and local user-data JSON exports created when the user requests them.

## Current Storage

In the current production scaffold, Inflamend stores data in a protected local app snapshot on the user's device. Local export files are created only when the user requests an export.

Production cloud storage is planned through Supabase, but live Supabase credentials and production account deletion/export jobs are not configured in this repository checkpoint.

## AI and Voice

Care assistant behavior is designed to be cautious and safety-framed. AI memory defaults off. Health context should not be sent to an AI provider unless the user has clearly consented and the backend request path has passed privacy review.

Voice logging uses transcript confirmation before saving. Microphone and speech-recognition permissions should be requested only when the user chooses a voice logging action. Manual transcript entry must remain available.

## Data Sharing

Inflamend does not include ad tracking and does not sell health data.

Planned service providers may include:

- Supabase for authentication, database storage, Edge Functions, export jobs, and deletion jobs.
- An AI provider for Care assistant requests after consent and server-side safety controls are configured.
- Apple platform services for app permissions, local notifications, diagnostics controlled by platform settings, and App Store distribution.

Any production analytics, diagnostics, or telemetry must be reviewed before use and must not log PHI or sensitive health text.

## User Controls

Current local controls include:

- Export doctor report as a local shareable text file.
- Export local user data as JSON.
- Toggle AI memory.
- Toggle voice transcript storage preference.
- Delete local Care message history.
- Record a local account/data deletion request.
- Sign out of the local account scaffold.

Backend-backed account deletion, cloud data deletion, cloud export receipts, and server retention enforcement are still required before App Store release.

## Retention

Current local data remains on the device until the user deletes app data, uses available local deletion controls, or removes the app. Production backend retention periods must be finalized before launch.

## Children

Inflamend is not designed for children under 13. If the production product supports minors, consent, guardian, and jurisdiction-specific requirements must be reviewed before launch.

## Security

Inflamend should protect local app data with iOS file protection and should use Keychain-backed tokens for production authentication. The current local account scaffold does not store passwords. Production backend secrets must stay server-side and must never be committed to the repository.

## Medical Safety

Inflamend is for self-tracking and care preparation. It is not a medical device, diagnosis tool, emergency service, or substitute for a clinician. Users should contact a clinician, urgent care, emergency services, or local crisis resources for urgent, severe, rapidly worsening, or unsafe symptoms.

## Contact and Published URLs

Required before publication:

- Company/legal entity: TBD.
- Support email: TBD.
- Privacy policy URL: TBD.
- Terms URL: TBD.
- Data deletion request URL or workflow: TBD.
