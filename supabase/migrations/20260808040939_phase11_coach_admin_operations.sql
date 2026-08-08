-- Phase 11.6-11.7: Coach read/review surfaces and authoritative Admin CMS,
-- score correction, program closure, winner lock, and poster publication.

alter table public.programs
  add column draft_idempotency_key text,
  add column publish_idempotency_key text,
  add column completion_idempotency_key text,
  add constraint programs_draft_idempotency_key_shape check (
    draft_idempotency_key is null
    or length(draft_idempotency_key) between 8 and 128
  ),
  add constraint programs_publish_idempotency_key_shape check (
    publish_idempotency_key is null
    or length(publish_idempotency_key) between 8 and 128
  ),
  add constraint programs_completion_idempotency_key_shape check (
    completion_idempotency_key is null
    or length(completion_idempotency_key) between 8 and 128
  );

alter table public.profiles
  add column coach_biography text not null default '';

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
  select jsonb_build_object(
    'id', profile.public_profile_id,
    'display_name', profile.display_name,
    'biography', profile.coach_biography,
    'city', profile.city,
    'photo_reference', profile.provider_avatar_url
  )
  from public.profiles profile
  where profile.role = 'coach'
    and profile.coach_is_approved
    and profile.coach_is_public
    and private.has_active_coach_access(profile.user_id)
  order by profile.display_name, profile.public_profile_id
  limit least(greatest(result_limit, 1), 100)
  offset greatest(result_offset, 0);
$$;

