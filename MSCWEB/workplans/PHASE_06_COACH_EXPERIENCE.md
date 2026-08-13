# MSCWEB W06 — Coach application and experience

Status: `Not started`  
Autonomy: `A` locally; `C` for final eligibility/operations policy  
Depends on: W04 evidence authority and W05 payment foundation

## Objective

Deliver the full Coach lifecycle: Participant application, eligibility/pricing, manual payment, Admin activation, Coach dashboard, unique QR, assigned participants, evidence operations, programs, leaderboard, and a professional public profile that Coach can share.

## Required references

- `00_PRODUCT_SPEC.md` Coach and application rules
- `04_MANUAL_PAYMENT.md` Coach flow/pricing
- `05_DATA_SECURITY.md`
- `02_UX_PARITY_AND_ROUTES.md`
- [`ADR-0005`](../decisions/0005-public-coach-profile.md) public Coach profile
- current iOS Coach dashboard, quick actions, queues, QR, program, and profile runtime

## Deliverables

- Coach application/attestation/pricing UI and authority operation;
- application payment request based on W05 infrastructure;
- Admin `Setujui dan aktifkan Coach` atomic operation;
- three-month Coach entitlement and protected role activation;
- complete Coach app shell and quick actions;
- assigned Participant/activity/review/QR/program/leaderboard/profile surfaces;
- public `/c/:handle` profile, Coach editor/publication controls, and share action;
- cross-Coach authorization and lifecycle tests.

## Mandatory simulator gate

- [ ] Inspect Coach Dashboard profile/metrics and exact 2×3 quick action order/states.
- [ ] Inspect review queues/detail, participants, activity, program, leaderboard, QR, and profile routes.
- [ ] Inspect Google-derived account photo/name behavior and identify which profile states have no native equivalent.
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

### Public profile and sharing

- [ ] Required identity is server-derived: Google/account photo baseline, name, and non-editable verified badge; missing Google photo blocks publication until Coach uploads one.
- [ ] Coach can replace the imported photo through the shared normalization/media pipeline.
- [ ] Optional editor fields: professional headline, story/biography, city/service area, Instagram, TikTok, website, WhatsApp, phone, testimonials, and before–after.
- [ ] Each contact/social field has an independent public toggle; hidden values are absent from the Guest read model and HTML.
- [ ] Private Coach draft and public snapshot are separate; publish operation copies only allowlisted/toggled fields and Coach cannot write verified state directly.
- [ ] Dedicated public profile media cannot reference private evidence objects; metadata is stripped.
- [ ] Every testimonial/before–after record enters moderation; third-party permission attestation is required only when another person is shown or quoted, while self-only content has a clear path without it.
- [ ] Public handle is stable, unique, and unrelated to raw QR/auth ID; unknown/unpublished handle returns a safe not-found state.
- [ ] `/c/:handle` renders cleanly with only required fields and progressively adds optional sections without empty placeholders.
- [ ] `Bagikan profil` uses Web Share when available and accessible copy-link fallback otherwise.
- [ ] Expired/revoked Coach entitlement removes verified/public state authoritatively.
- [ ] W06 records the metadata contract needed by W08; dynamic Open Graph/Cloudflare rendering is not silently claimed complete here.

## Sub-agent plan

- `msc_explorer`: current Coach/Admin application simulator audit and existing eligibility/entitlement contract map.
- `msc_implementer`: sole writer; application/activation first, then one Coach feature slice at a time.
- `msc_reviewer`: role escalation, entitlement expiry, cross-Coach data, public-field leakage, media provenance, idempotency, UI/accessibility/parity.

Primary agent owns role transition/entitlement operation and shared route guards.

## Verification

- eligibility/pricing boundary tests for every member level;
- incomplete/mutated/concurrent/already-Coach application cases;
- `QA-JRN-005` and `QA-JRN-006`;
- cross-Coach RLS negative tests;
- QR raw-value privacy/log tests;
- entitlement expiry/session refresh;
- required-only/full/partially-public Coach profile component/E2E cases;
- public API/HTML negative tests for hidden contact, raw QR/auth ID, and private evidence path;
- share API/copy fallback/unknown handle/unpublished/expired entitlement tests;
- compact current-simulator parity and wide adaptation checks.

## Exit criteria

- Participant cannot become Coach without complete eligibility, approved proof, and Admin authority operation.
- Coach sees only assigned scope and all six iOS quick actions work.
- QR enrollment identifier remains internal.
- Coach can publish and share a professional profile while every optional field remains optional and hidden contacts stay absent from public responses.
- Activation/rejection/expiry are idempotent and audited.

## User input or authorization

- Confirm operational reviewer/eligibility policy if it differs from the accepted specs.
- Production Admin identities, real payment destination, and production activation remain unauthorized.
- Production photography/testimonials and subject permissions are content inputs, not a blocker for deterministic local fixtures.

## Progress log

Append eligibility cases, simulator evidence, functions/policies, files/tests, adaptive differences, policy decisions, and next item.
