# MSC Body Transformation iOS MVP
## Phased Codex Workplan

Dokumen ini adalah pintu masuk untuk menjalankan pengembangan aplikasi secara bertahap. Workplan sengaja dipisah agar Codex dapat membangun bagian lokal yang terlihat dan dapat diuji sekarang, tanpa menunggu Supabase, Google OAuth, App Store Connect, domain universal link, atau kredensial eksternal lain.

## Workplan program end-to-end authoritative

Sebelum mengubah domain, UI program, Supabase schema, scoring, pembayaran, atau
Android contract, baca:

- `PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md`
- `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`
- `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`

Dokumen tersebut memuat keputusan produk terbaru tentang satu Coach per
Peserta, multi-program, QR enrollment, konten dan kuis, timbang, scoring,
duplikasi cohort, serta commerce lintas App Store dan Google Play. Jika ada
konflik dengan phase lama, workplan remediation tersebut berlaku sampai file
phase terkait direkonsiliasi.

Semua file phase lama yang bertentangan sekarang diperlakukan sebagai catatan
historis implementasi lokal. Kontrak baru dan matriks consumer di atas adalah
satu-satunya sumber requirement program yang aktif.

## Target produk

Aplikasi native iOS dan iPadOS untuk program transformasi berat badan dengan tiga role:

- Participant mengikuti beberapa program, menjawab konten typed termasuk
  unggah foto, mengisi timbang melalui langkah program, memperoleh poin, dan
  melihat leaderboard.
- Coach memiliki QR identifier unik untuk pendaftaran peserta dan memantau peserta.
- Admin mengelola program melalui CMS, transfer Coach, koreksi/audit, closure,
  pemenang, poster, serta konfigurasi commerce program.

## Keputusan teknis utama

- Swift 6 dan SwiftUI.
- Minimum deployment target iOS 17.
- iPhone sebagai fokus pertama, tetapi layout harus tetap layak pada iPad.
- Native Apple frameworks sebisa mungkin.
- Observation untuk state modern.
- Swift Testing untuk unit test dan XCTest untuk UI test.
- Liquid Glass native pada iOS 26 atau lebih baru.
- Fallback native SwiftUI pada iOS 17 sampai 25.
- Feature-oriented architecture.
- Repository protocol dan dependency injection agar UI tidak bergantung pada Supabase.
- Business rules penting akhirnya harus authoritative di server.
- Android akan dibuat kemudian dengan Kotlin dan Jetpack Compose menggunakan backend yang sama.

## Bahasa dan UI Reference

- Bahasa utama aplikasi adalah **Bahasa Indonesia**.
- Semua copy production-facing menggunakan Bahasa Indonesia.
- Gunakan locale `id-ID` untuk angka, berat, tanggal, waktu, dan mata uang.
- Gunakan `Localizable.xcstrings` sejak awal agar struktur localization siap dikembangkan.
- Referensi visual wajib terdapat di `UI_REFERENCE_SHEET.md`.
- Warna utama adalah hitam, merah, dan kuning dengan semantic colors yang berbeda untuk light mode dan dark mode.
- Tipografi menggunakan San Francisco dan Dynamic Type native.
- Coding agent wajib membaca `UI_REFERENCE_SHEET.md` sebelum membuat atau mengubah UI.

## Jalur pengerjaan

### Track A: Lokal, dapat dimulai sekarang

Tidak membutuhkan akun atau kredensial eksternal.

1. `01_PHASE_00_PROJECT_BOOTSTRAP_OFFLINE.md`
2. `02_PHASE_01_DOMAIN_MODELS_AND_MOCKS.md`
3. `03_PHASE_02_DESIGN_SYSTEM_AND_APP_SHELL.md`
4. `04_PHASE_03_PARTICIPANT_EXPERIENCE_UI.md`
5. `05_PHASE_04_COACH_EXPERIENCE_UI.md`
6. `06_PHASE_05_ADMIN_CMS_UI.md`
7. `07_PHASE_06_NATIVE_MEDIA_QR_AND_LOCAL_WORKFLOWS.md`
8. `08_PHASE_07_LOCAL_SCORING_AND_LEADERBOARD.md`
9. `09_PHASE_08_ACCESSIBILITY_TESTS_AND_DEMO.md`

