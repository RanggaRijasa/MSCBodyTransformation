create extension if not exists pg_cron;

alter table public.profiles
  add column member_level text,
  add column account_purpose text not null default 'participant',
  add column onboarding_status text not null default 'active',
  add column provisional_expires_at timestamptz,
  add column finalized_at timestamptz default now();

update public.profiles
set finalized_at = coalesce(updated_at, created_at, now())
where onboarding_status = 'active'
  and finalized_at is null;

alter table public.profiles
  add constraint profiles_member_level_check check (
    member_level is null or member_level in (
      'member', 'sc', 'sb', 'supervisor', 'world_team', 'tab_team',
      'get_team', 'millionaire_team', 'presidents_team'
    )
  ),
  add constraint profiles_account_purpose_check check (
    account_purpose in ('participant', 'coach_applicant')
  ),
  add constraint profiles_onboarding_status_check check (
    onboarding_status in (
      'provisional', 'coach_handoff_pending', 'active', 'cleanup_pending'
    )
  ),
  add constraint profiles_provisional_expiry_shape check (
    (
      onboarding_status in (
        'provisional', 'coach_handoff_pending', 'cleanup_pending'
      )
      and provisional_expires_at is not null
      and finalized_at is null
    )
    or (
      onboarding_status = 'active'
      and provisional_expires_at is null
      and finalized_at is not null
    )
  );

create index profiles_provisional_expiry_idx
  on public.profiles(provisional_expires_at)
  where onboarding_status in (
    'provisional', 'coach_handoff_pending', 'cleanup_pending'
  );

create or replace function private.normalized_signup_display_name(
  metadata jsonb
)
returns text
language sql
immutable
security invoker
set search_path = ''
as $$
  select coalesce(
    nullif(
      left(
        trim(
          regexp_replace(
            coalesce(metadata ->> 'display_name', ''),
            '[[:cntrl:]]',
            '',
            'g'
          )
        ),
        80
      ),
      ''
    ),
    'Peserta baru'
  );
$$;

