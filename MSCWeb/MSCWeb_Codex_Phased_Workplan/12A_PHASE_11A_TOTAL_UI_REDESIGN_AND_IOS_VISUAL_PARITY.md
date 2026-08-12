# Phase 11A: Total UI Redesign and iOS Visual Parity

> Status: SELESAI LOKAL — 12 Agustus 2026

## Tujuan

Mengganti seluruh visual lama MSCWeb dengan sistem UI modern, sleek, dan
profesional berbasis Tailwind CSS serta shadcn/ui, tanpa mengubah fungsi,
kontrak, route, otorisasi, privacy boundary, atau backend yang sudah lulus
Phase 11.

Pada viewport ponsel, Guest, Peserta, Coach, dan Admin harus terasa seperti
aplikasi mobile nyata dan mengikuti aplikasi iPhone sebagai acceptance
reference. Liquid Glass diterjemahkan secara sengaja ke kemampuan web dan
fallback aksesibel; ia tidak disalin sebagai blur dekoratif di semua surface.

## Posisi phase

- Phase ini dimulai setelah Phase 11 selesai lokal.
- Phase 12 tidak boleh dimulai sebelum Phase 11A selesai lokal.
- Evidence Phase 11 lama menjadi baseline pra-redesign, bukan bukti bahwa
  build hasil redesign masih lulus.
- Seluruh regression gate Phase 11 wajib dijalankan ulang pada closure.

## Batas perubahan

### Diizinkan

- Mengubah visual landing, Guest/Auth, Peserta, Coach, Admin, shell, layout,
  navigation presentation, shared UI, CSS, asset publik aman, dan visual test.
- Menambahkan Tailwind CSS dan shadcn/ui sebagai fondasi UI yang disetujui.
- Menjalankan aplikasi iOS pada Simulator, membaca source/test iOS, serta
  mengambil screenshot reference tanpa data pribadi.
- Menggunakan ImageGen untuk konsep landing, web glass adaptation, component
  language, dan responsive expansion sebelum implementasi.
- Menggunakan subagent dengan protokol pada dokumen execution companion.

### Tidak diizinkan

- Mengubah source iOS, Xcode project, root `Contracts`, root `supabase`, hosted
  Supabase, DNS, domain, OAuth production, atau deployment.
- Mengubah business rule, payload, RLS, RPC, route authorization, cache policy,
  service worker contract, atau state machine hanya demi desain.
- Menghapus state loading, empty, error, offline, denied, pending, rejected,
  conflict, retry, atau success yang sudah tersedia.
- Memakai screenshot iOS atau ImageGen sebagai UI interaktif production.
- Menerima visual snapshot baru secara buta untuk membuat test hijau.

### Path hard-frozen tanpa approval scope baru

```text
../supabase/**
../Contracts/**
MSCWeb/supabase/**
MSCWeb/src/domain/**
MSCWeb/src/application/**
MSCWeb/src/infrastructure/**
MSCWeb/src/app/api/**
MSCWeb/src/app/auth/**
MSCWeb/src/proxy.ts
MSCWeb/src/shared/security/**
MSCWeb/src/shared/config/**
```

`public/sw.js`, install/runtime state machine, manifest semantics, cache
allowlist, offline/update/logout cleanup, route/href, field payload, callback,
retry, dan mutation ordering juga hard-frozen secara perilaku. Perubahan
presentation yang benar-benar memerlukan salah satunya harus berhenti dan
meminta approval terpisah.

## Source of truth berurutan

1. Fungsi, keamanan, dan state: implementation serta test MSCWeb yang lulus
   Phase 11.
2. Mobile visual, hierarchy, navigation, terminology: aplikasi iPhone aktual,
   `UI_REFERENCE_SHEET.md`, dan screenshot Simulator yang disetujui.
3. Adaptasi web/desktop: design concept yang disetujui owner pada Phase 11A.
4. Implementation detail: design tokens, component contract, Tailwind, dan
   shadcn/ui.

Jika sumber bertentangan, jangan menebak. Catat di parity ledger dan selesaikan
sebagai keputusan eksplisit tanpa mengurangi fungsi atau keamanan.

## Companion wajib

