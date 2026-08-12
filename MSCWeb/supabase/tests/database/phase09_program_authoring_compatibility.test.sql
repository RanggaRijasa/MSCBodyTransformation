begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(19);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('f9400000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'phase09-authoring-admin@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('f9400000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'phase09-authoring-participant@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());

update public.profiles
set role = 'admin', display_name = 'Admin Authoring Phase 09',
  onboarding_status = 'active', provisional_expires_at = null, finalized_at = now()
where user_id = 'f9400000-0000-4000-8000-000000000001';

update public.profiles
set role = 'participant', display_name = 'Peserta Authoring Phase 09',
  onboarding_status = 'active', provisional_expires_at = null, finalized_at = now()
where user_id = 'f9400000-0000-4000-8000-000000000002';

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"f9400000-0000-4000-8000-000000000002","role":"authenticated"}';

select extensions.throws_like(
  $$ select public.save_program_draft(jsonb_build_object('title', 'Tidak diizinkan'), 'phase09-authoring-participant-denied') $$,
  'permission_denied',
  'Participant cannot save an Admin program draft'
);

set local "request.jwt.claims" =
  '{"sub":"f9400000-0000-4000-8000-000000000001","role":"authenticated"}';

select extensions.lives_ok(
  $$ select public.save_program_draft(
    jsonb_build_object(
      'id', 'f9410000-0000-4000-8000-000000000001',
      'title', 'Program Authoring Phase 09',
      'summary', 'Program uji kontrak authoring Admin.',
      'pace', 'scheduled',
      'duration_mode', 'specific_dates',
      'starts_on', current_date + 2,
      'ends_on', current_date + 3,
      'timezone', 'Asia/Makassar',
      'participant_limit', 10,
      'registration_closes_at', ((current_date + 1)::timestamp at time zone 'Asia/Makassar'),
      'past_step_policy', 'available',
      'future_step_policy', 'locked',
      'wellness_disclaimer', 'Program kebugaran non-diagnostik.',
      'points_per_activity', 10,
      'points_per_weight_kg', 0,
      'quiz_passing_percentage', 70,
      'pricing_mode', 'free',
      'days', jsonb_build_array(jsonb_build_object(
        'id', 'f9420000-0000-4000-8000-000000000001',
        'day_number', 1,
        'title', 'Hari pertama',
        'scheduled_on', current_date + 2,
        'steps', jsonb_build_array(jsonb_build_object(
          'id', 'f9430000-0000-4000-8000-000000000001',
          'step_order', 1,
          'title', 'Baca panduan',
          'content_kind', 'article',
          'completion_policy', 'mark_complete',
          'verification_mode', 'automatic',
          'questions', jsonb_build_array()
        ))
      ))
    ),
    'phase09-authoring-save'
  ) $$,
  'Admin can save a complete nested draft with deterministic future dates'
);

select extensions.is(
  (select count(*)::bigint from public.programs where id = 'f9410000-0000-4000-8000-000000000001'),
  1::bigint,
  'draft save creates one program'
);
select extensions.is(
  (select count(*)::bigint from public.program_days where program_id = 'f9410000-0000-4000-8000-000000000001'),
  1::bigint,
  'draft save creates the nested day'
);
select extensions.is(
  (select count(*)::bigint from public.program_steps where program_day_id = 'f9420000-0000-4000-8000-000000000001'),
  1::bigint,
  'draft save creates the nested step'
);
select extensions.lives_ok(
  $$ select public.save_program_draft(
    jsonb_build_object(
      'id', 'f9410000-0000-4000-8000-000000000001',
      'title', 'Program Authoring Phase 09',
      'starts_on', current_date + 2,
      'ends_on', current_date + 3,
      'timezone', 'Asia/Makassar',
      'wellness_disclaimer', 'Program kebugaran non-diagnostik.',
      'pricing_mode', 'free'
    ),
    'phase09-authoring-save'
  ) $$,
  'draft save replay is idempotent'
);
select extensions.is(
  (select count(*)::bigint from public.programs where id = 'f9410000-0000-4000-8000-000000000001'),
  1::bigint,
  'draft save replay does not duplicate the program'
);

select extensions.lives_ok(
  $$ select public.duplicate_program_as_draft(
    'f9410000-0000-4000-8000-000000000001',
    'f9410000-0000-4000-8000-000000000002',
    'Salinan Program Authoring', current_date + 7, 'phase09-authoring-duplicate'
  ) $$,
  'Admin can duplicate a normalized program graph'
);
select extensions.is(
  (select source_program_id from public.programs where id = 'f9410000-0000-4000-8000-000000000002'),
  'f9410000-0000-4000-8000-000000000001'::uuid,
  'duplicate keeps the source program reference'
);
select extensions.is(
  (select count(*)::bigint from public.program_days where program_id = 'f9410000-0000-4000-8000-000000000002'),
  1::bigint,
  'duplicate creates new normalized days'
);
select extensions.is(
  (select count(*)::bigint from public.program_steps step join public.program_days day on day.id = step.program_day_id where day.program_id = 'f9410000-0000-4000-8000-000000000002'),
  1::bigint,
  'duplicate creates new normalized steps'
);
select extensions.lives_ok(
  $$ select public.duplicate_program_as_draft(
    'f9410000-0000-4000-8000-000000000001',
    'f9410000-0000-4000-8000-000000000002',
    'Salinan Program Authoring', current_date + 7, 'phase09-authoring-duplicate'
  ) $$,
  'duplicate replay is idempotent'
);
select extensions.is(
  (select count(*)::bigint from public.programs where id = 'f9410000-0000-4000-8000-000000000002'),
  1::bigint,
  'duplicate replay does not create another program'
);

select extensions.lives_ok(
  $$ select public.publish_program('f9410000-0000-4000-8000-000000000001', 'phase09-authoring-publish') $$,
  'Admin can publish a validated free program'
);
select extensions.is(
  (select status from public.programs where id = 'f9410000-0000-4000-8000-000000000001'),
  'scheduled',
  'future program persists the scheduled status'
);
select extensions.lives_ok(
  $$ select public.publish_program('f9410000-0000-4000-8000-000000000001', 'phase09-authoring-publish') $$,
  'publish replay is idempotent'
);

set local "request.jwt.claims" =
  '{"sub":"f9400000-0000-4000-8000-000000000002","role":"authenticated"}';
select extensions.throws_like(
  $$ select public.complete_program('f9410000-0000-4000-8000-000000000001', 'Tidak berwenang.', 'phase09-authoring-complete-denied') $$,
  'permission_denied',
  'Participant cannot complete a program'
);
select extensions.throws_like(
  $$ select * from public.lock_program_winners('f9410000-0000-4000-8000-000000000001', 'phase09-authoring-lock-denied') $$,
  'permission_denied',
  'Participant cannot lock program winners'
);

reset role;
insert into public.winner_snapshots(id, program_id, locked_by, idempotency_key)
values (
  'f9440000-0000-4000-8000-000000000001',
  'f9410000-0000-4000-8000-000000000001',
  'f9400000-0000-4000-8000-000000000001',
  'phase09-authoring-snapshot'
);
set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"f9400000-0000-4000-8000-000000000001","role":"authenticated"}';
select extensions.throws_like(
  $$ insert into public.program_winners(snapshot_id, participant_id, rank, display_name, total_points)
     values ('f9440000-0000-4000-8000-000000000001', 'f9400000-0000-4000-8000-000000000002', 1, 'Tidak sah', 0) $$,
  '%permission denied%',
  'Admin clients cannot mutate immutable winner rows directly'
);

select * from extensions.finish();
rollback;
