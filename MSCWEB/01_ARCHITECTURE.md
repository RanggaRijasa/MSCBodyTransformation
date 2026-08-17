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
| Food vision | Server-side provider adapter; OpenRouter/OpenAI-compatible transport sebagai adapter awal |
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

Async food insight
  Submission event / durable database job
       ↓
  Supabase Edge Function worker
       ↓
  FoodVisionProvider interface
       ↓
  OpenRouter adapter sekarang / adapter provider lain kemudian
```

- `ARCH-006` Cloudflare MUST NOT menjadi database kedua atau menyimpan authority state produk.
- `ARCH-007` Browser MUST berisi hanya Supabase URL dan publishable/anon client key yang memang public; service-role, database password, JWT secret, dan OAuth client secret MUST NOT berada di bundle.
- `ARCH-008` View MUST NOT melakukan query langsung atau memuat business rule authoritative.
- `ARCH-009` Domain model MUST bebas dari React, browser `File`, Supabase SDK type, dan component type.
- `ARCH-010` Adapters MUST memetakan framework values menjadi domain values di boundary.
- `ARCH-011` Pemanggilan model vision MUST berlangsung server-side setelah foto dinormalisasi dan MUST tidak dilakukan langsung dari browser.
- `ARCH-012` Job analisis MUST durable, idempotent per submission + analysis version, retry terbatas, dan tidak berada dalam transaksi authority submission/poin. Best-effort enqueue setelah commit MUST didampingi reconciliation scan yang membuat job untuk setiap eligible submission tanpa job agar crash di antaranya tidak kehilangan analisis permanen.
- `ARCH-013` Domain hanya menerima hasil `FoodInsight` tervalidasi; provider-specific payload, SDK type, model name, dan transport error berhenti di adapter.

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
| `/c/:handle` | profil Coach publik yang dapat dibagikan |
| `/admin/*` | Admin-only surface |
| `/privacy`, `/terms`, `/payment-help` | legal/support public |

- `ARCH-NAV-001` Entity URL MUST memakai opaque ID; raw Coach enrollment QR identifier MUST NOT pernah menjadi URL param.
- `ARCH-NAV-002` Back button UI, browser back, dan history gesture MUST menghasilkan route/state yang konsisten.
- `ARCH-NAV-003` Deep link ke private route MUST menuju login bila session tidak ada dan kembali ke route tersebut setelah auth bila authorized.
- `ARCH-NAV-004` Deep link unauthorized MUST menunjukkan state aman; tidak boleh membocorkan keberadaan entity privat.
- `ARCH-NAV-005` Setiap tab compact MUST mempertahankan stack/history masuk akal tanpa meniru `NavigationStack` dengan global boolean state.
- `ARCH-NAV-006` `:handle` profil Coach MUST berupa public slug server-managed yang tidak sama dengan raw QR, auth user ID, atau enrollment identifier.

## 7. Food vision provider boundary

Contract internal minimum:

```text
FoodVisionProvider.analyze(normalizedImage, programRubric)
  → detectedKind: food | drink | shake | not_food | uncertain
  → energyKcal?, proteinGrams?, carbohydrateGrams?, fatGrams?
  → starRating: 1...5
  → confidence: 0...1
  → reasonCode
  → insightSentences: string[1...2]
```

Konfigurasi server-side minimum:

```text
FOOD_AI_PROVIDER=openrouter
FOOD_AI_BASE_URL=https://openrouter.ai/api/v1
FOOD_AI_API_KEY=<server secret>
FOOD_AI_MODEL=google/gemma-4-31b-it:free
FOOD_AI_REASONING_EFFORT=none
FOOD_AI_MAX_OUTPUT_TOKENS=256
FOOD_AI_PROMPT_VERSION=<version>
FOOD_AI_OUTPUT_POLICY_VERSION=food_insight_output_v1
```

Contoh pergantian model di OpenRouter tanpa perubahan kode:

```text
# default free
FOOD_AI_MODEL=google/gemma-4-31b-it:free

# contoh pindah ke endpoint berbayar dari model yang sama
FOOD_AI_MODEL=google/gemma-4-31b-it
```

API key dan base URL tetap sama selama provider-nya OpenRouter. Slug model lain juga dapat dipakai bila lulus capability preflight.

- `ARCH-AI-001` Feature/domain MUST bergantung pada `FoodVisionProvider`, bukan OpenRouter SDK atau endpoint langsung.
- `ARCH-AI-002` Adapter awal SHOULD memakai `fetch` dan schema output tervalidasi agar tidak menambah provider SDK ke browser maupun shared domain.
- `ARCH-AI-003` Perubahan antar-provider OpenAI-compatible SHOULD cukup mengganti `PROVIDER`, `BASE_URL`, `API_KEY`, dan `MODEL`. Klaim "ganti API key saja" MUST NOT dibuat untuk provider dengan endpoint/schema berbeda; provider tersebut membutuhkan adapter implementasi baru.
- `ARCH-AI-004` Worker MUST mengirim hanya byte foto ternormalisasi dan rubric minimum. Nama, user ID, berat, caption bebas, object path, signed URL, dan data program lain MUST tidak dikirim kecuali field rubric yang sudah di-allowlist.
- `ARCH-AI-005` Server validator MUST memverifikasi schema, rentang macro/rating/confidence, reason code, dan favorable-rating guard sebelum menyimpan hasil.
- `ARCH-AI-006` Hasil MUST menyimpan provider/model alias, prompt/rubric version, status, attempt count, dan timestamps untuk reproducibility tanpa menyimpan raw request/response provider.
- `ARCH-AI-007` Provider prompt/schema MUST meminta array `insightSentences` berisi satu atau dua kalimat Bahasa Indonesia, masing-masing maksimal 80 karakter. Server menggabungkannya menjadi `insightText` untuk UI dan MUST menolak, meregenerasi secara terbatas, atau mengganti output invalid/non-Indonesia dengan fallback Indonesia tervalidasi; client MUST tidak menerjemahkan atau memotong raw output secara ad hoc.
- `ARCH-AI-008` Request OpenRouter MUST mengirim model dari `FOOD_AI_MODEL`, `reasoning: { effort: "none", exclude: true }`, output-token cap, dan structured `response_format`. Reasoning content yang tetap muncul MUST diabaikan dan tidak disimpan.
- `ARCH-AI-009` Mengganti model dalam OpenRouter SHOULD hanya memerlukan perubahan `FOOD_AI_MODEL` dan restart/redeploy server. Preflight/health check MUST memastikan model baru menerima image input, menghasilkan text, mendukung structured response, dan tidak mewajibkan reasoning; model incompatible gagal aman tanpa memengaruhi submission/poin.

## 8. Rendering strategy

- `ARCH-WEB-001` Landing dan halaman legal SHOULD dihasilkan sebagai static HTML untuk SEO dan first paint.
- `ARCH-WEB-002` Authenticated app MAY menggunakan client rendering karena bersifat session-dependent dan app-like.
- `ARCH-WEB-003` Pemilihan Expo `web.output` (`static` atau hybrid yang didukung versi terpilih) MUST diprototipekan pada Phase 0 sebelum dikunci.
- `ARCH-WEB-004` Pilihan rendering MUST tetap dapat diekspor ke output yang dilayani Cloudflare Workers Static Assets.
- `ARCH-WEB-005` API route Expo MUST NOT digunakan sebagai pengganti RPC/Edge Function authority tanpa ADR dan threat review.

## 9. Error contract

Repository/use case mengembalikan typed error minimal:

```text
validation | unauthenticated | unauthorized | notFound | conflict
offline | timeout | rateLimited | storageRejected | unknown
```

- `ARCH-ERR-001` Raw error Postgres, Supabase, browser, atau OAuth MUST NOT ditampilkan ke pengguna.
- `ARCH-ERR-002` Error UI MUST berbahasa Indonesia, actionable, dan memberi retry hanya jika aman.
- `ARCH-ERR-003` Logging MUST NOT memuat token, password, raw QR payload, berat badan, signed URL, object path privat, atau isi foto.

## 10. Referensi resmi

- [Expo: Develop websites](https://docs.expo.dev/workflow/web/)
- [Expo: Progressive web apps](https://docs.expo.dev/guides/progressive-web-apps/)
- [Expo: Publish websites](https://docs.expo.dev/guides/publishing-websites/)
- [Supabase: Google Auth](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Cloudflare: Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/)
- [OpenRouter: Gemma 4 31B free](https://openrouter.ai/google/gemma-4-31b-it%3Afree/api)
- [OpenRouter: Quickstart and model field](https://openrouter.ai/docs/quickstart)
- [OpenRouter: Reasoning controls](https://openrouter.ai/docs/guides/best-practices/reasoning-tokens)
