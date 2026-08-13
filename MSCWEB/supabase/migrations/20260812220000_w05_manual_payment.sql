-- MSCWEB W05 manual payment authority.
-- Applies after the shared Phase 11/12 schema and only targets local Supabase
-- until a separate hosted-production authorization is granted.

create table if not exists public.payment_destinations (
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
  instructions text not null default 'Ikuti petunjuk pembayaran yang tampil pada pesanan.',
  effective_from timestamptz not null,
  effective_until timestamptz,
  status text not null check (status in ('scheduled', 'active', 'retired')),
  created_by uuid not null references public.profiles(user_id),
  created_at timestamptz not null default statement_timestamp(),
  unique (id, version),
  check (effective_until is null or effective_until > effective_from)
);

alter table public.payment_destinations
  add column if not exists instructions text not null
    default 'Ikuti petunjuk pembayaran yang tampil pada pesanan.';

create table if not exists public.payment_orders (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references public.profiles(user_id) on delete set null,
  purpose text not null check (purpose in ('program_enrollment', 'coach_access')),
  program_id uuid references public.programs(id) on delete restrict,
  pending_enrollment_id uuid references public.program_enrollments(id) on delete set null,
  coach_application_id uuid references public.coach_applications(id) on delete set null,
  coach_user_id_snapshot uuid references public.profiles(user_id) on delete set null,
  amount_minor bigint not null check (amount_minor > 0),
  currency text not null default 'IDR' check (currency = 'IDR'),
  declared_method text not null default 'bank_transfer'
    check (declared_method in ('bank_transfer', 'static_qris')),
  destination_id uuid not null references public.payment_destinations(id) on delete restrict,
  destination_version integer not null check (destination_version > 0),
  bank_code_snapshot text not null,
  bank_name_snapshot text not null,
  account_name_snapshot text not null,
  account_reference_snapshot text not null,
  qris_object_path_snapshot text,
  instructions_snapshot text not null,
  timezone_snapshot text not null
    check (timezone_snapshot in ('Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura')),
  reserved_at timestamptz,
  reservation_expires_at timestamptz,
  evidence_submitted_at timestamptz,
  correction_expires_at timestamptz,
  retention_after timestamptz,
  status text not null check (status in (
    'awaiting_evidence', 'under_review', 'correction_required', 'approved',
    'expired', 'cancelled', 'rejected', 'reversal_pending', 'reversed'
  )),
  latest_rejection_reason text,
  idempotency_key text not null check (length(idempotency_key) between 8 and 128),
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  unique (owner_user_id, idempotency_key),
  foreign key (destination_id, destination_version)
    references public.payment_destinations(id, version) on delete restrict,
  check (
    (purpose = 'program_enrollment' and program_id is not null
      and coach_application_id is null and reserved_at is not null
      and reservation_expires_at is not null)
    or
    (purpose = 'coach_access' and program_id is null
      and pending_enrollment_id is null and coach_user_id_snapshot is null)
  )
);

alter table public.payment_orders
  add column if not exists declared_method text not null default 'bank_transfer',
  add column if not exists instructions_snapshot text not null
    default 'Ikuti petunjuk pembayaran yang tampil pada pesanan.';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.payment_orders'::regclass
      and conname = 'payment_orders_declared_method_check'
  ) then
    alter table public.payment_orders
      add constraint payment_orders_declared_method_check
      check (declared_method in ('bank_transfer', 'static_qris'));
  end if;
end;
$$;

create table if not exists public.payment_evidence_attempts (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.payment_orders(id) on delete restrict,
  attempt_number integer not null check (attempt_number between 1 and 3),
  upload_idempotency_key text not null check (length(upload_idempotency_key) between 8 and 128),
  object_path text not null unique check (
    object_path ~ '^orders/[0-9a-f-]{36}/attempts/[0-9a-f-]{36}/normalized\.jpg$'
  ),
  mime_type text check (mime_type is null or mime_type = 'image/jpeg'),
  byte_size integer check (byte_size is null or byte_size between 1 and 8388608),
  pixel_width integer check (pixel_width is null or pixel_width between 1 and 2048),
  pixel_height integer check (pixel_height is null or pixel_height between 1 and 2048),
  sha256_hex text check (sha256_hex is null or sha256_hex ~ '^[0-9a-f]{64}$'),
  status text not null check (status in ('prepared', 'submitted', 'rejected', 'approved', 'deleted')),
  prepared_at timestamptz not null default statement_timestamp(),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(user_id),
  rejection_reason text,
  deleted_at timestamptz,
  unique (order_id, attempt_number),
  unique (order_id, upload_idempotency_key)
);

