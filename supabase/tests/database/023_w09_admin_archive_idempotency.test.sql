begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(10);

select extensions.has_column(
  'public', 'programs', 'archive_idempotency_key',
  'program archive idempotency column is part of the canonical schema'
);
select extensions.has_column(
  'public', 'winner_posters', 'mutation_idempotency_key',
  'poster archive idempotency column is part of the canonical schema'
);
select extensions.has_column(
  'public', 'winner_posters', 'deleted_at',
  'poster archive timestamp is part of the canonical schema'
);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  'fb000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
  'w09-admin-archive@test.invalid', '', now(),
  '{"provider":"email","providers":["email"]}', '{}', now(), now()
);

update public.profiles
set role = 'admin', display_name = 'Admin Archive W09',
  onboarding_status = 'active', provisional_expires_at = null,
  finalized_at = now()
where user_id = 'fb000000-0000-0000-0000-000000000001';

insert into public.programs (
  id, title, summary, status, pace, duration_mode, starts_on, ends_on,
  timezone, past_step_policy, future_step_policy, wellness_disclaimer,
  points_per_activity, points_per_weight_kg, quiz_passing_percentage,
  pricing_mode, desired_price, created_by
) values (
  'fb000000-0000-0000-0000-000000000010', 'Program Arsip W09',
  'Fixture arsip yang selalu di-rollback.', 'completed',
  'scheduled', 'specific_dates', current_date - 2, current_date - 1,
  'Asia/Jakarta', 'available', 'locked', 'Program wellness non-diagnostik.',
  10, 0, 70, 'free', null, 'fb000000-0000-0000-0000-000000000001'
);

insert into public.winner_snapshots(id, program_id, locked_by)
values (
  'fb000000-0000-0000-0000-000000000020',
  'fb000000-0000-0000-0000-000000000010',
  'fb000000-0000-0000-0000-000000000001'
);

insert into public.winner_posters(
  id, program_id, winner_snapshot_id, media_path, alt_text,
  is_published, published_at
) values (
  'fb000000-0000-0000-0000-000000000030',
  'fb000000-0000-0000-0000-000000000010',
  'fb000000-0000-0000-0000-000000000020',
  'w09/archive-fixture.jpg', 'Poster pemenang sintetis W09.', true, now()
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"fb000000-0000-0000-0000-000000000001","role":"authenticated"}';

select extensions.lives_ok(
  $$ select public.archive_admin_winner_poster(
    'fb000000-0000-0000-0000-000000000030',
    'Arsip fixture poster W09.', 'w09-poster-archive-key'
  ) $$,
  'Admin can archive a winner poster'
);
select extensions.lives_ok(
  $$ select public.archive_admin_winner_poster(
    'fb000000-0000-0000-0000-000000000030',
    'Arsip fixture poster W09.', 'w09-poster-archive-key'
  ) $$,
  'repeating poster archive with the same key is idempotent'
);
select extensions.is(
  (select is_published from public.winner_posters
   where id = 'fb000000-0000-0000-0000-000000000030'),
  false,
  'archived poster is unpublished'
);
select extensions.ok(
  (select deleted_at is not null from public.winner_posters
   where id = 'fb000000-0000-0000-0000-000000000030'),
  'archived poster records its deletion timestamp'
);

select extensions.lives_ok(
  $$ select public.archive_admin_program(
    'fb000000-0000-0000-0000-000000000010',
    'Arsip fixture program W09.', 'w09-program-archive-key'
  ) $$,
  'Admin can archive a completed program'
);
select extensions.lives_ok(
  $$ select public.archive_admin_program(
    'fb000000-0000-0000-0000-000000000010',
    'Arsip fixture program W09.', 'w09-program-archive-key'
  ) $$,
  'repeating program archive with the same key is idempotent'
);
select extensions.is(
  (select status from public.programs
   where id = 'fb000000-0000-0000-0000-000000000010'),
  'archived',
  'program becomes archived'
);

select * from extensions.finish();
rollback;
