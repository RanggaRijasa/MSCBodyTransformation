# Checklist Adapter Backend

## Prinsip

- Pertahankan View, feature state, use case, dan model domain.
- Ganti implementasi protocol repository melalui `AppEnvironment`.
- Jangan membawa tipe SDK, URL media, token, atau response mentah ke domain.
- Petakan error teknis ke `DomainError` sebelum mencapai UI.

## Autentikasi dan izin

- [ ] Pasang session adapter dengan refresh serta pemulihan sesi.
- [ ] Registrasi baru selalu menjadi Peserta.
- [ ] Ambil peran istimewa dari data server-controlled.
- [ ] Pertahankan pending invite melewati login.
- [ ] Tambahkan Google dan Apple hanya pada fase yang ditugaskan.
- [ ] Terapkan Row Level Security dan uji permission denied.

## Data dan konkurensi

- [ ] Implementasikan setiap protocol repository tanpa mengubah kontrak UI.
- [ ] Gunakan server time untuk hari aktif, expiry, dan lock.
- [ ] Terapkan idempotency untuk submission, enrollment, review, dan purchase.
- [ ] Tangani pagination, cancellation, timeout, offline cache, dan retry.
- [ ] Hindari duplicate load serta pastikan list identity tetap stabil.

## Skor dan pemenang

- [ ] Pindahkan skor authoritative ke transaction atau function server.
- [ ] Gunakan numeric/decimal untuk berat.
- [ ] Hitung hanya submission approved unik.
- [ ] Simpan adjustment terpisah beserta alasan dan audit.
- [ ] Lock pemenang dalam transaction dan simpan snapshot stabil.
- [ ] Jangan mengekspos berat pada query papan peringkat publik.

## Media

- [ ] Pertahankan resize, orientasi, dan penghapusan metadata di klien.
- [ ] Unggah dengan path privat dan content type tervalidasi.
- [ ] Gunakan signed URL berumur pendek untuk bukti.
- [ ] Terapkan batas ukuran, retry, progress, cleanup, dan authorization.
- [ ] Jangan log path privat, signed URL, berat, atau token.

## Coach dan pembelian

- [ ] Sinkronkan wallet dan ledger secara authoritative.
- [ ] Kurangi satu kuota hanya setelah enrollment baru berhasil.
- [ ] Tambahkan StoreKit dan App Store Server API pada fase produksi.
- [ ] Verifikasi transaksi di server; jangan mempercayai saldo klien.

## Admin dan operasional

- [ ] Validasi draft dan perubahan published program di server.
- [ ] Lindungi persetujuan Coach, pendaftaran manual, adjustment, dan lock.
- [ ] Simpan audit append-only untuk semua tindakan istimewa.
- [ ] Tambahkan observability tanpa data sensitif.
- [ ] Jalankan migration, seed nonproduksi, backup, dan rollback rehearsal.

## Gerbang sebelum produksi

- [ ] Unit, integration, UI, RLS, dan security test lulus.
- [ ] Offline, session expiry, conflict, timeout, dan retry tervalidasi.
- [ ] Privacy manifest, usage description, signing, dan entitlement selesai.
- [ ] Kamera serta QR diuji pada perangkat fisik.
- [ ] Dynamic Type, VoiceOver, contrast, transparency, dan Reduce Motion diaudit.
