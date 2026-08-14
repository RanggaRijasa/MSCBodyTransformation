# MSCWEB W06 — Coach application and experience

Status: `Completed`
Autonomy: `A` locally; `C` for final eligibility/operations policy  
Depends on: W04 evidence authority and W05 payment foundation

## Objective

Deliver the full Coach lifecycle: Participant application, eligibility/pricing, manual payment, Admin activation, Coach dashboard, unique QR, assigned participants, evidence operations, programs, leaderboard, and a professional public profile that Coach can share.

## Required references

- `00_PRODUCT_SPEC.md` Coach and application rules
- `04_MANUAL_PAYMENT.md` Coach flow/pricing
- `05_DATA_SECURITY.md`
- `02_UX_PARITY_AND_ROUTES.md`
- [`ADR-0005`](../decisions/0005-public-coach-profile.md) public Coach profile
- current iOS Coach dashboard, quick actions, queues, QR, program, and profile runtime

## Deliverables

- Coach application/attestation/pricing UI and authority operation;
- application payment request based on W05 infrastructure;
- Admin `Setujui dan aktifkan Coach` atomic operation;
- three-month Coach entitlement and protected role activation;
- complete Coach app shell and quick actions;
- assigned Participant/activity/review/QR/program/leaderboard/profile surfaces;
- public `/c/:handle` profile, Coach editor/publication controls, and share action;
- cross-Coach authorization and lifecycle tests.

## Mandatory simulator gate

- [x] Inspect Coach Dashboard profile/metrics and exact 2×3 quick action order/states.
- [x] Inspect review queues/detail, participants, activity, program, leaderboard, QR, and profile routes.
- [x] Inspect Google-derived account photo/name behavior and identify which profile states have no native equivalent.
- [x] Inspect current Admin Coach application detail/eligibility/payment/decision states.
- [x] Record compact hierarchy, badges, tabs, menus, sheets, sticky actions, and empty/error states.

## Checklist

### Application and activation

- [x] Only authenticated Participant can apply; no self-selected Coach/Admin role.
- [x] Level SC or higher plus required HOM STS/ICT attestations.
- [x] Server determines price: SC/SB 100k, Supervisor/World Team 150k, higher group 200k; Member rejected.
- [x] Payment/eligibility/application states remain distinct.
- [x] One Admin action atomically approves payment/application, creates three-month entitlement, activates protected role, and audits.
- [x] Rejection reason required; repeated decision safe/idempotent.

### Coach app

- [x] Dashboard actions: Periksa bukti, Peserta saya, Aktivitas terbaru, Peringkat, Program saya, QR pendaftaran.
- [x] Coach tabs: Dashboard, Program, Profil.
- [x] Tab Program Coach memakai ulang katalog, detail, QR enrollment, pembayaran, aktivitas, dan limitasi Participant; tidak ada katalog `Program yang Anda dampingi`.
- [x] Participant lists and evidence review are assignment/program scoped.
- [x] Unique QR is generated/displayed without exposing raw identifier.
- [x] QR payload supports Participant enrollment and Coach self-enrollment only through protected operations; a Coach cannot enroll with another Coach's QR.
- [x] Program, leaderboard, activity, and profile states match iOS capability.
- [x] Expired/revoked entitlement removes privileged routes after authoritative refresh.

### Public profile and sharing

- [x] Required identity is server-derived: Google/account photo baseline, name, and non-editable verified badge; missing Google photo blocks publication until Coach uploads one.
- [x] Coach can replace the imported photo through the shared normalization/media pipeline.
- [x] Optional editor fields: professional headline, story/biography, city/service area, Instagram, TikTok, website, WhatsApp, phone, testimonials, and before–after.
- [x] Each contact/social field has an independent public toggle; hidden values are absent from the Guest read model and HTML.
- [x] Private Coach draft and public snapshot are separate; publish operation copies only allowlisted/toggled fields and Coach cannot write verified state directly.
- [x] Dedicated public profile media cannot reference private evidence objects; metadata is stripped.
- [x] Every testimonial/before–after record enters moderation; third-party permission attestation is required only when another person is shown or quoted, while self-only content has a clear path without it.
- [x] Public handle is stable, unique, and unrelated to raw QR/auth ID; unknown/unpublished handle returns a safe not-found state.
- [x] `/c/:handle` renders cleanly with only required fields and progressively adds optional sections without empty placeholders.
- [x] `Bagikan profil` uses Web Share when available and accessible copy-link fallback otherwise.
- [x] Expired/revoked Coach entitlement removes verified/public state authoritatively.
- [x] W06 records the metadata contract needed by W08; dynamic Open Graph/Cloudflare rendering is not silently claimed complete here.

