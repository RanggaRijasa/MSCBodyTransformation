begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(31);

select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.prepare_step_submission(uuid,uuid,text)',
    'execute'
  ),
  'authenticated can prepare a reviewed submission upload session'
);
select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.submit_step_answers(uuid,jsonb,text)',
    'execute'
  ),
  'authenticated can call the typed-answer RPC'
);
select extensions.ok(
  not has_function_privilege(
    'anon',
    'public.review_step_submission(uuid,text,text,text)',
    'execute'
  ),
  'anon cannot call the Coach review RPC'
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
  'every SECURITY DEFINER function has an empty explicit search_path'
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
    '91000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'vertical-admin@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    '91000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'vertical-coach@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    '91000000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'vertical-unrelated-coach@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    '91000000-0000-0000-0000-000000000011',
    'authenticated',
    'authenticated',
    'vertical-participant@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    '91000000-0000-0000-0000-000000000012',
    'authenticated',
    'authenticated',
    'vertical-unrelated-participant@test.invalid',
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
  coach_is_approved
)
values
  (
    '91000000-0000-0000-0000-000000000001',
    'admin',
    'Admin Vertical Slice',
    null,
    null,
    false
  ),
  (
    '91000000-0000-0000-0000-000000000002',
    'coach',
    'Coach Vertical Slice',
    null,
    'vertical-coach-qr',
    true
  ),
  (
    '91000000-0000-0000-0000-000000000003',
    'coach',
    'Coach Tidak Terkait',
    null,
    'vertical-other-coach-qr',
    true
  ),
  (
    '91000000-0000-0000-0000-000000000011',
    'participant',
    'Peserta Vertical Slice',
    '91000000-0000-0000-0000-000000000002',
    null,
    false
  ),
  (
    '91000000-0000-0000-0000-000000000012',
    'participant',
    'Peserta Tidak Terkait',
    '91000000-0000-0000-0000-000000000003',
    null,
    false
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
values (
  '92000000-0000-0000-0000-000000000001',
  'Program Vertical Slice',
  'active',
  'scheduled',
  'fixed_duration',
  (
    timezone('Asia/Jakarta', statement_timestamp())
  )::date - 1,
  (
    timezone('Asia/Jakarta', statement_timestamp())
  )::date + 10,
  'Asia/Jakarta',
  'available',
  'locked',
  'Program kebugaran non-diagnostik.',
  10,
  100,
  70,
  'free',
  '91000000-0000-0000-0000-000000000001'
);

insert into public.program_days (
  id,
  program_id,
  day_number,
  title,
  scheduled_on
)
values (
  '93000000-0000-0000-0000-000000000001',
  '92000000-0000-0000-0000-000000000001',
  1,
  'Hari Vertical Slice',
  (timezone('Asia/Jakarta', statement_timestamp()))::date
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
values
  (
    '94000000-0000-0000-0000-000000000001',
    '93000000-0000-0000-0000-000000000001',
    1,
    'Form dengan foto',
    'form',
    'answer_all_questions',
    'coach_review'
  ),
  (
    '94000000-0000-0000-0000-000000000002',
    '93000000-0000-0000-0000-000000000001',
    2,
    'Kuis otomatis',
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
values
  (
    '95000000-0000-0000-0000-000000000001',
    '94000000-0000-0000-0000-000000000001',
    1,
    'short_answer',
    'Apa fokus hari ini?'
  ),
  (
    '95000000-0000-0000-0000-000000000002',
    '94000000-0000-0000-0000-000000000001',
    2,
    'number',
    'Berapa gelas air?'
  ),
  (
    '95000000-0000-0000-0000-000000000003',
    '94000000-0000-0000-0000-000000000001',
    3,
    'single_choice',
    'Pilih kondisi'
  ),
  (
    '95000000-0000-0000-0000-000000000004',
    '94000000-0000-0000-0000-000000000001',
    4,
    'photo_upload',
    'Unggah foto jawaban'
  ),
  (
    '95000000-0000-0000-0000-000000000005',
    '94000000-0000-0000-0000-000000000002',
    1,
    'single_choice',
    'Pilihan yang benar?'
  );

insert into public.program_question_options (
  id,
  question_id,
  option_order,
  title
)
values
  (
    '96000000-0000-0000-0000-000000000001',
    '95000000-0000-0000-0000-000000000003',
    1,
    'Baik'
  ),
  (
    '96000000-0000-0000-0000-000000000002',
    '95000000-0000-0000-0000-000000000005',
    1,
    'Benar'
  ),
  (
    '96000000-0000-0000-0000-000000000003',
    '95000000-0000-0000-0000-000000000005',
    2,
    'Salah'
  );

insert into public.program_answer_keys (
  question_id,
  selected_option_ids
)
values (
  '95000000-0000-0000-0000-000000000005',
  array['96000000-0000-0000-0000-000000000002'::uuid]
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
    '97000000-0000-0000-0000-000000000001',
    '92000000-0000-0000-0000-000000000001',
    '91000000-0000-0000-0000-000000000011',
    '91000000-0000-0000-0000-000000000002',
    'active'
  ),
  (
    '97000000-0000-0000-0000-000000000002',
    '92000000-0000-0000-0000-000000000001',
    '91000000-0000-0000-0000-000000000012',
    '91000000-0000-0000-0000-000000000003',
    'active'
  );

insert into public.program_scores(enrollment_id)
values
  ('97000000-0000-0000-0000-000000000001'),
  ('97000000-0000-0000-0000-000000000002');

create temporary table vertical_slice_test_ids (
  name text primary key,
  value uuid not null
);
grant select, insert on vertical_slice_test_ids to authenticated;

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"91000000-0000-0000-0000-000000000011","role":"authenticated"}';

select extensions.is(
  (
    select status
    from public.prepare_step_submission(
      '97000000-0000-0000-0000-000000000001',
      '94000000-0000-0000-0000-000000000001',
      'form-request-0001'
    )
  ),
  'draft',
  'Participant prepares an internal draft before private upload'
);

insert into vertical_slice_test_ids(name, value)
select 'form_submission', id
from public.step_submissions
where idempotency_key = 'form-request-0001';

select extensions.is(
  (
    select id
    from public.prepare_step_submission(
      '97000000-0000-0000-0000-000000000001',
      '94000000-0000-0000-0000-000000000001',
      'form-request-0001'
    )
  ),
  (
    select id
    from public.step_submissions
    where idempotency_key = 'form-request-0001'
  ),
  'submission preparation retry returns the same draft'
);

insert into storage.objects (
  bucket_id,
  name,
  metadata
)
select
  'question-photos',
  '91000000-0000-0000-0000-000000000011/'
    || '97000000-0000-0000-0000-000000000001/'
    || submission.id::text || '/'
    || '95000000-0000-0000-0000-000000000004/'
    || '98000000-0000-0000-0000-000000000001.jpg',
  '{"mimetype":"image/jpeg"}'::jsonb
from public.step_submissions submission
where submission.idempotency_key = 'form-request-0001';

select extensions.is(
  (
    select status
    from public.submit_step_answers(
      (
        select id
        from public.step_submissions
        where idempotency_key = 'form-request-0001'
      ),
      jsonb_build_array(
        jsonb_build_object(
          'question_id',
          '95000000-0000-0000-0000-000000000001',
          'text_value',
          'Konsisten'
        ),
        jsonb_build_object(
          'question_id',
          '95000000-0000-0000-0000-000000000002',
          'number_value',
          '8'
        ),
        jsonb_build_object(
          'question_id',
          '95000000-0000-0000-0000-000000000003',
          'selected_option_ids',
          jsonb_build_array(
            '96000000-0000-0000-0000-000000000001'
          )
        ),
        jsonb_build_object(
          'question_id',
          '95000000-0000-0000-0000-000000000004',
          'private_photo_path',
          (
            select name
            from storage.objects
            where bucket_id = 'question-photos'
          )
        )
      ),
      'form-request-0001'
    )
  ),
  'pending',
  'complete typed answers finalize into Coach review'
);

select extensions.is(
  (
    select count(*)::bigint
    from public.step_submission_answers
  ),
  4::bigint,
  'finalization persists exactly one answer per interactive question'
);

select extensions.is(
  (
    select status
    from public.submit_step_answers(
      (
        select id
        from public.step_submissions
        where idempotency_key = 'form-request-0001'
      ),
      '[]'::jsonb,
      'form-request-0001'
    )
  ),
  'pending',
  'finalization retry returns the existing submission'
);

select extensions.is(
  (
    select count(*)::bigint
    from public.step_submission_answers
  ),
  4::bigint,
  'finalization retry does not duplicate answers'
);

select extensions.throws_like(
  $$
    select public.refresh_enrollment_score(
      '97000000-0000-0000-0000-000000000002'
    )
  $$,
  '%permission_denied%',
  'Participant cannot refresh an unrelated enrollment score'
);

set local "request.jwt.claims" =
  '{"sub":"91000000-0000-0000-0000-000000000003","role":"authenticated"}';

select extensions.throws_like(
  $$
    select public.review_step_submission(
      (
        select value
        from vertical_slice_test_ids
        where name = 'form_submission'
      ),
      'approved',
      null,
      'review-request-0001'
    )
  $$,
  '%permission_denied%',
  'unrelated Coach cannot review the submission'
);

set local "request.jwt.claims" =
  '{"sub":"91000000-0000-0000-0000-000000000002","role":"authenticated"}';

select extensions.is(
  (
    select count(*)::bigint
    from public.step_submissions
    where status = 'draft'
  ),
  0::bigint,
  'Coach cannot see Participant upload drafts'
);

select extensions.is(
  (
    select status
    from public.review_step_submission(
      (
        select value
        from vertical_slice_test_ids
        where name = 'form_submission'
      ),
      'approved',
      null,
      'review-request-0001'
    )
  ),
  'approved',
  'assigned Coach approves a complete pending submission'
);

reset role;

select extensions.is(
  (
    select activity_points
    from public.program_scores
    where enrollment_id =
      '97000000-0000-0000-0000-000000000001'
  ),
  10,
  'Coach approval awards activity points exactly once'
);

select extensions.is(
  (
    select progress_percentage
    from public.program_scores
    where enrollment_id =
      '97000000-0000-0000-0000-000000000001'
  ),
  50,
  'authoritative progress counts one of two program steps'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"91000000-0000-0000-0000-000000000002","role":"authenticated"}';

select extensions.is(
  (
    select status
    from public.review_step_submission(
      (
        select value
        from vertical_slice_test_ids
        where name = 'form_submission'
      ),
      'approved',
      null,
      'review-request-0001'
    )
  ),
  'approved',
  'same review retry returns the prior decision'
);

select extensions.throws_like(
  $$
    select public.review_step_submission(
      (
        select value
        from vertical_slice_test_ids
        where name = 'form_submission'
      ),
      'rejected',
      'Berbeda',
      'review-request-0002'
    )
  $$,
  '%submission_already_reviewed%',
  'a later conflicting review cannot reverse the decision'
);

reset role;

select extensions.is(
  (
    select count(*)::bigint
    from public.audit_events
    where kind = 'submission_approved'
  ),
  1::bigint,
  'idempotent review writes one audit event'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"91000000-0000-0000-0000-000000000011","role":"authenticated"}';

select public.prepare_step_submission(
  '97000000-0000-0000-0000-000000000001',
  '94000000-0000-0000-0000-000000000002',
  'quiz-request-0001'
);

select extensions.is(
  (
    select status
    from public.submit_step_answers(
      (
        select id
        from public.step_submissions
        where idempotency_key = 'quiz-request-0001'
      ),
      jsonb_build_array(
        jsonb_build_object(
          'question_id',
          '95000000-0000-0000-0000-000000000005',
          'selected_option_ids',
          jsonb_build_array(
            '96000000-0000-0000-0000-000000000002'
          )
        )
      ),
      'quiz-request-0001'
    )
  ),
  'approved',
  'quiz is scored automatically without a Coach mutation'
);

select extensions.is(
  (
    select correct_count
    from public.quiz_attempt_results
  ),
  1,
  'quiz result stores the correct count'
);

select extensions.is(
  (
    select awarded_points
    from public.quiz_attempt_results
  ),
  10,
  'quiz points come from server-side answer keys and program scoring'
);

select extensions.is(
  (
    select quiz_points
    from public.program_scores
    where enrollment_id =
      '97000000-0000-0000-0000-000000000001'
  ),
  10,
  'score reconciliation includes the latest quiz result'
);

select extensions.is(
  (
    select progress_percentage
    from public.program_scores
    where enrollment_id =
      '97000000-0000-0000-0000-000000000001'
  ),
  100,
  'passed quiz completes the second program step'
);

select extensions.is(
  (
    select count(*)::bigint
    from public.program_answer_keys
  ),
  0::bigint,
  'Participant still cannot read answer keys after quiz scoring'
);

set local "request.jwt.claims" =
  '{"sub":"91000000-0000-0000-0000-000000000002","role":"authenticated"}';

select extensions.is(
  (
    select count(*)::bigint
    from public.program_answer_keys
  ),
  1::bigint,
  'assigned Coach can read answer-key context'
);

reset role;

insert into storage.objects (
  bucket_id,
  name,
  metadata,
  created_at
)
values (
  'question-photos',
  '91000000-0000-0000-0000-000000000011/'
    || '97000000-0000-0000-0000-000000000001/'
    || (
      select id::text
      from public.step_submissions
      where idempotency_key = 'form-request-0001'
    )
    || '/95000000-0000-0000-0000-000000000004/'
    || '98000000-0000-0000-0000-000000000099.jpg',
  '{"mimetype":"image/jpeg"}',
  statement_timestamp() - interval '2 days'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"91000000-0000-0000-0000-000000000011","role":"authenticated"}';

select extensions.throws_like(
  $$
    select public.list_orphan_question_photos()
  $$,
  '%permission_denied%',
  'Participant cannot enumerate orphan private media'
);

set local "request.jwt.claims" =
  '{"sub":"91000000-0000-0000-0000-000000000001","role":"authenticated"}';

select extensions.is(
  (
    select count(*)::bigint
    from public.list_orphan_question_photos()
  ),
  1::bigint,
  'Admin cleanup worker receives only old unreferenced candidates'
);

select extensions.lives_ok(
  $$
    select public.record_orphan_question_photo_cleanup(
      array[
        'private/object/name-that-must-not-be-logged.jpg'
      ],
      'Pembersihan terjadwal lokal'
    )
  $$,
  'Admin records a successful Storage API cleanup audit'
);

select extensions.is(
  (
    select payload ? 'object_names'
    from public.audit_events
    where kind = 'question_photo_orphans_cleaned'
  ),
  false,
  'cleanup audit stores hashes and count rather than private object paths'
);

select extensions.is(
  (
    select (payload ->> 'deleted_count')::integer
    from public.audit_events
    where kind = 'question_photo_orphans_cleaned'
  ),
  1,
  'cleanup audit records the number of deleted objects'
);

select * from extensions.finish();
rollback;
