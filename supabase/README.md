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

Supabase CLI `2.111.0`, Docker CLI, and Colima are installed on the current
development machine. The local PostgreSQL 17 stack, fresh reset, lint,
advisors, 89 pgTAP assertions, 16 Storage API assertions, 14 enrollment race
assertions, and 15 submission/review/quiz race assertions passed on 4 August
2026. The registration deadline migration and expanded assertions were
verified again on 5 August 2026.

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

1. Phase 10 adds Auth/profile bootstrap and RLS-safe session persistence.
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
