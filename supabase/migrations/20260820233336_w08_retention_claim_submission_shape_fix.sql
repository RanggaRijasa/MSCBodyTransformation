-- Keep the submitted evidence shape valid during an atomic retention claim.

alter table public.payment_evidence_attempts
  drop constraint if exists payment_evidence_submission_shape;

alter table public.payment_evidence_attempts
  add constraint payment_evidence_submission_shape check (
    (status = 'prepared' and submitted_at is null)
    or (
      status in ('submitted', 'rejected', 'approved', 'deleting')
      and submitted_at is not null
    )
    or status = 'deleted'
  );
