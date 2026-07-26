# Phase 04: Coach Experience UI

## Tujuan

Membangun seluruh coach-facing experience dengan mock wallet, mock programs, mock participants, local invites, dan review queue.

## External dependency status

**Lokal sepenuhnya.**

Tidak ada StoreKit transaction, Supabase, atau external QR redemption.

## Screen inventory

### Dashboard

- [ ] Public coach identity.
- [ ] Mock wallet seat balance.
- [ ] Active programs.
- [ ] Total assigned participants.
- [ ] Completion metrics.
- [ ] Missing step count.
- [ ] Pending review count.
- [ ] Quick actions.
- [ ] Offline and error states.

### Participants

- [ ] Participant list.
- [ ] Search.
- [ ] Filter by program.
- [ ] Filter by completion status.
- [ ] Filter by review status.
- [ ] Sort by progress, points, dan last activity.
- [ ] Participant row with progress.
- [ ] Empty filter state.

### Participant detail

- [ ] Profile summary.
- [ ] Program and enrollment summary.
- [ ] Initial/final weight availability.
- [ ] Daily completion timeline.
- [ ] Step submissions.
- [ ] Evidence thumbnails.
- [ ] Text answers.
- [ ] Score breakdown.
- [ ] Missing-step indicators.
- [ ] Private-data warning and access context.

### Review queue

- [ ] Pending submissions list.
- [ ] Evidence viewer.
- [ ] Step instruction context.
- [ ] Approve action.
- [ ] Reject action.
- [ ] Rejection reason required.
- [ ] Confirmation.
- [ ] Updated local score after decision.
- [ ] Undo is not required. Use a new explicit review action if allowed.

### Invite

- [ ] Available program selector.
- [ ] Mock seat balance.
- [ ] Invite capacity.
- [ ] Expiry configuration.
- [ ] Generate local opaque token.
- [ ] Generate QR image locally.
- [ ] Share sheet for local invite.
- [ ] Invite history.
- [ ] Revoke local invite.
- [ ] Exhausted and expired states.
- [ ] Explain that production seat consumption happens only after successful enrollment.

### Coach store preview

This phase only builds UI and local product fixtures.

- [ ] Seat pack cards: 10, 25, and 50.
- [ ] Local sample price text.
- [ ] Purchase CTA disabled or routed to demo confirmation.
- [ ] Purchase state previews: loading, available, purchasing, pending, success, cancelled, error.
- [ ] Purchase history mock.
- [ ] Clear label that Debug demo does not perform a real purchase.
- [ ] Do not instantiate live StoreKit transaction flow.

### Leaderboard

- [ ] Program selector.
- [ ] Top five.
- [ ] Current coach participants marker.
- [ ] Provisional and final states.
- [ ] Score detail.

### Profile

- [ ] Public coach profile editor UI.
- [ ] Photo picker placeholder or local picker.
- [ ] Bio.
- [ ] Visibility status.
- [ ] Purchase history mock.
- [ ] Settings.

## Local behavior

- [ ] Approve submission updates local participant points.
- [ ] Reject requires reason and removes local awarded points.
- [ ] Generate invite decrements nothing.
- [ ] Local mock redemption consumes seat only after successful enrollment.
- [ ] Duplicate enrollment consumes no additional seat.
- [ ] Insufficient seat state blocks local redemption.
- [ ] Coach cannot navigate to unrelated participant fixture.
- [ ] Coach store demo can simulate successful credit grant through Debug-only action.

## State architecture

Pisahkan:

- Dashboard feature state.
- Participant list state.
- Participant detail state.
- Review queue state.
- Invite composer state.
- Store preview state.
- Coach profile state.

Jangan membuat satu `CoachViewModel` besar.

## Previews

- [ ] Coach dashboard normal.
- [ ] Wallet zero.
- [ ] Pending review.
- [ ] No participants.
- [ ] Participant complete.
- [ ] Participant falling behind.
- [ ] Evidence rejected.
- [ ] Invite active.
- [ ] Invite exhausted.
- [ ] Purchase success preview.
- [ ] Largest Dynamic Type.
- [ ] Dark mode.

## Tests

### Swift Testing

- [ ] Coach filters.
- [ ] Review decision validation.
- [ ] Rejection reason required.
- [ ] Local score recalc.
- [ ] Invite capacity.
- [ ] Duplicate local enrollment.
- [ ] Wallet cannot become negative in mock.
- [ ] Unrelated participant access is blocked by mock repository contract.

### UI tests

- [ ] Launch as coach.
- [ ] Open participant detail.
- [ ] Open evidence.
- [ ] Approve submission.
- [ ] Generate local invite QR.
- [ ] Open store preview.
- [ ] Verify no real purchase prompt occurs.

## Larangan scope

Jangan:

- Mengakses App Store Connect.
- Membuat live purchase.
- Menganggap mock access check sebagai pengganti RLS.
- Mengunggah coach profile ke server.
- Menyimpan transaction id palsu sebagai production model.
- Menambahkan service secrets.

## Exit criteria

- [ ] Coach journey dapat didemokan tanpa internet.
- [ ] Review action mengubah local score.
- [ ] Invite dan QR dapat dibuat lokal.
- [ ] Store UI lengkap tetapi tidak melakukan transaksi live.
- [ ] Coach hanya melihat assigned participant fixtures.
- [ ] Test lulus dan clean build.

## Progress log

### Log
