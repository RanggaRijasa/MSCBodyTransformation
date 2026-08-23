# MSCWEB W09 — Release and standalone web-repository cutover

Status: `Complete — standalone repository and production authority cutover verified`
Autonomy: `A` for readiness audits; `C/D` for production and Git/repository actions  
Depends on: W08 production candidate and all launch blockers resolved

## Objective

Produce final release evidence, obtain explicit production authorizations, perform controlled production rollout only when requested, and cut MSCWEB over to a standalone repository that becomes the sole deployment authority for the web application, Cloudflare, and the complete canonical Supabase history. The former iOS repository becomes an archive with no deployment authority.

## Required references

- `08_DELIVERY_PLAN.md` safe split criteria
- `07_TESTING_ACCEPTANCE.md` release gates
- `workplans/AUTOMATION_AND_PERMISSIONS.md`
- deployment/security/privacy runbooks from W08
- all phase progress logs and accepted ADRs
- `decisions/0011-web-only-repository-and-supabase-authority.md`

## Final ownership decision

- The standalone MSCWEB repository owns the web/PWA source, tests, specifications, Cloudflare Worker/configuration, and the entire canonical repository-root `supabase/` tree.
- The complete existing Supabase migration history moves as one ordered chain. The split must not squash, rebaseline, renumber, selectively copy, or recreate migrations that are already part of the linked production history.
- Supabase Functions, shared Function modules, database tests, local configuration, and deployment documentation move with that migration history.
- After cutover, only the standalone MSCWEB repository may deploy Cloudflare or Supabase changes. The former iOS repository is archival and must have all web/backend deployment automation disabled.
- A temporary safety copy may exist during validation, but it is not a second authority and must not have an active deployment path.
- The iOS application is no longer a release target or backend owner. Its source remains unchanged as an archive until the owner separately authorizes cleanup.

## Deliverables

- requirements-to-evidence traceability report;
- unresolved-risk/waiver register;
- production configuration checklist with no secrets committed;
- authorized deployment and smoke/rollback evidence, if requested;
- repository split plan/dry run;
- complete transfer inventory for web source, Cloudflare configuration, and the canonical repository-root `supabase/` tree;
- standalone MSCWEB repository as the sole Supabase and Cloudflare deployment authority;
- archived former iOS repository with no active web/backend deployment path;
- standalone build/test/release commands and documentation after authorized split;
- explicit W10 handoff; recurring GitHub Actions production automation is not implemented inside W09.

## Pre-production checklist

- [x] All QA release gates pass and no visible localization key/private leak exists.
- [x] Domain/subdomain, privacy/terms/support, reviewer roster, payment/reconciliation/dispute/retention/SLA are approved.
- [x] Production bank/QRIS data handling has owner and rotation procedure.
- [x] Hosted Supabase migration/function/Auth/Storage rollout reviewed and explicitly authorized.
- [x] Food AI provider terms/data-use, model availability, rate limits, spend ceiling, secret owner/rotation, and failure alert are reviewed; production provider secret is configured only through authorized server secret management.
- [x] First-login production onboarding has approved Google callback/origins, provisional expiry/cleanup schedule, test identities, QR Coach fixture, cancellation cleanup, and no-private-access evidence.
- [x] Minimum media launch safety is approved: private evidence buckets/RLS, payment-proof retention/orphan-cleanup schedule and operator, opaque Coach-media gateway, legacy-direct-URL denial, cache invalidation, and rollback/incident runbook.
- [x] W07.5 Sales Overview and W07.6 Admin Image Storage routes/actions are absent and recorded as deferred post-launch, not reported as completed.
- [x] Cloudflare deployment/domain/DNS/secrets/headers reviewed and explicitly authorized.
- [x] Enforced candidate CSP passed on the authorized production-shaped noindex candidate before rollout.
- [x] Backup/rollback/incident contacts and non-mutating smoke scope were prepared; pre-deployment inventories and prior Worker version form the rollback checkpoint.
- [x] Production mutation scope was approved but not exercised because non-mutating smoke fully covered W09 release gates.
- [x] No production mutation occurred from a sub-agent.
- [x] Synthetic production AI scope was approved; W09 intentionally made no AI call and used no real Participant photo.
- [x] Google OAuth/onboarding mutation smoke remains explicitly `DEFERRED`; local synthetic onboarding and prior owner production login evidence are the accepted gate.

