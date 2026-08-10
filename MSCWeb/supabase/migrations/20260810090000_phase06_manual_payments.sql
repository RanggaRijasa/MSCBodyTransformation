-- Phase 06 is additive and local-first. Apply to hosted main only during the
-- explicitly approved Phase 12 deployment gate.

create table public.payment_destinations (
  id uuid primary key default gen_random_uuid(),
  version integer not null unique check (version > 0),
  bank_code text not null check (bank_code ~ '^[A-Z0-9_]{2,24}$'),
  bank_name text not null check (length(trim(bank_name)) between 2 and 80),
  account_name text not null check (length(trim(account_name)) between 2 and 120),
  account_reference text not null check (length(trim(account_reference)) between 4 and 64),
  qris_object_path text check (
    qris_object_path is null
    or qris_object_path ~ '^destinations/[0-9a-f-]{36}/qris\.jpg$'
  ),
  effective_from timestamptz not null,
  effective_until timestamptz,
  status text not null check (status in ('scheduled', 'active', 'retired')),
  created_by uuid not null references public.profiles(user_id),
  created_at timestamptz not null default statement_timestamp(),
  unique (id, version),
  check (effective_until is null or effective_until > effective_from)
);

create table public.payment_orders (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.profiles(user_id) on delete restrict,
  purpose text not null check (purpose in ('program_enrollment', 'coach_access')),
  program_id uuid references public.programs(id) on delete restrict,
  pending_enrollment_id uuid references public.program_enrollments(id) on delete restrict,
  coach_application_id uuid references public.coach_applications(id) on delete restrict,
  coach_user_id_snapshot uuid references public.profiles(user_id) on delete restrict,
  amount_minor bigint not null check (amount_minor > 0),
  currency text not null default 'IDR' check (currency = 'IDR'),
  destination_id uuid not null references public.payment_destinations(id) on delete restrict,
  destination_version integer not null check (destination_version > 0),
  bank_code_snapshot text not null,
  bank_name_snapshot text not null,
  account_name_snapshot text not null,
  account_reference_snapshot text not null,
  qris_object_path_snapshot text,
  timezone_snapshot text not null check (
    timezone_snapshot in ('Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura')
  ),
  reserved_at timestamptz,
  reservation_expires_at timestamptz,
  evidence_submitted_at timestamptz,
  correction_expires_at timestamptz,
  retention_after timestamptz,
  status text not null check (
    status in (
      'awaiting_evidence', 'under_review', 'correction_required', 'approved',
      'expired', 'cancelled', 'rejected', 'reversal_pending', 'reversed'
    )
  ),
  latest_rejection_reason text,
  idempotency_key text not null check (length(idempotency_key) between 8 and 128),
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  unique (owner_user_id, idempotency_key),
  constraint payment_order_target_shape check (
    (purpose = 'program_enrollment' and program_id is not null
      and pending_enrollment_id is not null and coach_application_id is null
      and coach_user_id_snapshot is not null and reserved_at is not null
      and reservation_expires_at is not null)
    or
    (purpose = 'coach_access' and program_id is null
      and pending_enrollment_id is null and coach_application_id is not null
      and coach_user_id_snapshot is null)
  ),
  constraint payment_order_destination_snapshot_fk
    foreign key (destination_id, destination_version)
    references public.payment_destinations(id, version) on delete restrict
);

create unique index payment_orders_open_program_owner_idx
  on public.payment_orders(owner_user_id, program_id)
  where purpose = 'program_enrollment'
    and status in ('awaiting_evidence', 'under_review', 'correction_required', 'approved');
create unique index payment_orders_open_coach_application_idx
  on public.payment_orders(coach_application_id)
  where purpose = 'coach_access'
    and status in ('awaiting_evidence', 'under_review', 'correction_required');
create index payment_orders_owner_created_idx
  on public.payment_orders(owner_user_id, created_at desc);
create index payment_orders_admin_queue_idx
  on public.payment_orders(status, created_at, purpose);
create index payment_orders_expiry_idx
  on public.payment_orders(reservation_expires_at)
  where status = 'awaiting_evidence';

create table public.payment_evidence_attempts (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.payment_orders(id) on delete restrict,
  attempt_number integer not null check (attempt_number between 1 and 3),
  upload_idempotency_key text not null check (length(upload_idempotency_key) between 8 and 128),
  object_path text not null unique check (
    object_path ~ '^orders/[0-9a-f-]{36}/attempts/[0-9a-f-]{36}/normalized\.jpg$'
  ),
  mime_type text check (mime_type is null or mime_type = 'image/jpeg'),
  byte_size integer check (byte_size is null or byte_size between 1 and 5242880),
  pixel_width integer check (pixel_width is null or pixel_width between 1 and 1600),
  pixel_height integer check (pixel_height is null or pixel_height between 1 and 1600),
  sha256_hex text check (sha256_hex is null or sha256_hex ~ '^[0-9a-f]{64}$'),
  status text not null check (status in ('prepared', 'submitted', 'rejected', 'approved', 'deleted')),
  prepared_at timestamptz not null default statement_timestamp(),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(user_id),
  rejection_reason text,
  deleted_at timestamptz,
  unique (order_id, attempt_number),
  unique (order_id, upload_idempotency_key),
  constraint payment_evidence_submission_shape check (
    (status = 'prepared' and submitted_at is null)
    or (status in ('submitted', 'rejected', 'approved', 'deleted') and submitted_at is not null)
  ),
  constraint payment_evidence_review_shape check (
    (status = 'rejected' and reviewed_at is not null and reviewed_by is not null
      and length(trim(rejection_reason)) > 0)
    or (status = 'approved' and reviewed_at is not null and reviewed_by is not null
      and rejection_reason is null)
    or status in ('prepared', 'submitted', 'deleted')
  )
);

