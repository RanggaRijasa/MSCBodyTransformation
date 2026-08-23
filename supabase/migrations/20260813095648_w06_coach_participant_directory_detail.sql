create or replace function public.get_my_coach_participant_directory()
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
    'participants', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'participant_id', participant.user_id,
          'display_name', participant.display_name,
          'avatar_url', participant.provider_avatar_url,
          'city', participant.city,
          'enrollments', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'enrollment_id', enrollment.id,
                'program_id', program.id,
                'program_title', program.title,
                'enrollment_status', enrollment.status,
                'starts_on', program.starts_on,
                'ends_on', program.ends_on,
                'timezone', program.timezone,
                'progress_percentage', coalesce(score.progress_percentage, 0),
                'total_points', coalesce(score.activity_points, 0)
                  + coalesce(score.quiz_points, 0)
                  + coalesce(score.weight_points, 0)
                  + coalesce(score.adjustment_points, 0),
                'rank', score.rank,
                'last_activity_at', coalesce((
                  select max(submission.submitted_at)
                  from public.step_submissions submission
                  where submission.enrollment_id = enrollment.id
                    and submission.status <> 'draft'
                ), enrollment.enrolled_at),
                'completed_step_count', (
                  select count(distinct submission.step_id)::integer
                  from public.step_submissions submission
                  where submission.enrollment_id = enrollment.id
                    and submission.status in ('pending', 'approved')
                ),
                'total_step_count', (
                  select count(step.id)::integer
                  from public.program_days day
                  join public.program_steps step on step.program_day_id = day.id
                  where day.program_id = program.id
                ),
                'evidence_count', (
                  select count(answer.id)::integer
                  from public.step_submissions submission
                  join public.step_submission_answers answer
                    on answer.submission_id = submission.id
                  where submission.enrollment_id = enrollment.id
                    and answer.private_photo_path is not null
                    and submission.status <> 'draft'
                ),
                'active_day_count', (
                  select count(distinct step.program_day_id)::integer
                  from public.step_submissions submission
                  join public.program_steps step on step.id = submission.step_id
                  where submission.enrollment_id = enrollment.id
                    and submission.status <> 'draft'
                )
              )
              order by
                case enrollment.status when 'active' then 0 else 1 end,
                enrollment.enrolled_at desc
            )
            from public.program_enrollments enrollment
            join public.programs program on program.id = enrollment.program_id
            left join public.program_scores score on score.enrollment_id = enrollment.id
            where enrollment.participant_id = participant.user_id
              and enrollment.coach_id = caller_id
              and enrollment.status in ('active', 'completed')
          ), '[]'::jsonb)
        )
        order by participant.display_name
      )
      from public.profiles participant
      where participant.current_coach_id = caller_id
        or exists (
          select 1
          from public.program_enrollments enrollment
          where enrollment.participant_id = participant.user_id
            and enrollment.coach_id = caller_id
            and enrollment.status in ('active', 'completed')
        )
    ), '[]'::jsonb),
    'programs', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'program_id', program.id,
          'title', program.title,
          'ends_on', program.ends_on,
          'timezone', program.timezone
        )
        order by program.starts_on desc
      )
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

create or replace function public.get_my_coach_participant_detail(
  target_participant_id uuid,
  target_enrollment_id uuid default null
)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  selected_enrollment public.program_enrollments;
  participant public.profiles;
  program public.programs;
