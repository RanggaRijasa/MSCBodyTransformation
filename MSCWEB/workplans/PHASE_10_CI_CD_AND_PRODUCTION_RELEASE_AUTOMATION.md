# MSCWEB W10 — CI/CD and production release automation

Status: `Planned — must not start before W09 repository cutover is complete`  
Autonomy: `A/B` for repository implementation and local/CI dry runs; `C/D` for GitHub settings, secrets, workflow activation, and production execution  
Depends on: W09 complete; standalone MSCWEB repository is the sole web/Cloudflare/Supabase authority; production is healthy or explicitly remains undeployed

## Objective

Replace routine GPT/MCP-driven production operations with a deterministic,
reviewable GitHub Actions release path. Feature work uses local Supabase;
pull requests validate against disposable local infrastructure and Cloudflare
dry runs; protected `main` is the only production source, and every production
deployment passes an owner-controlled approval or manual-dispatch gate.

W10 does not create a hosted staging environment. A real `develop` → hosted
Supabase staging → Cloudflare staging track requires a later owner decision,
separate project/resources, and a new ADR.

## Required references

- `decisions/0011-web-only-repository-and-supabase-authority.md`
- `decisions/0012-github-actions-production-deployment-authority.md`
- `workplans/PHASE_09_RELEASE_AND_REPOSITORY_SPLIT.md`
- `workplans/AUTOMATION_AND_PERMISSIONS.md`
- `07_TESTING_ACCEPTANCE.md`
- `production/W08_PRODUCTION_OPERATIONS.md`
- `production/SYNTHETIC_SMOKE_AND_CLEANUP_MANIFEST.md`
- Supabase environment/deployment guide: `https://supabase.com/docs/guides/deployment/managing-environments`
- Supabase Edge Functions GitHub Actions guide: `https://supabase.com/docs/guides/functions/examples/github-actions`
- Cloudflare Workers CI/CD guide: `https://developers.cloudflare.com/workers/ci-cd/`
- Cloudflare Wrangler environments guide: `https://developers.cloudflare.com/workers/wrangler/environments/`
- GitHub deployment environments guide: `https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments`

At implementation time, re-check current changelogs and CLI `--help`; do not
copy command flags from this planning document without verifying the pinned
tool versions in the standalone repository.

## Locked release model

| Source | Supabase target | Cloudflare target | Allowed outcome |
|---|---|---|---|
| local checkout / `feature/*` | local Supabase only | local Worker/dev server | development and tests |
| pull request targeting `main` | disposable local Supabase in CI | build and deploy dry run only | required checks; no external mutation |
| protected `main` | hosted production after approval | production Worker/domain after backend success | production release |

Additional rules:

- There is no baseline `develop` branch and no hosted staging Supabase project.
- PR jobs never receive production environment secrets and never invoke a
  production-mutating command.
- A Cloudflare candidate/preview build that points at production Supabase is
  not staging and must not become an automatic PR deployment.
- Push/merge to `main` may prepare a production deployment, but production
  secrets are released only after the configured GitHub Environment approval.
- If required reviewers are unavailable for the repository visibility/plan,
  production uses `workflow_dispatch` restricted to the current `main` commit;
  clicking `Run workflow` is the release approval.
- Only one production deployment may run at once. An in-progress production
  deployment is not cancelled by a newer commit.
- GitHub Actions is the routine production deployment authority. GPT, Codex,
  Supabase MCP, Cloudflare MCP, dashboard clicks, and developer laptops are not
  routine release mechanisms after W10 activation.
- Break-glass deployment remains documented but disabled by default and always
  requires an incident record plus explicit owner authorization.

## Requirement IDs

