# Phase 04: Browser Media, QR, and Video

> Status: BELUM DIMULAI

## Tujuan

Mengganti PhotosPicker, camera, QR native, image processor, share, dan
VideoPlayer dengan adapter Web Platform yang aman, testable, dan graceful pada
Safari/Chrome.

## Dependency/compatibility gate

- [ ] Audit support target Safari iOS, installed PWA, Chrome Android, desktop.
- [ ] Spike camera/file capture, QR decode/display, Canvas/worker processing,
  video events, Web Share, and permission behavior.
- [ ] Pilih library QR hanya jika native API tidak cukup; pin version, license,
  bundle size, maintainer/security posture, dan alasan.
- [ ] Pilih service worker/media worker dependency hanya pada phase yang
  memerlukannya dan setelah approval.

## Slice 04.1 — Image acquisition

- [ ] File input galeri dengan accept allowlist dan optional capture hint.
- [ ] Interactive camera hanya setelah deliberate user action dan HTTPS.
- [ ] Permission denied/unavailable/no-camera/cancel/retry/rotation states.
- [ ] Jangan menyediakan media demo sebagai shortcut upload.
- [ ] Preview object URL selalu direvoke.

## Slice 04.2 — Image processing/upload seam

- [ ] Decode, normalize orientation, resize, re-encode, thumbnail, strip
  metadata, and size/MIME guard off main interaction path.
- [ ] Server tetap memvalidasi magic bytes/decoder/ownership/limit.
- [ ] Cancellable upload, progress, retry, duplicate submit, cleanup orphan.
- [ ] Domain tidak menerima browser image/blob type.
- [ ] Private object paths dan signed URLs tidak masuk log/cache.

## Slice 04.3 — QR scanner/display

- [ ] Opaque QR payload parsing dan server validation boundary.
- [ ] Tidak ada typed/manual Coach code fallback.
- [ ] Scan via camera; image-file decode fallback boleh dipakai hanya sebagai
  scan gambar, bukan input kode.
- [ ] Denied/unavailable state dapat ditutup dan menjelaskan langkah aman.
- [ ] Coach QR display dapat dipindai, memiliki accessible description, dan
  tidak menyediakan raw payload copy.
- [ ] Canonical HTTPS QR/deep-link contract siap untuk domain final.

## Slice 04.4 — Video

- [ ] HTML video player dengan captions/controls/keyboard.
- [ ] Resume position per enrollment/step.
- [ ] Autoplay mengikuti browser policy dan user preference.
- [ ] Watch threshold/required completion divalidasi server dan tahan terhadap
  forged jump/event spam sesuai contract.
- [ ] Network interruption, background/resume, unsupported format, and retry.

## Slice 04.5 — Share/download

- [ ] Web Share digunakan bila supported.
- [ ] Fallback hanya mengunduh/render visual QR yang aman; tidak menyalin raw
  identifier.
- [ ] Poster/evidence share mengikuti privacy role dan tidak mencampur bucket.

## Verification

- [ ] Unit tests parser/state/processor limits.
- [ ] Component tests permission and fallback states.
- [ ] Integration tests private Storage policies dan orphan cleanup lokal.
- [ ] E2E dengan synthetic media untuk deterministic tests; fixture tidak
  tersedia sebagai production upload shortcut.
- [ ] Manual physical iPhone Safari/installed PWA dan Android Chrome checklist
  dicatat; final gate Phase 11/13.
- [ ] Bundle size dan main-thread performance budget lulus.
- [ ] Lint, typecheck, test, build lulus.

## Definition of done

- Media dan QR boundary tidak bergantung pada React View besar.
- Safari/Chrome memiliki feature detection serta fallback yang jelas.
- Private media tidak bocor dan upload lifecycle bersih.
- Tidak ada manual Coach code.
- Video resume/completion mengikuti contract authoritative.

