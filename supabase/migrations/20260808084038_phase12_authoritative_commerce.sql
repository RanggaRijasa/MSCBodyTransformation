-- Phase 12: provider-neutral, server-authoritative commerce for paid program
-- enrollment and manual three-month Coach access. All mutable commerce
-- projections are written through protected operations; mobile clients only
-- receive preflight inputs and read their own resulting state.

create table private.account_commerce_tokens (
  account_id uuid primary key
    references public.profiles(user_id) on delete cascade,
  app_account_token uuid not null unique default gen_random_uuid(),
  created_at timestamptz not null default statement_timestamp()
);

revoke all on table private.account_commerce_tokens
  from public, anon, authenticated;
grant select, insert, delete on table private.account_commerce_tokens
  to service_role;

create table private.commerce_request_limits (
  account_id uuid not null references public.profiles(user_id) on delete cascade,
  operation text not null check (
    operation in ('program_preflight', 'coach_preflight', 'verify', 'restore')
  ),
  window_started_at timestamptz not null,
  request_count integer not null check (request_count > 0),
  primary key (account_id, operation)
);

revoke all on table private.commerce_request_limits
  from public, anon, authenticated, service_role;

create table private.pending_program_coach_selections (
  account_id uuid primary key
    references public.profiles(user_id) on delete cascade,
  coach_id uuid not null
    references public.profiles(user_id) on delete cascade,
  selected_at timestamptz not null default statement_timestamp(),
  expires_at timestamptz not null,
  constraint pending_program_coach_selection_expiry check (
    expires_at > selected_at
  )
);

revoke all on table private.pending_program_coach_selections
  from public, anon, authenticated, service_role;

alter table public.program_store_products
  drop constraint program_store_products_environment_check,
  add constraint program_store_products_environment_check check (
    environment in ('xcode', 'local_testing', 'sandbox', 'production')
  ),
  add column product_type text not null default 'non_consumable'
    check (product_type = 'non_consumable');

create table public.coach_store_products (
  id uuid primary key default gen_random_uuid(),
  price_band text not null check (
    price_band in ('entry', 'growth', 'leadership')
  ),
  platform text not null check (platform in ('app_store', 'play_store')),
  environment text not null check (
    environment in ('xcode', 'local_testing', 'sandbox', 'production')
  ),
  product_id text not null,
  product_type text not null check (
    product_type = 'non_renewing_subscription'
  ),
  provisioning_status text not null check (
    provisioning_status in (
      'not_requested', 'provisioning', 'waiting_for_store', 'ready',
      'action_required', 'retired'
    )
  ),
  actual_price numeric(14, 2),
  currency_code text,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  unique (platform, environment, product_id),
  unique (price_band, platform, environment)
);

create table public.commerce_purchase_intents (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.profiles(user_id) on delete cascade,
  app_account_token uuid not null,
  subject_kind text not null check (
    subject_kind in ('program', 'coach_access')
  ),
  program_id uuid references public.programs(id) on delete restrict,
  coach_application_id uuid
    references public.coach_applications(id) on delete cascade,
  coach_id_snapshot uuid references public.profiles(user_id) on delete restrict,
  program_store_product_id uuid
    references public.program_store_products(id) on delete restrict,
  coach_store_product_id uuid
    references public.coach_store_products(id) on delete restrict,
  provider text not null check (provider in ('app_store', 'play_store')),
  environment text not null check (
    environment in ('xcode', 'local_testing', 'sandbox', 'production')
  ),
  product_id text not null,
  status text not null default 'reserved' check (
    status in (
      'reserved', 'purchase_pending', 'fulfilled', 'cancelled',
      'expired', 'failed'
    )
  ),
  idempotency_key text not null check (
    length(idempotency_key) between 8 and 128
  ),
  expires_at timestamptz not null,
  fulfilled_transaction_id uuid,
  last_error_code text,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  fulfilled_at timestamptz,
  unique (account_id, idempotency_key),
  constraint commerce_purchase_intent_subject_shape check (
    (
      subject_kind = 'program'
      and program_id is not null
      and coach_id_snapshot is not null
      and program_store_product_id is not null
      and coach_application_id is null
      and coach_store_product_id is null
    )
    or (
      subject_kind = 'coach_access'
      and coach_application_id is not null
      and coach_store_product_id is not null
      and program_id is null
      and coach_id_snapshot is null
      and program_store_product_id is null
    )
  ),
  constraint commerce_purchase_intent_expiry check (
    expires_at > created_at
  ),
  constraint commerce_purchase_intent_fulfillment_shape check (
    (status = 'fulfilled' and fulfilled_at is not null)
    or (status <> 'fulfilled' and fulfilled_at is null)
  )
);

create unique index commerce_purchase_intents_active_program_idx
  on public.commerce_purchase_intents(account_id, program_id, environment)
  where subject_kind = 'program'
    and status in ('reserved', 'purchase_pending');
create unique index commerce_purchase_intents_active_coach_idx
  on public.commerce_purchase_intents(
    account_id, coach_application_id, environment
  )
  where subject_kind = 'coach_access'
    and status in ('reserved', 'purchase_pending');
create index commerce_purchase_intents_capacity_idx
  on public.commerce_purchase_intents(program_id, status, expires_at)
  where subject_kind = 'program';
create index commerce_purchase_intents_account_idx
  on public.commerce_purchase_intents(account_id, created_at desc);
create index commerce_purchase_intents_coach_snapshot_idx
  on public.commerce_purchase_intents(coach_id_snapshot)
  where coach_id_snapshot is not null;

alter table public.commerce_transactions
  drop constraint commerce_transactions_status_check,
  alter column program_id drop not null,
  alter column participant_id drop not null,
  add column subject_kind text not null default 'program' check (
    subject_kind in ('program', 'coach_access')
  ),
  add column coach_application_id uuid
    references public.coach_applications(id) on delete set null,
  add column purchase_intent_id uuid
    references public.commerce_purchase_intents(id) on delete set null,
  add column provider text not null default 'app_store' check (
    provider in ('app_store', 'play_store')
  ),
  add column product_type text not null default 'non_consumable' check (
    product_type in ('non_consumable', 'non_renewing_subscription')
  ),
  add column original_transaction_id text,
  add column app_account_token uuid,
  add column signed_at timestamptz,
  add column expires_at timestamptz,
  add column revocation_at timestamptz,
  add column revocation_reason text,
  add column currency_code text,
  add column price_milliunits bigint,
  add column last_event_at timestamptz,
  add constraint commerce_transactions_status_check check (
    status in ('verified', 'pending', 'refunded', 'revoked', 'expired')
  ),
  add constraint commerce_transactions_subject_shape check (
    (subject_kind = 'program' and program_id is not null)
    or (subject_kind = 'coach_access' and program_id is null)
  ),
  add constraint commerce_transactions_price_shape check (
    price_milliunits is null or price_milliunits >= 0
  );

create unique index commerce_transactions_original_lineage_idx
  on public.commerce_transactions(
    provider, environment, original_transaction_id, product_id, participant_id
  )
  where original_transaction_id is not null and participant_id is not null;
create index commerce_transactions_purchase_intent_idx
  on public.commerce_transactions(purchase_intent_id);
create index commerce_transactions_coach_application_idx
  on public.commerce_transactions(coach_application_id)
  where coach_application_id is not null;

alter table public.commerce_purchase_intents
  add constraint commerce_purchase_intents_fulfilled_transaction_fkey
  foreign key (fulfilled_transaction_id)
  references public.commerce_transactions(id) on delete set null;