create index payment_evidence_order_idx
  on public.payment_evidence_attempts(order_id, attempt_number desc);

create table public.payment_ledger (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.payment_orders(id) on delete restrict,
  entry_kind text not null check (entry_kind in ('verified', 'reversal')),
  amount_minor bigint not null check (amount_minor > 0),
  currency text not null check (currency = 'IDR'),
  destination_version integer not null,
  reconciliation_reference text not null check (length(trim(reconciliation_reference)) between 4 and 128),
  verified_by uuid not null references public.profiles(user_id),
  verified_at timestamptz not null default statement_timestamp(),
  related_ledger_id uuid references public.payment_ledger(id) on delete restrict,
  resolution_due_at timestamptz,
  resolution_note text,
  unique (order_id, entry_kind),
  constraint payment_ledger_reversal_shape check (
    (entry_kind = 'verified' and related_ledger_id is null and resolution_due_at is null)
    or (entry_kind = 'reversal' and related_ledger_id is not null
      and resolution_due_at is not null and length(trim(resolution_note)) > 0)
  )
);

create table public.payment_events (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.payment_orders(id) on delete restrict,
  attempt_id uuid references public.payment_evidence_attempts(id) on delete restrict,
  actor_id uuid references public.profiles(user_id) on delete set null,
  event_type text not null check (
    event_type in (
      'order_created', 'reservation_expired', 'reservation_restored',
      'upload_intent_created', 'evidence_submitted', 'evidence_rejected',
      'payment_approved', 'order_cancelled', 'reversal_required',
      'reversal_recorded', 'entitlement_projected', 'enrollment_projected',
      'evidence_deleted'
    )
  ),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default statement_timestamp(),
  check (jsonb_typeof(metadata) = 'object'),
  check (octet_length(metadata::text) <= 4096)
);

create index payment_events_order_idx on public.payment_events(order_id, id);

create or replace function private.reject_payment_event_mutation()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE'
    and old.actor_id is not null and new.actor_id is null
    and new.id = old.id
    and new.order_id = old.order_id
    and new.attempt_id is not distinct from old.attempt_id
    and new.event_type = old.event_type
    and new.metadata = old.metadata
    and new.created_at = old.created_at
  then
    return new;
  end if;
  raise exception 'payment_events_are_immutable';
end;
$$;

create trigger payment_events_no_update_or_delete
before update or delete on public.payment_events
for each row execute function private.reject_payment_event_mutation();

create or replace function private.reject_payment_ledger_mutation()
returns trigger language plpgsql set search_path = '' as $$
begin
  raise exception 'payment_ledger_is_immutable';
end;
$$;

create trigger payment_ledger_no_update_or_delete
before update or delete on public.payment_ledger
for each row execute function private.reject_payment_ledger_mutation();

create or replace function private.prevent_submitted_evidence_rewrite()
returns trigger language plpgsql set search_path = '' as $$
begin
  if old.submitted_at is not null and (
    new.order_id is distinct from old.order_id
    or new.attempt_number is distinct from old.attempt_number
    or new.object_path is distinct from old.object_path
    or new.mime_type is distinct from old.mime_type
    or new.byte_size is distinct from old.byte_size
    or new.pixel_width is distinct from old.pixel_width
    or new.pixel_height is distinct from old.pixel_height
    or new.sha256_hex is distinct from old.sha256_hex
    or new.submitted_at is distinct from old.submitted_at
  ) then
    raise exception 'submitted_evidence_is_immutable';
  end if;
  return new;
end;
$$;

create trigger payment_evidence_immutable_content
before update on public.payment_evidence_attempts
for each row execute function private.prevent_submitted_evidence_rewrite();

alter table public.payment_destinations enable row level security;
alter table public.payment_orders enable row level security;
alter table public.payment_evidence_attempts enable row level security;
alter table public.payment_ledger enable row level security;
alter table public.payment_events enable row level security;

revoke all on table public.payment_destinations, public.payment_orders,
  public.payment_evidence_attempts, public.payment_ledger, public.payment_events
from anon, authenticated;
grant select on table public.payment_orders, public.payment_evidence_attempts
to authenticated;
grant select on table public.payment_destinations, public.payment_ledger,
  public.payment_events to authenticated;
grant all on table public.payment_destinations, public.payment_orders,
  public.payment_evidence_attempts, public.payment_ledger, public.payment_events
to service_role;
grant usage, select on sequence public.payment_events_id_seq to service_role;

create policy "owner or admin reads payment orders"
on public.payment_orders for select to authenticated
using (owner_user_id = (select auth.uid()) or private.is_admin());

