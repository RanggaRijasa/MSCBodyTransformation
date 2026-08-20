# MSCWEB W07.4 — Registration and First-login Onboarding Remediation

Status: `Not started`  
Autonomy: `A` against local Supabase; `B` for real browser camera/Google OAuth smoke; `D` for hosted Auth/schema/function changes or production account creation  
Depends on: completed W02 Auth, W05 manual payment, W06 Coach application, and W07 Admin review

## Objective

Close the registration-parity gap by routing every new Google user through the iOS-authoritative onboarding hierarchy: profile → `Lanjut sebagai Peserta` or `Ajukan menjadi Coach` → Participant QR or Coach eligibility/manual payment → active Participant/pending Coach application.

Role authority does not change: every self-registration starts as Participant; Coach is only an application until authoritative Admin approval.

## Why this is remediation

Current MSCWEB:

- `/login` has only Google and says Coach cannot be chosen at registration;
- OAuth callback loads role only and routes directly into the app;
- backend creates a provisional Participant profile, but AuthProvider ignores `onboarding_status`;
- active Participant can apply later from Profile through W06;
- first-login name/phone/member-level/purpose and Participant QR finalization UI are missing.

The backend already contains `update_my_profile`, `finalize_participant_onboarding`, `prepare_coach_application_handoff`, provisional cancellation/expiry cleanup, and W06 application/payment operations. W07.4 reconciles, hardens, and connects them instead of creating a parallel onboarding system.

## Required references

- native [`10A Phase 09.5`](../../MSCBodyTransformation/MSC_Codex_Phased_Workplan/10A_PHASE_09_5_GUEST_AUTH_PROFILE_AND_COACH_APPLICATION_UI.md)
- native [`UI Reference Sheet`](../../MSCBodyTransformation/MSC_Codex_Phased_Workplan/UI_REFERENCE_SHEET.md) onboarding/eligibility/payment/Admin rules
- current iOS runtime/screens: profile purpose, Coach eligibility/payment/pending, Participant QR unconfirmed/confirmed
- `00_PRODUCT_SPEC.md` `PROD-ONB-*`
- `01_ARCHITECTURE.md` first-login onboarding state
- `02_UX_PARITY_AND_ROUTES.md` `UX-ONB-*`
- `03_DESIGN_SYSTEM.md` onboarding components/radio semantics
- `04_MANUAL_PAYMENT.md` Coach manual-payment contract
- `05_DATA_SECURITY.md` `SEC-ONB-*`
- `07_TESTING_ACCEPTANCE.md` `QA-ONB-*`, `QA-JRN-014`, `QA-JRN-015`
- [`ADR-0009`](../decisions/0009-first-login-onboarding-parity.md)
- W02/W05/W06 migrations, AuthProvider, Google adapter, QR/media adapters, cleanup functions, generated types, and regressions

## In scope

- Google new-vs-existing resolution after OAuth callback;
- session-context/onboarding state and central route guards;
- Name, phone, member level, and Participant/Coach-intent form;
- Participant Coach-QR validation/finalization;
- new-user Coach eligibility, manual payment proof, pending/correction/status;
- Participant activation after Coach proof is under review;
- explicit cancel, 24-hour resume/expiry cleanup, cache/session hygiene;
- reuse of current W05/W06 components/operations and Admin decision flow;
- compact/wide/accessibility/browser-camera/security/E2E tests.

## Out of scope

- email/password, Apple login, OTP, manual Coach code, anonymous Supabase Auth, direct Coach/Admin role selection;
- changing Coach eligibility/prices, payment destination/policy, Admin approval authority, or existing active Participant application semantics;
- adding a second onboarding database model, storing onboarding draft in localStorage, or modifying iOS source;
- hosted Google/Auth configuration or production account smoke without separate authorization.

## Deliverables

- reconciled clean migration chain/generated types for provisional lifecycle and all called RPCs;
- safe `get_my_session_context` projection and explicit AuthProvider onboarding state;
- central onboarding route guard/preserved-intent policy;
- typed onboarding domain/repository/use-case boundary;
- `/onboarding/profile`, Participant QR, Coach eligibility/payment/status routes;
- atomic provisional Coach proof-submit + active-Participant authority operation;
- two-phase idempotent cancellation receipt/worker and abandoned provisional cleanup reconciliation;
- shared W06 active-Participant application preserved;
- unit/database/integration/E2E/visual/accessibility/security evidence;
- no hosted deployment, production account, real transfer, Git, or iOS mutation.

## Mandatory simulator gate

- [ ] Fresh-build/launch current iOS first-registration flow on iPhone 17/iOS 26.5 or current available device/OS.
- [ ] Inspect and log `Lengkapi profil`, both purpose cards, Member-disabled Coach, every member level, Back/Tutup, scroll/keyboard, and draft copy.
- [ ] Inspect Coach eligibility, price/duration/no-auto-renew, payment, pending Admin, correction/rejection where scenarios exist.
- [ ] Inspect Participant `Hubungkan dengan Coach` before/after valid QR and camera/invalid/denied states.
- [ ] Record hierarchy/flow/gesture/menu/state differences. Web adaptation uses `akun MSC belum aktif`, Google-only Auth, browser camera, and manual bank/QRIS.
- [ ] Do not mark the slice complete using the supplied screenshots alone; fresh runtime and browser comparison are required.

