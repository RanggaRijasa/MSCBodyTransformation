# Supabase program backend

This directory is the reproducible backend contract for the program flow.

- `migrations/20260802000000_program_end_to_end.sql` contains the schema,
  indexes, RLS policies, storage buckets, free-enrollment transaction, and
  Admin Coach-transfer transaction.
- `seed.sql` intentionally contains no production-like identity or private
  wellness data.
- Store credentials must be configured as server secrets. They must never be
  placed in this directory or in either mobile application.

Verification commands once Supabase CLI and Docker are installed:

```sh
supabase start
supabase db reset --local
supabase db lint --local
```

The current development machine did not have the Supabase CLI or Docker
available when this migration was created, so those commands remain an
external verification gate.

## Required production follow-up

The migration is a checked-in schema contract, not evidence of a deployed
backend. Before staging:

1. Run fresh reset, lint, and policy tests.
2. Implement and test the atomic operations listed in the remediation
   workplan, including submission, quiz reopen, review, correction, scoring,
   winner lock, poster publish, and commerce verification.
3. Put App Store Connect and Google Play credentials in server secrets only.
4. Verify wrong-Coach, capacity, duplicate callback, refund, and RLS races.
