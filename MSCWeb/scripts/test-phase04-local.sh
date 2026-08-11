#!/usr/bin/env bash
set -euo pipefail

web_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(cd "$web_root/.." && pwd)"
phase04_temp_dir="$(mktemp -d "$web_root/.phase04.XXXXXX")"
status_file="$phase04_temp_dir/supabase.env"
isolated_storage_test="$phase04_temp_dir/private-media.test.sql"
trap 'rm -f "$status_file" "$isolated_storage_test"; rmdir "$phase04_temp_dir"' EXIT

node "$web_root/scripts/prepare-phase04-storage-test.mjs" \
  "$repository_root/supabase/tests/database/002_phase09_private_media.test.sql" \
  "$isolated_storage_test"

cd "$repository_root"
DO_NOT_TRACK=1 supabase test db --local \
  "$isolated_storage_test" \
  supabase/tests/database/014_phase13_recurring_operations.test.sql

DO_NOT_TRACK=1 supabase status -o env > "$status_file"
set -a
# Supabase CLI menghasilkan assignment shell quoted untuk environment lokal.
# shellcheck disable=SC1090
. "$status_file"
set +a

node "$web_root/tests/integration/phase04-orphan-cleanup.integration.mjs"

cd "$web_root"
NEXT_PUBLIC_SUPABASE_URL="$API_URL" \
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY="$PUBLISHABLE_KEY" \
SUPABASE_TEST_SERVICE_ROLE_KEY="${SECRET_KEY:-$SERVICE_ROLE_KEY}" \
  corepack pnpm exec playwright test \
    tests/e2e/phase04-local-media.integration.spec.ts \
    --project=chromium
