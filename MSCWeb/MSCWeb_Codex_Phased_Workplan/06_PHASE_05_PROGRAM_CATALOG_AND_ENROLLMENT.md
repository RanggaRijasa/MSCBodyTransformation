# Phase 05: Program Catalog and Enrollment

> Status: SELESAI LOKAL

## Tujuan

Memport public catalog, program offer/activity routing, QR Coach preflight,
free enrollment, dan handoff payment order untuk program berbayar.

## Prasyarat

- Phase 03 Auth dan Phase 04 QR seam selesai.
- Contract Phase 00 telah menetapkan capacity/reservation/payment policy.

## Slice 05.1 — Public catalog

- [x] Program public-safe server read dengan status published/scheduled/
  active/completed dan registration cutoff.
- [x] Katalog Peserta: `Diikuti`, `Tersedia`, `Riwayat`.
- [x] Guest tidak menerima enrollment/profile/payment projection.
- [x] Program detail menampilkan cover, ringkasan, periode/timezone, Coach
  requirement, layanan, scoring summary, capacity, cutoff, dan status.
- [x] Program closed tetap dapat dilihat; join disabled dan scanner tidak
  dibuka.

## Slice 05.2 — Multi-program context

- [x] Fokus program dan state selalu keyed by `enrollmentID`/`programID`.
- [x] Route offer vs activity ditentukan server read model, bukan client flag.
- [x] Tab/scroll/history state tidak bocor antarprogram.
- [x] Guest pending program intent survive Auth sesuai TTL, lalu direvalidasi.

## Slice 05.3 — QR Coach preflight

- [x] Scan QR hanya setelah actor authenticated dan program eligible.
- [x] Server memvalidasi opaque payload, Coach approved/active, same-Coach
  rule, cutoff, capacity, lifecycle, duplicate enrollment, dan ownership.
- [x] Raw QR tidak dipersist di browser storage, URL, log, analytics, atau UI.
- [x] Validasi menampilkan nama Coach untuk konfirmasi tanpa membuka ID mentah.
- [x] Invalid/mismatch/expired/inactive/permission/offline typed states.

## Slice 05.4 — Enrollment paths

- [x] Program gratis: protected idempotent operation membuat enrollment dan
  score entry atomik.
- [x] Program berbayar: repository interface membuat server-owned payment
  order/preflight tanpa harga atau owner authoritative dari client.
- [x] Capacity/reservation UI menjelaskan expiry sesuai Phase 00.
- [x] Duplicate click/reload/multi-tab menghasilkan order/enrollment yang sama
  atau typed conflict, bukan double state.
- [x] Admin manual enrollment tetap di luar phase ini dan tidak boleh melewati
  payment/capacity/Coach guard selain deadline override yang diaudit.

## Slice 05.5 — Presentation

- [x] Loading, empty, error, offline, unavailable, closed, capacity full,
  duplicate, waiting payment, active, history.
- [x] Join action lewat centralized Auth gate.
- [x] Tidak ada typed invite/manual Coach code atau hidden digital unlock.
- [x] Harga hanya amount snapshot/server read; belum ada fake verified state.

## Verification

- [x] Domain/unit tests date/timezone/cutoff/capacity/same-Coach/idempotency.
- [x] Contract tests DTO and stable enum mappings.
- [x] Local Supabase integration Guest/public, QR validation, free enrollment,
  paid order preflight interface, RLS/BOLA/race.
- [x] E2E Guest catalog -> login intent; closed program; free join; paid handoff;
  duplicate; mismatch QR; capacity race.
- [x] Screenshot/accessibility mobile catalog/detail/scanner states.
- [x] Lint, typecheck, test, build lulus.

## Definition of done

- Catalog dan route public tidak bocor PII.
- Free enrollment authoritative dan idempoten.
- Paid program berhenti pada valid server-owned payment order, bukan client
  entitlement.
- Multi-program/QR/cutoff/capacity rules parity dengan backend iOS.

## Progress log

### 10 Agustus 2026 — selesai lokal

- Files changed: domain/program repository dan mapper di `src/domain/programs`
  serta `src/infrastructure/supabase/programs`; katalog, detail, dan alur QR di
  `src/features/programs`; route program dan endpoint enrollment/payment-order;
  test unit, component, gallery, race integration, dan E2E lokal Phase 05.
- Assumptions: Supabase root dan hosted `main` tetap read-only; kontrak manual
  payment additive Phase 06 dipakai lokal hanya untuk handoff order berbayar.
- Build command: `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm verify`.
- Test commands: `corepack pnpm test:phase05:local` dan
  `corepack pnpm test:gallery`.
- Result: PASS — 102 Vitest, production build 38 halaman, 49 pgTAP existing,
  12 assertion race/BOLA, 4 Chromium E2E lokal, serta 10 gallery checks pada
  Chromium/WebKit. Baseline katalog, detail mobile, dan pemindai QR diperiksa
  secara visual.
- Remaining blockers: tidak ada untuk gate lokal. Hosted migration/deployment
  tetap external gate Phase 12 dan tidak dijalankan.
