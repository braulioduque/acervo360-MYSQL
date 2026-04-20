-- Adds avatar_url to firearms
alter table public.firearms add column if not exists avatar_url text;
