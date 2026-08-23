alter table public.program_questions
  drop constraint if exists program_questions_kind_check;

alter table public.program_questions
  add constraint program_questions_kind_check check (
    kind in (
      'short_answer', 'long_answer', 'number', 'single_choice',
      'multiple_choice', 'image_choice', 'photo_upload', 'video_upload',
      'heading', 'text'
    )
  ),
  add column if not exists media_kind text,
  add column if not exists media_path text,
  add column if not exists media_alt_text text;

alter table public.program_questions
  drop constraint if exists program_questions_prompt_media_check;

alter table public.program_questions
  add constraint program_questions_prompt_media_check check (
    (
      media_kind is null
      and media_path is null
      and media_alt_text is null
    )
    or (
      media_kind in ('image', 'video')
      and length(trim(coalesce(media_path, ''))) > 0
      and length(trim(coalesce(media_alt_text, ''))) > 0
    )
  );

alter table public.step_submission_answers
  add column if not exists private_video_path text;

alter table public.step_submission_answers
  drop constraint if exists step_submission_answers_check;

alter table public.step_submission_answers
  add constraint step_submission_answers_check check (
    text_value is not null
    or number_value is not null
    or cardinality(selected_option_ids) > 0
    or private_photo_path is not null
    or private_video_path is not null
  );

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values
  (
    'program-question-media',
    'program-question-media',
    true,
    52428800,
    array[
      'image/jpeg',
      'video/mp4',
      'video/quicktime',
      'video/webm'
    ]
  ),
  (
    'question-videos',
    'question-videos',
    false,
    52428800,
    array['video/mp4', 'video/quicktime', 'video/webm']
  )
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function private.question_video_path_is_valid(
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
      || '[0-9a-f]{12}\.(mp4|mov|webm)$'
    ),
    false
  );
$$;

create or replace function private.can_write_question_video(
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
  if not private.question_video_path_is_valid(target_path) then
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
      and submission.status in ('draft', 'pending')
      and question.kind = 'video_upload'
  );
end;
$$;

create or replace function private.can_read_question_video(
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
  if not private.question_video_path_is_valid(target_path) then
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
      and question.kind = 'video_upload'
  );
end;
$$;

revoke execute on function private.question_video_path_is_valid(text)
  from public, anon, service_role;
revoke execute on function private.can_write_question_video(text)
  from public, anon, service_role;
revoke execute on function private.can_read_question_video(text)
  from public, anon, service_role;
grant execute on function private.question_video_path_is_valid(text)
  to authenticated;
grant execute on function private.can_write_question_video(text)
  to authenticated;
grant execute on function private.can_read_question_video(text)
  to authenticated;

drop policy if exists "question video owner inserts" on storage.objects;
create policy "question video owner inserts"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'question-videos'
  and private.can_write_question_video(name)
);

drop policy if exists "question video related users read" on storage.objects;
create policy "question video related users read"
on storage.objects for select to authenticated
using (
  bucket_id = 'question-videos'
  and private.can_read_question_video(name)
);

drop policy if exists "question video owner updates" on storage.objects;
create policy "question video owner updates"
on storage.objects for update to authenticated
using (
  bucket_id = 'question-videos'
  and private.can_write_question_video(name)
)
with check (
  bucket_id = 'question-videos'
  and private.can_write_question_video(name)
);

drop policy if exists "question video owner deletes" on storage.objects;
create policy "question video owner deletes"
on storage.objects for delete to authenticated
using (
  bucket_id = 'question-videos'
  and private.can_write_question_video(name)
);

drop policy if exists "admin inserts program question media" on storage.objects;
create policy "admin inserts program question media"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'program-question-media'
  and private.is_admin()
);

drop policy if exists "admin updates program question media" on storage.objects;
create policy "admin updates program question media"
on storage.objects for update to authenticated
using (
  bucket_id = 'program-question-media'
  and private.is_admin()
)
with check (
  bucket_id = 'program-question-media'
  and private.is_admin()
);

