# Phase 07: Participant Experience

> Status: SELESAI LOKAL — 10 Agustus 2026

## Tujuan

Memport seluruh perjalanan program Peserta dengan multi-program state,
renderer typed, submissions, quiz, media, weigh-ins, profile, dan public
highlights menggunakan mobile app-like shell.

## Slice 07.1 — Hari ini/Home

- [x] Guest CTA dan public-safe state sesuai reference.
- [x] Participant header identity tanpa private overexposure.
- [x] Urutan section: Program, Fokus, Top 5, Pemenang, Coach.
- [x] Program focus/timezone/day active berasal dari server result.
- [x] Loading/empty/error/offline/no-active-program states.

## Slice 07.2 — Program activity

- [x] Compact progress header dan accordion hari/step.
- [x] Auto-open hari relevan; `Hari ini`, scroll, highlight memakai satu date
  result server/timezone.
- [x] Future access: available, locked, hidden; past read-only explicit.
- [x] Stable identities dan lazy rendering untuk program panjang.
- [x] Program switch tidak mencampur answers/progress/submission state.

## Slice 07.3 — Typed content renderer

- [x] Article/heading/text.
- [x] Video resume/threshold dari Phase 04.
- [x] Short/long text, number/decimal rules.
- [x] Single/multiple choice dan image choice.
- [x] Photo upload melalui private media pipeline.
- [x] Initial/daily/final weigh-in sebagai content, bukan onboarding global.
- [x] Quiz objective, completeness, one attempt, private result, no answer-key
  leakage.
- [x] Shared renderer dipakai Admin preview/Coach context tanpa copy-paste.

## Slice 07.4 — Submission lifecycle

- [x] Draft local UI state tidak mengaku durable sebelum server success.
- [x] Required answer validation dan per-field errors.
- [x] Auto-review/objective vs Coach-review subjective/photo behavior.
- [x] Pending/approved/rejected/retry/correction/reopen lifecycle.
- [x] Idempotency and duplicate submit/reload/multi-tab handling.
- [x] Cancellation ownership saat route/program/account berubah.

## Slice 07.5 — Weigh-in/privacy

- [x] Decimal parsing/format ID locale tanpa binary float authority.
- [x] Initial/final uniqueness, final-after-initial, daily step uniqueness.
- [x] Weight tidak tampil di public feed/leaderboard.
- [x] User-facing wellness/non-diagnostic copy.
- [x] No logs/analytics/cache containing weight.

## Slice 07.6 — Peringkat, Coach, Profil

- [x] Program selector, top 5/podium, current user emphasis, archive snapshot.
- [x] Equal score deterministic order; fewer than five winners.
- [x] Coach directory/profile dan `Coach-mu` badge.
- [x] Profile avatar/name/phone edit, email read-only, current Coach, legal,
  logout/delete account.
- [x] Change Coach only via QR confirmation and authoritative operation; no
  manual code.

## Verification

- [x] Port relevant Phase03/Phase06/Phase07/contract Swift test cases.
- [x] Component matrix all content/question/state variants.
- [x] Integration submissions/quiz/weigh-in/media/RLS/idempotency.
- [x] E2E critical journey: join -> pay verified fixture/local Admin -> initial
  weight -> daily content -> Coach review -> final weight -> leaderboard.
- [x] Edge cases: empty days, locked, missing answer/photo/final weight, failed
  quiz, rejection, offline, expiry, repository failure.
- [x] Accessibility/zoom/dark/mobile WebKit/Chromium screenshots.
- [x] Lint, typecheck, test, build lulus.

## Definition of done

- Semua content type dan Participant journeys parity.
- Multi-program state terisolasi per enrollment.
- Weight/photo/answer-key privacy terjaga.
- UI modular; tidak ada journey store/page/renderer besar melewati limit.

## External gate

Migration dan bucket Phase 07 baru diterapkan serta diuji pada Supabase lokal.
Hosted `main`, secrets, OAuth production, dan deployment tetap gate Phase 12
yang memerlukan persetujuan eksplisit pengguna.

## Progress log

### 10 Agustus 2026 — selesai lokal

- Files changed: domain dan contract typed program/Peserta, repository/use case
  Supabase, route submission/weigh/profile, Home/aktivitas/langkah/peringkat/
  Coach/profil, shared content preview, migration additive Phase 07, fixture,
  gallery, unit/component/pgTAP/integration/E2E, script gate, dan audit DoD.
- Assumptions: keputusan hari aktif/timezone, authorization, scoring, review,
  pembayaran, enrollment, dan perubahan Coach tetap server-authoritative;
  hosted `main` serta seluruh path di luar `MSCWeb/` tetap read-only.
- Build command:
  `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm verify`.
- Test commands:
  `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:phase07:local`
  dan `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:gallery`.
- Result: PASS — DB lint; 31 pgTAP; 15 assertion race/idempotensi; 16
  assertion media privat; satu Chromium journey gabung, transfer, verifikasi
  Admin, timbang awal, aktivitas, review Coach, timbang akhir, leaderboard;
  16 gallery Chromium/WebKit + axe; 28 file/124 Vitest; lint, typecheck,
  production build 41 halaman, dan bundle gate.
- Remaining blockers: tidak ada untuk gate lokal. Device fisik dan deployment
  hosted tetap Phase 11–13 sesuai workplan.
