-- Keep every public/assigned Coach surface on the same published snapshot.
-- Draft fields and hidden contacts remain private; media is returned as an
-- opaque asset id that the controlled public gateway resolves.

create or replace function public.list_public_coaches(
  result_limit integer default 100,
  result_offset integer default 0
)
returns setof jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'id', profile.public_profile_id,
    'handle', published.public_handle,
    'display_name', published.display_name,
    'professional_headline', published.professional_headline,
    'biography', published.biography,
    'city', published.service_area,
    'photo_reference', avatar_asset.id,
    'is_verified', published.is_verified
  ))
  from public.coach_public_profiles published
  join public.profiles profile
    on profile.user_id = published.coach_user_id
  join private.coach_public_media_assets avatar_asset
    on avatar_asset.coach_user_id = published.coach_user_id
    and avatar_asset.object_path = published.photo_reference
    and avatar_asset.media_folder = 'avatar'
  where profile.role = 'coach'
    and profile.coach_is_approved
    and profile.coach_is_public
    and private.has_active_coach_access(published.coach_user_id)
  order by published.display_name, profile.public_profile_id
  limit least(greatest(result_limit, 1), 100)
  offset greatest(result_offset, 0);
$$;

create or replace function public.get_my_assigned_coach_profile()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.assert_active_account();

  return query
  select jsonb_strip_nulls(jsonb_build_object(
    'user_id', coach.user_id,
    'public_profile_id', coach.public_profile_id,
    'handle', published.public_handle,
    'display_name', coalesce(published.display_name, coach.display_name),
    'professional_headline', published.professional_headline,
    'biography', published.biography,
    'city', coalesce(published.service_area, nullif(coach.city, '')),
    'photo_reference', avatar_asset.id,
    'provider_avatar_url', null,
    'is_public', published.coach_user_id is not null,
    'is_approved', coach.coach_is_approved,
    'is_verified', coalesce(published.is_verified, false)
  ))
  from public.profiles program_participant
  join public.profiles coach
    on coach.user_id = program_participant.current_coach_id
  left join public.coach_public_profiles published
    on published.coach_user_id = coach.user_id
    and coach.coach_is_public
    and private.has_active_coach_access(coach.user_id)
  left join private.coach_public_media_assets avatar_asset
    on avatar_asset.coach_user_id = published.coach_user_id
    and avatar_asset.object_path = published.photo_reference
    and avatar_asset.media_folder = 'avatar'
  where program_participant.user_id = (select auth.uid())
    and program_participant.role in ('participant', 'coach')
    and coach.role = 'coach'
    and coach.coach_is_approved
  limit 1;
end;
$$;

revoke all on function public.list_public_coaches(integer, integer)
  from public, anon, authenticated;
revoke all on function public.get_my_assigned_coach_profile()
  from public, anon, authenticated;

grant execute on function public.list_public_coaches(integer, integer)
  to anon, authenticated;
grant execute on function public.get_my_assigned_coach_profile()
  to authenticated;

notify pgrst, 'reload schema';
