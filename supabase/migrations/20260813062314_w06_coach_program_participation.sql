-- Coach accounts retain Coach authorization while participating in programs
-- through the exact same enrollment contract as Participant accounts.

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
  from public.profiles program_participant
  join public.profiles coach
    on coach.user_id = program_participant.current_coach_id
  where program_participant.user_id = (select auth.uid())
    and program_participant.role in ('participant', 'coach')
  limit 1;
end;
$$;

create or replace function public.enroll_free_program(
  target_program_id uuid,
  scanned_coach_qr text
)
returns public.program_enrollments
language plpgsql
security definer
set search_path = ''
as $$
declare
  program_participant public.profiles;
  coach public.profiles;
  target_program public.programs;
  existing public.program_enrollments;
  result public.program_enrollments;
begin
  if length(trim(coalesce(scanned_coach_qr, ''))) < 16 then
    raise exception 'coach_qr_invalid';
  end if;

  select * into program_participant
  from public.profiles
  where user_id = (select auth.uid())
    and role in ('participant', 'coach')
  for update;
  if program_participant.user_id is null then
    raise exception 'permission_denied';
  end if;

  select * into existing
  from public.program_enrollments
  where program_id = target_program_id
    and participant_id = program_participant.user_id
  for update;
  if existing.id is not null then return existing; end if;

  select * into coach
  from public.profiles
  where coach_qr_identifier = scanned_coach_qr
    and role = 'coach'
    and coach_is_approved
  for share;
  if coach.user_id is null
    or not private.has_active_coach_access(coach.user_id)
  then
    raise exception 'coach_qr_invalid';
  end if;
  if program_participant.role = 'coach'
    and coach.user_id <> program_participant.user_id
  then
    raise exception 'coach_qr_invalid';
  end if;
  if program_participant.role = 'participant'
    and program_participant.current_coach_id is not null
    and program_participant.current_coach_id <> coach.user_id
  then
    raise exception 'coach_mismatch';
  end if;

  select * into target_program
  from public.programs
  where id = target_program_id
  for update;
  if target_program.id is null
    or target_program.status not in ('scheduled', 'active')
    or target_program.published_at is null
    or target_program.pricing_mode <> 'free'
  then
    raise exception 'program_unavailable';
  end if;
  if target_program.registration_closes_at is not null
    and statement_timestamp() >= target_program.registration_closes_at
  then
    raise exception 'registration_closed';
  end if;
  if target_program.participant_limit is not null and (
    select count(*)
    from public.program_enrollments enrollment
    where enrollment.program_id = target_program_id
      and enrollment.status in ('active', 'completed')
  ) >= target_program.participant_limit then
    raise exception 'program_full';
  end if;

  update public.profiles
  set current_coach_id = coach.user_id,
      updated_at = statement_timestamp()
  where user_id = program_participant.user_id
    and (
      current_coach_id is null
      or program_participant.role = 'coach'
    );

  insert into public.program_enrollments (
    program_id, participant_id, coach_id, status
  ) values (
    target_program_id, program_participant.user_id, coach.user_id, 'active'
  )
  on conflict (program_id, participant_id) do update
    set program_id = excluded.program_id
  returning * into result;

  insert into public.program_scores(enrollment_id)
  values (result.id) on conflict do nothing;

  return result;
end;
$$;

