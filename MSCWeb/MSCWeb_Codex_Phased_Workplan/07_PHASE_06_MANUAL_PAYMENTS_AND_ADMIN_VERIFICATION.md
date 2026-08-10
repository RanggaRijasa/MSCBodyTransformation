# Phase 06: Manual Payments and Admin Verification

> Status: BELUM DIMULAI

## Tujuan

Menggantikan StoreKit runtime dengan transfer manual yang aman untuk program
dan akses Coach: rekening berversi, order, bukti privat, review Admin,
immutable ledger/event, serta fulfillment atomik.

## Safety boundary

- Semua schema iteration dan destructive test hanya pada Supabase lokal.
- Migration baru additive/forward-only terhadap 20 migration hosted baseline.
- Hosted `main`, Auth, bucket production, Edge deploy, cron, dan secrets tidak
  disentuh pada phase lokal ini.
- Jangan memasukkan transfer ke tabel Apple dengan product/transaction palsu.

## Slice 06.1 — Schema dan contract

- [ ] Buat migration via current Supabase CLI workflow yang benar.
- [ ] Tambah `payment_destinations` dengan effective window dan Admin-only
  mutation, termasuk optional versioned static QRIS image reference.
- [ ] Tambah `payment_orders` untuk program/Coach, amount snapshot, target,
  owner, Coach snapshot, reservation, state/version, idempotency.
- [ ] Tambah `payment_evidence_attempts` untuk upload/retry/review lineage.
- [ ] Tambah immutable `payment_ledger` dan `payment_events`.
- [ ] Tambah indexes, unique constraints, foreign keys, cleanup/expiry support.
- [ ] Update OpenAPI/contract types; hapus mismatch Coach status sebelum
  TypeScript codegen.
- [ ] Existing entitlement tables tetap access projection.

## Slice 06.2 — RLS/grants/storage

- [ ] Bucket privat `payment-evidence`, terpisah dari `public-media` dan
  `question-photos`.
- [ ] Owner hanya dapat mengakses order/evidence miliknya sesuai lifecycle.
- [ ] Admin reviewer dapat membaca bukti melalui short-lived access.
- [ ] Coach tidak dapat melihat bukti participant/Coach applicant.
- [ ] Submitted evidence immutable bagi owner; retry membuat attempt baru.
- [ ] Object path server-derived/opaque dan ownership verified.
- [ ] MIME magic/decoder/size/dimension validation, metadata stripping,
  thumbnail policy, and orphan cleanup.
- [ ] Account deletion/retention policy diterapkan dan diuji.

## Slice 06.3 — Server operations

- [ ] Create order untuk paid program setelah preflight/reservation.
- [ ] Create/renew Coach order hanya setelah accepted eligibility.
- [ ] Upload intent dan submit evidence idempoten.
- [ ] Admin approve/reject dengan row lock, actor check, reason, amount/bank
  match reference, version, and audit.
- [ ] Program approve atomik: ledger + entitlement + enrollment + score + event.
- [ ] Coach approve atomik: ledger + payment projection + period entitlement +
  role/capability + QR + event.
- [ ] Reject evidence tidak membatalkan accepted Coach application; retry aman.
- [ ] Expire/cancel/refund/revoke/late-transfer/capacity behavior sesuai Phase 00.
- [ ] Late transfer hanya dapat dipulihkan Admin bila kursi tersedia; jika
  penuh, order ditolak dan exceptional reversal dibuat secara audited.
- [ ] Exceptional reversal rejected funds/duplicate/excess/program unavailable
  diselesaikan maksimal tujuh hari kerja tanpa client refund action.
- [ ] Duplicate/replay/concurrent Admin decisions fail closed/idempoten.

## Slice 06.4 — Participant/Coach payment UI

- [ ] Instruksi transfer menampilkan tujuan, pemilik rekening, nominal IDR,
  deadline/timezone, reference aman, dan optional gambar QRIS statis.
- [ ] QRIS hanya display asset untuk pembayaran manual; tidak ada dynamic QR,
  gateway callback, OCR approval, atau status otomatis.
- [ ] Upload/replace sebelum submit; setelah submit read-only.
- [ ] Status: menunggu bukti, mengunggah, menunggu pemeriksaan, ditolak dengan
  alasan, terverifikasi, expired, cancelled, refunded/revoked bila berlaku.
- [ ] Tidak ada client action `Ajukan refund`; exceptional resolution hanya
  melalui protected Admin operation dan policy Phase 00.
- [ ] Tidak menampilkan data rekening lama setelah order snapshot dibuat.
- [ ] Copy tidak mengklaim transfer verified sebelum Admin mencocokkan mutasi.
- [ ] Personal evidence tidak masuk browser/PWA cache.

## Slice 06.5 — Minimal Admin payment queue

- [ ] `/admin/pembayaran` filter program/Coach/status/date.
- [ ] Detail menampilkan safe identity, amount, destination snapshot, timestamps,
  evidence viewer, attempt history, dan related aggregate.
- [ ] Approve confirmation; reject/correction wajib alasan.
- [ ] Admin harus mencatat nominal/reference reconciliation yang disyaratkan
  policy, bukan menilai gambar secara visual saja.
- [ ] Queue/detail usable pada desktop dan mobile fallback.
- [ ] No full phone/weight/private answer leakage.

## Slice 06.6 — Expiry dan recurring operations

- [ ] Local job melepas reservation/order sesuai policy.
- [ ] Cleanup bukti program berjalan 30 hari setelah program selesai; bukti
  Coach berjalan 30 hari setelah access period dari order berakhir.
- [ ] Submitted-before-expiry review behavior teruji.
- [ ] Expired evidence/order cleanup tidak menghapus audit/ledger yang wajib.
- [ ] Existing Apple jobs tetap tidak dihapus; Phase 13 mengatur retirement.

## Verification

- [ ] Fresh local migration chain lulus tanpa rewrite history.
- [ ] pgTAP/RLS/grants/storage/SECURITY DEFINER/advisor/lint lulus.
- [ ] Integration tests happy path dan program/Coach atomic fulfillment.
- [ ] Race: duplicate order, upload replay, two Admins, expiry vs submit,
  capacity last seat, late approve, refund/revoke, account deletion.
- [ ] Horizontal access: Guest/other Participant/Coach cannot access evidence.
- [ ] E2E Participant and Coach transfer -> Admin review -> activation; rejection
  retry; offline upload; session expiry.
- [ ] Evidence/log/cache/secret redaction scan lulus.
- [ ] Web lint/typecheck/tests/build lulus.

## Definition of done

- Tidak ada client-write path ke verified/payment/role/entitlement.
- Payment evidence benar-benar privat dan memiliki retention lifecycle.
- Program dan Coach fulfillment atomik, idempoten, teraudit, dan race-safe.
- StoreKit tidak dipakai runtime web, tetapi legacy production belum dihapus.
- Contract, SQL, TypeScript, UI states, dan tests konsisten.

## External gate

Hosted deployment dilakukan Phase 12 dengan approval eksplisit dan backup/
forward-fix runbook.