create table public.commerce_transaction_events (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid references public.commerce_transactions(id) on delete cascade,
  provider text not null check (provider in ('app_store', 'play_store')),
  environment text not null check (
    environment in ('xcode', 'local_testing', 'sandbox', 'production')
  ),
  external_event_id text not null,
  event_type text not null,
  event_at timestamptz not null,
  signed_payload_hash text not null,
  decoded_fields jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default statement_timestamp(),
  unique (provider, environment, external_event_id)
);

create index commerce_transaction_events_transaction_idx
  on public.commerce_transaction_events(transaction_id, event_at desc);

create table public.program_entitlement_events (
  id uuid primary key default gen_random_uuid(),
  entitlement_id uuid not null
    references public.program_entitlements(id) on delete cascade,
  transaction_id uuid references public.commerce_transactions(id) on delete set null,
  event_type text not null check (
    event_type in ('granted', 'restored', 'refunded', 'revoked')
  ),
  event_at timestamptz not null,
  created_at timestamptz not null default statement_timestamp(),
  unique (entitlement_id, event_type, transaction_id)
);

create index program_entitlement_events_entitlement_idx
  on public.program_entitlement_events(entitlement_id, event_at desc);

create table public.apple_notification_inbox (
  id uuid primary key default gen_random_uuid(),
  notification_uuid uuid not null unique,
  environment text not null check (
    environment in ('xcode', 'local_testing', 'sandbox', 'production')
  ),
  notification_type text not null,
  subtype text,
  transaction_id text,
  original_transaction_id text,
  signed_at timestamptz not null,
  signed_payload_hash text not null,
  decoded_fields jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (
    status in ('pending', 'processed', 'dead_letter')
  ),
  retry_count integer not null default 0 check (retry_count >= 0),
  last_error_code text,
  received_at timestamptz not null default statement_timestamp(),
  processed_at timestamptz
);

create index apple_notification_inbox_pending_idx
  on public.apple_notification_inbox(status, received_at)
  where status in ('pending', 'dead_letter');
create index apple_notification_inbox_transaction_idx
  on public.apple_notification_inbox(environment, transaction_id)
  where transaction_id is not null;

alter table public.coach_payment_records
  drop constraint coach_payment_records_application_id_key,
  drop constraint coach_payment_records_state_check,
  add column transaction_id uuid unique
    references public.commerce_transactions(id) on delete set null,
  add column period_sequence integer not null default 1 check (
    period_sequence > 0
  ),
  add constraint coach_payment_records_state_check check (
    state in (
      'not_started', 'processing', 'pending', 'verified', 'cancelled',
      'failed', 'interrupted', 'refunded', 'revoked'
    )
  );

create unique index coach_payment_records_application_period_idx
  on public.coach_payment_records(application_id, period_sequence);
create index coach_payment_records_application_created_idx
  on public.coach_payment_records(application_id, created_at desc);

alter table public.coach_access_entitlements
  drop constraint coach_access_entitlements_application_id_key,
  drop constraint coach_access_entitlements_status_check,
  add column period_sequence integer not null default 1 check (
    period_sequence > 0
  ),
  add column supersedes_entitlement_id uuid
    references public.coach_access_entitlements(id) on delete set null,
  add constraint coach_access_entitlements_status_check check (
    status in (
      'pending_activation', 'active', 'expired', 'revoked', 'refunded'
    )
  );

create unique index coach_access_entitlements_application_period_idx
  on public.coach_access_entitlements(application_id, period_sequence);

alter table public.coach_applications
  drop constraint coach_applications_status_check,
  drop constraint coach_application_terminal_shape;

update public.coach_applications
set status = case status
  when 'ready_for_payment' then 'submitted'
  when 'payment_processing' then 'submitted'
  when 'payment_verified' then 'submitted'
  when 'pending_admin_approval' then 'submitted'
  when 'approved' then 'active'
  else status
end,
updated_at = statement_timestamp()
where status in (
  'ready_for_payment', 'payment_processing', 'payment_verified',
  'pending_admin_approval', 'approved'
);

alter table public.coach_applications
  add constraint coach_applications_status_check check (
    status in (
      'draft', 'ineligible', 'submitted', 'accepted_pending_payment',
      'active', 'rejected', 'expired'
    )
  ),
  add constraint coach_application_terminal_shape check (
    (status in ('accepted_pending_payment', 'active', 'expired')
      and decided_at is not null and decided_by is not null
      and rejection_reason is null)
    or (status = 'rejected' and decided_at is not null and decided_by is not null
      and length(trim(rejection_reason)) > 0)
    or (status in ('draft', 'ineligible', 'submitted')
      and decided_at is null and decided_by is null and rejection_reason is null)
  );

drop index coach_applications_one_active_per_user_idx;
create unique index coach_applications_one_active_per_user_idx
  on public.coach_applications(applicant_user_id)
  where status in (
    'draft', 'ineligible', 'submitted', 'accepted_pending_payment', 'active'
  );

alter table public.coach_store_products enable row level security;
alter table public.commerce_purchase_intents enable row level security;
alter table public.commerce_transaction_events enable row level security;
alter table public.program_entitlement_events enable row level security;
alter table public.apple_notification_inbox enable row level security;

revoke all privileges on table
  public.coach_store_products,
  public.commerce_purchase_intents,
  public.commerce_transaction_events,
  public.program_entitlement_events,
  public.apple_notification_inbox
from public, anon, authenticated, service_role;

grant all privileges on table
  public.coach_store_products,
  public.commerce_purchase_intents,
  public.commerce_transaction_events,
  public.program_entitlement_events,
  public.apple_notification_inbox
to service_role;

create policy "account reads own commerce intents"
on public.commerce_purchase_intents for select to authenticated
using (account_id = (select auth.uid()));

create policy "account reads own program entitlement history"
on public.program_entitlement_events for select to authenticated
using (exists (
  select 1
  from public.program_entitlements entitlement
  where entitlement.id = entitlement_id
    and entitlement.participant_id = (select auth.uid())
));

