# Phase 02: Design System and Shells

> Status: SELESAI

## Tujuan

Memindahkan visual language iOS menjadi semantic web design system dan tiga
shell responsif tanpa menduplikasi layout per feature.

## Required reading

- Root `UI_REFERENCE_SHEET.md` seluruhnya.
- `../docs/architecture/ROUTES_AND_ROLES.md`.
- iOS SharedUI, AppShell, RootView, dan UI test referensi.

## Di dalam scope

- CSS tokens light/dark, spacing, radius, typography, status, elevation.
- Shared accessible components dan layout primitives.
- Guest/Peserta mobile shell, Coach mobile shell, Admin desktop shell.
- Navigation/history/scroll/focus behavior.
- Placeholder route states memakai fixtures, bukan Supabase real data.
- Manifest metadata/icon placeholder pipeline; full service worker Phase 11.

## Slice 02.1 — Tokens

- [x] Port brand red/black/yellow dan semantic surfaces/status ke CSS custom
  properties untuk light/dark/contrast.
- [x] Port spacing/radius/type hierarchy dan numeric styles.
- [x] Gunakan `color-scheme`, safe-area env, reduced motion, focus ring, dan
  minimum 44px target.
- [x] Tidak ada hard-coded brand hex di feature components.

## Slice 02.2 — Shared UI

- [x] Button/link/icon-button dengan loading/disabled/destructive semantics.
- [x] Card/surface/list row/status badge/metric/progress/empty/error/retry.
- [x] Field, select, checkbox, radio, textarea, inline error, form summary.
- [x] Dialog, bottom sheet/drawer, toast/live region, filter sheet.
- [x] Avatar dengan blank-person fallback; tidak memakai inisial.
- [x] Image/media surface dan skeleton tanpa layout shift.
- [x] Shared program/activity renderer seam untuk Peserta/Coach/Admin preview.

## Slice 02.3 — Shells

- [x] Guest/Peserta bottom navigation: Hari ini, Program, Peringkat, Coach,
  Profil.
- [x] Coach bottom navigation: Dashboard, Program, Profil; quick actions tetap
  destinations, bukan tab duplikat.
- [x] Admin sidebar: Dashboard, Pembayaran, Program, Orang, Konten, Pengaturan.
- [x] Desktop/tablet/mobile breakpoint behavior teruji.
- [x] Browser back/forward, deep link, per-tab scroll restoration, focus on
  route change, and modal history tidak saling merusak.

## Slice 02.4 — State gallery

- [x] Buat internal development-only gallery untuk primitives dan shell.
- [x] Loading, empty, error, populated, dark, large text/zoom, reduced motion.
- [x] Jangan compile role switcher/demo data ke production routes.

## Slice 02.5 — PWA presentation baseline

- [x] Buat manifest name/short name/start URL/display/theme/background/icons
  contract.
- [x] Siapkan icon pipeline dari final brand asset tanpa menyalin iOS-only
  formats secara buta.
- [x] Tambah viewport/safe-area metadata dan standalone CSS behavior.
- [x] Service worker/offline/install prompt lengkap ditunda Phase 11.

## Verification

- [x] Component tests keyboard/focus/ARIA untuk shared primitives.
- [x] Visual screenshot matrix mobile light/dark dan Admin desktop.
- [x] Axe/accessibility smoke tanpa serious/critical issue.
- [x] Zoom 200%, text wrap Bahasa Indonesia, reduced motion, high contrast.
- [x] Chromium dan WebKit navigation smoke.
- [x] Lint, typecheck, focused tests, build lulus.

## Definition of done

- Tiga shell stabil dan tidak berisi business logic/data leak.
- Semantic tokens menjadi satu-satunya source warna/spacing status reusable.
- Admin memanfaatkan desktop dan tetap usable pada mobile.
- Participant/Coach terasa seperti aplikasi mobile tanpa meniru Liquid Glass
  secara palsu.
- Shared renderer seam siap dipakai feature berikutnya.

## Progress log

Catat screenshots/viewport, accessibility checks, files, commands, hasil.

### 10 Agustus 2026 — selesai

- Files changed: token dan style semantik di `src/shared/ui/styles`; primitives di
  `src/shared/ui`; shell, navigation, route behavior, fixture, dan placeholder
  di `src/features/app-shell`; route Peserta/Coach/Admin di `src/app`; gallery
  Vite development-only di `development` dan `src/development`; manifest,
  viewport, ikon PWA, pipeline ikon, dokumentasi baseline, serta test
  unit/component/E2E/gallery.
- Assumptions: gallery kondisi internal sengaja dijalankan melalui
  `pnpm dev:gallery` dan tidak menjadi route Next produksi. Service worker,
  offline cache, install prompt, serta perangkat fisik tetap ditunda ke Phase
  11/13 sesuai scope. Seluruh data layar masih fixture lokal aman.
- Screenshots: Chromium Peserta 390×844 light dan dark; Admin 1440×1000 light
  full-page. Ketiga baseline diperbarui, dibandingkan ulang tanpa update, dan
  diperiksa visual.
- Accessibility: Axe lulus tanpa issue serious/critical untuk fondasi, shell
  Peserta, Coach, Admin, serta gallery. Zoom/text 200%, reduced motion, contrast
  more, wrap Bahasa Indonesia, target 44px, dan horizontal overflow diuji.
- Build command: `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm build`.
  Result: lulus; 21 static pages dihasilkan dan tidak ada route gallery
  development pada output produksi.
- Test commands: `corepack pnpm test` (20/20 lulus),
  `corepack pnpm test:e2e` (19 lulus, 3 visual WebKit dilewati sesuai baseline
  Chromium), `corepack pnpm test:gallery` (2/2 lintas Chromium/WebKit lulus),
  dan focused WebKit scroll restoration `--repeat-each=5` (5/5 lulus).
- Quality commands: `corepack pnpm lint`, `corepack pnpm typecheck`,
  `corepack pnpm format:check`, dan `git diff --check`. Result: lulus tanpa
  warning aplikasi. Warning runner `NO_COLOR`/`FORCE_COLOR` berasal dari
  environment Playwright dan tidak memengaruhi aplikasi.
- Remaining blockers: tidak ada untuk Phase 02. Phase 02A adalah item berikutnya.
