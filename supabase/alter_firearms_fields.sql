-- Adds extra firearm fields for CRAF and registry.
alter table public.firearms add column if not exists firearm_type text;
alter table public.firearms add column if not exists registry_type text;
alter table public.firearms add column if not exists craf_number text;
alter table public.firearms add column if not exists craf_valid_until date;

-- Firearm type constraint.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'firearms_type_check'
  ) then
    alter table public.firearms
      add constraint firearms_type_check
      check (firearm_type is null or firearm_type in (
        'Carabina/Fuzil',
        'Espingarda',
        'Pistola',
        'Revolver',
        'Rifle/Fuzil'
      ));
  end if;
end $$;

-- Registry type constraint.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'firearms_registry_check'
  ) then
    alter table public.firearms
      add constraint firearms_registry_check
      check (registry_type is null or registry_type in ('SIGMA', 'SINARM'));
  end if;
end $$;
