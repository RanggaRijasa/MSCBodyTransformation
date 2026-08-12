# Phase 11A iPhone/PWA Parity Ledger

> Created in Slice 11A.0 and reconciled at local closure on 12 August 2026.  
> `Accepted` remains evidence-scoped: uncaptured lifecycle/error states stay `Open` even though the complete functional regression passes. The pre-redesign web snapshot is never an accepted reference.

## Ledger rules

- One row represents one material surface/state or one tightly coupled interaction outcome.
- `Exact` means the mobile hierarchy, terminology, navigation intent, action prominence, and outcome match the iPhone reference. It does not require pixel-identical SwiftUI rendering.
- `Adapted` requires a concrete browser, accessibility, responsive, or web-native commerce reason.
- Screenshot evidence must be captured from an actual route with deterministic safe data. Gallery evidence alone cannot close an action-oriented row.
- The reviewer cannot be the primary implementer of the same row.
- Allowed status values are `Open`, `Needs decision`, `Needs fix`, and `Accepted`.
- `Accepted` requires functional preservation, no unresolved Critical/High finding, and stable Chromium/WebKit evidence where applicable.

Stable evidence naming:

```text
ios26-iphone-<role>-<surface>-<state>-<appearance>.png
pwa-<browser>-<viewport>-<role>-<surface>-<state>-<appearance>.png
```

## Landing and public

| ID | Role / surface / state | iOS reference | PWA evidence | Exact/adapted | Reason/adaptation decision | Function test | Reviewer | Status |
|---|---|---|---|---|---|---|---|---|
| LAN-001 | Landing `/` / hero + primary entry | `landing-phase11a-v1.png`; no legacy visual | `evidence/phase-11a/landing/landing-{390,430,768,1440}-*.png` | Adapted | Web marketing surface; preserve product hierarchy | landing component, smoke, visual C/W | Independent Phase 11A review, 2026-08-12 | Accepted |
| LAN-002 | Landing / install prompt ready | `PHASE_11A_CONCEPT_DECISIONS.md` | `evidence/phase-11a/landing/install/pwa-chromium-390x844-landing-install-prompt-ready-light.png` | Adapted | Browser install prompt; frozen canonical labels/outcomes | install component + landing state C/W | Independent Phase 11A review, 2026-08-12 | Accepted |
| LAN-003 | Landing / iPhone manual guidance | `PHASE_11A_CONCEPT_DECISIONS.md` | `evidence/phase-11a/landing/install/pwa-webkit-390x844-landing-install-ios-guidance-light.png` | Adapted | Safari has no custom install prompt; frozen canonical guidance | exact single-copy guidance + C/W state runner | Independent Phase 11A review, 2026-08-12 | Accepted |
| LAN-004 | Landing / standalone, dismissed, unsupported, not-ready | `PHASE_11A_CONCEPT_DECISIONS.md` | `evidence/phase-11a/landing/install/` (7 applicable capability-state PNGs) | Adapted | Platform capability state; one primary CTA; bounded announcement | install component + landing state C/W | Independent Phase 11A review, 2026-08-12 | Accepted |
| LAN-005 | Landing / Program entry + public-safe navigation | relevant Guest Program capture | `evidence/phase-11a/landing/landing-390-light-{chromium,webkit}.png` | Adapted | Accepted concept omits a teaser; header, hero, and footer retain public `/program` entry without personal hydration | landing boundaries + landing smoke | Independent Phase 11A review, 2026-08-12 | Accepted |
| LAN-006 | Landing / sections, FAQ, footer, legal links | `landing-phase11a-v1.png` | `evidence/phase-11a/landing/` (12 responsive C/W PNGs) | Adapted | Responsive marketing composition | landing component/smoke/visual | Independent Phase 11A review, 2026-08-12 | Accepted |
| LAN-007 | Landing / final PWA screenshots | N/A | `public/images/landing-{participant,coach,admin}-v1.jpg`; landing evidence packet | Adapted | Actual redesigned PWA crops, not iOS; privacy and metadata screened | bundle/media budget + privacy inspection | Independent Phase 11A review, 2026-08-12 | Accepted |
| PUB-001 | Public `/bantuan` | iPhone help/legal hierarchy | TBD | Exact | — | landing component + route smoke | TBD | Open |
| PUB-002 | Public `/privasi`, `/ketentuan` | iPhone legal hierarchy | TBD | Exact | Browser page/back adaptation only | landing component + route smoke | TBD | Open |

