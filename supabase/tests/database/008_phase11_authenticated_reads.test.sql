begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(25);

select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.get_my_assigned_coach()',
    'execute'
  ),
  'authenticated users can read their assigned Coach projection'
);
select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.list_my_program_day_access()',
    'execute'
  ),
  'authenticated users can read their program-day access'
);
select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.get_my_dashboard_summary()',
    'execute'
  ),
  'authenticated users can read their dashboard summary'
);
select extensions.ok(
  not has_function_privilege(
    'anon',
    'public.get_my_assigned_coach()',
    'execute'
  ),
  'anon cannot read an assigned Coach'
);
select extensions.ok(
  not has_function_privilege(
    'anon',
    'public.list_my_program_day_access()',
    'execute'
  ),
  'anon cannot read participant day access'
);
select extensions.ok(
  not has_function_privilege(
    'anon',
    'public.get_my_dashboard_summary()',
    'execute'
  ),
  'anon cannot read an authenticated dashboard summary'
);
select extensions.ok(
  not has_function_privilege(
    'public',
    'public.get_my_assigned_coach()',
    'execute'
  ),
  'PUBLIC has no assigned-Coach execute privilege'
);

insert into auth.users (
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    'd1000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'phase11-auth-admin@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    'd1000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'phase11-auth-coach-a@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    'd1000000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'phase11-auth-coach-b@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    'd1000000-0000-0000-0000-000000000011',
    'authenticated',
    'authenticated',
    'phase11-auth-participant-a@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    'd1000000-0000-0000-0000-000000000012',
    'authenticated',
    'authenticated',
    'phase11-auth-participant-b@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  );

update public.profiles
set role = 'admin',
    display_name = 'Admin Auth Read',
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = 'd1000000-0000-0000-0000-000000000001';

update public.profiles
set role = 'coach',
    display_name = case user_id
      when 'd1000000-0000-0000-0000-000000000002'
        then 'Coach Auth A'
      else 'Coach Auth B'
    end,
    city = 'Denpasar',
    phone_number = '+6281200000999',
    coach_qr_identifier = 'phase11-auth-' || user_id::text,
    coach_is_approved = true,
    coach_is_public = false,
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id in (
  'd1000000-0000-0000-0000-000000000002',
  'd1000000-0000-0000-0000-000000000003'
);

insert into public.coach_applications (
  id, applicant_user_id, participant_profile_id, display_name_snapshot,
  phone_number_snapshot, member_level_snapshot, has_completed_hom_sts,
  has_completed_ict, terms_version, status, draft_idempotency_key,
  submitted_at, decided_at, decided_by
)
values
  ('da000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000002', 'Coach Auth A', '+6281200000999', 'sc', true, true, 'test-v1', 'approved', 'auth-read-coach-a', now(), now(), 'd1000000-0000-0000-0000-000000000001'),
  ('da000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000003', 'Coach Auth B', '+6281200000999', 'sc', true, true, 'test-v1', 'approved', 'auth-read-coach-b', now(), now(), 'd1000000-0000-0000-0000-000000000001');

insert into public.coach_payment_records (
  id, application_id, state, price_band, amount_minor_units,
  provider_reference, verified_at
)
values
  ('db000000-0000-0000-0000-000000000002', 'da000000-0000-0000-0000-000000000002', 'verified', 'entry', 100000, 'test-auth-read-a', now()),
  ('db000000-0000-0000-0000-000000000003', 'da000000-0000-0000-0000-000000000003', 'verified', 'entry', 100000, 'test-auth-read-b', now());

insert into public.coach_access_entitlements (
  id, application_id, payment_record_id, coach_user_id, status,
  starts_at, ends_at
)
values
  ('dc000000-0000-0000-0000-000000000002', 'da000000-0000-0000-0000-000000000002', 'db000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000002', 'active', now() - interval '1 day', now() + interval '30 days'),
  ('dc000000-0000-0000-0000-000000000003', 'da000000-0000-0000-0000-000000000003', 'db000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000003', 'active', now() - interval '1 day', now() + interval '30 days');

update public.profiles
set display_name = case user_id
      when 'd1000000-0000-0000-0000-000000000011'
        then 'Peserta Auth A'
      else 'Peserta Auth B'
    end,
    current_coach_id = case user_id
      when 'd1000000-0000-0000-0000-000000000011'
        then 'd1000000-0000-0000-0000-000000000002'::uuid
      else 'd1000000-0000-0000-0000-000000000003'::uuid
    end,
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id in (
  'd1000000-0000-0000-0000-000000000011',
  'd1000000-0000-0000-0000-000000000012'
);

insert into public.programs (
  id,
  title,
  summary,
  status,
  pace,
  duration_mode,
  starts_on,
  ends_on,
  timezone,
  past_step_policy,
  future_step_policy,
  wellness_disclaimer,
  points_per_activity,
  points_per_weight_kg,
  quiz_passing_percentage,
  pricing_mode,
  published_at,
  created_by
)
values (
  'd2000000-0000-0000-0000-000000000001',
  'Program Auth Read',
  'Program pengujian baca terautentikasi.',
  'active',
  'scheduled',
  'specific_dates',
  timezone('Asia/Makassar', statement_timestamp())::date,
  timezone('Asia/Makassar', statement_timestamp())::date + 1,
  'Asia/Makassar',
  'read_only',
  'locked',
  'Program kebugaran non-diagnostik.',
  10,
  100,
  70,
  'free',
  now(),
  'd1000000-0000-0000-0000-000000000001'
);

insert into public.program_days (
  id, program_id, day_number, title, scheduled_on
)
values (
  'd3000000-0000-0000-0000-000000000001',
  'd2000000-0000-0000-0000-000000000001',
  1,
  'Hari Auth Read',
  timezone('Asia/Makassar', statement_timestamp())::date
);

insert into public.program_steps (
  id,
  program_day_id,
  step_order,
  title,
  content_kind,
  completion_policy,
  verification_mode
)
values (
  'd4000000-0000-0000-0000-000000000001',
  'd3000000-0000-0000-0000-000000000001',
  1,
  'Langkah Auth Read',
  'form',
  'answer_all_questions',
  'coach_review'
);

insert into public.program_questions (
  id, step_id, question_order, kind, prompt
)
values (
  'd5000000-0000-0000-0000-000000000001',
  'd4000000-0000-0000-0000-000000000001',
  1,
  'short_answer',
  'Pertanyaan privat'
);

insert into public.program_answer_keys (
  question_id, accepted_text_values
)
values (
  'd5000000-0000-0000-0000-000000000001',
  array['rahasia']
);

insert into public.program_enrollments (
  id, program_id, participant_id, coach_id, status
)
values
  (
    'd6000000-0000-0000-0000-000000000011',
    'd2000000-0000-0000-0000-000000000001',
    'd1000000-0000-0000-0000-000000000011',
    'd1000000-0000-0000-0000-000000000002',
    'active'
  ),
  (
    'd6000000-0000-0000-0000-000000000012',
    'd2000000-0000-0000-0000-000000000001',
    'd1000000-0000-0000-0000-000000000012',
    'd1000000-0000-0000-0000-000000000003',
    'active'
  );

insert into public.step_submissions (
  id, enrollment_id, step_id, status
)
values
  (
    'd7000000-0000-0000-0000-000000000011',
    'd6000000-0000-0000-0000-000000000011',
    'd4000000-0000-0000-0000-000000000001',
    'pending'
  ),
  (
    'd7000000-0000-0000-0000-000000000012',
    'd6000000-0000-0000-0000-000000000012',
    'd4000000-0000-0000-0000-000000000001',
    'pending'
  );

insert into public.weigh_ins (
  id, enrollment_id, step_id, kind, weight_kg
)
values
  (
    'd8000000-0000-0000-0000-000000000011',
    'd6000000-0000-0000-0000-000000000011',
    'd4000000-0000-0000-0000-000000000001',
    'daily',
    70
  ),
  (
    'd8000000-0000-0000-0000-000000000012',
    'd6000000-0000-0000-0000-000000000012',
    'd4000000-0000-0000-0000-000000000001',
    'daily',
    80
  );

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"d1000000-0000-0000-0000-000000000011","role":"authenticated"}';

