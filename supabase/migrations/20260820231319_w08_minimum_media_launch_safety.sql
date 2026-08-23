-- MSCWEB W08 minimum production launch safety.
-- Canonical deployment authority: repository-root supabase/ only.

create table if not exists private.coach_public_media_assets (
  id uuid primary key default gen_random_uuid(),
  coach_user_id uuid not null references public.profiles(user_id) on delete cascade,
  object_path text not null unique,
  media_folder text not null check (media_folder in ('avatar', 'items')),
  created_at timestamptz not null default statement_timestamp(),
  check (
    object_path ~ '^coaches/[0-9a-f-]{36}/(avatar|items)/[0-9a-f-]{36}\.jpg$'
  )
);

create index if not exists coach_public_media_assets_owner_idx
  on private.coach_public_media_assets(coach_user_id, media_folder, created_at desc);

revoke all on table private.coach_public_media_assets
  from public, anon, authenticated;
grant all on table private.coach_public_media_assets to service_role;

insert into private.coach_public_media_assets(coach_user_id, object_path, media_folder)
select draft.coach_user_id, draft.profile_photo_object_path, 'avatar'
from public.coach_public_profile_drafts draft
where draft.profile_photo_object_path is not null
on conflict (object_path) do nothing;

insert into private.coach_public_media_assets(coach_user_id, object_path, media_folder)
select published.coach_user_id, published.photo_reference, 'avatar'
from public.coach_public_profiles published
on conflict (object_path) do nothing;

insert into private.coach_public_media_assets(coach_user_id, object_path, media_folder)
select item.coach_user_id, item.media_object_path, 'items'
from public.coach_public_profile_items item
where item.media_object_path is not null
on conflict (object_path) do nothing;

update storage.buckets
set public = false, file_size_limit = 8388608,
  allowed_mime_types = array['image/jpeg']
where id = 'coach-public-media';

drop policy if exists "Public reads published Coach media" on storage.objects;

drop policy if exists "Coach and Admin read controlled Coach media" on storage.objects;
create policy "Coach and Admin read controlled Coach media"
on storage.objects for select to authenticated
using (
  bucket_id = 'coach-public-media'
  and (
    private.is_admin()
    or (
      (storage.foldername(name))[1] = 'coaches'
      and (storage.foldername(name))[2] = (
        select namespace.media_namespace::text
        from public.coach_public_media_namespaces namespace
        where namespace.coach_user_id = (select auth.uid())
      )
    )
  )
);

create or replace function private.register_coach_public_media_asset(
  target_coach_user_id uuid,
  target_object_path text,
  target_media_folder text
)
returns uuid
language plpgsql volatile security definer
set search_path = ''
as $$
declare
  namespace uuid;
  asset_id uuid;
begin
  if target_media_folder not in ('avatar', 'items') then
    raise exception 'profile_media_folder_invalid';
  end if;
  select media.media_namespace into namespace
  from public.coach_public_media_namespaces media
  where media.coach_user_id = target_coach_user_id;
  if namespace is null or target_object_path !~ (
    '^coaches/' || namespace::text || '/' || target_media_folder
      || '/[a-z0-9-]+\.jpg$'
  ) then
    raise exception 'profile_media_invalid';
  end if;
  if not exists (
    select 1 from storage.objects object
    where object.bucket_id = 'coach-public-media'
      and object.name = target_object_path
  ) then
    raise exception 'profile_media_missing';
  end if;
  insert into private.coach_public_media_assets(
    coach_user_id, object_path, media_folder
  ) values (
    target_coach_user_id, target_object_path, target_media_folder
  )
  on conflict (object_path) do update set
    coach_user_id = excluded.coach_user_id,
    media_folder = excluded.media_folder
  returning id into asset_id;
  return asset_id;
end;
$$;

revoke execute on function private.register_coach_public_media_asset(uuid,text,text)
  from public, anon, authenticated;

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
  result public.coach_public_profile_drafts;
begin
  if not private.has_active_coach_access(caller_id) then
    raise exception 'coach_entitlement_inactive';
  end if;
  select draft.public_handle into existing_handle
  from public.coach_public_profile_drafts draft
  where draft.coach_user_id = caller_id;
  if existing_handle is not null then normalized_handle := existing_handle; end if;
  if normalized_handle !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    or length(normalized_handle) not between 3 and 48 then
    raise exception 'public_handle_invalid';
  end if;
  if photo_object_path is not null then
    perform private.register_coach_public_media_asset(
      caller_id, photo_object_path, 'avatar'
    );
  end if;
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
  result public.coach_public_profile_items;
