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

- [ ] Buat atau periksa Xcode project.
- [ ] Set deployment target iOS 17.0.
- [ ] Set Swift language mode yang kompatibel dengan Swift 6.
- [ ] Aktifkan strict concurrency checking secara bertahap.
- [ ] Pastikan iPhone dan iPad device families tidak menghasilkan layout crash.
- [ ] Tambahkan Debug, Staging, dan Release configuration.
- [ ] Pastikan secrets tidak dimasukkan ke `.xcconfig` yang dikomit.
- [ ] Tambahkan `.gitignore` yang sesuai Xcode.
- [ ] Pastikan `Package.resolved` belum berisi dependency yang tidak dibutuhkan.

### App wiring

- [ ] Buat `MSCBodyTransformationApp`.
- [ ] Buat `AppEnvironment` sebagai root dependency container.
- [ ] Buat `AppConfiguration` dengan mode `.localDemo`.
- [ ] Buat `AppRouter` tanpa global mutable singleton.
- [ ] Buat `RootView`.
- [ ] RootView menampilkan status build, current demo role, dan tombol masuk ke demo placeholder.
- [ ] Gunakan `@Environment` atau explicit injection untuk dependency bersama.

### Core testability

- [ ] Buat `AppClock` protocol.
- [ ] Buat `SystemClock`.
- [ ] Buat `FixedClock` untuk test dan preview.
- [ ] Buat `IdentifierGenerating` protocol.
- [ ] Buat production UUID generator.
- [ ] Buat deterministic UUID generator untuk test.
- [ ] Buat OSLog categories tanpa data pribadi.

### Test targets

- [ ] Tambahkan Swift Testing unit test target.
- [ ] Tambahkan XCTest UI test target.
- [ ] Buat satu smoke test aplikasi.
- [ ] Buat satu UI launch test.
- [ ] Pastikan test dapat dijalankan tanpa jaringan.

### Developer documentation

- [ ] Buat `README.md` untuk build lokal.
- [ ] Buat `CONTRIBUTING.md`.
- [ ] Dokumentasikan format file dan naming.
- [ ] Dokumentasikan larangan secret.
- [ ] Dokumentasikan command build dan test yang benar berdasarkan scheme aktual.

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

- [ ] Clean build pada simulator.
- [ ] App launch tanpa crash.
- [ ] Unit test target berjalan.
- [ ] UI test target berjalan.
- [ ] Tidak ada third-party dependency.
- [ ] Tidak ada secret.
- [ ] Root dependency container dapat diganti untuk preview dan test.

## Progress log

Tambahkan catatan tanggal, perubahan, command yang dijalankan, hasil build, hasil test, dan blocker di bawah ini.

### Log
