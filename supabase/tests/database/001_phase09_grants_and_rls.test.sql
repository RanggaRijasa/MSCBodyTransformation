begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(26);

-- Object-level Data API grants are intentionally narrower than RLS. Both
-- layers are tested because a correct policy cannot compensate for an
-- accidentally broad table or function grant.
select extensions.ok(
  not has_table_privilege('anon', 'public.profiles', 'select'),
  'anon cannot read application profiles'
);
select extensions.ok(
  has_table_privilege('authenticated', 'public.profiles', 'select'),
  'authenticated can reach the profiles RLS boundary'
);
select extensions.ok(
  not has_table_privilege('authenticated', 'public.profiles', 'update'),
  'authenticated cannot directly change profile roles'
);
select extensions.ok(
  not has_table_privilege('authenticated', 'public.profiles', 'insert'),
  'authenticated cannot create a privileged profile'
);
select extensions.ok(
  has_table_privilege('authenticated', 'public.programs', 'insert'),
  'authenticated can reach the Admin-only program insert policy'
);
select extensions.ok(
  not has_table_privilege(
    'authenticated',
    'public.program_store_products',
    'select'
  ),
  'store products remain server-only'
);
select extensions.ok(
  not has_table_privilege(
    'authenticated',
    'public.score_adjustments',
    'select'
  ),
  'score adjustments remain server-only'
);
select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.enroll_free_program(uuid,text)',
    'execute'
  ),
  'authenticated can call the reviewed enrollment RPC'
);
select extensions.ok(
  not has_schema_privilege(
    'authenticated',
    'private',
    'usage'
  ),
  'authenticated cannot resolve private helper functions directly'
);
select extensions.ok(
  not has_function_privilege(
    'service_role',
    'private.can_coach_participant(uuid)',
    'execute'
  ),
  'service role cannot execute the Coach helper directly'
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
    '00000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'admin@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'coach-one@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'coach-two@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000011',
    'authenticated',
    'authenticated',
    'participant-one@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000012',
    'authenticated',
    'authenticated',
    'participant-two@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  );

insert into public.profiles (
  user_id,
  role,
  display_name,
  current_coach_id,
  coach_qr_identifier,
  coach_is_approved,
  coach_is_public
)
values
  (
    '00000000-0000-0000-0000-000000000001',
    'admin',
    'Admin Test',
    null,
    null,
    false,
    false
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'coach',
    'Coach Satu',
    null,
    'coach-one-private-qr',
    true,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    'coach',
    'Coach Dua',
    null,
    'coach-two-private-qr',
    true,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000011',
    'participant',
    'Peserta Satu',
    '00000000-0000-0000-0000-000000000002',
    null,
    false,
    false
  ),
  (
    '00000000-0000-0000-0000-000000000012',
    'participant',
    'Peserta Dua',
    '00000000-0000-0000-0000-000000000003',
    null,
    false,
    false
  );

insert into public.programs (
  id,
  title,
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
  created_by
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'Program Aktif',
    'active',
    'scheduled',
    'fixed_duration',
    date '2026-08-01',
    date '2026-08-31',
    'Asia/Makassar',
    'available',
    'locked',
    'Program kebugaran non-diagnostik.',
    10,
    100,
    70,
    'free',
    '00000000-0000-0000-0000-000000000001'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'Program Draf',
    'draft',
    'scheduled',
    'fixed_duration',
    date '2026-09-01',
    date '2026-09-30',
    'Asia/Makassar',
    'available',
    'locked',
    'Program kebugaran non-diagnostik.',
    10,
    100,
    70,
    'free',
    '00000000-0000-0000-0000-000000000001'
  );

insert into public.program_days (
  id,
  program_id,
  day_number,
  title,
  scheduled_on
)
values (
  '20000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  1,
  'Hari Pertama',
  date '2026-08-01'
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
  '30000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  1,
  'Kuis Harian',
  'quiz',
  'automatic_quiz',
  'automatic'
);

insert into public.program_questions (
  id,
  step_id,
  question_order,
  kind,
  prompt
)
values (
  '40000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-000000000001',
  1,
  'short_answer',
  'Pertanyaan pengujian'
);

insert into public.program_answer_keys (
  question_id,
  accepted_text_values
)
values (
  '40000000-0000-0000-0000-000000000001',
  array['jawaban']
);

insert into public.program_enrollments (
  id,
  program_id,
  participant_id,
  coach_id,
  status
)
values
  (
    '50000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000011',
    '00000000-0000-0000-0000-000000000002',
    'active'
  ),
  (
    '50000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000012',
    '00000000-0000-0000-0000-000000000003',
    'active'
  );

insert into public.step_submissions (
  id,
  enrollment_id,
  step_id,
  status
)
values
  (
    '60000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    'approved'
  ),
  (
    '60000000-0000-0000-0000-000000000002',
    '50000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    'approved'
  );

insert into public.step_submission_answers (
  id,
  submission_id,
  question_id,
  text_value
)
values
  (
    '70000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    'jawaban'
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000001',
    'jawaban'
  );

insert into public.weigh_ins (
  id,
  enrollment_id,
  step_id,
  kind,
  weight_kg
)
values
  (
    '80000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    'daily',
    70.00
  ),
  (
    '80000000-0000-0000-0000-000000000002',
    '50000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    'daily',
    80.00
  );

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000011","role":"authenticated"}';

select extensions.is(
  (select count(*)::bigint from public.profiles),
  1::bigint,
  'Participant sees only their own profile'
);
select extensions.is(
  (select count(*)::bigint from public.program_enrollments),
  1::bigint,
  'Participant sees only their own enrollment'
);
select extensions.is(
  (select count(*)::bigint from public.step_submissions),
  1::bigint,
  'Participant sees only their own submission'
);
select extensions.is(
  (select count(*)::bigint from public.weigh_ins),
  1::bigint,
  'Participant sees only their own private weight'
);
select extensions.is(
  (select count(*)::bigint from public.program_answer_keys),
  0::bigint,
  'Participant cannot read quiz answer keys'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.programs
    where id = '10000000-0000-0000-0000-000000000002'
  ),
  0::bigint,
  'Participant cannot read draft programs'
);
select extensions.throws_like(
  $$
    insert into public.programs (
      title,
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
      created_by
    )
    values (
      'Tidak Diizinkan',
      'draft',
      'scheduled',
      'fixed_duration',
      date '2026-10-01',
      date '2026-10-31',
      'Asia/Makassar',
      'available',
      'locked',
      'Program kebugaran non-diagnostik.',
      10,
      100,
      70,
      'free',
      '00000000-0000-0000-0000-000000000011'
    )
  $$,
  '%row-level security policy%',
  'Participant cannot mutate Program CMS rows'
);

