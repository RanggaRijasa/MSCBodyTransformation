alter table public.programs
  add column if not exists default_verification_mode text not null
    default 'coach_review'
    check (default_verification_mode in ('automatic', 'coach_review'));

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
language plpgsql security definer
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
    analysis_rubric_version = source_question.analysis_rubric_version
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
