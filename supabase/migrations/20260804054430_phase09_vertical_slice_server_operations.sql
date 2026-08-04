-- Phase 09 proves one complete local vertical slice:
-- catalog read -> free enrollment -> typed/photo submission -> Coach review
-- -> authoritative score refresh.
--
-- Submission preparation is deliberately separate from final submission so a
-- private Storage object can be bound to an authoritative submission ID before
-- upload. Draft rows are internal transport state and are never returned in
-- Coach review queues or counted for progress/scoring.

alter table public.step_submissions
  drop constraint step_submissions_status_check;

alter table public.step_submissions
  add constraint step_submissions_status_check
  check (status in ('draft', 'pending', 'approved', 'rejected'));

alter table public.step_submissions
  add column idempotency_key text,
  add column finalized_at timestamptz,
  add column review_idempotency_key text,
  add constraint step_submissions_idempotency_key_shape check (
    idempotency_key is null
    or length(idempotency_key) between 8 and 128
  ),
  add constraint step_submissions_review_idempotency_key_shape check (
    review_idempotency_key is null
    or length(review_idempotency_key) between 8 and 128
  );

update public.step_submissions
set
  finalized_at = submitted_at,
  idempotency_key = 'legacy-' || id::text
where finalized_at is null;

create unique index step_submissions_idempotency_idx
  on public.step_submissions(enrollment_id, step_id, idempotency_key);

create unique index step_submissions_single_open_draft_idx
  on public.step_submissions(enrollment_id, step_id)
  where status = 'draft';

-- Existing read policy is replaced so an unfinished upload draft is visible
-- only to its Participant owner. Coach/Admin consumers see final submissions.
drop policy "own or coached submissions" on public.step_submissions;
create policy "submission owner or related reviewer read"
on public.step_submissions for select to authenticated
using (
  exists (
    select 1
    from public.program_enrollments enrollment
    where enrollment.id = enrollment_id
      and (
        enrollment.participant_id = (select auth.uid())
        or (
          status <> 'draft'
          and (
            private.can_coach_participant(enrollment.participant_id)
            or private.is_admin()
          )
        )
      )
  )
);

create or replace function private.assert_idempotency_key(
  target_key text
)
returns void
language plpgsql
immutable
security invoker
set search_path = ''
as $$
begin
  if target_key is null
    or length(target_key) < 8
    or length(target_key) > 128
  then
    raise exception 'idempotency_key_invalid';
  end if;
end;
$$;

create or replace function private.step_accepts_submission(
  target_enrollment_id uuid,
  target_step_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.program_enrollments enrollment
    join public.programs program
      on program.id = enrollment.program_id
    join public.program_days day
      on day.program_id = program.id
    join public.program_steps step
      on step.program_day_id = day.id
    where enrollment.id = target_enrollment_id
      and enrollment.participant_id = (select auth.uid())
      and enrollment.status = 'active'
      and step.id = target_step_id
      and program.status in ('scheduled', 'active')
      and (
        day.scheduled_on = (
          timezone(program.timezone, statement_timestamp())
        )::date
        or (
          day.scheduled_on < (
            timezone(program.timezone, statement_timestamp())
          )::date
          and program.past_step_policy = 'available'
        )
        or (
          day.scheduled_on > (
            timezone(program.timezone, statement_timestamp())
          )::date
          and program.future_step_policy = 'available'
        )
      )
  );
$$;

create or replace function private.recalculate_enrollment_score(
  target_enrollment_id uuid
)
returns public.program_scores
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_program_id uuid;
  activity_points_value integer;
  quiz_points_value integer;
  weight_points_value integer;
  adjustment_points_value integer;
  completed_step_count integer;
  total_step_count integer;
  initial_weight numeric;
  final_weight numeric;
  points_per_activity_value integer;
  points_per_weight_value numeric;
  result public.program_scores;
