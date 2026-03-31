-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ─── Profiles ──────────────────────────────────────────────────────────────
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  display_name text,
  date_of_birth date,
  diagnosis_type text check (diagnosis_type in ('crohns', 'ulcerative_colitis', 'ibd_unspecified', 'other')),
  diagnosis_date date,
  tracks_menstrual_cycle boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

-- Auto-update updated_at
create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger on_profiles_updated
  before update on public.profiles
  for each row execute procedure public.handle_updated_at();

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─── Food Logs ─────────────────────────────────────────────────────────────
create table public.food_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  logged_at timestamptz not null default now(),
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack', 'drink')),
  description text not null,
  photo_url text,
  calories integer,
  protein_g decimal(6,2),
  carbs_g decimal(6,2),
  fat_g decimal(6,2),
  fiber_g decimal(6,2),
  water_ml integer,
  is_trigger_food boolean not null default false,
  is_safe_food boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.food_logs enable row level security;

create policy "Users can crud own food_logs"
  on public.food_logs for all using (auth.uid() = user_id);

create index food_logs_user_logged_at on public.food_logs(user_id, logged_at desc);

-- ─── Bowel Logs ────────────────────────────────────────────────────────────
create table public.bowel_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  logged_at timestamptz not null default now(),
  bristol_scale integer not null check (bristol_scale between 1 and 7),
  urgency integer not null default 1 check (urgency between 1 and 5),
  blood_present boolean not null default false,
  blood_amount text not null default 'none' check (blood_amount in ('none', 'trace', 'moderate', 'significant')),
  mucus_present boolean not null default false,
  pain_during integer not null default 0 check (pain_during between 0 and 10),
  notes text,
  created_at timestamptz not null default now()
);

alter table public.bowel_logs enable row level security;

create policy "Users can crud own bowel_logs"
  on public.bowel_logs for all using (auth.uid() = user_id);

create index bowel_logs_user_logged_at on public.bowel_logs(user_id, logged_at desc);

-- ─── Symptom Logs ──────────────────────────────────────────────────────────
create table public.symptom_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  logged_at timestamptz not null default now(),
  pain_level integer not null default 0 check (pain_level between 0 and 10),
  pain_location text[] not null default '{}',
  fatigue_level integer not null default 0 check (fatigue_level between 0 and 10),
  nausea_level integer not null default 0 check (nausea_level between 0 and 10),
  bloating_level integer not null default 0 check (bloating_level between 0 and 10),
  stress_level integer not null default 0 check (stress_level between 0 and 10),
  mood text check (mood in ('great', 'good', 'okay', 'bad', 'terrible')),
  is_flare boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.symptom_logs enable row level security;

create policy "Users can crud own symptom_logs"
  on public.symptom_logs for all using (auth.uid() = user_id);

create index symptom_logs_user_logged_at on public.symptom_logs(user_id, logged_at desc);

-- ─── Medications ───────────────────────────────────────────────────────────
create table public.medications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  dosage text,
  dosage_unit text,
  frequency text,
  time_of_day text[] not null default '{}',
  is_active boolean not null default true,
  start_date date,
  end_date date,
  created_at timestamptz not null default now()
);

alter table public.medications enable row level security;

create policy "Users can crud own medications"
  on public.medications for all using (auth.uid() = user_id);

-- ─── Medication Logs ───────────────────────────────────────────────────────
create table public.medication_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  medication_name text not null,
  dosage text,
  dosage_unit text,
  scheduled_time time,
  taken_at timestamptz,
  was_taken boolean not null default false,
  side_effects text[] not null default '{}',
  notes text,
  created_at timestamptz not null default now()
);

alter table public.medication_logs enable row level security;

create policy "Users can crud own medication_logs"
  on public.medication_logs for all using (auth.uid() = user_id);

create index medication_logs_user_created_at on public.medication_logs(user_id, created_at desc);

-- ─── Sleep Logs ────────────────────────────────────────────────────────────
create table public.sleep_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  date date not null,
  bedtime timestamptz not null,
  wake_time timestamptz not null,
  duration_minutes integer,
  quality integer not null check (quality between 1 and 5),
  night_wakings integer not null default 0,
  bathroom_wakings integer not null default 0,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.sleep_logs enable row level security;

create policy "Users can crud own sleep_logs"
  on public.sleep_logs for all using (auth.uid() = user_id);

create index sleep_logs_user_date on public.sleep_logs(user_id, date desc);

-- ─── Menstrual Logs ────────────────────────────────────────────────────────
create table public.menstrual_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  date date not null,
  cycle_day integer,
  flow text not null default 'none' check (flow in ('none', 'spotting', 'light', 'medium', 'heavy')),
  symptoms text[] not null default '{}',
  notes text,
  created_at timestamptz not null default now()
);

alter table public.menstrual_logs enable row level security;

create policy "Users can crud own menstrual_logs"
  on public.menstrual_logs for all using (auth.uid() = user_id);

create index menstrual_logs_user_date on public.menstrual_logs(user_id, date desc);

-- ─── Weight Logs ───────────────────────────────────────────────────────────
create table public.weight_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  logged_at timestamptz not null default now(),
  weight_kg decimal(5,2) not null,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.weight_logs enable row level security;

create policy "Users can crud own weight_logs"
  on public.weight_logs for all using (auth.uid() = user_id);

create index weight_logs_user_logged_at on public.weight_logs(user_id, logged_at desc);

-- ─── Chat Messages ─────────────────────────────────────────────────────────
create table public.chat_messages (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz not null default now()
);

alter table public.chat_messages enable row level security;

create policy "Users can crud own chat_messages"
  on public.chat_messages for all using (auth.uid() = user_id);

create index chat_messages_user_created_at on public.chat_messages(user_id, created_at asc);

-- ─── Flare Events ──────────────────────────────────────────────────────────
create table public.flare_events (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  started_at timestamptz not null,
  ended_at timestamptz,
  severity integer not null check (severity between 1 and 10),
  triggers_identified text[] not null default '{}',
  notes text,
  created_at timestamptz not null default now()
);

alter table public.flare_events enable row level security;

create policy "Users can crud own flare_events"
  on public.flare_events for all using (auth.uid() = user_id);

create index flare_events_user_started_at on public.flare_events(user_id, started_at desc);
