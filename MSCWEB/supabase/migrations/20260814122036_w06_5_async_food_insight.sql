-- MSCWEB W06.5 async food insight. Secondary analysis only: never changes
-- submission review state, points, or leaderboard accounting.

alter table public.program_questions
  add column if not exists analysis_mode text not null default 'none',
  add column if not exists analysis_rubric text,
  add column if not exists analysis_rubric_version text;

alter table public.program_questions
  drop constraint if exists program_questions_analysis_mode_check;
alter table public.program_questions
  add constraint program_questions_analysis_mode_check check (
    analysis_mode in ('none', 'food')
    and (analysis_mode = 'none' or kind = 'photo_upload')
    and (analysis_mode = 'food' or (analysis_rubric is null and analysis_rubric_version is null))
    and (analysis_rubric is not null or analysis_rubric_version is null)
    and (analysis_rubric is null or length(analysis_rubric) <= 500)
    and (analysis_rubric_version is null or length(analysis_rubric_version) <= 80)
  );

create table if not exists public.food_insight_jobs (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.step_submissions(id) on delete cascade,
  answer_id uuid not null references public.step_submission_answers(id) on delete cascade,
  question_id uuid not null references public.program_questions(id) on delete restrict,
  analysis_version text not null,
  rubric text,
  rubric_version text,
  status text not null default 'queued' check (
    status in ('queued', 'processing', 'retry_scheduled', 'completed', 'failed', 'unavailable')
  ),
  attempt_count integer not null default 0 check (attempt_count between 0 and 5),
  max_attempts integer not null default 3 check (max_attempts between 1 and 5),
  next_attempt_at timestamptz not null default statement_timestamp(),
  lease_token uuid,
  lease_expires_at timestamptz,
  terminal_error_code text check (
    terminal_error_code is null or terminal_error_code in (
      'provider_unavailable', 'rate_limited', 'invalid_output',
      'incompatible_model', 'image_unavailable', 'configuration_invalid', 'attempts_exhausted'
    )
  ),
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  completed_at timestamptz,
  unique (submission_id, analysis_version)
);

create table if not exists public.food_insight_results (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null unique references public.food_insight_jobs(id) on delete cascade,
  submission_id uuid not null references public.step_submissions(id) on delete cascade,
  question_id uuid not null references public.program_questions(id) on delete restrict,
  analysis_version text not null,
  policy_version text not null check (policy_version = 'food_rating_policy_v1'),
  output_policy_version text not null check (output_policy_version = 'food_insight_output_v1'),
  provider_name text not null check (length(provider_name) between 1 and 60),
  model_alias text not null check (length(model_alias) between 1 and 160),
  detected_kind text not null check (
    detected_kind in ('food', 'drink', 'shake', 'not_food', 'uncertain')
  ),
  protein_grams numeric(8,2) check (protein_grams is null or protein_grams between 0 and 1000),
  carbohydrate_grams numeric(8,2) check (carbohydrate_grams is null or carbohydrate_grams between 0 and 1000),
  fat_grams numeric(8,2) check (fat_grams is null or fat_grams between 0 and 1000),
  calorie_kcal numeric(10,2) check (calorie_kcal is null or calorie_kcal between 0 and 10000),
  ai_rating integer not null check (ai_rating between 1 and 5),
  effective_rating integer not null check (effective_rating between 1 and 5),
  confidence numeric(5,4) not null check (confidence between 0 and 1),
  reason_code text not null check (
    reason_code in (
      'strong_rubric_match', 'plausible_food', 'ambiguous_or_mixed',
      'not_food_for_required_food', 'severe_explicit_rubric_mismatch', 'invalid_provider_output'
    )
  ),
  insight_sentences text[] not null check (
    cardinality(insight_sentences) between 1 and 2
    and array_to_string(insight_sentences, ' ') <> ''
    and length(array_to_string(insight_sentences, ' ')) <= 160
    and length(trim(insight_sentences[1])) between 4 and 80
    and (cardinality(insight_sentences) = 1 or length(trim(insight_sentences[2])) between 4 and 80)
  ),
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  unique (submission_id, analysis_version)
);

