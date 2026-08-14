-- MSCWEB W06 Coach experience. See workplans/PHASE_06_COACH_EXPERIENCE.md.
-- This migration deliberately adds web-owned operations instead of changing the
-- native App Store purchase operations in the repository-root migrations.

create table if not exists public.coach_public_profile_drafts (
  coach_user_id uuid primary key references public.profiles(user_id) on delete cascade,
  public_handle text not null unique check (
    public_handle ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    and length(public_handle) between 3 and 48
  ),
  profile_photo_object_path text,
  professional_headline text not null default '' check (length(professional_headline) <= 120),
  biography text not null default '' check (length(biography) <= 2000),
  service_area text not null default '' check (length(service_area) <= 120),
  instagram_url text not null default '' check (length(instagram_url) <= 300),
  tiktok_url text not null default '' check (length(tiktok_url) <= 300),
  website_url text not null default '' check (length(website_url) <= 300),
  whatsapp_number text not null default '' check (length(whatsapp_number) <= 40),
  phone_number text not null default '' check (length(phone_number) <= 40),
  show_instagram boolean not null default false,
  show_tiktok boolean not null default false,
  show_website boolean not null default false,
  show_whatsapp boolean not null default false,
  show_phone boolean not null default false,
  updated_at timestamptz not null default statement_timestamp()
);

create table if not exists public.coach_public_media_namespaces (
  coach_user_id uuid primary key references public.profiles(user_id) on delete cascade,
  media_namespace uuid not null unique default gen_random_uuid()
);

create table if not exists public.coach_public_profiles (
  coach_user_id uuid primary key references public.profiles(user_id) on delete cascade,
  public_handle text not null unique references public.coach_public_profile_drafts(public_handle),
  display_name text not null,
  photo_kind text not null check (photo_kind = 'storage'),
  photo_reference text not null,
  professional_headline text,
  biography text,
  service_area text,
  instagram_url text,
  tiktok_url text,
  website_url text,
  whatsapp_number text,
  phone_number text,
  is_verified boolean not null default true check (is_verified),
  published_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp()
);

alter table public.coach_public_profiles
  drop constraint if exists coach_public_profiles_photo_kind_check;
alter table public.coach_public_profiles
  add constraint coach_public_profiles_photo_kind_check check (photo_kind = 'storage');

create table if not exists public.coach_public_profile_items (
  id uuid primary key default gen_random_uuid(),
  coach_user_id uuid not null references public.profiles(user_id) on delete cascade,
  item_kind text not null check (item_kind in ('testimonial', 'before_after')),
  title text not null check (length(trim(title)) between 1 and 120),
  body text not null default '' check (length(body) <= 1500),
  media_object_path text,
  includes_third_party boolean not null default false,
  permission_attested boolean not null default false,
  moderation_status text not null default 'pending' check (
    moderation_status in ('pending', 'approved', 'rejected')
  ),
  is_public boolean not null default true,
  submitted_at timestamptz not null default statement_timestamp(),
  moderated_at timestamptz,
  moderated_by uuid references public.profiles(user_id),
  moderation_note text,
  check (not includes_third_party or permission_attested)
);

create index if not exists coach_public_profile_items_owner_idx
  on public.coach_public_profile_items(coach_user_id, item_kind, submitted_at desc);

alter table public.coach_public_profile_drafts enable row level security;
alter table public.coach_public_profiles enable row level security;
alter table public.coach_public_profile_items enable row level security;
alter table public.coach_public_media_namespaces enable row level security;

revoke all on table
  public.coach_public_profile_drafts,
  public.coach_public_profiles,
  public.coach_public_profile_items,
  public.coach_public_media_namespaces
from public, anon, authenticated;
grant select on table public.coach_public_profile_drafts,
  public.coach_public_profile_items,
  public.coach_public_media_namespaces to authenticated;
grant all on table public.coach_public_profile_drafts,
  public.coach_public_profiles,
  public.coach_public_profile_items,
  public.coach_public_media_namespaces to service_role;

drop policy if exists "Coach reads own public media namespace"
  on public.coach_public_media_namespaces;
create policy "Coach reads own public media namespace"
on public.coach_public_media_namespaces for select to authenticated
using (coach_user_id = (select auth.uid()) or private.is_admin());

drop policy if exists "Coach reads own public profile draft"
  on public.coach_public_profile_drafts;
create policy "Coach reads own public profile draft"
on public.coach_public_profile_drafts for select to authenticated
using (coach_user_id = (select auth.uid()) or private.is_admin());

drop policy if exists "Coach reads own moderation items"
  on public.coach_public_profile_items;
