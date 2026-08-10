# Arsitektur MSC Web/PWA

## Tujuan

Membangun ulang pengalaman MSC sebagai satu PWA modular tanpa memindahkan
aturan bisnis authoritative ke browser. Desain dan perilaku iOS menjadi
referensi parity; backend Supabase tetap menjadi sumber kebenaran.

## Konteks sistem

```text
Browser/PWA
  |
  | HTTPS + authenticated cookie/JWT
  v
Next.js web application
  |-- Server Components dan Route Handlers
  |-- Client Components untuk interaksi/perangkat
  |
  v
Supabase Auth / Data API / RPC / Storage / Edge Functions
  |
  v
Postgres + RLS + audit + server-authoritative rules
```

PWA tidak memiliki jalur khusus yang dapat melewati RLS atau protected server
operation. Admin adalah surface berbeda, bukan backend berbeda.

## Shell dan responsivitas

### Guest dan Peserta

- Mobile-first, bottom navigation, safe-area, full-height route transitions.
- Pada desktop tetap nyaman dan dapat memakai content rail dengan lebar
  terkontrol; jangan menggambar bingkai ponsel dekoratif.
- Guest menggunakan shell Peserta tanpa personal data.

### Coach

- Mobile-first dengan bottom navigation dan action hierarchy yang sama dengan
  referensi iOS.
- Tablet/desktop boleh memperlebar roster dan detail tanpa mengubah aturan
  privasi.

### Admin

- Desktop-first dengan sidebar, header, tabel/list responsif, editor berkolom,
  dan detail panel bila ruang cukup.
- Pada mobile berubah menjadi single-column navigation dan sheet/dialog yang
  dapat dioperasikan, bukan versi desktop yang diperkecil.
- Route utama tetap `/admin/...` pada origin yang sama agar Auth, cookie, CSP,
  deployment, dan audit lebih sederhana.

## Lapisan

### App/router

Memiliki route, metadata, layout, loading/error/not-found boundary, dan role
gate. Route tidak memiliki query kompleks atau business rule.

### Feature

Satu feature memuat komponen, state/controller, schema form, use case wiring,
dan public entry point untuk satu capability. Feature tidak mengimpor internal
feature lain.

### Domain

Memuat model portable, typed error, value object, validator, formatter input,
dan pure business service. Domain tidak mengenal React, Next.js, Supabase,
browser, atau provider pembayaran.

### Infrastructure

Memuat adapter Supabase browser/server, repository implementation, media/QR
browser adapter, telemetry adapter, dan manual payment transport. Semua
provider-specific DTO dipetakan ke domain di sini.

### Shared

Memuat UI primitive, semantic tokens, layout primitives, hooks generik,
localization, config, clock/ID abstraction, dan utilitas kecil yang benar-benar
digunakan lintas feature. Shared bukan tempat membuang kode yang belum jelas.

## Data fetching

- Public catalog dapat dirender server-side dan di-cache hanya bila payload
  telah dibuktikan public-safe.
- Data authenticated selalu dipisahkan per request/user dan tidak masuk CDN
  public cache.
- Mutation memakai protected RPC atau Edge Function yang sudah menetapkan
  actor dari JWT.
- Client tidak mengirim user ID, role, harga authoritative, payment status,
  points, atau Coach assignment sebagai kebenaran.
- TanStack Query atau state library lain tidak menjadi default. Tambahkan hanya
  bila kebutuhan invalidation/realtime telah dibuktikan dan disetujui.

## Auth

- Guest adalah logged-out state, bukan anonymous Supabase user atau role.
- Google OAuth menjadi provider utama saat production configuration siap.
- Email/password atau magic link tetap feature-gated sampai SMTP/domain siap.
- Sign in with Apple tidak diport.
- Session web menggunakan cookie yang diatur sesuai Supabase SSR.
- Server memvalidasi claims/token sebelum protected rendering atau mutation.
- Protected profile/role tetap dibaca dari data server-controlled.
- Account deletion, reauthentication, session revoke, dan retention tetap
  mengikuti operasi backend yang diuji.

## Manual commerce

StoreKit diganti adapter `manual_bank_transfer`, tetapi state tetap terpisah:

```text
application/enrollment intent
  -> payment request
  -> evidence uploaded
  -> Admin decision
  -> verified payment event
  -> entitlement/enrollment/Coach capability projection
```

Admin tidak mengedit role atau entitlement langsung. Satu protected operation
harus memverifikasi state, mengunci row, merekam reviewer serta audit event,
dan mengaktifkan projection secara atomik/idempoten.

## PWA dan cache

- Manifest, icons, theme color, standalone display, install guidance, update
  lifecycle, dan HTTPS adalah baseline.
- Service worker menggunakan network-first/no-store untuk authenticated
  routes dan private data.
- Cache-first hanya untuk fingerprinted static assets yang tidak sensitif.
- Offline MVP menampilkan shell dan status koneksi; mutation personal tidak
  mengaku berhasil saat belum durable di server.
- Background sync, push, dan offline drafts adalah capability opsional yang
  hanya ditambahkan setelah privacy/reliability spike.

## Observability

- Log memakai event name allowlist dan correlation ID yang tidak mengandung
  PII.
- Jangan log token, email penuh, nomor HP, berat, jawaban, QR mentah, object
  path privat, signed URL, atau bukti transfer.
- Error UI memetakan typed error menjadi copy Bahasa Indonesia yang dapat
  ditindaklanjuti.
- Provider observability eksternal memerlukan keputusan privacy dan consent
  sebelum dipasang.

## Portability

- Domain model dan kontrak tidak bergantung pada Cloudflare atau Vercel.
- Hosting-specific code dibatasi pada config/deployment adapter.
- Supabase API URL berasal dari environment; custom domain bersifat opsional.
- Target default adalah Cloudflare Workers melalui OpenNext setelah adapter
  runtime lulus compatibility test. Vercel tetap fallback tanpa menulis ulang
  feature/domain bila ada blocker kompatibilitas yang belum aman.

## Phase 00 contract set

Dokumen berikut menjadi companion wajib arsitektur sebelum scaffold dan
vertical slice terkait:

- [Source and Runtime Baseline](../baseline/PHASE_00_SOURCE_AND_RUNTIME_BASELINE.md).
- [Contract Reconciliation](../baseline/PHASE_00_CONTRACT_RECONCILIATION.md).
- [Capability and State Parity Matrix](./PHASE_00_PARITY_MATRIX.md).
- [Target Manual Commerce Contract](./TARGET_MANUAL_COMMERCE_CONTRACT.md).
- [Forward-only Migration and Decommission Plan](./FORWARD_ONLY_MIGRATION_AND_DECOMMISSION.md).
- [iOS to Web Test Mapping](../testing/IOS_TO_WEB_TEST_MAPPING.md).
