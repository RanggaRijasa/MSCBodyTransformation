create or replace function public.get_my_coach_activity_feed()
returns jsonb
language plpgsql stable security definer
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

  return jsonb_build_object(
    'items', coalesce((
      with activity as (
        select
          'joined:' || enrollment.id::text as id,
          enrollment.participant_id,
          participant.display_name as participant_name,
          participant.provider_avatar_url as avatar_url,
          enrollment.id as enrollment_id,
          program.id as program_id,
          program.title as program_title,
          null::uuid as submission_id,
          null::text as step_title,
          'participant_joined'::text as kind,
          null::text as evidence_status,
          null::integer as points,
          enrollment.enrolled_at as occurred_at,
          false as requires_review
        from public.program_enrollments enrollment
        join public.profiles participant on participant.user_id = enrollment.participant_id
        join public.programs program on program.id = enrollment.program_id
        where enrollment.coach_id = caller_id
          and enrollment.status in ('active', 'completed')

        union all

        select
          'completed:' || enrollment.id::text,
          enrollment.participant_id,
          participant.display_name,
          participant.provider_avatar_url,
          enrollment.id,
          program.id,
          program.title,
          null::uuid,
          null::text,
          'program_completed'::text,
          null::text,
          null::integer,
          coalesce(
            enrollment.completed_at,
            program.ends_on::timestamp at time zone program.timezone
          ),
          false
        from public.program_enrollments enrollment
        join public.profiles participant on participant.user_id = enrollment.participant_id
        join public.programs program on program.id = enrollment.program_id
        where enrollment.coach_id = caller_id
          and enrollment.status = 'completed'

        union all

        select
          'submission:' || submission.id::text,
          enrollment.participant_id,
          participant.display_name,
          participant.provider_avatar_url,
          enrollment.id,
          program.id,
          program.title,
          submission.id,
          step.title,
          case
            when (submission.status = 'pending' and step.verification_mode = 'coach_review')
              or submission.status = 'rejected'
            then 'evidence_submitted'
            else 'step_completed'
          end,
          case
            when (submission.status = 'pending' and step.verification_mode = 'coach_review')
              or submission.status = 'rejected'
            then submission.status
            else null
          end,
          case
            when submission.status = 'approved' then coalesce(
              quiz.awarded_points,
              case when step.content_kind in ('article', 'video', 'form')
                then program.points_per_activity else 0 end
            )
            else null
          end,
          submission.submitted_at,
          submission.status = 'pending' and step.verification_mode = 'coach_review'
        from public.step_submissions submission
        join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
        join public.profiles participant on participant.user_id = enrollment.participant_id
        join public.program_steps step on step.id = submission.step_id
        join public.program_days day on day.id = step.program_day_id
        join public.programs program on program.id = day.program_id
        left join public.quiz_attempt_results quiz on quiz.submission_id = submission.id
        where enrollment.coach_id = caller_id
          and enrollment.status in ('active', 'completed')
          and submission.status <> 'draft'
      )
      select jsonb_agg(jsonb_build_object(
        'id', activity.id,
        'participant_id', activity.participant_id,
        'participant_name', activity.participant_name,
        'avatar_url', activity.avatar_url,
        'enrollment_id', activity.enrollment_id,
        'program_id', activity.program_id,
        'program_title', activity.program_title,
        'submission_id', activity.submission_id,
        'step_title', activity.step_title,
        'kind', activity.kind,
        'evidence_status', activity.evidence_status,
        'points', activity.points,
        'occurred_at', activity.occurred_at,
        'requires_review', activity.requires_review
      ) order by activity.occurred_at desc, activity.id)
      from activity
      where activity.occurred_at >= statement_timestamp() - interval '30 days'
    ), '[]'::jsonb),
    'programs', coalesce((
      select jsonb_agg(jsonb_build_object(
        'program_id', program.id,
        'title', program.title,
        'ends_on', program.ends_on,
        'timezone', program.timezone
      ) order by program.starts_on desc)
      from public.programs program
      where exists (
        select 1
        from public.program_enrollments enrollment
        where enrollment.program_id = program.id
          and enrollment.coach_id = caller_id
          and enrollment.status in ('active', 'completed')
      )
    ), '[]'::jsonb)
  );
end;
$$;

revoke execute on function public.get_my_coach_activity_feed() from public, anon;
grant execute on function public.get_my_coach_activity_feed() to authenticated;