create policy "Coach reads own moderation items"
on public.coach_public_profile_items for select to authenticated
using (coach_user_id = (select auth.uid()) or private.is_admin());

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('coach-public-media', 'coach-public-media', true, 8388608, array['image/jpeg'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public reads published Coach media" on storage.objects;
create policy "Public reads published Coach media"
on storage.objects for select to public
using (bucket_id = 'coach-public-media');

drop policy if exists "Active Coach uploads public profile media" on storage.objects;
create policy "Active Coach uploads public profile media"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'coach-public-media'
  and (storage.foldername(name))[1] = 'coaches'
  and (storage.foldername(name))[2] = (
    select namespace.media_namespace::text
    from public.coach_public_media_namespaces namespace
    where namespace.coach_user_id = (select auth.uid())
  )
  and exists (
    select 1 from public.profiles profile
    join public.coach_access_entitlements entitlement
      on entitlement.coach_user_id = profile.user_id
    where profile.user_id = (select auth.uid()) and profile.role = 'coach'
      and profile.coach_is_approved and entitlement.status = 'active'
      and entitlement.starts_at <= statement_timestamp()
      and entitlement.ends_at > statement_timestamp()
  )
);

drop policy if exists "Active Coach updates public profile media" on storage.objects;
create policy "Active Coach updates public profile media"
on storage.objects for update to authenticated
using (
  bucket_id = 'coach-public-media'
  and (storage.foldername(name))[1] = 'coaches'
  and (storage.foldername(name))[2] = (
    select namespace.media_namespace::text
    from public.coach_public_media_namespaces namespace
    where namespace.coach_user_id = (select auth.uid())
  )
  and exists (
    select 1 from public.profiles profile
    join public.coach_access_entitlements entitlement
      on entitlement.coach_user_id = profile.user_id
    where profile.user_id = (select auth.uid()) and profile.role = 'coach'
      and profile.coach_is_approved and entitlement.status = 'active'
      and entitlement.starts_at <= statement_timestamp()
      and entitlement.ends_at > statement_timestamp()
  )
)
with check (
  bucket_id = 'coach-public-media'
  and (storage.foldername(name))[1] = 'coaches'
  and (storage.foldername(name))[2] = (
    select namespace.media_namespace::text
    from public.coach_public_media_namespaces namespace
    where namespace.coach_user_id = (select auth.uid())
  )
  and exists (
    select 1 from public.profiles profile
    join public.coach_access_entitlements entitlement
      on entitlement.coach_user_id = profile.user_id
    where profile.user_id = (select auth.uid()) and profile.role = 'coach'
      and profile.coach_is_approved and entitlement.status = 'active'
      and entitlement.starts_at <= statement_timestamp()
      and entitlement.ends_at > statement_timestamp()
  )
);

drop policy if exists "Coach deletes own public profile media" on storage.objects;
create policy "Coach deletes own public profile media"
on storage.objects for delete to authenticated
using (
  bucket_id = 'coach-public-media'
  and (storage.foldername(name))[1] = 'coaches'
  and (storage.foldername(name))[2] = (
    select namespace.media_namespace::text
    from public.coach_public_media_namespaces namespace
    where namespace.coach_user_id = (select auth.uid())
  )
);

create or replace function private.web_coach_price_minor(member_level text)
returns bigint
language sql immutable
set search_path = ''
as $$
  select case
    when member_level in ('sc', 'sb') then 100000
    when member_level in ('supervisor', 'world_team') then 150000
    when member_level in ('tab_team', 'get_team', 'millionaire_team', 'presidents_team') then 200000
    else null
  end;
$$;

drop function if exists public.create_coach_payment_order(uuid, text);

create or replace function public.create_coach_payment_order(
  target_application_id uuid,
  request_idempotency_key text
)
returns public.payment_orders
language plpgsql security definer
set search_path = ''
as $$
declare
  actor_id uuid := (select auth.uid());
  application public.coach_applications;
  destination public.payment_destinations;
  existing public.payment_orders;
  result public.payment_orders;
  amount bigint;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if actor_id is null then raise exception 'authentication_required'; end if;
  select * into existing from public.payment_orders
  where owner_user_id = actor_id and idempotency_key = request_idempotency_key;
  if existing.id is not null then
    if existing.coach_application_id is distinct from target_application_id then
      raise exception 'idempotency_conflict';
    end if;
    return existing;
  end if;
  select * into application from public.coach_applications
  where id = target_application_id and applicant_user_id = actor_id for update;
  if application.id is null or application.status <> 'submitted'
    or not application.has_completed_hom_sts or not application.has_completed_ict then
    raise exception 'application_not_eligible';
  end if;
  amount := private.web_coach_price_minor(application.member_level_snapshot);
  if amount is null then raise exception 'application_not_eligible'; end if;
  select * into destination from private.current_payment_destination();
  if destination.id is null then raise exception 'payment_destination_unavailable'; end if;
  select * into existing from public.payment_orders
  where coach_application_id = application.id
    and status in ('awaiting_evidence', 'under_review', 'correction_required')
  for update;
  if existing.id is not null then return existing; end if;
  insert into public.payment_orders(
    owner_user_id, purpose, coach_application_id, amount_minor, declared_method,
    destination_id, destination_version, bank_code_snapshot, bank_name_snapshot,
    account_name_snapshot, account_reference_snapshot, qris_object_path_snapshot,
    instructions_snapshot, retention_after, timezone_snapshot, status,
    idempotency_key
  ) values (
    actor_id, 'coach_access', application.id, amount, 'bank_transfer',
    destination.id, destination.version, destination.bank_code,
    destination.bank_name, destination.account_name, destination.account_reference,
    destination.qris_object_path, destination.instructions,
    statement_timestamp() + interval '30 days', 'Asia/Jakarta',
    'awaiting_evidence', request_idempotency_key
  ) returning * into result;
  insert into public.payment_events(order_id, actor_id, event_type)
  values (result.id, actor_id, 'order_created');
  return result;
end;
$$;

create or replace function public.approve_coach_payment_and_activate(
  target_order_id uuid,
  expected_version integer,
  reconciled_amount_minor bigint,
  reconciliation_reference text,
  destination_matches boolean,
  request_idempotency_key text
)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  reviewer uuid := (select auth.uid());
  target_order public.payment_orders;
  application public.coach_applications;
  attempt public.payment_evidence_attempts;
  payment public.coach_payment_records;
  entitlement public.coach_access_entitlements;
  transaction_id uuid;
  generated_qr text;
  price_band text;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reconciliation_reference, ''))) < 4
    or not destination_matches then raise exception 'reconciliation_required'; end if;
  select * into target_order from public.payment_orders
  where id = target_order_id for update;
  if target_order.id is null or target_order.purpose <> 'coach_access' then
    raise exception 'payment_order_not_found';
  end if;
  select * into application from public.coach_applications
  where id = target_order.coach_application_id for update;
  if target_order.status = 'approved' and application.status = 'active' then
    return jsonb_build_object('order', to_jsonb(target_order), 'application', to_jsonb(application));
  end if;
  if target_order.version <> expected_version then raise exception 'version_conflict'; end if;
  if target_order.status <> 'under_review' then raise exception 'payment_order_not_reviewable'; end if;
  if application.status <> 'submitted' or application.member_level_snapshot = 'member'
    or not application.has_completed_hom_sts or not application.has_completed_ict then
    raise exception 'coach_eligibility_incomplete';
  end if;
  if reconciled_amount_minor <> target_order.amount_minor
    or target_order.amount_minor <> private.web_coach_price_minor(application.member_level_snapshot) then
    raise exception 'amount_mismatch';
  end if;
  select * into attempt from public.payment_evidence_attempts
  where order_id = target_order.id and status = 'submitted'
  order by attempt_number desc limit 1 for update;
  if attempt.id is null then raise exception 'payment_evidence_not_found'; end if;
  price_band := case
    when target_order.amount_minor = 100000 then 'entry'
    when target_order.amount_minor = 150000 then 'growth'
    else 'leadership'
  end;
  insert into public.commerce_transactions(
    platform, environment, external_transaction_id, participant_id,
    product_id, status, signed_payload_hash, purchased_at, subject_kind,
    coach_application_id, provider, product_type, currency_code,
    price_milliunits, last_event_at, expires_at
  ) values (
    'web', 'local', 'manual-coach:' || target_order.id::text,
    application.applicant_user_id, 'manual-coach:' || price_band,
    'verified', encode(extensions.digest(
      target_order.id::text || ':' || trim(reconciliation_reference), 'sha256'
    ), 'hex'), statement_timestamp(), 'coach_access', application.id,
    'manual_transfer', 'non_renewing_subscription', 'IDR',
    target_order.amount_minor * 1000, statement_timestamp(),
    statement_timestamp() + interval '3 months'
  ) on conflict (platform, environment, external_transaction_id)
  do update set last_event_at = excluded.last_event_at
  returning id into transaction_id;
  insert into public.coach_payment_records(
    application_id, state, price_band, amount_minor_units, duration_months,
    provider_reference, verified_at, transaction_id, period_sequence
  ) values (
    application.id, 'verified', price_band, target_order.amount_minor, 3,
    trim(reconciliation_reference), statement_timestamp(), transaction_id, 1
  ) on conflict (application_id, period_sequence) do update set
    state = 'verified', provider_reference = excluded.provider_reference,
    verified_at = excluded.verified_at, transaction_id = excluded.transaction_id,
    updated_at = statement_timestamp()
  returning * into payment;
  insert into public.coach_access_entitlements(
    application_id, payment_record_id, coach_user_id, status,
    starts_at, ends_at, period_sequence
  ) values (
    application.id, payment.id, application.applicant_user_id, 'active',
    statement_timestamp(), statement_timestamp() + interval '3 months', 1
  ) on conflict (application_id, period_sequence) do update set
    status = 'active', starts_at = excluded.starts_at, ends_at = excluded.ends_at,
    payment_record_id = excluded.payment_record_id, revoked_at = null
  returning * into entitlement;
  generated_qr := 'coach_' || pg_catalog.encode(extensions.gen_random_bytes(24), 'hex');
  update public.profiles set
    role = 'coach', coach_is_approved = true,
    coach_qr_identifier = coalesce(coach_qr_identifier, generated_qr),
    account_purpose = 'participant', updated_at = statement_timestamp()
  where user_id = application.applicant_user_id and role = 'participant';
  if not found then raise exception 'role_transition_invalid'; end if;
  update public.coach_applications set
    status = 'active', decided_at = statement_timestamp(), decided_by = reviewer,
    rejection_reason = null, decision_idempotency_key = request_idempotency_key,
    updated_at = statement_timestamp()
  where id = application.id returning * into application;
  update public.payment_evidence_attempts set
    status = 'approved', reviewed_at = statement_timestamp(),
    reviewed_by = reviewer, rejection_reason = null
  where id = attempt.id;
  insert into public.payment_ledger(
    order_id, entry_kind, amount_minor, currency, destination_version,
    reconciliation_reference, verified_by
  ) values (
    target_order.id, 'verified', target_order.amount_minor, target_order.currency,
    target_order.destination_version, trim(reconciliation_reference), reviewer
  ) on conflict (order_id, entry_kind) do nothing;
  update public.payment_orders set status = 'approved', version = version + 1,
    latest_rejection_reason = null, updated_at = statement_timestamp()
  where id = target_order.id returning * into target_order;
  insert into public.payment_events(order_id, attempt_id, actor_id, event_type)
  values (target_order.id, attempt.id, reviewer, 'payment_approved');
  insert into public.audit_events(kind, actor_id, subject_id, summary, payload)
  values (
    'coach_approved', reviewer, application.id,
    'Pembayaran disetujui dan akses Coach diaktifkan selama tiga bulan.',
    jsonb_build_object('payment_order_id', target_order.id,
      'entitlement_id', entitlement.id, 'transaction_id', transaction_id)
  );
  return jsonb_build_object('order', to_jsonb(target_order),
    'application', to_jsonb(application), 'entitlement', to_jsonb(entitlement));
