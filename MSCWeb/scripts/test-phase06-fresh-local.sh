#!/usr/bin/env bash
set -euo pipefail

if [[ "${ALLOW_LOCAL_DB_RESET:-}" != "phase06" ]]; then
  echo "Dibatalkan: set ALLOW_LOCAL_DB_RESET=phase06 setelah approval eksplisit pengguna." >&2
  exit 2
fi

web_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(cd "$web_root/.." && pwd)"
phase06_temp_dir="$(mktemp -d "$web_root/.phase06-fresh.XXXXXX")"
status_file="$phase06_temp_dir/supabase.env"
trap 'rm -f "$status_file"; rmdir "$phase06_temp_dir"' EXIT

cd "$repository_root"
DO_NOT_TRACK=1 supabase status -o env > "$status_file"
set -a
# shellcheck disable=SC1090
. "$status_file"
set +a

case "$(node -e 'console.log(new URL(process.argv[1]).hostname)' "$DB_URL")" in
  127.0.0.1|localhost|::1) ;;
  *) echo "Dibatalkan: DB_URL bukan Supabase lokal." >&2; exit 3 ;;
esac

DO_NOT_TRACK=1 supabase db reset --local

DO_NOT_TRACK=1 supabase status -o env > "$status_file"
set -a
# shellcheck disable=SC1090
. "$status_file"
set +a

psql_bin="/opt/homebrew/opt/postgresql@16/bin/psql"
"$psql_bin" -X -w -v ON_ERROR_STOP=1 -d "$DB_URL" --single-transaction \
  -f "$web_root/supabase/migrations/20260810090000_phase06_manual_payments.sql"

DO_NOT_TRACK=1 supabase db lint --local --level warning
DO_NOT_TRACK=1 supabase test db --local \
  MSCWeb/supabase/tests/database/phase06_manual_payments.test.sql
