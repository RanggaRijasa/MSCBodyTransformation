begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(32);

select extensions.has_column(
  'public', 'profiles', 'member_level',
  'profiles stores the user-editable member level'
);
select extensions.has_column(
  'public', 'profiles', 'onboarding_status',
  'profiles stores server-controlled onboarding status'
);
select extensions.has_column(
  'public', 'profiles', 'provisional_expires_at',
  'profiles stores server-controlled provisional expiry'
);
select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.update_my_profile(text,text,text,text)',
    'execute'
  ),
  'authenticated can call the allowlisted profile operation'
);
select extensions.ok(
  not has_function_privilege(
    'anon',
    'public.update_my_profile(text,text,text,text)',
    'execute'
  ),
  'anon cannot call the profile operation'
);
select extensions.ok(
  not has_function_privilege(
    'authenticated',
    'private.bootstrap_participant_profile()',
    'execute'
  ),
  'authenticated cannot execute the privileged bootstrap helper'
);
select extensions.ok(
  not has_table_privilege('authenticated', 'public.profiles', 'update'),
  'authenticated still cannot update profiles directly'
);
select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.pending_program_enrollment_availability(uuid)',
    'execute'
  ),
  'authenticated can revalidate a pending program intent'
);
select extensions.ok(
  not has_function_privilege(
    'anon',
    'public.pending_program_enrollment_availability(uuid)',
    'execute'
  ),
  'anon cannot inspect pending program availability'
);
select extensions.is(
  (
    select count(*)::bigint
    from pg_trigger
    where tgrelid = 'auth.users'::regclass
      and tgname = 'auth_user_bootstrap_participant_profile'
      and not tgisinternal
  ),
  1::bigint,
  'auth.users has exactly one profile bootstrap trigger'
);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    'b1000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'phase10-user@test.invalid', '', now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"  Nama Aman  ","role":"admin","onboarding_status":"active"}',
    now(), now()
  ),
  (
    'b1000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'phase10-coach@test.invalid', '', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    'b1000000-0000-0000-0000-000000000003',
    'authenticated', 'authenticated', 'phase10-cancel@test.invalid', '', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    'b1000000-0000-0000-0000-000000000004',
    'authenticated', 'authenticated', 'phase10-expired@test.invalid', '', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    'b1000000-0000-0000-0000-000000000005',
    'authenticated', 'authenticated', 'phase10-capacity@test.invalid', '', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now()
  );

update public.profiles
set role = 'coach',
    display_name = 'Coach Phase 10',
    coach_qr_identifier = 'phase10-coach-qr',
    coach_is_approved = true,
    coach_is_public = true,
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = 'b1000000-0000-0000-0000-000000000002';

update public.profiles
set display_name = 'Peserta Kapasitas',
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = 'b1000000-0000-0000-0000-000000000005';

insert into public.coach_applications (
  id, applicant_user_id, participant_profile_id, display_name_snapshot,
  phone_number_snapshot, member_level_snapshot, has_completed_hom_sts,
  has_completed_ict, terms_version, status, draft_idempotency_key,
  submitted_at, decided_at, decided_by
) values (
  'b1100000-0000-0000-0000-000000000002',
  'b1000000-0000-0000-0000-000000000002',
  'b1000000-0000-0000-0000-000000000002',
  'Coach Phase 10', '+6281200000011', 'sc', true, true, 'test-v1',
  'active', 'phase10-coach-active', now(), now(),
  'b1000000-0000-0000-0000-000000000002'
);

insert into public.coach_payment_records (
  id, application_id, state, price_band, amount_minor_units,
  provider_reference, verified_at
) values (
  'b1200000-0000-0000-0000-000000000002',
  'b1100000-0000-0000-0000-000000000002',
  'verified', 'entry', 100000, 'phase10-coach-payment', now()
);

insert into public.coach_access_entitlements (
  id, application_id, payment_record_id, coach_user_id, status,
  starts_at, ends_at
) values (
  'b1300000-0000-0000-0000-000000000002',
  'b1100000-0000-0000-0000-000000000002',
  'b1200000-0000-0000-0000-000000000002',
  'b1000000-0000-0000-0000-000000000002',
  'active', now() - interval '1 day', now() + interval '30 days'
);

insert into public.programs (
  id, title, status, pace, duration_mode, starts_on, ends_on, timezone,
  participant_limit, registration_closes_at, past_step_policy,
  future_step_policy, wellness_disclaimer, points_per_activity,
  points_per_weight_kg, quiz_passing_percentage, pricing_mode,
  desired_price, created_by
)
values
  (
    'b2000000-0000-0000-0000-000000000001',
    'Program Pending Terbuka', 'active', 'scheduled', 'fixed_duration',
    current_date, current_date + 7, 'Asia/Jakarta', null,
    clock_timestamp() + interval '1 day', 'available', 'locked',
    'Program kebugaran non-diagnostik.', 10, 100, 70, 'free', null,
    'b1000000-0000-0000-0000-000000000002'
  ),
  (
    'b2000000-0000-0000-0000-000000000002',
    'Program Pending Ditutup', 'active', 'scheduled', 'fixed_duration',
    current_date, current_date + 7, 'Asia/Jakarta', null,
    clock_timestamp() - interval '1 minute', 'available', 'locked',
    'Program kebugaran non-diagnostik.', 10, 100, 70, 'free', null,
    'b1000000-0000-0000-0000-000000000002'
  ),
  (
    'b2000000-0000-0000-0000-000000000003',
    'Program Pending Penuh', 'active', 'scheduled', 'fixed_duration',
    current_date, current_date + 7, 'Asia/Jakarta', 1,
    clock_timestamp() + interval '1 day', 'available', 'locked',
    'Program kebugaran non-diagnostik.', 10, 100, 70, 'free', null,
    'b1000000-0000-0000-0000-000000000002'
  );

