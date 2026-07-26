# Phase 03: Participant Experience UI

## Tujuan

Membangun seluruh participant journey dengan in-memory repository dan local fixtures. Pada akhir phase, participant dapat menjalankan sample program dari awal sampai selesai tanpa backend.

## External dependency status

**Lokal sepenuhnya.**

Authentication menggunakan fake session. Evidence disimpan sebagai local demo reference. Program dan leaderboard berasal dari mock repositories.

## Screen inventory

### Entry dan onboarding

- [x] Local demo login screen.
- [x] Participant profile completion.
- [x] Privacy and wellness disclaimer screen.
- [x] Pending invite preview.
- [x] Join confirmation.
- [x] Initial weigh-in prompt.

### Today

- [x] Current program header.
- [x] Current day information.
- [x] Progress summary.
- [x] Initial/final weight callout.
- [x] Required step list.
- [x] Completed, pending, rejected, missing, dan locked states.
- [x] Empty state ketika tidak ada active enrollment.
- [x] All-complete celebration yang menghormati Reduce Motion.

### Program

- [x] Program overview.
- [x] Dates dan duration.
- [x] Assigned coach.
- [x] Rules and scoring summary.
- [x] Day timeline.
- [x] Past day state.
- [x] Current day state.
- [x] Future hidden state.
- [x] Future locked but visible state.
- [x] Overall progress.

### Step detail

- [x] Title dan points.
- [x] Instruction body.
- [x] Image instruction.
- [x] Local video placeholder atau bundled sample video.
- [x] Required items checklist.
- [x] Required text answer.
- [x] Evidence section.
- [x] Upload or replace photo action.
- [x] Complete step button.
- [x] Validation message.
- [x] Submission status.
- [x] Rejection reason.
- [x] Retry state.

### Weigh-in

- [x] Initial weigh-in form.
- [x] Final weigh-in form.
- [x] Decimal input.
- [x] Unit display kg.
- [x] Optional evidence photo UI bila product decision mengaktifkannya.
- [x] Window closed state.
- [x] Confirmation before submit.
- [x] Weight data privacy explanation.

### Leaderboard

- [x] Current user rank card.
- [x] Top five emphasized.
- [x] Full ranking.
- [x] Step points.
- [x] Weight points.
- [x] Total points.
- [x] Tie state presentation.
- [x] Provisional label.
- [x] Final locked label.
- [x] Winner banner from local managed content.

### Coaches

- [x] Coach directory.
- [x] Coach profile detail.
- [x] Assigned coach emphasis.
- [x] Accessible photo and bio.

### Profile

- [x] User information.
- [x] Current and previous enrollments.
- [x] App settings.
- [x] Privacy and terms placeholders.
- [x] Logout local demo.
- [x] Delete-account informational placeholder, no live deletion.

## Local participant workflow

Implement state changes against `InMemory...Repository`:

1. Participant enters a valid local invite.
2. Participant confirms join.
3. Enrollment appears.
4. Initial weight is submitted.
5. Today steps become available.
6. Participant attaches local image.
7. Participant completes a step.
8. Progress and local score update.
9. Participant continues to final day using Debug date override.
10. Participant submits final weight.
11. Leaderboard recalculates locally.

## Debug tools

- [x] Program date override.
- [x] Current day selector.
- [x] Reset demo participant.
- [x] Mark all previous days complete.
- [x] Simulate rejected submission.
- [x] Simulate offline.
- [x] Simulate repository error.
- [x] Simulate final program state.

Debug tools must not compile into Release.

## State architecture

Setiap feature harus memiliki:

- Focused screen state.
- Explicit loading, loaded, empty, error states.
- Async actions.
- Cancellation-safe `.task`.
- Repository injected via initializer atau environment.
- No business logic in view body.
- No giant participant view model for every tab.

## Validation

- [x] Evidence required sebelum completion.
- [x] Text answer required when configured.
- [x] Cannot complete locked step.
- [x] Duplicate completion idempotent.
- [x] Weight range validation.
- [x] Decimal separator works untuk Indonesian locale.
- [x] Final weight not accepted before allowed local window.
- [x] Error message associated with relevant field.