create or replace function public.update_coach_profile(
  target_coach_user_id uuid,
  new_display_name text,
  new_biography text,
  new_city text,
  new_is_public boolean,
  reason text default null
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.profiles;
  caller_is_admin boolean := private.is_admin();
begin
  if target_coach_user_id <> (select auth.uid()) and not caller_is_admin then
    raise exception 'permission_denied';
  end if;
  if length(trim(coalesce(new_display_name, ''))) = 0 then
    raise exception 'display_name_required';
  end if;
  if caller_is_admin and target_coach_user_id <> (select auth.uid())
    and length(trim(coalesce(reason, ''))) = 0
  then raise exception 'reason_required'; end if;

  update public.profiles
  set display_name = trim(new_display_name),
      coach_biography = trim(coalesce(new_biography, '')),
      city = trim(coalesce(new_city, '')),
      coach_is_public = new_is_public,
      updated_at = statement_timestamp()
  where user_id = target_coach_user_id
    and role = 'coach'
    and coach_is_approved
  returning * into result;
  if result.user_id is null then raise exception 'coach_not_found'; end if;

  if caller_is_admin then
    insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
    values (
      (select auth.uid()), 'coach_visibility_changed', result.user_id,
      coalesce(nullif(trim(coalesce(reason, '')), ''), 'Profil Coach diperbarui.'),
      jsonb_build_object('is_public', result.coach_is_public)
    );
  end if;
  return result;
end;
$$;

alter table public.winner_snapshots
  add column idempotency_key text,
  add constraint winner_snapshots_idempotency_key_shape check (
    idempotency_key is null
    or length(idempotency_key) between 8 and 128
  );

alter table public.winner_posters
  add column idempotency_key text,
  add constraint winner_posters_idempotency_key_shape check (
    idempotency_key is null
    or length(idempotency_key) between 8 and 128
  );

create unique index winner_posters_idempotency_idx
  on public.winner_posters(program_id, idempotency_key)
  where idempotency_key is not null;

create or replace function public.list_my_assigned_participants()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.has_active_coach_access((select auth.uid())) then
    raise exception 'coach_entitlement_inactive';
  end if;

  return query
  select jsonb_build_object(
    'profile', jsonb_build_object(
      'user_id', participant.user_id,
      'display_name', participant.display_name,
      'city', participant.city,
      'phone_number', participant.phone_number,
      'avatar_path', participant.provider_avatar_url,
      'member_level', participant.member_level
    ),
    'active_enrollment_count', count(enrollment.id) filter (
      where enrollment.status = 'active'
    ),
    'pending_review_count', count(submission.id) filter (
      where submission.status = 'pending'
    ),
    'average_progress_percentage', coalesce(
      round(avg(score.progress_percentage))::integer,
      0
    )
  )
  from public.profiles participant
  left join public.program_enrollments enrollment
    on enrollment.participant_id = participant.user_id
    and enrollment.coach_id = (select auth.uid())
  left join public.step_submissions submission
    on submission.enrollment_id = enrollment.id
    and submission.status = 'pending'
  left join public.program_scores score
    on score.enrollment_id = enrollment.id
  where participant.role = 'participant'
    and participant.current_coach_id = (select auth.uid())
  group by participant.user_id
  order by participant.display_name, participant.user_id;
end;
$$;

create or replace function public.list_my_pending_reviews()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.has_active_coach_access((select auth.uid())) then
    raise exception 'coach_entitlement_inactive';
  end if;

  return query
  select jsonb_build_object(
    'submission', to_jsonb(submission),
    'participant', jsonb_build_object(
      'user_id', participant.user_id,
      'display_name', participant.display_name,
      'avatar_path', participant.provider_avatar_url
    ),
    'program', jsonb_build_object(
      'id', program.id,
      'title', program.title
    ),
    'step', jsonb_build_object(
      'id', step.id,
      'title', step.title,
      'content_kind', step.content_kind
    ),
    'answers', coalesce((
      select jsonb_agg(to_jsonb(answer) order by question.question_order)
      from public.step_submission_answers answer
      join public.program_questions question on question.id = answer.question_id
      where answer.submission_id = submission.id
    ), '[]'::jsonb)
  )
  from public.step_submissions submission
  join public.program_enrollments enrollment
    on enrollment.id = submission.enrollment_id
  join public.profiles participant
    on participant.user_id = enrollment.participant_id
  join public.program_steps step on step.id = submission.step_id
  join public.program_days day on day.id = step.program_day_id
  join public.programs program on program.id = day.program_id
  where enrollment.coach_id = (select auth.uid())
    and participant.current_coach_id = (select auth.uid())
    and submission.status = 'pending'
  order by submission.submitted_at, submission.id;
end;
$$;

create or replace function public.save_program_draft(
  program_payload jsonb,
  request_idempotency_key text
)
returns public.programs
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_id uuid;
  target_program public.programs;
  day_payload jsonb;
  step_payload jsonb;
  question_payload jsonb;
  option_payload jsonb;
  target_pricing_mode text;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if jsonb_typeof(program_payload) <> 'object' then raise exception 'payload_invalid'; end if;

  target_id := coalesce((program_payload ->> 'id')::uuid, gen_random_uuid());
  target_pricing_mode := coalesce(program_payload ->> 'pricing_mode', 'free');

  select * into target_program from public.programs
  where id = target_id for update;
  if target_program.id is not null
    and target_program.draft_idempotency_key = request_idempotency_key
  then return target_program; end if;
  if target_program.id is not null and target_program.status <> 'draft' then
    raise exception 'published_program_read_only';
  end if;

  if length(trim(coalesce(program_payload ->> 'title', ''))) = 0 then
    raise exception 'program_title_required';
  end if;
  if coalesce(jsonb_array_length(program_payload -> 'days'), 0) = 0 then
    raise exception 'program_days_required';
  end if;
  if target_pricing_mode not in ('free', 'paid') then
    raise exception 'pricing_mode_invalid';
  end if;

  insert into public.programs (
    id, source_program_id, title, summary, category, cover_path,
    cover_alt_text, status, pace, duration_mode, starts_on, ends_on,
    timezone, participant_limit, registration_closes_at, past_step_policy,
    future_step_policy, wellness_disclaimer, points_per_activity,
    points_per_weight_kg, quiz_passing_percentage, pricing_mode,
    desired_price, created_by, draft_idempotency_key
  ) values (
    target_id,
    nullif(program_payload ->> 'source_program_id', '')::uuid,
    trim(program_payload ->> 'title'),
    coalesce(program_payload ->> 'summary', ''),
    nullif(program_payload ->> 'category', ''),
    nullif(program_payload ->> 'cover_path', ''),
    nullif(program_payload ->> 'cover_alt_text', ''),
    'draft',
    coalesce(program_payload ->> 'pace', 'scheduled'),
    coalesce(program_payload ->> 'duration_mode', 'specific_dates'),
    (program_payload ->> 'starts_on')::date,
    (program_payload ->> 'ends_on')::date,
    program_payload ->> 'timezone',
    nullif(program_payload ->> 'participant_limit', '')::integer,
    nullif(program_payload ->> 'registration_closes_at', '')::timestamptz,
    coalesce(program_payload ->> 'past_step_policy', 'available'),
    coalesce(program_payload ->> 'future_step_policy', 'locked'),
    coalesce(program_payload ->> 'wellness_disclaimer', ''),
    coalesce((program_payload ->> 'points_per_activity')::integer, 0),
    coalesce((program_payload ->> 'points_per_weight_kg')::numeric, 0),
    coalesce((program_payload ->> 'quiz_passing_percentage')::integer, 70),
    target_pricing_mode,
    case when target_pricing_mode = 'paid'
      then (program_payload ->> 'desired_price')::numeric else null end,
    (select auth.uid()),
    request_idempotency_key
  )
  on conflict (id) do update set
    source_program_id = excluded.source_program_id,
    title = excluded.title,
    summary = excluded.summary,
    category = excluded.category,
    cover_path = excluded.cover_path,
    cover_alt_text = excluded.cover_alt_text,
    pace = excluded.pace,
    duration_mode = excluded.duration_mode,
    starts_on = excluded.starts_on,
    ends_on = excluded.ends_on,
    timezone = excluded.timezone,
    participant_limit = excluded.participant_limit,
    registration_closes_at = excluded.registration_closes_at,
    past_step_policy = excluded.past_step_policy,
    future_step_policy = excluded.future_step_policy,
    wellness_disclaimer = excluded.wellness_disclaimer,
    points_per_activity = excluded.points_per_activity,
    points_per_weight_kg = excluded.points_per_weight_kg,
    quiz_passing_percentage = excluded.quiz_passing_percentage,
    pricing_mode = excluded.pricing_mode,
    desired_price = excluded.desired_price,
    draft_idempotency_key = excluded.draft_idempotency_key,
    updated_at = statement_timestamp();

  delete from public.program_days where program_id = target_id;

  for day_payload in select value from jsonb_array_elements(program_payload -> 'days') loop
    insert into public.program_days(id, program_id, day_number, title, summary, scheduled_on)
    values (
      (day_payload ->> 'id')::uuid,
      target_id,
      (day_payload ->> 'day_number')::integer,
      day_payload ->> 'title',
      nullif(day_payload ->> 'summary', ''),
      (day_payload ->> 'scheduled_on')::date
    );

    for step_payload in select value from jsonb_array_elements(day_payload -> 'steps') loop
      insert into public.program_steps(
        id, program_day_id, step_order, title, instructions, content_kind,
        completion_policy, verification_mode, media_path, media_alt_text,
        video_required, video_threshold, video_autoplay
      ) values (
        (step_payload ->> 'id')::uuid,
        (day_payload ->> 'id')::uuid,
        (step_payload ->> 'step_order')::integer,
        step_payload ->> 'title',
        coalesce(step_payload ->> 'instructions', ''),
        step_payload ->> 'content_kind',
        step_payload ->> 'completion_policy',
        step_payload ->> 'verification_mode',
        nullif(step_payload ->> 'media_path', ''),
        nullif(step_payload ->> 'media_alt_text', ''),
        coalesce((step_payload ->> 'video_required')::boolean, false),
        nullif(step_payload ->> 'video_threshold', '')::integer,
        coalesce((step_payload ->> 'video_autoplay')::boolean, false)
      );

      for question_payload in select value from jsonb_array_elements(
        coalesce(step_payload -> 'questions', '[]'::jsonb)
      ) loop
        insert into public.program_questions(id, step_id, question_order, kind, prompt)
        values (
          (question_payload ->> 'id')::uuid,
          (step_payload ->> 'id')::uuid,
          (question_payload ->> 'question_order')::integer,
          question_payload ->> 'kind',
          question_payload ->> 'prompt'
        );

        for option_payload in select value from jsonb_array_elements(
          coalesce(question_payload -> 'options', '[]'::jsonb)
        ) loop
          insert into public.program_question_options(
            id, question_id, option_order, title, media_path, media_alt_text
          ) values (
            (option_payload ->> 'id')::uuid,
            (question_payload ->> 'id')::uuid,
            (option_payload ->> 'option_order')::integer,
            option_payload ->> 'title',
            nullif(option_payload ->> 'media_path', ''),
            nullif(option_payload ->> 'media_alt_text', '')
          );
        end loop;

        if question_payload ? 'answer_key' then
          insert into public.program_answer_keys(
            question_id, accepted_text_values, number_value,
            selected_option_ids, matching_mode
          ) values (
            (question_payload ->> 'id')::uuid,
            coalesce(array(
              select value from jsonb_array_elements_text(
                coalesce(question_payload -> 'answer_key' -> 'accepted_text_values', '[]'::jsonb)
              )
            ), '{}'::text[]),
            nullif(question_payload -> 'answer_key' ->> 'number_value', '')::numeric,
            coalesce(array(
              select value::uuid from jsonb_array_elements_text(
                coalesce(question_payload -> 'answer_key' -> 'selected_option_ids', '[]'::jsonb)
              )
            ), '{}'::uuid[]),
            coalesce(question_payload -> 'answer_key' ->> 'matching_mode', 'exact')
          );
        end if;
      end loop;
    end loop;
  end loop;

  select * into target_program from public.programs where id = target_id;
  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()),
    case when target_program.created_at = target_program.updated_at
      then 'program_created' else 'program_updated' end,
    target_program.id,
    case when target_program.created_at = target_program.updated_at
      then 'Draft program dibuat.' else 'Draft program diperbarui.' end,
    jsonb_build_object('idempotency_key', request_idempotency_key)
  );
  return target_program;