select extensions.is(
  (select count(*)::bigint from public.get_my_assigned_coach()),
  1::bigint,
  'Participant sees exactly one assigned Coach'
);
select extensions.is(
  (select user_id from public.get_my_assigned_coach()),
  'd1000000-0000-0000-0000-000000000002'::uuid,
  'assigned Coach is resolved from the caller profile'
);
select extensions.ok(
  not (
    select to_jsonb(coach) ? 'phone_number'
    from public.get_my_assigned_coach() coach
  ),
  'assigned Coach projection omits phone number'
);
select extensions.ok(
  not (
    select to_jsonb(coach) ? 'coach_qr_identifier'
    from public.get_my_assigned_coach() coach
  ),
  'assigned Coach projection omits raw QR identifier'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.list_my_program_day_access()
  ),
  1::bigint,
  'day access contains only the caller enrollment'
);
select extensions.is(
  (
    select access_state
    from public.list_my_program_day_access()
  ),
  'available',
  'current program day is server-resolved as available'
);
select extensions.is(
  (
    select active_enrollment_count
    from public.get_my_dashboard_summary()
  ),
  1,
  'dashboard counts only the caller active enrollment'
);
select extensions.is(
  (
    select pending_submission_count
    from public.get_my_dashboard_summary()
  ),
  1,
  'dashboard counts only the caller pending submission'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.program_enrollments
    where participant_id =
      'd1000000-0000-0000-0000-000000000012'
  ),
  0::bigint,
  'explicit filters cannot bypass enrollment RLS'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.step_submissions
    where enrollment_id =
      'd6000000-0000-0000-0000-000000000012'
  ),
  0::bigint,
  'explicit filters cannot bypass submission RLS'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.weigh_ins
    where enrollment_id =
      'd6000000-0000-0000-0000-000000000012'
  ),
  0::bigint,
  'explicit filters cannot bypass private-weight RLS'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.program_scores
    where enrollment_id =
      'd6000000-0000-0000-0000-000000000012'
  ),
  0::bigint,
  'explicit filters cannot bypass private score-breakdown RLS'
);
select extensions.is(
  (select count(*)::bigint from public.program_answer_keys),
  0::bigint,
  'Participant cannot read answer keys'
);
select extensions.is(
  (select count(*)::bigint from public.profiles),
  1::bigint,
  'Participant base-profile read remains self-only'
);

set local "request.jwt.claims" =
  '{"sub":"d1000000-0000-0000-0000-000000000012","role":"authenticated"}';

select extensions.is(
  (select user_id from public.get_my_assigned_coach()),
  'd1000000-0000-0000-0000-000000000003'::uuid,
  'a second Participant resolves only their own Coach'
);
select extensions.is(
  (
    select active_enrollment_count
    from public.get_my_dashboard_summary()
  ),
  1,
  'a second Participant receives an isolated dashboard count'
);

set local "request.jwt.claims" =
  '{"sub":"d1000000-0000-0000-0000-000000000002","role":"authenticated"}';

select extensions.is(
  (select count(*)::bigint from public.get_my_assigned_coach()),
  0::bigint,
  'a Coach cannot use the Participant assigned-Coach projection'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.list_my_program_day_access()
  ),
  0::bigint,
  'a Coach cannot use the Participant day-access projection'
);

select * from extensions.finish();
rollback;
