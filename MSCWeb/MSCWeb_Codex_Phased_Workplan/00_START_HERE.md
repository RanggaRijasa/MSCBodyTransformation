# MSC Body Transformation Web/PWA
## Phased Replatforming Workplan

## Status

Workplan dibuat pada 10 Agustus 2026. Phase 00 baseline dan contract freeze
selesai pada tanggal yang sama; implementasi executable web belum dimulai dan
Phase 01 adalah phase berikutnya.

Source iOS sudah mencapai Phase 13.1 dan tetap menjadi behavioral/design
reference. Hosted Supabase `main` sudah memiliki 20 migration, sembilan Edge
Functions, recurring jobs, legal endpoint, serta Google dan Apple provider.
Karena itu migrasi web harus forward-only dan tidak boleh memperlakukan
backend sebagai prototype Phase 12 yang belum pernah dideploy.

Hasil Phase 00:

- `../docs/baseline/PHASE_00_SOURCE_AND_RUNTIME_BASELINE.md`.
- `../docs/baseline/PHASE_00_CONTRACT_RECONCILIATION.md`.
- `../docs/architecture/PHASE_00_PARITY_MATRIX.md`.
- `../docs/architecture/TARGET_MANUAL_COMMERCE_CONTRACT.md`.
- `../docs/architecture/FORWARD_ONLY_MIGRATION_AND_DECOMMISSION.md`.
- `../docs/testing/IOS_TO_WEB_TEST_MAPPING.md`.

## Keputusan produk yang sudah disetujui

- Platform target adalah website/PWA, bukan aplikasi App Store.
- Folder implementasi berada di `MSCWeb/` selama masa konversi.
- Source iOS tidak dikembangkan lebih lanjut untuk release dan tidak dihapus;
  ia menjadi referensi sampai parity web aman.
- Setelah parity/cutover selesai, pengguna akan memindahkan `MSCWeb` ke
  repository baru.
- Fitur produk dipertahankan kecuali Sign in with Apple dan StoreKit.
- Pembayaran menggunakan transfer manual, upload bukti privat, pemeriksaan
  Admin, dan aktivasi server-authoritative.
- Guest/Peserta dan Coach menggunakan mobile app-like UI.
- Admin menggunakan desktop-first responsive UI.
- Supabase tetap backend bersama.

## Rekomendasi teknis

- Next.js App Router dan TypeScript strict.
- pnpm dengan lockfile serta Node active LTS yang dipin saat Phase 01.
- Supabase SSR dengan browser/server client terpisah.
- CSS semantic design tokens; jangan port hard-coded styling per View.
- Unit/component/integration/contract tests dan Playwright E2E.
- PWA manifest serta service worker dengan private-data no-cache policy.
- Cloudflare Workers Paid sebagai hosting production cost-first melalui
  OpenNext; Vercel Pro hanya fallback bila compatibility gate gagal.
- Supabase Pro sebagai backend production.
- Domain `.id` melalui registrar PANDI atau TLD global melalui registrar yang
  dipilih; keputusan final tercatat di Phase 12.

Versi package tidak ditulis permanen di workplan. Verifikasi stable release,
changelog, support matrix, dan security advisory saat scaffold dilakukan.

## Source of truth selama transisi

| Area | Source authoritative |
|---|---|
| Perilaku produk | remediation workplan, contract matrix, test dan source iOS |
| Visual/terminology | iOS `UI_REFERENCE_SHEET.md` |
| Backend schema/RLS/RPC/functions | `../../supabase` |
| API contract | `../../Contracts` |
| Web architecture | `../docs/architecture` |
| Urutan implementasi | folder phase ini |

Jika dokumen status lama menyebut Phase 12 lokal sebagai kondisi terakhir,
gunakan deployment record Phase 13.1 tanggal 9 Agustus 2026 sebagai baseline
operasional yang lebih baru.

## Required reading

Sebelum semua phase:

1. `../AGENTS.md`.
2. `../docs/architecture/ARCHITECTURE.md`.
3. `../docs/architecture/TARGET_FOLDER_STRUCTURE.md`.
4. `../../MSCBodyTransformation/MSC_Codex_Phased_Workplan/UI_REFERENCE_SHEET.md`
   sebelum UI.