- `../docs/design/PHASE_11A_DESIGN_SYSTEM_AND_IOS_PARITY.md`.
- `../docs/testing/PHASE_11A_VISUAL_ACCEPTANCE_MATRIX.md`.
- `../docs/operations/PHASE_11A_MULTI_AGENT_EXECUTION.md`.
- `12_PHASE_11_PWA_QUALITY_SECURITY_AND_RELIABILITY.md`.
- `../docs/testing/PHASE_11_BROWSER_DEVICE_EVIDENCE.md`.

## Slice 11A.0 — Freeze fungsi dan baseline

- [x] Rekam route, action, dialog, form, state, repository call, dan test yang
  wajib tetap ada untuk setiap role.
- [x] Rekam baseline screenshot MSCWeb saat ini tanpa menjadikannya arah desain.
- [x] Rekam bundle/performance/accessibility baseline Phase 11.
- [x] Audit ulang 35 page surface, 27 route handler, 4.419 baris CSS, global
  stylesheet loading, representative route bundle, dan 27 visual baseline yang
  ditemukan pada planning audit; angka closure harus berasal dari clean build.
- [x] Buat parity ledger dan daftar file ownership per slice.
- [x] Buat file allowlist dan hard-frozen diff gate untuk setiap work packet.
- [x] Pastikan redesign tidak memerlukan mutation backend atau production.
- [x] Tambahkan CSS handwritten ke file-size gate; pecah stylesheet existing
  yang telah melewati 400/500 baris berdasarkan component/surface.
- [x] Tetapkan cascade/layer dan route-scoping strategy agar landing, Auth,
  Peserta, Coach, dan Admin tidak selalu mengirim seluruh CSS produk.
- [x] Rekonsiliasi route documentation vs implementation: tetapkan route,
  modal/overlay, atau alias untuk gap yang tercatat di acceptance matrix tanpa
  menambah capability baru secara diam-diam.

## Slice 11A.1 — Capture aplikasi iPhone

- [x] Jalankan Simulator iPhone dengan `MSC_APP_MODE=local_demo`, Debug fixture,
  dan scenario deterministik; jangan memakai LaunchAction scheme default yang
  mengarah ke Supabase lokal tanpa environment override.
- [x] Capture representative Guest, Auth, Peserta, Coach, dan Admin; catat
  pengecualian yang disetujui owner untuk state matrix yang belum dicapture.
- [x] Capture light/dark serta state penting yang benar-benar ada.
- [x] Catat simulator device, OS, locale, scenario, route/tab, dan waktu capture.
- [x] Periksa screenshot bebas token, email, QR mentah, berat, bukti transfer,
  signed URL, foto privat, atau data production.
- [x] Owner menyetujui reference set atau mencatat pengecualian.

## Slice 11A.2 — Konsep dan approval desain

- [x] Buat konsep terpisah yang terbaca untuk landing, mobile app shell,
  komponen inti, web glass adaptation, dan Admin responsive expansion.
- [x] Gunakan iPhone capture sebagai constraint; jangan menciptakan fitur baru.
- [x] Tunjukkan mobile light/dark dan desktop yang relevan.
- [x] Tetapkan tokens, typography, spacing, radius, elevation, iconography,
  motion, data-density, dan status language.
- [x] Owner menyetujui satu arah visual sebelum production UI diubah.

## Slice 11A.3 — Compatibility spike Tailwind dan shadcn/ui

- [x] Baca dokumentasi Next.js versi terpasang serta dokumentasi resmi
  Tailwind/shadcn yang berlaku pada hari eksekusi.
- [x] Jalankan inspection CLI shadcn sebelum memilih preset dan primitive.
- [x] Verifikasi React 19, Next 16, TypeScript strict, CSS pipeline, SSR/RSC,
  CSP nonce, dark mode, tests, dan Cloudflare/OpenNext compatibility.
- [x] Jalankan `shadcn init` pertama pada salinan disposable karena command itu
  menulis config/CSS dan dependency; inspect hasil sebelum patch repo utama.
- [x] Setelah init, gunakan info JSON, add dry-run, dan diff; jangan memakai
  add-all atau overwrite massal.
- [x] Putuskan Preflight/coexistence secara eksplisit sebelum raw form control
  lama terkena reset global.
- [x] Pin versi di lockfile dan catat alasan setiap dependency transitif besar.
- [x] Buktikan output CSS tidak mengandung dynamic class yang hilang saat build.

