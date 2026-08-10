# Phase 02A: Public Landing and Install CTA

> Status: BELUM DIMULAI

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

- [ ] Tetapkan `/` sebagai landing page publik pada route group `(marketing)`.
- [ ] Pertahankan `/hari-ini` sebagai entry aplikasi Peserta.
- [ ] Buat `features/landing` dan `features/pwa-install` terpisah.
- [ ] Landing component tidak mengimpor repository/auth internals secara
  langsung; session-aware CTA melalui boundary kecil dan fail closed.
- [ ] PWA `start_url` target `/hari-ini`, scope `/`; final gate Phase 11.
- [ ] Signed-in actor dapat membuka destination role tanpa memaksa redirect
  dari landing yang merusak shareable public URL.

## Slice 02A.2 — Header dan hero

- [ ] Header desktop/mobile, skip link, wordmark, section nav, `Masuk`, install.
- [ ] Hero memakai copy yang telah disetujui dan satu CTA primary merah.
- [ ] `Lihat program` menuju public catalog/section dengan focus/scroll benar.
- [ ] Trust copy `Gratis dipasang • Tanpa App Store` tidak menjadi store badge.
- [ ] Responsive hero media memakai asset berizin/approved; tidak memakai
  before/after, hasil palsu, atau mockup ImageGen mentah sebagai production UI.
- [ ] Selama PWA belum selesai, gunakan placeholder berlabel
  `Pratinjau aplikasi` dengan aspect ratio/dimensi stabil.
- [ ] Placeholder tidak boleh meniru fitur di luar contract atau memakai
  screenshot iOS seolah-olah merupakan PWA final.
- [ ] Catat replacement owner: screenshot Peserta/Coach/Admin asli diganti
  setelah layar terkait lulus parity Phase 10 dan quality gate Phase 11.
- [ ] Above-the-fold CTA tetap muncul tanpa JavaScript.

## Slice 02A.3 — Content sections

- [ ] Benefits: Program terstruktur, Didampingi Coach, Progres lebih jelas.
- [ ] Cara mulai: pilih program, QR Coach, bukti transfer, approval.
- [ ] Section Peserta dan Coach hanya menjanjikan capability authoritative.
- [ ] Install callout kedua setelah value/product preview.
- [ ] FAQ native semantic disclosure dan footer legal/support.
- [ ] Tidak ada testimoni, rating, statistik, jumlah peserta, credential Coach,
  atau hasil transformasi tanpa evidence/approval.
- [ ] Semua production copy masuk katalog i18n Bahasa Indonesia.

## Slice 02A.4 — Install CTA state machine

- [ ] Buat typed states: prompt-ready, iOS-guidance, manual-guidance,
  standalone, unsupported, dan not-ready.
- [ ] Chromium menangkap `beforeinstallprompt`, menyimpan hanya reference in
  memory, lalu memanggil `prompt()` setelah user gesture.
- [ ] iOS membuka accessible instruction sheet untuk Share/Add to Home Screen;
  jangan memanggil API yang tidak tersedia.
- [ ] Standalone memakai `display-mode`/platform signals yang diuji dan
  mengganti CTA menjadi `Buka aplikasi`.
- [ ] Unsupported/not-ready memakai `Gunakan di browser`, bukan tombol mati
  tanpa penjelasan.
- [ ] Setelah accepted/dismissed, state diperbarui tanpa prompt loop agresif.
- [ ] Install CTA header, hero, dan sticky bar memakai satu controller/state,
  bukan tiga implementasi terpisah.
- [ ] Sticky mobile bar hanya muncul setelah hero CTA tidak terlihat dan tidak
  menutup focus target, cookie/legal UI, keyboard, atau safe area.

## Slice 02A.5 — Public data dan session behavior

- [ ] Landing dapat render tanpa login dan tanpa private data.
- [ ] Program teaser hanya memakai DTO public-safe dan explicit allowlist.
- [ ] Public Coach teaser hanya approved/visible fields.
- [ ] Session state hanya mengadaptasi `Masuk`/`Buka aplikasi`; authenticated
  HTML tidak boleh masuk shared public CDN cache.
- [ ] Role destination: Peserta `/hari-ini`, Coach `/coach-area`, Admin
  `/admin`; server authoritative role tetap menentukan akses.
- [ ] Repository error menampilkan landing statis dan CTA aman, bukan raw error.

## Slice 02A.6 — SEO, metadata, dan sharing

- [ ] Title/description/canonical/Open Graph dalam Bahasa Indonesia.
- [ ] Public sitemap dan robots exclusions untuk Auth/Admin/private routes.
- [ ] Structured data hanya fakta yang diverifikasi.
- [ ] Buat social image terpisah dengan safe-area dan copy approved.
- [ ] Tidak ada session, query sensitif, atau tracking ID dalam canonical/share.

## Slice 02A.7 — Accessibility dan performance

- [ ] Landmarks, heading order, accessible names, keyboard/focus, skip link.
- [ ] Install instruction sheet focus trap/restore/Escape/live announcement.
- [ ] 320 px, 200%/400% zoom relevant, large text, reduced motion, contrast.
- [ ] Responsive image dimensions mencegah CLS dan menghindari oversized hero.
- [ ] Route bundle dipisah dari Admin/Peserta/Coach code yang tidak diperlukan.
- [ ] Tetapkan dan ukur LCP/CLS/INP serta JS/image budget bersama Phase 11.
- [ ] Landing usable pada network lambat dan ketika public teaser gagal.

## Slice 02A.8 — Tests

- [ ] Unit test seluruh transition install state machine.
- [ ] Component test CTA labels/actions per capability.
- [ ] Test hero/FAQ/navigation/sticky CTA keyboard dan accessibility.
- [ ] E2E Chromium dengan mocked `beforeinstallprompt` accepted/dismissed.
- [ ] E2E WebKit untuk guidance fallback tanpa custom prompt.
- [ ] Screenshot regression desktop/mobile light/dark/large text.
- [ ] Test anonymous response tidak mengandung private payload/cache header.
- [ ] Test signed-in role CTA tanpa mempercayai client-supplied role.

## Phase 11 handoff

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
