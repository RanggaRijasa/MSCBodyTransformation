# Supabase program backend

This directory is the reproducible backend contract for the program flow.

- `COLIMA_LOCAL_DEVELOPMENT.md` documents the daily start, status, shutdown,
  data-preservation, and troubleshooting workflow for Colima and local
  Supabase.
- `migrations/20260802000000_program_end_to_end.sql` contains the schema,
  indexes, RLS policies, storage buckets, free-enrollment transaction, and
  Admin Coach-transfer transaction.
- `migrations/20260804043720_phase09_data_api_hardening.sql` removes implicit
  Data API access, adds the Phase 09 least-privilege grants matrix, restricts
  privileged helper execution, and remediates the hosted
  `public.rls_auto_enable()` execute warning when that helper exists.
- `migrations/20260804050012_phase09_policy_performance_hardening.sql` splits
  broad Admin policies by operation and adds the foreign-key indexes reported
  by local advisors.
- `migrations/20260804050646_phase09_private_media_hardening.sql` binds private
  object paths to Participant, enrollment, submission, and question rows,
  restricts uploads to normalized JPEG, and adds owner/Coach/Admin policies.
- `migrations/20260804054430_phase09_vertical_slice_server_operations.sql`
  adds idempotent submission preparation/finalization, automatic quiz
  evaluation, Coach review, authoritative score refresh, and auditable orphan
  media cleanup candidates.
- `migrations/20260805013707_program_registration_deadline.sql` adds the
  optional exact registration cutoff, blocks Participant self-enrollment at
  the server boundary, and adds an audited Admin enrollment RPC that bypasses
  only the cutoff.
- `migrations/20260805044617_phase10_auth_profile_and_session_foundation.sql`
  bootstraps one provisional Participant profile per Auth identity, adds
  member-level/account-purpose/onboarding state, exposes allowlisted profile
  and finalization RPCs, revalidates pending program status/cutoff/capacity,
  and schedules provisional-identity cleanup.
- `migrations/20260805055830_phase10_immediate_account_deletion.sql` and
  `20260805061953_phase10_account_deletion_retention_safety.sql` require a
  recently created Auth session, prepare private-media cleanup, remove or
  anonymize account-owned data, preserve redacted financial/audit history,
  and make profile references safe for hard deletion.
- `migrations/20260806053130_phase11_public_guest_reads.sql` exposes fixed
  public projections for program catalog, approved Coaches, leaderboard
  totals, locked winners, and published posters. Guest requests use the
  publishable key as `anon`; private base tables remain ungranted.
- `migrations/20260806062936_phase11_authenticated_reads.sql` adds narrow
  current-user projections for assigned Coach, program-day access, and
  role-specific dashboard counts.
- `migrations/20260806064919_phase11_authenticated_score_privacy.sql`
  restricts direct score breakdown rows to the owning Participant, assigned
  Coach, or Admin; public leaderboard totals continue through the safe
  projection.
- `functions/delete-account/index.ts` owns the server-only Storage cleanup and
  Auth Admin hard-delete boundary. The iOS client never receives the service
  credential.
- `tests/database` contains transactional pgTAP grants, RLS, and private-media
  tests.
- `tests/integration` contains local Auth/Storage API and concurrent enrollment
  and submission/review checks. The iOS setup/verifier scripts prove one real
  local adapter vertical slice. Fixtures are temporary and never copied from
  production.
- `seed.sql` intentionally contains no production-like identity or private
  wellness data.
- Store credentials must be configured as server secrets. They must never be
  placed in this directory or in either mobile application.

Local verification commands:

```sh
supabase start
supabase db reset --local
supabase db lint --local --level warning --fail-on error
supabase db advisors --local --type all --level warn --fail-on error
supabase test db --local supabase/tests/database
```

Phase 10 uses confirmed-email behavior locally. After changing
`[auth.email].enable_confirmations`, restart the local stack explicitly so the
Auth container receives the configuration:

```sh
supabase stop
supabase start
supabase db reset --local
```

Then load local-only status values into the current shell without writing
them to files and run the Auth lifecycle test:

```sh
set -a
eval "$(supabase status -o env)"
set +a
node supabase/tests/integration/auth_lifecycle.mjs
node supabase/tests/integration/public_guest_reads.mjs
node supabase/tests/integration/authenticated_reads.mjs
```

The script rejects non-loopback URLs, verifies PKCE email confirmation,
protected profile updates, role hardening, refresh rotation, password
recovery, login/logout, recent reauthentication, immediate account deletion,
and removes its temporary identities. An interrupted run cleans up only
identities using the dedicated `phase10-…@test.invalid` pattern. It does not
print a password, token, email address, or Coach QR.

