-- Phase 12 manual payment is live on web. Replace the Phase 11 handoff guard
-- with publication checks that keep a paid program unavailable until both its
-- price and the server-controlled payment destination are ready.
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
  payment_destination public.payment_destinations;
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
  if target.pricing_mode = 'paid' then
    if target.desired_price is null or target.desired_price <= 0 then
      raise exception 'program_paid_not_ready';
    end if;
    select * into payment_destination from private.current_payment_destination();
    if payment_destination.id is null then
      raise exception 'program_paid_not_ready';
    end if;
  end if;
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

revoke all on function public.publish_program(uuid, text)
from public, anon, authenticated, service_role;
grant execute on function public.publish_program(uuid, text) to authenticated;
