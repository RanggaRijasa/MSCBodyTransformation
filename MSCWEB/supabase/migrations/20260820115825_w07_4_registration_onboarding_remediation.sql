-- MSCWEB W07.4 first-login onboarding authority.
-- Local-only until hosted Auth/schema/function deployment is explicitly approved.

alter table public.profiles
  add column if not exists onboarding_version integer not null default 1
    check (onboarding_version > 0);

create index if not exists profiles_onboarding_state_idx
  on public.profiles(onboarding_status, account_purpose, provisional_expires_at);

alter table public.payment_events
  drop constraint if exists payment_events_event_type_check;
alter table public.payment_events
  add constraint payment_events_event_type_check check (event_type in (
    'order_created', 'reservation_expired', 'reservation_restored',
    'upload_intent_created', 'evidence_submitted', 'evidence_rejected',
    'correction_requested', 'payment_approved', 'order_cancelled',
    'reversal_required', 'reversal_recorded', 'entitlement_projected',
    'enrollment_projected', 'evidence_deleted'
  ));

alter table public.payment_evidence_attempts
  drop constraint if exists payment_evidence_submission_shape;
alter table public.payment_evidence_attempts
  add constraint payment_evidence_submission_shape check (
    (status = 'prepared' and submitted_at is null)
    or (status in ('submitted', 'rejected', 'approved') and submitted_at is not null)
    or status = 'deleted'
  );

create table if not exists private.provisional_cancellation_receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  idempotency_key text not null check (length(idempotency_key) between 8 and 128),
  source text not null default 'user' check (source in ('user', 'expiry')),
  status text not null default 'queued'
    check (status in ('queued', 'processing', 'failed', 'completed', 'retained')),
  object_paths text[] not null default '{}',
  attempt_count integer not null default 0 check (attempt_count >= 0),
  lease_expires_at timestamptz,
  last_error_code text,
  requested_at timestamptz not null default statement_timestamp(),
  completed_at timestamptz,
  unique (user_id, idempotency_key)
);

create unique index if not exists provisional_cancellation_one_open_per_user_idx
  on private.provisional_cancellation_receipts(user_id)
  where status in ('queued', 'processing', 'failed');

revoke all on table private.provisional_cancellation_receipts
  from public, anon, authenticated;
grant all on table private.provisional_cancellation_receipts to service_role;

create or replace function private.onboarding_profile_is_complete(profile public.profiles)
returns boolean
language sql immutable security invoker
set search_path = ''
as $$
  select length(trim(profile.display_name)) between 2 and 80
    and profile.display_name <> 'Peserta baru'
    and profile.phone_number ~ '^\+?[0-9]{8,15}$'
    and profile.member_level is not null;
$$;

create or replace function private.assert_active_account()
returns void
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.profiles profile
    where profile.user_id = (select auth.uid())
      and profile.onboarding_status = 'active'
  ) then raise exception 'active_account_required'; end if;
end;
$$;

create or replace function private.current_account_is_active()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles profile
    where profile.user_id = (select auth.uid())
      and profile.onboarding_status = 'active'
  );
$$;

create or replace function private.can_access_payment_order(target_order_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.payment_orders payment_order
    join public.profiles profile on profile.user_id = payment_order.owner_user_id
    where payment_order.id = target_order_id
      and profile.user_id = (select auth.uid())
      and (
        profile.onboarding_status = 'active'
        or (profile.onboarding_status = 'coach_handoff_pending'
          and profile.account_purpose = 'coach_applicant'
          and payment_order.purpose = 'coach_access')
      )
  );
$$;