## Sub-agent plan

- `msc_explorer`: current Coach/Admin application simulator audit and existing eligibility/entitlement contract map.
- `msc_implementer`: sole writer; application/activation first, then one Coach feature slice at a time.
- `msc_reviewer`: role escalation, entitlement expiry, cross-Coach data, public-field leakage, media provenance, idempotency, UI/accessibility/parity.

Primary agent owns role transition/entitlement operation and shared route guards.

## Verification

- eligibility/pricing boundary tests for every member level;
- incomplete/mutated/concurrent/already-Coach application cases;
- `QA-JRN-005` and `QA-JRN-006`;
- cross-Coach RLS negative tests;
- QR raw-value privacy/log tests;
- entitlement expiry/session refresh;
- required-only/full/partially-public Coach profile component/E2E cases;
- public API/HTML negative tests for hidden contact, raw QR/auth ID, and private evidence path;
- share API/copy fallback/unknown handle/unpublished/expired entitlement tests;
- compact current-simulator parity and wide adaptation checks.

## Exit criteria

- Participant cannot become Coach without complete eligibility, approved proof, and Admin authority operation.
- Coach sees only assigned scope and all six iOS quick actions work.
- QR enrollment identifier remains internal.
- Coach can publish and share a professional profile while every optional field remains optional and hidden contacts stay absent from public responses.
- Activation/rejection/expiry are idempotent and audited.

## User input or authorization

- Confirm operational reviewer/eligibility policy if it differs from the accepted specs.
- Production Admin identities, real payment destination, and production activation remain unauthorized.
- Production photography/testimonials and subject permissions are content inputs, not a blocker for deterministic local fixtures.

## Progress log

Append eligibility cases, simulator evidence, functions/policies, files/tests, adaptive differences, policy decisions, and next item.

### 2026-08-13 — W06 completed locally

