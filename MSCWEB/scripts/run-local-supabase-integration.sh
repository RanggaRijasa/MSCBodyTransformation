#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
web_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

if [ -f "$web_root/supabase/config.toml" ]; then
  authority_root=$web_root
elif [ -f "$web_root/../supabase/config.toml" ]; then
  authority_root=$(CDPATH= cd -- "$web_root/.." && pwd)
else
  echo "Canonical supabase/config.toml tidak ditemukan." >&2
  exit 1
fi

cleanup() {
  cd "$authority_root"
  supabase db reset --local >/dev/null
}
trap cleanup EXIT INT TERM

cd "$authority_root"
set -a
eval "$(supabase status -o env)"
set +a

case "${API_URL:-}" in
  http://127.0.0.1:*|http://localhost:*) ;;
  *)
    echo "Integration test ditolak: API_URL bukan loopback lokal." >&2
    exit 1
    ;;
esac

case "${DB_URL:-}" in
  postgresql://*@127.0.0.1:*/*|postgresql://*@localhost:*/*) ;;
  *)
    echo "Integration test ditolak: DB_URL bukan loopback lokal." >&2
    exit 1
    ;;
esac

psql "$DB_URL" -X -v ON_ERROR_STOP=1 \
  -f "$authority_root/supabase/tests/integration/local_service_role_fixture_grants.sql" \
  >/dev/null

cd "$web_root"
npx vitest run tests/integration/*.local.test.ts --maxWorkers=1