## Checklist

### 1. Migration-chain and authority audit

- [ ] Reproduce local schema from committed migrations; verify profile provisional columns/constraints, bootstrap trigger, profile update, Participant finalization, Coach handoff, cancel, expiry cleanup, Coach application/payment RPCs, and grants.
- [ ] Regenerate/verify database types only after migration authority is consistent; no generated-only function/column may be treated as real.
- [ ] Audit existing private RPC/RLS for active-status enforcement and inventory every operation a provisional token can call.
- [ ] Add focused migration tests before UI: new profile shape, active existing profile, expired profile, double callback, and direct private-operation denial.

### 2. Session context and route guards

- [ ] Add fixed `get_my_session_context` with role, onboarding status, account purpose, completeness flags, provisional expiry, and safe resume step only.
- [ ] Extend AuthProvider state to `loading | guest | onboarding | authenticated | error`; never infer active from role alone.
- [ ] OAuth callback and initial session refresh route provisional/coach-handoff/cleanup states before evaluating intended app route.
- [ ] Central guard covers direct `/app`, `/coach`, `/admin`, Back/Forward, reload, duplicate tabs, and stale cached account summary without private-content flash.
- [ ] Preserve one allowlisted internal `returnTo`; consume only after active finalization and authorization. Reject external, Admin/Coach-forged, stale, or recursive onboarding intent.
- [ ] Existing active Participant/Coach/Admin route exactly as before.

### 3. Profile and account-purpose step

- [ ] `/onboarding/profile` pre-fills Google display name/photo safely and requires trimmed Name, normalized phone, Member Level, and purpose.
- [ ] Use all stable member-level raw values and `id-ID` labels; level is profile data, never role/authorization.
- [ ] Purpose cards use radio semantics, Phosphor/`MSCIcon`, selected text/border/icon, accessible labels, and 44×44 minimum targets.
- [ ] Member disables Coach with explanation. Changing to Member while Coach selected clears/reconciles purpose; other profile fields remain.
- [ ] Draft stays feature/session state while editing; Continue uses new versioned `save_my_provisional_onboarding_profile`. Do not narrow/reuse native shared `update_my_profile`; add native active-edit and concurrent provisional-save regression. No phone/purpose in URL, localStorage, analytics, or logs.
- [ ] Back/Tutup confirmation distinguishes explicit cancel from browser tab close and explains 24-hour provisional resume.

### 4. Participant QR and finalization

- [ ] Participant purpose routes to `/onboarding/participant/coach` and reuses browser QR adapter with no manual input/fallback.
- [ ] Unconfirmed state, permission request, denied, unsupported, invalid, expired, unapproved/non-public/inactive Coach, retry/close, and confirmed Coach card match iOS hierarchy.
- [ ] Harden `finalize_participant_onboarding` to recheck caller provisional/purpose/profile/version/expiry and Coach approved + public + active entitlement at commit time.
- [ ] Raw QR stays in transient scanner/operation boundary and never appears in route, state logs, analytics, query cache, UI, or response.
- [ ] Valid confirmation atomically sets current Coach, active onboarding, finalized timestamp, clears expiry, and returns safe Participant context exactly once.
- [ ] Double-click, concurrent tab, retry after lost response, QR change, and account switch are deterministic.

### 5. New-user Coach eligibility and payment

- [ ] Coach purpose routes to eligibility and calls Coach handoff only after valid profile/level.
- [ ] Reuse W06 member levels, server prices, HOM STS/ICT/terms, three-month/no-auto-renew copy, application/order idempotency, payment destination, image normalization, and private proof upload.
- [ ] Member/incomplete eligibility cannot create order; client price/level/purpose mutation is revalidated server-side.
- [ ] Provisioning creates at most one resumable application and one current payment order; refresh/tab duplication never creates another.
- [ ] Payment route supports awaiting proof, upload progress/error, under review, correction/reason/resubmit, terminal rejection, approved/active, expired/cancelled.
- [ ] Add `submit_coach_onboarding_payment_evidence` wrapper/variant that in one database transaction validates/submits prepared proof, moves order to `under_review`, and sets profile active Participant/finalized exactly once. Provisional Coach orders cannot call generic submit followed by another finalizer.
- [ ] Add nonterminal `Minta perbaikan bukti`: same submitted application/order, `correction_required`, reason, new append-only proof attempt, and safe resubmit.
- [ ] Keep `Tolak pengajuan` terminal: current application/order close with reason/history; a later deliberate reapplication from active Participant creates a new application/order, never mutates the rejected pair.
- [ ] Pending screen states `Akun tetap sebagai Peserta`; Participant shell/profile exposes application status and resume without allowing Coach workspace.
- [ ] W06 Admin approval remains the only Coach activation; correction preserves the same pair, terminal rejection preserves Participant and closes that pair.

### 6. Cancellation, expiry, and cleanup

