# Audit Definition of Done Phase 11

Tanggal penutupan lokal: 11 Agustus 2026  
Status: **SELESAI LOKAL**

## Ringkasan hasil

Phase 11 memenuhi seluruh Definition of Done engineering lokal. PWA memiliki
install state yang jujur, update eksplisit, offline fallback generik, cache
publik allowlisted, no-store untuk surface privat, dan pembersihan state akun.
Web Push masuk MVP sesuai keputusan user dengan permission contextual,
subscription owner/RLS, outbox, dispatcher aman, retry terbatas, dan copy tanpa
PII. Kandidat rilis juga memiliki accessibility, performance, security,
dependency, reliability, visual, serta regression evidence yang dapat diulang.

Tidak ada perubahan ke hosted Supabase, root `supabase/`, root `Contracts/`,
source iOS, DNS, domain, provider, atau Git state. Semua hasil disimpan hanya di
`MSCWeb/`.

## Pemetaan Definition of Done

| Definition of Done | Evidence | Hasil |
| --- | --- | --- |
| Install/update/offline predictable dan tanpa private cache | `public/sw.js`, `public/offline.html`, install/runtime state, account clear, Chromium E2E | Lulus |
| Critical accessibility issue zero | axe Chromium + WebKit untuk Guest/Peserta/Coach, light/dark/contrast/reduced motion/400%; route boundaries dan semantic UI | Lulus otomatis; manual owner checklist siap |
| Performance budget target mobile | route JS/CSS dan image budgets; LCP/CLS/INP pada Chromium 4× CPU dan slow network | Lulus |
| Threat matrix tanpa Critical/High terbuka | threat model, CSP nonce, HSTS plan, origin/CSRF defense, RLS, upload controls, rate limits, redaction | Lulus; residual production hanya Medium/Phase 12 |
| Device/browser evidence siap | Chromium/WebKit otomatis dan checklist iPhone/Android/Desktop/Firefox/AT terdokumentasi | Siap; eksekusi manual ditunda user dan non-blocking |
| Screenshot landing release candidate | fixture Peserta + Coach metadata-stripped, visual baseline, manifest metadata, HTML/security scan | Lulus |

## Verification yang dijalankan

- `pnpm test:phase11:local` — lulus:
  - Supabase lokal schema lint tanpa error.
  - 13/13 pgTAP security/push/rate-limit.
  - SBOM SPDX 2.3 berisi 127 paket production.
  - format, architecture, file-size, public-secret, localization, ESLint, dan
    TypeScript lulus.
  - 35 file test dengan 162 unit/component test lulus.
  - production build lulus; 40 static pages dihasilkan dan dynamic routes
    divalidasi.
  - budget route: landing 98,1 KiB; Peserta 108,0 KiB; Coach 99,8 KiB; Admin
    107,8 KiB gzip, seluruhnya di bawah budget.
  - PWA E2E 6 lulus dan 2 skip terencana karena service worker/CDP metrics
    khusus Chromium.
  - 4 visual landing dan 2 marketing release capture lulus.
- `pnpm test:phase10:local` — lulus sebagai regression gate:
  - 63 pgTAP, 48 focused unit/component, 7 local browser integration, dan 2
    cross-role Chromium/WebKit journey.
- `pnpm audit --prod --audit-level high` — tidak ada vulnerability yang
  diketahui pada saat audit.

## Perbaikan regresi selama closure

- Same-origin mutation gate kini memakai effective host/protocol sehingga
  request sah `127.0.0.1` tidak ditolak ketika Next.js menormalkan URL internal
  menjadi `localhost`; cross-site/malformed tetap gagal tertutup.
- Fixture tanggal antrean pembayaran memakai kalender Asia/Jakarta saat ini,
  bukan tanggal hard-coded.
- Hasil kuis server dipertahankan di UI dan tombol submit dikunci sehingga
  WebKit tidak kehilangan status `Lulus` akibat refresh Server Component yang
  selesai lebih cepat.

## Follow-up manual dan production

Owner akan menjalankan checklist HP/laptop di
`docs/testing/PHASE_11_BROWSER_DEVICE_EVIDENCE.md`. Sesuai instruksi user,
jadwal itu bukan blocker penutupan engineering Phase 11; setiap temuan
Critical/High tetap memblokir deployment Phase 12.

Input manual berikut baru diperlukan pada Phase 12:

- pasangan VAPID, subject operator, dan dispatcher secret;
- approval deploy migration/Edge Function/scheduler ke hosted production;
- domain, TLS, Cloudflare edge/WAF/rate rules, backup, dan rollback production.

Item berikutnya: Phase 12 — Hosting, Domain, and Production.
