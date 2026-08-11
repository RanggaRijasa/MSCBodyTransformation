# Phase 06: Manual Payments and Admin Verification

> Status: SELESAI LOKAL

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

- [x] Buat migration via current Supabase CLI workflow yang benar.
- [x] Tambah `payment_destinations` dengan effective window dan Admin-only
  mutation, termasuk optional versioned static QRIS image reference.
- [x] Tambah `payment_orders` untuk program/Coach, amount snapshot, target,
  owner, Coach snapshot, reservation, state/version, idempotency.
- [x] Tambah `payment_evidence_attempts` untuk upload/retry/review lineage.
- [x] Tambah immutable `payment_ledger` dan `payment_events`.
- [x] Tambah indexes, unique constraints, foreign keys, cleanup/expiry support.
- [x] Update OpenAPI/contract types; hapus mismatch Coach status sebelum
  TypeScript codegen.
- [x] Existing entitlement tables tetap access projection.

## Slice 06.2 — RLS/grants/storage

- [x] Bucket privat `payment-evidence`, terpisah dari `public-media` dan
  `question-photos`.
- [x] Owner hanya dapat mengakses order/evidence miliknya sesuai lifecycle.
- [x] Admin reviewer dapat membaca bukti melalui short-lived access.
- [x] Coach tidak dapat melihat bukti participant/Coach applicant.
- [x] Submitted evidence immutable bagi owner; retry membuat attempt baru.
- [x] Object path server-derived/opaque dan ownership verified.
- [x] MIME magic/decoder/size/dimension validation, metadata stripping,
  thumbnail policy, and orphan cleanup.
- [x] Account deletion/retention policy diterapkan dan diuji.

## Slice 06.3 — Server operations

- [x] Create order untuk paid program setelah preflight/reservation.
- [x] Create/renew Coach order hanya setelah accepted eligibility.
- [x] Upload intent dan submit evidence idempoten.
- [x] Admin approve/reject dengan row lock, actor check, reason, amount/bank
  match reference, version, and audit.
- [x] Program approve atomik: ledger + entitlement + enrollment + score + event.
- [x] Coach approve atomik: ledger + payment projection + period entitlement +
  role/capability + QR + event.
- [x] Reject evidence tidak membatalkan accepted Coach application; retry aman.
- [x] Expire/cancel/refund/revoke/late-transfer/capacity behavior sesuai Phase 00.
- [x] Late transfer hanya dapat dipulihkan Admin bila kursi tersedia; jika
  penuh, order ditolak dan exceptional reversal dibuat secara audited.
- [x] Exceptional reversal rejected funds/duplicate/excess/program unavailable
  diselesaikan maksimal tujuh hari kerja tanpa client refund action.
- [x] Duplicate/replay/concurrent Admin decisions fail closed/idempoten.

## Slice 06.4 — Participant/Coach payment UI

- [x] Instruksi transfer menampilkan tujuan, pemilik rekening, nominal IDR,
  deadline/timezone, reference aman, dan optional gambar QRIS statis.
- [x] QRIS hanya display asset untuk pembayaran manual; tidak ada dynamic QR,
  gateway callback, OCR approval, atau status otomatis.
- [x] Upload/replace sebelum submit; setelah submit read-only.
- [x] Status: menunggu bukti, mengunggah, menunggu pemeriksaan, ditolak dengan
  alasan, terverifikasi, expired, cancelled, refunded/revoked bila berlaku.
- [x] Tidak ada client action `Ajukan refund`; exceptional resolution hanya
  melalui protected Admin operation dan policy Phase 00.
- [x] Tidak menampilkan data rekening lama setelah order snapshot dibuat.
- [x] Copy tidak mengklaim transfer verified sebelum Admin mencocokkan mutasi.
- [x] Personal evidence tidak masuk browser/PWA cache.

## Slice 06.5 — Minimal Admin payment queue

- [x] `/admin/pembayaran` filter program/Coach/status/date.
- [x] Detail menampilkan safe identity, amount, destination snapshot, timestamps,
  evidence viewer, attempt history, dan related aggregate.
- [x] Approve confirmation; reject/correction wajib alasan.
- [x] Admin harus mencatat nominal/reference reconciliation yang disyaratkan
  policy, bukan menilai gambar secara visual saja.
- [x] Queue/detail usable pada desktop dan mobile fallback.
- [x] No full phone/weight/private answer leakage.

## Slice 06.6 — Expiry dan recurring operations

- [x] Local job melepas reservation/order sesuai policy.
- [x] Cleanup bukti program berjalan 30 hari setelah program selesai; bukti
  Coach berjalan 30 hari setelah access period dari order berakhir.
- [x] Submitted-before-expiry review behavior teruji.
- [x] Expired evidence/order cleanup tidak menghapus audit/ledger yang wajib.
- [x] Existing Apple jobs tetap tidak dihapus; Phase 13 mengatur retirement.

## Verification

- [x] Fresh local migration chain lulus tanpa rewrite history.
- [x] pgTAP/RLS/grants/storage/SECURITY DEFINER/advisor/lint lulus.
- [x] Integration tests happy path dan program/Coach atomic fulfillment.
- [x] Race: duplicate order, upload replay, two Admins, expiry vs submit,
  capacity last seat, late approve, refund/revoke, account deletion.
- [x] Horizontal access: Guest/other Participant/Coach cannot access evidence.
- [x] E2E Participant and Coach transfer -> Admin review -> activation; rejection
  retry; offline upload; session expiry.
- [x] Evidence/log/cache/secret redaction scan lulus.
- [x] Web lint/typecheck/tests/build lulus.

## Definition of done

- Tidak ada client-write path ke verified/payment/role/entitlement.
- Payment evidence benar-benar privat dan memiliki retention lifecycle.
- Program dan Coach fulfillment atomik, idempoten, teraudit, dan race-safe.
- StoreKit tidak dipakai runtime web, tetapi legacy production belum dihapus.
- Contract, SQL, TypeScript, UI states, dan tests konsisten.

## External gate

Hosted deployment dilakukan Phase 12 dengan approval eksplisit dan backup/
forward-fix runbook.

## Progress log

### 10 Agustus 2026 — selesai lokal

- Files changed: migration additive manual payment di `supabase/migrations`,
  contract OpenAPI, repository/operation/payment UI, private evidence dan QRIS
  proxy, recurring local runner, unit/component/pgTAP/integration/E2E/gallery,
  serta audit DoD Phase 06.
- Assumptions: hosted `main`, root Supabase, proyek iOS, dan `Contracts/` tetap
  read-only; deployment/cron/secrets production tetap external gate Phase 12.
- Build command: `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm verify`.
- Test commands:
  `ALLOW_LOCAL_DB_RESET=phase06 PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm test:phase06:fresh-local`,
  `corepack pnpm test:phase06:local`, dan `corepack pnpm test:gallery`.
- Result: PASS — fresh root migration chain + migration Phase 06, database
  lint, 37 pgTAP, integration atomicity/RLS/race/retention, 3 Chromium E2E,
  14 Chromium/WebKit gallery checks, 105 Vitest, typecheck, production build
  38 halaman, serta media bundle gate. Baseline owner mobile dan Admin desktop
  diperiksa secara visual.
- Remaining blockers: tidak ada untuk gate lokal. Hosted migration, bucket,
  secrets, recurring schedule, dan deployment tetap Phase 12 dengan approval
  eksplisit.