## Guest and Auth

| ID | Role / surface / state | iOS reference | PWA evidence | Exact/adapted | Reason/adaptation decision | Function test | Reviewer | Status |
|---|---|---|---|---|---|---|---|---|
| GST-001 | Guest `/hari-ini` / logged-out card | `ios26-iphone17-guest-hari_ini-home-light/dark.png` | `evidence/phase-11a/guest-auth/guest-home-390-{light,dark}-{chromium,webkit}.png` | Exact | — | Guest/Auth visual 18/18 + Phase 03 | Independent Phase 11A review, 2026-08-12 | Accepted |
| GST-002 | Guest / Participant shell tabs | `ios26-iphone17-guest-hari_ini-home-light/dark.png` | 390 packet + `guest-home-320-zoom400-{chromium,webkit}.png` | Adapted | Browser history plus bounded horizontal nav at 400% zoom; normal 390 retains five tabs | shell 18/18 + Guest/Auth visual | Independent Phase 11A review, 2026-08-12 | Accepted |
| GST-003 | Guest `/program` / public catalog | `guest_program_catalog` TBD | TBD | Exact | — | Programs component + Phase 05 E2E | TBD | Open |
| GST-004 | Guest Program personal action / centralized Auth gate | Guest Program detail TBD | TBD | Exact | Form redirect preserves pending intent | Auth flow + Phase 03/05 E2E | TBD | Open |
| GST-005 | Guest `/peringkat` and `/coach` / public-safe | Guest ranking/Coach TBD | TBD | Exact | No private profile/weight | Participant component + Phase 07 E2E | TBD | Open |
| AUT-001 | `/masuk` / provider-ready | `ios26-iphone17-auth-login-light/dark.png`; `auth-components-v2.png` | `evidence/phase-11a/guest-auth/auth-login-ready-390-{light,dark}-{chromium,webkit}.png` | Exact | Google-only production flag differs from the iOS Apple action | Auth component + Guest/Auth C/W | Independent Phase 11A review, 2026-08-12 | Accepted |
| AUT-002 | `/masuk` / pending/provider error/config error/retry | `auth_login` error TBD | `auth-login-error-390-{light,dark}-{chromium,webkit}.png` (provider error only) | Exact | OAuth browser redirect is adapted; pending/config/retry remain uncaptured | Auth component + Auth integration | Independent review: partial evidence only | Open |
| AUT-003 | `/daftar` / provider-first | `auth-components-v2.png` | `evidence/phase-11a/guest-auth/auth-register-390-light-{chromium,webkit}.png` | Exact | Web provider availability is adapted | Auth component + Guest/Auth C/W | Independent Phase 11A review, 2026-08-12 | Accepted |
| AUT-004 | `/lupa-password` / generic response | `auth-components-v2.png` | `evidence/phase-11a/guest-auth/auth-forgot-password-390-light-{chromium,webkit}.png` | Exact | Canonical web path differs from old docs | Auth component + Guest/Auth C/W | Independent Phase 11A review, 2026-08-12 | Accepted |
| AUT-005 | `/onboarding` / Participant purpose + QR | `auth_profile_onboarding` TBD | TBD | Exact | QR uses accessible web dialog | Auth component + Phase 03/04 E2E | TBD | Open |
| AUT-006 | `/onboarding` / Coach eligible/ineligible/attestations | Coach application captures TBD | TBD | Exact | Manual commerce continuation is web-native | Auth model/component + Phase 03/06 | TBD | Open |
| AUT-007 | Auth / keyboard, autofill, focus, back/close | Auth login/register captures | Guest/Auth evidence packet | Adapted | Browser password manager/history; programmatic H1 focus has no decorative ring | Auth smoke + Guest/Auth 18/18 C/W | Independent Phase 11A review, 2026-08-12 | Accepted |
| AUT-008 | Session / expired, revoked, stale role, offline | Global error/session captures TBD | TBD | Exact | Retry/back navigation adapted | session unit + Phase 03/11 | TBD | Open |

## Peserta

