# Incident Response Runbook

Dokumen ini berlaku untuk hosted Supabase `main`, OAuth Google/Apple,
StoreKit, App Store Server Notifications, dan build perangkat Phase 13.1.
Jangan menyalin token, secret, raw QR, berat badan, private media path, signed
payload Apple, atau data pribadi test user ke tiket, chat, screenshot, dan log.

## Prinsip respons

1. Hentikan deployment atau pengujian berikutnya ketika ada indikasi akses
   tidak sah, fulfillment salah, kehilangan data, atau secret terekspos.
2. Catat waktu, environment, operasi, versi build/migration/function, dampak,
   dan correlation ID yang tidak sensitif.
3. Pertahankan bukti minimum yang sudah direduksi; jangan menyalin payload
   sensitif untuk mempermudah investigasi.
4. Pulihkan melalui forward-fix yang direview. Jangan menjalankan reset, seed,
   atau destructive rewrite pada hosted `main`.
5. Setelah pemulihan, ulangi smoke security, authorization, dan alur bisnis
   yang terdampak sebelum membuka kembali pengujian.

## Klasifikasi

- **Kritis:** secret/service key bocor, cross-account private-data access,
  pembayaran sah tidak dapat dipulihkan, penghapusan akun menghapus data akun
  lain, atau hosted database tidak tersedia.
- **Tinggi:** role escalation, forged webhook diterima, duplicate fulfillment,
  refund/revocation tidak mencabut akses, atau private media dapat diakses
  pihak tidak berhak.
- **Sedang:** recurring job terlambat tetapi dapat direkonsiliasi, OAuth satu
  provider gagal, atau sebagian fungsi non-kritis tidak tersedia.
- **Rendah:** tampilan/copy/telemetry non-sensitif yang tidak mengubah akses,
  data, atau transaksi.

## Secret atau tester compromise

1. Hentikan function/job yang memakai credential terdampak bila aman.
2. Revoke/rotate credential pada provider asal: Supabase, Google, Apple Sign
   in, atau App Store Connect.
3. Perbarui Edge secret melalui approved secret management tanpa mencetak
   nilainya.
4. Deploy ulang hanya function yang memerlukan credential tersebut.
5. Invalidasi session tester yang terdampak dan ganti akun sandbox bila perlu.
6. Audit log berdasarkan waktu/correlation ID untuk akses tidak wajar.
7. Jalankan ulang OAuth, deletion, notification TEST, dan reconciliation smoke.

## App Store webhook atau reconciliation outage

1. Jangan mengubah status transaksi secara manual dari client.
2. Pastikan Notification V2 endpoint tetap menolak signature/environment/app
   yang salah dan mengembalikan respons retry untuk kegagalan sebelum durable
   inbox.
3. Pulihkan endpoint/credential, lalu jalankan worker reconciliation dengan
   service-role authorization server-side.
4. Verifikasi duplicate/out-of-order event tetap idempoten dan tidak
   menggandakan enrollment/entitlement.
5. Cocokkan transaksi terverifikasi, refund/revoke, entitlement, dan inbox
   state menggunakan identifier non-sensitif.

## Migration atau function deployment failure

1. Hentikan deployment berikutnya.
2. Bandingkan migration history hosted dengan daftar lokal yang direview.
3. Jangan menghapus migration yang sudah diterapkan dan jangan reset hosted.
4. Buat forward-fix minimal, review SQL/grants/RLS, lalu uji dari reset lokal.
5. Jalankan lint, schema diff, pgTAP, dan integration suite sebelum push.
6. Setelah push, ulangi hosted grants/RLS/Auth/Storage/function smoke.

## Indikasi kebocoran data atau authorization bypass

1. Nonaktifkan route/policy terdampak atau batasi akses secepat mungkin tanpa
   merusak bukti.
2. Rotasi credential bila ada kemungkinan secret ikut terekspos.
3. Identifikasi tipe data, akun, rentang waktu, dan operasi yang terdampak
   tanpa menyalin nilai sensitif.
4. Perbaiki policy/RPC, tambahkan regression test lintas akun, dan deploy
   melalui forward-fix.
5. Lakukan penilaian kewajiban pemberitahuan bersama pihak yang bertanggung
   jawab atas legal/privacy sebelum memberi komunikasi eksternal.

## Penutupan insiden

- Root cause dan boundary yang gagal terdokumentasi.
- Credential terdampak sudah dirotasi dan credential lama tidak berlaku.
- Regression test baru membuktikan kegagalan tidak berulang.
- Hosted smoke, reconciliation, dan redaction scan lulus.
- Owner menyetujui pengujian dilanjutkan.
