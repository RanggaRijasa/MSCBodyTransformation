# Phase 12: StoreKit 2 Program and Coach Access Payments

> Status: direkonsiliasi oleh E2E-11 dan E2E-12. Harga Admin adalah desired
> price; harga tampil berasal dari store. Setiap cohort berbayar mempunyai
> Product ID unik dan entitlement diverifikasi server-side serta berlaku
> lintas platform. Amendment 4 Agustus 2026 menambahkan pembayaran manual
> akses Coach tiga bulan dari Phase 09.5.

## Tujuan

Mengaktifkan pembayaran native Apple untuk:

- Peserta yang memilih program setelah mengonfirmasi QR Coach.
- Applicant Coach eligible yang membeli akses manual tiga bulan sebelum
  menunggu persetujuan Admin.

Tidak ada paket kuota peserta atau wallet coach.

## Prasyarat

- Program, harga, dan enrollment backend selesai.
- QR identifier coach bersifat unik dan server-controlled.
- Final bundle identifier dipilih.
- App Store Connect tersedia.
- Produk pembayaran program dibuat.
- Supabase Edge Functions tersedia.
- Kredensial App Store disimpan hanya di server.
- Refund/credit bila Admin menolak dan kebijakan renewal approval ulang sudah
  diputuskan.

## Produk akses Coach

| Level | Harga intent | Durasi |
|---|---:|---:|
| Member | Tidak tersedia | — |
| SC, SB | Rp100.000 | 3 bulan |
| Supervisor, World Team | Rp150.000 | 3 bulan |
| TAB, GET, Millionaire, President’s Team | Rp200.000 | 3 bulan |

- Pembelian bersifat manual, bukan auto-renewing subscription.
- Evaluasi StoreKit non-renewing subscription atau non-consumable
  time-limited entitlement; keputusan final harus cocok dengan App Review,
  restore, Android, dan backend reconciliation.
- Harga runtime berasal dari StoreKit; tabel di atas adalah product intent
  dan server validation mapping.
- Payment verified hanya memenuhi satu precondition. Role Coach tetap
  menunggu approval Admin.

## Alur produk

```text
Pilih program
    ↓
Lihat deskripsi, durasi, dan harga
    ↓
Pindai QR unik coach
    ↓
Konfirmasi identitas coach
    ↓
Pembayaran native Apple
    ↓
Verifikasi server
    ↓
Enrollment dibuat satu kali
```

```text
Participant eligible mengajukan Coach
    ↓
StoreKit Coach access product
    ↓
Server memverifikasi transaction dan periode tiga bulan
    ↓
Application menunggu Admin
    ↓
Admin approve
    ↓
Coach role + active entitlement
```

## Client StoreKit implementation

- [ ] Product loader berdasarkan product identifier milik program.
- [ ] Harga memakai localized price dari StoreKit.
- [ ] Purchase state machine.
- [ ] Success.
- [ ] User cancellation.
- [ ] Pending.
- [ ] Unverified.
- [ ] Interrupted purchase.
- [ ] `Transaction.updates` listener.
- [ ] Recovery setelah relaunch.
- [ ] Riwayat pembayaran peserta dari backend.
- [ ] Product loader Coach berdasarkan price band authoritative.
- [ ] Coach purchase tidak mengubah role pada client.
- [ ] Manual renewal menampilkan expiry dan tidak auto-renew.
- [ ] Restore/relaunch merekonsiliasi Coach entitlement dari server.
- [ ] Enrollment tidak dibuat dari status client-only.
- [ ] Finish transaction setelah hasil transaksi tersimpan durably.
- [ ] Tidak ada private key di app.

## Backend verification

Edge Function:

- [ ] Authenticate peserta.
- [ ] Verify Apple-signed transaction.
- [ ] Validate bundle id.
- [ ] Validate product id terhadap program.
- [ ] Validate environment dan transaction state.
- [ ] Resolve coach identifier dari server-controlled data.
- [ ] Idempotent transaction insert.
- [ ] Idempotent enrollment insert.
- [ ] Simpan program, peserta, dan coach yang dipilih pada audit.
- [ ] Return authoritative enrollment.
- [ ] Untuk Coach product, cocokkan product ID dengan application Member
  level/price band.
- [ ] Hitung access start/end tiga bulan dengan server clock.
- [ ] Payment verification mengubah payment state, bukan protected role.
- [ ] Admin approval memerlukan payment verified dan entitlement valid.
- [ ] Renewal, expiry, refund, revocation, dan rejection-credit bersifat
  idempoten.

Client tidak boleh mengirim harga authoritative atau membuat enrollment hanya
berdasarkan purchase state lokal.

## App Store Server Notifications V2

- [ ] Signed payload verification.
- [ ] Test notification.
- [ ] Refund.
- [ ] Revocation.
- [ ] Idempotent processing.
- [ ] Update payment status.
- [ ] Refund atau revocation membuat status enrollment sesuai keputusan produk.
- [ ] Durable processing sebelum success response.

## StoreKit testing

### Local configuration

- [ ] Add `Products.storekit`.
- [ ] Configure sample program products.
- [ ] Success.
- [ ] Cancel.
- [ ] Pending.
- [ ] Interrupted.
- [ ] Duplicate transaction.
- [ ] Refund.
- [ ] Relaunch recovery.

### Sandbox and TestFlight

- [ ] Sandbox account.
- [ ] Physical device.
- [ ] Product availability.
- [ ] Currency localization.
- [ ] Backend verification.
- [ ] Enrollment dibuat satu kali.
- [ ] Coach assignment sesuai QR yang dikonfirmasi.
- [ ] Duplicate callback tidak membuat enrollment tambahan.
- [ ] Refund behavior.
- [ ] Coach access success/cancel/pending/interrupted.
- [ ] Coach applicant tetap Participant setelah purchase success.
- [ ] Admin rejection policy.
- [ ] Three-month expiry dan manual renewal.
- [ ] Entitlement lintas iOS/Android.
- [ ] Review notes prepared.

## Security rules

- [ ] Tidak ada client-only enrollment grant.
- [ ] Tidak ada service role di app.
- [ ] Tidak ada App Store private key di app.
- [ ] Transaction id unique.
- [ ] Sandbox dan production dipisahkan.
- [ ] Harga dan product mapping authoritative di server.
- [ ] QR identifier tidak memberikan role atau hak akses.
- [ ] Member level dari client tidak menentukan harga/entitlement tanpa
  server mapping.
- [ ] Coach operation memerlukan role approved dan entitlement active.

## Exit criteria

- [ ] Verified purchase membuat enrollment yang tepat satu kali.
- [ ] Program dan coach pada enrollment sesuai konfirmasi peserta.
- [ ] Duplicate callbacks tidak membuat enrollment tambahan.
- [ ] Pending purchase pulih setelah relaunch.
- [ ] Refund path diuji.
- [ ] TestFlight purchase flow lulus.
- [ ] Verified Coach purchase membuat payment/entitlement satu kali tanpa
  self-promotion.
- [ ] Admin approval dan expiry Coach direkonsiliasi server-side.

## Progress log

### 4 Agustus 2026 — Coach access handoff

- Menambahkan tiga price band, durasi manual tiga bulan, server verification,
  Admin approval setelah payment, expiry/renewal/restore/refund, dan
  cross-platform entitlement.
- Phase 09.5 fake purchase bukan bukti StoreKit atau payment production.
