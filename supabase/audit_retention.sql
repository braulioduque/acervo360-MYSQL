begin;

create or replace function public.purge_security_audit_logs(retention_days integer default 90)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_rows integer;
begin
  delete from public.security_audit_logs
  where created_at < now() - make_interval(days => greatest(retention_days, 1));

  get diagnostics deleted_rows = row_count;
  return deleted_rows;
end;
$$;

-- Tenta agendar expurgo diario as 03:15 UTC (00:15 BRT sem horario de verao).
do $$
begin
  begin
    create extension if not exists pg_cron;
  exception
    when others then
      raise notice 'pg_cron nao disponivel/permitido neste projeto. Agendamento automatico nao foi criado.';
      return;
  end;

  perform cron.unschedule(jobid)
  from cron.job
  where jobname = 'purge_security_audit_logs_daily';

  perform cron.schedule(
    'purge_security_audit_logs_daily',
    '15 3 * * *',
    'select public.purge_security_audit_logs(90);'
  );
end;
$$;

commit;