create table if not exists public.food_insight_corrections (
  id uuid primary key default gen_random_uuid(),
  result_id uuid not null references public.food_insight_results(id) on delete cascade,
  actor_id uuid not null references public.profiles(user_id),
  previous_rating integer not null check (previous_rating between 1 and 5),
  corrected_rating integer not null check (corrected_rating between 1 and 5),
  reason text not null check (length(trim(reason)) between 8 and 500),
  idempotency_key text not null,
  created_at timestamptz not null default statement_timestamp(),
  unique (actor_id, idempotency_key)
);

create index if not exists food_insight_jobs_claim_idx
  on public.food_insight_jobs(status, next_attempt_at, created_at);
create index if not exists food_insight_results_submission_idx
  on public.food_insight_results(submission_id, analysis_version);

alter table public.food_insight_jobs enable row level security;
alter table public.food_insight_results enable row level security;
alter table public.food_insight_corrections enable row level security;

revoke all on table public.food_insight_jobs, public.food_insight_results,
  public.food_insight_corrections from public, anon, authenticated;
grant select on table public.food_insight_jobs, public.food_insight_results,
  public.food_insight_corrections to authenticated;
grant all on table public.food_insight_jobs, public.food_insight_results,
  public.food_insight_corrections to service_role;

create or replace function private.can_read_food_insight(target_submission_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.step_submissions submission
    join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
    where submission.id = target_submission_id
      and (
        enrollment.participant_id = (select auth.uid())
        or enrollment.coach_id = (select auth.uid())
        or private.is_admin()
      )
  );
$$;
revoke execute on function private.can_read_food_insight(uuid) from public, anon;
grant execute on function private.can_read_food_insight(uuid) to authenticated, service_role;

drop policy if exists "Authorized members read food insight jobs" on public.food_insight_jobs;
create policy "Authorized members read food insight jobs"
on public.food_insight_jobs for select to authenticated
using (exists (
  select 1 where private.can_read_food_insight(food_insight_jobs.submission_id)
));

drop policy if exists "Authorized members read food insight results" on public.food_insight_results;
create policy "Authorized members read food insight results"
on public.food_insight_results for select to authenticated
using (exists (
  select 1 where private.can_read_food_insight(food_insight_results.submission_id)
));

drop policy if exists "Authorized members read food insight corrections" on public.food_insight_corrections;
create policy "Authorized members read food insight corrections"
on public.food_insight_corrections for select to authenticated
using (
  exists (
    select 1 from public.food_insight_results result
    where result.id = food_insight_corrections.result_id
      and private.can_read_food_insight(result.submission_id)
  )
);

create or replace function public.list_public_food_question_configs(target_question_ids uuid[])
returns setof jsonb
language sql stable security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', question.id,
    'analysis_mode', question.analysis_mode,
    'analysis_rubric', question.analysis_rubric,
    'analysis_rubric_version', question.analysis_rubric_version
  )
  from public.program_questions question
  join public.program_steps step on step.id = question.step_id
  join public.program_days day on day.id = step.program_day_id
  join public.programs program on program.id = day.program_id
  where question.id = any(coalesce(target_question_ids, '{}'::uuid[]))
    and program.status in ('scheduled', 'active', 'completed', 'archived');
$$;

create or replace function public.enqueue_food_insight(
  target_submission_id uuid,
  target_analysis_version text default 'food_insight_v1'
)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  candidate record;
  result_id uuid;
begin
  if target_analysis_version <> 'food_insight_v1' then
    raise exception 'analysis_version_invalid';
  end if;

  select submission.id submission_id, enrollment.participant_id,
    answer.id answer_id, answer.question_id,
    question.analysis_rubric, question.analysis_rubric_version
  into candidate
  from public.step_submissions submission
  join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
  join public.step_submission_answers answer on answer.submission_id = submission.id
  join public.program_questions question on question.id = answer.question_id
  where submission.id = target_submission_id
    and submission.status <> 'draft'
    and submission.finalized_at is not null
    and question.kind = 'photo_upload'
    and question.analysis_mode = 'food'
    and answer.private_photo_path is not null
  order by question.question_order, question.id
  limit 1;

  if candidate.submission_id is null then return null; end if;
  if caller_id is distinct from candidate.participant_id
    and coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role'
    and not private.is_admin()
  then raise exception 'permission_denied'; end if;

  insert into public.food_insight_jobs(
    submission_id, answer_id, question_id, analysis_version, rubric, rubric_version
  ) values (
    candidate.submission_id, candidate.answer_id, candidate.question_id,
    target_analysis_version, candidate.analysis_rubric, candidate.analysis_rubric_version
  )
  on conflict (submission_id, analysis_version) do update
    set updated_at = public.food_insight_jobs.updated_at
  returning id into result_id;
  return result_id;
