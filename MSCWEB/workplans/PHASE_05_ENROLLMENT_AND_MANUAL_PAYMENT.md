# MSCWEB W05 — Enrollment and manual payment

Status: `Complete locally — production inputs recorded; deployment not authorized`
Autonomy: `A` locally; `C` business payment policy; `D` real payment/production data  
Depends on: W02 Auth, W03 Program, and stable W04 authority patterns

## Objective

Implement Coach QR enrollment, free-program enrollment, and manual bank/QRIS payment with private proof, Admin review, and atomic entitlement/enrollment.

Final Participant sequence: a valid Coach QR immediately creates the paid reservation and opens the payment screen. Bank transfer and QRIS are shown together as destination alternatives; there is no Participant method picker, Coach confirmation step, or extra create-request action. Only Admin approves or rejects after proof submission.

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

- [x] Inspect current iOS program offer, `Gabung program`, selected program/price, and `Pindai QR coach` flow.
- [x] Inspect current Admin proof/decision interaction patterns, sticky actions, dialogs, and conflict copy.
- [x] Treat manual payment UI as web replacement while preserving navigation/state hierarchy.

## Checklist

### QR and enrollment

- [x] Camera permission, unsupported, denied, invalid, mismatch, duplicate, capacity, inactive, and close states.
- [x] No manual/copyable Coach code or raw payload in URL/log/cache.
- [x] Preserve safe opaque intent through login.
- [x] Free program creates enrollment exactly once without payment request.

### Payment data/security

- [x] Destination configuration and immutable request snapshot.
- [x] State machine and compare-and-set version transitions.
- [x] Unique proof attempts; private bucket; normalized JPEG ≤ 8 MiB.
- [x] Define the orphan-proof cleanup process: eligible object states, database reference check, minimum retention, authorized actor/job, audit, retry, and dry-run mode.
- [x] Verify cleanup locally with referenced, unreferenced, pending-upload, rejected-history, and concurrent-submit cases; never delete a referenced attempt.
- [x] Owner/Admin policies and short-lived authorized viewing.
- [x] Append-only review/audit and idempotency keys.
- [x] Explicit grants/RLS and typed authority functions.

### Participant UI

- [x] Subject, amount, order ID, account holder/number, QRIS, instructions, copy feedback.
- [x] Valid Coach QR proceeds directly to payment; no Coach confirmation, payment-method selection, or extra request CTA.
- [x] Upload/preview/confirm/progress/failure and manual-review explanation.
- [x] Awaiting, pending, rejected with reason/resubmit, approved, expired, cancelled.
- [x] No invented approval SLA or automatic-verification claim.

### Admin UI/authority

- [x] `Perlu tindakan` queue, filters, oldest-first, identity/context/attempt history.
- [x] Full private proof viewer and concurrent-review handling.
- [x] Reject requires reason.
- [x] Approve confirmation shows subject/amount.
- [x] One transaction atomically creates approved commerce state, entitlement, enrollment, and audit; no partial approval.

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
- Orphan proof cleanup is designed and locally verified; production schedule and retention activation remain an authorization gate.
- Production payment inputs are recorded without committing or uploading real bank/QRIS data.

## User input or authorization

- Cleanup policy is final: automatic daily run at `02.00 WITA`; day-30 evidence still under review is retained until the Admin decision and then deleted immediately.
- Real payment data and any hosted deployment require explicit authorization.
- Local work may use clearly fake fixtures and a non-payable QR test image.

## Progress log

Append simulator flow, schema/functions, state transitions, payment tests, policy blockers, files/commands, and next item.

### 2026-08-12 — W05 complete locally

