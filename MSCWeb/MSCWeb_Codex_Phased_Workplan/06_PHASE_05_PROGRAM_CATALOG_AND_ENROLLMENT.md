# Phase 05: Program Catalog and Enrollment

> Status: BELUM DIMULAI

## Tujuan

Memport public catalog, program offer/activity routing, QR Coach preflight,
free enrollment, dan handoff payment order untuk program berbayar.

## Prasyarat

- Phase 03 Auth dan Phase 04 QR seam selesai.
- Contract Phase 00 telah menetapkan capacity/reservation/payment policy.

## Slice 05.1 — Public catalog

- [ ] Program public-safe server read dengan status published/scheduled/
  active/completed dan registration cutoff.
- [ ] Katalog Peserta: `Diikuti`, `Tersedia`, `Riwayat`.
- [ ] Guest tidak menerima enrollment/profile/payment projection.
- [ ] Program detail menampilkan cover, ringkasan, periode/timezone, Coach
  requirement, layanan, scoring summary, capacity, cutoff, dan status.
- [ ] Program closed tetap dapat dilihat; join disabled dan scanner tidak
  dibuka.

## Slice 05.2 — Multi-program context

- [ ] Fokus program dan state selalu keyed by `enrollmentID`/`programID`.
- [ ] Route offer vs activity ditentukan server read model, bukan client flag.
- [ ] Tab/scroll/history state tidak bocor antarprogram.
- [ ] Guest pending program intent survive Auth sesuai TTL, lalu direvalidasi.

## Slice 05.3 — QR Coach preflight

- [ ] Scan QR hanya setelah actor authenticated dan program eligible.
- [ ] Server memvalidasi opaque payload, Coach approved/active, same-Coach
  rule, cutoff, capacity, lifecycle, duplicate enrollment, dan ownership.
- [ ] Raw QR tidak dipersist di browser storage, URL, log, analytics, atau UI.
- [ ] Validasi menampilkan nama Coach untuk konfirmasi tanpa membuka ID mentah.
- [ ] Invalid/mismatch/expired/inactive/permission/offline typed states.

## Slice 05.4 — Enrollment paths

- [ ] Program gratis: protected idempotent operation membuat enrollment dan
  score entry atomik.
- [ ] Program berbayar: repository interface membuat server-owned payment
  order/preflight tanpa harga atau owner authoritative dari client.
- [ ] Capacity/reservation UI menjelaskan expiry sesuai Phase 00.
- [ ] Duplicate click/reload/multi-tab menghasilkan order/enrollment yang sama
  atau typed conflict, bukan double state.
- [ ] Admin manual enrollment tetap di luar phase ini dan tidak boleh melewati
  payment/capacity/Coach guard selain deadline override yang diaudit.

## Slice 05.5 — Presentation

- [ ] Loading, empty, error, offline, unavailable, closed, capacity full,
  duplicate, waiting payment, active, history.
- [ ] Join action lewat centralized Auth gate.
- [ ] Tidak ada typed invite/manual Coach code atau hidden digital unlock.
- [ ] Harga hanya amount snapshot/server read; belum ada fake verified state.

## Verification

- [ ] Domain/unit tests date/timezone/cutoff/capacity/same-Coach/idempotency.
- [ ] Contract tests DTO and stable enum mappings.
- [ ] Local Supabase integration Guest/public, QR validation, free enrollment,
  paid order preflight interface, RLS/BOLA/race.
- [ ] E2E Guest catalog -> login intent; closed program; free join; paid handoff;
  duplicate; mismatch QR; capacity race.
- [ ] Screenshot/accessibility mobile catalog/detail/scanner states.
- [ ] Lint, typecheck, test, build lulus.

## Definition of done

- Catalog dan route public tidak bocor PII.
- Free enrollment authoritative dan idempoten.
- Paid program berhenti pada valid server-owned payment order, bukan client
  entitlement.
- Multi-program/QR/cutoff/capacity rules parity dengan backend iOS.

