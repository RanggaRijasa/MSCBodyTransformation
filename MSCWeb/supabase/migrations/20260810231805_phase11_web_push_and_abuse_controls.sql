-- Phase 11 additive local candidate: Web Push subscriptions/outbox and
-- authenticated abuse controls. Hosted main is intentionally untouched.

create table public.web_push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  endpoint text not null check (
    length(endpoint) between 16 and 2048 and endpoint ~ '^https://'
  ),
  endpoint_hash text generated always as (
    encode(extensions.digest(endpoint, 'sha256'), 'hex')
  ) stored,
  p256dh text not null check (length(p256dh) between 32 and 256),
  auth_secret text not null check (length(auth_secret) between 8 and 128),
  user_agent_family text not null check (
    user_agent_family in (
      'ios_safari', 'android_chrome', 'desktop_chromium',
      'desktop_safari', 'other'
    )
  ),
  permission_granted_at timestamptz not null default statement_timestamp(),
  last_seen_at timestamptz not null default statement_timestamp(),
  revoked_at timestamptz,
  created_at timestamptz not null default statement_timestamp(),
  unique (endpoint_hash)
);

create index web_push_subscriptions_user_active_idx
  on public.web_push_subscriptions(user_id, last_seen_at desc)
  where revoked_at is null;

alter table public.web_push_subscriptions enable row level security;
revoke all on table public.web_push_subscriptions from public, anon, authenticated;
grant select on table public.web_push_subscriptions to authenticated;
grant select, update on table public.web_push_subscriptions to service_role;

create policy web_push_subscriptions_owner_read
on public.web_push_subscriptions for select to authenticated
using (user_id = (select auth.uid()));

