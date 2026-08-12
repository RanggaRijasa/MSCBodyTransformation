# Phase 11A Slice 11A.0 — Functional Freeze and Pre-redesign Baseline

> Captured: 11 August 2026 (Asia/Jakarta)  
> Scope: read-only audit of the current `MSCWeb` implementation.  
> Status: baseline frozen; this document is not visual approval and the current web UI is not design direction.

## Freeze decision

Phase 11A is presentation-only. The following remain authoritative and must not change in behavior while the UI is replaced:

- route paths, links, browser back/history, redirects, callbacks, payload fields, form semantics, retry order, and mutation order;
- Guest-as-logged-out behavior, verified profile/role routing, authorization, idempotency, validation, rate limiting, privacy, private-media, cache, and service-worker boundaries;
- all loading, empty, error, offline, denied, pending, rejected, conflict, retry, success, expired, and unavailable states that exist below;
- application operations, domain services, repository interfaces/adapters, route handlers, proxy/security/config, local Supabase contract, root Supabase, and root Contracts.

No backend mutation, production access, dependency install, snapshot update, Git operation, deployment, or file outside `MSCWeb` was used to create this baseline.

## Quantitative baseline

Counts were taken directly from the current tree before the redesign.

| Inventory | Baseline | Method / note |
|---|---:|---|
| Page surfaces | 35 | `find src/app -name page.tsx -type f` |
| Route handler files | 27 | `find src/app -name route.ts -type f` |
| Exported HTTP handler methods | 30 | 7 GET, 19 POST, 2 PATCH, 2 DELETE |
| CSS files under `src` | 20 | All handwritten |
| Handwritten CSS lines | 4,419 | `wc -l` across the 20 files |
| Root-global stylesheet imports | 19 | Every feature/shared stylesheet is imported by `src/app/globals.css` |
| Built global CSS | 81,715 B raw / 14,653 B gzip | Clean `next build`, one emitted CSS chunk |
| React TSX files | 138 | `src/**/*.tsx` |
| TypeScript files | 141 | `src/**/*.ts` |
| Client-boundary files | 37 | Files beginning with `use client` |
| Native `<form>` sites | 24 | Includes GET, POST, and Server Action forms |
| Shared `FilterForm` sites | 3 | Total rendered form sites: 27 |
| Server Actions | 17 | All in `application/admin/admin-mutations.ts` |
| Visual PNG baselines | 27 | 3 shell + 5 landing + 19 gallery |
| Test files by standard suffix | 51 | 23 unit, 12 component, 15 E2E, 1 gallery |
| Additional executable integration runners | 3 | Phase 04 orphan cleanup, Phase 05 race, Phase 06 payment |

### CSS size and delivery baseline

| Stylesheet | Lines | Gate implication |
|---|---:|---|
| `features/landing/styles/landing-sections.css` | 510 | Blocking split target (>500) |
| `shared/ui/styles/components.css` | 454 | Mandatory review/split (>400) |
| `features/landing/styles/landing-responsive.css` | 440 | Mandatory review/split (>400) |
| `features/landing/styles/landing.css` | 384 | Large, must become landing-scoped |
| `features/admin/styles/admin.css` | 352 | Split by Admin surface during 11A.9 |
| `features/participant/styles/participant.css` | 340 | Split by Peserta capability during 11A.7 |
| `shared/ui/styles/shells.css` | 284 | Serialized shell owner |
| `features/coach/styles/coach.css` | 260 | Split by Coach capability during 11A.8 |
| Remaining 12 stylesheets | 1,395 | Each is below 250 lines |

Current delivery is intentionally recorded as a defect baseline: `src/app/layout.tsx` imports `globals.css`, and `globals.css` imports all 19 shared, landing, Auth, media, Program, Payment, Peserta, Coach, Admin, Push, and PWA runtime stylesheets. Consequently every route receives the whole product stylesheet.

Closure strategy is frozen as follows:

1. Define Tailwind order explicitly as `@layer theme, base, components, utilities`; utilities/components consume MSC semantic variables rather than arbitrary brand values.
2. Disable/omit Tailwind Preflight for the initial pilot until every raw control, list, table, media, and dialog surface is audited.
3. Keep only tokens, audited base semantics, safe-area, focus, motion/accessibility, glass fallback, and genuinely cross-role primitives global.
4. Load landing, Auth, Peserta, Coach, and Admin CSS from their route-group layout or feature entry boundary; cross-role Payments/Programs/Media/PWA styling has one serialized owner.
5. Do not retain legacy and new design systems as parallel production layers. Remove a legacy selector only after caller search is zero and focused regression passes.
6. Add `.css` to the handwritten file-size gate in the foundation slice; no handwritten CSS file may remain above 500 lines, and every file above 400 lines requires split/review.

