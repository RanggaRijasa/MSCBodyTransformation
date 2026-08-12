# 01 — Architecture specification

## 1. Keputusan stack

Baseline implementasi:

| Lapisan | Pilihan |
|---|---|
| Runtime | Node.js 22 LTS, minimum 22.13.x, untuk development/CI |
| App framework | Expo SDK 57, React Native 0.86, React Native Web 0.21 |
| Bahasa | TypeScript strict |
| Routing | Expo Router |
| Styling | React Native `StyleSheet.create` + design tokens |
| Motion | React Native Reanimated 4; CSS transition hanya untuk surface web-only |
| Gesture | React Native Gesture Handler untuk gesture app; browser history tetap authority navigation |
| Icon | Phosphor Icons melalui SVG dan wrapper `MSCIcon` |
| SVG | `react-native-svg` |
| Data fetching | TanStack Query + typed repository/use-case boundary |
| Forms | React Hook Form + Zod pada UI boundary |
| Backend | Supabase Auth, Postgres, Storage, RPC/Edge Functions |
| Hosting | Cloudflare Workers Static Assets |
| Unit/component test | Vitest + React Native Testing Library |
| End-to-end | Playwright; browser/device coverage pada dokumen QA |

Versi final MUST dikunci pada `package.json`/lockfile ketika scaffolding dimulai, setelah compatibility check pada release notes saat itu. Versi di atas adalah baseline spesifikasi tanggal dokumen, bukan izin untuk floating dependency.

- `ARCH-001` Tailwind CSS dan NativeWind MUST NOT menjadi styling utama.
- `ARCH-002` UI kit besar MUST NOT ditambahkan hanya untuk mempercepat pembuatan screen.
- `ARCH-003` Web-only landing MAY memakai CSS Modules atau stylesheet platform khusus untuk semantic HTML, grid, hover, focus-visible, dan metadata/SEO.
- `ARCH-004` Feature screen MUST memakai tokens yang sama pada compact, medium, dan wide layout.
- `ARCH-005` Setiap third-party dependency baru di luar baseline ini MUST memiliki ADR.

## 2. Batas sistem

```text
Browser / installed PWA
  ├─ Landing (public, indexable)
  └─ Authenticated app shell
       ↓
Feature screen + feature state
       ↓
Use case / domain service
       ↓
Repository interface
       ↓
Supabase adapter
  ├─ Auth: Google OAuth session
  ├─ Data API: read yang dilindungi RLS
  ├─ Storage: private media
  └─ RPC / Edge Function: authoritative mutations

Cloudflare
  ├─ DNS + TLS
  ├─ static application assets
  └─ SPA route fallback / headers
```

- `ARCH-006` Cloudflare MUST NOT menjadi database kedua atau menyimpan authority state produk.
- `ARCH-007` Browser MUST berisi hanya Supabase URL dan publishable/anon client key yang memang public; service-role, database password, JWT secret, dan OAuth client secret MUST NOT berada di bundle.
- `ARCH-008` View MUST NOT melakukan query langsung atau memuat business rule authoritative.
- `ARCH-009` Domain model MUST bebas dari React, browser `File`, Supabase SDK type, dan component type.
- `ARCH-010` Adapters MUST memetakan framework values menjadi domain values di boundary.

## 3. Struktur project target

Struktur ini menjadi contract untuk fase scaffolding:

```text
MSCWEB/
  app/                         # route files Expo Router
    (public)/
    (auth)/
    (app)/
      (participant)/
      (coach)/
      (admin)/
    +html.tsx
    +not-found.tsx
  src/
    app/                       # dependency container, providers, route guards
    domain/                    # portable models, policies, errors, use cases
    data/                      # repository protocols and Supabase adapters
    features/                  # screen/state grouped by capability
    shared/
      design/                  # tokens, themes, responsive rules
      icons/                   # MSCIcon and semantic icon registry
      ui/                      # reusable primitives/components
      media/                   # normalize/compress/upload adapters
      auth/
      navigation/
  public/
    icons/
    manifest.webmanifest
    robots.txt
  supabase/
    migrations/                # sementara tetap authority di repo induk; lihat delivery plan
    functions/
  tests/
    e2e/
    rls/
  specs/                       # opsional saat dipindah repo; dokumen ini dipertahankan
```

Folder nyata MAY disesuaikan sedikit dengan convention Expo, tetapi dependency direction dan ownership di atas MUST dipertahankan.

## 4. State dan data flow

