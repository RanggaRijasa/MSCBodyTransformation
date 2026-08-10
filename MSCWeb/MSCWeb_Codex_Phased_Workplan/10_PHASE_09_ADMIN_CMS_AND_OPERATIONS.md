# Phase 09: Admin CMS and Operations

> Status: BELUM DIMULAI

## Tujuan

Memport seluruh Admin surface menjadi desktop-first responsive CMS dan
operations console, termasuk dashboard, payments, programs, people, content,
preview, audit, dan privileged mutations.

## Slice 09.1 — Dashboard/navigation

- [ ] Admin `/admin` default dengan sidebar desktop/mobile fallback.
- [ ] Action counts: payment review, Coach application, submission/closure
  blockers, system attention, recent audit safe summary.
- [ ] Quick actions tidak menduplikasi sidebar.
- [ ] Unauthorized/non-Admin fail closed tanpa resource disclosure.

## Slice 09.2 — Program list/lifecycle

- [ ] Search/filter/status, create draft, duplicate-as-draft.
- [ ] Published read-only and explicit controlled operations.
- [ ] Registration deadline/capacity/timezone/price/payment destination policy.
- [ ] Archive/closure state sesuai server lifecycle.

## Slice 09.3 — Draft settings/editor

- [ ] Identity, cover/alt text, category/summary.
- [ ] Schedule, timezone, duration/access-day policy, capacity/cutoff.
- [ ] Program-wide scoring and quiz threshold lock rules.
- [ ] Hari/langkah/content/question editors seluruh typed variants.
- [ ] Copy day content to multiple targets dengan new nested IDs dan overwrite
  confirmation.
- [ ] File terpisah per editor/capability; jangan port giant Swift View.

## Slice 09.4 — Preview/publish

- [ ] Peserta/Coach segmented preview wrapper.
- [ ] Runtime shared renderer, not Admin-only duplicate card hierarchy.
- [ ] Lossless draft round-trip and publish validation summary.
- [ ] Publish protected operation and post-publish read-only projection.
- [ ] Duplicate program does not copy enrollment/payment/runtime/winners.

## Slice 09.5 — People/Coach applications

- [ ] Segmented Peserta/Coach/Admin directory and role-specific detail.
- [ ] Coach application eligibility/accept/reject/reason/payment status.
- [ ] Manual enrollment after cutoff only deadline override; all other guards
  remain and reason audited.
- [ ] Coach transfer with reason; weight/score corrections with audit.
- [ ] Admin account restrictions and no editable role metadata shortcut.

## Slice 09.6 — Payment operations

- [ ] Extend Phase 06 queue with metrics, search, filters, attempt/ledger/events,
  destination management, refund/revoke/cancel actions per policy.
- [ ] Dual-control/confirmation requirement if decided Phase 00.
- [ ] Evidence viewer no public caching/download leakage.
- [ ] Operational export, if needed, excludes evidence and excessive PII by
  default; scope must be explicitly approved.

## Slice 09.7 — Managed content and audit

- [ ] Winner poster gallery, 9:16 preview, add/replace/delete/publish.
- [ ] Winner snapshot remains leaderboard-owned; content gallery does not edit
  ranking.
- [ ] Audit list/detail with allowlisted metadata, actor/time/reason.
- [ ] Legal/settings surface uses true backend/config values only.

## Verification

- [ ] Port Phase05 Admin CMS and contract tests.
- [ ] Draft round-trip/publish/duplicate/copy-day/validation tests.
- [ ] Integration Admin authorization/idempotency/race/audit/storage.
- [ ] E2E Admin create -> content -> preview -> publish; payment review; Coach
  approval; correction; closure preflight; poster publish.
- [ ] Desktop wide/tablet/mobile fallback screenshots and keyboard navigation.
- [ ] Large dataset pagination/virtualization/performance and empty/error states.
- [ ] Lint, typecheck, test, build lulus.

## Definition of done

- Admin mengelola seluruh production capability tanpa direct table editor.
- Privileged mutation protected, idempotent, reasoned, and audited.
- Shared renderer prevents preview drift.
- Admin UI desktop-useful, mobile-operable, and modular.

