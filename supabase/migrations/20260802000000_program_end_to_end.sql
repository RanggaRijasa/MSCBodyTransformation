create extension if not exists pgcrypto;
create schema if not exists private;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('participant', 'coach', 'admin')),
  display_name text not null check (length(trim(display_name)) > 0),
  city text not null default '',
  phone_number text,
  current_coach_id uuid,
  coach_qr_identifier text unique,
  coach_is_approved boolean not null default false,
  coach_is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint participant_coach_shape check (
    (role = 'participant' and coach_qr_identifier is null)
    or role <> 'participant'
  )
);

alter table public.profiles
  add constraint profiles_current_coach_fk
  foreign key (current_coach_id) references public.profiles(user_id);

create table public.programs (
  id uuid primary key default gen_random_uuid(),
  source_program_id uuid references public.programs(id),
  title text not null check (length(trim(title)) > 0),
  summary text not null default '',
  category text,
  cover_path text,
  cover_alt_text text,
  status text not null check (
    status in (
      'draft', 'preparing_commerce', 'scheduled', 'active',
      'completed', 'archived'
    )
  ),
  pace text not null check (pace in ('scheduled', 'self_paced')),
  duration_mode text not null check (
    duration_mode in ('fixed_duration', 'specific_dates')
  ),
  starts_on date not null,
  ends_on date not null,
  timezone text not null,
  participant_limit integer check (participant_limit > 0),
  past_step_policy text not null check (
    past_step_policy in ('available', 'read_only', 'hidden')
  ),
  future_step_policy text not null check (
    future_step_policy in ('available', 'locked', 'hidden')
  ),
  wellness_disclaimer text not null,
  points_per_activity integer not null check (points_per_activity >= 0),
  points_per_weight_kg numeric(12, 2) not null
    check (points_per_weight_kg >= 0),
  quiz_passing_percentage integer not null
    check (quiz_passing_percentage between 0 and 100),
  pricing_mode text not null check (pricing_mode in ('free', 'paid')),
  desired_price numeric(14, 2),
  published_at timestamptz,
  created_by uuid not null references public.profiles(user_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_on >= starts_on),
  check (
    (pricing_mode = 'free' and desired_price is null)
    or (pricing_mode = 'paid' and desired_price > 0)
  )
);

create table public.program_days (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs(id) on delete cascade,
  day_number integer not null check (day_number > 0),
  title text not null,
  summary text,
  scheduled_on date not null,
  unique (program_id, day_number),
  unique (program_id, scheduled_on)
);

create table public.program_steps (
  id uuid primary key default gen_random_uuid(),
  program_day_id uuid not null
    references public.program_days(id) on delete cascade,
  step_order integer not null check (step_order > 0),
  title text not null check (length(trim(title)) > 0),
  instructions text not null default '',
  content_kind text not null check (
    content_kind in (
      'article', 'video', 'form', 'quiz',
      'initial_weigh_in', 'daily_weigh_in', 'final_weigh_in'
    )
  ),
  completion_policy text not null check (
    completion_policy in (
      'mark_complete', 'answer_all_questions', 'watch_video',
      'automatic_quiz', 'submit_weigh_in'
    )
  ),
  verification_mode text not null check (
    verification_mode in ('automatic', 'coach_review')
  ),
  media_path text,
  media_alt_text text,
  video_required boolean not null default false,
  video_threshold integer check (video_threshold between 0 and 100),
  video_autoplay boolean not null default false,
  unique (program_day_id, step_order)
);

create table public.program_questions (
  id uuid primary key default gen_random_uuid(),
  step_id uuid not null references public.program_steps(id) on delete cascade,
  question_order integer not null check (question_order > 0),
  kind text not null check (
    kind in (
      'short_answer', 'long_answer', 'number', 'single_choice',
      'multiple_choice', 'image_choice', 'photo_upload', 'heading', 'text'
    )
  ),
  prompt text not null,
  unique (step_id, question_order)
);

create table public.program_question_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null
    references public.program_questions(id) on delete cascade,
  option_order integer not null check (option_order > 0),
  title text not null,
  media_path text,
  media_alt_text text,
  unique (question_id, option_order)
);

