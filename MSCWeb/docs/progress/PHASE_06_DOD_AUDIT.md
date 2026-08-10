# Audit Definition of Done Phase 06

> Tanggal audit: 10 Agustus 2026
>
> Status: SELESAI LOKAL — seluruh gate termasuk fresh local migration chain
> lulus.

## Batas eksekusi

- Semua source, migration additive, test, contract, dan dokumen berada di
  `MSCWeb/`.
- Root Supabase, proyek iOS, `Contracts/`, hosted `main`, Auth production,
  bucket production, cron, deployment, dan secret production tidak diubah.
- Migration Phase 06 hanya diterapkan ke Supabase lokal untuk iterasi dan test.
- Tidak ada operasi Git mutating.

## Bukti schema, contract, dan privacy boundary

| Requirement | Bukti |
| --- | --- |
| Destination/order/evidence/ledger/event additive | `supabase/migrations/20260810090000_phase06_manual_payments.sql` |
| Immutable ledger/event | trigger immutable, revoke direct mutation, pgTAP, dan integration replay |
| Contract konsisten | `docs/contracts/MANUAL_PAYMENT_OPENAPI.yaml` dan `scripts/check-phase06-contract.mjs` |
| Bukti privat | bucket `payment-evidence` privat tanpa client policy; akses melalui route server `no-store` |
| QRIS privat/versioned | bucket `payment-destination-assets` privat, path dibatasi, dan object harus ada sebelum destination dibuat |
| Client tidak menulis state authoritative | tabel tidak memiliki INSERT/UPDATE grant client; finalisasi metadata bukti dan recurring job hanya `service_role` |
| Sanitasi foto | browser decode/re-encode; server memeriksa magic byte, struktur, dimensi, ukuran, menghapus APP1–APP15/COM, memvalidasi ulang, lalu menghitung hash dari byte bersih |
| Thumbnail | hanya object URL preview lokal maksimum 320 px; tidak diunggah atau dipertahankan server |
| Retention dan orphan | runner lokal menghapus object due/orphan sebelum menandai metadata immutable sebagai deleted |
| Account deletion | owner/order dianonimkan, bukti sesuai retention dan ledger/event tetap dipertahankan; integration menghapus profile fixture |

## Bukti operasi dan race

- Order program dan Coach menggunakan amount, destination, owner, target, dan
  reservation server snapshot.
- Submit/retry idempoten, maksimal tiga attempt, dan attempt submitted tidak
  dapat ditulis ulang.
- Approve/reject memakai actor check, row lock, version, alasan/reconciliation,
  destination match, dan amount match.
- Fulfillment program membuat enrollment/score; fulfillment Coach membuat
  payment projection, entitlement period, capability/role, dan QR secara
  atomik.
- Integration mencakup duplicate order, submit sebelum/sesudah expiry,
  approve replay, dua Admin, approve melawan reject, capacity last seat,
  late restore available/full, cancellation, reversal replay, Coach retry dan
  renewal, retention, orphan, serta account anonymization.
- BOLA mencakup Participant lain dan Coach terhadap metadata maupun object
  bukti yang benar-benar ada; Guest/session expiry diuji melalui route E2E.

## Bukti UI

- Owner: `/pembayaran/[paymentId]` dan `/akses-coach/[applicationId]`.
- Admin: `/admin/pembayaran` serta `/admin/pembayaran/[paymentId]` dengan
  filter purpose/status/date, safe identity, attempt history, viewer privat,
  confirmation approve, dan alasan reject.
- Copy Bahasa Indonesia membedakan menunggu bukti, proses upload, review,
  koreksi, approved, expired, cancelled, reversal pending, dan selesai.
- Tidak ada tindakan refund client, input Coach manual, OCR approval, dynamic
  QR, callback gateway, atau status verified dari client.
- Gallery Chromium/WebKit dan axe terakhir lulus 14 check; baseline owner
  mobile dan Admin desktop telah diperiksa visual.

## Perintah verifikasi terakhir

```bash
PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:phase06:local
PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm verify
```

Hasil:

- database lint: PASS, tanpa schema error;
- pgTAP: 37 PASS;
- integration atomicity/RLS/race/retention: PASS;
- Chromium E2E: 3 PASS;
- contract/security scan: PASS;
- lint, architecture, file-size, secret, dan localization: PASS;
- Vitest: 25 file, 105 test PASS;
- typecheck dan production build 38 halaman: PASS;
- media bundle gate: PASS.

## Fresh migration gate

Fresh local migration chain dijalankan setelah persetujuan eksplisit pengguna.
Script memverifikasi token `ALLOW_LOCAL_DB_RESET` dan hostname lokal sebelum
reset:

```bash
ALLOW_LOCAL_DB_RESET=phase06 \
PATH="/opt/homebrew/opt/node@24/bin:$PATH" \
corepack pnpm test:phase06:fresh-local
```

Hasil: PASS. Seluruh migration root existing, migration Phase 06, database
lint, dan 37 pgTAP lulus; `test:phase06:local` serta `pnpm verify` kemudian
diulang dan lulus pada schema hasil fresh chain.
