-- Phase 11.4-11.5: harden enrollment, private media, quiz, weigh-in, and
-- score operations. Every mutation is server-authoritative and idempotent.

alter table public.weigh_ins
  add column idempotency_key text,
  add column correction_idempotency_key text;

update public.weigh_ins
set idempotency_key = 'legacy-' || id::text
where idempotency_key is null;

alter table public.weigh_ins
  add constraint weigh_ins_idempotency_key_shape check (
    idempotency_key is null
    or length(idempotency_key) between 8 and 128
  ),
  add constraint weigh_ins_correction_idempotency_key_shape check (
    correction_idempotency_key is null
    or length(correction_idempotency_key) between 8 and 128
  );

create unique index weigh_ins_idempotency_idx
  on public.weigh_ins(enrollment_id, step_id, idempotency_key);

alter table public.quiz_attempt_results
  add column reopen_idempotency_key text,
  add constraint quiz_reopen_idempotency_key_shape check (
    reopen_idempotency_key is null
    or length(reopen_idempotency_key) between 8 and 128
  );

alter table public.score_adjustments
  add column idempotency_key text,
  add constraint score_adjustment_idempotency_key_shape check (
    idempotency_key is null
    or length(idempotency_key) between 8 and 128
  );

create unique index score_adjustments_idempotency_idx
  on public.score_adjustments(actor_id, enrollment_id, idempotency_key)
  where idempotency_key is not null;

