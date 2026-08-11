-- Phase 08: Coach read capability and Coach-as-Participant compatibility.
-- Role remains server-controlled; these operations add Participant capability
-- to an active Coach account without creating a second profile or role.

create or replace function private.is_participant_capable(target_user_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles profile
    where profile.user_id = target_user_id
      and profile.role in ('participant', 'coach')
      and profile.onboarding_status = 'active'
  );
$$;

create or replace function private.can_coach_participant(target_participant uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select target_participant <> (select auth.uid())
    and private.has_active_coach_access((select auth.uid()))
    and exists (
      select 1 from public.profiles participant
      where participant.user_id = target_participant
        and participant.role in ('participant', 'coach')
        and participant.current_coach_id = (select auth.uid())
    );
$$;

create or replace function public.get_my_assigned_coach()
returns table (
  user_id uuid, public_profile_id uuid, display_name text, city text,
  provider_avatar_url text, is_public boolean, is_approved boolean
) language plpgsql stable security definer set search_path = '' as $$
begin
  if (select auth.uid()) is null then raise exception 'permission_denied'; end if;
  return query
  select coach.user_id, coach.public_profile_id, coach.display_name, coach.city,
    coach.provider_avatar_url, coach.coach_is_public, coach.coach_is_approved
  from public.profiles participant
  join public.profiles coach on coach.user_id = participant.current_coach_id
  where participant.user_id = (select auth.uid())
    and participant.role in ('participant', 'coach')
  limit 1;
end;
$$;

create or replace function public.pending_program_enrollment_availability(target_program_id uuid)
returns text language plpgsql security definer set search_path = '' as $$
declare caller_profile public.profiles; target_program public.programs;
begin
  select * into caller_profile from public.profiles where user_id = (select auth.uid());
  if caller_profile.user_id is null or caller_profile.role not in ('participant', 'coach')
  then raise exception 'permission_denied'; end if;
  select * into target_program from public.programs
  where id = target_program_id and status in ('scheduled', 'active');
  if target_program.id is null then return 'program_unavailable'; end if;
  if exists (select 1 from public.program_enrollments
    where program_id = target_program_id and participant_id = (select auth.uid())
      and status in ('waiting_for_payment', 'active', 'completed'))
  then return 'already_enrolled'; end if;
  if target_program.registration_closes_at is not null
    and statement_timestamp() >= target_program.registration_closes_at
  then return 'registration_closed'; end if;
  if target_program.participant_limit is not null and (
    select count(*) from public.program_enrollments
    where program_id = target_program.id
      and status in ('waiting_for_payment', 'active', 'completed')
  ) >= target_program.participant_limit then return 'program_full'; end if;
  return 'available';
end;
$$;

create or replace function public.resolve_coach_qr_for_enrollment(scanned_coach_qr text)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare participant public.profiles; coach public.profiles;
begin
  if length(trim(coalesce(scanned_coach_qr, ''))) not between 16 and 128
  then raise exception 'coach_qr_invalid'; end if;
  select * into participant from public.profiles
  where user_id = (select auth.uid()) and role in ('participant', 'coach');
  if participant.user_id is null then raise exception 'permission_denied'; end if;
  select * into coach from public.profiles
  where coach_qr_identifier = trim(scanned_coach_qr) and role = 'coach'
    and coach_is_approved and private.has_active_coach_access(user_id);
  if coach.user_id is null or coach.user_id = participant.user_id
  then raise exception 'coach_qr_invalid'; end if;
  if participant.current_coach_id is not null and participant.current_coach_id <> coach.user_id
  then raise exception 'coach_mismatch'; end if;
  return jsonb_build_object(
    'id', coach.user_id, 'display_name', coach.display_name, 'city', coach.city,
    'photo_reference', coach.provider_avatar_url, 'is_public', coach.coach_is_public,
    'is_approved', coach.coach_is_approved
  );
end;
$$;

create or replace function public.enroll_free_program(target_program_id uuid, scanned_coach_qr text)
returns public.program_enrollments language plpgsql security definer set search_path = '' as $$
declare
  participant public.profiles; coach public.profiles; target_program public.programs;
  existing public.program_enrollments; result public.program_enrollments;
begin
  if length(trim(coalesce(scanned_coach_qr, ''))) not between 16 and 128
  then raise exception 'coach_qr_invalid'; end if;
  select * into participant from public.profiles
  where user_id = (select auth.uid()) and role in ('participant', 'coach') for update;
  if participant.user_id is null then raise exception 'permission_denied'; end if;
  select * into existing from public.program_enrollments
  where program_id = target_program_id and participant_id = participant.user_id for update;
  if existing.id is not null then return existing; end if;
  select * into coach from public.profiles
  where coach_qr_identifier = trim(scanned_coach_qr) and role = 'coach'
    and coach_is_approved and private.has_active_coach_access(user_id) for share;
  if coach.user_id is null or coach.user_id = participant.user_id
  then raise exception 'coach_qr_invalid'; end if;
  if participant.current_coach_id is not null and participant.current_coach_id <> coach.user_id
  then raise exception 'coach_mismatch'; end if;
  select * into target_program from public.programs where id = target_program_id for update;
  if target_program.id is null or target_program.status not in ('scheduled', 'active')
    or target_program.pricing_mode <> 'free' then raise exception 'program_unavailable'; end if;
  if target_program.registration_closes_at is not null
    and statement_timestamp() >= target_program.registration_closes_at
  then raise exception 'registration_closed'; end if;
  if target_program.participant_limit is not null and (
    select count(*) from public.program_enrollments enrollment
    where enrollment.program_id = target_program_id
      and enrollment.status in ('active', 'completed')
  ) >= target_program.participant_limit then raise exception 'program_full'; end if;
  update public.profiles set current_coach_id = coach.user_id,
    updated_at = statement_timestamp()
  where user_id = participant.user_id and current_coach_id is null;
  insert into public.program_enrollments(program_id, participant_id, coach_id, status)
  values (target_program_id, participant.user_id, coach.user_id, 'active')
  on conflict (program_id, participant_id) do update set program_id = excluded.program_id
  returning * into result;
  insert into public.program_scores(enrollment_id) values (result.id) on conflict do nothing;
  return result;
end;
$$;

create or replace function public.create_program_payment_order(
  target_program_id uuid, coach_qr_payload text, request_idempotency_key text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  actor_id uuid := (select auth.uid()); target_program public.programs;
  target_coach public.profiles; actor_profile public.profiles;
  destination public.payment_destinations; enrollment public.program_enrollments;
  existing public.payment_orders; result public.payment_orders; occupied integer;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if actor_id is null then raise exception 'authentication_required'; end if;
  select * into existing from public.payment_orders
  where owner_user_id = actor_id and idempotency_key = request_idempotency_key;
  if existing.id is not null then
    if existing.program_id is distinct from target_program_id then raise exception 'idempotency_conflict'; end if;
    return jsonb_build_object('order_id', existing.id, 'amount_minor', existing.amount_minor,
      'currency', existing.currency, 'status', existing.status,
      'reservation_expires_at', existing.reservation_expires_at);
  end if;
  select * into actor_profile from public.profiles where user_id = actor_id for update;
  if actor_profile.user_id is null or actor_profile.role not in ('participant', 'coach')
  then raise exception 'permission_denied'; end if;
  select * into target_program from public.programs where id = target_program_id for update;
  if target_program.id is null or target_program.status not in ('scheduled', 'active')
    or target_program.published_at is null or target_program.pricing_mode <> 'paid'
  then raise exception 'program_unavailable'; end if;
  if target_program.registration_closes_at is not null
    and statement_timestamp() >= target_program.registration_closes_at
  then raise exception 'registration_closed'; end if;
  select * into target_coach from public.profiles
  where coach_qr_identifier = coach_qr_payload and role = 'coach'
    and coach_is_approved and private.has_active_coach_access(user_id);
  if target_coach.user_id is null or target_coach.user_id = actor_id
  then raise exception 'coach_invalid'; end if;
  if actor_profile.current_coach_id is not null and actor_profile.current_coach_id <> target_coach.user_id
  then raise exception 'coach_mismatch'; end if;
  select * into destination from private.current_payment_destination();
  if destination.id is null then raise exception 'payment_destination_unavailable'; end if;
  select count(*) into occupied from public.program_enrollments
  where program_id = target_program.id and status in ('waiting_for_payment', 'active', 'completed');
  if target_program.participant_limit is not null and occupied >= target_program.participant_limit
  then raise exception 'program_full'; end if;
  select * into enrollment from public.program_enrollments
  where program_id = target_program.id and participant_id = actor_id for update;
  if enrollment.status in ('active', 'completed') then raise exception 'already_enrolled'; end if;
  if enrollment.id is null then
    insert into public.program_enrollments(program_id, participant_id, coach_id, status)
    values (target_program.id, actor_id, target_coach.user_id, 'waiting_for_payment') returning * into enrollment;
  else
    update public.program_enrollments set coach_id = target_coach.user_id,
      status = 'waiting_for_payment', enrolled_at = statement_timestamp(), completed_at = null
    where id = enrollment.id returning * into enrollment;
  end if;
  update public.profiles set current_coach_id = target_coach.user_id,
    updated_at = statement_timestamp()
  where user_id = actor_id and current_coach_id is null;
  insert into public.payment_orders(
    owner_user_id, purpose, program_id, pending_enrollment_id, coach_user_id_snapshot,
    amount_minor, destination_id, destination_version, bank_code_snapshot,
    bank_name_snapshot, account_name_snapshot, account_reference_snapshot,
    qris_object_path_snapshot, reserved_at, reservation_expires_at, retention_after,
    timezone_snapshot, status, idempotency_key
  ) values (
    actor_id, 'program_enrollment', target_program.id, enrollment.id, target_coach.user_id,
    round(target_program.desired_price)::bigint, destination.id, destination.version,
    destination.bank_code, destination.bank_name, destination.account_name,
    destination.account_reference, destination.qris_object_path, statement_timestamp(),
    statement_timestamp() + interval '24 hours',
    ((target_program.ends_on + 30)::timestamp at time zone target_program.timezone),
    target_program.timezone, 'awaiting_evidence', request_idempotency_key
  ) returning * into result;
  insert into public.payment_events(order_id, actor_id, event_type)
  values (result.id, actor_id, 'order_created');
  return jsonb_build_object('order_id', result.id, 'amount_minor', result.amount_minor,
    'currency', result.currency, 'status', result.status,
    'reservation_expires_at', result.reservation_expires_at);
end;
$$;

create or replace function public.list_my_assigned_participants()
returns setof jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  if not private.has_active_coach_access((select auth.uid()))
  then raise exception 'coach_entitlement_inactive'; end if;
  return query
  select jsonb_build_object(
    'profile', jsonb_build_object(
      'user_id', participant.user_id, 'display_name', participant.display_name,
      'city', participant.city, 'phone_number', participant.phone_number,
      'avatar_path', participant.provider_avatar_url, 'member_level', participant.member_level
    ),
    'active_enrollment_count', (
      select count(*) from public.program_enrollments enrollment
      where enrollment.participant_id = participant.user_id
        and enrollment.coach_id = (select auth.uid())
        and enrollment.status = 'active'
    ),
    'pending_review_count', (
      select count(*) from public.step_submissions submission
      join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
      where enrollment.participant_id = participant.user_id
        and enrollment.coach_id = (select auth.uid())
        and submission.status = 'pending'
    ),
    'average_progress_percentage', coalesce((
      select round(avg(score.progress_percentage))::integer
      from public.program_scores score
      join public.program_enrollments enrollment on enrollment.id = score.enrollment_id
      where enrollment.participant_id = participant.user_id
        and enrollment.coach_id = (select auth.uid())
    ), 0)
  )
  from public.profiles participant
  where participant.role in ('participant', 'coach')
    and participant.current_coach_id = (select auth.uid())
  order by participant.display_name, participant.user_id;
end;
$$;

create or replace function public.change_my_coach_from_qr(
  scanned_coach_qr text, request_idempotency_key text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  participant public.profiles; coach public.profiles;
  existing_request public.participant_coach_change_requests;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if length(trim(coalesce(scanned_coach_qr, ''))) not between 16 and 128
  then raise exception 'coach_qr_invalid'; end if;
  select * into participant from public.profiles where user_id = (select auth.uid()) for update;
  if participant.user_id is null or participant.role not in ('participant', 'coach')
    or participant.onboarding_status <> 'active' then raise exception 'permission_denied'; end if;
  select * into existing_request from public.participant_coach_change_requests
  where participant_id = participant.user_id and idempotency_key = request_idempotency_key;
  if existing_request.id is not null then
    select * into coach from public.profiles where user_id = existing_request.coach_id;
    return jsonb_build_object('public_profile_id', coach.public_profile_id,
      'display_name', coach.display_name, 'city', coach.city,
      'photo_reference', coach.provider_avatar_url);
  end if;
  select * into coach from public.profiles
  where coach_qr_identifier = trim(scanned_coach_qr) and role = 'coach'
    and coach_is_approved and onboarding_status = 'active'
    and private.has_active_coach_access(user_id);
  if coach.user_id is null or coach.user_id = participant.user_id
  then raise exception 'coach_unavailable'; end if;
  insert into public.participant_coach_change_requests(participant_id, idempotency_key, coach_id)
  values (participant.user_id, request_idempotency_key, coach.user_id);
  update public.profiles set current_coach_id = coach.user_id,
    updated_at = statement_timestamp() where user_id = participant.user_id;
  update public.program_enrollments set coach_id = coach.user_id
  where participant_id = participant.user_id and status = 'active';
  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (participant.user_id, 'participant_coach_changed', participant.user_id,
    'Pergantian Coach melalui QR terverifikasi',
    jsonb_build_object('coach_public_profile_id', coach.public_profile_id));
  return jsonb_build_object('public_profile_id', coach.public_profile_id,
    'display_name', coach.display_name, 'city', coach.city,
    'photo_reference', coach.provider_avatar_url);
end;
$$;

revoke all on function public.get_my_assigned_coach() from public, anon, authenticated, service_role;
revoke all on function public.pending_program_enrollment_availability(uuid) from public, anon, authenticated, service_role;
revoke all on function public.resolve_coach_qr_for_enrollment(text) from public, anon, authenticated, service_role;
revoke all on function public.enroll_free_program(uuid, text) from public, anon, authenticated, service_role;
revoke all on function public.create_program_payment_order(uuid, text, text) from public, anon, authenticated, service_role;
revoke all on function public.list_my_assigned_participants() from public, anon, authenticated, service_role;
revoke all on function public.change_my_coach_from_qr(text, text) from public, anon, authenticated, service_role;

grant execute on function public.get_my_assigned_coach() to authenticated;
grant execute on function public.pending_program_enrollment_availability(uuid) to authenticated;
grant execute on function public.resolve_coach_qr_for_enrollment(text) to authenticated;
grant execute on function public.enroll_free_program(uuid, text) to authenticated;
grant execute on function public.create_program_payment_order(uuid, text, text) to authenticated;
grant execute on function public.list_my_assigned_participants() to authenticated;
grant execute on function public.change_my_coach_from_qr(text, text) to authenticated;
