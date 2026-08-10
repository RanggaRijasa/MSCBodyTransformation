# Phase 01 Dependency Baseline

> Diverifikasi: 10 Agustus 2026. Semua versi dipin exact di lockfile.

## Runtime dan framework

| Dependency | Versi | Alasan |
|---|---:|---|
| Node.js | 24.19.0 LTS | Runtime production aktif LTS; Node 25 lokal bukan target |
| pnpm | 11.21.0 | Package manager tunggal dan reproducible lockfile |
| Next.js | 16.3.0 | App Router stabil; dependency PostCSS dan Sharp sudah memakai patch advisory Agustus 2026 |
| React / React DOM | 19.2.8 | Versi stable yang kompatibel dengan Next.js 16.3 |
| TypeScript | 6.0.3 | Strict compiler stable; tidak mengadopsi native TS 7 sebelum support matrix matang |

Sumber resmi: [Node releases](https://nodejs.org/en/about/previous-releases),
[Next.js releases](https://nextjs.org/blog),
[React versions](https://react.dev/versions), dan
[TypeScript 6.0](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html).

## Production dependencies

| Dependency | Versi | Alasan native/framework belum cukup |
|---|---:|---|
| `@supabase/supabase-js` | 2.112.2 | Typed browser/server Data API dan Auth client resmi |
| `@supabase/ssr` | 0.12.4 | Cookie session rotation untuk Next.js SSR; package resmi yang direkomendasikan |
| `server-only` | 0.0.1 | Build-time guard agar server adapter tidak masuk client graph |

Supabase SSR tetap beta sehingga adapter dipersempit dan dilindungi contract
test. Implementasi mengikuti [SSR guide](https://supabase.com/docs/guides/auth/server-side),
[creating a client](https://supabase.com/docs/guides/auth/server-side/creating-a-client),
dan [getClaims](https://supabase.com/docs/reference/javascript/auth-getclaims).

## Development dependencies

- ESLint 9.39.5 + `eslint-config-next` 16.3.0 untuk framework lint dan import boundary.
- Prettier 3.9.6 untuk format policy, tanpa runtime dependency.
- Vitest 4.1.10, Vite 8.2.1, jsdom 30.0.1, dan Testing Library untuk unit/component.
- Playwright 1.62.1 untuk Chromium/WebKit E2E.
- `@axe-core/playwright` 4.12.1 untuk accessibility smoke.
- Type packages dipin ke React 19 dan Node 24 lines.

Referensi resmi: [Vitest 4.1](https://vitest.dev/blog/vitest-4-1.html) dan
[Playwright release notes](https://playwright.dev/docs/release-notes).

## Changelog dan security scan

- Next.js 16.3.0 dipilih setelah audit 16.2.11 menemukan advisory transitif pada
  `postcss` dan `sharp`; 16.3.0 menaikkan keduanya ke versi patched.
- React berada di patch 19.2.8, di atas patch RSC yang diwajibkan advisory Desember 2025.
- Supabase breaking changes relevan: explicit Data API grants tetap wajib,
  OpenAPI anon endpoint tidak diandalkan, dan local self-hosted gateway berubah
  menuju Envoy. Phase ini tidak mengubah local Docker/config.
- `@supabase/ssr` 0.12.4 membawa fix flush PKCE verifier removal pada server.
- `skipLibCheck` dibatasi pada deklarasi `.d.ts` dependency karena deklarasi WebAuthn
  Supabase belum kompatibel dengan `exactOptionalPropertyTypes` TypeScript 6;
  seluruh source dan test milik aplikasi tetap diperiksa dengan strict mode.
- `pnpm audit` dan clean lockfile install wajib dijalankan sebelum Phase 01 selesai.

Tidak ada dependency QR, PWA, media, state management, analytics, atau UI library
pada Phase 01.
