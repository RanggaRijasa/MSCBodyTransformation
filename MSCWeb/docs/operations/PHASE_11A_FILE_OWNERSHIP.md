# Phase 11A File Ownership, Allowlists, and Freeze Gates

> Created in Slice 11A.0. This is the PM ownership plan; it is not blanket authorization to edit every listed path. Every work packet must narrow the allowlist before implementation starts.

## Operating rules

1. One file has one writer at a time. Shared tokens, root/global CSS, primitives, app shell, package/config/lockfile, parity ledger, and snapshot baseline are always serialized.
2. The PM issues an immutable work packet containing objective, exact owned paths, read-only references, frozen functions/states, accepted reference, tests/evidence, commands, prohibitions, and handoff format.
3. A path not explicitly owned is read-only. Discovery of a required out-of-allowlist change stops the packet and returns to the PM.
4. Reviewer is read-only for the slice being reviewed. Fixes go back to the current implementer/owner.
5. Ownership transfers only after the previous writer is idle, focused verification is recorded, and the PM updates the active packet.
6. Snapshots are updated only by the snapshot custodian after independent visual review. The custodian reruns the same command without update mode.
7. No Git operation is permitted by the Phase 11A goal. Changed-path validation therefore uses the agent patch/handoff manifest and direct filesystem inspection, not `git status`/`git diff`. This does not weaken the allowlist.
8. Generated `.next/`, `test-results/`, and Playwright trace output are disposable command artifacts, never source ownership or acceptance evidence by themselves.

## Global denylist / hard-frozen gate

These paths are never in a presentation work packet without a new, explicit scope approval:

```text
../**                                  # everything outside MSCWeb
supabase/**
src/domain/**
src/application/**
src/infrastructure/**
src/app/api/**
src/app/auth/**
src/proxy.ts
src/shared/security/**
src/shared/config/**
```

The following contracts are hard-frozen in behavior even when a presentation file near them is allowlisted:

- `public/sw.js`, install/runtime state machine, manifest/start URL/scope/display semantics, cache allowlist, update/offline/logout/account-switch cleanup;
- route/href/deep-link/redirect/callback paths, field names, payloads, status mapping, retry order, mutation order, idempotency keys, browser back, and focus restoration;
- verified role/claims, Guest isolation, authorization, trusted mutation origin, CSP/security headers, private `no-store`, private-media URL access, rate limit, secret/PII redaction;
- repository/use-case calls and server-authoritative scoring, enrollment, payment verification, Coach assignment, winner lock, and Admin audit;
- behavioral test assertions from Phase 03–11. Tests may be adapted for accessible markup/selectors, but never weakened to hide a regression.

If a visual design appears to require any item above, the implementer stops and files a scoped blocker. It must not be worked around in presentation code.

## Canonical route lock

This route reconciliation is final for Phase 11A:

| Capability | Canonical presentation contract |
|---|---|
| Forgot password | `/lupa-password`; no `/lupa-kata-sandi` alias |
| Coach application payment | `/akses-coach/[applicationId]`; no `/pengajuan-coach` alias |
| Participant profile edit / Coach change / account delete | Combined `/profil` page with sheets/dialog/confirmation as appropriate; no new routes |
| Coach activity + ranking | `/coach-area/program` owns both |
| Coach review detail | Inline on `/coach-area/pemeriksaan` |
| Admin Program settings + content | Tabs on `/admin/program/[programId]/edit` |
| Admin Program preview + lifecycle | `/admin/program/[programId]` |
| Admin audit | `/admin/pengaturan#audit` |
| Public Coach detail | `/coach/[coachId]` is absent; no new capability in Phase 11A |
| Admin person detail | `/admin/orang/[userId]` is absent; no new capability in Phase 11A |

## Shared ownership lanes