create policy "owner or admin reads payment evidence metadata"
on public.payment_evidence_attempts for select to authenticated
using (
  private.is_admin()
  or exists (
    select 1 from public.payment_orders payment_order
    where payment_order.id = order_id
      and payment_order.owner_user_id = (select auth.uid())
  )
);

create policy "owner or admin reads destination snapshot source"
on public.payment_destinations for select to authenticated
using (
  private.is_admin()
  or exists (
    select 1 from public.payment_orders payment_order
    where payment_order.destination_id = id
      and payment_order.owner_user_id = (select auth.uid())
  )
);

create policy "admin reads verified payment ledger"
on public.payment_ledger for select to authenticated using (private.is_admin());
create policy "admin reads payment events"
on public.payment_events for select to authenticated using (private.is_admin());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('payment-evidence', 'payment-evidence', false, 5242880, array['image/jpeg'])
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'payment-destination-assets', 'payment-destination-assets', false, 5242880,
  array['image/jpeg']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.create_payment_destination(
  destination_bank_code text,
  destination_bank_name text,
  destination_account_name text,
  destination_account_reference text,
  effective_at timestamptz,
  destination_qris_object_path text default null
)
returns public.payment_destinations
language plpgsql security definer set search_path = '' as $$
declare
  result public.payment_destinations;
  next_version integer;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if effective_at < statement_timestamp() - interval '5 minutes' then
    raise exception 'effective_time_invalid';
  end if;
  if destination_qris_object_path is not null and not exists (
    select 1
    from storage.objects object
    where object.bucket_id = 'payment-destination-assets'
      and object.name = destination_qris_object_path
  ) then
    raise exception 'qris_asset_not_found';
  end if;
  perform pg_advisory_xact_lock(hashtext('payment_destination'));
  select coalesce(max(version), 0) + 1 into next_version
  from public.payment_destinations;
  update public.payment_destinations
  set effective_until = effective_at,
      status = case when effective_at <= statement_timestamp() then 'retired' else status end
  where effective_until is null and effective_from < effective_at;
  insert into public.payment_destinations(
    version, bank_code, bank_name, account_name, account_reference,
    qris_object_path, effective_from, status, created_by
  ) values (
    next_version, upper(trim(destination_bank_code)), trim(destination_bank_name),
    trim(destination_account_name), trim(destination_account_reference),
    destination_qris_object_path, effective_at,
    case when effective_at <= statement_timestamp() then 'active' else 'scheduled' end,
    (select auth.uid())
  ) returning * into result;
  return result;
end;
$$;

create or replace function private.current_payment_destination()
returns public.payment_destinations
language sql stable security definer set search_path = '' as $$
  select destination
  from public.payment_destinations destination
  where destination.effective_from <= statement_timestamp()
    and (destination.effective_until is null
      or destination.effective_until > statement_timestamp())
    and destination.status in ('active', 'scheduled')
  order by destination.version desc
  limit 1;
$$;

create or replace function public.create_program_payment_order(
  target_program_id uuid,
  coach_qr_payload text,
  request_idempotency_key text
)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor_id uuid := (select auth.uid());
  target_program public.programs;
  target_coach public.profiles;
  actor_profile public.profiles;
  destination public.payment_destinations;
  enrollment public.program_enrollments;
  existing public.payment_orders;
  result public.payment_orders;
  occupied integer;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if actor_id is null then raise exception 'authentication_required'; end if;
  select * into existing from public.payment_orders
  where owner_user_id = actor_id and idempotency_key = request_idempotency_key;
  if existing.id is not null then
    if existing.program_id is distinct from target_program_id then
      raise exception 'idempotency_conflict';
    end if;
    return jsonb_build_object('order_id', existing.id, 'amount_minor', existing.amount_minor,
      'currency', existing.currency, 'status', existing.status,
      'reservation_expires_at', existing.reservation_expires_at);
  end if;
  select * into actor_profile from public.profiles where user_id = actor_id for update;
  if actor_profile.user_id is null or actor_profile.role <> 'participant' then
    raise exception 'permission_denied';
  end if;
  select * into target_program from public.programs
  where id = target_program_id for update;
  if target_program.id is null or target_program.status not in ('scheduled', 'active')
    or target_program.published_at is null or target_program.pricing_mode <> 'paid' then
    raise exception 'program_unavailable';
  end if;
  if target_program.registration_closes_at is not null
    and statement_timestamp() >= target_program.registration_closes_at then
    raise exception 'registration_closed';
  end if;
  select * into target_coach from public.profiles
  where coach_qr_identifier = coach_qr_payload and role = 'coach'
    and coach_is_approved and private.has_active_coach_access(user_id);
  if target_coach.user_id is null then raise exception 'coach_invalid'; end if;
  if actor_profile.current_coach_id is not null
    and actor_profile.current_coach_id <> target_coach.user_id then
    raise exception 'coach_mismatch';
  end if;
  select * into destination from private.current_payment_destination();
  if destination.id is null then raise exception 'payment_destination_unavailable'; end if;
  select count(*) into occupied from public.program_enrollments
  where program_id = target_program.id and status in ('waiting_for_payment', 'active', 'completed');
  if target_program.participant_limit is not null and occupied >= target_program.participant_limit then
    raise exception 'program_full';
  end if;
  select * into enrollment from public.program_enrollments
  where program_id = target_program.id and participant_id = actor_id for update;
  if enrollment.status in ('active', 'completed') then raise exception 'already_enrolled'; end if;
  if enrollment.id is null then
    insert into public.program_enrollments(program_id, participant_id, coach_id, status)
    values (target_program.id, actor_id, target_coach.user_id, 'waiting_for_payment')
    returning * into enrollment;
  else
    update public.program_enrollments set coach_id = target_coach.user_id,
      status = 'waiting_for_payment', enrolled_at = statement_timestamp(), completed_at = null
    where id = enrollment.id returning * into enrollment;
  end if;
  insert into public.payment_orders(
    owner_user_id, purpose, program_id, pending_enrollment_id,
    coach_user_id_snapshot, amount_minor, destination_id, destination_version,
    bank_code_snapshot, bank_name_snapshot, account_name_snapshot,
    account_reference_snapshot, qris_object_path_snapshot, reserved_at,
    reservation_expires_at, retention_after, timezone_snapshot, status, idempotency_key
  ) values (
    actor_id, 'program_enrollment', target_program.id, enrollment.id,
    target_coach.user_id, round(target_program.desired_price)::bigint,
    destination.id, destination.version, destination.bank_code, destination.bank_name,
    destination.account_name, destination.account_reference, destination.qris_object_path,
    statement_timestamp(), statement_timestamp() + interval '24 hours',
    ((target_program.ends_on + 30)::timestamp at time zone target_program.timezone),
    target_program.timezone,
    'awaiting_evidence', request_idempotency_key
  ) returning * into result;
  insert into public.payment_events(order_id, actor_id, event_type)
  values (result.id, actor_id, 'order_created');
  return jsonb_build_object('order_id', result.id, 'amount_minor', result.amount_minor,
    'currency', result.currency, 'status', result.status,
    'reservation_expires_at', result.reservation_expires_at);