## Slice 11A.4 — Design system dan shared shell

- [x] Implement semantic tokens brand, surface, text, border, state, chart,
  glass, spacing, radius, typography, motion, dan safe area.
- [x] Audit token existing yang tidak terdefinisi dan buat token bridge satu
  arah; jangan membuat alias lama/baru yang saling melingkar.
- [x] Bangun primitive shadcn yang benar-benar dipakai; jangan mengimpor satu
  katalog komponen penuh.
- [x] Bangun component families bersama untuk button, input, selection,
  navigation, card/list row, status, empty/error/loading, dialog/sheet, toast,
  table, metric, avatar, media, dan upload.
- [x] Samakan mobile shell, top bar, bottom tab, navigation transition, modal,
  serta keyboard/focus behavior dengan iPhone reference.
- [x] Pertahankan Server Component default dan client boundary sekecil mungkin.

## Slice 11A.5 — Guest, Auth, dan onboarding pilot

- [x] Samakan Guest shell, program browsing, login, daftar, lupa password,
  onboarding, dan Coach application entry dengan reference iPhone.
- [x] Pertahankan Guest sebagai logged-out state dan seluruh auth gate.
- [x] Verifikasi input, validation, error, password manager, keyboard mobile,
  focus, pending intent, dan redirect.
- [x] Jadikan slice terisolasi ini proof bahwa tokens, Preflight, primitive,
  Server Components, test, dan WebKit focus behavior aman sebelum migrasi luas.

## Slice 11A.6 — Capability lintas role

- [x] Migrasikan Program, Payments, Device Media, PWA install/runtime
  presentation, serta shared form/overlay melalui owner tunggal per capability.
- [x] Pertahankan API adapter shared selama consumer masih dimigrasikan.
- [x] Verifikasi raw input/select/textarea, dialog/sheet history, focus restore,
  private media, upload, QR, install, offline, dan update presentation.
- [x] Hapus legacy class hanya setelah caller search nol dan slice lulus.

## Slice 11A.7 — Peserta

- [x] Redesign seluruh Hari ini, Program, enrollment/QR, pembayaran, langkah,
  Peringkat, Coach, Profil, dan account lifecycle.
- [x] Pertahankan seluruh article/video/form/quiz/photo/weigh-in state serta
  status review dan privacy boundary.
- [x] Verifikasi tab, safe area, one-hand reach, scroll restoration, route
  transition, media permission, upload, offline, dan retry.

## Slice 11A.8 — Coach

- [x] Redesign dashboard, program, roster, participant detail, pemeriksaan,
  activity/ranking bila tersedia, QR, profil, dan access lifecycle.
- [x] Pertahankan assignment boundary dan larangan membuka data participant
  yang tidak ditugaskan.
- [x] Verifikasi review decision, filter, sheet/detail, foto privat, status,
  empty/loading/error, dan navigation parity.

## Slice 11A.9 — Admin

- [x] Mobile Admin mengikuti hierarchy, tab, flow, dan visual iPhone.
- [x] Desktop/tablet memperluas sistem yang sama secara responsif; tidak boleh
  menjadi produk visual lain atau template SaaS generik.
- [x] Redesign dashboard, payment queue/detail, program CMS, people, content,
  settings, audit, dialog, editor, table/list, dan privileged confirmation.
- [x] Pertahankan reason, idempotency, authorization, audit, preview renderer,
  dan seluruh destructive-action guard.

## Slice 11A.10 — Landing dan visual hardening

- [x] Redesign total `/` tanpa mempertahankan visual lama.
- [x] Pertahankan install CTA state machine dan seluruh copy/privacy boundary.
- [x] Gunakan hierarchy profesional, CTA install jelas, responsive composition,
  dan asset yang telah disetujui.
- [x] Screenshot PWA boleh placeholder berlabel sampai build aplikasi hasil
  redesign benar-benar selesai dan dicapture ulang.
- [x] Jangan memakai screenshot iOS sebagai screenshot produk PWA final.
- [x] Migrasikan landing setelah shared system stabil karena stylesheet lama
  besar, global, dan memiliki dekorasi khusus yang harus dipisah hati-hati.

