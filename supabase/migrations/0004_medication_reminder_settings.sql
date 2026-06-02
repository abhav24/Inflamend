alter table public.user_settings
  add column if not exists medication_reminder_lead_time_minutes integer not null default 10,
  add constraint user_settings_medication_reminder_lead_time_check
    check (medication_reminder_lead_time_minutes in (0, 10, 30, 60));

comment on column public.user_settings.medication_reminder_lead_time_minutes
  is 'User-selected medication reminder lead time in minutes. iOS notification scheduling remains client-side and permission-gated.';