| Lane | Single writer while active | Paths/capabilities |
|---|---|---|
| PM ledger/decisions | Orchestrator/PM | `docs/design/PHASE_11A_PARITY_LEDGER.md`, acceptance status, route decisions, work-packet ledger |
| Dependency/config | Compatibility implementer | `package.json`, `pnpm-lock.yaml`, `components.json`, Tailwind/PostCSS-related config, narrowly required Next config |
| Global cascade/tokens | Foundation implementer | `src/app/globals.css`, `src/styles/**` or replacement token/base files, Tailwind theme bridge |
| Primitive/component contract | Foundation implementer | `src/shared/ui/primitives/**`, migrated `src/shared/ui/**`, shared layout/app-shell contract |
| Cross-role Programs | Capability implementer | `src/features/programs/**` presentation only and shared Program renderer styling |
| Cross-role Payments | Capability implementer | `src/features/payments/**` presentation only |
| Cross-role Media | Capability implementer | `src/features/device-media/**` presentation only |
| PWA presentation | Capability implementer | `src/features/pwa-install/**`, `src/features/pwa-runtime/**`, `src/features/push/**` presentation only; state/service-worker semantics frozen |
| Visual snapshots | Snapshot custodian | `tests/**/*-snapshots/*.png`, only after review |

No role implementer may make an opportunistic change in a cross-role lane. It requests the capability owner, then resumes after the shared contract is handed off.

## Cascade and Preflight decision

The initial Tailwind/shadcn pilot uses semantic variables and explicit layers:

```text
@layer theme, base, components, utilities;
```

- Tailwind utilities/components consume MSC semantic CSS variables inside `theme/base/components/utilities`; features do not introduce arbitrary brand hex values or a second token system.
- Tailwind Preflight is disabled/omitted for the initial pilot until every existing raw `input`, `select`, `textarea`, button, list, table, media, and dialog surface has been audited.
- Existing styles move from the root-global import list into route/feature-scoped loading incrementally. Landing, Auth, Peserta, Coach, and Admin must no longer always ship together.
- A one-way legacy-to-semantic token bridge may exist during migration. Circular aliases and permanent dual design systems are forbidden.
- A legacy stylesheet/selector is removed only after caller search is zero and its focused behavior/visual regression passes.
- Handwritten CSS joins the 400-line review and 500-line blocking gate. `landing-sections.css` (510), `components.css` (454), and `landing-responsive.css` (440) are mandatory split targets.

## Slice allowlist plan

The entries below are maximum candidate paths. The active PM packet must choose exact files from the row and may be narrower.

### Slice 11A.0 — Function/baseline inventory

Single writer: baseline auditor.

```text
docs/progress/PHASE_11A_BASELINE.md
docs/design/PHASE_11A_PARITY_LEDGER.md
docs/operations/PHASE_11A_FILE_OWNERSHIP.md
```

Everything else is read-only. No snapshot update or backend command.

### Slice 11A.1 — iPhone reference capture

Single writer: reference custodian; iOS source is read-only.

```text
docs/design/references/phase-11a/**/*.png
docs/design/references/phase-11a/manifest.*
docs/design/references/phase-11a/REVIEW.md
```

Only Simulator chrome may be cropped. No token, email, raw QR, weight, private photo, evidence, signed URL, or production data may enter the reference set.

### Slice 11A.2 — Concepts and approval

Single writer: concept custodian; PM owns approval fields.

```text
docs/design/concepts/phase-11a/**
docs/design/PHASE_11A_CONCEPT_DECISIONS.md
docs/design/PHASE_11A_PARITY_LEDGER.md       # PM only
```

No production UI changes before approval. ImageGen output is reference, never production UI or fake product screenshot.

### Slice 11A.3 — Tailwind/shadcn compatibility

Single writer: dependency/config implementer.

```text
package.json
pnpm-lock.yaml
components.json
postcss.config.*
tailwind.config.*                            # only if required by installed version
tsconfig.json                                # only reviewed alias change
next.config.ts                               # only compatibility wiring; security/cache unchanged
src/shared/ui/lib/**                         # narrow class utility if selected
src/styles/tailwind-compatibility.css        # disposable-to-reviewed compatibility bridge
tests/unit/*tailwind*
tests/component/*shadcn*
docs/decisions/*tailwind*shadcn*
docs/security/PHASE_11_SPDX_SBOM.json         # regenerate after approved dependency delta
```