end;
$$;

create or replace function public.create_coach_payment_order(
  target_application_id uuid,
  request_idempotency_key text
)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor_id uuid := (select auth.uid());
  application public.coach_applications;
  destination public.payment_destinations;
  existing public.payment_orders;
  result public.payment_orders;
  amount bigint;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  select * into existing from public.payment_orders
  where owner_user_id = actor_id and idempotency_key = request_idempotency_key;
  if existing.id is not null then
    if existing.coach_application_id is distinct from target_application_id then
      raise exception 'idempotency_conflict';
    end if;
    return jsonb_build_object('order_id', existing.id, 'amount_minor', existing.amount_minor,
      'currency', existing.currency, 'status', existing.status);
  end if;
  select * into application from public.coach_applications
  where id = target_application_id and applicant_user_id = actor_id for update;
  if application.id is null
    or application.status not in ('accepted_pending_payment', 'active', 'expired') then
    raise exception 'application_not_eligible';
  end if;
  amount := case
    when application.member_level_snapshot in ('sc', 'sb') then 100000
    when application.member_level_snapshot in ('supervisor', 'world_team') then 150000
    when application.member_level_snapshot in (
      'tab_team', 'get_team', 'millionaire_team', 'presidents_team') then 200000
    else null end;
  if amount is null then raise exception 'application_not_eligible'; end if;
  select * into destination from private.current_payment_destination();
  if destination.id is null then raise exception 'payment_destination_unavailable'; end if;
  insert into public.payment_orders(
    owner_user_id, purpose, coach_application_id, amount_minor, destination_id,
    destination_version, bank_code_snapshot, bank_name_snapshot,
    account_name_snapshot, account_reference_snapshot, qris_object_path_snapshot,
    retention_after, timezone_snapshot, status, idempotency_key
  ) values (
    actor_id, 'coach_access', application.id, amount, destination.id,
    destination.version, destination.bank_code, destination.bank_name,
    destination.account_name, destination.account_reference, destination.qris_object_path,
    statement_timestamp() + interval '4 months', 'Asia/Jakarta',
    'awaiting_evidence', request_idempotency_key
  ) returning * into result;
  insert into public.payment_events(order_id, actor_id, event_type)
  values (result.id, actor_id, 'order_created');
  return jsonb_build_object('order_id', result.id, 'amount_minor', result.amount_minor,
    'currency', result.currency, 'status', result.status);
end;
$$;

