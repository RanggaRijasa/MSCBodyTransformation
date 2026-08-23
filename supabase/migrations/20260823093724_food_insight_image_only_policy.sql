-- Food insight v2 is image-only. Program questions, steps, rubrics, and other
-- participant context never cross the worker/provider boundary.

alter table public.food_insight_results
  drop constraint if exists food_insight_results_policy_version_check;
alter table public.food_insight_results
  add constraint food_insight_results_policy_version_check check (
    policy_version in ('food_rating_policy_v1', 'food_rating_policy_v2_image_only')
  );

alter table public.food_insight_results
  drop constraint if exists food_insight_results_output_policy_version_check;
alter table public.food_insight_results
  add constraint food_insight_results_output_policy_version_check check (
    output_policy_version in ('food_insight_output_v1', 'food_insight_output_v2_image_only')
  );

alter table public.food_insight_results
  drop constraint if exists food_insight_results_reason_code_check;
alter table public.food_insight_results
  add constraint food_insight_results_reason_code_check check (
    reason_code in (
      'strong_rubric_match', 'plausible_food', 'ambiguous_or_mixed',
      'not_food_for_required_food', 'severe_explicit_rubric_mismatch',
      'invalid_provider_output', 'food_or_drink_detected', 'shake_detected',
      'image_uncertain', 'not_food_detected'
    )
  );

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
    'private_photo_path', object_path,
    'lease_token', token,
    'attempt_count', target.attempt_count,
    'max_attempts', target.max_attempts
  );
end;
$$;

create or replace function public.complete_food_insight_job(
  target_job_id uuid,
  target_lease_token uuid,
  validated_result jsonb,
  provider_name text,
  model_alias text
)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare target public.food_insight_jobs;
declare result_id uuid;
declare sentences text[];
begin
  select * into target from public.food_insight_jobs where id = target_job_id for update;
  if target.id is null or target.status <> 'processing' or target.lease_token is distinct from target_lease_token
  then raise exception 'job_lease_conflict'; end if;

  sentences := array(select jsonb_array_elements_text(validated_result -> 'insight_sentences'));
  insert into public.food_insight_results(
    job_id, submission_id, question_id, analysis_version, policy_version,
    output_policy_version, provider_name, model_alias, detected_kind,
    protein_grams, carbohydrate_grams, fat_grams, calorie_kcal,
    ai_rating, effective_rating, confidence, reason_code, insight_sentences
  ) values (
    target.id, target.submission_id, target.question_id, target.analysis_version,
    'food_rating_policy_v2_image_only', 'food_insight_output_v2_image_only',
    provider_name, model_alias, validated_result ->> 'detected_kind',
    nullif(validated_result ->> 'protein_grams', '')::numeric,
    nullif(validated_result ->> 'carbohydrate_grams', '')::numeric,
    nullif(validated_result ->> 'fat_grams', '')::numeric,
    nullif(validated_result ->> 'calorie_kcal', '')::numeric,
    (validated_result ->> 'rating')::integer,
    (validated_result ->> 'rating')::integer,
    (validated_result ->> 'confidence')::numeric,
    validated_result ->> 'reason_code',
    sentences
  )
  on conflict (submission_id, analysis_version) do update set
    updated_at = public.food_insight_results.updated_at
  returning id into result_id;

  update public.food_insight_jobs set
    status = 'completed',
    completed_at = statement_timestamp(),
    lease_token = null,
    lease_expires_at = null,
    updated_at = statement_timestamp()
  where id = target.id;
  return result_id;
end;
$$;

revoke execute on function public.claim_food_insight_job(integer,uuid)
  from public, anon, authenticated;
grant execute on function public.claim_food_insight_job(integer,uuid)
  to service_role;
revoke execute on function public.complete_food_insight_job(uuid,uuid,jsonb,text,text)
  from public, anon, authenticated;
grant execute on function public.complete_food_insight_job(uuid,uuid,jsonb,text,text)
  to service_role;
