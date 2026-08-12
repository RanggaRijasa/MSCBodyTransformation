# MSCWEB W04 — Evidence, review, and authoritative scoring

Status: `Not started`  
Autonomy: `A` against local Supabase; device picker/camera check is `B`  
Depends on: W03 activity renderers and Participant state models

## Objective

Implement private program evidence upload, typed answer submission, Coach-scoped review foundations, and server-authoritative score effects without leaking sensitive media or weights.

## Required references

- `00_PRODUCT_SPEC.md` program/scoring/media requirements
- `05_DATA_SECURITY.md`
- `07_TESTING_ACCEPTANCE.md`
- repository media/privacy/scoring contracts
- current iOS Participant submission and Coach proof-review runtime

## Deliverables

- browser media adapter and normalization pipeline;
- private `program-evidence` Storage path/policies;
- Participant submission operations/status/history;
- Coach-scoped review queue/detail operation foundation;
- approve/reject/idempotency/audit;
- authoritative score ledger/update behavior;
- private signed-media viewer and cache cleanup.

## Mandatory simulator gate

- [ ] Inspect Participant evidence picker/submission/pending/rejected/approved states.
- [ ] Inspect Coach queue filters, row context, detail media, sticky `Tolak`/`Setujui`, and reject-reason behavior.
- [ ] Inspect error/offline/permission-denied paths where scenarios exist.
- [ ] Record current behavior before each UI slice.

## Checklist

### Media pipeline

- [ ] Use actual picker/camera path; no demo upload button.
- [ ] Decode, normalize orientation, resize off main UI path, strip unnecessary metadata, output JPEG.
- [ ] Validate signature/MIME/dimensions/8 MiB at client and server/storage boundary.
- [ ] Unique non-overwrite path and orphan cleanup strategy.
- [ ] Revoke object URLs and purge private cached media on logout.

### Security and authority

- [ ] Owner-only create/read status policies; Coach access only through assigned scope; authorized Admin access.
- [ ] Short-lived signed/authenticated media access without logging URL/path.
- [ ] Submission transition checks required answers/evidence and prevents duplicates.
- [ ] Review operation locks state, is idempotent, and requires reason on rejection.
- [ ] Approved evidence creates authoritative step points once; pending/rejected receives none.
- [ ] Weight calculation uses Decimal/numeric server semantics and never negative loss points.

### UI

- [ ] Participant upload, preview, progress, retry, validation, confirmation, pending/rejected/approved states.
- [ ] Coach queue `Perlu tindakan`/`Semua bukti`, filters, context, detail, zoom, and decision actions.
- [ ] Accessible file input, progress announcements, focus return, and no color-only status.
- [ ] Concurrent/already-reviewed conflict refetches and explains state.

## Sub-agent plan

- `msc_explorer`: inspect existing media/scoring migrations and current iOS submission/review states.
- `msc_implementer`: sole writer for one path at a time: media adapter → local policies/RPC → UI.
- `msc_reviewer`: private-media RLS, signed URL/logging, concurrency/idempotency, score duplication, and accessibility.

Primary agent owns migration order, authority operation signatures, and shared media adapter.

## Verification

- image pipeline fixtures including corrupt/rotated/metadata/oversize;
- RLS negative tests across owners and Coaches;
- concurrent/double submit/review tests;
- scoring edge cases: duplicate, rejected, weight gain, rounding;
- Playwright Participant submit and Coach review journeys;
- real Safari/Chrome picker/camera smoke when device access is available;
- simulator parity and private-data/log scan.

## Exit criteria

- Participant evidence can be submitted and reviewed locally end-to-end.
- Cross-user/cross-Coach media access is denied.
- Approval/rejection and points are idempotent, audited, server-authoritative.
- Sensitive values do not appear in logs/cache/public responses.

## User input or authorization

- Browser/OS camera or picker permission during device smoke tests.
- No production Storage/policy/function deployment is authorized.

## Progress log

Append migration/function IDs, media fixtures, simulator evidence, security/concurrency tests, commands/results, and next item.