create or replace function public.prepare_payment_evidence_attempt(
  target_order_id uuid,
  request_idempotency_key text
)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor_id uuid := (select auth.uid());
  target_order public.payment_orders;
  existing public.payment_evidence_attempts;
  result public.payment_evidence_attempts;
  next_attempt integer;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  select * into target_order from public.payment_orders
  where id = target_order_id and owner_user_id = actor_id for update;
  if target_order.id is null then raise exception 'payment_order_not_found'; end if;
  select * into existing from public.payment_evidence_attempts
  where order_id = target_order.id and upload_idempotency_key = request_idempotency_key;
  if existing.id is not null then
    return jsonb_build_object('attempt_id', existing.id, 'object_path', existing.object_path,
      'attempt_number', existing.attempt_number);
  end if;
  if target_order.status not in ('awaiting_evidence', 'correction_required') then
    raise exception 'payment_order_not_uploadable';
  end if;
  if target_order.status = 'awaiting_evidence'
    and target_order.purpose = 'program_enrollment'
    and statement_timestamp() >= target_order.reservation_expires_at then
    raise exception 'payment_order_expired';
  end if;
  if target_order.status = 'correction_required'
    and statement_timestamp() >= target_order.correction_expires_at then
    raise exception 'correction_window_expired';
  end if;
  select coalesce(max(attempt_number), 0) + 1 into next_attempt
  from public.payment_evidence_attempts where order_id = target_order.id;
  if next_attempt > 3 then raise exception 'evidence_attempt_limit'; end if;
  result.id := gen_random_uuid();
  insert into public.payment_evidence_attempts(
    id, order_id, attempt_number, upload_idempotency_key, object_path, status
  ) values (
    result.id, target_order.id, next_attempt, request_idempotency_key,
    'orders/' || target_order.id || '/attempts/' || result.id || '/normalized.jpg', 'prepared'
  ) returning * into result;
  insert into public.payment_events(order_id, attempt_id, actor_id, event_type)
  values (target_order.id, result.id, actor_id, 'upload_intent_created');
  return jsonb_build_object('attempt_id', result.id, 'object_path', result.object_path,
    'attempt_number', result.attempt_number);
end;
$$;

create or replace function public.submit_payment_evidence(
  target_attempt_id uuid,
  content_sha256_hex text,
  content_byte_size integer,
  content_pixel_width integer,
  content_pixel_height integer,
  submitting_owner_user_id uuid
)
returns public.payment_orders
language plpgsql security definer set search_path = '' as $$
declare
  actor_id uuid := submitting_owner_user_id;
  attempt public.payment_evidence_attempts;
  target_order public.payment_orders;
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role'
    or actor_id is null then
    raise exception 'permission_denied';
  end if;
  select evidence.* into attempt from public.payment_evidence_attempts evidence
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
  if content_sha256_hex !~ '^[0-9a-f]{64}$' or content_byte_size not between 1 and 5242880
    or content_pixel_width not between 1 and 1600
    or content_pixel_height not between 1 and 1600 then
    raise exception 'evidence_validation_failed';
  end if;
  if not exists (
    select 1 from storage.objects object
    where object.bucket_id = 'payment-evidence' and object.name = attempt.object_path
  ) then raise exception 'evidence_object_missing'; end if;
  if target_order.status = 'awaiting_evidence'
    and target_order.purpose = 'program_enrollment'
    and statement_timestamp() >= target_order.reservation_expires_at then
    raise exception 'payment_order_expired';
  end if;
  if target_order.status = 'correction_required'
    and statement_timestamp() >= target_order.correction_expires_at then
    raise exception 'correction_window_expired';
  end if;
  update public.payment_evidence_attempts set
    mime_type = 'image/jpeg', byte_size = content_byte_size,
    pixel_width = content_pixel_width, pixel_height = content_pixel_height,
    sha256_hex = content_sha256_hex, status = 'submitted',
    submitted_at = statement_timestamp()
  where id = attempt.id;
  update public.payment_orders set status = 'under_review',
    evidence_submitted_at = statement_timestamp(), correction_expires_at = null,
    latest_rejection_reason = null, version = version + 1,
    updated_at = statement_timestamp()
  where id = target_order.id returning * into target_order;
  insert into public.payment_events(order_id, attempt_id, actor_id, event_type)
  values (target_order.id, attempt.id, actor_id, 'evidence_submitted');
  return target_order;
end;
$$;

create or replace function public.reject_payment_evidence(
  target_order_id uuid,
  expected_version integer,
  rejection_reason text
)
returns public.payment_orders
language plpgsql security definer set search_path = '' as $$
declare
  target_order public.payment_orders;
  attempt public.payment_evidence_attempts;
  normalized_reason text := trim(rejection_reason);
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(coalesce(normalized_reason, '')) < 5 then raise exception 'reason_required'; end if;
  select * into target_order from public.payment_orders where id = target_order_id for update;
  if target_order.id is null then raise exception 'payment_order_not_found'; end if;
  if target_order.version <> expected_version then raise exception 'version_conflict'; end if;
  if target_order.status <> 'under_review' then raise exception 'payment_order_not_reviewable'; end if;
  select * into attempt from public.payment_evidence_attempts
  where order_id = target_order.id and status = 'submitted'
  order by attempt_number desc limit 1 for update;
  if attempt.id is null then raise exception 'payment_evidence_not_found'; end if;
  update public.payment_evidence_attempts set status = 'rejected',
    reviewed_at = statement_timestamp(), reviewed_by = (select auth.uid()),
    rejection_reason = normalized_reason where id = attempt.id;
  update public.payment_orders set status = 'correction_required',
    correction_expires_at = statement_timestamp() + interval '24 hours',
    latest_rejection_reason = normalized_reason, version = version + 1,
    updated_at = statement_timestamp()
  where id = target_order.id returning * into target_order;
  insert into public.payment_events(order_id, attempt_id, actor_id, event_type)
  values (target_order.id, attempt.id, (select auth.uid()), 'evidence_rejected');
  return target_order;
