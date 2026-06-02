# Doctor Report Format

## Purpose

Reports help users prepare for clinician conversations. They must not diagnose or recommend treatment changes.

## Formats

- Plain text: implemented locally from current app logs and shareable from Profile.
- JSON user data: implemented locally from the protected app snapshot and shareable from Profile.
- CSV: required for logs and summaries.
- PDF: scaffolded until PDF generation is implemented.

## Sections

1. Header:
- User-selected date range.
- Generated timestamp.
- Disclaimer: self-reported data, not a diagnosis.

2. Summary:
- Local logs included.
- Overall status distribution.
- Possible red-flag events.
- Flare markers.

3. Bowel Movement Trends:
- Frequency by day.
- Bristol distribution.
- Blood/urgency/nighttime flags.

4. Symptoms:
- Pain/fatigue/urgency averages and ranges.
- Notes highlights.

5. Medication:
- Doses scheduled.
- Taken/skipped/missed counts.
- Adherence percentage.

6. Food Pattern Tracking:
- Recent foods.
- User-marked triggers.
- Possible patterns with confidence and data count.
- Causation disclaimer.

7. Sleep/Weight/Water:
- Trends and notable changes.

8. Questions For Doctor:
- User notes.
- Automatically suggested discussion prompts framed as questions.

## Current Status

`export-report` Edge Function returns a safe scaffolded report. iOS now creates a protected local plain-text doctor report and a protected local user-data JSON file, then exposes both through `ShareLink`; CSV/PDF and backend export jobs are still pending.

The local user-data JSON export includes a format version, export timestamp, privacy notice, and the current local app snapshot: auth scaffold, onboarding profile, logs, privacy preferences, pending sync records, and saved Care messages.