create or replace function private.can_coach_participant(target_participant uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select private.has_active_coach_access((select auth.uid()))
    and exists (
      select 1 from public.profiles participant
      where participant.user_id = target_participant
        and participant.role = 'participant'
        and participant.onboarding_status = 'active'
        and participant.current_coach_id = (select auth.uid())
    );
$$;

create or replace function private.active_coach_for_onboarding(
  scanned_qr text,
  participant_user_id uuid
)
returns public.profiles
language sql stable security definer
set search_path = ''
as $$
  select coach
  from public.profiles coach
  where coach.coach_qr_identifier = trim(scanned_qr)
    and coach.user_id <> participant_user_id
    and coach.role = 'coach'
    and coach.onboarding_status = 'active'
    and coach.coach_is_approved
    and coach.coach_is_public
    and exists (
      select 1
      from public.coach_access_entitlements entitlement
      where entitlement.coach_user_id = coach.user_id
        and entitlement.status = 'active'
        and entitlement.starts_at <= statement_timestamp()
        and entitlement.ends_at > statement_timestamp()
    )
  limit 1;
$$;

create or replace function public.get_my_session_context()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  profile public.profiles;
  resume_step text;
  latest_order_status text;
begin
  if caller_id is null then raise exception 'authentication_required'; end if;

  select * into profile from public.profiles where user_id = caller_id;
  if profile.user_id is null then raise exception 'session_profile_missing'; end if;

  if profile.onboarding_status = 'active' then
    resume_step := 'active';
  elsif profile.onboarding_status = 'cleanup_pending' then
    resume_step := 'cleanup';
  elsif not private.onboarding_profile_is_complete(profile) then
    resume_step := 'profile';
  elsif profile.account_purpose = 'participant' then
    resume_step := 'participant_coach';
  elsif profile.onboarding_status = 'provisional' then
    resume_step := 'coach_eligibility';
  else
    select payment_order.status into latest_order_status
    from public.payment_orders payment_order
    where payment_order.owner_user_id = caller_id
      and payment_order.purpose = 'coach_access'
    order by payment_order.created_at desc
    limit 1;
    resume_step := case
      when latest_order_status is null then 'coach_eligibility'
      when latest_order_status = 'awaiting_evidence' then 'coach_payment'
      else 'coach_status'
    end;
  end if;

  return jsonb_build_object(
    'user_id', profile.user_id,
    'role', profile.role,
    'onboarding_status', profile.onboarding_status,
    'account_purpose', profile.account_purpose,
    'profile_complete', private.onboarding_profile_is_complete(profile),
    'provisional_expires_at', profile.provisional_expires_at,
    'onboarding_version', profile.onboarding_version,
    'resume_step', resume_step
  );
end;
$$;

create or replace function public.get_my_provisional_onboarding_profile()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare profile public.profiles;
begin
  if (select auth.uid()) is null then raise exception 'authentication_required'; end if;
  select * into profile from public.profiles where user_id = (select auth.uid());
  if profile.user_id is null
    or profile.onboarding_status not in ('provisional', 'coach_handoff_pending') then
    raise exception 'provisional_profile_not_available';
  end if;
  return jsonb_build_object(
    'user_id', profile.user_id,
    'display_name', profile.display_name,
    'phone_number', profile.phone_number,
    'member_level', profile.member_level,
    'account_purpose', profile.account_purpose,
    'onboarding_status', profile.onboarding_status,
    'onboarding_version', profile.onboarding_version
  );
end;
$$;

create or replace function public.save_my_provisional_onboarding_profile(
  new_display_name text,
  new_phone_number text,
  new_member_level text,
  new_account_purpose text,
  expected_version integer
)
returns public.profiles
language plpgsql security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  profile public.profiles;
  normalized_name text := trim(coalesce(new_display_name, ''));
  normalized_phone text := regexp_replace(coalesce(new_phone_number, ''), '[[:space:]-]', '', 'g');
begin
  if caller_id is null then raise exception 'authentication_required'; end if;
  if length(normalized_name) not between 2 and 80 then raise exception 'display_name_invalid'; end if;
  if normalized_phone !~ '^\+?[0-9]{8,15}$' then raise exception 'phone_number_invalid'; end if;
  if new_member_level not in (
    'member', 'sc', 'sb', 'supervisor', 'world_team', 'tab_team',
    'get_team', 'millionaire_team', 'presidents_team'
  ) then raise exception 'member_level_invalid'; end if;
  if new_account_purpose not in ('participant', 'coach_applicant') then
    raise exception 'account_purpose_invalid';
  end if;
  if new_account_purpose = 'coach_applicant' and new_member_level = 'member' then
    raise exception 'coach_level_ineligible';
  end if;

  select * into profile from public.profiles where user_id = caller_id for update;
  if profile.user_id is null or profile.role <> 'participant'
     or profile.onboarding_status <> 'provisional' then
    raise exception 'provisional_profile_not_editable';
  end if;
  if profile.provisional_expires_at <= statement_timestamp() then
    raise exception 'provisional_identity_expired';
  end if;
  if profile.onboarding_version <> expected_version then raise exception 'version_conflict'; end if;

  update public.profiles set
    display_name = normalized_name,
    phone_number = normalized_phone,
    member_level = new_member_level,
    account_purpose = new_account_purpose,
    onboarding_version = onboarding_version + 1,
    updated_at = statement_timestamp()
  where user_id = caller_id
  returning * into profile;
  return profile;
end;
$$;

create or replace function public.validate_participant_onboarding_coach_qr(
  coach_qr text
)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  participant public.profiles;
  coach public.profiles;
begin
  if caller_id is null then raise exception 'authentication_required'; end if;
  select * into participant from public.profiles where user_id = caller_id;
  if participant.user_id is null or participant.role <> 'participant'
     or participant.onboarding_status <> 'provisional'
     or participant.account_purpose <> 'participant'
     or not private.onboarding_profile_is_complete(participant)
     or participant.provisional_expires_at <= statement_timestamp() then
    raise exception 'participant_onboarding_not_ready';
  end if;
  select * into coach from private.active_coach_for_onboarding(coach_qr, caller_id);
  if coach.user_id is null then raise exception 'coach_qr_invalid'; end if;
  return jsonb_build_object(
    'coach_id', coach.user_id,
    'display_name', coach.display_name,
    'city', nullif(coach.city, ''),
    'avatar_url', coach.provider_avatar_url
  );
end;
$$;

drop function if exists public.finalize_participant_onboarding(text);
create or replace function public.finalize_participant_onboarding(
  coach_qr text,
  expected_version integer default null
)
returns public.profiles
language plpgsql security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  participant public.profiles;
  coach public.profiles;
begin
  if caller_id is null then raise exception 'authentication_required'; end if;
  select * into participant from public.profiles where user_id = caller_id for update;
  if participant.user_id is null or participant.role <> 'participant' then
    raise exception 'permission_denied';
  end if;
  if participant.onboarding_status = 'active' then return participant; end if;
  if participant.onboarding_status <> 'provisional'
     or participant.account_purpose <> 'participant'
     or not private.onboarding_profile_is_complete(participant) then
    raise exception 'profile_incomplete';
  end if;
  if participant.provisional_expires_at <= statement_timestamp() then
    raise exception 'provisional_identity_expired';
  end if;
  if expected_version is not null and participant.onboarding_version <> expected_version then
    raise exception 'version_conflict';
  end if;
  select * into coach from private.active_coach_for_onboarding(coach_qr, caller_id);
  if coach.user_id is null then raise exception 'coach_qr_invalid'; end if;

  update public.profiles set
    current_coach_id = coach.user_id,
    onboarding_status = 'active',
    provisional_expires_at = null,
    finalized_at = statement_timestamp(),
    onboarding_version = onboarding_version + 1,
    updated_at = statement_timestamp()
  where user_id = caller_id
  returning * into participant;
  return participant;
end;
$$;

drop function if exists public.prepare_coach_application_handoff();
create or replace function public.prepare_coach_application_handoff(
  expected_version integer default null
)
returns public.profiles
language plpgsql security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  profile public.profiles;
begin
  if caller_id is null then raise exception 'authentication_required'; end if;
  select * into profile from public.profiles where user_id = caller_id for update;
  if profile.user_id is null or profile.role <> 'participant'
     or profile.onboarding_status not in ('provisional', 'coach_handoff_pending')
     or profile.account_purpose <> 'coach_applicant'
     or not private.onboarding_profile_is_complete(profile)
     or profile.member_level = 'member' then
    raise exception 'coach_handoff_incomplete';
  end if;
  if profile.provisional_expires_at <= statement_timestamp() then
    raise exception 'provisional_identity_expired';
  end if;
  if expected_version is not null and profile.onboarding_version <> expected_version then
    raise exception 'version_conflict';
  end if;
  if profile.onboarding_status = 'coach_handoff_pending' then return profile; end if;
  update public.profiles set
    onboarding_status = 'coach_handoff_pending',
    onboarding_version = onboarding_version + 1,
    updated_at = statement_timestamp()
  where user_id = caller_id returning * into profile;
  return profile;
end;
$$;

-- Provisional identities may read only fixed onboarding projections. Active
-- account behavior for self, related Coach, and Admin remains unchanged.
drop policy if exists "profile self coach or admin read" on public.profiles;
drop policy if exists "active profile self coach or admin read" on public.profiles;
create policy "active profile self coach or admin read"
  on public.profiles for select to authenticated
  using (
    (user_id = (select auth.uid()) and onboarding_status = 'active')
    or private.can_coach_participant(user_id)
    or private.is_admin()
  );

drop policy if exists "applicant or admin reads Coach applications" on public.coach_applications;
drop policy if exists "active or onboarding applicant reads Coach applications" on public.coach_applications;
create policy "active or onboarding applicant reads Coach applications"
  on public.coach_applications for select to authenticated
  using (
    private.is_admin()
    or exists (
      select 1 from public.profiles profile
      where profile.user_id = (select auth.uid())
        and profile.user_id = coach_applications.applicant_user_id
        and (
          profile.onboarding_status = 'active'
          or (profile.onboarding_status = 'coach_handoff_pending'
            and profile.account_purpose = 'coach_applicant')
        )
    )
  );

drop policy if exists "owner or admin reads payment orders" on public.payment_orders;
drop policy if exists "active or onboarding owner or admin reads payment orders" on public.payment_orders;
create policy "active or onboarding owner or admin reads payment orders"
  on public.payment_orders for select to authenticated
  using (
    private.is_admin()
    or private.can_access_payment_order(id)
  );

drop policy if exists "owner or admin reads payment evidence metadata" on public.payment_evidence_attempts;
drop policy if exists "active or onboarding owner or admin reads payment evidence meta" on public.payment_evidence_attempts;
create policy "active or onboarding owner or admin reads payment evidence metadata"
  on public.payment_evidence_attempts for select to authenticated
  using (
    private.is_admin()
    or private.can_access_payment_order(order_id)
  );

drop policy if exists "own or coached enrollments" on public.program_enrollments;
drop policy if exists "active own or coached enrollments" on public.program_enrollments;
create policy "active own or coached enrollments"
  on public.program_enrollments for select to authenticated
  using (
    (participant_id = (select auth.uid()) and private.current_account_is_active())
    or private.can_coach_participant(participant_id)
    or private.is_admin()
  );

drop policy if exists "submission owner or related reviewer read" on public.step_submissions;
drop policy if exists "active submission owner or related reviewer read" on public.step_submissions;
create policy "active submission owner or related reviewer read"
  on public.step_submissions for select to authenticated
  using (exists (
    select 1 from public.program_enrollments enrollment
    where enrollment.id = step_submissions.enrollment_id
      and (
        (enrollment.participant_id = (select auth.uid()) and private.current_account_is_active())
        or (enrollment.status <> 'draft'
          and (private.can_coach_participant(enrollment.participant_id) or private.is_admin()))
      )
  ));

drop policy if exists "private weigh in" on public.weigh_ins;
drop policy if exists "active private weigh in" on public.weigh_ins;
create policy "active private weigh in"
  on public.weigh_ins for select to authenticated
  using (exists (
    select 1 from public.program_enrollments enrollment
    where enrollment.id = weigh_ins.enrollment_id
      and (
        (enrollment.participant_id = (select auth.uid()) and private.current_account_is_active())
        or private.can_coach_participant(enrollment.participant_id)
        or private.is_admin()
      )
  ));

drop policy if exists "own assigned coach or admin score read" on public.program_scores;
drop policy if exists "active own assigned coach or admin score read" on public.program_scores;
create policy "active own assigned coach or admin score read"
  on public.program_scores for select to authenticated
  using (exists (
    select 1 from public.program_enrollments enrollment
    where enrollment.id = program_scores.enrollment_id
      and (
        (enrollment.participant_id = (select auth.uid()) and private.current_account_is_active())
        or private.can_coach_participant(enrollment.participant_id)
        or private.is_admin()
      )
  ));

drop policy if exists "own entitlements" on public.program_entitlements;
drop policy if exists "active own entitlements" on public.program_entitlements;
create policy "active own entitlements"
  on public.program_entitlements for select to authenticated
  using (
    (participant_id = (select auth.uid()) and private.current_account_is_active())
    or private.is_admin()
  );

drop policy if exists "own transactions" on public.commerce_transactions;
drop policy if exists "active own transactions" on public.commerce_transactions;
create policy "active own transactions"
  on public.commerce_transactions for select to authenticated
  using (
    (participant_id = (select auth.uid()) and private.current_account_is_active())
    or private.is_admin()
  );

drop policy if exists "Coach or admin reads Coach entitlement" on public.coach_access_entitlements;
drop policy if exists "active Coach or admin reads Coach entitlement" on public.coach_access_entitlements;
create policy "active Coach or admin reads Coach entitlement"
  on public.coach_access_entitlements for select to authenticated
  using (
    (coach_user_id = (select auth.uid()) and private.current_account_is_active())
    or private.is_admin()
  );

drop policy if exists "applicant or admin reads Coach payment state" on public.coach_payment_records;
drop policy if exists "active applicant or admin reads Coach payment state" on public.coach_payment_records;
create policy "active applicant or admin reads Coach payment state"
  on public.coach_payment_records for select to authenticated
  using (
    private.is_admin()
    or (private.current_account_is_active() and exists (
      select 1 from public.coach_applications application
      where application.id = coach_payment_records.application_id
        and application.applicant_user_id = (select auth.uid())
    ))
  );

drop policy if exists "owner uploads prepared payment evidence" on storage.objects;
drop policy if exists "active or onboarding owner uploads prepared payment evidence" on storage.objects;
create policy "active or onboarding owner uploads prepared payment evidence"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'payment-evidence'
    and exists (
      select 1
      from public.payment_evidence_attempts attempt
      join public.payment_orders payment_order on payment_order.id = attempt.order_id
      where attempt.object_path = name and attempt.status = 'prepared'
        and payment_order.status in ('awaiting_evidence', 'correction_required')
        and private.can_access_payment_order(payment_order.id)
    )
  );