end;
$$;

create or replace function public.approve_payment_order(
  target_order_id uuid,
  expected_version integer,
  reconciled_amount_minor bigint,
  reconciliation_reference text,
  destination_matches boolean
)
returns public.payment_orders
language plpgsql security definer set search_path = '' as $$
declare
  reviewer uuid := (select auth.uid());
  target_order public.payment_orders;
  attempt public.payment_evidence_attempts;
  application public.coach_applications;
  existing_entitlement public.coach_access_entitlements;
  payment_record_id uuid;
  entitlement_id uuid;
  access_start timestamptz;
  access_end timestamptz;
  next_period integer;
  target_program public.programs;
  occupied integer;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reconciliation_reference, ''))) < 4
    or not destination_matches then raise exception 'reconciliation_required'; end if;
  select * into target_order from public.payment_orders where id = target_order_id for update;
  if target_order.id is null then raise exception 'payment_order_not_found'; end if;
  if target_order.status = 'approved' then return target_order; end if;
  if target_order.version <> expected_version then raise exception 'version_conflict'; end if;
  if target_order.status <> 'under_review' then raise exception 'payment_order_not_reviewable'; end if;
  if reconciled_amount_minor <> target_order.amount_minor then raise exception 'amount_mismatch'; end if;
  select * into attempt from public.payment_evidence_attempts
  where order_id = target_order.id and status = 'submitted'
  order by attempt_number desc limit 1 for update;
  if attempt.id is null then raise exception 'payment_evidence_not_found'; end if;
  if target_order.purpose = 'program_enrollment' then
    select * into target_program from public.programs where id = target_order.program_id for update;
    select count(*) into occupied from public.program_enrollments
      where program_id = target_order.program_id and status in ('active', 'completed');
    if target_program.participant_limit is not null and occupied >= target_program.participant_limit then
      raise exception 'program_full';
    end if;
    update public.program_enrollments set status = 'active',
      coach_id = target_order.coach_user_id_snapshot, enrolled_at = statement_timestamp()
    where id = target_order.pending_enrollment_id;
    insert into public.program_scores(enrollment_id)
    values (target_order.pending_enrollment_id) on conflict (enrollment_id) do nothing;
    update public.profiles set current_coach_id = coalesce(current_coach_id,
      target_order.coach_user_id_snapshot), updated_at = statement_timestamp()
    where user_id = target_order.owner_user_id;
    insert into public.payment_events(order_id, actor_id, event_type)
    values (target_order.id, reviewer, 'enrollment_projected');
  else
    select * into application from public.coach_applications
    where id = target_order.coach_application_id for update;
    if application.status not in ('accepted_pending_payment', 'active', 'expired') then
      raise exception 'application_not_eligible';
    end if;
    select * into existing_entitlement from public.coach_access_entitlements
    where coach_user_id = target_order.owner_user_id and status = 'active'
    order by ends_at desc limit 1 for update;
    access_start := greatest(statement_timestamp(), coalesce(existing_entitlement.ends_at,
      statement_timestamp()));
    access_end := access_start + interval '3 months';
    select coalesce(max(period_sequence), 0) + 1 into next_period
    from public.coach_payment_records where application_id = application.id;
    payment_record_id := gen_random_uuid();
    insert into public.coach_payment_records(
      id, application_id, state, price_band, amount_minor_units,
      duration_months, provider_reference, verified_at, period_sequence
    ) values (
      payment_record_id, application.id, 'verified',
      case when target_order.amount_minor = 100000 then 'entry'
        when target_order.amount_minor = 150000 then 'growth' else 'leadership' end,
      target_order.amount_minor, 3, trim(reconciliation_reference), statement_timestamp(), next_period
    );
    entitlement_id := gen_random_uuid();
    insert into public.coach_access_entitlements(
      id, application_id, payment_record_id, coach_user_id, status, starts_at, ends_at,
      period_sequence, supersedes_entitlement_id
    ) values (
      entitlement_id, application.id, payment_record_id, target_order.owner_user_id,
      case when access_start > statement_timestamp() then 'pending_activation' else 'active' end,
      access_start, access_end, next_period, existing_entitlement.id
    );
    update public.coach_applications set status = 'active', decided_at = statement_timestamp(),
      decided_by = reviewer, rejection_reason = null, updated_at = statement_timestamp()
    where id = application.id;
    update public.profiles set role = 'coach', coach_is_approved = true,
      coach_qr_identifier = coalesce(coach_qr_identifier,
        encode(extensions.gen_random_bytes(24), 'hex')), updated_at = statement_timestamp()
    where user_id = target_order.owner_user_id;
    update public.payment_orders set retention_after = access_end + interval '30 days'
    where id = target_order.id;
    insert into public.payment_events(order_id, actor_id, event_type)
    values (target_order.id, reviewer, 'entitlement_projected');
  end if;
  insert into public.payment_ledger(
    order_id, entry_kind, amount_minor, currency, destination_version,
    reconciliation_reference, verified_by
  ) values (
    target_order.id, 'verified', target_order.amount_minor, target_order.currency,
    target_order.destination_version, trim(reconciliation_reference), reviewer
  );
  update public.payment_evidence_attempts set status = 'approved',
    reviewed_at = statement_timestamp(), reviewed_by = reviewer, rejection_reason = null
  where id = attempt.id;
  update public.payment_orders set status = 'approved', version = version + 1,
    latest_rejection_reason = null, updated_at = statement_timestamp()
  where id = target_order.id returning * into target_order;
  insert into public.payment_events(order_id, attempt_id, actor_id, event_type)
  values (target_order.id, attempt.id, reviewer, 'payment_approved');
  return target_order;