create or replace function private.register_my_web_push_subscription(
  target_endpoint text,
  target_p256dh text,
  target_auth_secret text,
  target_user_agent_family text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_user_id uuid := (select auth.uid());
  subscription_id uuid;
begin
  if actor_user_id is null then raise exception 'authentication_required'; end if;
  if target_endpoint !~ '^https://' or length(target_endpoint) not between 16 and 2048 then
    raise exception 'push_endpoint_invalid';
  end if;
  if length(target_p256dh) not between 32 and 256
     or length(target_auth_secret) not between 8 and 128 then
    raise exception 'push_key_invalid';
  end if;
  if target_user_agent_family not in (
    'ios_safari', 'android_chrome', 'desktop_chromium',
    'desktop_safari', 'other'
  ) then
    raise exception 'push_user_agent_invalid';
  end if;

  insert into public.web_push_subscriptions(
    user_id, endpoint, p256dh, auth_secret, user_agent_family
  ) values (
    actor_user_id, target_endpoint, target_p256dh, target_auth_secret,
    target_user_agent_family
  )
  on conflict (endpoint_hash) do update set
    user_id = excluded.user_id,
    endpoint = excluded.endpoint,
    p256dh = excluded.p256dh,
    auth_secret = excluded.auth_secret,
    user_agent_family = excluded.user_agent_family,
    last_seen_at = statement_timestamp(),
    revoked_at = null
  returning id into subscription_id;

  return subscription_id;
end;
$$;

create or replace function private.revoke_my_web_push_subscription(
  target_endpoint text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  changed_count bigint;
begin
  if (select auth.uid()) is null then raise exception 'authentication_required'; end if;
  update public.web_push_subscriptions
  set revoked_at = statement_timestamp(), last_seen_at = statement_timestamp()
  where user_id = (select auth.uid())
    and endpoint_hash = encode(extensions.digest(target_endpoint, 'sha256'), 'hex')
    and revoked_at is null;
  get diagnostics changed_count = row_count;
  return changed_count > 0;
end;
$$;

create or replace function public.register_my_web_push_subscription(
  target_endpoint text,
  target_p256dh text,
  target_auth_secret text,
  target_user_agent_family text
)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select private.register_my_web_push_subscription(
    target_endpoint, target_p256dh, target_auth_secret, target_user_agent_family
  );
$$;

create or replace function public.revoke_my_web_push_subscription(
  target_endpoint text
)
returns boolean
language sql
security invoker
set search_path = ''
as $$
  select private.revoke_my_web_push_subscription(target_endpoint);
$$;

revoke all on function private.register_my_web_push_subscription(text,text,text,text)
  from public, anon;
revoke all on function private.revoke_my_web_push_subscription(text) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.register_my_web_push_subscription(text,text,text,text)
  to authenticated;
grant execute on function private.revoke_my_web_push_subscription(text) to authenticated;
revoke all on function public.register_my_web_push_subscription(text,text,text,text)
  from public, anon;
revoke all on function public.revoke_my_web_push_subscription(text) from public, anon;
grant execute on function public.register_my_web_push_subscription(text,text,text,text)
  to authenticated;
grant execute on function public.revoke_my_web_push_subscription(text) to authenticated;

create table public.web_push_outbox (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid references public.profiles(user_id) on delete cascade,
  event_type text not null check (
    event_type in (
      'coach_review_pending', 'submission_approved', 'submission_rejected',
      'payment_review_pending', 'payment_approved', 'payment_correction_required',
      'payment_rejected', 'coach_application_review_pending',
      'coach_application_approved', 'coach_application_rejected'
    )
  ),
  destination_path text not null check (
    destination_path like '/%' and destination_path not like '//%'
      and destination_path !~ '[[:cntrl:]]'
  ),
  idempotency_key text not null unique check (length(idempotency_key) between 16 and 180),
  status text not null default 'pending' check (
    status in ('pending', 'processing', 'sent', 'failed')
  ),
  attempts integer not null default 0 check (attempts between 0 and 8),
  next_attempt_at timestamptz not null default statement_timestamp(),
  last_error_code text check (
    last_error_code is null or last_error_code ~ '^[a-z0-9_]{3,64}$'
  ),
  created_at timestamptz not null default statement_timestamp(),
  processed_at timestamptz
);

create index web_push_outbox_dispatch_idx
  on public.web_push_outbox(status, next_attempt_at, created_at)
  where status in ('pending', 'failed');

alter table public.web_push_outbox enable row level security;
revoke all on table public.web_push_outbox from public, anon, authenticated;
grant select, update on table public.web_push_outbox to service_role;

create or replace function private.enqueue_web_push(
  recipient uuid,
  notification_type text,
  target_path text,
  dedupe_key text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if recipient is null then return; end if;
  insert into public.web_push_outbox(
    recipient_user_id, event_type, destination_path, idempotency_key
  ) values (recipient, notification_type, target_path, dedupe_key)
  on conflict (idempotency_key) do nothing;
end;
$$;

create or replace function private.enqueue_submission_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  enrollment public.program_enrollments;
begin
  select * into enrollment from public.program_enrollments where id = new.enrollment_id;
  if tg_op = 'INSERT' and new.status = 'pending' then
    perform private.enqueue_web_push(
      enrollment.coach_id,
      'coach_review_pending',
      '/coach-area/pemeriksaan',
      'coach_review_pending:' || new.id::text
    );
  elsif tg_op = 'UPDATE' and old.status is distinct from new.status
      and new.status in ('approved', 'rejected') then
    perform private.enqueue_web_push(
      enrollment.participant_id,
      'submission_' || new.status,
      '/program/' || enrollment.program_id::text || '/langkah/' || new.step_id::text,
      'submission_' || new.status || ':' || new.id::text
    );
  end if;
  return new;
end;
$$;

create trigger enqueue_submission_web_push
after insert or update of status on public.step_submissions
for each row execute function private.enqueue_submission_push();

create or replace function private.enqueue_payment_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  admin_user uuid;
begin
  if new.status = 'under_review'
     and (tg_op = 'INSERT' or old.status is distinct from new.status) then
    for admin_user in
      select user_id from public.profiles where role = 'admin'
    loop
      perform private.enqueue_web_push(
        admin_user,
        'payment_review_pending',
        '/admin/pembayaran/' || new.id::text,
        'payment_review_pending:' || new.id::text || ':' || admin_user::text
      );
    end loop;
  elsif tg_op = 'UPDATE' and old.status is distinct from new.status
      and new.status in ('approved', 'correction_required', 'rejected') then
    perform private.enqueue_web_push(
      new.owner_user_id,
      'payment_' || new.status,
      '/pembayaran/' || new.id::text,
      'payment_' || new.status || ':' || new.id::text
    );
  end if;
  return new;
end;
$$;

create trigger enqueue_payment_web_push
after insert or update of status on public.payment_orders
for each row execute function private.enqueue_payment_push();

create or replace function private.enqueue_coach_application_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  admin_user uuid;
begin
  if new.status = 'pending_admin_approval'
     and (tg_op = 'INSERT' or old.status is distinct from new.status) then
    for admin_user in
      select user_id from public.profiles where role = 'admin'
    loop
      perform private.enqueue_web_push(
        admin_user,
        'coach_application_review_pending',
        '/admin/orang?role=coach',
        'coach_application_review_pending:' || new.id::text || ':' || admin_user::text
      );
    end loop;
  elsif tg_op = 'UPDATE' and old.status is distinct from new.status
      and new.status in ('approved', 'rejected') then
    perform private.enqueue_web_push(
      new.applicant_user_id,
      'coach_application_' || new.status,
      '/profil',
      'coach_application_' || new.status || ':' || new.id::text
    );
  end if;
  return new;
end;
$$;

create trigger enqueue_coach_application_web_push
after insert or update of status on public.coach_applications
for each row execute function private.enqueue_coach_application_push();

create table private.web_rate_limit_buckets (
  actor_id uuid not null references public.profiles(user_id) on delete cascade,
  operation text not null,
  subject_hash text not null,
  window_started_at timestamptz not null,
  request_count integer not null check (request_count > 0),
  primary key (actor_id, operation, subject_hash, window_started_at)
);

create index web_rate_limit_buckets_cleanup_idx
  on private.web_rate_limit_buckets(window_started_at);
revoke all on table private.web_rate_limit_buckets from public, anon, authenticated;

create or replace function private.consume_web_rate_limit(
  target_operation text,
  target_subject_hash text default ''
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_user_id uuid := (select auth.uid());
  normalized_subject text := left(coalesce(target_subject_hash, ''), 128);
  operation_limit integer;
  current_count integer;
  current_window timestamptz := date_trunc('minute', statement_timestamp());
begin
  if actor_user_id is null then raise exception 'authentication_required'; end if;
  operation_limit := case target_operation
    when 'qr_validation' then 12
    when 'upload' then 20
    when 'payment_order' then 8
    when 'payment_review' then 30
    when 'submission' then 30
    when 'admin_search' then 60
    when 'push_subscription' then 10
    else null
  end;
  if operation_limit is null then raise exception 'rate_limit_operation_invalid'; end if;

  insert into private.web_rate_limit_buckets(
    actor_id, operation, subject_hash, window_started_at, request_count
  ) values (
    actor_user_id, target_operation, normalized_subject, current_window, 1
  )
  on conflict (actor_id, operation, subject_hash, window_started_at)
  do update set request_count = private.web_rate_limit_buckets.request_count + 1
  returning request_count into current_count;

  if current_count > operation_limit then
    raise exception 'rate_limit_exceeded';
  end if;
  return operation_limit - current_count;
end;
$$;

create or replace function public.consume_web_rate_limit(
  target_operation text,
  target_subject_hash text default ''
)
returns integer
language sql
security invoker
set search_path = ''
as $$
  select private.consume_web_rate_limit(target_operation, target_subject_hash);
$$;

revoke all on function private.consume_web_rate_limit(text,text) from public, anon;
grant execute on function private.consume_web_rate_limit(text,text) to authenticated;
revoke all on function public.consume_web_rate_limit(text,text) from public, anon;
grant execute on function public.consume_web_rate_limit(text,text) to authenticated;
