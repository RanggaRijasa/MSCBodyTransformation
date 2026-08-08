-- Phase 11.3: authoritative Coach application aggregate and protected role
-- transition. Payment verification and entitlement issuance remain trusted
-- server inputs owned by Phase 12; mobile clients can only read their state.

create table public.coach_applications (
  id uuid primary key default gen_random_uuid(),
  applicant_user_id uuid not null references public.profiles(user_id),
  participant_profile_id uuid not null references public.profiles(user_id),
  display_name_snapshot text not null,
  phone_number_snapshot text not null,
  member_level_snapshot text not null check (
    member_level_snapshot in (
      'member', 'sc', 'sb', 'supervisor', 'world_team', 'tab_team',
      'get_team', 'millionaire_team', 'presidents_team'
    )
  ),
  has_completed_hom_sts boolean not null,
  has_completed_ict boolean not null,
  terms_version text not null check (length(trim(terms_version)) > 0),
  status text not null check (
    status in (
      'draft', 'ineligible', 'ready_for_payment', 'payment_processing',
      'payment_verified', 'pending_admin_approval', 'approved',
      'rejected', 'expired'
    )
  ),
  draft_idempotency_key text not null,
  submit_idempotency_key text,
  decision_idempotency_key text,
  submitted_at timestamptz,
  decided_at timestamptz,
  decided_by uuid references public.profiles(user_id),
  rejection_reason text,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  unique (applicant_user_id, draft_idempotency_key),
  constraint coach_application_profile_identity check (
    applicant_user_id = participant_profile_id
  ),
  constraint coach_application_terminal_shape check (
    (status = 'approved' and decided_at is not null and decided_by is not null
      and rejection_reason is null)
    or (status = 'rejected' and decided_at is not null and decided_by is not null
      and length(trim(rejection_reason)) > 0)
    or (status not in ('approved', 'rejected') and decided_at is null
      and decided_by is null and rejection_reason is null)
  )
);

create unique index coach_applications_one_active_per_user_idx
  on public.coach_applications(applicant_user_id)
  where status in (
    'draft', 'ineligible', 'ready_for_payment', 'payment_processing',
    'payment_verified', 'pending_admin_approval'
  );

create index coach_applications_admin_queue_idx
  on public.coach_applications(status, submitted_at, created_at);
create index coach_applications_decided_by_idx
  on public.coach_applications(decided_by);

create table public.coach_payment_records (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null unique
    references public.coach_applications(id) on delete restrict,
  state text not null check (
    state in (
      'not_started', 'processing', 'pending', 'verified', 'cancelled',
      'failed', 'interrupted'
    )
  ),
  price_band text not null check (price_band in ('entry', 'growth', 'leadership')),
  amount_minor_units bigint not null check (amount_minor_units > 0),
  duration_months integer not null default 3 check (duration_months = 3),
  provider_reference text,
  verified_at timestamptz,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint coach_payment_verified_shape check (
    (state = 'verified' and verified_at is not null and provider_reference is not null)
    or state <> 'verified'
  )
);

create table public.coach_access_entitlements (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null unique
    references public.coach_applications(id) on delete restrict,
  payment_record_id uuid not null unique
    references public.coach_payment_records(id) on delete restrict,
  coach_user_id uuid not null references public.profiles(user_id),
  status text not null check (status in ('active', 'expired', 'revoked')),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_at timestamptz not null default statement_timestamp(),
  revoked_at timestamptz,
  check (ends_at > starts_at),
  check ((status = 'revoked' and revoked_at is not null) or status <> 'revoked')
);

create index coach_access_entitlements_active_idx
  on public.coach_access_entitlements(coach_user_id, status, starts_at, ends_at);

alter table public.coach_applications enable row level security;
alter table public.coach_payment_records enable row level security;
alter table public.coach_access_entitlements enable row level security;

revoke all privileges on table
  public.coach_applications,
  public.coach_payment_records,
  public.coach_access_entitlements
from anon, authenticated;

grant select on table
  public.coach_applications,
  public.coach_payment_records,
  public.coach_access_entitlements
to authenticated;

grant all privileges on table
  public.coach_applications,
  public.coach_payment_records,
  public.coach_access_entitlements
to service_role;

create policy "applicant or admin reads Coach applications"
on public.coach_applications for select to authenticated
using (
  applicant_user_id = (select auth.uid())
  or private.is_admin()
);

create policy "applicant or admin reads Coach payment state"
on public.coach_payment_records for select to authenticated
using (
  private.is_admin()
  or exists (
    select 1
    from public.coach_applications application
    where application.id = application_id
      and application.applicant_user_id = (select auth.uid())
  )
);

create policy "Coach or admin reads Coach entitlement"
on public.coach_access_entitlements for select to authenticated
using (
  coach_user_id = (select auth.uid())
  or private.is_admin()
);

create or replace function private.has_active_coach_access(
  target_coach_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles profile
    join public.coach_access_entitlements entitlement
      on entitlement.coach_user_id = profile.user_id
    where profile.user_id = target_coach_user_id
      and profile.role = 'coach'
      and profile.coach_is_approved
      and entitlement.status = 'active'
      and entitlement.starts_at <= statement_timestamp()
      and entitlement.ends_at > statement_timestamp()
  );
