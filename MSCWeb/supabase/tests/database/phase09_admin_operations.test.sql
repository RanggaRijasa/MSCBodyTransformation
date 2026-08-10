begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(20);

insert into auth.users(id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('f9000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'p9-admin@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('f9000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'p9-participant@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());

update public.profiles set role = 'admin', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null
where user_id = 'f9000000-0000-4000-8000-000000000001';
update public.profiles set role = 'participant', onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null
where user_id = 'f9000000-0000-4000-8000-000000000002';

insert into public.programs(
  id, title, summary, status, pace, duration_mode, starts_on, ends_on,
  timezone, past_step_policy, future_step_policy, wellness_disclaimer,
  points_per_activity, points_per_weight_kg, quiz_passing_percentage,
  pricing_mode, created_by, published_at
) values (
  'f9100000-0000-4000-8000-000000000001', 'Program Admin Phase 09',
  'Fixture lifecycle Admin.', 'completed', 'scheduled', 'fixed_duration',
  current_date - 7, current_date - 1, 'Asia/Makassar', 'available', 'locked',
  'Program wellness non-diagnostik.', 10, 0, 70, 'free',
  'f9000000-0000-4000-8000-000000000001', now() - interval '8 days'
);

insert into storage.objects(bucket_id, name, metadata)
values
  ('public-media', 'winners/phase09-poster-a.jpg', '{"mimetype":"image/jpeg"}'::jsonb),
  ('public-media', 'winners/phase09-poster-b.jpg', '{"mimetype":"image/jpeg"}'::jsonb);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"f9000000-0000-4000-8000-000000000002","role":"authenticated"}';

select extensions.throws_like(
  $$ select public.archive_program('f9100000-0000-4000-8000-000000000001', 'Tidak berwenang.', 'p9-participant-archive') $$,
  'permission_denied', 'Participant cannot archive a program'
);
select extensions.throws_like(
  $$ select public.manage_winner_poster('f9300000-0000-4000-8000-000000000001', 'f9100000-0000-4000-8000-000000000001', null, 'winners/phase09-poster-a.jpg', 'Poster', 'add', 'Tidak berwenang.', 'p9-participant-poster') $$,
  'permission_denied', 'Participant cannot manage winner posters'
);

set local "request.jwt.claims" =
  '{"sub":"f9000000-0000-4000-8000-000000000001","role":"authenticated"}';

select extensions.throws_like(
  $$ select public.archive_program('f9100000-0000-4000-8000-000000000001', '', 'p9-archive-no-reason') $$,
  'reason_required', 'archive requires a reason'
);
select extensions.throws_like(
  $$ select public.archive_program('f9100000-0000-4000-8000-000000000001', 'Arsip setelah pemenang.', 'p9-archive-before-lock') $$,
  'winners_not_locked', 'archive requires a locked winner snapshot'
);

reset role;
insert into public.winner_snapshots(id, program_id, locked_by, idempotency_key)
values ('f9200000-0000-4000-8000-000000000001', 'f9100000-0000-4000-8000-000000000001', 'f9000000-0000-4000-8000-000000000001', 'p9-existing-snapshot');
set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"f9000000-0000-4000-8000-000000000001","role":"authenticated"}';

select extensions.lives_ok(
  $$ select public.archive_program('f9100000-0000-4000-8000-000000000001', 'Operasional program selesai.', 'p9-archive-once') $$,
  'Admin archives a completed program after winner lock'
);
select extensions.lives_ok(
  $$ select public.archive_program('f9100000-0000-4000-8000-000000000001', 'Operasional program selesai.', 'p9-archive-once') $$,
  'archive replay is idempotent'
);
select extensions.is(
  (select status from public.programs where id = 'f9100000-0000-4000-8000-000000000001'),
  'archived', 'program persists archived state'
);
select extensions.is(
  (select count(*)::bigint from public.audit_events where kind = 'program_archived' and subject_id = 'f9100000-0000-4000-8000-000000000001'),
  1::bigint, 'archive writes exactly one audit event'
);

select extensions.throws_like(
  $$ select public.manage_winner_poster('f9300000-0000-4000-8000-000000000001', 'f9100000-0000-4000-8000-000000000001', 'f9200000-0000-4000-8000-000000000001', 'winners/missing.jpg', 'Poster pemenang', 'add', 'Tambah poster.', 'p9-poster-missing') $$,
  'media_not_found', 'poster cannot reference a missing public asset'
);
select extensions.lives_ok(
  $$ select public.manage_winner_poster('f9300000-0000-4000-8000-000000000001', 'f9100000-0000-4000-8000-000000000001', 'f9200000-0000-4000-8000-000000000001', 'winners/phase09-poster-a.jpg', 'Poster lima pemenang', 'add', 'Tambah draft poster.', 'p9-poster-add') $$,
  'Admin adds an unpublished winner poster'
);
select extensions.lives_ok(
  $$ select public.manage_winner_poster('f9300000-0000-4000-8000-000000000001', 'f9100000-0000-4000-8000-000000000001', 'f9200000-0000-4000-8000-000000000001', 'winners/phase09-poster-a.jpg', 'Poster lima pemenang', 'add', 'Tambah draft poster.', 'p9-poster-add') $$,
  'poster add replay is idempotent'
);
select extensions.is(
  (select count(*)::bigint from public.winner_posters where id = 'f9300000-0000-4000-8000-000000000001'),
  1::bigint, 'poster replay does not duplicate content'
);
select extensions.is(
  (select is_published from public.winner_posters where id = 'f9300000-0000-4000-8000-000000000001'),
  false, 'new poster remains draft'
);
select extensions.lives_ok(
  $$ select public.manage_winner_poster('f9300000-0000-4000-8000-000000000001', null, null, null, null, 'publish', 'Pratinjau telah diperiksa.', 'p9-poster-publish') $$,
  'Admin publishes a poster explicitly'
);
select extensions.ok(
  (select is_published and published_at is not null from public.winner_posters where id = 'f9300000-0000-4000-8000-000000000001'),
  'publication state and timestamp are persisted'
);
select extensions.lives_ok(
  $$ select public.manage_winner_poster('f9300000-0000-4000-8000-000000000001', null, null, 'winners/phase09-poster-b.jpg', 'Poster pemenang revisi', 'replace', 'Perbaikan visual poster.', 'p9-poster-replace') $$,
  'replacement returns poster to draft'
);
select extensions.ok(
  (select not is_published and media_path = 'winners/phase09-poster-b.jpg' from public.winner_posters where id = 'f9300000-0000-4000-8000-000000000001'),
  'replacement does not alter winner snapshot ownership'
);
select extensions.lives_ok(
  $$ select public.manage_winner_poster('f9300000-0000-4000-8000-000000000001', null, null, null, null, 'delete', 'Poster tidak lagi digunakan.', 'p9-poster-delete') $$,
  'Admin soft deletes managed poster'
);
select extensions.ok(
  (select deleted_at is not null and not is_published from public.winner_posters where id = 'f9300000-0000-4000-8000-000000000001'),
  'deleted poster is never public'
);
select extensions.is(
  (select count(*)::bigint from public.audit_events where kind = 'managed_content_updated' and subject_id = 'f9300000-0000-4000-8000-000000000001'),
  4::bigint, 'add, publish, replace, and delete each write one audit event'
);

select * from extensions.finish();
rollback;
