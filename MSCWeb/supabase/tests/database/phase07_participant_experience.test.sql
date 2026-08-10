begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(18);

select extensions.has_column('public', 'profiles', 'profile_avatar_path', 'profile avatar path exists');
select extensions.has_table('public', 'participant_coach_change_requests', 'Coach change idempotency table exists');
select extensions.ok(
  has_function_privilege('authenticated', 'public.get_my_participant_profile_context()', 'execute'),
  'authenticated can read narrow profile context'
);
select extensions.ok(
  has_function_privilege('authenticated', 'public.update_my_profile_avatar(text,text)', 'execute'),
  'authenticated can reach avatar operation'
);
select extensions.ok(
  has_function_privilege('authenticated', 'public.change_my_coach_from_qr(text,text)', 'execute'),
  'authenticated can reach QR Coach operation'
);
select extensions.ok(
  not has_table_privilege('authenticated', 'public.participant_coach_change_requests', 'select'),
  'client cannot read Coach change idempotency rows'
);

insert into auth.users(
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('c7000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'p7-admin@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('c7000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'p7-coach-old@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('c7000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'p7-coach-new@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('c7000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'p7-participant@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());

update public.profiles set role = 'admin', display_name = 'Admin Phase 07', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null
where user_id = 'c7000000-0000-0000-0000-000000000001';
update public.profiles set role = 'coach', display_name = 'Coach Lama', coach_qr_identifier = 'phase07-coach-old-valid', coach_is_approved = true, coach_is_public = true, onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null
where user_id = 'c7000000-0000-0000-0000-000000000002';
update public.profiles set role = 'coach', display_name = 'Coach Baru', city = 'Denpasar', coach_qr_identifier = 'phase07-coach-new-valid', coach_is_approved = true, coach_is_public = true, onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null
where user_id = 'c7000000-0000-0000-0000-000000000003';
update public.profiles set role = 'participant', display_name = 'Peserta Phase 07', current_coach_id = 'c7000000-0000-0000-0000-000000000002', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null
where user_id = 'c7000000-0000-0000-0000-000000000004';

insert into public.coach_applications(
  id, applicant_user_id, participant_profile_id, display_name_snapshot,
  phone_number_snapshot, member_level_snapshot, has_completed_hom_sts,
  has_completed_ict, terms_version, status, draft_idempotency_key,
  submitted_at, decided_at, decided_by
) values (
  'c7100000-0000-0000-0000-000000000003',
  'c7000000-0000-0000-0000-000000000003',
  'c7000000-0000-0000-0000-000000000003',
  'Coach Baru', '+628700000003', 'sc', true, true, 'p7-v1', 'active',
  'phase07-coach-new-draft', now(), now(),
  'c7000000-0000-0000-0000-000000000001'
);
insert into public.coach_payment_records(
  id, application_id, state, price_band, amount_minor_units,
  provider_reference, verified_at
) values (
  'c7200000-0000-0000-0000-000000000003',
  'c7100000-0000-0000-0000-000000000003', 'verified', 'entry', 100000,
  'phase07-coach-payment', now()
);
insert into public.coach_access_entitlements(
  id, application_id, payment_record_id, coach_user_id, status, starts_at, ends_at
) values (
  'c7300000-0000-0000-0000-000000000003',
  'c7100000-0000-0000-0000-000000000003',
  'c7200000-0000-0000-0000-000000000003',
  'c7000000-0000-0000-0000-000000000003', 'active',
  now() - interval '1 day', now() + interval '30 days'
);

insert into public.programs(
  id, title, summary, status, pace, duration_mode, starts_on, ends_on,
  timezone, participant_limit, past_step_policy, future_step_policy,
  wellness_disclaimer, points_per_activity, points_per_weight_kg,
  quiz_passing_percentage, pricing_mode, published_at, created_by
) values (
  'c7400000-0000-0000-0000-000000000001', 'Program Phase 07', '',
  'active', 'scheduled', 'fixed_duration', current_date, current_date + 7,
  'Asia/Makassar', 20, 'available', 'locked', 'Non-diagnostik.',
  10, 100, 70, 'free', now(), 'c7000000-0000-0000-0000-000000000001'
);
insert into public.program_enrollments(
  id, program_id, participant_id, coach_id, status
) values (
  'c7500000-0000-0000-0000-000000000001',
  'c7400000-0000-0000-0000-000000000001',
  'c7000000-0000-0000-0000-000000000004',
  'c7000000-0000-0000-0000-000000000002', 'active'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"c7000000-0000-0000-0000-000000000004","role":"authenticated"}';

select extensions.throws_like(
  $$ select public.change_my_coach_from_qr('kode-tidak-valid', 'phase07-change-invalid') $$,
  'coach_unavailable', 'unknown Coach QR fails closed'
);
select extensions.is(
  (select current_coach_id from public.profiles where user_id = 'c7000000-0000-0000-0000-000000000004'),
  'c7000000-0000-0000-0000-000000000002'::uuid,
  'invalid QR does not change current Coach'
);
select extensions.lives_ok(
  $$ select public.change_my_coach_from_qr('phase07-coach-new-valid', 'phase07-change-coach-once') $$,
  'verified QR changes Coach authoritatively'
);
select extensions.is(
  (select current_coach_id from public.profiles where user_id = 'c7000000-0000-0000-0000-000000000004'),
  'c7000000-0000-0000-0000-000000000003'::uuid,
  'profile points to the verified Coach'
);
select extensions.is(
  (select coach_id from public.program_enrollments where id = 'c7500000-0000-0000-0000-000000000001'),
  'c7000000-0000-0000-0000-000000000003'::uuid,
  'active enrollment changes in the same transaction'
);
select extensions.lives_ok(
  $$ select public.change_my_coach_from_qr('phase07-coach-new-valid', 'phase07-change-coach-once') $$,
  'same Coach change key replays idempotently'
);
select extensions.throws_like(
  $$ select count(*) from public.participant_coach_change_requests $$,
  'permission denied for table participant_coach_change_requests',
  'Participant cannot read internal idempotency rows'
);
select extensions.is(
  (select count(*)::bigint from public.audit_events
    where actor_id = 'c7000000-0000-0000-0000-000000000004'
      and kind = 'participant_coach_changed'),
  0::bigint, 'RLS hides audit rows from Participant'
);
select extensions.throws_like(
  $$ select public.update_my_profile_avatar(
    'avatars/c7000000-0000-0000-0000-000000000004/c7600000-0000-0000-0000-000000000001.jpg',
    'phase07-avatar-missing-object'
  ) $$,
  'avatar_object_invalid', 'avatar operation rejects missing Storage object'
);
select extensions.ok(
  (public.get_my_participant_profile_context() -> 'coach' ->> 'display_name') = 'Coach Baru',
  'profile context returns current Coach display data'
);

reset role;
select extensions.is(
  (select count(*)::bigint from public.participant_coach_change_requests
    where participant_id = 'c7000000-0000-0000-0000-000000000004'),
  1::bigint, 'idempotency replay stores one request'
);
select extensions.is(
  (select count(*)::bigint from public.audit_events
    where actor_id = 'c7000000-0000-0000-0000-000000000004'
      and kind = 'participant_coach_changed'
      and summary not like '%phase07-coach-new-valid%'
      and payload::text not like '%phase07-coach-new-valid%'),
  1::bigint, 'audit event contains no raw Coach QR identifier'
);

select * from extensions.finish();
rollback;