end;
$$;

create or replace function public.reject_coach_application_and_payment(
  target_order_id uuid,
  expected_version integer,
  rejection_reason text,
  request_idempotency_key text
)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  reviewer uuid := (select auth.uid());
  target_order public.payment_orders;
  application public.coach_applications;
  normalized_reason text := trim(rejection_reason);
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(coalesce(normalized_reason, '')) < 5 then raise exception 'reason_required'; end if;
  select * into target_order from public.payment_orders where id = target_order_id for update;
  if target_order.id is null or target_order.purpose <> 'coach_access' then
    raise exception 'payment_order_not_found'; end if;
  select * into application from public.coach_applications
  where id = target_order.coach_application_id for update;
  if target_order.status = 'rejected' and application.status = 'rejected'
    and application.decision_idempotency_key = request_idempotency_key then
    return jsonb_build_object('order', to_jsonb(target_order), 'application', to_jsonb(application));
  end if;
  if target_order.version <> expected_version then raise exception 'version_conflict'; end if;
  if target_order.status <> 'under_review' or application.status <> 'submitted' then
    raise exception 'application_already_decided'; end if;
  update public.payment_evidence_attempts set status = 'rejected',
    reviewed_at = statement_timestamp(), reviewed_by = reviewer,
    rejection_reason = normalized_reason
  where order_id = target_order.id and status = 'submitted';
  update public.payment_orders set status = 'rejected', version = version + 1,
    latest_rejection_reason = normalized_reason, updated_at = statement_timestamp()
  where id = target_order.id returning * into target_order;
  update public.coach_applications set status = 'rejected',
    decided_at = statement_timestamp(), decided_by = reviewer,
    rejection_reason = normalized_reason,
    decision_idempotency_key = request_idempotency_key,
    updated_at = statement_timestamp()
  where id = application.id returning * into application;
  insert into public.payment_events(order_id, actor_id, event_type, metadata)
  values (target_order.id, reviewer, 'evidence_rejected', jsonb_build_object('reason', normalized_reason));
  insert into public.audit_events(kind, actor_id, subject_id, summary, payload)
  values ('coach_application_rejected', reviewer, application.id,
    normalized_reason, jsonb_build_object('payment_order_id', target_order.id));
  return jsonb_build_object('order', to_jsonb(target_order), 'application', to_jsonb(application));
