-- Keep the original, already-audited authorization and payload builders as
-- private base functions. Public wrappers below only normalize progress from
-- the authoritative weigh_ins table.
alter function public.get_my_coach_participant_directory() set schema private;
alter function private.get_my_coach_participant_directory()
  rename to w08_coach_participant_directory_base;

alter function public.get_my_coach_participant_detail(uuid, uuid) set schema private;
alter function private.get_my_coach_participant_detail(uuid, uuid)
  rename to w08_coach_participant_detail_base;

revoke all on function private.w08_coach_participant_directory_base()
  from public, anon, authenticated;
revoke all on function private.w08_coach_participant_detail_base(uuid, uuid)
  from public, anon, authenticated;

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
    select enrollment.id, enrollment.program_id, enrollment.enrolled_at
    from public.program_enrollments enrollment
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

create or replace function public.get_my_coach_participant_detail(
  target_participant_id uuid,
  target_enrollment_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  payload jsonb;
  metrics jsonb;
  selected_enrollment_id uuid;
  enrollment_status text;
  selected_step_id uuid;
  content_kind text;
  expected_weigh_in_kind text;
begin
  payload := private.w08_coach_participant_detail_base(
    target_participant_id,
    target_enrollment_id
  );

  if payload -> 'enrollment' = 'null'::jsonb then
    return payload;
  end if;

  selected_enrollment_id := (payload #>> '{enrollment,enrollment_id}')::uuid;
  enrollment_status := payload #>> '{enrollment,status}';
  metrics := private.w08_coach_enrollment_progress_metrics(selected_enrollment_id);

  if enrollment_status <> 'completed' then
    payload := jsonb_set(
      payload,
      '{summary,completed_step_count}',
      metrics -> 'completed_step_count'
    );
  end if;
  payload := jsonb_set(
    payload,
    '{summary,active_day_count}',
    metrics -> 'active_day_count'
  );

  if jsonb_array_length(coalesce(payload -> 'days', '[]'::jsonb)) = 0 then
    return payload;
  end if;

  for day_index in 0 .. jsonb_array_length(payload -> 'days') - 1 loop
    if jsonb_array_length(coalesce(
      payload #> array['days', day_index::text, 'steps'],
      '[]'::jsonb
    )) = 0 then
      continue;
    end if;

    for step_index in 0 .. jsonb_array_length(
      payload #> array['days', day_index::text, 'steps']
    ) - 1 loop
      selected_step_id := (
        payload #>> array['days', day_index::text, 'steps', step_index::text, 'id']
      )::uuid;
      content_kind := payload #>> array[
        'days', day_index::text, 'steps', step_index::text, 'content_kind'
      ];
      expected_weigh_in_kind := case content_kind
        when 'initial_weigh_in' then 'initial'
        when 'daily_weigh_in' then 'daily'
        when 'final_weigh_in' then 'final'
        else null
      end;

      if expected_weigh_in_kind is not null and exists (
        select 1
        from public.weigh_ins weigh_in
        where weigh_in.enrollment_id = selected_enrollment_id
          and weigh_in.step_id = selected_step_id
          and weigh_in.kind = expected_weigh_in_kind
      ) then
        payload := jsonb_set(
          payload,
          array['days', day_index::text, 'steps', step_index::text, 'status'],
          '"approved"'::jsonb
        );
      end if;
    end loop;
  end loop;

  return payload;
end;
$$;

revoke all on function public.get_my_coach_participant_directory()
  from public, anon;
revoke all on function public.get_my_coach_participant_detail(uuid, uuid)
  from public, anon;
grant execute on function public.get_my_coach_participant_directory()
  to authenticated;
grant execute on function public.get_my_coach_participant_detail(uuid, uuid)
  to authenticated;
