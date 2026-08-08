begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(63);

select extensions.ok(
  not has_table_privilege(
    'authenticated', 'public.commerce_purchase_intents', 'select'
  ),
  'client cannot read private purchase-intent rows directly'
);
select extensions.ok(
  not has_table_privilege(
    'authenticated', 'public.commerce_transactions', 'insert'
  ),
  'client cannot insert a verified transaction'
);
select extensions.ok(
  not has_table_privilege(
    'authenticated', 'public.program_entitlements', 'insert'
  ),
  'client cannot issue a program entitlement'
);
select extensions.ok(
  not has_table_privilege(
    'authenticated', 'public.apple_notification_inbox', 'select'
  ),
  'client cannot inspect Apple notification data'
);
select extensions.ok(
  not has_function_privilege(
    'authenticated',
    'public.create_program_purchase_intent(uuid,uuid,text,text)',
    'execute'
  ),
  'client cannot bypass the authenticated program preflight Edge boundary'
);
select extensions.ok(
  has_function_privilege(
    'service_role',
    'public.fulfill_apple_purchase(uuid,uuid,text,text,text,uuid,text,text,timestamptz,timestamptz,timestamptz,text,bigint)',
    'execute'
  ),
  'trusted Edge role can run atomic fulfillment'
);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('12000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'phase12-admin@test.invalid', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('12000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'phase12-coach@test.invalid', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('12000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated',
   'phase12-participant-one@test.invalid', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('12000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated',
   'phase12-participant-two@test.invalid', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('12000000-0000-0000-0000-000000000021', 'authenticated', 'authenticated',
   'phase12-applicant@test.invalid', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('12000000-0000-0000-0000-000000000022', 'authenticated', 'authenticated',
   'phase12-rejected@test.invalid', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now());

update public.profiles
set role = 'admin', display_name = 'Admin Commerce',
    onboarding_status = 'active', provisional_expires_at = null,
    finalized_at = now()
where user_id = '12000000-0000-0000-0000-000000000001';

update public.profiles
set role = 'coach', display_name = 'Coach Commerce',
    phone_number = '+6281200000002', member_level = 'sc',
    coach_is_approved = true,
    coach_qr_identifier = 'coach_phase12_active_fixture',
    onboarding_status = 'active', provisional_expires_at = null,
    finalized_at = now()
where user_id = '12000000-0000-0000-0000-000000000002';

update public.profiles
set display_name = case user_id
      when '12000000-0000-0000-0000-000000000011' then 'Peserta Satu'
      when '12000000-0000-0000-0000-000000000012' then 'Peserta Dua'
      when '12000000-0000-0000-0000-000000000021' then 'Calon Coach'
      else 'Calon Ditolak' end,
    phone_number = '+6281299999999', member_level = 'sc',
    current_coach_id = case
      when user_id = '12000000-0000-0000-0000-000000000012'
      then '12000000-0000-0000-0000-000000000002'::uuid
      else null
    end,
    onboarding_status = 'active', provisional_expires_at = null,
    finalized_at = now()
where user_id in (
  '12000000-0000-0000-0000-000000000011',
  '12000000-0000-0000-0000-000000000012',
  '12000000-0000-0000-0000-000000000021',
  '12000000-0000-0000-0000-000000000022'
);

set local role service_role;
select extensions.lives_ok(
  $$ select public.record_apple_notification(
    '12900000-0000-0000-0000-000000000002', 'xcode', 'TEST', null,
    null, null, now(), repeat('0', 64), '{"test":true}'::jsonb
  ) $$,
  'Xcode notification metadata uses the same durable local inbox contract'
);
select extensions.lives_ok(
  $$ select public.consume_commerce_rate_limit(
    '12000000-0000-0000-0000-000000000011',
    'program_preflight'
  ) $$,
  'commerce rate limit records a timestamp without keyword collisions'
);
reset role;
select extensions.is(
  (select request_count
   from private.commerce_request_limits
   where account_id = '12000000-0000-0000-0000-000000000011'
     and operation = 'program_preflight'),
  1,
  'first rate-limit call stores one request in the current window'
);

insert into public.coach_applications(
  id, applicant_user_id, participant_profile_id, display_name_snapshot,
  phone_number_snapshot, member_level_snapshot, has_completed_hom_sts,
  has_completed_ict, terms_version, status, draft_idempotency_key,
  submitted_at, decided_at, decided_by
)
values (
  '12100000-0000-0000-0000-000000000002',
  '12000000-0000-0000-0000-000000000002',
  '12000000-0000-0000-0000-000000000002',
  'Coach Commerce', '+6281200000002', 'sc', true, true, 'test-v1',
  'active', 'phase12-existing-coach', now(), now(),
  '12000000-0000-0000-0000-000000000001'
);
insert into public.coach_payment_records(
  id, application_id, state, price_band, amount_minor_units,
  provider_reference, verified_at
)
values (
  '12200000-0000-0000-0000-000000000002',
  '12100000-0000-0000-0000-000000000002',
  'verified', 'entry', 100000, 'phase12-existing-payment', now()
);
insert into public.coach_access_entitlements(
  id, application_id, payment_record_id, coach_user_id, status,
  starts_at, ends_at
)
values (
  '12300000-0000-0000-0000-000000000002',
  '12100000-0000-0000-0000-000000000002',
  '12200000-0000-0000-0000-000000000002',
  '12000000-0000-0000-0000-000000000002',
  'active', now() - interval '1 day', now() + interval '1 year'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"12000000-0000-0000-0000-000000000011","role":"authenticated"}';
select extensions.lives_ok(
  $$ select public.resolve_coach_qr_for_enrollment(
    'coach_phase12_active_fixture'
  ) $$,
  'paid-program QR scan records a temporary Coach selection'
);
reset role;

select extensions.is(
  (select current_coach_id from public.profiles
   where user_id = '12000000-0000-0000-0000-000000000011'),
  null::uuid,
  'QR preview does not bind the account before verified fulfillment'
);
select extensions.is(
  (select coach_id from private.pending_program_coach_selections
   where account_id = '12000000-0000-0000-0000-000000000011'),
  '12000000-0000-0000-0000-000000000002'::uuid,
  'server retains the pending Coach without exposing the raw QR'
);

insert into public.programs(
  id, title, status, pace, duration_mode, starts_on, ends_on, timezone,
  participant_limit, past_step_policy, future_step_policy,
  wellness_disclaimer, points_per_activity, points_per_weight_kg,
  quiz_passing_percentage, pricing_mode, desired_price,
  created_by, published_at, registration_closes_at
)
values (
  '12400000-0000-0000-0000-000000000001',
  'Program Commerce Phase 12', 'active', 'scheduled', 'specific_dates',
  current_date, current_date + 7, 'Asia/Makassar', 1,
  'available', 'locked', 'Program kebugaran non-diagnostik.',
  10, 100, 70, 'paid', 250000,
  '12000000-0000-0000-0000-000000000001', now(), now() + interval '1 day'
);
insert into public.program_store_products(
  id, program_id, platform, environment, product_id, product_type,
  provisioning_status, actual_price, currency_code
)
values (
  '12500000-0000-0000-0000-000000000001',
  '12400000-0000-0000-0000-000000000001',
  'app_store', 'xcode', 'local.msc.program.phase12.cohort',
  'non_consumable', 'ready', 250000, 'IDR'
);

set local role service_role;
select extensions.lives_ok(
  $$ select public.create_program_purchase_intent(
    '12400000-0000-0000-0000-000000000001',
    '12000000-0000-0000-0000-000000000011',
    'xcode', 'phase12-program-intent-0001'
  ) $$,
  'trusted preflight creates a paid-program reservation'
);
reset role;

select extensions.is(
  (select subject_kind from public.commerce_purchase_intents
   where account_id = '12000000-0000-0000-0000-000000000011'),
  'program',
  'program preflight stores a server-owned subject'
);
select extensions.is(
  (select product_id from public.commerce_purchase_intents
   where account_id = '12000000-0000-0000-0000-000000000011'),
  'local.msc.program.phase12.cohort',
  'product mapping comes from the database'
);
select extensions.ok(
  (select app_account_token is not null
   from public.commerce_purchase_intents
   where account_id = '12000000-0000-0000-0000-000000000011'),
  'preflight creates an opaque stable appAccountToken'
);
select extensions.ok(
  (select expires_at between created_at + interval '29 minutes'
      and created_at + interval '31 minutes'
   from public.commerce_purchase_intents
   where account_id = '12000000-0000-0000-0000-000000000011'),
  'capacity reservation uses the approved thirty-minute TTL'
);

set local role service_role;
select extensions.lives_ok(
  $$ select public.create_program_purchase_intent(
    '12400000-0000-0000-0000-000000000001',
    '12000000-0000-0000-0000-000000000011',
    'xcode', 'phase12-program-intent-0001'
  ) $$,
  'same preflight idempotency key is stable'
);
select extensions.lives_ok(
  $$ select public.create_program_purchase_intent(
    '12400000-0000-0000-0000-000000000001',
    '12000000-0000-0000-0000-000000000011',
    'xcode', 'phase12-program-intent-0002'
  ) $$,
  'a duplicate tap reuses the active reservation'
);
select extensions.is(
  (select count(*)::bigint from public.commerce_purchase_intents
   where account_id = '12000000-0000-0000-0000-000000000011'),
  1::bigint,
  'duplicate preflight does not create another reservation'
);
select extensions.throws_like(
  $$ select public.create_program_purchase_intent(
    '12400000-0000-0000-0000-000000000001',
    '12000000-0000-0000-0000-000000000012',
    'xcode', 'phase12-program-intent-full'
  ) $$,
  'program_full',
  'another account cannot over-reserve the final seat'
);
select extensions.lives_ok(
  $$ select public.mark_purchase_intent_pending(
    (select id from public.commerce_purchase_intents
     where account_id = '12000000-0000-0000-0000-000000000011'),
    '12000000-0000-0000-0000-000000000011'
  ) $$,
  'purchase sheet transition extends the reservation safely'
);
reset role;

select extensions.is(
  (select status from public.commerce_purchase_intents
   where account_id = '12000000-0000-0000-0000-000000000011'),
  'purchase_pending',
  'intent records the pending StoreKit state'
);

set local role service_role;
select extensions.lives_ok(
  $$ select public.fulfill_apple_purchase(
    (select id from public.commerce_purchase_intents
     where account_id = '12000000-0000-0000-0000-000000000011'),
    '12000000-0000-0000-0000-000000000011',
    'xcode-program-transaction-0001', 'xcode-program-original-0001',
    'local.msc.program.phase12.cohort',
    (select app_account_token from public.commerce_purchase_intents
     where account_id = '12000000-0000-0000-0000-000000000011'),
    'xcode', repeat('a', 64), now(), now(), null, 'IDR', 250000000
  ) $$,
  'verified Apple purchase is fulfilled atomically'
);
reset role;

select extensions.is(
  (select count(*)::bigint from public.commerce_transactions
   where external_transaction_id = 'xcode-program-transaction-0001'),
  1::bigint,
  'one verified transaction is retained'
);
select extensions.is(
  (select count(*)::bigint from public.program_entitlements
   where program_id = '12400000-0000-0000-0000-000000000001'
     and participant_id = '12000000-0000-0000-0000-000000000011'),
  1::bigint,
  'fulfillment creates exactly one program entitlement'
);
select extensions.is(
  (select count(*)::bigint from public.program_enrollments
   where program_id = '12400000-0000-0000-0000-000000000001'
     and participant_id = '12000000-0000-0000-0000-000000000011'),
  1::bigint,
  'fulfillment creates exactly one enrollment'
);
select extensions.is(
  (select count(*)::bigint from public.program_scores),
  1::bigint,
  'fulfillment creates the score projection once'
);
select extensions.is(
  (select coach_id from public.program_enrollments
   where program_id = '12400000-0000-0000-0000-000000000001'),
  '12000000-0000-0000-0000-000000000002'::uuid,
  'enrollment Coach comes from the immutable reservation snapshot'
);
select extensions.is(
  (select current_coach_id from public.profiles
   where user_id = '12000000-0000-0000-0000-000000000011'),
  '12000000-0000-0000-0000-000000000002'::uuid,
  'verified fulfillment binds the selected Coach to the account'
);
select extensions.is(
  (select count(*)::bigint
   from private.pending_program_coach_selections
   where account_id = '12000000-0000-0000-0000-000000000011'),
  0::bigint,
  'verified fulfillment clears the temporary Coach selection'
);

set local role service_role;
select extensions.lives_ok(
  $$ select public.fulfill_apple_purchase(
    (select id from public.commerce_purchase_intents
     where account_id = '12000000-0000-0000-0000-000000000011'),
    '12000000-0000-0000-0000-000000000011',
    'xcode-program-transaction-0001', 'xcode-program-original-0001',
    'local.msc.program.phase12.cohort',
    (select app_account_token from public.commerce_purchase_intents
     where account_id = '12000000-0000-0000-0000-000000000011'),
    'xcode', repeat('a', 64), now(), now(), null, 'IDR', 250000000
  ) $$,
  'duplicate verifier callback returns the durable result'
);
select extensions.throws_like(
  $$ select public.fulfill_apple_purchase(
    (select id from public.commerce_purchase_intents
     where account_id = '12000000-0000-0000-0000-000000000011'),
    '12000000-0000-0000-0000-000000000012',
    'xcode-program-transaction-0001', 'xcode-program-original-0001',
    'local.msc.program.phase12.cohort',
    (select app_account_token from public.commerce_purchase_intents
     where account_id = '12000000-0000-0000-0000-000000000011'),
    'xcode', repeat('a', 64), now(), now(), null, 'IDR', 250000
  ) $$,
  'transaction_mismatch',
  'verified transaction cannot be replayed for another account'
);
select extensions.lives_ok(
  $$ select public.reconcile_apple_commerce_event(
    'xcode-program-transaction-0001', 'xcode',
    'xcode-program-refund-0001', 'refund', now() + interval '1 minute',
    repeat('b', 64), '{}'::jsonb
  ) $$,
  'authoritative Apple refund is reconciled'
);
reset role;

select extensions.is(
  (select status from public.program_entitlements
   where program_id = '12400000-0000-0000-0000-000000000001'),
  'refunded',
  'refund revokes the program entitlement projection'
);
select extensions.is(
  (select status from public.program_enrollments
   where program_id = '12400000-0000-0000-0000-000000000001'),
  'refunded',
  'refund removes protected program access'
);

set local role service_role;
select extensions.lives_ok(
  $$ select public.reconcile_apple_commerce_event(
    'xcode-program-transaction-0001', 'xcode',
    'xcode-program-older-verified', 'verified', now() - interval '1 day',
    repeat('c', 64), '{}'::jsonb
  ) $$,
  'older out-of-order event is accepted as a no-op'
);
reset role;
select extensions.is(
  (select status from public.commerce_transactions
   where external_transaction_id = 'xcode-program-transaction-0001'),
  'refunded',
  'an older event cannot resurrect a refunded purchase'
);

select extensions.is(private.coach_price_band('sc'), 'entry',
  'SC maps to the entry Coach price band');
select extensions.is(private.coach_price_band('world_team'), 'growth',
  'World Team maps to the growth Coach price band');
select extensions.is(private.coach_price_band('presidents_team'), 'leadership',
  'Presidents Team maps to the leadership Coach price band');

insert into public.coach_applications(
  id, applicant_user_id, participant_profile_id, display_name_snapshot,
  phone_number_snapshot, member_level_snapshot, has_completed_hom_sts,
  has_completed_ict, terms_version, status, draft_idempotency_key,
  submitted_at
)
values (
  '12100000-0000-0000-0000-000000000021',
  '12000000-0000-0000-0000-000000000021',
  '12000000-0000-0000-0000-000000000021',
  'Calon Coach', '+6281299999999', 'sc', true, true, 'test-v1',
  'submitted', 'phase12-applicant-submitted', now()
);

set local role service_role;
select extensions.throws_like(
  $$ select public.create_coach_purchase_intent(
    '12000000-0000-0000-0000-000000000021',
    'xcode', 'phase12-coach-before-approval'
  ) $$,
  'coach_approval_required',
  'Coach payment cannot begin before protected Admin acceptance'
);
reset role;

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"12000000-0000-0000-0000-000000000001","role":"authenticated"}';
select extensions.lives_ok(
  $$ select public.decide_coach_application(
    '12100000-0000-0000-0000-000000000021',
    'approved', null, 'phase12-admin-accept-applicant'
  ) $$,
  'Admin accepts the applicant before payment'
);
reset role;

select extensions.is(
  (select status from public.coach_applications
   where id = '12100000-0000-0000-0000-000000000021'),
  'accepted_pending_payment',
  'accepted application waits for payment without Coach authority'
);

set local role service_role;
select extensions.lives_ok(
  $$ select public.create_coach_purchase_intent(
    '12000000-0000-0000-0000-000000000021',
    'xcode', 'phase12-coach-intent-0001'
  ) $$,
  'accepted applicant receives a server-mapped Coach product'
);
select extensions.lives_ok(
  $$ select public.fulfill_apple_purchase(
    (select id from public.commerce_purchase_intents
     where account_id = '12000000-0000-0000-0000-000000000021'
       and subject_kind = 'coach_access'),
    '12000000-0000-0000-0000-000000000021',
    'xcode-coach-transaction-0001', 'xcode-coach-original-0001',
    'local.msc.coach.access.entry.3months',
    (select app_account_token from public.commerce_purchase_intents
     where account_id = '12000000-0000-0000-0000-000000000021'
       and subject_kind = 'coach_access'),
    'xcode', repeat('d', 64), now(), now(), null, 'IDR', 100000000
  ) $$,
  'verified Coach transaction activates a three-month period'
);
reset role;

select extensions.is(
  (select role from public.profiles
   where user_id = '12000000-0000-0000-0000-000000000021'),
  'coach',
  'verified purchase after acceptance activates protected Coach role'
);
select extensions.ok(
  (select coach_is_approved and coach_qr_identifier is not null
   from public.profiles
   where user_id = '12000000-0000-0000-0000-000000000021'),
  'activation enables the opaque Coach QR capability'
);
select extensions.is(
  (select count(*)::bigint from public.coach_payment_records
   where application_id = '12100000-0000-0000-0000-000000000021'),
  1::bigint,
  'first Coach purchase creates one immutable payment period'
);
select extensions.ok(
  (select ends_at between starts_at + interval '2 months 27 days'
      and starts_at + interval '3 months 1 day'
   from public.coach_access_entitlements
   where application_id = '12100000-0000-0000-0000-000000000021'),
  'Coach entitlement spans three calendar months'
);

set local role service_role;
select extensions.lives_ok(
  $$ select public.create_coach_purchase_intent(
    '12000000-0000-0000-0000-000000000021',
    'xcode', 'phase12-coach-renewal-0002'
  ) $$,
  'active accepted Coach can manually renew without another review'
);
select extensions.lives_ok(
  $$ select public.fulfill_apple_purchase(
    (select id from public.commerce_purchase_intents
     where account_id = '12000000-0000-0000-0000-000000000021'
       and status <> 'fulfilled'),
    '12000000-0000-0000-0000-000000000021',
    'xcode-coach-transaction-0002', 'xcode-coach-original-0002',
    'local.msc.coach.access.entry.3months',
    (select app_account_token from public.commerce_purchase_intents
     where account_id = '12000000-0000-0000-0000-000000000021'
     limit 1),
    'xcode', repeat('e', 64), now(), now(), null, 'IDR', 100000000
  ) $$,
  'renewal creates a second verified transaction'
);
reset role;

select extensions.is(
  (select count(*)::bigint from public.coach_access_entitlements
   where application_id = '12100000-0000-0000-0000-000000000021'),
  2::bigint,
  'renewal appends entitlement history instead of overwriting it'
);
select extensions.is(
  (select starts_at from public.coach_access_entitlements
   where application_id = '12100000-0000-0000-0000-000000000021'
     and period_sequence = 2),
  (select ends_at from public.coach_access_entitlements
   where application_id = '12100000-0000-0000-0000-000000000021'
     and period_sequence = 1),
  'early renewal begins after the prior paid period'
);

set local role service_role;
select extensions.lives_ok(
  $$ select public.reconcile_apple_commerce_event(
    'xcode-coach-transaction-0001', 'xcode',
    'xcode-coach-refund-0001', 'refund', now() + interval '2 minutes',
    repeat('f', 64), '{}'::jsonb
  ) $$,
  'refund of the currently active Coach period is reconciled'
);
reset role;

select extensions.is(
  (select role from public.profiles
   where user_id = '12000000-0000-0000-0000-000000000021'),
  'participant',
  'refund disables Coach while the renewal period has not started'
);
select extensions.is(
  (select status from public.coach_applications
   where id = '12100000-0000-0000-0000-000000000021'),
  'expired',
  'application acceptance is retained as renewable but access is inactive'
);

set local role service_role;
select extensions.lives_ok(
  $$ select public.record_apple_notification(
    '12900000-0000-0000-0000-000000000001', 'sandbox', 'TEST', null,
    null, null, now(), repeat('1', 64), '{"test":true}'::jsonb
  ) $$,
  'verified notification metadata is durably recorded before response'
);
select extensions.lives_ok(
  $$ select public.record_apple_notification(
    '12900000-0000-0000-0000-000000000001', 'sandbox', 'TEST', null,
    null, null, now(), repeat('1', 64), '{"test":true}'::jsonb
  ) $$,
  'duplicate notificationUUID with the same hash is idempotent'
);
select extensions.is(
  (select count(*)::bigint from public.apple_notification_inbox
   where notification_uuid = '12900000-0000-0000-0000-000000000001'),
  1::bigint,
  'duplicate notification does not create another inbox row'
);
select extensions.throws_like(
  $$ select public.record_apple_notification(
    '12900000-0000-0000-0000-000000000001', 'sandbox', 'TEST', null,
    null, null, now(), repeat('2', 64), '{"test":true}'::jsonb
  ) $$,
  'transaction_replayed',
  'same notificationUUID with a different payload hash is rejected'
);
select extensions.lives_ok(
  $$ select public.complete_apple_notification(
    '12900000-0000-0000-0000-000000000001', true, null
  ) $$,
  'notification processing state can be completed durably'
);
reset role;

select extensions.is(
  (select status from public.apple_notification_inbox
   where notification_uuid = '12900000-0000-0000-0000-000000000001'),
  'processed',
  'processed notification is stable in the durable inbox'
);

select * from extensions.finish();
rollback;
