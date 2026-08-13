begin;
set local request.jwt.claims = '{"role":"service_role"}';

create temporary table w05_cleanup_ids (
  destination_id uuid,
  order_prepared_id uuid,
  order_concurrent_id uuid,
  prepared_attempt_id uuid,
  rejected_attempt_id uuid,
  concurrent_attempt_id uuid,
  admin_id uuid
) on commit drop;

do $$
declare
  fixture w05_cleanup_ids;
begin
  select user_id into fixture.admin_id from public.profiles where role = 'admin' limit 1;
  if fixture.admin_id is null then raise exception 'w05_cleanup_admin_fixture_missing'; end if;
  fixture.destination_id := gen_random_uuid();
  fixture.order_prepared_id := gen_random_uuid();
  fixture.order_concurrent_id := gen_random_uuid();
  fixture.prepared_attempt_id := gen_random_uuid();
  fixture.rejected_attempt_id := gen_random_uuid();
  fixture.concurrent_attempt_id := gen_random_uuid();

  insert into public.payment_destinations(
    id, version, bank_code, bank_name, account_name, account_reference,
    effective_from, status, created_by, instructions
  ) values (
    fixture.destination_id, 999999, 'TST', 'Bank Uji', 'FIXTURE CLEANUP', '0000',
    statement_timestamp() - interval '10 days', 'retired', fixture.admin_id,
    'Fixture transaksional yang selalu di-rollback.'
  );

  insert into public.payment_orders(
    id, purpose, amount_minor, destination_id, destination_version,
    bank_code_snapshot, bank_name_snapshot, account_name_snapshot,
    account_reference_snapshot, timezone_snapshot, status, idempotency_key
  ) values
    (fixture.order_prepared_id, 'coach_access', 1, fixture.destination_id, 999999,
     'TST', 'Bank Uji', 'FIXTURE CLEANUP', '0000', 'Asia/Jakarta',
     'awaiting_evidence', 'w05-cleanup-prepared'),
    (fixture.order_concurrent_id, 'coach_access', 1, fixture.destination_id, 999999,
     'TST', 'Bank Uji', 'FIXTURE CLEANUP', '0000', 'Asia/Jakarta',
     'awaiting_evidence', 'w05-cleanup-concurrent');

  insert into storage.objects(bucket_id, name, created_at, metadata) values
    ('payment-evidence', 'orders/00000000-0000-4000-8000-000000000001/attempts/00000000-0000-4000-8000-000000000001/normalized.jpg', statement_timestamp() - interval '8 days', '{"mimetype":"image/jpeg","size":100}'),
    ('payment-evidence', 'orders/' || fixture.order_prepared_id || '/attempts/' || fixture.prepared_attempt_id || '/normalized.jpg', statement_timestamp() - interval '8 days', '{"mimetype":"image/jpeg","size":100}'),
    ('payment-evidence', 'orders/' || fixture.order_prepared_id || '/attempts/' || fixture.rejected_attempt_id || '/normalized.jpg', statement_timestamp() - interval '8 days', '{"mimetype":"image/jpeg","size":100}'),
    ('payment-evidence', 'orders/' || fixture.order_concurrent_id || '/attempts/' || fixture.concurrent_attempt_id || '/normalized.jpg', statement_timestamp() - interval '8 days', '{"mimetype":"image/jpeg","size":100}');

  insert into public.payment_evidence_attempts(
    id, order_id, attempt_number, upload_idempotency_key, object_path, status
  ) values (
    fixture.prepared_attempt_id, fixture.order_prepared_id, 1,
    'w05-cleanup-pending-upload',
    'orders/' || fixture.order_prepared_id || '/attempts/' || fixture.prepared_attempt_id || '/normalized.jpg',
    'prepared'
  );
  insert into public.payment_evidence_attempts(
    id, order_id, attempt_number, upload_idempotency_key, object_path, mime_type,
    byte_size, pixel_width, pixel_height, sha256_hex, status, submitted_at,
    reviewed_at, reviewed_by, rejection_reason
  ) values (
    fixture.rejected_attempt_id, fixture.order_prepared_id, 2,
    'w05-cleanup-rejected-history',
    'orders/' || fixture.order_prepared_id || '/attempts/' || fixture.rejected_attempt_id || '/normalized.jpg',
    'image/jpeg', 100, 1, 1, repeat('a', 64), 'rejected',
    statement_timestamp() - interval '7 days', statement_timestamp() - interval '7 days',
    fixture.admin_id, 'Bukti fixture ditolak.'
  );
  insert into w05_cleanup_ids values (fixture.*);
end;
$$;

do $$
declare
  candidates text[];
begin
  select array_agg(object_name order by object_name) into candidates
  from public.list_payment_evidence_orphans(interval '72 hours', 100, true);
  if coalesce(array_length(candidates, 1), 0) <> 2 then
    raise exception 'w05_cleanup_expected_two_unreferenced_candidates_before_concurrent_submit';
  end if;
  if exists (
    select 1 from public.list_payment_evidence_orphans(interval '72 hours', 100, true)
    where object_name like '%/' || (select prepared_attempt_id from w05_cleanup_ids) || '/%'
       or object_name like '%/' || (select rejected_attempt_id from w05_cleanup_ids) || '/%'
  ) then raise exception 'w05_cleanup_referenced_history_must_not_be_candidate'; end if;
end;
$$;

insert into public.payment_evidence_attempts(
  id, order_id, attempt_number, upload_idempotency_key, object_path, status
)
select concurrent_attempt_id, order_concurrent_id, 1,
  'w05-cleanup-concurrent-submit',
  'orders/' || order_concurrent_id || '/attempts/' || concurrent_attempt_id || '/normalized.jpg',
  'prepared'
from w05_cleanup_ids;

do $$
declare
  candidate_count integer;
begin
  select count(*) into candidate_count
  from public.list_payment_evidence_orphans(interval '72 hours', 100, false);
  if candidate_count <> 1 then
    raise exception 'w05_cleanup_concurrent_submit_reference_must_remove_candidate';
  end if;
  if exists (
    select 1 from public.list_payment_evidence_orphans(interval '72 hours', 100, false)
    where object_name like '%/' || (select concurrent_attempt_id from w05_cleanup_ids) || '/%'
  ) then raise exception 'w05_cleanup_concurrent_submit_would_be_deleted'; end if;
  begin
    perform * from public.list_payment_evidence_orphans(interval '23 hours', 100, true);
    raise exception 'w05_cleanup_minimum_age_guard_missing';
  exception when others then
    if sqlerrm = 'w05_cleanup_minimum_age_guard_missing' then raise; end if;
  end;
end;
$$;

rollback;
