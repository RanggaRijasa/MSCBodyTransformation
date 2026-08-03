# Phase 11: Real Data, Storage Uploads, and Server Operations

> Status: spesifikasi lama ditahan. Operasi server aktif tercantum pada
> E2E-10: Coach guard, enrollment/leaderboard atomik, typed submission, kuis,
> timbang, scoring, closure, winner snapshot, serta poster terkait program.

## Tujuan

Mengganti in-memory repository secara bertahap dengan Supabase adapters dan authoritative server operations tanpa mengubah screen contracts.

## Migration strategy

Integrasikan satu vertical slice per waktu:

1. Coach directory.
2. Program catalog.
3. Enrollment.
4. Weigh-in.
5. Step submission and evidence.
6. Progress.
7. Coach monitoring.
8. Admin CMS.
9. Scoring.
10. Leaderboard and winner lock.
11. Managed content.

Local demo adapters tetap tersedia.

## Server operations

Implementasikan atomic operation:

- [ ] Redeem program invite.
- [ ] Submit step.
- [ ] Review submission.
- [ ] Submit weigh-in.
- [ ] Admin manual enrollment.
- [ ] Publish program.
- [ ] Recalculate score.
- [ ] Lock program winners.
- [ ] Apply score adjustment.
- [ ] Coach invite creation/revoke.

## Enrollment

- [ ] Raw token hashed server-side.
- [ ] Invite row locked.
- [ ] Expiry and capacity validated.
- [ ] Existing enrollment returned idempotently.
- [ ] Wallet locked.
- [ ] Seat decremented only on successful new enrollment.
- [ ] Ledger and audit appended.
- [ ] Concurrency tests.

## Submission

- [ ] Caller owns enrollment.
- [ ] Step belongs to program.
- [ ] Server determines active day.
- [ ] Evidence ownership validated.
- [ ] Required answer validated.
- [ ] Points loaded from program step.
- [ ] Automatic/review status.
- [ ] Score recalculated.
- [ ] Duplicate submit idempotent.

## Weigh-in

- [ ] Ownership.
- [ ] Window validation.
- [ ] Decimal weight.
- [ ] Initial/final uniqueness.
- [ ] Server calculates weight points.
- [ ] Admin override requires reason and audit.
- [ ] Sensitive logs avoided.

## Storage upload integration

- [ ] Upload processed image.
- [ ] Progress reporting.
- [ ] Safe retry.
- [ ] Avoid duplicate evidence.
- [ ] Private path convention.
- [ ] Signed access only where appropriate.
- [ ] Orphan cleanup.
- [ ] Delete local temp after durable success.
- [ ] Error recovery.

## Admin CMS integration

- [ ] Draft CRUD.
- [ ] Day and step CRUD.
- [ ] Media upload.
- [ ] Server publish validation.
- [ ] Published edit restrictions.
- [ ] Audit.
- [ ] Participant preview remains local view over draft model.

## Leaderboard

- [ ] Authoritative query or RPC.
- [ ] Pagination.
- [ ] Safe participant display fields.
- [ ] Tie-break deterministic.
- [ ] Provisional/final.
- [ ] Winner snapshot.
- [ ] Client cannot submit total points.

## Realtime

Gunakan hanya bila memberi nilai jelas:

- Review queue.
- Leaderboard lightweight update.
- Enrollment count.
- Managed content refresh.

- [ ] Avoid duplicate subscriptions.
- [ ] Cancel on screen exit.
- [ ] Manual refresh remains available.
- [ ] Handle reconnect.

## Tests

- [ ] RLS matrix.
- [ ] Invite race.
- [ ] Duplicate enrollment.
- [ ] Wallet non-negative.
- [ ] Evidence access.
- [ ] Score recalc approve/reject.
- [ ] Final weight formula.
- [ ] Winner lock.
- [ ] Published program restrictions.
- [ ] UI integration against staging/local Supabase.

## Exit criteria

- [ ] Participant full flow works with real backend.
- [ ] Coach monitoring works with RLS.
- [ ] Admin CMS publishes valid program.
- [ ] Client cannot forge points.
- [ ] Private evidence inaccessible to unrelated users.
- [ ] Local demo remains operational.

## Progress log

### Log
