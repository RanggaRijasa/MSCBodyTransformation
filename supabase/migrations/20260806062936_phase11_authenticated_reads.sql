-- Slice 11.2 adds narrow authenticated read projections only. Authoritative
-- mutations continue to use reviewed server operations in later slices.

create or replace function public.get_my_assigned_coach()
returns table (
  user_id uuid,
  public_profile_id uuid,
  display_name text,
  city text,
  provider_avatar_url text,
  is_public boolean,
  is_approved boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception using
      errcode = '42501',
      message = 'permission_denied';
  end if;

  return query
  select
    coach.user_id,
    coach.public_profile_id,
    coach.display_name,
    coach.city,
    coach.provider_avatar_url,
    coach.coach_is_public,
    coach.coach_is_approved
  from public.profiles participant
  join public.profiles coach
    on coach.user_id = participant.current_coach_id
  where participant.user_id = (select auth.uid())
    and participant.role = 'participant'
  limit 1;
end;
$$;

create or replace function public.list_my_program_day_access()
returns table (
  enrollment_id uuid,
  program_id uuid,
  program_day_id uuid,
  day_number integer,
  access_state text,
  is_current_day boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    enrollment.id,
    program.id,
    program_day.id,
    program_day.day_number,
    case
      when enrollment.status = 'completed'
        and (
          program_day.scheduled_on
            < timezone(program.timezone, statement_timestamp())::date
          and program.past_step_policy = 'hidden'
        )
        then 'hidden'
      when enrollment.status = 'completed'
        then 'read_only'
      when program_day.scheduled_on
        = timezone(program.timezone, statement_timestamp())::date
        then 'available'
      when program_day.scheduled_on
        < timezone(program.timezone, statement_timestamp())::date
        then program.past_step_policy
      else program.future_step_policy
    end,
    program_day.scheduled_on
      = timezone(program.timezone, statement_timestamp())::date
  from public.program_enrollments enrollment
  join public.programs program
    on program.id = enrollment.program_id
  join public.program_days program_day
    on program_day.program_id = program.id
  where enrollment.participant_id = (select auth.uid())
    and enrollment.status in ('active', 'completed')
    and program.status in ('scheduled', 'active', 'completed', 'archived')
  order by program.id, program_day.day_number;
$$;

create or replace function public.get_my_dashboard_summary()
returns table (
  account_role text,
  active_enrollment_count integer,
  completed_enrollment_count integer,
  pending_submission_count integer,
  assigned_participant_count integer
)
language sql
stable
security invoker
set search_path = ''
as $$
  with caller as (
    select profile.role
    from public.profiles profile
    where profile.user_id = (select auth.uid())
  )
  select
    caller.role,
    (
      select count(*)::integer
      from public.program_enrollments enrollment
      where enrollment.status = 'active'
        and (
          (caller.role = 'participant'
            and enrollment.participant_id = (select auth.uid()))
          or (caller.role = 'coach'
            and enrollment.coach_id = (select auth.uid()))
          or caller.role = 'admin'
        )
    ),
    (
      select count(*)::integer
      from public.program_enrollments enrollment
      where enrollment.status = 'completed'
        and (
          (caller.role = 'participant'
            and enrollment.participant_id = (select auth.uid()))
          or (caller.role = 'coach'
            and enrollment.coach_id = (select auth.uid()))
          or caller.role = 'admin'
        )
    ),
    (
      select count(*)::integer
      from public.step_submissions submission
      join public.program_enrollments enrollment
        on enrollment.id = submission.enrollment_id
      where submission.status = 'pending'
        and (
          (caller.role = 'participant'
            and enrollment.participant_id = (select auth.uid()))
          or (caller.role = 'coach'
            and enrollment.coach_id = (select auth.uid()))
          or caller.role = 'admin'
        )
    ),
    (
      select count(*)::integer
      from public.profiles participant
      where caller.role = 'coach'
        and participant.role = 'participant'
        and participant.current_coach_id = (select auth.uid())
    )
  from caller;
$$;

revoke execute on function public.get_my_assigned_coach()
  from public, anon, authenticated, service_role;
revoke execute on function public.list_my_program_day_access()
  from public, anon, authenticated, service_role;
revoke execute on function public.get_my_dashboard_summary()
  from public, anon, authenticated, service_role;

grant execute on function public.get_my_assigned_coach()
  to authenticated;
grant execute on function public.list_my_program_day_access()
  to authenticated;
grant execute on function public.get_my_dashboard_summary()
  to authenticated;