create table public.program_answer_keys (
  question_id uuid primary key
    references public.program_questions(id) on delete cascade,
  accepted_text_values text[] not null default '{}',
  number_value numeric,
  selected_option_ids uuid[] not null default '{}',
  matching_mode text not null default 'exact'
    check (matching_mode in ('exact', 'case_insensitive_text'))
);

create table public.program_store_products (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs(id) on delete restrict,
  platform text not null check (platform in ('app_store', 'play_store')),
  environment text not null check (
    environment in ('sandbox', 'staging', 'production')
  ),
  product_id text not null,
  external_product_id text,
  provisioning_status text not null check (
    provisioning_status in (
      'not_requested', 'provisioning', 'waiting_for_store', 'ready',
      'action_required', 'retired'
    )
  ),
  actual_price numeric(14, 2),
  currency_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (platform, environment, product_id),
  unique (program_id, platform, environment)
);

create table public.program_enrollments (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs(id) on delete restrict,
  participant_id uuid not null references public.profiles(user_id),
  coach_id uuid not null references public.profiles(user_id),
  status text not null check (
    status in (
      'initiated', 'waiting_for_payment', 'active', 'completed',
      'cancelled', 'refunded'
    )
  ),
  enrolled_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (program_id, participant_id)
);

create table public.step_submissions (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null
    references public.program_enrollments(id) on delete cascade,
  step_id uuid not null references public.program_steps(id),
  attempt_sequence integer not null default 1 check (attempt_sequence > 0),
  status text not null check (status in ('pending', 'approved', 'rejected')),
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewer_id uuid references public.profiles(user_id),
  review_note text,
  supersedes_submission_id uuid references public.step_submissions(id),
  unique (enrollment_id, step_id, attempt_sequence)
);

create table public.step_submission_answers (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null
    references public.step_submissions(id) on delete cascade,
  question_id uuid not null references public.program_questions(id),
  text_value text,
  number_value numeric,
  selected_option_ids uuid[] not null default '{}',
  private_photo_path text,
  unique (submission_id, question_id),
  check (
    text_value is not null or number_value is not null
    or cardinality(selected_option_ids) > 0 or private_photo_path is not null
  )
);

create table public.quiz_attempt_results (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null unique
    references public.step_submissions(id) on delete cascade,
  correct_count integer not null check (correct_count >= 0),
  total_count integer not null check (total_count > 0),
  percentage integer not null check (percentage between 0 and 100),
  passed boolean not null,
  awarded_points integer not null check (awarded_points >= 0),
  reopened_at timestamptz,
  reopened_by uuid references public.profiles(user_id),
  reopen_reason text
);

create table public.weigh_ins (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null
    references public.program_enrollments(id) on delete cascade,
  step_id uuid not null references public.program_steps(id),
  kind text not null check (kind in ('initial', 'daily', 'final')),
  weight_kg numeric(6, 2) not null check (
    weight_kg between 20 and 400
  ),
  recorded_at timestamptz not null default now(),
  corrected_at timestamptz,
  corrected_by uuid references public.profiles(user_id),
  correction_reason text,
  unique (enrollment_id, step_id)
);

create unique index weigh_ins_one_initial_per_enrollment
  on public.weigh_ins (enrollment_id)
  where kind = 'initial';

create unique index weigh_ins_one_final_per_enrollment
  on public.weigh_ins (enrollment_id)
  where kind = 'final';

create table public.program_scores (
  enrollment_id uuid primary key
    references public.program_enrollments(id) on delete cascade,
  activity_points integer not null default 0,
  quiz_points integer not null default 0,
  weight_points integer not null default 0,
  adjustment_points integer not null default 0,
  progress_percentage integer not null default 0
    check (progress_percentage between 0 and 100),
  rank integer,
  recalculated_at timestamptz not null default now()
);

create table public.score_adjustments (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null
    references public.program_enrollments(id) on delete cascade,
  points integer not null,
  reason text not null check (length(trim(reason)) > 0),
  actor_id uuid not null references public.profiles(user_id),
  created_at timestamptz not null default now()
);

