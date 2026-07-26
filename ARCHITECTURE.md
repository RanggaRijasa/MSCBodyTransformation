# Arsitektur

## Arah dependensi

```text
SwiftUI View
  → feature state / @Observable model
  → use case atau domain service
  → repository protocol
  → InMemoryAppRepository
```

View hanya merender state dan meneruskan aksi. Aturan skor, validasi,
visibilitas hari, ranking, izin peran, dan idempotensi berada di lapisan
domain atau repository.

## Lapisan

- `App`: bootstrap, dependency environment, fake session, router, tab, dan
  launcher skenario Debug.
- `Domain/Models`: nilai portable tanpa tipe SwiftUI, UIKit, StoreKit, atau
  Supabase.
- `Domain/Services` dan `Domain/UseCases`: aturan bisnis deterministik.
- `Domain/Repositories`: kontrak adapter.
- `LocalData`: decoder fixture dan actor repository in-memory.
- `Features`: state serta View terpisah untuk Peserta, Coach, Admin, media,
  dan app shell.
- `SharedUI`: token visual semantik, komponen reusable, aksesibilitas, dan
  fallback Liquid Glass.
- `Resources`: asset, fixture JSON, video lokal, dan `Localizable.xcstrings`.

## State dan konkurensi

Root memasang `AppEnvironment`. Mutable data demo diisolasi oleh actor
`InMemoryAppRepository`; feature state yang mengubah UI hidup di main actor.
Pemuatan menggunakan structured concurrency, memeriksa cancellation sebelum
menulis hasil, dan terikat lifecycle melalui `.task`.

## Navigasi

Setiap peran memiliki lima tab. `ShellTabRouter` mempertahankan
`NavigationStack` terpisah per tab. Route divalidasi terhadap peran sebelum
dibuka. Sheet dan alert memakai enum agar presentasi saling eksklusif.

## Media

Tipe domain hanya menyimpan referensi lokal. `NativeImageProcessor`
menormalisasi orientasi, downsample, membuat JPEG baru tanpa metadata lokasi,
dan menyediakan thumbnail. File sementara diberi proteksi yang tersedia,
dikecualikan dari backup, serta dibersihkan bila yatim.

## Skor

`EnrollmentScoreCalculator` menyatukan poin langkah approved, poin berat
berbasis `Decimal`, penyesuaian, dan progres. `LeaderboardSorter` menerapkan
tie-break stabil. `WinnerSelector` membuat snapshot final yang tidak berubah
setelah dikunci.

## Adaptasi platform

iOS 26+ memakai Liquid Glass hanya pada surface interaktif yang ringkas.
iOS 17–25 memakai fallback SwiftUI native. Semua API baru dilindungi
availability check. Tidak ada package pihak ketiga pada Track A.