drop policy if exists "admin deletes program question media" on storage.objects;
create policy "admin deletes program question media"
on storage.objects for delete to authenticated
using (
  bucket_id = 'program-question-media'
  and private.is_admin()
);

create or replace function private.validate_question_video_answer()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  object storage.objects;
begin
  if new.private_video_path is null then return new; end if;

  if not private.can_read_question_video(new.private_video_path) then
    raise exception 'private_video_invalid';
  end if;

  select * into object
  from storage.objects stored_object
  where stored_object.bucket_id = 'question-videos'
    and stored_object.name = new.private_video_path;

  if object.id is null then raise exception 'private_video_missing'; end if;
  if coalesce(object.metadata ->> 'mimetype', '') not in (
    'video/mp4', 'video/quicktime', 'video/webm'
  ) then
    raise exception 'private_video_mime_invalid';
  end if;
  if object.metadata ? 'size' and (
    (object.metadata ->> 'size')::bigint <= 0
    or (object.metadata ->> 'size')::bigint > 52428800
  ) then
    raise exception 'private_video_size_invalid';
  end if;

  return new;
end;
$$;

drop trigger if exists validate_question_video_answer_before_write
  on public.step_submission_answers;
create trigger validate_question_video_answer_before_write
before insert or update of private_video_path
on public.step_submission_answers
for each row execute function private.validate_question_video_answer();

create or replace function public.submit_step_answers(
  target_submission_id uuid,
  submitted_answers jsonb,
  request_idempotency_key text
)
returns public.step_submissions
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.step_submissions;
  normalized_answers jsonb;
  answer_payload jsonb;
  target_question public.program_questions;
  video_path text;
begin
  perform private.assert_active_account();
  if jsonb_typeof(submitted_answers) <> 'array' then
    raise exception 'answers_invalid';
  end if;

  for answer_payload in
    select value from jsonb_array_elements(submitted_answers)
  loop
    select question.* into target_question
    from public.program_questions question
    join public.step_submissions submission
      on submission.step_id = question.step_id
    where submission.id = target_submission_id
      and question.id = (answer_payload ->> 'question_id')::uuid;

    if target_question.kind = 'video_upload' then
      video_path := nullif(answer_payload ->> 'private_video_path', '');
      if video_path is null
        or not private.can_write_question_video(video_path)
        or not exists (
          select 1 from storage.objects object
          where object.bucket_id = 'question-videos'
            and object.name = video_path
        )
      then
        raise exception 'private_video_invalid';
      end if;
    end if;
  end loop;

  select coalesce(
    jsonb_agg(
      case
        when question.kind = 'video_upload' then
          jsonb_set(answer.value, '{text_value}', to_jsonb('__video_upload__'::text), true)
        else answer.value
      end
      order by answer.ordinality
    ),
    '[]'::jsonb
  )
  into normalized_answers
  from jsonb_array_elements(submitted_answers) with ordinality answer(value, ordinality)
  left join public.program_questions question
    on question.id = (answer.value ->> 'question_id')::uuid;

  result := private.w074_active_submit_step_answers(
    target_submission_id,
    normalized_answers,
    request_idempotency_key
  );

  update public.step_submission_answers answer set
    private_video_path = nullif(payload.value ->> 'private_video_path', ''),
    text_value = null
  from jsonb_array_elements(submitted_answers) payload(value)
  join public.program_questions question
    on question.id = (payload.value ->> 'question_id')::uuid
  where answer.submission_id = target_submission_id
    and answer.question_id = question.id
    and question.kind = 'video_upload';

  return result;
end;
$$;

revoke execute on function public.submit_step_answers(uuid,jsonb,text)
  from public, anon;
grant execute on function public.submit_step_answers(uuid,jsonb,text)
  to authenticated;

