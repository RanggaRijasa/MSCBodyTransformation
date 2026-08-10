# Phase 02A: Public Landing and Install CTA

> Status: SELESAI

## Tujuan

Membangun landing page publik yang menarik, cepat, accessible, SEO-ready, dan
memiliki install CTA adaptif tanpa mencampur marketing UI dengan aplikasi
Peserta, Coach, atau Admin.

## Prasyarat

- Phase 00 contract/decision baseline selesai.
- Phase 01 scaffold dan test harness selesai.
- Phase 02 tokens serta shared primitives yang dibutuhkan selesai.
- Baca `../docs/design/LANDING_PAGE_DESIGN_AND_CONTENT.md`.
- Tidak memerlukan hosted Supabase mutation atau production deployment.

## Batas phase

Phase ini membangun page, content, responsive layout, dan install state seam.
Manifest/service worker/installability final tetap diselesaikan Phase 11.
Sebelum gate Phase 11 lulus, CTA wajib jatuh ke `Gunakan di browser` atau
petunjuk yang benar; tidak boleh memalsukan keberhasilan pemasangan.

## Slice 02A.1 — Route dan module boundary

- [x] Tetapkan `/` sebagai landing page publik pada route group `(marketing)`.
- [x] Pertahankan `/hari-ini` sebagai entry aplikasi Peserta.
- [x] Buat `features/landing` dan `features/pwa-install` terpisah.
- [x] Landing component tidak mengimpor repository/auth internals secara
  langsung; session-aware CTA melalui boundary kecil dan fail closed.
- [x] PWA `start_url` target `/hari-ini`, scope `/`; final gate Phase 11.
- [x] Signed-in actor dapat membuka destination role tanpa memaksa redirect
  dari landing yang merusak shareable public URL.

## Slice 02A.2 — Header dan hero

- [x] Header desktop/mobile, skip link, wordmark, section nav, `Masuk`, install.
- [x] Hero memakai copy yang telah disetujui dan satu CTA primary merah.
- [x] `Lihat program` menuju public catalog/section dengan focus/scroll benar.
- [x] Trust copy `Gratis dipasang • Tanpa App Store` tidak menjadi store badge.
- [x] Responsive hero media memakai asset berizin/approved; tidak memakai
  before/after, hasil palsu, atau mockup ImageGen mentah sebagai production UI.
- [x] Selama PWA belum selesai, gunakan placeholder berlabel
  `Pratinjau aplikasi` dengan aspect ratio/dimensi stabil.
- [x] Placeholder tidak boleh meniru fitur di luar contract atau memakai
  screenshot iOS seolah-olah merupakan PWA final.
- [x] Catat replacement owner: screenshot Peserta/Coach/Admin asli diganti
  setelah layar terkait lulus parity Phase 10 dan quality gate Phase 11.
- [x] Above-the-fold CTA tetap muncul tanpa JavaScript.

## Slice 02A.3 — Content sections

- [x] Benefits: Program terstruktur, Didampingi Coach, Progres lebih jelas.
- [x] Cara mulai: pilih program, QR Coach, bukti transfer, approval.
- [x] Section Peserta dan Coach hanya menjanjikan capability authoritative.
- [x] Install callout kedua setelah value/product preview.
- [x] FAQ native semantic disclosure dan footer legal/support.
- [x] Tidak ada testimoni, rating, statistik, jumlah peserta, credential Coach,
  atau hasil transformasi tanpa evidence/approval.
- [x] Semua production copy masuk katalog i18n Bahasa Indonesia.

## Slice 02A.4 — Install CTA state machine

- [x] Buat typed states: prompt-ready, iOS-guidance, manual-guidance,
  standalone, unsupported, dan not-ready.
- [x] Chromium menangkap `beforeinstallprompt`, menyimpan hanya reference in
  memory, lalu memanggil `prompt()` setelah user gesture.
- [x] iOS membuka accessible instruction sheet untuk Share/Add to Home Screen;
  jangan memanggil API yang tidak tersedia.
- [x] Standalone memakai `display-mode`/platform signals yang diuji dan
  mengganti CTA menjadi `Buka aplikasi`.
- [x] Unsupported/not-ready memakai `Gunakan di browser`, bukan tombol mati
  tanpa penjelasan.
- [x] Setelah accepted/dismissed, state diperbarui tanpa prompt loop agresif.
- [x] Install CTA header, hero, dan sticky bar memakai satu controller/state,
  bukan tiga implementasi terpisah.
- [x] Sticky mobile bar hanya muncul setelah hero CTA tidak terlihat dan tidak
  menutup focus target, cookie/legal UI, keyboard, atau safe area.

## Slice 02A.5 — Public data dan session behavior

- [x] Landing dapat render tanpa login dan tanpa private data.
- [x] Program teaser hanya memakai DTO public-safe dan explicit allowlist.
- [x] Public Coach teaser hanya approved/visible fields.
- [x] Session state hanya mengadaptasi `Masuk`/`Buka aplikasi`; authenticated
  HTML tidak boleh masuk shared public CDN cache.
- [x] Role destination: Peserta `/hari-ini`, Coach `/coach-area`, Admin
  `/admin`; server authoritative role tetap menentukan akses.
- [x] Repository error menampilkan landing statis dan CTA aman, bukan raw error.

## Slice 02A.6 — SEO, metadata, dan sharing

- [x] Title/description/canonical/Open Graph dalam Bahasa Indonesia.
- [x] Public sitemap dan robots exclusions untuk Auth/Admin/private routes.
- [x] Structured data hanya fakta yang diverifikasi.
- [x] Buat social image terpisah dengan safe-area dan copy approved.
- [x] Tidak ada session, query sensitif, atau tracking ID dalam canonical/share.

## Slice 02A.7 — Accessibility dan performance

