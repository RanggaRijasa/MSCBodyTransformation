-- Keep CMS read policies separate from Admin mutations so each SELECT checks
-- only one permissive policy. The readable policies created by the baseline
-- migration already include private.is_admin().

drop policy "admin manages programs" on public.programs;
create policy "admin inserts programs"
on public.programs for insert to authenticated
with check (private.is_admin());
create policy "admin updates programs"
on public.programs for update to authenticated
using (private.is_admin())
with check (private.is_admin());
create policy "admin deletes programs"
on public.programs for delete to authenticated
using (private.is_admin());

drop policy "admin manages days" on public.program_days;
create policy "admin inserts days"
on public.program_days for insert to authenticated
with check (private.is_admin());
create policy "admin updates days"
on public.program_days for update to authenticated
using (private.is_admin())
with check (private.is_admin());
create policy "admin deletes days"
on public.program_days for delete to authenticated
using (private.is_admin());

drop policy "admin manages steps" on public.program_steps;
create policy "admin inserts steps"
on public.program_steps for insert to authenticated
with check (private.is_admin());
create policy "admin updates steps"
on public.program_steps for update to authenticated
using (private.is_admin())
with check (private.is_admin());
create policy "admin deletes steps"
on public.program_steps for delete to authenticated
using (private.is_admin());

drop policy "admin manages questions" on public.program_questions;
create policy "admin inserts questions"
on public.program_questions for insert to authenticated
with check (private.is_admin());
create policy "admin updates questions"
on public.program_questions for update to authenticated
using (private.is_admin())
with check (private.is_admin());
create policy "admin deletes questions"
on public.program_questions for delete to authenticated
using (private.is_admin());

drop policy "admin manages options" on public.program_question_options;
create policy "admin inserts options"
on public.program_question_options for insert to authenticated
with check (private.is_admin());
create policy "admin updates options"
on public.program_question_options for update to authenticated
using (private.is_admin())
with check (private.is_admin());
create policy "admin deletes options"
on public.program_question_options for delete to authenticated
using (private.is_admin());

drop policy "admin manages keys" on public.program_answer_keys;
create policy "admin inserts keys"
on public.program_answer_keys for insert to authenticated
with check (private.is_admin());
create policy "admin updates keys"
on public.program_answer_keys for update to authenticated
using (private.is_admin())
with check (private.is_admin());
create policy "admin deletes keys"
on public.program_answer_keys for delete to authenticated
using (private.is_admin());

-- PostgreSQL does not automatically index foreign-key columns. Add covering
-- indexes for joins, RLS lookups, and referential actions reported by the
-- local database advisor.

create index audit_events_actor_idx
  on public.audit_events(actor_id);
create index commerce_transactions_participant_idx
  on public.commerce_transactions(participant_id);
create index commerce_transactions_program_idx
  on public.commerce_transactions(program_id);
create index program_entitlements_participant_idx
  on public.program_entitlements(participant_id);
create index program_entitlements_transaction_idx
  on public.program_entitlements(transaction_id);
create index program_winners_participant_idx
  on public.program_winners(participant_id);
create index programs_created_by_idx
  on public.programs(created_by);
create index programs_source_program_idx
  on public.programs(source_program_id);
create index quiz_attempt_results_reopened_by_idx
  on public.quiz_attempt_results(reopened_by);
create index score_adjustments_actor_idx
  on public.score_adjustments(actor_id);
create index score_adjustments_enrollment_idx
  on public.score_adjustments(enrollment_id);
create index submission_answers_question_idx
  on public.step_submission_answers(question_id);
create index step_submissions_reviewer_idx
  on public.step_submissions(reviewer_id);
create index step_submissions_step_idx
  on public.step_submissions(step_id);
create index step_submissions_supersedes_idx
  on public.step_submissions(supersedes_submission_id);
create index weigh_ins_corrected_by_idx
  on public.weigh_ins(corrected_by);
create index weigh_ins_step_idx
  on public.weigh_ins(step_id);
create index winner_posters_program_idx
  on public.winner_posters(program_id);
create index winner_posters_snapshot_idx
  on public.winner_posters(winner_snapshot_id);
create index winner_snapshots_locked_by_idx
  on public.winner_snapshots(locked_by);
