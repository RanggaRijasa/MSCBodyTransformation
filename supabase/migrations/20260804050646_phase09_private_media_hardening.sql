-- Private question-photo object keys use:
--
-- participant_id/enrollment_id/submission_id/question_id/object_id.jpg
--
-- The opaque object ID permits retry/replacement without placing names,
-- Coach QR identifiers, weight values, or other personal data in the path.
-- Every relational segment is checked against authoritative database rows.

create or replace function private.question_photo_path_is_valid(
  target_path text
)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $$
  select coalesce(
    target_path ~ (
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-'
      || '[0-9a-f]{12}/'
      || '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-'
      || '[0-9a-f]{12}/'
      || '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-'
      || '[0-9a-f]{12}/'
      || '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-'
      || '[0-9a-f]{12}/'
      || '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-'
      || '[0-9a-f]{12}\.jpg$'
    ),
    false
  );
$$;

create or replace function private.can_write_question_photo(
  target_path text
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  path_parts text[];
  path_participant_id uuid;
  path_enrollment_id uuid;
  path_submission_id uuid;
  path_question_id uuid;
begin
  if not private.question_photo_path_is_valid(target_path) then
    return false;
  end if;

  path_parts := string_to_array(target_path, '/');
  path_participant_id := path_parts[1]::uuid;
  path_enrollment_id := path_parts[2]::uuid;
  path_submission_id := path_parts[3]::uuid;
  path_question_id := path_parts[4]::uuid;

  if path_participant_id <> (select auth.uid()) then
    return false;
  end if;

  return exists (
    select 1
    from public.program_enrollments enrollment
    join public.step_submissions submission
      on submission.enrollment_id = enrollment.id
    join public.program_questions question
      on question.id = path_question_id
      and question.step_id = submission.step_id
    where enrollment.id = path_enrollment_id
      and enrollment.participant_id = path_participant_id
      and enrollment.status = 'active'
      and submission.id = path_submission_id
      and submission.status = 'pending'
      and question.kind = 'photo_upload'
  );
end;
$$;

create or replace function private.can_read_question_photo(
  target_path text
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  path_parts text[];
  path_participant_id uuid;
  path_enrollment_id uuid;
  path_submission_id uuid;
  path_question_id uuid;
begin
  if not private.question_photo_path_is_valid(target_path) then
    return false;
  end if;

  path_parts := string_to_array(target_path, '/');
  path_participant_id := path_parts[1]::uuid;
  path_enrollment_id := path_parts[2]::uuid;
  path_submission_id := path_parts[3]::uuid;
  path_question_id := path_parts[4]::uuid;

  if not (
    path_participant_id = (select auth.uid())
    or private.can_coach_participant(path_participant_id)
    or private.is_admin()
  ) then
    return false;
  end if;

  return exists (
    select 1
    from public.program_enrollments enrollment
    join public.step_submissions submission
      on submission.enrollment_id = enrollment.id
    join public.program_questions question
      on question.id = path_question_id
      and question.step_id = submission.step_id
    where enrollment.id = path_enrollment_id
      and enrollment.participant_id = path_participant_id
      and submission.id = path_submission_id
      and question.kind = 'photo_upload'
  );
end;
$$;

revoke execute on function private.question_photo_path_is_valid(text)
  from public, anon, service_role;
revoke execute on function private.can_write_question_photo(text)
  from public, anon, service_role;
revoke execute on function private.can_read_question_photo(text)
  from public, anon, service_role;

-- Authenticated needs EXECUTE while PostgreSQL evaluates the stored RLS
-- expression. The private schema remains outside the Data API exposed schemas
-- and authenticated has no USAGE privilege on it.
grant execute on function private.question_photo_path_is_valid(text)
  to authenticated;
grant execute on function private.can_write_question_photo(text)
  to authenticated;
grant execute on function private.can_read_question_photo(text)
  to authenticated;

-- The native pipeline accepts larger JPEG/PNG/HEIC inputs but normalizes the
-- upload artifact to a resized, metadata-stripped JPEG. Eight MiB leaves
-- headroom for the 1600 px JPEG output while rejecting oversized artifacts.
update storage.buckets
set
  public = true,
  file_size_limit = 8388608,
  allowed_mime_types = array['image/jpeg']
where id = 'public-media';

update storage.buckets
set
  public = false,
  file_size_limit = 8388608,
  allowed_mime_types = array['image/jpeg']
where id = 'question-photos';

drop policy "participant owns question upload" on storage.objects;
drop policy "private question media read" on storage.objects;

create policy "question photo owner inserts"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'question-photos'
  and private.can_write_question_photo(name)
);

-- SELECT is required for private download, signed-URL authorization, and
-- replacement/upsert. Coach and Admin access remains read-only.
create policy "question photo related users read"
on storage.objects for select to authenticated
using (
  bucket_id = 'question-photos'
  and private.can_read_question_photo(name)
);

create policy "question photo owner updates"
on storage.objects for update to authenticated
using (
  bucket_id = 'question-photos'
  and private.can_write_question_photo(name)
)
with check (
  bucket_id = 'question-photos'
  and private.can_write_question_photo(name)
);

create policy "question photo owner deletes"
on storage.objects for delete to authenticated
using (
  bucket_id = 'question-photos'
  and private.can_write_question_photo(name)
);

-- Public delivery bypasses read RLS because this bucket is intentionally
-- public. Mutations remain restricted to the protected Admin role.
create policy "admin inserts public media"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'public-media'
  and private.is_admin()
);

create policy "admin updates public media"
on storage.objects for update to authenticated
using (
  bucket_id = 'public-media'
  and private.is_admin()
)
with check (
  bucket_id = 'public-media'
  and private.is_admin()
);

create policy "admin deletes public media"
on storage.objects for delete to authenticated
using (
  bucket_id = 'public-media'
  and private.is_admin()
);
