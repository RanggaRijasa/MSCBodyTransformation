-- The public leaderboard is served by the narrow Phase 11 projection.
-- Direct score rows contain private component details and therefore remain
-- visible only to the owner, their assigned Coach, or an Admin.

drop policy if exists "program leaderboard readable"
  on public.program_scores;

create policy "own assigned coach or admin score read"
on public.program_scores
for select
to authenticated
using (
  exists (
    select 1
    from public.program_enrollments enrollment
    where enrollment.id = program_scores.enrollment_id
      and (
        enrollment.participant_id = (select auth.uid())
        or private.can_coach_participant(enrollment.participant_id)
        or private.is_admin()
      )
  )
);
