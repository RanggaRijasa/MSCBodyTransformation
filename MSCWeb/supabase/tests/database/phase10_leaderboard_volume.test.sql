begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(3);

insert into auth.users(
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
select
  ('fb000000-0000-4000-8000-' || lpad(value::text, 12, '0'))::uuid,
  'authenticated', 'authenticated',
  'phase10-volume-' || value || '@test.invalid', '', now(),
  '{"provider":"email","providers":["email"]}', '{}', now(), now()
from generate_series(0, 250) value;

update public.profiles
set onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null,
  display_name = case when user_id = 'fb000000-0000-4000-8000-000000000000'
    then 'Admin Volume Phase 10'
    else 'Peserta Volume ' || substring(user_id::text from 25) end,
  role = case when user_id = 'fb000000-0000-4000-8000-000000000000'
    then 'admin' else 'participant' end
where user_id::text like 'fb000000-0000-4000-8000-%';

insert into public.programs(
  id, title, summary, status, pace, duration_mode, starts_on, ends_on,
  timezone, past_step_policy, future_step_policy, wellness_disclaimer,
  points_per_activity, points_per_weight_kg, quiz_passing_percentage,
  pricing_mode, created_by, published_at
) values (
  'fb100000-0000-4000-8000-000000000001', 'Program Volume Phase 10',
  'Fixture volume leaderboard.', 'active', 'scheduled', 'fixed_duration',
  current_date, current_date, 'Asia/Makassar', 'available', 'locked',
  'Program kebugaran non-diagnostik.', 10, 0, 70, 'free',
  'fb000000-0000-4000-8000-000000000000', now()
);

insert into public.program_enrollments(
  id, program_id, participant_id, coach_id, status
)
select
  ('fb200000-0000-4000-8000-' || lpad(value::text, 12, '0'))::uuid,
  'fb100000-0000-4000-8000-000000000001',
  ('fb000000-0000-4000-8000-' || lpad(value::text, 12, '0'))::uuid,
  'fb000000-0000-4000-8000-000000000000', 'active'
from generate_series(1, 250) value;

alter table public.program_scores disable trigger rank_program_scores_stably;
insert into public.program_scores(
  enrollment_id, activity_points, adjustment_points, progress_percentage, rank
)
select
  ('fb200000-0000-4000-8000-' || lpad(value::text, 12, '0'))::uuid,
  251 - value, 0, value % 101, value
from generate_series(1, 250) value;
alter table public.program_scores enable trigger rank_program_scores_stably;

select extensions.is(
  (select count(*)::integer from public.list_public_leaderboard(
    'fb100000-0000-4000-8000-000000000001', 100, 0
  )),
  100, 'leaderboard returns a bounded first page from 250 participants'
);
select extensions.is(
  (select (entry ->> 'rank')::integer from public.list_public_leaderboard(
    'fb100000-0000-4000-8000-000000000001', 1, 199
  ) entry),
  200, 'leaderboard keeps stable rank across deep pagination'
);
select extensions.performs_ok(
  $$ select * from public.list_public_leaderboard(
    'fb100000-0000-4000-8000-000000000001', 100, 100
  ) $$,
  1000, '100-row leaderboard page resolves within one second locally'
);

select * from extensions.finish();
rollback;
