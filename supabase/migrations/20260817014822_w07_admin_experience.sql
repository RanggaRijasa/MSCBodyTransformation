-- MSCWEB W07 Admin experience. All privileged mutations remain narrow,
-- server-authoritative, idempotent, and audited. Browser clients receive
-- fixed projections and never receive secrets or private media paths.

alter table public.coach_public_profile_items
  add column if not exists content_version integer not null default 1
    check (content_version > 0),
  add column if not exists moderation_version integer not null default 1
    check (moderation_version > 0),
  add column if not exists moderation_idempotency_key text;

create unique index if not exists coach_profile_item_moderation_idempotency_idx
  on public.coach_public_profile_items(moderated_by, moderation_idempotency_key)
  where moderated_by is not null and moderation_idempotency_key is not null;

create or replace function public.get_admin_dashboard()
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  return jsonb_build_object(
    'program_counts', jsonb_build_object(
      'draft', (select count(*) from public.programs where status = 'draft'),
      'scheduled', (select count(*) from public.programs where status = 'scheduled'),
      'active', (select count(*) from public.programs where status = 'active'),
      'completed', (select count(*) from public.programs where status = 'completed'),
      'archived', (select count(*) from public.programs where status = 'archived')
    ),
    'active_participant_count', (
      select count(distinct participant_id) from public.program_enrollments
      where status = 'active'
    ),
    'pending_reviews', (
      select count(*) from public.step_submissions where status = 'pending'
    ),
    'pending_coach_approvals', (
      select count(*) from public.coach_applications
      where status in ('submitted', 'pending_admin_approval')
    ),
    'pending_payments', (
      select count(*) from public.payment_orders where status = 'under_review'
    ),
    'pending_moderation', (
      select count(*) from public.coach_public_profile_items
      where moderation_status = 'pending'
    ),
    'ai_attention', (
      select count(*) from public.food_insight_jobs
      where status in ('failed', 'unavailable')
    ),
    'audit_events', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', event.id,
        'kind', event.kind,
        'subject_id', event.subject_id,
        'summary', event.summary,
        'created_at', event.created_at
      ) order by event.created_at desc, event.id)
      from (
        select id, kind, subject_id, summary, created_at
        from public.audit_events
        order by created_at desc, id
        limit 3
      ) event
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.list_admin_people()
returns setof jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  return query
  select jsonb_strip_nulls(jsonb_build_object(
    'user_id', profile.user_id,
    'role', profile.role,
    'display_name', profile.display_name,
    'city', profile.city,
    'provider_avatar_url', profile.provider_avatar_url,
    'member_level', profile.member_level,
    'current_coach_id', profile.current_coach_id,
    'current_coach_name', coach.display_name,
    'coach_is_approved', profile.coach_is_approved,
    'coach_is_public', profile.coach_is_public,
    'application_id', application.id,
    'application_status', application.status,
    'public_handle', draft.public_handle,
    'profile_published', published.coach_user_id is not null,
    'created_at', profile.created_at
  ))
  from public.profiles profile
  left join public.profiles coach on coach.user_id = profile.current_coach_id
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
  order by profile.display_name, profile.user_id;
end;
$$;