- [x] Landmarks, heading order, accessible names, keyboard/focus, skip link.
- [x] Install instruction sheet focus trap/restore/Escape/live announcement.
- [x] 320 px, 200%/400% zoom relevant, large text, reduced motion, contrast.
- [x] Responsive image dimensions mencegah CLS dan menghindari oversized hero.
- [x] Route bundle dipisah dari Admin/Peserta/Coach code yang tidak diperlukan.
- [x] Tetapkan dan ukur LCP/CLS/INP serta JS/image budget bersama Phase 11.
- [x] Landing usable pada network lambat dan ketika public teaser gagal.

## Slice 02A.8 — Tests

- [x] Unit test seluruh transition install state machine.
- [x] Component test CTA labels/actions per capability.
- [x] Test hero/FAQ/navigation/sticky CTA keyboard dan accessibility.
- [x] E2E Chromium dengan mocked `beforeinstallprompt` accepted/dismissed.
- [x] E2E WebKit untuk guidance fallback tanpa custom prompt.
- [x] Screenshot regression desktop/mobile light/dark/large text.
- [x] Test anonymous response tidak mengandung private payload/cache header.
- [x] Test signed-in role CTA tanpa mempercayai client-supplied role.

## Phase 11 handoff

Butir berikut sengaja tetap terbuka sebagai gate Phase 11/13 dan tidak
menyatakan pekerjaan Phase 02A belum selesai. Owner dan budget tercatat di
`docs/design/PHASE_02A_LANDING_AND_INSTALL_HANDOFF.md`.

- [ ] Manifest final memenuhi installability criteria.
- [ ] Service worker/update/offline private-cache policy lulus.
- [ ] Physical iPhone install instruction diverifikasi terhadap UI aktual.
- [ ] Physical Android/desktop Chromium custom prompt diverifikasi.
- [ ] Installed standalone launch memakai `/hari-ini` dan role gate benar.
- [ ] Install analytics, bila disetujui, memakai allowlist tanpa PII.
- [ ] Ganti seluruh placeholder preview dengan screenshot dari release
  candidate PWA yang lulus parity; jangan capture dari iOS atau ImageGen.
- [ ] Screenshot memakai deterministic marketing fixture tanpa PII, berat,
  QR mentah, payment evidence, private photo, signed URL, atau production data.
- [ ] Audit bahwa tidak ada label/asset placeholder tertinggal sebelum cutover.

## Commands minimum

```text
pnpm lint
pnpm typecheck
pnpm test -- landing pwa-install
pnpm test:e2e --project=chromium --grep landing
pnpm test:e2e --project=webkit --grep landing
pnpm build
```

Nama filter test disesuaikan dengan runner Phase 01; jangan mengklaim command
lulus sebelum benar-benar tersedia dan dijalankan.

## Definition of done

- Landing menarik, modular, responsive, accessible, dan public-safe.
- CTA install jelas tetapi selalu sesuai capability browser yang nyata.
- Halaman dan aplikasi berada dalam satu repo/origin tanpa coupling feature.
- Tidak ada klaim, testimoni, statistik, atau private data yang tidak sah.
- SEO/share metadata dan route/cache boundaries lulus test.
- Placeholder memiliki owner penggantian; release tidak memakai placeholder
  tanpa label atau persetujuan eksplisit.
- Handoff installability ke Phase 11 terdokumentasi.

## Progress log

Catat files, copy changes, asset provenance, viewport/screenshots, commands,
hasil accessibility/performance, asumsi, dan remaining Phase 11 gates.

### 10 Agustus 2026 — selesai

- Files: route group `(marketing)`, landing sections/header/footer/legal-safe
  placeholders, `features/landing`, typed `features/pwa-install`, CSS feature,
  metadata/robots/sitemap/ImageResponse social images, public DTO/session
  boundaries, i18n copy, unit/component/E2E/visual tests, dan handoff Phase 11.
- Copy: memakai baseline approved tanpa testimoni, rating, statistik, hasil,
  atau credential yang tidak terverifikasi. Footer legal/help menuju halaman
  noindex yang jujur tentang status lokal sampai kebijakan resmi disetujui.
- Asset provenance: hero adalah CSS placeholder berlabel, tanpa raster/iOS/
  ImageGen. Social image dibentuk deterministik dari approved copy. Replacement
  owner Phase 10–11 dan batas privacy dicatat pada dokumen handoff.
- Screenshots: Chromium 1440×1000 desktop light full-page; 390×844 mobile light
  dan dark; 320×900 large text 200%. Baseline diperbarui, diperiksa visual, dan
  dibandingkan ulang tanpa update.
- Accessibility/privacy: Axe tanpa serious/critical, focus anchor dan dialog
  pulih, Escape/history lulus, 320px + zoom 400% tanpa overflow diuji stabil
  5× per browser, query `role=admin` diabaikan, HTML anonim tanpa private keys,
  dan response landing tidak shared-cache personalized HTML.
- Install: enam state typed diuji; Chromium accepted/dismissed mengonsumsi
  prompt satu kali; WebKit iPhone guidance dan standalone display-mode lulus.
- Commands: `corepack pnpm lint`, `typecheck`, `test` (43/43), `build`,
  `test:e2e`, visual update/compare, focused smoke lintas Chromium/WebKit, serta
  `git diff --check`. Seluruh command memakai Node 24 path yang dipin.
- Build: lulus; `/` dynamic fail-closed, marketing info routes/metadata images/
  robots/sitemap terbentuk, `/hari-ini` dan tiga role shell tetap terpisah.
- Remaining blockers: tidak ada untuk Phase 02A. Gate service worker, device
  fisik, Core Web Vitals production, domain, kebijakan legal final, dan capture
  release-candidate tetap milik Phase 11–13.
