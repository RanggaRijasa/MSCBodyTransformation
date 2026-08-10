begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(15);

select extensions.ok(
  has_function_privilege(
    'service_role',
    'public.list_orphan_question_photos(interval)',
    'execute'
  ),
  'service role can list orphan media for the scheduled worker'
);
select extensions.ok(
  has_function_privilege(
    'service_role',
    'public.record_orphan_question_photo_cleanup(text[],text)',
    'execute'
  ),
  'service role can record scheduled orphan cleanup'
);
select extensions.ok(
  not has_function_privilege(
    'anon',
    'public.list_orphan_question_photos(interval)',
    'execute'
  ),
  'anon cannot list orphan media'
);
select extensions.ok(
  not has_function_privilege(
    'authenticated',
    'private.invoke_phase13_edge_worker(text,jsonb)',
    'execute'
  ),
  'authenticated cannot invoke scheduled Edge workers'
);
select extensions.ok(
  not has_function_privilege(
    'service_role',
    'private.invoke_phase13_edge_worker(text,jsonb)',
    'execute'
  ),
  'service role cannot invoke the private cron dispatcher directly'
);

select extensions.ok(
  exists (
    select 1 from cron.job
    where jobname = 'phase13-orphan-question-photo-cleanup'
      and schedule = '12 3 * * *'
      and active
      and command not ilike '%sb_secret_%'
  ),
  'orphan cleanup schedule is active without an embedded secret'
);
select extensions.ok(
  exists (
    select 1 from cron.job
    where jobname = 'phase13-apple-identity-reconciliation'
      and schedule = '2-59/15 * * * *'
      and active
      and command not ilike '%sb_secret_%'
  ),
  'Apple identity reconciliation schedule is active without a secret'
);
select extensions.ok(
  exists (
    select 1 from cron.job
    where jobname = 'phase13-apple-commerce-reconciliation'
      and schedule = '7-59/15 * * * *'
      and active
      and command not ilike '%sb_secret_%'
  ),
  'Apple commerce reconciliation schedule is active without a secret'
);
select extensions.is(
  (
    select count(*)::bigint from cron.job
    where jobname like 'phase13-%'
  ),
  3::bigint,
  'exactly three Phase 13 Edge worker schedules exist'
);

select extensions.throws_ok(
  $$select private.invoke_phase13_edge_worker('unreviewed-worker')$$,
  'P0001',
  'worker_not_allowed',
  'dispatcher rejects an unreviewed worker name'
);
select extensions.throws_ok(
  $$select private.invoke_phase13_edge_worker('apple-identity-reconciliation')$$,
  'P0001',
  'phase13_project_url_invalid',
  'dispatcher fails closed before Vault configuration exists'
);

do $$
begin
  perform vault.create_secret(
    'https://abcdefghijklmnopqrst.supabase.co',
    'phase13_project_url',
    'pgTAP fixture rolled back with this transaction'
  );
  perform vault.create_secret(
    'sb_secret_phase13_test_only',
    'phase13_edge_function_secret',
    'pgTAP fixture rolled back with this transaction'
  );
end;
$$;
select extensions.lives_ok(
  $$select private.invoke_phase13_edge_worker('apple-identity-reconciliation')$$,
  'dispatcher accepts a valid hosted URL and modern secret shape'
);

select extensions.ok(
  exists (
    select 1
    from pg_proc procedure
    join pg_namespace namespace
      on namespace.oid = procedure.pronamespace
    where namespace.nspname = 'private'
      and procedure.proname = 'invoke_phase13_edge_worker'
      and procedure.prosecdef
      and coalesce(procedure.proconfig, '{}'::text[])
        @> array['search_path=""']
  ),
  'dispatcher is SECURITY DEFINER with an empty fixed search path'
);
select extensions.ok(
  not exists (
    select 1
    from cron.job
    where command ilike '%apikey%'
       or command ilike '%authorization%'
       or command ilike '%phase13_edge_function_secret%'
  ),
  'cron commands do not embed header names or Vault secret identifiers'
);
select extensions.ok(
  not exists (
    select 1
    from pg_proc procedure
    join pg_namespace namespace
      on namespace.oid = procedure.pronamespace
    where namespace.nspname in ('public', 'private')
      and procedure.prosecdef
      and not (
        coalesce(procedure.proconfig, '{}'::text[])
          @> array['search_path=""']
      )
  ),
  'all application SECURITY DEFINER functions retain fixed search paths'
);

select * from extensions.finish();
rollback;