create or replace function public.get_admin_person_detail(target_user_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  return coalesce((
    select jsonb_strip_nulls(jsonb_build_object(
      'user_id', profile.user_id,
      'role', profile.role,
      'display_name', profile.display_name,
      'email', identity.email,
      'city', profile.city,
      'phone_number', profile.phone_number,
      'provider_avatar_url', profile.provider_avatar_url,
      'member_level', profile.member_level,
      'current_coach_id', profile.current_coach_id,
      'current_coach_name', coach.display_name,
      'coach_is_approved', profile.coach_is_approved,
      'coach_is_public', profile.coach_is_public,
      'coach_biography', profile.coach_biography,
      'application_id', application.id,
      'application_status', application.status,
      'public_handle', draft.public_handle,
      'profile_published', published.coach_user_id is not null,
      'created_at', profile.created_at
    ))
    from public.profiles profile
    left join auth.users identity on identity.id = profile.user_id
    left join public.profiles coach on coach.user_id = profile.current_coach_id
    left join lateral (
      select item.id, item.status from public.coach_applications item
      where item.applicant_user_id = profile.user_id
      order by item.created_at desc, item.id limit 1
    ) application on true
    left join public.coach_public_profile_drafts draft on draft.coach_user_id = profile.user_id
    left join public.coach_public_profiles published on published.coach_user_id = profile.user_id
    where profile.user_id = target_user_id
  ), '{}'::jsonb);
end;
$$;

create or replace function public.list_admin_pending_evidence()
returns setof jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  return query
  select jsonb_build_object(
    'submission_id', submission.id,
    'participant_id', enrollment.participant_id,
    'participant_name', participant.display_name,
    'program_id', program.id,
    'program_title', program.title,
    'step_title', step.title,
    'submitted_at', submission.submitted_at,
    'status', submission.status
  )
  from public.step_submissions submission
  join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
  join public.profiles participant on participant.user_id = enrollment.participant_id
  join public.program_steps step on step.id = submission.step_id
  join public.program_days day on day.id = step.program_day_id
  join public.programs program on program.id = day.program_id
  where submission.status = 'pending'
  order by submission.submitted_at nulls last, submission.id;
end;
$$;

create or replace function public.list_admin_profile_moderation_items()
returns setof jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  return query
  select jsonb_build_object(
    'id', item.id,
    'coach_user_id', item.coach_user_id,
    'coach_name', profile.display_name,
    'item_kind', item.item_kind,
    'title', item.title,
    'body', item.body,
    'media_object_path', item.media_object_path,
    'includes_third_party', item.includes_third_party,
    'permission_attested', item.permission_attested,
    'moderation_status', item.moderation_status,
    'content_version', item.content_version,
    'moderation_version', item.moderation_version,
    'moderation_note', item.moderation_note,
    'submitted_at', item.submitted_at,
    'moderated_at', item.moderated_at
  )
  from public.coach_public_profile_items item
  join public.profiles profile on profile.user_id = item.coach_user_id
  order by case item.moderation_status when 'pending' then 0 else 1 end,
    item.submitted_at, item.id;
end;
$$;

create or replace function public.list_admin_food_insight_operations()
returns setof jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  return query
  select jsonb_strip_nulls(jsonb_build_object(
    'job_id', job.id,
    'submission_id', job.submission_id,
    'participant_name', participant.display_name,
    'program_title', program.title,
    'step_title', step.title,
    'status', job.status,
    'attempt_count', job.attempt_count,
    'max_attempts', job.max_attempts,
    'terminal_error_code', job.terminal_error_code,
    'analysis_version', job.analysis_version,
    'provider_name', result.provider_name,
    'model_alias', result.model_alias,
    'policy_version', result.policy_version,
    'output_policy_version', result.output_policy_version,
    'result_id', result.id,
    'effective_rating', result.effective_rating,
    'result_version', result.version,
    'updated_at', job.updated_at
  ))
  from public.food_insight_jobs job
  join public.step_submissions submission on submission.id = job.submission_id
  join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
  join public.profiles participant on participant.user_id = enrollment.participant_id
  join public.program_steps step on step.id = submission.step_id
  join public.program_days day on day.id = step.program_day_id
  join public.programs program on program.id = day.program_id
  left join public.food_insight_results result on result.job_id = job.id
  order by case job.status
    when 'failed' then 0 when 'unavailable' then 1
    when 'processing' then 2 when 'retry_scheduled' then 3 else 4 end,
    job.updated_at desc, job.id;
end;
$$;

create or replace function public.list_admin_audit_events(result_limit integer default 50)
returns setof jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  return query
  select jsonb_build_object(
    'id', event.id,
    'actor_id', event.actor_id,
    'actor_name', actor.display_name,
    'kind', event.kind,
    'subject_id', event.subject_id,
    'summary', event.summary,
    'created_at', event.created_at
  )
  from public.audit_events event
  left join public.profiles actor on actor.user_id = event.actor_id
  order by event.created_at desc, event.id
  limit least(greatest(result_limit, 1), 200);
end;
$$;

create or replace function public.get_admin_closure_preflight(target_program_id uuid)
returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare target public.programs;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  select * into target from public.programs where id = target_program_id;
  if target.id is null then raise exception 'program_not_found'; end if;
  return jsonb_build_object(
    'program_id', target.id,
    'program_status', target.status,
    'enrollment_count', (select count(*) from public.program_enrollments
      where program_id = target.id and status in ('active', 'completed')),
    'pending_reviews', (select count(*) from public.step_submissions submission
      join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
      where enrollment.program_id = target.id and submission.status = 'pending'),
    'missing_final_weigh_ins', (select count(*) from public.program_enrollments enrollment
      where enrollment.program_id = target.id and enrollment.status in ('active', 'completed')
        and target.points_per_weight_kg > 0
        and not exists (select 1 from public.weigh_ins weigh_in
          where weigh_in.enrollment_id = enrollment.id and weigh_in.kind = 'final')),
    'failed_quizzes', (select count(*) from public.quiz_attempt_results quiz
      join public.step_submissions submission on submission.id = quiz.submission_id
      join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
      where enrollment.program_id = target.id and not quiz.passed),
    'winners_locked', exists(select 1 from public.winner_snapshots snapshot
      where snapshot.program_id = target.id)
  );
end;
$$;

create or replace function public.preview_admin_program_winners(target_program_id uuid)
returns setof jsonb
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  return query
  select jsonb_build_object(
    'enrollment_id', ranked.enrollment_id,
    'participant_id', ranked.participant_id,
    'participant_name', ranked.display_name,
    'rank', ranked.rank,
    'total_points', ranked.total_points,
    'progress_percentage', ranked.progress_percentage
  )
  from (
    select enrollment.id enrollment_id, enrollment.participant_id,
      profile.display_name,
      row_number() over (order by
        (score.activity_points + score.quiz_points + score.weight_points + score.adjustment_points) desc,
        score.recalculated_at asc, enrollment.id asc)::integer rank,
      score.activity_points + score.quiz_points + score.weight_points + score.adjustment_points total_points,
      score.progress_percentage
    from public.program_scores score
    join public.program_enrollments enrollment on enrollment.id = score.enrollment_id
    join public.profiles profile on profile.user_id = enrollment.participant_id
    where enrollment.program_id = target_program_id
      and enrollment.status in ('active', 'completed')
  ) ranked
  order by ranked.rank
  limit 5;
end;
$$;

create or replace function public.save_admin_program_draft(
  program_payload jsonb,
  request_idempotency_key text
)
returns public.programs
language plpgsql security definer
set search_path = ''
as $$
declare result public.programs;
declare day_payload jsonb;
declare step_payload jsonb;
declare question_payload jsonb;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  result := public.save_program_draft(program_payload, request_idempotency_key);
  for day_payload in select value from jsonb_array_elements(program_payload -> 'days') loop
    for step_payload in select value from jsonb_array_elements(day_payload -> 'steps') loop
      for question_payload in select value from jsonb_array_elements(
        coalesce(step_payload -> 'questions', '[]'::jsonb)
      ) loop
        update public.program_questions set
          analysis_mode = coalesce(question_payload ->> 'analysis_mode', 'none'),
          analysis_rubric = nullif(question_payload ->> 'analysis_rubric', ''),
          analysis_rubric_version = nullif(question_payload ->> 'analysis_rubric_version', '')
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
language plpgsql security definer
set search_path = ''
as $$
declare result public.programs;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  result := public.duplicate_program_as_draft(
    source_program_id, target_program_id, target_title,
    target_start_date, request_idempotency_key
  );
  update public.program_questions target_question set
    analysis_mode = source_question.analysis_mode,
    analysis_rubric = source_question.analysis_rubric,
    analysis_rubric_version = source_question.analysis_rubric_version
  from public.program_steps target_step
  join public.program_days target_day on target_day.id = target_step.program_day_id
  join public.program_days source_day on source_day.program_id = source_program_id
    and source_day.day_number = target_day.day_number
  join public.program_steps source_step on source_step.program_day_id = source_day.id
    and source_step.step_order = target_step.step_order
  join public.program_questions source_question on source_question.step_id = source_step.id
  where target_question.step_id = target_step.id
    and target_day.program_id = target_program_id
    and source_question.question_order = target_question.question_order;
  return result;
end;
$$;

create or replace function public.archive_admin_program(
  target_program_id uuid,
  reason text,
  request_idempotency_key text
)
returns public.programs
language plpgsql security definer
set search_path = ''
as $$
declare target public.programs;
declare previous_status text;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reason, ''))) < 8 then raise exception 'reason_required'; end if;
  select * into target from public.programs where id = target_program_id for update;
  if target.id is null then raise exception 'program_not_found'; end if;
  if target.archive_idempotency_key = request_idempotency_key then return target; end if;
  if target.status = 'draft' then raise exception 'draft_cannot_be_archived'; end if;
  if target.status = 'archived' then raise exception 'program_already_archived'; end if;
  previous_status := target.status;
  update public.programs set status = 'archived',
    archive_idempotency_key = request_idempotency_key,
    updated_at = statement_timestamp()
  where id = target.id returning * into target;
  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values ((select auth.uid()), 'program_archived', target.id, trim(reason),
    jsonb_build_object('before_status', previous_status, 'after_status', 'archived'));
  return target;
