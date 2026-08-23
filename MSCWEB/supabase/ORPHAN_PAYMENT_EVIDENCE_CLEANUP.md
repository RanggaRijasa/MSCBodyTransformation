# Pembersihan bukti pembayaran yatim

Status produksi: implementasi root sudah disiapkan untuk review dan verifikasi
lokal; secret, cron, dan mode delete hosted belum diaktifkan.

## Kontrak aman

- Objek hanya menjadi kandidat bila berada di bucket privat `payment-evidence`, berusia sekurang-kurangnya 72 jam, dan tidak memiliki referensi `payment_evidence_attempts.object_path`.
- Batas minimum fungsi database adalah 24 jam. Job memakai 72 jam secara baku.
- Bukti berstatus `prepared`, `submitted`, `rejected`, atau `approved` yang masih direferensikan tidak pernah menjadi kandidat. Riwayat penolakan tetap dipertahankan.
- Pemindaian ulang dilakukan tepat sebelum setiap penghapusan agar submit yang berjalan bersamaan dapat mempertahankan objeknya.
- Hanya Edge Function ber-Service Role dan rahasia job terpisah yang boleh menjalankan penghapusan. Admin dapat menjalankan RPC hanya untuk pemeriksaan/dry-run, bukan menghapus melalui UI.
- Mode bawaan adalah dry-run. Aktivasi penghapusan memerlukan `dryRun: false` secara eksplisit.
- Setiap eksekusi menulis jumlah kandidat, berhasil, dan gagal ke `audit_events`. Nama objek tidak masuk audit atau log.
- Kegagalan per objek tidak menghentikan batch. Objek gagal tetap ada dan aman untuk dicoba lagi pada eksekusi berikutnya.

## Dua jenis cleanup

1. **Cleanup orphan** menghapus file upload yang tidak pernah berhasil direferensikan oleh record bukti. Kontrak aman di atas tetap memakai usia minimum 72 jam.
2. **Cleanup retensi** menghapus file gambar bukti Participant dan Coach 30 hari setelah `submitted_at`. Record transaksi, object path non-publik, keputusan, ledger, dan audit non-gambar tetap dipertahankan; attempt ditandai `deleted` setelah Storage mengonfirmasi penghapusan.

File berstatus `under_review` pada hari ke-30 dipertahankan sampai keputusan Admin. Setelah keputusan tercatat, file yang sudah melewati 30 hari segera menjadi kandidat penghapusan. Pengecualian ini mencegah hilangnya satu-satunya bukti sebelum pemeriksaan selesai.

Sebelum penghapusan retensi, worker melakukan claim atomik dengan status
sementara `deleting`. Claim hanya berhasil setelah database memeriksa ulang umur,
status attempt, status order, dan keberadaan objek. Kegagalan Storage melepas
claim ke status keputusan sebelumnya; claim macet lebih dari 15 menit dipulihkan
di awal job berikutnya.

## Jadwal final

- jalankan sekali sehari pukul `02.00 WITA` (`18.00 UTC` hari sebelumnya);
- jalankan sebagai Supabase Cron yang memanggil Edge Function menggunakan secret di Vault;
- aktor teknis adalah job server ber-Service Role, bukan browser atau akun Admin;
- tujuh eksekusi produksi pertama menggunakan dry-run dan diperiksa operator teknis sebelum mode delete diaktifkan;
- setiap eksekusi dan kegagalan dicatat tanpa object path atau isi bukti.

Job berjalan otomatis. Admin web tidak memiliki tombol untuk menjalankan atau menghapus cleanup. Admin yang berwenang hanya dapat melihat hasil dry-run/audit bila permukaan monitoring disediakan.

Eksekusi manual hanya untuk pemulihan darurat dan dilakukan operator teknis melalui Supabase Dashboard/CLI atau pemanggilan Edge Function yang terautentikasi. Operator wajib menjalankan dry-run terlebih dahulu, memeriksa jumlah kandidat, memakai secret server yang tidak pernah masuk browser, dan memastikan hasil tercatat di audit. Penghapusan langsung melalui SQL Editor atau Storage Explorer bukan prosedur normal.

## Verifikasi lokal

Uji integrasi membuat keadaan objek yatim, upload `prepared`, bukti final lebih
muda dari 30 hari, bukti final yang melewati 30 hari, order `under_review`, claim
gagal, pelepasan claim, dan penyelesaian `deleted`. Dry-run tidak mengubah data
atau Storage.

Source deployment berada hanya di `supabase/migrations/` dan
`supabase/functions/cleanup-orphan-payment-evidence/`. Deployment hosted tetap
menunggu review legal, release gate W08, dan production-shaped preview.