create or replace function private.can_coach_participant(
  target_participant uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.has_active_coach_access((select auth.uid()))
    and exists (
      select 1
      from public.profiles participant
      where participant.user_id = target_participant
        and participant.role = 'participant'
        and participant.current_coach_id = (select auth.uid())
    );
$$;

create or replace function public.resolve_coach_qr_for_enrollment(
  scanned_coach_qr text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  participant public.profiles;
  coach public.profiles;
begin
  if length(trim(coalesce(scanned_coach_qr, ''))) = 0 then
    raise exception 'coach_qr_invalid';
  end if;

  select * into participant from public.profiles
  where user_id = (select auth.uid()) and role = 'participant';
  if participant.user_id is null then raise exception 'permission_denied'; end if;

  select * into coach from public.profiles
  where coach_qr_identifier = trim(scanned_coach_qr)
    and role = 'coach'
    and coach_is_approved
    and private.has_active_coach_access(user_id);
  if coach.user_id is null then raise exception 'coach_qr_invalid'; end if;
  if participant.current_coach_id is not null
    and participant.current_coach_id <> coach.user_id
  then raise exception 'coach_mismatch'; end if;

  return jsonb_build_object(
    'id', coach.user_id,
    'display_name', coach.display_name,
    'city', coach.city,
    'photo_reference', coach.provider_avatar_url,
    'is_public', coach.coach_is_public,
    'is_approved', coach.coach_is_approved
  );
end;
$$;

create or replace function private.validate_question_photo_answer()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  object storage.objects;
begin
  if new.private_photo_path is null then return new; end if;

  if not private.can_write_question_photo(new.private_photo_path) then
    raise exception 'private_photo_invalid';
  end if;

  select * into object
  from storage.objects stored_object
  where stored_object.bucket_id = 'question-photos'
    and stored_object.name = new.private_photo_path;

  if object.id is null then raise exception 'private_photo_missing'; end if;
  if coalesce(object.metadata ->> 'mimetype', '') <> 'image/jpeg' then
    raise exception 'private_photo_mime_invalid';
  end if;
  if object.metadata ? 'size' and (
    (object.metadata ->> 'size')::bigint <= 0
    or (object.metadata ->> 'size')::bigint > 8388608
  ) then
    raise exception 'private_photo_size_invalid';
  end if;

  return new;
end;
$$;

create trigger validate_question_photo_answer_before_write
before insert or update of private_photo_path
on public.step_submission_answers
for each row execute function private.validate_question_photo_answer();

create or replace function public.enroll_free_program(
  target_program_id uuid,
  scanned_coach_qr text
)
returns public.program_enrollments
language plpgsql
security definer
set search_path = ''
as $$
declare
  participant public.profiles;
  coach public.profiles;
  target_program public.programs;
  existing public.program_enrollments;
  result public.program_enrollments;
begin
  if length(trim(coalesce(scanned_coach_qr, ''))) < 16 then
    raise exception 'coach_qr_invalid';
  end if;

  select * into participant
  from public.profiles
  where user_id = (select auth.uid())
    and role = 'participant'
  for update;
  if participant.user_id is null then raise exception 'permission_denied'; end if;

  select * into existing
  from public.program_enrollments
  where program_id = target_program_id
    and participant_id = participant.user_id
  for update;
  if existing.id is not null then return existing; end if;

  select * into coach
  from public.profiles
  where coach_qr_identifier = scanned_coach_qr
    and role = 'coach'
    and coach_is_approved
  for share;
  if coach.user_id is null
    or not private.has_active_coach_access(coach.user_id)
  then
    raise exception 'coach_qr_invalid';
  end if;
  if participant.current_coach_id is not null
    and participant.current_coach_id <> coach.user_id
  then
    raise exception 'coach_mismatch';
  end if;

  select * into target_program
  from public.programs
  where id = target_program_id
  for update;
  if target_program.id is null
    or target_program.status not in ('scheduled', 'active')
    or target_program.pricing_mode <> 'free'
  then
    raise exception 'program_unavailable';
  end if;
  if target_program.registration_closes_at is not null
    and statement_timestamp() >= target_program.registration_closes_at
  then
    raise exception 'registration_closed';
  end if;
  if target_program.participant_limit is not null and (
    select count(*)
    from public.program_enrollments enrollment
    where enrollment.program_id = target_program_id
      and enrollment.status in ('active', 'completed')
  ) >= target_program.participant_limit then
    raise exception 'program_full';
  end if;

  update public.profiles
  set current_coach_id = coach.user_id,
      updated_at = statement_timestamp()
  where user_id = participant.user_id
    and current_coach_id is null;

  insert into public.program_enrollments (
    program_id, participant_id, coach_id, status
  ) values (
    target_program_id, participant.user_id, coach.user_id, 'active'
  )
  on conflict (program_id, participant_id) do update
    set program_id = excluded.program_id
  returning * into result;

  insert into public.program_scores(enrollment_id)
  values (result.id) on conflict do nothing;

  return result;
end;
$$;

create or replace function public.admin_enroll_participant(
  target_program_id uuid,
  target_participant_id uuid,
  reason text
)
returns public.program_enrollments
language plpgsql
security definer
set search_path = ''
as $$
declare
  participant public.profiles;
  coach public.profiles;
  target_program public.programs;
  existing public.program_enrollments;
  result public.program_enrollments;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reason, ''))) = 0 then raise exception 'reason_required'; end if;

  select * into target_program from public.programs
  where id = target_program_id for update;
  if target_program.id is null
    or target_program.status not in ('scheduled', 'active')
  then raise exception 'program_unavailable'; end if;

  select * into existing from public.program_enrollments
  where program_id = target_program_id
    and participant_id = target_participant_id
  for update;
  if existing.id is not null then return existing; end if;

  select * into participant from public.profiles
  where user_id = target_participant_id and role = 'participant'
  for update;
  if participant.user_id is null then raise exception 'participant_invalid'; end if;
  if participant.current_coach_id is null then raise exception 'coach_required'; end if;

  select * into coach from public.profiles
  where user_id = participant.current_coach_id
    and role = 'coach' and coach_is_approved
  for share;
  if coach.user_id is null
    or not private.has_active_coach_access(coach.user_id)
  then raise exception 'coach_invalid'; end if;

  if target_program.participant_limit is not null and (
    select count(*) from public.program_enrollments
    where program_id = target_program_id
      and status in ('active', 'completed')
  ) >= target_program.participant_limit then raise exception 'program_full'; end if;

  if target_program.pricing_mode = 'paid' and not exists (
    select 1 from public.program_entitlements
    where program_id = target_program_id
      and participant_id = target_participant_id
      and status = 'active'
  ) then raise exception 'payment_required'; end if;

  insert into public.program_enrollments (
    program_id, participant_id, coach_id, status
  ) values (
    target_program_id, participant.user_id, coach.user_id, 'active'
  ) returning * into result;

  insert into public.program_scores(enrollment_id)
  values (result.id) on conflict do nothing;

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()), 'participant_enrolled', participant.user_id,
    trim(reason), jsonb_build_object(
      'program_id', target_program.id,
      'coach_id', coach.user_id,
      'registration_deadline_bypassed',
        target_program.registration_closes_at is not null
        and statement_timestamp() >= target_program.registration_closes_at
    )
  );
  return result;
end;
$$;

