# Phase 00: Baseline and Contract Freeze

> Status: SELESAI — 10 Agustus 2026

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

- [x] Catat `git status` read-only dan jangan menyentuh user changes.
- [x] Inventaris source/lines/tests per feature iOS.
- [x] Inventaris migration, schema, RPC, grants, RLS, buckets, functions, cron,
  dan provider yang aktif berdasarkan local serta deployment record.
- [x] Catat contract/model/status enum yang benar-benar digunakan SQL terbaru.
- [x] Buat manifest hash untuk source backend/contract yang akan dijadikan
  referensi transfer ownership di Phase 13.
- [x] Bedakan fakta source, fakta local runtime, fakta hosted, dan deferred
  manual gate; jangan menggabungkannya menjadi satu status palsu.

## Slice 00.2 — Parity contract

- [x] Petakan seluruh route dan capability Guest/Peserta, Coach, Admin.
- [x] Petakan seluruh content/question type, access-day state, submission,
  quiz, weigh-in, scoring, leaderboard, winner, poster, dan account lifecycle.
- [x] Tandai konsep historis yang dilarang: program invite, typed QR fallback,
  wallet/seat credit, access non-public, poin per langkah, global weigh-in.
- [x] Petakan test Swift/XCUI ke test web target dan edge cases.
- [x] Catat deliberate web adaptations untuk navigation, sheets, media,
  permissions, install, offline, dan Admin desktop.

## Slice 00.3 — Manual payment product gate

- [x] Putuskan rekening tujuan dan siapa yang boleh mengelola.
- [x] Rekonsiliasi rekening berversi dan optional gambar QRIS statis; QRIS
  bukan payment gateway atau verifikasi otomatis.
- [x] Putuskan nominal snapshot, mata uang IDR, dan apakah nominal unik dipakai.
- [x] Putuskan reservation TTL program; rekomendasi awal audit adalah 24 jam.
- [x] Putuskan bahwa bukti yang submitted sebelum expiry mempertahankan
  reservation selama review atau tentukan alternatif yang aman.
- [x] Putuskan transfer terlambat, capacity full, duplicate payment, salah
  rekening/nominal, program batal, refund, cancellation, dan revoke.
- [x] Putuskan jumlah retry evidence dan expiry setelah rejection.
- [x] Putuskan SLA review Admin dan copy status Peserta/Coach.
- [x] Putuskan file type/size, retention, deletion, dan audit data bukti.
- [x] Konfirmasi urutan Coach: eligibility diterima sebelum diminta membayar;
  bukti ditolak tidak membatalkan acceptance.
- [x] Konfirmasi periode serta renewal akses Coach.

## Slice 00.4 — Target contract

- [x] Desain `payment_destinations` berversi/effective-dated.
- [x] Destination mendukung optional versioned QRIS image reference tanpa
  menyimpan asset nyata atau credential dalam source/workplan.
- [x] Desain `payment_orders` per purpose, owner, amount, target, reservation,
  status, dan idempotency.
- [x] Desain `payment_evidence_attempts` append/retry tanpa mutable submitted
  evidence.
- [x] Desain verified `payment_ledger` dan immutable `payment_events`.
- [x] Pertahankan program/Coach entitlement sebagai access projection.
- [x] Definisikan protected operations create order, upload intent, submit,
  approve, reject, expire, cancel, refund/revoke, dan renewal.
- [x] Rekonsiliasi OpenAPI enum/DTO agar sesuai SQL target dan stable
  `snake_case` values.
- [x] Definisikan bucket private `payment-evidence`, access matrix, object path,
  signed access, cleanup, dan retention.

## Slice 00.5 — Forward-only migration plan

- [x] Klasifikasikan Apple/StoreKit objects: retain active, stop new writes,
  legacy read-only, archive, atau later drop.
- [x] Buat urutan additive migration tanpa rewrite history production.
- [x] Buat rollback sebagai forward-fix, bukan down migration destructive.
- [x] Tentukan kapan Apple Auth provider dan recurring jobs dinonaktifkan;
  jangan lakukan sekarang.
- [x] Tentukan one-time backend/Contracts ownership transfer untuk Phase 13.

## Verifikasi

- [x] Markdown links dan path checker lulus.
- [x] OpenAPI syntax/parser lulus. Tidak ada contract edit pada Phase 00 karena
  `Contracts/` read-only; semantic drift memiliki blocking resolution eksplisit
  sebelum codegen.
- [x] Tidak ada source executable, package, migration, config, atau hosted
  resource yang berubah pada phase documentation-only ini.
- [x] Decision Register telah memiliki amendment untuk semua gate Phase 00.
- [x] Verifikasi decision document berstatus final dan seluruh product gate
  GATE-003 sampai GATE-009 telah ditutup oleh amendment.
- [x] Review manusia menyetujui keputusan uang, refund, retention, dan expiry.

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

### 10 Agustus 2026 — Phase 00 selesai

- Files: baseline source/runtime, hash manifest, contract reconciliation,
  parity matrix, target manual commerce contract, test mapping,
  forward-only/decommission plan, Decision Register, manifest, dan status
  workplan; semuanya berada di `MSCWeb/`.
- Inventory: 145 file/49.352 baris Swift production, 194 deklarasi Swift test,
  52 metode XCUI, 20 migration, 9 Edge Functions, 14 pgTAP files, 29 tabel
  public local dengan 29 RLS, 50 policy, dan 5 cron aktif.
- Hash: combined `Contracts/` + `supabase/` 71 file adalah
  `778856ac913f27123db224b0e390fc4433551c04b9639097b5118960d9b664d4`.
- Keputusan: seluruh GATE-003–GATE-009 closed; manual commerce lifecycle,
  privacy, capacity, exceptional reversal, retention, dan Coach renewal final.
- Contract: OpenAPI YAML valid tetapi enum Coach application lebih lama dari
  SQL. Codegen diblokir sampai authorized shared-contract update Phase 06.
- Commands: `git status --short`; `colima status`;
  `docker info --format '{{.ServerVersion}}'`; `supabase status`; read-only
  local `psql` inventory queries; `ruby -e` OpenAPI YAML parser; `ruby -e`
  relative Markdown link checker; `git diff --check -- MSCWeb`;
  `git ls-files -z supabase Contracts | sort -z | xargs -0 shasum -a 256 |
  shasum -a 256`.
- Result: link/path, OpenAPI syntax, whitespace/diff, scope, and hash checks
  lulus. Tidak ada build/test executable karena Phase 00 melarang scaffold,
  package, dan source web.
- Blocker: tidak ada blocker Phase 00. Drift OpenAPI adalah gate eksplisit
  sebelum codegen/shared update, bukan alasan menebak contract di Phase 01.
- Approver: pengguna; keputusan manual commerce dan instruksi eksplisit untuk
  menyelesaikan Phase 00 diberikan pada 10 Agustus 2026.
- Next unchecked item: Phase 01 Slice 01.1, pin toolchain dan scaffold minimal
  di `MSCWeb/` setelah verifikasi versi pada hari eksekusi.
