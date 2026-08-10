# Phase 01: Web Foundation

> Status: BELUM DIMULAI

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

- [ ] Verifikasi current Node LTS, Next.js, React, TypeScript, Supabase JS/SSR,
  test runner, Playwright, dan accessibility tooling pada dokumentasi resmi.
- [ ] Scan changelog/security advisories dan pin compatible versions.
- [ ] Catat alasan setiap non-dev dependency.
- [ ] Jangan install QR/PWA/media/state/UI packages pada phase ini.

## Slice 01.1 — Scaffold

- [ ] Buat package metadata, lockfile, Node/package-manager pin.
- [ ] Aktifkan TypeScript strict tanpa blanket suppression.
- [ ] Buat App Router root, global metadata, Bahasa Indonesia, locale config,
  loading/error/not-found baseline.
- [ ] Gunakan system font stack; jangan menyalin SF Symbols/font files.
- [ ] Pastikan production build tidak membutuhkan secret lokal.

## Slice 01.2 — Architecture guardrails

- [ ] Buat folder hanya saat dipakai sesuai target structure.
- [ ] Konfigurasikan alias dan lint import boundary.
- [ ] Tambah file-size checker: review >400 dan fail handwritten >500.
- [ ] Tambah checks untuk forbidden `NEXT_PUBLIC_*` secret names.
- [ ] Tambah rule agar direct Supabase import tidak muncul di feature UI.
- [ ] Buat typed `AppError`, clock, ID generator, Result/state helpers minimal.

## Slice 01.3 — Test harness

- [ ] Unit test sample pure domain.
- [ ] Component render/interaksi sample dengan Indonesian copy.
- [ ] Playwright smoke root pada Chromium dan WebKit project config.
- [ ] Accessibility smoke dan console-error failure policy.
- [ ] Deterministic fixture/clock/ID conventions.

## Slice 01.4 — Supabase seam

- [ ] Ikuti current official SSR guide untuk browser client, server client, dan
  proxy/session refresh.
- [ ] Environment schema menerima URL + publishable key saja untuk client.
- [ ] Server protection menggunakan verified claims/user path yang sesuai
  signing-key configuration; tidak mempercayai unverified session user.
- [ ] Buat repository interfaces dan composition root tanpa business query.
- [ ] Buktikan local unavailable/misconfigured state fail closed.

## Slice 01.5 — Localization/formatting

- [ ] Buat katalog Bahasa Indonesia dan checker key/value.
- [ ] Root menetapkan app locale `id-ID` terlepas browser language.
- [ ] Buat shared `Intl` formatter untuk number, IDR, date/time/timezone,
  percentage, weight, dan monospaced-numeric class.
- [ ] Test browser locale `en-US` tetap menampilkan copy Bahasa Indonesia.

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

