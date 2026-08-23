# Automation and permissions matrix

## Work Codex can perform automatically now

The following are authorized local, non-destructive actions within the approved phase scope:

- read specs, source, migrations, tests, and logs;
- create/edit MSCWEB source, documentation, local migrations, tests, fixtures, and non-secret configuration examples;
- spawn bounded sub-agents using `gpt-5.6-sol` with `high` reasoning;
- run iOS Simulator builds, launch scenarios, navigate UI, inspect gestures/menus, and capture reference screenshots;
- prepare the Expo/React Native Web scaffold and dependency/version manifest; actual `package.json`/lockfile modification and installation starts only after the one-time explicit W00 implementation/install authorization below;
- run local dev servers, builds, lint, typecheck, unit/component/E2E/accessibility/performance checks;
- start local Colima/Supabase when a phase requires it and leave it running;
- create/test local Supabase migrations, RLS, Storage policies, seeds, RPCs, and Edge Functions against local only;
- generate design/reference assets and local PWA icon derivatives from approved source assets;
- implement landing, Guest, Participant, Coach, Admin, and payment flows against local/mock data according to the active phase;
- implement W06.5 with deterministic fake AI fixtures, provider contract tests, and local Supabase jobs without a real provider key;
- implement W07.4 first-login onboarding remediation with local Google/provisional fixtures and synthetic QR/payment proof;
- implement W08 minimum media launch safety against local Supabase: private/RLS evidence, payment-proof retention/orphan cleanup, opaque Coach-media gateway, and cache invalidation tests;
- perform local security, privacy, concurrency, cache, offline, and responsive testing;
- prepare Cloudflare/Supabase production configuration files with placeholders and dry-run validation;
- produce release checklists, runbooks, and migration plans.

## Work requiring one-time setup or permission

| Need | Why | Earliest phase |
|---|---|---:|
| Explicit authorization to modify package manifests and install the approved baseline dependencies | root repository policy requires installation authority beyond architectural agreement | 00 |
| npm/package network access if sandbox asks | install approved dependencies | 00 |
| Xcode/iOS Simulator process permission if host asks | runtime parity evidence | 01 |
| Colima/Docker/Supabase local availability | backend, Auth, Storage, RLS tests | 02 |
| Local Google OAuth client configuration | W00 callback feasibility and W02 complete login flow | 00 |
| Browser camera permission | QR scanning device/browser test | 05 |
| Physical iPhone/Android access | installed PWA, camera, safe area, keyboard verification | 08 |
| Cloudflare noindex preview deployment authorization | real routing/OAuth/Supabase endpoint and enforced-CSP gate | 08 |
| Optional OpenRouter runtime secret | one synthetic provider smoke; not required for deterministic W06.5 completion | 06.5 |
| Colima/Supabase local plus synthetic media fixtures | W08 minimum media launch-safety integration tests | 08 |
| Existing local Google OAuth and browser camera permission | optional real callback/QR smoke after deterministic W07.4 tests | 07.4 |

The user has already granted conceptual permission for iOS Simulator inspection and sub-agent use. System-level approval prompts may still appear when the local host requires them.

## User decisions/manual inputs required

| Decision/input | Used by | Can work continue before it? |
|---|---|---|
| Final landing visual approval | W01 production polish | Yes, Codex can build v1 and present it |
| Approved production photography/Coach identity | Landing/Coach | Yes, placeholders or generated reference only |
| Domain and subdomain | Cloudflare/Auth | Yes, use documented placeholders |
| Production bank name/account/holder | Payment | Yes, use safe local fixture values |
| Approved static QRIS image | Payment | Yes, use test-only fixture not resembling a real payment code |
| Payment review SLA, expiry, resubmission rules | Payment | Partial; state machine can be built, production defaults cannot be invented |
| Reconciliation, dispute/refund SOP | Payment release | No production launch |
| Evidence/payment retention period | Privacy/release | No production launch |
| Payment-proof orphan cleanup schedule and responsible actor | Payment release | Cleanup logic/tests can be built; production job cannot be activated |
| Privacy policy, terms, support contact | Landing/release | Placeholder pages only |
| Production Admin/reviewer identities | Authorization/release | Local deterministic fixtures only |
| Monitoring/analytics vendor and consent policy | Hardening | Core app can proceed without vendor |
| Notification channel/provider | Payment/operations | In-app status can proceed; external notifications deferred |
| Production AI provider/model, spend/rate limit, and secret owner | Food insight release | Yes; W06.5 can complete with fake provider, but production activation cannot |
| Production Trash auto-purge period, program-evidence retention/appeal, worker operator/alerts | Deferred W07.6 Image Storage release | Yes for first deployment; required only before post-launch Admin deletion activation |

## Actions requiring explicit authorization at execution time

- deploy or mutate hosted Supabase main;
- configure a real food-AI provider secret, enable production analysis, or send any production/user photo to an external model;
- after W07.6 is resumed: deploy/activate media inventory backfill, Trash/purge worker, or delete/restore any hosted user image;
- deploy Auth bootstrap/session/onboarding/cancel/cleanup changes or create/cancel/finalize a production registration identity;
- after W07.5 is resumed: run production Sales Overview reads or export financial/customer aggregates without an approved Admin/test scope;
- configure production Google OAuth provider/redirects;
- upload real bank/QRIS/payment destination data;
- deploy to Cloudflare, bind a custom domain, change DNS, secrets, routes, cache rules, or security headers in production;
- send external messages/notifications or invite production users;
- purchase services or enable paid plans;
- run destructive reset/delete/seed against any non-local environment;
- run `git add`, commit, push, branch operations, tags, PRs, or repository transfer;
- move MSCWEB into a new repository or change backend migration authority;
- publish a production release.
- run production smoke flows that create/mutate accounts, applications, roles, payments, proof/media, entitlements, enrollments, scoring, or audit records; these need a separate exact scope and cleanup authorization even after deploy approval.

## Recommended permission sequence

1. W00: explicitly authorize modification of package manifests/lockfile and installation of the approved baseline; then approve network access if the host prompts.
2. W00: provide/authorize local Google OAuth configuration and physical/emulated iOS/Android QR checks for feasibility exit.
3. W01: choose an authorized repository split now or explicitly defer it to W09.
4. W05: provide business payment and cleanup-policy inputs for production-readiness; continue with test fixtures meanwhile.
5. W06.5: optionally provide a runtime-only OpenRouter key for one synthetic smoke; otherwise retain deterministic provider tests.
6. W07.4: reuse local Google OAuth/camera for optional real smoke; do not mutate hosted Auth or production identities.
7. W08: verify minimum media launch safety locally; confirm payment-proof retention/orphan-cleanup schedule/operator and Coach-media cache/rollback policy.
8. W08: authorize a noindex Cloudflare preview for real routing/CSP validation, or explicitly record a rollout-blocking waiver.
9. W09: separately authorize production Supabase/Auth onboarding, payment-proof cleanup activation, AI provider/secret activation, Cloudflare/domain, production smoke-test mutations/cleanup, and exact Git/repository operations. Sales reads and Admin media deletion are excluded from first-launch scope.

## Deferred automatic work

After launch and a new owner priority, Codex may implement W07.5 locally with deterministic ledger fixtures and W07.6 locally with synthetic media. Hosted financial reads, inventory backfill, Trash/restore/purge activation, or deletion of any production object still require their original explicit authorizations.
