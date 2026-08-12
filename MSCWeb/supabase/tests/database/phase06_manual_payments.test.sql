begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(37);

select extensions.has_table('public', 'payment_destinations', 'destination table exists');
select extensions.has_table('public', 'payment_orders', 'order table exists');
select extensions.has_table('public', 'payment_evidence_attempts', 'evidence table exists');
select extensions.has_table('public', 'payment_ledger', 'ledger table exists');
select extensions.has_table('public', 'payment_events', 'event table exists');
select extensions.ok(
  exists (select 1 from storage.buckets where id = 'payment-evidence' and not public),
  'payment evidence bucket is private'
);
select extensions.ok(
  exists (select 1 from storage.buckets where id = 'payment-destination-assets' and not public),
  'versioned QRIS assets use a separate private bucket'
);
select extensions.ok(
  not has_function_privilege('anon', 'public.create_program_payment_order(uuid,text,text)', 'execute'),
  'anon cannot create payment order'
);
select extensions.ok(
  has_function_privilege('authenticated', 'public.create_program_payment_order(uuid,text,text)', 'execute'),
  'authenticated actor can reach protected order boundary'
);
select extensions.ok(
  not has_function_privilege(
    'authenticated', 'public.submit_payment_evidence(uuid,text,integer,integer,integer,uuid)',
    'execute'
  ),
  'authenticated actor cannot submit authoritative evidence metadata directly'
);
select extensions.ok(
  has_function_privilege(
    'service_role', 'public.submit_payment_evidence(uuid,text,integer,integer,integer,uuid)',
    'execute'
  ),
  'service role can submit server-validated evidence metadata'
);
select extensions.ok(
  not has_function_privilege('authenticated', 'public.expire_payment_orders()', 'execute'),
  'authenticated actor cannot run recurring order expiry'
);
select extensions.ok(
  not has_function_privilege('authenticated', 'public.cleanup_expired_payment_evidence()', 'execute'),
  'authenticated actor cannot run evidence retention cleanup'
);
select extensions.ok(
  has_function_privilege('service_role', 'public.expire_payment_orders()', 'execute'),
  'service role can run recurring order expiry'
);
select extensions.ok(
  has_function_privilege('service_role', 'public.cleanup_expired_payment_evidence()', 'execute'),
  'service role can run evidence retention cleanup'
);
select extensions.ok(
  not has_table_privilege('authenticated', 'public.payment_orders', 'insert'),
  'client has no direct order insert privilege'
);
select extensions.ok(
  not has_table_privilege('authenticated', 'public.payment_ledger', 'insert'),
  'client has no direct ledger insert privilege'
);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('b6000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'p6-admin@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('b6000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'p6-coach@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('b6000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 'p6-one@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('b6000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated', 'p6-two@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());

insert into public.profiles(
  user_id, role, display_name, coach_qr_identifier, coach_is_approved,
  onboarding_status, finalized_at
) values
  ('b6000000-0000-0000-0000-000000000001', 'admin', 'Admin Phase 06', null, false, 'active', now()),
  ('b6000000-0000-0000-0000-000000000002', 'coach', 'Coach Phase 06', 'phase06-coach-qr-valid', true, 'active', now()),
  ('b6000000-0000-0000-0000-000000000011', 'participant', 'Peserta Phase 06 Satu', null, false, 'active', now()),
  ('b6000000-0000-0000-0000-000000000012', 'participant', 'Peserta Phase 06 Dua', null, false, 'active', now())
on conflict (user_id) do update set
  role = excluded.role,
  display_name = excluded.display_name,
  coach_qr_identifier = excluded.coach_qr_identifier,
  coach_is_approved = excluded.coach_is_approved,
  onboarding_status = excluded.onboarding_status,
  finalized_at = excluded.finalized_at,
  provisional_expires_at = null,
  updated_at = now();

insert into public.coach_applications(
  id, applicant_user_id, participant_profile_id, display_name_snapshot,
  phone_number_snapshot, member_level_snapshot, has_completed_hom_sts,
  has_completed_ict, terms_version, status, draft_idempotency_key,
  submitted_at, decided_at, decided_by
) values (
  'b6100000-0000-0000-0000-000000000002',
  'b6000000-0000-0000-0000-000000000002',
  'b6000000-0000-0000-0000-000000000002',
  'Coach Phase 06', '+628600000002', 'sc', true, true, 'p6-v1',
  'active', 'phase06-coach-draft', now(), now(),
  'b6000000-0000-0000-0000-000000000001'
);
insert into public.coach_payment_records(
  id, application_id, state, price_band, amount_minor_units,
  provider_reference, verified_at
) values (
  'b6200000-0000-0000-0000-000000000002',
  'b6100000-0000-0000-0000-000000000002', 'verified', 'entry', 100000,
  'phase06-coach-access', now()
);
insert into public.coach_access_entitlements(
  id, application_id, payment_record_id, coach_user_id, status, starts_at, ends_at
) values (
  'b6300000-0000-0000-0000-000000000002',
  'b6100000-0000-0000-0000-000000000002',
  'b6200000-0000-0000-0000-000000000002',
  'b6000000-0000-0000-0000-000000000002', 'active', now() - interval '1 day', now() + interval '30 days'
);
insert into public.programs(
  id, title, summary, status, pace, duration_mode, starts_on, ends_on,
  timezone, participant_limit, past_step_policy, future_step_policy,
  wellness_disclaimer, points_per_activity, points_per_weight_kg,
  quiz_passing_percentage, pricing_mode, desired_price, published_at, created_by
) values (
  'b6400000-0000-0000-0000-000000000001', 'Program Bayar Phase 06',
  'Fixture transaksi manual.', 'active', 'scheduled', 'fixed_duration',
  current_date, current_date + 7, 'Asia/Makassar', 1, 'available', 'locked',
  'Program kebugaran non-diagnostik.', 10, 100, 70, 'paid', 250000, now(),
  'b6000000-0000-0000-0000-000000000001'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"b6000000-0000-0000-0000-000000000001","role":"authenticated"}';

select extensions.throws_like(
  $$ select public.create_payment_destination(
    'BCA', 'Bank Central Asia', 'MSC Lokal', '1234567890',
    statement_timestamp(), 'destinations/b6000000-0000-0000-0000-000000000001/qris.jpg'
  ) $$,
  'qris_asset_not_found', 'destination cannot reference a missing protected QRIS asset'
);
select extensions.lives_ok(
  $$ select public.create_payment_destination('BCA', 'Bank Central Asia', 'MSC Lokal', '1234567890', statement_timestamp()) $$,
  'Admin can create versioned destination'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.payment_destinations
    where created_by = 'b6000000-0000-0000-0000-000000000001'
  ),
  1::bigint,
  'one fixture destination created without assuming an empty local table'
);

set local "request.jwt.claims" =
  '{"sub":"b6000000-0000-0000-0000-000000000011","role":"authenticated"}';

select extensions.lives_ok(
  $$ select public.create_program_payment_order(
    'b6400000-0000-0000-0000-000000000001', 'phase06-coach-qr-valid', 'phase06-create-order-one'
  ) $$,
  'Participant creates a paid program order'
);
select extensions.is(
  (select status from public.payment_orders where owner_user_id = 'b6000000-0000-0000-0000-000000000011'),
  'awaiting_evidence', 'new order awaits evidence'
);
select extensions.is(
  (select amount_minor from public.payment_orders where owner_user_id = 'b6000000-0000-0000-0000-000000000011'),
  250000::bigint, 'amount is server snapshot'
);
select extensions.ok(
  (select reservation_expires_at between created_at + interval '23 hours 59 minutes'
    and created_at + interval '24 hours 1 minute'
   from public.payment_orders where owner_user_id = 'b6000000-0000-0000-0000-000000000011'),
  'reservation is twenty-four hours'
);
select extensions.is(
  (select count(*)::bigint from public.program_enrollments
    where program_id = 'b6400000-0000-0000-0000-000000000001'
      and status = 'waiting_for_payment'),
  1::bigint, 'order atomically reserves one seat'
);
select extensions.lives_ok(
  $$ select public.create_program_payment_order(
    'b6400000-0000-0000-0000-000000000001', 'phase06-coach-qr-valid', 'phase06-create-order-one'
  ) $$,
  'same idempotency key replays safely'
);
select extensions.is(
  (select count(*)::bigint from public.payment_orders
    where owner_user_id = 'b6000000-0000-0000-0000-000000000011'),
  1::bigint, 'idempotency replay creates no duplicate'
);

set local "request.jwt.claims" =
  '{"sub":"b6000000-0000-0000-0000-000000000012","role":"authenticated"}';
select extensions.throws_like(
  $$ select public.create_program_payment_order(
    'b6400000-0000-0000-0000-000000000001', 'phase06-coach-qr-valid', 'phase06-create-order-two'
  ) $$,
  'program_full', 'last-seat reservation fails closed'
);
select extensions.is(
  (select count(*)::bigint from public.payment_orders),
  0::bigint, 'RLS hides another Participant order'
);

set local "request.jwt.claims" =
  '{"sub":"b6000000-0000-0000-0000-000000000011","role":"authenticated"}';
select extensions.lives_ok(
  $$ select public.prepare_payment_evidence_attempt(
    (select id from public.payment_orders limit 1), 'phase06-upload-attempt-one'
  ) $$,
  'owner can prepare an opaque evidence attempt'
);
select extensions.is(
  (select attempt_number from public.payment_evidence_attempts),
  1, 'first evidence attempt is numbered one'
);
select extensions.throws_like(
  $$ update public.payment_events set metadata = '{"changed":true}'::jsonb $$,
  'permission denied for table payment_events', 'client cannot mutate payment events'
);
reset role;
select extensions.is(
  (select confdeltype::text from pg_constraint
    where conname = 'payment_orders_owner_user_id_fkey'),
  'n', 'account deletion anonymizes the order owner reference'
);
select extensions.is(
  (select confdeltype::text from pg_constraint
    where conname = 'payment_orders_pending_enrollment_id_fkey'),
  'n', 'account deletion preserves orders after enrollment removal'
);
select extensions.is(
  (select confdeltype::text from pg_constraint
    where conname = 'payment_orders_coach_application_id_fkey'),
  'n', 'account deletion preserves orders after Coach application removal'
);
select extensions.is(
  (select confdeltype::text from pg_constraint
    where conname = 'payment_orders_coach_user_id_snapshot_fkey'),
  'n', 'deleted Coach identity is removed from retained payment orders'
);
select extensions.throws_like(
  $$ update public.payment_events set metadata = '{"changed":true}'::jsonb $$,
  'payment_events_are_immutable', 'immutable trigger protects events from privileged rewrites'
);

select * from extensions.finish();
rollback;
