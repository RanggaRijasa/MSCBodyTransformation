# MSCWEB W06 — Coach application and experience

Status: `Not started`  
Autonomy: `A` locally; `C` for final eligibility/operations policy  
Depends on: W04 evidence authority and W05 payment foundation

## Objective

Deliver the full Coach lifecycle: Participant application, eligibility/pricing, manual payment, Admin activation, Coach dashboard, unique QR, assigned participants, evidence operations, programs, leaderboard, and profile.

## Required references

- `00_PRODUCT_SPEC.md` Coach and application rules
- `04_MANUAL_PAYMENT.md` Coach flow/pricing
- `05_DATA_SECURITY.md`
- `02_UX_PARITY_AND_ROUTES.md`
- current iOS Coach dashboard, quick actions, queues, QR, program, and profile runtime

## Deliverables

- Coach application/attestation/pricing UI and authority operation;
- application payment request based on W05 infrastructure;
- Admin `Setujui dan aktifkan Coach` atomic operation;
- three-month Coach entitlement and protected role activation;
- complete Coach app shell and quick actions;
- assigned Participant/activity/review/QR/program/leaderboard/profile surfaces;
- cross-Coach authorization and lifecycle tests.

## Mandatory simulator gate

- [ ] Inspect Coach Dashboard profile/metrics and exact 2×3 quick action order/states.
- [ ] Inspect review queues/detail, participants, activity, program, leaderboard, QR, and profile routes.
- [ ] Inspect current Admin Coach application detail/eligibility/payment/decision states.
- [ ] Record compact hierarchy, badges, tabs, menus, sheets, sticky actions, and empty/error states.

## Checklist

### Application and activation

- [ ] Only authenticated Participant can apply; no self-selected Coach/Admin role.
- [ ] Level SC or higher plus required HOM STS/ICT attestations.
- [ ] Server determines price: SC/SB 100k, Supervisor/World Team 150k, higher group 200k; Member rejected.
- [ ] Payment/eligibility/application states remain distinct.
- [ ] One Admin action atomically approves payment/application, creates three-month entitlement, activates protected role, and audits.
- [ ] Rejection reason required; repeated decision safe/idempotent.

### Coach app

- [ ] Dashboard actions: Periksa bukti, Peserta saya, Aktivitas terbaru, Peringkat, Program saya, QR pendaftaran.
- [ ] Coach tabs: Dashboard, Program, Profil.
- [ ] Participant lists and evidence review are assignment/program scoped.
- [ ] Unique QR is generated/displayed without exposing raw identifier.
- [ ] QR payload supports Participant enrollment validation only through protected operation.
- [ ] Program, leaderboard, activity, and profile states match iOS capability.
- [ ] Expired/revoked entitlement removes privileged routes after authoritative refresh.

## Sub-agent plan

- `msc_explorer`: current Coach/Admin application simulator audit and existing eligibility/entitlement contract map.
- `msc_implementer`: sole writer; application/activation first, then one Coach feature slice at a time.
- `msc_reviewer`: role escalation, entitlement expiry, cross-Coach data, idempotency, UI/accessibility/parity.

Primary agent owns role transition/entitlement operation and shared route guards.

## Verification

- eligibility/pricing boundary tests for every member level;
- incomplete/mutated/concurrent/already-Coach application cases;
- `QA-JRN-005` and `QA-JRN-006`;
- cross-Coach RLS negative tests;
- QR raw-value privacy/log tests;
- entitlement expiry/session refresh;
- compact current-simulator parity and wide adaptation checks.

## Exit criteria

- Participant cannot become Coach without complete eligibility, approved proof, and Admin authority operation.
- Coach sees only assigned scope and all six iOS quick actions work.
- QR enrollment identifier remains internal.
- Activation/rejection/expiry are idempotent and audited.

## User input or authorization

- Confirm operational reviewer/eligibility policy if it differs from the accepted specs.
- Production Admin identities, real payment destination, and production activation remain unauthorized.

## Progress log

Append eligibility cases, simulator evidence, functions/policies, files/tests, adaptive differences, policy decisions, and next item.

