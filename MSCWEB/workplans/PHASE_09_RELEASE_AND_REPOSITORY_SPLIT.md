# MSCWEB W09 — Release, production authorization, and repository split

Status: `Not started`  
Autonomy: `A` for readiness audits; `C/D` for production and Git/repository actions  
Depends on: W08 production candidate and all launch blockers resolved

## Objective

Produce final release evidence, obtain explicit production authorizations, perform controlled production rollout only when requested, and move MSCWEB into its own repository at a safe checkpoint without splitting backend authority.

## Required references

- `08_DELIVERY_PLAN.md` safe split criteria
- `07_TESTING_ACCEPTANCE.md` release gates
- `workplans/AUTOMATION_AND_PERMISSIONS.md`
- deployment/security/privacy runbooks from W08
- all phase progress logs and accepted ADRs

## Deliverables

- requirements-to-evidence traceability report;
- unresolved-risk/waiver register;
- production configuration checklist with no secrets committed;
- authorized deployment and smoke/rollback evidence, if requested;
- repository split plan/dry run;
- one authoritative home for Supabase migrations/functions;
- standalone CI/build/test/docs after authorized split.

## Pre-production checklist

- [ ] All QA release gates pass and no visible localization key/private leak exists.
- [ ] Domain/subdomain, privacy/terms/support, reviewer roster, payment/reconciliation/dispute/retention/SLA are approved.
- [ ] Production bank/QRIS data handling has owner and rotation procedure.
- [ ] Hosted Supabase migration/function/Auth/Storage rollout reviewed and explicitly authorized.
- [ ] Food AI provider terms/data-use, model availability, rate limits, spend ceiling, secret owner/rotation, and failure alert are reviewed; production provider secret is configured only through authorized server secret management.
- [ ] Sales Overview production-read scope, Admin identities, ledger reconciliation sample, and no-export/no-PII response evidence are approved.
- [ ] Image Storage production inventory backfill, Trash/purge period, protected-state matrix, worker/operator/alerts, public-cache invalidation, and rollback/incident runbook are approved.
- [ ] Cloudflare deployment/domain/DNS/secrets/headers reviewed and explicitly authorized.
- [ ] Enforced candidate CSP has passed on an authorized preview with production-shaped OAuth/Supabase endpoints; any prior waiver is resolved before rollout.
- [ ] Backup/rollback/incident contacts and smoke-test account prepared.
- [ ] Production smoke-test mutation scope is separately approved: exact test identities, allowed Guest/Participant/Coach/Admin/payment operations, proof/media upload permission, records allowed to persist, retention, and cleanup owner/steps.
- [ ] No production mutation occurs from an unapproved sub-agent.
- [ ] Synthetic production AI smoke scope is separately authorized and does not use a real Participant photo.
- [ ] Production media-management smoke uses only synthetic owned images with exact allowed trash/restore/purge and cleanup scope; no real user image may be deleted for smoke testing.

## Repository split checklist

- [ ] `MSCWEB` installs, typechecks, lints, tests, exports, and serves independently.
- [ ] No runtime import/symlink to Swift source or parent-only path.
- [ ] Approved App Icon/assets copied with provenance/license note.
- [ ] Specs, ADRs, workplans, nested AGENTS, CI, lockfile, and examples included.
- [ ] No secrets, generated production data, private evidence, or temp artifacts included.
- [ ] Decide which repository owns deployable Supabase migrations/functions.
- [ ] Do not duplicate two independently deployable migration histories.
- [ ] Dry-run path scan and fresh-clone-equivalent build succeed.
- [ ] Parent iOS project remains unchanged/buildable.
- [ ] Exact Git/repository operations are requested and authorized before execution.

## Controlled rollout sequence

1. Read-only readiness report.
2. User approves exact Supabase production operations.
3. Apply/verify backend with rollback checkpoints.
4. User approves exact Cloudflare deploy/domain operations.
5. Deploy frontend without assuming data-mutation permission.
6. Obtain separate exact authorization for production smoke-test identities, operations, payment/proof/media records, retention, and cleanup.
7. Run only the authorized Guest/Auth/Participant/Coach/Admin/payment smoke subset; inventory and clean test data according to the approved plan.
8. Monitor/redact/rollback if gate fails.
9. User separately authorizes Git/repository split operations if the split was deferred after W01.
10. Validate standalone repository and update ownership documentation.

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
- standalone fresh-environment build after authorized split.

## Exit criteria

- Release evidence is complete and production is either explicitly deployed/verified or clearly remains undeployed.
- Repository split is either explicitly performed/verified or remains a documented plan.
- Supabase migration authority is singular and documented.
- No action is claimed without command/result evidence and authorization.

## User input or authorization

Required: all unresolved business/legal/brand inputs, exact production Supabase actions, financial-report read scope, media inventory/deletion activation, AI provider/secret activation, exact Cloudflare/domain actions, exact Git/repository actions, and launch decision.

## Progress log

Append approvals verbatim by scope, operations/results, rollback checkpoints, smoke evidence, repository outcome, remaining risks, and next item.