begin
  if not private.has_active_coach_access(caller_id) then
    raise exception 'coach_entitlement_inactive';
  end if;
  if item_kind not in ('testimonial', 'before_after') then
    raise exception 'profile_item_kind_invalid';
  end if;
  if includes_third_party and not permission_attested then
    raise exception 'third_party_permission_required';
  end if;
  if media_object_path is not null then
    perform private.register_coach_public_media_asset(
      caller_id, media_object_path, 'items'
    );
  end if;
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
      'photo_reference', avatar_asset.id,
      'professional_headline', published.professional_headline,
      'biography', published.biography,
      'service_area', published.service_area,
      'instagram_url', published.instagram_url,
      'tiktok_url', published.tiktok_url,
      'website_url', published.website_url,
      'whatsapp_number', published.whatsapp_number,
      'phone_number', published.phone_number,
      'is_verified', true,
      'items', coalesce((
        select jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
          'kind', item.item_kind,
          'title', item.title,
          'body', nullif(item.body, ''),
          'media_object_path', item_asset.id
        )) order by item.submitted_at)
        from public.coach_public_profile_items item
        left join private.coach_public_media_assets item_asset
          on item_asset.coach_user_id = item.coach_user_id
          and item_asset.object_path = item.media_object_path
        where item.coach_user_id = published.coach_user_id
          and item.moderation_status = 'approved'
          and item.is_public
      ), '[]'::jsonb)
    ))
    from public.coach_public_profiles published
    join public.profiles profile on profile.user_id = published.coach_user_id
    join private.coach_public_media_assets avatar_asset
      on avatar_asset.coach_user_id = published.coach_user_id
      and avatar_asset.object_path = published.photo_reference
      and avatar_asset.media_folder = 'avatar'
    where published.public_handle = lower(trim(target_handle))
      and profile.role = 'coach'
      and profile.coach_is_approved
      and profile.coach_is_public
      and private.has_active_coach_access(published.coach_user_id)
  ), 'null'::jsonb);
$$;

create or replace function public.resolve_public_coach_media_asset(
  target_asset_id uuid
)
returns text
language sql stable security definer
set search_path = ''
as $$
  select asset.object_path
  from private.coach_public_media_assets asset
  join public.profiles profile on profile.user_id = asset.coach_user_id
  where asset.id = target_asset_id
    and profile.role = 'coach'
    and profile.coach_is_approved
    and profile.coach_is_public
    and private.has_active_coach_access(asset.coach_user_id)
    and (
      exists (
        select 1 from public.coach_public_profiles published
        where published.coach_user_id = asset.coach_user_id
          and published.photo_reference = asset.object_path
      )
      or exists (
        select 1 from public.coach_public_profile_items item
        where item.coach_user_id = asset.coach_user_id
          and item.media_object_path = asset.object_path
          and item.moderation_status = 'approved'
          and item.is_public
      )
    )
  limit 1;
$$;

revoke execute on function public.resolve_public_coach_media_asset(uuid)
  from public, anon, authenticated;
grant execute on function public.resolve_public_coach_media_asset(uuid)
  to service_role;

alter table public.payment_evidence_attempts
  add column if not exists retention_previous_status text,
  add column if not exists retention_cleanup_claimed_at timestamptz;

alter table public.payment_evidence_attempts
  drop constraint if exists payment_evidence_attempts_status_check;
alter table public.payment_evidence_attempts
  add constraint payment_evidence_attempts_status_check check (
    status in ('prepared', 'submitted', 'rejected', 'approved', 'deleting', 'deleted')
  ),
  add constraint payment_evidence_attempts_retention_previous_status_check check (
    retention_previous_status is null
    or retention_previous_status in ('rejected', 'approved')
  ),
  add constraint payment_evidence_attempts_retention_claim_check check (
    (status = 'deleting' and retention_previous_status is not null
      and retention_cleanup_claimed_at is not null)
    or
    (status <> 'deleting' and retention_cleanup_claimed_at is null)
  );