- Native parity evidence: the current iPhone 17 Simulator on iOS 26.5 was inspected across Coach Dashboard, review queue/detail, Participants, recent activity, leaderboard, Coach Programs, registration QR, Profile, and Admin People/application detail. Dashboard order is `Periksa bukti`, `Peserta saya`, `Aktivitas terbaru`, `Peringkat`, `Program saya`, `QR pendaftaran`; compact tabs are Dashboard, Program, Profil. Review detail retains sticky reject/approve actions and mandatory rejection copy. The native app has account photo/name and verified state but no equivalent advanced public-profile editor or `/c/:handle` page; those are the accepted ADR-0005 web adaptation. XcodeBuildMCP `build_run_sim` and route launches passed for scheme `MSCBodyTransformation`, Debug, iPhone 17/iOS 26.5; no native source, project, signing, or capability was changed.
- Application/activation: added Participant application and attestation UI, server-priced SC/SB (`Rp100.000`), Supervisor/World Team (`Rp150.000`), higher groups (`Rp200.000`), Member/incomplete rejection, W05 manual-payment reuse, and Admin `Setujui dan aktifkan Coach`. The authority operation uses version checks and one transaction for payment/application approval, commerce/ledger/audit records, three-month entitlement, protected role, and unique QR. Rejection requires a reason, uses the existing `evidence_rejected` event contract, and repeated/crossed decisions are safe.
- Coach app: added the six parity actions and Dashboard/Program/Profile shell plus assigned Participants, activity, leaderboard, program, review reuse, and QR routes. The QR is rendered as an image and share/download never renders or copies its raw payload. Workspace RPCs require an active entitlement and only aggregate rows whose enrollment is assigned to the calling Coach.
- Public profile: added private draft, allowlisted public snapshot, stable public handle, `/c/:handle`, optional professional/contact fields with independent toggles, Web Share/copy fallback, testimonial/before–after moderation and conditional third-party permission. Google/account photo is imported through the shared orientation/resize/metadata-stripping pipeline; public snapshots accept only dedicated Storage objects. Media paths use a server-allocated random namespace rather than auth UUID, and cross-Coach upload/path reuse is rejected. Expiry hides the public snapshot and privileged workspace authoritatively.
- Main files: `supabase/migrations/20260813051840_w06_coach_experience.sql`; `src/features/coach/coach-experience-{models,repository,queries}.ts`; `src/features/coach/{CoachApplicationComponents,AdminCoachApplicationComponents,CoachWorkspaceComponents,CoachProfileComponents}.tsx`; routes under `src/app/app/coach-application.tsx`, `src/app/coach/`, `src/app/admin/people.tsx`, and `src/app/c/[handle].tsx`; production routing in `scripts/serve-production.mjs` and `worker/index.ts`; metadata handoff in `feasibility/W06_PUBLIC_PROFILE_METADATA_CONTRACT.md`; W06 unit, local integration, Worker-routing, and Playwright tests.
- Requirements covered: `PROD-001`, `PROD-004`, `PROD-006`, `PROD-007`, `PROD-CCH-001`–`PROD-CCH-012`, `PROD-ADM-003`–`PROD-ADM-004`, `PROD-OPS-001`–`PROD-OPS-004`, `PROD-SUC-003`, `PROD-SUC-005`, `PROD-SUC-007`, `PAY-001`–`PAY-005`, `PAY-STATE-001`–`PAY-STATE-004`, `QA-JRN-005`, `QA-JRN-006`, `QA-JRN-009`, and `QA-CPR-001`–`QA-CPR-005`.
- Database verification: the migration was applied with `PGPASSWORD=<local-only> psql -h 127.0.0.1 -p 54322 -U postgres -d postgres -v ON_ERROR_STOP=1 -f supabase/migrations/20260813051840_w06_coach_experience.sql`; pass. `API_URL=<local> PUBLISHABLE_KEY=<local> SECRET_KEY=<local> npx vitest run tests/integration/coach-experience.local.test.ts`; 1 passed. It covers every price band, incomplete/Member/already-Coach cases, atomic activation, rejection reason/idempotency/race, cross-Coach workspace and media denial, hidden public fields/IDs/QR, unknown handle, and entitlement expiry.
- Web verification: `npm run typecheck`, `npm run lint`, `npm test`, `npm run build`, `npm run verify:bundle`, `npm run verify:pwa`, and local-env `npx playwright test tests/e2e/coach-experience.spec.ts`; pass. Full Vitest: 92 passed and 5 environment-skipped. W06 E2E: 6 passed across desktop and compact projects, including real provider-photo import/normalization, six-action navigation, responsive overflow checks, public partial profile, hidden contacts/identifiers, and safe unknown handle. Production output contains 39 split JavaScript files and valid PWA assets.
- Policy/scope: accepted product eligibility/pricing and the W05 manual-payment policy were used unchanged. W07 owns Admin moderation operations UI and W08 owns dynamic per-handle Open Graph/Cloudflare metadata; W06 records their contract without claiming them complete. The local payment destination was restored to BCA `0263313841`, Ni Wayan Sudarmi after tests. Historical failed-run W06 audit fixtures remain immutable/retired and cannot become active. No hosted deployment, production Supabase mutation, Git mutation, package-manifest change, or Xcode project/native-source change was performed.
- Remaining blockers: none for local W06. Production Admin identities, production payment destination/deployment, and real testimonial/subject-permission content remain intentionally unauthorized inputs for later release work. Next phase: W07 Admin operations.

### 2026-08-13 — Compact quick-action parity refinement

- Updated `src/features/coach/CoachWorkspaceComponents.tsx` so the compact Coach Dashboard uses the accepted iOS 3×2 quick-action grid instead of one oversized card per row. The six-action order and routes are unchanged. Compact cards now use a neutral icon, short red action accent, two-line centered label, distinct yellow pending-review badge, red participant-count badge, and a visible pressed scale state while retaining a touch surface well above 44×44 px.
- Added stable quick-action test IDs and extended `tests/e2e/coach-experience.spec.ts` with geometry assertions for six cards, equal rows, two-row separation, minimum dimensions, compact/wide navigation, and no horizontal overflow.
- Assumption: the supplied current iOS Dashboard screenshot is the accepted compact layout reference; this change matches its hierarchy and card anatomy without changing W06 behavior or data contracts.
- Build and static verification: `npm run typecheck`, `npm run lint`, and `npm run build`; pass. Focused unit verification: `npm test -- --run tests/unit/coach-experience-contract.test.ts`; 4 passed.
- Browser verification: local-env `npx playwright test tests/e2e/coach-experience.spec.ts`; 6 passed across compact and desktop projects, including action navigation. The in-app browser loaded the production bundle with no console warning/error but had no Coach session, so authenticated visual parity was verified in the already-authenticated Chrome Android emulator at `http://127.0.0.1:4173/coach`; the rendered grid is 3×2 with no clipping or bottom-navigation overlap.
- Files changed in this refinement: `src/features/coach/CoachWorkspaceComponents.tsx`, `tests/e2e/coach-experience.spec.ts`, and this progress log. No migration, package manifest, deployment, production Supabase, native source, Xcode project, or Git mutation was performed. Remaining blockers: none for this compact-layout refinement.