$$;

create or replace function public.save_my_coach_application_draft(
  member_level text,
  applicant_has_completed_hom_sts boolean,
  applicant_has_completed_ict boolean,
  accepted_terms_version text,
  request_idempotency_key text
)
returns public.coach_applications
language plpgsql
security definer
set search_path = ''
as $$
declare
  applicant public.profiles;
  existing public.coach_applications;
  result public.coach_applications;
  computed_status text;
begin
  perform private.assert_idempotency_key(request_idempotency_key);

  if member_level not in (
    'member', 'sc', 'sb', 'supervisor', 'world_team', 'tab_team',
    'get_team', 'millionaire_team', 'presidents_team'
  ) then
    raise exception 'member_level_invalid';
  end if;
  if length(trim(coalesce(accepted_terms_version, ''))) = 0 then
    raise exception 'terms_version_required';
  end if;

  select * into applicant
  from public.profiles
  where user_id = (select auth.uid())
    and role = 'participant'
  for update;

  if applicant.user_id is null then
    raise exception 'permission_denied';
  end if;
  if length(trim(coalesce(applicant.phone_number, ''))) = 0 then
    raise exception 'profile_incomplete';
  end if;

  select * into existing
  from public.coach_applications
  where applicant_user_id = applicant.user_id
    and draft_idempotency_key = request_idempotency_key
  for update;

  if existing.id is not null then
    return existing;
  end if;

  select * into existing
  from public.coach_applications
  where applicant_user_id = applicant.user_id
    and status in (
      'draft', 'ineligible', 'ready_for_payment', 'payment_processing',
      'payment_verified', 'pending_admin_approval'
    )
  for update;

  computed_status := case
    when member_level = 'member'
      or not applicant_has_completed_hom_sts
      or not applicant_has_completed_ict
    then 'ineligible'
    else 'ready_for_payment'
  end;

  if existing.id is not null then
    if existing.status not in ('draft', 'ineligible', 'ready_for_payment') then
      raise exception 'application_locked';
    end if;
    update public.coach_applications
    set
      display_name_snapshot = applicant.display_name,
      phone_number_snapshot = applicant.phone_number,
      member_level_snapshot = member_level,
      has_completed_hom_sts = applicant_has_completed_hom_sts,
      has_completed_ict = applicant_has_completed_ict,
      terms_version = trim(accepted_terms_version),
      status = computed_status,
      draft_idempotency_key = request_idempotency_key,
      updated_at = statement_timestamp()
    where id = existing.id
    returning * into result;
  else
    insert into public.coach_applications (
      applicant_user_id,
      participant_profile_id,
      display_name_snapshot,
      phone_number_snapshot,
      member_level_snapshot,
      has_completed_hom_sts,
      has_completed_ict,
      terms_version,
      status,
      draft_idempotency_key
    ) values (
      applicant.user_id,
      applicant.user_id,
      applicant.display_name,
      applicant.phone_number,
      member_level,
      applicant_has_completed_hom_sts,
      applicant_has_completed_ict,
      trim(accepted_terms_version),
      computed_status,
      request_idempotency_key
    ) returning * into result;
  end if;

  return result;
end;
$$;

create or replace function public.submit_my_coach_application(
  target_application_id uuid,
  request_idempotency_key text
)
returns public.coach_applications
language plpgsql
security definer
set search_path = ''
as $$
declare
  application public.coach_applications;
  payment public.coach_payment_records;
begin
  perform private.assert_idempotency_key(request_idempotency_key);

  select * into application
  from public.coach_applications
  where id = target_application_id
  for update;

  if application.id is null then raise exception 'application_not_found'; end if;
  if application.applicant_user_id <> (select auth.uid()) then
    raise exception 'permission_denied';
  end if;
  if application.submit_idempotency_key = request_idempotency_key
    and application.submitted_at is not null
  then
    return application;
  end if;
  if application.status in ('approved', 'rejected', 'expired') then
    raise exception 'application_terminal';
  end if;
  if application.member_level_snapshot = 'member'
    or not application.has_completed_hom_sts
    or not application.has_completed_ict
  then
    raise exception 'coach_eligibility_incomplete';
  end if;

  select * into payment
  from public.coach_payment_records
  where application_id = application.id;

  update public.coach_applications
  set
    status = case
      when payment.state = 'verified' then 'pending_admin_approval'
      when payment.state in ('processing', 'pending') then 'payment_processing'
      else 'ready_for_payment'
    end,
    submitted_at = coalesce(submitted_at, statement_timestamp()),
    submit_idempotency_key = request_idempotency_key,
    updated_at = statement_timestamp()
  where id = application.id
  returning * into application;

  return application;
end;
$$;

