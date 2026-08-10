-- Phase 13.1 hosted-main read-only verification.
--
-- This file intentionally contains one SELECT statement only. It must never
-- print account identifiers, private media paths, tokens, keys, signed
-- payloads, body-weight values, or other personal data.

select jsonb_build_object(
  'public_tables_without_rls', (
    select count(*)
    from pg_catalog.pg_class relation
    join pg_catalog.pg_namespace namespace
      on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relkind in ('r', 'p')
      and not relation.relrowsecurity
  ),
  'private_table_grants_to_clients', (
    select count(*)
    from information_schema.role_table_grants grants
    where grants.table_schema = 'private'
      and grants.grantee in ('anon', 'authenticated')
  ),
  'security_definer_without_fixed_search_path', (
    select count(*)
    from pg_catalog.pg_proc procedure
    join pg_catalog.pg_namespace namespace
      on namespace.oid = procedure.pronamespace
    where namespace.nspname in ('public', 'private')
      and procedure.prosecdef
      and not exists (
        select 1
        from unnest(coalesce(procedure.proconfig, array[]::text[])) setting
        where setting like 'search_path=%'
      )
  ),
  'security_definer_executable_by_public', (
    select count(*)
    from pg_catalog.pg_proc procedure
    join pg_catalog.pg_namespace namespace
      on namespace.oid = procedure.pronamespace
    where namespace.nspname in ('public', 'private')
      and procedure.prosecdef
      and has_function_privilege('public', procedure.oid, 'EXECUTE')
  ),
  'ordinary_views_without_security_invoker', (
    select count(*)
    from pg_catalog.pg_class relation
    join pg_catalog.pg_namespace namespace
      on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and relation.relkind = 'v'
      and not coalesce(relation.reloptions, array[]::text[])
        @> array['security_invoker=true']
  ),
  'rls_auto_enable_public_execute', (
    select case
      when to_regprocedure('public.rls_auto_enable()') is null then false
      else has_function_privilege(
        'public',
        to_regprocedure('public.rls_auto_enable()'),
        'EXECUTE'
      )
    end
  ),
  'cron_jobs', (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'jobname', jobname,
          'schedule', schedule,
          'active', active
        )
        order by jobname
      ),
      '[]'::jsonb
    )
    from cron.job
  ),
  'program_product_counts', (
    select coalesce(jsonb_object_agg(environment, product_count), '{}'::jsonb)
    from (
      select environment, count(*) as product_count
      from public.program_store_products
      group by environment
    ) counts
  ),
  'coach_product_counts', (
    select coalesce(jsonb_object_agg(environment, product_count), '{}'::jsonb)
    from (
      select environment, count(*) as product_count
      from public.coach_store_products
      group by environment
    ) counts
  ),
  'public_bucket_count', (
    select count(*) filter (where public)
    from storage.buckets
  ),
  'private_bucket_count', (
    select count(*) filter (where not public)
    from storage.buckets
  ),
  'hosted_auth_user_count', (
    select count(*)
    from auth.users
  )
) as audit;