## Previews

Buat preview untuk:

- [x] Today loading.
- [x] Today active with partial completion.
- [x] Today complete.
- [x] No enrollment.
- [x] Step missing evidence.
- [x] Step pending review.
- [x] Step rejected.
- [x] Timeline with hidden days.
- [x] Leaderboard current user outside top five.
- [x] Leaderboard final winners.
- [x] Largest Dynamic Type.
- [x] Dark mode.

## Tests

### Swift Testing

- [x] Today state mapping.
- [x] Step validation.
- [x] Weigh-in validation.
- [x] Progress calculation.
- [x] Locked step behavior.
- [x] Local participant completion.
- [x] Final weight flow.
- [x] Error mapping.

### UI tests

- [x] Launch as participant.
- [x] Join sample program.
- [x] Submit initial weight.
- [x] Select bundled/local test image.
- [x] Complete one step.
- [x] Verify progress changes.
- [x] Open leaderboard.
- [x] Navigate coach directory.

## Larangan scope

Jangan:

- Menghubungkan kamera production bila native wrapper belum dibuat pada Phase 06.
- Mengunggah file ke network.
- Mengimplementasikan Google login.
- Mengimplementasikan database authorization.
- Menganggap local score sebagai final server truth.
- Menambahkan HealthKit.

## Exit criteria

- [x] Participant journey dapat didemokan tanpa internet.
- [x] Semua primary screens memiliki meaningful mock states.
- [x] Required evidence mencegah premature completion.
- [x] Progress dan local leaderboard berubah setelah action.
- [x] Dynamic Type dan VoiceOver baseline terpenuhi.
- [x] Test lulus dan clean build.

## Progress log

### Log

#### 2026-07-26 — Phase 03 selesai

- Files changed: participant journey store dan focused screen state; entry,
  onboarding, Today, Program, step detail, weigh-in, leaderboard, coach
  directory/detail, profile, dan Debug tools; repository mock untuk reset,
  retry, progres, poin langkah, dan poin berat; fixture riwayat enrollment;
  localization; Swift Testing dan XCTest UI.
- Assumptions: evidence memakai referensi foto contoh lokal dan video memakai
  placeholder bundled karena camera/photo integration baru dikerjakan pada
  Phase 06. Poin ditandai jelas sebagai demo lokal, bukan hasil terverifikasi
  server. Build tetap memakai override Swift 6, strict concurrency, dan
  deployment target iOS 17 karena `project.pbxproj` tidak termasuk scope.
- Build command: XcodeBuildMCP
  `build_run_sim(launchArgs: ["-DemoRole", "participant", "-DemoScenario", "participant_active", "-SkipDemoLanding"])`
  pada iPhone 17 Pro dan iPad Pro 13-inch; Release diverifikasi dengan
  `build_sim()`.
- Test command: XcodeBuildMCP
  `test_sim(extraArgs: ["-only-testing:MSCBodyTransformationTests"])` dan
  `test_sim(extraArgs: ["-only-testing:MSCBodyTransformationUITests"])`.
- Result: Debug build iPhone/iPad serta Release build lulus tanpa warning;
  31 unit/integration tests lulus; 4 UI test methods dan seluruh launch
  configuration invocations lulus. End-to-end UI test mencakup login lokal,
  profil, disclaimer, invite, join, timbang awal, bukti contoh, penyelesaian
  langkah, perubahan progres, papan peringkat, dan direktori coach.
- Accessibility verification: VoiceOver labels/identifiers diperiksa melalui
  runtime accessibility tree; light, dark, iPad, dan accessibility Dynamic
  Type terbesar diverifikasi, termasuk scroll dan akses lima tab.
- Remaining blockers: nilai Swift 6, strict concurrency, dan deployment target
  iOS 17 belum dipersist ke Xcode project karena perubahan `project.pbxproj`
  tidak diizinkan. Tidak ada integrasi eksternal yang dibutuhkan.