### Phase 11A file-size closure addendum

The production gate now scans `.css` together with TypeScript/JavaScript and
normalizes a terminal newline so an exact 500-line file is reviewed rather than
incorrectly blocked as 501. The baseline targets were split by surface:

- `landing-sections.css` became section/audience rules plus
  `landing-results.css`;
- `landing-responsive.css` became general responsive rules plus
  `landing-narrow.css`;
- the former shared `components.css` was split into actions, forms, status,
  surfaces, and remaining media/identity rules;
- Admin and Coach styles were split by their owned dashboard/workflow surfaces.

`check:file-size` passes with no handwritten file above 500 lines. Files in the
401–500 review band remain explicit reviewer items and are not silently treated
as small files.

## Clean build and performance baseline

Pinned runtime used: Node `24.19.0`, pnpm `11.21.0`. In this sandbox, the Corepack shim attempted a registry lookup/cache write, so the already-cached pinned pnpm executable was invoked directly; package versions and lockfile were not changed.

| Gate | Exact result |
|---|---|
| `format:check` | PASS — all files match Prettier |
| `lint` | PASS — architecture, file size, public secret, localization, and ESLint gates passed; six existing 400–475 line files remain REVIEW findings, none >500 |
| `typecheck` | PASS — `tsc --noEmit` |
| `test` | PASS — 35 Vitest files, 163 tests |
| `build` | PASS — Next 16.3.0/Turbopack, 40 static pages generated and all dynamic routes validated |
| Phase 04 bundle gate | PASS — media chunks 15,931–33,980 B; landing remains split |
| Phase 11 performance gate | PASS |
| Phase 11 security/cache/metadata gate | PASS |
| Public secret/hosted URL gate | PASS |

Representative route payload baseline from the clean build:

| Representative surface | gzip baseline | Existing Phase 11 hard budget | Phase 11A unapproved delta budget |
|---|---:|---:|---:|
| Landing | 102.0 KiB | 280 KiB | +10 KiB |
| Peserta | 112.0 KiB | 300 KiB | +10 KiB |
| Coach | 103.8 KiB | 300 KiB | +10 KiB |
| Admin | 111.7 KiB | 300 KiB | +10 KiB |
| Global CSS | 14.31 KiB gzip | clean baseline | +5 KiB |

Image baseline: Participant release candidate 59.1 KiB (100 KiB budget); Coach release candidate 155.1 KiB (200 KiB budget).

Phase 11 accessibility evidence remains a historical baseline only: Chromium/WebKit axe coverage, keyboard checks, dark/contrast/reduced-motion/zoom coverage, and zero serious/critical axe findings were recorded in `docs/testing/PHASE_11_BROWSER_DEVICE_EVIDENCE.md`. Slice 11A must rerun it on redesigned production routes.

## Visual baseline status (no snapshot update)

The 27 existing PNGs freeze the pre-redesign appearance only. They must never be used as the visual direction or accepted concept.

- Shell visual suite: 3 PNGs (Peserta light/dark and Admin desktop).
- Landing visual suite: 5 PNGs (desktop, mobile light/dark, tablet dark, 320 px large text).
- Gallery: 19 PNGs (Program, Payment, Peserta, Coach, Admin, QR, and safe marketing captures; Chromium/WebKit where present).

Non-updating verification found intentional baseline debt:

- combined shell/landing Chromium visual run: 5/8 passed. All five landing snapshots passed; Peserta light and dark each drifted by about 4%, and Admin encountered a dev-navigation timing failure;
- full Chromium/WebKit gallery: 29/30 passed, including axe/keyboard/privacy assertions; the WebKit marketing-Peserta capture differed by 491 pixels (~1%), localized to text rasterization. No snapshot was updated.

These are baseline findings, not accepted redesign output. They must be replaced only after concept/reference review and then rerun without `--update-snapshots`.

## Page surface inventory (35)

`Boundary / function` names the entry behavior that must remain; visual composition may change.