create table public.commerce_transactions (
  id uuid primary key default gen_random_uuid(),
  platform text not null check (platform in ('app_store', 'play_store')),
  environment text not null,
  external_transaction_id text not null,
  program_id uuid not null references public.programs(id),
  participant_id uuid not null references public.profiles(user_id),
  product_id text not null,
  status text not null check (
    status in ('verified', 'pending', 'refunded', 'revoked')
  ),
  signed_payload_hash text not null,
  purchased_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (platform, environment, external_transaction_id)
);

create table public.program_entitlements (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs(id),
  participant_id uuid not null references public.profiles(user_id),
  transaction_id uuid references public.commerce_transactions(id),
  status text not null check (
    status in ('active', 'revoked', 'refunded')
  ),
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  unique (program_id, participant_id)
);

create table public.winner_snapshots (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null unique references public.programs(id),
  locked_by uuid not null references public.profiles(user_id),
  locked_at timestamptz not null default now()
);

create table public.program_winners (
  id uuid primary key default gen_random_uuid(),
  snapshot_id uuid not null
    references public.winner_snapshots(id) on delete cascade,
  participant_id uuid not null references public.profiles(user_id),
  rank integer not null check (rank between 1 and 5),
  display_name text not null,
  total_points integer not null,
  unique (snapshot_id, rank),
  unique (snapshot_id, participant_id)
);

create table public.winner_posters (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs(id),
  winner_snapshot_id uuid not null
    references public.winner_snapshots(id),
  media_path text not null,
  alt_text text not null,
  is_published boolean not null default false,
  published_at timestamptz
);

create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(user_id),
  kind text not null,
  subject_id uuid not null,
  summary text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index profiles_current_coach_idx on public.profiles(current_coach_id);
create index program_days_program_idx on public.program_days(program_id);
create index enrollments_participant_idx
  on public.program_enrollments(participant_id);
create index enrollments_coach_idx on public.program_enrollments(coach_id);
create index submissions_enrollment_status_idx
  on public.step_submissions(enrollment_id, status);
create index answers_submission_idx
  on public.step_submission_answers(submission_id);
create index scores_rank_idx
  on public.program_scores(rank, enrollment_id);

create or replace function private.is_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.user_id = (select auth.uid()) and p.role = 'admin'
  );
$$;

create or replace function private.can_coach_participant(
  target_participant uuid
)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.user_id = target_participant
      and p.current_coach_id = (select auth.uid())
  );
$$;

alter table public.profiles enable row level security;
alter table public.programs enable row level security;
alter table public.program_days enable row level security;
alter table public.program_steps enable row level security;
alter table public.program_questions enable row level security;
alter table public.program_question_options enable row level security;
alter table public.program_answer_keys enable row level security;
alter table public.program_store_products enable row level security;
alter table public.program_enrollments enable row level security;
alter table public.step_submissions enable row level security;
alter table public.step_submission_answers enable row level security;
alter table public.quiz_attempt_results enable row level security;
alter table public.weigh_ins enable row level security;
alter table public.program_scores enable row level security;
alter table public.score_adjustments enable row level security;
alter table public.commerce_transactions enable row level security;
alter table public.program_entitlements enable row level security;
alter table public.winner_snapshots enable row level security;
alter table public.program_winners enable row level security;
alter table public.winner_posters enable row level security;
alter table public.audit_events enable row level security;

create policy "profile self coach or admin read"
on public.profiles for select to authenticated
using (
  user_id = (select auth.uid())
  or private.can_coach_participant(user_id)
  or private.is_admin()
);

create policy "published programs readable"
on public.programs for select to authenticated
using (status in ('scheduled', 'active', 'completed', 'archived')
  or private.is_admin());

create policy "program days readable"
on public.program_days for select to authenticated
using (exists (
  select 1 from public.programs p
  where p.id = program_id
    and (p.status <> 'draft' or private.is_admin())
));

