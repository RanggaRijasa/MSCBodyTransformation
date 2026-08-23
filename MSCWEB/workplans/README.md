# MSCWEB phased workplans

Status: `W08 ready for execution; W07.5/W07.6 deferred post-launch`
Primary executor: Codex  
Sub-agent default: `gpt-5.6-sol`, reasoning `high`

These workplans translate the product specs into ordered, verifiable implementation phases. They are written for Codex execution in the current monorepo and remain valid after MSCWEB is moved to its own repository, subject to path updates.

## Execution order

| Phase | File | Outcome | Autonomy baseline |
|---:|---|---|---|
| W00 | [Foundation and feasibility](./PHASE_00_FOUNDATION_AND_FEASIBILITY.md) | independent Expo project, locked toolchain, proven risks | mostly automatic |
| W01 | [Landing and design system](./PHASE_01_LANDING_AND_DESIGN_SYSTEM.md) | polished landing, tokens, icon system, app shell | automatic draft + visual sign-off |
| W02 | [Auth and public app](./PHASE_02_AUTH_AND_PUBLIC_APP.md) | Google Auth local, Guest/public experience | conditional on local OAuth config |
| W03 | [Participant program](./PHASE_03_PARTICIPANT_PROGRAM.md) | Participant home/catalog/activity parity | mostly automatic |
| W04 | [Evidence, review, and scoring](./PHASE_04_EVIDENCE_REVIEW_AND_SCORING.md) | private media, Coach review, authoritative points | mostly automatic locally |
| W05 | [Enrollment and manual payment](./PHASE_05_ENROLLMENT_AND_MANUAL_PAYMENT.md) | QR enrollment and Admin-approved payment | local automatic; business inputs required |
| W06 | [Coach experience](./PHASE_06_COACH_EXPERIENCE.md) | application, payment, activation, Coach operations | local automatic; policy inputs required |
| W06.5 | [Async food insight](./PHASE_06_5_ASYNC_FOOD_INSIGHT.md) | non-blocking macro insight and favorable AI stars | automatic with fake provider; real key optional |
| W07 | [Admin experience](./PHASE_07_ADMIN_EXPERIENCE.md) | program/people/content/operations parity | mostly automatic locally |
| W07.4 | [Registration onboarding remediation](./PHASE_07_4_REGISTRATION_ONBOARDING_REMEDIATION.md) | first-login Participant/Coach-intent parity and provisional security | automatic locally; OAuth/camera smoke conditional |
| W08 | [PWA and Cloudflare hardening](./PHASE_08_PWA_AND_CLOUDFLARE.md) | installable, secure, performant production candidate plus minimum media launch safety | local automatic; external preview/production permission required |
| W09 | [Release and repository split](./PHASE_09_RELEASE_AND_REPOSITORY_SPLIT.md) | release evidence plus sole web/Cloudflare/Supabase authority in a standalone repo; iOS archived | explicit external/Git decisions required |
| W07.5 | [Admin Sales Overview](./PHASE_07_5_ADMIN_SALES_OVERVIEW.md) | deferred post-launch ledger-reconciled sales analytics | not a launch dependency; resume by owner priority |
| W07.6 | [Admin Image Storage](./PHASE_07_6_ADMIN_IMAGE_STORAGE.md) | deferred post-launch inventory, Trash, restore, and purge | not a launch dependency; destructive production authorization required |

See [AUTOMATION_AND_PERMISSIONS.md](./AUTOMATION_AND_PERMISSIONS.md) for the consolidated manual-input and authorization matrix.

## Requirement families by phase