end;
$$;

create or replace function public.duplicate_program_as_draft(
  source_target_id uuid,
  target_program_id uuid,
  target_title text,
  target_starts_on date,
  request_idempotency_key text
)
returns public.programs
language plpgsql
security definer
set search_path = ''
as $$
declare
  source public.programs;
  result public.programs;
  day_map jsonb;
  step_map jsonb;
  question_map jsonb;
  option_map jsonb;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(target_title, ''))) = 0 then raise exception 'program_title_required'; end if;

  select * into result from public.programs
  where id = target_program_id for update;
  if result.id is not null then
    if result.source_program_id = source_target_id
      and result.draft_idempotency_key = request_idempotency_key
    then return result; end if;
    raise exception 'program_id_conflict';
  end if;

  select * into source from public.programs
  where id = source_target_id for share;
  if source.id is null then raise exception 'program_not_found'; end if;

  select coalesce(
    jsonb_object_agg(id::text, gen_random_uuid()::text), '{}'::jsonb
  ) into day_map
  from public.program_days
  where program_id = source.id;

  select coalesce(
    jsonb_object_agg(step.id::text, gen_random_uuid()::text), '{}'::jsonb
  ) into step_map
  from public.program_steps step
  join public.program_days day on day.id = step.program_day_id
  where day.program_id = source.id;

  select coalesce(
    jsonb_object_agg(question.id::text, gen_random_uuid()::text), '{}'::jsonb
  ) into question_map
  from public.program_questions question
  join public.program_steps step on step.id = question.step_id
  join public.program_days day on day.id = step.program_day_id
  where day.program_id = source.id;

  select coalesce(
    jsonb_object_agg(option.id::text, gen_random_uuid()::text), '{}'::jsonb
  ) into option_map
  from public.program_question_options option
  join public.program_questions question on question.id = option.question_id
  join public.program_steps step on step.id = question.step_id
  join public.program_days day on day.id = step.program_day_id
  where day.program_id = source.id;

  insert into public.programs(
    id, source_program_id, title, summary, category, cover_path, cover_alt_text,
    status, pace, duration_mode, starts_on, ends_on, timezone,
    participant_limit, registration_closes_at, past_step_policy,
    future_step_policy, wellness_disclaimer, points_per_activity,
    points_per_weight_kg, quiz_passing_percentage, pricing_mode,
    desired_price, created_by, draft_idempotency_key
  ) values (
    target_program_id, source.id, trim(target_title), source.summary,
    source.category, source.cover_path, source.cover_alt_text, 'draft',
    source.pace, source.duration_mode, target_starts_on,
    target_starts_on + (source.ends_on - source.starts_on), source.timezone,
    source.participant_limit,
    case when source.registration_closes_at is null then null else
      source.registration_closes_at
        + make_interval(days => target_starts_on - source.starts_on)
    end,
    source.past_step_policy, source.future_step_policy,
    source.wellness_disclaimer, source.points_per_activity,
    source.points_per_weight_kg, source.quiz_passing_percentage,
    source.pricing_mode, source.desired_price, (select auth.uid()),
    request_idempotency_key
  );

  insert into public.program_days(id, program_id, day_number, title, summary, scheduled_on)
  select (day_map ->> day.id::text)::uuid, target_program_id,
    day.day_number, day.title, day.summary,
    target_starts_on + (day.scheduled_on - source.starts_on)
  from public.program_days day
  where day.program_id = source.id;

  insert into public.program_steps(
    id, program_day_id, step_order, title, instructions, content_kind,
    completion_policy, verification_mode, media_path, media_alt_text,
    video_required, video_threshold, video_autoplay
  )
  select (step_map ->> step.id::text)::uuid,
    (day_map ->> step.program_day_id::text)::uuid,
    step.step_order, step.title,
    step.instructions, step.content_kind, step.completion_policy,
    step.verification_mode, step.media_path, step.media_alt_text,
    step.video_required, step.video_threshold, step.video_autoplay
  from public.program_steps step
  where step_map ? step.id::text;

  insert into public.program_questions(id, step_id, question_order, kind, prompt)
  select (question_map ->> question.id::text)::uuid,
    (step_map ->> question.step_id::text)::uuid, question.question_order,
    question.kind, question.prompt
  from public.program_questions question
  where question_map ? question.id::text;

  insert into public.program_question_options(
    id, question_id, option_order, title, media_path, media_alt_text
  )
  select (option_map ->> option.id::text)::uuid,
    (question_map ->> option.question_id::text)::uuid, option.option_order,
    option.title, option.media_path, option.media_alt_text
  from public.program_question_options option
  where option_map ? option.id::text;

  insert into public.program_answer_keys(
    question_id, accepted_text_values, number_value, selected_option_ids, matching_mode
  )
  select (question_map ->> answer_key.question_id::text)::uuid,
    answer_key.accepted_text_values,
    answer_key.number_value,
    coalesce(array(
      select (option_map ->> selected_id::text)::uuid
      from unnest(answer_key.selected_option_ids) selected_id
      where option_map ? selected_id::text
    ), '{}'::uuid[]),
    answer_key.matching_mode
  from public.program_answer_keys answer_key
  where question_map ? answer_key.question_id::text;

  select * into result from public.programs where id = target_program_id;
  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()), 'program_created', result.id,
    'Program diduplikasi sebagai draft.',
    jsonb_build_object('source_program_id', source.id)
  );
  return result;
