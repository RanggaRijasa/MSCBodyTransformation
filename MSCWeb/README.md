# MSC Body Transformation Web/PWA

Folder ini adalah jalur replatforming MSC Body Transformation dari aplikasi
native iOS menjadi web app/PWA. Source iOS tetap dipertahankan sebagai
referensi perilaku, desain, dan acceptance test sampai parity web dinyatakan
lulus.

## Status

- Phase 00 baseline dan contract freeze: selesai 10 Agustus 2026.
- Phase 01 web foundation: selesai 10 Agustus 2026; seluruh local gate lulus.
- Phase 02 design system dan shells: selesai 10 Agustus 2026; seluruh local
  gate lulus.
- Phase 02A public landing dan install CTA: selesai 10 Agustus 2026; seluruh
  gate lokal lulus, dengan device/service-worker gate diteruskan ke Phase 11.
- Phase 03 Guest, Auth, dan onboarding: selesai lokal 10 Agustus 2026; hosted
  Google/domain tetap gate Phase 12 dan scanner QR produksi masuk Phase 04.
- Phase 04 browser media, QR, dan video: selesai lokal 10 Agustus 2026; device
  fisik dan release-candidate performance tetap gate Phase 11/13.
- Phase 05–10 selesai lokal; seluruh local gate sampai scoring, leaderboard,
  closure, winner, dan cross-role journey telah lulus.
- Implementasi web: scaffold Next.js/TypeScript dan test harness tersedia.
- Source iOS: tidak diubah oleh pembuatan workplan ini.
- Backend authoritative selama transisi: `../supabase`.
- Kontrak authoritative selama transisi: `../Contracts`.
- Target akhir: `MSCWeb` menjadi self-contained sebelum dipindahkan ke
  repository baru.

## Mulai dari sini

1. Baca `MSCWeb_Codex_Phased_Workplan/00_START_HERE.md`.
2. Baca `AGENTS.md`.
3. Baca seluruh dokumen dalam `docs/architecture` yang diwajibkan phase.
4. Untuk keputusan manual payment, baca
   `docs/decisions/PHASE_00_MANUAL_COMMERCE_DECISIONS.md`.
5. Untuk hasil audit Phase 00, baca
   `docs/baseline/PHASE_00_SOURCE_AND_RUNTIME_BASELINE.md`,
   `docs/architecture/PHASE_00_PARITY_MATRIX.md`, dan
   `docs/architecture/TARGET_MANUAL_COMMERCE_CONTRACT.md`.
6. Untuk landing page, baca
   `docs/design/LANDING_PAGE_DESIGN_AND_CONTENT.md` dan mockup v2.
7. Kerjakan tepat satu phase dari
   `MSCWeb_Codex_Phased_Workplan/MANIFEST.md`.

Phase 01 boleh membuat scaffold sesuai workplan, tetapi codegen dari
`CoachApplication` OpenAPI lama tetap diblokir oleh contract reconciliation.
Jangan menghapus StoreKit, Apple identity, source Swift, migration, atau test
iOS hanya karena adapter tersebut tidak dipakai oleh PWA.
