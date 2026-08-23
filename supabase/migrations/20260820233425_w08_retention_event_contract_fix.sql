-- Reuse the existing audited payment event vocabulary for retention deletion.

create or replace function public.complete_payment_evidence_retention(
  target_attempt_id uuid
)
returns boolean
language plpgsql security definer
set search_path = ''
as $$
declare target_order_id uuid;
begin
  if coalesce((select auth.jwt() ->> 'role'), '') <> 'service_role' then
    raise exception 'permission_denied';
  end if;
  update public.payment_evidence_attempts
  set status = 'deleted',
    deleted_at = statement_timestamp(),
    retention_cleanup_claimed_at = null
  where id = target_attempt_id
    and status = 'deleting'
  returning order_id into target_order_id;
  if target_order_id is null then return false; end if;
  insert into public.payment_events(order_id, attempt_id, event_type, metadata)
  values (
    target_order_id, target_attempt_id, 'evidence_deleted',
    jsonb_build_object('policy', 'submitted_plus_30_days')
  );
  return true;
end;
$$;

revoke all on function public.complete_payment_evidence_retention(uuid)
  from public, anon, authenticated;
grant execute on function public.complete_payment_evidence_retention(uuid)
  to service_role;
