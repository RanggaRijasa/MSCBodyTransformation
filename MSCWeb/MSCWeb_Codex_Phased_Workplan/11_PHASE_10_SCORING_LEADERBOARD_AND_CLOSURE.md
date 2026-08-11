# Phase 10: Scoring, Leaderboard, and Closure

> Status: SELESAI LOKAL

## Tujuan

Membuktikan parity authoritative lintas role untuk scoring, rank, closure,
quiz reopen, immutable winners, poster, correction, dan full program journey.

## Slice 10.1 — Scoring contract parity

- [x] Activity, quiz-correct, weight-loss, adjustment breakdown konsisten.
- [x] Decimal weight loss `max(initial-final, 0)` dan rounding server-only.
- [x] Daily weight tidak menambah weight points.
- [x] Pending/rejected duplicate tidak menerima authoritative points.
- [x] Correction/reconciliation idempoten and audited.
- [x] Config lock setelah enrollment.

## Slice 10.2 — Leaderboard

- [x] Active/history program selector.
- [x] Deterministic ties and stable pagination/ranking.
- [x] Top 5/podium/current-user row parity.
- [x] Fewer than five, empty, loading, error, closed snapshot.
- [x] No weight, private answers, evidence, phone, payment data.

## Slice 10.3 — Closure/winners

- [x] Preflight blockers: pending review, missing final weight, failed quiz
  visibility, incomplete required state.
- [x] Admin close/reopen allowed transitions and audit.
- [x] Winner lock creates immutable stable snapshot once.
- [x] Equal score policy and fewer winners tested.
- [x] Poster publication references program + winner snapshot and cannot alter
  winners.

## Slice 10.4 — Quiz/review remediation

- [x] Admin quiz reopen with reason, attempt sequence/history.
- [x] Coach cannot reopen.
- [x] Re-review/reconciliation does not duplicate points.
- [x] Participant sees private result only; answer key remains Coach/Admin.

## Slice 10.5 — Cross-role end-to-end

- [x] Admin creates/publishes program with payment/cutoff/capacity/scoring.
- [x] Participant scans QR, transfers, Admin verifies, enrollment activates.
- [x] Participant completes typed content, media, quiz, weigh-ins.
- [x] Coach reviews subjective/photo submission.
- [x] Server reconciles score and rank.
- [x] Admin corrects with reason, closes, locks winners, publishes poster.
- [x] Guest/Peserta/Coach see only correct public/private projections.

## Slice 10.6 — Landing capture readiness

- [x] Tetapkan layar PWA Peserta, Coach, dan bila perlu Admin yang sudah lulus
  parity untuk menggantikan placeholder landing.
- [x] Buat deterministic marketing fixture tanpa PII atau data production.
- [x] Pastikan capture state tidak memuat berat, QR mentah, bukti transfer,
  foto privat, signed URL, email, nomor HP, token, atau identifier sensitif.
- [x] Catat viewport, DPR, locale, theme, fixture version, dan build identifier
  agar screenshot final dapat direproduksi Phase 11.
- [x] Jangan capture layar yang masih berbeda material dari release candidate.

## Verification

- [x] Port Phase07/ProgramEndToEnd contract edge cases to TypeScript.
- [x] pgTAP/integration race/idempotency/scoring/privacy tests.
- [x] Contract compatibility web DTO/OpenAPI/SQL.
- [x] E2E full journey Chromium + WebKit.
- [x] Performance with realistic participant/step/leaderboard volume.
- [x] Snapshot immutability and post-close mutation denial.
- [x] Marketing fixture/capture states siap tanpa private data.
- [x] Lint, typecheck, all tests, production build lulus.

## Definition of done

- Full program lifecycle parity terbukti, bukan sekadar individual screens.
- Scoring/rank/winner tetap server-authoritative dan privacy-safe.
- Manual commerce integrates without changing scoring semantics.
- Cross-role E2E menjadi release regression suite.

## External gate

Migration Phase 10 hanya diterapkan dan diuji pada Supabase lokal. Hosted
`main`, secrets, OAuth production, DNS, dan deployment tidak disentuh; seluruh
gate tersebut tetap berada pada Phase 12 dan memerlukan persetujuan eksplisit.

## Progress log

### 10 Agustus 2026 — selesai lokal

- Files changed: migration scoring/closure dan paid publish, leaderboard,
  closure/remediasi Admin, fixture marketing, privacy/volume gate, pgTAP,
  unit/component, dan full cross-role E2E.
- Assumptions: tie diurutkan stabil dengan enrollment UUID; manual commerce
  Phase 06 dapat menerbitkan program berbayar bila harga valid dan destination
  aktif; snapshot pemenang tetap immutable.
- Build command:
  `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm verify`.
- Test commands:
  `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:phase10:local`
  dan `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:gallery`.
- Result: PASS — DB lint; 63 pgTAP; 47 unit/component fokus; tujuh regresi
  Chromium; dua full journey Chromium/WebKit; 30 gallery + axe; 33 file/154
  Vitest; lint, architecture, typecheck, production build 39 halaman, privacy,
  contract, dan bundle gate.
- Remaining blockers: tidak ada untuk gate lokal. Hosted deployment tetap
  Phase 12 sesuai workplan.
