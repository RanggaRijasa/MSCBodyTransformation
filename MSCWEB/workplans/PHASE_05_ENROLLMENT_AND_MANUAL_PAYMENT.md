# MSCWEB W05 — Enrollment and manual payment

Status: `Not started`  
Autonomy: `A` locally; `C` business payment policy; `D` real payment/production data  
Depends on: W02 Auth, W03 Program, and stable W04 authority patterns

## Objective

Implement Coach QR enrollment, free-program enrollment, and manual bank/QRIS payment with private proof, Admin review, and atomic entitlement/enrollment.

## Required references

- `04_MANUAL_PAYMENT.md`
- `05_DATA_SECURITY.md`
- `07_TESTING_ACCEPTANCE.md` payment journeys/matrix
- ADR-0003
- current iOS join/QR/program offer and Admin decision interaction patterns

## Deliverables

- browser QR scanner adapter and permission/unavailable states;
- Coach/program validation and free enrollment authority operation;
- manual payment destination/request/proof/review schema adapted to existing commerce contracts;
- Participant payment screen and status/resubmission history;
- Admin payment queue/detail/reject/approve;
- atomic approved transaction + entitlement + enrollment + audit;
- full local RLS/concurrency/E2E suite.

## Mandatory simulator gate

- [ ] Inspect current iOS program offer, `Gabung program`, selected program/price, and `Pindai QR coach` flow.
- [ ] Inspect current Admin proof/decision interaction patterns, sticky actions, dialogs, and conflict copy.
- [ ] Treat manual payment UI as web replacement while preserving navigation/state hierarchy.

## Checklist

### QR and enrollment

- [ ] Camera permission, unsupported, denied, invalid, mismatch, duplicate, capacity, inactive, and close states.
- [ ] No manual/copyable Coach code or raw payload in URL/log/cache.
- [ ] Preserve safe opaque intent through login.
- [ ] Free program creates enrollment exactly once without payment request.

### Payment data/security

- [ ] Destination configuration and immutable request snapshot.
- [ ] State machine and compare-and-set version transitions.
- [ ] Unique proof attempts; private bucket; normalized JPEG ≤ 8 MiB.
- [ ] Define the orphan-proof cleanup process: eligible object states, database reference check, minimum retention, authorized actor/job, audit, retry, and dry-run mode.
- [ ] Verify cleanup locally with referenced, unreferenced, pending-upload, rejected-history, and concurrent-submit cases; never delete a referenced attempt.
- [ ] Owner/Admin policies and short-lived authorized viewing.
- [ ] Append-only review/audit and idempotency keys.
- [ ] Explicit grants/RLS and typed authority functions.

### Participant UI

- [ ] Subject, amount, order ID, account holder/number, QRIS, instructions, copy feedback.
- [ ] Upload/preview/confirm/progress/failure and manual-review explanation.
- [ ] Awaiting, pending, rejected with reason/resubmit, approved, expired, cancelled.
- [ ] No invented approval SLA or automatic-verification claim.

### Admin UI/authority

- [ ] `Perlu tindakan` queue, filters, oldest-first, identity/context/attempt history.
- [ ] Full private proof viewer and concurrent-review handling.
- [ ] Reject requires reason.
- [ ] Approve confirmation shows subject/amount.
- [ ] One transaction atomically creates approved commerce state, entitlement, enrollment, and audit; no partial approval.

## Sub-agent plan

- `msc_explorer`: map existing commerce/enrollment migrations and iOS join/Admin decision flows.
- `msc_implementer`: sole writer; sequential schema/RPC first, then Participant UI, then Admin UI.
- `msc_reviewer`: threat/RLS/concurrency/payment-state audit and `QA-JRN-001…004` review.

Do not parallelize schema and RPC authority design or let a sub-agent configure real payment data.

## Verification

- all cases in the payment acceptance matrix;
- `QA-JRN-001` through `QA-JRN-004`;
- RLS cross-owner/Admin negative/positive tests;
- concurrent Admin approval and duplicate enrollment tests;
- browser QR/camera device test where available;
- simulator parity for offer/scan/decision patterns;
- no proof/signed URL/account detail in logs/analytics.

## Exit criteria

- Free and paid local enrollment work end-to-end.
- Paid Participant remains unenrolled until Admin approval.
- Approval is atomic/idempotent/audited and private evidence is isolated.
- Orphan proof cleanup is designed and locally verified; production schedule/retention activation remains a policy/authorization gate.
- Production policy gaps are clearly listed and no real bank/QRIS data is stored.

## User input or authorization

- For production readiness: bank/account holder/number, approved QRIS, expiry, SLA, resubmission, reconciliation, dispute/refund, proof retention, and cleanup schedule/actor decisions.
- Real payment data and any hosted deployment require explicit authorization.
- Local work may use clearly fake fixtures and a non-payable QR test image.

## Progress log

Append simulator flow, schema/functions, state transitions, payment tests, policy blockers, files/commands, and next item.
