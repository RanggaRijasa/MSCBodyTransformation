-- Food insight is strictly opt-in. A disabled question must never be claimed
-- by the provider, including jobs queued before the configuration changed.

create or replace function public.reconcile_food_insight_jobs(
  target_analysis_version text default 'food_insight_v1'
)
returns integer
language plpgsql security definer
set search_path = ''
as $$
declare inserted_count integer;
begin
  if target_analysis_version <> 'food_insight_v1' then
    raise exception 'analysis_version_invalid';
  end if;

  update public.food_insight_jobs job set
    status = 'unavailable',
    terminal_error_code = 'configuration_invalid',
    lease_token = null,
    lease_expires_at = null,
    updated_at = statement_timestamp()
  from public.program_questions question
  where question.id = job.question_id
    and job.analysis_version = target_analysis_version
    and job.status in ('queued', 'retry_scheduled')
    and (
      question.kind <> 'photo_upload'
      or question.analysis_mode <> 'food'
    );

  insert into public.food_insight_jobs(
    submission_id, answer_id, question_id, analysis_version, rubric, rubric_version
  )
  select distinct on (submission.id)
    submission.id, answer.id, answer.question_id, target_analysis_version,
    question.analysis_rubric, question.analysis_rubric_version
  from public.step_submissions submission
  join public.step_submission_answers answer on answer.submission_id = submission.id
  join public.program_questions question on question.id = answer.question_id
  where submission.status <> 'draft'
    and submission.finalized_at is not null
    and question.kind = 'photo_upload'
    and question.analysis_mode = 'food'
    and answer.private_photo_path is not null
  order by submission.id, question.question_order, question.id
  on conflict (submission_id, analysis_version) do nothing;
  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;

create or replace function public.claim_food_insight_job(
  lease_seconds integer default 90,
  target_submission_id uuid default null
)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare target public.food_insight_jobs;
declare token uuid := gen_random_uuid();
declare object_path text;
begin
  if lease_seconds not between 30 and 300 then raise exception 'lease_invalid'; end if;

  select job.* into target
  from public.food_insight_jobs job
  join public.program_questions question on question.id = job.question_id
  join public.step_submission_answers answer on answer.id = job.answer_id
  where ((
      job.status in ('queued', 'retry_scheduled')
      and job.next_attempt_at <= statement_timestamp()
    ) or (
      job.status = 'processing'
      and job.lease_expires_at < statement_timestamp()
    ))
    and (target_submission_id is null or job.submission_id = target_submission_id)
    and question.kind = 'photo_upload'
    and question.analysis_mode = 'food'
    and answer.private_photo_path is not null
  order by job.next_attempt_at, job.created_at
  for update of job skip locked
  limit 1;
  if target.id is null then return null; end if;

  update public.food_insight_jobs set
    status = 'processing',
    attempt_count = attempt_count + 1,
    lease_token = token,
    lease_expires_at = statement_timestamp() + make_interval(secs => lease_seconds),
    terminal_error_code = null,
    updated_at = statement_timestamp()
  where id = target.id
  returning * into target;

  select answer.private_photo_path into object_path
  from public.step_submission_answers answer
  where answer.id = target.answer_id;

  return jsonb_build_object(
    'id', target.id,
    'submission_id', target.submission_id,
    'question_id', target.question_id,
    'analysis_version', target.analysis_version,
    'rubric', target.rubric,
    'rubric_version', target.rubric_version,
    'private_photo_path', object_path,
    'lease_token', token,
    'attempt_count', target.attempt_count,
    'max_attempts', target.max_attempts
  );
end;
$$;

revoke execute on function public.reconcile_food_insight_jobs(text)
  from public, anon, authenticated;
grant execute on function public.reconcile_food_insight_jobs(text)
  to service_role;
revoke execute on function public.claim_food_insight_job(integer,uuid)
  from public, anon, authenticated;
grant execute on function public.claim_food_insight_job(integer,uuid)
  to service_role;