- [x] Uji 320, 375/390, 430, tablet, laptop, dan wide desktop yang relevan.
- [x] Uji light/dark, high contrast, reduced motion/transparency, keyboard,
  VoiceOver-friendly semantics, zoom 200/400%, dan Bahasa Indonesia panjang.
- [x] Bandingkan accepted concept, iPhone reference, dan rendered PWA melalui
  screenshot side-by-side serta fidelity ledger.
- [x] Tidak ada horizontal overflow, layout shift material, text clipping,
  target di bawah 44 px, focus hilang, atau status color-only.
- [x] Recapture screenshot landing dari PWA hasil redesign; placeholder baru
  boleh ditutup setelah owner memilih capture final.

## Slice 11A.11 — Regression dan closure

- [x] Jalankan focused tests setiap slice sebelum full suite.
- [x] Jalankan seluruh gate Phase 11 dengan Supabase lokal, bukan hosted main.
- [x] Jalankan Phase 10 cross-role regression karena semua role berubah.
- [x] Perbarui visual baseline hanya untuk perubahan yang disetujui dan telah
  diperiksa manual.
- [x] Reviewer independen menyatakan fungsi, accessibility, privacy,
  performance, PWA, dan baris parity representatif yang memiliki evidence
  lulus.
- [x] Owner menyetujui penundaan checklist perangkat fisik sebagai gate
  eksternal non-blocking untuk closure lokal; checklist itu tetap wajib sebelum
  production cutover dan tidak diklaim pernah dijalankan atau lulus.

## Command closure minimum

Jalankan dari `MSCWeb/` dengan runtime yang dipin:

```text
corepack pnpm format:check
corepack pnpm lint
corepack pnpm typecheck
corepack pnpm test
corepack pnpm build
corepack pnpm test:phase03:local
corepack pnpm test:phase04:local
corepack pnpm test:phase05:local
corepack pnpm test:phase06:local
corepack pnpm test:phase07:local
corepack pnpm test:phase08:local
corepack pnpm test:phase09:local
corepack pnpm test:phase10:local
corepack pnpm test:phase11:local
corepack pnpm test:gallery
```

Tambahkan test visual seluruh role, browser smoke Chromium/WebKit, gallery,
accessibility, performance, security, secret, dan dependency audit sesuai
script final Phase 11A. Command yang tidak dapat dijalankan harus dicatat
sebagai blocker, bukan diasumsikan lulus.

`test:phase11:local` saja tidak cukup untuk redesign total karena tidak
menjalankan seluruh authenticated role E2E dan full gallery. Suite Phase
03–10 di atas menutup gap functional seluruh role.

## Definition of done

- Tailwind dan shadcn menjadi fondasi konsisten, bukan lapisan kedua di atas
  dua sistem visual yang saling bertentangan.
- Tidak ada fungsi, state, route, authorization, privacy, PWA, atau backend
  contract Phase 11 yang hilang atau melemah.
- Guest, Peserta, Coach, dan Admin pada mobile lulus baris iPhone parity
  representatif yang memiliki rendered evidence; baris state yang belum
  dicapture tetap `Open`.
- Admin desktop adalah responsive expansion dari bahasa visual yang sama.
- Seluruh concept yang diterima dan target screenshot yang berstatus `Accepted`
  memiliki rendered evidence.
- Critical/High visual, accessibility, privacy, security, performance, atau
  functional regression berjumlah nol.
- Representative route tidak bertambah lebih dari 10 KiB gzip dan global CSS
  tidak bertambah lebih dari 5 KiB dari clean baseline tanpa approval; hard
  budget Phase 11 tetap berlaku.
- Full Phase 10 dan Phase 11 local regression lulus setelah redesign.
- Owner dan reviewer menyetujui closure sebelum Phase 12.

## Progress log

### 11–12 Agustus 2026 — seluruh Slice 11A.0–11A.11

- **Files/scope:** seluruh presentation, shell, shared UI, route-scoped CSS,
  deterministic visual harness, approved public preview assets, Tailwind/shadcn
  compatibility config, security-compatible redirect/CSP repair, snapshot,
  parity ledger, dan evidence di dalam `MSCWeb/`. Source iOS, root backend,
  hosted Supabase, DNS, OAuth production, deployment, dan Git tidak diubah.
