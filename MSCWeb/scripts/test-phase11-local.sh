#!/usr/bin/env bash
set -euo pipefail

web_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(cd "$web_root/.." && pwd)"
phase11_temp_dir="$(mktemp -d "$web_root/.phase11.XXXXXX")"
status_file="$phase11_temp_dir/supabase.env"
trap 'rm -f "$status_file"; rmdir "$phase11_temp_dir"' EXIT
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
if [[ "$($psql_bin -X -w -At -d "$DB_URL" -c "select to_regclass('public.web_push_subscriptions') is not null")" != "t" ]]; then
  "$psql_bin" -X -w -v ON_ERROR_STOP=1 -d "$DB_URL" --single-transaction \
    -f "$web_root/supabase/migrations/20260810231805_phase11_web_push_and_abuse_controls.sql"
fi

DO_NOT_TRACK=1 supabase db lint --local --level warning
DO_NOT_TRACK=1 supabase test db --local \
  MSCWeb/supabase/tests/database/phase11_pwa_security.test.sql

cd "$web_root"
node scripts/generate-phase11-sbom.mjs
node scripts/check-phase11-security.mjs
corepack pnpm format:check
corepack pnpm lint
corepack pnpm typecheck
corepack pnpm test
corepack pnpm build
node scripts/check-phase04-bundle.mjs
node scripts/check-phase11-performance.mjs
corepack pnpm exec playwright test \
  --config=playwright.phase11.config.ts \
  tests/e2e/phase11-pwa-quality.spec.ts
corepack pnpm exec playwright test \
  tests/e2e/phase02a-landing.visual.spec.ts \
  --project=chromium
corepack pnpm exec playwright test \
  --config=playwright.gallery.config.ts \
  tests/gallery/gallery.smoke.spec.ts \
  --grep 'capture marketing' \
  --project=chromium