create or replace function public.list_payment_evidence_retention_candidates(
  batch_size integer default 100,
  dry_run boolean default true
)
returns table(
  attempt_id uuid,
  object_name text,
  submitted_at timestamptz,
  is_dry_run boolean
)
language plpgsql security definer
set search_path = ''
as $$
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role'
    and not private.is_admin() then
    raise exception 'permission_denied';
  end if;
  if batch_size not between 1 and 500 then raise exception 'batch_size_invalid'; end if;
  return query
  select attempt.id, attempt.object_path, attempt.submitted_at, dry_run
  from public.payment_evidence_attempts attempt
  join public.payment_orders payment_order on payment_order.id = attempt.order_id
  join storage.objects object on object.bucket_id = 'payment-evidence'
    and object.name = attempt.object_path
  where attempt.status in ('approved', 'rejected')
    and attempt.submitted_at <= statement_timestamp() - interval '30 days'
    and payment_order.status not in (
      'awaiting_evidence', 'under_review', 'correction_required', 'reversal_pending'
    )
  order by attempt.submitted_at, attempt.id
  limit batch_size;
end;
$$;

create or replace function public.reconcile_payment_evidence_retention_claims()
returns integer
language plpgsql security definer
set search_path = ''
as $$
declare restored_count integer;
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role' then
    raise exception 'permission_denied';
  end if;
  update public.payment_evidence_attempts
  set status = retention_previous_status,
    retention_previous_status = null,
    retention_cleanup_claimed_at = null
  where status = 'deleting'
    and retention_cleanup_claimed_at < statement_timestamp() - interval '15 minutes';
  get diagnostics restored_count = row_count;
  return restored_count;
end;
$$;

create or replace function public.claim_payment_evidence_retention(
  target_attempt_id uuid
)
returns boolean
language plpgsql security definer
set search_path = ''
as $$
declare claimed boolean := false;
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role' then
    raise exception 'permission_denied';
  end if;
  update public.payment_evidence_attempts attempt
  set retention_previous_status = attempt.status,
    status = 'deleting',
    retention_cleanup_claimed_at = statement_timestamp()
  from public.payment_orders payment_order
  where attempt.id = target_attempt_id
    and payment_order.id = attempt.order_id
    and attempt.status in ('approved', 'rejected')
    and attempt.submitted_at <= statement_timestamp() - interval '30 days'
    and payment_order.status not in (
      'awaiting_evidence', 'under_review', 'correction_required', 'reversal_pending'
    )
    and exists (
      select 1 from storage.objects object
      where object.bucket_id = 'payment-evidence'
        and object.name = attempt.object_path
    );
  claimed := found;
  return claimed;
end;
$$;

create or replace function public.complete_payment_evidence_retention(
  target_attempt_id uuid
)
returns boolean
language plpgsql security definer
set search_path = ''
as $$
declare target_order_id uuid;
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role' then
    raise exception 'permission_denied';
  end if;
  update public.payment_evidence_attempts
  set status = 'deleted',
    deleted_at = statement_timestamp(),
    retention_cleanup_claimed_at = null
  where id = target_attempt_id
    and status = 'deleting'
  returning order_id into target_order_id;
  if target_order_id is null then return false; end if;
  insert into public.payment_events(order_id, attempt_id, event_type, metadata)
  values (
    target_order_id, target_attempt_id, 'evidence_file_deleted',
    jsonb_build_object('policy', 'submitted_plus_30_days')
  );
  return true;
end;
$$;

create or replace function public.release_payment_evidence_retention(
  target_attempt_id uuid
)
returns boolean
language plpgsql security definer
set search_path = ''
as $$
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role' then
    raise exception 'permission_denied';
  end if;
  update public.payment_evidence_attempts
  set status = retention_previous_status,
    retention_previous_status = null,
    retention_cleanup_claimed_at = null
  where id = target_attempt_id and status = 'deleting';
  return found;
end;
$$;

revoke all on function public.list_payment_evidence_retention_candidates(integer,boolean)
  from public, anon;
revoke all on function public.reconcile_payment_evidence_retention_claims()
  from public, anon, authenticated;
revoke all on function public.claim_payment_evidence_retention(uuid)
  from public, anon, authenticated;
revoke all on function public.complete_payment_evidence_retention(uuid)
  from public, anon, authenticated;
revoke all on function public.release_payment_evidence_retention(uuid)
  from public, anon, authenticated;
grant execute on function public.list_payment_evidence_retention_candidates(integer,boolean)
  to authenticated, service_role;
grant execute on function public.reconcile_payment_evidence_retention_claims()
  to service_role;
grant execute on function public.claim_payment_evidence_retention(uuid)
  to service_role;
grant execute on function public.complete_payment_evidence_retention(uuid)
  to service_role;
grant execute on function public.release_payment_evidence_retention(uuid)
  to service_role;

notify pgrst, 'reload schema';
