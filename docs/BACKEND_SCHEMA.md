# Backend Schema

## Schema Goals

The schema stores self-reported IBD tracking data with user ownership, RLS protection, date indexes, soft deletion where useful, and cautious support for AI/voice/report workflows.

## Core Tables

| Table | Purpose | Notes |
|---|---|---|
| `profiles` | User health profile | User-owned, soft deletable |
| `user_settings` | Privacy/reminder/AI settings | AI memory and transcript toggles default off |
| `onboarding_responses` | Skippable onboarding answers | JSON payload for flexible product iteration |
| `medications` | Medication list | No medication advice, user-entered data only |
| `medication_schedules` | Schedule definitions | Supports reminders without requiring notifications yet |
| `medication_doses` | Expected dose instances | Enables missed/taken history |
| `medication_events` | Taken/skipped/snoozed/missed events | Append-style event trail |
| `daily_checkins` | Fast daily status | Unique per user/date |
| `bowel_logs` | BM details | Bristol, urgency, blood, pain, safety flags |
| `food_items` | Recent/favorite/user trigger foods | Not a nutrition database |
| `meal_logs` | Meals | Manual/voice/photo-placeholder/barcode-placeholder source |
| `meal_components` | Foods attached to meals | Tags and optional linked item |
| `symptom_logs` | Pain/fatigue/urgency/mood | Flexible symptom array |
| `sleep_logs` | Sleep duration/quality/wakes | No HealthKit dependency yet |
| `weight_logs` | Weight entries | Unit-aware |
| `water_logs` | Hydration entries | Amount in ml |
| `flare_events` | Flare start/end summaries | Doctor contacted flag |
| `trigger_insights` | Possible pattern summaries | Requires cautious language and confidence |
| `insight_feedback` | User feedback on insights | Helpful/not accurate/dismissed |
| `risk_scores` | Deterministic score snapshots | Not medically validated |
| `voice_log_drafts` | Parsed voice drafts | Confirmation required before save |
| `voice_transcripts` | Consent-only transcripts | Separate table for deletion and retention |
| `chat_conversations` | AI conversation sessions | Memory flag defaults false |
| `chat_messages` | AI/user messages | Red-flag marker |
| `export_jobs` | Report export jobs | Plain text/CSV/PDF scaffold |
| `log_notes` | General notes | Can relate to any log |
| `audit_events` | User-visible account/data events | Must not include PHI in metadata |

## Integrity Rules

- Every user-owned table has `user_id`.
- Every user-owned table has a UUID primary key.
- Date-heavy tables have `(user_id, date/time desc)` indexes.
- Sensitive mutable tables have `deleted_at` for soft deletion.
- Numeric health scales are constrained to expected ranges.
- Risk and trigger tables store cautious summaries, not medical diagnoses.

## Gaps

- Cross-table ownership validation for references should be strengthened with triggers or service-layer validation before production.
- Hosted migration execution is not verified without Supabase credentials.
- Storage buckets for PDF exports are not yet defined.
- Long-term retention jobs are documented but not implemented.
