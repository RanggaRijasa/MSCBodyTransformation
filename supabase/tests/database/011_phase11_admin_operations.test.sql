begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(35);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('fa000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'admin-cms@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('fa000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 'participant-cms@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());

update public.profiles
set role = 'admin', display_name = 'Admin CMS', onboarding_status = 'active',
  provisional_expires_at = null, finalized_at = now()
where user_id = 'fa000000-0000-0000-0000-000000000001';
update public.profiles
set display_name = 'Peserta CMS', onboarding_status = 'active',
  provisional_expires_at = null, finalized_at = now()
where user_id = 'fa000000-0000-0000-0000-000000000011';

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"fa000000-0000-0000-0000-000000000011","role":"authenticated"}';

select extensions.throws_like(
  $$ select public.save_program_draft(
    jsonb_build_object('title', 'Tidak diizinkan'), 'participant-cms-denied'
  ) $$,
  'permission_denied',
  'Participant cannot save an Admin program draft'
);

set local "request.jwt.claims" =
  '{"sub":"fa000000-0000-0000-0000-000000000001","role":"authenticated"}';

select extensions.lives_ok(
  $$ select public.save_program_draft(
    jsonb_build_object(
      'id', 'fb000000-0000-0000-0000-000000000001',
      'title', 'Program CMS Phase 11',
      'summary', 'Program uji operasi Admin.',
      'pace', 'scheduled',
      'duration_mode', 'specific_dates',
      'starts_on', current_date,
      'ends_on', current_date,
      'timezone', 'Asia/Makassar',
      'participant_limit', 10,
      'registration_closes_at', (statement_timestamp() + interval '1 hour'),
      'past_step_policy', 'available',
      'future_step_policy', 'locked',
      'wellness_disclaimer', 'Program kebugaran non-diagnostik.',
      'points_per_activity', 10,
      'points_per_weight_kg', 0,
      'quiz_passing_percentage', 70,
      'pricing_mode', 'free',
      'days', jsonb_build_array(jsonb_build_object(
        'id', 'fc000000-0000-0000-0000-000000000001',
        'day_number', 1,
        'title', 'Hari pertama',
        'scheduled_on', current_date,
        'steps', jsonb_build_array(jsonb_build_object(
          'id', 'fd000000-0000-0000-0000-000000000001',
          'step_order', 1,
          'title', 'Baca panduan',
          'content_kind', 'article',
          'completion_policy', 'mark_complete',
          'verification_mode', 'automatic',
          'questions', jsonb_build_array()
        ))
      ))
    ),
    'admin-draft-phase11'
  ) $$,
  'Admin can save a complete nested draft'
);
select extensions.is(
  (select count(*)::bigint from public.programs
   where id = 'fb000000-0000-0000-0000-000000000001'),
  1::bigint,
  'draft save creates one program'
);
select extensions.is(
  (select count(*)::bigint from public.program_days
   where program_id = 'fb000000-0000-0000-0000-000000000001'),
  1::bigint,
  'draft save creates the nested day'
);
select extensions.is(
  (select count(*)::bigint from public.program_steps
   where program_day_id = 'fc000000-0000-0000-0000-000000000001'),
  1::bigint,
  'draft save creates the nested step'
);
select extensions.lives_ok(
  $$ select public.save_program_draft(
    jsonb_build_object(
      'id', 'fb000000-0000-0000-0000-000000000001',
      'title', 'Program CMS Phase 11',
      'starts_on', current_date,
      'ends_on', current_date,
      'timezone', 'Asia/Makassar',
      'wellness_disclaimer', 'Program kebugaran non-diagnostik.',
      'pricing_mode', 'free',
      'days', jsonb_build_array(jsonb_build_object(
        'id', 'fc000000-0000-0000-0000-000000000001',
        'day_number', 1,
        'title', 'Hari pertama',
        'scheduled_on', current_date,
        'steps', jsonb_build_array(jsonb_build_object(
          'id', 'fd000000-0000-0000-0000-000000000001',
          'step_order', 1,
          'title', 'Baca panduan',
          'content_kind', 'article',
          'completion_policy', 'mark_complete',
          'verification_mode', 'automatic'
        ))
      ))
    ),
    'admin-draft-phase11'
  ) $$,
  'draft save retry is idempotent'
);
select extensions.is(
  (select count(*)::bigint from public.programs
   where id = 'fb000000-0000-0000-0000-000000000001'),
  1::bigint,
  'draft save retry does not duplicate the program'
);