alter table public.payment_evidence_attempts
  drop constraint if exists payment_evidence_attempts_byte_size_check,
  drop constraint if exists payment_evidence_attempts_pixel_width_check,
  drop constraint if exists payment_evidence_attempts_pixel_height_check;
alter table public.payment_evidence_attempts
  add constraint payment_evidence_attempts_byte_size_check
    check (byte_size is null or byte_size between 1 and 8388608),
  add constraint payment_evidence_attempts_pixel_width_check
    check (pixel_width is null or pixel_width between 1 and 2048),
  add constraint payment_evidence_attempts_pixel_height_check
    check (pixel_height is null or pixel_height between 1 and 2048);

create table if not exists public.payment_events (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.payment_orders(id) on delete restrict,
  attempt_id uuid references public.payment_evidence_attempts(id) on delete restrict,
  actor_id uuid references public.profiles(user_id) on delete set null,
  event_type text not null,
  metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(metadata) = 'object' and octet_length(metadata::text) <= 4096),
  created_at timestamptz not null default statement_timestamp()
);

create table if not exists public.payment_ledger (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.payment_orders(id) on delete restrict,
  entry_kind text not null check (entry_kind in ('verified', 'reversal')),
  amount_minor bigint not null check (amount_minor > 0),
  currency text not null check (currency = 'IDR'),
  destination_version integer not null,
  reconciliation_reference text not null
    check (length(trim(reconciliation_reference)) between 4 and 128),
  verified_by uuid not null references public.profiles(user_id),
  verified_at timestamptz not null default statement_timestamp(),
  related_ledger_id uuid references public.payment_ledger(id) on delete restrict,
  resolution_due_at timestamptz,
  resolution_note text,
  unique (order_id, entry_kind)
);

create index if not exists payment_orders_admin_queue_idx
  on public.payment_orders(status, created_at, purpose);
create index if not exists payment_orders_owner_created_idx
  on public.payment_orders(owner_user_id, created_at desc);
create index if not exists payment_evidence_order_idx
  on public.payment_evidence_attempts(order_id, attempt_number desc);
create index if not exists payment_events_order_idx
  on public.payment_events(order_id, id);
create unique index if not exists payment_orders_open_program_owner_idx
  on public.payment_orders(owner_user_id, program_id)
  where purpose = 'program_enrollment'
    and status in ('awaiting_evidence', 'under_review', 'correction_required', 'approved');

alter table public.payment_destinations enable row level security;
alter table public.payment_orders enable row level security;
alter table public.payment_evidence_attempts enable row level security;
alter table public.payment_events enable row level security;
alter table public.payment_ledger enable row level security;

revoke all on public.payment_destinations from anon, authenticated;
revoke all on public.payment_orders from anon, authenticated;
revoke all on public.payment_evidence_attempts from anon, authenticated;
revoke all on public.payment_events from anon, authenticated;
revoke all on public.payment_ledger from anon, authenticated;
grant select on public.payment_destinations to authenticated;
grant select on public.payment_orders to authenticated;
grant select on public.payment_evidence_attempts to authenticated;
grant select on public.payment_events to authenticated;
grant select on public.payment_ledger to authenticated;

drop policy if exists "owner or admin reads destination snapshot source" on public.payment_destinations;
drop policy if exists "admin reads payment destinations" on public.payment_destinations;
create policy "admin reads payment destinations"
  on public.payment_destinations for select to authenticated
  using ((select private.is_admin()));

drop policy if exists "owner or admin reads payment orders" on public.payment_orders;
create policy "owner or admin reads payment orders"
  on public.payment_orders for select to authenticated
  using (owner_user_id = (select auth.uid()) or (select private.is_admin()));