end;
$$;

create or replace function public.moderate_admin_coach_profile_item(
  target_item_id uuid,
  expected_version integer,
  decision text,
  note text,
  request_idempotency_key text
)
returns public.coach_public_profile_items
language plpgsql security definer
set search_path = ''
as $$
declare target public.coach_public_profile_items;
declare previous_status text;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if decision not in ('approved', 'rejected') then raise exception 'decision_invalid'; end if;
  if decision = 'rejected' and length(trim(coalesce(note, ''))) < 8 then
    raise exception 'reason_required'; end if;
  select * into target from public.coach_public_profile_items
  where id = target_item_id for update;
  if target.id is null then raise exception 'profile_item_not_found'; end if;
  if target.moderation_idempotency_key = request_idempotency_key then return target; end if;
  if target.moderation_version <> expected_version then raise exception 'moderation_conflict'; end if;
  previous_status := target.moderation_status;
  update public.coach_public_profile_items set
    moderation_status = decision,
    moderated_at = statement_timestamp(),
    moderated_by = (select auth.uid()),
    moderation_note = nullif(trim(note), ''),
    moderation_version = moderation_version + 1,
    moderation_idempotency_key = request_idempotency_key
  where id = target.id returning * into target;
  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values ((select auth.uid()), 'coach_profile_item_moderated', target.id,
    case when decision = 'approved' then 'Konten profil Coach disetujui.' else trim(note) end,
    jsonb_build_object(
      'before_status', previous_status,
      'after_status', decision,
      'content_version', target.content_version,
      'moderation_version', target.moderation_version
    ));
  return target;
