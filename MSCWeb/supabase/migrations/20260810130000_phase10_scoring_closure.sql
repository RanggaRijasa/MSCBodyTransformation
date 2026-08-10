-- Phase 10: authoritative scoring/ranking parity, closure preflight, controlled
-- reopen, and post-close mutation guards. This migration is additive and is
-- exercised only against local Supabase until the production deployment gate.

alter table public.programs
  add column if not exists reopen_idempotency_key text,
  add constraint programs_reopen_idempotency_key_shape check (
    reopen_idempotency_key is null
    or length(reopen_idempotency_key) between 8 and 128
  );

create or replace function private.prevent_enrolled_scoring_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (
    old.points_per_activity is distinct from new.points_per_activity
    or old.points_per_weight_kg is distinct from new.points_per_weight_kg
    or old.quiz_passing_percentage is distinct from new.quiz_passing_percentage
  ) and exists (
    select 1 from public.program_enrollments enrollment
    where enrollment.program_id = old.id
  ) then
    raise exception 'scoring_configuration_locked';
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_enrolled_scoring_change on public.programs;
create trigger prevent_enrolled_scoring_change
before update of points_per_activity, points_per_weight_kg,
  quiz_passing_percentage on public.programs
for each row execute function private.prevent_enrolled_scoring_change();

create or replace function private.prevent_closed_runtime_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_enrollment_id uuid;
  target_status text;
begin
  if tg_table_name = 'quiz_attempt_results' then
    select submission.enrollment_id into target_enrollment_id
    from public.step_submissions submission
    where submission.id = new.submission_id;
  else
    target_enrollment_id := new.enrollment_id;
  end if;

  select program.status into target_status
  from public.program_enrollments enrollment
  join public.programs program on program.id = enrollment.program_id
  where enrollment.id = target_enrollment_id;

  if target_status in ('completed', 'archived') then
    raise exception 'program_closed';
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_closed_score_adjustment on public.score_adjustments;
create trigger prevent_closed_score_adjustment
before insert on public.score_adjustments
for each row execute function private.prevent_closed_runtime_mutation();

drop trigger if exists prevent_closed_weigh_in_mutation on public.weigh_ins;
create trigger prevent_closed_weigh_in_mutation
before insert or update on public.weigh_ins
for each row execute function private.prevent_closed_runtime_mutation();

drop trigger if exists prevent_closed_submission_mutation on public.step_submissions;
create trigger prevent_closed_submission_mutation
before insert or update on public.step_submissions
for each row execute function private.prevent_closed_runtime_mutation();

drop trigger if exists prevent_closed_quiz_mutation on public.quiz_attempt_results;
create trigger prevent_closed_quiz_mutation
before insert or update on public.quiz_attempt_results
for each row execute function private.prevent_closed_runtime_mutation();

create or replace function private.rank_program_scores_stably()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_program_id uuid;
begin
  select enrollment.program_id into target_program_id
  from public.program_enrollments enrollment
  where enrollment.id = new.enrollment_id;

  with ranked as (
    select score.enrollment_id,
      row_number() over (
        order by
          (score.activity_points + score.quiz_points + score.weight_points
            + score.adjustment_points) desc,
          score.enrollment_id asc
      )::integer as rank_value
    from public.program_scores score
    join public.program_enrollments enrollment
      on enrollment.id = score.enrollment_id
    where enrollment.program_id = target_program_id
      and enrollment.status in ('active', 'completed')
  )
  update public.program_scores score
  set rank = ranked.rank_value
  from ranked
  where score.enrollment_id = ranked.enrollment_id
    and score.rank is distinct from ranked.rank_value;
  return new;
end;
$$;

drop trigger if exists rank_program_scores_stably on public.program_scores;
create trigger rank_program_scores_stably
after insert or update of activity_points, quiz_points, weight_points,
  adjustment_points on public.program_scores
for each row execute function private.rank_program_scores_stably();

with stable_ranks as (
  select score.enrollment_id,
    row_number() over (
      partition by enrollment.program_id
      order by
        (score.activity_points + score.quiz_points + score.weight_points
          + score.adjustment_points) desc,
        score.enrollment_id asc
    )::integer as rank_value
  from public.program_scores score
  join public.program_enrollments enrollment on enrollment.id = score.enrollment_id
  where enrollment.status in ('active', 'completed')
)
update public.program_scores score
set rank = stable_ranks.rank_value
from stable_ranks
where score.enrollment_id = stable_ranks.enrollment_id
  and score.rank is distinct from stable_ranks.rank_value;

