-- Promote published scheduled programs when their local start date arrives.
-- The UI also derives an effective lifecycle from program dates so a delayed
-- scheduler run cannot render a currently running program as upcoming.
create or replace function private.activate_due_programs()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  activated_count integer;
begin
  with activated as (
    update public.programs program
    set status = 'active',
        updated_at = statement_timestamp()
    where program.status = 'scheduled'
      and program.published_at is not null
      and program.starts_on <= timezone(program.timezone, statement_timestamp())::date
    returning program.id, program.starts_on, program.timezone
  ), audited as (
    insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
    select
      null,
      'program_activated',
      activated.id,
      'Program diaktifkan otomatis sesuai jadwal.',
      jsonb_build_object(
        'starts_on', activated.starts_on,
        'timezone', activated.timezone,
        'source', 'program_lifecycle_job'
      )
    from activated
    returning subject_id
  )
  select count(*)::integer into activated_count from audited;

  return activated_count;
end;
$$;

revoke all on function private.activate_due_programs()
from public, anon, authenticated, service_role;

do $$
begin
  if to_regprocedure('cron.schedule(text,text,text)') is null then
    raise exception 'pg_cron_missing';
  end if;

  if not exists (
    select 1 from cron.job where jobname = 'w08-program-lifecycle-activation'
  ) then
    perform cron.schedule(
      'w08-program-lifecycle-activation',
      '*/5 * * * *',
      $job$select private.activate_due_programs()$job$
    );
  end if;
end;
$$;

select private.activate_due_programs();
