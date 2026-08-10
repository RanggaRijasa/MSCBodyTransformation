#!/usr/bin/env bash
set -euo pipefail

web_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(cd "$web_root/.." && pwd)"
phase09_temp_dir="$(mktemp -d "$web_root/.phase09.XXXXXX")"
status_file="$phase09_temp_dir/supabase.env"
trap 'rm -f "$status_file"; rmdir "$phase09_temp_dir"' EXIT
export PATH="/opt/homebrew/opt/node@24/bin:$PATH"

cd "$repository_root"
DO_NOT_TRACK=1 supabase status -o env > "$status_file"
set -a
# Supabase CLI menghasilkan assignment shell quoted untuk lingkungan lokal.
# shellcheck disable=SC1090
. "$status_file"
set +a

case "$(node -e 'console.log(new URL(process.argv[1]).hostname)' "$DB_URL")" in
  127.0.0.1|localhost|::1) ;;
  *) echo "Dibatalkan: DB_URL bukan Supabase lokal." >&2; exit 3 ;;
esac

psql_bin="/opt/homebrew/opt/postgresql@16/bin/psql"
if [[ "$($psql_bin -X -w -At -d "$DB_URL" -c "select exists(select 1 from information_schema.columns where table_schema='public' and table_name='programs' and column_name='archive_idempotency_key')")" != "t" ]]; then
  "$psql_bin" -X -w -v ON_ERROR_STOP=1 -d "$DB_URL" --single-transaction \
    -f "$web_root/supabase/migrations/20260810120000_phase09_admin_operations.sql"
fi

DO_NOT_TRACK=1 supabase db lint --local --level warning
DO_NOT_TRACK=1 supabase test db --local \
  supabase/tests/database/011_phase11_admin_operations.test.sql \
  MSCWeb/supabase/tests/database/phase09_admin_operations.test.sql

cd "$web_root"
corepack pnpm exec vitest run \
  tests/unit/admin-program.test.ts \
  tests/component/admin-experience.test.tsx \
  tests/component/payments.test.tsx
NEXT_PUBLIC_SUPABASE_URL="$API_URL" \
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY="$PUBLISHABLE_KEY" \
SUPABASE_TEST_SERVICE_ROLE_KEY="${SECRET_KEY:-$SERVICE_ROLE_KEY}" \
DB_URL="$DB_URL" \
AUTH_FLOW_COOKIE_SECRET="phase09-local-cookie-secret-2026-only" \
APP_ENVIRONMENT="phase09-local" \
  corepack pnpm exec playwright test \
    tests/e2e/phase06-local-payments.integration.spec.ts \
    tests/e2e/phase09-local-admin.integration.spec.ts \
    --project=chromium --workers=1
