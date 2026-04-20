-- Script para atualizar banco de dados para anexos do CRAF
begin;

-- 1. Cria o bucket para documentos do CRAF
insert into storage.buckets (id, name, public) 
values ('craf-documents', 'craf-documents', false)
on conflict (id) do nothing;

-- 2. Políticas de segurança (Row Level Security) para o novo bucket
create policy "Users can view own craf documents" 
on storage.objects for select 
using ( bucket_id = 'craf-documents' and auth.uid() = owner );

create policy "Users can upload own craf documents" 
on storage.objects for insert 
with check ( bucket_id = 'craf-documents' and auth.uid() = owner );

create policy "Users can update own craf documents" 
on storage.objects for update 
using ( bucket_id = 'craf-documents' and auth.uid() = owner );

create policy "Users can delete own craf documents" 
on storage.objects for delete 
using ( bucket_id = 'craf-documents' and auth.uid() = owner );

-- 3. Adiciona a coluna craf_url na tabela firearms, se ela ainda não existir
alter table public.firearms add column if not exists craf_url text;

commit;