### 2026-08-13 — Coach program-participation parity correction

- Corrected the Coach Program tab after rereading the native source and the user-confirmed product rule. Native `RoleAppShellView` constructs `ParticipantJourneyStore(participationAccount: .coach)`, `ParticipantTabRootView` renders the same `ParticipantProgramCatalogView`, and Coach detail/join/step routes render the same Participant views with Coach navigation context. The web route now re-exports that shared catalog instead of rendering an invented `Program yang Anda dampingi` workspace.
- Coach now receives the same `Diikuti`, `Tersedia`, and `Riwayat` catalog; shared program detail, Coach QR scan, free/paid enrollment, manual payment, activity, evidence, weight, score, and limit rules remain one flow. Segment navigation retains `/coach/programs` and replaces the query state so repeated tab changes do not stack duplicate catalog routes.
- Private participation reads are explicitly scoped to the authenticated account's own `participant_id` and own enrollment IDs. This prevents RLS-visible assigned-Participant rows from being mistaken for the Coach's personal enrollments, submissions, or scores while preserving the separate `Peserta saya`, activity, review, and leaderboard workspace.
- Added local migration `supabase/migrations/20260813062314_w06_coach_program_participation.sql`. `enroll_free_program` now accepts Participant or Coach actors and preserves the same publication/deadline/capacity/duplicate checks. A Participant scans the selected Coach QR as before; a Coach must scan their own active QR and another Coach's QR is rejected. If the Coach still has a historical `current_coach_id` from their Participant period, successful self-enrollment replaces it with their own Coach identity without weakening the Participant mismatch rule. `get_my_assigned_coach` returns the Coach's own identity for their program participation. The W05 paid-order authority is overridden with the same own-QR rule while retaining its reservation, destination, capacity, and idempotency contract.
- Requirements clarified: `PROD-CCH-013` and the Coach Program parity row in `02_UX_PARITY_AND_ROUTES.md` now make the shared-flow rule explicit. Main implementation files: `src/app/coach/programs.tsx`, `src/app/app/programs.tsx`, `src/app/app/programs/[programId].tsx`, `src/app/app/payments/[programId].tsx`, `src/features/participant/participant-repository.ts`, and the W06 migration. Removed the obsolete Coach workspace program screen from `CoachWorkspaceComponents.tsx`.
- Database command: `PGPASSWORD=<local-only> psql -h 127.0.0.1 -p 54322 -U postgres -d postgres -v ON_ERROR_STOP=1 -f MSCWEB/supabase/migrations/20260813062314_w06_coach_program_participation.sql`; pass. Integration command: local-env `npx vitest run tests/integration/coach-experience.local.test.ts tests/integration/participant-program.local.test.ts tests/integration/manual-payment.local.test.ts`; 3 passed, including rejection of another Coach's QR, own-QR enrollment replacing a historical Participant-era Coach assignment, idempotent duplicate enrollment, self-assigned Coach read, own-QR paid-order reservation, workspace scope, and unchanged Participant/payment behavior.
- Web verification: `npm run typecheck`, `npm run lint`, `npm test -- --run`, `npm run build`, `npm run verify:bundle`, `npm run verify:pwa`, and local-env `npx playwright test tests/e2e/coach-experience.spec.ts`; pass. Vitest: 93 passed and 5 environment-skipped. W06 E2E: 6 passed across compact and desktop. The production verifier found 38 split JavaScript files and valid PWA assets. Android Chrome emulator inspection confirmed the Coach shell renders the shared segmented catalog with no `Program yang Anda dampingi` copy, then opened the enrollment screen and verified the visible rule `Pindai QR Coach milikmu sendiri` plus `QR Coach lain tidak dapat digunakan`. Server, Android emulator, Colima, and Supabase local were left running.
- No hosted deployment, production Supabase mutation, package-manifest change, native iOS/Xcode change, or Git mutation was performed. Remaining blockers: none for this parity correction; W07 remains the next phase.