drop policy if exists "owner or admin reads payment evidence object" on storage.objects;
drop policy if exists "active or onboarding owner or admin reads payment evidence object" on storage.objects;
create policy "active or onboarding owner or admin reads payment evidence object"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'payment-evidence'
    and (
      private.is_admin()
      or exists (
        select 1
        from public.payment_evidence_attempts attempt
        join public.payment_orders payment_order on payment_order.id = attempt.order_id
        where attempt.object_path = name
          and private.can_access_payment_order(payment_order.id)
      )
    )
  );

drop policy if exists "owner deletes unsubmitted payment evidence" on storage.objects;
drop policy if exists "active or onboarding owner deletes unsubmitted payment evidence" on storage.objects;
create policy "active or onboarding owner deletes unsubmitted payment evidence"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'payment-evidence'
    and exists (
      select 1
      from public.payment_evidence_attempts attempt
      join public.payment_orders payment_order on payment_order.id = attempt.order_id
      where attempt.object_path = name and attempt.status = 'prepared'
        and private.can_access_payment_order(payment_order.id)
    )
  );

create or replace function private.submit_payment_evidence_core(
  target_attempt_id uuid,
  content_sha256_hex text,
  content_byte_size integer,
  content_pixel_width integer,
  content_pixel_height integer,
  allow_provisional_coach boolean
)
returns public.payment_orders
language plpgsql security definer
set search_path = ''
as $$
declare
  actor_id uuid := (select auth.uid());
  attempt public.payment_evidence_attempts;
  target_order public.payment_orders;
  actor_profile public.profiles;
  application public.coach_applications;
  stored_object storage.objects;
begin
  if actor_id is null then raise exception 'authentication_required'; end if;
  select * into actor_profile from public.profiles where user_id = actor_id for update;
  select evidence.* into attempt
  from public.payment_evidence_attempts evidence
  join public.payment_orders payment_order on payment_order.id = evidence.order_id
  where evidence.id = target_attempt_id and payment_order.owner_user_id = actor_id
  for update of evidence;
  if attempt.id is null then raise exception 'payment_evidence_not_found'; end if;
  select * into target_order from public.payment_orders where id = attempt.order_id for update;
  if attempt.status = 'submitted' then return target_order; end if;
  if attempt.status <> 'prepared' then raise exception 'evidence_not_submittable'; end if;
  if target_order.status not in ('awaiting_evidence', 'correction_required') then
    raise exception 'payment_order_not_uploadable';
  end if;
  if target_order.reservation_expires_at is not null
     and statement_timestamp() >= target_order.reservation_expires_at then
    raise exception 'payment_order_expired';
  end if;
  if target_order.status = 'correction_required'
     and target_order.correction_expires_at is not null
     and statement_timestamp() >= target_order.correction_expires_at then
    raise exception 'correction_window_expired';
  end if;
  if actor_profile.onboarding_status <> 'active' then
    if not allow_provisional_coach or actor_profile.onboarding_status <> 'coach_handoff_pending'
       or actor_profile.account_purpose <> 'coach_applicant'
       or target_order.purpose <> 'coach_access' then
      raise exception 'provisional_generic_payment_submit_denied';
    end if;
    select * into application from public.coach_applications
    where id = target_order.coach_application_id
      and applicant_user_id = actor_id for update;
    if application.id is null or application.status <> 'submitted'
       or application.member_level_snapshot is distinct from actor_profile.member_level
       or application.member_level_snapshot = 'member'
       or not application.has_completed_hom_sts
       or not application.has_completed_ict then
      raise exception 'coach_eligibility_incomplete';
    end if;
  end if;
  if content_sha256_hex !~ '^[0-9a-f]{64}$'
    or content_byte_size not between 1 and 8388608
    or content_pixel_width not between 1 and 2048
    or content_pixel_height not between 1 and 2048 then
    raise exception 'evidence_validation_failed';
  end if;
  select * into stored_object from storage.objects object
  where object.bucket_id = 'payment-evidence' and object.name = attempt.object_path;
  if stored_object.id is null then raise exception 'evidence_object_missing'; end if;
  if coalesce(stored_object.metadata ->> 'mimetype', '') <> 'image/jpeg'
    or coalesce((stored_object.metadata ->> 'size')::bigint, 0) <> content_byte_size then
    raise exception 'evidence_object_mismatch';
  end if;

  update public.payment_evidence_attempts set
    mime_type = 'image/jpeg', byte_size = content_byte_size,
    pixel_width = content_pixel_width, pixel_height = content_pixel_height,
    sha256_hex = content_sha256_hex, status = 'submitted',
    submitted_at = statement_timestamp()
  where id = attempt.id;
  update public.payment_orders set
    status = 'under_review', evidence_submitted_at = statement_timestamp(),
    correction_expires_at = null, latest_rejection_reason = null,
    version = version + 1, updated_at = statement_timestamp()
  where id = target_order.id returning * into target_order;
  insert into public.payment_events(order_id, attempt_id, actor_id, event_type)
  values (target_order.id, attempt.id, actor_id, 'evidence_submitted');

  if allow_provisional_coach and actor_profile.onboarding_status = 'coach_handoff_pending' then
    update public.profiles set
      onboarding_status = 'active', provisional_expires_at = null,
      finalized_at = statement_timestamp(), onboarding_version = onboarding_version + 1,
      updated_at = statement_timestamp()
    where user_id = actor_id and onboarding_status = 'coach_handoff_pending';
  end if;
  return target_order;
