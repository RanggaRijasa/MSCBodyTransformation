# ADR-0002 — Phosphor SVG and approved iOS App Icon

Status: Accepted  
Date: 12 August 2026

## Context

Icon harus modern, konsisten, dan bukan hasil gambar `div`/CSS. iOS menggunakan SF Symbols dan sudah memiliki approved App Icon.

## Decision

- Gunakan Phosphor Icons melalui SVG (`phosphor-react-native` + `react-native-svg`) di balik semantic wrapper `MSCIcon`.
- Feature tidak mengimpor icon pack secara langsung.
- Gunakan satu family dan semantic mapping; selected states boleh memakai weight/fill terkontrol.
- Asset brand/illustration bukan bagian Phosphor.
- PWA icons diturunkan dari `AppIcon-Default.png` iOS approved.
- Buat variants `any`, `maskable`, Apple touch, dan favicon; maskable diberi safe padding tanpa redesign artwork.
- Jangan menyalin SF Symbols ke web dan jangan membuat icon dengan `div`, CSS border, emoji, atau text glyph.

## Consequences

- Visual icon konsisten dan tree-shakeable.
- Semantic registry memudahkan mengganti glyph tanpa mengubah feature code.
- Perlu audit manual mapping SF Symbols→Phosphor.
- Artwork PWA maskable mungkin tampak sedikit lebih kecil karena safe-zone requirement, tetapi identitas tetap berasal dari App Icon iOS.