The first `shadcn init` runs in a disposable copy, not the repository. No `add --all`, mass overwrite, large UI/animation/icon/state dependency, or unreviewed transitive package.

### Slice 11A.4 — Design system and shared shell

Single writer for global cascade/primitives/app shell. Dependency ownership must already be idle.

```text
src/app/layout.tsx
src/app/globals.css
src/app/(marketing)/layout.tsx                # stylesheet import only
src/app/(auth)/layout.tsx                     # stylesheet import only
src/app/(participant)/layout.tsx              # stylesheet import only
src/app/coach-area/layout.tsx                  # stylesheet import only
src/app/admin/layout.tsx                      # stylesheet import only
src/styles/**
src/shared/ui/**
src/features/app-shell/**
tests/component/shared-ui.test.tsx
tests/component/shell-navigation.test.tsx
tests/e2e/phase02-shells.smoke.spec.ts
tests/e2e/phase02-visual.spec.ts
tests/e2e/support/phase11a-shell-fixture.ts   # local-only deterministic role sessions
scripts/test-phase11a-shell-local.sh          # local Supabase env loader; no hosted target
development/**                                # gallery presentation only
tests/gallery/**                              # assertions/evidence, snapshot update excluded until review
```

`SessionSynchronizer`, `PwaRuntimeProvider`, route behavior, hrefs, scroll/focus/history, role labels, and server/client boundaries are preserved.
The five route-layout addenda above may only add reviewed route-scoped stylesheet
imports; metadata, composition, providers, shell kind/label, and runtime behavior
remain hard-frozen.

### Slice 11A.5 — Guest/Auth/onboarding pilot

Single writer: Auth pilot implementer. Foundation owner must be idle/stable.

```text
src/app/(auth)/**                             # page/layout presentation only
src/app/(participant)/hari-ini/page.tsx       # composition only
src/app/(participant)/program/page.tsx        # composition only
src/features/auth/components/**
src/features/auth/styles/**
src/features/participant/components/participant-home.tsx  # Guest branch presentation
tests/component/auth-pages.test.tsx
tests/component/participant-experience.test.tsx            # Guest assertions only in this packet
tests/e2e/phase03-auth.smoke.spec.ts
tests/e2e/phase03-local-auth.integration.spec.ts            # selector-only changes, behavior frozen
```

`src/features/auth/model/**`, `src/features/auth/server/**`, Auth route handlers, pending intents, profile/session operations, and Guest privacy are read-only.

### Slice 11A.6 — Cross-role capabilities

One capability owner at a time; do not assign all lanes concurrently if they share primitives/CSS.

```text
src/features/programs/components/**
src/features/programs/styles/**
src/features/payments/components/**
src/features/payments/styles/**
src/features/device-media/components/**
src/features/device-media/styles/**
src/features/pwa-install/components/**
src/features/pwa-install/styles/**
src/features/pwa-runtime/components/**
src/features/pwa-runtime/styles/**
src/features/push/components/**
src/features/push/styles/**
tests/component/programs.test.tsx
tests/component/payments.test.tsx
tests/component/device-media*.test.tsx
tests/component/landing-and-install.test.tsx  # install presentation only
tests/e2e/phase04-*.spec.ts
tests/e2e/phase05-*.spec.ts
tests/e2e/phase06-*.spec.ts
tests/e2e/phase11-pwa-quality.spec.ts          # selector/presentation assertions only
```

Models, browser adapters, APIs, service worker, private paths, sequential upload/mutation behavior, and cache rules remain read-only.

### Slice 11A.7 — Peserta

Single writer: Peserta implementer; cross-role lane changes must be requested from their owner.

```text
src/app/(participant)/**                      # excluding cross-role/auth-owned files unless transferred
src/features/participant/components/**
src/features/participant/styles/**
tests/component/participant-experience.test.tsx
tests/e2e/phase07-local-participant.integration.spec.ts
tests/e2e/phase10-cross-role.integration.spec.ts            # Peserta selectors only
```

Participant model, operations, domain scoring/access, repositories, API routes, QR/private-media boundaries, and payment capability remain frozen.

