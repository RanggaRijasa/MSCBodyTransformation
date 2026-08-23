# MSCWEB W07.6 — Admin Image Storage Management

Status: `Deferred post-launch — Admin inventory/Trash is not a first-deployment dependency (owner decision 21 August 2026)`
Autonomy: `A` against local Supabase fixtures; `C` for production retention overrides; `D` for hosted deploy or production deletion  
Depends on when resumed: W08 minimum media launch safety, W07.5 for the final Quick Access grid, W04 private media, W05 payment evidence, W06 Coach public media, and W06.5 food jobs

Scheduling authority: [`ADR-0010`](../decisions/0010-defer-admin-analytics-and-storage-management.md). Admin inventory, usage, Trash, restore, purge, registry/backfill, and deletion worker remain deferred. The launch-critical private Coach-media gateway and automatic payment-proof retention are reassigned to W08 and MUST not wait for this phase.

## Objective

Add an Admin-only `Penyimpanan gambar` for inventory, usage, search/filter, Trash/restore, and permanent deletion of eligible user-uploaded images. Deletion must free Supabase Storage safely without breaking domain references, points, transactions, review history, or audit.

Images are stored in Supabase Storage; Postgres stores metadata/references. This phase never treats `DELETE FROM storage.objects` as file deletion.

## Required references

- `00_PRODUCT_SPEC.md` `PROD-MED-*`
- `01_ARCHITECTURE.md` managed media deletion boundary
- `02_UX_PARITY_AND_ROUTES.md` `UX-MED-*` and final Quick Access layout
- `03_DESIGN_SYSTEM.md` media/destructive/icon components
- `04_MANUAL_PAYMENT.md` proof retention/reversal/dispute contract
- `05_DATA_SECURITY.md` `SEC-DATA-012…014`, `SEC-STO-008…014`, `SEC-OP-006/007`
- `07_TESTING_ACCEPTANCE.md` `QA-MED-*` and `QA-JRN-013`
- [`ADR-0008`](../decisions/0008-admin-managed-media-deletion.md)
- current bucket policies, cleanup/account-deletion workers, generated types, W07 Dashboard tests, and Supabase Storage delete/usage guidance

## In scope

Allowlisted user-uploaded image categories:

| Bucket | UI category | Canonical references |
|---|---|---|
| `question-photos` | Bukti program | `step_submission_answers.private_photo_path`, submission/review/food-job state |
| `payment-evidence` | Bukti pembayaran · inventory-only | `payment_evidence_attempts.object_path`, automatic order/review/retention cleanup state |
| `coach-public-media` | Media profil Coach | draft/published profile photo and testimonial/before–after item references |

## Out of scope

- video/audio/document management;
- `public-media` program covers/steps/options/winner posters;
- `payment-destination-assets` QRIS/business-owned media;
- PWA/brand assets, Supabase plan/billing controls, arbitrary bucket explorer, folder rename/move, direct file upload, or direct raw-path deletion;
- changing iOS source. Shared backend behavior is regression-tested against iOS contracts.

## Safe eligibility baseline

- `question-photos`: protected while submission is draft/pending, Coach decision is unresolved, or related food job is queued/processing/retry. Approved/rejected finalized evidence MAY be manually trashed; submission/review/poin remain and viewer receives tombstone.
- `payment-evidence`: existing automatic 30-day policy remains authoritative. Admin Image Storage is inventory/monitoring-only and never offers Trash/restore/purge; cleanup worker owns deletion after under-review/correction/reversal/dispute protection clears.
- `coach-public-media`: superseded/unreferenced draft or rejected item can be trashed; published avatar/item requires explicit impact confirmation and authoritative detach/unpublish first.
- Any shared, concurrently changed, account-cleanup, missing-reference-map, or unknown object is protected/fail closed.
- Trash blocks normal access immediately and creates a delayed purge job with injected-clock `not_before`. Default local auto-purge eligibility is seven days; Admin MAY move `not_before` to now only through a second irreversible confirmation. Restore cancels the unclaimed job. Production value/schedule is configurable and must be approved before hosted activation.

## Deliverables

- clean migration-chain/type prerequisite for all current media columns and cleanup RPCs;
- private managed-media asset/reference registry plus deterministic backfill/reconciliation;
- private-bucket migration and opaque public delivery gateway for Coach media;
- private durable deletion-job table/functions using existing lease/`SKIP LOCKED` pattern;
- narrow Admin inventory/usage/detail/trash/restore/purge-intent RPCs;
- server-only Edge Function worker using Supabase Storage API;
- reference-aware policy/tombstone changes and direct-delete hardening;
- `/admin/image-storage`, final fourth Quick Access card, responsive inventory/detail/Trash UI;
- local deterministic media/deletion/race/retry/security/E2E suites and runbook;
- no hosted deletion, bucket emptying, production asset mutation, or iOS source change.

