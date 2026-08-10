# Phase 00: Baseline and Contract Freeze

> Status: BELUM DIMULAI

## Tujuan

Menghasilkan baseline replatforming yang dapat diaudit sebelum ada scaffold,
dependency, schema, atau hosted mutation. Phase ini menyelesaikan contract
drift dan keputusan produk manual payment yang akan memengaruhi semua phase.

## Required reading

- `00_START_HERE.md` dan `DECISION_REGISTER.md`.
- `../docs/decisions/PHASE_00_MANUAL_COMMERCE_DECISIONS.md`.
- Seluruh `../docs/architecture`.
- Root remediation workplan, contract matrix, implementation status.
- `../../Documentation/Release/HOSTED_MAIN_DEPLOYMENT_2026-08-09.md`.
- `../../UI_SCREEN_INVENTORY.md` dan test inventory di
  `../../MSCBodyTransformationTests` serta
  `../../MSCBodyTransformationUITests`.

## Di dalam scope

- Snapshot read-only source iOS, local Supabase, hosted-main deployment record,
  migrations, Edge Functions, cron, Auth providers, buckets, dan OpenAPI.
- Parity matrix per capability/role/state.
- Contract reconciliation khusus Coach application dan manual commerce.
- Product decision manual transfer/reservation/refund/retention.
- Migration/decommission strategy forward-only.
- Fixture strategy dan test case mapping.

## Di luar scope

- Next.js scaffold atau package install.
- Migration SQL baru.
- Mutation hosted main/Auth/Storage/DNS/domain.
- Menghapus Apple/StoreKit/Swift source.

## Known baseline yang wajib diverifikasi

- Hosted main telah menerima 20 migration, sembilan Edge Functions, tiga cron,
  SSL enforcement, legal endpoint, Google dan Apple Auth provider.
- Store product mapping/credential Apple production belum lengkap.
- Source iOS dan OpenAPI dapat mengandung status contract yang lebih lama.
- OpenAPI Coach application state harus dibandingkan dengan constraint SQL
  terbaru; jangan menghasilkan TypeScript types sebelum mismatch ditutup.
- Commerce Phase 12 masih store-centric dan tidak boleh diisi nilai palsu
  seperti provider `manual` tanpa schema yang benar.

## Slice 00.1 — Inventory dan hash baseline

- [ ] Catat `git status` read-only dan jangan menyentuh user changes.
- [ ] Inventaris source/lines/tests per feature iOS.
- [ ] Inventaris migration, schema, RPC, grants, RLS, buckets, functions, cron,
  dan provider yang aktif berdasarkan local serta deployment record.
- [ ] Catat contract/model/status enum yang benar-benar digunakan SQL terbaru.
- [ ] Buat manifest hash untuk source backend/contract yang akan dijadikan
  referensi transfer ownership di Phase 13.
- [ ] Bedakan fakta source, fakta local runtime, fakta hosted, dan deferred
  manual gate; jangan menggabungkannya menjadi satu status palsu.

## Slice 00.2 — Parity contract

- [ ] Petakan seluruh route dan capability Guest/Peserta, Coach, Admin.
- [ ] Petakan seluruh content/question type, access-day state, submission,
  quiz, weigh-in, scoring, leaderboard, winner, poster, dan account lifecycle.
- [ ] Tandai konsep historis yang dilarang: program invite, typed QR fallback,
  wallet/seat credit, access non-public, poin per langkah, global weigh-in.
- [ ] Petakan test Swift/XCUI ke test web target dan edge cases.
- [ ] Catat deliberate web adaptations untuk navigation, sheets, media,
  permissions, install, offline, dan Admin desktop.

## Slice 00.3 — Manual payment product gate

- [ ] Putuskan rekening tujuan dan siapa yang boleh mengelola.
- [ ] Rekonsiliasi rekening berversi dan optional gambar QRIS statis; QRIS
  bukan payment gateway atau verifikasi otomatis.
- [ ] Putuskan nominal snapshot, mata uang IDR, dan apakah nominal unik dipakai.
- [ ] Putuskan reservation TTL program; rekomendasi awal audit adalah 24 jam.
- [ ] Putuskan bahwa bukti yang submitted sebelum expiry mempertahankan
  reservation selama review atau tentukan alternatif yang aman.
- [ ] Putuskan transfer terlambat, capacity full, duplicate payment, salah
  rekening/nominal, program batal, refund, cancellation, dan revoke.
- [ ] Putuskan jumlah retry evidence dan expiry setelah rejection.
- [ ] Putuskan SLA review Admin dan copy status Peserta/Coach.
- [ ] Putuskan file type/size, retention, deletion, dan audit data bukti.
- [ ] Konfirmasi urutan Coach: eligibility diterima sebelum diminta membayar;
  bukti ditolak tidak membatalkan acceptance.
- [ ] Konfirmasi periode serta renewal akses Coach.

## Slice 00.4 — Target contract

- [ ] Desain `payment_destinations` berversi/effective-dated.
- [ ] Destination mendukung optional versioned QRIS image reference tanpa
  menyimpan asset nyata atau credential dalam source/workplan.
- [ ] Desain `payment_orders` per purpose, owner, amount, target, reservation,
  status, dan idempotency.
- [ ] Desain `payment_evidence_attempts` append/retry tanpa mutable submitted
  evidence.
- [ ] Desain verified `payment_ledger` dan immutable `payment_events`.
- [ ] Pertahankan program/Coach entitlement sebagai access projection.
- [ ] Definisikan protected operations create order, upload intent, submit,
  approve, reject, expire, cancel, refund/revoke, dan renewal.
- [ ] Rekonsiliasi OpenAPI enum/DTO agar sesuai SQL target dan stable
  `snake_case` values.
- [ ] Definisikan bucket private `payment-evidence`, access matrix, object path,
  signed access, cleanup, dan retention.

## Slice 00.5 — Forward-only migration plan

- [ ] Klasifikasikan Apple/StoreKit objects: retain active, stop new writes,
  legacy read-only, archive, atau later drop.
- [ ] Buat urutan additive migration tanpa rewrite history production.
- [ ] Buat rollback sebagai forward-fix, bukan down migration destructive.
- [ ] Tentukan kapan Apple Auth provider dan recurring jobs dinonaktifkan;
  jangan lakukan sekarang.
- [ ] Tentukan one-time backend/Contracts ownership transfer untuk Phase 13.

## Verifikasi

- [ ] Markdown links dan path checker lulus.
- [ ] OpenAPI syntax/parser lulus setelah contract edit.
- [ ] Tidak ada source executable, package, migration, config, atau hosted
  resource yang berubah pada phase documentation-only ini.
- [ ] Decision Register telah memiliki amendment untuk semua gate Phase 00.
- [ ] Verifikasi decision document berstatus final dan seluruh product gate
  GATE-003 sampai GATE-009 telah ditutup oleh amendment.
- [ ] Review manusia menyetujui keputusan uang, refund, retention, dan expiry.

## Definition of done

- Baseline hosted/local/source tidak ambigu.
- Parity matrix lengkap dan fitur tidak diam-diam hilang.
- Manual commerce mempunyai lifecycle, privacy, capacity, audit, dan failure
  policy yang disetujui.
- Contract drift Coach/OpenAPI telah direkonsiliasi atau memiliki blocking
  resolution yang eksplisit sebelum codegen.
- Phase 01 dapat membuat scaffold tanpa menebak keputusan produk.

## Progress log

Tambahkan entry bertanggal berisi file, inventory/hash, keputusan, command,
hasil, blocker, dan approver. Jangan memasukkan credential atau private URL.
