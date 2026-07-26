# Phase 05: Admin CMS UI

## Tujuan

Membangun CMS native di dalam aplikasi menggunakan local draft repository. Admin dapat membuat, mengedit, mem-preview, dan mensimulasikan publish program tanpa backend.

## External dependency status

**Lokal sepenuhnya.**

Media menggunakan local references. Publish hanya mengubah status mock.

## Admin tabs

1. Overview
2. Programs
3. People
4. Content
5. Settings

## Overview

- [x] Program counts by status.
- [x] Active participant count.
- [x] Pending coach approvals.
- [x] Pending reviews.
- [x] Scoring status.
- [x] Recent local audit events.
- [x] Quick actions.

## Program list

- [x] Draft, scheduled, active, completed, archived sections.
- [x] Search.
- [x] Status filter.
- [x] Duplicate draft action.
- [x] Archive local action.
- [x] Empty states.
- [x] Error and loading simulations.

## Staged program editor

Gunakan staged flow:

1. Basics
2. Dates and timezone
3. Scoring and visibility
4. Days
5. Steps and media
6. Participant preview
7. Publish validation

### Basics

- [x] Name.
- [x] Description.
- [x] Cover image local reference.
- [x] Verification mode.
- [x] Wellness disclaimer reference.

### Dates and timezone

- [x] Start date.
- [x] End date.
- [x] IANA timezone selection.
- [x] Initial weigh-in window.
- [x] Final weigh-in window.
- [x] Date validation.
- [x] Duration derived safely.

### Scoring and visibility

- [x] Weight points per kg.
- [x] Past step policy.
- [x] Future step policy.
- [x] Automatic or coach review.
- [x] Human-readable scoring preview.
- [x] Warning that server becomes authoritative later.

### Days

- [x] Generate days from date range.
- [x] Day list.
- [x] Add, remove, and reorder when allowed.
- [x] Day title and description.
- [x] Scheduled date.
- [x] Duplicate day.
- [x] Validation for unique day number and date.

### Steps

- [x] Ordered steps.
- [x] Add step.
- [x] Edit step.
- [x] Delete draft step.
- [x] Reorder.
- [x] Title.
- [x] Description.
- [x] Points.
- [x] Requires photo.
- [x] Requires text answer.
- [x] Required or optional.
- [x] Image/video local media.
- [x] Participant-facing preview.
- [x] Validation for non-negative points.

### Preview

- [x] Preview participant Today.
- [x] Preview timeline.
- [x] Preview step detail.
- [x] Preview locked states.
- [x] Preview leaderboard scoring description.
- [x] Preview on small and large device sizes.

### Local publish simulation

- [x] Validate at least one day.
- [x] Validate every day has an active step.
- [x] Validate dates.
- [x] Validate scoring.
- [x] Validate step ordering.
- [x] Validate required media reference when configured.
- [x] Show validation summary.
- [x] Publish changes mock status only.
- [x] Append local audit event.

## People

- [x] User list.
- [x] Role badges.
- [x] Pending coach approval.
- [x] Approve coach local action.
- [x] Public coach profile toggle.
- [x] Participant detail summary.
- [x] Manual enrollment UI.
- [x] Manual enrollment reason required.
- [x] Local audit record.
- [x] Score adjustment UI with required reason.
- [x] No self-service role promotion outside admin demo.

## Content

- [x] Managed content list.
- [x] Winner banner editor.
- [x] Title and body.
- [x] Local media selection.
- [x] Program association.
- [x] Visibility dates.
- [x] Sort order.
- [x] Active toggle.
- [x] Participant preview.
- [x] Archive local content.

## Winner management

- [x] Leaderboard preview.
- [x] Lock top five local simulation.
- [x] Confirmation.
- [x] Winner records display.
- [x] Locked state prevents silent reorder.
- [x] New score adjustment after lock shows warning.
- [x] Upload local winner banner.

## Draft persistence

Gunakan salah satu pendekatan native lokal:

- JSON file in application support untuk Debug demo, atau
- In-memory repository dengan fixture reset.

Jangan menambahkan SwiftData hanya untuk sementara bila persistence tidak dibutuhkan. Bila dipilih, dokumentasikan alasan dan migration implications.

## Tests

### Swift Testing

- [x] Program editor validation.
- [x] Day generation.
- [x] Date range validation.
- [x] Step order validation.
- [x] Publish validation.
- [x] Manual enrollment reason.
- [x] Score adjustment reason.
- [x] Winner lock determinism.
- [x] Managed content visibility.

### UI tests

- [x] Launch as admin.
- [x] Create draft.
- [x] Add day and step.
- [x] Preview participant screen.
- [x] Simulate publish.
- [x] Approve coach.
- [x] Manual enroll participant.
- [x] Create winner banner.

## Larangan scope

Jangan:

- Membuat SQL.
- Menyimpan live data.
- Menganggap client CMS validation cukup untuk production publish.
- Membolehkan scoring change silent setelah publish.
- Mengunggah media ke server.
- Membuat web admin panel.

## Exit criteria

- [x] Admin dapat membuat valid sample program tanpa perubahan kode.
- [x] Invalid draft tidak dapat dipublish dalam local simulation.
- [x] Participant preview mencerminkan draft.
- [x] People dan Content screens dapat didemokan.
- [x] Semua privileged local action membuat local audit entry.
- [x] Test lulus dan clean build.

## Progress log

### Log

#### 2026-07-26 — Phase 05 selesai

- Files changed: model draft CMS lengkap beserta kebijakan visibilitas,
  metadata konten, status arsip, dan audit event; protocol serta actor
  repository lokal; validator dan use case publish/enrollment/skor/pemenang;
  lima layar tab Admin; editor program tujuh tahap; pratinjau peserta;
  pengelolaan orang, konten, dan snapshot pemenang; app-shell routing;
  fixture, localization catalog, Swift Testing, XCTest UI, dan README.
- Assumptions: persistence in-memory dipilih agar fixture dapat di-reset dan
  tidak memerlukan migrasi SwiftData; referensi gambar/video tetap berupa
  nama resource lokal; publish hanya mengubah status mock; snapshot pemenang
  sengaja tidak berubah setelah dikunci; scoring preview belum
  server-authoritative. Tidak ada Supabase, OAuth, StoreKit, networking,
  package baru, atau perubahan `project.pbxproj`.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-DemoRole", "admin", "-DemoScenario", "admin_draft_editor",
  "-SkipDemoLanding"])` pada iPhone 17 Pro dan iPad Pro 13-inch, serta
  `build_sim()` pada konfigurasi Release; seluruh command memakai
  `SWIFT_VERSION=6`, `SWIFT_STRICT_CONCURRENCY=complete`, dan
  `IPHONEOS_DEPLOYMENT_TARGET=17.0`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase05AdminCMSTests"])`,
  tiga focused XCTest UI untuk publish, People, dan banner, lalu
  `test_sim()` untuk seluruh scheme.
- Result: sembilan test Phase 05 dan tiga journey UI Admin lulus; seluruh 58
  test, build Debug iPhone/iPad, dan build Release lulus tanpa warning.
  Ringkasan Admin diverifikasi pada light mode serta dark mode dengan
  accessibility Dynamic Type terbesar; grid berubah menjadi satu kolom agar
  teks tetap terbaca.
- Remaining blockers: tidak ada blocker lokal. Upload media, backend/RLS,
  scoring server-authoritative, dan autentikasi production tetap ditunda ke
  phase yang ditetapkan.
