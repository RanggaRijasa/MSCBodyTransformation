#!/usr/bin/env bash
set -euo pipefail

web_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(cd "$web_root/.." && pwd)"
phase08_temp_dir="$(mktemp -d "$web_root/.phase08.XXXXXX")"
status_file="$phase08_temp_dir/supabase.env"
trap 'rm -f "$status_file"; rmdir "$phase08_temp_dir"' EXIT

cd "$repository_root"
DO_NOT_TRACK=1 supabase status -o env > "$status_file"
set -a
# Supabase CLI menghasilkan assignment shell quoted untuk environment lokal.
# shellcheck disable=SC1090
. "$status_file"
set +a

case "$(node -e 'console.log(new URL(process.argv[1]).hostname)' "$DB_URL")" in
  127.0.0.1|localhost|::1) ;;
  *) echo "Dibatalkan: DB_URL bukan Supabase lokal." >&2; exit 3 ;;
esac

psql_bin="/opt/homebrew/opt/postgresql@16/bin/psql"
if [[ "$($psql_bin -X -w -At -d "$DB_URL" -c "select to_regclass('public.payment_orders') is not null")" != "t" ]]; then
  "$psql_bin" -X -w -v ON_ERROR_STOP=1 -d "$DB_URL" --single-transaction \
    -f "$web_root/supabase/migrations/20260810090000_phase06_manual_payments.sql"
fi
if [[ "$($psql_bin -X -w -At -d "$DB_URL" -c "select exists(select 1 from information_schema.columns where table_schema='public' and table_name='profiles' and column_name='profile_avatar_path')")" != "t" ]]; then
  "$psql_bin" -X -w -v ON_ERROR_STOP=1 -d "$DB_URL" --single-transaction \
    -f "$web_root/supabase/migrations/20260810100000_phase07_participant_experience.sql"
fi
if [[ "$($psql_bin -X -w -At -d "$DB_URL" -c "select to_regprocedure('private.is_participant_capable(uuid)') is not null")" != "t" ]]; then
  "$psql_bin" -X -w -v ON_ERROR_STOP=1 -d "$DB_URL" --single-transaction \
    -f "$web_root/supabase/migrations/20260810110000_phase08_coach_experience.sql"
fi

DO_NOT_TRACK=1 supabase db lint --local --level warning
DO_NOT_TRACK=1 supabase test db --local \
  MSCWeb/supabase/tests/database/phase07_program_operations.test.sql \
  MSCWeb/supabase/tests/database/phase08_coach_experience.test.sql

node "$repository_root/supabase/tests/integration/submission_review_races.mjs"
node "$repository_root/supabase/tests/integration/private_media_storage.mjs"

cd "$web_root"
node scripts/check-phase08-privacy.mjs
NEXT_PUBLIC_SUPABASE_URL="$API_URL" \
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY="$PUBLISHABLE_KEY" \
SUPABASE_TEST_SERVICE_ROLE_KEY="${SECRET_KEY:-$SERVICE_ROLE_KEY}" \
DB_URL="$DB_URL" \
AUTH_FLOW_COOKIE_SECRET="phase08-local-cookie-secret-2026-only" \
APP_ENVIRONMENT="phase08-local" \
  corepack pnpm exec playwright test \
    tests/e2e/phase08-local-coach.integration.spec.ts \
    --project=chromium
