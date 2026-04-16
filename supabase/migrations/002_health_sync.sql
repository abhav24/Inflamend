-- ─── App Settings ───────────────────────────────────────────────────────────
create table if not exists public.app_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  timezone text not null default 'UTC',
  preferred_weight_unit text not null default 'kg' check (preferred_weight_unit in ('kg', 'lb')),
  health_sync_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.app_settings enable row level security;

drop policy if exists "Users can crud own app_settings" on public.app_settings;
create policy "Users can crud own app_settings"
  on public.app_settings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop trigger if exists on_app_settings_updated on public.app_settings;
create trigger on_app_settings_updated
  before update on public.app_settings
  for each row execute procedure public.handle_updated_at();

-- ─── Health Samples (Apple Health imports) ────────────────────────────────
create table if not exists public.health_samples (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  metric text not null check (metric in ('steps', 'heart_rate', 'sleep_hours', 'active_energy_kcal')),
  value numeric(12,4) not null,
  unit text not null,
  observed_at timestamptz not null,
  source text not null default 'apple_health',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (user_id, metric, observed_at, source)
);

alter table public.health_samples enable row level security;

drop policy if exists "Users can crud own health_samples" on public.health_samples;
create policy "Users can crud own health_samples"
  on public.health_samples for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists health_samples_user_metric_observed_at
  on public.health_samples(user_id, metric, observed_at desc);

-- ─── Health Sync State ─────────────────────────────────────────────────────
create table if not exists public.health_sync_state (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null check (provider in ('apple_health')),
  metric text not null check (metric in ('steps', 'heart_rate', 'sleep_hours', 'active_energy_kcal')),
  last_synced_at timestamptz,
  last_cursor text,
  last_status text not null default 'idle' check (last_status in ('idle', 'syncing', 'success', 'error')),
  last_error text,
  updated_at timestamptz not null default now(),
  unique (user_id, provider, metric)
);

alter table public.health_sync_state enable row level security;

drop policy if exists "Users can crud own health_sync_state" on public.health_sync_state;
create policy "Users can crud own health_sync_state"
  on public.health_sync_state for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists health_sync_state_user_provider_metric
  on public.health_sync_state(user_id, provider, metric);

drop trigger if exists on_health_sync_state_updated on public.health_sync_state;
create trigger on_health_sync_state_updated
  before update on public.health_sync_state
  for each row execute procedure public.handle_updated_at();
