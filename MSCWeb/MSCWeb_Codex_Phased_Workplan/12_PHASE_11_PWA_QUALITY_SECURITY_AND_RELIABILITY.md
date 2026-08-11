# Phase 11: PWA Quality, Security, and Reliability

> Status: SELESAI LOKAL — 11 Agustus 2026

## Tujuan

Mengeraskan aplikasi lengkap sebagai PWA yang installable, accessible,
performant, privacy-safe, update-safe, dan reliable pada browser/perangkat
target sebelum menyentuh production hosting.

## Slice 11.1 — Install dan standalone

- [x] Final manifest name/short name/start URL/scope/display/theme/icons.
- [x] Maskable/standard icons, favicon, screenshots bila dibutuhkan.
- [x] HTTPS local test path dan install guidance.
- [x] Safari iOS Add to Home Screen instructions; jangan bergantung pada
  `beforeinstallprompt` yang tidak cross-platform.
- [x] Hubungkan install state machine landing Phase 02A ke manifest/service
  worker final; CTA tidak boleh menampilkan state sukses palsu.
- [x] Chromium custom prompt, iOS/manual guidance, unsupported, dismissed, dan
  already-standalone state lulus pada CTA header/hero/sticky.
- [x] Standalone launch/state, deep-link, logout/account switch, safe-area, dan
  theme memiliki gate otomatis; resume/rotation/status bar masuk checklist
  owner perangkat yang eksplisit non-blocking.

## Slice 11.2 — Service worker/cache/update

- [x] Pilih custom service worker atau dependency melalui verified spike.
- [x] Cache fingerprinted static assets/public-safe shell saja.
- [x] `no-store`/network policy untuk authenticated HTML, Auth callback,
  Supabase responses, signed URLs, QR payload, weight, answers, payment
  evidence, and private media.
- [x] Cache versioning, activation, stale asset removal, update available UI,
  reload timing, rollback, and multi-tab coordination.
- [x] Logout/account switch clears user-related memory/cache.
- [x] Offline mutation gagal actionable; tidak menampilkan success palsu.

## Slice 11.3 — Offline/recovery

- [x] Explicit online/offline state and retry.
- [x] Public shell/catalog fallback hanya bila payload benar-benar public-safe
  dan freshness policy disetujui.
- [x] Upload interruption/resume/cancel/orphan cleanup.
- [x] Session expiry while offline and reauthentication on reconnect.
- [x] Background sync/offline drafts tetap ditunda kecuali privacy/reliability
  spike membuktikan kebutuhan dan mendapat approval.
- [x] Push notification masuk MVP sesuai keputusan user GATE-011; permission
  hanya diminta contextually dari Pengaturan.

## Slice 11.4 — Accessibility

- [x] Semantic headings/landmarks/forms/tables/dialogs/live regions.
- [x] Keyboard path seluruh Guest/Peserta/Coach/Admin memiliki gate otomatis dan
  checklist owner untuk browser/perangkat fisik.
- [x] Screen reader labels/order/status/action.
- [x] Focus restore on route/dialog/error.
- [x] Zoom 200%/400% relevant, text wrapping Bahasa Indonesia, touch targets.
- [x] Dark/light, contrast, reduced motion, color-independent states.
- [x] Camera/media/QR/payment evidence controls accessible.

## Slice 11.5 — Performance

- [x] Tetapkan budgets untuk JS per route, images, LCP, CLS, INP, API calls.
- [x] Route/feature code splitting dan client boundary audit.
- [x] Images/thumbnails/lazy content/video strategy tanpa private CDN leak.
- [x] Program panjang, Admin list, leaderboard scale tests.
- [x] No giant context/store rerendering all roles.
- [x] Vitals diuji pada mid-range mobile throttling dan network lambat.

## Slice 11.6 — Security/privacy

- [x] Threat model Auth, role, payment, upload, QR, media, Admin, service worker.
- [x] CSP, HSTS plan, frame ancestors, referrer, MIME, permissions policy,
  CSRF/OAuth state, input/output encoding, open redirect.
- [x] Route guard + RLS + protected operation defense in depth.
- [x] File upload signature/size/decompression/metadata/path controls.
- [x] Dependency/license/audit/SBOM and secret scan.
- [x] Cache/log/telemetry redaction and retention.
- [x] Rate limits/abuse for Auth, QR validation, upload, payment order/review,
  submission, and Admin search.

## Slice 11.7 — Reliability/observability

