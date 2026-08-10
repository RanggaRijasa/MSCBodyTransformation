# Phase 03: Guest, Auth, and Onboarding

> Status: SELESAI LOKAL

## Tujuan

Menghasilkan Guest public-safe shell dan lifecycle Auth web yang aman dengan
Google OAuth, profile onboarding, application intent, session, logout, dan
account deletion. Apple tidak diport.

## Prasyarat

- Phase 00 contract dan Phase 01–02 foundation selesai.
- Supabase local readiness diperiksa hanya saat integration slice dimulai.
- Google hosted config tidak disentuh pada phase lokal ini.

## Slice 03.1 — Guest

- [x] Guest adalah logged-out state tanpa `auth.users` row.
- [x] Public reads hanya program published, leaderboard public-safe, winner
  poster, dan Coach approved/public.
- [x] Tidak ada fixture profile, enrollment, weight, submission, current Coach,
  payment, atau private media pada Guest.
- [x] Central auth gate mempertahankan pending public program intent secara
  opaque/expiring tanpa QR mentah.

## Slice 03.2 — Auth pages

- [x] `/masuk`, `/daftar`, callback, cancel/error, and return-to behavior.
- [x] Google provider-first UI dengan official brand asset/component.
- [x] Tidak ada Sign in with Apple.
- [x] Email/password/forgot password tetap feature-gated sesuai keputusan.
- [x] PKCE callback memvalidasi state, redirect allowlist, environment, TTL,
  dan code exchange; open redirect ditolak.
- [x] Generic account-recovery response tidak membocorkan keberadaan akun.

## Slice 03.3 — Session dan role routing

- [x] SSR cookie refresh mengikuti current Supabase guidance.
- [x] Protected route menggunakan verified identity/claims dan protected
  profile, bukan client metadata.
- [x] Logout membersihkan cookie, feature state, PWA cache yang relevan, dan
  pending personal intent.
- [x] Session expiry, account switch, stale role, revoked session, concurrent
  tabs, retry, dan offline state teruji.
- [x] Guest dan Participant tidak dapat memilih Coach/Admin role.

## Slice 03.4 — Onboarding

- [x] Nama, nomor HP, member level, dan tujuan Peserta/Ajukan Coach.
- [x] App-owned form memakai Bahasa Indonesia dan `id-ID`.
- [x] New registration membuat Participant terlebih dahulu.
- [x] Participant onboarding memerlukan QR Coach valid pada browser-capability
  seam; production scanner diselesaikan Phase 04.
- [x] Coach applicant SC+ mengisi HOM STS/ICT attestations; `Member` tidak
  eligible dan tidak diberi capability.
- [x] Draft tidak menjadi authoritative profile sebelum server operation
  selesai; cancel membersihkan draft dengan aman.

## Slice 03.5 — Profile/account lifecycle

- [x] Read/edit allowlisted profile fields.
- [x] Email read-only, role/server status read-only.
- [x] Logout dan account deletion dengan reauthentication.
- [x] Coach dengan assignment aktif tetap mengikuti transfer guard.
- [x] Retention/anonymization dan private media cleanup dipertahankan.
- [x] Apple token revoke tidak dipanggil untuk web-created Google accounts;
  legacy Apple identity retirement ditunda Phase 13.

## Verification

- [x] Unit tests auth state machine/pending intent/role routing.
- [x] Integration tests local Auth bootstrap/RLS/profile/account deletion.
- [x] E2E Guest browse -> auth gate; Google callback stub; onboarding Peserta;
  application intent; logout; expiry; deletion denial/success.
- [x] Forged metadata/role, open redirect, CSRF/state mismatch, cross-user read,
  and cached response tests.
- [x] Browser `en-US` tetap Bahasa Indonesia.
- [x] Lint, typecheck, test, build lulus.

## Definition of done

- Guest tidak pernah memperoleh private data atau Auth identity.
- Google web flow dan session cookie boundary siap secara lokal.
- Apple tidak muncul pada UI/runtime web.
- Role hanya berasal dari protected server state.
- Auth/profile/account journeys memiliki loading/error/offline/retry states.

## External gates

- Google web client/callback hosted dan domain production: Phase 12.
- SMTP/email production: tetap skipped sampai keputusan eksplisit.

## Progress log

### 10 Agustus 2026 — selesai lokal

- Files changed: model dan state machine Auth di `src/features/auth/model`,
  server boundary dan repository profile di `src/features/auth/server`, operasi
  aplikasi di `src/application/auth`, adapter SSR Supabase di
  `src/infrastructure/supabase`, route/page Auth dan account lifecycle di
  `src/app`, komponen serta style Auth, asset resmi Google, dokumentasi
  security, script verifikasi lokal, dan test unit/component/E2E/integration.
- Assumptions: Google menjadi provider pertama dan Apple tidak tersedia pada
  UI/runtime web. Participant scanner tetap berupa capability seam yang gagal
  tertutup; implementasi scanner produksi adalah scope Phase 04. Hosted Google
  client/callback, domain production, dan SMTP tetap gate Phase 12 atau
  keputusan eksplisit.
- Security: transaksi OAuth dan pending program intent ditandatangani,
  HttpOnly, memiliki TTL, serta hanya menerima return-to internal. Identity
  diverifikasi server-side memakai Supabase claims dan profile diload melalui
  client SSR terverifikasi yang sama; client metadata tidak memberi role.
- Build command: `PATH="/opt/homebrew/opt/node@24/bin:$PATH" corepack pnpm build`.
  Result: lulus; 39 route terbentuk tanpa development gallery.
- Test commands: `corepack pnpm test` (62/62 lulus),
  `corepack pnpm test:e2e` (42 lulus lintas Chromium/WebKit; 22 skip
  conditional sesuai browser/local-backend), focused local Auth Playwright
  (4/4 lulus), dan `corepack pnpm test:phase03:local` (4 file, 111 pgTAP
  lulus dan seluruh perubahan database di-rollback/dibersihkan).
- Quality commands: `corepack pnpm format:check`, `corepack pnpm verify`, dan
  pemeriksaan arsitektur, localization, public env, serta secret scan di dalam
  pipeline. Result: lint, typecheck, unit/component test, production build,
  localization, dan batas dependency lulus.
- Remaining blockers: tidak ada untuk local Definition of Done Phase 03.
  Google hosted configuration/domain production tetap Phase 12, SMTP tetap
  skipped, dan production QR scanner diteruskan ke Phase 04.
