#!/usr/bin/env bash
set -euo pipefail

web_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(cd "$web_root/.." && pwd)"
phase05_temp_dir="$(mktemp -d "$web_root/.phase05.XXXXXX")"
status_file="$phase05_temp_dir/supabase.env"
trap 'rm -f "$status_file"; rmdir "$phase05_temp_dir"' EXIT

cd "$repository_root"
DO_NOT_TRACK=1 supabase test db --local \
  supabase/tests/database/004_program_registration_deadline.test.sql \
  supabase/tests/database/007_phase11_public_guest_reads.test.sql

DO_NOT_TRACK=1 supabase status -o env > "$status_file"
set -a
# Supabase CLI menghasilkan assignment shell quoted untuk environment lokal.
# shellcheck disable=SC1090
. "$status_file"
set +a

psql_bin="/opt/homebrew/opt/postgresql@16/bin/psql"
if [[ "$($psql_bin -X -w -At -d "$DB_URL" -c "select to_regclass('public.payment_orders') is not null")" != "t" ]]; then
  "$psql_bin" -X -w -v ON_ERROR_STOP=1 -d "$DB_URL" --single-transaction \
    -f "$web_root/supabase/migrations/20260810090000_phase06_manual_payments.sql"
fi

node "$web_root/tests/integration/phase05-enrollment-races.integration.mjs"

cd "$web_root"
NEXT_PUBLIC_SUPABASE_URL="$API_URL" \
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY="$PUBLISHABLE_KEY" \
SUPABASE_TEST_SERVICE_ROLE_KEY="${SECRET_KEY:-$SERVICE_ROLE_KEY}" \
DB_URL="$DB_URL" \
AUTH_FLOW_COOKIE_SECRET="phase05-local-cookie-secret-2026-only" \
APP_ENVIRONMENT="phase05-local" \
  corepack pnpm exec playwright test \
    tests/e2e/phase05-local-programs.integration.spec.ts \
    --project=chromium