| Actor | Route | Boundary / function that is frozen |
|---|---|---|
| Landing | `/` | Trusted landing actor + public-safe teaser, truthful install CTA state |
| Public | `/bantuan` | Public information page |
| Public | `/ketentuan` | Public legal page |
| Public | `/privasi` | Public privacy page |
| Auth | `/masuk` | Safe `returnTo`, Google start, provider/config/status errors |
| Auth | `/daftar` | Register presentation through shared Auth page |
| Auth | `/lupa-password` | Generic reset response; enumeration-safe copy |
| Auth | `/onboarding` | Verified provisional profile + onboarding form/cleanup |
| Guest/Peserta | `/hari-ini` | Guest-safe or authenticated home; no Guest personal hydration |
| Guest/Peserta | `/program` | Public catalog + authenticated followed/history projection |
| Guest/Peserta | `/program/[programId]` | Offer or activity mode; validation -> 404 |
| Peserta | `/program/[programId]/gabung` | role gate, pending intent revalidation, availability, QR flow, redirect if already enrolled |
| Peserta | `/program/[programId]/langkah/[stepId]` | participant step load, validation -> 404, answer/weight flow |
| Peserta | `/pembayaran/[paymentId]` | verified profile, owner-only order, missing/denied -> 404 |
| Guest/Peserta | `/peringkat` | public-safe/participant ranking, program selector, final snapshot |
| Guest/Peserta | `/coach` | approved Coach directory and assigned marker |
| Peserta | `/profil` | verified profile, profile/avatar/Coach change/account lifecycle, Push settings |
| Peserta | `/akses-coach/[applicationId]` | Participant role gate + Coach access payment order entry |
| Coach | `/coach-area` | dashboard metrics, attention, activity quick paths |
| Coach | `/coach-area/program` | Program hub, activity and ranking presentation |
| Coach | `/coach-area/peserta` | assignment-scoped roster, search/filter/empty |
| Coach | `/coach-area/peserta/[participantId]` | assignment-scoped private detail, submissions and weigh-ins |
| Coach | `/coach-area/pemeriksaan` | review queue and inline decision/detail cards |
| Coach | `/coach-area/qr` | access-state gate + internal QR image/share |
| Coach | `/coach-area/profil` | verified profile, access lifecycle, public profile, Push settings |
| Admin | `/admin` | Admin role gate + dashboard/queue metrics |
| Admin | `/admin/pembayaran` | Admin role gate + filters, queue, payment destinations |
| Admin | `/admin/pembayaran/[paymentId]` | private evidence, history, decision/reason/confirmation |
| Admin | `/admin/program` | program filters/list |
| Admin | `/admin/program/baru` | new typed draft with generated ID |
| Admin | `/admin/program/[programId]` | detail, shared preview, closure/preflight/lifecycle actions |
| Admin | `/admin/program/[programId]/edit` | typed editor load/save, settings/content tabs |
| Admin | `/admin/orang` | role/search directory, Coach applications, controlled corrections |
| Admin | `/admin/konten` | winner poster gallery/upload/publish/delete + locked snapshots |
| Admin | `/admin/pengaturan` | runtime-safe settings, audit list, Push settings |

Shell navigation hrefs are frozen: Peserta `/hari-ini`, `/program`, `/peringkat`, `/coach`, `/profil`; Coach `/coach-area`, `/coach-area/program`, `/coach-area/profil`; Admin `/admin`, `/admin/pembayaran`, `/admin/program`, `/admin/orang`, `/admin/konten`, `/admin/pengaturan`.

## Route reconciliation decisions

These decisions describe the implementation that already exists; they do not authorize new capability.

