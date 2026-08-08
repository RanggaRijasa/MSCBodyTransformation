begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(13);

select extensions.has_column(
  'public',
  'programs',
  'registration_closes_at',
  'programs stores the exact registration cutoff'
);
select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.admin_enroll_participant(uuid,uuid,text)',
    'execute'
  ),
  'authenticated can reach the Admin enrollment RPC boundary'
);
select extensions.ok(
  not has_function_privilege(
    'anon',
    'public.admin_enroll_participant(uuid,uuid,text)',
    'execute'
  ),
  'anon cannot call the Admin enrollment RPC'
);
select extensions.ok(
  not has_function_privilege(
    'service_role',
    'public.admin_enroll_participant(uuid,uuid,text)',
    'execute'
  ),
  'service role has no implicit Admin enrollment RPC grant'
);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    'a1000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'deadline-admin@test.invalid', '',
    now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    'a1000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'deadline-coach@test.invalid', '',
    now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    'a1000000-0000-0000-0000-000000000011',
    'authenticated', 'authenticated', 'deadline-one@test.invalid', '',
    now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    'a1000000-0000-0000-0000-000000000012',
    'authenticated', 'authenticated', 'deadline-two@test.invalid', '',
    now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()
  );

insert into public.profiles (
  user_id, role, display_name, current_coach_id,
  coach_qr_identifier, coach_is_approved
)
values
  (
    'a1000000-0000-0000-0000-000000000001',
    'admin', 'Admin Deadline', null, null, false
  ),
  (
    'a1000000-0000-0000-0000-000000000002',
    'coach', 'Coach Deadline', null, 'deadline-coach-qr', true
  ),
  (
    'a1000000-0000-0000-0000-000000000011',
    'participant', 'Peserta Deadline Satu',
    'a1000000-0000-0000-0000-000000000002', null, false
  ),
  (
    'a1000000-0000-0000-0000-000000000012',
    'participant', 'Peserta Deadline Dua',
    'a1000000-0000-0000-0000-000000000002', null, false
  )
on conflict (user_id) do update set
  role = excluded.role,
  display_name = excluded.display_name,
  current_coach_id = excluded.current_coach_id,
  coach_qr_identifier = excluded.coach_qr_identifier,
  coach_is_approved = excluded.coach_is_approved,
  onboarding_status = 'active',
  provisional_expires_at = null,
  finalized_at = now(),
  updated_at = now();

insert into public.coach_applications (
  id, applicant_user_id, participant_profile_id, display_name_snapshot,
  phone_number_snapshot, member_level_snapshot, has_completed_hom_sts,
  has_completed_ict, terms_version, status, draft_idempotency_key,
  submitted_at, decided_at, decided_by
)
values (
  'aa000000-0000-0000-0000-000000000002',
  'a1000000-0000-0000-0000-000000000002',
  'a1000000-0000-0000-0000-000000000002',
  'Coach Deadline', '+628300000002', 'sc', true, true, 'test-v1',
  'approved', 'deadline-coach-one', now(), now(),
  'a1000000-0000-0000-0000-000000000001'
);

insert into public.coach_payment_records (
  id, application_id, state, price_band, amount_minor_units,
  provider_reference, verified_at
)
values (
  'ab000000-0000-0000-0000-000000000002',
  'aa000000-0000-0000-0000-000000000002',
  'verified', 'entry', 100000, 'test-deadline-one', now()
);

insert into public.coach_access_entitlements (
  id, application_id, payment_record_id, coach_user_id, status,
  starts_at, ends_at
)
values (
  'ac000000-0000-0000-0000-000000000002',
  'aa000000-0000-0000-0000-000000000002',
  'ab000000-0000-0000-0000-000000000002',
  'a1000000-0000-0000-0000-000000000002',
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
    'a2000000-0000-0000-0000-000000000001',
    'Program Deadline Gratis', 'active', 'scheduled', 'fixed_duration',
    current_date - 1, current_date + 7, 'Asia/Jakarta', 1,
    clock_timestamp() - interval '1 minute', 'available', 'locked',
    'Program kebugaran non-diagnostik.', 10, 100, 70, 'free', null,
    'a1000000-0000-0000-0000-000000000001'
  ),
  (
    'a2000000-0000-0000-0000-000000000002',
    'Program Deadline Berbayar', 'active', 'scheduled', 'fixed_duration',
    current_date - 1, current_date + 7, 'Asia/Jakarta', null,
    clock_timestamp() - interval '1 minute', 'available', 'locked',
    'Program kebugaran non-diagnostik.', 10, 100, 70, 'paid', 100000,
    'a1000000-0000-0000-0000-000000000001'
  );

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"a1000000-0000-0000-0000-000000000011","role":"authenticated"}';

select extensions.throws_like(
  $$
    select public.enroll_free_program(
      'a2000000-0000-0000-0000-000000000001',
      'deadline-coach-qr'
    )
  $$,
  'registration_closed',
  'Participant self-enrollment is rejected after the cutoff'
);
select extensions.is(
  (
    select count(*)::bigint from public.program_enrollments
    where program_id = 'a2000000-0000-0000-0000-000000000001'
  ),
  0::bigint,
  'rejected self-enrollment creates no row'
);
select extensions.throws_like(
  $$
    select public.admin_enroll_participant(
      'a2000000-0000-0000-0000-000000000001',
      'a1000000-0000-0000-0000-000000000011',
      'Bukan Admin'
    )
  $$,
  'permission_denied',
  'a Participant cannot invoke the Admin override'
);

set local "request.jwt.claims" =
  '{"sub":"a1000000-0000-0000-0000-000000000001","role":"authenticated"}';

select extensions.lives_ok(
  $$
    select public.admin_enroll_participant(
      'a2000000-0000-0000-0000-000000000001',
      'a1000000-0000-0000-0000-000000000011',
      'Dokumen dan Coach sudah diverifikasi.'
    )
  $$,
  'Admin can enroll after the registration cutoff'
);
select extensions.is(
  (
    select count(*)::bigint from public.program_enrollments
    where program_id = 'a2000000-0000-0000-0000-000000000001'
      and participant_id = 'a1000000-0000-0000-0000-000000000011'
  ),
  1::bigint,
  'Admin override creates exactly one enrollment'
);
select extensions.is(
  (
    select count(*)::bigint from public.audit_events
    where kind = 'participant_enrolled'
      and subject_id = 'a1000000-0000-0000-0000-000000000011'
      and (payload ->> 'registration_deadline_bypassed')::boolean
  ),
  1::bigint,
  'Admin deadline override is audited'
);
select extensions.is(
  (
    select count(*)::bigint from public.program_scores score
    join public.program_enrollments enrollment
      on enrollment.id = score.enrollment_id
    where enrollment.program_id =
      'a2000000-0000-0000-0000-000000000001'
      and enrollment.participant_id =
        'a1000000-0000-0000-0000-000000000011'
  ),
  1::bigint,
  'Admin enrollment initializes one score row'
);
select extensions.throws_like(
  $$
    select public.admin_enroll_participant(
      'a2000000-0000-0000-0000-000000000001',
      'a1000000-0000-0000-0000-000000000012',
      'Kapasitas tidak boleh dilewati.'
    )
  $$,
  'program_full',
  'Admin deadline override does not bypass capacity'
);
select extensions.throws_like(
  $$
    select public.admin_enroll_participant(
      'a2000000-0000-0000-0000-000000000002',
      'a1000000-0000-0000-0000-000000000012',
      'Pembayaran belum ada.'
    )
  $$,
  'payment_required',
  'Admin deadline override does not bypass payment'
);

select * from extensions.finish();
rollback;