- Requirement IDs: `PAY-001…005`, `PAY-DST-001…004`, `PAY-STATE-001…005`, `PAY-PTC-001…006`, `PAY-UPL-001…007`, `PAY-ADM-001…005`, `SEC-DATA-001…005`, `QA-JRN-001…004`.
- Files changed: W05 Supabase migration/function/cleanup documentation; payment models/repository/queries; Participant enrollment/payment and Admin queue/detail routes/components; private-media bucket contract; enrollment status model; production/Worker routing; unit, integration, cleanup, and E2E tests.
- Assumptions: local fixtures use a clearly fake, non-payable destination; authenticated Storage downloads replace shareable signed URLs for proof/QRIS viewing; three proof attempts and 24-hour local reservation/correction values are feasibility defaults only, not approved production policy.
- iOS Simulator parity: fresh `iPhone 17 Pro`, iOS `26.5`, Participant local journey, Admin manual enrollment/proof decision, and Coach rejection sheet were built/launched. The verified hierarchy is offer → selected program/price → scanner → Coach confirmation → payment; Admin uses queue/detail, sticky actions, confirmation, mandatory rejection reason, then return/refetch. Command: `xcodebuild test -project MSCBodyTransformation.xcodeproj -scheme MSCBodyTransformation -configuration Debug -destination 'platform=iOS Simulator,id=C63135B7-AF6A-42C0-8993-DF4C72589FE1' -parallel-testing-enabled NO -only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testParticipantCompletesLocalJourneySlice -only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testAdminApprovesCoachAndManuallyEnrollsParticipant -only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachRejectionUsesSingleSheetNavigationFlow`; result: 3 passed, 0 failed. iOS source/project were not modified.
- Camera evidence: the existing shared browser scanner retains verified permission, denied, unsupported, close, and scan behavior. Physical Safari iPhone evidence supplied at `/Users/ranggarijasa/Downloads/ScreenRecording_08-12-2026 16-59-59_1.MP4` confirms `QR terdeteksi`; the iPhone Simulator is not counted as camera evidence.
- Migration: `PGPASSWORD=postgres psql -h 127.0.0.1 -p 54322 -U postgres -d postgres -X -v ON_ERROR_STOP=1 --single-transaction -f MSCWEB/supabase/migrations/20260812220000_w05_manual_payment.sql`; result: pass, including a second idempotency application.
- Database/integration: local payment test passes free idempotency, invalid/mismatched QR, full/inactive program, immutable destination snapshot, owner isolation, Admin read, upload, atomic approval, duplicate prevention, and concurrent approve/reject. Cleanup SQL passes referenced, unreferenced, pending upload, rejected history, concurrent reference, dry-run, and retention guard, with full rollback.
- Browser: E2E passes on Chromium desktop and Android compact for Participant upload → Admin reject → Participant resubmit → Admin approval → atomic enrollment. Full regression: 60 passed across both projects. Compact screenshots were inspected after the final layout pass; no horizontal overflow or raw object path appears in UI.
- Build/tests: `npm run typecheck`, `npm run lint`, `npm test`, `npm run build`, `npm run verify:bundle`, and `npm run verify:pwa` pass. Unit/integration default run: 78 passed, 4 environment-skipped. Bundle verifier: 33 JavaScript files. Local Supabase integration and cleanup suites pass separately.
- Security: proof and QRIS assets remain private; browser uses authenticated, no-store downloads and revokes object URLs. Raw Coach QR, private object paths, proof URLs, account secrets, and sensitive media are not logged or placed in navigation/cache. Review is compare-and-set, audited, and server-authoritative.
- Remaining production blockers: real bank/account/QRIS, expiry, review SLA, resubmission, reconciliation, dispute/refund, proof retention, cleanup schedule/actor, hosted migration/function deployment, and any production data require explicit authorization. No production schedule or real payment destination was created.
- Next item: W06 Coach experience. Its Coach application/payment policy inputs remain separate; W05 approval intentionally rejects `coach_access` purpose.

### 2026-08-13 — Production payment decisions recorded