### 2026-08-13 — Periksa bukti/detail parity refinement

- Reread native `Features/Coach/CoachReviewQueueView.swift` and matched the web Coach review hierarchy to the accepted iOS reference: `Periksa bukti`, `Perlu tindakan`/`Semua bukti`, one filter-summary surface, program/status filter sheet, searchable `Riwayat program`, compact participant evidence cards, verification/point banner, Participant/program/day/step/instruction context, submitted answers/private photo/quiz result, and sticky reject/approve actions. The iOS star/`Penilaian Coach` concept is intentionally absent by explicit product direction because MSCWEB uses a different rating model.
- Extended the review read model/repository with step instructions and verification mode, program end/timezone/activity points, selected-option titles, and quiz results. Private photos still use short-lived authorized Storage URLs; raw object paths are never rendered. Pending Coach review, automatic points, approved, and rejected states have distinct Indonesian labels and non-color-only icons.
- Added repeatable local preview data in `scripts/ensure-coach-review-preview.mjs`: two pending Coach-review items, one automatic-points item, one rejected historical item, and a real Participant-authorized private JPEG upload. `COACH_PREVIEW_ID` can target the already-authenticated local Coach without embedding an account identifier in production code. The fixture is restricted to localhost and is idempotent across repeated runs.
- Main files: `src/features/coach/CoachReviewComponents.tsx`, `coach-review-{models,repository}.ts`, `src/app/coach/reviews/{index,[submissionId]}.tsx`, `src/shared/icons/MSCIcon.tsx`, `scripts/ensure-coach-review-preview.mjs`, `tests/unit/{coach-experience-contract,evidence-review-contract}.test.ts`, and `tests/e2e/evidence-review.spec.ts`.
- Static/test verification: local-env `npm run typecheck`, `npm run lint`, and `npm test -- --run`; pass. Vitest: 100 passed, including the five local Supabase integration tests. Production verification: `npm run build`, `npm run verify:bundle`, and `npm run verify:pwa`; pass with 38 split JavaScript files and valid PWA assets.
- Authenticated E2E command: local-env `npx playwright test tests/e2e/evidence-review.spec.ts --workers=1`; 4 passed across desktop and compact projects. Coverage includes normalized private photo submission, filter/history sheet with no Coach-rating section, instruction/photo detail, image expansion, authoritative one-time approval/points, mandatory rejection reason, and Participant-visible correction copy. The run also caught and fixed an invalid `Intl.DateTimeFormat` option combination before final verification.
- Android Chrome inspection at `http://127.0.0.1:4173/coach/reviews` confirmed the current production bundle renders the iOS-derived list, filter sheet, historical-program entry, private-photo detail, and sticky `Tolak bukti` / `Setujui • 10 poin` actions without horizontal overflow or bottom-navigation overlap. Deliberate web adaptations are the persistent app header/bottom navigation and omission of stars. Server, Android emulator, Colima, and Supabase local were left running.
- No hosted deployment, production Supabase mutation, package-manifest change, native iOS/Xcode change, or Git mutation was performed. Remaining blockers: none for this W06 parity refinement; W07 remains the next phase.

### 2026-08-13 — Navigasi kembali dari Periksa bukti

- Added the full-width secondary `Kembali ke dashboard` action above the review scope/filter controls in `src/features/coach/CoachReviewComponents.tsx`. It uses the shared back icon/button treatment and replaces the route with `/coach`, so the action always returns to the Coach Dashboard rather than an arbitrary browser-history entry.
- Verification: `npm run typecheck`, `npm run lint`, focused `npm test -- --run tests/unit/coach-experience-contract.test.ts` (7 passed), and `npm run build`; pass. Local authenticated `npx playwright test tests/e2e/evidence-review.spec.ts --workers=1 --grep "Participant submits"`; 2 passed across desktop and compact, including the Dashboard navigation assertion.
- Android Chrome inspection matched the supplied button reference and confirmed tapping it opens the authenticated Coach Dashboard. The in-app browser bundle had no console warnings/errors but lacked a Coach session, so authenticated rendered interaction was verified in the existing Android emulator session. Server, emulator, Colima, and Supabase local remain running; no deployment, package, native/Xcode, production Supabase, or Git mutation was performed.

