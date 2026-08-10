# Phase 02: Design System and Shells

> Status: BELUM DIMULAI

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

- [ ] Port brand red/black/yellow dan semantic surfaces/status ke CSS custom
  properties untuk light/dark/contrast.
- [ ] Port spacing/radius/type hierarchy dan numeric styles.
- [ ] Gunakan `color-scheme`, safe-area env, reduced motion, focus ring, dan
  minimum 44px target.
- [ ] Tidak ada hard-coded brand hex di feature components.

## Slice 02.2 — Shared UI

- [ ] Button/link/icon-button dengan loading/disabled/destructive semantics.
- [ ] Card/surface/list row/status badge/metric/progress/empty/error/retry.
- [ ] Field, select, checkbox, radio, textarea, inline error, form summary.
- [ ] Dialog, bottom sheet/drawer, toast/live region, filter sheet.
- [ ] Avatar dengan blank-person fallback; tidak memakai inisial.
- [ ] Image/media surface dan skeleton tanpa layout shift.
- [ ] Shared program/activity renderer seam untuk Peserta/Coach/Admin preview.

## Slice 02.3 — Shells

- [ ] Guest/Peserta bottom navigation: Hari ini, Program, Peringkat, Coach,
  Profil.
- [ ] Coach bottom navigation: Dashboard, Program, Profil; quick actions tetap
  destinations, bukan tab duplikat.
- [ ] Admin sidebar: Dashboard, Pembayaran, Program, Orang, Konten, Pengaturan.
- [ ] Desktop/tablet/mobile breakpoint behavior teruji.
- [ ] Browser back/forward, deep link, per-tab scroll restoration, focus on
  route change, and modal history tidak saling merusak.

## Slice 02.4 — State gallery

- [ ] Buat internal development-only gallery untuk primitives dan shell.
- [ ] Loading, empty, error, populated, dark, large text/zoom, reduced motion.
- [ ] Jangan compile role switcher/demo data ke production routes.

## Slice 02.5 — PWA presentation baseline

- [ ] Buat manifest name/short name/start URL/display/theme/background/icons
  contract.
- [ ] Siapkan icon pipeline dari final brand asset tanpa menyalin iOS-only
  formats secara buta.
- [ ] Tambah viewport/safe-area metadata dan standalone CSS behavior.
- [ ] Service worker/offline/install prompt lengkap ditunda Phase 11.

## Verification

- [ ] Component tests keyboard/focus/ARIA untuk shared primitives.
- [ ] Visual screenshot matrix mobile light/dark dan Admin desktop.
- [ ] Axe/accessibility smoke tanpa serious/critical issue.
- [ ] Zoom 200%, text wrap Bahasa Indonesia, reduced motion, high contrast.
- [ ] Chromium dan WebKit navigation smoke.
- [ ] Lint, typecheck, focused tests, build lulus.

## Definition of done

- Tiga shell stabil dan tidak berisi business logic/data leak.
- Semantic tokens menjadi satu-satunya source warna/spacing status reusable.
- Admin memanfaatkan desktop dan tetap usable pada mobile.
- Participant/Coach terasa seperti aplikasi mobile tanpa meniru Liquid Glass
  secara palsu.
- Shared renderer seam siap dipakai feature berikutnya.

## Progress log

Catat screenshots/viewport, accessibility checks, files, commands, hasil.