drop policy if exists "owner or admin reads payment evidence metadata" on public.payment_evidence_attempts;
create policy "owner or admin reads payment evidence metadata"
  on public.payment_evidence_attempts for select to authenticated
  using (
    (select private.is_admin())
    or exists (
      select 1 from public.payment_orders payment_order
      where payment_order.id = payment_evidence_attempts.order_id
        and payment_order.owner_user_id = (select auth.uid())
    )
  );

drop policy if exists "admin reads payment events" on public.payment_events;
create policy "admin reads payment events"
  on public.payment_events for select to authenticated
  using ((select private.is_admin()));

drop policy if exists "admin reads verified payment ledger" on public.payment_ledger;
create policy "admin reads verified payment ledger"
  on public.payment_ledger for select to authenticated
  using ((select private.is_admin()));

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values
  ('payment-evidence', 'payment-evidence', false, 8388608, array['image/jpeg']),
  ('payment-destination-assets', 'payment-destination-assets', false, 8388608, array['image/jpeg'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "owner uploads prepared payment evidence" on storage.objects;
create policy "owner uploads prepared payment evidence"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'payment-evidence'
    and exists (
      select 1
      from public.payment_evidence_attempts attempt
      join public.payment_orders payment_order on payment_order.id = attempt.order_id
      where attempt.object_path = name
        and attempt.status = 'prepared'
        and payment_order.owner_user_id = (select auth.uid())
        and payment_order.status in ('awaiting_evidence', 'correction_required')
    )
  );

drop policy if exists "owner or admin reads payment evidence object" on storage.objects;
create policy "owner or admin reads payment evidence object"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'payment-evidence'
    and (
      (select private.is_admin())
      or exists (
        select 1
        from public.payment_evidence_attempts attempt
        join public.payment_orders payment_order on payment_order.id = attempt.order_id
        where attempt.object_path = name
          and payment_order.owner_user_id = (select auth.uid())
      )
    )
  );

drop policy if exists "owner deletes unsubmitted payment evidence" on storage.objects;
create policy "owner deletes unsubmitted payment evidence"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'payment-evidence'
    and exists (
      select 1
      from public.payment_evidence_attempts attempt
      join public.payment_orders payment_order on payment_order.id = attempt.order_id
      where attempt.object_path = name
        and attempt.status = 'prepared'
        and payment_order.owner_user_id = (select auth.uid())
    )
  );

drop policy if exists "authorized reads payment destination asset" on storage.objects;
create policy "authorized reads payment destination asset"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'payment-destination-assets'
    and (
      (select private.is_admin())
      or exists (
        select 1 from public.payment_orders payment_order
        where payment_order.owner_user_id = (select auth.uid())
          and payment_order.qris_object_path_snapshot = name
      )
    )
  );

drop policy if exists "admin uploads payment destination asset" on storage.objects;
create policy "admin uploads payment destination asset"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'payment-destination-assets'
    and (select private.is_admin())
    and name ~ '^destinations/[0-9a-f-]{36}/qris\.jpg$'
  );

create or replace function private.current_payment_destination()
returns public.payment_destinations
language sql stable security definer
set search_path = ''
as $$
  select destination
  from public.payment_destinations destination
  where destination.effective_from <= statement_timestamp()
    and (destination.effective_until is null
      or destination.effective_until > statement_timestamp())
    and destination.status in ('active', 'scheduled')
  order by destination.version desc
  limit 1;
$$;

drop function if exists public.create_payment_destination(text,text,text,text,timestamptz,text);
drop function if exists public.create_program_payment_order(uuid,text,text);
drop function if exists public.prepare_payment_evidence_attempt(uuid,text);
drop function if exists public.submit_payment_evidence(uuid,text,integer,integer,integer,uuid);

create or replace function public.create_payment_destination(
  destination_bank_code text,
  destination_bank_name text,
  destination_account_name text,
  destination_account_reference text,
  destination_instructions text,
  effective_at timestamptz,
  destination_qris_object_path text default null
)
returns public.payment_destinations
language plpgsql security definer
set search_path = ''
as $$
declare
  result public.payment_destinations;
  next_version integer;