insert into public.program_enrollments (
  program_id, participant_id, coach_id, status
)
values (
  'b2000000-0000-0000-0000-000000000003',
  'b1000000-0000-0000-0000-000000000005',
  'b1000000-0000-0000-0000-000000000002',
  'active'
);

select extensions.is(
  (
    select count(*)::bigint from public.profiles
    where user_id = 'b1000000-0000-0000-0000-000000000001'
  ),
  1::bigint,
  'signup creates exactly one application profile'
);
select extensions.is(
  (
    select role from public.profiles
    where user_id = 'b1000000-0000-0000-0000-000000000001'
  ),
  'participant',
  'client metadata cannot self-promote a signup to Admin'
);
select extensions.is(
  (
    select onboarding_status from public.profiles
    where user_id = 'b1000000-0000-0000-0000-000000000001'
  ),
  'provisional',
  'client metadata cannot bypass provisional onboarding'
);
select extensions.is(
  (
    select display_name from public.profiles
    where user_id = 'b1000000-0000-0000-0000-000000000001'
  ),
  'Nama Aman',
  'safe display metadata is trimmed and retained'
);
select extensions.ok(
  (
    select provisional_expires_at > now()
    from public.profiles
    where user_id = 'b1000000-0000-0000-0000-000000000001'
  ),
  'new signup receives a future server-controlled expiry'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"b1000000-0000-0000-0000-000000000001","role":"authenticated"}';

select lives_ok(
  $$
    select public.save_my_provisional_onboarding_profile(
      'Peserta Phase 10', '+6281200000010', 'sc', 'participant', 1
    )
  $$,
  'provisional user can save only allowlisted onboarding fields'
);
reset role;
select extensions.is(
  (
    select member_level from public.profiles
    where user_id = 'b1000000-0000-0000-0000-000000000001'
  ),
  'sc',
  'member level persists through the allowlisted operation'
);
select extensions.is(
  (
    select role from public.profiles
    where user_id = 'b1000000-0000-0000-0000-000000000001'
  ),
  'participant',
  'profile update cannot change the protected role'
);
set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"b1000000-0000-0000-0000-000000000001","role":"authenticated"}';
select extensions.throws_like(
  $$ select public.finalize_participant_onboarding('wrong-qr') $$,
  'coach_qr_invalid',
  'participant onboarding rejects a wrong Coach QR'
);
select lives_ok(
  $$ select public.finalize_participant_onboarding('phase10-coach-qr') $$,
  'participant onboarding accepts an approved Coach QR'
);
select extensions.is(
  (
    select onboarding_status from public.profiles
    where user_id = (select auth.uid())
  ),
  'active',
  'successful Participant finalization activates the profile'
);
select extensions.is(
  (
    select current_coach_id::text from public.profiles
    where user_id = (select auth.uid())
  ),
  'b1000000-0000-0000-0000-000000000002',
  'successful Participant finalization assigns the scanned Coach'
);
select extensions.is(
  public.pending_program_enrollment_availability(
    'b2000000-0000-0000-0000-000000000001'
  ),
  'available',
  'active account intent remains valid while the program accepts registration'
);
select extensions.is(
  public.pending_program_enrollment_availability(
    'b2000000-0000-0000-0000-000000000002'
  ),
  'registration_closed',
  'active account intent is invalidated from the authoritative server cutoff'
);
select extensions.is(
  public.pending_program_enrollment_availability(
    'b2000000-0000-0000-0000-000000000003'
  ),
  'program_full',
  'active account intent is invalidated when capacity is reached'
);
select extensions.is(
  public.pending_program_enrollment_availability(
    'b2000000-0000-0000-0000-000000000099'
  ),
  'program_unavailable',
  'active account intent is invalidated when the program is unavailable'
);
select extensions.is(
  public.request_my_provisional_cancellation('phase10-active-retained') ->> 'status',
  'retained',
  'an active account is retained by the durable cancellation boundary'
);

set local "request.jwt.claims" =
  '{"sub":"b1000000-0000-0000-0000-000000000003","role":"authenticated"}';
select extensions.is(
  public.request_my_provisional_cancellation('phase10-cancel-user') ->> 'status',
  'queued',
  'a relationship-free provisional identity receives a durable cleanup receipt'
);

reset role;
select extensions.is(
  (
    select onboarding_status from public.profiles
    where user_id = 'b1000000-0000-0000-0000-000000000003'
  ),
  'cleanup_pending',
  'provisional cancellation waits for the server cleanup worker'
);

update public.profiles
set provisional_expires_at = now() - interval '1 minute'
where user_id = 'b1000000-0000-0000-0000-000000000004';

select extensions.is(
  private.cleanup_expired_provisional_identities(),
  1,
  'scheduled cleanup removes one expired relationship-free identity'
);
select extensions.is(
  (
    select onboarding_status from public.profiles
    where user_id = 'b1000000-0000-0000-0000-000000000004'
  ),
  'cleanup_pending',
  'expired provisional cleanup is queued for the server worker'
);
select extensions.is(
  (
    select count(*)::bigint from cron.job
    where jobname = 'phase10-expired-provisional-cleanup'
  ),
  1::bigint,
  'expired provisional identity cleanup is scheduled exactly once'
);

select * from extensions.finish();
rollback;
