# MSC Body Transformation Web/PWA

Folder ini adalah jalur replatforming MSC Body Transformation dari aplikasi
native iOS menjadi web app/PWA. Source iOS tetap dipertahankan sebagai
referensi perilaku, desain, dan acceptance test sampai parity web dinyatakan
lulus.

## Status

- Phase 00 baseline dan contract freeze: selesai 10 Agustus 2026.
- Workplan dan arsitektur: tersedia; Phase 01 menjadi langkah berikutnya.
- Implementasi web: belum dimulai.
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