| ID | Role / surface / state | iOS reference | PWA evidence | Exact/adapted | Reason/adaptation decision | Function test | Reviewer | Status |
|---|---|---|---|---|---|---|---|---|
| PAR-001 | `/hari-ini` / no active Program | Participant no-program TBD | TBD | Exact | — | Participant component/E2E | TBD | Open |
| PAR-002 | `/hari-ini` / active day, progress, focus order | `ios26-iphone17-participant-hari_ini-active-light/dark.png` | `evidence/phase-11a/participant/participant-home-390-{light,dark}-{chromium,webkit}.png` | Exact | — | Participant visual 6/6 + Phase 07/10 | Independent Phase 11A review, 2026-08-12 | Accepted |
| PAR-003 | `/hari-ini` / completed/locked state | Participant locked/completed TBD | TBD | Exact | — | Participant Program unit/component | TBD | Open |
| PAR-004 | `/program` / Diikuti | Participant active TBD | TBD | Exact | — | Program catalog unit/component/E2E | TBD | Open |
| PAR-005 | `/program` / Tersedia + registration closed | public catalog TBD | TBD | Exact | — | Program catalog unit/component/E2E | TBD | Open |
| PAR-006 | `/program` / Riwayat | Participant final/history TBD | TBD | Exact | — | Program catalog unit/component/E2E | TBD | Open |
| PAR-007 | Program detail / offer | Program detail TBD | TBD | Exact | Browser route is adapted | Programs component/E2E | TBD | Open |
| PAR-008 | Program activity / day accordion/access policies | day 1/mid/final TBD | TBD | Exact | — | Participant Program unit/component/E2E | TBD | Open |
| PAR-009 | Join / scanner checking, permission denied, unavailable | Enrollment QR TBD | TBD | Adapted | Web camera permissions/dialog | media + Program component/E2E | TBD | Open |
| PAR-010 | Join / Coach preflight, confirm, rescan | Enrollment QR valid/invalid TBD | TBD | Exact | Opaque QR contract retained | Program component + Phase 05 | TBD | Open |
| PAR-011 | Join / duplicate, capacity, deadline, conflict, offline | Enrollment edge states TBD | TBD | Exact | — | Program unit + Phase 05 races/E2E | TBD | Open |
| PAR-012 | Payment / awaiting evidence + QRIS/instructions | N/A web-native | TBD | Adapted | Manual transfer replaces StoreKit; adaptation frozen, visual state uncaptured | Payments component + Phase 06 PASS | TBD | Open |
| PAR-013 | Payment / upload, offline, retry | N/A web-native | TBD | Adapted | Browser media/private upload; adaptation frozen, visual state uncaptured | media/payments + Phase 06/11 PASS | TBD | Open |
| PAR-014 | Payment / under review, correction, rejected, approved, expired | N/A web-native | TBD | Adapted | Manual commerce lifecycle frozen; visual states uncaptured | Payments component/integration PASS | TBD | Open |
| PAR-015 | Step / article | Participant article TBD | TBD | Exact | — | Participant component/E2E | TBD | Open |
| PAR-016 | Step / video loading, waiting, offline, threshold, error | Participant video TBD | TBD | Adapted | HTML media capability | video unit/media/Participant E2E | TBD | Open |
| PAR-017 | Step / typed form and validation | Participant form TBD | TBD | Exact | Browser form controls adapted | Participant component/E2E | TBD | Open |
| PAR-018 | Step / quiz pass/fail/result | Participant quiz TBD | TBD | Exact | Server result remains authoritative | Participant component + Phase 07/10 | TBD | Open |
| PAR-019 | Step / photo processing/upload/error | Participant photo TBD | TBD | Adapted | Browser picker/camera | media/Participant component/E2E | TBD | Open |
| PAR-020 | Step / initial, daily, final weigh-in | Participant weigh-in captures TBD | TBD | Exact | Browser numeric input adapted | Participant component + Phase 07/10 | TBD | Open |
| PAR-021 | Submission / pending, rejected, approved, conflict/retry | Participant review states TBD | TBD | Exact | — | Participant component + Phase 07/10 | TBD | Open |
| PAR-022 | `/peringkat` / selector, tie, fewer winners | Participant ranking TBD | TBD | Exact | — | leaderboard unit + Phase 10 | TBD | Open |
| PAR-023 | `/peringkat` / final snapshot/history | Participant final leaderboard TBD | TBD | Exact | — | leaderboard unit + Phase 10 | TBD | Open |
| PAR-024 | `/coach` / directory + Coach-mu | Participant Coach TBD | TBD | Exact | Existing profile cards stay on one route | Participant component/E2E | TBD | Open |
| PAR-025 | `/profil` / identity/avatar edit | Participant profile TBD | TBD | Exact | In-place web form replaces sheet | profile component + Phase 07 | TBD | Open |
| PAR-026 | `/profil` / Coach change scan/confirm | Participant Coach change TBD | TBD | Adapted | Accessible QR dialog | profile/media component + Phase 07 | TBD | Open |
| PAR-027 | `/profil` / logout, reauth, delete confirmation/errors | Participant account lifecycle TBD | TBD | Adapted | OAuth/web account lifecycle | Auth/profile + Phase 03/07/11 | TBD | Open |
| PAR-028 | Participant shell / safe area, tabs, reach, scroll restore | Participant active light/dark | Participant evidence packet | Adapted | Browser history/scroll and 400% horizontal nav adaptation | shell 18/18 + Participant visual 6/6 | Independent Phase 11A review, 2026-08-12 | Accepted |

