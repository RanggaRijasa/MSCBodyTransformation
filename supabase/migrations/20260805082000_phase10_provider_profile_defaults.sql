alter table public.profiles
  add column if not exists provider_avatar_url text;

alter table public.profiles
  drop constraint if exists profiles_provider_avatar_url_check;

alter table public.profiles
  add constraint profiles_provider_avatar_url_check
  check (
    provider_avatar_url is null
    or provider_avatar_url ~ '^https://'
  );

create or replace function private.normalized_signup_display_name(
  metadata jsonb
)
returns text
language sql
immutable
security invoker
set search_path = ''
as $$
  select coalesce(
    nullif(
      left(
        trim(
          regexp_replace(
            coalesce(
              metadata ->> 'display_name',
              metadata ->> 'full_name',
              metadata ->> 'name',
              ''
            ),
            '[[:cntrl:]]',
            '',
            'g'
          )
        ),
        80
      ),
      ''
    ),
    'Peserta baru'
  );
$$;

create or replace function private.provider_avatar_url(metadata jsonb)
returns text
language sql
immutable
security invoker
set search_path = ''
as $$
  select case
    when coalesce(
      nullif(metadata ->> 'avatar_url', ''),
      nullif(metadata ->> 'picture', '')
    ) ~ '^https://'
    then left(
      coalesce(
        nullif(metadata ->> 'avatar_url', ''),
        nullif(metadata ->> 'picture', '')
      ),
      2048
    )
    else null
  end;
$$;

create or replace function private.bootstrap_participant_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    user_id,
    role,
    display_name,
    provider_avatar_url,
    account_purpose,
    onboarding_status,
    provisional_expires_at,
    finalized_at,
    created_at,
    updated_at
  ) values (
    new.id,
    'participant',
    private.normalized_signup_display_name(new.raw_user_meta_data),
    private.provider_avatar_url(new.raw_user_meta_data),
    'participant',
    'provisional',
    now() + interval '24 hours',
    null,
    coalesce(new.created_at, now()),
    now()
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

update public.profiles as profiles
set provider_avatar_url =
      private.provider_avatar_url(users.raw_user_meta_data),
    updated_at = now()
from auth.users as users
where users.id = profiles.user_id
  and profiles.provider_avatar_url is null
  and private.provider_avatar_url(users.raw_user_meta_data) is not null;

update public.profiles as profiles
set display_name =
      private.normalized_signup_display_name(users.raw_user_meta_data),
    updated_at = now()
from auth.users as users
where users.id = profiles.user_id
  and profiles.onboarding_status = 'provisional'
  and profiles.display_name = 'Peserta baru'
  and private.normalized_signup_display_name(users.raw_user_meta_data)
      <> 'Peserta baru';

create or replace function public.apply_provider_profile_defaults(
  provider_display_name text default null,
  provider_avatar_url text default null
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  normalized_name text := nullif(
    left(
      trim(
        regexp_replace(
          coalesce(provider_display_name, ''),
          '[[:cntrl:]]',
          '',
          'g'
        )
      ),
      80
    ),
    ''
  );
  normalized_avatar text := nullif(
    left(trim(coalesce(provider_avatar_url, '')), 2048),
    ''
  );
  result public.profiles;
begin
  if caller_id is null then
    raise exception 'permission_denied';
  end if;

  if normalized_avatar is not null
     and normalized_avatar !~ '^https://' then
    raise exception 'provider_avatar_invalid';
  end if;

  update public.profiles
  set display_name = case
        when onboarding_status = 'provisional'
             and display_name = 'Peserta baru'
             and normalized_name is not null
        then normalized_name
        else display_name
      end,
      provider_avatar_url = case
        when onboarding_status = 'provisional'
             and public.profiles.provider_avatar_url is null
        then normalized_avatar
        else public.profiles.provider_avatar_url
      end,
      updated_at = now()
  where user_id = caller_id
  returning * into result;

  if result.user_id is null then
    raise exception 'profile_not_found';
  end if;

  return result;
end;
$$;

revoke all on function private.provider_avatar_url(jsonb) from public;
revoke all on function public.apply_provider_profile_defaults(text, text)
  from public;
grant execute on function public.apply_provider_profile_defaults(text, text)
  to authenticated;
