-- Phase 07 Web-only additive operations. This file is applied to local Supabase
-- for verification and is not a hosted deployment authorization.

alter table public.profiles
  add column if not exists profile_avatar_path text;

alter table public.profiles
  drop constraint if exists profiles_profile_avatar_path_shape;

alter table public.profiles
  add constraint profiles_profile_avatar_path_shape check (
    profile_avatar_path is null
    or profile_avatar_path ~ (
      '^avatars/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-'
      || '[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-'
      || '[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
    )
  );

create table if not exists public.participant_coach_change_requests (
  id uuid primary key default gen_random_uuid(),
  participant_id uuid not null references public.profiles(user_id) on delete cascade,
  idempotency_key text not null,
  coach_id uuid not null references public.profiles(user_id),
  created_at timestamptz not null default statement_timestamp(),
  unique (participant_id, idempotency_key)
);

alter table public.participant_coach_change_requests enable row level security;
revoke all on public.participant_coach_change_requests from public, anon, authenticated;

create or replace function public.get_my_participant_profile_context()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  caller public.profiles;
  coach public.profiles;
begin
  select * into caller from public.profiles
  where user_id = (select auth.uid());
  if caller.user_id is null then raise exception 'permission_denied'; end if;

  if caller.current_coach_id is not null then
    select * into coach from public.profiles where user_id = caller.current_coach_id;
  end if;

  return jsonb_build_object(
    'avatar_path', caller.profile_avatar_path,
    'coach', case when coach.user_id is null then null else jsonb_build_object(
      'public_profile_id', coach.public_profile_id,
      'display_name', coach.display_name,
      'city', coach.city,
      'photo_reference', coach.provider_avatar_url
    ) end
  );
end;
$$;

create or replace function public.update_my_profile_avatar(
  target_path text,
  request_idempotency_key text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  expected_pattern text;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if caller_id is null then raise exception 'permission_denied'; end if;

  expected_pattern := '^avatars/' || caller_id::text || '/'
    || '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-'
    || '[0-9a-f]{12}\.jpg$';
  if target_path !~ expected_pattern then raise exception 'avatar_path_invalid'; end if;

  if not exists (
    select 1 from storage.objects object
    where object.bucket_id = 'public-media'
      and object.name = target_path
      and lower(coalesce(object.metadata ->> 'mimetype', '')) = 'image/jpeg'
      and coalesce((object.metadata ->> 'size')::bigint, 0) between 1 and 8388608
  ) then raise exception 'avatar_object_invalid'; end if;

  update public.profiles
  set profile_avatar_path = target_path, updated_at = statement_timestamp()
  where user_id = caller_id;
  if not found then raise exception 'profile_not_found'; end if;
  return target_path;
end;
$$;

create or replace function public.change_my_coach_from_qr(
  scanned_coach_qr text,
  request_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  participant public.profiles;
  coach public.profiles;
  existing_request public.participant_coach_change_requests;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if length(trim(coalesce(scanned_coach_qr, ''))) not between 16 and 128 then
    raise exception 'coach_qr_invalid';
  end if;

  select * into participant from public.profiles
  where user_id = (select auth.uid()) for update;
  if participant.user_id is null or participant.role <> 'participant'
    or participant.onboarding_status <> 'active'
  then raise exception 'permission_denied'; end if;

  select * into existing_request
  from public.participant_coach_change_requests
  where participant_id = participant.user_id
    and idempotency_key = request_idempotency_key;
  if existing_request.id is not null then
    select * into coach from public.profiles where user_id = existing_request.coach_id;
    return jsonb_build_object(
      'public_profile_id', coach.public_profile_id,
      'display_name', coach.display_name,
      'city', coach.city,
      'photo_reference', coach.provider_avatar_url
    );
  end if;

  select * into coach from public.profiles
  where coach_qr_identifier = trim(scanned_coach_qr)
    and role = 'coach'
    and coach_is_approved
    and onboarding_status = 'active'
    and exists (
      select 1 from public.coach_access_entitlements entitlement
      where entitlement.coach_user_id = public.profiles.user_id
        and entitlement.status = 'active'
        and entitlement.starts_at <= statement_timestamp()
        and entitlement.ends_at > statement_timestamp()
    );
  if coach.user_id is null then raise exception 'coach_unavailable'; end if;

  insert into public.participant_coach_change_requests(
    participant_id, idempotency_key, coach_id
  ) values (
    participant.user_id, request_idempotency_key, coach.user_id
  );

  update public.profiles
  set current_coach_id = coach.user_id, updated_at = statement_timestamp()
  where user_id = participant.user_id;

  update public.program_enrollments
  set coach_id = coach.user_id
  where participant_id = participant.user_id
    and status = 'active';

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    participant.user_id,
    'participant_coach_changed',
    participant.user_id,
    'Pergantian Coach melalui QR terverifikasi',
    jsonb_build_object('coach_public_profile_id', coach.public_profile_id)
  );

  return jsonb_build_object(
    'public_profile_id', coach.public_profile_id,
    'display_name', coach.display_name,
    'city', coach.city,
    'photo_reference', coach.provider_avatar_url
  );
end;
$$;

revoke all on function public.get_my_participant_profile_context()
  from public, anon, authenticated, service_role;
revoke all on function public.update_my_profile_avatar(text, text)
  from public, anon, authenticated, service_role;
revoke all on function public.change_my_coach_from_qr(text, text)
  from public, anon, authenticated, service_role;

grant execute on function public.get_my_participant_profile_context()
  to authenticated;
grant execute on function public.update_my_profile_avatar(text, text)
  to authenticated;
grant execute on function public.change_my_coach_from_qr(text, text)
  to authenticated;
