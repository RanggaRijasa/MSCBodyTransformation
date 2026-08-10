begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(37);

select extensions.ok(
  exists (
    select 1 from cron.job
    where jobname = 'phase12-expire-commerce-state'
      and schedule = '*/5 * * * *'
      and command = 'select public.expire_commerce_state()'
      and active
  ),
  'commerce expiry recurring job is installed and active'
);

select extensions.ok(
  not has_table_privilege(
    'authenticated', 'private.apple_identity_credentials', 'select'
  ),
  'authenticated cannot read encrypted Apple credentials'
);
select extensions.ok(
  not has_table_privilege(
    'service_role', 'private.apple_identity_credentials', 'select'
  ),
  'service role must use the reviewed credential operations'
);
select extensions.ok(
  not has_function_privilege(
    'authenticated',
    'public.store_apple_identity_credential(uuid,text,text,text)',
    'execute'
  ),
  'authenticated cannot store an arbitrary Apple credential'
);
select extensions.ok(
  has_function_privilege(
    'service_role',
    'public.store_apple_identity_credential(uuid,text,text,text)',
    'execute'
  ),
  'trusted Edge role can store a verified encrypted Apple credential'
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

-- The grants below exist only inside this rolled-back test transaction. They
-- let assertions inspect private retry state while production service_role
-- remains restricted to the reviewed SECURITY DEFINER operations.
grant usage on schema private to service_role;
grant select, update on table
  private.apple_identity_credentials,
  private.apple_account_event_inbox,
  private.apple_commerce_reconciliation_state
to service_role;

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '13000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'apple-user@test.invalid', '', now(),
    '{"provider":"apple","providers":["apple"]}', '{}', now(), now()
  ),
  (
    '13000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'apple-admin@test.invalid', '', now(),
    '{"provider":"apple","providers":["apple"]}', '{}', now(), now()
  );

insert into auth.identities(
  provider_id, user_id, identity_data, provider,
  last_sign_in_at, created_at, updated_at
)
values
  (
    'apple-subject-phase13',
    '13000000-0000-0000-0000-000000000001',
    '{"sub":"apple-subject-phase13","email":"apple-user@test.invalid"}',
    'apple', now(), now(), now()
  ),
  (
    'apple-admin-subject-phase13',
    '13000000-0000-0000-0000-000000000002',
    '{"sub":"apple-admin-subject-phase13","email":"apple-admin@test.invalid"}',
    'apple', now(), now(), now()
  );

update public.profiles
set display_name = 'Participant Apple',
    phone_number = '081200000001',
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = '13000000-0000-0000-0000-000000000001';

update public.profiles
set role = 'admin',
    display_name = 'Admin Apple',
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = '13000000-0000-0000-0000-000000000002';

set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';

select extensions.throws_ok(
  $$ select public.store_apple_identity_credential(
    '13000000-0000-0000-0000-000000000001',
    repeat('0', 64),
    'ciphertext-that-is-long-enough',
    'nonce-long-enough'
  ) $$,
  'P0001',
  'apple_identity_mismatch',
  'credential storage rejects a mismatched Apple subject'
);

select extensions.lives_ok(
  $$ select public.store_apple_identity_credential(
    '13000000-0000-0000-0000-000000000001',
    encode(extensions.digest('apple-subject-phase13', 'sha256'), 'hex'),
    'ciphertext-that-is-long-enough',
    'nonce-long-enough'
  ) $$,
  'verified encrypted credential can be stored'
);

reset role;

select extensions.is(
  (
    select status from private.apple_identity_credentials
    where account_id = '13000000-0000-0000-0000-000000000001'
  ),
  'active',
  'stored credential starts active'
);
select extensions.is(
  (
    select encrypted_refresh_token
    from private.apple_identity_credentials
    where account_id = '13000000-0000-0000-0000-000000000001'
  ),
  'ciphertext-that-is-long-enough',
  'database stores ciphertext rather than a refresh token field'
);

set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';
select extensions.ok(
  public.claim_apple_identity_credential_for_account(
    '13000000-0000-0000-0000-000000000001'
  ) ->> 'id' is not null,
  'account deletion can claim its Apple credential once'
);
reset role;
select extensions.is(
  (
    select status from private.apple_identity_credentials
    where account_id = '13000000-0000-0000-0000-000000000001'
  ),
  'processing',
  'claim moves the credential to processing'
);

set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';
select public.complete_apple_identity_revocation(
  (
    select id from private.apple_identity_credentials
    where account_id = '13000000-0000-0000-0000-000000000001'
  ),
  false,
  'network_failure'
);
reset role;
select extensions.is(
  (
    select account_id from private.apple_identity_credentials
    where apple_subject_hash = encode(
      extensions.digest('apple-subject-phase13', 'sha256'), 'hex'
    )
  ),
  null::uuid,
  'failed revocation detaches the credential before account deletion'
);
select extensions.is(
  (
    select status from private.apple_identity_credentials
    where apple_subject_hash = encode(
      extensions.digest('apple-subject-phase13', 'sha256'), 'hex'
    )
  ),
  'retry',
  'failed revocation remains durable for retry'
);

update private.apple_identity_credentials
set next_retry_at = statement_timestamp() - interval '1 second';
set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';
select extensions.is(
  (
    select count(*)::bigint
    from public.claim_pending_apple_identity_revocations(10)
  ),
  1::bigint,
  'reconciliation claims a due detached credential'
);
reset role;
set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';
select public.complete_apple_identity_revocation(
  (select id from private.apple_identity_credentials limit 1),
  true,
  null
);
reset role;
select extensions.is(
  (select count(*)::bigint from private.apple_identity_credentials),
  0::bigint,
  'successful revocation removes encrypted token material'
);

