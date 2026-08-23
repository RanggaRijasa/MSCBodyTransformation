# 06 — PWA and hosting specification

## 1. Deployment topology

```text
User
  → Cloudflare DNS/TLS
  → Cloudflare Workers Static Assets
      ├─ landing/static HTML
      ├─ Expo web bundles/assets
      ├─ manifest/icons/service worker
      └─ SPA route fallback
  → Supabase hosted main
      ├─ Google Auth
      ├─ Postgres/Data API/RPC
      ├─ Edge Functions
      └─ private Storage
```

- `PWA-HST-001` Gunakan Cloudflare Workers Static Assets, bukan legacy Workers Sites.
- `PWA-HST-002` Production domain MUST memakai HTTPS, custom domain, managed TLS, dan canonical host redirect.
- `PWA-HST-003` SPA navigation routes MUST fallback ke app shell; missing real static assets MUST tetap menghasilkan 404 yang benar.
- `PWA-HST-004` Hashed assets MAY immutable-cache; HTML, manifest, dan service worker MUST menggunakan update-safe cache policy.
- `PWA-HST-005` Environment configuration MUST dipisahkan local/preview/production dan tervalidasi pada build.

Referensi: [Cloudflare Workers Static Assets](https://developers.cloudflare.com/workers/static-assets/) dan [SPA routing](https://developers.cloudflare.com/workers/static-assets/routing/single-page-application/).

## 2. PWA manifest

Manifest minimum:

```json
{
  "name": "MSC Body Transformation",
  "short_name": "MSC",
  "lang": "id-ID",
  "start_url": "/app",
  "scope": "/",
  "display": "standalone",
  "orientation": "any",
  "theme_color": "#111111",
  "background_color": "#111111"
}
```

Nilai final theme/background harus diuji terhadap splash platform. Icons mengikuti [03_DESIGN_SYSTEM.md](./03_DESIGN_SYSTEM.md).

- `PWA-MAN-001` Manifest MUST link dari seluruh HTML entry.
- `PWA-MAN-002` Icons MUST mencakup 192/512 `any`, 192/512 `maskable`, dan Apple touch icon.
- `PWA-MAN-003` App name/short name MUST tidak terpotong pada platform target utama.
- `PWA-MAN-004` `start_url` MUST menangani unauthenticated state dengan benar dan tidak menyimpan route privat akun sebelumnya.
- `PWA-MAN-005` Browser theme color MUST mengikuti supported light/dark metadata bila implementasi target mendukung.

Referensi: [Expo PWA guide](https://docs.expo.dev/guides/progressive-web-apps/) dan [web.dev manifest](https://web.dev/learn/pwa/web-app-manifest).

## 3. Service worker and offline contract

PWA bukan aplikasi offline penuh. Service worker hanya memberi fast shell, static asset caching, dan offline explanation. Mutation, auth, QR validation, upload, approval, dan authoritative program data memerlukan koneksi.

- `PWA-OFF-001` Precache hanya versioned public app shell/assets.
- `PWA-OFF-002` Private API response, payment data, profile, evidence, signed URL, dan private image MUST NOT precache.
- `PWA-OFF-003` Offline navigation ke cached shell MUST menunjukkan status offline dan menonaktifkan server mutation secara jujur.
- `PWA-OFF-004` Upload/payment/approval MUST NOT masuk background queue yang dapat terkirim tanpa konfirmasi baru setelah state berubah.
- `PWA-OFF-005` Cached public data MAY ditampilkan dengan label waktu terakhir diperbarui; tidak boleh dilabeli server-current.
- `PWA-OFF-006` Service worker update MUST tidak membuat user terjebak pada incompatible shell/API. Prompt reload hanya muncul pada safe point.
- `PWA-OFF-007` Logout/account switch MUST membersihkan user-scoped Cache Storage/IndexedDB jika ada.

## 4. Install experience

- `PWA-INS-001` App MUST tidak memaksa install prompt pada first visit.
- `PWA-INS-002` Install affordance MAY muncul setelah meaningful engagement dan hanya bila platform mendukung.
- `PWA-INS-003` iOS/iPadOS guidance MUST menjelaskan Share → Tambahkan ke Layar Utama dengan copy Indonesia dan dapat ditutup.
- `PWA-INS-004` App tetap fully usable pada Safari/Chrome browser tanpa instalasi.
- `PWA-INS-005` Standalone display MUST memperhitungkan safe area, virtual keyboard, status bar theme, dan external link handling.

## 5. Landing page

Landing page adalah bagian dari product, bukan marketing template terpisah.

Section minimum:

1. hero + CTA masuk/mulai;
2. penjelasan singkat cara program bekerja;
3. program aktif publik;
4. peran Coach/dukungan;
5. cara pembayaran dan pemeriksaan manual;
6. trust/privacy copy;
7. install-app guidance;
8. footer legal/support.

- `PWA-LND-001` Landing MUST semantic, keyboard-accessible, responsive, dan tidak membutuhkan JS untuk membaca copy utama.
- `PWA-LND-002` Hero asset MUST menggunakan asset brand approved atau visual yang dibuat/disetujui terpisah; tidak memakai stock-template generic tanpa review.
- `PWA-LND-003` CTA dan program publik MUST menggunakan canonical routes.
- `PWA-LND-004` Metadata MUST mencakup title, description, canonical, Open Graph, favicon, dan theme-color.
- `PWA-LND-005` Structured data hanya ditambahkan bila content benar-benar memenuhi schema; tidak membuat rating/testimonial palsu.

### 5.1 Profil Coach publik dan social preview

- `PWA-CPR-001` `/c/:handle` MUST memiliki title, description, canonical URL, dan Open Graph image yang berasal hanya dari public Coach read model.
- `PWA-CPR-002` Canonical MUST menghapus `utm_*`, `fbclid`, dan query tracking lain; link tetap boleh dibuka dengan parameter tersebut tanpa menjadikannya canonical.
- `PWA-CPR-003` Crawler yang tidak menjalankan SPA JavaScript MUST tetap menerima metadata profil published yang benar. Strategi Worker HTML rendering/metadata injection dan cache-nya MUST diprototipekan serta dikunci sebelum W08 selesai.
- `PWA-CPR-004` Unknown, draft, expired, revoked, dan unlisted profile MUST tidak menghasilkan metadata seolah Coach masih terverifikasi.
- `PWA-CPR-005` Raw QR, auth ID, private media path, dan setiap field dengan public toggle off MUST tidak masuk HTML/meta/cache response. Nomor telepon/WhatsApp yang memang dipublikasikan MAY tampil pada body profil, tetapi MUST tidak dimasukkan ke title, description, Open Graph, JSON-LD, atau metadata crawler.
- `PWA-CPR-006` Cache key/invalidation MUST memperhitungkan handle, publication/moderation version, dan entitlement state; response draft/private MUST tidak pernah masuk public cache.

## 6. Security headers

Baseline headers:

- `Content-Security-Policy` yang allowlist Cloudflare app origin, Supabase project, Google auth resources yang diperlukan, dan image/media sources spesifik;
- `Referrer-Policy: strict-origin-when-cross-origin` atau lebih ketat bila flow memungkinkan;
- `X-Content-Type-Options: nosniff`;
- `Permissions-Policy` yang menonaktifkan sensor tidak dipakai dan mengizinkan camera hanya untuk QR route;
- `frame-ancestors 'none'` melalui CSP kecuali integration resmi disetujui;
- HSTS setelah domain/TLS tervalidasi.

- `PWA-SEC-001` CSP awal SHOULD berjalan report-only pada preview untuk menemukan dependency, lalu enforce sebelum production.
- `PWA-SEC-002` Source wildcard luas dan `unsafe-eval` MUST tidak masuk production tanpa ADR/threat justification.
- `PWA-SEC-003` OAuth popup/redirect dan Supabase realtime/storage endpoints yang dipakai MUST diuji di bawah CSP final.

QR scanning pada iOS WebKit memakai fallback ZXing WebAssembly karena
`BarcodeDetector` native tidak tersedia secara konsisten. Binary WASM MUST
self-hosted pada origin aplikasi, dikunci dengan checksum saat build, memiliki
nama ber-versi, dan dikirim sebagai `application/wasm`. CSP production MAY
menambahkan token sempit `wasm-unsafe-eval` pada `script-src`; token JavaScript
umum `unsafe-eval`, CDN runtime, dan wildcard source tetap dilarang. Perubahan
versi decoder MUST memperbarui checksum serta nama aset sebelum deployment.

## 7. Performance budgets

Budgets awal pada simulated mid-tier mobile, koneksi 4G:

- landing LCP p75 ≤ 2,5 detik;
- INP p75 ≤ 200 ms;
- CLS p75 ≤ 0,1;
- initial compressed JS untuk landing dijaga serendah mungkin dan MUST dipisah dari authenticated/admin feature chunks;
- hero image responsive dan tidak melebihi kebutuhan viewport;
- list image menggunakan thumbnails dan lazy loading.

- `PWA-PERF-001` Bundle analyzer MUST menjadi checkpoint setiap phase besar.
- `PWA-PERF-002` Admin/Coach screens MUST lazy-load dari public landing bundle.
- `PWA-PERF-003` Phosphor MUST tree-shake/import glyph terpilih; dilarang mengirim seluruh icon pack.
- `PWA-PERF-004` Image proof full-resolution hanya dimuat di authorized detail viewer.

## 8. Observability

Tool vendor belum dikunci. Minimal contract:

- deploy/version identifier;
- route-level error count;
- auth callback success/failure category;
- payment state-transition result tanpa bukti/PII;
- upload failure category/size band tanpa path;
- Web Vitals;
- correlation ID untuk RPC/Function.

Analytics/monitoring vendor memerlukan privacy review dan ADR. Consent/notice harus sesuai data yang benar-benar dikumpulkan.

## 9. Domain and environment checklist

Sebelum production:

- domain/subdomain final diputuskan;
- Cloudflare account ownership dan access roles ditentukan;
- DNS/TLS/canonical redirect aktif;
- Supabase Google OAuth authorized origin/redirect URL tepat;
- preview domain tidak berbagi production OAuth bila tidak diperlukan;
- noindex untuk preview;
- secrets hanya di provider configuration;
- rollback deploy dan cache purge procedure diuji;
- incident contact dan status communication ditentukan.