begin
  if not (select private.is_admin()) then raise exception 'permission_denied'; end if;
  if effective_at < statement_timestamp() - interval '5 minutes' then
    raise exception 'effective_time_invalid';
  end if;
  if length(trim(coalesce(destination_instructions, ''))) < 8 then
    raise exception 'instructions_required';
  end if;
  if destination_qris_object_path is not null and not exists (
    select 1 from storage.objects object
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
    qris_object_path, instructions, effective_from, status, created_by
  ) values (
    next_version, upper(trim(destination_bank_code)), trim(destination_bank_name),
    trim(destination_account_name), trim(destination_account_reference),
    destination_qris_object_path, trim(destination_instructions), effective_at,
    case when effective_at <= statement_timestamp() then 'active' else 'scheduled' end,
    (select auth.uid())
  ) returning * into result;
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
  if actor_profile.user_id is null or actor_profile.role not in ('participant', 'coach') then
    raise exception 'permission_denied';
  end if;
  select * into target_program from public.programs
  where id = target_program_id for update;
  if target_program.id is null or target_program.status not in ('scheduled', 'active')
    or target_program.published_at is null or target_program.pricing_mode <> 'paid'
    or target_program.desired_price is null or target_program.desired_price <= 0 then
    raise exception 'program_unavailable';
  end if;
  if target_program.registration_closes_at is not null
    and statement_timestamp() >= target_program.registration_closes_at then
    raise exception 'registration_closed';
  end if;
  select * into target_coach from public.profiles
  where coach_qr_identifier = coach_qr_payload
    and role = 'coach' and coach_is_approved
    and private.has_active_coach_access(user_id);
  if target_coach.user_id is null or target_coach.user_id = actor_id then
    raise exception 'coach_invalid';
  end if;
  if actor_profile.current_coach_id is not null
    and actor_profile.current_coach_id <> target_coach.user_id then
    raise exception 'coach_mismatch';
  end if;
  select * into destination from private.current_payment_destination();
  if destination.id is null then raise exception 'payment_destination_unavailable'; end if;
  if payment_method = 'static_qris' and destination.qris_object_path is null then
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
  where program_id = target_program.id and participant_id = actor_id for update;
  if enrollment.status in ('active', 'completed') then raise exception 'already_enrolled'; end if;
  if enrollment.id is null then
    insert into public.program_enrollments(program_id, participant_id, coach_id, status)
    values (target_program.id, actor_id, target_coach.user_id, 'waiting_for_payment')
    returning * into enrollment;
  else
    update public.program_enrollments
    set coach_id = target_coach.user_id, status = 'waiting_for_payment',
      enrolled_at = statement_timestamp(), completed_at = null
    where id = enrollment.id returning * into enrollment;
  end if;
  update public.profiles
  set current_coach_id = target_coach.user_id, updated_at = statement_timestamp()
  where user_id = actor_id and current_coach_id is null;
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
    payment_method, destination.id, destination.version, destination.bank_code,
    destination.bank_name, destination.account_name,
    destination.account_reference, destination.qris_object_path,
    destination.instructions, statement_timestamp(),
    statement_timestamp() + interval '24 hours',
    ((target_program.ends_on + 30)::timestamp at time zone target_program.timezone),
    target_program.timezone, 'awaiting_evidence', request_idempotency_key
  ) returning * into result;
  insert into public.payment_events(order_id, actor_id, event_type)
  values (result.id, actor_id, 'order_created');
  return result;
end;
$$;

create or replace function public.prepare_payment_evidence_attempt(
  target_order_id uuid,
  request_idempotency_key text
)
returns public.payment_evidence_attempts
language plpgsql security definer
set search_path = ''
as $$
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
  where order_id = target_order.id
    and upload_idempotency_key = request_idempotency_key;
  if existing.id is not null then return existing; end if;
  if target_order.status not in ('awaiting_evidence', 'correction_required') then
    raise exception 'payment_order_not_uploadable';
  end if;
  if target_order.reservation_expires_at is not null
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
    'orders/' || target_order.id || '/attempts/' || result.id || '/normalized.jpg',
    'prepared'
  ) returning * into result;
  insert into public.payment_events(order_id, attempt_id, actor_id, event_type)
  values (target_order.id, result.id, actor_id, 'upload_intent_created');
  return result;
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
language plpgsql security definer
set search_path = ''
as $$
declare
  actor_id uuid := (select auth.uid());
  attempt public.payment_evidence_attempts;
  target_order public.payment_orders;
  stored_object storage.objects;