end;
$$;

create or replace function public.submit_payment_evidence(
  target_attempt_id uuid,
  content_sha256_hex text,
  content_byte_size integer,
  content_pixel_width integer,
  content_pixel_height integer
)
returns public.payment_orders
language sql security definer
set search_path = ''
as $$
  select private.submit_payment_evidence_core(
    target_attempt_id, content_sha256_hex, content_byte_size,
    content_pixel_width, content_pixel_height, false
  );
$$;

create or replace function public.submit_coach_onboarding_payment_evidence(
  target_attempt_id uuid,
  content_sha256_hex text,
  content_byte_size integer,
  content_pixel_width integer,
  content_pixel_height integer
)
returns public.payment_orders
language sql security definer
set search_path = ''
as $$
  select private.submit_payment_evidence_core(
    target_attempt_id, content_sha256_hex, content_byte_size,
    content_pixel_width, content_pixel_height, true
  );
$$;

create or replace function public.request_coach_payment_correction(
  target_order_id uuid,
  expected_version integer,
  correction_reason text,
  request_idempotency_key text
)
returns public.payment_orders
language plpgsql security definer
set search_path = ''
as $$
declare
  reviewer uuid := (select auth.uid());
  target_order public.payment_orders;
  attempt public.payment_evidence_attempts;
  normalized_reason text := trim(coalesce(correction_reason, ''));
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(normalized_reason) < 5 then raise exception 'reason_required'; end if;
  select * into target_order from public.payment_orders
  where id = target_order_id and purpose = 'coach_access' for update;
  if target_order.id is null then raise exception 'payment_order_not_found'; end if;
  if target_order.status = 'correction_required'
     and target_order.latest_rejection_reason = normalized_reason then return target_order; end if;
  if target_order.version <> expected_version then raise exception 'version_conflict'; end if;
  if target_order.status <> 'under_review' then raise exception 'payment_order_not_reviewable'; end if;
  select * into attempt from public.payment_evidence_attempts
  where order_id = target_order.id and status = 'submitted'
  order by attempt_number desc limit 1 for update;
  if attempt.id is null then raise exception 'payment_evidence_not_found'; end if;
  update public.payment_evidence_attempts set
    status = 'rejected', reviewed_at = statement_timestamp(), reviewed_by = reviewer,
    rejection_reason = normalized_reason
  where id = attempt.id;
  update public.payment_orders set
    status = 'correction_required', correction_expires_at = statement_timestamp() + interval '24 hours',
    latest_rejection_reason = normalized_reason, version = version + 1,
    updated_at = statement_timestamp()
  where id = target_order.id returning * into target_order;
  insert into public.payment_events(order_id, attempt_id, actor_id, event_type, metadata)
  values (target_order.id, attempt.id, reviewer, 'correction_requested',
    jsonb_build_object('reason', normalized_reason, 'idempotency_key', request_idempotency_key));
  return target_order;
end;
$$;

-- Preserve the established active-account implementations behind narrow
-- guards. This prevents a provisional Participant role from reaching W03/W05
-- private mutations while keeping active native/web contracts unchanged.
do $$
begin
  if to_regprocedure('private.w074_active_update_my_profile(text,text,text,text)') is null and to_regprocedure('public.w074_active_update_my_profile(text,text,text,text)') is null then
    alter function public.update_my_profile(text,text,text,text) rename to w074_active_update_my_profile;
  end if;
  if to_regprocedure('private.w074_active_pending_program_enrollment_availability(uuid)') is null and to_regprocedure('public.w074_active_pending_program_enrollment_availability(uuid)') is null then
    alter function public.pending_program_enrollment_availability(uuid) rename to w074_active_pending_program_enrollment_availability;
  end if;
  if to_regprocedure('private.w074_active_enroll_free_program(uuid,text)') is null and to_regprocedure('public.w074_active_enroll_free_program(uuid,text)') is null then
    alter function public.enroll_free_program(uuid,text) rename to w074_active_enroll_free_program;
  end if;
  if to_regprocedure('private.w074_active_create_program_payment_order(uuid,text,text,text)') is null and to_regprocedure('public.w074_active_create_program_payment_order(uuid,text,text,text)') is null then
    alter function public.create_program_payment_order(uuid,text,text,text) rename to w074_active_create_program_payment_order;
  end if;
  if to_regprocedure('private.w074_active_prepare_step_submission(uuid,uuid,text)') is null and to_regprocedure('public.w074_active_prepare_step_submission(uuid,uuid,text)') is null then
    alter function public.prepare_step_submission(uuid,uuid,text) rename to w074_active_prepare_step_submission;
  end if;
  if to_regprocedure('private.w074_active_submit_step_answers(uuid,jsonb,text)') is null and to_regprocedure('public.w074_active_submit_step_answers(uuid,jsonb,text)') is null then
    alter function public.submit_step_answers(uuid,jsonb,text) rename to w074_active_submit_step_answers;
  end if;
  if to_regprocedure('private.w074_active_submit_weigh_in(uuid,uuid,text,numeric,text)') is null and to_regprocedure('public.w074_active_submit_weigh_in(uuid,uuid,text,numeric,text)') is null then
    alter function public.submit_weigh_in(uuid,uuid,text,numeric,text) rename to w074_active_submit_weigh_in;
  end if;
  if to_regprocedure('private.w074_active_get_my_dashboard_summary()') is null and to_regprocedure('public.w074_active_get_my_dashboard_summary()') is null then
    alter function public.get_my_dashboard_summary() rename to w074_active_get_my_dashboard_summary;
  end if;
  if to_regprocedure('private.w074_active_get_my_assigned_coach()') is null and to_regprocedure('public.w074_active_get_my_assigned_coach()') is null then
    alter function public.get_my_assigned_coach() rename to w074_active_get_my_assigned_coach;
  end if;
  if to_regprocedure('private.w074_prepare_payment_evidence_attempt(uuid,text)') is null and to_regprocedure('public.w074_prepare_payment_evidence_attempt(uuid,text)') is null then
    alter function public.prepare_payment_evidence_attempt(uuid,text) rename to w074_prepare_payment_evidence_attempt;
  end if;
  if to_regprocedure('private.w074_save_my_coach_application_draft(text,boolean,boolean,text,text)') is null and to_regprocedure('public.w074_save_my_coach_application_draft(text,boolean,boolean,text,text)') is null then
    alter function public.save_my_coach_application_draft(text,boolean,boolean,text,text) rename to w074_save_my_coach_application_draft;
  end if;
  if to_regprocedure('private.w074_submit_my_coach_application(uuid,text)') is null and to_regprocedure('public.w074_submit_my_coach_application(uuid,text)') is null then
    alter function public.submit_my_coach_application(uuid,text) rename to w074_submit_my_coach_application;
  end if;
  if to_regprocedure('private.w074_create_coach_payment_order(uuid,text)') is null and to_regprocedure('public.w074_create_coach_payment_order(uuid,text)') is null then
    alter function public.create_coach_payment_order(uuid,text) rename to w074_create_coach_payment_order;
  end if;
  if to_regprocedure('private.w074_apply_provider_profile_defaults(text,text)') is null and to_regprocedure('public.w074_apply_provider_profile_defaults(text,text)') is null then
    alter function public.apply_provider_profile_defaults(text,text) rename to w074_apply_provider_profile_defaults;
  end if;
  if to_regprocedure('private.w074_prepare_my_account_deletion()') is null and to_regprocedure('public.w074_prepare_my_account_deletion()') is null then alter function public.prepare_my_account_deletion() rename to w074_prepare_my_account_deletion; end if;
  if to_regprocedure('private.w074_finalize_my_account_deletion()') is null and to_regprocedure('public.w074_finalize_my_account_deletion()') is null then alter function public.finalize_my_account_deletion() rename to w074_finalize_my_account_deletion; end if;
  if to_regprocedure('private.w074_resolve_coach_qr_for_enrollment(text)') is null and to_regprocedure('public.w074_resolve_coach_qr_for_enrollment(text)') is null then alter function public.resolve_coach_qr_for_enrollment(text) rename to w074_resolve_coach_qr_for_enrollment; end if;
  if to_regprocedure('private.w074_cancel_payment_order(uuid)') is null and to_regprocedure('public.w074_cancel_payment_order(uuid)') is null then alter function public.cancel_payment_order(uuid) rename to w074_cancel_payment_order; end if;
