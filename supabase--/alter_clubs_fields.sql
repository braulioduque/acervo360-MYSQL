-- Adds the extra club fields used by the app.
alter table public.clubs add column if not exists cr_number text;
alter table public.clubs add column if not exists cnpj text;
alter table public.clubs add column if not exists phone text;
alter table public.clubs add column if not exists street text;
alter table public.clubs add column if not exists number text;
alter table public.clubs add column if not exists complement text;
alter table public.clubs add column if not exists neighborhood text;
alter table public.clubs add column if not exists logo_url text;

-- Phone must have 11 digits when present.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'clubs_phone_digits'
  ) then
    alter table public.clubs
      add constraint clubs_phone_digits
      check (phone is null or phone ~ '^[0-9]{11}$');
  end if;
end $$;

-- CNPJ must have 14 digits when present.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'clubs_cnpj_digits'
  ) then
    alter table public.clubs
      add constraint clubs_cnpj_digits
      check (cnpj is null or cnpj ~ '^[0-9]{14}$');
  end if;
end $$;
