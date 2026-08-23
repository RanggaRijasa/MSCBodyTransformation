# MSCWEB W03 — Participant program experience

Status: `Complete`
Autonomy: `A` against local Supabase  
Depends on: W02 session, public data, and role guards

## Objective

Deliver Participant Home, catalog, program detail, day/activity navigation, content renderers, progress, and profile parity before private evidence review and payment are activated.

## Required references

- `00_PRODUCT_SPEC.md` Participant/program/scoring requirements
- `02_UX_PARITY_AND_ROUTES.md`
- `03_DESIGN_SYSTEM.md`
- existing end-to-end program contract matrix
- current iOS Participant simulator screens for each implemented slice

## Deliverables

- Participant home sections in approved order;
- Program `Diikuti`, `Tersedia`, `Riwayat`;
- offer/detail and entitlement states;
- activity program header, day accordions, relevant-day positioning, lock states;
- renderers for article, video, form, quiz, and weigh-in states;
- typed domain/repository/use-case boundaries;
- progress/points/profile read surfaces using server values.

## Mandatory simulator gate per screen

- [x] Launch exact Participant scenario and navigate to the corresponding screen.
- [x] Capture current hierarchy, scroll behavior, selected tab, header/menu, sheet, enabled/disabled, loading/empty/error/locked state.
- [x] Repeat for Home, catalog, offer/detail, activity accordion, and at least one step renderer.
- [x] Complete the parity sign-off template for each vertical slice.

## Checklist

### Domain/data

- [x] Map portable program/activity/day/step/status models.
- [x] Implement repositories and query keys without Supabase types in domain.
- [x] Enforce published visibility/timezone and avoid client-authoritative unlock/scoring.
- [x] Model loading/empty/error/offline/forbidden/session-expired states.

### Home and catalog

- [x] Home order: Program, Fokus, Top 5, Pemenang, Coach.
- [x] Compact horizontal program cards have pointer, keyboard, and screen-reader alternatives.
- [x] Catalog segments preserve route/filter/scroll state.
- [x] Program detail shows poster, schedule/timezone, price/status, Coach context, and state-aware CTA.

### Activity flow

- [x] Compact progress header and day accordions.
- [x] Relevant day opens and scrolls without violating reduced motion.
- [x] Locked/hidden/pending/rejected state has label/icon/copy, not color alone.
- [x] Article/video/form/quiz/weight renderer uses shared published definition.
- [x] Quiz one-attempt and required-answer UI mirror authoritative policy; client validation is only UX.
- [x] Sticky CTA survives bottom nav, safe area, and virtual keyboard.

### Profile/progress

- [x] Participant profile uses neutral blank-person fallback.
- [x] Points/rank/weight/date formatting uses `id-ID` and tabular numerals.
- [x] Private weight never appears in public leaderboard or telemetry.

## Sub-agent plan

- `msc_explorer`: one bounded iOS/source audit per screen family and domain-contract map.
- `msc_implementer`: one vertical slice at a time; sole writer.
- `msc_reviewer`: state coverage, accessibility, browser history, responsive and current-simulator parity.

Do not split edits to shared activity renderer, navigation root, or design tokens across writers.

## Verification

- domain policy and mapping unit tests;
- component tests for all explicit states;
- Playwright Home/catalog/detail/activity navigation and browser Back;
- visual baselines compact 320/390/430, dark/light, long copy/zoom;
- simulator side-by-side sign-off;
- Admin wide is not in scope yet.

## Exit criteria

- Participant can browse and navigate all supported published program content against local data.
- All step types render with correct state, but evidence mutation authority remains in W04.
- No client computes authoritative role, unlock, entitlement, or points.
- Parity evidence exists for every core compact screen.

## User input or authorization

- None for local implementation with deterministic fixtures.
- Any new video/media dependency outside approved baseline requires ADR and explicit approval.

## Progress log

Append requirement IDs, simulator scenario/screens, files, tests, visual/accessibility evidence, adaptive differences, and next item.

### 2026-08-12 — W03 complete

- Requirement IDs: `PROD-PTC-005`, `PROD-PRG-001`–`PROD-PRG-004`,
  `PROD-LDB-001`–`PROD-LDB-003`, `UX-HOME-001`–`UX-HOME-004`, and
  `UX-PRG-001`–`UX-PRG-004`. `PROD-PRG-005` remains assigned to W04;
  enrollment and payment mutations remain assigned to W05.