end;
$$;

create or replace function public.get_my_coach_workspace()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  result jsonb;
begin
  if caller_id is null then raise exception 'authentication_required'; end if;
  if not private.has_active_coach_access(caller_id) then
    raise exception 'coach_entitlement_inactive';
  end if;
  select jsonb_build_object(
    'profile', jsonb_build_object(
      'display_name', profile.display_name,
      'city', profile.city,
      'provider_avatar_url', profile.provider_avatar_url,
      'profile_avatar_path', profile.profile_avatar_path
    ),
    'entitlement', (
      select jsonb_build_object('starts_at', entitlement.starts_at, 'ends_at', entitlement.ends_at)
      from public.coach_access_entitlements entitlement
      where entitlement.coach_user_id = caller_id and entitlement.status = 'active'
        and entitlement.starts_at <= statement_timestamp()
        and entitlement.ends_at > statement_timestamp()
      order by entitlement.ends_at desc limit 1
    ),
    'pending_review_count', (
      select count(*) from public.step_submissions submission
      join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
      where enrollment.coach_id = caller_id and submission.status = 'pending'
    ),
    'assigned_participant_count', (
      select count(distinct enrollment.participant_id)
      from public.program_enrollments enrollment
      where enrollment.coach_id = caller_id and enrollment.status in ('active', 'completed')
    ),
    'participants', coalesce((
      select jsonb_agg(jsonb_build_object(
        'participant_id', enrollment.participant_id,
        'display_name', participant.display_name,
        'avatar_url', participant.provider_avatar_url,
        'city', participant.city,
        'program_id', program.id,
        'program_title', program.title,
        'enrollment_status', enrollment.status,
        'progress_percentage', coalesce(score.progress_percentage, 0),
        'total_points', coalesce(score.activity_points, 0) + coalesce(score.quiz_points, 0)
          + coalesce(score.weight_points, 0) + coalesce(score.adjustment_points, 0),
        'rank', score.rank
      ) order by participant.display_name, program.title)
      from public.program_enrollments enrollment
      join public.profiles participant on participant.user_id = enrollment.participant_id
      join public.programs program on program.id = enrollment.program_id
      left join public.program_scores score on score.enrollment_id = enrollment.id
      where enrollment.coach_id = caller_id and enrollment.status in ('active', 'completed')
    ), '[]'::jsonb),
    'activity', coalesce((
      select jsonb_agg(jsonb_build_object(
        'submission_id', activity.id,
        'participant_name', activity.participant_name,
        'program_title', activity.program_title,
        'step_title', activity.step_title,
        'status', activity.status,
        'submitted_at', activity.submitted_at
      ) order by activity.submitted_at desc)
      from (
        select submission.id, participant.display_name participant_name,
          program.title program_title, step.title step_title,
          submission.status, submission.submitted_at
        from public.step_submissions submission
        join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
        join public.profiles participant on participant.user_id = enrollment.participant_id
        join public.programs program on program.id = enrollment.program_id
        join public.program_steps step on step.id = submission.step_id
        where enrollment.coach_id = caller_id and submission.status <> 'draft'
        order by submission.submitted_at desc limit 30
      ) activity
    ), '[]'::jsonb),
    'programs', coalesce((
      select jsonb_agg(jsonb_build_object(
        'program_id', program.id, 'title', program.title, 'status', program.status,
        'starts_on', program.starts_on, 'ends_on', program.ends_on,
        'timezone', program.timezone, 'participant_count', grouped.participant_count,
        'pending_review_count', grouped.pending_review_count
      ) order by program.starts_on desc)
      from (
        select enrollment.program_id,
          count(distinct enrollment.participant_id)::integer participant_count,
          count(submission.id) filter (where submission.status = 'pending')::integer pending_review_count
        from public.program_enrollments enrollment
        left join public.step_submissions submission on submission.enrollment_id = enrollment.id
        where enrollment.coach_id = caller_id and enrollment.status in ('active', 'completed')
        group by enrollment.program_id
      ) grouped
      join public.programs program on program.id = grouped.program_id
    ), '[]'::jsonb),
    'leaderboard', coalesce((
      select jsonb_agg(jsonb_build_object(
        'participant_id', enrollment.participant_id,
        'display_name', participant.display_name,
        'avatar_url', participant.provider_avatar_url,
        'program_id', enrollment.program_id,
        'program_title', program.title,
        'rank', score.rank,
        'progress_percentage', score.progress_percentage,
        'total_points', score.activity_points + score.quiz_points
          + score.weight_points + score.adjustment_points
      ) order by score.rank nulls last, participant.display_name)
      from public.program_enrollments enrollment
      join public.program_scores score on score.enrollment_id = enrollment.id
      join public.profiles participant on participant.user_id = enrollment.participant_id
      join public.programs program on program.id = enrollment.program_id
      where enrollment.coach_id = caller_id and enrollment.status in ('active', 'completed')
    ), '[]'::jsonb),
    'qr_payload', profile.coach_qr_identifier
  ) into result
  from public.profiles profile where profile.user_id = caller_id;
  return result;