create or replace function public.admin_transfer_coach(
  target_participant_id uuid,
  target_coach_id uuid,
  reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  old_coach uuid;
begin
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reason, ''))) = 0 then raise exception 'reason_required'; end if;
  if not private.has_active_coach_access(target_coach_id) then
    raise exception 'coach_invalid';
  end if;

  select current_coach_id into old_coach
  from public.profiles
  where user_id = target_participant_id and role = 'participant'
  for update;
  if not found then raise exception 'participant_invalid'; end if;

  if old_coach = target_coach_id then return; end if;

  update public.profiles
  set current_coach_id = target_coach_id,
      updated_at = statement_timestamp()
  where user_id = target_participant_id;

  update public.program_enrollments
  set coach_id = target_coach_id
  where participant_id = target_participant_id
    and status in ('initiated', 'waiting_for_payment', 'active');

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()), 'coach_transferred', target_participant_id,
    trim(reason), jsonb_build_object(
      'old_coach_id', old_coach,
      'new_coach_id', target_coach_id
    )
  );
end;
$$;

create or replace function public.submit_weigh_in(
  target_enrollment_id uuid,
  target_step_id uuid,
  weigh_in_kind text,
  weight_kg numeric,
  request_idempotency_key text
)
returns public.weigh_ins
language plpgsql
security definer
set search_path = ''
as $$
declare
  enrollment public.program_enrollments;
  step public.program_steps;
  existing public.weigh_ins;
  result public.weigh_ins;
  expected_content_kind text;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if weigh_in_kind not in ('initial', 'daily', 'final') then
    raise exception 'weigh_in_kind_invalid';
  end if;
  if weight_kg < 20 or weight_kg > 400 then
    raise exception 'weight_invalid';
  end if;

  select * into enrollment from public.program_enrollments
  where id = target_enrollment_id for update;
  if enrollment.id is null then raise exception 'enrollment_not_found'; end if;
  if enrollment.participant_id <> (select auth.uid()) then
    raise exception 'permission_denied';
  end if;
  if not private.step_accepts_submission(target_enrollment_id, target_step_id) then
    raise exception 'step_unavailable';
  end if;

  select * into step from public.program_steps
  where id = target_step_id;
  expected_content_kind := case weigh_in_kind
    when 'initial' then 'initial_weigh_in'
    when 'daily' then 'daily_weigh_in'
    else 'final_weigh_in'
  end;
  if step.id is null or step.content_kind <> expected_content_kind then
    raise exception 'weigh_in_step_mismatch';
  end if;

  select * into existing from public.weigh_ins
  where enrollment_id = target_enrollment_id
    and step_id = target_step_id
    and idempotency_key = request_idempotency_key;
  if existing.id is not null then return existing; end if;

  if weigh_in_kind = 'final' and not exists (
    select 1 from public.weigh_ins
    where enrollment_id = target_enrollment_id and kind = 'initial'
  ) then raise exception 'initial_weight_required'; end if;

  insert into public.weigh_ins (
    enrollment_id, step_id, kind, weight_kg, idempotency_key
  ) values (
    target_enrollment_id, target_step_id, weigh_in_kind, weight_kg,
    request_idempotency_key
  ) returning * into result;

  perform private.recalculate_enrollment_score(target_enrollment_id);
  return result;
exception
  when unique_violation then
    select * into result from public.weigh_ins
    where enrollment_id = target_enrollment_id
      and step_id = target_step_id;
    if result.id is not null and result.idempotency_key = request_idempotency_key then
      return result;
    end if;
    raise exception 'weigh_in_already_exists';
end;
$$;

create or replace function public.admin_correct_weigh_in(
  target_weigh_in_id uuid,
  corrected_weight_kg numeric,
  reason text,
  request_idempotency_key text
)
returns public.weigh_ins
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.weigh_ins;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reason, ''))) = 0 then raise exception 'reason_required'; end if;
  if corrected_weight_kg < 20 or corrected_weight_kg > 400 then
    raise exception 'weight_invalid';
  end if;

  select * into result from public.weigh_ins
  where id = target_weigh_in_id for update;
  if result.id is null then raise exception 'weigh_in_not_found'; end if;
  if result.correction_idempotency_key = request_idempotency_key then
    return result;
  end if;

  update public.weigh_ins
  set weight_kg = corrected_weight_kg,
      corrected_at = statement_timestamp(),
      corrected_by = (select auth.uid()),
      correction_reason = trim(reason),
      correction_idempotency_key = request_idempotency_key
  where id = target_weigh_in_id
  returning * into result;

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()), 'weigh_in_corrected', result.id, trim(reason),
    jsonb_build_object('enrollment_id', result.enrollment_id, 'kind', result.kind)
  );

  perform private.recalculate_enrollment_score(result.enrollment_id);
  return result;
