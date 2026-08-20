#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
web_root="$repository_root/MSCWEB"

cd "$repository_root"
set -a
eval "$(supabase status -o env)"
set +a

case "$DB_URL" in
  postgresql://*@127.0.0.1:*/*|postgresql://*@localhost:*/*) ;;
  *)
    echo "Menolak menerapkan migrasi: target bukan Supabase lokal." >&2
    exit 1
    ;;
esac

for migration in "$web_root"/supabase/migrations/*.sql; do
  echo "Menerapkan $(basename "$migration")"
  psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$migration"
done

echo "Migrasi MSCWEB lokal selesai."

