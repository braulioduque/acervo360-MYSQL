-- Bucket for firearm avatars (private)
insert into storage.buckets (id, name, public)
values ('firearm-avatars', 'firearm-avatars', false)
on conflict (id) do nothing;

alter table storage.objects enable row level security;

-- Policies
drop policy if exists "firearm_avatars_read_own" on storage.objects;
create policy "firearm_avatars_read_own"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'firearm-avatars'
  and name like auth.uid() || '/%'
);

drop policy if exists "firearm_avatars_insert_own" on storage.objects;
create policy "firearm_avatars_insert_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'firearm-avatars'
  and name like auth.uid() || '/%'
);

drop policy if exists "firearm_avatars_update_own" on storage.objects;
create policy "firearm_avatars_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'firearm-avatars'
  and name like auth.uid() || '/%'
)
with check (
  bucket_id = 'firearm-avatars'
  and name like auth.uid() || '/%'
);

drop policy if exists "firearm_avatars_delete_own" on storage.objects;
create policy "firearm_avatars_delete_own"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'firearm-avatars'
  and name like auth.uid() || '/%'
);
