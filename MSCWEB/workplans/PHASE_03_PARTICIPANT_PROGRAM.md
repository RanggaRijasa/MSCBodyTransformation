# MSCWEB W03 — Participant program experience

Status: `Not started`  
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

- [ ] Launch exact Participant scenario and navigate to the corresponding screen.
- [ ] Capture current hierarchy, scroll behavior, selected tab, header/menu, sheet, enabled/disabled, loading/empty/error/locked state.
- [ ] Repeat for Home, catalog, offer/detail, activity accordion, and at least one step renderer.
- [ ] Complete the parity sign-off template for each vertical slice.

## Checklist

### Domain/data

- [ ] Map portable program/activity/day/step/status models.
- [ ] Implement repositories and query keys without Supabase types in domain.
- [ ] Enforce published visibility/timezone and avoid client-authoritative unlock/scoring.
- [ ] Model loading/empty/error/offline/forbidden/session-expired states.

### Home and catalog

- [ ] Home order: Program, Fokus, Top 5, Pemenang, Coach.
- [ ] Compact horizontal program cards have pointer, keyboard, and screen-reader alternatives.
- [ ] Catalog segments preserve route/filter/scroll state.
- [ ] Program detail shows poster, schedule/timezone, price/status, Coach context, and state-aware CTA.

### Activity flow

- [ ] Compact progress header and day accordions.
- [ ] Relevant day opens and scrolls without violating reduced motion.
- [ ] Locked/hidden/pending/rejected state has label/icon/copy, not color alone.
- [ ] Article/video/form/quiz/weight renderer uses shared published definition.
- [ ] Quiz one-attempt and required-answer UI mirror authoritative policy; client validation is only UX.
- [ ] Sticky CTA survives bottom nav, safe area, and virtual keyboard.

### Profile/progress

- [ ] Participant profile uses neutral blank-person fallback.
- [ ] Points/rank/weight/date formatting uses `id-ID` and tabular numerals.
- [ ] Private weight never appears in public leaderboard or telemetry.

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

