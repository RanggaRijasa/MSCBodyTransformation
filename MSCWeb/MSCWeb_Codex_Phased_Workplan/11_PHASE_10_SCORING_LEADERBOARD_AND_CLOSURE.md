# Phase 10: Scoring, Leaderboard, and Closure

> Status: BELUM DIMULAI

## Tujuan

Membuktikan parity authoritative lintas role untuk scoring, rank, closure,
quiz reopen, immutable winners, poster, correction, dan full program journey.

## Slice 10.1 — Scoring contract parity

- [ ] Activity, quiz-correct, weight-loss, adjustment breakdown konsisten.
- [ ] Decimal weight loss `max(initial-final, 0)` dan rounding server-only.
- [ ] Daily weight tidak menambah weight points.
- [ ] Pending/rejected duplicate tidak menerima authoritative points.
- [ ] Correction/reconciliation idempoten and audited.
- [ ] Config lock setelah enrollment.

## Slice 10.2 — Leaderboard

- [ ] Active/history program selector.
- [ ] Deterministic ties and stable pagination/ranking.
- [ ] Top 5/podium/current-user row parity.
- [ ] Fewer than five, empty, loading, error, closed snapshot.
- [ ] No weight, private answers, evidence, phone, payment data.

## Slice 10.3 — Closure/winners

- [ ] Preflight blockers: pending review, missing final weight, failed quiz
  visibility, incomplete required state.
- [ ] Admin close/reopen allowed transitions and audit.
- [ ] Winner lock creates immutable stable snapshot once.
- [ ] Equal score policy and fewer winners tested.
- [ ] Poster publication references program + winner snapshot and cannot alter
  winners.

## Slice 10.4 — Quiz/review remediation

- [ ] Admin quiz reopen with reason, attempt sequence/history.
- [ ] Coach cannot reopen.
- [ ] Re-review/reconciliation does not duplicate points.
- [ ] Participant sees private result only; answer key remains Coach/Admin.

## Slice 10.5 — Cross-role end-to-end

- [ ] Admin creates/publishes program with payment/cutoff/capacity/scoring.
- [ ] Participant scans QR, transfers, Admin verifies, enrollment activates.
- [ ] Participant completes typed content, media, quiz, weigh-ins.
- [ ] Coach reviews subjective/photo submission.
- [ ] Server reconciles score and rank.
- [ ] Admin corrects with reason, closes, locks winners, publishes poster.
- [ ] Guest/Peserta/Coach see only correct public/private projections.

## Slice 10.6 — Landing capture readiness

- [ ] Tetapkan layar PWA Peserta, Coach, dan bila perlu Admin yang sudah lulus
  parity untuk menggantikan placeholder landing.
- [ ] Buat deterministic marketing fixture tanpa PII atau data production.
- [ ] Pastikan capture state tidak memuat berat, QR mentah, bukti transfer,
  foto privat, signed URL, email, nomor HP, token, atau identifier sensitif.
- [ ] Catat viewport, DPR, locale, theme, fixture version, dan build identifier
  agar screenshot final dapat direproduksi Phase 11.
- [ ] Jangan capture layar yang masih berbeda material dari release candidate.

## Verification

- [ ] Port Phase07/ProgramEndToEnd contract edge cases to TypeScript.
- [ ] pgTAP/integration race/idempotency/scoring/privacy tests.
- [ ] Contract compatibility web DTO/OpenAPI/SQL.
- [ ] E2E full journey Chromium + WebKit.
- [ ] Performance with realistic participant/step/leaderboard volume.
- [ ] Snapshot immutability and post-close mutation denial.
- [ ] Marketing fixture/capture states siap tanpa private data.
- [ ] Lint, typecheck, all tests, production build lulus.

## Definition of done

- Full program lifecycle parity terbukti, bukan sekadar individual screens.
- Scoring/rank/winner tetap server-authoritative dan privacy-safe.
- Manual commerce integrates without changing scoring semantics.
- Cross-role E2E menjadi release regression suite.
