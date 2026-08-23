-- Keep profile photos visible on every leaderboard surface without exposing
-- Coach Storage object paths. Google/provider avatars are already HTTPS URLs;
-- published Coach avatars remain opaque asset ids resolved by the gateway.

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
  if target_program_id is null then
    raise exception 'program_required';
  end if;
  if result_limit not between 1 and 100 or result_offset < 0 then
    raise exception 'pagination_invalid';
  end if;

  return query
  select jsonb_build_object(
    'id', score.public_id,
    'program_id', enrollment.program_id,
    'participant_id', profile.public_profile_id,
    'participant_display_name', profile.display_name,
    'avatar_url', profile.provider_avatar_url,
    'avatar_reference', case when profile.role = 'coach' then avatar_asset.id end,
    'rank', coalesce(
      score.rank,
      row_number() over (
        order by
          score.activity_points + score.quiz_points
            + score.weight_points + score.adjustment_points desc,
          profile.display_name,
          score.public_id
      )::integer
    ),
    'progress_percentage', score.progress_percentage,
    'total_points', score.activity_points + score.quiz_points
      + score.weight_points + score.adjustment_points
  )
  from public.program_scores score
  join public.program_enrollments enrollment
    on enrollment.id = score.enrollment_id
  join public.profiles profile
    on profile.user_id = enrollment.participant_id
  join public.programs program
    on program.id = enrollment.program_id
  left join public.coach_public_profiles published
    on published.coach_user_id = profile.user_id
    and profile.role = 'coach'
    and profile.coach_is_public
    and profile.coach_is_approved
  left join private.coach_public_media_assets avatar_asset
    on avatar_asset.coach_user_id = published.coach_user_id
    and avatar_asset.object_path = published.photo_reference
    and avatar_asset.media_folder = 'avatar'
  where enrollment.program_id = target_program_id
    and enrollment.status in ('active', 'completed')
    and program.status in ('scheduled', 'active', 'completed', 'archived')
  order by
    score.activity_points + score.quiz_points
      + score.weight_points + score.adjustment_points desc,
    profile.display_name,
    score.public_id
  limit result_limit
  offset result_offset;
end;
$$;

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
      profile.provider_avatar_url as avatar_url,
      case when profile.role = 'coach' then avatar_asset.id end as avatar_reference,
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
    left join public.coach_public_profiles published
      on published.coach_user_id = profile.user_id
      and profile.role = 'coach'
      and profile.coach_is_public
      and profile.coach_is_approved
    left join private.coach_public_media_assets avatar_asset
      on avatar_asset.coach_user_id = published.coach_user_id
      and avatar_asset.object_path = published.photo_reference
      and avatar_asset.media_folder = 'avatar'
    where enrollment.program_id = target_program_id
      and enrollment.status in ('active', 'completed')
      and program.status in ('scheduled', 'active', 'completed', 'archived')
  )
  select jsonb_build_object(
    'id', ranked.id,
    'program_id', ranked.program_id,
    'participant_id', ranked.participant_id,
    'participant_display_name', ranked.participant_display_name,
    'avatar_url', ranked.avatar_url,
    'avatar_reference', ranked.avatar_reference,
    'rank', ranked.rank,
    'progress_percentage', ranked.progress_percentage,
    'total_points', ranked.total_points,
    'is_assigned_to_coach', ranked.is_assigned_to_coach,
    'step_points', case when ranked.is_assigned_to_coach then ranked.step_points end,
    'weight_points', case when ranked.is_assigned_to_coach then ranked.weight_points end,
    'adjustment_points', case when ranked.is_assigned_to_coach then ranked.adjustment_points end
  )
  from ranked
  order by ranked.rank, ranked.participant_display_name, ranked.id
  limit result_limit
  offset result_offset;
end;
$$;

revoke all on function public.list_public_leaderboard(uuid, integer, integer)
  from public, anon, authenticated, service_role;
revoke all on function public.get_my_coach_leaderboard(uuid, integer, integer)
  from public, anon, authenticated, service_role;

grant execute on function public.list_public_leaderboard(uuid, integer, integer)
  to anon, authenticated;
grant execute on function public.get_my_coach_leaderboard(uuid, integer, integer)
  to authenticated;

notify pgrst, 'reload schema';
