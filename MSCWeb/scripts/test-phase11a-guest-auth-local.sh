#!/usr/bin/env bash
set -euo pipefail

web_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(cd "$web_root/.." && pwd)"
phase11a_temp_dir="$(mktemp -d "$web_root/.phase11a-guest-auth.XXXXXX")"
status_file="$phase11a_temp_dir/supabase.env"
trap 'rm -f "$status_file"; rmdir "$phase11a_temp_dir"' EXIT
export PATH="$web_root/node_modules/.bin:/opt/homebrew/opt/node@24/bin:$PATH"

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
case "$(node -e 'console.log(new URL(process.argv[1]).hostname)' "$API_URL")" in
  127.0.0.1|localhost|::1) ;;
  *) echo "Dibatalkan: API_URL bukan Supabase lokal." >&2; exit 4 ;;
esac

cd "$web_root"
CI=1 \
NEXT_PUBLIC_SUPABASE_URL="$API_URL" \
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY="$PUBLISHABLE_KEY" \
AUTH_FLOW_COOKIE_SECRET="phase11a-guest-auth-local-cookie-secret-2026-only" \
APP_ENVIRONMENT="phase11a-guest-auth-local" \
  node_modules/.bin/playwright test \
    tests/e2e/phase11a-guest-auth-visual.spec.ts \
    "$@" --project=chromium --project=webkit --workers=1 --retries=0
