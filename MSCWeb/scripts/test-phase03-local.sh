#!/usr/bin/env bash
set -euo pipefail

web_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(cd "$web_root/.." && pwd)"

cd "$repository_root"
DO_NOT_TRACK=1 supabase test db --local \
  supabase/tests/database/005_phase10_auth_profile_foundation.test.sql \
  supabase/tests/database/006_phase10_account_deletion.test.sql \
  supabase/tests/database/007_phase11_public_guest_reads.test.sql \
  supabase/tests/database/008_phase11_authenticated_reads.test.sql