### 2026-08-13 — Peserta saya/detail parity refinement

- Reread native `Features/Coach/CoachParticipantsView.swift`, `CoachParticipantDetailView.swift`, `CoachPresentation.swift`, `CoachDashboardState.swift`, and `CoachDataService.swift`. Matched the web hierarchy to the accepted iOS capability: unique assigned-Participant directory, total/attention metrics, name/city search, program/history/completion/sort filter sheet, progress/activity/attention cards, and Participant detail with identity, current program, progress, private weight history, points/days/evidence summary, recent activity, evidence list, and expandable daily step progress. The existing `Kembali ke dashboard` action remains above the directory.
- Added locally authorized read functions in `supabase/migrations/20260813095648_w06_coach_participant_directory_detail.sql`. Both functions require an active Coach entitlement, scope every Participant/enrollment/submission/weight row to the calling Coach assignment, collapse multiple enrollments into one Participant directory entry, and reject cross-Coach detail reads. Completed enrollment progress is consistently reported as 100%, and current day is capped to the program's available days.
- Main files: `src/features/coach/CoachParticipantComponents.tsx`, `coach-experience-{models,repository,queries}.ts`, routes `src/app/coach/participants.tsx` and `src/app/coach/participants/[participantId].tsx`, `scripts/ensure-coach-review-preview.mjs`, `scripts/serve-production.mjs`, `worker/index.ts`, W06 unit/integration/E2E tests, and this workplan. Production routing now recognizes direct `/coach/participants/:participantId` UUID deep links in both the local server and Cloudflare Worker mirror.
- Assumptions: the supplied iOS screens are the accepted compact reference; data counts, participant names, program titles, weight entries, and number of program days remain authoritative/data-driven rather than hardcoded to screenshot fixtures. Participant weight remains sensitive but is visible only to the assigned active Coach through the protected function. No native iOS file was changed.
- Verification: `npm run typecheck`, `npm run lint`, `npm test -- --run`, `npm run build`, `npm run verify:bundle`, and `npm run verify:pwa`; pass. Full Vitest: 96 passed and 5 environment-skipped. Local Supabase integration: `npx vitest run tests/integration/coach-experience.local.test.ts`; 1 passed, including cross-Coach denial. Authenticated Playwright: `npx playwright test tests/e2e/coach-experience.spec.ts`; 6 passed across compact and desktop. Production output contains 39 split JavaScript files and valid PWA assets.
- Visual verification: the Codex in-app browser loaded the route with no console errors and correctly denied its non-Coach session. The authenticated Android Chrome emulator then verified the directory, iOS-style filter sheet, internal participant navigation, and detail hierarchy with no horizontal overflow or bottom-navigation obstruction. A direct detail reload initially exposed a production-route 404; the server/Worker route fix above resolved it before final verification. Server, Android emulator, Colima, and Supabase local remain running.
- Remaining blockers: none for this W06 parity refinement. No hosted deployment, production Supabase mutation, package-manifest change, native/Xcode change, or Git mutation was performed; W07 remains the next phase.

### 2026-08-14 — Aktivitas terbaru parity refinement

