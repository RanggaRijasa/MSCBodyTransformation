create or replace function public.get_my_coach_leaderboard(
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
declare
  caller_id uuid := (select auth.uid());
begin
  if caller_id is null then
    raise exception 'authentication_required';
  end if;
  if not private.has_active_coach_access(caller_id) then
    raise exception 'coach_entitlement_inactive';
  end if;
  if target_program_id is null then
    raise exception 'program_required';
  end if;
  if result_limit not between 1 and 100 or result_offset < 0 then
    raise exception 'pagination_invalid';
  end if;

  return query
  with ranked as (
    select
      score.public_id as id,
      enrollment.program_id,
      profile.public_profile_id as participant_id,
      profile.display_name as participant_display_name,
      profile.provider_avatar_url as private_avatar_url,
      enrollment.coach_id = caller_id as is_assigned_to_coach,
      coalesce(
        score.rank,
        row_number() over (
          order by
            score.activity_points + score.quiz_points
              + score.weight_points + score.adjustment_points desc,
            profile.display_name,
            score.public_id
        )::integer
      ) as rank,
      score.progress_percentage,
      score.activity_points + score.quiz_points
        + score.weight_points + score.adjustment_points as total_points,
      score.activity_points + score.quiz_points as step_points,
      score.weight_points,
      score.adjustment_points
    from public.program_scores score
    join public.program_enrollments enrollment
      on enrollment.id = score.enrollment_id
    join public.profiles profile
      on profile.user_id = enrollment.participant_id
    join public.programs program
      on program.id = enrollment.program_id
    where enrollment.program_id = target_program_id
      and enrollment.status in ('active', 'completed')
      and program.status in ('scheduled', 'active', 'completed', 'archived')
  )
  select jsonb_build_object(
    'id', ranked.id,
    'program_id', ranked.program_id,
    'participant_id', ranked.participant_id,
    'participant_display_name', ranked.participant_display_name,
    'avatar_url', case when ranked.is_assigned_to_coach then ranked.private_avatar_url else null end,
    'rank', ranked.rank,
    'progress_percentage', ranked.progress_percentage,
    'total_points', ranked.total_points,
    'is_assigned_to_coach', ranked.is_assigned_to_coach,
    'step_points', case when ranked.is_assigned_to_coach then ranked.step_points else null end,
    'weight_points', case when ranked.is_assigned_to_coach then ranked.weight_points else null end,
    'adjustment_points', case when ranked.is_assigned_to_coach then ranked.adjustment_points else null end
  )
  from ranked
  order by ranked.rank, ranked.participant_display_name, ranked.id
  limit result_limit
  offset result_offset;
end;
$$;

revoke all on function public.get_my_coach_leaderboard(uuid, integer, integer) from public;
revoke all on function public.get_my_coach_leaderboard(uuid, integer, integer) from anon;
revoke all on function public.get_my_coach_leaderboard(uuid, integer, integer) from authenticated;
revoke all on function public.get_my_coach_leaderboard(uuid, integer, integer) from service_role;
grant execute on function public.get_my_coach_leaderboard(uuid, integer, integer) to authenticated;
