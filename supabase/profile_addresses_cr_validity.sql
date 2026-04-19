begin;

alter table public.profiles
  add column if not exists cr_valid_until date;

create table if not exists public.profile_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  address_type text not null,
  street text not null,
  number text not null,
  complement text,
  neighborhood text not null,
  state_code char(2) not null,
  city text not null,
  postal_code text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profile_addresses_type_check check (address_type in ('primary', 'secondary')),
  constraint profile_addresses_user_type_unique unique (user_id, address_type),
  constraint profile_addresses_postal_code_digits check (postal_code ~ '^[0-9]{8}$')
);

create index if not exists profile_addresses_user_idx on public.profile_addresses(user_id);

alter table public.profile_addresses enable row level security;

drop policy if exists "profile_addresses_select_own" on public.profile_addresses;
create policy "profile_addresses_select_own"
on public.profile_addresses
for select
using (auth.uid() = user_id);

drop policy if exists "profile_addresses_insert_own" on public.profile_addresses;
create policy "profile_addresses_insert_own"
on public.profile_addresses
for insert
with check (auth.uid() = user_id);

drop policy if exists "profile_addresses_update_own" on public.profile_addresses;
create policy "profile_addresses_update_own"
on public.profile_addresses
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "profile_addresses_delete_own" on public.profile_addresses;
create policy "profile_addresses_delete_own"
on public.profile_addresses
for delete
using (auth.uid() = user_id);

drop trigger if exists trg_profile_addresses_updated_at on public.profile_addresses;
create trigger trg_profile_addresses_updated_at
before update on public.profile_addresses
for each row execute function public.set_updated_at();

commit;


\r\n-- CR categories and phone\r\nalter table public.profiles\r\n  add column if not exists phone text;\r\n\r\nalter table public.profiles\r\n  add column if not exists cr_categories text[];\r\n\r\nupdate public.profiles\r\nset cr_categories = array[cr_category]\r\nwhere cr_categories is null and cr_category is not null;\r\n\r\ndo \r\nbegin\r\n  if not exists (\r\n    select 1 from pg_constraint where conname = 'profiles_cr_categories_check'\r\n  ) then\r\n    alter table public.profiles\r\n      add constraint profiles_cr_categories_check\r\n      check (cr_categories is null or cr_categories <@ array['Caçador','Atirador','Colecionador']);\r\n  end if;\r\nend ;\r\n