## Coach

| ID | Role / surface / state | iOS reference | PWA evidence | Exact/adapted | Reason/adaptation decision | Function test | Reviewer | Status |
|---|---|---|---|---|---|---|---|---|
| COA-001 | `/coach-area` / dashboard metrics and quick actions | `ios26-iphone17-coach-dashboard-review_queue-light/dark.png` | `evidence/phase-11a/coach/coach-dashboard-390-{light,dark}-{chromium,webkit}.png` | Exact | — | Coach visual 8/8 + Phase 08/10 | Independent Phase 11A review, 2026-08-12 | Accepted |
| COA-002 | Dashboard / attention states | Coach attention TBD | TBD | Exact | not-enrolled/not-started/falling-behind/on-track/complete | Coach unit/component/E2E | TBD | Open |
| COA-003 | `/coach-area/program` / Program hub | Coach Program TBD | TBD | Exact | — | Coach component/E2E | TBD | Open |
| COA-004 | Program hub / activity/ranking/filter/history | Coach activity/ranking TBD | TBD | Exact | Existing single route is canonical | Coach component/E2E | TBD | Open |
| COA-005 | `/coach-area/peserta` / roster populated | Coach roster TBD | TBD | Exact | — | Coach component/E2E | TBD | Open |
| COA-006 | Roster / empty/search/filter | Coach roster empty/filter TBD | TBD | Adapted | Browser GET filter | Coach component/E2E | TBD | Open |
| COA-007 | Participant detail / assigned private profile | Coach participant detail TBD | TBD | Exact | Assignment guard unchanged | Coach component/E2E/privacy gate | TBD | Open |
| COA-008 | Participant detail / submissions + weigh-in history | Coach private detail TBD | TBD | Exact | Private photo/weight boundaries unchanged | Coach component + Phase 08/10 | TBD | Open |
| COA-009 | `/coach-area/pemeriksaan` / queue/filter/empty | Coach review queue TBD | TBD | Exact | Inline detail is canonical | Coach component/E2E | TBD | Open |
| COA-010 | Review / private answer photo, approve/reject/reason | Coach review detail TBD | TBD | Exact | Browser inline card adapted | Coach component + Phase 08/10 | TBD | Open |
| COA-011 | Review / busy, complete, error, multi-tab conflict | Coach review states TBD | TBD | Exact | — | Coach component/E2E race | TBD | Open |
| COA-012 | `/coach-area/qr` / access gate, QR, share/download | Coach identifier TBD | TBD | Adapted | Web Share/download fallback | media/Coach component/E2E | TBD | Open |
| COA-013 | `/coach-area/profil` / public profile | Coach profile TBD | TBD | Exact | In-place form replaces sheet | Coach component/E2E | TBD | Open |
| COA-014 | Coach access / active, pending, rejected, expired, inactive | Coach access lifecycle TBD | TBD | Exact | — | Coach unit/component/E2E | TBD | Open |
| COA-015 | `/akses-coach/[applicationId]` / payment continuation | N/A web-native | TBD | Adapted | Manual transfer access lifecycle frozen; visual state uncaptured | Payments component + Phase 06/08 PASS | TBD | Open |
| COA-016 | Coach shell / mobile tabs, desktop expansion | Coach dashboard light/dark | Coach evidence packet + accepted gallery dashboard | Adapted | Browser responsive rail adapted | shell 18/18 + Coach visual 8/8 | Independent Phase 11A review, 2026-08-12 | Accepted |

## Admin