begin
  if actor_id is null then raise exception 'authentication_required'; end if;
  select evidence.* into attempt
  from public.payment_evidence_attempts evidence
  join public.payment_orders payment_order on payment_order.id = evidence.order_id
  where evidence.id = target_attempt_id and payment_order.owner_user_id = actor_id
  for update of evidence;
  if attempt.id is null then raise exception 'payment_evidence_not_found'; end if;
  select * into target_order from public.payment_orders
  where id = attempt.order_id for update;
  if attempt.status = 'submitted' then return target_order; end if;
  if attempt.status <> 'prepared' then raise exception 'evidence_not_submittable'; end if;
  if target_order.status not in ('awaiting_evidence', 'correction_required') then
    raise exception 'payment_order_not_uploadable';
  end if;
  if content_sha256_hex !~ '^[0-9a-f]{64}$'
    or content_byte_size not between 1 and 8388608
    or content_pixel_width not between 1 and 2048
    or content_pixel_height not between 1 and 2048 then
    raise exception 'evidence_validation_failed';
  end if;
  select * into stored_object from storage.objects object
  where object.bucket_id = 'payment-evidence'
    and object.name = attempt.object_path;
  if stored_object.id is null then raise exception 'evidence_object_missing'; end if;
  if coalesce(stored_object.metadata ->> 'mimetype', '') <> 'image/jpeg'
    or coalesce((stored_object.metadata ->> 'size')::bigint, 0) <> content_byte_size then
    raise exception 'evidence_object_mismatch';
  end if;
  if target_order.reservation_expires_at is not null
    and statement_timestamp() >= target_order.reservation_expires_at then
    raise exception 'payment_order_expired';
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
  return target_order;
end;
$$;

-- Allow the shared commerce ledger to represent the approved web transaction.
alter table public.commerce_transactions
  drop constraint if exists commerce_transactions_platform_check,
  drop constraint if exists commerce_transactions_provider_check;
alter table public.commerce_transactions
  add constraint commerce_transactions_platform_check
    check (platform in ('app_store', 'play_store', 'web')),
  add constraint commerce_transactions_provider_check
    check (provider in ('app_store', 'play_store', 'manual_transfer', 'static_qris'));

create or replace function public.approve_payment_order(
  target_order_id uuid,
  expected_version integer,
  reconciled_amount_minor bigint,
  reconciliation_reference text,
  destination_matches boolean
)
returns public.payment_orders
language plpgsql security definer
set search_path = ''
as $$
declare
  reviewer uuid := (select auth.uid());
  target_order public.payment_orders;
  attempt public.payment_evidence_attempts;
  target_program public.programs;
  enrollment public.program_enrollments;
  occupied integer;
  transaction_id uuid;
  provider_name text;
  hash_value text;
