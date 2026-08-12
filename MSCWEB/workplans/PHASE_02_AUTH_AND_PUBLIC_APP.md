# MSCWEB W02 — Google Auth and public app

Status: `Complete`
Autonomy: `A` with fake/local adapters; `B` for real local Google OAuth  
Depends on: W01 exit criteria and local Supabase readiness

## Objective

Implement Guest-safe public surfaces and Google-only Supabase Auth with preserved intent, role-aware routing, and private-cache hygiene.

## Required references

- `00_PRODUCT_SPEC.md` Guest/Participant authority
- `01_ARCHITECTURE.md` authentication and routing
- `02_UX_PARITY_AND_ROUTES.md`
- `05_DATA_SECURITY.md`
- `07_TESTING_ACCEPTANCE.md`
- current iOS Guest/Login/public Participant runtime

## Deliverables

- Supabase client/auth adapter and environment validation;
- Google OAuth PKCE callback flow;
- Guest state, auth gate, preserved internal intent, logout/session expiry;
- server-controlled role/profile loader;
- public Home, program catalog/detail, leaderboard/winners, and Coach profile read models;
- RLS/grant tests proving Guest/private separation.

## Mandatory simulator gate

- [x] Inspect Guest Home, login presentation, intended return behavior, public Program/Peringkat/Coach/Profile gates.
- [x] Inspect loading, empty, error, and logged-in transition states.
- [x] Record adaptive web differences, especially browser redirect/back behavior.

## Checklist

### Local backend

- [x] Check `colima status`, `docker info`, and `supabase status`; start only when needed.
- [x] Verify and reuse the authoritative local migrations/grants/RLS for public read models and protected profiles; do not duplicate the shared backend contract under `MSCWEB/`.
- [x] Exercise deterministic local fixtures without production personal data.
- [x] Generate typed DB bindings through the chosen project workflow.

### Authentication

- [x] Environment parser allows local/production public values but rejects secret/server keys in browser config.
- [x] Implement Google login, callback validation, internal return-route allowlist, and typed errors.
- [x] New self-registration creates Participant authority state only.
- [x] Load role from protected data, not editable metadata.
- [x] Handle cancelled OAuth, provider error, expired session, cross-tab logout, and account switch.
- [x] Purge private query/media/signed-URL cache on logout/session invalidation.

### Public experience

- [x] Guest Home uses published/public data only.
- [x] Program catalog/detail expose only approved fields.
- [x] Leaderboard/winner public result excludes private weight.
- [x] Coach public profile excludes raw QR/current private relationships.
- [x] Personal mutation routes use centralized auth gate and return to safe intent.

## Sub-agent plan

- `msc_explorer`: map existing Supabase auth/profile/public policies and iOS Guest states.
- `msc_implementer`: sole writer for local migrations, adapter, and one UI vertical slice at a time.
- `msc_reviewer`: open-redirect, RLS negative, cache-clearing, role-authority, and UI parity review.

Migration ordering and generated types are primary-agent integration ownership.

## Verification

- local migration/RLS tests;
- unit tests for intent allowlist, role mapping, typed auth errors;
- Playwright Guest→login→return and session-expiry journeys;
- owner/account-switch cache isolation;
- compact simulator comparison and wide accessibility checks;
- production bundle secret scan.

## Exit criteria

- Real local Google login works if credentials are provided; otherwise all non-provider code is complete and the exact provider blocker is documented.
- Guest cannot query or render private account data.
- Authenticated session resolves protected role and routes correctly.
- Public surfaces match iOS product behavior with documented web adaptations.

## User input or authorization

- Local Google OAuth client/provider configuration and redirect registration for live login.
- No hosted main configuration or production credentials are authorized.

## Progress log

Append backend readiness, migrations, auth scenario, simulator evidence, commands/results, secrets check, blockers, and next item.

### 2026-08-12 — W02 complete

- Requirements covered: `PROD-002`, `PROD-003`, `PROD-004`, `PROD-007`,
  `PROD-GST-001`–`PROD-GST-003`, `PROD-PRG-001`, `PROD-PRG-002`,
  `PROD-LDB-001`, `ARCH-007`–`ARCH-010`, `ARCH-STATE-001`,
  `ARCH-STATE-003`, `ARCH-STATE-006`, `ARCH-AUTH-001`–`ARCH-AUTH-006`,
  `ARCH-NAV-001`–`ARCH-NAV-004`, `ARCH-ERR-001`–`ARCH-ERR-003`,
  `SEC-001`–`SEC-003`, `SEC-006`, `SEC-AUTHZ-001`–`SEC-AUTHZ-003`,
  `SEC-PRV-001`, `SEC-PRV-002`,
  `UX-001`–`UX-003`, `UX-HOME-001`–`UX-HOME-004`, `UX-PRG-001`,
  `UX-PRG-002`, `QA-001`–`QA-003`, and `QA-JRN-007`.
- Files changed: auth/config/client boundaries under `src/shared/auth/`,
  `src/shared/config/`, and `src/shared/supabase/`; provider wiring in
  `src/shared/AppProviders.tsx` and `src/app/_layout.tsx`; Google login and
  callback routes; public domain/repository/query/components under
  `src/features/public/`; Guest/Participant Home, Program, Peringkat, Coach,
  and Profil routes; production server/Worker routing; focused unit,
  integration, and Playwright tests; generated database types; and simulator
  evidence under `references/simulator/w02/`.
