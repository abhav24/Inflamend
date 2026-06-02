do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles',
    'user_settings',
    'onboarding_responses',
    'medications',
    'medication_schedules',
    'medication_doses',
    'medication_events',
    'daily_checkins',
    'bowel_logs',
    'food_items',
    'meal_logs',
    'meal_components',
    'symptom_logs',
    'sleep_logs',
    'weight_logs',
    'water_logs',
    'flare_events',
    'trigger_insights',
    'insight_feedback',
    'risk_scores',
    'voice_log_drafts',
    'voice_transcripts',
    'chat_conversations',
    'chat_messages',
    'export_jobs',
    'log_notes',
    'audit_events'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('alter table public.%I force row level security', t);
    execute format('create policy %I on public.%I for select using (user_id = auth.uid())', t || '_select_own', t);
    execute format('create policy %I on public.%I for insert with check (user_id = auth.uid())', t || '_insert_own', t);
    execute format('create policy %I on public.%I for update using (user_id = auth.uid()) with check (user_id = auth.uid())', t || '_update_own', t);
    execute format('create policy %I on public.%I for delete using (user_id = auth.uid())', t || '_delete_own', t);
  end loop;
end;
$$;

revoke all on schema public from anon;
grant usage on schema public to authenticated;

grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public grant usage, select on sequences to authenticated;