create or replace function public.save_admin_program_draft(
  program_payload jsonb,
  request_idempotency_key text
)
returns public.programs
language plpgsql
security definer
set search_path = ''
as $$
declare result public.programs;
declare day_payload jsonb;
declare step_payload jsonb;
declare question_payload jsonb;
declare requested_verification_mode text;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  requested_verification_mode := coalesce(
    nullif(program_payload ->> 'default_verification_mode', ''),
    'coach_review'
  );
  if requested_verification_mode not in ('automatic', 'coach_review') then
    raise exception 'invalid_default_verification_mode';
  end if;
  result := public.save_program_draft(
    program_payload,
    request_idempotency_key
  );
  update public.programs
  set default_verification_mode = requested_verification_mode
  where id = result.id
  returning * into result;
  for day_payload in
    select value from jsonb_array_elements(program_payload -> 'days')
  loop
    for step_payload in
      select value from jsonb_array_elements(day_payload -> 'steps')
    loop
      for question_payload in
        select value from jsonb_array_elements(
          coalesce(step_payload -> 'questions', '[]'::jsonb)
        )
      loop
        if nullif(question_payload ->> 'media_path', '') is not null
          and not exists (
            select 1
            from storage.objects object
            where object.bucket_id = 'program-question-media'
              and object.name = (question_payload ->> 'media_path')
              and (
                (
                  question_payload ->> 'media_kind' = 'image'
                  and object.metadata ->> 'mimetype' = 'image/jpeg'
                )
                or (
                  question_payload ->> 'media_kind' = 'video'
                  and object.metadata ->> 'mimetype' in (
                    'video/mp4', 'video/quicktime', 'video/webm'
                  )
                )
              )
          )
        then
          raise exception 'question_media_invalid';
        end if;
        update public.program_questions set
          analysis_mode = coalesce(
            question_payload ->> 'analysis_mode',
            'none'
          ),
          analysis_rubric = nullif(
            question_payload ->> 'analysis_rubric',
            ''
          ),
          analysis_rubric_version = nullif(
            question_payload ->> 'analysis_rubric_version',
            ''
          ),
          media_kind = nullif(question_payload ->> 'media_kind', ''),
          media_path = nullif(question_payload ->> 'media_path', ''),
          media_alt_text = nullif(
            question_payload ->> 'media_alt_text',
            ''
          )
        where id = (question_payload ->> 'id')::uuid;
      end loop;
    end loop;
  end loop;
  return result;
end;
$$;

create or replace function public.duplicate_admin_program_as_draft(
  target_program_id uuid,
  source_program_id uuid,
  target_title text,
  target_start_date date,
  request_idempotency_key text
)
returns public.programs
language plpgsql
security definer
set search_path = ''
as $$
declare result public.programs;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  result := public.duplicate_program_as_draft(
    $2,
    $1,
    target_title,
    target_start_date,
    request_idempotency_key
  );
  update public.programs target set
    default_verification_mode = source.default_verification_mode
  from public.programs source
  where target.id = $1
    and source.id = $2
  returning target.* into result;
  update public.program_questions target_question set
    analysis_mode = source_question.analysis_mode,
    analysis_rubric = source_question.analysis_rubric,
    analysis_rubric_version = source_question.analysis_rubric_version,
    media_kind = source_question.media_kind,
    media_path = source_question.media_path,
    media_alt_text = source_question.media_alt_text
  from public.program_steps target_step
  join public.program_days target_day
    on target_day.id = target_step.program_day_id
  join public.program_days source_day
    on source_day.program_id = $2
    and source_day.day_number = target_day.day_number
  join public.program_steps source_step
    on source_step.program_day_id = source_day.id
    and source_step.step_order = target_step.step_order
  join public.program_questions source_question
    on source_question.step_id = source_step.id
  where target_question.step_id = target_step.id
    and target_day.program_id = $1
    and source_question.question_order = target_question.question_order;
  return result;
end;
$$;

revoke execute on function public.save_admin_program_draft(jsonb,text)
  from public, anon, service_role;