## Repository split checklist

- [x] Standalone repository installs, typechecks, lints, tests, exports, and serves independently.
- [x] No runtime import/symlink to Swift source or parent-only path.
- [x] Approved App Icon/assets copied with provenance/license note.
- [x] Specs, ADRs, workplans, root AGENTS, W10 handoff, lockfile, and examples included.
- [x] No secrets, generated production data, private evidence, or temp artifacts included.
- [x] The entire canonical repository-root `supabase/` tree is inventoried for transfer, including every migration, Function/shared module, database test, `config.toml`, and operational document required by the web product.
- [x] The migration timestamps, filenames, ordering, and SQL contents remain intact; no historical migration is omitted merely because it originated before MSCWEB.
- [x] The standalone repository uses one root `supabase/` directory as the only deployable migration/Function authority.
- [x] Tests and scripts resolve canonical `supabase/` inside the standalone repository root.
- [x] Fresh-clone Supabase checks prove that the local and linked migration inventories match the expected canonical history before deployment authority is switched.
- [x] No legacy Cloudflare/Supabase auto-deployment path exists; W09 rollout remained manual and W10 owns recurring GitHub Actions automation.
- [x] The former iOS repository is archival and has no tracked web/backend deployment workflow or production credential. Ignored local link state is retained under the explicit no-delete rule.
- [x] The temporary safety copy in the former repository is explicitly non-deployable and retained as rollback archive.
- [x] Dry-run path scan and fresh-clone-equivalent build succeed.
- [x] The archive operation did not modify iOS source; iOS build/release verification is not a W09 exit gate.
- [x] Exact Git/repository operations were requested and authorized in the W09 execution prompt.
- [x] Deleting the old `MSCWEB/` or repository-root `supabase/` copy remains a separate destructive cleanup requiring explicit authorization.

## Controlled rollout sequence

1. Read-only readiness report.
2. Build a non-destructive standalone-repository candidate containing the approved `MSCWEB/` source and the complete canonical repository-root `supabase/` tree; validate paths, migration inventory, build, tests, and secret exclusions.
3. User separately authorizes the exact Git host/repository creation, history strategy, remote, commit, push, and CI/deployment-authority cutover operations.
4. Establish the standalone repository as the sole source authority and disable the former repository's Cloudflare/Supabase deployment paths. Existing hosted Worker, domain, DNS, Auth, Storage, Functions, and database remain in place.
5. User approves exact Supabase production operations from the standalone repository.
6. Apply/verify backend from the standalone repository with rollback checkpoints.
7. User approves exact Cloudflare deploy/domain operations from the standalone repository.
8. Deploy frontend without assuming data-mutation permission.
9. Obtain separate exact authorization for production smoke-test identities, operations, payment/proof/media records, retention, and cleanup.
10. Run only the authorized Guest/Auth/Participant/Coach/Admin/payment smoke subset; inventory and clean test data according to the approved plan.
11. Monitor/redact/rollback if a release gate fails and verify that production availability is not coupled to the archived repository.
12. Keep the former repository as a non-deployable archive through the rollback window. Remove old source copies only under a later explicit destructive-cleanup authorization.

No approval in one step grants approval for later steps. In particular, deploy authorization does not authorize production account creation, role activation, enrollment, payment, proof/media upload, or cleanup/deletion.

## Sub-agent plan

- `msc_explorer`: read-only traceability, path, secret, dependency, and migration-ownership audits.
- `msc_reviewer`: independent release/security/privacy evidence review.
- `msc_implementer`: may fix a bounded local release defect as sole writer; must not deploy or run Git mutations.

Production external actions remain primary-agent controlled and require exact authorization.

## Verification

- complete CI/test/device/security/performance suite;
- secret/privacy/license/path scans;
- local deployment dry run and rollback rehearsal;
- authorized production smoke tests if deployment occurs;
- standalone fresh-environment build after authorized split;
- full canonical Supabase migration/Function inventory comparison before and after transfer;
- proof that only the standalone repository retains active Cloudflare/Supabase deployment authority.