begin
  select
    enrollment.program_id,
    program.points_per_activity,
    program.points_per_weight_kg
  into
    target_program_id,
    points_per_activity_value,
    points_per_weight_value
  from public.program_enrollments enrollment
  join public.programs program on program.id = enrollment.program_id
  where enrollment.id = target_enrollment_id
  for update of enrollment;

  if target_program_id is null then
    raise exception 'enrollment_not_found';
  end if;

  select count(distinct submission.step_id)::integer
    * points_per_activity_value
  into activity_points_value
  from public.step_submissions submission
  join public.program_steps step on step.id = submission.step_id
  where submission.enrollment_id = target_enrollment_id
    and submission.status = 'approved'
    and step.content_kind in ('article', 'video', 'form');

  select coalesce(sum(latest.awarded_points), 0)::integer
  into quiz_points_value
  from (
    select distinct on (submission.step_id)
      quiz_result.awarded_points
    from public.step_submissions submission
    join public.quiz_attempt_results quiz_result
      on quiz_result.submission_id = submission.id
    where submission.enrollment_id = target_enrollment_id
      and submission.status = 'approved'
    order by
      submission.step_id,
      submission.attempt_sequence desc
  ) latest;

  select weight_kg
  into initial_weight
  from public.weigh_ins
  where enrollment_id = target_enrollment_id
    and kind = 'initial';

  select weight_kg
  into final_weight
  from public.weigh_ins
  where enrollment_id = target_enrollment_id
    and kind = 'final';

  weight_points_value := case
    when initial_weight is null or final_weight is null then 0
    else round(
      greatest(initial_weight - final_weight, 0)
      * points_per_weight_value
    )::integer
  end;

  select coalesce(sum(points), 0)::integer
  into adjustment_points_value
  from public.score_adjustments
  where enrollment_id = target_enrollment_id;

  select count(*)::integer
  into total_step_count
  from public.program_steps step
  join public.program_days day on day.id = step.program_day_id
  where day.program_id = target_program_id;

  select count(*)::integer
  into completed_step_count
  from public.program_steps step
  join public.program_days day on day.id = step.program_day_id
  where day.program_id = target_program_id
    and (
      (
        step.content_kind in ('article', 'video', 'form')
        and exists (
          select 1
          from public.step_submissions submission
          where submission.enrollment_id = target_enrollment_id
            and submission.step_id = step.id
            and submission.status = 'approved'
        )
      )
      or (
        step.content_kind = 'quiz'
        and exists (
          select 1
          from public.step_submissions submission
          join public.quiz_attempt_results quiz
            on quiz.submission_id = submission.id
          where submission.enrollment_id = target_enrollment_id
            and submission.step_id = step.id
            and submission.status = 'approved'
            and quiz.passed
        )
      )
      or (
        step.content_kind in (
          'initial_weigh_in',
          'daily_weigh_in',
          'final_weigh_in'
        )
        and exists (
          select 1
          from public.weigh_ins weigh_in
          where weigh_in.enrollment_id = target_enrollment_id
            and weigh_in.step_id = step.id
        )
      )
    );

  insert into public.program_scores (
    enrollment_id,
    activity_points,
    quiz_points,
    weight_points,
    adjustment_points,
    progress_percentage,
    recalculated_at
  )
  values (
    target_enrollment_id,
    coalesce(activity_points_value, 0),
    coalesce(quiz_points_value, 0),
    coalesce(weight_points_value, 0),
    coalesce(adjustment_points_value, 0),
    case
      when total_step_count = 0 then 0
      else round(
        completed_step_count::numeric * 100 / total_step_count
      )::integer
    end,
    statement_timestamp()
  )
  on conflict (enrollment_id) do update
  set
    activity_points = excluded.activity_points,
    quiz_points = excluded.quiz_points,
    weight_points = excluded.weight_points,
    adjustment_points = excluded.adjustment_points,
    progress_percentage = excluded.progress_percentage,
    recalculated_at = excluded.recalculated_at
  returning * into result;

  with ranked as (
    select
      score.enrollment_id,
      row_number() over (
        order by
          (
            score.activity_points
            + score.quiz_points
            + score.weight_points
            + score.adjustment_points
          ) desc,
          score.recalculated_at asc,
          score.enrollment_id asc
      )::integer as rank_value
    from public.program_scores score
    join public.program_enrollments enrollment
      on enrollment.id = score.enrollment_id
    where enrollment.program_id = target_program_id
      and enrollment.status in ('active', 'completed')
  )
  update public.program_scores score
  set rank = ranked.rank_value
  from ranked
  where score.enrollment_id = ranked.enrollment_id;

  select *
  into result
  from public.program_scores
  where enrollment_id = target_enrollment_id;

  return result;
