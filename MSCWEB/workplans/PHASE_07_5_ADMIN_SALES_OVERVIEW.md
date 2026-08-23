# MSCWEB W07.5 — Admin Sales Overview

Status: `Deferred post-launch — not a first-deployment dependency (owner decision 21 August 2026)`
Autonomy: `A` against local Supabase; `D` for hosted deployment or production financial smoke  
Depends on when resumed: deployed core baseline, completed W07 Admin experience/W07.4 onboarding remediation, and reproducible W05/W06 payment ledger/reversal contract

Scheduling authority: [`ADR-0010`](../decisions/0010-defer-admin-analytics-and-storage-management.md). This workplan remains the implementation authority after launch, but none of its unchecked items block W08/W09 or the first production deployment.

## Objective

Add an Admin-only `Ringkasan penjualan` opened from Dashboard `Akses cepat`, with authoritative manual-web revenue analytics for program purchases and Coach access. Keep financial totals reconcilable to the append-only payment ledger, privacy-minimized, responsive, accessible, and independent of external analytics vendors.

## Required references

- `00_PRODUCT_SPEC.md` `PROD-SLS-*`
- `01_ARCHITECTURE.md` Admin sales reporting boundary
- `02_UX_PARITY_AND_ROUTES.md` `UX-SLS-*`
- `03_DESIGN_SYSTEM.md` chart/icon/component rules
- `04_MANUAL_PAYMENT.md` order/reversal policy
- `05_DATA_SECURITY.md` `SEC-DATA-009…011`, `SEC-OP-005`, privacy/logging
- `07_TESTING_ACCEPTANCE.md` `QA-SLS-*` and `QA-JRN-012`
- [`ADR-0007`](../decisions/0007-admin-sales-ledger-reporting.md)
- W05/W06/W07 migrations, generated database types, integration tests, and current Admin Dashboard runtime

## In scope

- manual web payment ledger only;
- program enrollment and three-month Coach-access sales;
- 7/30/90-day and custom ranges in WITA;
- gross, reversal, net, verified-order count, average gross order, daily trend;
- purpose/program/customer breakdown and non-revenue order pipeline;
- Admin Quick Access, route, domain/repository/query/UI, migration/RPC/index/tests.

## Out of scope

- StoreKit, Google Play, payment gateway, tax/accounting statements, invoices, payout reconciliation, forecasting, attribution cookies, external analytics, CSV export, and arbitrary SQL/report builder;
- sales-by-payment-source based on `declared_method`;
- editing transactions, reversals, orders, or customers from the analytics screen.

## Deliverables

- reconciled migration chain for manual reversal authority and generated types;
- append-only reversal remediation plus separate exceptional cash-adjustment authority;
- narrow Admin-only `get_admin_sales_overview(from_at, to_at, timezone, purpose?)` RPC;
- measured reporting indexes and query-plan evidence;
- typed sales domain/repository/query boundary;
- `/admin/sales` route and responsive overview components;
- third Quick Access card plus reusable wrapping grid that supports the final fourth card in W07.6;
- deterministic unit/database/integration/E2E/visual/accessibility tests;
- no hosted data mutation or financial export.

## Mandatory simulator and web-extension gate

- [ ] Fresh-build/launch iOS Admin Dashboard; record device, OS, locale, scenario, two native quick actions, metric hierarchy, scroll/bottom-nav behavior.
- [ ] Mark `Ringkasan penjualan` as intentional web-only scope; do not add a sixth Admin tab or modify iOS.
- [ ] Compare compact card sizing/spacing to the current two-action runtime, then document the temporary three-card and final four-card responsive behavior.
- [ ] Inspect the user-provided sales screenshot only for hierarchy/density; do not copy Wix blue styling, English labels, initials avatar, or `null` placeholders.

## Checklist

### Contract and reproducibility prerequisite

- [ ] Reconcile committed migrations, local schema, and `database.types.ts` for `declared_method`, `instructions_snapshot`, `record_exceptional_reversal`, and every ledger/reversal field used by reporting.
- [ ] Replace `unique(order_id, entry_kind)` with one-verified-per-order constraint plus multiple reversal rows keyed by idempotency and related verified entry.
- [ ] Define revenue reversal amount, cumulative `<= verified` constraint, recognition timestamp, reason/status, and relation to verified ledger.
- [ ] Add separate exceptional cash-adjustment record/operation for late/rejected-but-paid, duplicate transfer, and overpayment difference; these movements never enter sales net.
- [ ] Add private durable customer-reporting key and non-null snapshot on new payment orders before account deletion; do not persist contact fields for reporting.
- [ ] Backfill one key per known owner. Existing null-owner orders that cannot be reconstructed become separate deterministic per-order unknown groups rather than one merged customer.
- [ ] Map complete order states, including `reversal_pending` and `reversed`, to pipeline labels without treating either status alone as ledger money.
- [ ] A clean local migration chain MUST reproduce partial, multiple, full, period-crossing, unmatched/refused revenue reversals and non-revenue cash adjustments before net-sales implementation proceeds.
- [ ] Document canonical formulas and recognition timestamps in tests/spec; no client-side money arithmetic from formatted strings.

### Sales authority and RPC

