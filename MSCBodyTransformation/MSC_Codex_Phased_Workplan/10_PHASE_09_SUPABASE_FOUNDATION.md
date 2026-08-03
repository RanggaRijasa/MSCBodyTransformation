# Phase 09: Supabase Foundation

> Status: spesifikasi lama ditahan. Schema produksi hanya boleh dibuat dari
> published contract yang sudah lulus E2E-01 sampai E2E-09 pada workplan
> remediation. Jangan membuat tabel invite, wallet, seat credit, atau answer
> key yang terbaca Peserta.

## Tujuan

Menambahkan backend Supabase setelah local UI dan domain contract stabil. Phase ini tidak mengubah user experience utama. Fokus pada schema, RLS, storage, seed, dan adapter foundation.

## Prasyarat wajib

- Track A Phase 00 sampai 08 selesai.
- Domain models dan repository protocols stabil.
- Supabase project atau local Supabase environment tersedia.
- Current Supabase documentation dan changelog telah diperiksa.
- Tidak ada secret yang akan dimasukkan ke iOS target.

## Dependency change

Pada phase ini baru boleh:

- Menambahkan `supabase-swift`.
- Pin exact compatible version.
- Commit `Package.resolved`.
- Menambahkan configuration keys non-secret seperti project URL dan publishable key melalui configuration yang aman.

Dilarang memasukkan:

- `service_role`.
- Database password.
- App Store private key.
- Google client secret.

## Database schema

Implementasikan melalui migration:

- [ ] Enums.
- [ ] Profiles.
- [ ] Coach profiles.
- [ ] Programs.
- [ ] Program days.
- [ ] Program steps.
- [ ] Program coaches.
- [ ] Coach wallets.
- [ ] Credit ledger.
- [ ] Coach invites.
- [ ] Program enrollments.
- [ ] Weigh-ins.
- [ ] Step submissions.
- [ ] Submission evidence.
- [ ] Score adjustments.
- [ ] Purchase transactions.
- [ ] Program winners.
- [ ] Managed content.
- [ ] Audit logs.

Gunakan UUID, `timestamptz`, dan `numeric` untuk weight.

## Security baseline

- [ ] Enable RLS pada setiap exposed table sebelum grants.
- [ ] Least-privilege grants.
- [ ] Participant own-data policies.
- [ ] Assigned coach policies.
- [ ] Admin policies.
- [ ] Role cannot be self-updated.
- [ ] Security-invoker public coach view.
- [ ] Protected helper schema.
- [ ] Any security-definer function has safe search path and restricted execute.
- [ ] Run database advisors.

## Storage

Buckets:

- [ ] `avatars-public`
- [ ] `coach-public`
- [ ] `program-media`
- [ ] `step-evidence-private`
- [ ] `weigh-in-evidence-private`
- [ ] `managed-content-public`

Policies:

- [ ] Participant own evidence.
- [ ] Assigned coach read.
- [ ] Admin read.
- [ ] MIME allowlist.
- [ ] Size limit.
- [ ] Public media only when explicitly intended.

## Seed

- [ ] Admin.
- [ ] Coach.
- [ ] Participant.
- [ ] Sample active program equivalent to local fixtures.
- [ ] Sample submissions.
- [ ] Sample leaderboard inputs.
- [ ] Storage sample media if required.
- [ ] Seed is safe for local/staging only.

## Adapter foundation

- [ ] `SupabaseClientProviding`.
- [ ] Data transfer objects isolated in adapter layer.
- [ ] Mapping DTO to domain model.
- [ ] Mapping domain errors.
- [ ] Repository adapter skeletons.
- [ ] Feature UI continues using repository protocols.
- [ ] Local demo mode remains available.

## Tests

- [ ] Fresh reset from empty database.
- [ ] Seed loads.
- [ ] Participant cannot read another participant evidence.
- [ ] Coach cannot read unrelated participant.
- [ ] Admin operations are scoped.
- [ ] Role cannot self-promote.
- [ ] Storage boundary tests.
- [ ] DTO mapping tests.

## Exit criteria

- [ ] Fresh local Supabase reset succeeds.
- [ ] RLS matrix passes.
- [ ] iOS app can initialize Supabase adapter in Staging.
- [ ] Local demo still works.
- [ ] No primary UI rewrite.
- [ ] No secrets committed.

## Progress log

### Log
