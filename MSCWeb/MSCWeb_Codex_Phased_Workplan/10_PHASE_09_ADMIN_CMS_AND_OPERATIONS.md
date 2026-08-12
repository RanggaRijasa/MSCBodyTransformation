# Phase 09: Admin CMS and Operations

> Presentation amendment: functional implementation phase ini tetap baseline,
> tetapi keputusan visual desktop-first lama digantikan Phase 11A. Admin mobile
> mengikuti aplikasi iPhone; desktop/tablet menjadi responsive expansion dari
> sistem visual yang sama.

> Status: SELESAI LOKAL

## Tujuan

Memport seluruh Admin surface menjadi desktop-first responsive CMS dan
operations console, termasuk dashboard, payments, programs, people, content,
preview, audit, dan privileged mutations.

## Slice 09.1 — Dashboard/navigation

- [x] Admin `/admin` default dengan sidebar desktop/mobile fallback.
- [x] Action counts: payment review, Coach application, submission/closure
  blockers, system attention, recent audit safe summary.
- [x] Quick actions tidak menduplikasi sidebar.
- [x] Unauthorized/non-Admin fail closed tanpa resource disclosure.

## Slice 09.2 — Program list/lifecycle

- [x] Search/filter/status, create draft, duplicate-as-draft.
- [x] Published read-only and explicit controlled operations.
- [x] Registration deadline/capacity/timezone/price/payment destination policy.
- [x] Archive/closure state sesuai server lifecycle.

## Slice 09.3 — Draft settings/editor

- [x] Identity, cover/alt text, category/summary.
- [x] Schedule, timezone, duration/access-day policy, capacity/cutoff.
- [x] Program-wide scoring and quiz threshold lock rules.
- [x] Hari/langkah/content/question editors seluruh typed variants.
- [x] Copy day content to multiple targets dengan new nested IDs dan overwrite
  confirmation.
- [x] File terpisah per editor/capability; jangan port giant Swift View.

## Slice 09.4 — Preview/publish

- [x] Peserta/Coach segmented preview wrapper.
- [x] Runtime shared renderer, not Admin-only duplicate card hierarchy.
- [x] Lossless draft round-trip and publish validation summary.
- [x] Publish protected operation and post-publish read-only projection.
- [x] Duplicate program does not copy enrollment/payment/runtime/winners.

## Slice 09.5 — People/Coach applications

- [x] Segmented Peserta/Coach/Admin directory and role-specific detail.
- [x] Coach application eligibility/accept/reject/reason/payment status.
- [x] Manual enrollment after cutoff only deadline override; all other guards
  remain and reason audited.
- [x] Coach transfer with reason; weight/score corrections with audit.
- [x] Admin account restrictions and no editable role metadata shortcut.

## Slice 09.6 — Payment operations

- [x] Extend Phase 06 queue with metrics, search, filters, attempt/ledger/events,
  destination management, refund/revoke/cancel actions per policy.
- [x] Dual-control/confirmation requirement if decided Phase 00.
- [x] Evidence viewer no public caching/download leakage.
- [x] Operational export, if needed, excludes evidence and excessive PII by
  default; scope must be explicitly approved.

## Slice 09.7 — Managed content and audit

- [x] Winner poster gallery, 9:16 preview, add/replace/delete/publish.
- [x] Winner snapshot remains leaderboard-owned; content gallery does not edit
  ranking.
- [x] Audit list/detail with allowlisted metadata, actor/time/reason.
- [x] Legal/settings surface uses true backend/config values only.

## Verification

- [x] Port Phase05 Admin CMS and contract tests.
- [x] Draft round-trip/publish/duplicate/copy-day/validation tests.
- [x] Integration Admin authorization/idempotency/race/audit/storage.
- [x] E2E Admin create -> content -> preview -> publish; payment review; Coach
  approval; correction; closure preflight; poster publish.
- [x] Desktop wide/tablet/mobile fallback screenshots and keyboard navigation.
- [x] Large dataset pagination/virtualization/performance and empty/error states.
- [x] Lint, typecheck, test, build lulus.

## Definition of done

- Admin mengelola seluruh production capability tanpa direct table editor.
- Privileged mutation protected, idempotent, reasoned, and audited.
- Shared renderer prevents preview drift.
- Admin UI desktop-useful, mobile-operable, and modular.

## External gate

Migration Phase 09 hanya diterapkan dan diuji pada Supabase lokal. Hosted
`main`, secrets, OAuth production, DNS, dan deployment tidak disentuh; seluruh
gate tersebut tetap berada pada Phase 12 dan memerlukan persetujuan eksplisit.

## Progress log

### 10 Agustus 2026 — selesai lokal

- Files changed: domain dan use case Admin, repository Supabase, protected
  mutations, dashboard/program editor/people/payments/content/settings,
  migration additive, gallery, serta unit/component/pgTAP/E2E.
- Assumptions: operasi privileged tetap server-authoritative; confirmation
  tunggal mengikuti keputusan Phase 00 karena dual-control tidak diwajibkan;
  export operasional tidak dibuat karena belum ada scope eksplisit.
- Build command:
  `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm verify`.
- Test commands:
  `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:phase09:local`
  dan `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:gallery`.
- Result: PASS — DB lint; 53 pgTAP; 13 unit/component fokus; enam Chromium
  journey; 26 gallery Chromium/WebKit + axe; 32 file/145 Vitest; lint,
  architecture, typecheck, production build 39 halaman, dan bundle gate.
- Remaining blockers: tidak ada untuk gate lokal. Deployment hosted tetap
  Phase 12 sesuai workplan.