- Reread native `Features/Coach/CoachActivityView.swift`, `CoachActivityState.swift`, `CoachActivityPresentation.swift`, `CoachDataService.swift`, and shared `ProgramFilterViews.swift`. Replaced the web workspace's submission-only cards with the native capability: grouped Indonesian date sections, Participant avatar/name, relative time, evidence/step/joined/completed event copy, non-color-only status or points badges, chevrons, and a default `Hari ini` scope with `Aktivitas sebelumnya` expansion.
- Added the iOS-equivalent `Filter aktivitas` sheet with current programs, searchable `Riwayat program`, `Bukti dikirim`, `Langkah selesai`, `Peserta bergabung`, `Program selesai`, and `Hari ini`/7/30-day ranges. Pending Coach-review activity opens the review queue; other activity opens the scoped Participant detail and preserves the enrollment context. The existing full-width `Kembali ke dashboard` action remains above the filter.
- Added `supabase/migrations/20260814031900_w06_coach_activity_feed.sql` and the `CoachActivityFeed` model/repository/query boundary. The function requires an authenticated caller with an active Coach entitlement, scopes every union branch by `enrollment.coach_id = caller_id`, excludes drafts, limits output to 30 days, revokes anonymous/public execution, and returns no raw QR, weight, answer, or private-media path. Local integration covers all four event kinds, automatic points, pending-review state, and an empty feed for a different active Coach.
- Main implementation files: `src/features/coach/CoachActivityComponents.tsx`, `coach-experience-{models,repository,queries}.ts`, `src/app/coach/activity.tsx`, `CoachWorkspaceComponents.tsx`, W06 unit/integration/E2E tests, the W06 local migration, and this progress log. No native file was changed.
- Verification: `npm run typecheck`, `npm run lint -- --no-cache`, `npx vitest run tests/unit/coach-experience-contract.test.ts` (9 passed), local-env `npx vitest run tests/integration/coach-experience.local.test.ts` (1 passed), `npm run build`, and local-env `npx playwright test tests/e2e/coach-experience.spec.ts --project=chromium-compact` (3 passed). The E2E flow exercises the filter sheet, pending evidence → review queue, and completed step → Participant detail.
- Visual verification: the in-app browser correctly denied its non-Coach session. The authenticated Android Chrome emulator verified the production bundle's empty-today state, 30-day grouped activity rows, current/history program filter, all four activity filters, sticky reset/apply actions, and bottom-navigation clearance against the accepted iOS screenshots. Server, Android emulator, Colima, and Supabase local remain running.
- Remaining blockers: none for this W06 parity refinement. No hosted deployment, production Supabase mutation, package-manifest/lockfile change, native/Xcode change, or Git mutation was performed; W07 remains the next phase.

### 2026-08-14 — Shared Participant/Coach leaderboard parity refinement

- Reread native `Features/Coach/CoachLeaderboardView.swift`, `Features/Participant/ParticipantLeaderboardView.swift`, and their shared leaderboard presentation/components. Replaced the separate simple web lists with one shared Participant/Coach experience: program/date summary, active/completed and locked-result copy, program-history selection, 2–1–3 podium with crown and gold/silver/bronze treatment, explicit tie state, current-user/assigned markers, and compact rank-4+ rows designed for long lists. Participant and Coach routes now render the same visual and scoring hierarchy.
- Coach-only behavior follows the native rule: a leaderboard entry opens `Rincian poin` only when that Participant is assigned to the authenticated Coach. The detail sheet shows rank, total points, step points, weight-loss points, adjustments, and progress without exposing body-weight values. Global names/rank/points/progress remain visible, while avatar and point breakdown are returned only for assigned Participants. Participant leaderboard entries remain non-interactive.
- Added local migration `supabase/migrations/20260814040500_w06_shared_leaderboard.sql` with `get_my_coach_leaderboard`. It requires an authenticated active Coach entitlement, grants execution only to `authenticated`, and conditionally reveals assigned-only detail fields. A second active Coach integration fixture proves the assignment boundary symmetrically. Main web files: `src/features/leaderboard/LeaderboardExperience.tsx`, Participant/Coach leaderboard routes, `coach-experience-{models,repository,queries}.ts`, shared design tokens/icons, and W06 unit/integration/E2E tests. No native file was changed.
- Verification: `npm run typecheck`, `npm run lint -- --no-cache`, `npm test`, `npm run build`, `npm run verify:bundle`, and `npm run verify:pwa`; pass. Vitest: 98 passed and 5 environment-skipped. Local-env `npx vitest run tests/integration/coach-experience.local.test.ts`; 1 passed. Local-env `npx playwright test tests/e2e/coach-experience.spec.ts`; 6 passed across compact and desktop, including podium geometry, history selection, assigned-only click behavior, score privacy, and no horizontal overflow.
- Visual verification: the Codex in-app browser rendered a compact public leaderboard with 86 local score rows, podium/tie/list states, and no console warnings or errors. Authenticated Android Chrome rendered the Coach podium and `Pesertamu` marker; tapping that assigned entry opened the private `Rincian poin` sheet. Non-assigned rows remain inert by E2E and RPC authorization tests. Server, Android emulator, Colima, and Supabase local remain running.
- Requirements exercised: `PROD-SUC-003`, `PROD-SUC-005`, `PROD-SUC-007`, `PROD-CCH-004`, `PROD-CCH-008`, `PROD-OPS-001`, and `QA-JRN-006`. No hosted deployment, production Supabase mutation, package-manifest/lockfile change, native/Xcode change, or Git mutation was performed. Remaining blockers: none for this W06 refinement; W07 remains the next phase.

