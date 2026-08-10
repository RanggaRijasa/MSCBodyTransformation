begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(24);

insert into auth.users(id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('e8000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'p8-admin@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('e8000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'p8-coach-a@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('e8000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'p8-coach-b@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('e8000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', 'p8-coach-participant@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('e8000000-0000-4000-8000-000000000005', 'authenticated', 'authenticated', 'p8-participant@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('e8000000-0000-4000-8000-000000000006', 'authenticated', 'authenticated', 'p8-expired@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());

update public.profiles set role = 'admin', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null where user_id = 'e8000000-0000-4000-8000-000000000001';
update public.profiles set role = 'coach', coach_is_approved = true, coach_qr_identifier = 'phase08-coach-a-opaque', display_name = 'Coach A', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null where user_id = 'e8000000-0000-4000-8000-000000000002';
update public.profiles set role = 'coach', coach_is_approved = true, coach_qr_identifier = 'phase08-coach-b-opaque', display_name = 'Coach B', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null where user_id = 'e8000000-0000-4000-8000-000000000003';
update public.profiles set role = 'coach', coach_is_approved = true, coach_qr_identifier = 'phase08-coach-p-opaque', display_name = 'Coach Peserta', current_coach_id = 'e8000000-0000-4000-8000-000000000002', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null where user_id = 'e8000000-0000-4000-8000-000000000004';
update public.profiles set role = 'participant', display_name = 'Peserta Phase 08', current_coach_id = 'e8000000-0000-4000-8000-000000000002', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null where user_id = 'e8000000-0000-4000-8000-000000000005';
update public.profiles set role = 'participant', coach_is_approved = false, display_name = 'Coach Kedaluwarsa', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null where user_id = 'e8000000-0000-4000-8000-000000000006';

insert into public.coach_applications(id, applicant_user_id, participant_profile_id, display_name_snapshot, phone_number_snapshot, member_level_snapshot, has_completed_hom_sts, has_completed_ict, terms_version, status, draft_idempotency_key, submitted_at, decided_at, decided_by)
values
  ('e8100000-0000-4000-8000-000000000002', 'e8000000-0000-4000-8000-000000000002', 'e8000000-0000-4000-8000-000000000002', 'Coach A', '+628100000002', 'sc', true, true, 'p8', 'active', 'p8-app-coach-a', now(), now(), 'e8000000-0000-4000-8000-000000000001'),
  ('e8100000-0000-4000-8000-000000000003', 'e8000000-0000-4000-8000-000000000003', 'e8000000-0000-4000-8000-000000000003', 'Coach B', '+628100000003', 'sc', true, true, 'p8', 'active', 'p8-app-coach-b', now(), now(), 'e8000000-0000-4000-8000-000000000001'),
  ('e8100000-0000-4000-8000-000000000004', 'e8000000-0000-4000-8000-000000000004', 'e8000000-0000-4000-8000-000000000004', 'Coach Peserta', '+628100000004', 'sc', true, true, 'p8', 'active', 'p8-app-coach-p', now(), now(), 'e8000000-0000-4000-8000-000000000001');
insert into public.coach_payment_records(id, application_id, state, price_band, amount_minor_units, provider_reference, verified_at)
values
  ('e8200000-0000-4000-8000-000000000002', 'e8100000-0000-4000-8000-000000000002', 'verified', 'entry', 100000, 'p8-pay-a', now()),
  ('e8200000-0000-4000-8000-000000000003', 'e8100000-0000-4000-8000-000000000003', 'verified', 'entry', 100000, 'p8-pay-b', now()),
  ('e8200000-0000-4000-8000-000000000004', 'e8100000-0000-4000-8000-000000000004', 'verified', 'entry', 100000, 'p8-pay-p', now());
insert into public.coach_access_entitlements(id, application_id, payment_record_id, coach_user_id, status, starts_at, ends_at)
values
  ('e8300000-0000-4000-8000-000000000002', 'e8100000-0000-4000-8000-000000000002', 'e8200000-0000-4000-8000-000000000002', 'e8000000-0000-4000-8000-000000000002', 'active', now() - interval '1 day', now() + interval '30 days'),
  ('e8300000-0000-4000-8000-000000000003', 'e8100000-0000-4000-8000-000000000003', 'e8200000-0000-4000-8000-000000000003', 'e8000000-0000-4000-8000-000000000003', 'active', now() - interval '1 day', now() + interval '30 days'),
  ('e8300000-0000-4000-8000-000000000004', 'e8100000-0000-4000-8000-000000000004', 'e8200000-0000-4000-8000-000000000004', 'e8000000-0000-4000-8000-000000000004', 'active', now() - interval '1 day', now() + interval '30 days');

insert into public.programs(id, title, status, pace, duration_mode, starts_on, ends_on, timezone, past_step_policy, future_step_policy, wellness_disclaimer, points_per_activity, points_per_weight_kg, quiz_passing_percentage, pricing_mode, created_by, published_at)
values ('e8400000-0000-4000-8000-000000000001', 'Program Coach Phase 08', 'active', 'scheduled', 'fixed_duration', current_date, current_date, 'UTC', 'available', 'locked', 'Non-diagnostik.', 10, 100, 70, 'free', 'e8000000-0000-4000-8000-000000000001', now());
insert into public.program_days(id, program_id, day_number, title, scheduled_on) values ('e8500000-0000-4000-8000-000000000001', 'e8400000-0000-4000-8000-000000000001', 1, 'Hari Coach', current_date);
insert into public.program_steps(id, program_day_id, step_order, title, content_kind, completion_policy, verification_mode) values ('e8600000-0000-4000-8000-000000000001', 'e8500000-0000-4000-8000-000000000001', 1, 'Refleksi', 'form', 'answer_all_questions', 'coach_review');
insert into public.program_questions(id, step_id, question_order, kind, prompt) values ('e8700000-0000-4000-8000-000000000001', 'e8600000-0000-4000-8000-000000000001', 1, 'short_answer', 'Apa fokusmu?');
insert into public.program_answer_keys(question_id, accepted_text_values, selected_option_ids, matching_mode) values ('e8700000-0000-4000-8000-000000000001', array['Menjaga konsistensi.'], array[]::uuid[], 'case_insensitive_text');
insert into public.program_enrollments(id, program_id, participant_id, coach_id, status) values ('e8800000-0000-4000-8000-000000000001', 'e8400000-0000-4000-8000-000000000001', 'e8000000-0000-4000-8000-000000000005', 'e8000000-0000-4000-8000-000000000002', 'active');
insert into public.program_scores(enrollment_id) values ('e8800000-0000-4000-8000-000000000001');
insert into public.step_submissions(id, enrollment_id, step_id, attempt_sequence, status, idempotency_key, submitted_at, finalized_at) values ('e8900000-0000-4000-8000-000000000001', 'e8800000-0000-4000-8000-000000000001', 'e8600000-0000-4000-8000-000000000001', 1, 'pending', 'p8-submission-pending', now(), now());
insert into public.step_submission_answers(submission_id, question_id, text_value) values ('e8900000-0000-4000-8000-000000000001', 'e8700000-0000-4000-8000-000000000001', 'Menjaga konsistensi.');

select extensions.ok(private.is_participant_capable('e8000000-0000-4000-8000-000000000004'), 'active Coach has Participant capability');
select extensions.ok(private.is_participant_capable('e8000000-0000-4000-8000-000000000006'), 'expired projection retains base Participant capability');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e8000000-0000-4000-8000-000000000004","role":"authenticated"}';
select extensions.is(public.pending_program_enrollment_availability('e8400000-0000-4000-8000-000000000001'), 'available', 'Coach can inspect Participant enrollment availability');
select extensions.throws_like($$ select public.resolve_coach_qr_for_enrollment('phase08-coach-p-opaque') $$, 'coach_qr_invalid', 'Coach cannot assign self as Participant Coach');
select extensions.lives_ok($$ select public.enroll_free_program('e8400000-0000-4000-8000-000000000001', 'phase08-coach-a-opaque') $$, 'Coach enrolls through shared Participant operation');
select extensions.is((select count(*)::bigint from public.list_my_program_day_access()), 1::bigint, 'Coach sees shared Participant day access');

set local "request.jwt.claims" = '{"sub":"e8000000-0000-4000-8000-000000000002","role":"authenticated"}';
select extensions.is((select count(*)::bigint from public.list_my_assigned_participants()), 2::bigint, 'Coach roster includes Participant and Coach-as-Participant');
select extensions.is((select count(*)::bigint from public.list_my_pending_reviews()), 1::bigint, 'Coach sees one pending assigned review');
select extensions.is((select count(*)::bigint from public.program_answer_keys where question_id = 'e8700000-0000-4000-8000-000000000001'), 1::bigint, 'assigned Coach can read review answer key');
select extensions.lives_ok($$ select public.review_step_submission('e8900000-0000-4000-8000-000000000001', 'approved', null, 'p8-review-approved-once') $$, 'Coach approves assigned submission');
select extensions.lives_ok($$ select public.review_step_submission('e8900000-0000-4000-8000-000000000001', 'approved', null, 'p8-review-approved-once') $$, 'review replay is idempotent');
select extensions.is((select activity_points from public.program_scores where enrollment_id = 'e8800000-0000-4000-8000-000000000001'), 10, 'approval reconciles score exactly once');
select extensions.is((select count(*)::bigint from public.audit_events where subject_id = 'e8900000-0000-4000-8000-000000000001' and kind = 'submission_approved'), 0::bigint, 'Coach cannot read audit rows through RLS');
select extensions.throws_like($$ select public.review_step_submission('e8900000-0000-4000-8000-000000000001', 'rejected', 'Tidak sesuai.', 'p8-review-conflict') $$, 'submission_already_reviewed', 'conflicting stale review fails closed');

set local "request.jwt.claims" = '{"sub":"e8000000-0000-4000-8000-000000000003","role":"authenticated"}';
select extensions.is((select count(*)::bigint from public.list_my_assigned_participants()), 0::bigint, 'other Coach roster is empty');
select extensions.is((select count(*)::bigint from public.profiles where user_id = 'e8000000-0000-4000-8000-000000000005'), 0::bigint, 'other Coach cannot read Participant profile');
select extensions.is((select count(*)::bigint from public.program_answer_keys where question_id = 'e8700000-0000-4000-8000-000000000001'), 0::bigint, 'other Coach cannot read review answer key');
select extensions.throws_like($$ select public.review_step_submission('e8900000-0000-4000-8000-000000000001', 'approved', null, 'p8-other-coach-review') $$, 'permission_denied', 'other Coach cannot review submission');

set local "request.jwt.claims" = '{"sub":"e8000000-0000-4000-8000-000000000006","role":"authenticated"}';
select extensions.throws_like($$ select * from public.list_my_assigned_participants() $$, 'coach_entitlement_inactive', 'expired Coach cannot use private roster');
select extensions.is((select role from public.profiles where user_id = 'e8000000-0000-4000-8000-000000000006'), 'participant', 'expired Coach keeps base Participant role');

set local "request.jwt.claims" = '{"sub":"e8000000-0000-4000-8000-000000000005","role":"authenticated"}';
select extensions.throws_like($$ select * from public.list_my_assigned_participants() $$, 'coach_entitlement_inactive', 'Participant cannot use Coach roster');

set local role anon;
set local "request.jwt.claims" = '{"role":"anon"}';
select extensions.throws_like($$ select * from public.list_my_assigned_participants() $$, '%permission denied%', 'Guest cannot execute Coach roster');

reset role;
update public.profiles set current_coach_id = 'e8000000-0000-4000-8000-000000000003' where user_id = 'e8000000-0000-4000-8000-000000000005';
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"e8000000-0000-4000-8000-000000000002","role":"authenticated"}';
select extensions.is((select count(*)::bigint from public.profiles where user_id = 'e8000000-0000-4000-8000-000000000005'), 0::bigint, 'historical Coach loses private detail after authoritative transfer');

reset role;
select extensions.is((select count(*)::bigint from public.audit_events where subject_id = 'e8900000-0000-4000-8000-000000000001' and kind = 'submission_approved'), 1::bigint, 'approval writes one audit event');

select * from extensions.finish();
rollback;
