-- W08 production repair: the Coach workspace and profile draft projections
-- referenced profiles.profile_avatar_path even though that column is not part
-- of the authoritative schema. Keep the response contract nullable without
-- adding or exposing a raw private-media path column.

create or replace function public.get_my_coach_workspace()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  result jsonb;
begin
  if caller_id is null then raise exception 'authentication_required'; end if;
  if not private.has_active_coach_access(caller_id) then
    raise exception 'coach_entitlement_inactive';
  end if;
  select jsonb_build_object(
    'profile', jsonb_build_object(
      'display_name', profile.display_name,
      'city', profile.city,
      'provider_avatar_url', profile.provider_avatar_url,
      'profile_avatar_path', null
    ),
    'entitlement', (
      select jsonb_build_object('starts_at', entitlement.starts_at, 'ends_at', entitlement.ends_at)
      from public.coach_access_entitlements entitlement
      where entitlement.coach_user_id = caller_id and entitlement.status = 'active'
        and entitlement.starts_at <= statement_timestamp()
        and entitlement.ends_at > statement_timestamp()
      order by entitlement.ends_at desc limit 1
    ),
    'pending_review_count', (
      select count(*) from public.step_submissions submission
      join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
      where enrollment.coach_id = caller_id and submission.status = 'pending'
    ),
    'assigned_participant_count', (
      select count(distinct enrollment.participant_id)
      from public.program_enrollments enrollment
      where enrollment.coach_id = caller_id and enrollment.status in ('active', 'completed')
    ),
    'participants', coalesce((
      select jsonb_agg(jsonb_build_object(
        'participant_id', enrollment.participant_id,
        'display_name', participant.display_name,
        'avatar_url', participant.provider_avatar_url,
        'city', participant.city,
        'program_id', program.id,
        'program_title', program.title,
        'enrollment_status', enrollment.status,
        'progress_percentage', coalesce(score.progress_percentage, 0),
        'total_points', coalesce(score.activity_points, 0) + coalesce(score.quiz_points, 0)
          + coalesce(score.weight_points, 0) + coalesce(score.adjustment_points, 0),
        'rank', score.rank
      ) order by participant.display_name, program.title)
      from public.program_enrollments enrollment
      join public.profiles participant on participant.user_id = enrollment.participant_id
      join public.programs program on program.id = enrollment.program_id
      left join public.program_scores score on score.enrollment_id = enrollment.id
      where enrollment.coach_id = caller_id and enrollment.status in ('active', 'completed')
    ), '[]'::jsonb),
    'activity', coalesce((
      select jsonb_agg(jsonb_build_object(
        'submission_id', activity.id,
        'participant_name', activity.participant_name,
        'program_title', activity.program_title,
        'step_title', activity.step_title,
        'status', activity.status,
        'submitted_at', activity.submitted_at
      ) order by activity.submitted_at desc)
      from (
        select submission.id, participant.display_name participant_name,
          program.title program_title, step.title step_title,
          submission.status, submission.submitted_at
        from public.step_submissions submission
        join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
        join public.profiles participant on participant.user_id = enrollment.participant_id
        join public.programs program on program.id = enrollment.program_id
        join public.program_steps step on step.id = submission.step_id
        where enrollment.coach_id = caller_id and submission.status <> 'draft'
        order by submission.submitted_at desc limit 30
      ) activity
    ), '[]'::jsonb),
    'programs', coalesce((
      select jsonb_agg(jsonb_build_object(
        'program_id', program.id, 'title', program.title, 'status', program.status,
        'starts_on', program.starts_on, 'ends_on', program.ends_on,
        'timezone', program.timezone, 'participant_count', grouped.participant_count,
        'pending_review_count', grouped.pending_review_count
      ) order by program.starts_on desc)
      from (
        select enrollment.program_id,
          count(distinct enrollment.participant_id)::integer participant_count,
          count(submission.id) filter (where submission.status = 'pending')::integer pending_review_count
        from public.program_enrollments enrollment
        left join public.step_submissions submission on submission.enrollment_id = enrollment.id
        where enrollment.coach_id = caller_id and enrollment.status in ('active', 'completed')
        group by enrollment.program_id
      ) grouped
      join public.programs program on program.id = grouped.program_id
    ), '[]'::jsonb),
    'leaderboard', coalesce((
      select jsonb_agg(jsonb_build_object(
        'participant_id', enrollment.participant_id,
        'display_name', participant.display_name,
        'avatar_url', participant.provider_avatar_url,
        'program_id', enrollment.program_id,
        'program_title', program.title,
        'rank', score.rank,
        'progress_percentage', score.progress_percentage,
        'total_points', score.activity_points + score.quiz_points
          + score.weight_points + score.adjustment_points
      ) order by score.rank nulls last, participant.display_name)
      from public.program_enrollments enrollment
      join public.program_scores score on score.enrollment_id = enrollment.id
      join public.profiles participant on participant.user_id = enrollment.participant_id
      join public.programs program on program.id = enrollment.program_id
      where enrollment.coach_id = caller_id and enrollment.status in ('active', 'completed')
    ), '[]'::jsonb),
    'qr_payload', profile.coach_qr_identifier
  ) into result
  from public.profiles profile where profile.user_id = caller_id;
  return result;
end;
$$;

create or replace function public.get_my_coach_public_profile_draft()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
begin
  if not private.has_active_coach_access(caller_id) then
    raise exception 'coach_entitlement_inactive'; end if;
  return jsonb_build_object(
    'identity', (select jsonb_build_object(
      'display_name', profile.display_name,
      'provider_avatar_url', profile.provider_avatar_url,
      'profile_avatar_path', null,
      'is_verified', profile.coach_is_approved
    ) from public.profiles profile where profile.user_id = caller_id),
    'draft', (select to_jsonb(draft) from public.coach_public_profile_drafts draft
      where draft.coach_user_id = caller_id),
    'published', exists(select 1 from public.coach_public_profiles published
      where published.coach_user_id = caller_id),
    'items', coalesce((select jsonb_agg(to_jsonb(item) order by item.submitted_at desc)
      from public.coach_public_profile_items item where item.coach_user_id = caller_id), '[]'::jsonb)
  );
end;
$$;

revoke execute on function public.get_my_coach_workspace() from public, anon;
revoke execute on function public.get_my_coach_public_profile_draft() from public, anon;
grant execute on function public.get_my_coach_workspace() to authenticated;
grant execute on function public.get_my_coach_public_profile_draft() to authenticated;
