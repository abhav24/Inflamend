# RLS Policy Audit

## Rule

Users can only access rows where `user_id = auth.uid()`.

## Implemented

`supabase/migrations/0002_rls_policies.sql` enables and forces RLS for every user-owned table, then creates:

- `select` policy using `user_id = auth.uid()`
- `insert` policy with check `user_id = auth.uid()`
- `update` policy using and checking `user_id = auth.uid()`
- `delete` policy using `user_id = auth.uid()`

The migration revokes broad anonymous schema access and grants table access to authenticated users only. RLS remains the enforcement boundary.

## Tables Covered

`profiles`, `user_settings`, `onboarding_responses`, `medications`, `medication_schedules`, `medication_doses`, `medication_events`, `daily_checkins`, `bowel_logs`, `food_items`, `meal_logs`, `meal_components`, `symptom_logs`, `sleep_logs`, `weight_logs`, `water_logs`, `flare_events`, `trigger_insights`, `insight_feedback`, `risk_scores`, `voice_log_drafts`, `voice_transcripts`, `chat_conversations`, `chat_messages`, `export_jobs`, `log_notes`, `audit_events`.

## Required Verification

Run after hosted or local Supabase setup:

```sql
-- As user A: insert a daily_checkins row with user_id = auth.uid().
-- As user B: select that row by id; expected 0 rows.
-- As user B: update/delete that row; expected 0 affected rows.
-- As user A: select/update/delete own row; expected success.
```

## Known Risks

- Foreign keys such as `meal_components.meal_id` and `chat_messages.conversation_id` should also be validated as same-user relationships in service code or database triggers.
- Edge Functions that use service role in the future must derive `user_id` from verified JWT, never from client payloads.
- Audit metadata must not include PHI.

## Current Status

Scaffold complete. Live verification is blocked until Supabase local or hosted environment is run.