- Destination input received: BCA account ending `3841`, account holder `Ni Wayan Sudarmi`, plus owner-provided static QRIS PNG (`1098×1098`). Full account data and QRIS were not committed, copied into public assets, uploaded, or deployed.
- Final policy: normal IDR price without unique amount; 24-hour seat reservation; on-time proof retains the seat during review; maximum three proof attempts; mandatory rejection reason/instructions; no Participant refund CTA; approved voluntary cancellation is non-refundable; no promised SLA; scheduled-program payments must be reviewed before start; Coach access is three months without auto-renew.
- Late transfer: Admin may restore the order when capacity remains. If capacity is full and funds arrived, Admin rejects and records an exceptional reversal.
- Exceptional reversal: funds received after a rejected payment, duplicate transfer, overpayment difference, or MSC cancellation/non-delivery. Admin-only, audited, target resolution seven business days. Legal review remains required before production.
- Retention is final: delete Participant and Coach proof images 30 days after upload; retain transaction/audit metadata. An image still `under_review` on day 30 remains available until the Admin decision, then is deleted immediately.
- Cleanup schedule is final: automatic daily run at `02.00 WITA` via server-side Supabase Cron → Edge Function, with the first seven production runs in dry-run. There is no Admin-web delete control; manual execution is an audited technical-operator emergency procedure through Supabase.
- Remaining production gates: legal review of `no refund`/exceptional reversal and a separate explicit authorization to deploy migrations/functions/cron/configuration and upload the real destination to hosted production.

### 2026-08-13 — Real destination activated locally for Android review

- Scope: local Supabase only. No hosted production, deployment, repository asset, or public bucket was changed.
- Activated exactly one versioned local destination: BCA account ending `3841`, account holder `Ni Wayan Sudarmi`, destination version `8`.
- The owner-supplied QRIS PNG was converted to a private metadata-stripped JPEG (`1098×1098`, under the 8 MiB bucket limit) and uploaded only to local `payment-destination-assets`.
- Local instructions explicitly say this is a preview and no real payment should be made.
- One `static_qris` preview order was created for the currently active local Participant through `create_program_payment_order`; the same server authority validated Participant, active Coach, program, capacity, destination, and idempotency.
- Android verification: Chrome emulator route displays `Pembayaran program`, `Menunggu bukti`, `Rp125.000`, QRIS, BCA/account holder, local-preview warning, and the proof-upload control. The prior generic payment-configuration error is no longer present.
- The local preview order and destination remain available so the owner can inspect the complete W05 UI. They are not production transactions and must not receive a real transfer.

### 2026-08-13 — Android free-enrollment loading and payment scroll regression fixed

- Files changed: `src/features/payment/ParticipantPaymentFlow.tsx` and `tests/e2e/enrollment-payment.spec.ts`.
- Cause: React Query correctly leaves a disabled paid-order query in `pending`; the screen incorrectly treated that state as active loading for free programs. The loading/error gate now applies only when paid orders are enabled.
- UI: free enrollment and payment-order content now use bounded vertical `ScrollView` containers, preserving the compact bottom navigation while allowing the full QRIS, account, upload, history, and return actions to be reached.
- Assumptions: free programs never create or load a payment order; paid programs keep the existing order-first resume behavior.
- Build commands: `npm run typecheck`, `npm run lint`, and `npm run build`; result: pass.
- Test command: `set -a; eval "$(supabase status -o env)"; set +a; npx playwright test tests/e2e/enrollment-payment.spec.ts --project=chromium-compact`; result: 2 passed. The added cases prove a free program reaches `Pindai QR Coach` without an infinite spinner and a compact paid-order container has usable vertical overflow.
- Android emulator: the previously stuck free-program tab was reloaded against the final build and now displays the enrollment card and `Pindai QR Coach`. The paid-order scroll container measured `1,874 px` content in a `661 px` viewport and moved from `scrollTop 0` to `1,212 px`.
- Remaining blockers: unchanged production deployment/legal gates above. No production, Git, or native iOS mutation was performed.

### 2026-08-13 — Local E2E fixture isolation corrected

