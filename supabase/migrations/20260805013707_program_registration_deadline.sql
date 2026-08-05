alter table public.programs
  add column registration_closes_at timestamptz;

alter table public.programs
  add constraint programs_registration_deadline_within_program
  check (
    registration_closes_at is null
    or (registration_closes_at at time zone timezone)::date <= ends_on
  );

comment on column public.programs.registration_closes_at is
  'Optional exact cutoff for participant self-enrollment. Admin enrollment '
  'may bypass only this cutoff.';

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
  if target_program.registration_closes_at is not null
    and clock_timestamp() >= target_program.registration_closes_at
  then raise exception 'registration_closed'; end if;

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

revoke all on function public.enroll_free_program(uuid, text)
  from public, anon, authenticated, service_role;
grant execute on function public.enroll_free_program(uuid, text)
  to authenticated;

create or replace function public.admin_enroll_participant(
  target_program_id uuid,
  target_participant_id uuid,
  reason text
)
returns public.program_enrollments
language plpgsql security definer
set search_path = ''
as $$
declare
  participant public.profiles;
  coach public.profiles;
  target_program public.programs;
  existing public.program_enrollments;
  result public.program_enrollments;
begin
  if (select auth.uid()) is null or not private.is_admin()
  then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reason, ''))) = 0
  then raise exception 'reason_required'; end if;

  select * into target_program from public.programs
  where id = target_program_id
    and status in ('scheduled', 'active')
  for update;
  if target_program.id is null then raise exception 'program_unavailable'; end if;

  select * into existing from public.program_enrollments
  where program_id = target_program_id
    and participant_id = target_participant_id
  for update;
  if existing.id is not null then return existing; end if;

  select * into participant from public.profiles
  where user_id = target_participant_id and role = 'participant'
  for update;
  if participant.user_id is null then raise exception 'participant_invalid'; end if;
  if participant.current_coach_id is null then raise exception 'coach_required'; end if;

  select * into coach from public.profiles
  where user_id = participant.current_coach_id
    and role = 'coach' and coach_is_approved
  for share;
  if coach.user_id is null then raise exception 'coach_invalid'; end if;

  if target_program.participant_limit is not null and (
    select count(*) from public.program_enrollments
    where program_id = target_program_id
      and status in ('active', 'completed')
  ) >= target_program.participant_limit
  then raise exception 'program_full'; end if;

  if target_program.pricing_mode = 'paid' and not exists (
    select 1 from public.program_entitlements
    where program_id = target_program_id
      and participant_id = target_participant_id
      and status = 'active'
  ) then raise exception 'payment_required'; end if;

  insert into public.program_enrollments (
    program_id, participant_id, coach_id, status
  ) values (
    target_program_id, participant.user_id, coach.user_id, 'active'
  )
  returning * into result;

  insert into public.program_scores(enrollment_id)
  values (result.id) on conflict do nothing;

  insert into public.audit_events(
    actor_id, kind, subject_id, summary, payload
  ) values (
    (select auth.uid()), 'participant_enrolled', participant.user_id,
    trim(reason), jsonb_build_object(
      'program_id', target_program.id,
      'coach_id', coach.user_id,
      'registration_deadline_bypassed',
        target_program.registration_closes_at is not null
        and clock_timestamp() >= target_program.registration_closes_at
    )
  );
  return result;
end;
$$;

revoke all on function public.admin_enroll_participant(uuid, uuid, text)
  from public, anon, authenticated, service_role;
grant execute on function public.admin_enroll_participant(uuid, uuid, text)
  to authenticated;