exception when others then
  if sqlerrm in ('permission_denied', 'analysis_version_invalid') then raise; end if;
  return null;
end;
$$;

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
  insert into public.food_insight_jobs(
    submission_id, answer_id, question_id, analysis_version, rubric, rubric_version
  )
  select distinct on (submission.id)
    submission.id, answer.id, answer.question_id, target_analysis_version,
    question.analysis_rubric, question.analysis_rubric_version
  from public.step_submissions submission
  join public.step_submission_answers answer on answer.submission_id = submission.id
  join public.program_questions question on question.id = answer.question_id
  where submission.status <> 'draft' and submission.finalized_at is not null
    and question.kind = 'photo_upload' and question.analysis_mode = 'food'
    and answer.private_photo_path is not null
  order by submission.id, question.question_order, question.id
  on conflict (submission_id, analysis_version) do nothing;
  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;

create or replace function public.correct_food_insight_rating(
  target_result_id uuid,
  expected_version integer,
  corrected_rating integer,
  correction_reason text,
  request_idempotency_key text
)
returns public.food_insight_results
language plpgsql security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  target public.food_insight_results;
  old_rating integer;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if corrected_rating not between 1 and 5 then raise exception 'rating_invalid'; end if;
  if length(trim(coalesce(correction_reason, ''))) < 8 then raise exception 'correction_reason_required'; end if;

  select result.* into target
  from public.food_insight_results result
  where result.id = target_result_id for update;
  if target.id is null then raise exception 'insight_not_found'; end if;
  if not (
    exists (
      select 1 from public.step_submissions submission
      join public.program_enrollments enrollment on enrollment.id = submission.enrollment_id
      where submission.id = target.submission_id and enrollment.coach_id = caller_id
    ) or private.is_admin()
  ) then raise exception 'permission_denied'; end if;

  if exists (
    select 1 from public.food_insight_corrections correction
    where correction.actor_id = caller_id and correction.idempotency_key = request_idempotency_key
  ) then return target; end if;
  if target.version <> expected_version then raise exception 'correction_conflict'; end if;

  old_rating := target.effective_rating;
  update public.food_insight_results set
    effective_rating = corrected_rating,
    version = version + 1,
    updated_at = statement_timestamp()
  where id = target.id returning * into target;

  insert into public.food_insight_corrections(
    result_id, actor_id, previous_rating, corrected_rating, reason, idempotency_key
  ) values (
    target.id, caller_id, old_rating, corrected_rating,
    trim(correction_reason), request_idempotency_key
  );
  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    caller_id, 'food_insight_rating_corrected', target.id,
    'Rating AI dikoreksi tanpa mengubah persetujuan atau poin.',
    jsonb_build_object('previous_rating', old_rating, 'corrected_rating', corrected_rating,
      'reason', trim(correction_reason), 'result_version', target.version)
  );
  return target;
end;
$$;