- [ ] Use `payment_ledger` only for money: gross `verified`, reversal `reversal`, net gross minus reversal.
- [ ] Join `payment_orders` only for purpose/program/owner/order-state dimensions; use current published program title and stable program ID.
- [ ] Include both purposes with server allowlist `all | program_enrollment | coach_access`.
- [ ] Validate Admin, timezone `Asia/Makassar`, inclusive `from_at`, exclusive `to_at`, maximum 366-day range, and IDR.
- [ ] Return fixed projection: summary, daily buckets, purpose breakdown, program rows, top-customer rows, and order pipeline.
- [ ] Top-customer projection groups by immutable reporting key and contains opaque `customer_group_id`, nullable `person_id`, safe display name, distinct verified-order count, gross/reversal/net only. Missing/deleted profile maps to `Pengguna dihapus`, never email.
- [ ] Program/customer top lists each limit five and sort by net desc, gross desc, verified-order count desc, then stable ID asc; duplicate display names never merge.
- [ ] Pending/correction/rejected/expired/cancelled order values remain pipeline, not revenue.
- [ ] Approved order without verified ledger is excluded and exposed only through an integrity count for Admin attention/testing.
- [ ] Never return bank/account/destination snapshot, declared method, reconciliation reference, reviewer, proof/media metadata/path, email, phone, member level, or raw audit payload.

### Query performance

- [ ] Create representative ledger/order fixtures across date, purpose, program, owner, and entry kind.
- [ ] Run `EXPLAIN (ANALYZE, BUFFERS)` before/after index changes.
- [ ] Prefer composite equality/range and partial indexes matching actual predicates; include amount/order columns only when the plan benefits.
- [ ] Verify no duplicate/redundant index and run local Supabase security/performance advisors.
- [ ] Keep live aggregate baseline. Stop and create a new ADR before materialized view/warehouse/cache authority.

### UI and Quick Access

- [ ] Add semantic `salesOverview` icon through `MSCIcon`; no new icon/chart dependency.
- [ ] Preserve `Buat program` and `Tambah poster` order. Add `Ringkasan penjualan` and make Quick Access grid safely wrap; W07.6 supplies the fourth final card.
- [ ] Route `/admin/sales` uses Admin guard, `activeRoute="dashboard"`, browser history/back, loading/empty/error/stale/offline states.
- [ ] Default 30 days; 7/30/90/custom and purpose filter use shared segmented/filter patterns.
- [ ] KPI: `Penjualan bersih`, `Terverifikasi`, `Pembalikan`, `Order terverifikasi`, `Rata-rata order` with `id-ID` currency/tabular numerals.
- [ ] Daily trend uses simple SVG/primitives plus exact accessible table/list; reduced motion and no color-only meaning.
- [ ] Purpose/program/customer/pipeline sections handle zero, reversal-only, ties, long Indonesian names, and fewer than top-five entries.
- [ ] Customer row opens existing authorized Admin Person detail; no email/phone on overview.
- [ ] No analytics/export/network call outside Supabase local.

## Sub-agent plan

- `msc_explorer`: map final ledger/reversal migrations, Admin dashboard parity, and query plan/index evidence.
- `msc_implementer`: sole writer, sequentially reproducibility/migration → RPC/tests → UI/E2E.
- `msc_reviewer`: financial arithmetic/double-counting, authorization/privacy, query performance, Quick Access regression, accessibility/responsiveness.

Primary agent owns formulas, migration authority, date/time semantics, and reconciliation evidence.

## Verification

- `QA-JRN-012` and all `QA-SLS-*`;
- clean migration-chain and generated-types consistency;
- non-Admin denial and safe response-shape tests;
- gross/reversal/net/order/average arithmetic including multiple partial/full/period-crossing reversal, cumulative-overflow denial, unmatched/refused reversal, non-revenue cash adjustment, two deleted customers/multiple orders, legacy null-owner grouping, approved-without-ledger, pending-only, reversal-only, and zero periods;
- WITA boundary and inclusive/exclusive range tests;
- no ledger + commerce double count;
- query-plan/index/advisor evidence;
- component/Playwright compact+wide, keyboard, screen reader, dark/light, 200% zoom, browser Back, Quick Access and Activity scroll regression;
- bundle/log scan for financial PII/private payment fields.

## Exit criteria

- Admin can open `/admin/sales` from Quick Access and reconcile every displayed total to deterministic ledger fixtures.
- Pending/rejected orders and commerce projection never inflate revenue.
- Both program and Coach-access sales filter correctly in WITA.
- Revenue reversals and exceptional cash returns have reproducible, non-overlapping authority and period semantics.
- No private payment/customer data leaves the fixed Admin projection.
- Query plan, security, accessibility, responsive, regression, and production build gates pass.

## User input or authorization

- No additional product input is required for local implementation: baseline is both manual-web purposes, 30 days WITA, no export/cross-channel analytics.
- Hosted migration/RPC deployment and any production financial smoke/read require explicit authorization and approved Admin identity/scope.
- Cross-channel App Store/Google Play reporting, exports, accounting/tax semantics, or external analytics require a separate product decision/ADR.

## Progress log

Append requirement IDs, simulator evidence, formula/version, migration/type reconciliation, query plans/indexes/advisors, UI/visual evidence, commands/results, external authorization, and next item.
