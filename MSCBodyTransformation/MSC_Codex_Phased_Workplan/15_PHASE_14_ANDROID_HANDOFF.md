# Phase 14: Android Handoff Package

## Tujuan

Mempersiapkan porting ke Kotlin dan Jetpack Compose tanpa membangun Android pada phase ini.

## Prinsip

- Backend tetap satu.
- UI Android dibangun ulang native.
- Business contracts platform-neutral.
- Android tidak mengonversi SwiftUI secara otomatis.
- Google Play Billing akan menjadi commerce adapter terpisah.
- Apple-specific tables tidak boleh merusak core program model.

## Deliverables

- [ ] Data dictionary.
- [ ] Database relationship document.
- [ ] RPC and Edge Function contracts.
- [ ] Request and response examples.
- [ ] Auth flow document.
- [ ] Role and permission matrix.
- [ ] RLS behavior matrix.
- [ ] Storage bucket and path rules.
- [ ] Scoring specification.
- [ ] Timezone and visibility specification.
- [ ] Invite specification.
- [ ] Leaderboard tie-break specification.
- [ ] Commerce abstraction notes.
- [ ] JSON fixtures for every model.
- [ ] Screen inventory.
- [ ] User journeys.
- [ ] Error catalog.
- [ ] Accessibility expectations.
- [ ] Android backlog.

## Android target stack

- Kotlin.
- Jetpack Compose.
- Coroutines.
- ViewModel.
- Repository pattern.
- Supabase Kotlin.
- Credential Manager for Google sign-in.
- Google Play Billing for seat packs.
- Native camera/photo APIs.
- ML Kit or native supported QR solution based on current Android guidance.
- Material system appropriate to supported Android versions.

## Contract guardrails

- [ ] Stable English enum raw values.
- [ ] ISO-compatible date/timestamp.
- [ ] UUID ids.
- [ ] Integer points.
- [ ] Decimal/numeric weight.
- [ ] No iOS UI concepts in core schema.
- [ ] Apple transaction data isolated.
- [ ] Server authoritative scoring.
- [ ] Server authoritative role.
- [ ] Server authoritative seat grant and consumption.
- [ ] Same user identity model where provider linking permits.

## Commerce migration note

Prepare for:

```text
commerce_transactions
- platform: app_store | play_store
- external_transaction_id
- product_id
- verified_state
- environment
- user_id
```

Do not migrate blindly if production data exists. Produce a reviewed migration plan.

## Android backlog groups

1. Project bootstrap.
2. Domain model mapping.
3. Auth.
4. Participant UI.
5. Coach UI.
6. Admin UI decision.
7. Media and QR.
8. Supabase adapters.
9. Google Play Billing.
10. Testing.
11. Security.
12. Play Store release.

## Exit criteria

- [ ] Android developer can implement without reading SwiftUI source for business rules.
- [ ] API contracts have examples.
- [ ] JSON fixtures decode on both platforms.
- [ ] Commerce boundary is documented.
- [ ] Known iOS-only behavior has Android alternative notes.
