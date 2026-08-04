# Phase 01: Domain Models, Repository Protocols, and Mock Data

> Status: arsip baseline Phase 01. Untuk perubahan program, kontrak aktif
> berada di `PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md` dan
> `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`. Requirement invite program,
> wallet/seat, bukti terpisah, poin per langkah, dan timbang global di bawah
> tidak boleh dipakai untuk implementasi baru.

## Tujuan

Mendefinisikan bahasa domain aplikasi dan membuat local data layer yang cukup lengkap agar seluruh UI dapat dibangun tanpa Supabase.

## External dependency status

**Lokal sepenuhnya.**

Tidak ada network client, Supabase SDK, OAuth, atau App Store integration.

## Hasil akhir

- Domain model platform-neutral.
- Repository protocols untuk semua feature.
- In-memory repositories.
- JSON fixtures untuk sample program.
- Fake session dengan tiga role.
- Seed data yang memungkinkan demo end-to-end.
- Validation dan scoring primitives dapat diuji.

## Domain models minimum

- [x] `AppUser`
- [x] `UserRole`
- [x] `ParticipantProfile`
- [x] `CoachProfile`
- [x] `Program`
- [x] `ProgramStatus`
- [x] `ProgramDay`
- [x] `ProgramStep`
- [x] `StepRequirement`
- [x] `ProgramEnrollment`
- [x] `EnrollmentStatus`
- [x] `WeighIn`
- [x] `WeighInType`
- [x] `StepSubmission`
- [x] `SubmissionEvidence`
- [x] `SubmissionStatus`
- [x] `ScoreBreakdown`
- [x] `LeaderboardEntry`
- [x] `ProgramWinner`
- [x] `CoachWallet`
- [x] `CreditLedgerEntry`
- [x] `CoachInvite`
- [x] `ManagedContent`
- [x] `AuditEvent`

## Model rules

- Gunakan `UUID` untuk identity.
- Gunakan `Date` untuk app model, tetapi siapkan encoding ISO 8601.
- Gunakan `Decimal` untuk berat badan.
- Gunakan integer untuk points dan seat credits.
- Enum persisted memakai raw values English yang stabil.
- Hindari nama properti yang mengandung `ios`, `swift`, atau detail Supabase.
- Gunakan value types secara default.
- Conform ke `Sendable` bila sesuai.
- Pisahkan display formatting dari domain model.
- Jangan menyimpan `UIImage` atau SwiftUI `Image` di domain model.

## Repository protocols minimum

```text
SessionRepository
ProfileRepository
CoachDirectoryRepository
ProgramRepository
EnrollmentRepository
SubmissionRepository
WeighInRepository
LeaderboardRepository
CoachParticipantRepository
InviteRepository
WalletRepository
ManagedContentRepository
AdminPeopleRepository
```

Setiap protocol harus:

- Async.
- Memiliki method yang kecil dan jelas.
- Tidak membocorkan tipe Supabase.
- Tidak membocorkan StoreKit type.
- Menggunakan domain error yang dapat dipetakan ke UI.
- Dapat diimplementasikan dengan actor atau safe concurrent storage.

## Mock implementation

### Session

- [x] Fake participant session.
- [x] Fake coach session.
- [x] Fake admin session.
- [x] Debug role switcher.
- [x] Simulasi logged out.
- [x] Simulasi onboarding belum selesai.
- [x] Simulasi session expired.

### Program seed

Buat minimal:

- [x] Satu program aktif 7 hari.
- [x] Tiga step per hari.
- [x] Step dengan image instruction.
- [x] Step dengan video placeholder.
- [x] Step yang membutuhkan text answer.
- [x] Past, current, dan future day.
- [x] Visibility mode hidden dan read-only.
- [x] Verification mode automatic dan coach review.

### Participant seed

- [x] Minimal 12 participant leaderboard.
- [x] Satu participant current user.
- [x] Participant dengan progress 0%, 40%, 90%, dan 100%.
- [x] Submission approved, pending, rejected, dan missing.
- [x] Initial weigh-in tersedia.
- [x] Final weigh-in belum tersedia pada active program.

