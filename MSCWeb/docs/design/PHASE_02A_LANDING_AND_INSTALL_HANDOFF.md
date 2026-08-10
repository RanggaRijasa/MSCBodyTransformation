# Phase 02A Landing and Install Handoff

## Boundary dan asset provenance

- `/` adalah landing publik di route group `(marketing)`; `/hari-ini` tetap
  entry aplikasi Peserta.
- Hero menggunakan CSS product-preview placeholder berlabel
  `Pratinjau aplikasi`. Tidak ada screenshot iOS, ImageGen, data production,
  foto orang, atau raster marketing yang dipakai.
- Open Graph dan Twitter image dibuat deterministik oleh Next `ImageResponse`
  dari approved copy. Warna inline diperlukan karena image route tidak dapat
  membaca CSS custom properties; nilainya mengikuti token brand Phase 02.
- Owner penggantian placeholder: Phase 10 menyediakan layar parity Peserta,
  Coach, dan Admin; Phase 11 menangkap release-candidate PWA dengan fixture
  marketing non-PII dan mengganti placeholder setelah visual/privacy review.
- Landing tidak memuat enrollment, bukti pembayaran, berat, foto privat, QR,
  signed URL, session token, email privat, atau jumlah enrollment.

## Install readiness

Controller mendukung state `prompt-ready`, `ios-guidance`,
`manual-guidance`, `standalone`, `unsupported`, dan `not-ready`. Gate
install-readiness tetap tertutup sampai Phase 11:

- event `beforeinstallprompt` nyata dapat mengaktifkan custom prompt setelah
  user gesture dan hanya disimpan in-memory;
- iPhone/iPad mendapat petunjuk Safari yang accessible;
- standalone membuka destination actor yang diberikan boundary server;
- browser lain mendapat `Gunakan di browser`, bukan keberhasilan palsu;
- prompt yang accepted atau dismissed dikonsumsi satu kali tanpa loop.

## Performance budget menuju Phase 11

Target release-candidate yang harus diukur ulang dari production build:

| Metrik | Budget |
|---|---:|
| LCP p75 mobile | ≤ 2,5 detik |
| CLS p75 | ≤ 0,10 |
| INP p75 | ≤ 200 ms |
| JavaScript initial landing, Brotli | ≤ 170 KB |
| Hero raster final | ≤ 180 KB |
| Social image | ≤ 300 KB |

Phase 02A menghilangkan hero raster dan mengunci aspect ratio placeholder,
memisahkan module landing dari shell role, serta menjaga hero copy/CTA tetap
ada pada server HTML. Lighthouse/WebPageTest, throttling production, bundle
compression, dan real-device Core Web Vitals adalah gate Phase 11.

## Phase 11/13 manual gates

- Verifikasi instruksi aktual pada iPhone fisik dan Add to Home Screen.
- Verifikasi custom prompt pada Android dan desktop Chromium fisik.
- Aktifkan service worker, offline/update policy, dan private-cache audit.
- Pastikan standalone launch ke `/hari-ini` melalui authoritative role gate.
- Ganti placeholder dengan capture PWA release candidate tanpa PII.
- Isi `NEXT_PUBLIC_SITE_URL` dengan origin produksi saat Phase 12 diberi izin.
- Tinjau dan setujui URL Privasi, Ketentuan, dan Bantuan sebelum deployment.
