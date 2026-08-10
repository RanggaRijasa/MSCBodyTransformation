-- Phase 09 Web: missing Admin lifecycle operations. This migration is additive
-- and is exercised against local Supabase only until production deployment is
-- separately authorized.

alter table public.programs
  add column if not exists archive_idempotency_key text,
  add constraint programs_archive_idempotency_key_shape check (
    archive_idempotency_key is null
    or length(archive_idempotency_key) between 8 and 128
  );

alter table public.winner_posters
  add column if not exists mutation_idempotency_key text,
  add column if not exists deleted_at timestamptz,
  add constraint winner_posters_mutation_idempotency_key_shape check (
    mutation_idempotency_key is null
    or length(mutation_idempotency_key) between 8 and 128
  );

create unique index if not exists winner_posters_mutation_idempotency_idx
  on public.winner_posters(mutation_idempotency_key)
  where mutation_idempotency_key is not null;

create or replace function public.archive_program(
  target_program_id uuid,
  reason text,
  request_idempotency_key text
)
returns public.programs
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.programs;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reason, ''))) = 0 then raise exception 'reason_required'; end if;

  select * into target from public.programs
  where id = target_program_id for update;
  if target.id is null then raise exception 'program_not_found'; end if;
  if target.status = 'archived'
    and target.archive_idempotency_key = request_idempotency_key
  then return target; end if;
  if target.status <> 'completed' then raise exception 'program_not_archivable'; end if;
  if not exists (
    select 1 from public.winner_snapshots where program_id = target.id
  ) then raise exception 'winners_not_locked'; end if;

  update public.programs
  set status = 'archived',
      archive_idempotency_key = request_idempotency_key,
      updated_at = statement_timestamp()
  where id = target.id
  returning * into target;

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()), 'program_archived', target.id, trim(reason),
    jsonb_build_object('idempotency_key', request_idempotency_key)
  );
  return target;
end;
$$;

create or replace function public.manage_winner_poster(
  target_poster_id uuid,
  target_program_id uuid,
  target_snapshot_id uuid,
  target_media_path text,
  target_alt_text text,
  operation text,
  reason text,
  request_idempotency_key text
)
returns public.winner_posters
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.winner_posters;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if operation not in ('add', 'replace', 'publish', 'delete') then
    raise exception 'operation_invalid';
  end if;
  if length(trim(coalesce(reason, ''))) = 0 then raise exception 'reason_required'; end if;

  select * into result from public.winner_posters
  where mutation_idempotency_key = request_idempotency_key;
  if result.id is not null then return result; end if;

  if operation = 'add' then
    if target_poster_id is null then raise exception 'poster_id_required'; end if;
    if length(trim(coalesce(target_media_path, ''))) = 0 then raise exception 'media_required'; end if;
    if length(trim(coalesce(target_alt_text, ''))) = 0 then raise exception 'alt_text_required'; end if;
    if not exists (
      select 1 from public.winner_snapshots
      where id = target_snapshot_id and program_id = target_program_id
    ) then raise exception 'winner_snapshot_mismatch'; end if;
    if not exists (
      select 1 from storage.objects
      where bucket_id = 'public-media' and name = target_media_path
    ) then raise exception 'media_not_found'; end if;
    insert into public.winner_posters(
      id, program_id, winner_snapshot_id, media_path, alt_text,
      is_published, mutation_idempotency_key
    ) values (
      target_poster_id, target_program_id, target_snapshot_id,
      target_media_path, trim(target_alt_text), false, request_idempotency_key
    ) returning * into result;
  else
    select * into result from public.winner_posters
    where id = target_poster_id for update;
    if result.id is null or result.deleted_at is not null then
      raise exception 'poster_not_found';
    end if;
    if operation = 'replace' then
      if length(trim(coalesce(target_media_path, ''))) = 0 then raise exception 'media_required'; end if;
      if length(trim(coalesce(target_alt_text, ''))) = 0 then raise exception 'alt_text_required'; end if;
      if not exists (
        select 1 from storage.objects
        where bucket_id = 'public-media' and name = target_media_path
      ) then raise exception 'media_not_found'; end if;
      update public.winner_posters set
        media_path = target_media_path,
        alt_text = trim(target_alt_text),
        is_published = false,
        published_at = null,
        mutation_idempotency_key = request_idempotency_key
      where id = result.id returning * into result;
    elsif operation = 'publish' then
      update public.winner_posters set
        is_published = true,
        published_at = statement_timestamp(),
        mutation_idempotency_key = request_idempotency_key
      where id = result.id returning * into result;
    else
      update public.winner_posters set
        is_published = false,
        deleted_at = statement_timestamp(),
        mutation_idempotency_key = request_idempotency_key
      where id = result.id returning * into result;
    end if;
  end if;

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()), 'managed_content_updated', result.id, trim(reason),
    jsonb_build_object(
      'operation', operation,
      'program_id', result.program_id,
      'winner_snapshot_id', result.winner_snapshot_id,
      'idempotency_key', request_idempotency_key
    )
  );
  return result;
end;
$$;

revoke execute on function
  public.archive_program(uuid, text, text),
  public.manage_winner_poster(uuid, uuid, uuid, text, text, text, text, text)
from public, anon, authenticated, service_role;

grant execute on function
  public.archive_program(uuid, text, text),
  public.manage_winner_poster(uuid, uuid, uuid, text, text, text, text, text)
to authenticated;