create policy "program steps readable"
on public.program_steps for select to authenticated
using (exists (
  select 1 from public.program_days d
  join public.programs p on p.id = d.program_id
  where d.id = program_day_id
    and (p.status <> 'draft' or private.is_admin())
));

create policy "questions readable"
on public.program_questions for select to authenticated
using (exists (
  select 1 from public.program_steps s
  join public.program_days d on d.id = s.program_day_id
  join public.programs p on p.id = d.program_id
  where s.id = step_id
    and (p.status <> 'draft' or private.is_admin())
));

create policy "question options readable"
on public.program_question_options for select to authenticated
using (exists (
  select 1 from public.program_questions q
  where q.id = question_id
));

create policy "answer keys coach or admin"
on public.program_answer_keys for select to authenticated
using (
  private.is_admin()
  or exists (
    select 1
    from public.program_questions q
    join public.program_steps s on s.id = q.step_id
    join public.program_days d on d.id = s.program_day_id
    join public.program_enrollments e on e.program_id = d.program_id
    join public.profiles p on p.user_id = e.participant_id
    where q.id = question_id
      and p.current_coach_id = (select auth.uid())
  )
);

create policy "own or coached enrollments"
on public.program_enrollments for select to authenticated
using (
  participant_id = (select auth.uid())
  or private.can_coach_participant(participant_id)
  or private.is_admin()
);

create policy "own or coached submissions"
on public.step_submissions for select to authenticated
using (exists (
  select 1 from public.program_enrollments e
  where e.id = enrollment_id
    and (
      e.participant_id = (select auth.uid())
      or private.can_coach_participant(e.participant_id)
      or private.is_admin()
    )
));

create policy "own or coached answers"
on public.step_submission_answers for select to authenticated
using (exists (
  select 1 from public.step_submissions s
  join public.program_enrollments e on e.id = s.enrollment_id
  where s.id = submission_id
    and (
      e.participant_id = (select auth.uid())
      or private.can_coach_participant(e.participant_id)
      or private.is_admin()
    )
));

create policy "own or coached quiz results"
on public.quiz_attempt_results for select to authenticated
using (exists (
  select 1 from public.step_submissions s
  join public.program_enrollments e on e.id = s.enrollment_id
  where s.id = submission_id
    and (
      e.participant_id = (select auth.uid())
      or private.can_coach_participant(e.participant_id)
      or private.is_admin()
    )
));

create policy "private weigh in"
on public.weigh_ins for select to authenticated
using (exists (
  select 1 from public.program_enrollments e
  where e.id = enrollment_id
    and (
      e.participant_id = (select auth.uid())
      or private.can_coach_participant(e.participant_id)
      or private.is_admin()
    )
));

create policy "program leaderboard readable"
on public.program_scores for select to authenticated
using (exists (
  select 1 from public.program_enrollments target
  join public.program_enrollments viewer
    on viewer.program_id = target.program_id
  where target.id = enrollment_id
    and viewer.participant_id = (select auth.uid())
    and viewer.status in ('active', 'completed')
) or private.is_admin());

create policy "own transactions"
on public.commerce_transactions for select to authenticated
using (participant_id = (select auth.uid()) or private.is_admin());

create policy "own entitlements"
on public.program_entitlements for select to authenticated
using (participant_id = (select auth.uid()) or private.is_admin());

create policy "winners readable"
on public.winner_snapshots for select to authenticated using (true);
create policy "winner rows readable"
on public.program_winners for select to authenticated using (true);
create policy "published posters readable"
on public.winner_posters for select to authenticated
using (is_published or private.is_admin());

create policy "admin audit read"
on public.audit_events for select to authenticated
using (private.is_admin());

create policy "admin manages programs"
on public.programs for all to authenticated
using (private.is_admin()) with check (private.is_admin());
create policy "admin manages days"
on public.program_days for all to authenticated
using (private.is_admin()) with check (private.is_admin());
create policy "admin manages steps"
on public.program_steps for all to authenticated
using (private.is_admin()) with check (private.is_admin());
create policy "admin manages questions"
on public.program_questions for all to authenticated
using (private.is_admin()) with check (private.is_admin());
create policy "admin manages options"
on public.program_question_options for all to authenticated
using (private.is_admin()) with check (private.is_admin());
create policy "admin manages keys"
on public.program_answer_keys for all to authenticated
using (private.is_admin()) with check (private.is_admin());

