-- =============================================
-- Migration: user_subscriptions
-- Tabela de assinaturas do ACERVO360
-- =============================================

-- Enums para plano e status
create type public.subscription_plan as enum (
  'trial',
  'monthly',
  'quarterly',
  'yearly',
  'lifetime'
);

create type public.subscription_status as enum (
  'active',
  'expired'
);

-- Tabela principal
create table public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan public.subscription_plan not null default 'trial',
  start_date timestamptz not null default now(),
  end_date timestamptz,  -- null para plano lifetime
  status public.subscription_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_subscriptions_unique_user unique (user_id)
);

-- Índice para busca rápida por user_id
create index user_subscriptions_user_idx on public.user_subscriptions(user_id);

-- Trigger de updated_at (reusa a função set_updated_at() existente)
create trigger trg_user_subscriptions_updated_at
before update on public.user_subscriptions
for each row execute function public.set_updated_at();

-- =============================================
-- RLS — cada usuário lê/atualiza apenas sua assinatura
-- =============================================
alter table public.user_subscriptions enable row level security;

create policy "user_subscriptions_select_own"
on public.user_subscriptions
for select
using (auth.uid() = user_id);

create policy "user_subscriptions_insert_own"
on public.user_subscriptions
for insert
with check (auth.uid() = user_id);

create policy "user_subscriptions_update_own"
on public.user_subscriptions
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- =============================================
-- Atualizar handle_new_user() para criar trial automático
-- =============================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Cria perfil do usuário
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', ''))
  on conflict (id) do nothing;

  -- Cria assinatura trial de 30 dias
  insert into public.user_subscriptions (user_id, plan, start_date, end_date, status)
  values (new.id, 'trial', now(), now() + interval '30 days', 'active')
  on conflict (user_id) do nothing;

  return new;
end;
$$;