end;
$$;

do $$
begin
  if to_regprocedure('public.w074_active_update_my_profile(text,text,text,text)') is not null then alter function public.w074_active_update_my_profile(text,text,text,text) set schema private; end if;
  if to_regprocedure('public.w074_active_pending_program_enrollment_availability(uuid)') is not null then alter function public.w074_active_pending_program_enrollment_availability(uuid) set schema private; end if;
  if to_regprocedure('public.w074_active_enroll_free_program(uuid,text)') is not null then alter function public.w074_active_enroll_free_program(uuid,text) set schema private; end if;
  if to_regprocedure('public.w074_active_create_program_payment_order(uuid,text,text,text)') is not null then alter function public.w074_active_create_program_payment_order(uuid,text,text,text) set schema private; end if;
  if to_regprocedure('public.w074_active_prepare_step_submission(uuid,uuid,text)') is not null then alter function public.w074_active_prepare_step_submission(uuid,uuid,text) set schema private; end if;
  if to_regprocedure('public.w074_active_submit_step_answers(uuid,jsonb,text)') is not null then alter function public.w074_active_submit_step_answers(uuid,jsonb,text) set schema private; end if;
  if to_regprocedure('public.w074_active_submit_weigh_in(uuid,uuid,text,numeric,text)') is not null then alter function public.w074_active_submit_weigh_in(uuid,uuid,text,numeric,text) set schema private; end if;
  if to_regprocedure('public.w074_active_get_my_dashboard_summary()') is not null then alter function public.w074_active_get_my_dashboard_summary() set schema private; end if;
  if to_regprocedure('public.w074_active_get_my_assigned_coach()') is not null then alter function public.w074_active_get_my_assigned_coach() set schema private; end if;
  if to_regprocedure('public.w074_prepare_payment_evidence_attempt(uuid,text)') is not null then alter function public.w074_prepare_payment_evidence_attempt(uuid,text) set schema private; end if;
  if to_regprocedure('public.w074_save_my_coach_application_draft(text,boolean,boolean,text,text)') is not null then alter function public.w074_save_my_coach_application_draft(text,boolean,boolean,text,text) set schema private; end if;
  if to_regprocedure('public.w074_submit_my_coach_application(uuid,text)') is not null then alter function public.w074_submit_my_coach_application(uuid,text) set schema private; end if;
  if to_regprocedure('public.w074_create_coach_payment_order(uuid,text)') is not null then alter function public.w074_create_coach_payment_order(uuid,text) set schema private; end if;
  if to_regprocedure('public.w074_apply_provider_profile_defaults(text,text)') is not null then alter function public.w074_apply_provider_profile_defaults(text,text) set schema private; end if;
  if to_regprocedure('public.w074_prepare_my_account_deletion()') is not null then alter function public.w074_prepare_my_account_deletion() set schema private; end if;
  if to_regprocedure('public.w074_finalize_my_account_deletion()') is not null then alter function public.w074_finalize_my_account_deletion() set schema private; end if;
  if to_regprocedure('public.w074_resolve_coach_qr_for_enrollment(text)') is not null then alter function public.w074_resolve_coach_qr_for_enrollment(text) set schema private; end if;
  if to_regprocedure('public.w074_cancel_payment_order(uuid)') is not null then alter function public.w074_cancel_payment_order(uuid) set schema private; end if;
end;
$$;

create or replace function public.update_my_profile(
  new_display_name text,
  new_phone_number text,
  new_member_level text,
  new_account_purpose text default 'participant'
)
returns public.profiles
language plpgsql security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return private.w074_active_update_my_profile(
    new_display_name, new_phone_number, new_member_level, new_account_purpose
  );
end; $$;

create or replace function public.apply_provider_profile_defaults(
  provider_display_name text default null,
  provider_avatar_url text default null
)
returns public.profiles
language plpgsql security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.profiles profile
    where profile.user_id = (select auth.uid())
      and profile.onboarding_status = 'provisional'
  ) then raise exception 'provisional_profile_not_editable'; end if;
  return private.w074_apply_provider_profile_defaults(provider_display_name, provider_avatar_url);
end;
$$;

create or replace function public.prepare_my_account_deletion()
returns jsonb
language plpgsql security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return private.w074_prepare_my_account_deletion();
end; $$;

create or replace function public.finalize_my_account_deletion()
returns uuid
language plpgsql security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return private.w074_finalize_my_account_deletion();
end; $$;

create or replace function public.resolve_coach_qr_for_enrollment(scanned_coach_qr text)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return private.w074_resolve_coach_qr_for_enrollment(scanned_coach_qr);
end; $$;

create or replace function public.cancel_payment_order(target_order_id uuid)
returns public.payment_orders
language plpgsql security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return private.w074_cancel_payment_order(target_order_id);
end; $$;

create or replace function public.pending_program_enrollment_availability(target_program_id uuid)
returns text
language plpgsql security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return private.w074_active_pending_program_enrollment_availability(target_program_id);
end; $$;

create or replace function public.enroll_free_program(target_program_id uuid, scanned_coach_qr text)
returns public.program_enrollments
language plpgsql security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return private.w074_active_enroll_free_program(target_program_id, scanned_coach_qr);
end; $$;

create or replace function public.create_program_payment_order(
  target_program_id uuid,
  coach_qr_payload text,
  payment_method text,
  request_idempotency_key text
)
returns public.payment_orders
language plpgsql security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return private.w074_active_create_program_payment_order(
    target_program_id, coach_qr_payload, payment_method, request_idempotency_key
  );
end; $$;

create or replace function public.prepare_step_submission(
  target_enrollment_id uuid,
  target_step_id uuid,
  request_idempotency_key text
)
returns public.step_submissions
language plpgsql security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return private.w074_active_prepare_step_submission(
    target_enrollment_id, target_step_id, request_idempotency_key
  );
end; $$;

create or replace function public.submit_step_answers(
  target_submission_id uuid,
  submitted_answers jsonb,
  request_idempotency_key text
)
returns public.step_submissions
language plpgsql security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return private.w074_active_submit_step_answers(
    target_submission_id, submitted_answers, request_idempotency_key
  );
end; $$;

create or replace function public.submit_weigh_in(
  target_enrollment_id uuid,
  target_step_id uuid,
  weigh_in_kind text,
  weight_kg numeric,
  request_idempotency_key text
)
returns public.weigh_ins
language plpgsql security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return private.w074_active_submit_weigh_in(
    target_enrollment_id, target_step_id, weigh_in_kind, weight_kg, request_idempotency_key
  );
end; $$;