begin
  if not (select private.is_admin()) then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reconciliation_reference, ''))) < 4
    or not destination_matches then raise exception 'reconciliation_required'; end if;
  select * into target_order from public.payment_orders
  where id = target_order_id for update;
  if target_order.id is null then raise exception 'payment_order_not_found'; end if;
  if target_order.status = 'approved' then return target_order; end if;
  if target_order.version <> expected_version then raise exception 'version_conflict'; end if;
  if target_order.status <> 'under_review' then raise exception 'payment_order_not_reviewable'; end if;
  if reconciled_amount_minor <> target_order.amount_minor then raise exception 'amount_mismatch'; end if;
  select * into attempt from public.payment_evidence_attempts
  where order_id = target_order.id and status = 'submitted'
  order by attempt_number desc limit 1 for update;
  if attempt.id is null then raise exception 'payment_evidence_not_found'; end if;
  if target_order.purpose <> 'program_enrollment' then
    raise exception 'coach_payment_review_moves_to_w06';
  end if;
  select * into target_program from public.programs
  where id = target_order.program_id for update;
  if target_program.id is null or target_program.status not in ('scheduled', 'active')
    or target_program.published_at is null then raise exception 'program_unavailable'; end if;
  select * into enrollment from public.program_enrollments
  where id = target_order.pending_enrollment_id for update;
  if enrollment.id is null or enrollment.participant_id <> target_order.owner_user_id
    or enrollment.program_id <> target_order.program_id
    or enrollment.coach_id <> target_order.coach_user_id_snapshot
    or enrollment.status <> 'waiting_for_payment' then
    raise exception 'enrollment_conflict';
  end if;
  select count(*) into occupied from public.program_enrollments
  where program_id = target_order.program_id and status in ('active', 'completed');
  if target_program.participant_limit is not null
    and occupied >= target_program.participant_limit then raise exception 'program_full'; end if;
  provider_name := case target_order.declared_method
    when 'static_qris' then 'static_qris' else 'manual_transfer' end;
  hash_value := encode(extensions.digest(
    target_order.id::text || ':' || trim(reconciliation_reference), 'sha256'
  ), 'hex');
  insert into public.commerce_transactions(
    platform, environment, external_transaction_id, program_id,
    participant_id, product_id, status, signed_payload_hash, purchased_at,
    subject_kind, provider, product_type, currency_code, price_milliunits,
    last_event_at
  ) values (
    'web', 'local', 'manual:' || target_order.id::text, target_order.program_id,
    target_order.owner_user_id, 'manual-program:' || target_order.program_id::text,
    'verified', hash_value, statement_timestamp(), 'program', provider_name,
    'non_consumable', target_order.currency, target_order.amount_minor * 1000,
    statement_timestamp()
  ) on conflict (platform, environment, external_transaction_id)
  do update set last_event_at = excluded.last_event_at
  returning id into transaction_id;
  insert into public.program_entitlements(
    program_id, participant_id, transaction_id, status
  ) values (
    target_order.program_id, target_order.owner_user_id, transaction_id, 'active'
  ) on conflict (program_id, participant_id) do nothing;
  update public.program_enrollments set
    status = 'active', enrolled_at = statement_timestamp()
  where id = enrollment.id;
  insert into public.program_scores(enrollment_id)
  values (enrollment.id) on conflict (enrollment_id) do nothing;
  insert into public.payment_ledger(
    order_id, entry_kind, amount_minor, currency, destination_version,
    reconciliation_reference, verified_by
  ) values (
    target_order.id, 'verified', target_order.amount_minor, target_order.currency,
    target_order.destination_version, trim(reconciliation_reference), reviewer
  ) on conflict (order_id, entry_kind) do nothing;
  update public.payment_evidence_attempts set
    status = 'approved', reviewed_at = statement_timestamp(),
    reviewed_by = reviewer, rejection_reason = null
  where id = attempt.id;
  update public.payment_orders set
    status = 'approved', version = version + 1,
    latest_rejection_reason = null, updated_at = statement_timestamp()
  where id = target_order.id returning * into target_order;
  insert into public.payment_events(order_id, attempt_id, actor_id, event_type, metadata)
  values (
    target_order.id, attempt.id, reviewer, 'payment_approved',
    jsonb_build_object('transaction_id', transaction_id)
  );
  insert into public.audit_events(kind, actor_id, subject_id, summary, payload)
  values (
    'manual_payment_approved', reviewer, target_order.id,
    'Pembayaran manual disetujui dan enrollment diaktifkan.',
    jsonb_build_object('transaction_id', transaction_id, 'program_id', target_order.program_id)
  );
  return target_order;
end;
$$;

create or replace function public.reject_payment_evidence(
  target_order_id uuid,
  expected_version integer,
  rejection_reason text
)
returns public.payment_orders
language plpgsql security definer
set search_path = ''
as $$
declare
  target_order public.payment_orders;
  attempt public.payment_evidence_attempts;
  normalized_reason text := trim(rejection_reason);