end;
$$;

create or replace function public.expire_payment_orders()
returns integer language plpgsql security definer set search_path = '' as $$
declare affected integer;
begin
  if not (private.is_admin() or (select auth.role()) = 'service_role') then
    raise exception 'permission_denied';
  end if;
  with expired as (
    update public.payment_orders set status = 'expired', version = version + 1,
      updated_at = statement_timestamp()
    where status = 'awaiting_evidence' and purpose = 'program_enrollment'
      and reservation_expires_at <= statement_timestamp()
      and evidence_submitted_at is null
    returning id, pending_enrollment_id
  ), cancelled as (
    update public.program_enrollments enrollment set status = 'cancelled'
    from expired where enrollment.id = expired.pending_enrollment_id returning expired.id
  )
  insert into public.payment_events(order_id, actor_id, event_type)
  select id, (select auth.uid()), 'reservation_expired' from expired;
  get diagnostics affected = row_count;
  return affected;
end;
$$;

create or replace function public.restore_expired_payment_order(
  target_order_id uuid,
  expected_version integer
)
returns public.payment_orders
language plpgsql security definer set search_path = '' as $$
declare target_order public.payment_orders; target_program public.programs; occupied integer;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  select * into target_order from public.payment_orders where id = target_order_id for update;
  if target_order.status <> 'expired' or target_order.version <> expected_version
    or target_order.purpose <> 'program_enrollment' then raise exception 'restore_conflict'; end if;
  select * into target_program from public.programs where id = target_order.program_id for update;
  select count(*) into occupied from public.program_enrollments
    where program_id = target_program.id and status in ('active', 'completed', 'waiting_for_payment');
  if target_program.participant_limit is not null and occupied >= target_program.participant_limit then
    raise exception 'program_full';
  end if;
  update public.program_enrollments set status = 'waiting_for_payment'
  where id = target_order.pending_enrollment_id;
  update public.payment_orders set status = 'correction_required',
    correction_expires_at = statement_timestamp() + interval '24 hours',
    reservation_expires_at = statement_timestamp() + interval '24 hours',
    version = version + 1, updated_at = statement_timestamp()
  where id = target_order.id returning * into target_order;
  insert into public.payment_events(order_id, actor_id, event_type)
  values (target_order.id, (select auth.uid()), 'reservation_restored');
  return target_order;
end;
$$;

create or replace function public.cancel_payment_order(target_order_id uuid)
returns public.payment_orders
language plpgsql security definer set search_path = '' as $$
declare target_order public.payment_orders;
begin
  select * into target_order from public.payment_orders where id = target_order_id for update;
  if target_order.id is null
    or not (target_order.owner_user_id = (select auth.uid()) or private.is_admin()) then
    raise exception 'permission_denied';
  end if;
  if target_order.status = 'cancelled' then return target_order; end if;
  if target_order.status not in ('awaiting_evidence', 'correction_required', 'expired') then
    raise exception 'payment_order_not_cancellable';
  end if;
  update public.payment_orders set status = 'cancelled', version = version + 1,
    updated_at = statement_timestamp() where id = target_order.id returning * into target_order;
  if target_order.pending_enrollment_id is not null then
    update public.program_enrollments set status = 'cancelled'
    where id = target_order.pending_enrollment_id and status = 'waiting_for_payment';
  end if;
  insert into public.payment_events(order_id, actor_id, event_type)
  values (target_order.id, (select auth.uid()), 'order_cancelled');
  return target_order;
end;
$$;

create or replace function public.record_exceptional_reversal(
  target_order_id uuid,
  reconciliation_reference text,
  resolution_note text,
  mark_completed boolean default false
)
returns public.payment_orders
language plpgsql security definer set search_path = '' as $$
declare target_order public.payment_orders; verified_entry public.payment_ledger;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reconciliation_reference, ''))) < 4
    or length(trim(coalesce(resolution_note, ''))) < 5 then raise exception 'reason_required'; end if;
  select * into target_order from public.payment_orders where id = target_order_id for update;
  select * into verified_entry from public.payment_ledger
    where order_id = target_order.id and entry_kind = 'verified';
  if target_order.id is null or verified_entry.id is null then raise exception 'verified_payment_required'; end if;
  if exists (select 1 from public.payment_ledger where order_id = target_order.id and entry_kind = 'reversal') then
    return target_order;
  end if;
  insert into public.payment_ledger(
    order_id, entry_kind, amount_minor, currency, destination_version,
    reconciliation_reference, verified_by, related_ledger_id,
    resolution_due_at, resolution_note
  ) values (
    target_order.id, 'reversal', target_order.amount_minor, target_order.currency,
    target_order.destination_version, trim(reconciliation_reference), (select auth.uid()),
    verified_entry.id, statement_timestamp() + interval '7 days', trim(resolution_note)
  );
  update public.payment_orders set status = case when mark_completed then 'reversed'
    else 'reversal_pending' end, version = version + 1, updated_at = statement_timestamp()
  where id = target_order.id returning * into target_order;
  insert into public.payment_events(order_id, actor_id, event_type, metadata)
  values (target_order.id, (select auth.uid()),
    case when mark_completed then 'reversal_recorded' else 'reversal_required' end,
    jsonb_build_object('resolution', case when mark_completed then 'completed' else 'pending' end));
  return target_order;
