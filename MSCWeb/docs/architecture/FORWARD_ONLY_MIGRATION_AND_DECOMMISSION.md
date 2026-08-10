# Forward-only Migration and Decommission Plan

## Guardrails

- Hosted `main` memiliki 20 migration production. History tidak diubah,
  disquash, atau di-reset.
- Manual commerce ditambahkan setelah backup dan local verification; existing
  StoreKit/Apple objects tetap tersedia selama parity dan rollback window.
- Rollback selalu forward-fix atau traffic/config rollback. Tidak ada down
  migration destructive pada production.
- Setiap hosted mutation, provider/cron change, DNS, atau ownership transfer
  memerlukan approval eksplisit pada phase terkait.

## Object classification

| Class | Objects | Tindakan |
|---|---|---|
| Retain active | profiles, roles, Coach assignment, programs/content, enrollment, submissions, quiz, weigh-ins, scoring, winners, audit, public/private reads | Digunakan web setelah adapter/contract tests lulus |
| Extend additive | manual payment destinations/orders/evidence/ledger/events, private evidence bucket, protected operations | Migration baru Phase 06; local first |
| Keep dual during parity | program/Coach entitlements dan shared audit | Store dan manual provider dapat coexist tanpa saling menulis state palsu |
| Stop new writes later | store product provisioning, store purchase intents, Apple identity credential creation | Hanya setelah web cutover dan owner approval Phase 13 |
| Legacy read-only | commerce transactions/events, Apple notification inbox, historical Coach payments/access, identity/account events | Dipertahankan untuk audit, support, reconciliation, dan rollback |
| Disable later | Apple commerce/account webhooks, Apple reconciliation cron, store expiry cron yang tidak lagi diperlukan | Setelah no-active-client/no-pending-event proof |
| Archive/later drop | Apple/StoreKit-only tables/functions/secrets/config | Setelah retention/legal/backup approval; bukan otomatis |

## Additive migration sequence

1. **Preflight:** backup/restore proof, manifest hash, remote/local migration
   equality, lint/advisors, pending event and entitlement inventory.
2. **Destination/storage:** tambah destination berversi, private
   `payment-evidence` bucket, grants/RLS, server-derived object path.
3. **Order/evidence:** tambah order, immutable attempts, indexes, constraints,
   idempotency, reservation expiry; tidak mengubah store provider constraint.
4. **Ledger/events:** tambah verified ledger, append-only events, retention
   anchors, exceptional reversal states.
5. **Operations:** tambah create/upload/submit/approve/reject/restore/expire/
   cancel/reversal/renew operations dengan race tests.
6. **Read projections:** tambah public-safe/owner/Admin DTO dan update OpenAPI
   agar enum SQL/manual contract cocok sebelum TS codegen.
7. **Local verification:** fresh reset, pgTAP, integration races, Storage API,
   OpenAPI parser/parity, web adapter contract tests.
8. **Hosted deployment:** hanya dengan approval, backup, dry-run, scoped push,
   post-deploy RLS/grants/function/bucket/cron verification.

Setiap step berada dalam migration baru dengan timestamp lebih tinggi dari
`20260809092112` dan tidak mengedit 20 migration production.

## Forward-fix rollback

| Failure | Forward response |
|---|---|
| Constraint/operation defect sebelum use | Migration perbaikan; feature flag tetap off |
| RLS/grant terlalu luas | Revoke/policy replacement migration segera; audit access |
| Operation race/idempotency defect | Disable entry point/flag, deploy fixed function/migration, reconcile events |
| Evidence storage defect | Stop upload intents; pertahankan object; fix policy/cleanup setelah inventory |
| Hosted compatibility defect | Route web tetap off; existing iOS/store flow tidak dihapus |
| Data projection defect | Rebuild projection dari immutable ledger/events; jangan rewrite audit history |

## Provider and recurring-job decommission gates

Apple Auth/provider baru boleh dinonaktifkan bila active Apple identities,
account deletion/revocation handling, login replacement, support plan, dan
rollback sudah lulus. Google tetap provider web utama.

Apple/store Edge Functions dan cron baru boleh dinonaktifkan bila:

- tidak ada supported iOS build yang memerlukan write/reconciliation;
- tidak ada pending notification/inbox/dead-letter/purchase intent;
- entitlement historical telah direkonsiliasi dan tetap readable;
- final backup dan restore test lulus;
- monitoring menunjukkan no traffic selama agreed observation window;
- owner menyetujui exact function/job/provider yang dinonaktifkan.

Disable schedule lebih dulu, pertahankan handler fail-closed/read-only selama
rollback window, lalu retire secret. Drop object menjadi keputusan terpisah.

## Phase 13 one-time ownership transfer

1. Freeze perubahan backend/contract pada repository sumber.
2. Hitung ulang [hash manifest](../baseline/BACKEND_CONTRACT_HASH_MANIFEST.md).
3. Salin satu kali `supabase` dan `Contracts` yang authoritative ke repository
   target `MSCWeb` setelah user menyetujui cutover path.
4. Jalankan parser, migration history, lint, tests, dan combined hash di target.
5. Tetapkan repository target sebagai sole write owner; source lama menjadi
   read-only archive/reference.
6. Dokumentasikan timestamp, approver, old/new hash, rollback window, dan
   location backup tanpa credential/private URL.

Tidak ada periode dua salinan yang sama-sama menerima perubahan. iOS source
tidak dipindahkan, dihapus, atau diarsipkan otomatis oleh langkah ini.
