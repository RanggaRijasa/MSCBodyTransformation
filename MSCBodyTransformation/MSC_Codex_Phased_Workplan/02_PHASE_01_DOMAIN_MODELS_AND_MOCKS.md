# Phase 01: Domain Models, Repository Protocols, and Mock Data

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

- [ ] `AppUser`
- [ ] `UserRole`
- [ ] `ParticipantProfile`
- [ ] `CoachProfile`
- [ ] `Program`
- [ ] `ProgramStatus`
- [ ] `ProgramDay`
- [ ] `ProgramStep`
- [ ] `StepRequirement`
- [ ] `ProgramEnrollment`
- [ ] `EnrollmentStatus`
- [ ] `WeighIn`
- [ ] `WeighInType`
- [ ] `StepSubmission`
- [ ] `SubmissionEvidence`
- [ ] `SubmissionStatus`
- [ ] `ScoreBreakdown`
- [ ] `LeaderboardEntry`
- [ ] `ProgramWinner`
- [ ] `CoachWallet`
- [ ] `CreditLedgerEntry`
- [ ] `CoachInvite`
- [ ] `ManagedContent`
- [ ] `AuditEvent`

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

- [ ] Fake participant session.
- [ ] Fake coach session.
- [ ] Fake admin session.
- [ ] Debug role switcher.
- [ ] Simulasi logged out.
- [ ] Simulasi onboarding belum selesai.
- [ ] Simulasi session expired.

### Program seed

Buat minimal:

- [ ] Satu program aktif 7 hari.
- [ ] Tiga step per hari.
- [ ] Step dengan image instruction.
- [ ] Step dengan video placeholder.
- [ ] Step yang membutuhkan text answer.
- [ ] Past, current, dan future day.
- [ ] Visibility mode hidden dan read-only.
- [ ] Verification mode automatic dan coach review.

### Participant seed

- [ ] Minimal 12 participant leaderboard.
- [ ] Satu participant current user.
- [ ] Participant dengan progress 0%, 40%, 90%, dan 100%.
- [ ] Submission approved, pending, rejected, dan missing.
- [ ] Initial weigh-in tersedia.
- [ ] Final weigh-in belum tersedia pada active program.

### Coach seed

- [ ] Minimal 4 coach public profiles.
- [ ] Current coach memiliki wallet mock.
- [ ] Current coach memiliki assigned participants.
- [ ] Review queue memiliki beberapa submission.

### Admin seed

- [ ] Draft program.
- [ ] Scheduled program.
- [ ] Active program.
- [ ] Completed program.
- [ ] Managed winner banner.
- [ ] User yang menunggu approval coach.

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

- [ ] Load current session.
- [ ] Switch debug role.
- [ ] Load today program.
- [ ] Complete local step.
- [ ] Submit local weigh-in.
- [ ] Calculate progress.
- [ ] Load leaderboard.
- [ ] Review local submission.
- [ ] Create local draft program.
- [ ] Save local CMS draft.
- [ ] Generate local invite.
- [ ] Redeem local invite.
- [ ] Apply local score adjustment untuk demo admin.

## Test minimum

- [ ] JSON fixture decoding.
- [ ] Enum raw-value stability.
- [ ] Decimal weight encoding.
- [ ] In-memory repository thread safety.
- [ ] Role switcher.
- [ ] Program progress calculation.
- [ ] Visibility state calculation.
- [ ] Domain error mapping.
- [ ] Duplicate enrollment idempotency pada mock.
- [ ] Duplicate completion idempotency pada mock.

## Larangan scope

Jangan:

- Menggunakan `SupabaseClient`.
- Menulis SQL.
- Menambahkan OAuth code.
- Menambahkan transaction verification.
- Menjadikan mock behavior sebagai final security behavior.
- Menghubungkan `Observable` feature state langsung ke mutable global array.

## Exit criteria

- [ ] Seluruh mock data dapat dimuat tanpa jaringan.
- [ ] Ketiga role memiliki state yang cukup untuk membangun UI.
- [ ] Domain models tidak bergantung pada SwiftUI, UIKit, Supabase, atau StoreKit.
- [ ] Repository protocols dapat diimplementasikan oleh mock dan future backend adapter.
- [ ] Unit tests lulus.
- [ ] Clean build.

## Progress log

### Log
