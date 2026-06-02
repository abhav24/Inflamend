create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text,
  ibd_type text check (ibd_type in ('ulcerative_colitis', 'crohns', 'indeterminate', 'not_sure', 'prefer_not_to_say')),
  diagnosis_year integer check (diagnosis_year is null or (diagnosis_year between 1900 and extract(year from now())::integer)),
  current_state text check (current_state is null or current_state in ('remission', 'mild', 'moderate', 'severe_flare', 'not_sure')),
  timezone text not null default 'America/New_York',
  units text not null default 'us' check (units in ('us', 'metric')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.user_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  daily_checkin_reminder boolean not null default false,
  medication_reminders boolean not null default false,
  quiet_hours_start time,
  quiet_hours_end time,
  ai_memory_enabled boolean not null default false,
  store_voice_transcripts boolean not null default false,
  allow_healthkit_import boolean not null default false,
  allow_ai_health_context boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.onboarding_responses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  completed_at timestamptz,
  skipped_sensitive_fields boolean not null default false,
  responses jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.medications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  dose text,
  instructions text,
  start_date date,
  end_date date,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.medication_schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  medication_id uuid not null references public.medications(id) on delete cascade,
  frequency text not null,
  scheduled_time time,
  days_of_week smallint[] default array[]::smallint[],
  reminder_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.medication_doses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  medication_id uuid not null references public.medications(id) on delete cascade,
  schedule_id uuid references public.medication_schedules(id) on delete set null,
  scheduled_for timestamptz not null,
  dose_label text,
  status text not null default 'scheduled' check (status in ('scheduled', 'taken', 'skipped', 'snoozed', 'missed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.medication_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  medication_id uuid not null references public.medications(id) on delete cascade,
  dose_id uuid references public.medication_doses(id) on delete set null,
  event_type text not null check (event_type in ('taken', 'skipped', 'snoozed', 'missed', 'refill_needed')),
  occurred_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now()
);

create table public.daily_checkins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  checkin_date date not null,
  overall_status text check (overall_status in ('great', 'ok', 'rough', 'flare', 'not_sure')),
  pain_score smallint check (pain_score between 0 and 10),
  fatigue_score smallint check (fatigue_score between 0 and 10),
  urgency_score smallint check (urgency_score between 0 and 10),
  stool_count smallint check (stool_count between 0 and 50),
  blood_present boolean,
  medication_taken boolean,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, checkin_date)
);

create table public.bowel_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  occurred_at timestamptz not null,
  bristol_type smallint check (bristol_type between 1 and 7),
  urgency_score smallint check (urgency_score between 0 and 10),
  blood text not null default 'none' check (blood in ('none', 'trace', 'visible', 'significant')),
  mucus boolean not null default false,
  pain_score smallint check (pain_score between 0 and 10),
  accident boolean not null default false,
  nighttime boolean not null default false,
  notes text,
  safety_flags text[] not null default array[]::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.food_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  is_favorite boolean not null default false,
  user_marked_trigger boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, name)
);

create table public.meal_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  occurred_at timestamptz not null,
  meal_type text check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack', 'other')),
  portion_size text check (portion_size is null or portion_size in ('small', 'normal', 'large', 'unknown')),
  notes text,
  source text not null default 'manual' check (source in ('manual', 'voice', 'photo_placeholder', 'barcode_placeholder')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.meal_components (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_id uuid not null references public.meal_logs(id) on delete cascade,
  food_item_id uuid references public.food_items(id) on delete set null,
  free_text text,
  tags text[] not null default array[]::text[],
  created_at timestamptz not null default now()
);

create table public.symptom_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  occurred_at timestamptz not null,
  pain_score smallint check (pain_score between 0 and 10),
  fatigue_score smallint check (fatigue_score between 0 and 10),
  urgency_score smallint check (urgency_score between 0 and 10),
  mood_score smallint check (mood_score between 0 and 10),
  symptoms text[] not null default array[]::text[],
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.sleep_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  sleep_start timestamptz,
  sleep_end timestamptz,
  duration_minutes integer check (duration_minutes is null or duration_minutes between 0 and 1440),
  quality_score smallint check (quality_score between 0 and 10),
  bathroom_wakes smallint check (bathroom_wakes between 0 and 20),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.weight_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_at timestamptz not null,
  weight_value numeric(6,2) not null check (weight_value > 0 and weight_value < 1000),
  unit text not null check (unit in ('lb', 'kg')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.water_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_at timestamptz not null,
  amount_ml integer not null check (amount_ml > 0 and amount_ml <= 5000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.flare_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  started_at timestamptz not null,
  ended_at timestamptz,
  severity text check (severity is null or severity in ('mild', 'moderate', 'severe', 'not_sure')),
  notes text,
  possible_triggers text[] not null default array[]::text[],
  treatment_changes text,
  doctor_contacted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  check (ended_at is null or ended_at >= started_at)
);

create table public.trigger_insights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  trigger_label text not null,
  window_hours integer not null check (window_hours in (0, 24, 48, 72)),
  confidence text not null check (confidence in ('insufficient_data', 'low', 'medium', 'high')),
  evidence_count integer not null default 0 check (evidence_count >= 0),
  summary text not null,
  generated_at timestamptz not null default now(),
  dismissed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.insight_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  trigger_insight_id uuid references public.trigger_insights(id) on delete cascade,
  feedback text not null check (feedback in ('helpful', 'not_accurate', 'dismissed')),
  notes text,
  created_at timestamptz not null default now()
);

create table public.risk_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  score smallint not null check (score between 0 and 100),
  tier text not null check (tier in ('low', 'medium', 'high')),
  factors jsonb not null default '[]'::jsonb,
  computed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.voice_log_drafts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  transcript text,
  parsed_payload jsonb not null default '{}'::jsonb,
  confidence text not null default 'ambiguous' check (confidence in ('high', 'medium', 'ambiguous')),
  status text not null default 'draft' check (status in ('draft', 'confirmed', 'discarded')),
  source_locale text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.voice_transcripts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  draft_id uuid references public.voice_log_drafts(id) on delete cascade,
  transcript text not null,
  consented_at timestamptz not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  memory_allowed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system_safety')),
  content text not null,
  red_flag_detected boolean not null default false,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.export_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  report_type text not null check (report_type in ('7_day', '30_day', 'custom')),
  range_start date not null,
  range_end date not null,
  format text not null check (format in ('plain_text', 'csv', 'pdf')),
  status text not null default 'queued' check (status in ('queued', 'running', 'completed', 'failed')),
  result_path text,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  check (range_end >= range_start)
);

