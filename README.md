# acervo360

Aplicativo Flutter com autenticacao integrada ao Supabase.

## Configuracao do Supabase

1. Crie o arquivo `.env` na raiz do projeto:

```env
SUPABASE_URL=https://SEU-PROJETO.supabase.co
SUPABASE_ANON_KEY=SUA_ANON_KEY
```

2. Crie o schema do banco no Supabase SQL Editor executando:

- [schema.sql](supabase/schema.sql)
- [audit_hardening.sql](supabase/audit_hardening.sql)
- [audit_retention.sql](supabase/audit_retention.sql)
- [storage_avatars.sql](supabase/storage_avatars.sql)
- [profile_addresses_cr_validity.sql](supabase/profile_addresses_cr_validity.sql)

3. Habilite exclusao total do usuario via Edge Function:

```bash
supabase functions deploy delete-user
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=SEU_SERVICE_ROLE_KEY
```

4. (Opcional) Configure rate limit da exclusao total:

```bash
supabase secrets set DELETE_USER_RATE_LIMIT_MAX=3
supabase secrets set DELETE_USER_RATE_LIMIT_WINDOW_MINUTES=60
```

5. Instale dependencias e rode com variaveis em tempo de build (sem embutir `.env` como asset):

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

## Fluxos implementados

- Login com e-mail/senha (`signInWithPassword`)
- Cadastro (`signUp`)
- Recuperacao de senha (`resetPasswordForEmail`)
- CRUD de conta em `profiles`
- Upload de avatar para Supabase Storage (`profile-avatars` privado com URL assinada)
- Exclusao total de usuario (`auth.users`) via `functions.invoke('delete-user')`
- Rate limit + auditoria estruturada na Edge Function de exclusao
- Expurgo automatico de logs de auditoria (retencao de 90 dias)