end;
$$;

create or replace function public.publish_program(
  target_program_id uuid,
  request_idempotency_key text
)
returns public.programs
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.programs;
  local_today date;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;

  select * into target from public.programs
  where id = target_program_id for update;
  if target.id is null then raise exception 'program_not_found'; end if;
  if target.publish_idempotency_key = request_idempotency_key
    and target.published_at is not null
  then return target; end if;
  if target.status <> 'draft' then raise exception 'program_not_draft'; end if;
  if target.pricing_mode = 'paid' then raise exception 'phase12_payment_handoff'; end if;
  if not exists (select 1 from public.program_days where program_id = target.id) then
    raise exception 'program_days_required';
  end if;
  if exists (
    select 1 from public.program_days day
    where day.program_id = target.id
      and not exists (
        select 1 from public.program_steps step where step.program_day_id = day.id
      )
  ) then raise exception 'program_step_required'; end if;
  if exists (
    select 1
    from public.program_questions question
    join public.program_steps step on step.id = question.step_id
    join public.program_days day on day.id = step.program_day_id
    where day.program_id = target.id
      and question.kind not in ('heading', 'text')
      and length(trim(question.prompt)) = 0
  ) then raise exception 'question_prompt_required'; end if;
  if exists (
    select 1
    from public.program_steps step
    join public.program_days day on day.id = step.program_day_id
    where day.program_id = target.id and step.content_kind = 'quiz'
      and not exists (
        select 1 from public.program_questions question
        join public.program_answer_keys answer_key on answer_key.question_id = question.id
        where question.step_id = step.id
      )
  ) then raise exception 'quiz_answer_key_required'; end if;
  if target.points_per_weight_kg > 0 and (
    (select count(*) from public.program_steps step
      join public.program_days day on day.id = step.program_day_id
      where day.program_id = target.id and step.content_kind = 'initial_weigh_in') <> 1
    or
    (select count(*) from public.program_steps step
      join public.program_days day on day.id = step.program_day_id
      where day.program_id = target.id and step.content_kind = 'final_weigh_in') <> 1
  ) then raise exception 'weigh_in_configuration_invalid'; end if;

  local_today := timezone(target.timezone, statement_timestamp())::date;
  update public.programs
  set status = case when starts_on <= local_today then 'active' else 'scheduled' end,
      published_at = statement_timestamp(),
      publish_idempotency_key = request_idempotency_key,
      updated_at = statement_timestamp()
  where id = target.id
  returning * into target;

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()), 'program_published', target.id,
    'Program diterbitkan.', jsonb_build_object('status', target.status)
  );
  return target;