- Files changed: `tests/e2e/enrollment-payment.spec.ts` and this workplan.
- Cause: W05 payment events and ledger entries are append-only by design, so teardown attempts to delete the paid order could not remove its parent program. Completed or interrupted E2E runs could therefore leave an active public fixture visible to the Android Participant; its order belonged to the deleted test identity, not the current user.
- Fix: teardown archives and unpublishes the paid fixture before any best-effort cleanup. This preserves immutable audit records while preventing test programs from remaining in the public catalog.
- Error copy: `coach_qr_invalid` and `coach_mismatch` now map to distinct, actionable Indonesian messages instead of the generic payment-data validation message; raw QR/backend details remain hidden.
- Local repair: eight stale paid E2E fixtures were changed from `active` to `archived`; the explicitly retained Android preview program remains the only active program with that fixture title. The stale error tab was closed and the valid preview order tab was brought to the foreground.
- Commands: `npx vitest run tests/unit/manual-payment-contract.test.ts`, `npm run typecheck`, `npm run lint`, `npm run build`, and `set -a; eval "$(supabase status -o env)"; set +a; npx playwright test tests/e2e/enrollment-payment.spec.ts --project=chromium-compact --workers=1`; result: 4 unit tests pass, typecheck/lint/build pass, and 2 E2E tests pass.
- Post-test database check: `Program Pembayaran Browser W05` has exactly `1 active` preview and `9 archived` audit-preserving fixtures. Android gesture verification reached QRIS, bank/account details, and the lower payment content.
- Scope: local Supabase and Android Chrome only. No hosted production, Git, or native iOS mutation was performed.

### 2026-08-13 — QRIS and proof-upload copy simplified

- Files changed: `src/features/payment/ParticipantPaymentFlow.tsx` and this workplan.
- UI: the private destination image now has a visible `QRIS` heading. The technical paragraph describing JPEG normalization, resizing, and metadata removal was removed from the Participant proof-upload card; the actual normalization/privacy behavior and upload control are unchanged.
- Build commands: `npm run typecheck`, `npm run lint`, and `npm run build`; result: pass.
- Android Chrome verification: the retained private payment preview was reloaded on `emulator-5554`. The `QRIS` heading appears directly above the code, the removed paragraph is absent, the proof-upload control remains available, and the browser console has no errors.
- Scope: local UI and Android review only. No hosted production, Git, Supabase data/configuration, or native iOS mutation was performed.

### 2026-08-13 — Participant payment actions decluttered

- Files changed: `src/features/payment/ParticipantPaymentFlow.tsx`, `tests/e2e/enrollment-payment.spec.ts`, and this workplan.
- UI: the fixed copy toast was replaced by inline feedback beneath the copy controls, so it cannot cover `Kembali ke program` or the compact navbar. The web copy action first uses a user-initiated temporary field to avoid Chrome Android's clipboard permission dialog, with the Clipboard API retained as fallback.
- Upload: `Ambil atau pilih bukti` is now `Upload bukti pembayaran`; after selection, the file name is rendered immediately below the button. The Participant `Riwayat bukti` card and its unnecessary query were removed; rejection status and Admin reason remain available from the payment order state.
- Build commands: `npm run typecheck`, `npm run lint`, and `npm run build`; result: pass.
- Test command: `set -a; eval "$(supabase status -o env)"; set +a; npx playwright test tests/e2e/enrollment-payment.spec.ts --project=chromium-compact --workers=1`; result: 2 passed. The upload helper now verifies `bukti.png` is visible after file selection.
- Android Chrome verification: a real click on `Salin jumlah` produced inline `Jumlah disalin` with non-overlay positioning; the renamed upload control, selected filename, absent history, visible return button, and compact navbar were visually inspected. CDP console inspection after a clean reload reported zero warnings/errors.
- Scope: local UI, tests, and Android review only. No hosted production, Git, Supabase schema/data/configuration, or native iOS mutation was performed.

### 2026-08-13 — Paid-program resume and compact payment controls