- [ ] Replace direct `cancel_my_provisional_identity` use with `request_my_provisional_cancellation(idempotency_key)`: create one private receipt, cancel safe pre-proof application/order/upload intents, set cleanup pending, and return before session/identity deletion.
- [ ] Trusted cancellation worker claims receipt, removes media through Storage API, revokes every session, deletes Auth/profile, and finalizes receipt/audit. Do not assume deleting `auth.users` invalidates existing JWTs.
- [ ] Retry before identity deletion returns the same receipt. After deletion, stale/absent session converges to Guest and is treated as completed; it does not require an authenticated prior-success response.
- [ ] Test response loss after receipt creation and after Auth deletion; neither path duplicates artifacts nor leaves cleanup stuck.
- [ ] Once proof is submitted/financial record exists, `Batalkan pendaftaran` MUST NOT delete identity/order/evidence/audit; finalize/retain Participant and route to application/payment status.
- [ ] Tab close/unload performs no authoritative mutation. Next login resumes exact server step until 24-hour expiry.
- [ ] Extend scheduled expired-provisional cleanup to enqueue/use the same cancellation receipt worker, recheck relationships/application/order/proof/media, and retry partial failures.
- [ ] Cleanup never deletes active Participant, submitted financial history, existing active-user application, or another account's objects.

### 7. UI reuse and regressions

- [ ] Extract/reuse W06 eligibility/payment/status presentation without coupling active Participant AppShell to onboarding navigation.
- [ ] Onboarding uses focused full-screen layout, safe-area/header/back/cancel, scroll, keyboard, light/dark, reduced motion, and no bottom tab/sidebar.
- [ ] Production copy is Indonesian and distinguishes `tujuan akun` from role selection.
- [ ] Existing `/login`, Guest auth gates, active Participant Profile `Ajukan akses Coach`, W05 enrollment/payment, W06 application/Admin approval, logout/cache, and role roots remain functional.
- [ ] Update misleading Login/Profile copy: account starts as Participant authority, while new user chooses Participant or `Ajukan Coach` during onboarding.

## Sub-agent plan

- `msc_explorer`: map iOS runtime/docs, auth bootstrap/session/RLS, provisional cleanup, QR finalization, and W06 payment/application dependencies.
- `msc_implementer`: sole writer, sequentially migration/security → session guard → profile/Participant → Coach/cancel → tests.
- `msc_reviewer`: auth/role escalation, provisional data access, QR secrecy, payment/application idempotency, cancellation/cleanup races, privacy, parity/accessibility, and regression.

Primary agent owns lifecycle state machine, migration order, route guard, cancellation boundary, proof-to-Participant finalization, and final evidence.

## Verification

- `QA-JRN-014`, `QA-JRN-015`, and every `QA-ONB-*`;
- clean migration chain, generated types, grants/RLS/security/performance advisors;
- provisional allowlist vs active private-operation negative matrix, including generic proof-submit denial for provisional Coach order;
- profile/purpose/member-level validation and phone/log privacy;
- Participant QR camera/invalid/authorization/idempotency/concurrency suite;
- Coach eligibility/price/order/atomic proof+Participant/pending/nonterminal correction/terminal rejection/reapplication/Admin approval suite;
- cancellation receipt/worker, response-loss-before/after-delete, cancel-before-proof, cancel-after-proof, tab-close/resume, expiry cleanup, partial failure/retry/orphan-media suite;
- stale-token/second-tab/session-revocation tests after explicit cancel and expiry cleanup;
- active existing Participant/Coach/Admin and existing W02/W03/W05/W06/W07 regressions;
- compact/wide/light/dark/keyboard/screen-reader/200%-zoom/Back/Forward/reload/account-switch/duplicate-tab Playwright;
- Safari iOS and Chrome Android camera smoke where device permission is available;
- production build/bundle/PWA/secret/private-data scan.

## Exit criteria

- New Google user cannot enter private app before an authoritative onboarding outcome.
- Participant purpose requires valid Coach QR and activates exactly one Participant/current-Coach relationship.
- Coach purpose completes eligibility/manual proof, then enters app as Participant with one pending application; only Admin approval activates Coach.
- Explicit cancellation/expiry cleanup leaves no unsafe provisional identity/artifact, while submitted financial history is preserved.
- Existing active accounts and later Profile Coach application remain unchanged.
- Security, idempotency, parity, accessibility, device, build, and regression gates pass.

## User input or authorization

- No new product decision is required for local implementation; iOS flow and ADR-0009 define the web adaptation.
- Local Google OAuth/Android camera may reuse already configured development setup; system permission prompts may still require user interaction.
- Hosted Auth trigger/RPC/RLS/function/cron deployment, production provisional cleanup activation, and production registration/account/payment smoke each require separate explicit authorization and cleanup scope.
- No real transfer is required for local tests; use deterministic local payment destination and synthetic proof only.

## Progress log

Append requirement IDs, iOS/device/browser evidence, lifecycle/version diagram, migrations/RPCs/policies, cancellation/cleanup inventory, commands/results, external approvals, remaining blockers, and next item.