| ID | Role / surface / state | iOS reference | PWA evidence | Exact/adapted | Reason/adaptation decision | Function test | Reviewer | Status |
|---|---|---|---|---|---|---|---|---|
| ADM-001 | `/admin` / dashboard metrics/action queue | `ios26-iphone17-admin-dashboard-winner_lock-light/dark.png`; `admin-responsive-v2.png` | `evidence/phase-11a/admin/admin-dashboard-{390,1440}-*.png` | Exact | First action maps to authoritative closure queue; review remains Coach-owned | Admin visual 16/16 + Phase 09/10 | Independent Phase 11A review, 2026-08-12 | Accepted |
| ADM-002 | Dashboard / empty/error/loading | Admin global states TBD | TBD | Exact | — | Admin component/E2E | TBD | Open |
| ADM-003 | Payment queue / filters/status metrics | N/A web-native | TBD | Adapted | Manual commerce adaptation frozen; visual states uncaptured | Payments/Admin component/E2E PASS | TBD | Open |
| ADM-004 | Payment detail / private evidence/history | N/A web-native | TBD | Adapted | Private manual commerce adaptation frozen; visual states uncaptured | Payments/Admin E2E/privacy PASS | TBD | Open |
| ADM-005 | Payment decision / approve confirm/reject reason/conflict | N/A web-native | TBD | Adapted | Accessible browser dialog frozen; visual states uncaptured | Payments/Admin component/E2E PASS | TBD | Open |
| ADM-006 | Payment destination / create/version/status | N/A web-native | TBD | Adapted | Web manual commerce config frozen; visual states uncaptured | Payments/Admin E2E PASS | TBD | Open |
| ADM-007 | `/admin/program` / list/filter/status/empty | Admin Program TBD | TBD | Exact | — | Admin component/E2E | TBD | Open |
| ADM-008 | Program create/edit / settings | Admin draft CMS TBD | TBD | Exact | Browser form/editor adapted | Admin Program unit/component/E2E | TBD | Open |
| ADM-009 | Program edit / days/steps/copy overwrite confirm | Admin content editor TBD | TBD | Exact | In-page tabs are canonical | Admin Program unit/component/E2E | TBD | Open |
| ADM-010 | Program detail / shared Participant preview | Admin preview TBD | TBD | Exact | Existing shared renderer retained | Admin component/E2E | TBD | Open |
| ADM-011 | Program lifecycle / validation/publish/duplicate | Admin draft/active TBD | TBD | Exact | — | Admin Program unit/E2E | TBD | Open |
| ADM-012 | Program closure / complete/reopen/archive | Admin closure TBD | TBD | Exact | Reason/idempotency retained | Admin + Phase 09/10 | TBD | Open |
| ADM-013 | Winner lock / preflight/fewer winners/ties | Admin winner lock TBD | TBD | Exact | Server snapshot authoritative | Admin/leaderboard + Phase 10 | TBD | Open |
| ADM-014 | Failed quiz reopen | Admin Program operation TBD | TBD | Exact | Guard/idempotency retained | Admin + Phase 10 | TBD | Open |
| ADM-015 | `/admin/orang` / role segments/search/directory | Admin people TBD | TBD | Exact | Current single route retained | Admin component/E2E | TBD | Open |
| ADM-016 | Coach applications / eligibility/payment/approve/reject | Admin Coach approval TBD | TBD | Exact | Payment verification remains separate | Admin component + Phase 09/10 | TBD | Open |
| ADM-017 | Controlled operations / manual enroll/transfer | Admin people operations TBD | TBD | Exact | Reason/audit/capacity guards retained | Admin E2E | TBD | Open |
| ADM-018 | Controlled operations / weight correction/score adjustment | Admin corrections TBD | TBD | Exact | Private fields and audit retained | Admin + Phase 09/10 | TBD | Open |
| ADM-019 | `/admin/konten` / poster grid empty/populated | Admin content gallery TBD | TBD | Exact | — | Admin component/E2E | TBD | Open |
| ADM-020 | Poster / upload/replace/publish/delete | Admin poster editor TBD | TBD | Adapted | Browser media picker | Admin/media component/E2E | TBD | Open |
| ADM-021 | `/admin/pengaturan` / safe runtime settings | Admin settings TBD | TBD | Exact | Secrets remain undisclosed | Admin component/security gate | TBD | Open |
| ADM-022 | Settings / audit list empty/populated | Admin audit TBD | TBD | Exact | Existing anchor route retained | Admin component/E2E | TBD | Open |
| ADM-023 | Admin mobile shell | Admin iPhone tabs/hierarchy | `evidence/phase-11a/admin/admin-dashboard-390-*.png` | Exact | Five mobile tabs; Payment remains discoverable through dashboard queue | shell/Admin visual 16/16 | Independent Phase 11A review, 2026-08-12 | Accepted |
| ADM-024 | Admin responsive expansion / dashboard 1440 + editor forced-colors | `admin-responsive-v2.png` | `evidence/phase-11a/admin/admin-dashboard-1440-light-{chromium,webkit}.png`; `evidence/phase-11a/admin/admin-editor-forced-colors-{chromium,webkit}.png` | Adapted | Six-item desktop rail and forced-colors editor cue expand the same mobile system | Admin component/gallery/E2E | Independent Phase 11A review, 2026-08-12 | Accepted |

