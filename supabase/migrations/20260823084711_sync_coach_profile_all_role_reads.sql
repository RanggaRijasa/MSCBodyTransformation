-- Keep authenticated Coach and Admin read models on the same published Coach
-- snapshot used by /c/:handle. Private account data remains sourced from
-- profiles, while public media is exposed only as an opaque gateway asset id.

alter function public.get_my_coach_workspace() set schema private;
alter function private.get_my_coach_workspace() rename to get_my_coach_workspace_before_public_profile_sync;

revoke all on function private.get_my_coach_workspace_before_public_profile_sync()
  from public, anon, authenticated;

create or replace function public.get_my_coach_workspace()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  workspace jsonb;
  synced_profile jsonb;
begin
  if caller_id is null then
    raise exception 'authentication_required';
  end if;

  workspace := private.get_my_coach_workspace_before_public_profile_sync();
  if workspace is null then
    return null;
  end if;

  select jsonb_strip_nulls(jsonb_build_object(
    'display_name', coalesce(published.display_name, profile.display_name),
    'city', coalesce(nullif(published.service_area, ''), profile.city),
    'professional_headline', published.professional_headline,
    'photo_reference', avatar_asset.id,
    'provider_avatar_url', profile.provider_avatar_url,
    'profile_avatar_path', null
  ))
  into synced_profile
  from public.profiles profile
  left join public.coach_public_profiles published
    on published.coach_user_id = profile.user_id
  left join private.coach_public_media_assets avatar_asset
    on avatar_asset.coach_user_id = published.coach_user_id
    and avatar_asset.object_path = published.photo_reference
    and avatar_asset.media_folder = 'avatar'
  where profile.user_id = caller_id;

  return jsonb_set(
    workspace,
    '{profile}',
    coalesce(workspace -> 'profile', '{}'::jsonb) || coalesce(synced_profile, '{}'::jsonb),
    true
  );
end;
$$;

create or replace function public.list_admin_people()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'permission_denied';
  end if;

  return query
  select jsonb_strip_nulls(jsonb_build_object(
    'user_id', profile.user_id,
    'role', profile.role,
    'display_name', case
      when profile.role = 'coach' then coalesce(published.display_name, profile.display_name)
      else profile.display_name
    end,
    'city', case
      when profile.role = 'coach' then coalesce(nullif(published.service_area, ''), profile.city)
      else profile.city
    end,
    'professional_headline', case when profile.role = 'coach' then published.professional_headline end,
    'photo_reference', case when profile.role = 'coach' then avatar_asset.id end,
    'provider_avatar_url', profile.provider_avatar_url,
    'member_level', profile.member_level,
    'current_coach_id', profile.current_coach_id,
    'current_coach_name', coalesce(current_coach_published.display_name, coach.display_name),
    'coach_is_approved', profile.coach_is_approved,
    'coach_is_public', profile.coach_is_public,
    'application_id', application.id,
    'application_status', application.status,
    'public_handle', coalesce(published.public_handle, draft.public_handle),
    'profile_published', published.coach_user_id is not null,
    'created_at', profile.created_at
  ))
  from public.profiles profile
  left join public.profiles coach
    on coach.user_id = profile.current_coach_id
  left join public.coach_public_profiles current_coach_published
    on current_coach_published.coach_user_id = coach.user_id
  left join lateral (
    select item.id, item.status
    from public.coach_applications item
    where item.applicant_user_id = profile.user_id
    order by item.created_at desc, item.id
    limit 1
  ) application on true
  left join public.coach_public_profile_drafts draft
    on draft.coach_user_id = profile.user_id
  left join public.coach_public_profiles published
    on published.coach_user_id = profile.user_id
  left join private.coach_public_media_assets avatar_asset
    on avatar_asset.coach_user_id = published.coach_user_id
    and avatar_asset.object_path = published.photo_reference
    and avatar_asset.media_folder = 'avatar'
  order by coalesce(published.display_name, profile.display_name), profile.user_id;
end;
$$;

create or replace function public.get_admin_person_detail(target_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'permission_denied';
  end if;

  return coalesce((
    select jsonb_strip_nulls(jsonb_build_object(
      'user_id', profile.user_id,
      'role', profile.role,
      'display_name', case
        when profile.role = 'coach' then coalesce(published.display_name, profile.display_name)
        else profile.display_name
      end,
      'email', identity.email,
      'city', case
        when profile.role = 'coach' then coalesce(nullif(published.service_area, ''), profile.city)
        else profile.city
      end,
      'phone_number', profile.phone_number,
      'professional_headline', case when profile.role = 'coach' then published.professional_headline end,
      'photo_reference', case when profile.role = 'coach' then avatar_asset.id end,
      'provider_avatar_url', profile.provider_avatar_url,
      'member_level', profile.member_level,
      'current_coach_id', profile.current_coach_id,
      'current_coach_name', coalesce(current_coach_published.display_name, coach.display_name),
      'coach_is_approved', profile.coach_is_approved,
      'coach_is_public', profile.coach_is_public,
      'coach_biography', case
        when profile.role = 'coach' then coalesce(nullif(published.biography, ''), profile.coach_biography)
        else profile.coach_biography
      end,
      'application_id', application.id,
      'application_status', application.status,
      'public_handle', coalesce(published.public_handle, draft.public_handle),
      'profile_published', published.coach_user_id is not null,
      'created_at', profile.created_at
    ))
    from public.profiles profile
    left join auth.users identity
      on identity.id = profile.user_id
    left join public.profiles coach
      on coach.user_id = profile.current_coach_id
    left join public.coach_public_profiles current_coach_published
      on current_coach_published.coach_user_id = coach.user_id
    left join lateral (
      select item.id, item.status
      from public.coach_applications item
      where item.applicant_user_id = profile.user_id
      order by item.created_at desc, item.id
      limit 1
    ) application on true
    left join public.coach_public_profile_drafts draft
      on draft.coach_user_id = profile.user_id
    left join public.coach_public_profiles published
      on published.coach_user_id = profile.user_id
    left join private.coach_public_media_assets avatar_asset
      on avatar_asset.coach_user_id = published.coach_user_id
      and avatar_asset.object_path = published.photo_reference
      and avatar_asset.media_folder = 'avatar'
    where profile.user_id = target_user_id
  ), '{}'::jsonb);
end;
$$;

revoke all on function public.get_my_coach_workspace()
  from public, anon, authenticated;
revoke all on function public.list_admin_people()
  from public, anon, authenticated;
revoke all on function public.get_admin_person_detail(uuid)
  from public, anon, authenticated;

grant execute on function public.get_my_coach_workspace()
  to authenticated;
grant execute on function public.list_admin_people()
  to authenticated;
grant execute on function public.get_admin_person_detail(uuid)
  to authenticated;

notify pgrst, 'reload schema';
