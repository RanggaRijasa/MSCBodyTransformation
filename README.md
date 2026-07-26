# MSC Body Transformation

Aplikasi native iOS dan iPadOS untuk program transformasi tubuh. Phase 00
sampai Phase 02 menyediakan fondasi, model domain, repository protocol, use
case, fixture JSON, semantic design system, shared components, serta app shell
role-aware yang dapat dibangun dan dijalankan tanpa internet maupun layanan
eksternal.

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
scenario loading, error, empty, offline, participant active, coach review
queue, serta admin draft editor. Setiap peran memiliki lima tab dan
`NavigationStack` terpisah per tab. Surface interaktif menggunakan Liquid
Glass secara selektif di iOS 26+, dengan fallback SwiftUI native untuk iOS 17
sampai iOS 25.

## Batasan Phase 02

Supabase, OAuth, StoreKit production, App Store Connect, networking, dan
package pihak ketiga belum digunakan. Participant journey lengkap tetap
menjadi scope Phase 03.