- [x] Typed failures validation/auth/offline/timeout/conflict/unknown.
- [x] Retry/backoff/cancellation and idempotency matrix.
- [x] Error boundaries per shell/route without exposing raw backend errors.
- [x] Allowlisted metrics/logs/correlation IDs no PII.
- [x] Backup/incident/rollback/update failure runbooks.
- [x] Observability vendor tidak dipasang untuk MVP; tetap memerlukan approval
  privacy/dependency terpisah bila diajukan kemudian.

## Slice 11.8 — Landing screenshot finalization

- [x] Capture PWA release candidate memakai fixture dan metadata Phase 10.
- [x] Ganti placeholder hero/feature dengan screenshot PWA final yang dipilih.
- [x] Optimalkan format, responsive source, dimensions, alt text, dan focal
  point tanpa membuat teks UI utama bergantung pada raster.
- [x] Bandingkan screenshot terhadap build final setelah setiap perubahan UI
  material; recapture bila sudah tidak representatif.
- [x] Verifikasi source asset dan rendered HTML tidak mengandung PII, private
  URL, identifier, atau metadata sensitif.
- [x] Hapus label placeholder hanya setelah replacement dan review benar-benar
  lulus; bila tetap placeholder, wajib dilabeli dan memerlukan approval launch.

## Verification matrix

- [x] Chromium dan WebKit smoke otomatis lulus; Firefox binary tidak tersedia
  lokal dan smoke Firefox diserahkan lewat checklist owner non-blocking.
- [x] Physical iPhone Safari browser + installed PWA: checklist owner siap;
  eksekusi ditunda user dan bukan blocker completion engineering.
- [x] Physical Android Chrome browser + installed PWA: checklist owner siap;
  eksekusi ditunda user dan bukan blocker completion engineering.
- [x] Desktop Chrome/Safari/Firefox Admin: Chrome/Safari otomatis lulus;
  checklist owner termasuk Firefox siap dan eksekusi manual ditunda user.
- [x] Lighthouse/PWA automated checks treated as supporting evidence, not sole
  accessibility/performance proof.
- [x] Axe lulus; manual keyboard/screen reader disiapkan sebagai checklist owner
  yang secara eksplisit non-blocking.
- [x] Offline/update/stale-cache/logout/account-switch E2E.
- [x] Security regression and dependency/secret scan.
- [x] Full lint/typecheck/unit/integration/E2E/build lulus.

## Definition of done

- Install/update/offline behavior predictable and no private cache.
- Critical accessibility issue zero.
- Performance budgets lulus on target mobile.
- Security threat matrix has no unresolved critical/high issue.
- Device/browser evidence siap untuk production phase.
- Screenshot landing berasal dari PWA release candidate atau placeholder masih
  diberi label serta memiliki approval launch eksplisit.

## Gate perubahan desain landing setelah Phase 11

Gate ini wajib dipakai oleh task/chat baru yang mengubah frontend landing
setelah Phase 11 berstatus `SELESAI LOKAL`. Perubahan diperbolehkan sebelum
Phase 12, tetapi evidence Phase 11 tidak boleh dianggap masih mutakhir tanpa
regression check berikut.

### Scope dan status

- Seluruh perubahan tetap hanya di `MSCWeb/`; perubahan desain landing tidak
  memberi izin mengubah root `supabase`, `Contracts`, source iOS, hosted main,
  DNS, domain, atau deployment.
- Baca Phase 02A, `docs/design/LANDING_PAGE_DESIGN_AND_CONTENT.md`, UI reference
  iOS, baseline visual saat ini, serta gate Phase 11 sebelum mengedit.
- Hero, navigation, section order, responsive CSS, typography, color, copy,
  screenshot/asset, metadata, install CTA, route, atau dependency frontend
  dihitung sebagai perubahan material.
- Saat perubahan material mulai diterapkan, catat sebagai regression work yang
  sedang berjalan. Status `SELESAI LOKAL` hanya boleh dipertahankan/dipulihkan
  setelah gate relevan lulus dan progress log baru ditambahkan.
- Perubahan visual-only tidak memerlukan Colima/Supabase. Nyalakan backend lokal
  hanya bila task turut menyentuh Auth, role-aware CTA, repository, atau journey
  data; hosted Supabase tetap dilarang tanpa approval Phase 12.

### Requirement desain yang tidak boleh regresi

- `/` tetap landing publik dan `/hari-ini` tetap entry aplikasi.
- CTA install tetap jelas, truthful, dan adaptif untuk Chromium, iPhone manual
  guidance, unsupported, dismissed, serta already-standalone state.
- Landing tetap usable pada mobile/desktop, light/dark, reduced motion, high
  contrast, keyboard, screen reader, zoom 200%/400%, dan viewport 320 px.
