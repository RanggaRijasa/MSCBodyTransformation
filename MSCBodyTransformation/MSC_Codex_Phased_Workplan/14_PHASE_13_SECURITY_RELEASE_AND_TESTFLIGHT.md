# Phase 13: Production Release Overview

Phase 13 sekarang dibagi menjadi tiga workplan authoritative agar owner dapat
menguji aplikasi sendiri sebelum archive, TestFlight, dan App Review.

## Urutan wajib

### 13.1 — Release hardening, hosted main, sandbox, dan physical testing

File:
`14A_PHASE_13_1_RELEASE_HARDENING_HOSTED_AND_PHYSICAL_TESTING.md`

Mencakup:

- Release hardening, privacy manifest, legal, App Icon, dan Release config;
- deploy Supabase hosted `main` setelah approval production;
- hosted Google/Apple OAuth;
- StoreKit/App Store Connect products dan Apple server integration;
- sandbox serta physical-device testing;
- exploratory test langsung oleh owner.

**Hard stop:** jangan membuat/upload archive sebelum owner menyatakan Phase
13.1 layak dilanjutkan.

### 13.2 — Archive dan TestFlight

File: `14B_PHASE_13_2_ARCHIVE_AND_TESTFLIGHT.md`

Mencakup:

- freeze release candidate;
- production archive dan bundle inspection;
- upload ke App Store Connect setelah approval;
- internal TestFlight distribution;
- TestFlight end-to-end validation terhadap hosted backend.

**Hard stop:** jangan submit App Review dari Phase 13.2.

### 13.3 — Metadata, App Review, dan release

File: `14C_PHASE_13_3_APP_STORE_REVIEW_AND_RELEASE.md`

Mencakup:

- metadata, screenshots, privacy/compliance responses, dan review notes;
- reviewer accounts, QR Coach, serta IAP submission association;
- final pre-submission audit;
- `Submit for Review` hanya setelah approval eksplisit owner;
- public release sesuai manual/automatic mode yang disetujui.

## Approval yang tidak boleh digabung

Persetujuan berikut selalu terpisah:

1. Hosted Supabase/Auth/secret/config mutation.
2. App Store Connect product/notification configuration.
3. Archive upload.
4. TestFlight tester distribution.
5. App Review submission.
6. Manual public release.

Persetujuan pada satu tahap tidak mengizinkan tahap berikutnya.

## Status saat split

- App Icon production default/dark/tinted sudah selesai dan tercatat pada
  Phase 13.1.
- Hosted `main`, production OAuth/StoreKit, sandbox, dan physical-device gate
  belum dinyatakan selesai.
- Archive, TestFlight upload/distribution, App Review, dan public release belum
  dijalankan.
- SMTP/domain/email-password tetap skipped.

## Progress log

### 9 Agustus 2026 — Phase 13 dibagi menjadi tiga workplan

- Memisahkan testable production integration dari distribution dan submission.
- Menambahkan owner exploratory-test gate sebelum archive/TestFlight.
- Mempertahankan approval boundary untuk setiap external mutation.