create or replace function public.get_my_dashboard_summary()
returns table(
  account_role text,
  active_enrollment_count integer,
  completed_enrollment_count integer,
  pending_submission_count integer,
  assigned_participant_count integer
)
language plpgsql stable security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return query select * from private.w074_active_get_my_dashboard_summary();
end; $$;

create or replace function public.get_my_assigned_coach()
returns table(
  user_id uuid,
  public_profile_id uuid,
  display_name text,
  city text,
  provider_avatar_url text,
  is_public boolean,
  is_approved boolean
)
language plpgsql stable security definer
set search_path = ''
as $$ begin
  perform private.assert_active_account();
  return query select * from private.w074_active_get_my_assigned_coach();
end; $$;

create or replace function public.prepare_payment_evidence_attempt(
  target_order_id uuid,
  request_idempotency_key text
)
returns public.payment_evidence_attempts
language plpgsql security definer
set search_path = ''
as $$
declare profile public.profiles; target_order public.payment_orders; application public.coach_applications;
begin
  select * into profile from public.profiles where user_id = (select auth.uid());
  select * into target_order from public.payment_orders
    where id = target_order_id and owner_user_id = (select auth.uid());
  if profile.user_id is null or target_order.id is null then raise exception 'permission_denied'; end if;
  if profile.onboarding_status <> 'active' and not (
    profile.onboarding_status = 'coach_handoff_pending'
    and profile.account_purpose = 'coach_applicant'
    and target_order.purpose = 'coach_access'
  ) then raise exception 'active_account_required'; end if;
  if profile.onboarding_status = 'coach_handoff_pending' then
    select * into application from public.coach_applications
    where id = target_order.coach_application_id and applicant_user_id = profile.user_id;
    if application.id is null or application.member_level_snapshot is distinct from profile.member_level then
      raise exception 'member_level_mismatch';
    end if;
  end if;
  return private.w074_prepare_payment_evidence_attempt(target_order_id, request_idempotency_key);
end;
$$;

create or replace function public.save_my_coach_application_draft(
  member_level text,
  applicant_has_completed_hom_sts boolean,
  applicant_has_completed_ict boolean,
  accepted_terms_version text,
  request_idempotency_key text
)
returns public.coach_applications
language plpgsql security definer
set search_path = ''
as $$
declare profile public.profiles;
begin
  select * into profile from public.profiles where user_id = (select auth.uid());
  if profile.user_id is null or profile.role <> 'participant' then raise exception 'permission_denied'; end if;
  if profile.onboarding_status = 'coach_handoff_pending' then
    if profile.account_purpose <> 'coach_applicant'
      or profile.provisional_expires_at <= statement_timestamp()
      or profile.member_level is distinct from member_level then
      raise exception 'coach_handoff_incomplete';
    end if;
  elsif profile.onboarding_status <> 'active' then
    raise exception 'active_account_required';
  end if;
  return private.w074_save_my_coach_application_draft(
    member_level, applicant_has_completed_hom_sts, applicant_has_completed_ict,
    accepted_terms_version, request_idempotency_key
  );
end;
$$;

create or replace function public.submit_my_coach_application(
  target_application_id uuid,
  request_idempotency_key text
)
returns public.coach_applications
language plpgsql security definer
set search_path = ''
as $$
declare profile public.profiles;
declare application public.coach_applications;
begin
  select * into profile from public.profiles where user_id = (select auth.uid());
  if profile.user_id is null or profile.role <> 'participant'
    or profile.onboarding_status not in ('active', 'coach_handoff_pending') then
    raise exception 'permission_denied';
  end if;
  if profile.onboarding_status = 'coach_handoff_pending'
    and (profile.account_purpose <> 'coach_applicant'
      or profile.provisional_expires_at <= statement_timestamp()) then
    raise exception 'coach_handoff_incomplete';
  end if;
  if profile.onboarding_status = 'coach_handoff_pending' then
    select * into application from public.coach_applications
    where id = target_application_id and applicant_user_id = profile.user_id;
    if application.id is null or application.member_level_snapshot is distinct from profile.member_level then
      raise exception 'member_level_mismatch';
    end if;
  end if;
  return private.w074_submit_my_coach_application(target_application_id, request_idempotency_key);
end;
$$;

create or replace function public.create_coach_payment_order(
  target_application_id uuid,
  request_idempotency_key text
)
returns public.payment_orders
language plpgsql security definer
set search_path = ''
as $$
declare profile public.profiles;
declare application public.coach_applications;
begin
  select * into profile from public.profiles where user_id = (select auth.uid());
  if profile.user_id is null or profile.role <> 'participant'
    or profile.onboarding_status not in ('active', 'coach_handoff_pending') then
    raise exception 'permission_denied';
  end if;
  if profile.onboarding_status = 'coach_handoff_pending'
    and (profile.account_purpose <> 'coach_applicant'
      or profile.provisional_expires_at <= statement_timestamp()) then
    raise exception 'coach_handoff_incomplete';
  end if;
  if profile.onboarding_status = 'coach_handoff_pending' then
    select * into application from public.coach_applications
    where id = target_application_id and applicant_user_id = profile.user_id;
    if application.id is null or application.member_level_snapshot is distinct from profile.member_level then
      raise exception 'member_level_mismatch';
    end if;
  end if;
  return private.w074_create_coach_payment_order(target_application_id, request_idempotency_key);
end;
$$;

create or replace function public.request_my_provisional_cancellation(
  request_idempotency_key text
)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  profile public.profiles;
  receipt private.provisional_cancellation_receipts;
  paths text[] := array[]::text[];
  durable_history boolean;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if caller_id is null then raise exception 'authentication_required'; end if;
  select * into profile from public.profiles where user_id = caller_id for update;
  if profile.user_id is null then return jsonb_build_object('status', 'completed'); end if;
  if profile.onboarding_status = 'active' then return jsonb_build_object('status', 'retained'); end if;

  select private.provisional_identity_has_relationships(caller_id) or exists (
    select 1 from public.payment_orders payment_order
    where payment_order.owner_user_id = caller_id
      and payment_order.status not in ('awaiting_evidence', 'cancelled', 'expired')
  ) or exists (
    select 1 from public.payment_ledger ledger
    join public.payment_orders payment_order on payment_order.id = ledger.order_id
    where payment_order.owner_user_id = caller_id
  ) into durable_history;

  if durable_history then
    update public.profiles set
      onboarding_status = 'active', provisional_expires_at = null,
      finalized_at = coalesce(finalized_at, statement_timestamp()),
      onboarding_version = onboarding_version + 1,
      updated_at = statement_timestamp()
    where user_id = caller_id;
    return jsonb_build_object('status', 'retained');
  end if;

  select * into receipt from private.provisional_cancellation_receipts
  where user_id = caller_id and idempotency_key = request_idempotency_key;
  if receipt.id is not null then
    return jsonb_build_object('id', receipt.id, 'status', receipt.status);
  end if;
  select * into receipt from private.provisional_cancellation_receipts
  where user_id = caller_id and status in ('queued', 'processing', 'failed')
  order by requested_at desc limit 1;
  if receipt.id is not null then
    return jsonb_build_object('id', receipt.id, 'status', receipt.status);
  end if;

  select coalesce(array_agg(attempt.object_path), array[]::text[]) into paths
  from public.payment_evidence_attempts attempt
  join public.payment_orders payment_order on payment_order.id = attempt.order_id
  where payment_order.owner_user_id = caller_id and attempt.status = 'prepared';

  insert into private.provisional_cancellation_receipts(
    user_id, idempotency_key, source, status, object_paths
  ) values (caller_id, request_idempotency_key, 'user', 'queued', paths)
  returning * into receipt;

  update public.payment_evidence_attempts set status = 'deleted', deleted_at = statement_timestamp()
  where status = 'prepared' and order_id in (
    select id from public.payment_orders
    where owner_user_id = caller_id and status in ('awaiting_evidence', 'cancelled', 'expired')
  );
  update public.payment_orders set status = 'cancelled', version = version + 1,
    updated_at = statement_timestamp()
  where owner_user_id = caller_id and status in ('awaiting_evidence', 'expired');
  delete from public.coach_applications
    where applicant_user_id = caller_id and status in ('draft', 'ineligible', 'submitted');
  update public.profiles set onboarding_status = 'cleanup_pending', updated_at = statement_timestamp()
  where user_id = caller_id;
  return jsonb_build_object('id', receipt.id, 'status', receipt.status);