create or replace function private.bootstrap_participant_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    user_id,
    role,
    display_name,
    account_purpose,
    onboarding_status,
    provisional_expires_at,
    finalized_at,
    created_at,
    updated_at
  ) values (
    new.id,
    'participant',
    private.normalized_signup_display_name(new.raw_user_meta_data),
    'participant',
    'provisional',
    now() + interval '24 hours',
    null,
    coalesce(new.created_at, now()),
    now()
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists auth_user_bootstrap_participant_profile
on auth.users;

create trigger auth_user_bootstrap_participant_profile
after insert on auth.users
for each row execute function private.bootstrap_participant_profile();

insert into public.profiles (
  user_id,
  role,
  display_name,
  account_purpose,
  onboarding_status,
  provisional_expires_at,
  finalized_at,
  created_at,
  updated_at
)
select
  users.id,
  'participant',
  private.normalized_signup_display_name(users.raw_user_meta_data),
  'participant',
  'provisional',
  now() + interval '24 hours',
  null,
  coalesce(users.created_at, now()),
  now()
from auth.users users
where not exists (
  select 1
  from public.profiles profile
  where profile.user_id = users.id
);

create or replace function public.update_my_profile(
  new_display_name text,
  new_phone_number text,
  new_member_level text,
  new_account_purpose text default 'participant'
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  updated_profile public.profiles;
  normalized_name text := trim(coalesce(new_display_name, ''));
  normalized_phone text := regexp_replace(
    coalesce(new_phone_number, ''),
    '[[:space:]-]',
    '',
    'g'
  );
begin
  if caller_id is null then
    raise exception 'permission_denied';
  end if;

  if length(normalized_name) not between 2 and 80 then
    raise exception 'display_name_invalid';
  end if;

  if normalized_phone !~ '^\+?[0-9]{8,15}$' then
    raise exception 'phone_number_invalid';
  end if;

  if new_member_level not in (
    'member', 'sc', 'sb', 'supervisor', 'world_team', 'tab_team',
    'get_team', 'millionaire_team', 'presidents_team'
  ) then
    raise exception 'member_level_invalid';
  end if;

  if new_account_purpose not in ('participant', 'coach_applicant') then
    raise exception 'account_purpose_invalid';
  end if;

  if new_account_purpose = 'coach_applicant'
     and new_member_level = 'member' then
    raise exception 'coach_level_ineligible';
  end if;

  update public.profiles
  set display_name = normalized_name,
      phone_number = normalized_phone,
      member_level = new_member_level,
      account_purpose = new_account_purpose,
      updated_at = now()
  where user_id = caller_id
  returning * into updated_profile;

  if updated_profile.user_id is null then
    raise exception 'profile_not_found';
  end if;

  return updated_profile;
end;
$$;

create or replace function public.finalize_participant_onboarding(
  coach_qr text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  participant public.profiles;
  coach public.profiles;
begin
  if caller_id is null then
    raise exception 'permission_denied';
  end if;

  select * into participant
  from public.profiles
  where user_id = caller_id
  for update;

  if participant.user_id is null or participant.role <> 'participant' then
    raise exception 'permission_denied';
  end if;

  if participant.onboarding_status = 'active' then
    return participant;
  end if;

  if participant.onboarding_status <> 'provisional'
     or participant.account_purpose <> 'participant'
     or participant.member_level is null
     or participant.phone_number is null then
    raise exception 'profile_incomplete';
  end if;

  if participant.provisional_expires_at <= now() then
    raise exception 'provisional_identity_expired';
  end if;

  select * into coach
  from public.profiles
  where coach_qr_identifier = trim(coach_qr)
  for share;

  if coach.user_id is null
     or coach.role <> 'coach'
     or not coach.coach_is_approved then
    raise exception 'coach_qr_invalid';
  end if;

  update public.profiles
  set current_coach_id = coach.user_id,
      onboarding_status = 'active',
      provisional_expires_at = null,
      finalized_at = now(),
      updated_at = now()
  where user_id = caller_id
  returning * into participant;

  return participant;
end;
$$;

create or replace function public.prepare_coach_application_handoff()
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  profile public.profiles;
begin
  if caller_id is null then
    raise exception 'permission_denied';
  end if;

  select * into profile
  from public.profiles
  where user_id = caller_id
  for update;

  if profile.user_id is null
     or profile.role <> 'participant'
     or profile.onboarding_status <> 'provisional'
     or profile.account_purpose <> 'coach_applicant'
     or profile.member_level is null
     or profile.member_level = 'member'
     or profile.phone_number is null then
    raise exception 'coach_handoff_incomplete';
  end if;

  if profile.provisional_expires_at <= now() then
    raise exception 'provisional_identity_expired';
  end if;

  update public.profiles
  set onboarding_status = 'coach_handoff_pending',
      updated_at = now()
  where user_id = caller_id
  returning * into profile;

  return profile;
end;
$$;

create or replace function public.pending_program_enrollment_availability(
  target_program_id uuid
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_profile public.profiles;
  target_program public.programs;
begin
  select * into caller_profile
  from public.profiles
  where user_id = (select auth.uid());

  if caller_profile.user_id is null
     or caller_profile.role <> 'participant' then
    raise exception 'permission_denied';
  end if;

  select * into target_program
  from public.programs
  where id = target_program_id
    and status in ('scheduled', 'active');

  if target_program.id is null then
    return 'program_unavailable';
  end if;

  if target_program.registration_closes_at is not null
     and clock_timestamp() >= target_program.registration_closes_at then
    return 'registration_closed';
  end if;

  if target_program.participant_limit is not null and (
    select count(*)
    from public.program_enrollments enrollment
    where enrollment.program_id = target_program.id
      and enrollment.status in ('active', 'completed')
  ) >= target_program.participant_limit then
    return 'program_full';
  end if;

  return 'available';
end;
$$;

create or replace function private.provisional_identity_has_relationships(
  target_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    exists (
      select 1 from public.program_enrollments enrollment
      where enrollment.participant_id = target_user_id
         or enrollment.coach_id = target_user_id
    )
    or exists (
      select 1 from public.programs program
      where program.created_by = target_user_id
    )
    or exists (
      select 1 from public.audit_events event
      where event.actor_id = target_user_id
    )
    or exists (
      select 1 from public.profiles profile
      where profile.current_coach_id = target_user_id
    );
$$;

create or replace function public.cancel_my_provisional_identity()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  profile_status text;
begin
  if caller_id is null then
    raise exception 'permission_denied';
  end if;

  select onboarding_status into profile_status
  from public.profiles
  where user_id = caller_id
  for update;

  if profile_status is null then
    return true;
  end if;

  if profile_status not in (
    'provisional', 'coach_handoff_pending', 'cleanup_pending'
  ) or private.provisional_identity_has_relationships(caller_id) then
    raise exception 'provisional_cleanup_not_allowed';
  end if;

  delete from auth.users where id = caller_id;
  return true;
end;
$$;

create or replace function private.cleanup_expired_provisional_identities()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  deleted_count integer;
begin
  with removable as (
    select profile.user_id
    from public.profiles profile
    where profile.onboarding_status in (
        'provisional', 'coach_handoff_pending', 'cleanup_pending'
      )
      and profile.provisional_expires_at <= now()
      and not private.provisional_identity_has_relationships(profile.user_id)
    for update skip locked
  ), deleted as (
    delete from auth.users users
    using removable
    where users.id = removable.user_id
    returning users.id
  )
  select count(*)::integer into deleted_count from deleted;

  return deleted_count;
end;
$$;

revoke all on function private.normalized_signup_display_name(jsonb)
  from public, anon, authenticated;
revoke all on function private.bootstrap_participant_profile()
  from public, anon, authenticated;
revoke all on function private.provisional_identity_has_relationships(uuid)
  from public, anon, authenticated;
revoke all on function private.cleanup_expired_provisional_identities()
  from public, anon, authenticated;

revoke all on function public.update_my_profile(text, text, text, text)
  from public, anon, authenticated;
revoke all on function public.finalize_participant_onboarding(text)
  from public, anon, authenticated;
revoke all on function public.prepare_coach_application_handoff()
  from public, anon, authenticated;
revoke all on function public.pending_program_enrollment_availability(uuid)
  from public, anon, authenticated;
revoke all on function public.cancel_my_provisional_identity()
  from public, anon, authenticated;

grant execute on function public.update_my_profile(text, text, text, text)
  to authenticated;
grant execute on function public.finalize_participant_onboarding(text)
  to authenticated;
grant execute on function public.prepare_coach_application_handoff()
  to authenticated;
grant execute on function public.pending_program_enrollment_availability(uuid)
  to authenticated;
grant execute on function public.cancel_my_provisional_identity()
  to authenticated;

do $$
begin
  if to_regprocedure('cron.schedule(text,text,text)') is not null then
    perform cron.schedule(
      'phase10-expired-provisional-cleanup',
      '17 * * * *',
      'select private.cleanup_expired_provisional_identities()'
    );
  end if;
end;
$$;