begin
  if caller_id is null then
    raise exception 'authentication_required';
  end if;
  if not private.has_active_coach_access(caller_id) then
    raise exception 'coach_entitlement_inactive';
  end if;

  select profile.* into participant
  from public.profiles profile
  where profile.user_id = target_participant_id
    and (
      profile.current_coach_id = caller_id
      or exists (
        select 1
        from public.program_enrollments enrollment
        where enrollment.participant_id = profile.user_id
          and enrollment.coach_id = caller_id
          and enrollment.status in ('active', 'completed')
      )
    );
  if participant.user_id is null then
    raise exception 'permission_denied';
  end if;

  select enrollment.* into selected_enrollment
  from public.program_enrollments enrollment
  where enrollment.participant_id = target_participant_id
    and enrollment.coach_id = caller_id
    and enrollment.status in ('active', 'completed')
    and (target_enrollment_id is null or enrollment.id = target_enrollment_id)
  order by case enrollment.status when 'active' then 0 else 1 end,
    enrollment.enrolled_at desc
  limit 1;

  if target_enrollment_id is not null and selected_enrollment.id is null then
    raise exception 'permission_denied';
  end if;

  if selected_enrollment.id is null then
    return jsonb_build_object(
      'participant', jsonb_build_object(
        'participant_id', participant.user_id,
        'display_name', participant.display_name,
        'avatar_url', participant.provider_avatar_url,
        'city', participant.city
      ),
      'enrollment', null,
      'program', null,
      'summary', jsonb_build_object(
        'progress_percentage', 0,
        'total_points', 0,
        'rank', null,
        'current_day', 0,
        'completed_step_count', 0,
        'total_step_count', 0,
        'active_day_count', 0,
        'evidence_count', 0
      ),
      'weigh_ins', '[]'::jsonb,
      'submissions', '[]'::jsonb,
      'days', '[]'::jsonb
    );
  end if;

  select source_program.* into program
  from public.programs source_program
  where source_program.id = selected_enrollment.program_id;

  return jsonb_build_object(
    'participant', jsonb_build_object(
      'participant_id', participant.user_id,
      'display_name', participant.display_name,
      'avatar_url', participant.provider_avatar_url,
      'city', participant.city
    ),
    'enrollment', jsonb_build_object(
      'enrollment_id', selected_enrollment.id,
      'status', selected_enrollment.status,
      'enrolled_at', selected_enrollment.enrolled_at,
      'completed_at', selected_enrollment.completed_at
    ),
    'program', jsonb_build_object(
      'program_id', program.id,
      'title', program.title,
      'starts_on', program.starts_on,
      'ends_on', program.ends_on,
      'timezone', program.timezone
    ),
    'summary', jsonb_build_object(
      'progress_percentage', case
        when selected_enrollment.status = 'completed' then 100
        else coalesce((
        select score.progress_percentage
        from public.program_scores score
        where score.enrollment_id = selected_enrollment.id
        ), 0)
      end,
      'total_points', coalesce((
        select score.activity_points + score.quiz_points
          + score.weight_points + score.adjustment_points
        from public.program_scores score
        where score.enrollment_id = selected_enrollment.id
      ), 0),
      'rank', (
        select score.rank
        from public.program_scores score
        where score.enrollment_id = selected_enrollment.id
      ),
      'current_day', least(
        coalesce((
          select max(day.day_number)
          from public.program_days day
          where day.program_id = program.id
            and day.scheduled_on <= (statement_timestamp() at time zone program.timezone)::date
        ), 0),
        (select count(day.id)::integer from public.program_days day where day.program_id = program.id)
      ),
      'completed_step_count', case
        when selected_enrollment.status = 'completed' then (
          select count(step.id)::integer
          from public.program_days day
          join public.program_steps step on step.program_day_id = day.id
          where day.program_id = program.id
        )
        else (
          select count(distinct submission.step_id)::integer
          from public.step_submissions submission
          where submission.enrollment_id = selected_enrollment.id
            and submission.status in ('pending', 'approved')
        )
      end,
      'total_step_count', (
        select count(step.id)::integer
        from public.program_days day
        join public.program_steps step on step.program_day_id = day.id
        where day.program_id = program.id
      ),
      'active_day_count', (
        select count(distinct step.program_day_id)::integer
        from public.step_submissions submission
        join public.program_steps step on step.id = submission.step_id
        where submission.enrollment_id = selected_enrollment.id
          and submission.status <> 'draft'
      ),
      'evidence_count', (
        select count(answer.id)::integer
        from public.step_submissions submission
        join public.step_submission_answers answer
          on answer.submission_id = submission.id
        where submission.enrollment_id = selected_enrollment.id
          and answer.private_photo_path is not null
          and submission.status <> 'draft'
      )
    ),
    'weigh_ins', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', weigh_in.id,
        'kind', weigh_in.kind,
        'weight_kg', weigh_in.weight_kg,
        'recorded_at', weigh_in.recorded_at
      ) order by weigh_in.recorded_at desc)
      from public.weigh_ins weigh_in
      where weigh_in.enrollment_id = selected_enrollment.id
    ), '[]'::jsonb),
    'submissions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', submission.id,
        'step_id', submission.step_id,
        'step_title', step.title,
        'day_number', day.day_number,
        'status', submission.status,
        'submitted_at', submission.submitted_at,
        'review_note', submission.review_note,
        'answers', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', answer.id,
            'prompt', question.prompt,
            'text_value', answer.text_value,
            'number_value', answer.number_value,
            'private_photo_path', answer.private_photo_path
          ) order by question.question_order)
          from public.step_submission_answers answer
          join public.program_questions question on question.id = answer.question_id
          where answer.submission_id = submission.id
        ), '[]'::jsonb)
      ) order by submission.submitted_at desc)
      from public.step_submissions submission
      join public.program_steps step on step.id = submission.step_id
      join public.program_days day on day.id = step.program_day_id
      where submission.enrollment_id = selected_enrollment.id
        and submission.status <> 'draft'
    ), '[]'::jsonb),
    'days', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', day.id,
        'day_number', day.day_number,
        'title', day.title,
        'scheduled_on', day.scheduled_on,
        'steps', coalesce((
          select jsonb_agg(jsonb_build_object(
            'id', step.id,
            'step_order', step.step_order,
            'title', step.title,
            'content_kind', step.content_kind,
            'status', coalesce(latest_submission.status, 'not_started')
          ) order by step.step_order)
          from public.program_steps step
          left join lateral (
            select submission.status
            from public.step_submissions submission
            where submission.enrollment_id = selected_enrollment.id
              and submission.step_id = step.id
              and submission.status <> 'superseded'
            order by submission.attempt_sequence desc
            limit 1
          ) latest_submission on true
          where step.program_day_id = day.id
        ), '[]'::jsonb)
      ) order by day.day_number)
      from public.program_days day
      where day.program_id = program.id
    ), '[]'::jsonb)
  );
end;
$$;

revoke execute on function public.get_my_coach_participant_directory() from public, anon;
revoke execute on function public.get_my_coach_participant_detail(uuid, uuid) from public, anon;
grant execute on function public.get_my_coach_participant_directory() to authenticated;
grant execute on function public.get_my_coach_participant_detail(uuid, uuid) to authenticated;