end;
$$;

drop function if exists public.claim_provisional_cancellation();
create or replace function public.claim_provisional_cancellation(
  target_receipt_id uuid default null
)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare receipt private.provisional_cancellation_receipts;
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role' then
    raise exception 'permission_denied';
  end if;
  select * into receipt from private.provisional_cancellation_receipts
  where status in ('queued', 'failed', 'processing')
    and (status <> 'processing' or lease_expires_at <= statement_timestamp())
    and (target_receipt_id is null or id = target_receipt_id)
  order by requested_at for update skip locked limit 1;
  if receipt.id is null then return null; end if;
  update private.provisional_cancellation_receipts set
    status = 'processing', attempt_count = attempt_count + 1,
    lease_expires_at = statement_timestamp() + interval '5 minutes', last_error_code = null
  where id = receipt.id returning * into receipt;
  return jsonb_build_object('id', receipt.id, 'user_id', receipt.user_id,
    'object_paths', receipt.object_paths, 'attempt_count', receipt.attempt_count);
end;
$$;

create or replace function public.complete_provisional_cancellation(target_receipt_id uuid)
returns boolean
language plpgsql security definer
set search_path = ''
as $$
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role' then
    raise exception 'permission_denied';
  end if;
  update private.provisional_cancellation_receipts set
    status = 'completed', completed_at = coalesce(completed_at, statement_timestamp()),
    lease_expires_at = null, last_error_code = null
  where id = target_receipt_id and status in ('processing', 'completed');
  return found;
end;
$$;

create or replace function public.revoke_provisional_cancellation_sessions(
  target_receipt_id uuid
)
returns boolean
language plpgsql security definer
set search_path = ''
as $$
declare target_user_id uuid;
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role' then
    raise exception 'permission_denied';
  end if;
  select user_id into target_user_id
  from private.provisional_cancellation_receipts
  where id = target_receipt_id and status = 'processing';
  if target_user_id is null then return false; end if;
  delete from auth.sessions where user_id = target_user_id;
  return true;
end;
$$;

create or replace function public.fail_provisional_cancellation(
  target_receipt_id uuid,
  failure_code text
)
returns boolean
language plpgsql security definer
set search_path = ''
as $$
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role' then
    raise exception 'permission_denied';
  end if;
  update private.provisional_cancellation_receipts set
    status = 'failed', lease_expires_at = null,
    last_error_code = left(regexp_replace(coalesce(failure_code, 'unknown'), '[^a-z0-9_]', '', 'g'), 80)
  where id = target_receipt_id and status = 'processing';
  return found;
end;
$$;

create or replace function private.cleanup_expired_provisional_identities()
returns integer
language plpgsql security definer
set search_path = ''
as $$
declare enqueued integer := 0;
declare candidate record;
declare paths text[];
begin
  for candidate in
    select profile.user_id
    from public.profiles profile
    where profile.onboarding_status in ('provisional', 'coach_handoff_pending', 'cleanup_pending')
      and profile.provisional_expires_at <= statement_timestamp()
    for update skip locked
  loop
    if exists (
      select 1 from public.payment_orders payment_order
      where payment_order.owner_user_id = candidate.user_id
        and payment_order.status not in ('awaiting_evidence', 'cancelled', 'expired')
    ) or exists (
      select 1 from public.payment_ledger ledger
      join public.payment_orders payment_order on payment_order.id = ledger.order_id
      where payment_order.owner_user_id = candidate.user_id
    ) then
      update public.profiles set onboarding_status = 'active', provisional_expires_at = null,
        finalized_at = coalesce(finalized_at, statement_timestamp()),
        onboarding_version = onboarding_version + 1, updated_at = statement_timestamp()
      where user_id = candidate.user_id;
      continue;
    end if;
    if private.provisional_identity_has_relationships(candidate.user_id) then
      insert into private.provisional_cancellation_receipts(
        user_id, idempotency_key, source, status, object_paths,
        last_error_code, completed_at
      ) values (
        candidate.user_id, 'expiry-' || candidate.user_id::text,
        'expiry', 'retained', array[]::text[],
        'relationships_present', statement_timestamp()
      ) on conflict (user_id, idempotency_key) do update set
        status = 'retained', last_error_code = 'relationships_present',
        completed_at = coalesce(private.provisional_cancellation_receipts.completed_at, statement_timestamp());
      update public.profiles set
        onboarding_status = 'active', provisional_expires_at = null,
        finalized_at = coalesce(finalized_at, statement_timestamp()),
        onboarding_version = onboarding_version + 1,
        updated_at = statement_timestamp()
      where user_id = candidate.user_id;
      continue;
    end if;
    select coalesce(array_agg(attempt.object_path), array[]::text[]) into paths
    from public.payment_evidence_attempts attempt
    join public.payment_orders payment_order on payment_order.id = attempt.order_id
    where payment_order.owner_user_id = candidate.user_id and attempt.status = 'prepared';
    insert into private.provisional_cancellation_receipts(
      user_id, idempotency_key, source, status, object_paths
    ) values (
      candidate.user_id, 'expiry-' || candidate.user_id::text,
      'expiry', 'queued', paths
    ) on conflict (user_id, idempotency_key) do nothing;
    if found then enqueued := enqueued + 1; end if;
    update public.payment_evidence_attempts set status = 'deleted', deleted_at = statement_timestamp()
    where status = 'prepared' and order_id in (
      select id from public.payment_orders
      where owner_user_id = candidate.user_id
        and status in ('awaiting_evidence', 'cancelled', 'expired')
    );
    update public.payment_orders set status = 'cancelled', version = version + 1,
      updated_at = statement_timestamp()
    where owner_user_id = candidate.user_id and status in ('awaiting_evidence', 'expired');
    delete from public.coach_applications
      where applicant_user_id = candidate.user_id
        and status in ('draft', 'ineligible', 'submitted');
    update public.profiles set onboarding_status = 'cleanup_pending', updated_at = statement_timestamp()
    where user_id = candidate.user_id;
  end loop;
  return enqueued;
end;
$$;

create or replace function public.enqueue_expired_provisional_cancellations()
returns integer
language plpgsql security definer
set search_path = ''
as $$
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role' then
    raise exception 'permission_denied';
  end if;
  return private.cleanup_expired_provisional_identities();
end;
$$;

revoke all on function private.onboarding_profile_is_complete(public.profiles) from public, anon, authenticated;
revoke all on function private.assert_active_account() from public, anon, authenticated;
revoke all on function private.current_account_is_active() from public, anon, authenticated;
revoke all on function private.can_access_payment_order(uuid) from public, anon, authenticated;
revoke all on function private.can_coach_participant(uuid) from public, anon, authenticated;
revoke all on function private.active_coach_for_onboarding(text, uuid) from public, anon, authenticated;
revoke all on function private.submit_payment_evidence_core(uuid,text,integer,integer,integer,boolean) from public, anon, authenticated;

