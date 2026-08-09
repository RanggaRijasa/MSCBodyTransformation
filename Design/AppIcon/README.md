# MSC Body Transformation App Icon

Artwork final ini menggunakan desain yang disetujui pada 9 Agustus 2026:
background hitam, orbit merah, `MSC` dan `BODY` kuning, serta
`TRANSFORMATION` merah miring.

## Output produksi

Asset Catalog iOS memakai tiga bitmap 1024×1024 tanpa alpha:

- `AppIcon-Default.png`: artwork final penuh.
- `AppIcon-Dark.png`: artwork berwarna pada background hitam bersih.
- `AppIcon-Tinted.png`: representasi monokrom untuk tinted appearance.

Ketiganya berada di
`MSCBodyTransformation/Resources/Assets.xcassets/AppIcon.appiconset` dan
direferensikan oleh `Contents.json`.

## Layer Icon Composer

Import layer dari `IconComposerLayers` dengan urutan belakang ke depan:

1. `01-Background.png`
2. `02-Orbit-Red.png`
3. `03-MSC-Yellow.png`
4. `04-Body-Yellow.png`
5. `05-Transformation-Red.png`

Gunakan `06-Monochrome-Artwork.png` sebagai sumber appearance monokrom bila
perlu menyesuaikan rendition tinted di Icon Composer. Semua layer berukuran
1024×1024. Background bersifat opaque; layer artwork mempunyai alpha dan tidak
memuat rounded-rectangle mask. Bentuk dan teks sudah berupa raster artwork,
sehingga tidak bergantung pada font saat dokumen dibuka di Mac lain.

Dokumen native Icon Composer berada di
`MSCBodyTransformation-AppIcon.icon`. Xcode memakai bitmap Asset Catalog untuk
build saat ini; dokumen `.icon` dan layer disimpan sebagai design source agar
efek, depth, dan appearance dapat disetel ulang tanpa mengubah master artwork.

## Regenerasi

Master yang disetujui berada di `Source/MSCBodyTransformation-AppIcon-Approved.png`.
Regenerasi output deterministik dengan:

```sh
CLANG_MODULE_CACHE_PATH=/private/tmp/msc-icon-module-cache \
SWIFT_MODULECACHE_PATH=/private/tmp/msc-icon-module-cache \
swift scripts/generate_app_icon_assets.swift \
  Design/AppIcon/Source/MSCBodyTransformation-AppIcon-Approved.png \
  Design/AppIcon \
  MSCBodyTransformation/Resources/Assets.xcassets/AppIcon.appiconset
```

Jangan mengekspor rounded corners ke bitmap. iOS menerapkan mask perangkatnya.
Preview 180, 120, 60, dan 40 px tersedia di `SmallSizePreviews` untuk audit
keterbacaan sebelum archive.
