alter table public.profiles
  drop constraint profiles_current_coach_fk,
  add constraint profiles_current_coach_fk
    foreign key (current_coach_id)
    references public.profiles(user_id)
    on delete set null;

alter table public.step_submissions
  drop constraint step_submissions_reviewer_id_fkey,
  add constraint step_submissions_reviewer_id_fkey
    foreign key (reviewer_id)
    references public.profiles(user_id)
    on delete set null;

alter table public.quiz_attempt_results
  drop constraint quiz_attempt_results_reopened_by_fkey,
  add constraint quiz_attempt_results_reopened_by_fkey
    foreign key (reopened_by)
    references public.profiles(user_id)
    on delete set null;

alter table public.weigh_ins
  drop constraint weigh_ins_corrected_by_fkey,
  add constraint weigh_ins_corrected_by_fkey
    foreign key (corrected_by)
    references public.profiles(user_id)
    on delete set null;

alter table public.score_adjustments
  alter column actor_id drop not null,
  drop constraint score_adjustments_actor_id_fkey,
  add constraint score_adjustments_actor_id_fkey
    foreign key (actor_id)
    references public.profiles(user_id)
    on delete set null;

alter table public.program_winners
  alter column participant_id drop not null,
  drop constraint program_winners_participant_id_fkey,
  add constraint program_winners_participant_id_fkey
    foreign key (participant_id)
    references public.profiles(user_id)
    on delete set null;

alter table public.audit_events
  drop constraint audit_events_actor_id_fkey,
  add constraint audit_events_actor_id_fkey
    foreign key (actor_id)
    references public.profiles(user_id)
    on delete set null;

create or replace function private.assert_recent_account_reauthentication(
  target_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  session_identifier uuid;
begin
  begin
    session_identifier := nullif(
      (select auth.jwt() ->> 'session_id'),
      ''
    )::uuid;
  exception when invalid_text_representation then
    raise exception 'recent_reauthentication_required';
  end;

  if session_identifier is null or not exists (
    select 1
    from auth.sessions session
    where session.id = session_identifier
      and session.user_id = target_user_id
      and session.created_at >= clock_timestamp() - interval '5 minutes'
  ) then
    raise exception 'recent_reauthentication_required';
  end if;
end;
$$;

create or replace function public.prepare_my_account_deletion()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  caller_role text;
  media_manifest jsonb;
begin
  if caller_id is null then
    raise exception 'permission_denied';
  end if;

  perform private.assert_recent_account_reauthentication(caller_id);

  select role into caller_role
  from public.profiles
  where user_id = caller_id
  for update;

  if caller_role is null then
    raise exception 'profile_not_found';
  end if;
  if caller_role = 'admin' then
    raise exception 'admin_account_deletion_not_allowed';
  end if;
  if exists (
    select 1 from public.programs
    where created_by = caller_id
  ) or (
    caller_role = 'coach'
    and exists (
      select 1 from public.program_enrollments
      where coach_id = caller_id
    )
  ) then
    raise exception 'account_relationships_require_transfer';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'bucket_id', object.bucket_id,
        'name', object.name
      )
      order by object.bucket_id, object.name
    ),
    '[]'::jsonb
  )
  into media_manifest
  from storage.objects object
  where object.owner_id = caller_id::text;

  return media_manifest;
end;
$$;

create or replace function public.finalize_my_account_deletion()
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  caller_role text;
begin
  if caller_id is null then
    raise exception 'permission_denied';
  end if;

  perform private.assert_recent_account_reauthentication(caller_id);

  select role into caller_role
  from public.profiles
  where user_id = caller_id
  for update;

  if caller_role is null then
    raise exception 'profile_not_found';
  end if;
  if caller_role = 'admin' then
    raise exception 'admin_account_deletion_not_allowed';
  end if;
  if exists (
    select 1 from public.programs
    where created_by = caller_id
  ) or (
    caller_role = 'coach'
    and exists (
      select 1 from public.program_enrollments
      where coach_id = caller_id
    )
  ) then
    raise exception 'account_relationships_require_transfer';
  end if;
  if exists (
    select 1 from storage.objects object
    where object.owner_id = caller_id::text
  ) then
    raise exception 'private_media_cleanup_required';
  end if;

  update public.program_winners
  set participant_id = null,
      display_name = 'Akun dihapus'
  where participant_id = caller_id;

  delete from public.program_entitlements
  where participant_id = caller_id;

  delete from public.commerce_transactions
  where participant_id = caller_id;

  delete from public.program_enrollments
  where participant_id = caller_id;

  delete from public.audit_events
  where subject_id = caller_id;

  update public.profiles
  set display_name = 'Akun dihapus',
      phone_number = null,
      member_level = null,
      current_coach_id = null,
      coach_qr_identifier = null,
      coach_is_approved = false,
      coach_is_public = false,
      account_purpose = 'participant',
      onboarding_status = 'cleanup_pending',
      provisional_expires_at = clock_timestamp(),
      finalized_at = null,
      updated_at = clock_timestamp()
  where user_id = caller_id;

  return caller_id;
end;
$$;

revoke all on function private.assert_recent_account_reauthentication(uuid)
  from public, anon, authenticated;
revoke all on function public.prepare_my_account_deletion()
  from public, anon, authenticated;
revoke all on function public.finalize_my_account_deletion()
  from public, anon, authenticated;

grant execute on function public.prepare_my_account_deletion()
  to authenticated;
grant execute on function public.finalize_my_account_deletion()
  to authenticated;

comment on function public.prepare_my_account_deletion() is
  'Validates recent reauthentication and returns owned Storage objects for '
  'server-side deletion through the Storage API.';
comment on function public.finalize_my_account_deletion() is
  'Redacts and removes application data after Storage cleanup. The trusted '
  'server must then hard-delete the Auth user through the Auth Admin API.';
