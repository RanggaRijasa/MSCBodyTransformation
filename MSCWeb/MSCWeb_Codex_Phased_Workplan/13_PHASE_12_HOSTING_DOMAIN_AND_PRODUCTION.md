# Phase 12: Hosting, Domain, and Production

> Status: BELUM DIMULAI

## Tujuan

Menyediakan production web pada domain milik pengguna, terhubung aman ke
hosted Supabase main, dengan OAuth, forward-only migration, backup, monitoring,
spend control, smoke test, dan rollback. Tidak ada purchase/deploy tanpa
persetujuan eksplisit.

## Rekomendasi default

- Hosting: Cloudflare Workers Paid melalui OpenNext.
- Backend: Supabase Pro hosted main.
- Domain Indonesia: `.id` melalui registrar terakreditasi PANDI.
- TLD global yang didukung: Cloudflare Registrar.
- Admin tetap satu origin di `/admin`.
- Supabase custom domain `api.*` opsional, bukan requirement launch.
- Vercel Pro hanya fallback bila compatibility gate Workers/OpenNext gagal.

Detail dan biaya ada di
`../docs/operations/HOSTING_DOMAIN_AND_ENVIRONMENTS.md`.

## External approval gates

Pengguna harus memberi approval terpisah sebelum:

- membeli domain/plan;
- membuat/menghubungkan Cloudflare Workers project;
- menambah production environment variables;
- mengubah DNS/nameserver/DNSSEC;
- mengubah Supabase Auth Site URL/redirect/provider;
- menjalankan migration/deploy Function/Storage/cron ke hosted main;
- menonaktifkan Apple provider/jobs/functions;
- mengaktifkan custom domain atau add-on berbayar;
- mengarahkan traffic/cutover.

## Slice 12.1 — Account/domain decision

- [ ] Pilih nama/TLD setelah availability, trademark, typo, premium, renewal,
  ownership, MFA, recovery, dan registrar review.
- [ ] Untuk `.id`, verifikasi registrar masih terakreditasi PANDI dan bandingkan
  renewal normal/support/DNSSEC/transfer, bukan promo saja.
- [ ] Beli domain atas account/identity pemilik yang benar setelah approval.
- [ ] Aktifkan MFA, recovery codes, auto-renew, contact verification.
- [ ] Pilih topology: apex app atau `app.`; rekomendasi satu app origin dan
  `/admin` yang sama.

## Slice 12.2 — Cloudflare Workers project/environments

- [ ] Provision Workers Paid, billing contact, alerts, dan limit yang tersedia.
- [ ] Hubungkan repository/production branch hanya setelah Git workflow
  pengguna disetujui.
- [ ] Build/deploy melalui `@opennextjs/cloudflare`; pin compatibility date,
  aktifkan `nodejs_compat`, dan review generated Worker bundle.
- [ ] Production gets hosted-main URL + publishable key only.
- [ ] Preview defaults to mock/public-safe mode; tidak mengunggah private data
  atau mutate hosted main di bawah strategi no-staging saat ini.
- [ ] Development memakai local Supabase.
- [ ] Atur compute/function region dekat Supabase hosted region bila applicable
  dan diverifikasi, bukan diasumsikan.
- [ ] Deployment protection dan log retention sesuai plan/policy.
- [ ] Lulus compatibility matrix SSR, Server Actions, cookies Auth,
  middleware/proxy, image, PWA, source maps, preview, dan rollback.
- [ ] Gunakan Vercel Pro hanya bila blocker compatibility dicatat dan fallback
  disetujui pengguna.

## Slice 12.3 — DNS/TLS

- [ ] Tambahkan zone/domain ke account Cloudflare milik pengguna.
- [ ] Jika registrar bukan Cloudflare, arahkan nameserver ke Cloudflare setelah
  record inventory dan approval.
- [ ] Hubungkan apex ke Worker melalui custom domain/route hasil inspection.
- [ ] Konfigurasikan apex/`www` redirect dan custom hostname chosen.
- [ ] Verifikasi TLS, renewal, HTTP->HTTPS, canonical URL, robots/noindex Admin,
  and security headers.
- [ ] Aktifkan/verifikasi DNSSEC setelah records stabil.
- [ ] Jangan menyalin contoh IP/CNAME tanpa project inspection.

## Slice 12.4 — Supabase/Auth production

- [ ] Snapshot/backup hosted main dan source hash sebelum mutation.
- [ ] Compare migration history/local/hosted; dry-run hanya forward migrations.
- [ ] Deploy manual-commerce schema/RLS/functions/storage policies dengan
  explicit approval, no reset/seed.
- [ ] Run hosted lint/advisors/grants/RLS/storage/function/cron redaction-safe
  checks.
- [ ] Google OAuth: web client origin, Supabase provider callback, Site URL,
  and app `/auth/callback` allowlist exact.
- [ ] Remove/retain legacy callbacks only through staged migration; do not break
  existing iOS identities prematurely.
- [ ] Email/password remains disabled unless Gate decision changes.
- [ ] `api.domain` custom domain only if add-on approved; add new OAuth callback
  before switching and keep old callback during verified transition.

## Slice 12.5 — Production data/operations

- [ ] Configure payment destinations through protected Admin operation.
- [ ] No real bank evidence in fixtures, logs, or screenshots.
- [ ] Verify cleanup/expiry recurring jobs and alerting.
- [ ] Legal/privacy/terms URLs updated for PWA, manual payment, retention,
  cookies, browser camera/storage, and account deletion.
- [ ] Data protection, backup, incident response, secret rotation, provider
  outage, payment dispute, and rollback runbooks signed off.

## Slice 12.6 — Smoke/acceptance

- [ ] Guest public reads.
- [ ] Google login/logout/relogin/cancel/account switch.
- [ ] Participant paid journey with controlled non-PII test data.
- [ ] Admin verifies evidence and activation occurs exactly once.
- [ ] Coach application/payment/activation/expiry test.
- [ ] Media/QR/submission/weight/leaderboard/Admin CMS critical journeys.
- [ ] Domain/browser/PWA install/update/offline/accessibility/device matrix.
- [ ] No secret/private data in client bundle, logs, cache, source maps.
- [ ] Rollback/fail-closed drill without destructive production reset.

## Definition of done

- Production domain/TLS/OAuth/Supabase integration works.
- Workers Paid, budget controls, backups, monitoring, and owner access are
  configured.
- Manual commerce hosted migration is secure, forward-only, and verified.
- Preview cannot accidentally mutate production.
- No Apple decommission yet unless separately approved and proven safe.

## Cost checkpoint

Re-verify immediately before purchase. Reference baseline 10 Agustus 2026:

```text
Cloudflare Workers Paid minimum USD 5/month + overage
Supabase Pro           USD 25/month + overage
Supabase custom domain USD 10/month optional
Domain                 annual registrar/registry price
```