drop function if exists public.claim_food_insight_job(integer);
create or replace function public.claim_food_insight_job(lease_seconds integer default 90, target_submission_id uuid default null)
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
  where ((
      job.status in ('queued', 'retry_scheduled') and job.next_attempt_at <= statement_timestamp()
    ) or (
      job.status = 'processing' and job.lease_expires_at < statement_timestamp()
    ))
    and (target_submission_id is null or job.submission_id = target_submission_id)
  order by job.next_attempt_at, job.created_at
  for update skip locked limit 1;
  if target.id is null then return null; end if;

  update public.food_insight_jobs set
    status = 'processing', attempt_count = attempt_count + 1,
    lease_token = token, lease_expires_at = statement_timestamp() + make_interval(secs => lease_seconds),
    terminal_error_code = null, updated_at = statement_timestamp()
  where id = target.id returning * into target;
  select answer.private_photo_path into object_path
  from public.step_submission_answers answer where answer.id = target.answer_id;
  return jsonb_build_object(
    'id', target.id, 'submission_id', target.submission_id,
    'question_id', target.question_id, 'analysis_version', target.analysis_version,
    'rubric', target.rubric, 'rubric_version', target.rubric_version,
    'private_photo_path', object_path, 'lease_token', token,
    'attempt_count', target.attempt_count, 'max_attempts', target.max_attempts
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
    'food_rating_policy_v1', 'food_insight_output_v1', provider_name, model_alias,
    validated_result ->> 'detected_kind',
    nullif(validated_result ->> 'protein_grams', '')::numeric,
    nullif(validated_result ->> 'carbohydrate_grams', '')::numeric,
    nullif(validated_result ->> 'fat_grams', '')::numeric,
    nullif(validated_result ->> 'calorie_kcal', '')::numeric,
    (validated_result ->> 'rating')::integer, (validated_result ->> 'rating')::integer,
    (validated_result ->> 'confidence')::numeric, validated_result ->> 'reason_code', sentences
  )
  on conflict (submission_id, analysis_version) do update set
    updated_at = public.food_insight_results.updated_at
  returning id into result_id;
  update public.food_insight_jobs set status = 'completed', completed_at = statement_timestamp(),
    lease_token = null, lease_expires_at = null, updated_at = statement_timestamp()
  where id = target.id;
  return result_id;
end;
$$;

create or replace function public.fail_food_insight_job(
  target_job_id uuid,
  target_lease_token uuid,
  error_code text,
  retryable boolean
)
returns text
language plpgsql security definer
set search_path = ''
as $$
declare target public.food_insight_jobs;
declare next_status text;
begin
  if error_code not in ('provider_unavailable', 'rate_limited', 'invalid_output',
    'incompatible_model', 'image_unavailable', 'configuration_invalid', 'attempts_exhausted')
  then raise exception 'error_code_invalid'; end if;
  select * into target from public.food_insight_jobs where id = target_job_id for update;
  if target.id is null or target.status <> 'processing' or target.lease_token is distinct from target_lease_token
  then raise exception 'job_lease_conflict'; end if;
  next_status := case
    when retryable and target.attempt_count < target.max_attempts then 'retry_scheduled'
    when error_code in ('configuration_invalid', 'incompatible_model') then 'unavailable'
    else 'failed'
  end;
  update public.food_insight_jobs set status = next_status,
    terminal_error_code = case when next_status = 'retry_scheduled' then null else error_code end,
    next_attempt_at = statement_timestamp() + make_interval(secs => least(300, 5 * (2 ^ target.attempt_count)::integer)),
    lease_token = null, lease_expires_at = null, updated_at = statement_timestamp()
  where id = target.id;
  return next_status;
end;
$$;

revoke execute on function public.list_public_food_question_configs(uuid[]) from public;
grant execute on function public.list_public_food_question_configs(uuid[]) to anon, authenticated;
revoke execute on function public.enqueue_food_insight(uuid,text) from public, anon;
grant execute on function public.enqueue_food_insight(uuid,text) to authenticated, service_role;
revoke execute on function public.reconcile_food_insight_jobs(text) from public, anon, authenticated;
grant execute on function public.reconcile_food_insight_jobs(text) to service_role;
revoke execute on function public.correct_food_insight_rating(uuid,integer,integer,text,text) from public, anon;
grant execute on function public.correct_food_insight_rating(uuid,integer,integer,text,text) to authenticated;
revoke execute on function public.claim_food_insight_job(integer,uuid) from public, anon, authenticated;
grant execute on function public.claim_food_insight_job(integer,uuid) to service_role;
revoke execute on function public.complete_food_insight_job(uuid,uuid,jsonb,text,text) from public, anon, authenticated;
grant execute on function public.complete_food_insight_job(uuid,uuid,jsonb,text,text) to service_role;
revoke execute on function public.fail_food_insight_job(uuid,uuid,text,boolean) from public, anon, authenticated;
grant execute on function public.fail_food_insight_job(uuid,uuid,text,boolean) to service_role;
