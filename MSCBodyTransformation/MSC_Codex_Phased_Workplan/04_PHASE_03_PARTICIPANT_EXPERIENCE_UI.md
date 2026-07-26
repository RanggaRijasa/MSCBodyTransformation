# Phase 03: Participant Experience UI

## Tujuan

Membangun seluruh participant journey dengan in-memory repository dan local fixtures. Pada akhir phase, participant dapat menjalankan sample program dari awal sampai selesai tanpa backend.

## External dependency status

**Lokal sepenuhnya.**

Authentication menggunakan fake session. Evidence disimpan sebagai local demo reference. Program dan leaderboard berasal dari mock repositories.

## Screen inventory

### Entry dan onboarding

- [ ] Local demo login screen.
- [ ] Participant profile completion.
- [ ] Privacy and wellness disclaimer screen.
- [ ] Pending invite preview.
- [ ] Join confirmation.
- [ ] Initial weigh-in prompt.

### Today

- [ ] Current program header.
- [ ] Current day information.
- [ ] Progress summary.
- [ ] Initial/final weight callout.
- [ ] Required step list.
- [ ] Completed, pending, rejected, missing, dan locked states.
- [ ] Empty state ketika tidak ada active enrollment.
- [ ] All-complete celebration yang menghormati Reduce Motion.

### Program

- [ ] Program overview.
- [ ] Dates dan duration.
- [ ] Assigned coach.
- [ ] Rules and scoring summary.
- [ ] Day timeline.
- [ ] Past day state.
- [ ] Current day state.
- [ ] Future hidden state.
- [ ] Future locked but visible state.
- [ ] Overall progress.

### Step detail

- [ ] Title dan points.
- [ ] Instruction body.
- [ ] Image instruction.
- [ ] Local video placeholder atau bundled sample video.
- [ ] Required items checklist.
- [ ] Required text answer.
- [ ] Evidence section.
- [ ] Upload or replace photo action.
- [ ] Complete step button.
- [ ] Validation message.
- [ ] Submission status.
- [ ] Rejection reason.
- [ ] Retry state.

### Weigh-in

- [ ] Initial weigh-in form.
- [ ] Final weigh-in form.
- [ ] Decimal input.
- [ ] Unit display kg.
- [ ] Optional evidence photo UI bila product decision mengaktifkannya.
- [ ] Window closed state.
- [ ] Confirmation before submit.
- [ ] Weight data privacy explanation.

### Leaderboard

- [ ] Current user rank card.
- [ ] Top five emphasized.
- [ ] Full ranking.
- [ ] Step points.
- [ ] Weight points.
- [ ] Total points.
- [ ] Tie state presentation.
- [ ] Provisional label.
- [ ] Final locked label.
- [ ] Winner banner from local managed content.

### Coaches

- [ ] Coach directory.
- [ ] Coach profile detail.
- [ ] Assigned coach emphasis.
- [ ] Accessible photo and bio.

### Profile

- [ ] User information.
- [ ] Current and previous enrollments.
- [ ] App settings.
- [ ] Privacy and terms placeholders.
- [ ] Logout local demo.
- [ ] Delete-account informational placeholder, no live deletion.

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

- [ ] Program date override.
- [ ] Current day selector.
- [ ] Reset demo participant.
- [ ] Mark all previous days complete.
- [ ] Simulate rejected submission.
- [ ] Simulate offline.
- [ ] Simulate repository error.
- [ ] Simulate final program state.

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

- [ ] Evidence required sebelum completion.
- [ ] Text answer required when configured.
- [ ] Cannot complete locked step.
- [ ] Duplicate completion idempotent.
- [ ] Weight range validation.
- [ ] Decimal separator works untuk Indonesian locale.
- [ ] Final weight not accepted before allowed local window.
- [ ] Error message associated with relevant field.

## Previews

Buat preview untuk:

- [ ] Today loading.
- [ ] Today active with partial completion.
- [ ] Today complete.
- [ ] No enrollment.
- [ ] Step missing evidence.
- [ ] Step pending review.
- [ ] Step rejected.
- [ ] Timeline with hidden days.
- [ ] Leaderboard current user outside top five.
- [ ] Leaderboard final winners.
- [ ] Largest Dynamic Type.
- [ ] Dark mode.

## Tests

### Swift Testing

- [ ] Today state mapping.
- [ ] Step validation.
- [ ] Weigh-in validation.
- [ ] Progress calculation.
- [ ] Locked step behavior.
- [ ] Local participant completion.
- [ ] Final weight flow.
- [ ] Error mapping.

### UI tests

- [ ] Launch as participant.
- [ ] Join sample program.
- [ ] Submit initial weight.
- [ ] Select bundled/local test image.
- [ ] Complete one step.
- [ ] Verify progress changes.
- [ ] Open leaderboard.
- [ ] Navigate coach directory.

## Larangan scope

Jangan:

- Menghubungkan kamera production bila native wrapper belum dibuat pada Phase 06.
- Mengunggah file ke network.
- Mengimplementasikan Google login.
- Mengimplementasikan database authorization.
- Menganggap local score sebagai final server truth.
- Menambahkan HealthKit.

## Exit criteria

- [ ] Participant journey dapat didemokan tanpa internet.
- [ ] Semua primary screens memiliki meaningful mock states.
- [ ] Required evidence mencegah premature completion.
- [ ] Progress dan local leaderboard berubah setelah action.
- [ ] Dynamic Type dan VoiceOver baseline terpenuhi.
- [ ] Test lulus dan clean build.

## Progress log

### Log