end;
$$;

create or replace function public.lock_program_winners(
  target_program_id uuid,
  request_idempotency_key text
)
returns setof public.program_winners
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_program public.programs;
  snapshot public.winner_snapshots;
  enrollment_record record;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;

  select * into target_program from public.programs
  where id = target_program_id for update;
  if target_program.id is null then raise exception 'program_not_found'; end if;

  select * into snapshot from public.winner_snapshots
  where program_id = target_program_id for update;
  if snapshot.id is not null then
    if snapshot.idempotency_key = request_idempotency_key then
      return query select * from public.program_winners
      where snapshot_id = snapshot.id order by rank;
      return;
    end if;
    raise exception 'winners_already_locked';
  end if;

  if target_program.status <> 'completed' then raise exception 'program_not_completed'; end if;
  if exists (
    select 1 from public.step_submissions submission
    join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
    where enrollment.program_id = target_program_id and submission.status = 'pending'
  ) then raise exception 'pending_reviews_exist'; end if;
  if target_program.points_per_weight_kg > 0 and exists (
    select 1 from public.program_enrollments enrollment
    where enrollment.program_id = target_program_id
      and enrollment.status in ('active', 'completed')
      and not exists (
        select 1 from public.weigh_ins
        where enrollment_id = enrollment.id and kind = 'final'
      )
  ) then raise exception 'final_weight_missing'; end if;

  for enrollment_record in
    select id from public.program_enrollments
    where program_id = target_program_id
      and status in ('active', 'completed')
  loop
    perform private.recalculate_enrollment_score(enrollment_record.id);
  end loop;

  insert into public.winner_snapshots(program_id, locked_by, idempotency_key)
  values (target_program_id, (select auth.uid()), request_idempotency_key)
  returning * into snapshot;

  insert into public.program_winners(
    snapshot_id, participant_id, rank, display_name, total_points
  )
  select snapshot.id, enrollment.participant_id,
    row_number() over (
      order by
        (score.activity_points + score.quiz_points + score.weight_points
          + score.adjustment_points) desc,
        score.recalculated_at asc,
        enrollment.id asc
    )::integer,
    profile.display_name,
    score.activity_points + score.quiz_points + score.weight_points
      + score.adjustment_points
  from public.program_scores score
  join public.program_enrollments enrollment on enrollment.id = score.enrollment_id
  join public.profiles profile on profile.user_id = enrollment.participant_id
  where enrollment.program_id = target_program_id
    and enrollment.status in ('active', 'completed')
  order by
    (score.activity_points + score.quiz_points + score.weight_points
      + score.adjustment_points) desc,
    score.recalculated_at asc,
    enrollment.id asc
  limit 5;

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()), 'winners_locked', snapshot.id,
    'Pemenang program dikunci.', jsonb_build_object('program_id', target_program_id)
  );

  return query select * from public.program_winners
  where snapshot_id = snapshot.id order by rank;
