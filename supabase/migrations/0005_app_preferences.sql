alter table public.user_settings
  add column if not exists preferred_weight_unit text not null default 'kg',
  add column if not exists use_device_timezone boolean not null default true,
  add column if not exists time_zone_identifier text not null default 'UTC',
  add constraint user_settings_preferred_weight_unit_check
    check (preferred_weight_unit in ('kg', 'lb'));

comment on column public.user_settings.preferred_weight_unit
  is 'User-selected weight unit for local logging and future backend settings sync.';

comment on column public.user_settings.use_device_timezone
  is 'Whether the client should use the current device timezone for local date grouping.';

comment on column public.user_settings.time_zone_identifier
  is 'IANA timezone identifier used when device timezone is not selected.';