end;
$$;

create or replace function public.get_my_coach_public_profile_draft()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
begin
  if not private.has_active_coach_access(caller_id) then
    raise exception 'coach_entitlement_inactive'; end if;
  return jsonb_build_object(
    'identity', (select jsonb_build_object(
      'display_name', profile.display_name,
      'provider_avatar_url', profile.provider_avatar_url,
      'profile_avatar_path', profile.profile_avatar_path,
      'is_verified', profile.coach_is_approved
    ) from public.profiles profile where profile.user_id = caller_id),
    'draft', (select to_jsonb(draft) from public.coach_public_profile_drafts draft
      where draft.coach_user_id = caller_id),
    'published', exists(select 1 from public.coach_public_profiles published
      where published.coach_user_id = caller_id),
    'items', coalesce((select jsonb_agg(to_jsonb(item) order by item.submitted_at desc)
      from public.coach_public_profile_items item where item.coach_user_id = caller_id), '[]'::jsonb)
  );
end;
$$;

create or replace function public.allocate_my_coach_public_media_path(media_folder text)
returns text
language plpgsql volatile security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  namespace uuid;
begin
  if not private.has_active_coach_access(caller_id) then
    raise exception 'coach_entitlement_inactive'; end if;
  if media_folder not in ('avatar', 'items') then
    raise exception 'profile_media_folder_invalid'; end if;
  insert into public.coach_public_media_namespaces(coach_user_id)
  values (caller_id) on conflict (coach_user_id) do nothing;
  select media.media_namespace into namespace
  from public.coach_public_media_namespaces media
  where media.coach_user_id = caller_id;
  return 'coaches/' || namespace::text || '/' || media_folder || '/'
    || gen_random_uuid()::text || '.jpg';
