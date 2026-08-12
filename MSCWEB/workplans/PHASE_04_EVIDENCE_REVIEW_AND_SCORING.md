# MSCWEB W04 — Evidence, review, and authoritative scoring

Status: `Completed`
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

- [x] Inspect Participant evidence picker/submission/pending/rejected/approved states.
- [x] Inspect Coach queue filters, row context, detail media, sticky `Tolak`/`Setujui`, and reject-reason behavior.
- [x] Inspect error/offline/permission-denied paths where scenarios exist.
- [x] Record current behavior before each UI slice.

## Checklist

### Media pipeline

- [x] Use actual picker/camera path; no demo upload button.
- [x] Decode, normalize orientation, resize off main UI path, strip unnecessary metadata, output JPEG.
- [x] Validate signature/MIME/dimensions/8 MiB at client and server/storage boundary.
- [x] Unique non-overwrite path and orphan cleanup strategy.
- [x] Revoke object URLs and purge private cached media on logout.

### Security and authority

- [x] Owner-only create/read status policies; Coach access only through assigned scope; authorized Admin access.
- [x] Short-lived signed/authenticated media access without logging URL/path.
- [x] Submission transition checks required answers/evidence and prevents duplicates.
- [x] Review operation locks state, is idempotent, and requires reason on rejection.
- [x] Approved evidence creates authoritative step points once; pending/rejected receives none.
- [x] Weight calculation uses Decimal/numeric server semantics and never negative loss points.

### UI

- [x] Participant upload, preview, progress, retry, validation, confirmation, pending/rejected/approved states.
- [x] Coach queue `Perlu tindakan`/`Semua bukti`, filters, context, detail, zoom, and decision actions.
- [x] Accessible file input, progress announcements, focus return, and no color-only status.
- [x] Concurrent/already-reviewed conflict refetches and explains state.

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

### 2026-08-12 — W04 completed

- Requirement IDs: `PROD-001`, `PROD-004`, `PROD-006`, `PROD-007`,
  `PROD-PTC-005`, `PROD-CCH-004`, `PROD-CCH-005`, `PROD-PRG-003`,
  `PROD-PRG-005`, `PROD-LDB-001`, `PROD-LDB-002`, `PROD-OPS-002`,
  `SEC-001`–`SEC-005`, `SEC-AUTHZ-001`, `SEC-AUTHZ-003`,
  `SEC-STO-001`–`SEC-STO-005`, `SEC-OP-001`–`SEC-OP-004`,
  `SEC-PRV-001`–`SEC-PRV-003`, `QA-001`–`QA-003`, `QA-JRN-006`, dan
  `QA-JRN-007`.
- Files changed: browser image/private-media adapters; Participant mutation
  repository/query/form and activity renderer; Coach review models,
  repository/query, queue/detail routes and dashboard entry; production/Worker
  route allowlist; focused unit, integration-facing, and Playwright tests.
- Backend contract reused without migration changes: existing private bucket
  `question-photos`; `prepare_step_submission(uuid,uuid,text)`,
  `submit_step_answers(uuid,jsonb,text)`,
  `review_step_submission(uuid,text,text,text)`, dan
  `submit_weigh_in(uuid,uuid,text,numeric,text)`. Path remains
  `participant/enrollment/submission/question/random.jpg`; scheduled orphan
  cleanup remains `cleanup-orphan-question-photos`.
- Assumptions: `program-evidence` in this workplan names the product media
  category; the authoritative shared backend contract deliberately calls the
  bucket `question-photos`. Web does not duplicate scoring, review, Storage
  policy, audit, or numeric weight rules.
- Media fixtures: existing rotated/metadata browser probe, corrupt and
  oversized unit fixtures, real PNG visual fixture normalized to JPEG during
  the W04 end-to-end upload.
- Native evidence: iPhone 17 Pro/iOS Simulator build-run passed for
  `participant_active` and `coach_review_queue`; focused UI tests
  `testCoachCompletesCriticalLocalJourney`,
  `testCoachRejectionUsesSingleSheetNavigationFlow`, dan
  `testOfflineAndPermissionScenariosAreExplicit` passed 3/3. Native runtime
  established the segmented queue, scoped context, media viewer, sticky
  actions, mandatory rejection reason, pending/rejected copy, and explicit
  offline/permission states before the web slices were closed.
- Build commands: `npm run typecheck`, `npm run lint`, and `npm run build` —
  passed. `npm run verify:bundle` — 30 JavaScript files valid;
  `npm run verify:pwa` — passed.
- Test commands: `npm test` — 74 passed, 3 environment-gated skipped;
  `npx playwright test` with local Supabase variables — 58 passed across
  desktop Chrome and Pixel 7 emulation; final focused Worker-pipeline rerun —
  4/4 passed. `private_media_storage.mjs` — 16 assertions passed;
  `submission_review_races.mjs` — 15 assertions passed.
- Security result: cross-user/cross-Coach Storage access, non-overwrite upload,
  signed media access, orphan selection, duplicate submit/review, audit count,
  pending/rejected zero points, one-time approval points, numeric weight gain,
  and redacted browser output are covered by the focused integration suites.
  No local secret values were found in `dist`; W04 source adds no console
  logging of URL, path, answer, or weight values.
- Additional database-suite observation: `supabase test db` was also run but
  is not counted as a W04 pass. It reported 53/400 failures because that global
  pgTAP suite assumes an empty database and the shared local stack already
  contains persistent fixtures/audit rows; several later Phase 11/12 assertions
  are also order-sensitive. No local reset was authorized or performed. The
  isolated W04 Storage/race suites above passed and clean up their own actors.
- Device smoke: Chrome camera/file behavior is covered by real browser file
  input plus Pixel emulation. No Android Emulator window or physical-iPhone
  browser connector was available for a fresh OS permission dialog; physical
  Safari/Android camera permission remains a non-blocking field-device smoke,
  not an authority or implementation deferral.
- Remaining blockers: none for W04 exit criteria. Next phase item is W05 manual
  payment and Coach application, without production deployment.