Pada akhir Track A, aplikasi harus dapat didemokan sepenuhnya dengan data lokal dan role switcher khusus Debug. Semua layar utama, navigasi, form, state, media picker, QR lokal, scoring lokal, leaderboard, dan CMS prototype sudah dapat digunakan.

### Track B: Integrasi eksternal

Dikerjakan setelah Track A stabil.

10. `10_PHASE_09_SUPABASE_FOUNDATION.md`
11. `11_PHASE_10_AUTH_EMAIL_GOOGLE_APPLE.md`
12. `12_PHASE_11_REAL_DATA_AND_SERVER_OPERATIONS.md`
13. `13_PHASE_12_STOREKIT_PROGRAM_PAYMENTS.md`
14. `14_PHASE_13_SECURITY_RELEASE_AND_TESTFLIGHT.md`
15. `15_PHASE_14_ANDROID_HANDOFF.md`

## Aturan dependency

### Phase 00 sampai 08

Dilarang:

- Menambahkan `supabase-swift`.
- Menulis URL atau key Supabase.
- Mengonfigurasi Google Cloud.
- Mengimplementasikan callback OAuth asli.
- Menghubungkan App Store Connect.
- Menambahkan service role key atau secret apa pun.
- Membuat UI yang hanya dapat dirender ketika jaringan tersedia.

Gunakan:

- In-memory repositories.
- JSON fixtures dari app bundle.
- Fake session dan Debug role switcher.
- Local image assets.
- Local Store preview data, bukan transaksi App Store.
- Deterministic clocks dan UUID provider untuk test.

### Phase 09 dan seterusnya

Adapter eksternal menggantikan mock secara bertahap tanpa menulis ulang feature UI.

## Dependency boundary yang wajib dipertahankan

```text
SwiftUI View
    ↓
Feature State / @Observable Model
    ↓
Use Case / Domain Service
    ↓
Repository Protocol
    ↓
Mock Adapter sekarang
    ↓
Supabase / StoreKit Adapter kemudian
```

SwiftUI View tidak boleh:

- Menjalankan query Supabase.
- Menentukan role authorization.
- Menjadi sumber kebenaran poin.
- Menyimpan aturan pembelian kredit.
- Menghitung hari program hanya dari jam perangkat.
- Mengandung networking langsung di `body`.

## Cara menjalankan Codex

Berikan Codex hanya satu file phase pada satu sesi kerja. Sertakan repository yang sedang dikerjakan dan instruksikan:

1. Baca file phase.
2. Periksa kondisi repository.
3. Kerjakan checklist dari atas secara berurutan.
4. Bangun setelah setiap vertical slice kecil.
5. Jalankan test terkait.
6. Jangan menyentuh phase berikutnya.
7. Perbarui checklist dan progress log pada file phase.
8. Catat asumsi dan hal yang diblokir.

## Urutan mulai yang direkomendasikan

Mulai dengan Phase 00. Setelah clean build, lanjut Phase 01. Jangan langsung membuat semua layar sebelum domain models, repository protocols, dan mock fixtures selesai karena itu akan membuat UI sulit dipindahkan ke Supabase.

## Definition of Done Track A

Track A selesai bila:

- Aplikasi berjalan tanpa internet.
- Debug role switcher dapat membuka Participant, Coach, dan Admin.
- Semua tab role tersedia.
- Participant dapat mengikuti sample program dengan timbang awal, harian,
  dan akhir.
- Setiap step dapat menerima foto lokal dan status selesai.
- Coach dapat melihat sample peserta, progress, bukti, dan review queue.
- Admin dapat membuat dan mengedit draft program lokal.
- Leaderboard berubah berdasarkan aksi pada mock data.
- Liquid Glass dan fallback sama-sama dapat dikompilasi.
- Dynamic Type, VoiceOver labels, light mode, dan dark mode diuji.
- Unit test dan critical UI test lulus.
- Tidak ada Supabase, OAuth, atau App Store production dependency.