revoke execute on function public.duplicate_admin_program_as_draft(
  uuid,uuid,text,date,text
) from public, anon, service_role;
grant execute on function public.save_admin_program_draft(jsonb,text)
  to authenticated;
grant execute on function public.duplicate_admin_program_as_draft(
  uuid,uuid,text,date,text
) to authenticated;

create or replace function public.list_public_question_media(
  target_question_ids uuid[]
)
returns setof jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', question.id,
    'media_kind', question.media_kind,
    'media_path', question.media_path,
    'media_alt_text', question.media_alt_text
  )
  from public.program_questions question
  join public.program_steps step on step.id = question.step_id
  join public.program_days day on day.id = step.program_day_id
  join public.programs program on program.id = day.program_id
  where question.id = any(coalesce(target_question_ids, '{}'::uuid[]))
    and program.status in ('scheduled', 'active', 'completed', 'archived');
$$;

revoke execute on function public.list_public_question_media(uuid[])
  from public;
grant execute on function public.list_public_question_media(uuid[])
  to anon, authenticated;

create or replace function public.list_my_coach_submission_videos(
  target_submission_ids uuid[]
)
returns setof jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'answer_id', answer.id,
    'private_video_path', answer.private_video_path
  )
  from public.step_submission_answers answer
  join public.step_submissions submission
    on submission.id = answer.submission_id
  join public.program_enrollments enrollment
    on enrollment.id = submission.enrollment_id
  where submission.id = any(coalesce(target_submission_ids, '{}'::uuid[]))
    and answer.private_video_path is not null
    and private.can_coach_participant(enrollment.participant_id)
    and private.has_active_coach_access((select auth.uid()));
$$;

revoke execute on function public.list_my_coach_submission_videos(uuid[])
  from public, anon, service_role;
grant execute on function public.list_my_coach_submission_videos(uuid[])
  to authenticated;

create or replace function public.list_orphan_question_videos(
  older_than interval default interval '24 hours'
)
returns table(object_name text)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce((select auth.role()), '') <> 'service_role'
    and not private.is_admin()
  then
    raise exception 'permission_denied';
  end if;
  if older_than < interval '1 hour' then
    raise exception 'retention_too_short';
  end if;
  return query
  select object.name
  from storage.objects object
  where object.bucket_id = 'question-videos'
    and object.created_at < statement_timestamp() - older_than
    and not exists (
      select 1
      from public.step_submission_answers answer
      where answer.private_video_path = object.name
    );
end;
$$;

create or replace function public.record_orphan_question_video_cleanup(
  deleted_object_names text[],
  cleanup_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce((select auth.role()), '') <> 'service_role'
    and not private.is_admin()
  then
    raise exception 'permission_denied';
  end if;
  if length(trim(coalesce(cleanup_reason, ''))) = 0 then
    raise exception 'reason_required';
  end if;
  if coalesce(cardinality(deleted_object_names), 0) = 0 then
    raise exception 'deleted_objects_required';
  end if;
  insert into public.audit_events (
    actor_id, kind, subject_id, summary, payload
  ) values (
    case
      when coalesce((select auth.role()), '') = 'service_role' then null
      else (select auth.uid())
    end,
    'question_video_orphans_cleaned',
    gen_random_uuid(),
    cleanup_reason,
    jsonb_build_object(
      'deleted_count', cardinality(deleted_object_names),
      'object_name_hashes', (
        select jsonb_agg(
          pg_catalog.encode(
            extensions.digest(value::bytea, 'sha256'),
            'hex'
          )
        )
        from unnest(deleted_object_names) value
      )
    )
  );
end;
$$;

revoke execute on function public.list_orphan_question_videos(interval)
  from public, anon, authenticated;
revoke execute on function public.record_orphan_question_video_cleanup(text[],text)
  from public, anon, authenticated;
grant execute on function public.list_orphan_question_videos(interval)
  to service_role;
grant execute on function public.record_orphan_question_video_cleanup(text[],text)
  to service_role;
