# Runbook reliability Phase 11

## Konfigurasi manual sebelum push production

Push termasuk MVP, tetapi deployment tetap Phase 12. Operator harus membuat satu pasangan VAPID dan secret dispatcher yang kuat, lalu mengisi secret hosting/Edge Function berikut tanpa memasukkannya ke repository:

- `NEXT_PUBLIC_WEB_PUSH_VAPID_PUBLIC_KEY`
- `WEB_PUSH_VAPID_PUBLIC_KEY`
- `WEB_PUSH_VAPID_PRIVATE_KEY`
- `WEB_PUSH_VAPID_SUBJECT` dengan alamat operator yang valid
- `PUSH_DISPATCH_SECRET`

Deploy migrasi dan `push-dispatch` hanya setelah approval production terpisah. Jadwalkan dispatcher dengan header `x-internal-secret`; jangan menaruh secret di URL. Uji satu subscription per platform dan pastikan payload tetap memakai copy generik.

## Matriks failure dan retry

| Failure | Presentasi | Retry/cancel | Idempotensi |
| --- | --- | --- | --- |
| Validation | pesan field langsung | perbaiki input | tidak diperlukan |
| Unauthorized/session expiry | minta masuk kembali | setelah reconnect/reauth | state pilihan program dipertahankan sesuai kontrak |
| Offline | banner dan offline fallback | tombol Coba lagi; mutasi gagal | tidak ada success palsu/draft offline |
| Timeout/transient | pesan aman | bounded retry pemilik aksi | idempotency key tetap |
| Conflict | muat status terbaru | tidak blind retry | server dedupe/version check |
| Upload cancelled | status dibatalkan | pilih/unggah lagi | receipt/path server-generated, orphan cleanup |
| Push delivery | tidak mengganggu transaksi utama | exponential 30 detik–1 jam, maksimum 8 | outbox key unik |
| Unknown | error boundary per shell | reset route | raw error tidak ditampilkan |

## Incident

1. Hentikan dispatcher push atau deployment web yang bermasalah; jangan menghapus data.
2. Catat waktu, build ID, correlation ID aman, route, dan event tetap. Jangan salin payload/PII.
3. Untuk dugaan kebocoran: rotasi secret terkait, revoke subscription bila perlu, dan isolasi akses Storage.
4. Verifikasi RLS, cache headers, service worker cache keys, outbox, audit events, serta error rate.
5. Pulihkan dari backup terverifikasi hanya melalui prosedur Supabase production yang disetujui.
6. Dokumentasikan akar masalah dan tambahkan regression test sebelum membuka kembali.

## Rollback dan kegagalan update PWA

- Deploy ulang build terakhir yang dikenal baik; jangan ubah nama cache build lama secara manual.
- Service worker baru menunggu tindakan pengguna. Saat diaktifkan, ia menghapus hanya cache dengan prefix MSC yang stale.
- Jika worker rusak, deploy `sw.js` perbaikan dengan `BUILD_VERSION` baru dan header no-store. Pengguna dapat menutup semua tab lalu membuka ulang; unregister manual adalah langkah terakhir.
- Data pribadi tidak boleh dipulihkan dari Cache Storage karena memang tidak pernah dicache.
- Backup database, Storage, dan daftar migration production harus diverifikasi sebelum migrasi Phase 12. Phase 11 tidak melakukan backup/restore hosted.

## Recovery offline/session

Saat koneksi kembali, tombol Coba lagi memverifikasi manifest no-store dan me-refresh route. Jika sesi sudah berakhir, route guard mengarah ke login. Upload yang terputus dapat dibatalkan dan dimulai ulang dengan idempotency key; tidak ada background sync atau draft privat offline di MVP.
