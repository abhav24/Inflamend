# Supabase Setup

## What Exists

The repository contains a local Supabase foundation:

```text
supabase/
  config.toml
  seed.sql
  migrations/
    0001_init.sql
    0002_rls_policies.sql
    0003_seed_dev_data.sql
    0004_medication_reminder_settings.sql
  functions/
    ai-chat/
    voice-parse/
    export-report/
    risk-score/
```

## Local Setup

Install the Supabase CLI, then run:

```bash
supabase start
supabase db reset
supabase functions serve ai-chat
supabase functions serve voice-parse
supabase functions serve export-report
supabase functions serve risk-score
```

The seed migration creates a demo local user:

```text
email: demo@inflamend.local
password: inflamend-demo-password
```

Use this only for local development.

## iOS Config

Copy the examples and fill in local or hosted values:

```bash
cp Config/Debug.xcconfig.example Config/Debug.xcconfig
cp Config/Release.xcconfig.example Config/Release.xcconfig
```

Required iOS build settings:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_FUNCTIONS_URL
```

Do not commit the copied `.xcconfig` files.

## Edge Function Secrets

Set server-side secrets with:

```bash
supabase secrets set AI_PROVIDER_API_KEY=...
```

Future production functions may also need:

```text
AI_PROVIDER_BASE_URL
AI_PROVIDER_MODEL
REPORT_STORAGE_BUCKET
FUNCTION_RATE_LIMIT_BACKEND
```

Never put provider keys or Supabase service role keys in the iOS app.

## Hosted Setup Checklist

- Create a Supabase project.
- Apply migrations.
- Verify RLS with two test users before any real health data is entered.
- Deploy all Edge Functions.
- Set Edge Function secrets.
- Configure allowed auth redirect URLs.
- Configure email templates.
- Confirm backups and retention policy.
- Confirm logs do not contain PHI.

## Current Blockers

- Supabase CLI is not installed in the current environment.
- No real Supabase project credentials are available in this repo.
- Hosted migrations, deployed functions, email auth, and production RLS verification are externally blocked until the project is created.
- `0004_medication_reminder_settings.sql` adds the lead-time column for local medication reminder preferences; it still needs Supabase CLI reset/hosted migration verification.
