# Phase 11 Gate 11.0 Baseline

Tanggal: 6 Agustus 2026  
Environment: Supabase lokal melalui Colima dan Docker  
Hosted `main`: tidak disentuh

## Perubahan Supabase yang relevan

- CLI lokal: `2.111.0`.
- Data API sekarang mewajibkan `GRANT` eksplisit untuk object baru. RLS tetap
  menjadi boundary row-level yang terpisah.
- Root OpenAPI Data API tidak boleh diakses atau diandalkan melalui anon key.
- Self-hosted Supabase dijadwalkan mengganti gateway default dari Kong ke
  Envoy pada minggu 9 Agustus 2026. Adapter aplikasi tidak boleh bergantung
  pada nama service gateway atau satu status sukses khusus seperti `201`.

## Fresh baseline

| Verifikasi | Hasil |
|---|---|
| `supabase db reset --local` | Lulus; 10 migration dan seed diterapkan |
| `supabase migration list --local` | 10 local migration cocok dengan database lokal |
| `supabase test db --local supabase/tests/database` | Lulus; 139 assertion dalam 6 file |
| `auth_lifecycle.mjs` | Lulus; 22 checks |
| `private_media_storage.mjs` | Lulus; 16 assertions |
| `enrollment_races.mjs` | Lulus; 14 assertions |
| `submission_review_races.mjs` | Lulus; 15 assertions |
| `supabase db lint --local --level warning --fail-on error` | Lulus; tidak ada schema error |
| `supabase db advisors --local --type all --level warn --fail-on error` | Lulus; tidak ada issue |
| `supabase db diff --local` | Lulus; tidak ada schema drift |
| Simulator build dan launch | Lulus; tanpa warning atau error |
| Swift tests | Lulus; 176 tests |
| OpenAPI YAML parse | Lulus untuk baseline contract |

Catatan baseline: pembuatan Auth user sejak Phase 10 otomatis membuat profile
provisional. Integration fixture Phase 09 diubah dari insert menjadi upsert
berdasarkan `user_id` agar mengonfigurasi row bootstrap yang sudah ada, bukan
mencoba membuat profile kedua.

## Inventaris object dan privilege

### Table dan view

- Schema `public` mempunyai 21 table dan tidak mempunyai view.
- Seluruh 21 table mempunyai RLS aktif.
- Role `anon` tidak mempunyai table grant pada schema `public`.
- Role `authenticated` hanya mempunyai grant yang diperlukan baseline:
  - `SELECT` pada data own/related yang dibatasi RLS;
  - `SELECT`, `INSERT`, `UPDATE`, dan `DELETE` pada aggregate definisi program
    yang seluruh mutation policy-nya mensyaratkan `private.is_admin()`.
- `program_store_products` dan `score_adjustments` tidak dapat dimutasi oleh
  client authenticated melalui direct table grant.
- `service_role` mempunyai akses server-side dan tidak dipakai aplikasi iOS.
- Bucket `question-photos` tetap privat. Read/write dibatasi policy ownership,
  assigned Coach, atau Admin. `public-media` hanya membuka object yang memang
  ditujukan sebagai media publik.

### Schema boundary

- `anon`, `authenticated`, dan `service_role` tidak mempunyai `USAGE` atau
  `CREATE` pada schema `private`.
- Ketiga role mempunyai `USAGE`, tetapi tidak mempunyai `CREATE`, pada schema
  `public`.
- Default privilege object milik role `postgres` tidak memberi Data API DML
  atau function execute kepada `anon`/`authenticated`; migration baru tetap
  wajib melakukan revoke/grant eksplisit per object.

### Function boundary

Seluruh function `SECURITY DEFINER` memakai fixed `search_path=""`.

Function publik yang dapat dipanggil hanya oleh `authenticated` dan owner
`postgres`:

