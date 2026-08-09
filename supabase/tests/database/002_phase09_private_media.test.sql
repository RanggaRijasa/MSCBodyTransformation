begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(19);

select extensions.is(
  (
    select public
    from storage.buckets
    where id = 'public-media'
  ),
  true,
  'public-media remains an explicitly public bucket'
);
select extensions.is(
  (
    select public
    from storage.buckets
    where id = 'question-photos'
  ),
  false,
  'question-photos remains a private bucket'
);
select extensions.is(
  (
    select file_size_limit
    from storage.buckets
    where id = 'question-photos'
  ),
  8388608::bigint,
  'question photos are limited to eight MiB'
);
select extensions.is(
  (
    select allowed_mime_types
    from storage.buckets
    where id = 'question-photos'
  ),
  array['image/jpeg']::text[],
  'question photos accept only normalized JPEG uploads'
);
select extensions.is(
  (
    select allowed_mime_types
    from storage.buckets
    where id = 'public-media'
  ),
  array['image/jpeg']::text[],
  'public media accepts only normalized JPEG uploads'
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
    'storage-admin@test.invalid',
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
    'storage-coach-one@test.invalid',
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
    'storage-coach-two@test.invalid',
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
    'storage-participant-one@test.invalid',
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
    'storage-participant-two@test.invalid',
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
    '00000000-0000-0000-0000-000000000001',
    'admin',
    'Admin Storage',
    null,
    null,
    false
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'coach',
    'Coach Storage Satu',
    null,
    'storage-coach-one-qr',
    true
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    'coach',
    'Coach Storage Dua',
    null,
    'storage-coach-two-qr',
    true
  ),
  (
    '00000000-0000-0000-0000-000000000011',
    'participant',
    'Peserta Storage Satu',
    '00000000-0000-0000-0000-000000000002',
    null,
    false
  ),
  (
    '00000000-0000-0000-0000-000000000012',
    'participant',
    'Peserta Storage Dua',
    '00000000-0000-0000-0000-000000000003',
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

insert into public.coach_applications (
  id, applicant_user_id, participant_profile_id, display_name_snapshot,
  phone_number_snapshot, member_level_snapshot, has_completed_hom_sts,
  has_completed_ict, terms_version, status, draft_idempotency_key,
  submitted_at, decided_at, decided_by
)
values
  ('1a000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'Coach Storage Satu', '+628100000002', 'sc', true, true, 'test-v1', 'active', 'storage-coach-one', now(), now(), '00000000-0000-0000-0000-000000000001'),
  ('1a000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', 'Coach Storage Dua', '+628100000003', 'sc', true, true, 'test-v1', 'active', 'storage-coach-two', now(), now(), '00000000-0000-0000-0000-000000000001');

insert into public.coach_payment_records (
  id, application_id, state, price_band, amount_minor_units,
  provider_reference, verified_at
)
values
  ('1b000000-0000-0000-0000-000000000002', '1a000000-0000-0000-0000-000000000002', 'verified', 'entry', 100000, 'test-storage-one', now()),
  ('1b000000-0000-0000-0000-000000000003', '1a000000-0000-0000-0000-000000000003', 'verified', 'entry', 100000, 'test-storage-two', now());

insert into public.coach_access_entitlements (
  id, application_id, payment_record_id, coach_user_id, status,
  starts_at, ends_at
)
values
  ('1c000000-0000-0000-0000-000000000002', '1a000000-0000-0000-0000-000000000002', '1b000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'active', now() - interval '1 day', now() + interval '30 days'),
  ('1c000000-0000-0000-0000-000000000003', '1a000000-0000-0000-0000-000000000003', '1b000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', 'active', now() - interval '1 day', now() + interval '30 days');

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
  '10000000-0000-0000-0000-000000000001',
  'Program Foto',
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
  'Hari Foto',
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
  'Unggah Foto',
  'form',
  'answer_all_questions',
  'coach_review'
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
  'photo_upload',
  'Unggah foto jawaban'
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
    'pending'
  ),
  (
    '60000000-0000-0000-0000-000000000002',
    '50000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    'pending'
  );

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000011","role":"authenticated"}';

select extensions.lives_ok(
  $$
    insert into storage.objects (
      bucket_id,
      name,
      metadata
    )
    values (
      'question-photos',
      '00000000-0000-0000-0000-000000000011/'
        || '50000000-0000-0000-0000-000000000001/'
        || '60000000-0000-0000-0000-000000000001/'
        || '40000000-0000-0000-0000-000000000001/'
        || '90000000-0000-0000-0000-000000000001.jpg',
      '{"cacheControl":"3600","mimetype":"image/jpeg"}'
    )
  $$,
  'Participant can upload a valid relationally bound private path'
);
select extensions.is(
  (
    select count(*)::bigint
    from storage.objects
    where bucket_id = 'question-photos'
  ),
  1::bigint,
  'Participant can read their own private object'
);
select extensions.throws_like(
  $$
    insert into storage.objects (
      bucket_id,
      name,
      metadata
    )
    values (
      'question-photos',
      '00000000-0000-0000-0000-000000000011/'
        || '50000000-0000-0000-0000-000000000002/'
        || '60000000-0000-0000-0000-000000000002/'
        || '40000000-0000-0000-0000-000000000001/'
        || '90000000-0000-0000-0000-000000000002.jpg',
      '{"mimetype":"image/jpeg"}'
    )
  $$,
  '%row-level security policy%',
  'Participant cannot combine their identity with another enrollment'
);
select extensions.throws_like(
  $$
    insert into storage.objects (
      bucket_id,
      name,
      metadata
    )
    values (
      'question-photos',
      '00000000-0000-0000-0000-000000000011/not-a-valid-path.png',
      '{"mimetype":"image/png"}'
    )
  $$,
  '%row-level security policy%',
  'Malformed or non-JPEG object paths are rejected'
);
select extensions.lives_ok(
  $$
    update storage.objects
    set metadata = '{"cacheControl":"60","mimetype":"image/jpeg"}'
    where bucket_id = 'question-photos'
  $$,
  'Owner can replace or update a pending private object'
);
select extensions.is(
  (
    select metadata ->> 'cacheControl'
    from storage.objects
    where bucket_id = 'question-photos'
  ),
  '60',
  'Owner replacement changed only their object metadata'
);

set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000002","role":"authenticated"}';

select extensions.is(
  (
    select count(*)::bigint
    from storage.objects
    where bucket_id = 'question-photos'
  ),
  1::bigint,
  'Assigned Coach can read private question media'
);
update storage.objects
set metadata = '{"cacheControl":"coach-write","mimetype":"image/jpeg"}'
where bucket_id = 'question-photos';
select extensions.is(
  (
    select metadata ->> 'cacheControl'
    from storage.objects
    where bucket_id = 'question-photos'
  ),
  '60',
  'Coach cannot replace Participant private media'
);

set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000003","role":"authenticated"}';

select extensions.is(
  (
    select count(*)::bigint
    from storage.objects
    where bucket_id = 'question-photos'
  ),
  0::bigint,
  'Unrelated Coach cannot read private question media'
);

set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000012","role":"authenticated"}';

select extensions.is(
  (
    select count(*)::bigint
    from storage.objects
    where bucket_id = 'question-photos'
  ),
  0::bigint,
  'Unrelated Participant cannot read private question media'
);
select extensions.throws_like(
  $$
    insert into storage.objects (
      bucket_id,
      name,
      metadata
    )
    values (
      'public-media',
      'participant-cannot-publish.jpg',
      '{"mimetype":"image/jpeg"}'
    )
  $$,
  '%row-level security policy%',
  'Participant cannot publish public media'
);

set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}';

select extensions.is(
  (
    select count(*)::bigint
    from storage.objects
    where bucket_id = 'question-photos'
  ),
  1::bigint,
  'Admin can read private question media'
);
select extensions.lives_ok(
  $$
    insert into storage.objects (
      bucket_id,
      name,
      metadata
    )
    values (
      'public-media',
      'programs/10000000-0000-0000-0000-000000000001/cover.jpg',
      '{"mimetype":"image/jpeg"}'
    )
  $$,
  'Admin can publish public media'
);

reset role;
update public.step_submissions
set status = 'approved'
where id = '60000000-0000-0000-0000-000000000001';

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000011","role":"authenticated"}';

update storage.objects
set metadata = '{"cacheControl":"after-review","mimetype":"image/jpeg"}'
where bucket_id = 'question-photos';
select extensions.is(
  (
    select metadata ->> 'cacheControl'
    from storage.objects
    where bucket_id = 'question-photos'
  ),
  '60',
  'Participant cannot replace media after submission review'
);

reset role;

select * from extensions.finish();
rollback;