- Touch target, focus, heading hierarchy, dialog, wrapping Bahasa Indonesia,
  safe area, dan status tanpa color-only cue tetap lulus.
- Tidak boleh ada PII, private URL, QR mentah, berat, payment evidence, signed
  URL, production data, atau metadata sensitif pada copy/HTML/asset/screenshot.
- Perubahan copy tidak boleh menambah klaim hasil, statistik, testimoni, harga,
  kebijakan, atau status install yang tidak memiliki source/approval.
- Jangan menghapus atau mem-bypass PWA runtime/provider, manifest, service
  worker, cache/privacy policy, route boundary, dan security headers demi UI.

### Verification minimum setiap perubahan visual

Jalankan dari `MSCWeb/` dengan Node/pnpm yang dipin:

```text
corepack pnpm format:check
corepack pnpm lint
corepack pnpm typecheck
corepack pnpm exec vitest run tests/component/landing-and-install.test.tsx tests/unit/landing-boundaries.test.ts tests/unit/pwa-install-state.test.ts
corepack pnpm build
corepack pnpm check:phase11:performance
corepack pnpm exec playwright test tests/e2e/phase02a-landing.smoke.spec.ts --project=chromium
corepack pnpm exec playwright test tests/e2e/phase02a-landing.smoke.spec.ts --project=webkit
corepack pnpm exec playwright test tests/e2e/phase02a-landing.visual.spec.ts --project=chromium
```

- Update visual snapshot hanya bila perbedaan memang dimaksudkan. Inspect hasil
  desktop light, mobile light/dark, dan 320 px large text secara visual; jangan
  menerima snapshot baru secara buta hanya agar test hijau.
- Untuk perubahan visual yang disetujui, jalankan command visual yang sama
  dengan `--update-snapshots`, inspect seluruh PNG hasilnya, lalu jalankan ulang
  tanpa flag tersebut untuk membuktikan baseline baru stabil.
- Jika layout yang menampilkan screenshot kandidat rilis berubah, verifikasi
  ulang `public/images/pwa-participant-rc-v1.jpg` dan
  `public/images/pwa-coach-rc-v1.jpg` masih representatif, tidak terdistorsi,
  responsive, memiliki alt text benar, dan bebas data sensitif. Recapture hanya
  bila isi screenshot aplikasi sudah tidak mewakili build aktual.
- Catat file, alasan desain, viewport yang diperiksa, snapshot yang berubah,
  command/result, dan remaining manual-device evidence pada progress log.

### Full regression trigger

Jalankan `corepack pnpm test` dan `corepack pnpm test:phase11:local` bila
perubahan menyentuh install CTA/provider/state, manifest, service worker,
offline/update, navigation/route boundary, session-aware content, dependency,
security/cache header, atau restrukturisasi landing yang luas. Full local gate
memerlukan Colima dan Supabase lokal; tidak pernah memakai hosted main.

Setiap failure accessibility, PWA, privacy, security, performance, build, atau
visual yang belum dijelaskan memblokir Phase 12. Jangan menandai regression
selesai hanya karena desain terlihat benar pada satu browser atau viewport.

## Progress log — 11 Agustus 2026

- Files changed: implementasi install/runtime PWA, service worker/offline,
  Web Push MVP, abuse controls, security headers/origin gate, error boundaries,
  observability aman, landing release screenshots, test/gate scripts, dan
  dokumen security/performance/reliability/evidence; seluruhnya di `MSCWeb/`.
- Assumptions: pengujian manual HP/laptop dijalankan owner kemudian dan bukan
  blocker sesuai instruksi user; hosted Supabase, DNS, domain, secret VAPID,
  deployment Edge Function, serta scheduler tetap Phase 12.
- Build command: `pnpm build` melalui `pnpm test:phase11:local` — lulus, 40
  static pages terbangun dan seluruh dynamic route tervalidasi.
- Test command: `pnpm test:phase11:local` — lulus; 13 pgTAP, 162
  unit/component, 6 PWA E2E lulus + 2 engine-specific skip, 4 visual, dan 2
  release capture. `pnpm test:phase10:local` juga lulus sebagai regresi penuh.
- Security/dependency: secret/security gate dan SPDX 127 paket lulus;
  `pnpm audit --prod --audit-level high` melaporkan tidak ada vulnerability
  yang diketahui.
- Remaining blockers: tidak ada blocker lokal Phase 11. Konfigurasi produksi
  dan checklist perangkat owner didokumentasikan untuk follow-up.
