-- Coach attention must compare participant completion against steps that are
-- due now. Future program days may be visible in total progress, but they must
-- not make an otherwise up-to-date participant look overdue.
create or replace function private.w08_coach_enrollment_progress_metrics(
  target_enrollment_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with target as (
    select
      enrollment.id,
      enrollment.program_id,
      enrollment.enrolled_at,
      program.pace,
      program.starts_on,
      program.timezone
    from public.program_enrollments enrollment
    join public.programs program on program.id = enrollment.program_id
    where enrollment.id = target_enrollment_id
  )
  select jsonb_build_object(
    'completed_step_count', coalesce((
      select count(step.id)::integer
      from target
      join public.program_days day on day.program_id = target.program_id
      join public.program_steps step on step.program_day_id = day.id
      where exists (
        select 1
        from public.step_submissions submission
        where submission.enrollment_id = target.id
          and submission.step_id = step.id
          and submission.status in ('pending', 'approved')
      ) or exists (
        select 1
        from public.weigh_ins weigh_in
        where weigh_in.enrollment_id = target.id
          and weigh_in.step_id = step.id
          and (
            (step.content_kind = 'initial_weigh_in' and weigh_in.kind = 'initial')
            or (step.content_kind = 'daily_weigh_in' and weigh_in.kind = 'daily')
            or (step.content_kind = 'final_weigh_in' and weigh_in.kind = 'final')
          )
      )
    ), 0),
    'due_step_count', coalesce((
      select count(step.id)::integer
      from target
      join public.program_days day on day.program_id = target.program_id
      join public.program_steps step on step.program_day_id = day.id
      where case
        when target.pace = 'self_paced' then
          day.scheduled_on - target.starts_on <= greatest(
            (statement_timestamp() at time zone target.timezone)::date
              - (target.enrolled_at at time zone target.timezone)::date,
            0
          )
        else day.scheduled_on <=
          (statement_timestamp() at time zone target.timezone)::date
      end
    ), 0),
    'completed_due_step_count', coalesce((
      select count(step.id)::integer
      from target
      join public.program_days day on day.program_id = target.program_id
      join public.program_steps step on step.program_day_id = day.id
      where (
        case
          when target.pace = 'self_paced' then
            day.scheduled_on - target.starts_on <= greatest(
              (statement_timestamp() at time zone target.timezone)::date
                - (target.enrolled_at at time zone target.timezone)::date,
              0
            )
          else day.scheduled_on <=
            (statement_timestamp() at time zone target.timezone)::date
        end
      )
      and (
        exists (
          select 1
          from public.step_submissions submission
          where submission.enrollment_id = target.id
            and submission.step_id = step.id
            and submission.status in ('pending', 'approved')
        ) or exists (
          select 1
          from public.weigh_ins weigh_in
          where weigh_in.enrollment_id = target.id
            and weigh_in.step_id = step.id
            and (
              (step.content_kind = 'initial_weigh_in' and weigh_in.kind = 'initial')
              or (step.content_kind = 'daily_weigh_in' and weigh_in.kind = 'daily')
              or (step.content_kind = 'final_weigh_in' and weigh_in.kind = 'final')
            )
        )
      )
    ), 0),
    'active_day_count', coalesce((
      select count(day.id)::integer
      from target
      join public.program_days day on day.program_id = target.program_id
      where exists (
        select 1
        from public.program_steps step
        join public.step_submissions submission on submission.step_id = step.id
        where step.program_day_id = day.id
          and submission.enrollment_id = target.id
          and submission.status <> 'draft'
      ) or exists (
        select 1
        from public.program_steps step
        join public.weigh_ins weigh_in on weigh_in.step_id = step.id
        where step.program_day_id = day.id
          and weigh_in.enrollment_id = target.id
          and (
            (step.content_kind = 'initial_weigh_in' and weigh_in.kind = 'initial')
            or (step.content_kind = 'daily_weigh_in' and weigh_in.kind = 'daily')
            or (step.content_kind = 'final_weigh_in' and weigh_in.kind = 'final')
          )
      )
    ), 0),
    'last_activity_at', coalesce((
      select max(activity.occurred_at)
      from target
      cross join lateral (
        select submission.submitted_at as occurred_at
        from public.step_submissions submission
        where submission.enrollment_id = target.id
          and submission.status <> 'draft'
        union all
        select weigh_in.recorded_at
        from public.weigh_ins weigh_in
        where weigh_in.enrollment_id = target.id
      ) activity
    ), (select target.enrolled_at from target))
  );
$$;

revoke all on function private.w08_coach_enrollment_progress_metrics(uuid)
  from public, anon, authenticated;

create or replace function public.get_my_coach_participant_directory()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  payload jsonb;
  metrics jsonb;
  enrollment_id uuid;
begin
  payload := private.w08_coach_participant_directory_base();

  if jsonb_array_length(coalesce(payload -> 'participants', '[]'::jsonb)) = 0 then
    return payload;
  end if;

  for participant_index in 0 .. jsonb_array_length(payload -> 'participants') - 1 loop
    if jsonb_array_length(coalesce(
      payload #> array['participants', participant_index::text, 'enrollments'],
      '[]'::jsonb
    )) = 0 then
      continue;
    end if;

    for enrollment_index in 0 .. jsonb_array_length(
      payload #> array['participants', participant_index::text, 'enrollments']
    ) - 1 loop
      enrollment_id := (
        payload #>> array[
          'participants', participant_index::text, 'enrollments',
          enrollment_index::text, 'enrollment_id'
        ]
      )::uuid;
      metrics := private.w08_coach_enrollment_progress_metrics(enrollment_id);

      payload := jsonb_set(
        payload,
        array[
          'participants', participant_index::text, 'enrollments',
          enrollment_index::text, 'completed_step_count'
        ],
        metrics -> 'completed_step_count'
      );
      payload := jsonb_set(
        payload,
        array[
          'participants', participant_index::text, 'enrollments',
          enrollment_index::text, 'due_step_count'
        ],
        metrics -> 'due_step_count'
      );
      payload := jsonb_set(
        payload,
        array[
          'participants', participant_index::text, 'enrollments',
          enrollment_index::text, 'completed_due_step_count'
        ],
        metrics -> 'completed_due_step_count'
      );
      payload := jsonb_set(
        payload,
        array[
          'participants', participant_index::text, 'enrollments',
          enrollment_index::text, 'active_day_count'
        ],
        metrics -> 'active_day_count'
      );
      payload := jsonb_set(
        payload,
        array[
          'participants', participant_index::text, 'enrollments',
          enrollment_index::text, 'last_activity_at'
        ],
        metrics -> 'last_activity_at'
      );
    end loop;
  end loop;

  return payload;
end;
$$;

revoke all on function public.get_my_coach_participant_directory()
  from public, anon;
grant execute on function public.get_my_coach_participant_directory()
  to authenticated;