select extensions.lives_ok(
  $$ select public.duplicate_program_as_draft(
    'fb000000-0000-0000-0000-000000000001',
    'fb000000-0000-0000-0000-000000000002',
    'Salinan Program CMS', current_date + 7, 'admin-duplicate-phase11'
  ) $$,
  'Admin can duplicate a normalized program graph'
);
select extensions.is(
  (select source_program_id from public.programs
   where id = 'fb000000-0000-0000-0000-000000000002'),
  'fb000000-0000-0000-0000-000000000001'::uuid,
  'duplicate keeps the source program reference'
);
select extensions.is(
  (select count(*)::bigint from public.program_days
   where program_id = 'fb000000-0000-0000-0000-000000000002'),
  1::bigint,
  'duplicate creates new normalized days'
);
select extensions.is(
  (select count(*)::bigint from public.program_steps step
   join public.program_days day on day.id = step.program_day_id
   where day.program_id = 'fb000000-0000-0000-0000-000000000002'),
  1::bigint,
  'duplicate creates new normalized steps'
);
select extensions.lives_ok(
  $$ select public.duplicate_program_as_draft(
    'fb000000-0000-0000-0000-000000000001',
    'fb000000-0000-0000-0000-000000000002',
    'Salinan Program CMS', current_date + 7, 'admin-duplicate-phase11'
  ) $$,
  'duplicate retry is idempotent'
);
select extensions.is(
  (select count(*)::bigint from public.programs
   where id = 'fb000000-0000-0000-0000-000000000002'),
  1::bigint,
  'duplicate retry does not create another program'
);

select extensions.lives_ok(
  $$ select public.publish_program(
    'fb000000-0000-0000-0000-000000000001', 'admin-publish-phase11'
  ) $$,
  'Admin can publish a validated free program'
);
select extensions.is(
  (select status from public.programs
   where id = 'fb000000-0000-0000-0000-000000000001'),
  'active',
  'program starting today becomes active'
);
select extensions.lives_ok(
  $$ select public.publish_program(
    'fb000000-0000-0000-0000-000000000001', 'admin-publish-phase11'
  ) $$,
  'publish retry is idempotent'
);

select extensions.lives_ok(
  $$ select public.save_program_draft(
    jsonb_build_object(
      'id', 'fb000000-0000-0000-0000-000000000003',
      'title', 'Program Berbayar',
      'starts_on', current_date + 14,
      'ends_on', current_date + 14,
      'timezone', 'Asia/Makassar',
      'wellness_disclaimer', 'Program kebugaran non-diagnostik.',
      'pricing_mode', 'paid',
      'desired_price', 100000,
      'days', jsonb_build_array(jsonb_build_object(
        'id', 'fc000000-0000-0000-0000-000000000003',
        'day_number', 1,
        'title', 'Hari berbayar',
        'scheduled_on', current_date + 14,
        'steps', jsonb_build_array(jsonb_build_object(
          'id', 'fd000000-0000-0000-0000-000000000003',
          'step_order', 1,
          'title', 'Panduan',
          'content_kind', 'article',
          'completion_policy', 'mark_complete',
          'verification_mode', 'automatic'
        ))
      ))
    ),
    'admin-paid-draft-phase11'
  ) $$,
  'Admin can keep a paid program as draft'
);
reset role;
update public.payment_destinations set status = 'retired';
set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"fa000000-0000-0000-0000-000000000001","role":"authenticated"}';
select extensions.throws_like(
  $$ select public.publish_program(
    'fb000000-0000-0000-0000-000000000003', 'admin-paid-publish-phase11'
  ) $$,
  'program_paid_not_ready',
  'paid publish requires a current manual-payment destination'
);

reset role;
insert into public.payment_destinations(
  id, version, bank_code, bank_name, account_name, account_reference,
  effective_from, status, created_by, instructions
) values (
  'fb000000-0000-0000-0000-000000000099', 999, 'TST', 'Bank Uji',
  'FIXTURE PGTAP', '0000000000', statement_timestamp() - interval '1 minute',
  'active', 'fa000000-0000-0000-0000-000000000001',
  'Jangan melakukan pembayaran nyata.'
);
set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"fa000000-0000-0000-0000-000000000001","role":"authenticated"}';
select extensions.lives_ok(
  $$ select public.publish_program(
    'fb000000-0000-0000-0000-000000000003', 'admin-paid-publish-ready-phase12'
  ) $$,
  'paid program publishes after its destination becomes ready'
);
select extensions.is(
  (select status from public.programs
   where id = 'fb000000-0000-0000-0000-000000000003'),
  'scheduled',
  'future paid program becomes scheduled'
);