revoke all on function public.get_my_session_context() from public, anon, authenticated;
revoke all on function public.get_my_provisional_onboarding_profile() from public, anon, authenticated;
revoke all on function public.save_my_provisional_onboarding_profile(text,text,text,text,integer) from public, anon, authenticated;
revoke all on function public.validate_participant_onboarding_coach_qr(text) from public, anon, authenticated;
revoke all on function public.finalize_participant_onboarding(text,integer) from public, anon, authenticated;
revoke all on function public.prepare_coach_application_handoff(integer) from public, anon, authenticated;
revoke all on function public.submit_coach_onboarding_payment_evidence(uuid,text,integer,integer,integer) from public, anon, authenticated;
revoke all on function public.request_coach_payment_correction(uuid,integer,text,text) from public, anon, authenticated;
revoke all on function public.request_my_provisional_cancellation(text) from public, anon, authenticated;
revoke all on function public.claim_provisional_cancellation(uuid) from public, anon, authenticated;
revoke all on function public.complete_provisional_cancellation(uuid) from public, anon, authenticated;
revoke all on function public.revoke_provisional_cancellation_sessions(uuid) from public, anon, authenticated;
revoke all on function public.fail_provisional_cancellation(uuid,text) from public, anon, authenticated;
revoke all on function public.enqueue_expired_provisional_cancellations() from public, anon, authenticated;

revoke all on function private.w074_active_update_my_profile(text,text,text,text) from public, anon, authenticated;
revoke all on function private.w074_active_pending_program_enrollment_availability(uuid) from public, anon, authenticated;
revoke all on function private.w074_active_enroll_free_program(uuid,text) from public, anon, authenticated;
revoke all on function private.w074_active_create_program_payment_order(uuid,text,text,text) from public, anon, authenticated;
revoke all on function private.w074_active_prepare_step_submission(uuid,uuid,text) from public, anon, authenticated;
revoke all on function private.w074_active_submit_step_answers(uuid,jsonb,text) from public, anon, authenticated;
revoke all on function private.w074_active_submit_weigh_in(uuid,uuid,text,numeric,text) from public, anon, authenticated;
revoke all on function private.w074_active_get_my_dashboard_summary() from public, anon, authenticated;
revoke all on function private.w074_active_get_my_assigned_coach() from public, anon, authenticated;
revoke all on function private.w074_prepare_payment_evidence_attempt(uuid,text) from public, anon, authenticated;
revoke all on function private.w074_save_my_coach_application_draft(text,boolean,boolean,text,text) from public, anon, authenticated;
revoke all on function private.w074_submit_my_coach_application(uuid,text) from public, anon, authenticated;
revoke all on function private.w074_create_coach_payment_order(uuid,text) from public, anon, authenticated;
revoke all on function private.w074_apply_provider_profile_defaults(text,text) from public, anon, authenticated;
revoke all on function private.w074_prepare_my_account_deletion() from public, anon, authenticated;
revoke all on function private.w074_finalize_my_account_deletion() from public, anon, authenticated;
revoke all on function private.w074_resolve_coach_qr_for_enrollment(text) from public, anon, authenticated;
revoke all on function private.w074_cancel_payment_order(uuid) from public, anon, authenticated;

revoke all on function public.update_my_profile(text,text,text,text) from public, anon, authenticated;
revoke all on function public.apply_provider_profile_defaults(text,text) from public, anon, authenticated;
revoke all on function public.prepare_my_account_deletion() from public, anon, authenticated;
revoke all on function public.finalize_my_account_deletion() from public, anon, authenticated;
revoke all on function public.resolve_coach_qr_for_enrollment(text) from public, anon, authenticated;
revoke all on function public.cancel_payment_order(uuid) from public, anon, authenticated;
revoke all on function public.pending_program_enrollment_availability(uuid) from public, anon, authenticated;
revoke all on function public.enroll_free_program(uuid,text) from public, anon, authenticated;
revoke all on function public.create_program_payment_order(uuid,text,text,text) from public, anon, authenticated;
revoke all on function public.prepare_step_submission(uuid,uuid,text) from public, anon, authenticated;
revoke all on function public.submit_step_answers(uuid,jsonb,text) from public, anon, authenticated;
revoke all on function public.submit_weigh_in(uuid,uuid,text,numeric,text) from public, anon, authenticated;
revoke all on function public.get_my_dashboard_summary() from public, anon, authenticated;
revoke all on function public.get_my_assigned_coach() from public, anon, authenticated;
revoke all on function public.prepare_payment_evidence_attempt(uuid,text) from public, anon, authenticated;
revoke all on function public.save_my_coach_application_draft(text,boolean,boolean,text,text) from public, anon, authenticated;
revoke all on function public.submit_my_coach_application(uuid,text) from public, anon, authenticated;
revoke all on function public.create_coach_payment_order(uuid,text) from public, anon, authenticated;

grant execute on function public.get_my_session_context() to authenticated;
grant execute on function public.get_my_provisional_onboarding_profile() to authenticated;
grant execute on function public.save_my_provisional_onboarding_profile(text,text,text,text,integer) to authenticated;
grant execute on function public.validate_participant_onboarding_coach_qr(text) to authenticated;
grant execute on function public.finalize_participant_onboarding(text,integer) to authenticated;
grant execute on function public.prepare_coach_application_handoff(integer) to authenticated;
grant execute on function public.submit_coach_onboarding_payment_evidence(uuid,text,integer,integer,integer) to authenticated;
grant execute on function public.request_coach_payment_correction(uuid,integer,text,text) to authenticated;
grant execute on function public.request_my_provisional_cancellation(text) to authenticated;
grant execute on function public.claim_provisional_cancellation(uuid) to service_role;
grant execute on function public.complete_provisional_cancellation(uuid) to service_role;
grant execute on function public.revoke_provisional_cancellation_sessions(uuid) to service_role;
grant execute on function public.fail_provisional_cancellation(uuid,text) to service_role;
grant execute on function public.enqueue_expired_provisional_cancellations() to service_role;

grant execute on function public.update_my_profile(text,text,text,text) to authenticated;
grant execute on function public.pending_program_enrollment_availability(uuid) to authenticated;
grant execute on function public.enroll_free_program(uuid,text) to authenticated;
grant execute on function public.create_program_payment_order(uuid,text,text,text) to authenticated;
grant execute on function public.prepare_step_submission(uuid,uuid,text) to authenticated;
grant execute on function public.submit_step_answers(uuid,jsonb,text) to authenticated;
grant execute on function public.submit_weigh_in(uuid,uuid,text,numeric,text) to authenticated;
grant execute on function public.get_my_dashboard_summary() to authenticated;
grant execute on function public.get_my_assigned_coach() to authenticated;
grant execute on function public.prepare_payment_evidence_attempt(uuid,text) to authenticated;
grant execute on function public.save_my_coach_application_draft(text,boolean,boolean,text,text) to authenticated;
grant execute on function public.submit_my_coach_application(uuid,text) to authenticated;
grant execute on function public.create_coach_payment_order(uuid,text) to authenticated;
grant execute on function public.apply_provider_profile_defaults(text,text) to authenticated;
grant execute on function public.prepare_my_account_deletion() to authenticated;
grant execute on function public.finalize_my_account_deletion() to authenticated;
grant execute on function public.resolve_coach_qr_for_enrollment(text) to authenticated;
grant execute on function public.cancel_payment_order(uuid) to authenticated;
grant execute on function private.can_coach_participant(uuid) to authenticated;
grant execute on function private.current_account_is_active() to authenticated;
grant execute on function private.can_access_payment_order(uuid) to authenticated;

-- The direct single-call deletion path is intentionally removed. All explicit
-- and expiry cleanup now converges through the durable receipt worker.
revoke execute on function public.cancel_my_provisional_identity() from authenticated;

-- Remove unsourced local drift so generated types cannot claim APIs that have
-- no committed migration authority in MSCWEB or the shared baseline.
drop function if exists public.get_my_participant_profile_context();
drop function if exists public.change_my_coach_from_qr(text,text);
drop function if exists public.update_my_profile_avatar(text,text);
drop function if exists public.register_my_web_push_subscription(text,text,text,text);
drop function if exists public.revoke_my_web_push_subscription(text);

notify pgrst, 'reload schema';