## Exit criteria

- Release evidence is complete and production is either explicitly deployed/verified or clearly remains undeployed.
- Repository split is either explicitly performed/verified or remains a documented plan.
- The standalone MSCWEB repository is the documented sole owner of the web app, Cloudflare deployment, and complete canonical Supabase deployment history when cutover is performed.
- The former iOS repository is archival and has no active web/backend deployment authority after cutover.
- Supabase migration authority is singular; no second deployable history, selective rebaseline, or independently writable copy exists.
- W10 is the documented next phase for protected-main CI/CD; routine deployment is not represented as automated before W10 passes.
- No action is claimed without command/result evidence and authorization.

## User input or authorization

Required: all unresolved business/legal/brand inputs, exact production Supabase/Auth onboarding actions, payment-proof retention/cleanup activation, minimum Coach-media gateway/cache safety, AI provider/secret activation, exact Cloudflare/domain actions, launch decision, destination repository, history-preservation strategy, exact Git/remote/push operations, CI/deployment-authority cutover, and any later destructive cleanup of the archived repository. Sales Overview reads and Admin media deletion activation are not required for the first deployment.

## Progress log

Append approvals verbatim by scope, operations/results, rollback checkpoints, smoke evidence, repository outcome, remaining risks, and next item.

- 23 August 2026 — Product owner decided that native iOS is discontinued as a release target. W09 now requires the standalone MSCWEB repository to become the sole owner of the web application, Cloudflare deployment, and the complete canonical Supabase migration/Function history. The former iOS repository becomes a non-deployable archive. Documentation only; no Git operation, file transfer, deployment, CI mutation, or deletion was performed.

- 24 August 2026 — W09 completed end-to-end under the owner's pasted execution authorization. A copy-only standalone candidate was built outside the old working tree, and the complete canonical root `supabase/` chain was transferred without squash/rebaseline/rename/selective copy. Source comparison passed for 48 migration files (aggregate manifest SHA-256 `61f88ba6ab3b93201038be19cfe5c41dc38f7bc550f3b1e8bb7a9b53561cb616`) and 25 Function/shared files (`d010f5f27c16a7fbac7b5d05ecbeb98fc07fe8ae5e36d177f16fcaf0867674e4`).
- Local/standalone verification passed: Node 22 clean install, typecheck, lint, 213 unit tests, production build/PWA/bundle/performance/environment/Worker dry-run, secret/private/path/symlink scan, clean 48-migration local rebuild, local lint/advisors, 423 pgTAP/RLS assertions, 9 integration tests, and 13 local Function runtime checks. One canonical defect was fixed forward-only by migration `20260823161016_w09_admin_archive_idempotency_columns.sql`; historical tests were updated to current W07.4/W08 contracts and timezone-safe fixtures.
- Production rollout passed: migration history advanced 47→48 with no destructive SQL; 13/13 Edge Functions are ACTIVE; candidate Worker `978d2eef-5fbc-4ffe-8c4d-f5dd87867796`; production Worker `3fd4a02a-6ea2-4fd7-8fea-4293d9ec15c8`; rollback Worker `a3cf6d4a-bb12-4588-b6b3-e22e7d6f95e7`. Apex/deep links/legal/PWA return 200, unknown returns 404, and `www` remains a 308 redirect preserving path/query. No DNS or secret mutation occurred.
- Non-mutating production smoke `w09-nonmutating-20260823-171415805-c50504ee` passed with zero created records/objects, no real transfer, no real user data/media, cleanup `NOT_REQUIRED_ZERO_MUTATION`, and residual `ZERO_BY_DESIGN`. Aggregate production counts remained unchanged except the expected migration-history increment. Hosted Supabase was not reset, restored, truncated, or recreated.
- Authority: `https://github.com/RanggaRijasa/MSCWEB.git` is the sole web/Cloudflare/Supabase deployment authority. The former repository retains both source copies as a non-deployable archive; no iOS source, branch, remote, credential, or history was removed. Next phase: W10 protected-main CI/CD automation.