end;
$$;

create or replace function public.cleanup_expired_payment_evidence()
returns integer language plpgsql security definer set search_path = '' as $$
declare affected integer;
begin
  if not (private.is_admin() or (select auth.role()) = 'service_role') then
    raise exception 'permission_denied';
  end if;
  with due as (
    select evidence.id, evidence.order_id
    from public.payment_evidence_attempts evidence
    join public.payment_orders payment_order on payment_order.id = evidence.order_id
    where payment_order.retention_after <= statement_timestamp()
      and evidence.status <> 'deleted'
      and not exists (
        select 1 from storage.objects object
        where object.bucket_id = 'payment-evidence'
          and object.name = evidence.object_path
      )
  ), marked as (
    update public.payment_evidence_attempts evidence set status = 'deleted',
      deleted_at = statement_timestamp() from due where evidence.id = due.id
    returning evidence.order_id, evidence.id
  )
  insert into public.payment_events(order_id, attempt_id, actor_id, event_type)
  select order_id, id, (select auth.uid()), 'evidence_deleted' from marked;
  get diagnostics affected = row_count;
  return affected;
end;
$$;

-- Account deletion preserves the minimal order/ledger/event audit record and
-- its retained evidence while allowing personal profile relationships to be
-- removed by the existing delete-account workflow. Server operations are the
-- only writers, so nullable historical projections cannot be client-forged.
alter table public.payment_orders
  alter column owner_user_id drop not null,
  drop constraint payment_orders_owner_user_id_fkey,
  add constraint payment_orders_owner_user_id_fkey
    foreign key (owner_user_id) references public.profiles(user_id) on delete set null,
  drop constraint payment_orders_pending_enrollment_id_fkey,
  add constraint payment_orders_pending_enrollment_id_fkey
    foreign key (pending_enrollment_id) references public.program_enrollments(id) on delete set null,
  drop constraint payment_orders_coach_application_id_fkey,
  add constraint payment_orders_coach_application_id_fkey
    foreign key (coach_application_id) references public.coach_applications(id) on delete set null,
  drop constraint payment_orders_coach_user_id_snapshot_fkey,
  add constraint payment_orders_coach_user_id_snapshot_fkey
    foreign key (coach_user_id_snapshot) references public.profiles(user_id) on delete set null,
  drop constraint payment_order_target_shape,
  add constraint payment_order_target_shape check (
    (purpose = 'program_enrollment' and program_id is not null
      and coach_application_id is null and reserved_at is not null
      and reservation_expires_at is not null)
    or
    (purpose = 'coach_access' and program_id is null
      and pending_enrollment_id is null and coach_user_id_snapshot is null)
  );

revoke all on function public.create_payment_destination(text, text, text, text, timestamptz, text),
  public.create_program_payment_order(uuid, text, text),
  public.create_coach_payment_order(uuid, text),
  public.prepare_payment_evidence_attempt(uuid, text),
  public.submit_payment_evidence(uuid, text, integer, integer, integer, uuid),
  public.reject_payment_evidence(uuid, integer, text),
  public.approve_payment_order(uuid, integer, bigint, text, boolean),
  public.expire_payment_orders(), public.restore_expired_payment_order(uuid, integer),
  public.cancel_payment_order(uuid),
  public.record_exceptional_reversal(uuid, text, text, boolean),
  public.cleanup_expired_payment_evidence()
from public, anon, authenticated;

grant execute on function public.create_payment_destination(text, text, text, text, timestamptz, text),
  public.create_program_payment_order(uuid, text, text),
  public.create_coach_payment_order(uuid, text),
  public.prepare_payment_evidence_attempt(uuid, text),
  public.submit_payment_evidence(uuid, text, integer, integer, integer, uuid),
  public.reject_payment_evidence(uuid, integer, text),
  public.approve_payment_order(uuid, integer, bigint, text, boolean),
  public.expire_payment_orders(), public.restore_expired_payment_order(uuid, integer),
  public.cancel_payment_order(uuid),
  public.record_exceptional_reversal(uuid, text, text, boolean),
  public.cleanup_expired_payment_evidence()
to authenticated, service_role;

revoke execute on function public.submit_payment_evidence(uuid, text, integer, integer, integer, uuid),
  public.expire_payment_orders(),
  public.cleanup_expired_payment_evidence()
from authenticated;

revoke all on function private.current_payment_destination() from public, anon, authenticated;