## Global, accessibility, privacy, and PWA

| ID | Role / surface / state | iOS reference | PWA evidence | Exact/adapted | Reason/adaptation decision | Function test | Reviewer | Status |
|---|---|---|---|---|---|---|---|---|
| GLB-001 | All shells / loading | global loading TBD | TBD | Exact | Web Skeleton may adapt animation | component + route E2E | TBD | Open |
| GLB-002 | All shells / empty | global empty TBD | TBD | Exact | — | component + route E2E | TBD | Open |
| GLB-003 | All shells / error + retry | repository error TBD | TBD | Exact | Browser retry adapted | foundation/component + route E2E | TBD | Open |
| GLB-004 | All shells / offline + reconnect | offline TBD | TBD | Adapted | PWA connectivity banner | Phase 11 PWA | TBD | Open |
| GLB-005 | All shells / denied/expired | permission/session denied TBD | TBD | Exact | Browser permissions adapted | Auth/media/Coach + Phase 11 | TBD | Open |
| GLB-006 | PWA / update available/apply/multi-tab | N/A web-native | TBD | Adapted | Service-worker lifecycle adaptation frozen; visual states uncaptured | Phase 11 PWA PASS | TBD | Open |
| GLB-007 | Push / disabled/enabling/active/denied/error | N/A web-native | TBD | Adapted | Browser notification capability frozen; visual states uncaptured | Push + Phase 11 PASS | TBD | Open |
| GLB-008 | Light/dark, reduced motion/transparency, forced colors | appearance captures TBD | TBD | Exact | Opaque glass fallback allowed | gallery + Phase 11 axe/manual | TBD | Open |
| GLB-009 | Keyboard/focus/route focus/dialog trap/restore | interaction captures TBD | TBD | Adapted | Browser focus model | component + Chromium/WebKit E2E | TBD | Open |
| GLB-010 | 320/375/390/430 mobile and safe area | iPhone captures TBD | TBD | Exact | — | visual matrix | TBD | Open |
| GLB-011 | 768/1280/1440/1920 responsive expansion | `admin-responsive-v2.png`; `landing-phase11a-v1.png` | TBD | Adapted | Web/tablet/desktop capability | visual matrix | TBD | Open |
| GLB-012 | Zoom 200/400%, long Indonesian copy, no clipping | large text captures TBD | TBD | Exact | CSS zoom differs from Dynamic Type | axe/manual/visual | TBD | Open |
| GLB-013 | Touch target >=44 px and status not color-only | all critical screens TBD | TBD | Exact | — | axe/manual/visual | TBD | Open |
| GLB-014 | Private media/payment/weight no cache/log/public URL | N/A visual | TBD | Exact | No adaptation permitted | privacy/security/Phase 07–11 | TBD | Open |
| GLB-015 | Logout/account switch clears client/cache state | N/A visual | TBD | Exact | No adaptation permitted | Auth + Phase 11 PWA | TBD | Open |
| GLB-016 | Route/deep link/back/scroll restoration | navigation captures TBD | TBD | Adapted | Browser URL/history preserved | shell/component/E2E | TBD | Open |

## Route reconciliation linked decisions

The detailed implementation evidence is recorded in `docs/progress/PHASE_11A_BASELINE.md`. Ledger work must use these canonical decisions:

- `/coach` contains inline Coach profile cards;
- profile edit/account lifecycle remain on `/profil`; Coach change opens the QR dialog;
- Coach activity/ranking remain on `/coach-area/program`; reviews remain inline on `/coach-area/pemeriksaan`;
- Admin people remain on `/admin/orang`; audit is `/admin/pengaturan#audit`; Program edit uses in-page tabs;
- `/lupa-password` and `/akses-coach/[applicationId]` are canonical; no undocumented aliases exist.

Any proposal to add a route, alias, or capability must stop and receive separate scope approval. Visual parity does not itself authorize it.
