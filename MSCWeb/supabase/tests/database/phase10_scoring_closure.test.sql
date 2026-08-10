begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(40);

insert into auth.users(
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('fa000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'p10-admin@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('fa000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'p10-one@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('fa000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'p10-two@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('fa000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', 'p10-coach@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());

update public.profiles
set onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null,
  display_name = case user_id
    when 'fa000000-0000-4000-8000-000000000001' then 'Admin Phase 10'
    when 'fa000000-0000-4000-8000-000000000002' then 'Peserta Alfa'
    when 'fa000000-0000-4000-8000-000000000003' then 'Peserta Beta'
    else 'Coach Phase 10' end,
  role = case
    when user_id = 'fa000000-0000-4000-8000-000000000001' then 'admin'
    when user_id = 'fa000000-0000-4000-8000-000000000004' then 'coach'
    else 'participant' end
where user_id in (
  'fa000000-0000-4000-8000-000000000001',
  'fa000000-0000-4000-8000-000000000002',
  'fa000000-0000-4000-8000-000000000003',
  'fa000000-0000-4000-8000-000000000004'
);

insert into public.programs(
  id, title, summary, status, pace, duration_mode, starts_on, ends_on,
  timezone, past_step_policy, future_step_policy, wellness_disclaimer,
  points_per_activity, points_per_weight_kg, quiz_passing_percentage,
  pricing_mode, desired_price, created_by, published_at
) values
  ('fa100000-0000-4000-8000-000000000001', 'Program Closure Phase 10',
    'Fixture scoring lengkap.', 'active', 'scheduled', 'fixed_duration',
    current_date, current_date, 'Asia/Makassar', 'available', 'locked',
    'Program kebugaran non-diagnostik.', 10, 100, 70, 'free', null,
    'fa000000-0000-4000-8000-000000000001', now()),
  ('fa100000-0000-4000-8000-000000000002', 'Program Quiz Remediasi',
    'Fixture kuis gagal.', 'active', 'scheduled', 'fixed_duration',
    current_date, current_date, 'Asia/Makassar', 'available', 'locked',
    'Program kebugaran non-diagnostik.', 10, 0, 70, 'free', null,
    'fa000000-0000-4000-8000-000000000001', now()),
  ('fa100000-0000-4000-8000-000000000003', 'Program Berbayar Phase 10',
    'Fixture manual commerce.', 'draft', 'scheduled', 'fixed_duration',
    current_date, current_date, 'Asia/Makassar', 'available', 'locked',
    'Program kebugaran non-diagnostik.', 10, 0, 70, 'paid', 150000,
    'fa000000-0000-4000-8000-000000000001', null);

insert into public.payment_destinations(
  id, version, status, bank_code, bank_name, account_name,
  account_reference, effective_from, created_by
) values (
  'fa600000-0000-4000-8000-000000000001', 1010, 'active', 'BCA',
  'Bank Central Asia', 'MSC Lokal Phase 10', '1010101010', now(),
  'fa000000-0000-4000-8000-000000000001'
);

insert into public.program_days(id, program_id, day_number, title, scheduled_on)
values
  ('fa110000-0000-4000-8000-000000000001', 'fa100000-0000-4000-8000-000000000001', 1, 'Hari lengkap', current_date),
  ('fa110000-0000-4000-8000-000000000002', 'fa100000-0000-4000-8000-000000000002', 1, 'Hari kuis', current_date),
  ('fa110000-0000-4000-8000-000000000003', 'fa100000-0000-4000-8000-000000000003', 1, 'Hari berbayar', current_date);

insert into public.program_steps(
  id, program_day_id, step_order, title, content_kind,
  completion_policy, verification_mode
) values
  ('fa120000-0000-4000-8000-000000000001', 'fa110000-0000-4000-8000-000000000001', 1, 'Artikel', 'article', 'mark_complete', 'automatic'),
  ('fa120000-0000-4000-8000-000000000002', 'fa110000-0000-4000-8000-000000000001', 2, 'Kuis', 'quiz', 'automatic_quiz', 'automatic'),
  ('fa120000-0000-4000-8000-000000000003', 'fa110000-0000-4000-8000-000000000001', 3, 'Timbang awal', 'initial_weigh_in', 'submit_weigh_in', 'automatic'),
  ('fa120000-0000-4000-8000-000000000004', 'fa110000-0000-4000-8000-000000000001', 4, 'Timbang harian', 'daily_weigh_in', 'submit_weigh_in', 'automatic'),
  ('fa120000-0000-4000-8000-000000000005', 'fa110000-0000-4000-8000-000000000001', 5, 'Timbang akhir', 'final_weigh_in', 'submit_weigh_in', 'automatic'),
  ('fa120000-0000-4000-8000-000000000006', 'fa110000-0000-4000-8000-000000000002', 1, 'Kuis ulang', 'quiz', 'automatic_quiz', 'automatic'),
  ('fa120000-0000-4000-8000-000000000007', 'fa110000-0000-4000-8000-000000000003', 1, 'Artikel berbayar', 'article', 'mark_complete', 'automatic');

insert into public.program_enrollments(
  id, program_id, participant_id, coach_id, status
) values
  ('fa200000-0000-4000-8000-000000000001', 'fa100000-0000-4000-8000-000000000001', 'fa000000-0000-4000-8000-000000000002', 'fa000000-0000-4000-8000-000000000004', 'active'),
  ('fa200000-0000-4000-8000-000000000002', 'fa100000-0000-4000-8000-000000000001', 'fa000000-0000-4000-8000-000000000003', 'fa000000-0000-4000-8000-000000000004', 'active'),
  ('fa200000-0000-4000-8000-000000000003', 'fa100000-0000-4000-8000-000000000002', 'fa000000-0000-4000-8000-000000000002', 'fa000000-0000-4000-8000-000000000004', 'active');

insert into public.program_scores(enrollment_id)
values
  ('fa200000-0000-4000-8000-000000000001'),
  ('fa200000-0000-4000-8000-000000000002'),
  ('fa200000-0000-4000-8000-000000000003');

insert into public.step_submissions(
  id, enrollment_id, step_id, attempt_sequence, status,
  submitted_at, finalized_at, idempotency_key
) values
  ('fa300000-0000-4000-8000-000000000001', 'fa200000-0000-4000-8000-000000000001', 'fa120000-0000-4000-8000-000000000001', 1, 'approved', now(), now(), 'phase10-a-article'),
  ('fa300000-0000-4000-8000-000000000002', 'fa200000-0000-4000-8000-000000000001', 'fa120000-0000-4000-8000-000000000002', 1, 'approved', now(), now(), 'phase10-a-quiz'),
  ('fa300000-0000-4000-8000-000000000003', 'fa200000-0000-4000-8000-000000000002', 'fa120000-0000-4000-8000-000000000001', 1, 'approved', now(), now(), 'phase10-b-article'),
  ('fa300000-0000-4000-8000-000000000004', 'fa200000-0000-4000-8000-000000000002', 'fa120000-0000-4000-8000-000000000002', 1, 'approved', now(), now(), 'phase10-b-quiz'),
  ('fa300000-0000-4000-8000-000000000005', 'fa200000-0000-4000-8000-000000000003', 'fa120000-0000-4000-8000-000000000006', 1, 'approved', now(), now(), 'phase10-failed-quiz');

insert into public.quiz_attempt_results(
  id, submission_id, correct_count, total_count, percentage, passed, awarded_points
) values
  ('fa310000-0000-4000-8000-000000000001', 'fa300000-0000-4000-8000-000000000002', 2, 2, 100, true, 20),
  ('fa310000-0000-4000-8000-000000000002', 'fa300000-0000-4000-8000-000000000004', 2, 2, 100, true, 20),
  ('fa310000-0000-4000-8000-000000000003', 'fa300000-0000-4000-8000-000000000005', 0, 1, 0, false, 0);

insert into public.weigh_ins(
  id, enrollment_id, step_id, kind, weight_kg, idempotency_key
) values
  ('fa400000-0000-4000-8000-000000000001', 'fa200000-0000-4000-8000-000000000001', 'fa120000-0000-4000-8000-000000000003', 'initial', 80, 'phase10-a-initial'),
  ('fa400000-0000-4000-8000-000000000002', 'fa200000-0000-4000-8000-000000000001', 'fa120000-0000-4000-8000-000000000004', 'daily', 60, 'phase10-a-daily'),
  ('fa400000-0000-4000-8000-000000000003', 'fa200000-0000-4000-8000-000000000001', 'fa120000-0000-4000-8000-000000000005', 'final', 79.5, 'phase10-a-final'),
  ('fa400000-0000-4000-8000-000000000004', 'fa200000-0000-4000-8000-000000000002', 'fa120000-0000-4000-8000-000000000003', 'initial', 80, 'phase10-b-initial'),
  ('fa400000-0000-4000-8000-000000000005', 'fa200000-0000-4000-8000-000000000002', 'fa120000-0000-4000-8000-000000000004', 'daily', 90, 'phase10-b-daily'),
  ('fa400000-0000-4000-8000-000000000006', 'fa200000-0000-4000-8000-000000000002', 'fa120000-0000-4000-8000-000000000005', 'final', 79.5, 'phase10-b-final');

insert into public.score_adjustments(
  id, enrollment_id, points, reason, actor_id, idempotency_key
) values
  ('fa500000-0000-4000-8000-000000000001', 'fa200000-0000-4000-8000-000000000001', 5, 'Fixture tie.', 'fa000000-0000-4000-8000-000000000001', 'phase10-a-adjust'),
  ('fa500000-0000-4000-8000-000000000002', 'fa200000-0000-4000-8000-000000000002', 5, 'Fixture tie.', 'fa000000-0000-4000-8000-000000000001', 'phase10-b-adjust');

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"fa000000-0000-4000-8000-000000000002","role":"authenticated"}';

select extensions.throws_like(
  $$ select public.get_program_closure_preflight('fa100000-0000-4000-8000-000000000001') $$,
  'permission_denied', 'Participant cannot read Admin closure preflight'
);
select extensions.throws_like(
  $$ select public.reopen_program('fa100000-0000-4000-8000-000000000001', 'Tidak berwenang.', 'phase10-user-reopen') $$,
  'permission_denied', 'Participant cannot reopen a program'
);

reset role;
select extensions.throws_like(
  $$ update public.programs set points_per_activity = 11 where id = 'fa100000-0000-4000-8000-000000000001' $$,
  'scoring_configuration_locked', 'scoring configuration is locked after enrollment'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"fa000000-0000-4000-8000-000000000001","role":"authenticated"}';

select extensions.lives_ok(
  $$ select public.publish_program('fa100000-0000-4000-8000-000000000003', 'phase10-publish-paid') $$,
  'Admin publishes a valid paid program through manual commerce'
);
select extensions.is(
  (select status from public.programs where id = 'fa100000-0000-4000-8000-000000000003'),
  'active', 'paid program becomes active on its local start date'
);

select extensions.lives_ok(
  $$ select public.refresh_enrollment_score('fa200000-0000-4000-8000-000000000001') $$,
  'Admin reconciles first score'
);
select extensions.lives_ok(
  $$ select public.refresh_enrollment_score('fa200000-0000-4000-8000-000000000002') $$,
  'Admin reconciles second score'
);
select extensions.is((select activity_points from public.program_scores where enrollment_id = 'fa200000-0000-4000-8000-000000000001'), 10, 'approved article earns activity points once');
select extensions.is((select quiz_points from public.program_scores where enrollment_id = 'fa200000-0000-4000-8000-000000000001'), 20, 'quiz points equal correct answers times program points');
select extensions.is((select weight_points from public.program_scores where enrollment_id = 'fa200000-0000-4000-8000-000000000001'), 50, 'weight points use decimal initial minus final');
select extensions.is((select weight_points from public.program_scores where enrollment_id = 'fa200000-0000-4000-8000-000000000002'), 50, 'daily weight never changes weight points');
select extensions.is((select adjustment_points from public.program_scores where enrollment_id = 'fa200000-0000-4000-8000-000000000001'), 5, 'adjustment remains a separate component');
select extensions.is((select progress_percentage from public.program_scores where enrollment_id = 'fa200000-0000-4000-8000-000000000001'), 100, 'all required content yields full progress');
select extensions.is((select rank from public.program_scores where enrollment_id = 'fa200000-0000-4000-8000-000000000001'), 1, 'equal score tie uses lower enrollment UUID first');
select extensions.is((select rank from public.program_scores where enrollment_id = 'fa200000-0000-4000-8000-000000000002'), 2, 'equal score tie gives deterministic next rank');
select extensions.is((select (entry ->> 'participant_display_name') from public.list_public_leaderboard('fa100000-0000-4000-8000-000000000001', 1, 0) entry), 'Peserta Alfa', 'public leaderboard order is stable');
select extensions.is((select (entry ->> 'participant_display_name') from public.list_public_leaderboard('fa100000-0000-4000-8000-000000000001', 1, 1) entry), 'Peserta Beta', 'public leaderboard pagination is stable');
select extensions.ok(not exists(select 1 from public.list_public_leaderboard('fa100000-0000-4000-8000-000000000001', 5, 0) entry where entry ?| array['weight_kg','phone_number','private_photo_path','payment_status']), 'public leaderboard excludes private fields');
select extensions.is((public.get_program_closure_preflight('fa100000-0000-4000-8000-000000000001') ->> 'can_complete')::boolean, true, 'ready program passes closure preflight');
select extensions.is((public.get_program_closure_preflight('fa100000-0000-4000-8000-000000000002') ->> 'failed_quiz_attempts')::integer, 1, 'preflight exposes failed quiz count');
select extensions.is((public.get_program_closure_preflight('fa100000-0000-4000-8000-000000000002') ->> 'can_complete')::boolean, false, 'failed quiz blocks closure');

set local "request.jwt.claims" =
  '{"sub":"fa000000-0000-4000-8000-000000000004","role":"authenticated"}';
select extensions.throws_like(
  $$ select public.reopen_quiz_attempt('fa200000-0000-4000-8000-000000000003', 'fa120000-0000-4000-8000-000000000006', 'Coach tidak boleh.', 'phase10-coach-quiz') $$,
  'permission_denied', 'Coach cannot reopen a quiz attempt'
);

set local "request.jwt.claims" =
  '{"sub":"fa000000-0000-4000-8000-000000000001","role":"authenticated"}';
select extensions.lives_ok(
  $$ select public.reopen_quiz_attempt('fa200000-0000-4000-8000-000000000003', 'fa120000-0000-4000-8000-000000000006', 'Berikan satu kesempatan remediasi.', 'phase10-admin-quiz') $$,
  'Admin reopens failed quiz with a reason'
);
select extensions.lives_ok(
  $$ select public.reopen_quiz_attempt('fa200000-0000-4000-8000-000000000003', 'fa120000-0000-4000-8000-000000000006', 'Berikan satu kesempatan remediasi.', 'phase10-admin-quiz') $$,
  'quiz reopen replay is idempotent'
);
select extensions.is((select status from public.step_submissions where id = 'fa300000-0000-4000-8000-000000000005'), 'rejected', 'reopened attempt remains in immutable history');
select extensions.is((select count(*)::bigint from public.audit_events where kind = 'quiz_attempt_reopened' and subject_id = 'fa310000-0000-4000-8000-000000000003'), 1::bigint, 'quiz reopen audit is exactly once');

select extensions.lives_ok(
  $$ select public.complete_program('fa100000-0000-4000-8000-000000000001', 'Seluruh prasyarat selesai.', 'phase10-complete-one') $$,
  'Admin completes a ready program'
);
select extensions.lives_ok(
  $$ select public.complete_program('fa100000-0000-4000-8000-000000000001', 'Seluruh prasyarat selesai.', 'phase10-complete-one') $$,
  'program completion replay is idempotent'
);
select extensions.throws_like(
  $$ select public.admin_adjust_score('fa200000-0000-4000-8000-000000000001', 1, 'Tidak boleh setelah tutup.', 'phase10-closed-adjust') $$,
  'program_closed', 'score mutation is denied after closure'
);
select extensions.throws_like(
  $$ select public.admin_correct_weigh_in('fa400000-0000-4000-8000-000000000003', 79.4, 'Tidak boleh setelah tutup.', 'phase10-closed-weigh') $$,
  'program_closed', 'weigh-in mutation is denied after closure'
);
select extensions.is((public.get_program_closure_preflight('fa100000-0000-4000-8000-000000000001') ->> 'can_reopen')::boolean, true, 'completed program may reopen before winner lock');
select extensions.lives_ok(
  $$ select public.reopen_program('fa100000-0000-4000-8000-000000000001', 'Perlu koreksi sebelum penguncian.', 'phase10-reopen-one') $$,
  'Admin reopens before winner lock'
);
select extensions.lives_ok(
  $$ select public.reopen_program('fa100000-0000-4000-8000-000000000001', 'Perlu koreksi sebelum penguncian.', 'phase10-reopen-one') $$,
  'program reopen replay is idempotent'
);
select extensions.lives_ok(
  $$ select public.complete_program('fa100000-0000-4000-8000-000000000001', 'Program siap dikunci.', 'phase10-complete-two') $$,
  'reopened program can complete again'
);
select extensions.lives_ok(
  $$ select public.lock_program_winners('fa100000-0000-4000-8000-000000000001', 'phase10-lock-winners') $$,
  'Admin locks winners once'
);
select extensions.lives_ok(
  $$ select public.lock_program_winners('fa100000-0000-4000-8000-000000000001', 'phase10-lock-winners') $$,
  'winner lock replay returns the same snapshot'
);
select extensions.is((select count(*)::integer from public.program_winners winner join public.winner_snapshots snapshot on snapshot.id = winner.snapshot_id where snapshot.program_id = 'fa100000-0000-4000-8000-000000000001'), 2, 'fewer than five eligible participants creates fewer winners');
select extensions.is((select participant_id from public.program_winners winner join public.winner_snapshots snapshot on snapshot.id = winner.snapshot_id where snapshot.program_id = 'fa100000-0000-4000-8000-000000000001' and winner.rank = 1), 'fa000000-0000-4000-8000-000000000002'::uuid, 'winner tie policy matches stable leaderboard order');
select extensions.throws_like(
  $$ select public.reopen_program('fa100000-0000-4000-8000-000000000001', 'Snapshot sudah ada.', 'phase10-reopen-locked') $$,
  'winners_already_locked', 'program cannot reopen after immutable winner lock'
);
select extensions.is((select count(*)::bigint from public.audit_events where kind = 'winners_locked' and payload ->> 'program_id' = 'fa100000-0000-4000-8000-000000000001'), 1::bigint, 'winner lock audit is exactly once');

select * from extensions.finish();
rollback;
