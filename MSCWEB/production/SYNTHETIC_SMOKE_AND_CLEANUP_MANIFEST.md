# Manifest synthetic production smoke dan cleanup

Status: `DISETUJUI — BOLEH DIJALANKAN SETELAH DEPLOYMENT GATE LULUS`

Manifest ini membatasi smoke production pada data sintetis, tanpa transfer uang
nyata dan tanpa data pengguna nyata. Google OAuth production smoke ditunda sampai
owner menetapkan satu akun Gmail test khusus.

## Identitas dan penanda run

- `run_id`: `w08-prod-smoke-<UTC timestamp>-<8 hex>`
- email sintetis: `msc+<run_id>-<role>@example.invalid`
- display name: `Synthetic Smoke <role> <run_id>`
- seluruh record, object path, idempotency key, dan audit test memakai `run_id`
- kredensial test dibuat runtime, tidak ditulis ke repository atau output log

Domain `example.invalid` tidak dapat menerima email. Pembuatan identity dilakukan
oleh operator melalui Admin API server-side hanya selama smoke. Flow Google Auth,
email delivery, reset password, dan inbox verification bukan bagian run ini.

## Operasi yang diizinkan

1. Buat identity Participant sintetis dan profile server-side.
2. Baca route publik, shell login, callback-invalid, legal yang sudah disetujui,
   serta endpoint health/routing tanpa mutasi.
3. Daftarkan Participant sintetis ke program smoke khusus atau fixture production
   yang secara eksplisit ditandai non-billable; jangan gunakan program pengguna.
4. Buat payment order sintetis bertanda `run_id`, tetapi jangan melakukan transfer,
   approval, atau penulisan ledger `verified`. Tujuan pembayaran boleh dirender
   hanya untuk memastikan UI, bukan untuk digunakan.
5. Unggah satu JPEG fixture sintetis tanpa wajah, nama, nomor rekening, lokasi,
   atau metadata pengguna; verifikasi private Storage dan signed URL singkat.
6. Verifikasi Coach-media gateway dengan asset sintetis: opaque UUID berhasil,
   direct Storage URL gagal, entitlement/publication invalidation mengembalikan
   `404`, lalu pulihkan state sebelum cleanup.
7. Panggil cleanup payment hanya dengan `dryRun: true`; mode delete production
   tidak menjadi bagian smoke peluncuran.
8. Verifikasi Worker apex, redirect `www` ke apex, enforced CSP, no shared cache
   untuk route privat, PWA install metadata, dan unknown route `404`.

## Operasi yang dilarang

- transfer bank, QRIS, charge, refund, atau settlement nyata;
- penggunaan email, foto, berat badan, QR Coach, media, atau account pengguna nyata;
- approval payment yang menulis ledger `verified`;
- perubahan role Admin/Coach production non-sintetis;
- pengiriman insight foto ke OpenRouter sampai key, model/router, consent, dan
  legal AI disetujui;
- Google OAuth smoke sebelum akun Gmail test khusus ditetapkan.

## Cleanup berurutan

Cleanup dijalankan dalam blok `finally` dan idempotent berdasarkan `run_id` serta
ID yang dicatat lokal selama run:

1. hapus object sintetis dari `coach-public-media`, `payment-evidence`, dan bucket
   privat lain yang dipakai;
2. hapus item/draft/profile publik Coach sintetis dan asset-map privatnya;
3. hapus payment events, attempts, orders, reservation/enrollment, submission,
   score, dan fixture program yang dibuat khusus run;
4. hapus audit test yang secara eksplisit boleh dihapus oleh cleanup procedure;
5. hapus profile sintetis lalu Auth identity melalui Admin API;
6. cabut token/session test dan hapus file kredensial runtime;
7. jalankan query residual berdasarkan `run_id`, email domain, dan semua ID manifest.

Audit production yang diwajibkan kebijakan dan tidak boleh dihapus harus tersisa
hanya sebagai aggregate/redacted event tanpa email, object path, token, QR, foto,
berat badan, atau secret. Jika procedure tidak dapat membuktikan nol residual
selain audit yang diwajibkan, smoke dinyatakan gagal dan rollout dihentikan.

## Bukti kelulusan

- status HTTP dan header per route tanpa response body sensitif;
- daftar ID sintetis yang dibuat dan status cleanup-nya di manifest lokal ignored;
- jumlah residual per tabel/bucket adalah nol;
- direct private Storage URL gagal dan opaque gateway mengikuti publication state;
- tidak ada `@example.invalid`, `run_id`, atau fixture object tersisa di Auth,
  public schema, private asset map, dan Storage;
- Google OAuth dicatat `DEFERRED`, bukan `PASS`.

## Catatan persetujuan

- [x] Google OAuth smoke ditunda; status wajib `DEFERRED`, bukan `PASS`.
- [x] Fixture program non-billable hanya boleh dibuat untuk run sintetis ini.
- [x] Cleanup wajib idempotent, berada dalam `finally`, dan membuktikan residual nol.
- [x] Legal final, Gemma 4 26B A4B dengan fallback Gemma 3 12B, tanpa enforcement ZDR, dan konfigurasi AI disetujui.
