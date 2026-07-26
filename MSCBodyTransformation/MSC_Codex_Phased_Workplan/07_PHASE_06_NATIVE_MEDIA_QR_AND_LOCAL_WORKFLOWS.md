# Phase 06: Native Media, QR, and Local Workflows

## Tujuan

Mengimplementasikan kemampuan native yang dapat dibuat tanpa backend: photo picker, camera wrapper, image processing, local video playback, QR generation, QR scanning, share sheet, dan safe local file handling.

## External dependency status

Tidak membutuhkan Supabase, OAuth, atau App Store Connect.

Sebagian fitur harus diuji pada physical device, tetapi implementasi tetap lokal.

## Media selection

### Photo library

- [ ] Gunakan `PhotosPicker`.
- [ ] Request permission hanya saat dibutuhkan.
- [ ] Handle limited library access.
- [ ] Handle denied permission.
- [ ] User dapat retry atau memilih alternatif.
- [ ] Jangan memuat full-resolution image ke list row.

### Camera

- [ ] Buat isolated native camera component menggunakan AVFoundation atau wrapper native yang kecil.
- [ ] Handle camera unavailable.
- [ ] Handle permission denied.
- [ ] Handle capture cancellation.
- [ ] Return local media result, bukan UIKit object ke domain layer.
- [ ] Tambahkan accessible capture controls.
- [ ] Pastikan orientation benar.

## Image pipeline

Buat `MediaProcessing` protocol dan native implementation.

- [ ] Decode safely.
- [ ] Normalize orientation.
- [ ] Resize image dengan maximum dimension yang dikonfigurasi.
- [ ] Compress untuk evidence review.
- [ ] Strip EXIF location metadata.
- [ ] Preserve enough visual quality.
- [ ] Return byte size, width, height, MIME type, dan local URL/data handle.
- [ ] Generate thumbnail.
- [ ] Avoid main-thread heavy processing.
- [ ] Support cancellation.
- [ ] Clean temporary files.

Jangan menyimpan `UIImage` dalam domain model.

## Video

- [ ] Gunakan `AVKit.VideoPlayer`.
- [ ] Support bundled local sample video.
- [ ] Loading and unavailable states.
- [ ] Captions or text alternative placeholder.
- [ ] Respect mute and audio session expectations.
- [ ] Do not autoplay unexpectedly.

## Evidence local workflow

- [ ] Attach image to draft submission.
- [ ] Preview image.
- [ ] Replace image.
- [ ] Remove image.
- [ ] Persist temporary local reference for demo session.
- [ ] Simulate progress.
- [ ] Simulate retry.
- [ ] Prevent step completion when required evidence missing.
- [ ] Reset removes temporary evidence safely.

## QR generation

- [ ] Gunakan `CIQRCodeGenerator`.
- [ ] Input local opaque token.
- [ ] Scale without blur.
- [ ] Add safe padding.
- [ ] Optional local app logo only if scan reliability remains good.
- [ ] Export/share as image.
- [ ] Accessibility label includes program and coach, not raw secret token.
- [ ] Never encode role or trusted score data.

## QR scanning

- [ ] Prefer VisionKit `DataScannerViewController` where available.
- [ ] AVFoundation barcode fallback.
- [ ] Handle simulator unsupported state.
- [ ] Parse only approved local scheme and route.
- [ ] Reject arbitrary URL.
- [ ] Show preview before redeem.
- [ ] Preserve pending local invite through fake login.
- [ ] Provide manual code entry fallback.
- [ ] Haptic feedback respects settings.

Example local scheme:

```text
msc-demo://join/{opaque-token}
```

Production universal link is deferred.

## Share sheet

- [ ] Native share sheet wrapper.
- [ ] Share invitation text and QR image.
- [ ] Do not expose internal debug information.
- [ ] Cancellation is not an error.

## Local file security

- [ ] Use temporary or application support directories.
- [ ] Exclude temporary evidence from backup if appropriate.
- [ ] Clean orphaned local demo files.
- [ ] Never log body weight or evidence path publicly.
- [ ] Use file protection options where practical.

## Tests

### Swift Testing

- [ ] Image dimension decision.
- [ ] MIME validation.
- [ ] File size limit.
- [ ] Metadata removal decisions.
- [ ] QR payload parser.
- [ ] Approved scheme/host validation.
- [ ] Invalid QR rejection.
- [ ] Evidence requirement validation.
- [ ] Temporary file cleanup.

### UI/device tests

- [ ] Photo picker path.
- [ ] Permission denied state.
- [ ] Camera unavailable state.
- [ ] Scan local test QR.
- [ ] Manual invite code.
- [ ] Share sheet opens.
- [ ] Video placeholder plays.

## Larangan scope

Jangan:

- Mengunggah media.
- Membuat storage bucket.
- Membuat signed URL.
- Menggunakan third-party QR library.
- Menyimpan raw invite token ke logs.
- Menambahkan universal link entitlement tanpa domain yang benar.
- Menambahkan broad photo permission bila PhotosPicker cukup.

## Exit criteria

- [ ] Participant dapat memilih atau mengambil foto.
- [ ] Evidence diproses dan tampil sebagai thumbnail.
- [ ] Metadata lokasi tidak dipertahankan.
- [ ] Local QR dapat dibuat dan dipindai.
- [ ] Manual code fallback bekerja.
- [ ] No external service required.
- [ ] Test lulus dan clean build.

## Progress log

### Log
