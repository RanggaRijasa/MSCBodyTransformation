# Phase 04: Browser Media, QR, and Video

> Status: SELESAI LOKAL

## Tujuan

Mengganti PhotosPicker, camera, QR native, image processor, share, dan
VideoPlayer dengan adapter Web Platform yang aman, testable, dan graceful pada
Safari/Chrome.

## Dependency/compatibility gate

- [x] Audit support target Safari iOS, installed PWA, Chrome Android, desktop.
- [x] Spike camera/file capture, QR decode/display, Canvas/worker processing,
  video events, Web Share, and permission behavior.
- [x] Pilih library QR hanya jika native API tidak cukup; pin version, license,
  bundle size, maintainer/security posture, dan alasan.
- [x] Pilih service worker/media worker dependency hanya pada phase yang
  memerlukannya dan setelah approval.

## Slice 04.1 — Image acquisition

- [x] File input galeri dengan accept allowlist dan optional capture hint.
- [x] Interactive camera hanya setelah deliberate user action dan HTTPS.
- [x] Permission denied/unavailable/no-camera/cancel/retry/rotation states.
- [x] Jangan menyediakan media demo sebagai shortcut upload.
- [x] Preview object URL selalu direvoke.

## Slice 04.2 — Image processing/upload seam

- [x] Decode, normalize orientation, resize, re-encode, thumbnail, strip
  metadata, and size/MIME guard off main interaction path.
- [x] Server tetap memvalidasi magic bytes/decoder/ownership/limit.
- [x] Cancellable upload, progress, retry, duplicate submit, cleanup orphan.
- [x] Domain tidak menerima browser image/blob type.
- [x] Private object paths dan signed URLs tidak masuk log/cache.

## Slice 04.3 — QR scanner/display

- [x] Opaque QR payload parsing dan server validation boundary.
- [x] Tidak ada typed/manual Coach code fallback.
- [x] Scan via camera; image-file decode fallback boleh dipakai hanya sebagai
  scan gambar, bukan input kode.
- [x] Denied/unavailable state dapat ditutup dan menjelaskan langkah aman.
- [x] Coach QR display dapat dipindai, memiliki accessible description, dan
  tidak menyediakan raw payload copy.
- [x] Canonical HTTPS QR/deep-link contract siap untuk domain final.

## Slice 04.4 — Video

- [x] HTML video player dengan captions/controls/keyboard.
- [x] Resume position per enrollment/step.
- [x] Autoplay mengikuti browser policy dan user preference.
- [x] Watch threshold/required completion divalidasi server dan tahan terhadap
  forged jump/event spam sesuai contract.
- [x] Network interruption, background/resume, unsupported format, and retry.

## Slice 04.5 — Share/download

- [x] Web Share digunakan bila supported.
- [x] Fallback hanya mengunduh/render visual QR yang aman; tidak menyalin raw
  identifier.
- [x] Poster/evidence share mengikuti privacy role dan tidak mencampur bucket.

## Verification

- [x] Unit tests parser/state/processor limits.
- [x] Component tests permission and fallback states.
- [x] Integration tests private Storage policies dan orphan cleanup lokal.
- [x] E2E dengan synthetic media untuk deterministic tests; fixture tidak
  tersedia sebagai production upload shortcut.
- [x] Manual physical iPhone Safari/installed PWA dan Android Chrome checklist
  dicatat; final gate Phase 11/13.
- [x] Bundle size dan main-thread performance budget lulus.
- [x] Lint, typecheck, test, build lulus.

## Definition of done

- Media dan QR boundary tidak bergantung pada React View besar.
- Safari/Chrome memiliki feature detection serta fallback yang jelas.
- Private media tidak bocor dan upload lifecycle bersih.
- Tidak ada manual Coach code.
- Video resume/completion mengikuti contract authoritative.

## Progress log

### 10 Agustus 2026 — selesai lokal

- Files: domain media/QR/video/upload state; browser camera, image worker dan
  Canvas fallback; QR decoder/renderer; image acquisition, scanner, Coach QR,
  share/download, dan video components; private QR route; upload/server image
  validation seam; development gallery; unit/component/E2E/integration tests;
  budget checker; compatibility/device handoff; package manifest dan lockfile.
- Dependencies: `qr-scanner@1.4.2` dan `uqr@0.1.3`, keduanya MIT dan dipin;
  `pnpm audit --prod` melaporkan tidak ada kerentanan diketahui. Tidak ada
  service-worker/media dependency tambahan.
- Assumptions: server operation tetap authoritative untuk ownership,
  completion, dan poin. Browser interval tontonan hanya pratinjau. Canonical
  production origin akan diisi HTTPS pada Phase 12. Test physical device
  dicatat di `docs/architecture/PHASE_04_BROWSER_MEDIA_COMPATIBILITY.md` dan
  tetap menjadi final gate Phase 11/13.
- Build/test: `pnpm verify` lulus—lint, localization, secret/architecture/file
  guards, TypeScript, 22 file/90 test Vitest, build production 39 route, dan
  media chunk raw 8.913–24.556 byte tanpa coupling ke initial landing.
- Browser: `pnpm test:e2e` lulus 44 dan skip terarah 24; `pnpm test:gallery`
  lulus 6/6 di Chromium/WebKit dengan QR dan image synthetic nyata dalam
  budget dua detik.
- Backend lokal: `pnpm test:phase04:local` lulus 34 pgTAP, 4 assertion Edge
  cleanup dengan nol object terhapus, dan 1 E2E Coach terverifikasi yang
  menerima SVG privat `no-store` tanpa payload mentah. Hosted Supabase tidak
  disentuh.
- Remaining external gates: Safari/installed PWA iPhone fisik, Android Chrome,
  release-candidate Core Web Vitals, final HTTPS domain, dan cache/service
  worker audit tetap Phase 11–13; tidak menghalangi status `SELESAI LOKAL`.
