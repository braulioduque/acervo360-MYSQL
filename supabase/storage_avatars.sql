begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-avatars',
  'profile-avatars',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public read profile avatars" on storage.objects;
drop policy if exists "Authenticated read own avatar" on storage.objects;
create policy "Authenticated read own avatar"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'profile-avatars'
  and name like auth.uid()::text || '/%'
);

drop policy if exists "Authenticated upload own avatar" on storage.objects;
create policy "Authenticated upload own avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profile-avatars'
  and name like auth.uid()::text || '/%'
);

drop policy if exists "Authenticated update own avatar" on storage.objects;
create policy "Authenticated update own avatar"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profile-avatars'
  and name like auth.uid()::text || '/%'
)
with check (
  bucket_id = 'profile-avatars'
  and name like auth.uid()::text || '/%'
);

drop policy if exists "Authenticated delete own avatar" on storage.objects;
create policy "Authenticated delete own avatar"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'profile-avatars'
  and name like auth.uid()::text || '/%'
);

commit;