end;
$$;

create or replace function public.save_my_coach_public_profile_draft(
  requested_handle text,
  photo_object_path text,
  professional_headline text,
  biography text,
  service_area text,
  instagram_url text,
  tiktok_url text,
  website_url text,
  whatsapp_number text,
  phone_number text,
  show_instagram boolean,
  show_tiktok boolean,
  show_website boolean,
  show_whatsapp boolean,
  show_phone boolean
)
returns public.coach_public_profile_drafts
language plpgsql security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  normalized_handle text := lower(trim(requested_handle));
  existing_handle text;
  media_namespace uuid;
  result public.coach_public_profile_drafts;
begin
  if not private.has_active_coach_access(caller_id) then
    raise exception 'coach_entitlement_inactive'; end if;
  select draft.public_handle into existing_handle
  from public.coach_public_profile_drafts draft where draft.coach_user_id = caller_id;
  if existing_handle is not null then normalized_handle := existing_handle; end if;
  if normalized_handle !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    or length(normalized_handle) not between 3 and 48 then
    raise exception 'public_handle_invalid'; end if;
  select media.media_namespace into media_namespace
  from public.coach_public_media_namespaces media
  where media.coach_user_id = caller_id;
  if photo_object_path is not null and (
    media_namespace is null or photo_object_path !~ (
      '^coaches/' || media_namespace::text || '/avatar/[a-z0-9-]+\.jpg$'
    )
  ) then raise exception 'profile_media_invalid'; end if;
  insert into public.coach_public_profile_drafts(
    coach_user_id, public_handle, profile_photo_object_path,
    professional_headline, biography, service_area, instagram_url, tiktok_url,
    website_url, whatsapp_number, phone_number, show_instagram, show_tiktok,
    show_website, show_whatsapp, show_phone, updated_at
  ) values (
    caller_id, normalized_handle, photo_object_path,
    trim(professional_headline), trim(biography), trim(service_area),
    trim(instagram_url), trim(tiktok_url), trim(website_url),
    trim(whatsapp_number), trim(phone_number), show_instagram, show_tiktok,
    show_website, show_whatsapp, show_phone, statement_timestamp()
  ) on conflict (coach_user_id) do update set
    profile_photo_object_path = excluded.profile_photo_object_path,
    professional_headline = excluded.professional_headline,
    biography = excluded.biography, service_area = excluded.service_area,
    instagram_url = excluded.instagram_url, tiktok_url = excluded.tiktok_url,
    website_url = excluded.website_url, whatsapp_number = excluded.whatsapp_number,
    phone_number = excluded.phone_number, show_instagram = excluded.show_instagram,
    show_tiktok = excluded.show_tiktok, show_website = excluded.show_website,
    show_whatsapp = excluded.show_whatsapp, show_phone = excluded.show_phone,
    updated_at = statement_timestamp()
  returning * into result;
  return result;
