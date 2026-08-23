begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(36);

select extensions.has_column(
  'public', 'profiles', 'public_profile_id',
  'profiles have a public identifier separate from Auth identity'
);
select extensions.has_column(
  'public', 'program_scores', 'public_id',
  'leaderboard rows have a public identifier'
);

select extensions.ok(
  has_function_privilege(
    'anon',
    'public.list_public_programs(uuid,integer,integer)',
    'execute'
  ),
  'anon can call the public program projection'
);
select extensions.ok(
  has_function_privilege(
    'anon',
    'public.list_public_coaches(integer,integer)',
    'execute'
  ),
  'anon can call the public Coach projection'
);
select extensions.ok(
  has_function_privilege(
    'anon',
    'public.list_public_leaderboard(uuid,integer,integer)',
    'execute'
  ),
  'anon can call the public leaderboard projection'
);
select extensions.ok(
  has_function_privilege(
    'anon',
    'public.list_public_winners(uuid,integer,integer)',
    'execute'
  ),
  'anon can call the public winner projection'
);
select extensions.ok(
  has_function_privilege(
    'anon',
    'public.list_public_winner_posters(integer,integer)',
    'execute'
  ),
  'anon can call the public poster projection'
);
select extensions.ok(
  not has_function_privilege(
    'public',
    'public.list_public_programs(uuid,integer,integer)',
    'execute'
  ),
  'PUBLIC does not inherit the Guest projection privilege'
);

select extensions.ok(
  not has_table_privilege('anon', 'public.profiles', 'select'),
  'anon cannot select profiles'
);
select extensions.ok(
  not has_table_privilege('anon', 'public.programs', 'select'),
  'anon cannot select program base rows'
);
select extensions.ok(
  not has_table_privilege('anon', 'public.program_enrollments', 'select'),
  'anon cannot select enrollments'
);
select extensions.ok(
  not has_table_privilege('anon', 'public.program_scores', 'select'),
  'anon cannot select score base rows'
);
select extensions.ok(
  not has_table_privilege('anon', 'public.weigh_ins', 'select'),
  'anon cannot select weights'
);
select extensions.ok(
  not has_table_privilege('anon', 'public.step_submissions', 'select'),
  'anon cannot select submissions'
);
select extensions.ok(
  not has_table_privilege(
    'anon',
    'public.step_submission_answers',
    'select'
  ),
  'anon cannot select submission answers'
);
select extensions.ok(
  not has_table_privilege('anon', 'public.program_answer_keys', 'select'),
  'anon cannot select answer keys'
);
select extensions.ok(
  not has_table_privilege('anon', 'public.commerce_transactions', 'select'),
  'anon cannot select payments'
);
select extensions.ok(
  not has_table_privilege('anon', 'public.audit_events', 'select'),
  'anon cannot select audit events'
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
    'c1000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'phase11-admin@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    'c1000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'phase11-public-coach@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    'c1000000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'phase11-private-coach@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  ),
  (
    'c1000000-0000-0000-0000-000000000011',
    'authenticated',
    'authenticated',
    'phase11-participant@test.invalid',
    '',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  );

update public.profiles
set role = 'admin',
    display_name = 'Admin Phase 11',
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = 'c1000000-0000-0000-0000-000000000001';

update public.profiles
set role = 'coach',
    display_name = 'Coach Publik',
    city = 'Denpasar',
    phone_number = '+6281200000011',
    coach_qr_identifier = 'phase11-private-qr-public-coach',
    coach_is_approved = true,
    coach_is_public = true,
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = 'c1000000-0000-0000-0000-000000000002';

update public.profiles
set role = 'coach',
    display_name = 'Coach Privat',
    coach_qr_identifier = 'phase11-private-qr-private-coach',
    coach_is_approved = true,
    coach_is_public = false,
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = 'c1000000-0000-0000-0000-000000000003';

update public.profiles
set display_name = 'Peserta Publik',
    current_coach_id = 'c1000000-0000-0000-0000-000000000002',
    phone_number = '+6281200000012',
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = now()
where user_id = 'c1000000-0000-0000-0000-000000000011';

insert into public.coach_applications (
  id, applicant_user_id, participant_profile_id, display_name_snapshot,
  phone_number_snapshot, member_level_snapshot, has_completed_hom_sts,
  has_completed_ict, terms_version, status, draft_idempotency_key,
  submitted_at, decided_at, decided_by
) values (
  'c1100000-0000-0000-0000-000000000002',
  'c1000000-0000-0000-0000-000000000002',
  'c1000000-0000-0000-0000-000000000002',
  'Coach Publik', '+6281200000011', 'sc', true, true, 'test-v1',
  'active', 'public-coach-fixture', now(), now(),
  'c1000000-0000-0000-0000-000000000001'
);
insert into public.coach_payment_records (
  id, application_id, state, price_band, amount_minor_units,
  provider_reference, verified_at
) values (
  'c1200000-0000-0000-0000-000000000002',
  'c1100000-0000-0000-0000-000000000002',
  'verified', 'entry', 100000, 'public-coach-fixture-payment', now()
);
insert into public.coach_access_entitlements (
  id, application_id, payment_record_id, coach_user_id, status,
  starts_at, ends_at
) values (
  'c1300000-0000-0000-0000-000000000002',
  'c1100000-0000-0000-0000-000000000002',
  'c1200000-0000-0000-0000-000000000002',
  'c1000000-0000-0000-0000-000000000002',
  'active', now() - interval '1 day', now() + interval '30 days'
);