## Mandatory simulator and web-extension gate

- [ ] Fresh-build/launch iOS Admin Dashboard and evidence/payment/profile viewers; record device, OS, locale, scenario, current two Quick Access actions and deleted/unavailable media behavior.
- [ ] Mark image storage as intentional web-only Admin capability; preserve five main Admin destinations and current Dashboard hierarchy.
- [ ] Compare final four Quick Access cards: compact 2 × 2, wide up to four columns, first two actions unchanged, Activity remains reachable above bottom nav.
- [ ] Treat the supplied Manage Storage screenshot as hierarchy inspiration only; do not copy Wix blue, 50 GB quota, video rows, raw filenames/location, or unrestricted bulk deletion.

## Checklist

### Migration-chain and inventory prerequisite

- [ ] Reconcile clean migrations/generated types for `profiles.profile_avatar_path`, winner-poster deletion columns, cleanup RPCs, and every reference used by inventory; block deletion if clean reset cannot reproduce them.
- [ ] Create private asset registry with opaque ID, bucket/path, path hash, owner, category, size/MIME, lifecycle, version, timestamps; raw paths remain unexposed.
- [ ] Create private reference inventory covering every allowlisted table/column and multiple/shared references.
- [ ] Backfill existing Storage objects and references deterministically; record `unknown` for unclassified objects and never auto-delete them.
- [ ] Reconciliation handles upload-before-reference, lost client response, replacement, rollback, existing orphan, already-missing object, and duplicate/shared path.
- [ ] Future successful uploads/replacements register/reconcile without making UI upload depend on Admin screen availability.
- [ ] Verify the W08 private `coach-public-media` cutover, opaque public asset IDs, safe projections, and controlled gateway remain intact before enabling Admin deletion.

### Authority and protected-state policy

- [ ] Admin safe-list/detail RPC returns opaque ID, safe owner/program/order labels, category, byte size, timestamps, lifecycle, reference count, protection reason, reclaimable state—never raw path.
- [ ] Trash RPC validates Admin, expected version, reference fingerprint, category allowlist, state, reason, idempotency; it snapshots impact and immediately denies normal/public access.
- [ ] Restore RPC is versioned/idempotent and only succeeds while object exists and purge has not started.
- [ ] Permanent-purge intent requires item/count/bytes impact, reason, irreversible acknowledgment, and current Trash state.
- [ ] Trash creates delayed job; explicit purge advances `not_before`; restore atomically cancels an unclaimed job. Injected clock makes seven-day behavior deterministic in tests.
- [ ] Published Coach media is detached/unpublished atomically before trash; shared profile/item media conflicts unless every impact is approved.
- [ ] Verify bucket-private cutover: draft, pending/rejected moderation, superseded, and trashed Coach objects are not public; previously known legacy direct Storage URL fails and gateway access fails immediately after Trash, before purge.
- [ ] Evidence/payment domain rows retain decision/point/ledger/audit and expose explicit `media_deleted` tombstone state.
- [ ] Tighten direct owner/Admin Storage DELETE paths for managed referenced objects; browser cannot bypass the authoritative operations.
- [ ] Existing automatic orphan/retention/account cleanup jobs remain separate server operations and must interoperate with registry/job idempotency.
- [ ] `payment-evidence` is rejected by Admin trash/purge RPC. Its row shows `Dikelola otomatis · retensi 30 hari`; inventory reconciles the W08-verified automatic cleanup outcome and deterministic cleanup-vs-reconciliation races.

### Worker and permanent deletion

- [ ] Reuse table-backed worker pattern with status, attempts, next attempt, lease token/expiry, path hash, expected version/reference fingerprint, terminal error code.
- [ ] Add server-only reconciliation/cron entry point that claims only due `not_before` jobs; local tests invoke it directly, while hosted schedule remains inactive until explicit authorization.
- [ ] Claim with short `FOR UPDATE SKIP LOCKED` transaction; release database lock before network call.
- [ ] Recompute all references/protected states immediately before removal; concurrent change returns conflict and preserves object.
- [ ] Remove via Supabase Storage API only, in batches no larger than 100 for UI jobs; never SQL-delete `storage.objects`.
- [ ] Finalize idempotently with exactly one logical tombstone/audit/final outcome and count/bytes/category/path hash. Remote Storage `.remove()` MAY be invoked at least once across crash recovery; do not log path, URL, image, weight, payment details, or subject identity.
- [ ] Missing object after prior successful delete finalizes safely; partial Storage/finalization failure stays retryable without duplicate audit.
- [ ] Cache/direct-public behavior for detached Coach media is verified and handed to W08 hardening/runbook.