end;
$$;

create or replace function public.archive_admin_winner_poster(
  target_poster_id uuid,
  reason text,
  request_idempotency_key text
)
returns public.winner_posters
language plpgsql security definer
set search_path = ''
as $$
declare target public.winner_posters;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reason, ''))) < 8 then raise exception 'reason_required'; end if;
  select * into target from public.winner_posters where id = target_poster_id for update;
  if target.id is null then raise exception 'poster_not_found'; end if;
  if target.mutation_idempotency_key = request_idempotency_key then return target; end if;
  update public.winner_posters set is_published = false,
    deleted_at = statement_timestamp(), mutation_idempotency_key = request_idempotency_key
  where id = target.id returning * into target;
  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values ((select auth.uid()), 'winner_poster_archived', target.id, trim(reason),
    jsonb_build_object('program_id', target.program_id, 'winner_snapshot_id', target.winner_snapshot_id));
  return target;
end;
$$;

revoke execute on function public.moderate_coach_public_profile_item(uuid,text,text)
  from public, anon, authenticated, service_role;

revoke execute on function
  public.get_admin_dashboard(),
  public.list_admin_people(),
  public.get_admin_person_detail(uuid),
  public.list_admin_pending_evidence(),
  public.list_admin_profile_moderation_items(),
  public.list_admin_food_insight_operations(),
  public.list_admin_audit_events(integer),
  public.get_admin_closure_preflight(uuid),
  public.preview_admin_program_winners(uuid),
  public.save_admin_program_draft(jsonb,text),
  public.duplicate_admin_program_as_draft(uuid,uuid,text,date,text),
  public.archive_admin_program(uuid,text,text),
  public.moderate_admin_coach_profile_item(uuid,integer,text,text,text),
  public.archive_admin_winner_poster(uuid,text,text)
from public, anon, authenticated, service_role;

grant execute on function
  public.get_admin_dashboard(),
  public.list_admin_people(),
  public.get_admin_person_detail(uuid),
  public.list_admin_pending_evidence(),
  public.list_admin_profile_moderation_items(),
  public.list_admin_food_insight_operations(),
  public.list_admin_audit_events(integer),
  public.get_admin_closure_preflight(uuid),
  public.preview_admin_program_winners(uuid),
  public.save_admin_program_draft(jsonb,text),
  public.duplicate_admin_program_as_draft(uuid,uuid,text,date,text),
  public.archive_admin_program(uuid,text,text),
  public.moderate_admin_coach_profile_item(uuid,integer,text,text,text),
  public.archive_admin_winner_poster(uuid,text,text)
to authenticated;
