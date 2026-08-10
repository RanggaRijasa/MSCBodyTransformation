# Phase 13.1 Physical Test Handoff

Tanggal readiness audit: 9 Agustus 2026

Dokumen ini adalah checklist owner untuk build Release yang terhubung ke
hosted Supabase `main`. Jangan menulis password, token, private key, raw QR,
berat badan, atau path media privat ke dokumen ini.

> Status engineering: **seluruh pekerjaan otomatis/non-manual Phase 13.1
> selesai**. Checklist App Store Connect, credential Apple, test identity/data,
> QR Coach, sandbox purchase, dan exploratory test di dokumen ini berstatus
> `DEFERRED MANUAL` sesuai keputusan owner. Deferral ini tidak menghalangi
> penutupan goal, tetapi purchase testing belum boleh dianggap siap sampai
> seluruh prasyarat manual terkait selesai.

## Build yang dipakai

- App: MSC Body Transformation.
- Version/build: `1.0 (1)`.
- Bundle identifier: `com.ranggar.MSCBodyTransformation`.
- Minimum deployment target: iOS 17.
- Backend: hosted Supabase `main` melalui HTTPS.
- Login production: Google dan Apple saja.
- Email/password, SMTP, dan custom mail domain: skipped by product.
- App Icon, privacy manifest, legal URL/fallback, camera purpose string, dan
  Release fail-closed config sudah berada pada build.
- Build Release terbaru dibangun, dipasang, dan diluncurkan pada iPhone 17
  paired pada 9 Agustus 2026 setelah Debug scenario control dikeluarkan dari
  konfigurasi Release.

## Yang sudah siap otomatis

- [x] Release dapat dibangun dan code-sign untuk iPhone fisik.
- [x] Release dapat dipasang serta diluncurkan pada iPhone fisik.
- [x] Hosted migrations, sembilan Functions, SSL, legal endpoint, dan recurring
  jobs aktif.
- [x] Google hosted OAuth mencapai halaman Google.
- [x] Apple hosted OAuth membuka sheet native Sign in with Apple.
- [x] Guest dapat membuka semua tab publik tanpa Auth identity.
- [x] Direct Guest read terhadap profile, weight, jawaban privat, commerce,
  dan audit ditolak RLS.
- [x] Release tidak membawa fixture, StoreKit test config, localhost, Debug
  scenario control, server secret, atau test-user PII yang diaudit.
- [x] 400 pgTAP assertions, 171 integration checks, dan 194 Swift/StoreKit
  tests lulus.
- [x] Database lint/advisor/schema diff, localization, source-secret scan,
  built-app scan, serta hosted auth/body-limit smoke lulus.

## Input manual sebelum purchase testing — DEFERRED MANUAL

Selesaikan `APP_STORE_CONNECT_SANDBOX_SETUP.md`, kemudian konfirmasi hanya
statusnya tanpa mengirim credential:

- [ ] Paid Apps Agreement, tax, dan banking siap.
- [ ] App record memakai bundle ID final dan numeric Apple ID sudah disimpan.
- [ ] Tiga Coach non-renewing subscription sudah dibuat.
- [ ] Minimal satu paid-cohort non-consumable sudah dibuat.
- [ ] In-App Purchase key dan Apple root certificates tersedia di secure
  storage lokal.
- [ ] Sandbox Notification V2 URL sudah diisi.
- [ ] Sandbox Apple Account sudah login pada iPhone.

Setelah input di atas tersedia, lanjutkan task baru agar Codex meminta approval
production terpisah untuk memasang App Store Server secrets, product mapping,
dan menjalankan TEST notification. Product mapping tidak boleh dibuat dari
contoh slug atau harga yang belum final.

## Test identity dan data minimum — DEFERRED MANUAL

Gunakan identity khusus pengujian tanpa data pribadi nyata:

- [ ] Satu Google identity untuk Participant/Admin bootstrap.
- [ ] Satu Apple identity dengan Hide My Email untuk private-relay flow.
- [ ] Satu identity lain untuk calon Coach.
- [ ] Satu identity lain untuk Participant yang akan scan QR Coach.

Urutan bootstrap hosted yang aman:

1. Login satu kali dengan Google pada build Release agar trigger Auth membuat
   profile Participant.
2. Catat hanya `user_id` profile yang akan menjadi Admin; jangan kirim token
   atau password.