| Phase | Primary requirement families |
|---:|---|
| W00 | `ARCH-*`, `DS-APPICON-*`, `PWA-HST-*`, feasibility portions of `QA-*` |
| W01 | `PROD-LND-*`, `DS-*`, `UX-NAV-*`, `UX-RSP-*`, `PWA-LND-*` |
| W02 | `PROD-GST-*`, `ARCH-AUTH-*`, `ARCH-NAV-*`, `SEC-AUTHZ-*` |
| W03 | `PROD-PTC-*`, `PROD-PRG-*`, `PROD-LDB-*`, `UX-HOME-*`, `UX-PRG-*` |
| W04 | `PROD-PRG-005`, `PROD-OPS-002`, `SEC-STO-*`, `SEC-OP-*`, `QA-JRN-006` |
| W05 | `PAY-*`, `UX-PAY-*`, `SEC-DATA-*`, `QA-JRN-001…004` |
| W06 | `PROD-CCH-*`, `PROD-OPS-001`, `UX-CPR-*`, `QA-CPR-*`, `PAY-CCH-*`, `QA-JRN-005/006/009` |
| W06.5 | `PROD-AI-*`, `ARCH-AI-*`, `UX-AI-*`, `SEC-PRV-005…010`, `QA-AI-*`, `QA-JRN-010/011` |
| W07 | `PROD-ADM-*`, `PROD-OPS-003…005`, scoring/winner/profile-moderation/AI-operations requirements, Admin `QA-*` |
| W07.4 | `PROD-ONB-*`, `ARCH-ONB-*`, `UX-ONB-*`, `SEC-ONB-*`, `QA-ONB-*`, `QA-JRN-014/015` |
| W08 | `PWA-*`, `DS-MOT-*`, `DS-GLS-*`, `PROD-MED-011`, `ARCH-MED-007`, `UX-MED-012`, `SEC-STO-013/014` launch subset, accessibility/performance/release `QA-*` |
| W09 | first-launch `PROD-SUC-*` except deferred `009/010`, QA release gates, safe repository split criteria |
| W07.5 (post-launch) | `PROD-SLS-*`, `PROD-SUC-009`, `ARCH-SLS-*`, `UX-SLS-*`, `SEC-DATA-009…011`, `QA-SLS-*`, `QA-JRN-012` |
| W07.6 (post-launch) | remaining `PROD-MED-*`, `PROD-SUC-010`, `ARCH-MED-*`, `UX-MED-*`, `SEC-DATA-012…014`, `SEC-STO-008…012/014`, `SEC-OP-006/007`, `QA-MED-*`, `QA-JRN-013` |

Every slice must list the exact individual requirement IDs selected from these families before implementation starts.

## Phase discipline

1. Only one phase is active.
2. Within a phase, select the smallest coherent vertical slice.
3. Mark a checkbox only after its acceptance evidence exists.
4. Do not implement later-phase functionality silently.
5. Backend development targets local Supabase; hosted main remains production.
6. No Cloudflare production deploy, DNS mutation, Supabase production mutation, or Git mutation without explicit authorization.
7. At the end of every slice, append a progress entry to that phase file.

## Required reading per phase

- root `AGENTS.md` and `MSCWEB/AGENTS.md`;
- `MSCWEB/README.md`;
- the spec files listed by the active phase;
- the active phase file only;
- relevant nearby code/tests;
- current iOS source and Simulator runtime for compact UI work.

## Mandatory iOS parity gate

The user has authorized non-destructive iOS Simulator inspection. For every mobile PWA screen or interaction:

1. Locate the corresponding SwiftUI screen/navigation path.
2. Build/launch the current iOS app for every applicable slice; prior audit screenshots never replace the fresh runtime check.
3. Inspect hierarchy, flow, states, menu, gesture outcome, tab behavior, sheet behavior, and Indonesian copy.
4. Record build result, device, OS, role/scenario, screens, and states in the phase progress log.
5. Implement browser semantics and responsive adaptations without inventing a different product flow.
6. Run compact browser visual/E2E checks and compare side-by-side.
7. The reviewer must fail the slice gate if fresh Simulator evidence is missing.

The simulator is a behavior/reference source. Do not modify iOS source during MSCWEB phases.

## Sub-agent execution protocol

The primary agent may spawn up to three bounded sub-agents. Project defaults are configured in `.codex/config.toml`.

Recommended arrangement:

```text
Primary agent
  ├─ msc_explorer (read-only): requirements/source/runtime evidence
  ├─ msc_implementer (one writer): one isolated vertical slice
  └─ msc_reviewer (read-only): independent quality/security/parity gate
```

Rules:

- Spawn only when work divides cleanly and results will be used.
- Run read-only exploration and documentation research in parallel when useful.
- Keep at most one implementation writer active in the shared checkout.
- Reviewer runs after the implementation is testable; it may run tests but does not edit.
- Primary agent resolves conflicts, performs final verification, and writes the completion report.
- Sub-agents inherit current permissions. A required external authorization is not bypassed by delegation.

## Autonomy labels

- `A — Automatic local`: Codex can perform read/edit/build/test/simulator/browser work without another product decision.
- `B — Automatic after setup`: Codex can continue after a one-time credential/account/config input or tool approval.
- `C — User decision`: business, brand, legal, policy, or product choice is required.
- `D — Explicit external authorization`: production deploy, DNS, hosted Supabase mutation, Git mutation, or other external write.

## Completion report template

```text
Phase / slice:
Requirement IDs:
Checklist completed:
Files changed:
Sub-agents and results:
iOS Simulator references inspected:
Commands run and results:
Acceptance evidence:
Manual inputs/configuration remaining:
Next unchecked item:
```
