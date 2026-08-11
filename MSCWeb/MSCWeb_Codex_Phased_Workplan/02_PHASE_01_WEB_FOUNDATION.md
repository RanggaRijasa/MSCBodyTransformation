# Phase 01: Web Foundation

> Status: SELESAI

## Tujuan

Membuat scaffold Next.js/TypeScript minimal yang buildable, modular, dapat
diuji, dan belum mengimplementasikan fitur produk kompleks.

## Prasyarat

- Phase 00 selesai dan target contract stabil.
- Dependency baseline disetujui.
- Tidak ada hosted mutation.

## Di dalam scope

- Next.js App Router, TypeScript strict, pnpm, Node active LTS pinned.
- ESLint, formatter policy, file-size check, import boundaries.
- Unit/component/Playwright test harness.
- Environment validation tanpa secret production.
- Supabase local browser/server seam dengan fake/local composition.
- Error, clock, ID, repository, localization, dan config boundaries.
- CI command contract, tetapi tidak membuat external CI/PR tanpa izin.

## Dependency gate

- [x] Verifikasi current Node LTS, Next.js, React, TypeScript, Supabase JS/SSR,
  test runner, Playwright, dan accessibility tooling pada dokumentasi resmi.
- [x] Scan changelog/security advisories dan pin compatible versions.
- [x] Catat alasan setiap non-dev dependency.
- [x] Jangan install QR/PWA/media/state/UI packages pada phase ini.

## Slice 01.1 — Scaffold

- [x] Buat package metadata, lockfile, Node/package-manager pin.
- [x] Aktifkan TypeScript strict tanpa blanket suppression.
- [x] Buat App Router root, global metadata, Bahasa Indonesia, locale config,
  loading/error/not-found baseline.
- [x] Gunakan system font stack; jangan menyalin SF Symbols/font files.
- [x] Pastikan production build tidak membutuhkan secret lokal.

## Slice 01.2 — Architecture guardrails

- [x] Buat folder hanya saat dipakai sesuai target structure.
- [x] Konfigurasikan alias dan lint import boundary.
- [x] Tambah file-size checker: review >400 dan fail handwritten >500.
- [x] Tambah checks untuk forbidden `NEXT_PUBLIC_*` secret names.
- [x] Tambah rule agar direct Supabase import tidak muncul di feature UI.
- [x] Buat typed `AppError`, clock, ID generator, Result/state helpers minimal.

## Slice 01.3 — Test harness

- [x] Unit test sample pure domain.
- [x] Component render/interaksi sample dengan Indonesian copy.
- [x] Playwright smoke root pada Chromium dan WebKit project config.
- [x] Accessibility smoke dan console-error failure policy.
- [x] Deterministic fixture/clock/ID conventions.

## Slice 01.4 — Supabase seam

- [x] Ikuti current official SSR guide untuk browser client, server client, dan
  proxy/session refresh.
- [x] Environment schema menerima URL + publishable key saja untuk client.
- [x] Server protection menggunakan verified claims/user path yang sesuai
  signing-key configuration; tidak mempercayai unverified session user.
- [x] Buat repository interfaces dan composition root tanpa business query.
- [x] Buktikan local unavailable/misconfigured state fail closed.

## Slice 01.5 — Localization/formatting

- [x] Buat katalog Bahasa Indonesia dan checker key/value.
- [x] Root menetapkan app locale `id-ID` terlepas browser language.
- [x] Buat shared `Intl` formatter untuk number, IDR, date/time/timezone,
  percentage, weight, dan monospaced-numeric class.
- [x] Test browser locale `en-US` tetap menampilkan copy Bahasa Indonesia.

## Commands minimum

```text
pnpm lint
pnpm typecheck
pnpm test
pnpm test:e2e --project=chromium --grep smoke
pnpm test:e2e --project=webkit --grep smoke
pnpm build
```

## Definition of done

- Clean install dan build reproducible dari lockfile.
- Tidak ada secret, hosted URL hard-coded, atau direct production mutation.
- Architecture/file-size/import/localization checks aktif.
- Supabase seam mengikuti dokumentasi current dan fail closed.
- Smoke unit/component/E2E/build lulus.
- Tidak ada file handwritten melewati limit.

## Progress log

Catat versions, dependencies, files, commands, hasil, warning, dan blocker.

### 10 Agustus 2026 — Phase 01 selesai

- Files changed: package/toolchain config dan lockfile; App Router root states;
  domain/core boundaries; Supabase browser/server/proxy seam; repository
  composition; localization/formatters; architecture, secret, localization,
  dan file-size checks; unit/component/E2E tests; dependency baseline.
- Versions: Node 24.19.0, pnpm 11.21.0, Next.js 16.3.0, React 19.2.8,
  TypeScript 6.0.3, Supabase JS 2.112.2, Supabase SSR 0.12.4, Vitest
  4.1.10, Playwright 1.62.1, axe-core 4.12.1.
- Assumptions: Phase 01 hanya membangun seam; tidak menjalankan business query,
  mutation hosted, OAuth, media/QR, PWA, atau package UI/state tambahan.
- Dependency result: audit awal Next.js 16.2.11 menemukan advisory transitif
  `sharp`/`postcss`; upgrade ke Next.js 16.3.0 menghasilkan `pnpm audit` tanpa
  known vulnerability. Clean `--frozen-lockfile` install lulus dari direktori
  sementara dengan 451 package.
- Build command: `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm build`.
  Result: lulus, static route `/` dan `/_not-found`, Proxy terdeteksi.
- Test commands: `corepack pnpm lint`, `corepack pnpm typecheck`,
  `corepack pnpm test`, `corepack pnpm test:e2e --project=chromium --grep smoke`,
  `corepack pnpm test:e2e --project=webkit --grep smoke`, dan
  `corepack pnpm verify`, seluruhnya dengan Node 24 explicit PATH.
- Test result: lint/architecture/file-size/secret/localization bersih;
  typecheck lulus; 13 test unit/component lulus; Chromium 2/2 dan WebKit 2/2
  smoke lulus termasuk axe dan console-error policy; production build lulus.
- Warning: Playwright menampilkan warning runner `NO_COLOR`/`FORCE_COLOR`;
  tidak berasal dari browser console atau source aplikasi dan tidak memblokir.
- Blocker: tidak ada. Hosted Supabase dan deployment tetap tidak disentuh.
- Next unchecked item: Phase 02 Slice 02.1, fondasi design token dan shell.