- `admin_enroll_participant`
- `admin_transfer_coach`
- `apply_provider_profile_defaults`
- `cancel_my_provisional_identity`
- `enroll_free_program`
- `finalize_my_account_deletion`
- `finalize_participant_onboarding`
- `list_orphan_question_photos`
- `pending_program_enrollment_availability`
- `prepare_coach_application_handoff`
- `prepare_my_account_deletion`
- `prepare_step_submission`
- `record_orphan_question_photo_cleanup`
- `refresh_enrollment_score`
- `review_step_submission`
- `submit_step_answers`
- `update_my_profile`

Tidak ada function `public` atau `private` yang executable oleh `PUBLIC` atau
`anon`. Helper pada schema `private` tidak dapat dipanggil langsung oleh Data
API karena schema usage juga ditolak.

## Rekonsiliasi endpoint

| Operation | Status Phase 11 | Catatan |
|---|---|---|
| `deleteCurrentAccount` | `existing-needs-wiring` | Sudah dipakai Phase 10; tidak diubah Phase 11 |
| `listPublicPrograms` | `existing-needs-wiring` | Direct authenticated read ada; public-safe Guest projection baru diperlukan |
| `duplicateProgram` | `new-phase11` | Belum authoritative |
| `publishProgram` | `new-phase11` | Belum authoritative |
| `enrollFreeProgram` | `existing-needs-wiring` | RPC ada; perlu hardening dan feature wiring |
| `adminEnrollParticipant` | `existing-needs-wiring` | RPC ada; perlu feature wiring |
| `verifyAppleProgramPurchase` | `deferred-phase12` | Store verification dan entitlement |
| `verifyGoogleProgramPurchase` | `deferred-phase12` | Store verification dan entitlement |
| `submitStep` | `existing-needs-wiring` | Prepare/finalize RPC ada |
| `reviewSubmission` | `existing-needs-wiring` | Review dan score refresh RPC ada |
| `submitWeighIn` | `new-phase11` | Belum authoritative |
| `correctWeighIn` | `new-phase11` | Belum authoritative |
| `reopenQuizAttempt` | `new-phase11` | Belum authoritative |
| `transferParticipantCoach` | `existing-needs-wiring` | RPC ada; perlu feature wiring |
| `lockProgramWinners` | `new-phase11` | Belum authoritative |
| `publishWinnerPoster` | `new-phase11` | Belum authoritative |

Public program, Coach directory, leaderboard, locked winners, dan published
poster reads akan ditambahkan sebagai contract Phase 11.1. Coach application
draft/submit/Admin decision akan ditambahkan pada Phase 11.3. Tidak ada
operation `deferred-phase12` yang boleh memperoleh implementation shortcut di
Phase 11.

## Stable error catalog

| Kategori | Stable code | Kepemilikan |
|---|---|---|
| Authentication required/expired | `authentication_required`, `session_expired` | Server dan client transport |
| Authorization | `permission_denied` | Server |
| General validation | `validation_failed` | Server |
| Resource conflict | `resource_conflict` | Server |
| Registration cutoff | `registration_closed` | Server |
| Capacity | `program_full` | Server |
| Duplicate/idempotent replay | `already_exists`, `idempotency_key_mismatch` | Server |
| Offline | `offline` | Client transport |
| Timeout | `request_timeout` | Client transport |
| Unknown | `unknown_error` | Client boundary; raw server error tidak ditampilkan |

Code domain yang lebih spesifik seperti `coach_qr_invalid`,
`coach_mismatch`, `payment_required`, `answers_incomplete`, dan
`submission_already_reviewed` tetap dipertahankan. Seluruh code harus
dipetakan ke kategori stabil di atas tanpa menampilkan pesan teknis mentah
kepada pengguna.

## Gate 11.0

- Fresh baseline hijau.
- Privileged function tidak executable oleh `PUBLIC` atau `anon`.
- Private schema tidak exposed ke role Data API.
- Endpoint commerce tetap ditunda ke Phase 12.
- Gap berikutnya: belum ada public-safe Guest surface atau anon transport.