- Files changed: `src/features/participant/participant-program-policy.ts`, `src/features/payment/ParticipantPaymentFlow.tsx`, `tests/unit/participant-program.test.ts`, `tests/e2e/enrollment-payment.spec.ts`, and this workplan.
- Root cause: the retained paid preview remained active, published, and in `awaiting_evidence`, but its Participant enrollment was `waiting_for_payment`. The catalog policy excluded that status from all three segments, making the program appear missing after refresh.
- Catalog fix: `waiting_for_payment` now belongs to `Diikuti`, where the existing `Lihat pembayaran` action resumes the order. No duplicate paid program or replacement order was created. Post-E2E database verification reports exactly one active/published paid preview fixture.
- Payment UI: the full-width copy buttons were replaced by accessible 44 px copy icon controls beside `Jumlah` and `Nomor rekening`. Upload is a compact outlined secondary control, while the red primary action is now `Konfirmasi pembayaran`; selected filename remains below upload.
- Upload interaction: the file input uses an explicit `label`/`htmlFor` association. Chrome Android's file-chooser event fired from a real pointer click, proving the control is actionable without selecting a private file.
- Commands: `npm run typecheck`, `npm run lint`, `npx vitest run tests/unit/participant-program.test.ts`, `npm run build`, and `set -a; eval "$(supabase status -o env)"; set +a; npx playwright test tests/e2e/enrollment-payment.spec.ts --project=chromium-compact --workers=1`; result: pass, including 5 focused unit tests and 2 compact E2E journeys.
- Android Chrome verification: the paid preview appears under `Diikuti`; amount/account copy icons, compact outlined upload, selected filename, `Konfirmasi pembayaran`, return button, and bottom navigation were visually inspected. Final console inspection reported zero warnings/errors.
- Environment: local Supabase remained active; `colima status` reported stopped and no runtime start/stop was performed. No hosted production, Git, schema, production data, or native iOS mutation was performed.

### 2026-08-13 — Continuous local payment fixture and upload hit target

- Files changed: `supabase/dev/ensure_continuous_payment_preview.local.sql`, `src/features/payment/ParticipantPaymentFlow.tsx`, `tests/e2e/enrollment-payment.spec.ts`, and this workplan.
- Local fixture: created `Program Uji Pembayaran Lokal #1`, an active/published paid program with zero enrollments and zero payment orders. It appears in `Tersedia`, allowing QR Coach scanning and payment creation to be exercised from the beginning without disturbing the existing `waiting_for_payment` preview.
- Continuous behavior: rerunning the local SQL script does nothing while a clean fixture exists. After the clean fixture receives an enrollment/order, rerunning creates the next numbered fixture and preserves the consumed program/audit history.
- Upload UI: the compact outlined control is now a real HTML button that directly clicks its hidden file input. Its container centers the button within the proof card; the selected filename and red `Konfirmasi pembayaran` action remain unchanged.
- Database verification: the SQL script was executed twice. The first run created `#1`; the second reported that a clean fixture already exists. Final query still reports exactly `0 enrollments` and `0 orders` for `#1`.
- Commands: `npm run typecheck`, `npm run lint`, `npx vitest run tests/unit/participant-program.test.ts`, `npm run build`, and the compact W05 Playwright command; result: pass, including 5 focused unit tests and 2 E2E journeys.
- Android Chrome verification: `#1` is visible first in `Tersedia`; the centered upload button measured at the compact viewport center and a real pointer click emitted the browser file-chooser event. Final catalog reload had zero console warnings/errors.
- Scope: local Supabase data, local-only fixture script, web UI, tests, and Android review. No hosted production, Git, migration/schema, production data, or native iOS mutation was performed.

### 2026-08-13 — Stale local Coach QR diagnosed and replaced

