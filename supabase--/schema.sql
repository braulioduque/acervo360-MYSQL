begin;

create extension if not exists pgcrypto;

create type public.gte_status as enum (
  'draft',
  'submitted',
  'approved',
  'expired',
  'cancelled'
);

create type public.document_kind as enum (
  'cr',
  'craf',
  'gte',
  'nf',
  'outro'
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  cpf text unique,
  cr_number text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_cpf_digits check (cpf is null or cpf ~ '^[0-9]{11}$')
);

create table public.firearms (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  nickname text,
  brand text,
  model text,
  caliber text,
  serial_number text,
  acquisition_date date,
  status text not null default 'ativo',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint firearms_status_check check (status in ('ativo', 'inativo', 'vendido'))
);

create table public.clubs (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  document_number text,
  city text,
  state text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.club_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  club_id uuid not null references public.clubs(id) on delete cascade,
  role text not null default 'member',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint club_memberships_role_check check (role in ('owner', 'admin', 'member')),
  constraint club_memberships_unique unique (user_id, club_id)
);

create table public.gtes (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  firearm_id uuid references public.firearms(id) on delete set null,
  origin_club_id uuid references public.clubs(id) on delete set null,
  destination_club_id uuid references public.clubs(id) on delete set null,
  protocol_number text,
  issued_at timestamptz,
  expires_at timestamptz,
  status public.gte_status not null default 'draft',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  firearm_id uuid references public.firearms(id) on delete set null,
  gte_id uuid references public.gtes(id) on delete cascade,
  kind public.document_kind not null,
  title text not null,
  storage_path text not null,
  mime_type text,
  expires_at date,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index firearms_owner_idx on public.firearms(owner_user_id);
create index clubs_owner_idx on public.clubs(owner_user_id);
create index memberships_user_idx on public.club_memberships(user_id);
create index memberships_club_idx on public.club_memberships(club_id);
create index gtes_owner_idx on public.gtes(owner_user_id);
create index gtes_expires_idx on public.gtes(expires_at);
create index documents_owner_idx on public.documents(owner_user_id);
create index documents_gte_idx on public.documents(gte_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger trg_firearms_updated_at
before update on public.firearms
for each row execute function public.set_updated_at();

create trigger trg_clubs_updated_at
before update on public.clubs
for each row execute function public.set_updated_at();

create trigger trg_memberships_updated_at
before update on public.club_memberships
for each row execute function public.set_updated_at();

create trigger trg_gtes_updated_at
before update on public.gtes
for each row execute function public.set_updated_at();

create trigger trg_documents_updated_at
before update on public.documents
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', ''))
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.firearms enable row level security;
alter table public.clubs enable row level security;
alter table public.club_memberships enable row level security;
alter table public.gtes enable row level security;
alter table public.documents enable row level security;

create policy "profiles_select_own"
on public.profiles
for select
using (auth.uid() = id);

create policy "profiles_insert_own"
on public.profiles
for insert
with check (auth.uid() = id);

create policy "profiles_update_own"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "firearms_all_own"
on public.firearms
for all
using (auth.uid() = owner_user_id)
with check (auth.uid() = owner_user_id);

create policy "clubs_all_own"
on public.clubs
for all
using (auth.uid() = owner_user_id)
with check (auth.uid() = owner_user_id);

create policy "memberships_all_own"
on public.club_memberships
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "gtes_all_own"
on public.gtes
for all
using (auth.uid() = owner_user_id)
with check (auth.uid() = owner_user_id);

create policy "documents_all_own"
on public.documents
for all
using (auth.uid() = owner_user_id)
with check (auth.uid() = owner_user_id);

commit;