- `REL-CI-001` — feature and PR work uses local/disposable Supabase only.
- `REL-CI-002` — PR validation has no production credentials or mutation path.
- `REL-CI-003` — CI reconstructs and tests the complete canonical migration chain.
- `REL-CI-004` — already-deployed migrations are immutable; only new ordered migrations may advance production.
- `REL-CI-005` — only protected `main` can request a production release.
- `REL-CI-006` — production secrets remain behind a GitHub `production` environment gate.
- `REL-CI-007` — deployment order is migrations → Functions → Worker → smoke.
- `REL-CI-008` — backend failure prevents Worker deployment.
- `REL-CI-009` — shared scripts are fail-closed, non-interactive in CI, and reusable for local dry runs.
- `REL-CI-010` — production deployment concurrency is serialized and never auto-cancelled.
- `REL-CI-011` — every release records commit, migration plan/result, Function result, Worker version, and smoke result without secrets or private data.
- `REL-CI-012` — Cloudflare rollback is version-aware; database rollback is forward-fix only unless a separately reviewed corrective migration exists.
- `REL-CI-013` — service-role/secret keys never enter frontend source, build output, PR jobs, logs, or artifacts.
- `REL-CI-014` — routine deployment does not rotate OpenRouter, Supabase Function, or Cloudflare secrets.
- `REL-CI-015` — synthetic smoke is non-destructive by default; any mutating production smoke retains the exact W09 authorization and cleanup requirements.
- `REL-CI-016` — no hosted staging environment is implied by `candidate`, `preview`, or a Git branch.
- `REL-CI-017` — production deployment is not performed by GPT/MCP after pipeline activation.

## Target repository artifacts

The paths below are relative to the standalone repository root after W09:

```text
.github/
  workflows/
    pull-request.yml
    deploy-production.yml
  CODEOWNERS                         # only if owner/repository plan supports it
scripts/
  ci-verify.sh
  production-dry-run.sh
  deploy-supabase.sh
  deploy-cloudflare.sh
  smoke-production.sh
  lib/release-guards.sh
production/
  CI_CD_RELEASE_RUNBOOK.md
  CI_CD_SECRET_INVENTORY.md
  CI_CD_ROLLBACK_RUNBOOK.md
```

Implementation may consolidate scripts when that removes duplication, but the
five named responsibilities must remain independently testable. Scripts must
not contain credentials, project passwords, private endpoint tokens, real user
identifiers, or copied production data.

## Slice 10.1 — Toolchain and release-contract lock

- [ ] Confirm W09 is complete and the working directory is the standalone repository root.
- [ ] Pin Node 22 within the repository and CI; reject unsupported Node versions.
- [ ] Pin Supabase CLI, Wrangler, npm dependencies, and all GitHub Actions; do not use `latest` or an unreviewed floating major for production.
- [ ] Prefer the repository-pinned Wrangler executable over an extra deployment action.
- [ ] Pin third-party GitHub Actions to reviewed full commit SHAs where practical and record the human-readable release version in comments.
- [ ] Re-check Supabase and Cloudflare changelogs for relevant breaking changes.
- [ ] Confirm the pipeline does not call the deprecated Supabase Management API `logs.all` endpoint and does not pin extension versions that hosted Supabase now ignores.
- [ ] Inventory current production Worker name/routes, Supabase project ref, migration history, Function list, scheduled jobs, and required build variables without printing secrets.
- [ ] Record the branch/trigger decision selected from the GitHub-plan gate below.

### GitHub-plan gate

Choose exactly one and document evidence:

1. `push main → production Environment waits for required reviewer` when the
   repository plan/visibility supports it; or
2. `push main → validation only`, followed by `workflow_dispatch` for the exact
   current `main` SHA when required reviewers are unavailable.

Fully automatic production deployment with no approval is out of W10 scope.

## Slice 10.2 — Deterministic PR verification

Create `scripts/ci-verify.sh` and `.github/workflows/pull-request.yml`.