create or replace function public.list_public_leaderboard(
  target_program_id uuid,
  result_limit integer default 100,
  result_offset integer default 0
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if target_program_id is null then raise exception 'program_required'; end if;
  if result_limit not between 1 and 100 or result_offset < 0 then
    raise exception 'pagination_invalid';
  end if;

  return query
  with public_ranking as (
    select score.public_id, score.progress_percentage,
      enrollment.id as enrollment_id,
      enrollment.program_id,
      profile.public_profile_id,
      profile.display_name,
      score.activity_points + score.quiz_points + score.weight_points
        + score.adjustment_points as total_points,
      row_number() over (
        order by
          (score.activity_points + score.quiz_points + score.weight_points
            + score.adjustment_points) desc,
          enrollment.id asc
      )::integer as stable_rank
    from public.program_scores score
    join public.program_enrollments enrollment
      on enrollment.id = score.enrollment_id
    join public.profiles profile on profile.user_id = enrollment.participant_id
    join public.programs program on program.id = enrollment.program_id
    where enrollment.program_id = target_program_id
      and enrollment.status in ('active', 'completed')
      and program.status in ('scheduled', 'active', 'completed', 'archived')
  )
  select jsonb_build_object(
    'id', ranking.public_id,
    'program_id', ranking.program_id,
    'participant_id', ranking.public_profile_id,
    'participant_display_name', ranking.display_name,
    'rank', ranking.stable_rank,
    'progress_percentage', ranking.progress_percentage,
    'total_points', ranking.total_points
  )
  from public_ranking ranking
  order by ranking.stable_rank
  limit result_limit
  offset result_offset;
end;
$$;

create or replace function public.get_program_closure_preflight(
  target_program_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.programs;
  enrollment_record record;
  pending_count integer;
  missing_final_count integer;
  failed_quiz_count integer;
  incomplete_count integer;
  snapshot_id uuid;
  failed_quizzes jsonb;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  select * into target from public.programs where id = target_program_id;
  if target.id is null then raise exception 'program_not_found'; end if;

  for enrollment_record in
    select id from public.program_enrollments
    where program_id = target_program_id and status in ('active', 'completed')
  loop
    perform private.recalculate_enrollment_score(enrollment_record.id);
  end loop;

  select count(*)::integer into pending_count
  from public.step_submissions submission
  join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
  where enrollment.program_id = target_program_id and submission.status = 'pending';

  select case when target.points_per_weight_kg > 0 then count(*) else 0 end::integer
  into missing_final_count
  from public.program_enrollments enrollment
  where enrollment.program_id = target_program_id
    and enrollment.status in ('active', 'completed')
    and not exists (
      select 1 from public.weigh_ins weigh_in
      where weigh_in.enrollment_id = enrollment.id and weigh_in.kind = 'final'
    );

  with latest_quiz as (
    select distinct on (submission.enrollment_id, submission.step_id)
      submission.enrollment_id, submission.step_id, submission.attempt_sequence,
      submission.status, quiz.percentage, quiz.passed,
      profile.display_name, step.title as step_title
    from public.step_submissions submission
    join public.quiz_attempt_results quiz on quiz.submission_id = submission.id
    join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
    join public.profiles profile on profile.user_id = enrollment.participant_id
    join public.program_steps step on step.id = submission.step_id
    where enrollment.program_id = target_program_id
    order by submission.enrollment_id, submission.step_id,
      submission.attempt_sequence desc, submission.id desc
  ), failed as (
    select * from latest_quiz where status = 'approved' and not passed
  )
  select count(*)::integer,
    coalesce(jsonb_agg(jsonb_build_object(
      'enrollment_id', enrollment_id,
      'step_id', step_id,
      'attempt_sequence', attempt_sequence,
      'percentage', percentage,
      'participant_display_name', display_name,
      'step_title', step_title
    ) order by display_name, step_title), '[]'::jsonb)
  into failed_quiz_count, failed_quizzes
  from failed;

  select count(*)::integer into incomplete_count
  from public.program_enrollments enrollment
  left join public.program_scores score on score.enrollment_id = enrollment.id
  where enrollment.program_id = target_program_id
    and enrollment.status in ('active', 'completed')
    and coalesce(score.progress_percentage, 0) < 100;

  select id into snapshot_id from public.winner_snapshots
  where program_id = target_program_id;

  return jsonb_build_object(
    'program_id', target_program_id,
    'status', target.status,
    'pending_reviews', pending_count,
    'missing_final_weights', missing_final_count,
    'failed_quiz_attempts', failed_quiz_count,
    'failed_quizzes', failed_quizzes,
    'incomplete_enrollments', incomplete_count,
    'winner_snapshot_id', snapshot_id,
    'can_complete', target.status in ('scheduled', 'active')
      and pending_count = 0 and missing_final_count = 0
      and failed_quiz_count = 0 and incomplete_count = 0,
    'can_reopen', target.status = 'completed' and snapshot_id is null,
    'can_lock', target.status = 'completed' and snapshot_id is null
      and pending_count = 0 and missing_final_count = 0
      and failed_quiz_count = 0 and incomplete_count = 0
  );
end;
$$;

create or replace function public.complete_program(
  target_program_id uuid,
  reason text,
  request_idempotency_key text
)
returns public.programs
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.programs;
  enrollment_record record;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reason, ''))) = 0 then raise exception 'reason_required'; end if;

  select * into target from public.programs
  where id = target_program_id for update;
  if target.id is null then raise exception 'program_not_found'; end if;
  if target.status = 'completed'
    and target.completion_idempotency_key = request_idempotency_key
  then return target; end if;
  if target.status not in ('scheduled', 'active') then
    raise exception 'program_not_completable';
  end if;

  for enrollment_record in
    select id from public.program_enrollments
    where program_id = target_program_id and status = 'active'
  loop
    perform private.recalculate_enrollment_score(enrollment_record.id);
  end loop;

  if exists (
    select 1 from public.step_submissions submission
    join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
    where enrollment.program_id = target_program_id and submission.status = 'pending'
  ) then raise exception 'pending_reviews_exist'; end if;
  if target.points_per_weight_kg > 0 and exists (
    select 1 from public.program_enrollments enrollment
    where enrollment.program_id = target_program_id and enrollment.status = 'active'
      and not exists (
        select 1 from public.weigh_ins
        where enrollment_id = enrollment.id and kind = 'final'
      )
  ) then raise exception 'final_weight_missing'; end if;
  if exists (
    select 1
    from public.program_enrollments enrollment
    join public.program_scores score on score.enrollment_id = enrollment.id
    where enrollment.program_id = target_program_id
      and enrollment.status = 'active' and score.progress_percentage < 100
  ) then raise exception 'required_activity_incomplete'; end if;

  update public.programs
  set status = 'completed', completion_idempotency_key = request_idempotency_key,
      updated_at = statement_timestamp()
  where id = target.id returning * into target;
  update public.program_enrollments
  set status = 'completed', completed_at = statement_timestamp()
  where program_id = target.id and status = 'active';
  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values ((select auth.uid()), 'program_completed', target.id, trim(reason),
    jsonb_build_object('idempotency_key', request_idempotency_key));
  return target;
