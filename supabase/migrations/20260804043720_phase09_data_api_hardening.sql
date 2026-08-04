-- Keep Data API exposure explicit and separate from row-level security.
-- The project setting disables automatic exposure for new public objects, but
-- these statements make the same least-privilege boundary reproducible in
-- local, preview, staging, and production environments.

alter default privileges for role postgres in schema public
  revoke select, insert, update, delete, truncate, references, trigger
  on tables from anon, authenticated;

alter default privileges for role postgres in schema public
  revoke usage, select, update on sequences from anon, authenticated;

alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated, service_role;

alter default privileges for role postgres in schema private
  revoke execute on functions from public, anon, authenticated, service_role;

-- Remove any platform or historical grants before adding the application
-- access matrix below. RLS still decides which rows each authenticated caller
-- may access after these object-level grants succeed.
revoke all privileges on all tables in schema public
  from anon, authenticated;
revoke all privileges on all sequences in schema public
  from anon, authenticated;
revoke execute on all functions in schema public
  from public, anon, authenticated;
revoke execute on all functions in schema private
  from public, anon, authenticated, service_role;

grant usage on schema public to authenticated, service_role;
revoke usage on schema private
  from public, anon, authenticated, service_role;

-- There is no anonymous Data API surface in Phase 09. Authentication itself
-- continues to use Supabase Auth and does not require grants on these tables.

-- Authenticated read surface. Every table listed here already has a matching
-- SELECT policy in the baseline migration.
grant select on table
  public.profiles,
  public.program_enrollments,
  public.step_submissions,
  public.step_submission_answers,
  public.quiz_attempt_results,
  public.weigh_ins,
  public.program_scores,
  public.commerce_transactions,
  public.program_entitlements,
  public.winner_snapshots,
  public.program_winners,
  public.winner_posters,
  public.audit_events
to authenticated;

-- Program CMS tables have both authenticated read policies and Admin-only
-- mutation policies. Grants make the operations reachable; RLS keeps writes
-- restricted to the protected Admin role.
grant select, insert, update, delete on table
  public.programs,
  public.program_days,
  public.program_steps,
  public.program_questions,
  public.program_question_options,
  public.program_answer_keys
to authenticated;

-- Server-owned tables deliberately remain unavailable to direct
-- authenticated Data API access until their atomic operations are added.
revoke all privileges on table
  public.program_store_products,
  public.score_adjustments
from anon, authenticated;

-- PostgreSQL evaluates policy helper permissions as the requesting role, so
-- authenticated needs EXECUTE for these two helpers. The private schema is
-- not exposed through the Data API and authenticated has no USAGE on it,
-- which prevents callers from resolving and invoking the helpers directly.
-- No blanket function grant is used.
grant execute on function private.is_admin()
  to authenticated;
grant execute on function private.can_coach_participant(uuid)
  to authenticated;

-- Public SECURITY DEFINER functions are explicit RPC endpoints. Regrant only
-- the two reviewed Phase 09 operations after the blanket function revoke.
grant execute on function public.enroll_free_program(uuid, text)
  to authenticated;
grant execute on function public.admin_transfer_coach(uuid, uuid, text)
  to authenticated;

-- Automatic RLS may create this event-trigger helper on hosted projects. It
-- does not need to be callable through the Data API. The guard keeps fresh
-- local resets valid when the hosted-only helper is absent.
do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    execute
      'revoke execute on function public.rls_auto_enable()
       from public, anon, authenticated';
  end if;
end
$$;

-- Trusted server code may operate on the complete application schema. The
-- service_role credential must remain server-side and must never be bundled
-- into either mobile client.
grant all privileges on all tables in schema public to service_role;
grant all privileges on all sequences in schema public to service_role;
