insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'demo@inflamend.local',
  crypt('inflamend-demo-password', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"name":"Demo Patient"}'::jsonb,
  now(),
  now()
)
on conflict (id) do nothing;

insert into public.profiles (user_id, display_name, ibd_type, diagnosis_year, current_state, timezone, units)
values ('00000000-0000-0000-0000-000000000001', 'Demo Patient', 'ulcerative_colitis', 2022, 'mild', 'America/New_York', 'us')
on conflict (user_id) do nothing;

insert into public.user_settings (user_id, daily_checkin_reminder, medication_reminders, ai_memory_enabled, store_voice_transcripts)
values ('00000000-0000-0000-0000-000000000001', true, true, false, false)
on conflict (user_id) do nothing;

insert into public.medications (id, user_id, name, dose, instructions, active)
values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Mesalamine', '800mg', 'Take as prescribed by clinician.', true),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Vitamin D', '1000 IU', 'Supplement plan from care team.', true)
on conflict (id) do nothing;

insert into public.medication_schedules (user_id, medication_id, frequency, scheduled_time, reminder_enabled)
values
  ('00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'twice_daily', '08:00', true),
  ('00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'twice_daily', '20:00', true),
  ('00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'daily', '08:00', false);

insert into public.daily_checkins (user_id, checkin_date, overall_status, pain_score, fatigue_score, urgency_score, stool_count, blood_present, medication_taken, notes)
values ('00000000-0000-0000-0000-000000000001', current_date, 'ok', 3, 5, 4, 3, false, true, 'Seed check-in for local development.')
on conflict (user_id, checkin_date) do nothing;

insert into public.bowel_logs (user_id, occurred_at, bristol_type, urgency_score, blood, mucus, pain_score, nighttime, notes)
values
  ('00000000-0000-0000-0000-000000000001', now() - interval '6 hours', 5, 4, 'none', false, 3, false, 'Local seed bowel log.'),
  ('00000000-0000-0000-0000-000000000001', now() - interval '2 hours', 6, 6, 'trace', true, 4, false, 'Trace blood should produce cautious safety copy.');

insert into public.meal_logs (id, user_id, occurred_at, meal_type, portion_size, notes, source)
values ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', now() - interval '5 hours', 'breakfast', 'normal', 'Oatmeal and banana.', 'manual')
on conflict (id) do nothing;

insert into public.food_items (id, user_id, name, is_favorite, user_marked_trigger)
values
  ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'oatmeal', true, false),
  ('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'banana', true, false)
on conflict (user_id, name) do nothing;

insert into public.risk_scores (user_id, score, tier, factors)
values ('00000000-0000-0000-0000-000000000001', 38, 'medium', '[{"label":"Trace blood logged","severity":"medium"},{"label":"Urgency above baseline","severity":"low"}]'::jsonb);
