# MSC Body Transformation

Aplikasi native iOS dan iPadOS untuk program transformasi tubuh. Phase 00
sampai Phase 08 menyediakan fondasi, model domain, repository protocol, use
case, fixture JSON, semantic design system, app shell role-aware, serta
participant, coach, dan Admin CMS journey lokal yang dapat dibangun dan
dijalankan tanpa internet maupun layanan eksternal.

## Kebutuhan lokal

- macOS dengan Xcode yang menyediakan simulator iOS yang sesuai dengan
  deployment target project saat ini.
- Tidak diperlukan akun layanan, API key, package pihak ketiga, atau koneksi
  internet.

## Membuka project

Buka `MSCBodyTransformation.xcodeproj`, pilih scheme
`MSCBodyTransformation`, lalu pilih simulator iPhone atau iPad yang tersedia.

## Build dari command line

Daftar scheme dan target:

```bash
xcodebuild -list -project MSCBodyTransformation.xcodeproj
```

Build Debug pada simulator:

```bash
xcodebuild \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  build
```

## Menjalankan test

Unit test Swift Testing:

```bash
xcodebuild \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -only-testing:MSCBodyTransformationTests \
  test
```

UI test XCTest:

```bash
xcodebuild \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -only-testing:MSCBodyTransformationUITests \
  test
```

## Konfigurasi lokal

App menggunakan `AppConfiguration.localDemo` dan memasang dependency melalui
`AppEnvironment`. Preview dan test dapat mengganti clock serta generator UUID
tanpa global mutable singleton.

Kontrol pilihan peran Peserta, Coach, dan Admin hanya dikompilasi pada build
Debug.

Source Phase 00 sudah diverifikasi dengan override command line
`SWIFT_VERSION=6`, `SWIFT_STRICT_CONCURRENCY=complete`, dan
`IPHONEOS_DEPLOYMENT_TARGET=17.0`. Nilai tersebut belum dipersist ke project
karena perubahan `project.pbxproj` tidak termasuk izin task ini.

## Data lokal Phase 01

Data demo dimuat dari `Resources/Fixtures` melalui decoder ISO 8601 yang
memetakan kegagalan ke domain error. Satu actor repository menyimpan state
lokal dengan aman untuk konkurensi, lalu diekspos melalui protocol di
`AppEnvironment`. Debug role switcher mengganti fake session Peserta, Coach,
atau Admin.

## App shell Phase 02

Build Debug menyediakan pilihan peran Peserta, Coach, dan Admin, ditambah
skenario state bersama serta alur khusus tiap peran. Setiap peran memiliki
lima tab dan
`NavigationStack` terpisah per tab. Surface interaktif menggunakan Liquid
Glass secara selektif di iOS 26+, dengan fallback SwiftUI native untuk iOS 17
sampai iOS 25.

## Participant journey Phase 03

Peserta dapat menjalankan onboarding demo, bergabung dengan kode `MSC7HARI`,
mengisi berat badan awal dan akhir, melihat program harian, menambahkan bukti
foto contoh lokal, menyelesaikan langkah, serta melihat progres dan papan
peringkat berubah. Tab Program, Coach, dan Profil menyediakan timeline,
direktori coach, riwayat enrollment, pengaturan, dan alat simulasi khusus
Debug.

## Coach experience Phase 04

Coach dapat melihat dashboard, saldo kuota, program aktif, peserta yang
ditugaskan, filter dan detail progres, bukti serta jawaban lokal, antrean
pemeriksaan, undangan dengan QR lokal, papan peringkat, profil publik, dan
pratinjau paket kuota. Persetujuan atau penolakan menghitung ulang poin lokal.
Pembuatan undangan tidak memakai kuota; satu kuota baru terpakai setelah
enrollment demo berhasil dan enrollment duplikat tetap idempoten.

Store Coach hanya menampilkan fixture paket 10, 25, dan 50 kuota dengan harga
contoh. Konfirmasi demo menambah saldo repository lokal tanpa membuat
transaksi atau prompt App Store.

## Admin CMS Phase 05

Admin dapat melihat ringkasan operasional dan audit lokal, mencari serta
memfilter program, membuat dan menduplikasi draft, menyusun program melalui
editor tujuh tahap, mem-preview pengalaman peserta, dan mensimulasikan
publish. Tab Orang mendukung persetujuan Coach, visibilitas profil,
enrollment manual beralasan, serta penyesuaian poin beralasan. Tab Konten
menyediakan banner pemenang, jadwal visibilitas, pengarsipan, dan snapshot
lima pemenang yang deterministik.

Semua tindakan istimewa dicatat dalam audit in-memory. Publish, media, skor,
dan pemenang tetap berstatus simulasi lokal serta tidak dianggap sebagai
hasil yang diverifikasi server.

## Native media dan QR Phase 06

Peserta dapat memilih foto dengan `PhotosPicker`, mengambil foto melalui
wrapper kamera native, memproses evidence menjadi JPEG terorientasi benar
tanpa metadata lokasi, melihat thumbnail, mengganti, menghapus, dan mencoba
ulang. Video petunjuk diputar dari MP4 bundle menggunakan `AVKit.VideoPlayer`
tanpa autoplay.

Undangan Coach memakai QR `msc-demo://join/{opaque-token}`, padding aman,
native share sheet, serta label aksesibilitas yang tidak membacakan token.
Peserta dapat memindai lewat VisionKit dengan fallback AVFoundation, memakai
QR demo pada simulator, atau tetap mengetik kode manual. File evidence demo
disimpan sementara, dikecualikan dari backup, dilindungi saat memungkinkan,
dan dibersihkan bila yatim.

## Scoring dan leaderboard Phase 07

Scoring lokal memakai satu rangkaian service deterministik untuk poin langkah
approved, poin berat berbasis `Decimal`, adjustment terpisah, progress, hari
aktif, visibilitas, ranking, dan pemilihan pemenang. Default program adalah
800 poin per kilogram, setara 80 poin per 0,1 kg, dengan pembulatan
`Decimal` nearest.

Ranking memecah seri berdasarkan total, poin langkah, poin berat, waktu
selesai, lalu UUID enrollment. Participant, Coach, dan Admin membaca hasil
repository yang dihitung melalui service yang sama. Snapshot pemenang tetap
immutable setelah dikunci; perubahan skor berikutnya menampilkan peringatan
dan reset hanya tersedia pada build Debug.

## Accessibility, reliability, dan demo Phase 08

Launcher Debug menyediakan 17 skenario deterministik untuk sesi keluar,
loading, offline, izin, error repository, perjalanan Peserta, state Coach,
dan state Admin. Unit test meliputi model, fixture, repository, validasi,
media, QR, skor, ranking, timezone, feature state, navigasi, dan error.
UI test mencakup alur kritis ketiga peran, pergantian peran, dark mode,
Dynamic Type aksesibilitas, offline, saldo nol, serta lock pemenang.

Panduan demo, arsitektur, glosarium, fixture, inventaris layar, dan checklist
adapter tersedia pada dokumen Markdown di root repository.

## Batasan Phase 08

Supabase, OAuth, StoreKit production, App Store Connect, networking, dan
package pihak ketiga belum digunakan. Kamera dan QR scanner pada perangkat
fisik memerlukan `NSCameraUsageDescription` pada target Xcode; konfigurasi
tersebut belum ditambahkan karena build setting dan `project.pbxproj` berada
di luar scope perubahan. Mock access check bukan pengganti Row Level Security
produksi.
