# Phase 12: StoreKit 2, Coach Seat Packs, and Credit Verification

## Tujuan

Mengaktifkan native Apple In-App Purchase untuk coach participant-seat packs dengan StoreKit 2 dan server verification.

## Prasyarat

- Coach role and wallet backend complete.
- Final bundle identifier selected.
- App Store Connect access.
- IAP products created.
- Supabase Edge Functions available.
- App Store server credentials configured server-side only.

## Product model

Consumable seat packs:

```text
com.example.msc.coach_seats_10
com.example.msc.coach_seats_25
com.example.msc.coach_seats_50
```

Ganti identifier placeholder sebelum release.

## Client StoreKit implementation

- [ ] Product loader.
- [ ] Product display using StoreKit localized price.
- [ ] Purchase state machine.
- [ ] Success.
- [ ] User cancellation.
- [ ] Pending.
- [ ] Unverified.
- [ ] Interrupted purchase.
- [ ] `Transaction.updates` listener.
- [ ] Recovery after relaunch.
- [ ] Purchase history from backend.
- [ ] Finish transaction only after durable credit grant confirmation.
- [ ] No private key in app.

## Backend verification

Edge Function:

- [ ] Authenticate Supabase user.
- [ ] Verify coach role.
- [ ] Verify Apple-signed transaction.
- [ ] Validate bundle id.
- [ ] Validate product id.
- [ ] Validate environment.
- [ ] Validate transaction state.
- [ ] Product-to-credit quantity mapped server-side.
- [ ] Idempotent transaction insert.
- [ ] Wallet row lock.
- [ ] Credit ledger append.
- [ ] Audit.
- [ ] Return authoritative balance.

Never accept seat quantity from client.

## App Store Server Notifications V2

- [ ] Signed payload verification.
- [ ] Test notification.
- [ ] Refund.
- [ ] Revocation.
- [ ] Idempotent processing.
- [ ] Update purchase status.
- [ ] Remove only unused credits automatically.
- [ ] Consumed refunded credits create admin review flag.
- [ ] Durable processing before success response.

## StoreKit testing

### Local configuration

- [ ] Add `Products.storekit`.
- [ ] Configure seat packs.
- [ ] Success.
- [ ] Cancel.
- [ ] Pending.
- [ ] Interrupted.
- [ ] Duplicate transaction simulation.
- [ ] Refund simulation.
- [ ] Relaunch recovery.

### Sandbox and TestFlight

- [ ] Sandbox account.
- [ ] Physical device.
- [ ] Product availability.
- [ ] Currency localization.
- [ ] Backend verification.
- [ ] Wallet updates once.
- [ ] Enrollment consumes one seat.
- [ ] Duplicate enrollment no extra seat.
- [ ] Refund behavior.
- [ ] Review notes prepared.

## Security rules

- [ ] No client-only credit grant.
- [ ] No service role in app.
- [ ] No App Store private key in app.
- [ ] Transaction id unique.
- [ ] Sandbox and production separated.
- [ ] Wallet client read-only.
- [ ] Ledger append-only.

## Exit criteria

- [ ] Verified purchase grants exact credits once.
- [ ] Duplicate callbacks grant nothing extra.
- [ ] Pending purchase recovers.
- [ ] Wallet never negative.
- [ ] Seat consumed only on successful enrollment.
- [ ] Refund path tested.
- [ ] TestFlight purchase flow passes.

## Progress log

### Log
