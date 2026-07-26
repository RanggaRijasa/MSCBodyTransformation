# Phase 00: Project Bootstrap Offline

## Tujuan

Membuat fondasi Xcode yang bersih dan dapat dikembangkan tanpa layanan eksternal. Phase ini menghasilkan app shell placeholder, struktur folder, konfigurasi build, test target, dan dependency container lokal.

## External dependency status

**Tidak boleh menyentuh layanan eksternal.**

- Tidak ada Supabase.
- Tidak ada Google OAuth.
- Tidak ada Sign in with Apple live flow.
- Tidak ada App Store Connect.
- Tidak ada API key.
- Tidak ada third-party package.

## Prasyarat

- Xcode stable terbaru yang tersedia.
- iOS 17 simulator.
- Repository kosong atau existing repository yang sudah diperiksa.

## Bahasa dan localization

- Bahasa utama aplikasi adalah Bahasa Indonesia.
- Buat `Localizable.xcstrings` sejak project bootstrap.
- Gunakan locale `id-ID` untuk fixture format angka, tanggal, berat, dan harga.
- Jangan hard-code reusable production copy di banyak View.
- Baca `UI_REFERENCE_SHEET.md` sebelum membuat shared UI.

## Hasil akhir

- Project dapat dibuka dan dibangun.
- Minimum iOS 17.
- Swift 6 dan strict concurrency yang sesuai.
- Unit test dan UI test target berjalan.
- Root app menampilkan local development landing screen.
- Struktur feature-oriented tersedia.
- Tidak ada secret dalam repository.

## Struktur awal

```text
MSCBodyTransformation/
├── App/
│   ├── MSCBodyTransformationApp.swift
│   ├── AppEnvironment.swift
│   ├── AppConfiguration.swift
│   ├── AppRouter.swift
│   └── RootView.swift
├── Core/
│   ├── Clock/
│   ├── Identifiers/
│   ├── Logging/
│   ├── Media/
│   ├── QR/
│   └── Utilities/
├── Domain/
│   ├── Models/
│   ├── Repositories/
│   ├── UseCases/
│   ├── Scoring/
│   └── Validation/
├── Features/
├── SharedUI/
│   ├── Components/
│   ├── Styles/
│   ├── Accessibility/
│   └── PreviewSupport/
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.xcstrings
│   └── PrivacyInfo.xcprivacy
├── Tests/
└── UITests/
```

## Checklist implementasi

### Project settings

- [x] Buat atau periksa Xcode project.
- [ ] Set deployment target iOS 17.0.
- [ ] Set Swift language mode yang kompatibel dengan Swift 6.
- [ ] Aktifkan strict concurrency checking secara bertahap.
- [x] Pastikan iPhone dan iPad device families tidak menghasilkan layout crash.
- [ ] Tambahkan Debug, Staging, dan Release configuration.
- [x] Pastikan secrets tidak dimasukkan ke `.xcconfig` yang dikomit.
- [x] Tambahkan `.gitignore` yang sesuai Xcode.
- [x] Pastikan `Package.resolved` belum berisi dependency yang tidak dibutuhkan.

### App wiring

- [x] Buat `MSCBodyTransformationApp`.
- [x] Buat `AppEnvironment` sebagai root dependency container.
- [x] Buat `AppConfiguration` dengan mode `.localDemo`.
- [x] Buat `AppRouter` tanpa global mutable singleton.
- [x] Buat `RootView`.
- [x] RootView menampilkan status build, current demo role, dan tombol masuk ke demo placeholder.
- [x] Gunakan `@Environment` atau explicit injection untuk dependency bersama.

### Core testability

- [x] Buat `AppClock` protocol.
- [x] Buat `SystemClock`.
- [x] Buat `FixedClock` untuk test dan preview.
- [x] Buat `IdentifierGenerating` protocol.
- [x] Buat production UUID generator.
- [x] Buat deterministic UUID generator untuk test.
- [x] Buat OSLog categories tanpa data pribadi.

### Test targets

- [x] Tambahkan Swift Testing unit test target.
- [x] Tambahkan XCTest UI test target.
- [x] Buat satu smoke test aplikasi.
- [x] Buat satu UI launch test.
- [x] Pastikan test dapat dijalankan tanpa jaringan.

### Developer documentation

- [x] Buat `README.md` untuk build lokal.
- [x] Buat `CONTRIBUTING.md`.
- [x] Dokumentasikan format file dan naming.
- [x] Dokumentasikan larangan secret.
- [x] Dokumentasikan command build dan test yang benar berdasarkan scheme aktual.

## Larangan scope

Jangan:

- Membuat login sungguhan.
- Menambahkan package Supabase.
- Membuat database schema.
- Membuat semua feature screen.
- Menambahkan StoreKit purchase code.
- Membuat custom design system besar sebelum app dapat dibangun.
- Menggunakan force unwrap untuk configuration.

## Verification

Codex harus menjalankan:

```bash
xcodebuild -list
```

Kemudian sesuaikan scheme dan simulator yang tersedia:

```bash
xcodebuild   -scheme MSCBodyTransformation   -configuration Debug   -destination 'platform=iOS Simulator,name=iPhone 16'   build
```

Jalankan unit test dan UI smoke test.

## Exit criteria

- [x] Clean build pada simulator.
- [x] App launch tanpa crash.
- [x] Unit test target berjalan.
- [x] UI test target berjalan.
- [x] Tidak ada third-party dependency.
- [x] Tidak ada secret.
- [x] Root dependency container dapat diganti untuk preview dan test.

## Progress log

Tambahkan catatan tanggal, perubahan, command yang dijalankan, hasil build, hasil test, dan blocker di bawah ini.

### Log

#### 26 Juli 2026 — Fondasi demo lokal

- Files changed: fondasi `App`, clock, generator UUID, logging, placeholder
  demo lokal, shared UI styles, semantic color assets, string catalog, privacy
  manifest, unit/UI smoke tests, `README.md`, dan `CONTRIBUTING.md`.
- Assumptions: folder test target yang sudah ada tetap digunakan di root
  repository; folder kosong untuk fase berikutnya dibuat tanpa marker resource
  karena project memakai filesystem-synchronized groups.
- Build command:
  `xcodebuild -project MSCBodyTransformation.xcodeproj -scheme MSCBodyTransformation -configuration Debug -destination 'platform=iOS Simulator,id=C63135B7-AF6A-42C0-8993-DF4C72589FE1' SWIFT_VERSION=6 SWIFT_STRICT_CONCURRENCY=complete IPHONEOS_DEPLOYMENT_TARGET=17.0 clean build`
- Test command: command build yang sama dengan
  `-only-testing:MSCBodyTransformationTests test`, lalu
  `-only-testing:MSCBodyTransformationUITests test`.
- Result: build Swift 6 dengan strict concurrency complete dan deployment
  target override iOS 17 berhasil. App berhasil diluncurkan pada iPhone 17 Pro
  dan iPad Pro 13-inch (M5), light/dark mode terverifikasi. Unit test 3 lulus;
  UI test target lulus tanpa kegagalan.
- Remaining blockers: deployment target project masih 26.5,
  `SWIFT_VERSION` masih 5.0, dan konfigurasi Staging belum ada. Ketiganya
  memerlukan perubahan `project.pbxproj`, yang tidak diizinkan pada task ini.