### 2026-08-14 — Ringkasan pendampingan Dashboard parity refinement

- Reread native `Features/Coach/CoachDashboardView.swift`, `CoachPresentation.swift`, and `CoachDataService.swift`. Replaced the web Dashboard's invented `Ringkasan` grid (`Peserta`, `Perlu diperiksa`, total `Program`, and access-expiry copy) with the accepted iOS `Ringkasan pendampingan`: three equal horizontal metrics for assigned Participants, average progress, and active programs, separated by vertical dividers and paired with the native-equivalent people, progress, and running icons. The duplicate Dashboard subtitle was removed so the section title appears only once, as on iOS.
- Average progress follows the native presentation rule: one primary enrollment per assigned Participant, preferring an active enrollment, then integer-floor averaging. The program metric counts only active programs rather than all historical programs. Values remain live workspace data; the authenticated Android fixture rendered `3 peserta`, `45% progres`, and `2 program aktif`.
- Main files: `src/features/coach/CoachWorkspaceComponents.tsx`, `src/shared/icons/MSCIcon.tsx`, `src/app/coach/index.tsx`, `tests/unit/coach-experience-contract.test.ts`, `tests/e2e/coach-experience.spec.ts`, and this progress log. E2E now asserts exact Indonesian accessible labels, three equal aligned columns on compact and desktop viewports, and minimum metric touch/read geometry.
- Verification: `npm run typecheck`, `npm run lint -- --no-cache`, `npm test -- --run` (99 passed, 5 environment-skipped), `npm run build`, `npm run verify:bundle` (39 split JavaScript files), and `npm run verify:pwa`; pass. Local-env `npx playwright test tests/e2e/coach-experience.spec.ts`; 6 passed across compact and desktop. The first E2E run exposed unequal accessible metric heights; adding a shared stretched minimum height resolved the compact alignment before the final pass.
- Visual verification: the Codex in-app browser loaded the final production bundle and correctly denied its non-Coach session without the former duplicate subtitle. The authenticated Android Chrome emulator was compared directly with the accepted iOS reference and confirmed the title, horizontal 3-column structure, icon/value/label order, dividers, neutral card, and bottom-navigation clearance. Server, Android emulator, Colima, and Supabase local remain running.
- No migration, package-manifest/lockfile change, hosted deployment, production Supabase mutation, native/Xcode change, or Git mutation was performed. Remaining blockers: none for this W06 parity refinement; W07 remains the next phase.

### 2026-08-14 — Ringkasan pendampingan density refinement

- Slimmed the existing iOS-parity summary card in `src/features/coach/CoachWorkspaceComponents.tsx`: inner minimum height changed from 132 to 104 px, each aligned metric from 112 to 88 px, divider from 82 to 64 px, metric gap from 8 to 4 px, and value type from 30/35 to 28/32 px. Copy, icons, live calculations, accessibility labels, three-column order, and outer shared Card treatment remain unchanged.
- Updated `tests/e2e/coach-experience.spec.ts` to require the three metrics to remain equally aligned while enforcing the new compact 88–112 px metric-height envelope.
- Verification: `npm run typecheck`, `npm run lint -- --no-cache`, focused Vitest (11 passed), `npm run build`, bundle/PWA verifiers, and local-env Coach Playwright (6 passed across compact and desktop). Browser/IAB loaded desktop and 390×844 shells with no warnings/errors and verified Dashboard → Program navigation. Authenticated Android Chrome confirmed the card is visibly shorter, labels remain one line, dividers remain centered, and there is no horizontal or bottom-navigation overlap.
- The supplied reference and final Android screenshot were inspected together for copy, three-column structure, typography hierarchy, icon alignment, divider height, white/neutral palette, radius/border, and compact spacing. No remaining material visual mismatch was found. Server, Android emulator, Colima, and Supabase local remain running; no deployment, native/Xcode, production Supabase, package, or Git mutation was performed.