| Documentation gap | Actual implementation decision for Phase 11A |
|---|---|
| `/coach/[coachId]` absent | It remains absent; `/coach` currently renders approved Coach cards, and Phase 11A adds no public Coach-detail capability or alias. |
| `/profil/edit` absent | Edit name/phone/avatar stays on the combined canonical `/profil` page; a sheet/dialog presentation may be used without creating a route. |
| `/profil/ganti-coach` absent | Coach change stays on `/profil` using the QR sheet/dialog and confirmation. No typed-code fallback or route is added. |
| `/akun/hapus` absent | Account deletion stays on `/profil` using an irreversible dialog/confirmation and the existing API boundary. |
| `/coach-area/aktivitas` absent | Activity is part of canonical `/coach-area/program`; do not invent a route. |
| `/coach-area/peringkat` absent | Ranking is part of canonical `/coach-area/program`; do not invent a route. |
| separate Coach review detail absent | `/coach-area/pemeriksaan` contains inline review/detail cards and decision actions. |
| `/admin/orang/[userId]` absent | It remains absent; `/admin/orang` is the existing directory/controlled-operation surface and Phase 11A adds no person-detail capability or alias. |
| `/admin/audit` absent | Audit is the existing anchor `/admin/pengaturan#audit`; no alias route exists. |
| granular Admin settings/content routes absent | `/admin/pengaturan` and `/admin/konten` are canonical actual routes. |
| granular Admin Program settings/content/preview routes absent | `/admin/program/[programId]/edit` uses in-page tabs; `/admin/program/[programId]` holds preview/lifecycle. |
| `/lupa-kata-sandi` documented | `/lupa-password` is the only canonical actual route. No redirect alias exists; parity docs/concepts must use it. |
| `/pengajuan-coach` documented | Coach application is embedded in onboarding; payment continuation is `/akses-coach/[applicationId]`. No alias exists. |

## Form, action, and dialog freeze

### Forms and mutations

Rendered form sites comprise 24 literal forms plus 3 shared filter forms. The required behaviors are:

- Auth/Profile: onboarding submit and provisional cancel; update profile; avatar upload; Coach QR change; logout; reauthentication link; account delete with recent-auth and cleanup errors.
- Program/Enrollment: Guest pending-program intent; Coach QR preflight; free enrollment or paid order creation; capacity/deadline/duplicate/conflict/offline handling.
- Peserta: prepare submission -> upload private photo(s) -> submit answers in that exact order; server-authoritative quiz result; initial/daily/final weigh-in; payment evidence upload/correction/retry.
- Coach: roster/review filters; approve/reject submission with rejection reason, idempotency key, score reconciliation, multi-tab conflict message; public profile update; QR share/download fallback.
- Admin: payment filters/approval/rejection and confirmation; payment destination creation; cancel/reversal with reason; Program filter/save/publish/duplicate/complete/reopen/lock winners/archive/reopen quiz; people filters; Coach application decision; manual enrollment; Coach transfer; weigh-in correction; score adjustment; poster upload/replace/publish/delete.
- PWA: install prompt/guidance/dismiss/standalone, Push enable/disable, offline retry, and explicit update apply.

All 17 Admin Server Actions remain the authoritative presentation boundary: `publishProgramAction`, `completeProgramAction`, `lockWinnersAction`, `archiveProgramAction`, `reopenProgramAction`, `reopenQuizAttemptAction`, `duplicateProgramAction`, `saveProgramDraftAction`, `decideCoachApplicationAction`, `adjustScoreAction`, `enrollParticipantAction`, `transferCoachAction`, `correctWeighInAction`, `managePosterAction`, `createPaymentDestinationAction`, `cancelPaymentOrderAction`, and `recordExceptionalReversalAction`.

### Dialog/overlay contract

- shared native `<dialog>`/`ModalDialog`: focus enters, Escape/backdrop/close works, history is preserved, focus restores;
- QR scanner dialog: onboarding, Program enrollment, and Coach change; permission denied/unavailable/error/close states; never expose manual code input;
- Camera capture dialog: opening/ready/permission-denied/unavailable/error/cancel/capture;
- install guidance dialog: iPhone/manual install instructions and dismissal;
- Admin payment approval custom `role="dialog"`: approve confirmation and cancel/focus behavior;
- browser irreversible confirmation currently used for account deletion and copy-day overwrite.

## Route-handler inventory (27 files / 30 methods)

Every path, method, payload field, status mapping, no-store header, authorization check, and operation call is hard-frozen.