- Reported behavior: the same `coach_qr_invalid` message appeared before both free and paid enrollment, isolating the failure to the shared QR-resolution boundary rather than program pricing.
- Diagnosis: the Android Participant is linked to an approved Coach with active access, but the previously supplied example QR no longer matched that Coach's current 42-character identifier. Only a SHA-256 fingerprint was printed during diagnosis; the raw identifier was not logged or added to the repository.
- Replacement: generated `/private/tmp/msc-current-coach-qr.png` from the linked active Coach's local identifier. The QR was decoded locally and compared byte-for-byte before being shown.
- Authority verification: `resolve_coach_qr_for_enrollment` was executed for the emulator Participant inside a rolled-back local transaction and resolved `Coach W04`. No pending selection or enrollment mutation was retained by the verification.
- Scope: read-only/rolled-back local Supabase diagnosis plus one temporary QR outside the repository. No application code, hosted production, Git, migration/schema, production data, or native iOS mutation was performed.

### 2026-08-13 — Coach QR proceeds directly to manual payment

- Product correction: the paid Participant flow is now `Pindai QR Coach` → server validates Coach/program/capacity and creates the reservation → `Pembayaran program`. Participant no longer confirms the Coach, chooses transfer versus QRIS, or presses `Buat permintaan pembayaran`; bank and QRIS are destination alternatives shown together. Admin remains the only decision maker after proof submission.
- Files changed: `04_MANUAL_PAYMENT.md`, `src/features/payment/ParticipantPaymentFlow.tsx`, `src/features/payment/payment-repository.ts`, `src/features/payment/payment-queries.ts`, `src/features/payment/AdminPaymentComponents.tsx`, `tests/e2e/enrollment-payment.spec.ts`, and this workplan.
- Privacy/authority: the raw QR payload is passed directly into the authoritative mutation and is not retained in UI state, URL, or logs. Paid enrollment remains `waiting_for_payment`; Admin approval after proof review is still required to create the active enrollment atomically.
- Compatibility: the existing RPC still receives an internal `bank_transfer` compatibility value, but it is no longer a Participant choice. Both bank and QRIS snapshots render whenever configured, and Admin review no longer labels a selected payment method.
- Verification commands: `npm run typecheck`, `npm run lint`, `npm run build`, `npx vitest run tests/unit/manual-payment-contract.test.ts tests/unit/participant-program.test.ts`, and `set -a; eval "$(supabase status -o env)"; set +a; npx playwright test tests/e2e/enrollment-payment.spec.ts --project=chromium-compact --workers=1`; result: pass, including 9 focused unit tests and 2 compact W05 E2E journeys.
- Android Chrome verification: on `emulator-5554`, scanning the current active Coach QR on `Program Uji Pembayaran Lokal #2` immediately rendered `Pembayaran program`, `Menunggu bukti`, BCA, account holder, and QRIS. `Konfirmasi Coach`, `Metode pembayaran`, and `Buat permintaan pembayaran` were absent; reload reported no framework overlay and no console warning/error.
- Local data repair: automated E2E had left a fake Bank Uji destination active because immutable order/audit references prevented its deletion. Teardown now snapshots the prior destination and restores it through the Admin RPC after every run. Final local state has BCA/QRIS active as version `18`; consumed fixture `#2` remains `awaiting_evidence` with enrollment `waiting_for_payment`, and clean fixture `Program Uji Pembayaran Lokal #3` has zero orders/enrollments for repeat testing.
- Scope: local Supabase, web source/tests, and Android Chrome only. No hosted production, deployment, Git, native iOS, or Xcode project mutation was performed.

### 2026-08-13 — Repeatable free/paid fixtures, Android picker, and physical-iPhone callback