create or replace function public.enroll_free_program(
  target_program_id uuid,
  scanned_coach_qr text
)
returns public.program_enrollments
language plpgsql security definer
set search_path = ''
as $$
declare
  participant public.profiles;
  coach public.profiles;
  target_program public.programs;
  result public.program_enrollments;
begin
  select * into participant from public.profiles
  where user_id = (select auth.uid()) and role = 'participant'
  for update;
  if participant.user_id is null then raise exception 'permission_denied'; end if;

  select * into coach from public.profiles
  where coach_qr_identifier = scanned_coach_qr
    and role = 'coach' and coach_is_approved
  for share;
  if coach.user_id is null then raise exception 'coach_qr_invalid'; end if;
  if participant.current_coach_id is not null
    and participant.current_coach_id <> coach.user_id
  then raise exception 'coach_mismatch'; end if;

  select * into target_program from public.programs
  where id = target_program_id
    and status in ('scheduled', 'active')
    and pricing_mode = 'free'
  for update;
  if target_program.id is null then raise exception 'program_unavailable'; end if;

  if target_program.participant_limit is not null and (
    select count(*) from public.program_enrollments
    where program_id = target_program_id
      and status in ('active', 'completed')
  ) >= target_program.participant_limit
  then raise exception 'program_full'; end if;

  update public.profiles set current_coach_id = coach.user_id,
    updated_at = now()
  where user_id = participant.user_id and current_coach_id is null;

  insert into public.program_enrollments (
    program_id, participant_id, coach_id, status
  ) values (
    target_program_id, participant.user_id, coach.user_id, 'active'
  )
  on conflict (program_id, participant_id) do update
    set program_id = excluded.program_id
  returning * into result;

  insert into public.program_scores(enrollment_id)
  values (result.id) on conflict do nothing;
  return result;
end;
$$;

revoke all on function public.enroll_free_program(uuid, text) from public;
grant execute on function public.enroll_free_program(uuid, text)
  to authenticated;

create or replace function public.admin_transfer_coach(
  target_participant_id uuid,
  target_coach_id uuid,
  reason text
)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare old_coach uuid;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(reason)) = 0 then raise exception 'reason_required'; end if;
  if not exists (
    select 1 from public.profiles
    where user_id = target_coach_id and role = 'coach'
      and coach_is_approved
  ) then raise exception 'coach_invalid'; end if;

  select current_coach_id into old_coach from public.profiles
  where user_id = target_participant_id for update;
  update public.profiles set current_coach_id = target_coach_id,
    updated_at = now()
  where user_id = target_participant_id and role = 'participant';
  update public.program_enrollments set coach_id = target_coach_id
  where participant_id = target_participant_id
    and status in ('initiated', 'waiting_for_payment', 'active');
  insert into public.audit_events(
    actor_id, kind, subject_id, summary, payload
  ) values (
    (select auth.uid()), 'coach_transferred', target_participant_id,
    reason, jsonb_build_object(
      'old_coach_id', old_coach, 'new_coach_id', target_coach_id
    )
  );
end;
$$;

revoke all on function public.admin_transfer_coach(uuid, uuid, text)
  from public;
grant execute on function public.admin_transfer_coach(uuid, uuid, text)
  to authenticated;

insert into storage.buckets (id, name, public, file_size_limit)
values
  ('public-media', 'public-media', true, 20971520),
  ('question-photos', 'question-photos', false, 20971520)
on conflict (id) do nothing;

create policy "public media read"
on storage.objects for select
using (bucket_id = 'public-media');

create policy "participant owns question upload"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'question-photos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "private question media read"
on storage.objects for select to authenticated
using (
  bucket_id = 'question-photos'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or private.is_admin()
    or private.can_coach_participant(
      ((storage.foldername(name))[1])::uuid
    )
  )
);