- Backend assumption: the repository-root Supabase migrations are the single
  authoritative shared backend contract. Existing profile provisioning,
  public-read RPCs, protected dashboard-summary RPC, grants, RLS, and synthetic
  fixtures were reused and tested; no duplicate web migration or hosted-main
  mutation was created.
- Product assumption: W02 exposes public discovery and authenticates with
  Google only. QR enrollment, entitlement/payment mutation, and authenticated
  program joining remain W03 responsibilities.
- Live auth result: Android Chrome completed real local Google OAuth, PKCE
  callback exchange, protected Participant role resolution, and safe return to
  `/app/profile`. Logout returned to Guest state without retaining personal
  account content. No account screenshot or personal identifier was persisted.
- iOS parity: XcodeBuildMCP `build_run_sim` passed for project
  `MSCBodyTransformation.xcodeproj`, scheme `MSCBodyTransformation`, on iPhone
  17 Pro/iOS 26.4. `launch_app_sim` then exercised Guest Home/login/catalog/
  leaderboard plus `loading`, `offline`, `repository_error`,
  `participant_no_program`, and `participant_active` with
  `-AppleLanguages (en) -AppleLocale en_US`. Product copy remained Indonesian.
  Browser OAuth intentionally uses full-page redirect/Back behavior; details
  are recorded in `references/simulator/w02/README.md`.
- Backend verification: `colima status`, `docker info`, and `supabase status`
  passed; `supabase test db --local` for tests `005`, `007`, and `008` passed
  3 files/93 assertions; `node supabase/tests/integration/public_guest_reads.mjs`
  passed 22 checks; the focused local Vitest integration passed 1 test. The
  stack was restarted without reset so final exact redirect configuration is
  active, and Supabase/Colima were left running.
- Web verification: `npm run typecheck` passed; `npm run lint` passed;
  `npm test` passed 63 tests with 2 environment-dependent tests skipped;
  `npm run build` passed; `npm run verify:bundle` passed for 28 JavaScript
  files; `npm run verify:pwa` passed; and `npx playwright test` passed 46/46
  cases across desktop and compact Chromium.
- Security/privacy verification: dedicated Guest integration proved public RPC
  access while profile rows remained unreadable and the protected role RPC was
  denied; the production bundle exact-value scan found no local server secret,
  service-role key, JWT secret, S3 secret, or Google provider secret. Public
  leaderboard/Coach payloads exclude private weight, phone, raw QR, and private
  relationship fields. `scripts/check_localization_catalog.sh` passed.
- External configuration: local Google provider and exact
  `http://127.0.0.1:4173/auth/callback` registration are active only for local
  development. No deployment or production Supabase configuration was changed.
- Remaining blockers: none for W02. Next unchecked workplan: W03 enrollment and
  participant payment.

### 2026-08-12 — Compact navigation parity correction

- Requirements covered: `UX-003`, `UX-NAV-001`, `UX-NAV-002`, `UX-RSP-005`,
  `DS-001`, `DS-005`, `DS-TKN-001`, `DS-TKN-003`, and `DS-ICO-007`.
- Files changed: `src/shared/navigation/AppShell.tsx`,
  `src/shared/design/tokens.ts`, `tests/e2e/feasibility.spec.ts`, and this
  progress log.
- Cause: the web link itself owned both layout and text rendering, so compact
  flex direction could become inconsistent across labels. The safe-area inset
  was also padded inside a full-width bar, making the active red block and
  surrounding surface much larger than the iPhone hierarchy.
- Fix: compact navigation now uses a floating capsule, five equal-width link
  targets with a dedicated vertical icon/label layout, external safe-area
  offset, a compact semantic selected pill, red filled selected icon/label,
  and neutral unselected items. Light and dark selected surfaces use semantic
  tokens; no Liquid Glass imitation or hardcoded feature color was added.
- Fresh iOS reference: XcodeBuildMCP `build_run_sim` passed for Debug
  `participant_active` on iPhone 17 Pro/iOS 26.4. The native Participant Home
  confirmed the floating capsule, equal tab distribution, vertical labels,
  and lighter selected pill used as the comparison contract.
- Browser evidence: the in-app browser verified the production build at
  `/app/home` and navigation to `/app/programs` with no console warning/error.
  Playwright screenshots at 368×800 verified compact light/dark rendering;
  direct `view_image` comparison against the supplied iPhone reference found
  no remaining material navbar mismatch.
- Commands/results: `npm run typecheck` passed; `npm run lint` passed;
  `npm test` passed 63 tests with 2 environment-dependent skips;
  `npm run build` passed; and the focused W01 role-shell Playwright suite
  passed 14/14 across desktop and compact Chromium. The 320 px test also
  verifies equal tab widths, centered icon/label baselines, no overflow,
  stable geometry after selecting Program, and selected-state semantics.
- Sub-agents: none. Remaining blockers: none. Next unchecked workplan remains
  W03 Participant Program.