- Files changed: `supabase/dev/ensure_continuous_payment_preview.local.sql`, `src/app/app/programs.tsx`, `src/app/app/programs/[programId].tsx`, `src/features/participant/participant-program-policy.ts`, `src/features/payment/ParticipantPaymentFlow.tsx`, `src/features/payment/payment-queries.ts`, `src/features/payment/payment-repository.ts`, `src/shared/config/public-environment.ts`, `tests/unit/public-environment.test.ts`, `tests/unit/participant-program.test.ts`, `tests/unit/manual-payment-contract.test.ts`, `tests/e2e/enrollment-payment.spec.ts`, this workplan, and the explicitly authorized local callback entry in repository-root `supabase/config.toml`.
- Local catalog behavior: exactly one active/published `Program uji lokal berbayar` and one `Program uji lokal gratis` are kept clean and available. After either is consumed, the local-only authenticated RPC archives that instance and creates a clean replacement. All current and historical W05 repeatable fixtures are excluded from `Diikuti` and `Riwayat`; immutable enrollment/order/audit records remain stored.
- Production behavior is unchanged: ordinary paid enrollment remains `waiting_for_payment` and appears under `Diikuti` until Admin approval. Repeatability is isolated by the exact local fixture category/title contract and a dev SQL file that is not a hosted migration.
- Android upload fix: the proof input no longer forces camera capture. A user-gesture `showPicker()`/`click()` adapter opens Android Photo Picker, supports selecting the same file again, and keeps the compact upload control centered.
- Physical-iPhone callback fix: when a local build is opened from a private LAN origin, a configured loopback OAuth callback is replaced with that browser origin. A LAN build is available at `http://192.168.111.47:4174`; local config allowlists its callback. Supabase Auth must still be restarted before the running local stack reads that updated allowlist, so a successful physical-device login callback remains unverified.
- Local data/SQL verification: the local fixture function installed successfully; a rollback-only rotation test retained exactly one clean paid and one clean free fixture; the final query reports both active/published and `legacy_active=0`.
- Commands: `npm run typecheck`, `npm run lint`, `npm run build`, `npx vitest run tests/unit/public-environment.test.ts tests/unit/participant-program.test.ts tests/unit/manual-payment-contract.test.ts`, and the compact W05 Playwright command; result: pass, including 21 focused unit tests and 2 compact E2E journeys.
- Android Chrome verification on `emulator-5554`: Tersedia shows the exact free/paid pair; Diikuti contains no W05 repeatable fixture; a real tap on `Upload bukti pembayaran` focuses `com.google.android.photopicker/com.android.photopicker.MainActivity`. The Android Photo Picker screenshot confirms the formerly inert control now opens the system picker.
- Supabase restart: after explicit owner authorization, `supabase stop --yes` reported `backup=true` and `supabase start` completed. Auth now exposes the exact LAN callback in `GOTRUE_URI_ALLOW_LIST`; both loopback and LAN Auth health checks pass, the fixture function remains installed, and the paid/free fixtures remain active/published.
- OAuth preflight: `/auth/v1/authorize` returns HTTP `302` to Google with `redirect_to=http://192.168.111.47:4174/auth/callback`. The LAN `/login` and `/auth/callback` routes both return HTTP `200` with no-cache HTML. Safari was opened on the paired physical iPhone without terminating existing tabs.
- Remaining blocker: the owner must finish the Google account interaction on the physical iPhone. No new `login` audit event was observed during two 20-second checks, so successful Google callback/session creation is not yet claimed. No hosted production, deployment, Git mutation, native iOS source, or Xcode project mutation was performed.

### 2026-08-13 — Redundant proof confirmation removed

- Files changed: `src/features/payment/ParticipantPaymentFlow.tsx`, `tests/unit/manual-payment-contract.test.ts`, `tests/e2e/enrollment-payment.spec.ts`, and this workplan.
- Participant interaction: after selecting a proof image, one primary `Kirim bukti pembayaran` button now submits it immediately. The `Kirim bukti sekarang?` warning card, `Periksa lagi`, intermediate confirmation state, and second `Kirim bukti` button were removed.
- Authority is unchanged: submission still enters manual Admin review, and Admin rejection/resubmission/approval remains server-authoritative.
- Verification: `npm run typecheck`, `npm run lint`, `npx vitest run tests/unit/manual-payment-contract.test.ts`, and `npm run build` pass; 7 focused unit tests pass. Compact Playwright W05 passes 2/2 and explicitly proves the warning/secondary button are absent, one click submits, rejection allows another one-click upload, and final Admin approval activates enrollment atomically.
- Browser/device QA: the in-app browser rendered the local catalog with no warning/error logs; its payment route was authorization-blocked for that browser session, so the authenticated interaction proof used the repository Playwright session. Android Photo Picker still opens from the real upload button. Localhost and physical-iPhone LAN production outputs were rebuilt; no hosted deployment, Git mutation, native iOS source, or Xcode project mutation was performed.