- `ARCH-STATE-001` TanStack Query MUST menangani server state, cache invalidation, retry yang aman, dan cancellation.
- `ARCH-STATE-002` State lokal/feature MUST menangani draft form, presentation, filter, dan ephemeral UI; tidak boleh menduplikasi server authority.
- `ARCH-STATE-003` Semua halaman data MUST memodelkan loading, loaded, empty, error, offline, forbidden, dan session-expired yang relevan.
- `ARCH-STATE-004` Optimistic update MUST NOT digunakan untuk approval pembayaran, activation role, enrollment, score correction, winner lock, atau review bukti.
- `ARCH-STATE-005` Mutation retry hanya boleh otomatis jika operation memiliki idempotency key dan semantics yang aman.
- `ARCH-STATE-006` Session expiry MUST menghapus private query cache sebelum kembali ke login.

## 5. Authentication

- `ARCH-AUTH-001` Google OAuth Supabase adalah satu-satunya login web baseline.
- `ARCH-AUTH-002` OAuth menggunakan Authorization Code + PKCE melalui API Supabase resmi dan redirect URL exact-match untuk local dan production.
- `ARCH-AUTH-003` Callback MUST memvalidasi hasil, membangun server-authoritative profile/role view, lalu meneruskan preserved intent yang aman.
- `ARCH-AUTH-004` URL tujuan setelah login MUST hanya menerima internal allowlisted route, bukan arbitrary external URL.
- `ARCH-AUTH-005` Role guard client hanya untuk UX. Authorization sebenarnya MUST ditegakkan RLS/RPC/Function.
- `ARCH-AUTH-006` Logout dan session-invalid MUST membersihkan private caches, in-memory media, dan pending signed URLs.

## 6. Routing dan navigation state

Route group dapat disembunyikan oleh Expo Router. URL publik harus stabil, machine-readable, dan tidak bergantung pada copy UI.

| Route publik | Tujuan |
|---|---|
| `/` | landing |
| `/login` | Google login |
| `/auth/callback` | OAuth callback |
| `/app` | role-aware entry |
| `/app/home` | home/dashboard role aktif |
| `/app/programs` | program root |
| `/app/programs/:programId` | detail program |
| `/app/programs/:programId/activities/:activityId` | activity detail |
| `/app/payments/:paymentRequestId` | pembayaran/status milik pengguna |
| `/app/leaderboard` | leaderboard |
| `/app/coach` | Coach Participant / Coach root sesuai guard |
| `/app/profile` | profil |
| `/admin/*` | Admin-only surface |
| `/privacy`, `/terms`, `/payment-help` | legal/support public |

- `ARCH-NAV-001` Entity URL MUST memakai opaque ID; raw Coach enrollment QR identifier MUST NOT pernah menjadi URL param.
- `ARCH-NAV-002` Back button UI, browser back, dan history gesture MUST menghasilkan route/state yang konsisten.
- `ARCH-NAV-003` Deep link ke private route MUST menuju login bila session tidak ada dan kembali ke route tersebut setelah auth bila authorized.
- `ARCH-NAV-004` Deep link unauthorized MUST menunjukkan state aman; tidak boleh membocorkan keberadaan entity privat.
- `ARCH-NAV-005` Setiap tab compact MUST mempertahankan stack/history masuk akal tanpa meniru `NavigationStack` dengan global boolean state.

## 7. Rendering strategy

- `ARCH-WEB-001` Landing dan halaman legal SHOULD dihasilkan sebagai static HTML untuk SEO dan first paint.
- `ARCH-WEB-002` Authenticated app MAY menggunakan client rendering karena bersifat session-dependent dan app-like.
- `ARCH-WEB-003` Pemilihan Expo `web.output` (`static` atau hybrid yang didukung versi terpilih) MUST diprototipekan pada Phase 0 sebelum dikunci.
- `ARCH-WEB-004` Pilihan rendering MUST tetap dapat diekspor ke output yang dilayani Cloudflare Workers Static Assets.
- `ARCH-WEB-005` API route Expo MUST NOT digunakan sebagai pengganti RPC/Edge Function authority tanpa ADR dan threat review.

## 8. Error contract

Repository/use case mengembalikan typed error minimal:

```text
validation | unauthenticated | unauthorized | notFound | conflict
offline | timeout | rateLimited | storageRejected | unknown
```

- `ARCH-ERR-001` Raw error Postgres, Supabase, browser, atau OAuth MUST NOT ditampilkan ke pengguna.
- `ARCH-ERR-002` Error UI MUST berbahasa Indonesia, actionable, dan memberi retry hanya jika aman.
- `ARCH-ERR-003` Logging MUST NOT memuat token, password, raw QR payload, berat badan, signed URL, object path privat, atau isi foto.

## 9. Referensi resmi

- [Expo: Develop websites](https://docs.expo.dev/workflow/web/)
- [Expo: Progressive web apps](https://docs.expo.dev/guides/progressive-web-apps/)
- [Expo: Publish websites](https://docs.expo.dev/guides/publishing-websites/)
- [Supabase: Google Auth](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Cloudflare: Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/)