### Usage, inventory, and Trash UI

- [ ] Add fourth `Penyimpanan gambar` quick action using semantic `imageStorage`; final compact grid 2 × 2 and wide up to four columns.
- [ ] `/admin/image-storage` uses Admin guard, `activeRoute="dashboard"`, browser Back, loading/empty/error/stale/offline states.
- [ ] Summary shows managed user-image bytes/count and categories; optional quota only from trusted server config. Trash bytes show `Dapat dibebaskan`, not already freed.
- [ ] Segment `Gambar`/`Sampah`; search by safe display label; filters category/status/date/size; keyset pagination and stable sort.
- [ ] Compact list/card and wide table show safe thumbnail/owner/category/size/date/reference/protection status. No filename/path column.
- [ ] Lazy private thumbnail uses authenticated no-store viewer, revokes object URL, and never precaches/service-worker caches media.
- [ ] Detail shows safe impact/reference summary, protected reason, retention status, and contextual Trash/Restore/Purge action. Payment evidence shows automatic-retention monitoring only.
- [ ] Trash confirmation requires reason; purge confirmation requires reason + irreversible acknowledgment; focus trap/return and live status are accessible.
- [ ] Bulk controls appear only in Trash/safe orphan-superseded scope, select current loaded page only, maximum 100, and report partial failures per safe item/count—not path.
- [ ] UI copy distinguishes `Di Sampah`, `Menunggu penghapusan`, `Menghapus`, `Gagal`, `Dihapus permanen`, and `Dipulihkan` without color alone.

## Sub-agent plan

- `msc_explorer`: map all bucket/reference/policy/cleanup/account-deletion contracts and current Admin/iOS runtime.
- `msc_implementer`: sole writer, sequentially reproducibility → registry/inventory → policy/operations → worker → UI/tests.
- `msc_reviewer`: destructive-action safety, shared references/races, RLS/service-role boundary, audit/privacy, retry/idempotency, cache, accessibility, and regression.

Primary agent owns allowlist, protected-state matrix, migration order, worker operation signatures, and destructive authorization evidence.

## Verification

- `QA-JRN-013` and all `QA-MED-*`;
- clean migration/reset and generated-types consistency;
- full three-bucket inventory/reference backfill plus unknown fail-closed;
- non-Admin/direct-delete/forged-bucket/path denial;
- every safe/protected state, shared reference, concurrent reference, account cleanup, active AI, and public detach case;
- trash/access denial/restore/purge, lease/duplicate delivery/at-least-once remove/retry/backoff/missing object/forced crash after remove/partial batch/exactly-one logical audit finalization;
- payment automatic-cleanup versus inventory reconciliation race, with no Admin manual deletion controls;
- Storage API deletion proof and explicit absence of SQL Storage delete;
- submission/points/leaderboard, payment ledger/audit, Coach profile/moderation, food insight, account deletion, and existing cleanup regressions;
- compact/wide/light/dark/keyboard/screen-reader/200%-zoom/Back/Quick Access/Activity scroll visual E2E;
- service-worker/cache/log/bundle scan for raw paths, signed URLs, credentials, and private media.

## Exit criteria

- Admin sees accurate managed user-image usage and safe inventory through opaque IDs.
- Eligible images can move to Trash, restore, and purge locally; protected/shared/unknown media cannot be deleted.
- Permanent delete uses Storage API with immediate reference recheck, idempotent tombstone/audit, and no browser service secret/path.
- Coach media uses private Storage plus opaque controlled public delivery; known legacy/direct URLs cannot bypass Trash.
- Evidence deletion preserves points/domain history; payment deletion preserves ledger/audit; Coach media unpublishes before removal.
- Final four-card Quick Access, responsive/accessibility/security/performance/regression gates pass.

## User input or authorization

- Local implementation can proceed with the safe eligibility matrix above and deterministic test media only.
- Before hosted activation, confirm production Trash auto-purge period (local default seven days), program-evidence retention/appeal policy, operator/alert responsibility, and public-cache invalidation runbook.
- Hosted migrations/policies/functions/cron, production inventory scan/backfill, and any real media trash/restore/purge require separate explicit authorization. Production smoke must use synthetic owned test images and approved cleanup.
- Expanding deletion to `public-media`, QRIS assets, videos, or system assets requires a separate product decision/ADR.

## Progress log

Append requirement IDs, simulator evidence, bucket/reference inventory, migration/backfill counts, protected-state version, worker/job/cache evidence, commands/results, external approvals, deleted synthetic fixture inventory, and next item.