create or replace function public.create_program_payment_order(
  target_program_id uuid,
  coach_qr_payload text,
  payment_method text,
  request_idempotency_key text
)
returns public.payment_orders
language plpgsql security definer
set search_path = ''
as $$
declare
  actor_id uuid := (select auth.uid());
  actor_profile public.profiles;
  target_program public.programs;
  target_coach public.profiles;
  destination public.payment_destinations;
  enrollment public.program_enrollments;
  existing public.payment_orders;
  result public.payment_orders;
  occupied integer;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if actor_id is null then raise exception 'authentication_required'; end if;
  if payment_method not in ('bank_transfer', 'static_qris') then
    raise exception 'payment_method_invalid';
  end if;
  select * into existing from public.payment_orders
  where owner_user_id = actor_id and idempotency_key = request_idempotency_key;
  if existing.id is not null then
    if existing.program_id is distinct from target_program_id
      or existing.declared_method is distinct from payment_method then
      raise exception 'idempotency_conflict';
    end if;
    return existing;
  end if;
  select * into actor_profile from public.profiles
  where user_id = actor_id for update;
  if actor_profile.user_id is null
    or actor_profile.role not in ('participant', 'coach') then
    raise exception 'permission_denied';
  end if;
  select * into target_program from public.programs
  where id = target_program_id for update;
  if target_program.id is null
    or target_program.status not in ('scheduled', 'active')
    or target_program.published_at is null
    or target_program.pricing_mode <> 'paid'
    or target_program.desired_price is null
    or target_program.desired_price <= 0 then
    raise exception 'program_unavailable';
  end if;
  if target_program.registration_closes_at is not null
    and statement_timestamp() >= target_program.registration_closes_at then
    raise exception 'registration_closed';
  end if;
  select * into target_coach from public.profiles
  where coach_qr_identifier = coach_qr_payload
    and role = 'coach'
    and coach_is_approved
    and private.has_active_coach_access(user_id);
  if target_coach.user_id is null then raise exception 'coach_invalid'; end if;
  if actor_profile.role = 'coach' and target_coach.user_id <> actor_id then
    raise exception 'coach_invalid';
  end if;
  if actor_profile.role = 'participant'
    and actor_profile.current_coach_id is not null
    and actor_profile.current_coach_id <> target_coach.user_id then
    raise exception 'coach_mismatch';
  end if;
  select * into destination from private.current_payment_destination();
  if destination.id is null then
    raise exception 'payment_destination_unavailable';
  end if;
  if payment_method = 'static_qris'
    and destination.qris_object_path is null then
    raise exception 'payment_method_unavailable';
  end if;
  select count(*) into occupied from public.program_enrollments
  where program_id = target_program.id
    and status in ('waiting_for_payment', 'active', 'completed');
  if target_program.participant_limit is not null
    and occupied >= target_program.participant_limit then
    raise exception 'program_full';
  end if;
  select * into enrollment from public.program_enrollments
  where program_id = target_program.id and participant_id = actor_id
  for update;
  if enrollment.status in ('active', 'completed') then
    raise exception 'already_enrolled';
  end if;
  if enrollment.id is null then
    insert into public.program_enrollments(
      program_id, participant_id, coach_id, status
    ) values (
      target_program.id, actor_id, target_coach.user_id,
      'waiting_for_payment'
    ) returning * into enrollment;
  else
    update public.program_enrollments
    set coach_id = target_coach.user_id,
        status = 'waiting_for_payment',
        enrolled_at = statement_timestamp(),
        completed_at = null
    where id = enrollment.id returning * into enrollment;
  end if;
  update public.profiles
  set current_coach_id = target_coach.user_id,
      updated_at = statement_timestamp()
  where user_id = actor_id
    and (
      current_coach_id is null
      or actor_profile.role = 'coach'
    );
  insert into public.payment_orders(
    owner_user_id, purpose, program_id, pending_enrollment_id,
    coach_user_id_snapshot, amount_minor, declared_method,
    destination_id, destination_version, bank_code_snapshot,
    bank_name_snapshot, account_name_snapshot, account_reference_snapshot,
    qris_object_path_snapshot, instructions_snapshot, reserved_at,
    reservation_expires_at, retention_after, timezone_snapshot, status,
    idempotency_key
  ) values (
    actor_id, 'program_enrollment', target_program.id, enrollment.id,
    target_coach.user_id, round(target_program.desired_price)::bigint,
    payment_method, destination.id, destination.version,
    destination.bank_code, destination.bank_name, destination.account_name,
    destination.account_reference, destination.qris_object_path,
    destination.instructions, statement_timestamp(),
    statement_timestamp() + interval '24 hours',
    ((target_program.ends_on + 30)::timestamp
      at time zone target_program.timezone),
    target_program.timezone, 'awaiting_evidence', request_idempotency_key
  ) returning * into result;
  insert into public.payment_events(order_id, actor_id, event_type)
  values (result.id, actor_id, 'order_created');
  return result;
end;
$$;

revoke execute on function public.get_my_assigned_coach()
  from public, anon, authenticated, service_role;
revoke all on function public.enroll_free_program(uuid, text)
  from public, anon;
revoke all on function public.create_program_payment_order(uuid, text, text, text)
  from public, anon;

grant execute on function public.get_my_assigned_coach()
  to authenticated;
grant execute on function public.enroll_free_program(uuid, text)
  to authenticated;
grant execute on function public.create_program_payment_order(uuid, text, text, text)
  to authenticated;