- Files changed: portable public/Participant schemas, RLS-backed read repository,
  private query keys, program policy, shared program/activity/step renderers,
  Participant Home/Program/detail/Profile/Peringkat routes, semantic segmented
  control state, focused unit/local-integration/Playwright coverage, and parity
  evidence under `references/simulator/w03/`.
- Backend assumption: repository-root local Supabase migrations remain the
  authoritative shared contract. W03 reuses published public RPCs plus existing
  self-read RLS for profile, enrollment, submissions, scores, day access, and
  assigned Coach. It adds no migration and performs no hosted-main mutation.
- Authority boundary: published content, day access, enrollment status,
  progress, points, rank, winner snapshots, and Coach assignment are rendered
  from server values. The browser does not derive unlocks or authoritative
  scores. Step controls are preview/read surfaces only; answer, weight, and
  evidence mutations are deliberately not activated in W03.
- Fresh iOS parity: Debug built on iPhone 17 Pro Simulator/iOS 26.4 and was
  launched with Participant `participant_active` and `participant_mid_program`
  scenarios. Home, all three catalog segments, offer, activity accordions,
  locked days, initial weigh-in renderer, sticky action, selected Program tab,
  browser/native Back outcome, and Indonesian fallback under an English device
  locale were inspected. Detailed sign-off is in
  `references/simulator/w03/README.md`.
- Native automation note: the existing focused UI test navigated successfully
  through catalog, offer/join, Back, active detail, and the opened current day,
  then failed its native-only assertion at
  `MSCBodyTransformationUITests.swift:968` because the static text query for
  `Hari ini` was not exposed. No iOS source/test/project file was changed; the
  runtime hierarchy was inspected directly and the W03 web acceptance suite is
  unaffected.
- Web verification: `npm run typecheck` passed; `npm run lint` passed;
  `npm test` passed 71/71 including the local Supabase integration;
  `npm run build` passed with 27 route bundles; `npx playwright test` passed
  54/54 across desktop and compact Chromium; `npm run verify:bundle` passed
  for 28 JavaScript files; `npm run verify:pwa` passed; and
  `scripts/check_localization_catalog.sh` passed.
- Responsive/accessibility evidence: 320/390/430 light/dark offer matrices have
  no horizontal overflow; Program segments expose tab semantics and selected
  state; accordions expose expanded state and 44-point-equivalent targets;
  current user and all locked/pending/rejected/read-only states have text/icon
  labels; relevant-day positioning is nonanimated; sticky CTA accounts for the
  compact navigation and safe-area inset; browser Back restores activity and
  catalog state.
- Adaptive differences: native sheets/edge-back map to browser routes and
  history; compact bottom navigation becomes a rail at wider breakpoints;
  web adds explicit carousel previous/next controls and URL-backed catalog
  segments; no custom edge gesture or Liquid Glass imitation was introduced.
- Sub-agents: none. Remaining blockers: none for W03. No package, deployment,
  production Supabase, Git, native source, or Xcode project mutation occurred.
  Next unchecked workplan: W04 private evidence, Coach review, and
  authoritative scoring operations.

### 2026-08-23 — Joined-program card date compaction

- Files changed: `src/shared/design/formatters.ts`,
  `src/features/participant/ParticipantProgramComponents.tsx`, and focused
  unit/Playwright coverage. Only the joined-program activity card changed;
  program offer/detail timezone disclosure remains unchanged.
- Behavior: the card no longer renders its timezone and uses a compact
  Indonesian range such as `22–24 Agustus 2026`, including cross-month and
  cross-year ranges.
- Verification: `npm run typecheck`, `npm run lint -- --no-cache`, and
  `npm test` passed (202 passed, 9 environment-skipped). The focused
  `chromium-compact` authenticated Playwright flow passed and measured the
  rendered date as exactly one line. Production shell identity, the Program
  tab interaction, and URL-backed segment change were inspected in the in-app
  browser.
- Deployment: production Worker version
  `958bf023-5359-4979-af30-ce7c0bf6966a` was deployed to the existing apex and
  `www` routes. No DNS, production Supabase, secrets, or production data were
  changed. Synthetic local data and temporary session material were removed;
  local Supabase and Colima were left running.