insert into public.coach_public_profile_drafts(
  coach_user_id, public_handle, profile_photo_object_path,
  professional_headline, biography, service_area
) values (
  'c1000000-0000-0000-0000-000000000002',
  'coach-publik-phase11',
  'coaches/c1400000-0000-0000-0000-000000000002/avatar/c1500000-0000-0000-0000-000000000002.jpg',
  'Coach', 'Profil publik sintetis.', 'Denpasar'
);

insert into public.coach_public_media_namespaces(coach_user_id, media_namespace)
values (
  'c1000000-0000-0000-0000-000000000002',
  'c1400000-0000-0000-0000-000000000002'
);

insert into private.coach_public_media_assets(
  id, coach_user_id, object_path, media_folder
) values (
  'c1500000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000002',
  'coaches/c1400000-0000-0000-0000-000000000002/avatar/c1500000-0000-0000-0000-000000000002.jpg',
  'avatar'
);

insert into public.coach_public_profiles(
  coach_user_id, public_handle, display_name, photo_kind,
  photo_reference, professional_headline, biography, service_area
) values (
  'c1000000-0000-0000-0000-000000000002',
  'coach-publik-phase11', 'Coach Publik', 'storage',
  'coaches/c1400000-0000-0000-0000-000000000002/avatar/c1500000-0000-0000-0000-000000000002.jpg',
  'Coach', 'Profil publik sintetis.', 'Denpasar'
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
values
  (
    'c2000000-0000-0000-0000-000000000001',
    'Program Publik Phase 11',
    'Ringkasan publik.',
    'completed',
    'scheduled',
    'fixed_duration',
    date '2026-07-01',
    date '2026-07-31',
    'Asia/Makassar',
    'available',
    'locked',
    'Program kebugaran non-diagnostik.',
    10,
    100,
    70,
    'free',
    now(),
    'c1000000-0000-0000-0000-000000000001'
  ),
  (
    'c2000000-0000-0000-0000-000000000002',
    'Program Draf Rahasia',
    'Tidak boleh dibaca Guest.',
    'draft',
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
    null,
    'c1000000-0000-0000-0000-000000000001'
  );

insert into public.program_days (
  id, program_id, day_number, title, scheduled_on
)
values (
  'c3000000-0000-0000-0000-000000000001',
  'c2000000-0000-0000-0000-000000000001',
  1,
  'Hari Publik',
  date '2026-07-01'
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
  'c4000000-0000-0000-0000-000000000001',
  'c3000000-0000-0000-0000-000000000001',
  1,
  'Kuis Publik',
  'quiz',
  'automatic_quiz',
  'automatic'
);

insert into public.program_questions (
  id, step_id, question_order, kind, prompt
)
values (
  'c5000000-0000-0000-0000-000000000001',
  'c4000000-0000-0000-0000-000000000001',
  1,
  'single_choice',
  'Pertanyaan publik'
);

insert into public.program_question_options (
  id, question_id, option_order, title
)
values (
  'c6000000-0000-0000-0000-000000000001',
  'c5000000-0000-0000-0000-000000000001',
  1,
  'Pilihan publik'
);

insert into public.program_answer_keys (
  question_id, selected_option_ids
)
values (
  'c5000000-0000-0000-0000-000000000001',
  array['c6000000-0000-0000-0000-000000000001'::uuid]
);

insert into public.program_enrollments (
  id, program_id, participant_id, coach_id, status, completed_at
)
values (
  'c7000000-0000-0000-0000-000000000001',
  'c2000000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000011',
  'c1000000-0000-0000-0000-000000000002',
  'completed',
  now()
);

insert into public.program_scores (
  enrollment_id,
  activity_points,
  quiz_points,
  weight_points,
  adjustment_points,
  progress_percentage,
  rank
)
values (
  'c7000000-0000-0000-0000-000000000001',
  100,
  20,
  300,
  5,
  100,
  1
);

insert into public.winner_snapshots (
  id, program_id, locked_by, locked_at
)
values (
  'c8000000-0000-0000-0000-000000000001',
  'c2000000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000001',
  now()
);

insert into public.program_winners (
  id,
  snapshot_id,
  participant_id,
  rank,
  display_name,
  total_points
)
values (
  'c9000000-0000-0000-0000-000000000001',
  'c8000000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000011',
  1,
  'Peserta Publik',
  425
);

insert into public.winner_posters (
  id,
  program_id,
  winner_snapshot_id,
  media_path,
  alt_text,
  is_published,
  published_at
)
values
  (
    'ca000000-0000-0000-0000-000000000001',
    'c2000000-0000-0000-0000-000000000001',
    'c8000000-0000-0000-0000-000000000001',
    'winner-posters/published.jpg',
    'Poster pemenang publik',
    true,
    now()
  ),
  (
    'ca000000-0000-0000-0000-000000000002',
    'c2000000-0000-0000-0000-000000000001',
    'c8000000-0000-0000-0000-000000000001',
    'winner-posters/private.jpg',
    'Poster yang belum diterbitkan',
    false,
    null
  );

set local role anon;

select extensions.is(
  (
    select count(*)::bigint
    from public.list_public_programs(
      'c2000000-0000-0000-0000-000000000001'
    )
  ),
  1::bigint,
  'Guest sees only published-lifecycle programs'
);
select extensions.ok(
  not (
    select value ? 'created_by'
    from public.list_public_programs(
      'c2000000-0000-0000-0000-000000000001'
    ) value
    limit 1
  ),
  'public program projection omits creator identity'
);
select extensions.ok(
  not (
    select value::text like '%answer_key%'
    from public.list_public_programs(
      'c2000000-0000-0000-0000-000000000001'
    ) value
    limit 1
  ),
  'public program projection omits answer keys'
);
select extensions.is(
  (
    select jsonb_array_length(value -> 'program_days')
    from public.list_public_programs(
      'c2000000-0000-0000-0000-000000000001'
    ) value
    limit 1
  ),
  1,
  'public program projection includes ordered day content'
);
select extensions.is(
  (select count(*)::bigint from public.list_public_coaches()),
  1::bigint,
  'Guest sees only approved and public Coaches'
);
select extensions.ok(
  not (
    select value ? 'user_id'
    from public.list_public_coaches() value
    limit 1
  ),
  'public Coach projection omits Auth user ID'
);
select extensions.ok(
  not (
    select value ? 'phone_number'
    from public.list_public_coaches() value
    limit 1
  ),
  'public Coach projection omits phone number'
);
select extensions.ok(
  not (
    select value ? 'coach_qr_identifier'
    from public.list_public_coaches() value
    limit 1
  ),
  'public Coach projection omits raw Coach QR identifier'
);
select extensions.isnt(
  (
    select value ->> 'id'
    from public.list_public_coaches() value
    limit 1
  ),
  'c1000000-0000-0000-0000-000000000002',
  'public Coach identifier differs from Auth user ID'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.list_public_leaderboard(
      'c2000000-0000-0000-0000-000000000001'
    )
  ),
  1::bigint,
  'Guest can read the public leaderboard'
);
select extensions.ok(
  not (
    select value ? 'enrollment_id'
    from public.list_public_leaderboard(
      'c2000000-0000-0000-0000-000000000001'
    ) value
    limit 1
  ),
  'public leaderboard omits enrollment ID'
);
select extensions.ok(
  not (
    select value ? 'weight_points'
    from public.list_public_leaderboard(
      'c2000000-0000-0000-0000-000000000001'
    ) value
    limit 1
  ),
  'public leaderboard omits weight score breakdown'
);
select extensions.isnt(
  (
    select value ->> 'participant_id'
    from public.list_public_leaderboard(
      'c2000000-0000-0000-0000-000000000001'
    ) value
    limit 1
  ),
  'c1000000-0000-0000-0000-000000000011',
  'public leaderboard participant ID differs from Auth user ID'
);
select extensions.is(
  (
    select (value ->> 'total_points')::integer
    from public.list_public_leaderboard(
      'c2000000-0000-0000-0000-000000000001'
    ) value
    limit 1
  ),
  425,
  'public leaderboard returns only the authoritative total score'
);
select extensions.is(
  (
    select count(*)::bigint
    from public.list_public_winners(
      'c2000000-0000-0000-0000-000000000001'
    )
  ),
  1::bigint,
  'Guest can read the locked winner snapshot'
);
select extensions.isnt(
  (
    select value ->> 'participant_id'
    from public.list_public_winners(
      'c2000000-0000-0000-0000-000000000001'
    ) value
    limit 1
  ),
  'c1000000-0000-0000-0000-000000000011',
  'public winner participant ID differs from Auth user ID'
);
select extensions.is(
  (select count(*)::bigint from public.list_public_winner_posters()),
  1::bigint,
  'Guest sees only published winner posters'
);
select extensions.ok(
  not (
    select value::text like '%private.jpg%'
    from public.list_public_winner_posters() value
    limit 1
  ),
  'unpublished poster media never enters the public projection'
);

select * from extensions.finish();
rollback;
