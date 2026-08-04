# Phase 14: Android Handoff

Status: kontrak siap; implementasi Android belum dimulai.

## Sumber kontrak

- `Contracts/program-api-v1.openapi.yaml`
- `PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md`
- `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`
- migration Supabase di `supabase/migrations`

Android memakai Kotlin, Jetpack Compose, dan backend/entitlement yang sama.
Business rule authoritative tidak disalin ke UI Android.

## Cakupan

- Mapping enum dan model OpenAPI.
- State per enrollment untuk beberapa program aktif.
- Same-Coach QR guard tanpa field kode manual.
- Renderer artikel, video, form, kuis, unggah foto, dan timbang.
- Satu percobaan kuis serta hasil tanpa answer key Peserta.
- Google Play Billing one-time product unik per cohort.
- Purchase token diverifikasi backend sebelum entitlement/enrollment.
- Cross-platform entitlement mencegah pembelian ganda.
- Refund/revocation melalui Real-time Developer Notifications.

## Tidak dibawa ke Android

- Program invite atau expiry/capacity invite.
- Wallet Coach, seat credit, dan seat pack.
- Approval enrollment.
- Bukti foto terpisah.
- Poin per langkah.
- Timbang onboarding global.

## Exit criteria

- Contract test Kotlin lulus terhadap sample payload OpenAPI.
- Purchase iOS terlihat sebagai entitlement Android dan sebaliknya.
- Wrong-Coach QR ditolak sebelum billing.
- Program duplikat memakai Product ID Google yang baru.
- RLS dan server scoring tetap menjadi sumber otoritatif.

Seluruh exit criteria di atas memerlukan project Android, Supabase staging,
dan Play Console test track; karena itu masih menjadi external gate.
