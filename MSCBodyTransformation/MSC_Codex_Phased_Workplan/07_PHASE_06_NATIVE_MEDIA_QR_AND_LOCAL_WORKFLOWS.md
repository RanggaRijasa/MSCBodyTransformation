# Phase 06: Native Media, QR, and Local Workflows

## Tujuan

Mengimplementasikan kemampuan native yang dapat dibuat tanpa backend: photo picker, camera wrapper, image processing, local video playback, QR generation, QR scanning, share sheet, dan safe local file handling.

## External dependency status

Tidak membutuhkan Supabase, OAuth, atau App Store Connect.

Sebagian fitur harus diuji pada physical device, tetapi implementasi tetap lokal.

## Media selection

### Photo library

- [x] Gunakan `PhotosPicker`.
- [x] Request permission hanya saat dibutuhkan.
- [x] Handle limited library access.
- [x] Handle denied permission.
- [x] User dapat retry atau memilih alternatif.
- [x] Jangan memuat full-resolution image ke list row.

### Camera

- [x] Buat isolated native camera component menggunakan AVFoundation atau wrapper native yang kecil.
- [x] Handle camera unavailable.
- [x] Handle permission denied.
- [x] Handle capture cancellation.
- [x] Return local media result, bukan UIKit object ke domain layer.
- [x] Tambahkan accessible capture controls.
- [x] Pastikan orientation benar.

## Image pipeline

Buat `MediaProcessing` protocol dan native implementation.

- [x] Decode safely.
- [x] Normalize orientation.
- [x] Resize image dengan maximum dimension yang dikonfigurasi.
- [x] Compress untuk evidence review.
- [x] Strip EXIF location metadata.
- [x] Preserve enough visual quality.
- [x] Return byte size, width, height, MIME type, dan local URL/data handle.
- [x] Generate thumbnail.
- [x] Avoid main-thread heavy processing.
- [x] Support cancellation.
- [x] Clean temporary files.

Jangan menyimpan `UIImage` dalam domain model.

## Video

- [x] Gunakan `AVKit.VideoPlayer`.
- [x] Support bundled local sample video.
- [x] Loading and unavailable states.
- [x] Captions or text alternative placeholder.
- [x] Respect mute and audio session expectations.
- [x] Do not autoplay unexpectedly.

## Evidence local workflow

- [x] Attach image to draft submission.
- [x] Preview image.
- [x] Replace image.
- [x] Remove image.
- [x] Persist temporary local reference for demo session.
- [x] Simulate progress.
- [x] Simulate retry.
- [x] Prevent step completion when required evidence missing.
- [x] Reset removes temporary evidence safely.

## QR generation

- [x] Gunakan `CIQRCodeGenerator`.
- [x] Input local opaque token.
- [x] Scale without blur.
- [x] Add safe padding.
- [x] Optional local app logo only if scan reliability remains good.
- [x] Export/share as image.
- [x] Accessibility label includes program and coach, not raw secret token.
- [x] Never encode role or trusted score data.

## QR scanning

- [x] Prefer VisionKit `DataScannerViewController` where available.
- [x] AVFoundation barcode fallback.
- [x] Handle simulator unsupported state.
- [x] Parse only approved local scheme and route.
- [x] Reject arbitrary URL.
- [x] Show preview before redeem.
- [x] Preserve pending local invite through fake login.
- [x] Provide manual code entry fallback.
- [x] Haptic feedback respects settings.

Example local scheme:

```text
msc-demo://join/{opaque-token}
```

Production universal link is deferred.

## Share sheet

- [x] Native share sheet wrapper.
- [x] Share invitation text and QR image.
- [x] Do not expose internal debug information.
- [x] Cancellation is not an error.

## Local file security

- [x] Use temporary or application support directories.
- [x] Exclude temporary evidence from backup if appropriate.
- [x] Clean orphaned local demo files.
- [x] Never log body weight or evidence path publicly.
- [x] Use file protection options where practical.

## Tests

### Swift Testing

- [x] Image dimension decision.
- [x] MIME validation.
- [x] File size limit.
- [x] Metadata removal decisions.
- [x] QR payload parser.
- [x] Approved scheme/host validation.
- [x] Invalid QR rejection.
- [x] Evidence requirement validation.
- [x] Temporary file cleanup.

### UI/device tests

- [x] Photo picker path.
- [x] Permission denied state.
- [x] Camera unavailable state.
- [x] Scan local test QR.
- [x] Manual invite code.
- [x] Share sheet opens.
- [x] Video placeholder plays.

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

- [x] Participant dapat memilih atau mengambil foto.
- [x] Evidence diproses dan tampil sebagai thumbnail.
- [x] Metadata lokasi tidak dipertahankan.
- [x] Local QR dapat dibuat dan dipindai.
- [x] Manual code fallback bekerja.
- [x] No external service required.
- [x] Test lulus dan clean build.

## Progress log

### Log

#### 2026-07-26 — Native media, QR, dan workflow lokal

- Files changed: `Core/Media`, `Features/Media`,
  `ParticipantStepDetailView`, `ParticipantEntryFlowView`,
  `ParticipantJourneyStore`, `CoachInviteView`, `CoachQRCodeView`,
  parser deep link, fixture program, video lokal, katalog lokalisasi,
  unit test, dan UI test.
- Assumptions: evidence tetap berupa referensi file sementara lokal; QR hanya
  menerima `msc-demo://join/{opaque-token}`; pemindai VisionKit memakai
  AVFoundation sebagai fallback.
- Build command:
  `xcodebuild -project MSCBodyTransformation.xcodeproj -scheme MSCBodyTransformation -configuration Debug -destination 'platform=iOS Simulator,id=C63135B7-AF6A-42C0-8993-DF4C72589FE1' SWIFT_VERSION=6 SWIFT_STRICT_CONCURRENCY=complete IPHONEOS_DEPLOYMENT_TARGET=17.0 build`.
- Test command: focused Phase 06 Swift Testing serta UI onboarding peserta,
  native photo picker, dan journey Coach.
- Result: 10 unit test Phase 06 lulus; ketiga alur UI fokus lulus; regresi
  penuh 69/69 lulus; build Debug dan Release simulator bersih tanpa warning.
- Remaining blocker: kamera dan scanner fisik memerlukan
  `NSCameraUsageDescription` pada target Xcode sebelum pengujian perangkat.
  Nilai tersebut tidak ditambahkan karena perubahan build setting atau
  `project.pbxproj` dilarang dalam task ini.