### 2026-08-13 — Repeatable proof selection and button press feedback

- Files changed: `src/features/payment/ParticipantPaymentFlow.tsx`, `src/shared/ui/primitives.tsx`, `tests/unit/manual-payment-contract.test.ts`, `tests/e2e/enrollment-payment.spec.ts`, and this workplan.
- Repeat selection: the hidden file input value is cleared immediately before every picker opening. Selecting the same image again now emits a fresh change event; after a selection the action reads `Ganti bukti pembayaran` and may be used repeatedly before submission.
- State rule: after `Kirim bukti pembayaran`, evidence remains locked while Admin is reviewing it. Upload becomes available again only when Admin rejects it as `correction_required`; it is not intended to create multiple simultaneous attempts during review.
- Visual interaction: upload now uses the shared `Pressable` secondary button rather than a static HTML button. Shared buttons use the pressed surface color and `0.98` scale while held, providing visible press/hold feedback while retaining at least the design-system touch target.
- Verification: typecheck, lint, build, and 8 focused unit tests pass. Compact W05 Playwright passes 2/2; it verifies the real pressed transform, opens the chooser twice, selects the exact same file twice, submits directly, then repeats upload after Admin rejection and completes atomic Admin approval.
- Outputs: localhost Android and physical-iPhone LAN builds were refreshed. No hosted deployment, Git mutation, native iOS source, or Xcode project mutation was performed.

### 2026-08-13 — Android-native proof picker and explicit local review loop

- Files changed: `src/features/payment/ParticipantPaymentFlow.tsx`, `src/global.css`, `tests/unit/manual-payment-contract.test.ts`, `tests/e2e/enrollment-payment.spec.ts`, and this workplan.
- Root cause correction: the shared React Native `Pressable` could re-render between pointer down/up and lose Chrome Android's transient file-picker activation. The proof action now contains a native `input[type=file]` whose selector button covers the complete visual hit target. Press feedback is pure CSS, so holding the action cannot replace the native control before click completes. The input is cleared after its file is captured, allowing the same image to be selected repeatedly.
- Production state: while an order is `under_review`, the proof card now says `Upload dikunci sementara` and explains that upload reopens only after Admin rejection. Ordinary production programs expose no upload action during review.
- Local-only state: an `under_review` program categorized `Pengujian lokal berulang` on a loopback/private-LAN Supabase build exposes `Upload foto uji lokal`. It runs the real browser image normalization repeatedly but does not upload, replace, or mutate the proof currently being reviewed. Leaving and reopening the route restores the same safe local test action. Hosted/non-local builds cannot activate this path.
- Build commands: `npm run typecheck`, `npm run lint`, and `npm run build`; result: pass.
- Test commands: `npm test -- --run tests/unit/manual-payment-contract.test.ts` and `set -a; source /private/tmp/mscweb-supabase-test.env; set +a; npx playwright test tests/e2e/enrollment-payment.spec.ts --project=chromium-compact`; result: 9 focused unit tests and 2 compact E2E journeys pass. E2E proves direct submit, the explicit review lock, repeat local processing, Admin rejection reopening authoritative upload, resubmission, and atomic Admin approval.
- Android verification: Playwright connected through Chrome DevTools to the exact `emulator-5554` payment tab. The native upload control was visible and actionable and emitted a real single-file chooser event (`multiple=false`). The retained local preview remains available for owner interaction.
- Scope: local web UI/tests and local Android Chrome only. No hosted deployment, production Supabase, Git, native iOS source, or Xcode project mutation was performed.
