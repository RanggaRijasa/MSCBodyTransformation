# Phase 12: StoreKit 2 Program Payments

## Tujuan

Mengaktifkan pembayaran native Apple untuk peserta yang memilih program,
setelah peserta memindai dan mengonfirmasi QR identifier coach.

Tidak ada paket kuota peserta atau wallet coach.

## Prasyarat

- Program, harga, dan enrollment backend selesai.
- QR identifier coach bersifat unik dan server-controlled.
- Final bundle identifier dipilih.
- App Store Connect tersedia.
- Produk pembayaran program dibuat.
- Supabase Edge Functions tersedia.
- Kredensial App Store disimpan hanya di server.

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
- [ ] Review notes prepared.

## Security rules

- [ ] Tidak ada client-only enrollment grant.
- [ ] Tidak ada service role di app.
- [ ] Tidak ada App Store private key di app.
- [ ] Transaction id unique.
- [ ] Sandbox dan production dipisahkan.
- [ ] Harga dan product mapping authoritative di server.
- [ ] QR identifier tidak memberikan role atau hak akses.

## Exit criteria

- [ ] Verified purchase membuat enrollment yang tepat satu kali.
- [ ] Program dan coach pada enrollment sesuai konfirmasi peserta.
- [ ] Duplicate callbacks tidak membuat enrollment tambahan.
- [ ] Pending purchase pulih setelah relaunch.
- [ ] Refund path diuji.
- [ ] TestFlight purchase flow lulus.

## Progress log

### Log