exception when unique_violation then
  raise exception 'public_handle_unavailable';
end;
$$;

create or replace function public.submit_my_coach_public_profile_item(
  item_kind text,
  title text,
  body text,
  media_object_path text,
  includes_third_party boolean,
  permission_attested boolean
)
returns public.coach_public_profile_items
language plpgsql security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  media_namespace uuid;
  result public.coach_public_profile_items;
begin
  if not private.has_active_coach_access(caller_id) then
    raise exception 'coach_entitlement_inactive'; end if;
  if item_kind not in ('testimonial', 'before_after') then
    raise exception 'profile_item_kind_invalid'; end if;
  if includes_third_party and not permission_attested then
    raise exception 'third_party_permission_required'; end if;
  select media.media_namespace into media_namespace
  from public.coach_public_media_namespaces media
  where media.coach_user_id = caller_id;
  if media_object_path is not null and (
    media_namespace is null or media_object_path !~ (
      '^coaches/' || media_namespace::text || '/items/[a-z0-9-]+\.jpg$'
    )
  ) then raise exception 'profile_media_invalid'; end if;
  insert into public.coach_public_profile_items(
    coach_user_id, item_kind, title, body, media_object_path,
    includes_third_party, permission_attested
  ) values (
    caller_id, item_kind, trim(title), trim(body), media_object_path,
    includes_third_party, permission_attested
  ) returning * into result;
  return result;
end;
$$;

create or replace function public.moderate_coach_public_profile_item(
  target_item_id uuid,
  decision text,
  note text
)
returns public.coach_public_profile_items
language plpgsql security definer
set search_path = ''
as $$
declare result public.coach_public_profile_items;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if decision not in ('approved', 'rejected') then raise exception 'decision_invalid'; end if;
  update public.coach_public_profile_items set moderation_status = decision,
    moderated_at = statement_timestamp(), moderated_by = (select auth.uid()),
    moderation_note = nullif(trim(note), '')
  where id = target_item_id returning * into result;
  if result.id is null then raise exception 'profile_item_not_found'; end if;
  return result;
end;
$$;

create or replace function public.get_public_coach_profile(target_handle text)
returns jsonb
language sql stable security definer
set search_path = ''
as $$
  select coalesce((
    select jsonb_strip_nulls(jsonb_build_object(
      'handle', published.public_handle,
      'display_name', published.display_name,
      'photo_kind', published.photo_kind,
      'photo_reference', published.photo_reference,
      'professional_headline', published.professional_headline,
      'biography', published.biography,
      'service_area', published.service_area,
      'instagram_url', published.instagram_url,
      'tiktok_url', published.tiktok_url,
      'website_url', published.website_url,
      'whatsapp_number', published.whatsapp_number,
      'phone_number', published.phone_number,
      'is_verified', true,
      'items', coalesce((select jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
        'kind', item.item_kind, 'title', item.title, 'body', nullif(item.body, ''),
        'media_object_path', item.media_object_path
      )) order by item.submitted_at)
      from public.coach_public_profile_items item
      where item.coach_user_id = published.coach_user_id
        and item.moderation_status = 'approved' and item.is_public), '[]'::jsonb)
    ))
    from public.coach_public_profiles published
    join public.profiles profile on profile.user_id = published.coach_user_id
    where published.public_handle = lower(trim(target_handle))
      and profile.role = 'coach' and profile.coach_is_approved
      and profile.coach_is_public
      and private.has_active_coach_access(published.coach_user_id)
  ), 'null'::jsonb);