### Coach seed

- [x] Minimal 4 coach public profiles.
- [x] Current coach memiliki wallet mock.
- [x] Current coach memiliki assigned participants.
- [x] Review queue memiliki beberapa submission.

### Admin seed

- [x] Draft program.
- [x] Scheduled program.
- [x] Active program.
- [x] Completed program.
- [x] Managed winner banner.
- [x] User yang menunggu approval coach.

## Fixture format

Simpan JSON fixtures di app bundle atau test resources:

```text
Fixtures/
├── users.json
├── coaches.json
├── programs.json
├── enrollments.json
├── submissions.json
├── leaderboard.json
└── managed_content.json
```

Tambahkan decoder yang gagal dengan error jelas ketika fixture invalid.

## Use cases minimum

- [x] Load current session.
- [x] Switch debug role.
- [x] Load today program.
- [x] Complete local step.
- [x] Submit local weigh-in.
- [x] Calculate progress.
- [x] Load leaderboard.
- [x] Review local submission.
- [x] Create local draft program.
- [x] Save local CMS draft.
- [x] Generate local invite.
- [x] Redeem local invite.
- [x] Apply local score adjustment untuk demo admin.

## Test minimum

- [x] JSON fixture decoding.
- [x] Enum raw-value stability.
- [x] Decimal weight encoding.
- [x] In-memory repository thread safety.
- [x] Role switcher.
- [x] Program progress calculation.
- [x] Visibility state calculation.
- [x] Domain error mapping.
- [x] Duplicate enrollment idempotency pada mock.
- [x] Duplicate completion idempotency pada mock.

## Larangan scope

Jangan:

- Menggunakan `SupabaseClient`.
- Menulis SQL.
- Menambahkan OAuth code.
- Menambahkan transaction verification.
- Menjadikan mock behavior sebagai final security behavior.
- Menghubungkan `Observable` feature state langsung ke mutable global array.

## Exit criteria

- [x] Seluruh mock data dapat dimuat tanpa jaringan.
- [x] Ketiga role memiliki state yang cukup untuk membangun UI.
- [x] Domain models tidak bergantung pada SwiftUI, UIKit, Supabase, atau StoreKit.
- [x] Repository protocols dapat diimplementasikan oleh mock dan future backend adapter.
- [x] Unit tests lulus.
- [x] Clean build.

## Progress log

### Log

#### 26 Juli 2026 — Domain, mock repository, dan seed demo lokal

- Files changed: model domain platform-neutral, domain error dan mapper,
  validation/scoring primitives, 13 repository protocol, use case Phase 01,
  `InMemoryAppRepository` berbasis actor, root repository container, tujuh
  fixture JSON, Debug role switcher yang terhubung ke fake session, string
  error Bahasa Indonesia, dan test Phase 01.
- Assumptions: progress lokal menghitung submission `pending` dan `approved`
  sebagai selesai, mengabaikan `rejected`, serta menghapus duplikat berdasarkan
  `stepID`; hari lampau menjadi read-only dan hari mendatang terkunci kecuali
  visibility program menetapkan hidden atau read-only.
- Build command:
  `xcodebuild -project MSCBodyTransformation.xcodeproj -scheme MSCBodyTransformation -configuration Debug -destination 'platform=iOS Simulator,id=C63135B7-AF6A-42C0-8993-DF4C72589FE1' SWIFT_VERSION=6 SWIFT_STRICT_CONCURRENCY=complete IPHONEOS_DEPLOYMENT_TARGET=17.0 build`
- Test command: command build yang sama dengan
  `-only-testing:MSCBodyTransformationTests test`, lalu
  `-only-testing:MSCBodyTransformationUITests test`.
- Result: build dan launch lulus tanpa warning; 16 unit test lulus; UI smoke
  test lulus. Snapshot runtime memastikan fake session Peserta dan Coach siap.
- Remaining blockers: deployment target, Swift language mode, strict
  concurrency, dan konfigurasi Staging belum dipersist ke project karena
  memerlukan perubahan `project.pbxproj` yang tidak diizinkan.
