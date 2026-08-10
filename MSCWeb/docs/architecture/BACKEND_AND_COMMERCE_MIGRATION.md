# Backend and Commerce Migration

## Prinsip

- Supabase, Postgres, RLS, RPC, Storage, scoring, audit, dan lifecycle program
  dipertahankan bila kontraknya masih benar.
- Hosted Supabase `main` sudah menerima 20 migration dan Phase 13.1 resources.
  Semua perubahan web adalah migration forward-only; jangan menulis ulang
  history production atau menganggap schema Apple hanya fixture lokal.
- StoreKit tidak diganti dengan boolean `isPaid` yang dapat ditulis client.
- Manual transfer menjadi provider baru dengan aggregate, event history, dan
  protected verification operation.
- Apple tables/functions tidak dihapus sampai backup, parity, dan rollback
  decision Phase 13 selesai.

## Reuse matrix

| Area sekarang | Keputusan web |
|---|---|
| Profiles, roles, Coach assignment | Pertahankan |
| Program draft/publish/content | Pertahankan |
| Enrollment guards/capacity/cutoff | Pertahankan dan adaptasi payment preflight |
| Submission/quiz/weigh-in | Pertahankan |
| Scoring/leaderboard/winner | Pertahankan |
| Public/participant/Coach/Admin reads | Pertahankan; buat TS mapper |
| Private media buckets | Pertahankan dan tambah payment evidence policy |
| Audit infrastructure | Pertahankan dan tambah manual-payment events |
| StoreKit purchase intent/JWS/notification | Tidak dipakai PWA; simpan legacy saat transisi |
| Program/Coach entitlement projections | Pertahankan sebagai hasil verified payment |
| Apple identity lifecycle | Tidak dipakai user baru; lakukan retirement terkontrol |
| Google Auth | Konfigurasi web callback baru |
| Email Auth | Tetap feature-gated sampai SMTP/domain siap |

## Aggregate manual payment yang ditargetkan

Nama final ditetapkan setelah audit schema Phase 00. Minimal harus memodelkan:

```text
payment_destination
  rekening/pemilik/bank + optional gambar QRIS statis
  berversi dan effective-dated

payment_order
  owner + purpose + target aggregate
  amount/currency/destination snapshot
  reservation/expiry + status + idempotency/version

payment_evidence_attempt
  satu upload/review attempt yang immutable setelah submit
  private object path + content hash + submitted/reviewed metadata

payment_ledger
  hasil rekonsiliasi yang sudah verified dan tidak dapat ditulis client

payment_event (append-only)
  order/attempt + event type + actor/time + allowlisted metadata
```

Client tidak boleh mengirim atau mengubah `reviewed_by`, `verified`, role,
entitlement, score, atau amount authoritative.

## Lifecycle peserta berbayar

```text
Program dan QR Coach tervalidasi server
  -> payment request + capacity policy
  -> instruksi transfer
  -> bukti diproses dan disimpan privat
  -> pending Admin review
  -> verified atau rejected
  -> verified: entitlement + enrollment + score entry atomik
```

Program gratis tetap memakai enrollment operation tanpa payment request.

## Lifecycle Coach

```text
Participant mengirim application
  -> Admin menerima eligibility
  -> accepted_pending_payment
  -> payment request + evidence
  -> Admin memverifikasi pembayaran
  -> Coach access period/capability aktif
```

Payment, application acceptance, role, dan access period tetap state terpisah.
Rejection eligibility terjadi sebelum pembayaran. Renewal manual menambah
periode menggunakan server clock dan policy yang ditetapkan.

## Keputusan yang wajib ditutup di Phase 00

- Apakah payment request mereservasi kapasitas program; jika ya, TTL dan
  perilaku transfer terlambat.
- Refund/cancellation policy untuk salah transfer, bukti ditolak, program
  penuh, dan program dibatalkan.
- Rekening tujuan, siapa yang dapat mengubah, effective date, dan snapshot
  pada transaksi.
- Optional gambar QRIS statis ikut versioned; tidak ada dynamic QR, gateway,
  callback, atau auto-verification pada MVP.
- Format, ukuran, retention, dan deletion bukti pembayaran.
- Apakah amount memakai nominal unik; jangan menganggap bukti gambar cukup
  untuk rekonsiliasi otomatis.
- SLA Admin review dan copy status pengguna.
- Periode serta renewal akses Coach.

Keputusan final Phase 00 dan product gate closure dicatat di
`../decisions/PHASE_00_MANUAL_COMMERCE_DECISIONS.md`.

Desain logical aggregate, operasi, enum target, storage, authorization, dan
test gate yang telah dibekukan berada di
[Target Manual Commerce Contract](./TARGET_MANUAL_COMMERCE_CONTRACT.md).
Urutan migration/decommission berada di
[Forward-only Migration and Decommission Plan](./FORWARD_ONLY_MIGRATION_AND_DECOMMISSION.md).

## Storage dan privasi

- Bucket bukti transfer privat dan terpisah dari media program.
- Object path diturunkan server dari request/owner; jangan menerima arbitrary
  path dari client.
- Owner dapat upload/read status sesuai policy; Admin reviewer dapat membaca
  melalui short-lived signed access; Coach lain tidak dapat membaca.
- Browser melakukan resize/metadata removal untuk UX, tetapi server tetap
  memvalidasi magic bytes, ukuran, decoder, dan ownership.
- Jangan menyimpan signed URL atau bukti di cache PWA, logs, analytics,
  previews, fixtures production, atau error payload.
- Retention dan account deletion harus membedakan bukti yang masih dibutuhkan
  untuk kewajiban transaksi/audit dari media personal yang dapat dihapus.

## Operasi verifikasi Admin

Protected operation harus:

1. Memvalidasi actor Admin dari server-controlled data.
2. Mengunci payment request dan aggregate target.
3. Menolak terminal/duplicate/conflicting decision secara idempoten.
4. Memeriksa amount, purpose, owner, lifecycle, capacity/cutoff policy, dan
   application/enrollment state.
5. Menulis immutable event dan reviewer timestamp.
6. Membuat/memperpanjang entitlement dan enrollment/capability secara atomik.
7. Menghasilkan audit record tanpa PII bukti.
8. Mengembalikan typed result yang aman ditampilkan.

## Supabase compatibility notes

- Explicit grants dan RLS tetap diperlukan; exposure Data API bukan pengganti
  RLS.
- Browser memakai publishable key, bukan secret/service role.
- View public/authenticated harus `security_invoker` atau tidak diekspos.
- Setiap `SECURITY DEFINER` baru harus berada di schema non-exposed, memiliki
  fixed search path, actor check, explicit execute grants, race test, dan
  advisor review.
- Migration dibuat serta diuji pada Supabase lokal lebih dulu. Hosted `main`
  hanya disentuh setelah approval deployment production.
- Existing StoreKit schema, Apple functions, Auth provider, cron, Vault values,
  and immutable transaction/audit records diklasifikasikan lalu dinonaktifkan
  bertahap pada Phase 13; tidak di-drop bersamaan dengan penambahan manual
  payment.
