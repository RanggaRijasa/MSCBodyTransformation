-- Phase 13.1: server-side Sign in with Apple credential lifecycle, account
-- events, and durable retry state. Raw Apple subjects and refresh tokens are
-- never stored. Refresh-token encryption/decryption stays in Edge Functions.

create table private.apple_identity_credentials (
  id uuid primary key default gen_random_uuid(),
  account_id uuid unique references public.profiles(user_id) on delete set null,
  apple_subject_hash text not null check (length(apple_subject_hash) = 64),
  encrypted_refresh_token text not null,
  encryption_nonce text not null,
  status text not null default 'active' check (
    status in ('active', 'pending_revoke', 'processing', 'retry')
  ),
  retry_count integer not null default 0 check (retry_count >= 0),
  next_retry_at timestamptz,
  claimed_at timestamptz,
  last_error_code text,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp()
);

create index apple_identity_credentials_retry_idx
  on private.apple_identity_credentials(status, next_retry_at)
  where status in ('pending_revoke', 'retry');

create table private.apple_account_event_inbox (
  event_jti text primary key check (length(event_jti) between 8 and 512),
  event_type text not null check (
    event_type in (
      'email-enabled', 'email-disabled', 'consent-revoked', 'account-deleted'
    )
  ),
  apple_subject_hash text not null check (length(apple_subject_hash) = 64),
  account_id uuid references public.profiles(user_id) on delete set null,
  event_time timestamptz not null,
  status text not null default 'pending' check (
    status in ('pending', 'processing', 'retry', 'processed', 'manual_action')
  ),
  retry_count integer not null default 0 check (retry_count >= 0),
  next_retry_at timestamptz,
  claimed_at timestamptz,
  last_error_code text,
  received_at timestamptz not null default statement_timestamp(),
  processed_at timestamptz
);

create index apple_account_event_inbox_retry_idx
  on private.apple_account_event_inbox(status, next_retry_at)
  where status in ('pending', 'retry');

create table private.apple_commerce_reconciliation_state (
  transaction_id uuid primary key
    references public.commerce_transactions(id) on delete cascade,
  environment text not null check (environment in ('sandbox', 'production')),
  status text not null default 'pending' check (
    status in ('pending', 'processing', 'retry')
  ),
  retry_count integer not null default 0 check (retry_count >= 0),
  next_attempt_at timestamptz not null default statement_timestamp(),
  lease_until timestamptz,
  last_attempt_at timestamptz,
  last_reconciled_at timestamptz,
  last_error_code text,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp()
);

create index apple_commerce_reconciliation_due_idx
  on private.apple_commerce_reconciliation_state(
    environment, status, next_attempt_at
  );

revoke all on table
  private.apple_identity_credentials,
  private.apple_account_event_inbox,
  private.apple_commerce_reconciliation_state
from public, anon, authenticated, service_role;

create or replace function private.require_service_role()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if coalesce((select auth.role()), '') <> 'service_role' then
    raise exception 'permission_denied';
  end if;
end;
$$;

