-- Allow the W08 cleanup claim to preserve the already-reviewed shape while an
-- approved or rejected evidence file is being removed from private Storage.

alter table public.payment_evidence_attempts
  drop constraint if exists payment_evidence_review_shape;

alter table public.payment_evidence_attempts
  add constraint payment_evidence_review_shape check (
    (
      status = 'rejected'
      and reviewed_at is not null
      and reviewed_by is not null
      and length(trim(rejection_reason)) > 0
    )
    or (
      status = 'approved'
      and reviewed_at is not null
      and reviewed_by is not null
      and rejection_reason is null
    )
    or (
      status = 'deleting'
      and reviewed_at is not null
      and reviewed_by is not null
      and (
        (
          retention_previous_status = 'approved'
          and rejection_reason is null
        )
        or (
          retention_previous_status = 'rejected'
          and length(trim(rejection_reason)) > 0
        )
      )
    )
    or status in ('prepared', 'submitted', 'deleted')
  );