end;
$$;

create or replace function public.reopen_program(
  target_program_id uuid,
  reason text,
  request_idempotency_key text
)
returns public.programs
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.programs;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reason, ''))) = 0 then raise exception 'reason_required'; end if;
  select * into target from public.programs
  where id = target_program_id for update;
  if target.id is null then raise exception 'program_not_found'; end if;
  if target.status = 'active' and target.reopen_idempotency_key = request_idempotency_key
  then return target; end if;
  if target.status <> 'completed' then raise exception 'program_not_reopenable'; end if;
  if exists (select 1 from public.winner_snapshots where program_id = target.id) then
    raise exception 'winners_already_locked';
  end if;

  update public.programs
  set status = 'active', reopen_idempotency_key = request_idempotency_key,
      updated_at = statement_timestamp()
  where id = target.id returning * into target;
  update public.program_enrollments
  set status = 'active', completed_at = null
  where program_id = target.id and status = 'completed';
  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values ((select auth.uid()), 'program_reopened', target.id, trim(reason),
    jsonb_build_object('idempotency_key', request_idempotency_key));
  return target;
end;
$$;

create or replace function public.lock_program_winners(
  target_program_id uuid,
  request_idempotency_key text
)
returns setof public.program_winners
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_program public.programs;
  snapshot public.winner_snapshots;
  enrollment_record record;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  select * into target_program from public.programs
  where id = target_program_id for update;
  if target_program.id is null then raise exception 'program_not_found'; end if;
  select * into snapshot from public.winner_snapshots
  where program_id = target_program_id for update;
  if snapshot.id is not null then
    if snapshot.idempotency_key = request_idempotency_key then
      return query select * from public.program_winners
      where snapshot_id = snapshot.id order by rank;
      return;
    end if;
    raise exception 'winners_already_locked';
  end if;
  if target_program.status <> 'completed' then raise exception 'program_not_completed'; end if;

  for enrollment_record in
    select id from public.program_enrollments
    where program_id = target_program_id and status = 'completed'
  loop
    perform private.recalculate_enrollment_score(enrollment_record.id);
  end loop;
  if exists (
    select 1 from public.step_submissions submission
    join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
    where enrollment.program_id = target_program_id and submission.status = 'pending'
  ) then raise exception 'pending_reviews_exist'; end if;
  if target_program.points_per_weight_kg > 0 and exists (
    select 1 from public.program_enrollments enrollment
    where enrollment.program_id = target_program_id and enrollment.status = 'completed'
      and not exists (
        select 1 from public.weigh_ins
        where enrollment_id = enrollment.id and kind = 'final'
      )
  ) then raise exception 'final_weight_missing'; end if;
  if exists (
    select 1 from public.program_enrollments enrollment
    join public.program_scores score on score.enrollment_id = enrollment.id
    where enrollment.program_id = target_program_id
      and enrollment.status = 'completed' and score.progress_percentage < 100
  ) then raise exception 'required_activity_incomplete'; end if;

  insert into public.winner_snapshots(program_id, locked_by, idempotency_key)
  values (target_program_id, (select auth.uid()), request_idempotency_key)
  returning * into snapshot;
  insert into public.program_winners(
    snapshot_id, participant_id, rank, display_name, total_points
  )
  select snapshot.id, enrollment.participant_id,
    row_number() over (
      order by
        (score.activity_points + score.quiz_points + score.weight_points
          + score.adjustment_points) desc,
        enrollment.id asc
    )::integer,
    profile.display_name,
    score.activity_points + score.quiz_points + score.weight_points
      + score.adjustment_points
  from public.program_scores score
  join public.program_enrollments enrollment on enrollment.id = score.enrollment_id
  join public.profiles profile on profile.user_id = enrollment.participant_id
  where enrollment.program_id = target_program_id and enrollment.status = 'completed'
  order by
    (score.activity_points + score.quiz_points + score.weight_points
      + score.adjustment_points) desc,
    enrollment.id asc
  limit 5;
  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values ((select auth.uid()), 'winners_locked', snapshot.id,
    'Pemenang program dikunci.', jsonb_build_object('program_id', target_program_id));
  return query select * from public.program_winners
  where snapshot_id = snapshot.id order by rank;
end;
$$;

revoke execute on function private.prevent_enrolled_scoring_change()
  from public, anon, authenticated, service_role;
revoke execute on function private.prevent_closed_runtime_mutation()
  from public, anon, authenticated, service_role;
revoke execute on function private.rank_program_scores_stably()
  from public, anon, authenticated, service_role;
revoke execute on function public.get_program_closure_preflight(uuid)
  from public, anon, authenticated, service_role;
revoke execute on function public.reopen_program(uuid, text, text)
  from public, anon, authenticated, service_role;
grant execute on function public.get_program_closure_preflight(uuid) to authenticated;
grant execute on function public.reopen_program(uuid, text, text) to authenticated;

revoke execute on function public.complete_program(uuid, text, text)
  from public, anon, authenticated, service_role;
revoke execute on function public.lock_program_winners(uuid, text)
  from public, anon, authenticated, service_role;
grant execute on function public.complete_program(uuid, text, text) to authenticated;
grant execute on function public.lock_program_winners(uuid, text) to authenticated;

revoke execute on function public.list_public_leaderboard(uuid, integer, integer)
  from public, anon, authenticated, service_role;
grant execute on function public.list_public_leaderboard(uuid, integer, integer)
  to anon, authenticated;