end;
$$;

create or replace function public.prepare_step_submission(
  target_enrollment_id uuid,
  target_step_id uuid,
  request_idempotency_key text
)
returns public.step_submissions
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.step_submissions;
  next_sequence integer;
begin
  perform private.assert_idempotency_key(request_idempotency_key);

  if not private.step_accepts_submission(
    target_enrollment_id,
    target_step_id
  ) then
    raise exception 'step_unavailable';
  end if;

  select *
  into result
  from public.step_submissions
  where enrollment_id = target_enrollment_id
    and step_id = target_step_id
    and idempotency_key = request_idempotency_key;

  if result.id is not null then
    return result;
  end if;

  if exists (
    select 1
    from public.step_submissions
    where enrollment_id = target_enrollment_id
      and step_id = target_step_id
      and status in ('pending', 'approved')
  ) then
    raise exception 'submission_already_finalized';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      target_enrollment_id::text || ':' || target_step_id::text,
      0
    )
  );

  select *
  into result
  from public.step_submissions
  where enrollment_id = target_enrollment_id
    and step_id = target_step_id
    and idempotency_key = request_idempotency_key;

  if result.id is not null then
    return result;
  end if;

  select coalesce(max(attempt_sequence), 0) + 1
  into next_sequence
  from public.step_submissions
  where enrollment_id = target_enrollment_id
    and step_id = target_step_id;

  insert into public.step_submissions (
    enrollment_id,
    step_id,
    attempt_sequence,
    status,
    idempotency_key
  )
  values (
    target_enrollment_id,
    target_step_id,
    next_sequence,
    'draft',
    request_idempotency_key
  )
  returning * into result;

  return result;
end;
$$;

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
  target_submission public.step_submissions;
  target_enrollment public.program_enrollments;
  target_step public.program_steps;
  target_program public.programs;
  answer_record record;
  answer_json jsonb;
  answer_text text;
  answer_number numeric;
  answer_options uuid[];
  answer_photo_path text;
  expected_interactive_count integer;
  supplied_interactive_count integer;
  correct_count_value integer := 0;
  total_count_value integer := 0;
  percentage_value integer := 0;
  passed_value boolean := false;
  status_value text;