- [ ] Trigger only for pull requests targeting `main` and optional manual read-only CI dispatch.
- [ ] Use least-privilege workflow permissions; default repository contents to read-only.
- [ ] Run on Node 22 with `npm ci` and the committed lockfile.
- [ ] Run typecheck, lint, unit/component tests, production build, bundle/PWA/performance checks, and focused E2E suitable for CI.
- [ ] Start disposable local Supabase using the pinned CLI/runtime.
- [ ] Rebuild the database from the complete `supabase/migrations/` chain and run database/RLS/Function tests against local only.
- [ ] Fail when an already-present migration is edited, deleted, renamed, reordered, or duplicated relative to the protected base.
- [ ] Fail on migration/schema errors, unsafe secret patterns, generated/private artifact inclusion, or database test failure.
- [ ] Run production-shaped environment validation with placeholders/public values only.
- [ ] Build the Worker and run a production configuration dry run without upload, custom-domain mutation, remote bindings, or production credentials.
- [ ] Upload only redacted test/build reports with bounded retention; never upload `.env*`, Supabase state, browser auth state, evidence media, or raw logs containing private data.
- [ ] Prove that fork/untrusted PRs cannot access production environment secrets.

Required PR checks become branch-protection requirements before W10 exits.

## Slice 10.3 — Fail-closed release scripts

### `scripts/production-dry-run.sh`

- [ ] Verify repository root, clean/reproducible source state, exact protected `main` commit, pinned tools, expected project/Worker identifiers, and required non-secret variables.
- [ ] Print a redacted release plan: pending migration filenames, Functions to deploy, Worker target, commit SHA, and smoke scope.
- [ ] Run Supabase linked dry-run/readiness commands and Cloudflare Worker dry run without mutation.
- [ ] Refuse non-`main`, detached/unverified commit, missing gate variables, unexpected project ref, or unreviewed migration-history divergence.

### `scripts/deploy-supabase.sh`

- [ ] Require a CI-only release guard and the expected `main` commit SHA.
- [ ] Apply only reviewed pending canonical migrations to the configured production project.
- [ ] Stop immediately on migration failure or unexpected remote/local history divergence.
- [ ] Deploy only version-controlled Functions/configuration that belong to the release.
- [ ] Do not upload or rotate runtime secrets during routine deployment.
- [ ] Record redacted migration and Function results as release artifacts.

### `scripts/deploy-cloudflare.sh`

- [ ] Require successful Supabase deployment evidence for the same commit/run.
- [ ] Require an explicit production Wrangler environment/target; plain accidental `wrangler deploy` must not target the apex domain.
- [ ] Preserve the existing production Worker identity and custom-domain bindings during config hardening.
- [ ] Deploy the repository build once and record the resulting Worker version/deployment identifier.
- [ ] Do not mutate DNS, unrelated routes, account settings, or secrets.

### `scripts/smoke-production.sh`

- [ ] Default to non-mutating checks: apex/`www`, redirects, security headers, manifest/service worker, public landing/legal/Coach route, auth entry, and redacted health endpoints.
- [ ] Use synthetic identifiers only.
- [ ] Require a separate explicit scope token/manifest before any account, payment, proof/media, enrollment, role, scoring, or cleanup mutation.
- [ ] Never use real user data or perform a transfer.
- [ ] Emit a compact redacted pass/fail report tied to the release SHA.

## Slice 10.4 — Production workflow

Create `.github/workflows/deploy-production.yml`.

- [ ] Trigger through the selected GitHub-plan gate and reject any SHA not reachable from current protected `main`.
- [ ] Reference GitHub Environment `production`; secrets must not be available to validation jobs before approval.
- [ ] Configure a production concurrency group with `cancel-in-progress: false`.
- [ ] Re-run the same validation used by PR CI for the exact release SHA.
- [ ] Run `production-dry-run.sh` and persist its redacted plan.
- [ ] Deploy Supabase migrations and Functions.
- [ ] Do not run Cloudflare deployment when any backend step fails.
- [ ] Deploy the Worker only after backend success.
- [ ] Run the approved smoke subset and publish a redacted release summary.
- [ ] Mark the GitHub deployment failed when smoke fails; do not silently report success.
- [ ] Never automatically roll back a database migration.
- [ ] Provide an owner-invoked Worker rollback path tied to a known version and compatibility assessment with the already-applied database state.

