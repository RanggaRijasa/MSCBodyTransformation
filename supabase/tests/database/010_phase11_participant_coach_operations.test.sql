begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(27);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('f1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'ops-admin@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('f1000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'ops-coach-active@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('f1000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'ops-coach-expired@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('f1000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 'ops-participant-one@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('f1000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated', 'ops-participant-two@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());

update public.profiles set role = 'admin', display_name = 'Admin Operations',
  onboarding_status = 'active', provisional_expires_at = null, finalized_at = now()
where user_id = 'f1000000-0000-0000-0000-000000000001';
update public.profiles set role = 'coach', coach_is_approved = true,
  coach_qr_identifier = case user_id
    when 'f1000000-0000-0000-0000-000000000002' then 'coach_active_phase11_qr'
    else 'coach_expired_phase11_qr' end,
  display_name = case user_id
    when 'f1000000-0000-0000-0000-000000000002' then 'Coach Aktif'
    else 'Coach Kedaluwarsa' end,
  onboarding_status = 'active', provisional_expires_at = null, finalized_at = now()
where user_id in ('f1000000-0000-0000-0000-000000000002', 'f1000000-0000-0000-0000-000000000003');
update public.profiles set display_name = case user_id
    when 'f1000000-0000-0000-0000-000000000011' then 'Peserta Operasi Satu'
    else 'Peserta Operasi Dua' end,
  onboarding_status = 'active', provisional_expires_at = null, finalized_at = now()
where user_id in ('f1000000-0000-0000-0000-000000000011', 'f1000000-0000-0000-0000-000000000012');

insert into public.coach_applications(
  id, applicant_user_id, participant_profile_id, display_name_snapshot,
  phone_number_snapshot, member_level_snapshot, has_completed_hom_sts,
  has_completed_ict, terms_version, status, draft_idempotency_key,
  submitted_at, decided_at, decided_by
)
values
  ('f2000000-0000-0000-0000-000000000002', 'f1000000-0000-0000-0000-000000000002', 'f1000000-0000-0000-0000-000000000002', 'Coach Aktif', '+628400000002', 'sc', true, true, 'test-v1', 'active', 'ops-coach-active', now(), now(), 'f1000000-0000-0000-0000-000000000001'),
  ('f2000000-0000-0000-0000-000000000003', 'f1000000-0000-0000-0000-000000000003', 'f1000000-0000-0000-0000-000000000003', 'Coach Kedaluwarsa', '+628400000003', 'sc', true, true, 'test-v1', 'expired', 'ops-coach-expired', now(), now(), 'f1000000-0000-0000-0000-000000000001');
insert into public.coach_payment_records(
  id, application_id, state, price_band, amount_minor_units,
  provider_reference, verified_at
)
values
  ('f3000000-0000-0000-0000-000000000002', 'f2000000-0000-0000-0000-000000000002', 'verified', 'entry', 100000, 'ops-active', now()),
  ('f3000000-0000-0000-0000-000000000003', 'f2000000-0000-0000-0000-000000000003', 'verified', 'entry', 100000, 'ops-expired', now());
insert into public.coach_access_entitlements(
  id, application_id, payment_record_id, coach_user_id, status,
  starts_at, ends_at
)
values
  ('f4000000-0000-0000-0000-000000000002', 'f2000000-0000-0000-0000-000000000002', 'f3000000-0000-0000-0000-000000000002', 'f1000000-0000-0000-0000-000000000002', 'active', now() - interval '1 day', now() + interval '30 days'),
  ('f4000000-0000-0000-0000-000000000003', 'f2000000-0000-0000-0000-000000000003', 'f3000000-0000-0000-0000-000000000003', 'f1000000-0000-0000-0000-000000000003', 'expired', now() - interval '30 days', now() - interval '1 day');

insert into public.programs(
  id, title, status, pace, duration_mode, starts_on, ends_on, timezone,
  participant_limit, past_step_policy, future_step_policy,
  wellness_disclaimer, points_per_activity, points_per_weight_kg,
  quiz_passing_percentage, pricing_mode, created_by, published_at
)
values (
  'f5000000-0000-0000-0000-000000000001', 'Program Operasi Phase 11',
  'active', 'scheduled', 'specific_dates', current_date, current_date,
  'UTC', 10, 'available', 'locked', 'Program kebugaran non-diagnostik.',
  10, 100, 70, 'free', 'f1000000-0000-0000-0000-000000000001', now()
);
insert into public.program_days(id, program_id, day_number, title, scheduled_on)
values ('f6000000-0000-0000-0000-000000000001', 'f5000000-0000-0000-0000-000000000001', 1, 'Hari Operasi', current_date);
insert into public.program_steps(
  id, program_day_id, step_order, title, content_kind,
  completion_policy, verification_mode
)
values
  ('f7000000-0000-0000-0000-000000000001', 'f6000000-0000-0000-0000-000000000001', 1, 'Artikel', 'article', 'mark_complete', 'automatic'),
  ('f7000000-0000-0000-0000-000000000002', 'f6000000-0000-0000-0000-000000000001', 2, 'Kuis', 'quiz', 'automatic_quiz', 'automatic'),
  ('f7000000-0000-0000-0000-000000000003', 'f6000000-0000-0000-0000-000000000001', 3, 'Timbang awal', 'initial_weigh_in', 'submit_weigh_in', 'automatic'),
  ('f7000000-0000-0000-0000-000000000004', 'f6000000-0000-0000-0000-000000000001', 4, 'Timbang akhir', 'final_weigh_in', 'submit_weigh_in', 'automatic');
insert into public.program_questions(id, step_id, question_order, kind, prompt)
values ('f8000000-0000-0000-0000-000000000001', 'f7000000-0000-0000-0000-000000000002', 1, 'short_answer', 'Jawaban benar?');
insert into public.program_answer_keys(question_id, accepted_text_values)
values ('f8000000-0000-0000-0000-000000000001', array['ya']);

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"f1000000-0000-0000-0000-000000000011","role":"authenticated"}';

select extensions.is(
  (select public.resolve_coach_qr_for_enrollment(
    'coach_active_phase11_qr'
  ) ->> 'display_name'),
  'Coach Aktif',
  'Participant resolves an opaque QR through the authenticated server boundary'
);
select extensions.throws_like(
  $$ select public.resolve_coach_qr_for_enrollment('qr-tidak-valid') $$,
  'coach_qr_invalid',
  'invalid Coach QR is rejected without exposing the directory secret'
);

select extensions.lives_ok(
  $$ select public.enroll_free_program(
    'f5000000-0000-0000-0000-000000000001', 'coach_active_phase11_qr'
  ) $$,
  'Participant can enroll with an active entitled Coach'
);
select extensions.is(
  (select count(*)::bigint from public.program_enrollments), 1::bigint,
  'free enrollment creates one enrollment'
);
select extensions.is(
  (select count(*)::bigint from public.program_scores), 1::bigint,
  'free enrollment atomically creates a score row'
);
select extensions.lives_ok(
  $$ select public.enroll_free_program(
    'f5000000-0000-0000-0000-000000000001', 'coach_active_phase11_qr'
  ) $$,
  'duplicate enrollment is idempotent'
);
select extensions.is(
  (select count(*)::bigint from public.program_enrollments), 1::bigint,
  'duplicate enrollment does not create another row'
);

select extensions.throws_like(
  $$ select public.submit_weigh_in(
    (select id from public.program_enrollments limit 1),
    'f7000000-0000-0000-0000-000000000004', 'final', 75,
    'weigh-final-before-initial'
  ) $$,
  'initial_weight_required',
  'final weigh-in is rejected before initial weigh-in'
);
select extensions.lives_ok(
  $$ select public.submit_weigh_in(
    (select id from public.program_enrollments limit 1),
    'f7000000-0000-0000-0000-000000000003', 'initial', 70,
    'weigh-initial-phase11'
  ) $$,
  'initial weigh-in succeeds'
);
select extensions.lives_ok(
  $$ select public.submit_weigh_in(
    (select id from public.program_enrollments limit 1),
    'f7000000-0000-0000-0000-000000000003', 'initial', 70,
    'weigh-initial-phase11'
  ) $$,
  'initial weigh-in retry is idempotent'
);
select extensions.is(
  (select count(*)::bigint from public.weigh_ins), 1::bigint,
  'weigh-in retry does not duplicate data'
);
select extensions.lives_ok(
  $$ select public.submit_weigh_in(
    (select id from public.program_enrollments limit 1),
    'f7000000-0000-0000-0000-000000000004', 'final', 75,
    'weigh-final-phase11'
  ) $$,
  'final weigh-in succeeds after initial weigh-in'
);
select extensions.is(
  (select weight_points from public.program_scores limit 1), 0,
  'weight gain produces zero weight points'
);

select extensions.lives_ok(
  $$ select public.prepare_step_submission(
    (select id from public.program_enrollments limit 1),
    'f7000000-0000-0000-0000-000000000002', 'quiz-prepare-phase11'
  ) $$,
  'Participant can prepare a quiz attempt'
);
select extensions.lives_ok(
  $$ select public.submit_step_answers(
    (select id from public.step_submissions where idempotency_key = 'quiz-prepare-phase11'),
    jsonb_build_array(jsonb_build_object(
      'question_id', 'f8000000-0000-0000-0000-000000000001',
      'text_value', 'ya', 'selected_option_ids', jsonb_build_array()
    )),
    'quiz-prepare-phase11'
  ) $$,
  'quiz is scored from the protected answer key'
);
select extensions.is(
  (select correct_count from public.quiz_attempt_results limit 1), 1,
  'quiz stores the authoritative correct count'
);
select extensions.is(
  (select quiz_points from public.program_scores limit 1), 10,
  'quiz points are reconciled server-side'
);

set local "request.jwt.claims" = '{"sub":"f1000000-0000-0000-0000-000000000003","role":"authenticated"}';
select extensions.throws_like(
  $$ select * from public.list_my_assigned_participants() $$,
  'coach_entitlement_inactive',
  'expired Coach cannot use protected roster operation'
);

set local "request.jwt.claims" = '{"sub":"f1000000-0000-0000-0000-000000000002","role":"authenticated"}';
select extensions.is(
  (select count(*)::bigint from public.list_my_assigned_participants()),
  1::bigint,
  'active Coach sees exactly the assigned Participant'
);

set local "request.jwt.claims" = '{"sub":"f1000000-0000-0000-0000-000000000001","role":"authenticated"}';
select extensions.lives_ok(
  $$ select public.reopen_quiz_attempt(
    (select id from public.program_enrollments limit 1),
    'f7000000-0000-0000-0000-000000000002',
    'Percobaan baru disetujui.', 'quiz-reopen-phase11'
  ) $$,
  'Admin can reopen a quiz attempt with a reason'
);
select extensions.lives_ok(
  $$ select public.reopen_quiz_attempt(
    (select id from public.program_enrollments limit 1),
    'f7000000-0000-0000-0000-000000000002',
    'Percobaan baru disetujui.', 'quiz-reopen-phase11'
  ) $$,
  'quiz reopen retry is idempotent'
);
select extensions.is(
  (select quiz_points from public.program_scores limit 1), 0,
  'reopening removes the previous attempt points until resubmission'
);
select extensions.is(
  (select count(*)::bigint from public.audit_events
   where kind = 'quiz_attempt_reopened'), 1::bigint,
  'quiz reopen writes one audit event'
);

select extensions.lives_ok(
  $$ select public.admin_adjust_score(
    (select id from public.program_enrollments limit 1), 7,
    'Koreksi hasil pemeriksaan.', 'score-adjust-phase11'
  ) $$,
  'Admin can add an audited score adjustment'
);
select extensions.lives_ok(
  $$ select public.admin_adjust_score(
    (select id from public.program_enrollments limit 1), 7,
    'Koreksi hasil pemeriksaan.', 'score-adjust-phase11'
  ) $$,
  'score adjustment retry is idempotent'
);
select extensions.is(
  (select adjustment_points from public.program_scores limit 1), 7,
  'adjustment remains a separate score component'
);
reset role;
select extensions.is(
  (select count(*)::bigint from public.score_adjustments), 1::bigint,
  'idempotent score adjustment creates one row'
);

select * from extensions.finish();
rollback;
