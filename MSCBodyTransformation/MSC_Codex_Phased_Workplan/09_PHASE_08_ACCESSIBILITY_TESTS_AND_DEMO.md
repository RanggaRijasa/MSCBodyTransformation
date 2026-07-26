# Phase 08: Accessibility, Reliability, UI Tests, and Offline Demo

## Tujuan

Menjadikan Track A sebagai prototype native yang stabil, dapat didemokan end-to-end, mudah direview, dan siap menerima backend adapter tanpa perubahan UI besar.

## External dependency status

**Tidak ada external integration.**

Semua test menggunakan mock repositories, fixtures, local media, dan launch arguments.

## Offline demo scenarios

Buat Debug-only scenario launcher:

- [ ] Logged out.
- [ ] Participant onboarding.
- [ ] Participant no program.
- [ ] Participant day 1.
- [ ] Participant mid-program.
- [ ] Participant final weigh-in.
- [ ] Participant final leaderboard.
- [ ] Coach wallet zero.
- [ ] Coach active participants.
- [ ] Coach review queue.
- [ ] Admin draft CMS.
- [ ] Admin active program.
- [ ] Admin winner lock.
- [ ] Loading.
- [ ] Offline.
- [ ] Permission denied.
- [ ] Generic repository error.

Setiap scenario harus deterministic.

## Bahasa dan localization audit

- [ ] Seluruh copy production-facing berbahasa Indonesia.
- [ ] Tidak ada English placeholder yang tertinggal.
- [ ] Angka, berat, tanggal, waktu, dan harga menggunakan locale `id-ID`.
- [ ] Text Bahasa Indonesia tidak terpotong pada Dynamic Type besar.
- [ ] Istilah mengikuti `UI_REFERENCE_SHEET.md`.

## Accessibility audit

### Dynamic Type

- [ ] Test standard sizes.
- [ ] Test largest accessibility sizes.
- [ ] No clipped primary action.
- [ ] No horizontal text truncation for required content.
- [ ] Forms remain navigable.
- [ ] Leaderboard remains understandable without compressed columns.

### VoiceOver

- [ ] Logical reading order.
- [ ] Icon-only button labels.
- [ ] Progress value and context.
- [ ] Rank value.
- [ ] Submission state.
- [ ] Locked day explanation.
- [ ] Evidence image accessible name.
- [ ] Decorative images hidden.
- [ ] QR has useful description without exposing token.
- [ ] Validation associated with field.

### Visual accessibility

- [ ] Light mode.
- [ ] Dark mode.
- [ ] Increase Contrast.
- [ ] Reduce Transparency.
- [ ] Differentiate Without Color.
- [ ] Minimum target size.
- [ ] System colors remain legible.

### Motion

- [ ] Reduce Motion disables unnecessary celebration.
- [ ] Leaderboard changes do not cause disorienting motion.
- [ ] Navigation uses system behavior.
- [ ] Loading indicators remain accessible.

## Reliability

- [ ] Cancellation-safe async tasks.
- [ ] Retry action for recoverable errors.
- [ ] Debounce search where needed.
- [ ] No duplicate repository loads caused by body recomputation.
- [ ] Stable list identity.
- [ ] No unbounded image memory.
- [ ] Local temporary files cleaned.
- [ ] Debug fixture reset works.
- [ ] App survives background/foreground.
- [ ] Fake session restoration.

## Performance

- [ ] Use lazy containers.
- [ ] Thumbnail instead of original image in lists.
- [ ] Avoid expensive work on main actor.
- [ ] Profile participant Today scrolling.
- [ ] Profile coach participant list.
- [ ] Profile admin day/step editor.
- [ ] Profile Liquid Glass candidates on iOS 26 runtime.
- [ ] Remove glass where it causes avoidable performance cost.

## Swift Testing completion

Required suites:

- [ ] Domain models.
- [ ] Fixture decoding.
- [ ] Validation.
- [ ] Scoring.
- [ ] Ranking.
- [ ] Timezone and visibility.
- [ ] Participant feature states.
- [ ] Coach feature states.
- [ ] Admin editor.
- [ ] QR parser.
- [ ] Media decisions.
- [ ] Role navigation.
- [ ] Error mapping.

## XCTest UI flows

- [ ] Participant full local flow.
- [ ] Coach review flow.
- [ ] Coach invite generation.
- [ ] Admin draft creation.
- [ ] Admin participant preview.
- [ ] Admin manual enrollment local simulation.
- [ ] Leaderboard and winner display.
- [ ] Role switch test.
- [ ] Dark mode launch.
- [ ] Accessibility size launch.

Use launch arguments untuk fixture scenario, jangan menulis test yang bergantung pada test sebelumnya.

## Device matrix

- [ ] Small supported iPhone simulator iOS 17.
- [ ] Standard current simulator.
- [ ] iOS 26 simulator untuk Liquid Glass.
- [ ] iPad simulator.
- [ ] Physical device untuk camera and scanning sanity.
- [ ] Offline mode.

## Track A demo checklist

Participant:

- [ ] Join local program.
- [ ] Submit initial weight.
- [ ] Complete step with local photo.
- [ ] See points and progress.
- [ ] Submit final weight.
- [ ] See final rank.

Coach:

- [ ] View dashboard.
- [ ] View participant.
- [ ] Review evidence.
- [ ] Generate QR.
- [ ] Open store preview.

Admin:

- [ ] Create program draft.
- [ ] Add days and steps.
- [ ] Preview participant UI.
- [ ] Simulate publish.
- [ ] Manual enroll.
- [ ] Lock winners.
- [ ] Add winner banner.

## Documentation deliverables

- [ ] `DEMO_GUIDE.md`.
- [ ] `ARCHITECTURE.md`.
- [ ] `DOMAIN_GLOSSARY.md`.
- [ ] `MOCK_DATA_GUIDE.md`.
- [ ] `UI_SCREEN_INVENTORY.md`.
- [ ] `BACKEND_ADAPTER_CHECKLIST.md`.
- [ ] Screenshots optional, but no snapshot test dependency required.

## Exit criteria

- [ ] Semua Track A flows dapat digunakan tanpa jaringan.
- [ ] No critical accessibility blockers.
- [ ] Critical UI tests lulus.
- [ ] Unit tests lulus.
- [ ] No Supabase dependency.
- [ ] No OAuth configuration.
- [ ] No live StoreKit transaction.
- [ ] UI siap menerima real repository adapters.

## Progress log

### Log