reset role;
insert into public.program_enrollments(
  id, program_id, participant_id, coach_id, status, enrolled_at
)
values (
  'fe000000-0000-0000-0000-000000000001',
  'fb000000-0000-0000-0000-000000000001',
  'fa000000-0000-0000-0000-000000000011',
  'fa000000-0000-0000-0000-000000000001', 'active', now()
);
insert into public.program_scores(
  enrollment_id, activity_points, quiz_points, weight_points,
  adjustment_points, progress_percentage, recalculated_at
)
values (
  'fe000000-0000-0000-0000-000000000001', 30, 10, 0, 2, 100, now()
);
insert into storage.objects(bucket_id, name, metadata)
values (
  'public-media', 'winners/phase11-poster.jpg',
  '{"mimetype":"image/jpeg"}'::jsonb
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"fa000000-0000-0000-0000-000000000011","role":"authenticated"}';
select extensions.throws_like(
  $$ select public.complete_program(
    'fb000000-0000-0000-0000-000000000001',
    'Program selesai.', 'participant-complete-denied'
  ) $$,
  'permission_denied',
  'Participant cannot close a program'
);
select extensions.throws_like(
  $$ select * from public.lock_program_winners(
    'fb000000-0000-0000-0000-000000000001', 'participant-lock-denied'
  ) $$,
  'permission_denied',
  'Participant cannot lock winners'
);

set local "request.jwt.claims" =
  '{"sub":"fa000000-0000-0000-0000-000000000001","role":"authenticated"}';
select extensions.lives_ok(
  $$ select public.complete_program(
    'fb000000-0000-0000-0000-000000000001',
    'Program telah selesai.', 'admin-complete-phase11'
  ) $$,
  'Admin can close an eligible program'
);
select extensions.is(
  (select status from public.programs
   where id = 'fb000000-0000-0000-0000-000000000001'),
  'completed',
  'program closure persists the completed status'
);
select extensions.is(
  (select status from public.program_enrollments
   where id = 'fe000000-0000-0000-0000-000000000001'),
  'completed',
  'program closure completes active enrollments'
);
select extensions.lives_ok(
  $$ select public.complete_program(
    'fb000000-0000-0000-0000-000000000001',
    'Program telah selesai.', 'admin-complete-phase11'
  ) $$,
  'program closure retry is idempotent'
);

select extensions.lives_ok(
  $$ select * from public.lock_program_winners(
    'fb000000-0000-0000-0000-000000000001', 'admin-lock-phase11'
  ) $$,
  'Admin can lock a deterministic winner snapshot'
);
select extensions.is(
  (select count(*)::bigint from public.program_winners),
  1::bigint,
  'winner lock supports fewer than five eligible winners'
);
select extensions.lives_ok(
  $$ select * from public.lock_program_winners(
    'fb000000-0000-0000-0000-000000000001', 'admin-lock-phase11'
  ) $$,
  'winner lock retry returns the immutable snapshot'
);
select extensions.is(
  (select count(*)::bigint from public.winner_snapshots),
  1::bigint,
  'winner lock retry does not duplicate the snapshot'
);

select extensions.lives_ok(
  $$ select public.publish_winner_poster(
    'fb000000-0000-0000-0000-000000000001',
    (select id from public.winner_snapshots limit 1),
    'winners/phase11-poster.jpg', 'Poster pemenang program.',
    'admin-poster-phase11'
  ) $$,
  'Admin can publish a poster tied to the locked snapshot'
);
select extensions.lives_ok(
  $$ select public.publish_winner_poster(
    'fb000000-0000-0000-0000-000000000001',
    (select id from public.winner_snapshots limit 1),
    'winners/phase11-poster.jpg', 'Poster pemenang program.',
    'admin-poster-phase11'
  ) $$,
  'poster publication retry is idempotent'
);
select extensions.is(
  (select count(*)::bigint from public.winner_posters),
  1::bigint,
  'poster publication retry does not duplicate the record'
);
select extensions.is(
  (select count(*)::bigint from public.audit_events
   where actor_id = 'fa000000-0000-0000-0000-000000000001'
     and kind in (
       'program_created', 'program_published', 'program_completed',
       'winners_locked', 'managed_content_updated'
     )),
  7::bigint,
  'authoritative Admin transitions write the expected audit events once'
);
select extensions.throws_like(
  $$ insert into public.program_winners(
    snapshot_id, participant_id, rank, display_name, total_points
  ) values (
    (select id from public.winner_snapshots limit 1),
    'fa000000-0000-0000-0000-000000000011', 2, 'Tidak sah', 0
  ) $$,
  '%permission denied%',
  'Admin clients cannot mutate immutable winner rows directly'
);

select * from extensions.finish();
rollback;