end;
$$;

create or replace function public.complete_program(
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
  if target.status = 'completed'
    and target.completion_idempotency_key = request_idempotency_key
  then return target; end if;
  if target.status not in ('scheduled', 'active') then
    raise exception 'program_not_completable';
  end if;
  if exists (
    select 1 from public.step_submissions submission
    join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
    where enrollment.program_id = target_program_id
      and submission.status = 'pending'
  ) then raise exception 'pending_reviews_exist'; end if;

  update public.programs
  set status = 'completed',
      completion_idempotency_key = request_idempotency_key,
      updated_at = statement_timestamp()
  where id = target.id
  returning * into target;

  update public.program_enrollments
  set status = 'completed', completed_at = statement_timestamp()
  where program_id = target.id and status = 'active';

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()), 'program_completed', target.id, trim(reason),
    jsonb_build_object('idempotency_key', request_idempotency_key)
  );
  return target;
end;
$$;

create or replace function public.publish_winner_poster(
  target_program_id uuid,
  target_snapshot_id uuid,
  media_path text,
  alt_text text,
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
  if length(trim(coalesce(media_path, ''))) = 0 then raise exception 'media_required'; end if;
  if length(trim(coalesce(alt_text, ''))) = 0 then raise exception 'alt_text_required'; end if;
  if not exists (
    select 1 from public.winner_snapshots
    where id = target_snapshot_id and program_id = target_program_id
  ) then raise exception 'winner_snapshot_mismatch'; end if;
  if not exists (
    select 1 from storage.objects
    where bucket_id = 'public-media' and name = media_path
  ) then raise exception 'media_not_found'; end if;

  select * into result from public.winner_posters
  where program_id = target_program_id
    and idempotency_key = request_idempotency_key;
  if result.id is not null then return result; end if;

  insert into public.winner_posters(
    program_id, winner_snapshot_id, media_path, alt_text,
    is_published, published_at, idempotency_key
  ) values (
    target_program_id, target_snapshot_id, media_path, trim(alt_text),
    true, statement_timestamp(), request_idempotency_key
  ) returning * into result;

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()), 'managed_content_updated', result.id,
    'Poster pemenang diterbitkan.', jsonb_build_object(
      'program_id', target_program_id,
      'winner_snapshot_id', target_snapshot_id
    )
  );
  return result;