set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000002","role":"authenticated"}';

select extensions.is(
  (select count(*)::bigint from public.profiles),
  2::bigint,
  'Coach sees their own and assigned Participant profiles'
);
select extensions.is(
  (select count(*)::bigint from public.program_enrollments),
  1::bigint,
  'Coach sees only assigned enrollments'
);
select extensions.is(
  (select count(*)::bigint from public.step_submissions),
  1::bigint,
  'Coach sees only assigned submissions'
);
select extensions.is(
  (select count(*)::bigint from public.weigh_ins),
  1::bigint,
  'Coach sees only assigned private weights'
);
select extensions.is(
  (select count(*)::bigint from public.program_answer_keys),
  1::bigint,
  'Coach sees answer keys only through an assigned enrollment'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.program_enrollments
    where participant_id = '00000000-0000-0000-0000-000000000012'
  ),
  0::bigint,
  'Coach cannot see another Coach participant'
);

set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}';

select extensions.is(
  (select count(*)::bigint from public.profiles),
  5::bigint,
  'Admin can read all profiles'
);
select extensions.is(
  (select count(*)::bigint from public.programs),
  2::bigint,
  'Admin can read active and draft programs'
);
select extensions.lives_ok(
  $$
    insert into public.programs (
      title,
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
      created_by
    )
    values (
      'Draf Admin',
      'draft',
      'scheduled',
      'fixed_duration',
      date '2026-10-01',
      date '2026-10-31',
      'Asia/Makassar',
      'available',
      'locked',
      'Program kebugaran non-diagnostik.',
      10,
      100,
      70,
      'free',
      '00000000-0000-0000-0000-000000000001'
    )
  $$,
  'Admin can mutate Program CMS rows'
);

reset role;

select * from extensions.finish();
rollback;
