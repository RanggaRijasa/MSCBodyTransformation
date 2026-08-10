# Phase 13: Parity UAT and Cutover

> Status: BELUM DIMULAI

## Tujuan

Membuktikan PWA aman menggantikan aplikasi iOS, melakukan acceptance bersama
owner, memindahkan kepemilikan backend/contract ke package/repository web tanpa
dua source aktif, dan menyiapkan decommission Apple secara bertahap.

## Non-destructive rule

- Tidak menghapus source iOS, `.git`, hosted data, migration history, Apple
  identities, transactions, audit, or functions automatically.
- Repository move/archive, DNS cutover, provider disable, cron disable, object
  drop, dan data deletion memerlukan approval eksplisit per tindakan.
- Jika parity belum lulus, production web dapat dihentikan/rollback tanpa
  merusak backend lama.

## Slice 13.1 — Automated parity audit

- [ ] Re-run full feature/route/role matrix against iOS reference.
- [ ] Compare OpenAPI/SQL/TypeScript enums and response fields.
- [ ] Map every relevant Swift/XCUI test to web test/manual evidence.
- [ ] Full unit/component/integration/pgTAP/contract/E2E/security/build suite.
- [ ] Verify no forbidden historical concept returned.
- [ ] Verify all deliberate web adaptations documented.
- [ ] Verify handwritten file-size/import boundary and generated-artifact rules.

## Slice 13.2 — Owner UAT

- [ ] Guest, Participant, Coach, Admin acceptance checklist with controlled
  accounts and no real sensitive data unless production policy permits.
- [ ] Physical iPhone Safari + installed PWA.
- [ ] Physical Android Chrome + installed PWA.
- [ ] Desktop Admin browser matrix.
- [ ] Realistic manual payment operations and reconciliation workflow.
- [ ] Camera/QR/upload/video/notifications-if-enabled/offline/update/session.
- [ ] Accessibility exploratory and Indonesian copy review.
- [ ] Owner records defects; critical/high blockers fixed and rerun.

## Slice 13.3 — Production observation

- [ ] Define limited rollout window and support owner.
- [ ] Observe Auth, errors, latency, payment queue, cleanup jobs, storage,
  capacity, scoring, and audit without logging PII.
- [ ] Verify backups, spend alerts, domain renewal, incident contacts.
- [ ] Test fail-closed provider outage and web rollback.
- [ ] Do not claim cutover from elapsed time alone; acceptance evidence required.

## Slice 13.4 — Backend/contract ownership transfer

- [ ] Freeze writes to old source paths for a short declared window.
- [ ] Hash/inventory authoritative `supabase` and `Contracts` source.
- [ ] Move exactly that verified source into target repository structure; do
  not maintain a duplicate fork.
- [ ] Update relative paths, scripts, CI, docs, runbooks, and local setup.
- [ ] Run fresh local environment, full migrations/tests, schema diff, and
  hosted comparison from new ownership location.
- [ ] Mark old paths reference-only and record transfer timestamp/hash.
- [ ] User performs or explicitly authorizes repository move/Git actions.

## Slice 13.5 — Legacy Apple/StoreKit decommission plan

- [ ] Inventory active Apple identities, sessions, transactions, entitlements,
  functions, Vault values, cron, Auth provider, callback, docs, and data
  retention obligations.
- [ ] Decide whether legacy Apple users need migration/sign-in recovery before
  provider disable.
- [ ] Stop new StoreKit purchases only after PWA payment is stable.
- [ ] Disable scheduled Apple reconciliation before function removal, with
  observability and rollback.
- [ ] Retain immutable financial/audit records for policy/legal period.
- [ ] Remove secrets/providers/functions/tables in separate forward phases;
  never combine all destructive actions in one blind migration.
- [ ] Each hosted mutation gets explicit approval and post-check.

## Slice 13.6 — Cutover and handoff

- [ ] Final canonical domain and redirects.
- [ ] PWA ownership, registrar, Cloudflare, Supabase, Google, billing, MFA/recovery,
  support and incident access documented.
- [ ] Final architecture, data dictionary, route matrix, operations, payment
  review, backup/restore, deployment/rollback docs current.
- [ ] Known limitations and deferred work listed.
- [ ] Owner explicitly accepts web as primary production platform.
- [ ] Owner explicitly approves moving `MSCWeb` to repository baru.

## Final verification

- [ ] Clean clone/install/build/test from target repository.
- [ ] Fresh Supabase local migration and pgTAP/integration suite.
- [ ] Hosted schema/migration/grants/RLS/storage/functions/cron audit.
- [ ] Production smoke all critical journeys.
- [ ] Secret/PII/cache/log/source-map scan.
- [ ] Domain/TLS/OAuth/PWA/install/update/offline checks.
- [ ] Rollback drill and incident contacts.

## Definition of done

- PWA feature parity dan security/privacy/reliability terbukti.
- Owner UAT lulus dan cutover disetujui.
- Backend/Contracts mempunyai satu owner source di repository target.
- iOS tetap tersedia sebagai archived reference sampai owner menentukan
  retention/deletion separately.
- Apple/StoreKit legacy memiliki decommission record bertahap, bukan silent
  abandonment atau destructive drop.
- Tidak ada required manual/external blocker yang disembunyikan.

## Completion report

Laporan akhir wajib memuat files/path ownership, commands/results, hosted and
device evidence, manual gates, costs/provider status, rollback, blockers,
known limitations, and next operational action. Jangan mencantumkan secret,
PII, raw QR, private URLs, atau Git hash kecuali pengguna meminta Git action.