begin
  perform private.assert_idempotency_key(request_idempotency_key);

  if jsonb_typeof(submitted_answers) <> 'array' then
    raise exception 'answers_invalid';
  end if;

  select *
  into target_submission
  from public.step_submissions
  where id = target_submission_id
  for update;

  if target_submission.id is null then
    raise exception 'submission_not_found';
  end if;

  select *
  into target_enrollment
  from public.program_enrollments
  where id = target_submission.enrollment_id;

  if target_enrollment.participant_id <> (select auth.uid()) then
    raise exception 'permission_denied';
  end if;

  if target_submission.idempotency_key <> request_idempotency_key then
    raise exception 'idempotency_key_mismatch';
  end if;

  if target_submission.status <> 'draft' then
    return target_submission;
  end if;

  if not private.step_accepts_submission(
    target_submission.enrollment_id,
    target_submission.step_id
  ) then
    raise exception 'step_unavailable';
  end if;

  select step.*
  into target_step
  from public.program_steps step
  where step.id = target_submission.step_id;

  select program.*
  into target_program
  from public.programs program
  join public.program_days day on day.program_id = program.id
  where day.id = target_step.program_day_id;

  if target_step.content_kind in (
    'initial_weigh_in',
    'daily_weigh_in',
    'final_weigh_in'
  ) then
    raise exception 'weigh_in_requires_dedicated_operation';
  end if;

  select count(*)::integer
  into expected_interactive_count
  from public.program_questions
  where step_id = target_submission.step_id
    and kind not in ('heading', 'text');

  select count(distinct value ->> 'question_id')::integer
  into supplied_interactive_count
  from jsonb_array_elements(submitted_answers);

  if supplied_interactive_count <> expected_interactive_count then
    raise exception 'answers_incomplete';
  end if;

  for answer_record in
    select question.*
    from public.program_questions question
    where question.step_id = target_submission.step_id
      and question.kind not in ('heading', 'text')
    order by question.question_order
  loop
    select value
    into answer_json
    from jsonb_array_elements(submitted_answers)
    where (value ->> 'question_id')::uuid = answer_record.id;

    if answer_json is null then
      raise exception 'answers_incomplete';
    end if;

    answer_text := nullif(trim(answer_json ->> 'text_value'), '');
    answer_number := case
      when nullif(answer_json ->> 'number_value', '') is null then null
      else (answer_json ->> 'number_value')::numeric
    end;
    answer_options := coalesce(
      array(
        select value::uuid
        from jsonb_array_elements_text(
          coalesce(answer_json -> 'selected_option_ids', '[]'::jsonb)
        )
      ),
      '{}'::uuid[]
    );
    answer_photo_path := nullif(
      answer_json ->> 'private_photo_path',
      ''
    );

    if answer_record.kind in ('short_answer', 'long_answer')
      and answer_text is null
    then
      raise exception 'answer_type_invalid';
    elsif answer_record.kind = 'number'
      and answer_number is null
    then
      raise exception 'answer_type_invalid';
    elsif answer_record.kind in (
      'single_choice',
      'multiple_choice',
      'image_choice'
    ) and cardinality(answer_options) = 0
    then
      raise exception 'answer_type_invalid';
    elsif answer_record.kind = 'photo_upload' then
      if answer_photo_path is null
        or not private.can_write_question_photo(answer_photo_path)
        or not exists (
          select 1
          from storage.objects object
          where object.bucket_id = 'question-photos'
            and object.name = answer_photo_path
        )
      then
        raise exception 'private_photo_invalid';
      end if;
    end if;

    if cardinality(answer_options) > 0 and exists (
      select 1
      from unnest(answer_options) selected_id
      where not exists (
        select 1
        from public.program_question_options option
        where option.id = selected_id
          and option.question_id = answer_record.id
      )
    ) then
      raise exception 'answer_option_invalid';
    end if;

    if answer_record.kind in ('single_choice', 'image_choice')
      and cardinality(answer_options) <> 1
    then
      raise exception 'answer_option_invalid';
    end if;

    insert into public.step_submission_answers (
      submission_id,
      question_id,
      text_value,
      number_value,
      selected_option_ids,
      private_photo_path
    )
    values (
      target_submission.id,
      answer_record.id,
      answer_text,
      answer_number,
      answer_options,
      answer_photo_path
    );
  end loop;

  if target_step.content_kind = 'quiz' then
    select count(*)::integer
    into total_count_value
    from public.program_questions
    where step_id = target_submission.step_id
      and kind not in ('heading', 'text');

    select count(*)::integer
    into correct_count_value
    from public.step_submission_answers answer
    join public.program_questions question
      on question.id = answer.question_id
    join public.program_answer_keys answer_key
      on answer_key.question_id = question.id
    where answer.submission_id = target_submission.id
      and (
        (
          question.kind in (
            'single_choice',
            'multiple_choice',
            'image_choice'
          )
          and answer.selected_option_ids @> answer_key.selected_option_ids
          and answer.selected_option_ids <@ answer_key.selected_option_ids
        )
        or (
          question.kind = 'number'
          and answer.number_value = answer_key.number_value
        )
        or (
          question.kind in ('short_answer', 'long_answer')
          and (
            (
              answer_key.matching_mode = 'exact'
              and answer.text_value = any(
                answer_key.accepted_text_values
              )
            )
            or (
              answer_key.matching_mode = 'case_insensitive_text'
              and lower(answer.text_value) = any(
                select lower(value)
                from unnest(
                  answer_key.accepted_text_values
                ) value
              )
            )
          )
        )
      );

    percentage_value := round(
      correct_count_value::numeric * 100 / total_count_value
    )::integer;
    passed_value :=
      percentage_value >= target_program.quiz_passing_percentage;
    status_value := 'approved';

    insert into public.quiz_attempt_results (
      submission_id,
      correct_count,
      total_count,
      percentage,
      passed,
      awarded_points
    )
    values (
      target_submission.id,
      correct_count_value,
      total_count_value,
      percentage_value,
      passed_value,
      correct_count_value * target_program.points_per_activity
    );
  elsif target_step.verification_mode = 'coach_review' then
    status_value := 'pending';
  else
    status_value := 'approved';
  end if;

  update public.step_submissions
  set
    status = status_value,
    submitted_at = statement_timestamp(),
    finalized_at = statement_timestamp()
  where id = target_submission.id
  returning * into target_submission;

  perform private.recalculate_enrollment_score(
    target_submission.enrollment_id
  );

  return target_submission;