create or replace function public.decide_coach_application(
  target_application_id uuid,
  decision text,
  decision_reason text,
  request_idempotency_key text
)
returns public.coach_applications
language plpgsql
security definer
set search_path = ''
as $$
declare
  application public.coach_applications;
  payment public.coach_payment_records;
  entitlement public.coach_access_entitlements;
  generated_qr text;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if decision not in ('approved', 'rejected') then
    raise exception 'decision_invalid';
  end if;
  if decision = 'rejected'
    and length(trim(coalesce(decision_reason, ''))) = 0
  then
    raise exception 'reason_required';
  end if;

  select * into application
  from public.coach_applications
  where id = target_application_id
  for update;

  if application.id is null then raise exception 'application_not_found'; end if;

  if application.status in ('approved', 'rejected') then
    if application.status = decision
      and application.decision_idempotency_key = request_idempotency_key
    then
      return application;
    end if;
    raise exception 'application_already_decided';
  end if;

  if application.submitted_at is null then
    raise exception 'application_not_submitted';
  end if;

  if decision = 'approved' then
    if application.member_level_snapshot = 'member'
      or not application.has_completed_hom_sts
      or not application.has_completed_ict
    then
      raise exception 'coach_eligibility_incomplete';
    end if;

    select * into payment
    from public.coach_payment_records
    where application_id = application.id
    for update;
    if payment.id is null or payment.state <> 'verified' then
      raise exception 'payment_not_verified';
    end if;

    select * into entitlement
    from public.coach_access_entitlements
    where application_id = application.id
      and payment_record_id = payment.id
    for update;
    if entitlement.id is null
      or entitlement.status <> 'active'
      or entitlement.starts_at > statement_timestamp()
      or entitlement.ends_at <= statement_timestamp()
    then
      raise exception 'coach_entitlement_inactive';
    end if;

    generated_qr := 'coach_' || pg_catalog.encode(
      extensions.gen_random_bytes(24),
      'hex'
    );
    update public.profiles
    set
      role = 'coach',
      coach_is_approved = true,
      coach_qr_identifier = coalesce(coach_qr_identifier, generated_qr),
      updated_at = statement_timestamp()
    where user_id = application.applicant_user_id
      and role = 'participant';

    if not found then raise exception 'role_transition_invalid'; end if;
  end if;

  update public.coach_applications
  set
    status = decision,
    decided_at = statement_timestamp(),
    decided_by = (select auth.uid()),
    rejection_reason = case when decision = 'rejected'
      then trim(decision_reason) else null end,
    decision_idempotency_key = request_idempotency_key,
    updated_at = statement_timestamp()
  where id = application.id
  returning * into application;

  insert into public.audit_events (
    actor_id, kind, subject_id, summary, payload
  ) values (
    (select auth.uid()),
    case when decision = 'approved'
      then 'coach_approved' else 'coach_application_rejected' end,
    application.id,
    coalesce(nullif(trim(coalesce(decision_reason, '')), ''), decision),
    jsonb_build_object(
      'applicant_user_id', application.applicant_user_id,
      'payment_record_id', payment.id,
      'entitlement_id', entitlement.id,
      'member_level_snapshot', application.member_level_snapshot
    )
  );

  return application;
end;
$$;

create or replace function public.get_my_coach_application()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'application', to_jsonb(application),
        'payment', case when payment.id is null then null else to_jsonb(payment) end,
        'entitlement', case when entitlement.id is null then null else to_jsonb(entitlement) end,
        'is_eligible', application.member_level_snapshot <> 'member'
          and application.has_completed_hom_sts
          and application.has_completed_ict
      )
      from public.coach_applications application
      left join public.coach_payment_records payment
        on payment.application_id = application.id
      left join public.coach_access_entitlements entitlement
        on entitlement.application_id = application.id
      where application.applicant_user_id = (select auth.uid())
      order by application.created_at desc
      limit 1
    ),
    'null'::jsonb
  );
$$;

create or replace function public.list_coach_applications_for_admin()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  return query
  select jsonb_build_object(
    'application', to_jsonb(application),
    'payment', case when payment.id is null then null else to_jsonb(payment) end,
    'entitlement', case when entitlement.id is null then null else to_jsonb(entitlement) end,
    'is_eligible', application.member_level_snapshot <> 'member'
      and application.has_completed_hom_sts
      and application.has_completed_ict
  )
  from public.coach_applications application
  left join public.coach_payment_records payment
    on payment.application_id = application.id
  left join public.coach_access_entitlements entitlement
    on entitlement.application_id = application.id
  order by
    case application.status when 'pending_admin_approval' then 0 else 1 end,
    application.submitted_at desc nulls last,
    application.created_at desc;
end;
$$;

revoke execute on function private.has_active_coach_access(uuid)
  from public, anon, authenticated, service_role;

revoke execute on function
  public.save_my_coach_application_draft(text, boolean, boolean, text, text),
  public.submit_my_coach_application(uuid, text),
  public.decide_coach_application(uuid, text, text, text),
  public.get_my_coach_application(),
  public.list_coach_applications_for_admin()
from public, anon, authenticated, service_role;

grant execute on function
  public.save_my_coach_application_draft(text, boolean, boolean, text, text),
  public.submit_my_coach_application(uuid, text),
  public.decide_coach_application(uuid, text, text, text),
  public.get_my_coach_application(),
  public.list_coach_applications_for_admin()
to authenticated;