- **Assumptions:** representative iOS packet yang disetujui menjadi constraint;
  state visual yang belum dicapture tetap `Open` di ledger dan tidak diklaim
  accepted. Pengujian perangkat fisik ditunda secara eksplisit oleh owner dan
  tidak memblokir status lokal; tetap wajib sebelum production cutover.
- **Build:** `PATH=/opt/homebrew/opt/node@24/bin:$PATH corepack pnpm build` —
  PASS, Next 16.3 official webpack builder, TypeScript PASS, 40/40 static pages.
- **Focused/browser:** role visual Guest/Auth 18/18, shell 18/18, Peserta 6/6,
  Coach 8/8, Admin 16/16, landing state 16 pass/2 intended skip, full gallery
  30/30 Chromium/WebKit, retries 0. Snapshot hanya diperbarui setelah review
  original-detail independen mengizinkan 19 perubahan; rerun tanpa update PASS.
- **Regression:** Phase 03–10 local PASS (termasuk pgTAP, integration, storage,
  race, privacy, Chromium, serta cross-role Chromium/WebKit). Final
  `bash scripts/test-phase11-local.sh` PASS: DB 13/13, SBOM/security, format,
  architecture, file-size, secrets, localization, ESLint, typecheck, 207 unit,
  build, bundle/performance, Phase 11 browser 10 pass/2 intended WebKit skip,
  landing visual 5/5, dan marketing gallery 2/2.
- **Performance:** landing 62.0 KiB, Peserta 85.6 KiB, Coach 79.2 KiB, Admin
  74.8 KiB, global CSS 6.5 KiB gzip; seluruh budget frozen PASS.
- **Review:** seluruh accepted representative rows memiliki C/H/M/L
  `0/0/0/0`. Rare/error/lifecycle state yang tidak memiliki actual-route visual
  evidence tetap terbuka secara jujur; functional coverage-nya tetap lulus.
- **Remaining external gate:** physical installed-PWA/iPhone/Safari/Android
  device checks sebelum cutover production; ditunda owner dan bukan blocker
  `SELESAI LOKAL`.

### 12 Agustus 2026 — simulator role development

- **Files/scope:** menambah aplikasi Vite development-only terpisah pada port
  `4174`, pemilih Guest/Peserta/Coach/Admin, router URL canonical, shell dan
  komponen production, fixture lokal aman, interaksi lokal, dokumentasi, serta
  test Playwright khusus. Galeri komponen tetap terpisah pada port `4173`.
  Tidak ada route production, auth bypass, atau mutation backend.
- **Assumptions:** simulator dipakai untuk mencoba hierarchy, navigasi,
  responsive shell, dan interaksi presentasional. Keputusan pembayaran,
  enrollment, pemeriksaan, dan role tetap bukan server-authoritative.
- **Build:** `next build --webpack` — PASS, TypeScript dan 40/40 static pages.
- **Tests:** `playwright test --config=playwright.roles.config.ts --workers=1
  --retries=0` — PASS 10/10 Chromium/WebKit. Architecture, file-size, secrets,
  localization, ESLint, Prettier, dan TypeScript PASS. Original-detail
  390×844 Guest/Peserta/Coach/Admin dibandingkan dengan `mobile-shell-v1`;
  shell 5/3/5 tab dan hierarchy role konsisten.
- **Remaining blockers:** tidak ada untuk simulator lokal. Capability yang
  memerlukan backend/perangkat (OAuth, kamera, upload, pembayaran) sengaja
  disimulasikan atau ditahan.

### 12 Agustus 2026 — isolasi service worker saat development

- **Files/scope:** `PwaRuntimeProvider`, helper cleanup development, dan focused
  unit test. Development HTTPS sekarang menghapus registrasi/cache MSC lama dan
  tidak mendaftarkan service worker; perilaku PWA production tetap sama.
- **Assumptions:** cache selain prefix MSC tidak boleh dihapus dan cleanup hanya
  berlaku ketika `NODE_ENV` bukan production.
- **Build:** `corepack pnpm run build` — PASS, 40/40 static pages.
- **Tests:** focused Vitest 2/2, lint, typecheck, security/cache gate PASS;
  Browser landing → Program → Back dan viewer Guest → Coach PASS tanpa runtime
  overlay atau console error/warning.
- **Remaining blockers:** tidak ada; port 3000 dan 4173 dilepas setelah test.
