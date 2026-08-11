# Phase 02 PWA Presentation Baseline

## Kontrak manifest

- Nama: `MSC Body Transformation`.
- Nama singkat: `MSC Body`.
- Start URL: `/hari-ini`.
- Scope: `/`.
- Display: `standalone`.
- Locale aplikasi: `id-ID`.
- Theme color: brand primary red.
- Background: semantic app background light.

Manifest dibuat dengan file convention `src/app/manifest.ts`. Service worker,
offline cache, install prompt, dan lifecycle update sengaja ditunda ke Phase 11.

## Pipeline ikon

Source brand dibaca dari AppIcon final iOS 1024×1024 tanpa mengubah file asal.
Pipeline hanya melakukan resize deterministik dan padding maskable:

```text
sh scripts/generate-pwa-icons.sh \
  ../MSCBodyTransformation/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-Default.png
```

Output seluruhnya berada di `public/icons/`:

- `app-icon-192.png` — 192×192.
- `app-icon-512.png` — 512×512.
- `app-icon-maskable-512.png` — source 410×410 pada kanvas hitam 512×512.
- `apple-touch-icon.png` — 180×180.

Maskable icon mempertahankan artwork di safe zone 80%. Full PWA icon audit dan
perangkat fisik tetap menjadi gate Phase 11 dan Phase 13.
