create extension if not exists pg_net with schema extensions;
create extension if not exists supabase_vault with schema vault;

-- Cron commands contain only stable function names. Runtime endpoint and the
-- modern secret key are read from Vault and sent in a request header, never in
-- a URL, query string, migration, or cron command.
create or replace function private.invoke_phase13_edge_worker(
  worker_name text,
  request_body jsonb default '{}'::jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  project_url text;
  edge_secret text;
  request_id bigint;
begin
  if worker_name not in (
    'cleanup-orphan-question-photos',
    'apple-identity-reconciliation',
    'apple-commerce-reconciliation'
  ) then
    raise exception 'worker_not_allowed';
  end if;

  select trim(secret.decrypted_secret)
  into project_url
  from vault.decrypted_secrets secret
  where secret.name = 'phase13_project_url'
  order by secret.created_at desc
  limit 1;

  select trim(secret.decrypted_secret)
  into edge_secret
  from vault.decrypted_secrets secret
  where secret.name = 'phase13_edge_function_secret'
  order by secret.created_at desc
  limit 1;

  project_url := rtrim(project_url, '/');
  if project_url is null or project_url !~
    '^https://[a-z0-9]{20}\\.supabase\\.co$'
  then
    raise exception 'phase13_project_url_invalid';
  end if;
  if edge_secret is null or edge_secret !~ '^sb_secret_[A-Za-z0-9_-]+$' then
    raise exception 'phase13_edge_function_secret_invalid';
  end if;

  select net.http_post(
    url := project_url || '/functions/v1/' || worker_name,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', edge_secret
    ),
    body := coalesce(request_body, '{}'::jsonb),
    timeout_milliseconds := 30000
  )
  into request_id;

  return request_id;
end;
$$;

-- The manual Admin path remains available, while the reviewed scheduled
-- worker can use the service role. Storage deletion still happens only via
-- the Storage API inside the Edge Function.
create or replace function public.list_orphan_question_photos(
  older_than interval default interval '24 hours'
)
returns table (object_name text)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce((select auth.role()), '') <> 'service_role'
    and not private.is_admin()
  then
    raise exception 'permission_denied';
  end if;

  if older_than < interval '1 hour' then
    raise exception 'retention_too_short';
  end if;

  return query
  select object.name
  from storage.objects object
  where object.bucket_id = 'question-photos'
    and object.created_at < statement_timestamp() - older_than
    and not exists (
      select 1
      from public.step_submission_answers answer
      where answer.private_photo_path = object.name
    );
end;
$$;

create or replace function public.record_orphan_question_photo_cleanup(
  deleted_object_names text[],
  cleanup_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce((select auth.role()), '') <> 'service_role'
    and not private.is_admin()
  then
    raise exception 'permission_denied';
  end if;

  if length(trim(coalesce(cleanup_reason, ''))) = 0 then
    raise exception 'reason_required';
  end if;

  if coalesce(cardinality(deleted_object_names), 0) = 0 then
    raise exception 'deleted_objects_required';
  end if;

  insert into public.audit_events (
    actor_id,
    kind,
    subject_id,
    summary,
    payload
  )
  values (
    case
      when coalesce((select auth.role()), '') = 'service_role' then null
      else (select auth.uid())
    end,
    'question_photo_orphans_cleaned',
    gen_random_uuid(),
    cleanup_reason,
    jsonb_build_object(
      'deleted_count', cardinality(deleted_object_names),
      'object_name_hashes', (
        select jsonb_agg(
          pg_catalog.encode(
            extensions.digest(value::bytea, 'sha256'),
            'hex'
          )
        )
        from unnest(deleted_object_names) value
      )
    )
  );
end;
$$;

revoke execute on function
  private.invoke_phase13_edge_worker(text, jsonb)
from public, anon, authenticated, service_role;

revoke execute on function public.list_orphan_question_photos(interval)
  from public, anon, authenticated, service_role;
revoke execute on function public.record_orphan_question_photo_cleanup(
  text[], text
) from public, anon, authenticated, service_role;

grant execute on function public.list_orphan_question_photos(interval)
  to authenticated, service_role;
grant execute on function public.record_orphan_question_photo_cleanup(
  text[], text
) to authenticated, service_role;

do $$
begin
  if to_regprocedure('cron.schedule(text,text,text)') is null then
    raise exception 'pg_cron_missing';
  end if;

  if not exists (
    select 1 from cron.job
    where jobname = 'phase13-orphan-question-photo-cleanup'
  ) then
    perform cron.schedule(
      'phase13-orphan-question-photo-cleanup',
      '12 3 * * *',
      $job$
        select private.invoke_phase13_edge_worker(
          'cleanup-orphan-question-photos',
          '{"older_than_hours":24,"reason":"Pembersihan media pertanyaan yatim terjadwal."}'::jsonb
        )
      $job$
    );
  end if;

  if not exists (
    select 1 from cron.job
    where jobname = 'phase13-apple-identity-reconciliation'
  ) then
    perform cron.schedule(
      'phase13-apple-identity-reconciliation',
      '2-59/15 * * * *',
      $job$
        select private.invoke_phase13_edge_worker(
          'apple-identity-reconciliation'
        )
      $job$
    );
  end if;

  if not exists (
    select 1 from cron.job
    where jobname = 'phase13-apple-commerce-reconciliation'
  ) then
    perform cron.schedule(
      'phase13-apple-commerce-reconciliation',
      '7-59/15 * * * *',
      $job$
        select private.invoke_phase13_edge_worker(
          'apple-commerce-reconciliation'
        )
      $job$
    );
  end if;
end;
$$;