create or replace function private.coach_price_band(target_level text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when target_level in ('sc', 'sb') then 'entry'
    when target_level in ('supervisor', 'world_team') then 'growth'
    when target_level in (
      'tab_team', 'get_team', 'millionaire_team', 'presidents_team'
    ) then 'leadership'
    else null
  end;
$$;

create or replace function private.ensure_account_commerce_token(
  target_account_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result uuid;
begin
  insert into private.account_commerce_tokens(account_id)
  values (target_account_id)
  on conflict (account_id) do nothing;

  select token.app_account_token into result
  from private.account_commerce_tokens token
  where token.account_id = target_account_id;
  return result;
end;
$$;

create or replace function public.consume_commerce_rate_limit(
  caller_account_id uuid,
  target_operation text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  maximum_requests integer;
  current_limit private.commerce_request_limits;
  current_statement_time timestamptz := statement_timestamp();
begin
  maximum_requests := case target_operation
    when 'program_preflight' then 30
    when 'coach_preflight' then 30
    when 'verify' then 20
    when 'restore' then 5
    else null
  end;
  if caller_account_id is null or maximum_requests is null then
    raise exception 'permission_denied';
  end if;

  select * into current_limit
  from private.commerce_request_limits request_limit
  where request_limit.account_id = caller_account_id
    and request_limit.operation = target_operation
  for update;

  if current_limit.account_id is null then
    insert into private.commerce_request_limits(
      account_id, operation, window_started_at, request_count
    ) values (
      caller_account_id, target_operation, current_statement_time, 1
    );
  elsif current_limit.window_started_at <=
      current_statement_time - interval '1 minute'
  then
    update private.commerce_request_limits
    set window_started_at = current_statement_time, request_count = 1
    where account_id = caller_account_id and operation = target_operation;
  elsif current_limit.request_count >= maximum_requests then
    raise exception 'rate_limited';
  else
    update private.commerce_request_limits
    set request_count = request_count + 1
    where account_id = caller_account_id and operation = target_operation;
  end if;
end;
$$;

create or replace function public.resolve_coach_qr_for_enrollment(
  scanned_coach_qr text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  account_profile public.profiles;
  coach public.profiles;
begin
  if length(trim(coalesce(scanned_coach_qr, ''))) < 16 then
    raise exception 'coach_qr_invalid';
  end if;

  select * into account_profile
  from public.profiles
  where user_id = (select auth.uid())
    and role in ('participant', 'coach')
    and onboarding_status = 'active'
  for update;
  if account_profile.user_id is null then raise exception 'permission_denied'; end if;

  select * into coach
  from public.profiles
  where coach_qr_identifier = trim(scanned_coach_qr)
    and role = 'coach'
    and coach_is_approved
    and private.has_active_coach_access(user_id)
  for share;
  if coach.user_id is null then raise exception 'coach_qr_invalid'; end if;
  if account_profile.current_coach_id is not null
    and account_profile.current_coach_id <> coach.user_id
  then raise exception 'coach_mismatch'; end if;

  insert into private.pending_program_coach_selections(
    account_id, coach_id, selected_at, expires_at
  ) values (
    account_profile.user_id, coach.user_id, statement_timestamp(),
    statement_timestamp() + interval '30 minutes'
  )
  on conflict (account_id) do update
    set coach_id = excluded.coach_id,
        selected_at = excluded.selected_at,
        expires_at = excluded.expires_at;

  return jsonb_build_object(
    'id', coach.user_id,
    'display_name', coach.display_name,
    'city', coach.city,
    'photo_reference', coach.provider_avatar_url,
    'is_public', coach.coach_is_public,
    'is_approved', coach.coach_is_approved
  );
end;
$$;

create or replace function public.create_program_purchase_intent(
  target_program_id uuid,
  caller_account_id uuid,
  target_environment text,
  request_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := caller_account_id;
  caller_profile public.profiles;
  target_program public.programs;
  product public.program_store_products;
  existing public.commerce_purchase_intents;
  result public.commerce_purchase_intents;
  active_count bigint;
  app_token uuid;
  selected_coach_id uuid;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if caller_id is null then raise exception 'permission_denied'; end if;
  if target_environment not in ('xcode', 'local_testing', 'sandbox', 'production')
  then raise exception 'transaction_mismatch'; end if;

  select * into caller_profile
  from public.profiles
  where user_id = caller_id
    and onboarding_status = 'active'
    and role in ('participant', 'coach')
  for update;
  if caller_profile.user_id is null then raise exception 'profile_incomplete'; end if;

  selected_coach_id := caller_profile.current_coach_id;
  if selected_coach_id is null then
    select selection.coach_id into selected_coach_id
    from private.pending_program_coach_selections selection
    where selection.account_id = caller_id
      and selection.expires_at > statement_timestamp();
  end if;
  if selected_coach_id is null then raise exception 'coach_required'; end if;
  if not private.has_active_coach_access(selected_coach_id) then
    raise exception 'coach_invalid';
  end if;

  select * into target_program
  from public.programs
  where id = target_program_id
  for update;
  if target_program.id is null
    or target_program.status not in ('scheduled', 'active')
  then raise exception 'program_unavailable'; end if;
  if target_program.pricing_mode <> 'paid' then
    raise exception 'payment_not_required';
  end if;
  if target_program.registration_closes_at is not null
    and statement_timestamp() >= target_program.registration_closes_at
  then raise exception 'registration_closed'; end if;
  if exists (
    select 1 from public.program_enrollments enrollment
    where enrollment.program_id = target_program.id
      and enrollment.participant_id = caller_id
      and enrollment.status in ('active', 'completed')
  ) then raise exception 'already_enrolled'; end if;

  select * into product
  from public.program_store_products mapping
  where mapping.program_id = target_program.id
    and mapping.platform = 'app_store'
    and mapping.environment = target_environment
    and mapping.provisioning_status = 'ready';
  if product.id is null then raise exception 'product_not_ready'; end if;

  select * into existing
  from public.commerce_purchase_intents intent
  where intent.account_id = caller_id
    and intent.idempotency_key = request_idempotency_key
  for update;
  if existing.id is not null then
    if existing.subject_kind <> 'program'
      or existing.program_id <> target_program.id
      or existing.environment <> target_environment
    then raise exception 'transaction_mismatch'; end if;
    return jsonb_build_object(
      'purchase_intent_id', existing.id,
      'product_id', existing.product_id,
      'app_account_token', existing.app_account_token,
      'environment', existing.environment,
      'expires_at', existing.expires_at,
      'status', existing.status,
      'subject_kind', existing.subject_kind
    );
  end if;

  update public.commerce_purchase_intents
  set status = 'expired', updated_at = statement_timestamp()
  where account_id = caller_id
    and program_id = target_program.id
    and environment = target_environment
    and status in ('reserved', 'purchase_pending')
    and expires_at <= statement_timestamp();

  select * into existing
  from public.commerce_purchase_intents intent
  where intent.account_id = caller_id
    and intent.program_id = target_program.id
    and intent.environment = target_environment
    and intent.status in ('reserved', 'purchase_pending')
    and intent.expires_at > statement_timestamp()
  for update;
  if existing.id is not null then
    return jsonb_build_object(
      'purchase_intent_id', existing.id,
      'product_id', existing.product_id,
      'app_account_token', existing.app_account_token,
      'environment', existing.environment,
      'expires_at', existing.expires_at,
      'status', existing.status,
      'subject_kind', existing.subject_kind,
      'program_id', existing.program_id,
      'coach_id', existing.coach_id_snapshot
    );
  end if;

  if target_program.participant_limit is not null then
    select
      (select count(*) from public.program_enrollments enrollment
       where enrollment.program_id = target_program.id
         and enrollment.status in ('active', 'completed'))
      +
      (select count(*) from public.commerce_purchase_intents intent
       where intent.program_id = target_program.id
         and intent.status in ('reserved', 'purchase_pending')
         and intent.expires_at > statement_timestamp())
    into active_count;
    if active_count >= target_program.participant_limit then
      raise exception 'program_full';
    end if;
  end if;

  app_token := private.ensure_account_commerce_token(caller_id);
  insert into public.commerce_purchase_intents(
    account_id, app_account_token, subject_kind, program_id,
    coach_id_snapshot, program_store_product_id, provider, environment,
    product_id, idempotency_key, expires_at
  ) values (
    caller_id, app_token, 'program', target_program.id,
    selected_coach_id, product.id, 'app_store',
    target_environment, product.product_id, request_idempotency_key,
    statement_timestamp() + interval '30 minutes'
  ) returning * into result;

  return jsonb_build_object(
    'purchase_intent_id', result.id,
    'product_id', result.product_id,
    'app_account_token', result.app_account_token,
    'environment', result.environment,
    'expires_at', result.expires_at,
    'status', result.status,
    'subject_kind', result.subject_kind,
    'program_id', result.program_id,
    'coach_id', result.coach_id_snapshot
  );
end;
$$;

create or replace function public.create_coach_purchase_intent(
  caller_account_id uuid,
  target_environment text,
  request_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := caller_account_id;
  application public.coach_applications;
  product public.coach_store_products;
  existing public.commerce_purchase_intents;
  result public.commerce_purchase_intents;
  resolved_price_band text;
  app_token uuid;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if caller_id is null then raise exception 'permission_denied'; end if;
  if target_environment not in ('xcode', 'local_testing', 'sandbox', 'production')
  then raise exception 'transaction_mismatch'; end if;

  select * into application
  from public.coach_applications candidate
  where candidate.applicant_user_id = caller_id
    and candidate.status in ('accepted_pending_payment', 'active', 'expired')
  order by candidate.created_at desc
  limit 1
  for update;
  if application.id is null then raise exception 'coach_approval_required'; end if;
  if application.member_level_snapshot = 'member'
    or not application.has_completed_hom_sts
    or not application.has_completed_ict
  then raise exception 'coach_eligibility_incomplete'; end if;

  resolved_price_band := private.coach_price_band(
    application.member_level_snapshot
  );
  select * into product
  from public.coach_store_products mapping
  where mapping.price_band = resolved_price_band
    and mapping.platform = 'app_store'
    and mapping.environment = target_environment
    and mapping.provisioning_status = 'ready';
  if product.id is null then raise exception 'product_not_ready'; end if;

  select * into existing
  from public.commerce_purchase_intents intent
  where intent.account_id = caller_id
    and intent.idempotency_key = request_idempotency_key
  for update;
  if existing.id is not null then
    if existing.subject_kind <> 'coach_access'
      or existing.coach_application_id <> application.id
      or existing.environment <> target_environment
    then raise exception 'transaction_mismatch'; end if;
    return jsonb_build_object(
      'purchase_intent_id', existing.id,
      'product_id', existing.product_id,
      'app_account_token', existing.app_account_token,
      'environment', existing.environment,
      'expires_at', existing.expires_at,
      'status', existing.status,
      'subject_kind', existing.subject_kind
    );
  end if;

  update public.commerce_purchase_intents
  set status = 'expired', updated_at = statement_timestamp()
  where account_id = caller_id
    and coach_application_id = application.id
    and environment = target_environment
    and status in ('reserved', 'purchase_pending')
    and expires_at <= statement_timestamp();

  select * into existing
  from public.commerce_purchase_intents intent
  where intent.account_id = caller_id
    and intent.coach_application_id = application.id
    and intent.environment = target_environment
    and intent.status in ('reserved', 'purchase_pending')
    and intent.expires_at > statement_timestamp()
  for update;
  if existing.id is not null then
    return jsonb_build_object(
      'purchase_intent_id', existing.id,
      'product_id', existing.product_id,
      'app_account_token', existing.app_account_token,
      'environment', existing.environment,
      'expires_at', existing.expires_at,
      'status', existing.status,
      'subject_kind', existing.subject_kind,
      'coach_application_id', existing.coach_application_id,
      'price_band', resolved_price_band
    );
  end if;

  app_token := private.ensure_account_commerce_token(caller_id);
  insert into public.commerce_purchase_intents(
    account_id, app_account_token, subject_kind, coach_application_id,
    coach_store_product_id, provider, environment, product_id,
    idempotency_key, expires_at
  ) values (
    caller_id, app_token, 'coach_access', application.id,
    product.id, 'app_store', target_environment, product.product_id,
    request_idempotency_key, statement_timestamp() + interval '30 minutes'
  ) returning * into result;

  return jsonb_build_object(
    'purchase_intent_id', result.id,
    'product_id', result.product_id,
    'app_account_token', result.app_account_token,
    'environment', result.environment,
    'expires_at', result.expires_at,
    'status', result.status,
    'subject_kind', result.subject_kind,
    'coach_application_id', result.coach_application_id,
    'price_band', resolved_price_band
  );
end;
$$;

create or replace function public.mark_purchase_intent_pending(
  target_purchase_intent_id uuid,
  caller_account_id uuid
)
returns public.commerce_purchase_intents
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.commerce_purchase_intents;
begin
  update public.commerce_purchase_intents
  set status = 'purchase_pending',
      expires_at = greatest(
        expires_at,
        statement_timestamp() + interval '30 minutes'
      ),
      updated_at = statement_timestamp()
  where id = target_purchase_intent_id
    and account_id = caller_account_id
    and status in ('reserved', 'purchase_pending')
  returning * into result;
  if result.id is null then raise exception 'purchase_intent_expired'; end if;
  return result;
end;
$$;

create or replace function public.resolve_purchase_intent_for_restore(
  caller_account_id uuid,
  verified_product_id text,
  verified_app_account_token uuid,
  target_environment text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result uuid;
begin
  select intent.id into result
  from public.commerce_purchase_intents intent
  where intent.account_id = caller_account_id
    and intent.product_id = verified_product_id
    and intent.app_account_token = verified_app_account_token
    and intent.environment = target_environment
    and intent.status not in ('cancelled', 'failed')
  order by
    case intent.status when 'fulfilled' then 1 else 0 end,
    intent.created_at desc
  limit 1;
  if result is null then raise exception 'transaction_mismatch'; end if;
  return result;
end;
$$;

create or replace function public.get_purchase_intent_for_verification(
  target_purchase_intent_id uuid,
  caller_account_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  intent public.commerce_purchase_intents;
begin
  select * into intent
  from public.commerce_purchase_intents candidate
  where candidate.id = target_purchase_intent_id
    and candidate.account_id = caller_account_id;
  if intent.id is null then raise exception 'purchase_intent_expired'; end if;
  if intent.status in ('cancelled', 'failed') then
    raise exception 'purchase_intent_expired';
  end if;

  return jsonb_build_object(
    'purchase_intent_id', intent.id,
    'account_id', intent.account_id,
    'app_account_token', intent.app_account_token,
    'subject_kind', intent.subject_kind,
    'product_id', intent.product_id,
    'product_type', case when intent.subject_kind = 'program'
      then 'non_consumable' else 'non_renewing_subscription' end,
    'environment', intent.environment,
    'status', intent.status,
    'expires_at', intent.expires_at
  );
end;
$$;

create or replace function public.fulfill_apple_purchase(
  target_purchase_intent_id uuid,
  caller_account_id uuid,
  target_external_transaction_id text,
  target_original_transaction_id text,
  verified_product_id text,
  verified_app_account_token uuid,
  verified_environment text,
  target_signed_payload_hash text,
  target_purchased_at timestamptz,
  target_signed_at timestamptz,
  target_expires_at timestamptz default null,
  target_currency_code text default null,
  target_price_milliunits bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  intent public.commerce_purchase_intents;
  existing_transaction public.commerce_transactions;
  result_transaction public.commerce_transactions;
  result_entitlement public.program_entitlements;
  result_enrollment public.program_enrollments;
  application public.coach_applications;
  payment public.coach_payment_records;
  coach_entitlement public.coach_access_entitlements;
  previous_coach_entitlement public.coach_access_entitlements;
  sequence_number integer;
  access_starts_at timestamptz;
  access_ends_at timestamptz;
  over_capacity boolean := false;
  generated_qr text;
  bound_coach_count integer;
begin
  if caller_account_id is null then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(target_external_transaction_id, ''))) = 0
    or length(trim(coalesce(target_original_transaction_id, ''))) = 0
    or length(trim(coalesce(target_signed_payload_hash, ''))) = 0
  then raise exception 'transaction_mismatch'; end if;

  select * into intent
  from public.commerce_purchase_intents
  where id = target_purchase_intent_id
  for update;
  if intent.id is null then raise exception 'purchase_intent_expired'; end if;
  if intent.account_id <> caller_account_id
    or intent.product_id <> verified_product_id
    or intent.app_account_token <> verified_app_account_token
    or intent.environment <> verified_environment
    or intent.provider <> 'app_store'
  then raise exception 'transaction_mismatch'; end if;

  select * into existing_transaction
  from public.commerce_transactions transaction
  where transaction.platform = 'app_store'
    and transaction.environment = verified_environment
    and transaction.external_transaction_id = target_external_transaction_id
  for update;
  if existing_transaction.id is not null then
    if existing_transaction.participant_id <> caller_account_id
      or existing_transaction.purchase_intent_id <> intent.id
      or existing_transaction.product_id <> verified_product_id
    then raise exception 'transaction_replayed'; end if;
    return jsonb_build_object(
      'transaction_id', existing_transaction.id,
      'status', existing_transaction.status,
      'subject_kind', existing_transaction.subject_kind,
      'program_id', existing_transaction.program_id,
      'coach_application_id', existing_transaction.coach_application_id,
      'idempotent', true
    );
  end if;

  if intent.status = 'fulfilled' then raise exception 'transaction_replayed'; end if;
  if intent.status in ('cancelled', 'failed') then
    raise exception 'purchase_intent_expired';
  end if;

  insert into public.commerce_transactions(
    platform, provider, environment, external_transaction_id,
    original_transaction_id, subject_kind, program_id, coach_application_id,
    participant_id, purchase_intent_id, product_id, product_type, status,
    signed_payload_hash, app_account_token, purchased_at, signed_at,
    expires_at, currency_code, price_milliunits, last_event_at
  ) values (
    'app_store', 'app_store', verified_environment,
    target_external_transaction_id,
    target_original_transaction_id, intent.subject_kind, intent.program_id,
    intent.coach_application_id, caller_account_id, intent.id,
    verified_product_id,
    case when intent.subject_kind = 'program'
      then 'non_consumable' else 'non_renewing_subscription' end,
    'verified', target_signed_payload_hash, verified_app_account_token,
    target_purchased_at, target_signed_at, target_expires_at,
    target_currency_code, target_price_milliunits, target_signed_at
  ) returning * into result_transaction;

  insert into public.commerce_transaction_events(
    transaction_id, provider, environment, external_event_id, event_type,
    event_at, signed_payload_hash, decoded_fields
  ) values (
    result_transaction.id, 'app_store', verified_environment,
    'transaction:' || target_external_transaction_id, 'verified',
    target_signed_at, target_signed_payload_hash,
    jsonb_build_object(
      'product_id', verified_product_id,
      'original_transaction_id_hash',
        encode(
          extensions.digest(target_original_transaction_id, 'sha256'),
          'hex'
        )
    )
  );

  if intent.subject_kind = 'program' then
    update public.profiles
    set current_coach_id = intent.coach_id_snapshot,
        updated_at = statement_timestamp()
    where user_id = caller_account_id
      and role in ('participant', 'coach')
      and (
        current_coach_id is null
        or current_coach_id = intent.coach_id_snapshot
      );
    get diagnostics bound_coach_count = row_count;
    if bound_coach_count <> 1 then raise exception 'coach_mismatch'; end if;

    if exists (
      select 1 from public.programs program
      where program.id = intent.program_id
        and program.participant_limit is not null
        and (
          select count(*) from public.program_enrollments enrollment
          where enrollment.program_id = program.id
            and enrollment.status in ('active', 'completed')
        ) >= program.participant_limit
    ) then over_capacity := true; end if;

    insert into public.program_entitlements(
      program_id, participant_id, transaction_id, status, granted_at
    ) values (
      intent.program_id, caller_account_id, result_transaction.id,
      'active', statement_timestamp()
    )
    on conflict (program_id, participant_id) do update
      set transaction_id = excluded.transaction_id,
          status = 'active',
          granted_at = excluded.granted_at,
          revoked_at = null
    returning * into result_entitlement;

    insert into public.program_entitlement_events(
      entitlement_id, transaction_id, event_type, event_at
    ) values (
      result_entitlement.id, result_transaction.id, 'granted',
      statement_timestamp()
    ) on conflict do nothing;

    insert into public.program_enrollments(
      program_id, participant_id, coach_id, status, enrolled_at
    ) values (
      intent.program_id, caller_account_id, intent.coach_id_snapshot,
      'active', statement_timestamp()
    )
    on conflict (program_id, participant_id) do update
      set coach_id = excluded.coach_id,
          status = 'active',
          enrolled_at = excluded.enrolled_at,
          completed_at = null
    returning * into result_enrollment;

    insert into public.program_scores(enrollment_id)
    values (result_enrollment.id)
    on conflict (enrollment_id) do nothing;

    insert into public.audit_events(
      actor_id, kind, subject_id, summary, payload
    ) values (
      caller_account_id,
      case when over_capacity
        then 'paid_program_over_capacity_fulfilled'
        else 'paid_program_purchase_fulfilled' end,
      result_enrollment.id,
      case when over_capacity
        then 'Pembelian sah dipenuhi setelah reservasi kedaluwarsa.'
        else 'Pembelian program berhasil diverifikasi.' end,
      jsonb_build_object(
        'program_id', intent.program_id,
        'transaction_id', result_transaction.id,
        'purchase_intent_id', intent.id,
        'over_capacity', over_capacity
      )
    );

    delete from private.pending_program_coach_selections
    where account_id = caller_account_id;
  else
    select * into application
    from public.coach_applications
    where id = intent.coach_application_id
    for update;
    if application.id is null
      or application.applicant_user_id <> caller_account_id
      or application.status not in (
        'accepted_pending_payment', 'active', 'expired'
      )
    then raise exception 'coach_approval_required'; end if;

    select coalesce(max(record.period_sequence), 0) + 1
    into sequence_number
    from public.coach_payment_records record
    where record.application_id = application.id;

    insert into public.coach_payment_records(
      application_id, state, price_band, amount_minor_units,
      duration_months, provider_reference, verified_at,
      transaction_id, period_sequence
    ) values (
      application.id, 'verified',
      private.coach_price_band(application.member_level_snapshot),
      coalesce(
        (select mapping.actual_price::bigint
         from public.coach_store_products mapping
         where mapping.id = intent.coach_store_product_id),
        case private.coach_price_band(application.member_level_snapshot)
          when 'entry' then 100000
          when 'growth' then 150000
          else 200000 end
      ),
      3, target_external_transaction_id, statement_timestamp(),
      result_transaction.id, sequence_number
    ) returning * into payment;

    select * into previous_coach_entitlement
    from public.coach_access_entitlements entitlement
    where entitlement.application_id = application.id
    order by entitlement.ends_at desc
    limit 1
    for update;

    access_starts_at := greatest(
      statement_timestamp(),
      coalesce(previous_coach_entitlement.ends_at, statement_timestamp())
    );
    access_ends_at := access_starts_at + interval '3 months';

    insert into public.coach_access_entitlements(
      application_id, payment_record_id, coach_user_id, status,
      starts_at, ends_at, period_sequence, supersedes_entitlement_id
    ) values (
      application.id, payment.id, caller_account_id, 'active',
      access_starts_at, access_ends_at, sequence_number,
      previous_coach_entitlement.id
    ) returning * into coach_entitlement;

    generated_qr := 'coach_' || pg_catalog.encode(
      extensions.gen_random_bytes(24), 'hex'
    );
    update public.profiles
    set role = 'coach', coach_is_approved = true,
        coach_qr_identifier = coalesce(coach_qr_identifier, generated_qr),
        updated_at = statement_timestamp()
    where user_id = caller_account_id
      and role in ('participant', 'coach');
    if not found then raise exception 'role_transition_invalid'; end if;

    update public.coach_applications
    set status = 'active', updated_at = statement_timestamp()
    where id = application.id;

    insert into public.audit_events(
      actor_id, kind, subject_id, summary, payload
    ) values (
      caller_account_id, 'coach_access_purchase_fulfilled',
      coach_entitlement.id,
      'Pembayaran akses Coach berhasil diverifikasi.',
      jsonb_build_object(
        'application_id', application.id,
        'transaction_id', result_transaction.id,
        'period_sequence', sequence_number,
        'starts_at', access_starts_at,
        'ends_at', access_ends_at
      )
    );
  end if;

  update public.commerce_purchase_intents
  set status = 'fulfilled',
      fulfilled_transaction_id = result_transaction.id,
      fulfilled_at = statement_timestamp(),
      updated_at = statement_timestamp()
  where id = intent.id;

  return jsonb_build_object(
    'transaction_id', result_transaction.id,
    'status', result_transaction.status,
    'subject_kind', result_transaction.subject_kind,
    'program_id', result_transaction.program_id,
    'coach_application_id', result_transaction.coach_application_id,
    'program_entitlement_id', result_entitlement.id,
    'enrollment_id', result_enrollment.id,
    'coach_entitlement_id', coach_entitlement.id,
    'coach_access_starts_at', access_starts_at,
    'coach_access_ends_at', access_ends_at,
    'idempotent', false
  );
end;
$$;

create or replace function private.refresh_coach_access_projection(
  target_coach_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  has_active_access boolean;
begin
  select exists (
    select 1
    from public.coach_access_entitlements entitlement
    where entitlement.coach_user_id = target_coach_user_id
      and entitlement.status = 'active'
      and entitlement.starts_at <= statement_timestamp()
      and entitlement.ends_at > statement_timestamp()
  ) into has_active_access;

  if has_active_access then
    update public.profiles
    set role = 'coach',
        coach_is_approved = true,
        updated_at = statement_timestamp()
    where user_id = target_coach_user_id
      and role in ('participant', 'coach');

    update public.coach_applications
    set status = 'active', updated_at = statement_timestamp()
    where applicant_user_id = target_coach_user_id
      and status in ('accepted_pending_payment', 'active', 'expired');
  else
    update public.profiles
    set role = case when role = 'coach' then 'participant' else role end,
        coach_qr_identifier = case when role = 'coach'
          then null else coach_qr_identifier end,
        coach_is_approved = false,
        coach_is_public = false,
        updated_at = statement_timestamp()
    where user_id = target_coach_user_id;

    update public.coach_applications
    set status = 'expired', updated_at = statement_timestamp()
    where applicant_user_id = target_coach_user_id
      and status = 'active';
  end if;
end;
$$;

create or replace function public.reconcile_apple_commerce_event(
  target_external_transaction_id text,
  target_environment text,
  target_external_event_id text,
  target_event_type text,
  target_event_at timestamptz,
  target_signed_payload_hash text,
  target_decoded_fields jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_transaction public.commerce_transactions;
  entitlement public.program_entitlements;
  coach_entitlement public.coach_access_entitlements;
  normalized_status text;
begin
  if target_event_type not in ('verified', 'refund', 'revoke', 'expired') then
    raise exception 'event_type_unsupported';
  end if;
  normalized_status := case target_event_type
    when 'refund' then 'refunded'
    when 'revoke' then 'revoked'
    when 'expired' then 'expired'
    else 'verified'
  end;

  select * into target_transaction
  from public.commerce_transactions transaction
  where transaction.platform = 'app_store'
    and transaction.environment = target_environment
    and transaction.external_transaction_id = target_external_transaction_id
  for update;
  if target_transaction.id is null then raise exception 'transaction_not_found'; end if;

  insert into public.commerce_transaction_events(
    transaction_id, provider, environment, external_event_id, event_type,
    event_at, signed_payload_hash, decoded_fields
  ) values (
    target_transaction.id, 'app_store', target_environment,
    target_external_event_id, target_event_type,
    target_event_at, target_signed_payload_hash,
    coalesce(target_decoded_fields, '{}'::jsonb)
  ) on conflict (provider, environment, external_event_id) do nothing;

  if not found or (
    target_transaction.last_event_at is not null
    and target_transaction.last_event_at >= target_event_at
  ) or (
    target_transaction.status in ('refunded', 'revoked')
    and normalized_status = 'verified'
  ) then
    return jsonb_build_object(
      'transaction_id', target_transaction.id,
      'status', target_transaction.status,
      'ignored_as_duplicate_or_older', true
    );
  end if;

  update public.commerce_transactions
  set status = normalized_status,
      revocation_at = case when normalized_status in ('refunded', 'revoked')
        then target_event_at else revocation_at end,
      revocation_reason = case when normalized_status in ('refunded', 'revoked')
        then target_event_type else revocation_reason end,
      last_event_at = target_event_at,
      updated_at = statement_timestamp()
  where id = target_transaction.id;

  if target_transaction.subject_kind = 'program' then
    update public.program_entitlements
    set status = case normalized_status
          when 'refunded' then 'refunded'
          when 'revoked' then 'revoked'
          else status end,
        revoked_at = case when normalized_status in ('refunded', 'revoked')
          then target_event_at else revoked_at end
    where transaction_id = target_transaction.id
    returning * into entitlement;

    if entitlement.id is not null and normalized_status in ('refunded', 'revoked') then
      insert into public.program_entitlement_events(
        entitlement_id, transaction_id, event_type, event_at
      ) values (
        entitlement.id, target_transaction.id,
        case normalized_status when 'refunded' then 'refunded' else 'revoked' end,
        target_event_at
      ) on conflict do nothing;
      update public.program_enrollments
      set status = 'refunded'
      where program_id = target_transaction.program_id
        and participant_id = target_transaction.participant_id
        and status not in ('refunded', 'cancelled');
    end if;
  else
    update public.coach_access_entitlements
    set status = case normalized_status
          when 'refunded' then 'refunded'
          when 'revoked' then 'revoked'
          when 'expired' then 'expired'
          else status end,
        revoked_at = case when normalized_status in ('refunded', 'revoked')
          then target_event_at else revoked_at end
    where payment_record_id = (
      select record.id from public.coach_payment_records record
      where record.transaction_id = target_transaction.id
    )
    returning * into coach_entitlement;
    update public.coach_payment_records
    set state = case normalized_status
          when 'refunded' then 'refunded'
          when 'revoked' then 'revoked'
          else state end,
        updated_at = statement_timestamp()
    where transaction_id = target_transaction.id;
    if coach_entitlement.coach_user_id is not null then
      perform private.refresh_coach_access_projection(
        coach_entitlement.coach_user_id
      );
    end if;
  end if;

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    null, 'commerce_event_reconciled', target_transaction.id,
    'Status transaksi direkonsiliasi dari event Apple.',
    jsonb_build_object(
      'event_type', target_event_type,
      'event_at', target_event_at,
      'status', normalized_status
    )
  );

  return jsonb_build_object(
    'transaction_id', target_transaction.id,
    'status', normalized_status,
    'ignored_as_duplicate_or_older', false
  );
end;
$$;

create or replace function public.record_apple_notification(
  target_notification_uuid uuid,
  target_environment text,
  target_notification_type text,
  target_subtype text,
  target_transaction_id text,
  target_original_transaction_id text,
  target_signed_at timestamptz,
  target_signed_payload_hash text,
  target_decoded_fields jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  notification public.apple_notification_inbox;
  inserted boolean := false;
begin
  if target_environment not in (
    'xcode', 'local_testing', 'sandbox', 'production'
  )
    or length(trim(coalesce(target_notification_type, ''))) = 0
    or length(trim(coalesce(target_signed_payload_hash, ''))) = 0
  then raise exception 'transaction_mismatch'; end if;

  insert into public.apple_notification_inbox(
    notification_uuid, environment, notification_type, subtype,
    transaction_id, original_transaction_id, signed_at,
    signed_payload_hash, decoded_fields
  ) values (
    target_notification_uuid, target_environment, target_notification_type,
    nullif(trim(coalesce(target_subtype, '')), ''),
    nullif(trim(coalesce(target_transaction_id, '')), ''),
    nullif(trim(coalesce(target_original_transaction_id, '')), ''),
    target_signed_at, target_signed_payload_hash,
    coalesce(target_decoded_fields, '{}'::jsonb)
  )
  on conflict (notification_uuid) do nothing
  returning * into notification;
  inserted := notification.id is not null;

  if not inserted then
    select * into notification
    from public.apple_notification_inbox inbox
    where inbox.notification_uuid = target_notification_uuid;
    if notification.signed_payload_hash <> target_signed_payload_hash then
      raise exception 'transaction_replayed';
    end if;
  end if;

  return jsonb_build_object(
    'notification_uuid', notification.notification_uuid,
    'status', notification.status,
    'is_duplicate', not inserted
  );
end;
$$;

create or replace function public.complete_apple_notification(
  target_notification_uuid uuid,
  did_succeed boolean,
  target_error_code text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  notification public.apple_notification_inbox;
begin
  update public.apple_notification_inbox
  set status = case when did_succeed then 'processed'
        when retry_count + 1 >= 5 then 'dead_letter' else 'pending' end,
      retry_count = case when did_succeed then retry_count
        else retry_count + 1 end,
      last_error_code = case when did_succeed then null
        else nullif(trim(coalesce(target_error_code, '')), '') end,
      processed_at = case when did_succeed then statement_timestamp()
        else null end
  where notification_uuid = target_notification_uuid
  returning * into notification;
  if notification.id is null then raise exception 'notification_not_found'; end if;

  return jsonb_build_object(
    'notification_uuid', notification.notification_uuid,
    'status', notification.status,
    'retry_count', notification.retry_count
  );
end;
$$;

create or replace function public.expire_commerce_state()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  expired_intents integer;
  expired_coach_selections integer;
  expired_entitlements integer;
  expired_coach record;
begin
  update public.commerce_purchase_intents
  set status = 'expired', updated_at = statement_timestamp()
  where status in ('reserved', 'purchase_pending')
    and expires_at <= statement_timestamp();
  get diagnostics expired_intents = row_count;

  delete from private.pending_program_coach_selections
  where expires_at <= statement_timestamp();
  get diagnostics expired_coach_selections = row_count;

  expired_entitlements := 0;
  for expired_coach in
    update public.coach_access_entitlements
    set status = 'expired'
    where status = 'active' and ends_at <= statement_timestamp()
    returning coach_user_id, payment_record_id
  loop
    expired_entitlements := expired_entitlements + 1;
    update public.commerce_transactions transaction
    set status = 'expired',
        last_event_at = greatest(
          coalesce(transaction.last_event_at, '-infinity'::timestamptz),
          statement_timestamp()
        ),
        updated_at = statement_timestamp()
    where transaction.id = (
      select payment.transaction_id
      from public.coach_payment_records payment
      where payment.id = expired_coach.payment_record_id
    )
      and transaction.status = 'verified';
    perform private.refresh_coach_access_projection(
      expired_coach.coach_user_id
    );
  end loop;

  return jsonb_build_object(
    'expired_purchase_intents', expired_intents,
    'expired_coach_selections', expired_coach_selections,
    'expired_coach_entitlements', expired_entitlements
  );
end;
$$;

create or replace function public.list_my_commerce_history()
returns setof jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', transaction.id,
    'subject_kind', transaction.subject_kind,
    'program_id', transaction.program_id,
    'coach_application_id', transaction.coach_application_id,
    'provider', transaction.provider,
    'environment', transaction.environment,
    'product_id', transaction.product_id,
    'product_type', transaction.product_type,
    'status', transaction.status,
    'purchased_at', transaction.purchased_at,
    'expires_at', transaction.expires_at,
    'revocation_at', transaction.revocation_at,
    'currency_code', transaction.currency_code,
    'price_milliunits', transaction.price_milliunits
  )
  from public.commerce_transactions transaction
  where transaction.participant_id = (select auth.uid())
  order by transaction.purchased_at desc nulls last, transaction.id;
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
  ) then raise exception 'member_level_invalid'; end if;
  if length(trim(coalesce(accepted_terms_version, ''))) = 0 then
    raise exception 'terms_version_required';
  end if;

  select * into applicant from public.profiles
  where user_id = (select auth.uid()) and role = 'participant'
  for update;
  if applicant.user_id is null then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(applicant.phone_number, ''))) = 0 then
    raise exception 'profile_incomplete';
  end if;

  select * into existing from public.coach_applications
  where applicant_user_id = applicant.user_id
    and draft_idempotency_key = request_idempotency_key
  for update;
  if existing.id is not null then return existing; end if;

  select * into existing from public.coach_applications
  where applicant_user_id = applicant.user_id
    and status in ('draft', 'ineligible')
  for update;

  computed_status := case
    when member_level = 'member'
      or not applicant_has_completed_hom_sts
      or not applicant_has_completed_ict
    then 'ineligible'
    else 'draft'
  end;

  if existing.id is not null then
    update public.coach_applications
    set display_name_snapshot = applicant.display_name,
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
    insert into public.coach_applications(
      applicant_user_id, participant_profile_id, display_name_snapshot,
      phone_number_snapshot, member_level_snapshot, has_completed_hom_sts,
      has_completed_ict, terms_version, status, draft_idempotency_key
    ) values (
      applicant.user_id, applicant.user_id, applicant.display_name,
      applicant.phone_number, member_level, applicant_has_completed_hom_sts,
      applicant_has_completed_ict, trim(accepted_terms_version),
      computed_status, request_idempotency_key
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
  then return application; end if;
  if application.status in (
    'accepted_pending_payment', 'active', 'rejected', 'expired'
  ) then raise exception 'application_terminal'; end if;
  if application.member_level_snapshot = 'member'
    or not application.has_completed_hom_sts
    or not application.has_completed_ict
  then raise exception 'coach_eligibility_incomplete'; end if;

  update public.coach_applications
  set status = 'submitted',
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
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if decision not in ('approved', 'rejected') then
    raise exception 'decision_invalid';
  end if;
  if decision = 'rejected'
    and length(trim(coalesce(decision_reason, ''))) = 0
  then raise exception 'reason_required'; end if;

  select * into application
  from public.coach_applications
  where id = target_application_id
  for update;
  if application.id is null then raise exception 'application_not_found'; end if;

  if application.status in ('accepted_pending_payment', 'rejected') then
    if application.decision_idempotency_key = request_idempotency_key
      and (
        (decision = 'approved' and application.status = 'accepted_pending_payment')
        or (decision = 'rejected' and application.status = 'rejected')
      )
    then return application; end if;
    raise exception 'application_already_decided';
  end if;
  if application.status <> 'submitted' then
    raise exception 'application_not_submitted';
  end if;
  if decision = 'approved' and (
    application.member_level_snapshot = 'member'
    or not application.has_completed_hom_sts
    or not application.has_completed_ict
  ) then raise exception 'coach_eligibility_incomplete'; end if;

  update public.coach_applications
  set status = case when decision = 'approved'
        then 'accepted_pending_payment' else 'rejected' end,
      decided_at = statement_timestamp(),
      decided_by = (select auth.uid()),
      rejection_reason = case when decision = 'rejected'
        then trim(decision_reason) else null end,
      decision_idempotency_key = request_idempotency_key,
      updated_at = statement_timestamp()
  where id = application.id
  returning * into application;

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()),
    case when decision = 'approved'
      then 'coach_application_accepted'
      else 'coach_application_rejected' end,
    application.id,
    coalesce(nullif(trim(coalesce(decision_reason, '')), ''), decision),
    jsonb_build_object(
      'applicant_user_id', application.applicant_user_id,
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
  select coalesce((
    select jsonb_build_object(
      'application', to_jsonb(application),
      'payment', case when payment.id is null then null else to_jsonb(payment) end,
      'entitlement', case when entitlement.id is null then null else to_jsonb(entitlement) end,
      'is_eligible', application.member_level_snapshot <> 'member'
        and application.has_completed_hom_sts
        and application.has_completed_ict
    )
    from public.coach_applications application
    left join lateral (
      select * from public.coach_payment_records record
      where record.application_id = application.id
      order by record.period_sequence desc limit 1
    ) payment on true
    left join lateral (
      select * from public.coach_access_entitlements access
      where access.application_id = application.id
      order by access.period_sequence desc limit 1
    ) entitlement on true
    where application.applicant_user_id = (select auth.uid())
    order by application.created_at desc
    limit 1
  ), 'null'::jsonb);
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
  left join lateral (
    select * from public.coach_payment_records record
    where record.application_id = application.id
    order by record.period_sequence desc limit 1
  ) payment on true
  left join lateral (
    select * from public.coach_access_entitlements access
    where access.application_id = application.id
    order by access.period_sequence desc limit 1
  ) entitlement on true
  order by
    case application.status
      when 'submitted' then 0
      when 'accepted_pending_payment' then 1
      else 2 end,
    application.submitted_at desc nulls last,
    application.created_at desc;
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
  if caller_id is null then raise exception 'permission_denied'; end if;
  perform private.assert_recent_account_reauthentication(caller_id);

  select role into caller_role from public.profiles
  where user_id = caller_id for update;
  if caller_role is null then raise exception 'profile_not_found'; end if;
  if caller_role = 'admin' then
    raise exception 'admin_account_deletion_not_allowed';
  end if;
  if exists (select 1 from public.programs where created_by = caller_id)
    or (caller_role = 'coach' and exists (
      select 1 from public.program_enrollments where coach_id = caller_id
    ))
  then raise exception 'account_relationships_require_transfer'; end if;
  if exists (
    select 1 from storage.objects object where object.owner_id = caller_id::text
  ) then raise exception 'private_media_cleanup_required'; end if;

  update public.program_winners
  set participant_id = null, display_name = 'Akun dihapus'
  where participant_id = caller_id;
  delete from public.program_entitlements where participant_id = caller_id;
  delete from private.pending_program_coach_selections
  where account_id = caller_id;
  delete from public.commerce_purchase_intents where account_id = caller_id;
  update public.commerce_transactions
  set participant_id = null, updated_at = clock_timestamp()
  where participant_id = caller_id;
  delete from public.program_enrollments where participant_id = caller_id;
  delete from public.coach_access_entitlements
  where coach_user_id = caller_id;
  delete from public.coach_payment_records record
  using public.coach_applications application
  where record.application_id = application.id
    and application.applicant_user_id = caller_id;
  delete from public.coach_applications where applicant_user_id = caller_id;

  update public.audit_events
  set actor_id = case when actor_id = caller_id then null else actor_id end,
      subject_id = case when subject_id = caller_id then null else subject_id end,
      summary = case when actor_id = caller_id or subject_id = caller_id
          or payload ->> 'applicant_user_id' = caller_id::text
        then 'Akun dihapus' else summary end,
      payload = case when actor_id = caller_id or subject_id = caller_id
          or payload ->> 'applicant_user_id' = caller_id::text
        then '{}'::jsonb else payload end
  where actor_id = caller_id or subject_id = caller_id
    or payload ->> 'applicant_user_id' = caller_id::text;

  update public.profiles
  set display_name = 'Akun dihapus', phone_number = null, member_level = null,
      current_coach_id = null, coach_qr_identifier = null,
      coach_is_approved = false, coach_is_public = false,
      account_purpose = 'participant', onboarding_status = 'cleanup_pending',
      provisional_expires_at = clock_timestamp(), finalized_at = null,
      updated_at = clock_timestamp()
  where user_id = caller_id;
  return caller_id;
end;
$$;

revoke execute on function private.coach_price_band(text),
  private.ensure_account_commerce_token(uuid),
  private.refresh_coach_access_projection(uuid)
from public, anon, authenticated, service_role;

revoke execute on function
  public.consume_commerce_rate_limit(uuid, text),
  public.create_program_purchase_intent(uuid, uuid, text, text),
  public.create_coach_purchase_intent(uuid, text, text),
  public.mark_purchase_intent_pending(uuid, uuid),
  public.resolve_purchase_intent_for_restore(uuid, text, uuid, text),
  public.get_purchase_intent_for_verification(uuid, uuid),
  public.fulfill_apple_purchase(
    uuid, uuid, text, text, text, uuid, text, text,
    timestamptz, timestamptz, timestamptz, text, bigint
  ),
  public.reconcile_apple_commerce_event(
    text, text, text, text, timestamptz, text, jsonb
  ),
  public.record_apple_notification(
    uuid, text, text, text, text, text, timestamptz, text, jsonb
  ),
  public.complete_apple_notification(uuid, boolean, text),
  public.expire_commerce_state(),
  public.list_my_commerce_history()
from public, anon, authenticated, service_role;

grant execute on function
  public.list_my_commerce_history()
to authenticated;

grant execute on function
  public.consume_commerce_rate_limit(uuid, text),
  public.create_program_purchase_intent(uuid, uuid, text, text),
  public.create_coach_purchase_intent(uuid, text, text),
  public.mark_purchase_intent_pending(uuid, uuid),
  public.resolve_purchase_intent_for_restore(uuid, text, uuid, text),
  public.get_purchase_intent_for_verification(uuid, uuid),
  public.fulfill_apple_purchase(
    uuid, uuid, text, text, text, uuid, text, text,
    timestamptz, timestamptz, timestamptz, text, bigint
  ),
  public.reconcile_apple_commerce_event(
    text, text, text, text, timestamptz, text, jsonb
  ),
  public.record_apple_notification(
    uuid, text, text, text, text, text, timestamptz, text, jsonb
  ),
  public.complete_apple_notification(uuid, boolean, text),
  public.expire_commerce_state()
to service_role;

comment on function public.fulfill_apple_purchase(
  uuid, uuid, text, text, text, uuid, text, text,
  timestamptz, timestamptz, timestamptz, text, bigint
) is
  'Trusted Edge-only atomic fulfillment after cryptographic Apple JWS verification.';

-- Deterministic local products are intentionally distinct from future App
-- Store Connect identifiers and exist only for xcode/local_testing.
insert into public.coach_store_products(
  price_band, platform, environment, product_id, product_type,
  provisioning_status, actual_price, currency_code
)
values
  ('entry', 'app_store', 'xcode',
   'local.msc.coach.access.entry.3months',
   'non_renewing_subscription', 'ready', 100000, 'IDR'),
  ('growth', 'app_store', 'xcode',
   'local.msc.coach.access.growth.3months',
   'non_renewing_subscription', 'ready', 150000, 'IDR'),
  ('leadership', 'app_store', 'xcode',
   'local.msc.coach.access.leadership.3months',
   'non_renewing_subscription', 'ready', 200000, 'IDR');
