-- Forward fix: migration 20260809090027 intentionally remains immutable after
-- production deployment. PostgreSQL standard strings pass its doubled
-- backslashes to the regex engine, so a valid hosted URL was rejected. Character
-- classes avoid escape ambiguity while preserving the strict host allowlist.
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
    '^https://[a-z0-9]{20}[.]supabase[.]co$'
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

revoke execute on function
  private.invoke_phase13_edge_worker(text, jsonb)
from public, anon, authenticated, service_role;