## Slice 10.5 — Secrets, variables, and repository protection

### GitHub Environment `production`

Exact names must be verified against the pinned CLI versions, but the expected
categories are:

- Supabase access token, project reference, and database credential required by the non-interactive CLI;
- Cloudflare least-privilege API token and account ID;
- public production build variables such as Supabase URL and publishable key, stored as GitHub variables where appropriate rather than mislabeled secrets;
- no frontend service-role/secret key;
- no routine OpenRouter secret copy. The provider key remains in authorized Supabase server-side secret management and is rotated separately.

- [ ] Configure secret owner, purpose, minimum scope, creation date, expiry/rotation date, and revocation procedure.
- [ ] Restrict the production environment to protected `main`.
- [ ] Enable required reviewer/no-self-review where the repository plan supports it.
- [ ] Enable branch protection: PR required, required checks, stale approval handling, no force-push, and no direct unreviewed production path.
- [ ] Confirm production environment secrets are absent from PR/fork jobs, artifacts, cache keys, command arguments, and debug logs.
- [ ] Ensure retired repository/iOS archive credentials remain revoked after W09.

These GitHub settings and secret insertions are external writes and require the
owner to perform them or explicitly authorize the exact setup operation. Secret
values must be entered in GitHub, not posted in chat or committed to files.

## Slice 10.6 — Rehearsal and activation

- [ ] Rehearse PR CI with frontend-only, migration, Function, and intentionally invalid changes.
- [ ] Prove an invalid migration fails before merge/deployment.
- [ ] Prove a PR cannot obtain production secrets or deploy a Worker.
- [ ] Prove a non-`main` SHA cannot trigger production.
- [ ] Prove the approval/manual-dispatch gate blocks production mutation.
- [ ] Prove concurrent production releases serialize and the running release is not cancelled.
- [ ] Prove backend failure prevents Worker deployment.
- [ ] Prove a no-op backend release does not rewrite migration history or rotate secrets.
- [ ] Rehearse Worker rollback without changing production data.
- [ ] Review the exact first live pipeline plan with the owner.
- [ ] Obtain explicit authorization for the first production pipeline execution.
- [ ] Run one authorized release using only synthetic/non-mutating smoke unless a broader scope was separately approved.
- [ ] Verify production availability, release artifacts, GitHub deployment status, and absence of secrets/private data in logs.
- [ ] Declare GitHub Actions the routine authority and update runbooks to stop GPT/MCP production deployment.

## Failure and rollback policy

- Migration files are forward-only and backward-compatible with the currently
  deployed frontend/Functions during the release window.
- Use expand/migrate/contract across separate releases for destructive schema
  changes. W10 must reject a single-release destructive contract step unless a
  separately reviewed maintenance plan exists.
- Database migrations are not automatically rolled back. Recover through a
  reviewed corrective migration or a separately authorized platform restore.
- A failed migration or Function deploy stops the release before Cloudflare.
- A failed Worker deploy leaves the previous Worker active where Cloudflare
  guarantees that behavior; verify current version/rollback semantics at implementation.
- A smoke failure blocks release success and starts the documented incident
  decision. Worker rollback is allowed only when compatible with the new backend.
- Never delete production records, Storage objects, Auth users, or migration
  history as an automated rollback shortcut.

## Explicitly out of scope

- hosted Supabase staging project;
- Supabase preview branches or production-data cloning;
- `develop` auto-deploy branch;
- automatic PR Worker connected to production Supabase;
- fully automatic no-approval production deployment;
- routine deployment through GPT, Codex, MCP, or dashboard clicks;
- automatic secret rotation;
- automatic database down migrations or restore;
- DNS/domain changes;
- W07.5 Sales Overview or W07.6 Image Storage implementation.