3. Minta approval eksplisit untuk one-time Admin bootstrap yang diaudit.
4. Admin membuat program dan content melalui UI aplikasi, bukan melalui seed.
5. Identity Coach mendaftar melalui flow normal; Admin menerima; Sandbox
   purchase mengaktifkan akses Coach.
6. Gunakan QR Coach aktif dari perangkat Coach untuk enrollment Participant.

Hosted production tidak boleh menerima `seed.sql`, fixture, atau identity
buatan langsung di `auth.users`.

## Matriks owner pada iPhone — DEFERRED MANUAL

Isi `LULUS`, `GAGAL`, atau `BELUM` dan catat langkah reproduksi tanpa data
sensitif.

### 1. Guest dan legal

- [ ] Beranda, Program, Peringkat, Coach, dan Profil dapat dibuka.
- [ ] Empty state tampil dalam Bahasa Indonesia dan tidak menampilkan data
  privat.
- [ ] Privacy Policy dan Terms dapat dibuka; fallback tetap terbaca bila
  koneksi dimatikan.
- [ ] `Gabung program` mengarahkan ke Login dan mempertahankan program pilihan.

### 2. Google dan Apple

- [ ] Google login, logout, relogin, cancel, dan account switch.
- [ ] Force-close setelah Google login lalu session dipulihkan.
- [ ] Apple first login mengisi nama awal yang tetap dapat diedit.
- [ ] Apple private relay, logout, relogin, cancel, dan session restore.
- [ ] Google dan Apple tetap menjadi identity/account terpisah.

### 3. Admin dan program

- [ ] Admin membuat draft program gratis, day, step, question, dan content.
- [ ] Admin mem-publish program lalu Guest dapat melihat projection publik.
- [ ] Admin membuat paid cohort yang Product ID-nya cocok dengan mapping.
- [ ] Capacity, cutoff, closure, winner locking, dan poster mempunyai state
  yang dapat dipahami.

### 4. Coach

- [ ] Eligibility dan attestations tervalidasi.
- [ ] Admin accept membuat status menunggu pembayaran, bukan langsung Coach.
- [ ] Sandbox purchase mengaktifkan akses tiga bulan dan QR.
- [ ] Renewal manual memperpanjang entitlement tanpa acceptance ulang.
- [ ] Expired/revoked access menonaktifkan fitur dan QR Coach.

### 5. Participant

- [ ] QR Coach aktif dapat dipindai dengan kamera fisik.
- [ ] QR invalid, Coach inactive, capacity penuh, cutoff, dan duplicate
  enrollment menampilkan error yang dapat ditindaklanjuti.
- [ ] Tidak ada typed/manual Coach-code fallback.
- [ ] Free enrollment dan paid-cohort purchase berfungsi.
- [ ] Weigh-in, typed answer, quiz, photo evidence, retry, review, scoring,
  leaderboard, winner, dan poster berfungsi.

### 6. Commerce dan deletion

- [ ] Harga/currency berasal dari StoreKit.
- [ ] Pending, cancel, interrupted purchase, relaunch, restore, dan duplicate
  tidak menggandakan fulfillment.
- [ ] Notification V2 dan reconciliation terlihat pada audit operasional.
- [ ] Google reauthentication diikuti immediate deletion.
- [ ] Apple reauthentication, token revoke, lalu immediate deletion.
- [ ] Private profile/media hilang dan retained audit/commerce/winner anonim.
- [ ] Coach dengan Participant aktif diblok sampai Admin transfer.

### 7. Perangkat dan aksesibilitas

- [ ] Camera denied/restricted dan PhotosPicker mempunyai recovery action.
- [ ] Offline, timeout, reconnect, background/foreground, dan force-close tidak
  membuat state transaksi ambigu.
- [ ] Dynamic Type besar, VoiceOver, dark/light, Increase Contrast, Reduce
  Motion/Transparency, dan Differentiate Without Color tetap dapat digunakan.
- [ ] Tidak ada crash, hang, kebocoran token/PII pada UI, atau transaksi yang
  tidak dapat dipulihkan.

## Pelaporan defect

Untuk setiap defect, catat:

- build `1.0 (1)`;
- perangkat dan versi iOS;
- role dan flow;
- langkah reproduksi;
- hasil aktual dan hasil yang diharapkan;
- screenshot yang sudah disensor bila relevan.

Jangan kirim screenshot pembayaran, token, raw QR, email private relay penuh,
nomor HP, weight, atau foto bukti privat.