Supabase CLI `2.111.0`, Docker CLI, and Colima are installed on the current
development machine. The local PostgreSQL 17 stack, fresh reset, lint,
advisors, 115 pgTAP assertions, 16 Storage API assertions, 14 enrollment race
assertions, and 15 submission/review/quiz race assertions passed on 4 August
2026. Phase 10 lint, advisors, 139 pgTAP assertions, and 22 Auth lifecycle
checks were verified on 5 August 2026 after the explicitly authorized local
stack restart. The complete migration chain, including both account-deletion
migrations, then passed an explicitly authorized fresh local reset.

Local confirmation and password-recovery messages are inspected at the
Mailpit URL reported by `supabase status`. The application callback is
`mscbodytransformation://auth/callback`; the scheme and Sign in with Apple
capability are registered in the Xcode target. The native-only Apple provider
is enabled locally with `com.ranggar.MSCBodyTransformation` as its client ID
and nonce validation enabled; it does not use a Services ID or web client
secret. Manual Apple sign-in, hosted callback/deployment, and physical-device
validation remain active production gates. Only custom SMTP/sender-domain
setup is **SKIPPED FOR NOW**;
email/password entry points must remain hidden until delivery and redirect
behavior are verified.

The iOS Simulator can reach the local stack through `127.0.0.1`. A physical
iPhone must use a reachable private Mac address supplied only through Debug
environment configuration, with Colima/Supabase ports reachable on that
network. Never commit a temporary LAN address or place it in Release
configuration. Under the approved local-only environment strategy, remote QA
is not available while the Mac and local stack are offline.

Immediate account deletion is served by
`supabase/functions/delete-account/index.ts`. The client must reauthenticate
first. The server removes owned Storage objects through the Storage API,
redacts and removes application data, preserves anonymized financial/audit
records, and hard-deletes the Auth identity through the server-only Admin API.
Admin self-deletion is denied, and a Coach with assigned participants must be
transferred by Admin first. The service-role credential never belongs in the
app or client configuration.

The iOS Phase 09 boundary uses native Foundation `URLSession` instead of
adding a package dependency. `supabase-swift` `2.54.1` was checked against its
official release and compatibility requirements, but is not required by this
vertical slice. Debug configuration accepts only loopback Supabase URLs and a
public local key; Release cannot select the local configuration. The focused
iOS suite, including the live catalog → enrollment → private upload →
submission → Coach review → score path, passed with nine assertions/tests and
the persisted result was verified through the local Data API.

## Required production follow-up

The migration is a checked-in schema contract, not evidence of a deployed
backend.

Environment policy:

- Development uses the local Supabase stack through Docker and Colima.
- Hosted `main` is production and must not receive development migrations.
- Supabase Branching and a second hosted development project are not used.
- Debug clients may use local credentials returned by `supabase status`.
- Release clients must never contain local endpoints or sensitive server
  credentials.

## Phase 09.5 handoff

Phase 09.5 is intentionally local UI/mock and adds no database migration:

- Guest is logged out; it is not a database role and does not create an
  anonymous Auth identity.
- Every fake registration creates Participant first.
- Member level, Coach eligibility, Coach application, payment preview, Admin
  decision, protected role, and three-month entitlement are separate states.
- A fake verified payment never grants Coach access.

Required backend work remains:

1. Phase 10 local Auth/profile bootstrap and RLS-safe session persistence are
   implemented, including immediate local account deletion; provider/hosted
   validation remains gated.
2. Phase 11 adds public-safe Guest reads, Coach application tables/policies,
   and atomic audited approve/reject operations.
3. Phase 12 adds StoreKit verification, unique transactions, manual
   three-month entitlement, expiry/renewal/revocation, and refund policy.

Do not add `anon` grants to private profiles, applications, payments,
entitlements, weights, submissions, or private media. Explicit Data API
grants remain mandatory because automatic table exposure is disabled.

Before production deployment:

1. Complete the broader Phase 11 operations: publish/duplicate program, paid
   enrollment handoff, quiz reopen, weigh-in correction, winner lock, and
   poster publication.
2. Complete Phase 12 server-side StoreKit and Play Billing verification.
3. Repeat fresh reset, lint, advisors, pgTAP, Storage API, and all relevant
   race tests.
4. Review the exact migration diff before applying it to hosted `main`.
5. Put App Store Connect and Google Play credentials in server secrets only.
6. Verify hosted-only callbacks and production configuration through an
   explicit release gate. Never use hosted `main` for development experiments.
