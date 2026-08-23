create extension if not exists pg_net with schema extensions;
create extension if not exists supabase_vault with schema vault;

create or replace function private.invoke_w08_web_job(
  worker_name text,
  request_body jsonb default '{}'::jsonb
)
returns bigint
language plpgsql security definer
set search_path = ''
as $$
declare
  project_url text;
  job_secret text;
  vault_secret_name text;
  request_id bigint;
begin
  vault_secret_name := case worker_name
    when 'cleanup-orphan-payment-evidence' then 'w08_payment_cleanup_job_secret'
    when 'process-provisional-cancellations' then 'w08_provisional_cleanup_job_secret'
    when 'process-food-insight' then 'w08_food_ai_worker_secret'
    else null
  end;
  if vault_secret_name is null then raise exception 'worker_not_allowed'; end if;

  select trim(secret.decrypted_secret) into project_url
  from vault.decrypted_secrets secret
  where secret.name = 'w08_project_url'
  order by secret.created_at desc limit 1;

  select trim(secret.decrypted_secret) into job_secret
  from vault.decrypted_secrets secret
  where secret.name = vault_secret_name
  order by secret.created_at desc limit 1;

  project_url := rtrim(project_url, '/');
  if project_url is null
    or project_url !~ '^https://[a-z0-9]{20}[.]supabase[.]co$' then
    raise exception 'w08_project_url_invalid';
  end if;
  if job_secret is null or job_secret !~ '^[a-f0-9]{64}$' then
    raise exception 'w08_job_secret_invalid';
  end if;

  select net.http_post(
    url := project_url || '/functions/v1/' || worker_name,
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || job_secret,
      'Content-Type', 'application/json'
    ),
    body := coalesce(request_body, '{}'::jsonb),
    timeout_milliseconds := 30000
  ) into request_id;
  return request_id;
end;
$$;

revoke execute on function private.invoke_w08_web_job(text,jsonb)
  from public, anon, authenticated, service_role;

do $$
begin
  if to_regprocedure('cron.schedule(text,text,text)') is null then
    raise exception 'pg_cron_missing';
  end if;

  if not exists (
    select 1 from cron.job where jobname = 'w08-payment-evidence-cleanup-dry-run'
  ) then
    perform cron.schedule(
      'w08-payment-evidence-cleanup-dry-run',
      '0 18 * * *',
      $job$
        select private.invoke_w08_web_job(
          'cleanup-orphan-payment-evidence',
          '{"dryRun":true,"batchSize":100,"minimumAgeHours":72}'::jsonb
        )
      $job$
    );
  end if;

  if not exists (
    select 1 from cron.job where jobname = 'w08-provisional-cancellation-cleanup'
  ) then
    perform cron.schedule(
      'w08-provisional-cancellation-cleanup',
      '1-59/5 * * * *',
      $job$
        select private.invoke_w08_web_job(
          'process-provisional-cancellations',
          '{"batchSize":20}'::jsonb
        )
      $job$
    );
  end if;

  if not exists (
    select 1 from cron.job where jobname = 'w08-food-insight-worker'
  ) then
    perform cron.schedule(
      'w08-food-insight-worker',
      '3-59/5 * * * *',
      $job$
        select private.invoke_w08_web_job(
          'process-food-insight',
          '{"batchSize":5}'::jsonb
        )
      $job$
    );
  end if;
end;
$$;