begin
  if not (select private.is_admin()) then raise exception 'permission_denied'; end if;
  if length(coalesce(normalized_reason, '')) < 5 then raise exception 'reason_required'; end if;
  select * into target_order from public.payment_orders
  where id = target_order_id for update;
  if target_order.id is null then raise exception 'payment_order_not_found'; end if;
  if target_order.version <> expected_version then raise exception 'version_conflict'; end if;
  if target_order.status <> 'under_review' then raise exception 'payment_order_not_reviewable'; end if;
  select * into attempt from public.payment_evidence_attempts
  where order_id = target_order.id and status = 'submitted'
  order by attempt_number desc limit 1 for update;
  if attempt.id is null then raise exception 'payment_evidence_not_found'; end if;
  update public.payment_evidence_attempts set
    status = 'rejected', reviewed_at = statement_timestamp(),
    reviewed_by = (select auth.uid()), rejection_reason = normalized_reason
  where id = attempt.id;
  update public.payment_orders set
    status = 'correction_required',
    correction_expires_at = statement_timestamp() + interval '24 hours',
    latest_rejection_reason = normalized_reason, version = version + 1,
    updated_at = statement_timestamp()
  where id = target_order.id returning * into target_order;
  insert into public.payment_events(order_id, attempt_id, actor_id, event_type, metadata)
  values (
    target_order.id, attempt.id, (select auth.uid()), 'evidence_rejected',
    jsonb_build_object('reason', normalized_reason)
  );
  insert into public.audit_events(kind, actor_id, subject_id, summary, payload)
  values (
    'manual_payment_rejected', (select auth.uid()), target_order.id,
    'Bukti pembayaran manual ditolak.', jsonb_build_object('reason', normalized_reason)
  );
  return target_order;
end;
$$;

create or replace function public.list_payment_evidence_orphans(
  minimum_age interval default interval '72 hours',
  batch_size integer default 100,
  dry_run boolean default true
)
returns table(object_name text, object_created_at timestamptz, is_dry_run boolean)
language plpgsql security definer
set search_path = ''
as $$
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role'
    and not (select private.is_admin()) then raise exception 'permission_denied'; end if;
  if minimum_age < interval '24 hours' then raise exception 'minimum_age_too_short'; end if;
  if batch_size not between 1 and 500 then raise exception 'batch_size_invalid'; end if;
  return query
  select object.name, object.created_at, dry_run
  from storage.objects object
  where object.bucket_id = 'payment-evidence'
    and object.created_at <= statement_timestamp() - minimum_age
    and not exists (
      select 1 from public.payment_evidence_attempts attempt
      where attempt.object_path = object.name
    )
  order by object.created_at
  limit batch_size;
end;
$$;

revoke all on function public.create_payment_destination(text,text,text,text,text,timestamptz,text) from public, anon;
revoke all on function public.create_program_payment_order(uuid,text,text,text) from public, anon;
revoke all on function public.prepare_payment_evidence_attempt(uuid,text) from public, anon;
revoke all on function public.submit_payment_evidence(uuid,text,integer,integer,integer) from public, anon;
revoke all on function public.approve_payment_order(uuid,integer,bigint,text,boolean) from public, anon;
revoke all on function public.reject_payment_evidence(uuid,integer,text) from public, anon;
revoke all on function public.list_payment_evidence_orphans(interval,integer,boolean) from public, anon;
grant execute on function public.create_payment_destination(text,text,text,text,text,timestamptz,text) to authenticated;
grant execute on function public.create_program_payment_order(uuid,text,text,text) to authenticated;
grant execute on function public.prepare_payment_evidence_attempt(uuid,text) to authenticated;
grant execute on function public.submit_payment_evidence(uuid,text,integer,integer,integer) to authenticated;
grant execute on function public.approve_payment_order(uuid,integer,bigint,text,boolean) to authenticated;
grant execute on function public.reject_payment_evidence(uuid,integer,text) to authenticated;
grant execute on function public.list_payment_evidence_orphans(interval,integer,boolean) to authenticated, service_role;

notify pgrst, 'reload schema';
