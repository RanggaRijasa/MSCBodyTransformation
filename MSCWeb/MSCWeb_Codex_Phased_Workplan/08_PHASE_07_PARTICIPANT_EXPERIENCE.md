# Phase 07: Participant Experience

> Status: BELUM DIMULAI

## Tujuan

Memport seluruh perjalanan program Peserta dengan multi-program state,
renderer typed, submissions, quiz, media, weigh-ins, profile, dan public
highlights menggunakan mobile app-like shell.

## Slice 07.1 — Hari ini/Home

- [ ] Guest CTA dan public-safe state sesuai reference.
- [ ] Participant header identity tanpa private overexposure.
- [ ] Urutan section: Program, Fokus, Top 5, Pemenang, Coach.
- [ ] Program focus/timezone/day active berasal dari server result.
- [ ] Loading/empty/error/offline/no-active-program states.

## Slice 07.2 — Program activity

- [ ] Compact progress header dan accordion hari/step.
- [ ] Auto-open hari relevan; `Hari ini`, scroll, highlight memakai satu date
  result server/timezone.
- [ ] Future access: available, locked, hidden; past read-only explicit.
- [ ] Stable identities dan lazy rendering untuk program panjang.
- [ ] Program switch tidak mencampur answers/progress/submission state.

## Slice 07.3 — Typed content renderer

- [ ] Article/heading/text.
- [ ] Video resume/threshold dari Phase 04.
- [ ] Short/long text, number/decimal rules.
- [ ] Single/multiple choice dan image choice.
- [ ] Photo upload melalui private media pipeline.
- [ ] Initial/daily/final weigh-in sebagai content, bukan onboarding global.
- [ ] Quiz objective, completeness, one attempt, private result, no answer-key
  leakage.
- [ ] Shared renderer dipakai Admin preview/Coach context tanpa copy-paste.

## Slice 07.4 — Submission lifecycle

- [ ] Draft local UI state tidak mengaku durable sebelum server success.
- [ ] Required answer validation dan per-field errors.
- [ ] Auto-review/objective vs Coach-review subjective/photo behavior.
- [ ] Pending/approved/rejected/retry/correction/reopen lifecycle.
- [ ] Idempotency and duplicate submit/reload/multi-tab handling.
- [ ] Cancellation ownership saat route/program/account berubah.

## Slice 07.5 — Weigh-in/privacy

- [ ] Decimal parsing/format ID locale tanpa binary float authority.
- [ ] Initial/final uniqueness, final-after-initial, daily step uniqueness.
- [ ] Weight tidak tampil di public feed/leaderboard.
- [ ] User-facing wellness/non-diagnostic copy.
- [ ] No logs/analytics/cache containing weight.

## Slice 07.6 — Peringkat, Coach, Profil

- [ ] Program selector, top 5/podium, current user emphasis, archive snapshot.
- [ ] Equal score deterministic order; fewer than five winners.
- [ ] Coach directory/profile dan `Coach-mu` badge.
- [ ] Profile avatar/name/phone edit, email read-only, current Coach, legal,
  logout/delete account.
- [ ] Change Coach only via QR confirmation and authoritative operation; no
  manual code.

## Verification

- [ ] Port relevant Phase03/Phase06/Phase07/contract Swift test cases.
- [ ] Component matrix all content/question/state variants.
- [ ] Integration submissions/quiz/weigh-in/media/RLS/idempotency.
- [ ] E2E critical journey: join -> pay verified fixture/local Admin -> initial
  weight -> daily content -> Coach review -> final weight -> leaderboard.
- [ ] Edge cases: empty days, locked, missing answer/photo/final weight, failed
  quiz, rejection, offline, expiry, repository failure.
- [ ] Accessibility/zoom/dark/mobile WebKit/Chromium screenshots.
- [ ] Lint, typecheck, test, build lulus.

## Definition of done

- Semua content type dan Participant journeys parity.
- Multi-program state terisolasi per enrollment.
- Weight/photo/answer-key privacy terjaga.
- UI modular; tidak ada journey store/page/renderer besar melewati limit.

