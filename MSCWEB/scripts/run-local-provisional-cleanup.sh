#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$repository_root"
set -a
eval "$(supabase status -o env)"
set +a

case "$API_URL" in
  http://127.0.0.1:*|http://localhost:*) ;;
  *) echo "Menolak cleanup: target bukan Supabase lokal." >&2; exit 1 ;;
esac

node MSCWEB/scripts/process-local-provisional-cancellations.mjs

