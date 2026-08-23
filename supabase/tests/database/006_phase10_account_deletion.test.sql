begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(18);

select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.prepare_my_account_deletion()',
    'execute'
  ),
  'authenticated can call the account-deletion preflight'
);
select extensions.ok(
  not has_function_privilege(
    'anon',
    'public.prepare_my_account_deletion()',
    'execute'
  ),
  'anon cannot call the account-deletion preflight'
);
select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.finalize_my_account_deletion()',
    'execute'
  ),
  'authenticated can call account-deletion finalization'
);
select extensions.ok(
  not has_function_privilege(
    'anon',
    'public.finalize_my_account_deletion()',
    'execute'
  ),
  'anon cannot call account-deletion finalization'
);
select extensions.is(
  (
    select count(*)::bigint
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
  0::bigint,
  'all SECURITY DEFINER functions retain an empty search path'
);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    'c1000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'deletion-participant@test.invalid',
    '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    'c1000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'deletion-admin@test.invalid',
    '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    'c1000000-0000-0000-0000-000000000003',
    'authenticated', 'authenticated', 'deletion-coach@test.invalid',
    '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    'c1000000-0000-0000-0000-000000000004',
    'authenticated', 'authenticated', 'deletion-enrollee@test.invalid',
    '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()
  );

update public.profiles
set role = 'admin',
    display_name = 'Admin Penghapusan',
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = 'c1000000-0000-0000-0000-000000000002';

update public.profiles
set role = 'coach',
    display_name = 'Coach Penghapusan',
    coach_qr_identifier = 'deletion-coach-qr',
    coach_is_approved = true,
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = 'c1000000-0000-0000-0000-000000000003';

update public.profiles
set display_name = 'Peserta Dihapus',
    phone_number = '081234567890',
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = 'c1000000-0000-0000-0000-000000000001';

update public.profiles
set display_name = 'Peserta Coach',
    current_coach_id = 'c1000000-0000-0000-0000-000000000003',
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = 'c1000000-0000-0000-0000-000000000004';

insert into public.programs (
  id, title, status, pace, duration_mode, starts_on, ends_on, timezone,
  participant_limit, registration_closes_at, past_step_policy,
  future_step_policy, wellness_disclaimer, points_per_activity,
  points_per_weight_kg, quiz_passing_percentage, pricing_mode,
  desired_price, created_by
)
values (
  'c2000000-0000-0000-0000-000000000001',
  'Program Penghapusan', 'active', 'scheduled', 'fixed_duration',
  current_date, current_date + 7, 'Asia/Jakarta', null,
  clock_timestamp() + interval '1 day', 'available', 'locked',
  'Program kebugaran non-diagnostik.', 10, 100, 70, 'free', null,
  'c1000000-0000-0000-0000-000000000002'
);

insert into public.program_enrollments (
  program_id, participant_id, coach_id, status
)
values (
  'c2000000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000004',
  'c1000000-0000-0000-0000-000000000003',
  'active'
);

insert into public.commerce_transactions (
  platform, environment, external_transaction_id, program_id,
  participant_id, product_id, status, signed_payload_hash, purchased_at
)
values (
  'app_store', 'local_test', 'phase10-retained-transaction',
  'c2000000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000001',
  'phase10.local.program', 'verified', 'non-sensitive-test-hash', now()
);

insert into public.audit_events (
  actor_id, kind, subject_id, summary, payload
)
values (
  'c1000000-0000-0000-0000-000000000001',
  'account_test',
  'c1000000-0000-0000-0000-000000000001',
  'Detail identitas sementara',
  '{"private_test_value":"hapus"}'
);

insert into auth.sessions (
  id, user_id, created_at, updated_at
)
values
  (
    'c3000000-0000-0000-0000-000000000001',
    'c1000000-0000-0000-0000-000000000001',
    now() - interval '10 minutes',
    now() - interval '10 minutes'
  ),
  (
    'c3000000-0000-0000-0000-000000000002',
    'c1000000-0000-0000-0000-000000000001',
    now(),
    now()
  ),
  (
    'c3000000-0000-0000-0000-000000000003',
    'c1000000-0000-0000-0000-000000000002',
    now(),
    now()
  ),
  (
    'c3000000-0000-0000-0000-000000000004',
    'c1000000-0000-0000-0000-000000000003',
    now(),
    now()
  );

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"c1000000-0000-0000-0000-000000000001","role":"authenticated","session_id":"c3000000-0000-0000-0000-000000000001"}';

select extensions.throws_like(
  $$ select public.prepare_my_account_deletion() $$,
  'recent_reauthentication_required',
  'a stale session cannot prepare account deletion'
);

set local "request.jwt.claims" =
  '{"sub":"c1000000-0000-0000-0000-000000000001","role":"authenticated","session_id":"c3000000-0000-0000-0000-000000000002"}';

select extensions.is(
  public.prepare_my_account_deletion(),
  '[]'::jsonb,
  'a recently reauthenticated participant receives an empty media manifest'
);
select extensions.is(
  public.finalize_my_account_deletion(),
  'c1000000-0000-0000-0000-000000000001'::uuid,
  'a recently reauthenticated relationship-free participant is finalized'
);
select extensions.throws_like(
  $$ select public.finalize_my_account_deletion() $$,
  'active_account_required',
  'browser retry is denied after the profile leaves active state'
);

reset role;
select extensions.is(
  (
    select onboarding_status
    from public.profiles
    where user_id = 'c1000000-0000-0000-0000-000000000001'
  ),
  'cleanup_pending',
  'finalization marks the profile for immediate identity cleanup'
);
select extensions.is(
  (
    select phone_number
    from public.profiles
    where user_id = 'c1000000-0000-0000-0000-000000000001'
  ),
  null,
  'finalization removes personal contact data'
);

select extensions.is(
  (
    select participant_id
    from public.commerce_transactions
    where external_transaction_id = 'phase10-retained-transaction'
  ),
  null,
  'financial history is retained without a participant identity'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.audit_events
    where kind = 'account_test'
      and actor_id is null
      and subject_id is null
      and summary = 'Akun dihapus'
      and payload = '{}'::jsonb
  ),
  1::bigint,
  'audit history is retained with identifying content redacted'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"c1000000-0000-0000-0000-000000000002","role":"authenticated","session_id":"c3000000-0000-0000-0000-000000000003"}';

select extensions.throws_like(
  $$ select public.prepare_my_account_deletion() $$,
  'admin_account_deletion_not_allowed',
  'Admin self-deletion is denied'
);

set local "request.jwt.claims" =
  '{"sub":"c1000000-0000-0000-0000-000000000003","role":"authenticated","session_id":"c3000000-0000-0000-0000-000000000004"}';

select extensions.throws_like(
  $$ select public.prepare_my_account_deletion() $$,
  'account_relationships_require_transfer',
  'a Coach with assigned participants must be transferred first'
);

reset role;

select extensions.lives_ok(
  $$
    delete from auth.users
    where id = 'c1000000-0000-0000-0000-000000000001'
  $$,
  'trusted server hard deletion succeeds after finalization'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.profiles
    where user_id = 'c1000000-0000-0000-0000-000000000001'
  ),
  0::bigint,
  'hard-deleting the Auth identity cascades the redacted profile'
);
select extensions.is(
  (
    select confdeltype::text
    from pg_constraint
    where conname = 'program_winners_participant_id_fkey'
  ),
  'n',
  'winner snapshots anonymize the participant reference on deletion'
);

select * from extensions.finish();
rollback;