$$;

create or replace function public.publish_my_coach_public_profile()
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  profile public.profiles;
  draft public.coach_public_profile_drafts;
begin
  if not private.has_active_coach_access(caller_id) then raise exception 'coach_entitlement_inactive'; end if;
  select * into profile from public.profiles where user_id = caller_id for update;
  select * into draft from public.coach_public_profile_drafts where coach_user_id = caller_id for update;
  if draft.coach_user_id is null then raise exception 'profile_draft_missing'; end if;
  if draft.profile_photo_object_path is null then raise exception 'profile_photo_required'; end if;
  insert into public.coach_public_profiles(
    coach_user_id, public_handle, display_name, photo_kind, photo_reference,
    professional_headline, biography, service_area, instagram_url, tiktok_url,
    website_url, whatsapp_number, phone_number, is_verified, published_at, updated_at
  ) values (
    caller_id, draft.public_handle, profile.display_name, 'storage', draft.profile_photo_object_path,
    nullif(draft.professional_headline, ''), nullif(draft.biography, ''), nullif(draft.service_area, ''),
    case when draft.show_instagram then nullif(draft.instagram_url, '') end,
    case when draft.show_tiktok then nullif(draft.tiktok_url, '') end,
    case when draft.show_website then nullif(draft.website_url, '') end,
    case when draft.show_whatsapp then nullif(draft.whatsapp_number, '') end,
    case when draft.show_phone then nullif(draft.phone_number, '') end,
    true, statement_timestamp(), statement_timestamp()
  ) on conflict (coach_user_id) do update set
    display_name = excluded.display_name, photo_kind = excluded.photo_kind,
    photo_reference = excluded.photo_reference, professional_headline = excluded.professional_headline,
    biography = excluded.biography, service_area = excluded.service_area,
    instagram_url = excluded.instagram_url, tiktok_url = excluded.tiktok_url,
    website_url = excluded.website_url, whatsapp_number = excluded.whatsapp_number,
    phone_number = excluded.phone_number, is_verified = true, updated_at = statement_timestamp();
  update public.profiles set coach_is_public = true, updated_at = statement_timestamp()
  where user_id = caller_id;
  return public.get_public_coach_profile(draft.public_handle);
end;
$$;

revoke execute on function private.web_coach_price_minor(text) from public, anon, authenticated;
revoke execute on function public.create_coach_payment_order(uuid,text) from public, anon;
revoke execute on function public.approve_coach_payment_and_activate(uuid,integer,bigint,text,boolean,text) from public, anon;
revoke execute on function public.reject_coach_application_and_payment(uuid,integer,text,text) from public, anon;
revoke execute on function public.get_my_coach_workspace() from public, anon;
revoke execute on function public.get_my_coach_public_profile_draft() from public, anon;
revoke execute on function public.allocate_my_coach_public_media_path(text) from public, anon;
revoke execute on function public.save_my_coach_public_profile_draft(text,text,text,text,text,text,text,text,text,text,boolean,boolean,boolean,boolean,boolean) from public, anon;
revoke execute on function public.submit_my_coach_public_profile_item(text,text,text,text,boolean,boolean) from public, anon;
revoke execute on function public.moderate_coach_public_profile_item(uuid,text,text) from public, anon;
revoke execute on function public.publish_my_coach_public_profile() from public, anon;
revoke execute on function public.get_public_coach_profile(text) from public;

grant execute on function public.create_coach_payment_order(uuid,text) to authenticated;
grant execute on function public.approve_coach_payment_and_activate(uuid,integer,bigint,text,boolean,text) to authenticated;
grant execute on function public.reject_coach_application_and_payment(uuid,integer,text,text) to authenticated;
grant execute on function public.get_my_coach_workspace() to authenticated;
grant execute on function public.get_my_coach_public_profile_draft() to authenticated;
grant execute on function public.allocate_my_coach_public_media_path(text) to authenticated;
grant execute on function public.save_my_coach_public_profile_draft(text,text,text,text,text,text,text,text,text,text,boolean,boolean,boolean,boolean,boolean) to authenticated;
grant execute on function public.submit_my_coach_public_profile_item(text,text,text,text,boolean,boolean) to authenticated;
grant execute on function public.moderate_coach_public_profile_item(uuid,text,text) to authenticated;
grant execute on function public.publish_my_coach_public_profile() to authenticated;
grant execute on function public.get_public_coach_profile(text) to anon, authenticated;

notify pgrst, 'reload schema';