end;
$$;

create or replace function public.review_step_submission(
  target_submission_id uuid,
  review_decision text,
  review_reason text,
  request_idempotency_key text
)
returns public.step_submissions
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_submission public.step_submissions;
  target_participant_id uuid;
begin
  perform private.assert_idempotency_key(request_idempotency_key);

  if review_decision not in ('approved', 'rejected') then
    raise exception 'review_decision_invalid';
  end if;

  if review_decision = 'rejected'
    and length(trim(coalesce(review_reason, ''))) = 0
  then
    raise exception 'review_reason_required';
  end if;

  select submission.*
  into target_submission
  from public.step_submissions submission
  where submission.id = target_submission_id
  for update of submission;

  if target_submission.id is null then
    raise exception 'submission_not_found';
  end if;

  select enrollment.participant_id
  into target_participant_id
  from public.program_enrollments enrollment
  where enrollment.id = target_submission.enrollment_id;

  if not (
    private.can_coach_participant(target_participant_id)
    or private.is_admin()
  ) then
    raise exception 'permission_denied';
  end if;

  if target_submission.status in ('approved', 'rejected') then
    if target_submission.review_idempotency_key = request_idempotency_key
      and target_submission.status = review_decision
    then
      return target_submission;
    end if;
    raise exception 'submission_already_reviewed';
  end if;

  if target_submission.status <> 'pending' then
    raise exception 'submission_not_reviewable';
  end if;

  update public.step_submissions
  set
    status = review_decision,
    reviewed_at = statement_timestamp(),
    reviewer_id = (select auth.uid()),
    review_note = nullif(trim(coalesce(review_reason, '')), ''),
    review_idempotency_key = request_idempotency_key
  where id = target_submission.id
  returning * into target_submission;

  insert into public.audit_events (
    actor_id,
    kind,
    subject_id,
    summary,
    payload
  )
  values (
    (select auth.uid()),
    'submission_' || review_decision,
    target_submission.id,
    coalesce(nullif(trim(coalesce(review_reason, '')), ''), review_decision),
    jsonb_build_object(
      'enrollment_id', target_submission.enrollment_id,
      'step_id', target_submission.step_id,
      'attempt_sequence', target_submission.attempt_sequence
    )
  );

  perform private.recalculate_enrollment_score(
    target_submission.enrollment_id
  );

  return target_submission;
end;
$$;

create or replace function public.refresh_enrollment_score(
  target_enrollment_id uuid
)
returns public.program_scores
language plpgsql
security definer
set search_path = ''
as $$
declare
  participant_id_value uuid;
