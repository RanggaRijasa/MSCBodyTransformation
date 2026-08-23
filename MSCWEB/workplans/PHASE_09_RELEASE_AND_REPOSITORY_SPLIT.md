# MSCWEB W09 — Release and standalone web-repository cutover

Status: `Not started`  
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

- [ ] All QA release gates pass and no visible localization key/private leak exists.
- [ ] Domain/subdomain, privacy/terms/support, reviewer roster, payment/reconciliation/dispute/retention/SLA are approved.
- [ ] Production bank/QRIS data handling has owner and rotation procedure.
- [ ] Hosted Supabase migration/function/Auth/Storage rollout reviewed and explicitly authorized.
- [ ] Food AI provider terms/data-use, model availability, rate limits, spend ceiling, secret owner/rotation, and failure alert are reviewed; production provider secret is configured only through authorized server secret management.
- [ ] First-login production onboarding has approved Google callback/origins, provisional expiry/cleanup schedule, test identities, QR Coach fixture, cancellation cleanup, and no-private-access evidence.
- [ ] Minimum media launch safety is approved: private evidence buckets/RLS, payment-proof retention/orphan-cleanup schedule and operator, opaque Coach-media gateway, legacy-direct-URL denial, cache invalidation, and rollback/incident runbook.
- [ ] W07.5 Sales Overview and W07.6 Admin Image Storage routes/actions are absent and recorded as deferred post-launch, not reported as completed.
- [ ] Cloudflare deployment/domain/DNS/secrets/headers reviewed and explicitly authorized.
- [ ] Enforced candidate CSP has passed on an authorized preview with production-shaped OAuth/Supabase endpoints; any prior waiver is resolved before rollout.
- [ ] Backup/rollback/incident contacts and smoke-test account prepared.
- [ ] Production smoke-test mutation scope is separately approved: exact test identities, allowed Guest/Participant/Coach/Admin/payment operations, proof/media upload permission, records allowed to persist, retention, and cleanup owner/steps.
- [ ] No production mutation occurs from an unapproved sub-agent.
- [ ] Synthetic production AI smoke scope is separately authorized and does not use a real Participant photo.
- [ ] Production onboarding smoke has separate authorization for exact Google identity, Participant/Coach path, QR/payment proof, records allowed to persist, and Auth/profile/application/order/media cleanup.

## Repository split checklist

- [ ] `MSCWEB` installs, typechecks, lints, tests, exports, and serves independently.
- [ ] No runtime import/symlink to Swift source or parent-only path.
- [ ] Approved App Icon/assets copied with provenance/license note.
- [ ] Specs, ADRs, workplans, nested AGENTS, CI, lockfile, and examples included.
- [ ] No secrets, generated production data, private evidence, or temp artifacts included.
- [ ] The entire canonical repository-root `supabase/` tree is inventoried for transfer, including every migration, Function/shared module, database test, `config.toml`, and operational document required by the web product.
- [ ] The migration timestamps, filenames, ordering, and SQL contents remain intact; no historical migration is omitted merely because it originated before MSCWEB.
- [ ] The standalone repository uses one root `supabase/` directory as the only deployable migration/Function authority.
- [ ] Tests and scripts that currently resolve `../supabase/` or another parent-only path are updated to resolve the standalone repository root.
- [ ] Fresh-clone Supabase checks prove that the local and linked migration inventories match the expected canonical history before deployment authority is switched.
- [ ] Any legacy Cloudflare/Supabase auto-deployment path is disabled at cutover; W09 initial rollout remains explicitly authorized/manual and W10 owns recurring GitHub Actions automation.
- [ ] The former iOS repository is marked archival and its web/backend deployment automation, scheduled deploy jobs, and production-write credentials are removed or disabled.
- [ ] Any temporary safety copy in the former repository is explicitly non-deployable and retained only until rollback and standalone validation gates pass.
- [ ] Dry-run path scan and fresh-clone-equivalent build succeed.
- [ ] The archive operation does not modify iOS source; iOS build/release verification is not a W09 exit gate.
- [ ] Exact Git/repository operations are requested and authorized before execution.
- [ ] Deleting the old `MSCWEB/` or repository-root `supabase/` copy is treated as a separate destructive cleanup requiring explicit authorization after the standalone release is verified.

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