## Sub-agent plan

- `msc_explorer`: read-only inventory of scripts, migration/Function commands, current Worker identity, and GitHub-plan capabilities.
- `msc_implementer`: sole writer for one bounded script/workflow slice after W09; no external deployment.
- `msc_reviewer`: independent supply-chain, least-privilege, secret-flow, branch-gate, and failure-order review.

No sub-agent may receive production secrets, approve an environment, enable a
workflow, or execute a production deployment.

## Acceptance scenarios

- `REL-CI-001/002/003`: a feature PR reconstructs local Supabase, passes all tests, performs a Worker dry run, and has no production secret context.
- `REL-CI-004`: modifying an already-deployed migration fails the PR check with the exact filename.
- `REL-CI-005/006`: a non-`main` SHA and an unapproved `main` job cannot access the production deployment steps.
- `REL-CI-007/008`: simulated Supabase failure prevents Function/Worker continuation as designed.
- `REL-CI-009/010`: scripts reject unsafe context and concurrent production runs serialize without cancellation.
- `REL-CI-011/013`: release artifacts contain identifiers/results but no secret, token, private path, user media, or personal data.
- `REL-CI-012`: Worker rollback rehearsal names the exact version and refuses an incompatible backend state.
- `REL-CI-014`: a routine release preserves existing provider/Function/Worker secrets.
- `REL-CI-015`: default smoke performs no account/data/media mutation.
- `REL-CI-016`: no branch or candidate URL is presented as hosted staging without a separate Supabase project.
- `REL-CI-017`: production runbook points operators to GitHub Actions, not GPT/MCP.

## Verification commands and evidence

Exact commands are finalized against the post-W09 repository and pinned CLI
versions. Minimum evidence:

- shell syntax/static analysis for every release script;
- workflow syntax/security review;
- `npm ci`, typecheck, lint, unit/component tests, production build, PWA/bundle/performance checks;
- complete local Supabase rebuild plus database/RLS/Function tests;
- Supabase linked dry-run/read-only migration inventory under an authorized production context;
- Wrangler production dry run with no upload;
- GitHub branch/environment protection screenshots or API evidence;
- negative-path workflow rehearsals;
- one separately authorized production pipeline execution and redacted smoke/release summary.

## Exit criteria

- PRs to protected `main` are gated by deterministic required checks using local Supabase and Cloudflare dry run only.
- Production deployment can originate only from the selected protected-main approval/manual-dispatch path.
- Migrations, Functions, and Worker deploy in the locked order with fail-stop behavior.
- Production secrets are environment-scoped, least-privilege, documented, and absent from PRs/logs/artifacts.
- Routine deployment no longer depends on GPT/MCP or a developer laptop.
- Release concurrency, evidence, smoke, and rollback behavior are rehearsed and documented.
- The first live pipeline execution is separately authorized and verified, or W10 remains incomplete with the exact external blocker recorded.
- Hosted staging remains explicitly absent; adding it requires a later ADR and workplan.

## User input and authorization

Required after W09:

1. destination GitHub repository visibility/plan and whether Environment required reviewers are available;
2. owner/reviewer for production approvals;
3. owner-entered GitHub Environment secrets/variables—never send values in chat;
4. authorization for branch protection and workflow activation;
5. exact authorization for the first production pipeline run and its smoke scope.

Repository implementation, local tests, workflow dry runs, redaction tests, and
negative-path rehearsals can be completed automatically after W09 without
production mutation. No hosted staging project or additional paid service is
required for the baseline.

## Progress log

Append each slice with requirement IDs, files changed, pinned versions, commands
and results, external settings changed, approvals, release evidence, blockers,
and the next unchecked item.
