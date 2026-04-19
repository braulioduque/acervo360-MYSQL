-- Bucket for CRAF documents (private)
insert into storage.buckets (id, name, public)
values ('craf-documents', 'craf-documents', false)
on conflict (id) do nothing;

alter table storage.objects enable row level security;

-- Policies
drop policy if exists "craf_documents_read_own" on storage.objects;
create policy "craf_documents_read_own"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'craf-documents'
  and name like auth.uid() || '/%'
);

drop policy if exists "craf_documents_insert_own" on storage.objects;
create policy "craf_documents_insert_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'craf-documents'
  and name like auth.uid() || '/%'
);

drop policy if exists "craf_documents_update_own" on storage.objects;
create policy "craf_documents_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'craf-documents'
  and name like auth.uid() || '/%'
)
with check (
  bucket_id = 'craf-documents'
  and name like auth.uid() || '/%'
);

drop policy if exists "craf_documents_delete_own" on storage.objects;
create policy "craf_documents_delete_own"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'craf-documents'
  and name like auth.uid() || '/%'
);
