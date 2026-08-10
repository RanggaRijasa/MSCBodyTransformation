begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(13);

insert into auth.users(
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('d7000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'p7-ops-admin@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('d7000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'p7-ops-participant@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('d7000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'p7-ops-coach@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());

update public.profiles
set role = 'admin', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null
where user_id = 'd7000000-0000-4000-8000-000000000001';
update public.profiles
set role = 'participant', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null
where user_id = 'd7000000-0000-4000-8000-000000000002';
update public.profiles
set role = 'coach', coach_is_approved = true, onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null
where user_id = 'd7000000-0000-4000-8000-000000000003';

insert into public.programs(
  id, title, status, pace, duration_mode, starts_on, ends_on, timezone,
  past_step_policy, future_step_policy, wellness_disclaimer,
  points_per_activity, points_per_weight_kg, quiz_passing_percentage,
  pricing_mode, created_by, published_at
) values (
  'd7100000-0000-4000-8000-000000000001', 'Program Operasi Phase 07',
  'active', 'scheduled', 'fixed_duration', current_date, current_date,
  'UTC', 'available', 'locked', 'Program kebugaran non-diagnostik.',
  10, 100, 70, 'free', 'd7000000-0000-4000-8000-000000000001', now()
);
insert into public.program_days(id, program_id, day_number, title, scheduled_on)
values (
  'd7200000-0000-4000-8000-000000000001',
  'd7100000-0000-4000-8000-000000000001', 1, 'Hari operasi', current_date
);
insert into public.program_steps(
  id, program_day_id, step_order, title, content_kind,
  completion_policy, verification_mode
) values
  ('d7300000-0000-4000-8000-000000000001', 'd7200000-0000-4000-8000-000000000001', 1, 'Timbang awal', 'initial_weigh_in', 'submit_weigh_in', 'automatic'),
  ('d7300000-0000-4000-8000-000000000002', 'd7200000-0000-4000-8000-000000000001', 2, 'Timbang harian', 'daily_weigh_in', 'submit_weigh_in', 'automatic'),
  ('d7300000-0000-4000-8000-000000000003', 'd7200000-0000-4000-8000-000000000001', 3, 'Timbang akhir', 'final_weigh_in', 'submit_weigh_in', 'automatic'),
  ('d7300000-0000-4000-8000-000000000004', 'd7200000-0000-4000-8000-000000000001', 4, 'Kuis', 'quiz', 'automatic_quiz', 'automatic');
insert into public.program_questions(id, step_id, question_order, kind, prompt)
values (
  'd7400000-0000-4000-8000-000000000001',
  'd7300000-0000-4000-8000-000000000004', 1, 'short_answer', 'Jawaban benar?'
);
insert into public.program_answer_keys(question_id, accepted_text_values)
values ('d7400000-0000-4000-8000-000000000001', array['ya']);
insert into public.program_enrollments(id, program_id, participant_id, coach_id, status)
values (
  'd7500000-0000-4000-8000-000000000001',
  'd7100000-0000-4000-8000-000000000001',
  'd7000000-0000-4000-8000-000000000002',
  'd7000000-0000-4000-8000-000000000003', 'active'
);
insert into public.program_scores(enrollment_id)
values ('d7500000-0000-4000-8000-000000000001');

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"d7000000-0000-4000-8000-000000000002","role":"authenticated"}';

select extensions.throws_like(
  $$ select public.submit_weigh_in(
    'd7500000-0000-4000-8000-000000000001',
    'd7300000-0000-4000-8000-000000000003', 'final', 75,
    'phase07-final-before-initial'
  ) $$,
  'initial_weight_required', 'final requires an initial weigh-in'
);
select extensions.lives_ok(
  $$ select public.submit_weigh_in(
    'd7500000-0000-4000-8000-000000000001',
    'd7300000-0000-4000-8000-000000000001', 'initial', 70,
    'phase07-initial-once'
  ) $$,
  'initial weigh-in succeeds'
);
select extensions.lives_ok(
  $$ select public.submit_weigh_in(
    'd7500000-0000-4000-8000-000000000001',
    'd7300000-0000-4000-8000-000000000001', 'initial', 70,
    'phase07-initial-once'
  ) $$,
  'initial weigh-in retry is idempotent'
);
select extensions.is(
  (select count(*)::bigint from public.weigh_ins
    where enrollment_id = 'd7500000-0000-4000-8000-000000000001'
      and kind = 'initial'),
  1::bigint, 'initial retry creates one row'
);
select extensions.lives_ok(
  $$ select public.submit_weigh_in(
    'd7500000-0000-4000-8000-000000000001',
    'd7300000-0000-4000-8000-000000000002', 'daily', 71,
    'phase07-daily-once'
  ) $$,
  'daily weigh-in succeeds'
);
select extensions.lives_ok(
  $$ select public.submit_weigh_in(
    'd7500000-0000-4000-8000-000000000001',
    'd7300000-0000-4000-8000-000000000002', 'daily', 71,
    'phase07-daily-once'
  ) $$,
  'daily weigh-in retry is idempotent'
);
select extensions.is(
  (select count(*)::bigint from public.weigh_ins
    where enrollment_id = 'd7500000-0000-4000-8000-000000000001'
      and kind = 'daily'),
  1::bigint, 'daily retry creates one row'
);
select extensions.lives_ok(
  $$ select public.submit_weigh_in(
    'd7500000-0000-4000-8000-000000000001',
    'd7300000-0000-4000-8000-000000000003', 'final', 75,
    'phase07-final-weight-gain'
  ) $$,
  'final weigh-in succeeds after initial'
);
select extensions.is(
  (select weight_points from public.program_scores
    where enrollment_id = 'd7500000-0000-4000-8000-000000000001'),
  0, 'weight gain cannot produce negative points'
);
select extensions.lives_ok(
  $$ select public.prepare_step_submission(
    'd7500000-0000-4000-8000-000000000001',
    'd7300000-0000-4000-8000-000000000004', 'phase07-failed-quiz'
  ) $$,
  'quiz attempt can be prepared once'
);
select extensions.lives_ok(
  $$ select public.submit_step_answers(
    (select id from public.step_submissions
      where enrollment_id = 'd7500000-0000-4000-8000-000000000001'
        and idempotency_key = 'phase07-failed-quiz'),
    jsonb_build_array(jsonb_build_object(
      'question_id', 'd7400000-0000-4000-8000-000000000001',
      'text_value', 'tidak', 'selected_option_ids', jsonb_build_array()
    )),
    'phase07-failed-quiz'
  ) $$,
  'wrong quiz answer is scored authoritatively'
);
select extensions.is(
  (select passed from public.quiz_attempt_results result
    join public.step_submissions submission on submission.id = result.submission_id
    where submission.enrollment_id = 'd7500000-0000-4000-8000-000000000001'),
  false, 'failed quiz result remains private and records not passed'
);
select extensions.throws_like(
  $$ select public.prepare_step_submission(
    'd7500000-0000-4000-8000-000000000001',
    'd7300000-0000-4000-8000-000000000004', 'phase07-second-quiz-attempt'
  ) $$,
  'submission_already_finalized', 'quiz permits only one finalized attempt'
);

select * from extensions.finish();
rollback;