end;
$$;

create or replace function public.reopen_quiz_attempt(
  target_enrollment_id uuid,
  target_step_id uuid,
  reason text,
  request_idempotency_key text
)
returns public.quiz_attempt_results
language plpgsql
security definer
set search_path = ''
as $$
declare
  submission public.step_submissions;
  result public.quiz_attempt_results;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reason, ''))) = 0 then raise exception 'reason_required'; end if;

  select submission_row.* into submission
  from public.step_submissions submission_row
  join public.program_steps step on step.id = submission_row.step_id
  where submission_row.enrollment_id = target_enrollment_id
    and submission_row.step_id = target_step_id
    and step.content_kind = 'quiz'
  order by submission_row.attempt_sequence desc
  limit 1
  for update of submission_row;
  if submission.id is null then raise exception 'quiz_attempt_not_found'; end if;

  select * into result from public.quiz_attempt_results
  where submission_id = submission.id for update;
  if result.id is null then raise exception 'quiz_result_not_found'; end if;
  if result.reopen_idempotency_key = request_idempotency_key then return result; end if;
  if result.reopened_at is not null then raise exception 'quiz_already_reopened'; end if;

  update public.quiz_attempt_results
  set reopened_at = statement_timestamp(),
      reopened_by = (select auth.uid()),
      reopen_reason = trim(reason),
      reopen_idempotency_key = request_idempotency_key
  where id = result.id
  returning * into result;

  update public.step_submissions
  set status = 'rejected',
      reviewed_at = statement_timestamp(),
      reviewer_id = (select auth.uid()),
      review_note = trim(reason)
  where id = submission.id;

  insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
  values (
    (select auth.uid()), 'quiz_attempt_reopened', result.id, trim(reason),
    jsonb_build_object(
      'enrollment_id', target_enrollment_id,
      'step_id', target_step_id,
      'previous_sequence', submission.attempt_sequence
    )
  );
  perform private.recalculate_enrollment_score(target_enrollment_id);
  return result;
end;
$$;

create or replace function public.admin_adjust_score(
  target_enrollment_id uuid,
  points integer,
  reason text,
  request_idempotency_key text
)
returns public.program_scores
language plpgsql
security definer
set search_path = ''
as $$
declare
  inserted_adjustment uuid;
  result public.program_scores;
begin
  perform private.assert_idempotency_key(request_idempotency_key);
  if not private.is_admin() then raise exception 'permission_denied'; end if;
  if length(trim(coalesce(reason, ''))) = 0 then raise exception 'reason_required'; end if;
  if points = 0 then raise exception 'adjustment_zero'; end if;

  insert into public.score_adjustments(
    enrollment_id, points, reason, actor_id, idempotency_key
  ) values (
    target_enrollment_id, points, trim(reason), (select auth.uid()),
    request_idempotency_key
  ) on conflict (actor_id, enrollment_id, idempotency_key)
    where idempotency_key is not null do nothing
  returning id into inserted_adjustment;

  if inserted_adjustment is not null then
    insert into public.audit_events(actor_id, kind, subject_id, summary, payload)
    values (
      (select auth.uid()), 'score_adjusted', target_enrollment_id,
      trim(reason), jsonb_build_object(
        'points', points,
        'idempotency_key', request_idempotency_key
      )
    );
  end if;

  result := private.recalculate_enrollment_score(target_enrollment_id);
  return result;
end;
$$;

-- Direct Data API writes are removed from server-owned scoring and media
-- references. Reads remain governed by RLS.
revoke insert, update, delete on table
  public.weigh_ins,
  public.score_adjustments,
  public.step_submissions,
  public.step_submission_answers,
  public.quiz_attempt_results
from authenticated;

revoke execute on function private.validate_question_photo_answer()
  from public, anon, authenticated, service_role;

revoke execute on function
  public.resolve_coach_qr_for_enrollment(text),
  public.submit_weigh_in(uuid, uuid, text, numeric, text),
  public.admin_correct_weigh_in(uuid, numeric, text, text),
  public.reopen_quiz_attempt(uuid, uuid, text, text),
  public.admin_adjust_score(uuid, integer, text, text)
from public, anon, authenticated, service_role;

grant execute on function
  public.resolve_coach_qr_for_enrollment(text),
  public.submit_weigh_in(uuid, uuid, text, numeric, text),
  public.admin_correct_weigh_in(uuid, numeric, text, text),
  public.reopen_quiz_attempt(uuid, uuid, text, text),
  public.admin_adjust_score(uuid, integer, text, text)
to authenticated;