create or replace function public.store_apple_identity_credential(
  target_account_id uuid,
  target_apple_subject_hash text,
  target_encrypted_refresh_token text,
  target_encryption_nonce text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  credential_id uuid;
begin
  perform private.require_service_role();
  if target_account_id is null
    or length(coalesce(target_apple_subject_hash, '')) <> 64
    or length(coalesce(target_encrypted_refresh_token, '')) < 16
    or length(coalesce(target_encryption_nonce, '')) < 12
  then
    raise exception 'request_invalid';
  end if;
  if not exists (
    select 1
    from auth.identities identity
    where identity.user_id = target_account_id
      and identity.provider = 'apple'
      and encode(
        extensions.digest(identity.identity_data ->> 'sub', 'sha256'),
        'hex'
      ) = target_apple_subject_hash
  ) then
    raise exception 'apple_identity_mismatch';
  end if;

  insert into private.apple_identity_credentials(
    account_id,
    apple_subject_hash,
    encrypted_refresh_token,
    encryption_nonce,
    status,
    retry_count,
    next_retry_at,
    claimed_at,
    last_error_code,
    updated_at
  ) values (
    target_account_id,
    target_apple_subject_hash,
    target_encrypted_refresh_token,
    target_encryption_nonce,
    'active',
    0,
    null,
    null,
    null,
    statement_timestamp()
  )
  on conflict (account_id) do update
  set apple_subject_hash = excluded.apple_subject_hash,
      encrypted_refresh_token = excluded.encrypted_refresh_token,
      encryption_nonce = excluded.encryption_nonce,
      status = 'active',
      retry_count = 0,
      next_retry_at = null,
      claimed_at = null,
      last_error_code = null,
      updated_at = statement_timestamp()
  returning id into credential_id;

  return credential_id;
end;
$$;

create or replace function public.claim_apple_identity_credential_for_account(
  target_account_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  credential private.apple_identity_credentials;
begin
  perform private.require_service_role();
  select * into credential
  from private.apple_identity_credentials stored
  where stored.account_id = target_account_id
  for update;
  if credential.id is null then
    return null;
  end if;
  update private.apple_identity_credentials
  set status = 'processing',
      claimed_at = statement_timestamp(),
      updated_at = statement_timestamp()
  where id = credential.id;
  return jsonb_build_object(
    'id', credential.id,
    'encrypted_refresh_token', credential.encrypted_refresh_token,
    'encryption_nonce', credential.encryption_nonce
  );
end;
$$;

create or replace function public.complete_apple_identity_revocation(
  target_credential_id uuid,
  succeeded boolean,
  error_code text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_service_role();
  if succeeded then
    delete from private.apple_identity_credentials
    where id = target_credential_id;
  else
    update private.apple_identity_credentials
    set account_id = null,
        status = 'retry',
        retry_count = retry_count + 1,
        next_retry_at = statement_timestamp()
          + make_interval(secs => least(3600, 30 * (2 ^ least(retry_count, 7)))),
        claimed_at = null,
        last_error_code = left(coalesce(error_code, 'apple_revoke_failed'), 96),
        updated_at = statement_timestamp()
    where id = target_credential_id;
  end if;
end;
$$;

create or replace function public.claim_pending_apple_identity_revocations(
  batch_size integer default 25
)
returns setof jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_service_role();
  if batch_size < 1 or batch_size > 100 then
    raise exception 'request_invalid';
  end if;
  return query
  with candidates as (
    select credential.id
    from private.apple_identity_credentials credential
    where credential.status in ('pending_revoke', 'retry')
      and coalesce(credential.next_retry_at, '-infinity'::timestamptz)
        <= statement_timestamp()
      and (
        credential.claimed_at is null
        or credential.claimed_at < statement_timestamp() - interval '10 minutes'
      )
    order by credential.next_retry_at nulls first, credential.created_at
    for update skip locked
    limit batch_size
  ), claimed as (
    update private.apple_identity_credentials credential
    set status = 'processing',
        claimed_at = statement_timestamp(),
        updated_at = statement_timestamp()
    from candidates
    where credential.id = candidates.id
    returning credential.*
  )
  select jsonb_build_object(
    'id', claimed.id,
    'encrypted_refresh_token', claimed.encrypted_refresh_token,
    'encryption_nonce', claimed.encryption_nonce
  )
  from claimed;
end;
$$;

create or replace function public.record_apple_account_event(
  target_event_jti text,
  target_event_type text,
  target_apple_subject_hash text,
  target_event_time timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_account_id uuid;
  inserted boolean;
begin
  perform private.require_service_role();
  if length(coalesce(target_event_jti, '')) not between 8 and 512
    or target_event_type not in (
      'email-enabled', 'email-disabled', 'consent-revoked', 'account-deleted'
    )
    or length(coalesce(target_apple_subject_hash, '')) <> 64
  then
    raise exception 'request_invalid';
  end if;

  select identity.user_id into resolved_account_id
  from auth.identities identity
  where identity.provider = 'apple'
    and encode(
      extensions.digest(identity.identity_data ->> 'sub', 'sha256'),
      'hex'
    ) = target_apple_subject_hash
  limit 1;

  insert into private.apple_account_event_inbox(
    event_jti,
    event_type,
    apple_subject_hash,
    account_id,
    event_time
  ) values (
    target_event_jti,
    target_event_type,
    target_apple_subject_hash,
    resolved_account_id,
    target_event_time
  )
  on conflict (event_jti) do nothing;
  inserted := found;

  if inserted and target_event_type in ('consent-revoked', 'account-deleted') then
    update private.apple_identity_credentials
    set status = 'pending_revoke',
        next_retry_at = statement_timestamp(),
        claimed_at = null,
        updated_at = statement_timestamp()
    where account_id = resolved_account_id;
  end if;

  return jsonb_build_object(
    'inserted', inserted,
    'account_id', resolved_account_id,
    'requires_deletion', target_event_type in (
      'consent-revoked', 'account-deleted'
    ) and resolved_account_id is not null
  );
end;
$$;

create or replace function public.claim_pending_apple_account_events(
  batch_size integer default 25
)
returns setof jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_service_role();
  if batch_size < 1 or batch_size > 100 then
    raise exception 'request_invalid';
  end if;
  return query
  with candidates as (
    select inbox.event_jti
    from private.apple_account_event_inbox inbox
    where inbox.status in ('pending', 'retry')
      and coalesce(inbox.next_retry_at, '-infinity'::timestamptz)
        <= statement_timestamp()
      and (
        inbox.claimed_at is null
        or inbox.claimed_at < statement_timestamp() - interval '10 minutes'
      )
    order by inbox.event_time, inbox.received_at
    for update skip locked
    limit batch_size
  ), claimed as (
    update private.apple_account_event_inbox inbox
    set status = 'processing',
        claimed_at = statement_timestamp()
    from candidates
    where inbox.event_jti = candidates.event_jti
    returning inbox.*
  )
  select jsonb_build_object(
    'event_jti', claimed.event_jti,
    'event_type', claimed.event_type,
    'account_id', claimed.account_id,
    'requires_deletion', claimed.event_type in (
      'consent-revoked', 'account-deleted'
    ) and claimed.account_id is not null
  )
  from claimed;
end;
$$;

create or replace function public.complete_apple_account_event(
  target_event_jti text,
  succeeded boolean,
  error_code text default null,
  requires_manual_action boolean default false
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_service_role();
  update private.apple_account_event_inbox
  set status = case
        when succeeded then 'processed'
        when requires_manual_action then 'manual_action'
        else 'retry'
      end,
      retry_count = case when succeeded then retry_count else retry_count + 1 end,
      next_retry_at = case
        when succeeded or requires_manual_action then null
        else statement_timestamp()
          + make_interval(secs => least(3600, 30 * (2 ^ least(retry_count, 7))))
      end,
      claimed_at = null,
      last_error_code = case
        when succeeded then null
        else left(coalesce(error_code, 'apple_account_event_failed'), 96)
      end,
      processed_at = case
        when succeeded or requires_manual_action then statement_timestamp()
        else null
      end
  where event_jti = target_event_jti;
end;
$$;

create or replace function public.prepare_external_apple_account_deletion(
  target_account_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_role text;
  media_manifest jsonb;
begin
  perform private.require_service_role();
  select role into target_role
  from public.profiles
  where user_id = target_account_id
  for update;
  if target_role is null then
    return '[]'::jsonb;
  end if;
  if target_role = 'admin' then
    raise exception 'admin_account_deletion_not_allowed';
  end if;
  if exists (
    select 1 from public.programs where created_by = target_account_id
  ) or (
    target_role = 'coach' and exists (
      select 1 from public.program_enrollments
      where coach_id = target_account_id
    )
  ) then
    raise exception 'account_relationships_require_transfer';
  end if;
  select coalesce(
    jsonb_agg(
      jsonb_build_object('bucket_id', object.bucket_id, 'name', object.name)
      order by object.bucket_id, object.name
    ),
    '[]'::jsonb
  ) into media_manifest
  from storage.objects object
  where object.owner_id = target_account_id::text;
  return media_manifest;
end;
$$;

create or replace function private.delete_account_application_data(
  target_account_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1 from storage.objects object
    where object.owner_id = target_account_id::text
  ) then
    raise exception 'private_media_cleanup_required';
  end if;

  update public.program_winners
  set participant_id = null, display_name = 'Akun dihapus'
  where participant_id = target_account_id;
  delete from public.program_entitlements
  where participant_id = target_account_id;
  delete from private.pending_program_coach_selections
  where account_id = target_account_id;
  delete from public.commerce_purchase_intents
  where account_id = target_account_id;
  update public.commerce_transactions
  set participant_id = null, updated_at = clock_timestamp()
  where participant_id = target_account_id;
  delete from public.program_enrollments
  where participant_id = target_account_id;
  delete from public.coach_access_entitlements
  where coach_user_id = target_account_id;
  delete from public.coach_payment_records record
  using public.coach_applications application
  where record.application_id = application.id
    and application.applicant_user_id = target_account_id;
  delete from public.coach_applications
  where applicant_user_id = target_account_id;

  update public.audit_events
  set actor_id = case
        when actor_id = target_account_id then null else actor_id end,
      subject_id = case
        when subject_id = target_account_id then null else subject_id end,
      summary = case
        when actor_id = target_account_id or subject_id = target_account_id
          or payload ->> 'applicant_user_id' = target_account_id::text
        then 'Akun dihapus' else summary end,
      payload = case
        when actor_id = target_account_id or subject_id = target_account_id
          or payload ->> 'applicant_user_id' = target_account_id::text
        then '{}'::jsonb else payload end
  where actor_id = target_account_id or subject_id = target_account_id
    or payload ->> 'applicant_user_id' = target_account_id::text;

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
  where user_id = target_account_id;
end;
$$;

create or replace function public.finalize_external_apple_account_deletion(
  target_account_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_service_role();
  perform private.delete_account_application_data(target_account_id);
  return target_account_id;
end;
$$;

create or replace function public.claim_apple_commerce_reconciliation_batch(
  target_environment text,
  batch_size integer default 20
)
returns setof jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_service_role();
  if target_environment not in ('sandbox', 'production')
    or batch_size < 1 or batch_size > 100
  then
    raise exception 'request_invalid';
  end if;

  insert into private.apple_commerce_reconciliation_state(
    transaction_id, environment
  )
  select transaction.id, transaction.environment
  from public.commerce_transactions transaction
  where transaction.platform = 'app_store'
    and transaction.environment = target_environment
    and transaction.external_transaction_id is not null
  on conflict (transaction_id) do nothing;

  return query
  with candidates as (
    select state.transaction_id
    from private.apple_commerce_reconciliation_state state
    where state.environment = target_environment
      and state.status in ('pending', 'retry')
      and state.next_attempt_at <= statement_timestamp()
      and (
        state.lease_until is null
        or state.lease_until < statement_timestamp()
      )
    order by state.next_attempt_at, state.created_at
    for update skip locked
    limit batch_size
  ), claimed as (
    update private.apple_commerce_reconciliation_state state
    set status = 'processing',
        lease_until = statement_timestamp() + interval '10 minutes',
        last_attempt_at = statement_timestamp(),
        updated_at = statement_timestamp()
    from candidates
    where state.transaction_id = candidates.transaction_id
    returning state.transaction_id, state.environment
  )
  select jsonb_build_object(
    'transaction_id', transaction.external_transaction_id,
    'environment', claimed.environment
  )
  from claimed
  join public.commerce_transactions transaction
    on transaction.id = claimed.transaction_id;
end;
$$;

create or replace function public.complete_apple_commerce_reconciliation(
  target_external_transaction_id text,
  target_environment text,
  succeeded boolean,
  error_code text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_transaction_id uuid;
begin
  perform private.require_service_role();
  select transaction.id into target_transaction_id
  from public.commerce_transactions transaction
  where transaction.platform = 'app_store'
    and transaction.environment = target_environment
    and transaction.external_transaction_id = target_external_transaction_id;
  if target_transaction_id is null then
    raise exception 'transaction_not_found';
  end if;

  update private.apple_commerce_reconciliation_state
  set status = case when succeeded then 'pending' else 'retry' end,
      retry_count = case when succeeded then 0 else retry_count + 1 end,
      next_attempt_at = case
        when succeeded then statement_timestamp() + interval '6 hours'
        else statement_timestamp() + make_interval(
          secs => least(86400, 60 * (2 ^ least(retry_count, 10)))
        )
      end,
      lease_until = null,
      last_reconciled_at = case
        when succeeded then statement_timestamp() else last_reconciled_at end,
      last_error_code = case
        when succeeded then null
        else left(coalesce(error_code, 'apple_reconciliation_failed'), 96)
      end,
      updated_at = statement_timestamp()
  where transaction_id = target_transaction_id;
end;
$$;

do $$
begin
  if to_regprocedure('cron.schedule(text,text,text)') is not null
    and not exists (
      select 1 from cron.job
      where jobname = 'phase12-expire-commerce-state'
    )
  then
    perform cron.schedule(
      'phase12-expire-commerce-state',
      '*/5 * * * *',
      'select public.expire_commerce_state()'
    );
  end if;
end;
$$;

revoke execute on function
  private.require_service_role(),
  private.delete_account_application_data(uuid)
from public, anon, authenticated, service_role;

revoke execute on function
  public.store_apple_identity_credential(uuid, text, text, text),
  public.claim_apple_identity_credential_for_account(uuid),
  public.complete_apple_identity_revocation(uuid, boolean, text),
  public.claim_pending_apple_identity_revocations(integer),
  public.record_apple_account_event(text, text, text, timestamptz),
  public.claim_pending_apple_account_events(integer),
  public.complete_apple_account_event(text, boolean, text, boolean),
  public.prepare_external_apple_account_deletion(uuid),
  public.finalize_external_apple_account_deletion(uuid),
  public.claim_apple_commerce_reconciliation_batch(text, integer),
  public.complete_apple_commerce_reconciliation(text, text, boolean, text)
from public, anon, authenticated, service_role;

grant execute on function
  public.store_apple_identity_credential(uuid, text, text, text),
  public.claim_apple_identity_credential_for_account(uuid),
  public.complete_apple_identity_revocation(uuid, boolean, text),
  public.claim_pending_apple_identity_revocations(integer),
  public.record_apple_account_event(text, text, text, timestamptz),
  public.claim_pending_apple_account_events(integer),
  public.complete_apple_account_event(text, boolean, text, boolean),
  public.prepare_external_apple_account_deletion(uuid),
  public.finalize_external_apple_account_deletion(uuid),
  public.claim_apple_commerce_reconciliation_batch(text, integer),
  public.complete_apple_commerce_reconciliation(text, text, boolean, text)
to service_role;
