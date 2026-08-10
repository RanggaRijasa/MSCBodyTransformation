# Phase 03: Guest, Auth, and Onboarding

> Status: BELUM DIMULAI

## Tujuan

Menghasilkan Guest public-safe shell dan lifecycle Auth web yang aman dengan
Google OAuth, profile onboarding, application intent, session, logout, dan
account deletion. Apple tidak diport.

## Prasyarat

- Phase 00 contract dan Phase 01–02 foundation selesai.
- Supabase local readiness diperiksa hanya saat integration slice dimulai.
- Google hosted config tidak disentuh pada phase lokal ini.

## Slice 03.1 — Guest

- [ ] Guest adalah logged-out state tanpa `auth.users` row.
- [ ] Public reads hanya program published, leaderboard public-safe, winner
  poster, dan Coach approved/public.
- [ ] Tidak ada fixture profile, enrollment, weight, submission, current Coach,
  payment, atau private media pada Guest.
- [ ] Central auth gate mempertahankan pending public program intent secara
  opaque/expiring tanpa QR mentah.

## Slice 03.2 — Auth pages

- [ ] `/masuk`, `/daftar`, callback, cancel/error, and return-to behavior.
- [ ] Google provider-first UI dengan official brand asset/component.
- [ ] Tidak ada Sign in with Apple.
- [ ] Email/password/forgot password tetap feature-gated sesuai keputusan.
- [ ] PKCE callback memvalidasi state, redirect allowlist, environment, TTL,
  dan code exchange; open redirect ditolak.
- [ ] Generic account-recovery response tidak membocorkan keberadaan akun.

## Slice 03.3 — Session dan role routing

- [ ] SSR cookie refresh mengikuti current Supabase guidance.
- [ ] Protected route menggunakan verified identity/claims dan protected
  profile, bukan client metadata.
- [ ] Logout membersihkan cookie, feature state, PWA cache yang relevan, dan
  pending personal intent.
- [ ] Session expiry, account switch, stale role, revoked session, concurrent
  tabs, retry, dan offline state teruji.
- [ ] Guest dan Participant tidak dapat memilih Coach/Admin role.

## Slice 03.4 — Onboarding

- [ ] Nama, nomor HP, member level, dan tujuan Peserta/Ajukan Coach.
- [ ] App-owned form memakai Bahasa Indonesia dan `id-ID`.
- [ ] New registration membuat Participant terlebih dahulu.
- [ ] Participant onboarding memerlukan QR Coach valid pada browser-capability
  seam; production scanner diselesaikan Phase 04.
- [ ] Coach applicant SC+ mengisi HOM STS/ICT attestations; `Member` tidak
  eligible dan tidak diberi capability.
- [ ] Draft tidak menjadi authoritative profile sebelum server operation
  selesai; cancel membersihkan draft dengan aman.

## Slice 03.5 — Profile/account lifecycle

- [ ] Read/edit allowlisted profile fields.
- [ ] Email read-only, role/server status read-only.
- [ ] Logout dan account deletion dengan reauthentication.
- [ ] Coach dengan assignment aktif tetap mengikuti transfer guard.
- [ ] Retention/anonymization dan private media cleanup dipertahankan.
- [ ] Apple token revoke tidak dipanggil untuk web-created Google accounts;
  legacy Apple identity retirement ditunda Phase 13.

## Verification

- [ ] Unit tests auth state machine/pending intent/role routing.
- [ ] Integration tests local Auth bootstrap/RLS/profile/account deletion.
- [ ] E2E Guest browse -> auth gate; Google callback stub; onboarding Peserta;
  application intent; logout; expiry; deletion denial/success.
- [ ] Forged metadata/role, open redirect, CSRF/state mismatch, cross-user read,
  and cached response tests.
- [ ] Browser `en-US` tetap Bahasa Indonesia.
- [ ] Lint, typecheck, test, build lulus.

## Definition of done

- Guest tidak pernah memperoleh private data atau Auth identity.
- Google web flow dan session cookie boundary siap secara lokal.
- Apple tidak muncul pada UI/runtime web.
- Role hanya berasal dari protected server state.
- Auth/profile/account journeys memiliki loading/error/offline/retry states.

## External gates

- Google web client/callback hosted dan domain production: Phase 12.
- SMTP/email production: tetap skipped sampai keputusan eksplisit.