end;
$$;

-- Admin CMS mutations now go through audited functions. Direct table reads
-- remain available under RLS for typed Admin read models.
revoke insert, update, delete on table
  public.programs,
  public.program_days,
  public.program_steps,
  public.program_questions,
  public.program_question_options,
  public.program_answer_keys,
  public.winner_snapshots,
  public.program_winners,
  public.winner_posters,
  public.audit_events
from authenticated;

revoke execute on function
  public.update_coach_profile(uuid, text, text, text, boolean, text),
  public.list_my_assigned_participants(),
  public.list_my_pending_reviews(),
  public.save_program_draft(jsonb, text),
  public.duplicate_program_as_draft(uuid, uuid, text, date, text),
  public.publish_program(uuid, text),
  public.complete_program(uuid, text, text),
  public.lock_program_winners(uuid, text),
  public.publish_winner_poster(uuid, uuid, text, text, text)
from public, anon, authenticated, service_role;

grant execute on function
  public.update_coach_profile(uuid, text, text, text, boolean, text),
  public.list_my_assigned_participants(),
  public.list_my_pending_reviews(),
  public.save_program_draft(jsonb, text),
  public.duplicate_program_as_draft(uuid, uuid, text, date, text),
  public.publish_program(uuid, text),
  public.complete_program(uuid, text, text),
  public.lock_program_winners(uuid, text),
  public.publish_winner_poster(uuid, uuid, text, text, text)
to authenticated;