begin
  select participant_id
  into participant_id_value
  from public.program_enrollments
  where id = target_enrollment_id;

  if participant_id_value is null then
    raise exception 'enrollment_not_found';
  end if;

  if not (
    participant_id_value = (select auth.uid())
    or private.can_coach_participant(participant_id_value)
    or private.is_admin()
  ) then
    raise exception 'permission_denied';
  end if;

  return private.recalculate_enrollment_score(target_enrollment_id);
end;
$$;

-- Replace the Storage helper so draft upload sessions are writable before the
-- final typed-answer RPC. Once reviewed, the object becomes immutable to the
-- Participant while remaining readable by its related Coach/Admin.
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
      and submission.status in ('draft', 'pending')
      and question.kind = 'photo_upload'
  );
end;
$$;

-- A server-side cleanup worker must delete through the Storage API, never by
-- deleting storage.objects directly. This reviewed RPC returns only candidates
-- older than the retention threshold and only to Admin. The worker records a
-- separate audit event after successful Storage API deletion.
create or replace function public.list_orphan_question_photos(
  older_than interval default interval '24 hours'
)
returns table (object_name text)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'permission_denied';
  end if;

  if older_than < interval '1 hour' then
    raise exception 'retention_too_short';
  end if;

  return query
  select object.name
  from storage.objects object
  where object.bucket_id = 'question-photos'
    and object.created_at < statement_timestamp() - older_than
    and not exists (
      select 1
      from public.step_submission_answers answer
      where answer.private_photo_path = object.name
    );
end;
$$;

create or replace function public.record_orphan_question_photo_cleanup(
  deleted_object_names text[],
  cleanup_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'permission_denied';
  end if;

  if length(trim(coalesce(cleanup_reason, ''))) = 0 then
    raise exception 'reason_required';
  end if;

  if coalesce(cardinality(deleted_object_names), 0) = 0 then
    raise exception 'deleted_objects_required';
  end if;

  insert into public.audit_events (
    actor_id,
    kind,
    subject_id,
    summary,
    payload
  )
  values (
    (select auth.uid()),
    'question_photo_orphans_cleaned',
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

-- Keep every new helper and RPC default-deny. Private helpers receive EXECUTE
-- only because stored RLS/function expressions must resolve them; callers
-- still have no USAGE on the unexposed private schema.
revoke execute on function private.assert_idempotency_key(text)
  from public, anon, authenticated, service_role;
revoke execute on function private.step_accepts_submission(uuid, uuid)
  from public, anon, authenticated, service_role;
revoke execute on function private.recalculate_enrollment_score(uuid)
  from public, anon, authenticated, service_role;

grant execute on function private.assert_idempotency_key(text)
  to authenticated;
grant execute on function private.step_accepts_submission(uuid, uuid)
  to authenticated;
grant execute on function private.recalculate_enrollment_score(uuid)
  to authenticated;

revoke execute on function public.prepare_step_submission(uuid, uuid, text)
  from public, anon, service_role;
revoke execute on function public.submit_step_answers(uuid, jsonb, text)
  from public, anon, service_role;
revoke execute on function public.review_step_submission(
  uuid, text, text, text
) from public, anon, service_role;
revoke execute on function public.refresh_enrollment_score(uuid)
  from public, anon, service_role;
revoke execute on function public.list_orphan_question_photos(interval)
  from public, anon, service_role;
revoke execute on function public.record_orphan_question_photo_cleanup(
  text[], text
) from public, anon, service_role;

grant execute on function public.prepare_step_submission(uuid, uuid, text)
  to authenticated;
grant execute on function public.submit_step_answers(uuid, jsonb, text)
  to authenticated;
grant execute on function public.review_step_submission(
  uuid, text, text, text
) to authenticated;
grant execute on function public.refresh_enrollment_score(uuid)
  to authenticated;
grant execute on function public.list_orphan_question_photos(interval)
  to authenticated;
grant execute on function public.record_orphan_question_photo_cleanup(
  text[], text
) to authenticated;
