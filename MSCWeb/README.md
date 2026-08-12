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
- Phase 11 PWA quality, security, dan reliability selesai lokal 11 Agustus
  2026; install/update/offline, Push MVP, accessibility, performance,
  hardening, SBOM, runbook, dan release screenshot telah lulus seluruh gate
  otomatis. Checklist HP/laptop disiapkan untuk owner sesuai penundaan manual
  yang disetujui; konfigurasi production tetap Phase 12.
- Phase 11A total UI redesign: selesai lokal 12 Agustus 2026. Tailwind CSS dan
  primitive shadcn yang dipilih, landing, Guest/Auth, Peserta, Coach, Admin,
  captured representative Chromium/WebKit matrix, gallery, serta regression
  fungsional Phase 03–11 lulus. Hanya baris parity dengan evidence yang
  berstatus `Accepted`; state visual lain tetap `Open`. Checklist perangkat
  fisik ditunda owner dan tetap wajib sebelum production cutover;
  konfigurasi/deployment production tetap Phase 12.
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
   `docs/design/LANDING_PAGE_DESIGN_AND_CONTENT.md` dan concept yang disetujui.
7. Kerjakan tepat satu phase dari
   `MSCWeb_Codex_Phased_Workplan/MANIFEST.md`.
8. Untuk evidence Phase 11, baca `docs/progress/PHASE_11_DOD_AUDIT.md` dan
   `docs/testing/PHASE_11_BROWSER_DEVICE_EVIDENCE.md`.
9. Untuk redesign, baca Phase 11A dan ketiga companion design, testing, serta
   multi-agent execution document sebelum mengubah frontend.

Phase 01 boleh membuat scaffold sesuai workplan, tetapi codegen dari
`CoachApplication` OpenAPI lama tetap diblokir oleh contract reconciliation.
Jangan menghapus StoreKit, Apple identity, source Swift, migration, atau test
iOS hanya karena adapter tersebut tidak dipakai oleh PWA.

## Simulator role untuk development

Jalankan simulator aplikasi yang tidak memerlukan login atau Supabase:

```bash
PATH=/opt/homebrew/opt/node@24/bin:$PATH corepack pnpm dev:roles
```

Lalu buka `http://127.0.0.1:4174/`, pilih Guest, Peserta, Coach, atau Admin,
dan gunakan navigasi aplikasi seperti pada perjalanan production. URL di dalam
simulator tetap mengikuti route canonical seperti `/hari-ini`, `/coach-area`,
dan `/admin`.

Simulator memakai fixture lokal aman dan komponen production, tetapi aksi
server sensitif ditahan dan diganti state development lokal. Simulator tidak
menjadi route Next production dan tidak membuat bypass autentikasi.

Galeri komponen internal tetap tersedia secara terpisah:

```bash
PATH=/opt/homebrew/opt/node@24/bin:$PATH corepack pnpm dev:gallery
```

Galeri komponen menggunakan `http://127.0.0.1:4173/`; simulator role memakai
port `4174`, sehingga keduanya dapat dijalankan bersamaan.
