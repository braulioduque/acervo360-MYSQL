begin;

create table if not exists public.security_audit_logs (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  event_type text not null,
  user_id uuid,
  request_id text,
  ip_address text,
  user_agent text,
  success boolean not null default false,
  details jsonb not null default '{}'::jsonb
);

create index if not exists security_audit_logs_event_idx
  on public.security_audit_logs (event_type, created_at desc);

create index if not exists security_audit_logs_user_event_idx
  on public.security_audit_logs (user_id, event_type, created_at desc);

alter table public.security_audit_logs enable row level security;

drop policy if exists "security_audit_logs_no_access" on public.security_audit_logs;
create policy "security_audit_logs_no_access"
  on public.security_audit_logs
  for all
  using (false)
  with check (false);

commit;
