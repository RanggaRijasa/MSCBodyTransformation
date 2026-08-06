alter table public.commerce_transactions
  alter column participant_id drop not null,
  drop constraint commerce_transactions_participant_id_fkey,
  add constraint commerce_transactions_participant_id_fkey
    foreign key (participant_id)
    references public.profiles(user_id)
    on delete set null;

alter table public.audit_events
  alter column subject_id drop not null;

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

  update public.commerce_transactions
  set participant_id = null,
      updated_at = clock_timestamp()
  where participant_id = caller_id;

  delete from public.program_enrollments
  where participant_id = caller_id;

  update public.audit_events
  set actor_id = case
        when actor_id = caller_id then null
        else actor_id
      end,
      subject_id = case
        when subject_id = caller_id then null
        else subject_id
      end,
      summary = case
        when actor_id = caller_id or subject_id = caller_id
          then 'Akun dihapus'
        else summary
      end,
      payload = case
        when actor_id = caller_id or subject_id = caller_id
          then '{}'::jsonb
        else payload
      end
  where actor_id = caller_id
     or subject_id = caller_id;

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

revoke all on function public.finalize_my_account_deletion()
  from public, anon, authenticated;
grant execute on function public.finalize_my_account_deletion()
  to authenticated;

comment on function public.finalize_my_account_deletion() is
  'Redacts application data after Storage cleanup, revokes access records, '
  'and preserves anonymized financial and audit records. The trusted server '
  'must then hard-delete the Auth user through the Auth Admin API.';