5. Tepat satu file phase yang ditugaskan.

Jika menyentuh data, Auth, payment, role, media privat, atau Supabase:

- `../docs/architecture/BACKEND_AND_COMMERCE_MIGRATION.md`.
- `../../MSCBodyTransformation/MSC_Codex_Phased_Workplan/PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md`.
- `../../MSCBodyTransformation/MSC_Codex_Phased_Workplan/PROGRAM_END_TO_END_CONTRACT_MATRIX.md`.
- `../../Documentation/Release/HOSTED_MAIN_DEPLOYMENT_2026-08-09.md`.

## Tracks

### Track A — Kontrak dan fondasi

- Phase 00: baseline, contract freeze, dan keputusan manual commerce.
- Phase 01: scaffold, tooling, boundaries, dan test harness.
- Phase 02: design system, shells, dan PWA presentation baseline.
- Phase 02A: public landing page dan install CTA adaptif.

### Track B — Vertical slices produk

- Phase 03: Guest, Auth, onboarding, dan profile lifecycle setelah landing.
- Phase 04: browser media, image, camera, QR, dan video foundation.
- Phase 05: program catalog, QR preflight, enrollment, dan payment intent.
- Phase 06: manual payment, bukti transfer, dan Admin verification.
- Phase 07: pengalaman program Peserta lengkap.
- Phase 08: pengalaman Coach lengkap.
- Phase 09: Admin dashboard, CMS, people, content, dan privileged operations.
- Phase 10: scoring, leaderboard, closure, winner, dan parity end-to-end.

### Track C — Production readiness dan cutover

- Phase 11: PWA install/offline/update, accessibility, performance, security,
  dan reliability.
- Phase 12: hosting, domain, environments, OAuth production, dan deployment.
- Phase 13: parity UAT, decommission bertahap, ownership transfer, dan cutover.

## Phase discipline

- Kerjakan phase berurutan dan satu phase per task.
- Pilih vertical slice terkecil, implementasikan production code serta test,
  lalu build sebelum slice berikutnya.
- Jangan menyalin file Swift besar menjadi satu file TypeScript besar.
- Jangan membuat mutation hosted hanya karena local tests lulus.
- Checkbox baru dicentang setelah command verifikasi dicatat.
- Semua perbedaan iOS/web harus menjadi keputusan adaptasi eksplisit.
- Perubahan frontend landing setelah Phase 11 wajib memakai regression gate di
  `12_PHASE_11_PWA_QUALITY_SECURITY_AND_RELIABILITY.md`; evidence visual,
  accessibility, PWA, privacy, performance, dan build harus diperbarui sesuai
  luas perubahan sebelum Phase 12.
- Phase 13 tidak menghapus source lama secara otomatis; archive/pemindahan repo
  adalah manual gate pengguna.

## Command baseline setelah Phase 01

Nama script final ditetapkan Phase 01, minimal:

```text
pnpm lint
pnpm typecheck
pnpm test
pnpm test:integration
pnpm test:e2e
pnpm build
```

Supabase lokal tetap memakai runbook root dan command CLI yang diverifikasi
melalui `--help` pada hari eksekusi.

## Definition of done keseluruhan

Konversi selesai bila:

- seluruh capability pada parity matrix memiliki implementasi web;
- Guest/Peserta, Coach, dan Admin journeys lulus terhadap backend production-
  equivalent;
- manual payment mengaktifkan enrollment/Coach secara atomik dan teraudit;
- tidak ada akses StoreKit atau Sign in with Apple dalam runtime web;
- private media/payment/weight tidak bocor ke cache, public route, log, atau
  role yang salah;
- Safari iPhone, installed PWA, Chrome Android, dan desktop browser lulus;
- accessibility, performance, PWA update, offline, session, dan security gates
  lulus;
- domain, OAuth callback, backups, monitoring, spend controls, dan rollback
  production siap;
- inventory membuktikan `MSCWeb` dapat dipindahkan menjadi repository
  self-contained tanpa dua source backend aktif;
- pengguna menyetujui cutover dan pemindahan repository.
