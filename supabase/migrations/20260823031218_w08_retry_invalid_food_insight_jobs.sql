-- Re-open provider-output failures that were incorrectly treated as terminal.
-- The updated Edge Function requires supported request parameters and retries
-- malformed output through the existing bounded max-attempt policy.
update public.food_insight_jobs job
set status = 'retry_scheduled',
    terminal_error_code = null,
    next_attempt_at = statement_timestamp(),
    lease_token = null,
    lease_expires_at = null,
    updated_at = statement_timestamp()
where job.status = 'failed'
  and job.terminal_error_code = 'invalid_output'
  and job.attempt_count < job.max_attempts
  and not exists (
    select 1
    from public.food_insight_results result
    where result.job_id = job.id
  );