### Slice 11A.8 — Coach

Single writer: Coach implementer.

```text
src/app/coach-area/**                         # page/layout/error presentation only
src/features/coach/components/**
src/features/coach/styles/**
tests/component/coach-experience.test.tsx
tests/e2e/phase08-local-coach.integration.spec.ts
tests/e2e/phase10-cross-role.integration.spec.ts            # Coach selectors only
```

Assignment guards, access state, private answer/photo/weight scope, review reason/idempotency, and Coach application/payment boundaries remain frozen.

### Slice 11A.9 — Admin

Single writer: Admin implementer. Payment/Program/media shared lane changes remain with capability owners.

```text
src/app/admin/**                              # page/layout/error presentation only
src/features/admin/components/**
src/features/admin/styles/**
tests/component/admin-experience.test.tsx
tests/e2e/phase09-local-admin.integration.spec.ts
tests/e2e/phase10-cross-role.integration.spec.ts            # Admin selectors only
```

Server Actions and Admin application/domain/repository code are read-only. Reason, confirmation, authorization, idempotency, preview renderer, closure, audit, and destructive guards cannot be simplified.

### Slice 11A.10 — Landing and visual hardening

Single writer: landing implementer; global cascade owner must be idle.

```text
src/app/(marketing)/**                        # page/layout/error/metadata presentation only
src/features/landing/components/**
src/features/landing/styles/**
public/images/*phase-11a*                     # approved safe redesigned-PWA capture only
tests/component/landing-and-install.test.tsx
tests/unit/landing-boundaries.test.ts
tests/e2e/phase02a-landing.smoke.spec.ts
tests/e2e/phase02a-landing.visual.spec.ts
```

Landing actor boundaries, truthful install state, legal paths, metadata safety, PWA runtime/provider, and existing release images remain until reviewed replacement captures exist.

Visual hardening may patch a role-owned presentation file only after formal ownership transfer. It does not grant a broad cross-product write allowlist.

### Slice 11A.11 — Regression and closure

Primary owners: PM (integration), independent reviewer (read-only), snapshot custodian (reviewed PNG only), and original implementer for fixes.

```text
tests/**/*-snapshots/*.png                    # snapshot custodian only after approval
docs/design/PHASE_11A_PARITY_LEDGER.md        # PM only
docs/testing/*PHASE_11A*                      # evidence/results
docs/progress/*PHASE_11A*                     # progress/closure log
MSCWeb_Codex_Phased_Workplan/12A_PHASE_11A_TOTAL_UI_REDESIGN_AND_IOS_VISUAL_PARITY.md  # PM checklist/status only after all gates
```

No production fix is made by the reviewer. A finding returns to the original file owner with a narrow repair packet and focused regression.

## Work-packet allowlist template

Every implementation delegation copies and completes this block:

```text
Phase/slice:
Objective:
Writer identity:
Exact files owned:
Explicit read-only references:
Hard-frozen functions/states:
Accepted iOS/concept reference paths:
Required actual-route evidence and viewports:
Focused test commands:
Snapshot policy (normally no update):
Forbidden paths/actions:
Expected handoff:
Ownership release condition:
```

The packet is invalid if it uses a broad directory without listing the expected files, omits the accepted reference, or gives two active writers the same file.

## Handoff and independent review gates

Implementer handoff must contain:

- exact changed-file manifest matched to the allowlist;
- preserved function/state checklist and repository calls;
- actual route screenshots with viewport/appearance/browser metadata;
- focused format/lint/typecheck/test/build output;
- every snapshot deliberately changed and its reviewer approval;
- known Low/Medium gaps, manual check, and external blocker.

Reviewer handoff must contain findings ordered by severity, exact path/evidence/reproduction, parity rows accepted or needing fix, commands/environment, and verdict. `Accepted` requires zero unresolved Critical/High.

Before advancing a wave, the PM verifies directly that only allowlisted files changed, hard-frozen paths did not change, evidence is readable at original detail, snapshots were not accepted blindly, and focused gates pass. Full Phase 03–11 local runners and full Chromium/WebKit gallery remain mandatory at closure.
