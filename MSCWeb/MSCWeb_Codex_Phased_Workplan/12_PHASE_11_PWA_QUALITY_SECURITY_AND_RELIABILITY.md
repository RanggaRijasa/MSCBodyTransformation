# Phase 11: PWA Quality, Security, and Reliability

> Status: BELUM DIMULAI

## Tujuan

Mengeraskan aplikasi lengkap sebagai PWA yang installable, accessible,
performant, privacy-safe, update-safe, dan reliable pada browser/perangkat
target sebelum menyentuh production hosting.

## Slice 11.1 — Install dan standalone

- [ ] Final manifest name/short name/start URL/scope/display/theme/icons.
- [ ] Maskable/standard icons, favicon, screenshots bila dibutuhkan.
- [ ] HTTPS local test path dan install guidance.
- [ ] Safari iOS Add to Home Screen instructions; jangan bergantung pada
  `beforeinstallprompt` yang tidak cross-platform.
- [ ] Hubungkan install state machine landing Phase 02A ke manifest/service
  worker final; CTA tidak boleh menampilkan state sukses palsu.
- [ ] Chromium custom prompt, iOS/manual guidance, unsupported, dismissed, dan
  already-standalone state lulus pada CTA header/hero/sticky.
- [ ] Installed standalone launch, resume, deep link, rotation, safe-area,
  status bar/theme, logout/account switch.

## Slice 11.2 — Service worker/cache/update

- [ ] Pilih custom service worker atau dependency melalui verified spike.
- [ ] Cache fingerprinted static assets/public-safe shell saja.
- [ ] `no-store`/network policy untuk authenticated HTML, Auth callback,
  Supabase responses, signed URLs, QR payload, weight, answers, payment
  evidence, and private media.
- [ ] Cache versioning, activation, stale asset removal, update available UI,
  reload timing, rollback, and multi-tab coordination.
- [ ] Logout/account switch clears user-related memory/cache.
- [ ] Offline mutation gagal actionable; tidak menampilkan success palsu.

## Slice 11.3 — Offline/recovery

- [ ] Explicit online/offline state and retry.
- [ ] Public shell/catalog fallback hanya bila payload benar-benar public-safe
  dan freshness policy disetujui.
- [ ] Upload interruption/resume/cancel/orphan cleanup.
- [ ] Session expiry while offline and reauthentication on reconnect.
- [ ] Background sync/offline drafts tetap ditunda kecuali privacy/reliability
  spike membuktikan kebutuhan dan mendapat approval.
- [ ] Push notification diputuskan lewat GATE-011; permission hanya contextually.

## Slice 11.4 — Accessibility

- [ ] Semantic headings/landmarks/forms/tables/dialogs/live regions.
- [ ] Keyboard-only seluruh Guest/Peserta/Coach/Admin journeys.
- [ ] Screen reader labels/order/status/action.
- [ ] Focus restore on route/dialog/error.
- [ ] Zoom 200%/400% relevant, text wrapping Bahasa Indonesia, touch targets.
- [ ] Dark/light, contrast, reduced motion, color-independent states.
- [ ] Camera/media/QR/payment evidence controls accessible.

## Slice 11.5 — Performance

- [ ] Tetapkan budgets untuk JS per route, images, LCP, CLS, INP, API calls.
- [ ] Route/feature code splitting dan client boundary audit.
- [ ] Images/thumbnails/lazy content/video strategy tanpa private CDN leak.
- [ ] Program panjang, Admin list, leaderboard scale tests.
- [ ] No giant context/store rerendering all roles.
- [ ] Vitals diuji pada mid-range mobile throttling dan network lambat.

## Slice 11.6 — Security/privacy

- [ ] Threat model Auth, role, payment, upload, QR, media, Admin, service worker.
- [ ] CSP, HSTS plan, frame ancestors, referrer, MIME, permissions policy,
  CSRF/OAuth state, input/output encoding, open redirect.
- [ ] Route guard + RLS + protected operation defense in depth.
- [ ] File upload signature/size/decompression/metadata/path controls.
- [ ] Dependency/license/audit/SBOM and secret scan.
- [ ] Cache/log/telemetry redaction and retention.
- [ ] Rate limits/abuse for Auth, QR validation, upload, payment order/review,
  submission, and Admin search.

## Slice 11.7 — Reliability/observability

- [ ] Typed failures validation/auth/offline/timeout/conflict/unknown.
- [ ] Retry/backoff/cancellation and idempotency matrix.
- [ ] Error boundaries per shell/route without exposing raw backend errors.
- [ ] Allowlisted metrics/logs/correlation IDs no PII.
- [ ] Backup/incident/rollback/update failure runbooks.
- [ ] Observability vendor requires separate privacy/dependency approval.

## Slice 11.8 — Landing screenshot finalization

- [ ] Capture PWA release candidate memakai fixture dan metadata Phase 10.
- [ ] Ganti placeholder hero/feature dengan screenshot PWA final yang dipilih.
- [ ] Optimalkan format, responsive source, dimensions, alt text, dan focal
  point tanpa membuat teks UI utama bergantung pada raster.
- [ ] Bandingkan screenshot terhadap build final setelah setiap perubahan UI
  material; recapture bila sudah tidak representatif.
- [ ] Verifikasi source asset dan rendered HTML tidak mengandung PII, private
  URL, identifier, atau metadata sensitif.
- [ ] Hapus label placeholder hanya setelah replacement dan review benar-benar
  lulus; bila tetap placeholder, wajib dilabeli dan memerlukan approval launch.

## Verification matrix

- [ ] Chromium, WebKit, Firefox smoke where supported.
- [ ] Physical iPhone Safari browser + installed PWA.
- [ ] Physical Android Chrome browser + installed PWA.
- [ ] Desktop Chrome/Safari/Firefox Admin.
- [ ] Lighthouse/PWA automated checks treated as supporting evidence, not sole
  accessibility/performance proof.
- [ ] Axe plus manual keyboard/screen reader.
- [ ] Offline/update/stale-cache/logout/account-switch E2E.
- [ ] Security regression and dependency/secret scan.
- [ ] Full lint/typecheck/unit/integration/E2E/build lulus.

## Definition of done

- Install/update/offline behavior predictable and no private cache.
- Critical accessibility issue zero.
- Performance budgets lulus on target mobile.
- Security threat matrix has no unresolved critical/high issue.
- Device/browser evidence siap untuk production phase.
- Screenshot landing berasal dari PWA release candidate atau placeholder masih
  diberi label serta memiliki approval launch eksplisit.