set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';
select extensions.ok(
  (
    public.record_apple_account_event(
      'phase13-event-jti-0001',
      'email-disabled',
      encode(extensions.digest('apple-subject-phase13', 'sha256'), 'hex'),
      statement_timestamp()
    ) ->> 'inserted'
  )::boolean,
  'first verified account event is recorded'
);
select extensions.ok(
  not (
    public.record_apple_account_event(
      'phase13-event-jti-0001',
      'email-disabled',
      encode(extensions.digest('apple-subject-phase13', 'sha256'), 'hex'),
      statement_timestamp()
    ) ->> 'inserted'
  )::boolean,
  'duplicate Apple event is idempotent'
);
reset role;
select extensions.is(
  (select count(*)::bigint from private.apple_account_event_inbox),
  1::bigint,
  'duplicate event does not duplicate inbox state'
);
set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';
select extensions.is(
  (
    select count(*)::bigint
    from public.claim_pending_apple_account_events(10)
  ),
  1::bigint,
  'reconciliation can claim a durable pending event'
);
select public.complete_apple_account_event(
  'phase13-event-jti-0001', true, null, false
);
reset role;
set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';
select extensions.is(
  (
    select status from private.apple_account_event_inbox
    where event_jti = 'phase13-event-jti-0001'
  ),
  'processed',
  'successful event processing is finalized'
);

select extensions.is(
  public.prepare_external_apple_account_deletion(
    '13000000-0000-0000-0000-000000000001'
  ),
  '[]'::jsonb,
  'external deletion preflight returns the private-media manifest'
);
select extensions.lives_ok(
  $$ select public.finalize_external_apple_account_deletion(
    '13000000-0000-0000-0000-000000000001'
  ) $$,
  'external Apple event can finalize eligible application data'
);
reset role;
select extensions.is(
  (
    select display_name from public.profiles
    where user_id = '13000000-0000-0000-0000-000000000001'
  ),
  'Akun dihapus',
  'external deletion anonymizes the profile before Auth removal'
);
select extensions.is(
  (
    select phone_number from public.profiles
    where user_id = '13000000-0000-0000-0000-000000000001'
  ),
  null::text,
  'external deletion removes participant contact data'
);
set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';
select extensions.throws_ok(
  $$ select public.prepare_external_apple_account_deletion(
    '13000000-0000-0000-0000-000000000002'
  ) $$,
  'P0001',
  'admin_account_deletion_not_allowed',
  'external event cannot silently delete an Admin account'
);

reset role;
select extensions.ok(
  not has_table_privilege(
    'authenticated',
    'private.apple_commerce_reconciliation_state',
    'select'
  ),
  'authenticated cannot inspect commerce reconciliation state'
);
select extensions.ok(
  not has_function_privilege(
    'authenticated',
    'public.claim_apple_commerce_reconciliation_batch(text,integer)',
    'execute'
  ),
  'authenticated cannot claim Apple Server API work'
);
select extensions.ok(
  has_function_privilege(
    'service_role',
    'public.claim_apple_commerce_reconciliation_batch(text,integer)',
    'execute'
  ),
  'trusted worker can claim Apple Server API work'
);

insert into public.commerce_transactions(
  platform, environment, external_transaction_id, program_id, participant_id,
  product_id, status, signed_payload_hash, subject_kind, provider,
  product_type, original_transaction_id, app_account_token, purchased_at,
  signed_at, last_event_at
) values (
  'app_store', 'sandbox', '1300000000000001', null,
  '13000000-0000-0000-0000-000000000001',
  'msc.coach.access.entry.3m', 'verified', repeat('1', 64),
  'coach_access', 'app_store', 'non_renewing_subscription',
  '1300000000000001', '13000000-0000-4000-8000-000000000001',
  statement_timestamp(), statement_timestamp(), statement_timestamp()
);

set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';
select extensions.is(
  (
    select count(*)::bigint
    from public.claim_apple_commerce_reconciliation_batch('sandbox', 10)
  ),
  1::bigint,
  'worker claims a due known sandbox transaction'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.claim_apple_commerce_reconciliation_batch('sandbox', 10)
  ),
  0::bigint,
  'active lease prevents a duplicate commerce claim'
);
reset role;
select extensions.is(
  (
    select status from private.apple_commerce_reconciliation_state limit 1
  ),
  'processing',
  'claimed commerce state records an active processing lease'
);

set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';
select public.complete_apple_commerce_reconciliation(
  '1300000000000001', 'sandbox', false, 'apple_server_api_unavailable'
);
reset role;
select extensions.is(
  (
    select status from private.apple_commerce_reconciliation_state limit 1
  ),
  'retry',
  'failed Server API work remains durable for retry'
);
select extensions.ok(
  (
    select next_attempt_at > statement_timestamp()
    from private.apple_commerce_reconciliation_state limit 1
  ),
  'failed Server API work receives backoff'
);

update private.apple_commerce_reconciliation_state
set next_attempt_at = statement_timestamp() - interval '1 second';
set local role service_role;
set local "request.jwt.claims" = '{"role":"service_role"}';
select extensions.is(
  (
    select count(*)::bigint
    from public.claim_apple_commerce_reconciliation_batch('sandbox', 10)
  ),
  1::bigint,
  'due retry can be reclaimed after its backoff'
);
select public.complete_apple_commerce_reconciliation(
  '1300000000000001', 'sandbox', true, null
);
reset role;
select extensions.is(
  (
    select retry_count from private.apple_commerce_reconciliation_state limit 1
  ),
  0,
  'successful reconciliation resets retry count'
);
select extensions.ok(
  (
    select last_reconciled_at is not null
    from private.apple_commerce_reconciliation_state limit 1
  ),
  'successful reconciliation records its completion time'
);

reset role;

select extensions.finish();

rollback;