| Route handler | Method(s) | Frozen operation |
|---|---|---|
| `/api/account/delete` | POST | account deletion |
| `/api/admin/content/posters` | POST | Admin-only private poster upload |
| `/api/admin/payments/[paymentId]/decision` | POST | approve/reject payment with reason/idempotency |
| `/api/coach-applications/[applicationId]/payment-order` | POST | Coach access payment order |
| `/api/coach/profile` | PATCH | public Coach profile update |
| `/api/coach/qr-image` | GET | private Coach QR SVG, no-store |
| `/api/coach/reviews/[submissionId]` | POST | assignment-scoped review |
| `/api/coach/submissions/[submissionId]/photos/[questionId]` | GET | assignment-scoped private photo |
| `/api/onboarding` | POST, DELETE | complete onboarding / cancel provisional identity |
| `/api/participant/submissions/photo` | POST | private question photo upload |
| `/api/participant/submissions/prepare` | POST | idempotent submission preparation |
| `/api/participant/submissions/submit` | POST | answer submission and scoring projection |
| `/api/participant/weigh-ins` | POST | typed weigh-in submission |
| `/api/payments/[paymentId]/evidence` | GET, POST | owner/Admin private evidence read/upload |
| `/api/payments/[paymentId]/qris` | GET | authorized QRIS download |
| `/api/profile/avatar` | POST | private avatar processing/update |
| `/api/profile/coach` | POST | QR-only Coach change |
| `/api/profile` | PATCH | profile update |
| `/api/programs/[programId]/coach-preflight` | POST | opaque QR validation |
| `/api/programs/[programId]/enroll/free` | POST | free enrollment |
| `/api/programs/[programId]/payment-order` | POST | paid Program order |
| `/api/push/subscriptions` | POST, DELETE | trusted-origin register/revoke |
| `/api/session` | GET | private verified session state |
| `/auth/callback` | GET | OAuth state/PKCE exchange and safe redirect |
| `/auth/google/start` | GET | sealed auth attempt and Google redirect |
| `/auth/intent/program` | POST | sealed pending Program intent and login redirect |
| `/auth/logout` | POST | sign out, cookie cleanup, client-state cleanup redirect |

## State inventory

| Capability | Material states that must remain |
|---|---|
| Route/shell | root/feature loading, empty, error with retry, not-found, Guest shell, authenticated role shell, safe-area, scroll restoration, route focus |
| Session/Auth | `guest`, `offline`, `expired`, `revoked`, `onboarding`, authenticated Participant/Coach/Admin, `stale_role`; provider pending/error/configuration and safe return |
| Install | `not-ready`, `prompt-ready`, `ios-guidance`, `manual-guidance`, `dismissed`, `standalone`, `unsupported` |
| PWA runtime | online, offline + retry, retrying, update available, update applying/activation, multi-tab notification, logout/account-state cleanup |
| Push | disabled, enabling, active, denied, unsupported, configuration-missing, error; iOS standalone requirement |
| Program catalog | Diikuti/Tersedia/Riwayat; scheduled/active/completed/archived; available/registration-closed/program-completed/unavailable |
| Day/step | available, locked, hidden, read-only; step available/pending/rejected/approved; article/video/form/quiz/photo/initial-daily-final weigh-in |
| Enrollment | ready, checking, Coach confirmation, submitting, complete, error/offline; already-enrolled, capacity-full, unavailable, registration-closed |
| Media | camera/QR checking/opening, ready/scanning, permission-denied, unavailable, error; image idle/processing/ready/error; upload idle/ready/uploading/failed(cancelled/conflict/offline/timeout/unknown)/uploaded |
| Video | loading, ready, waiting, offline, unsupported, error; watched threshold completion |
| Submission | draft validation, preparing, sequential photo upload, submitting, approved/pending/rejected, quiz pass/fail, conflict/multi-tab, abort/retry |
| Payment | awaiting-evidence, under-review, correction-required, approved, expired, cancelled, rejected, reversal-pending, reversed; upload offline/error/retry |
| Coach access | active, pending, rejected, expired, inactive; no cross-assignment private access |
| Coach attention/review | not-enrolled, not-started, falling-behind, on-track, complete; queue empty/filter; approve/reject/reason/busy/complete/conflict |
| Admin Program | draft/scheduled/active/completed/archived; validation, preview, publish, duplicate, complete, reopen, lock, archive, failed-quiz reopen |
| Admin people/content | role/search empty, application submitted/approved/rejected, controlled reason-required operations, poster draft/published/empty/upload/replace/delete |
| Global feedback | loading, empty, error, offline, denied, pending, rejected, conflict, retry, success are never collapsed into a generic state |

## Repository and security boundary freeze

The redesign must keep the dependency direction `route -> feature -> application operation -> domain/repository boundary -> Supabase/browser adapter`.

