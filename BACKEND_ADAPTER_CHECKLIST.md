# Checklist adapter backend

## Contract

- [x] Model platform-neutral dan enum raw value stabil.
- [x] OpenAPI untuk program, enrollment, submission, kuis, timbang, Coach,
  winner, poster, dan commerce.
- [x] Decimal ditransportasikan sebagai string.
- [x] Participant payload tidak memuat answer key.
- [ ] Generate/verify Swift dan Kotlin client dari contract pada CI.

## Supabase

- [x] Schema program end-to-end tanpa invite/wallet/seat table.
- [x] Satu `current_coach_id` dan Coach snapshot pada enrollment.
- [x] Typed questions, answers, quiz results, weigh-ins, scores, commerce,
  entitlement, winners, poster, audit.
- [x] Cover gambar, future policy `available`, dan timbang harian
  step-scoped tercakup pada OpenAPI serta draft schema.
- [x] RLS dasar untuk Peserta, Coach terkait, dan Admin.
- [x] Bucket publik dan private question-photo.
- [x] Atomic free enrollment dan Admin Coach transfer.
- [ ] Jalankan fresh migration, lint, RLS matrix, serta race suite pada
  Supabase lokal/staging.
- [ ] Implementasikan seluruh Edge Function/mutation produksi dan scoring
  server-authoritative.

## Commerce

- [x] Store product mapping unik per program dan platform.
- [x] StoreKit 2 client adapter untuk load/purchase/restore/update.
- [x] Client tidak membuat enrollment dari purchase state saja.
- [ ] Provisioning App Store Connect dan Google Play dari backend.
- [ ] Verifikasi transaksi Apple/Google server-side.
- [ ] Notification, refund, revocation, replay protection, dan retry queue.
- [ ] Uji StoreKit sandbox dan Google Play test track.

## Keamanan

- [x] Tidak ada store credential atau service role di app/repository.
- [x] QR Coach opaque dan tanpa input kode manual.
- [x] Mutation Admin lokal memerlukan alasan dan audit.
- [ ] Signed URL private media dan policy retention produksi.
- [ ] Security advisor, penetration review, dan account deletion.

Checklist kosong memerlukan environment/credential eksternal dan tidak boleh
ditandai selesai hanya dari build client lokal.