create table public.log_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  occurred_at timestamptz not null,
  note text not null,
  related_log_type text,
  related_log_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index profiles_user_id_idx on public.profiles(user_id);
create index medications_user_active_idx on public.medications(user_id, active) where deleted_at is null;
create index medication_schedules_user_med_idx on public.medication_schedules(user_id, medication_id);
create index medication_doses_user_scheduled_idx on public.medication_doses(user_id, scheduled_for);
create index medication_events_user_occurred_idx on public.medication_events(user_id, occurred_at desc);
create index daily_checkins_user_date_idx on public.daily_checkins(user_id, checkin_date desc) where deleted_at is null;
create index bowel_logs_user_occurred_idx on public.bowel_logs(user_id, occurred_at desc) where deleted_at is null;
create index food_items_user_name_idx on public.food_items(user_id, lower(name)) where deleted_at is null;
create index meal_logs_user_occurred_idx on public.meal_logs(user_id, occurred_at desc) where deleted_at is null;
create index meal_components_user_meal_idx on public.meal_components(user_id, meal_id);
create index symptom_logs_user_occurred_idx on public.symptom_logs(user_id, occurred_at desc) where deleted_at is null;
create index sleep_logs_user_start_idx on public.sleep_logs(user_id, sleep_start desc) where deleted_at is null;
create index weight_logs_user_logged_idx on public.weight_logs(user_id, logged_at desc) where deleted_at is null;
create index water_logs_user_logged_idx on public.water_logs(user_id, logged_at desc) where deleted_at is null;
create index flare_events_user_started_idx on public.flare_events(user_id, started_at desc) where deleted_at is null;
create index trigger_insights_user_generated_idx on public.trigger_insights(user_id, generated_at desc);
create index risk_scores_user_computed_idx on public.risk_scores(user_id, computed_at desc);
create index voice_log_drafts_user_created_idx on public.voice_log_drafts(user_id, created_at desc) where deleted_at is null;
create index voice_transcripts_user_created_idx on public.voice_transcripts(user_id, created_at desc) where deleted_at is null;
create index chat_conversations_user_created_idx on public.chat_conversations(user_id, created_at desc) where deleted_at is null;
create index chat_messages_conversation_created_idx on public.chat_messages(conversation_id, created_at);
create index export_jobs_user_created_idx on public.export_jobs(user_id, created_at desc);
create index log_notes_user_occurred_idx on public.log_notes(user_id, occurred_at desc) where deleted_at is null;
create index audit_events_user_created_idx on public.audit_events(user_id, created_at desc);

do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'user_settings', 'onboarding_responses', 'medications',
    'medication_schedules', 'medication_doses', 'daily_checkins',
    'bowel_logs', 'food_items', 'meal_logs', 'symptom_logs',
    'sleep_logs', 'weight_logs', 'water_logs', 'flare_events',
    'trigger_insights', 'voice_log_drafts', 'chat_conversations',
    'export_jobs', 'log_notes'
  ]
  loop
    execute format('create trigger %I before update on public.%I for each row execute function public.set_updated_at()', t || '_set_updated_at', t);
  end loop;
end;
$$;

comment on table public.bowel_logs is 'Self-reported bowel movement logs. Not diagnostic. Includes safety flags for red-flag UI.';
comment on table public.trigger_insights is 'Cautious possible-pattern insights. Correlation must not be presented as causation.';
comment on table public.voice_transcripts is 'Stored only when the user explicitly consents to transcript retention.';
comment on table public.chat_messages is 'AI assistant messages. Provider keys must never be stored in iOS clients.';