- Domain interfaces: `PublicProgramRepository`, `EnrollmentProjectionRepository`, `ParticipantExperienceRepository`, `PaymentRepository`, `ProgramPaymentOrderRepository`, and `ServiceHealthRepository`.
- Supabase adapters: Program/catalog/enrollment/participant; Payment owner/Admin/evidence/QRIS/destinations; Coach context/roster/detail/review/activity; Admin dashboard/people/audit/content/program/closure; verified actor/session clients.
- Browser adapters: QR decoder, camera/image processing, private upload lifecycle, video progress, service worker/install/Push.
- Application operation groups: Auth/pending intent; Program load/enrollment; Participant experience/profile/submission; Payment; Coach experience/review/profile; Admin reads/mutations/posters; Push; safe observability/rate limit.
- Hard-frozen security/config: `src/proxy.ts`, `src/shared/security/**`, `src/shared/config/**`, CSP nonce, trusted mutation origin, verified claims/role, private `no-store`, secret redaction, and `public/sw.js` cache allowlist/lifecycle.

No UI component may call Supabase directly or move authoritative role, scoring, enrollment, payment verification, or authorization into the browser.

## Test inventory that must remain mapped

### Unit (23)

`admin-program`, `application-dependencies`, `auth-flow`, `auth-model`, `coach-experience`, `deterministic-dependencies`, `environment`, `indonesian-formatters`, `landing-boundaries`, `leaderboard`, media image/QR/upload/video, `mutation-origin`, `participant-program`, Program catalog/content/progress, PWA install, rate limiter, server image validation, and session state.

### Component (12)

Admin experience, Auth pages, Coach experience, device-media workflows, device media, foundation status, landing/install, Participant experience, Payments, Programs, shared UI, and shell navigation.

### E2E and local integration (15 + 3 runners)

Phase 02 shells/visual; Phase 02A landing smoke/visual; Phase 03 Auth smoke/local; Phase 04 media smoke/local + orphan cleanup; Phase 05 local Programs + enrollment races; Phase 06 local Payments + manual-payment integration; Phase 07 Participant; Phase 08 Coach; Phase 09 Admin; Phase 10 cross-role; Phase 11 PWA quality. Full gallery is a separate suite.

The closure runners `test:phase03:local` through `test:phase11:local` remain mandatory. They may not be replaced by gallery or visual snapshots. This Slice 11A.0 audit did not run local phase runners because its work packet prohibited backend mutation; the orchestrator must run them at Slice 11A.11 against local Supabase only.

## Commands executed and results

Commands were run from `MSCWeb/`. `PNPM` below means:

```text
/opt/homebrew/opt/node@24/bin/node /Users/ranggarijasa/.cache/node/corepack/v1/pnpm/11.21.0/bin/pnpm.cjs
```

```text
PATH="/opt/homebrew/opt/node@24/bin:$PATH" $PNPM format:check                       PASS
PATH="/opt/homebrew/opt/node@24/bin:$PATH" $PNPM lint                               PASS
PATH="/opt/homebrew/opt/node@24/bin:$PATH" $PNPM typecheck                          PASS
PATH="/opt/homebrew/opt/node@24/bin:$PATH" $PNPM test                               PASS (35 files / 163 tests)
PATH="/opt/homebrew/opt/node@24/bin:$PATH" $PNPM build                              PASS (40 static pages)
/opt/homebrew/opt/node@24/bin/node scripts/check-phase04-bundle.mjs                  PASS
/opt/homebrew/opt/node@24/bin/node scripts/check-phase11-performance.mjs             PASS
/opt/homebrew/opt/node@24/bin/node scripts/check-phase11-security.mjs                PASS
/opt/homebrew/opt/node@24/bin/node scripts/check-public-secrets.mjs                  PASS
PATH="/opt/homebrew/opt/node@24/bin:$PATH" $PNPM exec playwright test \
  tests/e2e/phase02-visual.spec.ts tests/e2e/phase02a-landing.visual.spec.ts \
  --project=chromium                                                              BASELINE DEBT (5/8 pass; no update)
PATH="/opt/homebrew/opt/node@24/bin:$PATH" $PNPM test:gallery                     BASELINE DEBT (29/30 pass; no update)
```

## Assumptions, gaps, and handoff

- The current web screenshots are accepted only as a pre-redesign inventory, never as design direction.
- Physical-device execution is deferred per owner instruction and is not a Slice 11A.0 blocker.
- The three visual mismatches/timing failure in the old shell suite and one minor WebKit gallery drift are recorded debt. They are not to be papered over by updating snapshots before redesign review.
- No local or hosted Supabase mutation was required. Full Phase 03–11 local regression remains a closure responsibility.
- The parity ledger skeleton and serialized ownership/allowlist are in the companion documents created with this baseline.
